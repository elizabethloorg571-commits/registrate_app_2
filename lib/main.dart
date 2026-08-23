import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:playx_version_update/playx_version_update.dart';
import 'package:running_app/config/router/app_router.dart';
import 'package:running_app/firebase_options.dart';
import 'package:running_app/l10n/app_localizations.dart';
import 'package:running_app/services/notification_service.dart';
import 'package:running_app/services/shared_service.dart';
import 'package:running_app/config/theme/app_theme.dart';

import 'src/presentation/providers/translation/locale_provider.dart';

bool needsUpdate = false;

class AppInitializer {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
    }
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log específico para errores de imágenes de red
      if (details.exception.toString().contains('No host specified in URI') ||
          details.exception.toString().contains('file:///') ||
          details.exception.toString().contains('NetworkImage')) {
        debugPrint('🖼️ Network Image Error detected:');
        debugPrint('   Exception: ${details.exception}');
        debugPrint('   Stack: ${details.stack}');

        // Reportar como no fatal para monitoreo
        FirebaseCrashlytics.instance.recordError(
          details.exception,
          details.stack,
          fatal: false,
          information: ['NetworkImage error with invalid URI scheme'],
        );
      }
      // Log específico para errores de DNS lookup
      else if (details.exception.toString().contains('Failed host lookup') ||
          details.exception.toString().contains('SocketException') ||
          details.exception.toString().contains('amazonaws.com')) {
        debugPrint('🌐 DNS/Network Error detected:');
        debugPrint('   Exception: ${details.exception}');
        debugPrint('   Stack: ${details.stack}');

        // Reportar como no fatal para monitoreo
        FirebaseCrashlytics.instance.recordError(
          details.exception,
          details.stack,
          fatal: false,
          information: ['DNS lookup or network connectivity error'],
        );
      } else {
        // Otros errores como antes
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      // Log específico para errores de URL
      if (error.toString().contains('No host specified in URI') ||
          error.toString().contains('file:///')) {
        debugPrint('🌐 URL Error detected:');
        debugPrint('   Error: $error');
        debugPrint('   Stack: $stack');

        // Reportar como no fatal
        FirebaseCrashlytics.instance.recordError(
          error,
          stack,
          fatal: false,
          information: ['URL parsing error with invalid scheme'],
        );
      }
      // Log específico para errores de DNS/AWS
      else if (error.toString().contains('Failed host lookup') ||
          error.toString().contains('SocketException') ||
          error.toString().contains('amazonaws.com') ||
          error.toString().contains('ClientException')) {
        debugPrint('🌐 Network/DNS Error detected:');
        debugPrint('   Error: $error');
        debugPrint('   Stack: $stack');

        // Reportar como no fatal
        FirebaseCrashlytics.instance.recordError(
          error,
          stack,
          fatal: false,
          information: ['Network connectivity or DNS resolution error'],
        );
      } else {
        // Otros errores como antes
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
      return true;
    };
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
  }
}

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Optionally show a local notification
  _showLocalNotification(message);
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  runZonedGuarded(
    () async {
      await AppInitializer.initialize();
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Local notifications setup
      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // No solicitar permisos de notificaciones en iOS al iniciar
      const DarwinInitializationSettings iOSInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const InitializationSettings initSettings = InitializationSettings(
        android: androidInit,
        iOS: iOSInit,
      );

      await flutterLocalNotificationsPlugin.initialize(
        settings: initSettings,
        // For handling notification taps
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // handle notification tap here if needed
        },
      );

      // Lock the orientation
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      await checkForUpdates();
      runApp(ProviderScope(child: MyApp(), retry: (retryCount, error) => null));
    },
    (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
    },
  );
}

Future<void> checkForUpdates() async {
  debugPrint('Checking for updates with playx_version_update...');

  try {
    final result = await PlayxVersionUpdate.checkVersion(
      options: PlayxUpdateOptions(
        forceUpdate: true,
        androidPackageName: 'com.magdata.runApp',
        iosBundleId: 'com.magdata.registraApp',
        country: 'EC',
      ),
    );

    result.when(
      success: (versionInfo) {
        debugPrint('✅ Version check successful');
        debugPrint('🆕 Nueva versión: ${versionInfo.newVersion}');
        debugPrint('✨ Puede actualizar: ${versionInfo.canUpdate}');
        debugPrint('🔒 Forzar actualización: ${versionInfo.forceUpdate}');
        debugPrint('🔗 URL de tienda: ${versionInfo.storeUrl}');
        if (versionInfo.releaseNotes?.isNotEmpty == true) {
          debugPrint('📝 Notas de versión: ${versionInfo.releaseNotes}');
        }

        if (versionInfo.canUpdate) {
          // Guardar información para mostrar el diálogo de actualización
          SharedService.storeUrl = versionInfo.storeUrl;
          SharedService.storeVersion = versionInfo.newVersion;
          SharedService.storeReleaseNotes = versionInfo.releaseNotes ?? '';

          debugPrint(
            '📱 Update available to version: ${versionInfo.newVersion}',
          );

          needsUpdate = true;
        } else {
          debugPrint('✅ App está actualizada');
        }
      },
      error: (error) {
        debugPrint('❌ Version check failed: ${error.message}');
      },
    );
  } catch (e) {
    debugPrint('❌ Exception during version check: $e');
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initFCM();
    try {
      final userId = SharedService.uuid;
      NotificationService.instance.ensureRegisteredForSignedInUser(
        userId: userId,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Verificar si hay actualización flexible pendiente de instalar al resumir la app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver a primer plano, si hay sesión, asegurar token actualizado sin prompt
    if (state == AppLifecycleState.resumed) {
      try {
        final userId = SharedService.uuid;
        NotificationService.instance.ensureRegisteredForSignedInUser(
          userId: userId,
        );
      } catch (_) {}
    }
  }

  Future<void> _initFCM() async {
    // iOS foreground notification permission
    // await messaging.requestPermission();

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Received a foreground message: ${message.messageId}');
      }
      _showLocalNotification(message);
    });

    // Notification tapped when app in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('User tapped a notification: ${message.messageId}');
      }
      // Handle navigation or logic here
    });
  }

  @override
  Widget build(BuildContext context) {
    final Locale locale = ref.watch(localeProvider).value ?? const Locale('es');

    return MaterialApp.router(
      routerConfig: !needsUpdate ? appRouter : updateRouter,
      debugShowCheckedModeBanner: false,
      title: 'Tenorio App',
      theme: AppTheme.lightModeAndroid,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: FlutterSmartDialog.init(
        builder: (context, child) {
          final query = MediaQuery.of(context);
          return MediaQuery(
            data: query.copyWith(
              textScaler: query.textScaler.clamp(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.1,
              ),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}

// Local notification display function
void _showLocalNotification(RemoteMessage message) async {
  RemoteNotification? notification = message.notification;

  if (notification != null) {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'default_channel',
          'Default',
          channelDescription: 'Default channel for notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: platformDetails,
      payload: message.data['payload'] ?? '',
    );
  }
}

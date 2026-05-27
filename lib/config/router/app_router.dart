import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:running_app/services/shared_service.dart';
import 'package:running_app/src/presentation/ui/competitions/competition_detail_from_id_screen.dart';
import 'package:running_app/src/presentation/ui/home/screens/home_screen.dart';
import 'package:running_app/src/presentation/ui/splash/splash_screen.dart';
import 'package:running_app/src/presentation/ui/update/update_screen.dart';
import 'package:running_app/src/utils/navigator_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  navigatorKey: navigatorKey,
  routes: [
    GoRoute(
      path: '/splash',
      name: SplashScreen.name,
      builder: (context, state) => const SplashScreen(),
    ),
    // GoRoute(
    //   path: '/login',
    //   name: LoginView.name,
    //   builder: (context, state) => LoginView(),
    // ),
    // GoRoute(
    //   path: '/onboarding',
    //   name: OnboardingScreen.name,
    //   builder: (context, state) => const OnboardingScreen(),
    // ),
    // GoRoute(
    //   path: '/login',
    //   name: LoginScreen.name,
    //   builder:
    //       (context, state) =>
    //           LoginScreen(message: state.uri.queryParameters['message'] ?? ''),
    // ),
    // GoRoute(
    //   path: '/register',
    //   name: RegisterScreen.name,
    //   builder: (context, state) {
    //     final queryParameters = state.uri.queryParameters;
    //     if (kDebugMode) {
    //       print(queryParameters);
    //     }
    //     final userEmail = queryParameters['userEmail'] ?? '';
    //     final userName = queryParameters['userName'] ?? '';
    //     final userLastName = queryParameters['userLastName'] ?? '';
    //     final userPhotoUrl = queryParameters['userPhotoUrl'] ?? '';
    //     final googleId = queryParameters['googleId'] ?? '';
    //     final facebookId = queryParameters['facebookId'] ?? '';
    //     final appleId = queryParameters['appleId'] ?? '';

    //     return RegisterScreen(
    //       userEmail: userEmail,
    //       userName: userName,
    //       userLastName: userLastName,
    //       userPhotoUrl: userPhotoUrl,
    //       googleId: googleId,
    //       facebookId: facebookId,
    //       appleId: appleId,
    //     );
    //   },
    // ),
    GoRoute(
      path: '/',
      name: HomeScreen.name,
      builder: (context, state) => HomeScreen(),
      // routes: [
      //   GoRoute(
      //     path: 'orders', // Relative path under /home
      //     builder: (context, state) => OrdersScreen(),
      //     routes: [
      //       GoRoute(
      //         path: 'order/:orderId', // Relative path under /home/orders
      //         builder: (context, state) {
      //           final serviceId =
      //               state.pathParameters['orderId']!; // Access path parameter
      //           return OrderDetailsScreen(serviceId: serviceId);
      //         },
      //         routes: [
      //           GoRoute(
      //             path: 'chat/:serviceId', // Relative path under /home/orders
      //             builder: (context, state) {
      //               final serviceId =
      //                   state
      //                       .pathParameters['serviceId']!; // Access path parameter
      //               return ChatScreen(
      //                 serviceId: serviceId,
      //                 chatTitle: "Praderas del Inga",
      //               );
      //             },
      //           ),
      //         ],
      //       ),
      //     ],
      //   ),
      // ],
    ),
    // Ruta para deep linking a detalle de competencia
    GoRoute(
      path: '/competition/:id',
      name: CompetitionDetailFromIdScreen.name,
      builder: (context, state) {
        final competitionId = state.pathParameters['id']!;
        return CompetitionDetailFromIdScreen(competitionId: competitionId);
      },
    ),
    // GoRoute(
    //   path: '/forgot_password',
    //   name: ForgotPasswordScreen.name,
    //   builder: (context, state) => const ForgotPasswordScreen(),
    // ),
    // GoRoute(
    //   path: '/new_password',
    //   name: NewPasswordScreen.name,
    //   builder: (context, state) {
    //     final uri = state.uri;
    //     final queryParameters = uri.queryParameters;
    //     final email = queryParameters['email']!;

    //     return NewPasswordScreen(email: email);
    //   },
    // ),
    // GoRoute(
    //   path: '/notifications',
    //   name: NotificationsScreen.name,
    //   builder: (context, state) => NotificationsScreen(),
    // ),
  ],

  redirect: (context, state) async {
    if (kDebugMode) {
      log('GoRouter redirect - URI: ${state.uri}');
      log('GoRouter redirect - Scheme: ${state.uri.scheme}');
      log('GoRouter redirect - Host: ${state.uri.host}');
      log('GoRouter redirect - Path: ${state.uri.path}');
    }

    // **Manejar deep links con esquema personalizado registrate://**
    final uri = state.uri;
    if (uri.scheme == 'registrate') {
      // Formato esperado: registrate://competition/ID
      if (uri.host == 'competition' || uri.path.startsWith('/competition')) {
        // Extraer el ID de la competencia
        String competitionId = '';

        if (uri.host == 'competition') {
          // Formato: registrate://competition/ID
          competitionId = uri.path.replaceFirst('/', '');
        } else if (uri.path.startsWith('/competition/')) {
          // Formato alternativo: registrate:///competition/ID
          competitionId = uri.path.replaceFirst('/competition/', '');
        }

        if (competitionId.isNotEmpty) {
          if (kDebugMode) {
            log(
              'Deep link detected! Redirecting to /competition/$competitionId',
            );
          }
          // Convertir a ruta que GoRouter entiende
          return '/competition/$competitionId';
        }
      }

      // Si no se pudo procesar el deep link, ir al home
      if (kDebugMode) {
        log('Deep link format not recognized, redirecting to home');
      }
      return '/';
    }

    // Retrieve necessary data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // final uri = state.uri;
    // log('uri: $uri');
    // final queryParameters = uri.queryParameters;
    // log('queryParameters: $queryParameters');
    // final String userEmail = queryParameters['userEmail'] ?? '';
    // final String userName = queryParameters['userName'] ?? '';
    // final String userLastName = queryParameters['userLastName'] ?? '';
    // final String userPhotoUrl = queryParameters['userPhotoUrl'] ?? '';
    // final String googleId = queryParameters['googleId'] ?? '';
    // final String facebookId = queryParameters['facebookId'] ?? '';
    // final String appleId = queryParameters['appleId'] ?? '';

    if (!isLoggedIn) {
      final hasSplashed = prefs.getBool('hasSplashed') ?? false;

      // Redirect to splash if necessary
      if (!hasSplashed) {
        return '/splash';
      }

      // final hasOnboarded = prefs.getBool('hasOnboarded') ?? false;

      // if (!hasOnboarded) {
      //   return '/onboarding';
      // }

      // if (state.uri.toString().startsWith('/register')) {
      //   String currentLocation = state.uri.toString();
      //   //parse %40 to @
      //   currentLocation = Uri.decodeFull(currentLocation);

      //   final expectedLocation =
      //       '/register?userEmail=$userEmail&userName=$userName&userLastName=$userLastName&userPhotoUrl=$userPhotoUrl&googleId=$googleId&facebookId=$facebookId&appleId=$appleId';

      //   if (currentLocation == expectedLocation) {
      //     return null;
      //   }
      // }

      // final isForgotPasswordFlow =
      //     prefs.getBool('isForgotPasswordFlow') ?? false;

      // if (isForgotPasswordFlow) {
      //   final forgetPasswordScreen = prefs.getString('forgetPasswordScreen');
      //   if (forgetPasswordScreen == '/new_password') {
      //     final email = queryParameters['email'] ?? '';
      //     return '/new_password?email=$email';
      //   }
      //   return '/forgot_password';
      // }

      // final preferredLoginMode =
      //     prefs.getString('preferredLoginMode') ?? 'register';

      // // Redirect based on preferred login mode
      // if (preferredLoginMode == 'register') {
      //   return '/register?userEmail=$userEmail&userName=$userName&userLastName=$userLastName&userPhotoUrl=$userPhotoUrl&googleId=$googleId&facebookId=$facebookId&appleId=$appleId';
      // }

      // // Default to login screen
      // return '/login';
    }

    // If the user is logged in, allow them to proceed
    return null;
  },
);

final updateRouter = GoRouter(
  initialLocation: '/update',
  navigatorKey: navigatorKey,
  routes: [
    GoRoute(
      path: '/update',
      name: UpdateScreen.name,
      builder: (context, state) => UpdateScreen(
        storeUrl: SharedService.storeUrl,
        storeVersion: SharedService.storeVersion,
      ),
    ),
  ],
  redirect: (context, state) async {
    return null;
  },
);

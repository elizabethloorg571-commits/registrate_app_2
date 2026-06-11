import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:running_app/services/notification_service.dart';
import 'package:running_app/services/shared_service.dart';
import 'package:running_app/src/data/api/devices/devices_api_service.dart';
import 'package:running_app/src/data/api/users/users_api_service.dart';
import 'package:running_app/src/data/cache/shared_preferences_manager.dart';
import 'package:running_app/src/domain/models/device.dart';
import 'package:running_app/src/presentation/providers/profile/profile_provider.dart';
import 'package:running_app/src/presentation/ui/auth/screens/forgot_password_screen.dart';
import 'package:running_app/src/presentation/ui/auth/screens/register_screen.dart';

import 'package:running_app/src/presentation/widgets/global_widgets.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';
import 'package:running_app/config/theme/helpers/hex_color.dart';
import 'package:running_app/src/utils/navigator_key.dart';
import 'package:running_app/src/utils/notification_permission_helper.dart';
import 'package:running_app/src/utils/responsive.dart';
import 'package:running_app/src/utils/url_launcher_utils.dart';
import 'package:running_app/src/utils/validator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../providers/inscriptions/inscriptions_provider.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key, this.needsSafeArea = true});

  final bool needsSafeArea;
  static const name = '/login';

  @override
  LoginViewState createState() => LoginViewState();
}

class LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isOperationInProgress = false;
  bool _isPasswordVisible = false;

  Future<void> _initializeGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize();
      debugPrint('Google Sign-In initialized.');
    } catch (e) {
      debugPrint('Google Sign-In initialization failed: $e');
    }
  }

  TapGestureRecognizer get tapTermsRecognizer => TapGestureRecognizer()
    ..onTap = () {
      try {
        UrlLauncherUtils.launch(
          "https://registrate.magdata.com.ec/terminosycondiciones",
        );
      } catch (e) {
        GlobalWidgets.showBasicAlert(
          "Error",
          "No se pudo abrir el enlace de términos y condiciones. Por favor, inténtalo más tarde",
          "Aceptar",
        );
      }
    };

  TapGestureRecognizer get tapPoliticsRecognizer => TapGestureRecognizer()
    ..onTap = () {
      try {
        UrlLauncherUtils.launch(
          "https://registrate.magdata.com.ec/politicasdeprotecciondedatos",
        );
      } catch (e) {
        GlobalWidgets.showBasicAlert(
          "Error",
          "No se pudo abrir el enlace de términos y condiciones. Por favor, inténtalo más tarde",
          "Aceptar",
        );
      }
    };

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

  @override
  Widget build(BuildContext context) {
    return widget.needsSafeArea
        ? SafeArea(child: _buildScaffold(needsSpacing: false))
        : _buildScaffold(needsSpacing: true);
  }

  Scaffold _buildScaffold({required bool needsSpacing}) {
    final responsive = Responsive(context);

    return Scaffold(
      body: Padding(
        padding: GlobalWidgets.pagePadding(context),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              if (needsSpacing) SizedBox(height: responsive.hp(75)),
              Center(
                child: SizedBox(
                  height: responsive.hPercent(10),
                  child: Image.asset('assets/images/registraTe-logo-horizontal.png', fit: BoxFit.contain),
                ),
              ),
              SizedBox(height: responsive.hp(5)),
              Text(
                textAlign: TextAlign.center,
                'Iniciar sesión',
                style: nunitoSansTitleLargeStyle(context),
              ),
              Text(
                textAlign: TextAlign.center,
                'Inicia sesión y encuentra las mejores carreras',
                style: nunitoSansBodyMediumStyle(
                  context,
                  fontWeight: FontWeight.w300,
                ),
              ),
              SizedBox(height: responsive.hp(20)),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      keyboardType: TextInputType.emailAddress,
                      style: nunitoSansBodyMediumStyle(context),
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        hintText: 'Ingresa tu correo electrónico',
                        hintStyle: nunitoSansBodyMediumStyle(context),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey.shade900,
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey.shade900,
                            width: 1,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 0.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 0.5),
                        ),
                      ),

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu correo electrónico';
                        }
                        if (!Validator.validate(ValidatorType.email, value)) {
                          return 'Correo electrónico no válido';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: responsive.hp(20)),
                    TextFormField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: !_isPasswordVisible,
                      obscuringCharacter: '*',
                      style: nunitoSansBodyMediumStyle(context),
                      controller: _passwordController,
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: hexOrRGBToColor("#7F8083"),
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        labelText: 'Contraseña',
                        hintText: 'Ingresa tu contraseña',
                        hintStyle: nunitoSansBodyMediumStyle(context),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey.shade900,
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey.shade900,
                            width: 1,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 0.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 0.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu contraseña';
                        }

                        if (!Validator.validate(
                          ValidatorType.password,
                          value,
                        )) {
                          return 'Contraseña no válida';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: responsive.hp(20)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary900,
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.wp(30),
                          vertical: responsive.hp(10),
                        ),
                        disabledBackgroundColor: AppTheme.primary900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.wp(20),
                          ),
                        ),
                      ),
                      onPressed: !_isOperationInProgress
                          ? () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _isOperationInProgress = true;
                                });
                                try {
                                  final result = await UsersApiService.login({
                                    "email": _emailController.text.trim(),
                                    "password": _passwordController.text,
                                  }, "es");
                                  if (result['response'] ?? false) {
                                    await onLoginSuccess(result);
                                  } else {
                                    ScaffoldMessenger.of(
                                      navigatorKey.currentContext!,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(result['message']),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (kDebugMode) {
                                    print(e);
                                  }
                                } finally {
                                  setState(() {
                                    _isOperationInProgress = false;
                                  });
                                }
                              }
                            }
                          : null,
                      child: !_isOperationInProgress
                          ? Text(
                              'Iniciar sesión',
                              style: nunitoSansTitleSmallStyle(
                                context,
                                color: AppTheme.white950,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : SizedBox(
                              height: 15,
                              width: 15,
                              child: CircularProgressIndicator(
                                color: AppTheme.white950,
                                strokeWidth: 2,
                              ),
                            ),
                    ),
                    SizedBox(height: responsive.hp(20)),
                    InkWell(
                      onTap: !_isOperationInProgress
                          ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordScreen(),
                              ),
                            )
                          : null,
                      child: Text(
                        'Olvidé mi contraseña',
                        style: nunitoSansLabelLargeStyle(
                          context,
                          fontWeight: FontWeight.w500,
                          color: hexOrRGBToColor("#007AFF"),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.hp(10)),
                    Divider(color: Colors.grey, thickness: 0.5),
                    SizedBox(height: responsive.hp(10)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lightModeButtonsSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: !_isOperationInProgress
                          ? () => _signInWithGoogle()
                          : null,
                      child: Text(
                        'Continuar con Google',
                        style: nunitoSansStyle(400, 13),
                      ),
                    ),
                    Platform.isIOS
                        ? Column(
                            children: [
                              const SizedBox(height: 5),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppTheme.lightModeButtonsSecondary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: !_isOperationInProgress
                                    ? () => _signInWithApple()
                                    : null,
                                label: Text(
                                  'Continuar con Apple',
                                  style: nunitoSansStyle(400, 13),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox(),
                    const SizedBox(height: 5),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lightModeButtonsSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: !_isOperationInProgress
                          ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            )
                          : null,
                      icon: Icon(Icons.mail_outline, size: 20),
                      label: Text(
                        'Registrarme con correo',
                        style: nunitoSansStyle(400, 13),
                      ),
                    ),
                    const SizedBox(height: 15),
                    //terms and conditions
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Al iniciar sesión usted acepta estar de acuerdo con los',
                          style: nunitoSansStyle(300, 12),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {
                                tapTermsRecognizer.onTap?.call();
                              },
                              child: Text(
                                'Términos y condiciones',
                                style: nunitoSansStyle(
                                  400,
                                  12,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            Text(' y ', style: nunitoSansStyle(300, 12)),
                            InkWell(
                              onTap: () {
                                tapPoliticsRecognizer.onTap?.call();
                              },
                              child: Text(
                                'Política de privacidad',
                                style: nunitoSansStyle(
                                  400,
                                  12,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isOperationInProgress = true;
    });

    final navigatorState = Navigator.of(context);

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final OAuthCredential oauthCredential = OAuthProvider("apple.com")
          .credential(
            idToken: credential.identityToken,
            accessToken: credential.authorizationCode,
          );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(oauthCredential);

      final User? user = userCredential.user;

      if (user != null) {
        final loginResult = await UsersApiService.login({
          "apple_id": user.uid,
        }, "es");

        if (loginResult["response"] ?? false) {
          await onLoginSuccess(loginResult);
        } else {
          if (user.providerData[0].email == null) {
            GlobalWidgets.showBasicAlert(
              "Inicio de sesión con Apple",
              "El usuario no tiene un correo electrónico asociado, asocie un correo o brinde los permisos necesarios para la operación.",
              "Ok",
            );
          } else {
            final personaResult = await UsersApiService.getPersonaByEmail(
              user.providerData[0].email!,
            );

            if ((personaResult["response"] ?? false) &&
                (personaResult["data"] ?? []).isNotEmpty) {
              final data = personaResult["data"];
              final userId = data[0]["_id"];
              final userData = {
                "apple_id": user.uid,
                // "foto": user.photoURL ?? user.providerData[0].photoURL ?? "",
                "_id": userId,
              };
              final userResult = await UsersApiService.updateUser(
                userData,
                needsCustomToken: true,
              );

              if (userResult["response"] ?? false) {
                final loginResult = await UsersApiService.login({
                  "apple_id": user.uid,
                }, "es");

                if (loginResult["response"] ?? false) {
                  await onLoginSuccess(loginResult);
                } else {
                  GlobalWidgets.showBasicAlert(
                    "Inicio de sesión con Apple",
                    loginResult["message"],
                    "Ok",
                  );
                }
              }
            } else {
              String? userName = credential.givenName;
              String? userLastName = credential.familyName;
              if (userName == null || userLastName == null) {
                final bool canContinue = await showDialog(
                  context: navigatorKey.currentContext!,
                  barrierDismissible: false,
                  builder: (context) => PlatformAlertDialog(
                    title: Text(
                      "Inicio de sesión con Apple",
                      style: nunitoSansStyle(600, 16),
                    ),
                    content: Column(
                      children: [
                        Text(
                          "No se ha podido obtener la información de tu nombre.",
                          style: nunitoSansStyle(400, 12),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Para volver a intentarlo por favor elimina el permiso de inicio de sesión con Apple para esta app desde tu dispositivo en Configuración > Tu cuenta de Apple > Iniciar sesión con Apple y vuelve a intentarlo.",
                          style: nunitoSansStyle(300, 12),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Puedes omitir este paso y continuar con el registro manual.",
                          style: nunitoSansStyle(400, 12),
                        ),
                      ],
                    ),
                    actions: [
                      PlatformDialogAction(
                        child: Text(
                          "Cancelar",
                          style: nunitoSansStyle(600, 12, color: Colors.red),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      PlatformDialogAction(
                        child: Text(
                          "Continuar",
                          style: nunitoSansStyle(600, 12, color: Colors.green),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  ),
                );

                if (!canContinue) {
                  setState(() {
                    _isOperationInProgress = false;
                  });
                  return;
                }
              }

              final Map<String, dynamic> userData = {
                "userEmail": user.providerData[0].email!,
                "userName": userName,
                "userLastName": userLastName,
                "appleId": user.uid,
              };

              navigatorState.push(
                MaterialPageRoute(
                  builder: (context) => RegisterScreen(userData: userData),
                ),
              );
            }
          }
          setState(() {
            _isOperationInProgress = false;
          });
        }
      }
    } catch (e) {
      if (e.runtimeType != SignInWithAppleAuthorizationException) {
        GlobalWidgets.showBasicAlert(
          "Inicio de sesión con Apple",
          e.toString(),
          "Ok",
        );
      }
    } finally {
      setState(() {
        _isOperationInProgress = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isOperationInProgress = true;
    });

    final navigatorState = Navigator.of(context);
    final googleSignIn = GoogleSignIn.instance;

    try {
      // 1️⃣ Authenticate user interactively
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      // 2️⃣ Define scopes you need (add from Google's list if required)
      const scopes = <String>['email', 'profile', 'openid'];

      // 3️⃣ Authorize for scopes (get tokens)
      final authClient = googleSignIn.authorizationClient;
      var authorization = await authClient.authorizationForScopes(scopes);

      authorization ??= await authClient.authorizeScopes(scopes);

      final accessToken = authorization.accessToken;
      final idToken = googleUser.authentication.idToken;

      // 4️⃣ Sign in to Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      // 5️⃣ Your backend login logic (unchanged from your original)
      if (user != null) {
        final loginResult = await UsersApiService.login({
          "google_id": user.uid,
        }, "es");

        if (loginResult["response"] ?? false) {
          await onLoginSuccess(loginResult);
        } else {
          if (user.providerData[0].email == null) {
            GlobalWidgets.showBasicAlert(
              "Inicio de sesión con Google",
              "El usuario no tiene un correo electrónico asociado, asocie un correo o brinde los permisos necesarios para la operación.",
              "Ok",
            );
          } else {
            final personaResult = await UsersApiService.getPersonaByEmail(
              user.providerData[0].email!,
            );

            if ((personaResult["response"] ?? false) &&
                (personaResult["data"] ?? []).isNotEmpty) {
              final data = personaResult["data"];
              final userId = data[0]["_id"];
              final userData = {
                "google_id": user.uid,
                "foto": user.photoURL ?? user.providerData[0].photoURL ?? "",
                "_id": userId,
              };

              final userResult = await UsersApiService.updateUser(
                userData,
                lang: "es",
                needsCustomToken: true,
              );

              if (userResult["response"] ?? false) {
                final loginResult = await UsersApiService.login({
                  "google_id": user.uid,
                }, "es");

                if (loginResult["response"] ?? false) {
                  await onLoginSuccess(loginResult);
                } else {
                  GlobalWidgets.showBasicAlert(
                    "Inicio de sesión con Google",
                    loginResult["message"],
                    "Ok",
                  );
                }
              } else {
                GlobalWidgets.showBasicAlert(
                  "Inicio de sesión con Google",
                  userResult["message"],
                  "Ok",
                );
              }
            } else {
              final displayName = user.providerData[0].displayName;
              String? userName;
              String? userLastName;
              if (displayName != null) {
                final parts = displayName.split(' ');
                userName = parts.isNotEmpty ? parts[0] : null;
                userLastName = parts.length > 1
                    ? parts.sublist(1).join(' ')
                    : null;
              }

              final Map<String, dynamic> userData = {
                "userEmail": user.providerData[0].email!,
                "userName": userName,
                "userLastName": userLastName,
                "userPhotoUrl":
                    user.photoURL ?? user.providerData[0].photoURL ?? "",
                "googleId": user.uid,
              };

              navigatorState.push(
                MaterialPageRoute(
                  builder: (context) => RegisterScreen(userData: userData),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      GlobalWidgets.showBasicAlert(
        "Inicio de sesión con Google",
        e.toString(),
        "Ok",
      );
    } finally {
      setState(() {
        _isOperationInProgress = false;
      });
    }
  }

  Future<void> onLoginSuccess(Map<String, dynamic> result) async {
    final userData = result["data"];
    final userExist = userData['userExist'];

    await _saveSharedPreferences(userData, userExist);
    await NotificationPermissionHelper.promptForNotifications();
    // Si ya existe sesión y permisos, asegurar registro del token sin prompt
    try {
      await NotificationService.instance.ensureRegisteredForSignedInUser(
        userId: SharedService.uuid,
      );
    } catch (_) {}
    await _addDeviceData();
    ref.invalidate(userProfileProvider);
    ref.invalidate(inscriptionsFilterProvider);

    if (!mounted) return;
    final navigatorState = Navigator.of(context);
    if (navigatorState.canPop()) {
      navigatorState.pop(true);
    }
  }

  Future<void> _saveSharedPreferences(
    Map<String, dynamic> userData,
    Map<String, dynamic> userExist,
  ) async {
    await SharedPreferencesManager.setFields(
      stringFields: {
        "userUuid": userData['userId'],
        "email": userData['email'] ?? "",
        "token": userData['token'],
        "nombres": userExist['nombres'] ?? "",
        "apellidos": userExist['apellidos'] ?? "",
        "uuid": userExist['_id'],
        "tipo_documento": userExist['tipo_documento'] ?? "",
        "num_documento": userExist['num_documento'] ?? "",
        "celular": userExist['celular'] ?? "",
        "tipo": userExist['tipo'] ?? "",
        "foto": userExist['foto'] ?? "",
        "fecha_creacion": userExist['createdAt'] ?? "",
      },
      intFields: {"estado": userExist['estado']},
      boolFields: {"hasLoggedIn": true, "isLoggedIn": true},
    );
  }

  Future<void> _addDeviceData() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.getNotificationSettings();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final prefs = await SharedPreferences.getInstance();

      // Obtener token con reintentos en iOS
      String? fcmToken;
      if (Platform.isIOS) {
        fcmToken = await _getTokenWithRetry(messaging);
      } else {
        fcmToken = await messaging.getToken();
      }

      if (fcmToken != null) {
        prefs.setString('fcmToken', fcmToken);

        final result = Platform.isAndroid
            ? await _addAndroidDeviceData()
            : await _addIosDeviceData();

        final bool status = result["status"] ?? result["response"] ?? false;

        if (!status) {
          final List data = result["data"] ?? [];
          final String message = result["message"] ?? result["error"];
          if (data.isNotEmpty) {
            final dontAskAgainRegisterDevice =
                prefs.getBool("dontAskAgainRegisterDevice") ?? false;
            if (!dontAskAgainRegisterDevice) {
              await GlobalWidgets.showAlertConfirmation(
                message,
                "Si pulsa continuar, su dispositivo no podrá recibir notificaciones.",
                PlatformDialogAction(
                  onPressed: () async {
                    final navigatorState = Navigator.of(context);

                    await prefs.setBool("dontAskAgainRegisterDevice", true);
                    navigatorState.pop();
                  },
                  child: Text(
                    "Continuar",
                    style: nunitoSansStyle(600, 12, color: Colors.orange),
                  ),
                ),
                PlatformDialogAction(
                  onPressed: () async {
                    final navigatorState = Navigator.of(context);
                    List<Device> devices = data
                        .map((deviceJson) => Device.fromJson(deviceJson))
                        .toList();

                    await _showDeviceDialog(context, devices);
                    navigatorState.pop();
                  },
                  child: Text("Administrar", style: nunitoSansStyle(600, 12)),
                ),
              );
            }
          } else {
            await GlobalWidgets.showBasicAlert(
              "Error al registrar su dispositivo",
              message,
              "ok",
            );
          }
        }
      }
    }
  }

  Future<void> _showDeviceDialog(
    BuildContext context,
    List<Device> devices,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccione un dispositivo para reemplazar'),
          content: SingleChildScrollView(
            child: ListBody(
              children: devices.map((device) {
                return ListTile(
                  leading: Icon(
                    device.alias.contains('iPhone')
                        ? Icons.phone_iphone
                        : Icons.phone_android,
                  ),
                  title: Text(device.alias),
                  onTap: () async {
                    final navigatorState = Navigator.of(context);
                    await onDeviceSelected(device);
                    navigatorState.pop();
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> onDeviceSelected(Device device) async {
    final result = await DevicesApiService.deleteDeviceRegister(device.id);

    final bool status = result["status"] ?? result["response"] ?? false;
    final String message = result["message"] ?? result["error"];

    if (!status) {
      await GlobalWidgets.showBasicAlert(
        "Error al registrar su dispositivo",
        message,
        "ok",
      );
    } else {
      Platform.isAndroid
          ? await _addAndroidDeviceData()
          : await _addIosDeviceData();
    }
  }

  Future<Map<String, dynamic>> _addAndroidDeviceData() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    final deviceData = {
      "deviceManufacturer": androidInfo.manufacturer,
      "deviceBrand": androidInfo.brand,
      "deviceModel": androidInfo.model,
      "deviceOsVersion": androidInfo.version.release,
      "deviceType": "ANDROID",
      "deviceProduct": androidInfo.product,
      "deviceId": androidInfo.id,
    };
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('deviceData', jsonEncode(deviceData));

    return await DevicesApiService.registerDevice(deviceData['deviceModel']!);
  }

  Future<Map<String, dynamic>> _addIosDeviceData() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;

    final deviceData = {
      "deviceManufacturer": iosInfo.model,
      "deviceBrand": iosInfo.name,
      "deviceModel": iosInfo.utsname.machine,
      "deviceOsVersion": iosInfo.systemVersion,
      "deviceType": "IOS",
      "deviceProduct": iosInfo.utsname.sysname,
      "deviceId": iosInfo.identifierForVendor,
    };

    return await DevicesApiService.registerDevice(deviceData['deviceModel']!);
  }

  /// Intenta obtener el token FCM con reintentos en iOS
  Future<String?> _getTokenWithRetry(
    FirebaseMessaging messaging, {
    int maxAttempts = 5,
    Duration delay = const Duration(seconds: 2),
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final token = await messaging.getToken();
        if (token != null) {
          return token;
        }
      } catch (e) {
        debugPrint('Intento ${i + 1}/$maxAttempts de obtener token FCM: $e');
      }

      if (i < maxAttempts - 1) {
        await Future.delayed(delay);
      }
    }
    debugPrint(
      'No se pudo obtener el token FCM después de $maxAttempts intentos',
    );
    return null;
  }
}

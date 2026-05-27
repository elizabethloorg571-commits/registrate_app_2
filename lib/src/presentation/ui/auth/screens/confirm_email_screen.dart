import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:running_app/services/notification_service.dart';
import 'package:running_app/services/shared_service.dart';
import 'package:running_app/src/data/api/users/users_api_service.dart';
import 'package:running_app/src/data/cache/shared_preferences_manager.dart';
import 'package:running_app/src/presentation/providers/inscriptions/inscriptions_provider.dart';
import 'package:running_app/src/presentation/widgets/global_widgets.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';
import 'package:running_app/src/utils/notification_permission_helper.dart';
import 'package:running_app/src/utils/responsive.dart';

import '../../../providers/profile/profile_provider.dart';

class ConfirmEmailScreen extends ConsumerStatefulWidget {
  const ConfirmEmailScreen({super.key, required this.loginData});

  final Map<String, dynamic> loginData;

  @override
  ConfirmEmailScreenState createState() => ConfirmEmailScreenState();
}

class ConfirmEmailScreenState extends ConsumerState<ConfirmEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _isOperationInProgress = false;
  String? codeErrorText;
  String welcomeMessage =
      'Excelentes noticias. Ya puedes iniciar sesión con tu correo electrónico registrado.';
  String buttonMessage = 'Ir al login';

  Map<String, dynamic> get loginData => widget.loginData;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Validación", style: nunitoSansTitleLargeStyle(context)),
          centerTitle: false,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Padding(
          padding: GlobalWidgets.pagePadding(context),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 5),
                Center(
                  child: SizedBox(
                    height: responsive.hPercent(10),
                    child: Image.asset('assets/images/geltea_icon.png'),
                  ),
                ),
                SizedBox(height: responsive.hp(5)),
                Column(
                  children: [
                    Text(
                      textAlign: TextAlign.center,
                      '¡Valida tu correo!',
                      style: nunitoSansTitleLargeStyle(context),
                    ),
                    Text(
                      textAlign: TextAlign.center,
                      'Hemos enviado un enlace a',
                      style: nunitoSansBodyMediumStyle(
                        context,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: responsive.hp(10)),
                    Text(
                      textAlign: TextAlign.center,
                      "[${loginData['email']}]",
                      style: nunitoSansBodyMediumStyle(
                        context,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: responsive.hp(10)),
                    Text(
                      textAlign: TextAlign.center,
                      'Por favor, revisa tu bandeja de entrada (o la carpeta de spam) y confirma que recibiste un código para restablecer tu contraseña.',
                      style: nunitoSansBodyMediumStyle(
                        context,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    SizedBox(height: responsive.hp(20)),

                    TextFormField(
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                      maxLength: 6,
                      style: nunitoSansBodyMediumStyle(context),
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'Código de verificación',
                        hintText: '123456',
                        hintStyle: nunitoSansBodyMediumStyle(
                          context,
                          fontWeight: FontWeight.w300,
                        ),
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
                          return 'Por favor ingresa el código de verificación';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: responsive.hp(10)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lightModeBlue,
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.wp(30),
                          vertical: responsive.hp(10),
                        ),
                        disabledBackgroundColor: AppTheme.lightModeBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            responsive.wp(20),
                          ),
                        ),
                      ),
                      onPressed: () async {
                        final navigatorState = Navigator.of(context);
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isOperationInProgress = true;
                          });

                          final verifyData = {
                            "email": loginData['email'],
                            "otp": _codeController.text,
                          };

                          try {
                            final verificationResult =
                                await UsersApiService.verifyEmail(
                                  verifyData,
                                  _codeController.text,
                                );

                            final bool response =
                                verificationResult["response"] ?? false;
                            final String message =
                                verificationResult["message"] ??
                                verificationResult["error"] ??
                                "Error al intentar el registro";

                            if (response ||
                                message.contains("verificado con éxito")) {
                              final loginResult = await UsersApiService.login(
                                loginData,
                                "es",
                              );
                              if (loginResult["response"] ?? false) {
                                await onLoginSuccess(loginResult);
                              } else {
                                final msg =
                                    loginResult["message"] ??
                                    loginResult["error"] ??
                                    "Error al intentar el inicio de sesión";
                                await GlobalWidgets.showBasicAlert(
                                  "Error: $msg",
                                  "Prueba el inicio de sesión manualmente",
                                  "Entendido",
                                );
                              }
                            } else {
                              final msg =
                                  verificationResult["message"] ??
                                  verificationResult["error"] ??
                                  "Error al intentar el registro";
                              await GlobalWidgets.showBasicAlert(
                                "Error: $msg",
                                "Prueba nuevamente",
                                "Entendido",
                              );
                            }

                            navigatorState.popUntil((route) => route.isFirst);
                          } catch (e) {
                            await GlobalWidgets.showBasicAlert(
                              'Error al validar el código',
                              e.toString(),
                              'Aceptar',
                            );
                          } finally {
                            setState(() {
                              _isOperationInProgress = false;
                            });
                          }
                        }
                      },

                      child: !_isOperationInProgress
                          ? Text(
                              "Registrarme",
                              style: nunitoSansStyle(
                                500,
                                14,
                                color: AppTheme.white,
                              ),
                            )
                          : GlobalWidgets.circularProgressIndicator(
                              radius: 10,
                              color: AppTheme.white,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> onLoginSuccess(Map<String, dynamic> result) async {
    final userData = result["data"];
    final userExist = userData['userExist'];

    welcomeMessage = 'Excelentes noticias. Te has registrado de manera exitosa';
    buttonMessage = "Ir al inicio";

    await _saveSharedPreferences(userData, userExist);
    await NotificationPermissionHelper.promptForNotifications();
    try {
      await NotificationService.instance.ensureRegisteredForSignedInUser(
        userId: SharedService.uuid,
      );
    } catch (_) {}

    ref.invalidate(userProfileProvider);
    ref.invalidate(inscriptionsFilterProvider);
  }

  Future<void> _saveSharedPreferences(
    Map<String, dynamic> userData,
    Map<String, dynamic> userExist,
  ) async {
    await SharedPreferencesManager.setFields(
      stringFields: {
        "userUuid": userData['userId'] ?? userData['_id'],
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
}

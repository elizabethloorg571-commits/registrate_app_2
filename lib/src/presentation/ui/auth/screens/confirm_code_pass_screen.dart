import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:running_app/src/data/api/users/users_api_service.dart';
import 'package:running_app/src/presentation/widgets/global_widgets.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';
import 'package:running_app/config/theme/helpers/hex_color.dart';
import 'package:running_app/src/utils/navigator_key.dart';
import 'package:running_app/src/utils/responsive.dart';
import 'package:running_app/src/utils/validator.dart';

class ConfirmCodePassScreen extends ConsumerStatefulWidget {
  const ConfirmCodePassScreen({super.key, required this.email});

  final String email;

  @override
  ConfirmCodePassScreenState createState() => ConfirmCodePassScreenState();
}

class ConfirmCodePassScreenState extends ConsumerState<ConfirmCodePassScreen> {
  final _formKey = GlobalKey<FormState>();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isOperationInProgress = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _success = false;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Recuperar contraseña",
            style: nunitoSansTitleLargeStyle(context),
          ),
          centerTitle: false,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_success) {
                Navigator.pop(context);
              }
              Navigator.pop(context);
            },
          ),
        ),
        body: Padding(
          padding: GlobalWidgets.pagePadding(context),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: [
                Center(
                  child: SizedBox(
                    height: responsive.hPercent(10),
                    child: Image.asset('assets/images/app_icon.png'),
                  ),
                ),
                SizedBox(height: responsive.hp(5)),
                Column(
                  children: !_success
                      ? [
                          Text(
                            textAlign: TextAlign.center,
                            'Restablecer contraseña',
                            style: nunitoSansTitleLargeStyle(context),
                          ),
                          Text(
                            textAlign: TextAlign.center,
                            'Ingresa el código de verificación que se envió a tu correo electrónico y establece una nueva contraseña.',
                            style: nunitoSansBodyMediumStyle(
                              context,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          SizedBox(height: responsive.hp(20)),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Requisito de contraseña: ',
                                  style: nunitoSansStyle(500, 12),
                                ),
                                TextSpan(
                                  text:
                                      'mínimo 8 caracteres y debe contener una mezcla de mayúsculas, minúsculas, números y caracteres especiales',
                                  style: nunitoSansStyle(300, 12),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: responsive.hp(20)),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
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
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                    labelText:
                                        'Introduce una contraseña segura',
                                    hintText: '*********',
                                    hintStyle: nunitoSansBodyMediumStyle(
                                      context,
                                      fontWeight: FontWeight.w200,
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
                                      borderSide: BorderSide(
                                        color: Colors.red,
                                        width: 0.5,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.red,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingresa tu contraseña';
                                    }
                                    if (!Validator.validate(
                                      ValidatorType.passwordStrong,
                                      value,
                                    )) {
                                      return 'Contraseña no válida';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: responsive.hp(20)),
                                TextFormField(
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  keyboardType: TextInputType.visiblePassword,
                                  obscureText: !_isConfirmPasswordVisible,
                                  obscuringCharacter: '*',
                                  style: nunitoSansBodyMediumStyle(context),
                                  controller: _confirmPasswordController,
                                  decoration: InputDecoration(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isConfirmPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: hexOrRGBToColor("#7F8083"),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isConfirmPasswordVisible =
                                              !_isConfirmPasswordVisible;
                                        });
                                      },
                                    ),
                                    labelText:
                                        'Vuelve a escribir la contraseña',
                                    hintText: '*********',
                                    hintStyle: nunitoSansBodyMediumStyle(
                                      context,
                                      fontWeight: FontWeight.w200,
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
                                      borderSide: BorderSide(
                                        color: Colors.red,
                                        width: 0.5,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.red,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor confirma tu contraseña';
                                    }
                                    if (!Validator.validate(
                                      ValidatorType.passwordStrong,
                                      value,
                                    )) {
                                      return 'Contraseña no válida';
                                    }
                                    return null;
                                  },
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
                                      borderSide: BorderSide(
                                        color: Colors.red,
                                        width: 0.5,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.red,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingresa el código de verificación';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: responsive.hp(30)),

                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.lightModeBlue,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: responsive.wp(30),
                                      vertical: responsive.hp(10),
                                    ),
                                    disabledBackgroundColor:
                                        AppTheme.lightModeBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        responsive.wp(20),
                                      ),
                                    ),
                                  ),
                                  onPressed: !_isOperationInProgress
                                      ? () async {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            if (_passwordController.text !=
                                                _confirmPasswordController
                                                    .text) {
                                              ScaffoldMessenger.of(
                                                navigatorKey.currentContext!,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Las contraseñas no coinciden',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }
                                            setState(() {
                                              _isOperationInProgress = true;
                                            });

                                            final confirmData = {
                                              "email": widget.email,
                                              "password":
                                                  _passwordController.text,
                                              "code": _codeController.text,
                                            };

                                            if (kDebugMode) {
                                              print(
                                                "confirmData: $confirmData",
                                              );
                                            }

                                            try {
                                              final result =
                                                  await UsersApiService.confirmResetPassword(
                                                    confirmData,
                                                    "es",
                                                  );

                                              if (result['response'] ?? false) {
                                                setState(() {
                                                  _success = true;
                                                });
                                              } else {
                                                setState(() {
                                                  _success = false;
                                                });
                                                ScaffoldMessenger.of(
                                                  navigatorKey.currentContext!,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      result['message'],
                                                    ),
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
                                          'Guardar nueva contraseña',
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
                                SizedBox(height: responsive.hp(30)),
                                InkWell(
                                  onTap: () => Navigator.pop(context),
                                  child: Text(
                                    'Volver al login',
                                    style: nunitoSansLabelLargeStyle(
                                      context,
                                      fontWeight: FontWeight.w500,
                                      color: hexOrRGBToColor("#007AFF"),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]
                      : [
                          Text(
                            textAlign: TextAlign.center,
                            '¡Contraseña restablecida!',
                            style: nunitoSansTitleLargeStyle(context),
                          ),
                          Text(
                            textAlign: TextAlign.center,
                            'Excelentes noticias, tu contraseña ha sido restablecida. Ya puedes iniciar sesión con tu correo electrónico registrado.',
                            style: nunitoSansBodyMediumStyle(
                              context,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          SizedBox(height: responsive.hp(30)),

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
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Ir al login',
                              style: nunitoSansTitleSmallStyle(
                                context,
                                color: AppTheme.white950,
                                fontWeight: FontWeight.w600,
                              ),
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
}

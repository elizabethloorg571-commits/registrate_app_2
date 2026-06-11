import 'dart:async';
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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ForgotPasswordScreenState createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isOperationInProgress = false;
  bool isInvalidCode = false;
  String? codeErrorText;
  bool _sucess = false;

  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _secondsRemaining = 60;
    _timer?.cancel(); // Cancela si ya hay uno
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  void _resendEmail() {
    _sendEmail();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWaiting = _secondsRemaining > 0;
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
                    child: Image.asset('assets/images/registraTe-logo-horizontal.png', fit: BoxFit.contain),
                  ),
                ),
                SizedBox(height: responsive.hp(5)),
                Column(
                  children: !_sucess
                      ? [
                          Text(
                            textAlign: TextAlign.center,
                            '¿Olvidaste tu contraseña?',
                            style: nunitoSansTitleLargeStyle(context),
                          ),
                          Text(
                            textAlign: TextAlign.center,
                            'No te preocupes, ingresa tu correo electrónico y te enviaremos un código para restablecerla.',
                            style: nunitoSansBodyMediumStyle(
                              context,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          SizedBox(height: responsive.hp(20)),

                          TextFormField(
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            keyboardType: TextInputType.emailAddress,
                            style: nunitoSansStyle(400, 14),
                            controller: _emailController,
                            decoration: InputDecoration(
                              suffixIcon: isInvalidCode
                                  ? Icon(
                                      Icons.error,
                                      color: AppTheme.lightModeErrorRed,
                                    )
                                  : null,
                              labelText: 'Correo electrónico',
                              labelStyle: nunitoSansStyle(
                                400,
                                14,
                                color: Colors.grey.shade700,
                              ),
                              hintText: 'Tu correo electrónico registrado',
                              hintStyle: nunitoSansStyle(400, 14),
                              errorText: codeErrorText,
                              errorMaxLines: 2,
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
                                return 'Por favor ingresa tu correo electrónico';
                              }
                              if (!Validator.validate(
                                ValidatorType.email,
                                value,
                              )) {
                                return 'Correo electrónico no válido';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.lightModeBlue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 10,
                              ),
                              disabledBackgroundColor: AppTheme.lightModeBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: !_isOperationInProgress
                                ? _sendEmail
                                : null,
                            child: !_isOperationInProgress
                                ? Text(
                                    'Enviar enlace de restablecimiento',
                                    style: nunitoSansStyle(
                                      500,
                                      14,
                                      color: AppTheme.white950,
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
                          const SizedBox(height: 20),
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
                        ]
                      : [
                          Text(
                            textAlign: TextAlign.center,
                            '¡Correo electrónico enviado!',
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
                            _emailController.text.trim(),
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
                          SizedBox(height: responsive.hp(10)),
                          Text(
                            textAlign: TextAlign.center,
                            '¿No recibiste el correo electrónico?',
                            style: nunitoSansBodyMediumStyle(
                              context,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: responsive.hp(20)),
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
                            onPressed: () {},
                            // => Navigator.of(context).push(
                            //   MaterialPageRoute(
                            //     builder: (context) => ConfirmCodePassScreen(
                            //       email: _emailController.text.trim(),
                            //     ),
                            //   ),
                            // )
                            child: Text(
                              "Confirmar",
                              style: nunitoSansStyle(
                                500,
                                14,
                                color: AppTheme.white950,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: isWaiting ? null : _resendEmail,
                            child: isWaiting
                                ? Text(
                                    "Reenviar código en ${_secondsRemaining}s",
                                  )
                                : const Text("Reenviar enlace"),
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
                          SizedBox(height: responsive.hp(30)),
                          Text(
                            textAlign: TextAlign.center,
                            'El código de restablecimiento es válido por un tiempo limitado. Si no lo recibes en unos minutos, por favor, verifica tu dirección de correo electrónico y solicita nuevamente el código de confirmación',
                            style: nunitoSansBodySmallStyle(
                              context,
                              fontWeight: FontWeight.w300,
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

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isOperationInProgress = true;
        isInvalidCode = false;
        codeErrorText = null;
      });

      final resetData = {"email": _emailController.text.trim()};

      final result = await UsersApiService.resetPassword(resetData, "es");

      final isValid = result["status"] ?? false;

      if (!isValid) {
        setState(() {
          isInvalidCode = true;
          codeErrorText =
              "Ese correo no está registrado. Asegúrate de haberlo escrito bien o regístrate si aún no tienes cuenta.";
          _isOperationInProgress = false;
          _sucess = false;
        });
      } else {
        setState(() {
          _isOperationInProgress = false;
          isInvalidCode = false;
          codeErrorText = null;
          _sucess = true;
        });
        _startCountdown(); // ← Asegúrate de llamar esto aquí también
      }
    } catch (e) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text("Error: $e", style: nunitoSansStyle(400, 14)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isOperationInProgress = false;
      });
    }
  }
}

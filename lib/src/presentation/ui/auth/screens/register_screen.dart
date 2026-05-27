import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
// import 'package:flutter_intl_phone_field/country_picker_dialog.dart';
// import 'package:flutter_intl_phone_field/flutter_intl_phone_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:running_app/services/notification_service.dart';
import 'package:running_app/services/shared_service.dart';
import 'package:running_app/src/data/api/devices/devices_api_service.dart';
import 'package:running_app/src/data/api/users/users_api_service.dart';
import 'package:running_app/src/data/cache/shared_preferences_manager.dart';
import 'package:running_app/src/domain/models/device.dart';
import 'package:running_app/src/presentation/providers/inscriptions/inscriptions_provider.dart';
import 'package:running_app/src/presentation/providers/profile/profile_provider.dart';
import 'package:running_app/src/presentation/ui/auth/screens/confirm_email_screen.dart';
import 'package:running_app/src/presentation/widgets/global_widgets.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';
import 'package:running_app/config/theme/helpers/hex_color.dart';
import 'package:running_app/src/utils/image_utils.dart';
import 'package:running_app/src/utils/notification_permission_helper.dart';
import 'package:running_app/src/utils/user_data_utils.dart';
import 'package:running_app/src/utils/validator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.userData});

  final Map<String, dynamic>? userData;

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cellphoneController = TextEditingController();
  int? _documentType;
  final _documentNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _birthDateController = TextEditingController();
  DateTime? _selectedBirthDate;

  String _googleId = "";
  String _appleId = "";
  String _photoUrl = "";

  final List<DropdownMenuItem<int>> _documentTypes = [
    DropdownMenuItem(value: 1, child: Text('Cédula de identidad')),
    DropdownMenuItem(value: 2, child: Text('RUC')),
    DropdownMenuItem(value: 3, child: Text('Pasaporte')),
  ];

  bool _isOperationInProgress = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    _nameController.addListener(() {
      setState(() {});
    });
    _lastNameController.addListener(() {
      setState(() {});
    });
    _emailController.addListener(() {
      setState(() {});
    });

    if (widget.userData != null) {
      // Sanitizar los datos de usuario antes de usarlos
      final sanitizedData = UserDataUtils.sanitizeUserData(widget.userData);

      _nameController.text = sanitizedData['userName'] ?? "";
      _lastNameController.text = sanitizedData['userLastName'] ?? "";
      _emailController.text = sanitizedData['userEmail'] ?? "";
      _googleId = sanitizedData['googleId'] ?? "";
      _appleId = sanitizedData['appleId'] ?? "";
      _photoUrl = sanitizedData['userPhotoUrl'] ?? "";

      debugPrint('🔄 User data sanitized for registration');
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Registro", style: nunitoSansTitleLargeStyle(context)),
          centerTitle: false,
          elevation: 0,
        ),
        body: Padding(
          padding: GlobalWidgets.pagePadding(context),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 5),
                  _nameController.text.isNotEmpty &&
                          _lastNameController.text.isNotEmpty &&
                          _emailController.text.isNotEmpty
                      ? Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.all(0),
                              minVerticalPadding: 0,
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundColor: AppTheme.lightModeBlue,
                                backgroundImage:
                                    ImageUtils.getSafeImageProvider(
                                      imageUrl: _googleId.isEmpty
                                          ? null
                                          : _photoUrl,
                                      fallbackAsset:
                                          'assets/images/fan_app_user.png',
                                      debugContext:
                                          'RegisterScreen CircleAvatar',
                                    ),
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${_nameController.text} ${_lastNameController.text}",
                                    style: nunitoSansStyle(
                                      500,
                                      16,
                                      color: AppTheme.lightModeBlack,
                                    ),
                                  ),
                                  Text(
                                    _emailController.text,
                                    style: nunitoSansStyle(
                                      400,
                                      12,
                                      color: AppTheme.lightModeBlack,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        )
                      : const SizedBox.shrink(),

                  widget.userData == null
                      ? Column(
                          children: [
                            TextFormField(
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              keyboardType: TextInputType.name,
                              style: nunitoSansStyle(400, 14),
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Nombre',
                                labelStyle: nunitoSansStyle(
                                  400,
                                  14,
                                  color: Colors.grey.shade700,
                                ),
                                hintText: 'Ingresa tu nombre',
                                hintStyle: nunitoSansStyle(400, 14),
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
                                  return 'Por favor ingresa tu nombre';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        )
                      : const SizedBox(),

                  widget.userData == null
                      ? Column(
                          children: [
                            TextFormField(
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              keyboardType: TextInputType.name,
                              style: nunitoSansStyle(400, 14),
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Apellido',
                                labelStyle: nunitoSansStyle(
                                  400,
                                  14,
                                  color: Colors.grey.shade700,
                                ),
                                hintText: 'Ingresa tu apellido',
                                hintStyle: nunitoSansStyle(
                                  400,
                                  14,
                                  color: Colors.grey.shade700,
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
                                  return 'Por favor ingresa tu apellido';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        )
                      : const SizedBox(),

                  DropdownButtonFormField<int>(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    initialValue: _documentType,
                    items: _documentTypes,
                    onChanged: (int? value) {
                      setState(() {
                        _documentType = value;
                      });
                    },
                    style: nunitoSansStyle(400, 14),
                    decoration: InputDecoration(
                      labelText: 'Tipo de documento transaccional',
                      hintText: 'Selecciona tu tipo de documento',
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
                      if (value == null) {
                        return 'Por favor selecciona tu tipo de documento';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _documentType != null
                      ? Column(
                          children: [
                            TextFormField(
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              keyboardType: TextInputType.number,
                              style: nunitoSansStyle(400, 14),
                              controller: _documentNumberController,
                              maxLength: _documentType == 1
                                  ? 10
                                  : _documentType == 2
                                  ? 13
                                  : 20,
                              decoration: InputDecoration(
                                counter: const SizedBox.shrink(),
                                labelText:
                                    'Número de ${_documentType == 1
                                        ? 'cédula'
                                        : _documentType == 2
                                        ? 'RUC'
                                        : 'pasaporte'}',
                                labelStyle: nunitoSansStyle(
                                  400,
                                  14,
                                  color: Colors.grey.shade700,
                                ),
                                hintText:
                                    'Ingresa tu número de ${_documentType == 1
                                        ? 'cédula'
                                        : _documentType == 2
                                        ? 'RUC'
                                        : 'pasaporte'}',
                                hintStyle: nunitoSansStyle(400, 14),
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
                                  return 'Por favor ingresa tu número de documento';
                                }
                                if (!Validator.validate(
                                  _documentType == 1
                                      ? ValidatorType.cedula
                                      : _documentType == 2
                                      ? ValidatorType.ruc
                                      : ValidatorType.passport,
                                  value,
                                )) {
                                  return 'Número de ${_documentType == 1
                                      ? 'cédula'
                                      : _documentType == 2
                                      ? 'RUC'
                                      : 'pasaporte'} no válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        )
                      : const SizedBox.shrink(),

                  TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType: TextInputType.phone,
                    style: nunitoSansStyle(400, 14),
                    controller: _cellphoneController,
                    decoration: InputDecoration(
                      labelText: 'Celular',
                      labelStyle: nunitoSansStyle(
                        400,
                        14,
                        color: Colors.grey.shade700,
                      ),
                      hintText: 'Ingresa tu número de celular',
                      hintStyle: nunitoSansStyle(400, 14),
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
                      if (value != null && value.isNotEmpty) {
                        if (!Validator.validate(ValidatorType.celular, value)) {
                          return 'Número de celular no válido';
                        }
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    readOnly: true,
                    style: nunitoSansStyle(400, 14),
                    controller: _birthDateController,
                    decoration: InputDecoration(
                      labelText: 'Fecha de nacimiento',
                      labelStyle: nunitoSansStyle(
                        400,
                        14,
                        color: Colors.grey.shade700,
                      ),
                      hintText: 'Selecciona tu fecha de nacimiento',
                      hintStyle: nunitoSansStyle(400, 14),
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        color: Colors.grey.shade700,
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
                    onTap: () => _selectBirthDate(context),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor selecciona tu fecha de nacimiento';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  widget.userData == null
                      ? Column(
                          children: [
                            const Divider(color: Colors.grey, thickness: 0.5),
                            const SizedBox(height: 20),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.lightModeLightBlue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Requisito de contraseña: ",
                                      style: nunitoSansLabelLargeStyle(
                                        context,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          "mínimo 8 caracteres y debe contener una mezcla mayúsculas, minúsculas, números y caracteres especiales.",
                                      style: nunitoSansLabelLargeStyle(context),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        )
                      : const SizedBox(),

                  //email
                  widget.userData == null
                      ? Column(
                          children: [
                            TextFormField(
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              keyboardType: TextInputType.emailAddress,
                              style: nunitoSansStyle(400, 14),
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Correo electrónico',
                                labelStyle: nunitoSansStyle(
                                  400,
                                  14,
                                  color: Colors.grey.shade700,
                                ),
                                hintText: 'Ingresa tu correo electrónico',
                                hintStyle: nunitoSansStyle(400, 14),
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
                          ],
                        )
                      : const SizedBox(),

                  widget.userData == null
                      ? Column(
                          children: [
                            TextFormField(
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              keyboardType: TextInputType.visiblePassword,
                              obscureText: !_isPasswordVisible,
                              obscuringCharacter: '*',
                              style: nunitoSansStyle(400, 14),
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
                                labelStyle: nunitoSansStyle(
                                  400,
                                  14,
                                  color: Colors.grey.shade700,
                                ),
                                hintText: 'Ingresa tu contraseña',
                                hintStyle: nunitoSansStyle(400, 14),
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
                            const SizedBox(height: 20),
                            TextFormField(
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              keyboardType: TextInputType.visiblePassword,
                              obscureText: !_isConfirmPasswordVisible,
                              obscuringCharacter: '*',
                              style: nunitoSansStyle(400, 14),
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
                                labelText: 'Vuelve a escribir la contraseña',
                                labelStyle: nunitoSansStyle(
                                  400,
                                  14,
                                  color: Colors.grey.shade700,
                                ),
                                hintText: 'Ingresa tu contraseña',
                                hintStyle: nunitoSansStyle(400, 14),
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

                                if (value != _passwordController.text) {
                                  return 'Las contraseñas no coinciden';
                                }
                                return null;
                              },
                            ),
                          ],
                        )
                      : const SizedBox(),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lightModeBlue,
                        disabledBackgroundColor: AppTheme.lightModeBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      onPressed: _isOperationInProgress
                          ? null
                          : () => _register(),
                      child: !_isOperationInProgress
                          ? Text(
                              'Registrarme',
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
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_documentType != null &&
        _documentNumberController.text.trim().isEmpty) {
      GlobalWidgets.showBasicAlert(
        "Ingrese un número de documento",
        "El número de documento es un dato importante para la verificación de tu identidad y propiedad de tu mascota, además de dar validez a tus comprobantes electrónicos y facturas. Por favor ingresa un número de documento válido.",
        "Entendido",
      );
      return;
    }

    try {
      final navigatorState = Navigator.of(context);
      setState(() {
        _isOperationInProgress = true;
      });

      final Text documentWidget =
          _documentTypes[_documentType != null ? (_documentType! - 1) : 0].child
              as Text;
      final String documentType = parsedDocument(documentWidget.data!);

      // //TODO: Use complete number
      // // final celular = _completeNumber.replaceAll(" ", "");
      // final celular = _completeNumber.replaceAll(" ", "").padLeft(10, "0");
      final celular = _cellphoneController.text.trim();

      Map<String, dynamic> registerData = {
        "nombres": _nameController.text.trim(),
        "apellidos": _lastNameController.text.trim(),
        "num_documento": _documentNumberController.text.trim(),
        "tipo_documento": documentType,
        "foto": _photoUrl,
        // "facebook_id": facebookId,
        "google_id": _googleId,
        "apple_id": _appleId,
        "email": _emailController.text.trim(),
        "password": _passwordController.text.trim(),
        // "celular": celular,
        "celular": celular,
        "birth_date": _selectedBirthDate?.toIso8601String(),
      };

      if (widget.userData != null) {
        registerData.remove("password");
      }

      Map<String, dynamic> invoiceData = {
        "nombres": _nameController.text.trim(),
        "apellidos": _lastNameController.text.trim(),
        "tipo_documento": documentType,
        "num_documento": _documentNumberController.text.trim(),
        "email": _emailController.text.trim(),
        "celular": celular,
        "birth_date": _selectedBirthDate?.toIso8601String(),
      };

      if (_documentType == null) {
        registerData.remove("tipo_documento");
        registerData.remove("num_documento");
        invoiceData.remove("tipo_documento");
        invoiceData.remove("num_documento");
      }

      registerData.addAll({"datos_facturacion": invoiceData});

      // log(jsonEncode(registerData));
      // setState(() {
      //   _isOperationInProgress = false;
      // });
      // return;

      final result = await UsersApiService.register(registerData, "es");

      if (result["response"] ?? false) {
        await SharedPreferencesManager.setFields(
          stringFields: {
            "nombres": _nameController.text.trim(),
            "apellidos": _lastNameController.text.trim(),
            "num_documento": _documentNumberController.text.trim(),
            "email": _emailController.text.trim(),
            "fecha_nacimiento": _selectedBirthDate?.toIso8601String() ?? "",
            "celular": celular,
            "tipo": "cliente",
          },
          boolFields: {"hasLoggedIn": true, "isLoggedIn": true},
        );

        final Map<String, dynamic> loginData = {
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
        };

        if (widget.userData == null) {
          navigatorState.push(
            MaterialPageRoute(
              builder: (context) => ConfirmEmailScreen(loginData: loginData),
            ),
          );
        } else {
          loginData.remove("password");
          loginData.remove("email");
          loginData["userId"] = widget.userData!['userId'];
          if (_googleId != "") {
            loginData["google_id"] = _googleId;
          }

          if (_appleId != "") {
            loginData["apple_id"] = _appleId;
          }

          final loginResult = await UsersApiService.login(loginData, "es");
          if (loginResult["response"] ?? false) {
            await onLoginSuccess(loginResult);
          } else {
            final msg =
                loginResult["message"] ??
                loginResult["error"] ??
                "Error al intentar el registro";
            await GlobalWidgets.showBasicAlert(
              "Error: $msg",
              "Intenta el inicio de sesión manualmente",
              "Entendido",
            );
          }

          navigatorState.pop();
        }
      } else {
        await GlobalWidgets.showBasicAlert(
          "Error",
          result["message"] ??
              result["error"] ??
              "Error al intentar el registro",
          "Entendido",
        );
      }
      setState(() {
        _isOperationInProgress = false;
      });
    } catch (e) {
      SnackBar(
        content: Text("Error: $e", style: nunitoSansStyle(400, 14)),
        backgroundColor: Colors.red,
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
    try {
      await NotificationService.instance.ensureRegisteredForSignedInUser(
        userId: SharedService.uuid,
      );
    } catch (_) {}
    await _addDeviceData();

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

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate =
        _selectedBirthDate ?? DateTime(now.year - 18, now.month, now.day);
    final DateTime firstDate = DateTime(1900);
    final DateTime lastDate = now;

    final DateTime? picked = await showPlatformDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      material: (_, _) => MaterialDatePickerData(
        helpText: 'Selecciona tu fecha de nacimiento',
        cancelText: 'Cancelar',
        confirmText: 'Aceptar',
      ),
      cupertino: (_, _) =>
          CupertinoDatePickerData(mode: CupertinoDatePickerMode.date),
    );

    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  String parsedDocument(String documentType) {
    switch (documentType) {
      case 'Cédula de identidad':
        return "cedula";
      case 'RUC':
        return "ruc";
      case 'Pasaporte':
        return "pasaporte";
      default:
        return "";
    }
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

class EcuadorPhoneNumberFormatter extends TextInputFormatter {
  @override
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip non-digits
    String digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limit to 9 digits
    if (digitsOnly.length > 9) {
      digitsOnly = digitsOnly.substring(0, 9);
    }

    // Format: 00 000 0000
    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 2 || i == 5) buffer.write(' ');
      buffer.write(digitsOnly[i]);
    }

    final formatted = buffer.toString();

    // Maintain cursor at end
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

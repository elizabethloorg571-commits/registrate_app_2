import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:running_app/app_localizations_context.dart';
import 'package:running_app/services/shared_service.dart';
import 'package:running_app/src/data/api/users/users_api_service.dart';
import 'package:running_app/src/domain/models/user.dart';
import 'package:running_app/src/presentation/providers/profile/profile_provider.dart';
import 'package:running_app/src/presentation/widgets/global_widgets.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';
import 'package:running_app/src/utils/validator.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final User user;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cellphoneController = TextEditingController();
  int? _documentType;
  final _documentNumberController = TextEditingController();

  final List<DropdownMenuItem<int>> _documentTypes = [
    const DropdownMenuItem(value: 1, child: Text('Cédula de identidad')),
    const DropdownMenuItem(value: 2, child: Text('RUC')),
    const DropdownMenuItem(value: 3, child: Text('Pasaporte')),
  ];

  bool _isOperationInProgress = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.nombres;
    _lastNameController.text = widget.user.apellidos;
    _cellphoneController.text = widget.user.celular;
    // Convertir el string del tipo de documento a int
    if (widget.user.tipoDocumento == 'cedula') {
      _documentType = 1;
    } else if (widget.user.tipoDocumento == 'ruc') {
      _documentType = 2;
    } else if (widget.user.tipoDocumento == 'pasaporte') {
      _documentType = 3;
    }
    _documentNumberController.text = widget.user.numDocumento;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _cellphoneController.dispose();
    _documentNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isOperationInProgress = true;
    });

    try {
      // Convertir el tipo de documento a string
      String tipoDocumento = '';
      if (_documentType == 1) {
        tipoDocumento = 'cedula';
      } else if (_documentType == 2) {
        tipoDocumento = 'ruc';
      } else if (_documentType == 3) {
        tipoDocumento = 'pasaporte';
      }

      final userData = {
        'nombres': _nameController.text.trim(),
        'apellidos': _lastNameController.text.trim(),
        'celular': _cellphoneController.text.trim(),
        'tipo_documento': tipoDocumento,
        'num_documento': _documentNumberController.text.trim(),
      };

      final result = await UsersApiService.updateUser(userData);

      if (result['response'] ?? false) {
        // Actualizar la URL de la foto en SharedService y en el provider
        final data = result['data'] ?? {};
        final dateNow = DateTime.now();
        SharedService.photoUrl = data["foto"];
        SharedService.userUpdatedAt = dateNow.toString();

        // Invalidar el provider para recargar los datos
        ref.invalidate(userProfileProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l1on.profileUpdatedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ??
                    result['error'] ??
                    context.l1on.errorUpdatingProfile,
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l1on.errorUpdatingProfile),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOperationInProgress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.l1on.editProfile,
            style: nunitoSansTitleLargeStyle(
              context,
              fontWeight: FontWeight.w600,
            ),
          ),
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
                  const SizedBox(height: 20),

                  // Nombre
                  TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType: TextInputType.name,
                    style: nunitoSansStyle(400, 14),
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: context.l1on.name,
                      labelStyle: nunitoSansStyle(
                        400,
                        14,
                        color: Colors.grey.shade700,
                      ),
                      hintText: context.l1on.enterYourName,
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
                      errorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 0.5),
                      ),
                      focusedErrorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 0.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.l1on.pleaseEnterYourName;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Apellido
                  TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType: TextInputType.name,
                    style: nunitoSansStyle(400, 14),
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: context.l1on.lastName,
                      labelStyle: nunitoSansStyle(
                        400,
                        14,
                        color: Colors.grey.shade700,
                      ),
                      hintText: context.l1on.enterYourLastName,
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
                      errorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 0.5),
                      ),
                      focusedErrorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 0.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.l1on.pleaseEnterYourLastName;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Tipo de documento
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
                      hintText: context.l1on.selectYourDocumentType,
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
                      errorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 0.5),
                      ),
                      focusedErrorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 0.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null) {
                        return context.l1on.pleaseSelectYourDocumentType;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Número de documento
                  if (_documentType != null)
                    Column(
                      children: [
                        TextFormField(
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.text,
                          style: nunitoSansStyle(400, 14),
                          controller: _documentNumberController,
                          maxLength: _documentType == 1
                              ? 10
                              : _documentType == 2
                              ? 13
                              : 20,
                          decoration: InputDecoration(
                            counter: const SizedBox.shrink(),
                            labelText: _documentType == 1
                                ? context.l1on.idNumber
                                : _documentType == 2
                                ? context.l1on.rucNumber
                                : context.l1on.passportNumber,
                            labelStyle: nunitoSansStyle(
                              400,
                              14,
                              color: Colors.grey.shade700,
                            ),
                            hintText: _documentType == 1
                                ? context.l1on.enterYourIdNumber
                                : _documentType == 2
                                ? context.l1on.enterYourRucNumber
                                : context.l1on.enterYourPassportNumber,
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
                            errorBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 0.5,
                              ),
                            ),
                            focusedErrorBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 0.5,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.l1on.pleaseEnterYourDocumentNumber;
                            }
                            if (!Validator.validate(
                              _documentType == 1
                                  ? ValidatorType.cedula
                                  : _documentType == 2
                                  ? ValidatorType.ruc
                                  : ValidatorType.passport,
                              value,
                            )) {
                              return _documentType == 1
                                  ? context.l1on.invalidIdNumber
                                  : _documentType == 2
                                  ? context.l1on.invalidRucNumber
                                  : context.l1on.invalidPassportNumber;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),

                  // Celular
                  TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType: TextInputType.phone,
                    style: nunitoSansStyle(400, 14),
                    controller: _cellphoneController,
                    decoration: InputDecoration(
                      labelText: context.l1on.cellphone,
                      labelStyle: nunitoSansStyle(
                        400,
                        14,
                        color: Colors.grey.shade700,
                      ),
                      hintText: context.l1on.enterYourCellphone,
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
                      errorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 0.5),
                      ),
                      focusedErrorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 0.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.l1on.pleaseEnterYourCellphone;
                      }
                      if (!Validator.validate(ValidatorType.celular, value)) {
                        return context.l1on.invalidCellphone;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 40),

                  // Botón Guardar
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isOperationInProgress
                          ? null
                          : _handleUpdateProfile,
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: _isOperationInProgress
                              ? LinearGradient(
                                  colors: [
                                    AppTheme.primary900.withValues(alpha: 0.5),
                                    AppTheme.secondary.withValues(alpha: 0.5),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : LinearGradient(
                                  colors: [
                                    AppTheme.primary900,
                                    AppTheme.secondary,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                        ),
                        child: Center(
                          child: _isOperationInProgress
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  context.l1on.save,
                                  style: nunitoSansTitleSmallStyle(
                                    context,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:running_app/app_localizations_context.dart';
import 'package:running_app/extensions/string_extensions.dart';
import 'package:running_app/services/shared_service.dart';
import 'package:running_app/src/data/api/users/users_api_service.dart';
import 'package:running_app/src/domain/models/user.dart';
import 'package:running_app/src/presentation/providers/profile/profile_provider.dart';
import 'package:running_app/src/presentation/ui/profile/edit_profile_screen.dart';
import 'package:running_app/src/presentation/ui/profile/utils/profile_svg_files.dart';
import 'package:running_app/src/presentation/widgets/global_widgets.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';
import 'package:running_app/src/utils/navigator_key.dart';
import 'package:running_app/src/utils/validator.dart';

enum ProcessType { accountSuspension, accountDeletion }

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key, required this.user});

  final User user;

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l1on.account,
          style: nunitoSansTitleLargeStyle(
            context,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: GlobalWidgets.pagePadding(context),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(user: widget.user),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Nombre
                    _buildInfoTile(
                      label: context.l1on.name,
                      value:
                          '${widget.user.nombres.capitalize()} ${widget.user.apellidos.capitalize()}',
                    ),

                    // Correo electrónico
                    _buildInfoTile(
                      label: context.l1on.email,
                      value: widget.user.email,
                    ),

                    // Contraseña
                    _buildInfoTile(
                      label: context.l1on.password,
                      value: '******',
                      showChevron: true,
                    ),

                    // // Género
                    // _buildInfoTile(
                    //   label: 'Género',
                    //   value: widget.user.genero,
                    // ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botón eliminar cuenta
            InkWell(
              onTap: () {
                _showDeleteAccountDialog(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    SvgPicture.string(kDeleteIconSvg, width: 20, height: 20),
                    const SizedBox(width: 16),
                    Text(
                      context.l1on.deleteAccount,
                      style: nunitoSansTitleSmallStyle(
                        context,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    bool showChevron = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: nunitoSansBodyMediumStyle(
                context,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: nunitoSansBodyMediumStyle(
                      context,
                      color: Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showChevron) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                context.l1on.deleteAccountTitle,
                style: nunitoSansTitleMediumStyle(
                  context,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                context.l1on.deleteAccountWarning,
                style: nunitoSansBodyMediumStyle(
                  context,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                context.l1on.deleteAccountDescription,
                style: nunitoSansBodyMediumStyle(
                  context,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                context.l1on.deleteAccountNote,
                style: nunitoSansBodyMediumStyle(
                  context,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),

              // Botón Eliminar cuenta
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAccountDeletionDialog(ProcessType.accountDeletion);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [AppTheme.primary900, AppTheme.secondary],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        context.l1on.deleteAccount,
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
              const SizedBox(height: 12),

              // Botón Cancelar
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary900, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        context.l1on.cancel,
                        style: nunitoSansTitleSmallStyle(
                          context,
                          color: AppTheme.primary900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAccountDeletionDialog(ProcessType processType) async {
    await showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: Text(
          processType == ProcessType.accountDeletion
              ? "Eliminar Cuenta"
              : "Suspender Cuenta",
          style: nunitoSansTitleSmallStyle(context),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                "Por favor, ingrese su contraseña para validar la ${processType == ProcessType.accountDeletion ? "eliminación" : "suspensión"} de su cuenta.",
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 10),
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.visiblePassword,
                style: nunitoSansBodySmallStyle(
                  context,
                  fontWeight: FontWeight.w400,
                ),
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: nunitoSansBodySmallStyle(
                    context,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade700,
                  ),
                  hintText: 'Ingresa tu contraseña',
                  hintStyle: nunitoSansBodySmallStyle(
                    context,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade500,
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
                  if (value != null && value.isNotEmpty) {
                    if (!Validator.validate(
                      ValidatorType.passwordStrong,
                      value,
                    )) {
                      return 'Contraseña no válida';
                    }
                  }

                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              context.l1on.cancel,
              style: nunitoSansLabelMediumStyle(context),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAccount(processType);
            },
            child: Text(
              processType == ProcessType.accountDeletion
                  ? context.l1on.delete
                  : context.l1on.suspend,
              style: nunitoSansLabelMediumStyle(context, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(ProcessType processType) async {
    final navigatorState = Navigator.of(context);
    final password = passwordController.text;

    if (password.isEmpty) {
      GlobalWidgets.showBasicAlert(
        processType == ProcessType.accountDeletion
            ? 'Eliminar cuenta'
            : 'Suspender cuenta',
        "Por favor, ingrese su contraseña para continuar.",
        "Aceptar",
      );
      return;
    }

    final result = await UsersApiService.login({
      "email": SharedService.email.trim(),
      "password": password,
    }, "es");

    if (result["response"] ?? false) {
      final result2 = processType == ProcessType.accountDeletion
          ? await UsersApiService.deleteUserComplete()
          : await UsersApiService.deleteUserComplete();

      if (result2["response"] ?? false) {
        await GlobalWidgets.showBasicAlert(
          "Cuenta ${processType == ProcessType.accountDeletion ? "Eliminada" : "Suspendida"}",
          "Su cuenta ha sido ${processType == ProcessType.accountDeletion ? "eliminada" : "suspendida"} exitosamente.",
          "Aceptar",
        );
        await SharedService.logOut();
        ref.invalidate(userProfileProvider);

        // Cerrar el dialog de confirmación de password
        navigatorState.pop();
        // Cerrar AccountDeletionScreen
        navigatorState.pop();

        // El HomeScreen se reconstruirá automáticamente y mostrará LoginView
        // porque userUuidProvider fue invalidado
      } else {
        await GlobalWidgets.showBasicAlert(
          "Error",
          "Ha ocurrido un error al intentar ${processType == ProcessType.accountDeletion ? "eliminar" : "suspender"} su cuenta.",
          "Aceptar",
        );
        navigatorState.pop();
      }
    } else {
      await GlobalWidgets.showBasicAlert(
        "Error",
        "Por favor, ingrese su contraseña correctamente.",
        "Aceptar",
      );
      navigatorState.pop();
    }
  }
}

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';
import 'package:running_app/services/image_fix_service.dart';
import 'package:running_app/services/image_picker_service.dart';
import 'package:running_app/src/utils/navigator_key.dart';
import 'package:share_plus/share_plus.dart';

class GlobalWidgets {
  static AppBar customAppBar(
    BuildContext context, {
    String title = '',
    bool showBackButton = true,
    bool centerTitle = false,
    Color? backgroundColor,
    Color? foregroundColor,
    Function()? onBackButtonPressed,
  }) {
    return AppBar(
      backgroundColor: backgroundColor ?? AppTheme.white950,
      foregroundColor: foregroundColor ?? AppTheme.lightModeBlack,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: title.isNotEmpty
          ? Text(title, style: nunitoSansTitleMediumStyle(context))
          : null,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left_outlined),
        onPressed:
            onBackButtonPressed ?? () => Navigator.of(context).pop(false),
      ),
      centerTitle: false,
    );
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // regla simple: si el ancho es >= 600dp lo tratamos como tablet
    final bool isTablet = screenWidth >= 600;

    if (isTablet) {
      return const EdgeInsets.only(left: 96, right: 96, top: 48);
    } else {
      return const EdgeInsets.only(left: 16, right: 16, top: 8);
    }
  }

  static Future<bool> showConfirmationModal(
    BuildContext context, {
    String title = '¿Desea eliminar?',
    String content = '¿Está seguro de que desea eliminar este elemento?',
    String confirmText = 'Eliminar',
    String cancelText = 'Cancelar',
    Widget icon = const Icon(CupertinoIcons.delete, color: Colors.red),
    double height = 200,
  }) async {
    return await showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return SizedBox(
              height: height,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    icon,
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: nunitoSansTitleMediumStyle(
                        context,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      content,
                      textAlign: TextAlign.center,
                      style: nunitoSansBodySmallStyle(
                        context,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.lightModeErrorRed,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          confirmText,
                          style: nunitoSansTitleSmallStyle(
                            context,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cardsBackground,
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          cancelText,
                          style: nunitoSansTitleSmallStyle(
                            context,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;
  }

  static SizedBox circularProgressIndicator({
    Color? color,
    double radius = 20,
  }) {
    return SizedBox(
      width: radius,
      height: radius,
      child: FittedBox(
        child: PlatformCircularProgressIndicator(
          cupertino: (_, _) => CupertinoProgressIndicatorData(color: color),
          material: (_, _) => MaterialProgressIndicatorData(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppTheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  static ButtonStyle elevatedButtonStyleWithPrimaryColor = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll<Color>(AppTheme.primary),
    shadowColor: WidgetStatePropertyAll<Color>(AppTheme.grey),
    shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
    ),
  );

  // DIALOGS AND MODALS

  static bool _isPickingImage = false;
  static Future<void> showBasicAlert(
    String title,
    String message,
    String acceptText,
  ) async {
    await showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => PlatformAlertDialog(
        title: Text(title),
        content: Text(message, style: const TextStyle(color: Colors.black)),
        actions: [
          PlatformDialogAction(
            child: Text(
              acceptText,
              style: const TextStyle(color: Colors.black),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  static void showAlertWithCustomContent(
    Widget content,
    String title,
    String acceptText,
  ) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => PlatformAlertDialog(
        title: Text(title),
        content: content,
        actions: [
          PlatformDialogAction(
            child: Text(acceptText),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  static void showBasicAlertWithCustomTitle(
    String message,
    String title,
    String okText,
  ) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => PlatformAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          PlatformDialogAction(
            child: Text(okText),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  static Future<void> showAlertConfirmation(
    String title,
    String message,
    PlatformDialogAction cancelButton,
    PlatformDialogAction acceptButton,
  ) async {
    await showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => PlatformAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [acceptButton, cancelButton],
      ),
    );
  }

  static Future<void> showActionConfirmation(
    String title,
    String message,
    PlatformDialogAction acceptButton,
  ) async {
    await showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => PlatformAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [acceptButton],
      ),
    );
  }

  static void showAConfirmation(
    String title,
    String message,
    String negativeText,
    PlatformDialogAction acceptButton,
  ) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => PlatformAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          PlatformDialogAction(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: Text(negativeText),
          ),
          acceptButton,
        ],
      ),
    );
  }

  static Future<XFile?> imagePickerCropperAlertClassic(
    double ratioX,
    double ratioY,
  ) async {
    return await showPlatformDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text("Por favor, ingrese una imagen"),
          content: SizedBox(
            height: MediaQuery.of(context).size.height / 6,
            child: Column(
              children: [
                ElevatedButton.icon(
                  style: GlobalWidgets.elevatedButtonStyleWithPrimaryColor,
                  onPressed: _isPickingImage
                      ? null
                      : () async {
                          if (_isPickingImage) return;
                          _isPickingImage = true;
                          final navigatorState = Navigator.of(context);
                          try {
                            final image =
                                await ImagePickerService.getImageFromCamera();
                            if (image != null) {
                              navigatorState.pop(XFile(image.path));
                            } else {
                              navigatorState.pop();
                            }
                          } catch (e) {
                            navigatorState.pop();
                          } finally {
                            _isPickingImage = false;
                          }
                        },
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text(
                    "Desde la cámara",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton.icon(
                  style: GlobalWidgets.elevatedButtonStyleWithPrimaryColor,
                  onPressed: _isPickingImage
                      ? null
                      : () async {
                          if (_isPickingImage) return;
                          _isPickingImage = true;
                          final navigatorState = Navigator.of(context);
                          try {
                            final image =
                                await ImagePickerService.getImageFromGallery();
                            if (image != null) {
                              navigatorState.pop(XFile(image.path));
                            } else {
                              navigatorState.pop();
                            }
                          } catch (e) {
                            navigatorState.pop();
                          } finally {
                            _isPickingImage = false;
                          }
                        },
                  icon: const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Desde la galería",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<XFile?> imagePickerCropperModal(
    double ratioX,
    double ratioY,
  ) async {
    return await showModalBottomSheet(
      context: navigatorKey.currentContext!,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height / 4,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Editar foto de perfil",
                    style: nunitoSansTitleMediumStyle(context),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(Icons.add_photo_alternate_outlined),
                    title: const Text(
                      "Seleccionar de la galería",
                      style: TextStyle(fontSize: 14),
                    ),
                    onTap: _isPickingImage
                        ? null
                        : () async {
                            if (_isPickingImage) return;
                            _isPickingImage = true;
                            final navigatorState = Navigator.of(context);
                            try {
                              final image =
                                  await ImagePickerService.getImageFromGallery();
                              if (image != null) {
                                navigatorState.pop(XFile(image.path));
                              } else {
                                navigatorState.pop();
                              }
                            } catch (e) {
                              navigatorState.pop();
                            } finally {
                              _isPickingImage = false;
                            }
                          },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_a_photo_outlined),
                    title: const Text(
                      "Tomar una foto",
                      style: TextStyle(fontSize: 14),
                    ),
                    onTap: _isPickingImage
                        ? null
                        : () async {
                            if (_isPickingImage) return;
                            _isPickingImage = true;
                            final navigatorState = Navigator.of(context);
                            try {
                              final image =
                                  await ImagePickerService.getImageFromCamera();
                              if (image != null) {
                                final imageFile = File(image.path);
                                final fixedFile =
                                    await fixImageOrientationAndSave(imageFile);
                                navigatorState.pop(XFile(fixedFile.path));
                              } else {
                                navigatorState.pop();
                              }
                            } catch (e) {
                              navigatorState.pop();
                            } finally {
                              _isPickingImage = false;
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

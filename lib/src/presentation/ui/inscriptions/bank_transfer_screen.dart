import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';
import 'package:running_app/marketplace/data/api/constants.dart';
import 'package:running_app/services/image_upload_service.dart';
import 'package:running_app/services/shared_service.dart';

import 'package:running_app/src/domain/models/bank_transfer_info.dart';
import 'package:running_app/src/utils/http_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/constants/constants.dart';

class BankTransferPaymentScreen extends StatefulWidget {
  const BankTransferPaymentScreen({
    super.key,
    required this.bankInfo,
    required this.total,
    required this.orderId,
    this.isFromMarketplace = false,
  });

  final BankTransferInfo bankInfo;
  final double total;
  final String orderId;
  final bool isFromMarketplace;

  @override
  State<BankTransferPaymentScreen> createState() =>
      _BankTransferPaymentScreenState();
}

class _BankTransferPaymentScreenState extends State<BankTransferPaymentScreen> {
  XFile? _pickedFile;
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (file != null) {
      setState(() => _pickedFile = file);
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppTheme.primary,
                  ),
                ),
                title: Text(
                  'Tomar foto',
                  style: nunitoSansStyle(
                    600,
                    15,
                    color: AppTheme.lightModeBlack,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: AppTheme.primary,
                  ),
                ),
                title: Text(
                  'Elegir de galería',
                  style: nunitoSansStyle(
                    600,
                    15,
                    color: AppTheme.lightModeBlack,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_pickedFile == null) return;

    // Validate format: only JPG and PNG allowed
    final ext = _pickedFile!.name.split('.').last.toLowerCase();
    if (ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo se permiten imágenes JPG o PNG'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Step 1: Upload image to S3
      final format = (ext == 'jpeg') ? 'jpg' : ext;
      final path = '${SharedService.uuid}/comprobantes';
      final imageName = 'comprobante_${widget.orderId}';

      final uploadService = ImageUploadService();
      final uploadResult = await uploadService.uploadImageWithDetails(
        _pickedFile!,
        path,
        imageName,
        format,
      );

      if (!mounted) return;

      if (!uploadResult.success || uploadResult.uploadedUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              uploadResult.errorMessage ?? 'Error al subir el comprobante',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final photoUrl = uploadResult.uploadedUrl!;

      // Step 2: PUT order with voucher
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final endpoint =
          '${widget.isFromMarketplace ? MarketplaceConstants.orderUpdateUrl : ApiConstants.inscriptionsUpdate}/${widget.orderId}';
      final url = Uri.parse(endpoint);
      log("url: $url");
      final headers = {
        'Authorization': token,
        'Content-Type': 'application/json',
      };
      log("headers: $headers");
      final body = jsonEncode({'voucher': photoUrl});
      log("body: $body");
      final response = await HttpUtils.put(url, headers: headers, body: body);
      log("response body: ${response.body}");

      if (!mounted) return;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final success = decoded['response'] == true || response.statusCode == 200;

      if (!success) {
        final msg =
            decoded['message']?.toString() ??
            'Error al registrar el comprobante';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
        return;
      }

      Navigator.of(context).pop({'response': true, 'url': photoUrl});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.inscriptionsBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.inscriptionsBackground,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.lightModeBlack),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: Text(
          'Transferencia Bancaria',
          style: nunitoSansStyle(600, 18, color: AppTheme.lightModeBlack),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Realiza la transferencia desde tu banca móvil y sube el comprobante aquí para confirmar tu pago.',
                      style: nunitoSansStyle(
                        400,
                        13,
                        color: AppTheme.lightModeBlack,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bank destination card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Banco Destino',
                        style: nunitoSansStyle(
                          400,
                          12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.bankInfo.banckName,
                        style: nunitoSansStyle(700, 16, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Account details card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  // Account number row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Número de cuenta',
                            style: nunitoSansStyle(
                              400,
                              12,
                              color: AppTheme.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.bankInfo.accountNumber,
                            style: nunitoSansStyle(
                              700,
                              17,
                              color: AppTheme.lightModeBlack,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: widget.bankInfo.accountNumber),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Número de cuenta copiado'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.copy_rounded,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Type + document row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tipo de cuenta',
                              style: nunitoSansStyle(
                                400,
                                12,
                                color: AppTheme.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.bankInfo.accountType,
                              style: nunitoSansStyle(
                                600,
                                14,
                                color: AppTheme.lightModeBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Documento',
                              style: nunitoSansStyle(
                                400,
                                12,
                                color: AppTheme.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.bankInfo.documentNumber,
                              style: nunitoSansStyle(
                                600,
                                14,
                                color: AppTheme.lightModeBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Holder name
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nombre del titular',
                            style: nunitoSansStyle(
                              400,
                              12,
                              color: AppTheme.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.bankInfo.accountHoldersName.toUpperCase(),
                            style: nunitoSansStyle(
                              700,
                              14,
                              color: AppTheme.lightModeBlack,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Comprobante section
            Text(
              'Comprobante de pago',
              style: nunitoSansStyle(700, 15, color: AppTheme.lightModeBlack),
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _showPickerOptions,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 160),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _pickedFile != null
                        ? AppTheme.primary
                        : AppTheme.grey.withValues(alpha: 0.5),
                    width: _pickedFile != null ? 2 : 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _pickedFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Stack(
                          children: [
                            Image.file(
                              File(_pickedFile!.path),
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _pickedFile = null),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  color: AppTheme.primary,
                                  size: 32,
                                ),
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primary,
                                          AppTheme.secondary,
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Subir o tomar foto',
                            style: nunitoSansStyle(
                              600,
                              14,
                              color: AppTheme.lightModeBlack,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Formatos: JPG o PNG (Máx. 5MB)',
                            style: nunitoSansStyle(
                              400,
                              12,
                              color: AppTheme.grey,
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          color: Colors.white,
          child: InkWell(
            onTap: _isUploading ? null : _submit,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: _isUploading || _pickedFile == null
                    ? null
                    : LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                color: _isUploading || _pickedFile == null
                    ? AppTheme.grey.withValues(alpha: 0.3)
                    : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: _isUploading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Continuar y guardar',
                            style: nunitoSansStyle(
                              700,
                              16,
                              color: _pickedFile == null
                                  ? AppTheme.grey
                                  : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: _pickedFile == null
                                ? AppTheme.grey
                                : Colors.white,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

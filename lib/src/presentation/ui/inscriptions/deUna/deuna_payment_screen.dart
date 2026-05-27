import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:running_app/src/data/api/inscriptions/inscriptions_api_service.dart';
import 'package:running_app/src/presentation/ui/profile/utils/money_utils.dart';
import 'package:running_app/src/presentation/widgets/global_widgets.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';
import 'package:running_app/src/utils/navigator_key.dart';
import 'package:running_app/src/utils/url_launcher_utils.dart';

class DeUnaPaymentScreen extends StatefulWidget {
  const DeUnaPaymentScreen({
    super.key,
    required this.data,
    required this.total,
    this.isAbonado = false,
  });

  final Map<String, dynamic> data;
  final num total;
  final bool isAbonado;
  @override
  DeUnaPaymentScreenState createState() => DeUnaPaymentScreenState();
}

class DeUnaPaymentScreenState extends State<DeUnaPaymentScreen> {
  Map<String, dynamic> get _data => widget.data;
  // bool _showVerificationButton = true;

  // @override
  // void initState() {
  //   Future.delayed(const Duration(seconds: 5), () {
  //     setState(() {
  //       _showVerificationButton = true;
  //     });
  //   });
  //   super.initState();
  // }

  Map<String, dynamic>? data;
  bool _isVeryfing = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        leading: IconButton(
          icon: Icon(context.platformIcons.back),
          onPressed: () {
            Navigator.of(context).pop(data);
          },
        ),
        title: FittedBox(
          child: Text(
            'Pagar con Deuna',
            style: nunitoSansTitleLargeStyle(context),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text(
              MoneyUtils.formatCurrency(widget.total),
              style: nunitoSansTitleLargeStyle(
                context,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: GlobalWidgets.pagePadding(context),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Image.asset('assets/images/deuna.png', height: size.height * 0.05),
            const SizedBox(height: 30),
            RichText(
              textAlign: TextAlign.justify,
              text: TextSpan(
                style: nunitoSansLabelLargeStyle(context),
                children: [
                  TextSpan(text: 'Presiona el botón para transferir con '),
                  TextSpan(
                    text: 'Deuna ',
                    style: nunitoSansLabelLargeStyle(
                      context,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: 'o escanea el '),
                  TextSpan(
                    text: 'código QR ',
                    style: nunitoSansLabelLargeStyle(
                      context,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: 'con otro dispositivo.'),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.lightModeLightBlue,
                borderRadius: BorderRadius.circular(10),
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.grey.withValues(alpha: 0.3),
                //     spreadRadius: 1,
                //     blurRadius: 2,
                //     offset: const Offset(0, 2),
                //   ),
                // ],
              ),
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Verifica tu pago',
                    style: nunitoSansLabelMediumStyle(
                      context,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2.5),
                  Text(
                    'Una vez realizado, recuerda volver a esta pantalla para verificar el pago.',
                    style: nunitoSansLabelMediumStyle(
                      context,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Container(
              height: size.height * 0.22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.7),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(15),
              child: PrettyQrView.data(
                data: _data['deeplink'] ?? '',
                // decoration: const PrettyQrDecoration(
                //   image: PrettyQrDecorationImage(
                //     image: AssetImage('assets/images/${Global.clubKey}/team_logo.png'),
                //   ),
                // ),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.deunaButtonColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 10,
                    ),
                    disabledBackgroundColor: AppTheme.lightModeBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    UrlLauncherUtils.launch(_data['deeplink'] ?? '');
                  },
                  child: Text(
                    'Pagar con Deuna',
                    style: nunitoSansTitleSmallStyle(
                      context,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightModeBlue,
                      disabledBackgroundColor: AppTheme.lightModeBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: !_isVeryfing
                        ? () async {
                            setState(() {
                              _isVeryfing = true;
                            });
                            try {
                              final navigatorState = Navigator.of(context);

                              final paymentData = {
                                "idTransactionReference":
                                    _data['transactionId'] ?? '',
                                "idType": "0",
                                "abonado": true,
                              };

                              final result =
                                  await InscriptionsApiService.requestDeUnaPaymentInfo(
                                    paymentData,
                                  );
                              if (result['response'] ?? false) {
                                data = result['data'] ?? {};

                                final String status =
                                    data!['status'] ?? 'unknown';
                                if (status == 'APPROVED') {
                                  ScaffoldMessenger.of(
                                    navigatorKey.currentContext!,
                                  ).showSnackBar(
                                    SnackBar(
                                      backgroundColor:
                                          AppTheme.lightModeSuccessGreen,
                                      content: Text(
                                        'El pago ha sido verificado exitosamente.',
                                        style: nunitoSansStyle(
                                          400,
                                          14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                  navigatorState.pop(data);
                                } else {
                                  ScaffoldMessenger.of(
                                    navigatorKey.currentContext!,
                                  ).showSnackBar(
                                    SnackBar(
                                      backgroundColor:
                                          AppTheme.lightModeWarning,
                                      content: Text(
                                        'El pago no ha sido verificado. Estado: $status',
                                        style: nunitoSansStyle(
                                          400,
                                          14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                final String error =
                                    result['message'] ??
                                    result['error'] ??
                                    'Ha ocurrido un error';

                                await GlobalWidgets.showBasicAlert(
                                  'Error al verificar pago',
                                  error,
                                  "Aceptar",
                                );
                              }
                            } catch (e) {
                              await GlobalWidgets.showBasicAlert(
                                'Error al verificar pago',
                                "$e",
                                "Aceptar",
                              );
                            } finally {
                              setState(() {
                                _isVeryfing = false;
                              });
                            }
                          }
                        : null,
                    child: !_isVeryfing
                        ? Text(
                            'Verificar pago',
                            style: nunitoSansTitleSmallStyle(
                              context,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : GlobalWidgets.circularProgressIndicator(
                            color: Colors.white,
                            radius: 20,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//  appBar: AppBar(
//         centerTitle: false,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new_rounded),
//           onPressed: () {
//             Navigator.of(context).pop(data);
//           },
//         ),
//         title: FittedBox(
//           child: Text(
//             'Pagar con Deuna',
//             style: nunitoSansTitleLargeStyle(context, fontWeight: FontWeight.w700),
//           ),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 8.0),
//             child: Text(
//               MoneyUtils.formatCurrency(_data['total']),
//               style: nunitoSansTitleLargeStyle(
//                 context,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ),
//         ],
//       ),

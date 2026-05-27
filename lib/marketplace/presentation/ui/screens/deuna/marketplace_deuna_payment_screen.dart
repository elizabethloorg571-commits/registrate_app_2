import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../../../../data/api/marketplace_api_service.dart';
import '../../../../utils/launcher_utils.dart';

import '../../../../utils/money_utils.dart';
import '../../../../config/theme/marketplace_theme.dart';
import '../../../widgets/global.dart';

class MarketplaceDeunaPaymentScreen extends StatefulWidget {
  const MarketplaceDeunaPaymentScreen({
    super.key,
    required this.data,
    required this.total,
    this.isAbonado = false,
  });

  final Map<String, dynamic> data;
  final num total;
  final bool isAbonado;
  @override
  MarketplaceDeunaPaymentScreenState createState() =>
      MarketplaceDeunaPaymentScreenState();
}

class MarketplaceDeunaPaymentScreenState
    extends State<MarketplaceDeunaPaymentScreen> {
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
            style: MarketplaceTheme.titleMediumTextStyle(context),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text(
              MoneyUtils.formatCurrency(widget.total),
              style: MarketplaceTheme.titleLargeTextStyle(
                context,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: Global.pagePadding(context),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Image.asset('assets/images/deuna.png', height: size.height * 0.05),
            const SizedBox(height: 30),
            RichText(
              textAlign: TextAlign.justify,
              text: TextSpan(
                style: MarketplaceTheme.labelLargeTextStyle(context),
                children: [
                  TextSpan(text: 'Presiona el botón para transferir con '),
                  TextSpan(
                    text: 'Deuna ',
                    style: MarketplaceTheme.labelLargeTextStyle(
                      context,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: 'o escanea el '),
                  TextSpan(
                    text: 'código QR ',
                    style: MarketplaceTheme.labelLargeTextStyle(
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
                color: MarketplaceTheme.lightModeLightBlue,
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
                    style: MarketplaceTheme.labelMediumTextStyle(
                      context,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2.5),
                  Text(
                    'Una vez realizado, recuerda volver a esta pantalla para verificar el pago.',
                    style: MarketplaceTheme.labelMediumTextStyle(
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
                    backgroundColor: MarketplaceTheme.deunaButtonColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 10,
                    ),
                    disabledBackgroundColor: MarketplaceTheme.lightModeBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    UrlLauncherUtils.launch(_data['deeplink'] ?? '');
                  },
                  child: Text(
                    'Pagar con Deuna',
                    style: MarketplaceTheme.titleSmallTextStyle(
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
                      backgroundColor: MarketplaceTheme.lightModeBlue,
                      disabledBackgroundColor: MarketplaceTheme.lightModeBlue,
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
                                  await MarketplaceApiService.requestDeUnaPaymentInfo(
                                    paymentData,
                                  );
                              if (result['response'] ?? false) {
                                data = result['data'] ?? {};

                                final String status =
                                    data!['status'] ?? 'unknown';
                                if (status == 'APPROVED') {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: MarketplaceTheme
                                            .lightModeSuccessGreen,
                                        content: Text(
                                          'El pago ha sido verificado exitosamente.',
                                          style:
                                              MarketplaceTheme.bodyMediumTextStyle(
                                                context,
                                                color: Colors.white,
                                              ),
                                        ),
                                      ),
                                    );
                                    navigatorState.pop(data);
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor:
                                            MarketplaceTheme.lightModeWarning,
                                        content: Text(
                                          'El pago no ha sido verificado. Estado: $status',
                                          style:
                                              MarketplaceTheme.bodyMediumTextStyle(
                                                context,
                                                color: Colors.white,
                                              ),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              } else {
                                final String error =
                                    result['message'] ??
                                    result['error'] ??
                                    'Ha ocurrido un error';

                                await Global.showBasicAlert(
                                  'Error al verificar pago',
                                  error,
                                  "Aceptar",
                                );
                              }
                            } catch (e) {
                              await Global.showBasicAlert(
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
                            style: MarketplaceTheme.bodyMediumTextStyle(
                              context,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : Global.circularProgressIndicator(
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

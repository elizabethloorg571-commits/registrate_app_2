import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:running_app/src/domain/models/running_competition.dart';
import 'package:running_app/config/theme/app_theme.dart';
import 'package:running_app/config/theme/fonts.dart';
import 'package:running_app/src/utils/date_handler.dart';

class InscriptionDetailScreen extends StatefulWidget {
  const InscriptionDetailScreen({
    super.key,
    required this.inscriptionData,
    required this.competition,
  });

  final Map<String, dynamic> inscriptionData;
  final RunningCompetition competition;

  @override
  State<InscriptionDetailScreen> createState() =>
      _InscriptionDetailScreenState();
}

class _InscriptionDetailScreenState extends State<InscriptionDetailScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Manejar la estructura de inscriptionData
    // Puede venir de dos fuentes diferentes con estructuras distintas
    List participantes = [];
    String orderId = '';

    if (widget.inscriptionData.containsKey('data') &&
        widget.inscriptionData['data'] != null) {
      // Estructura antigua: inscriptionData['data']['participantes']
      final data = widget.inscriptionData['data'];
      if (data is Map<String, dynamic>) {
        participantes = (data['participantes'] as List?) ?? [];
        orderId = data['orderId']?.toString() ?? '';
      }
    } else if (widget.inscriptionData.containsKey('items')) {
      // Estructura de Inscription.toJson(): items directamente
      participantes = (widget.inscriptionData['items'] as List?) ?? [];
      orderId = widget.inscriptionData['_id']?.toString() ?? '';
    }

    // Si no hay participantes, mostrar mensaje
    if (participantes.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.lightModeBlack),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'E-Ticket',
            style: nunitoSansStyle(600, 18, color: AppTheme.lightModeBlack),
          ),
        ),
        body: Center(
          child: Text(
            'No hay participantes registrados',
            style: nunitoSansStyle(400, 16, color: AppTheme.grey),
          ),
        ),
      );
    }

    final hour = int.tryParse(widget.competition.hour.split(':').first) ?? 0;
    final minute = int.tryParse(widget.competition.hour.split(':')[1]) ?? 0;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.lightModeBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'E-Ticket',
          style: nunitoSansStyle(600, 18, color: AppTheme.lightModeBlack),
        ),
      ),
      body: Column(
        children: [
          // Indicador de inscripción
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Inscrito ${_currentIndex + 1} de ${participantes.length}',
                style: nunitoSansStyle(600, 14, color: Colors.white),
              ),
            ),
          ),
          // QR y datos
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: participantes.length,
              itemBuilder: (context, index) {
                final participante = participantes[index];
                final qrData = '$orderId-${participante['_id']}';

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Información de la carrera
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Carrera',
                                  style: nunitoSansStyle(
                                    400,
                                    14,
                                    color: AppTheme.grey,
                                  ),
                                ),
                                Text(
                                  'Fecha',
                                  style: nunitoSansStyle(
                                    400,
                                    14,
                                    color: AppTheme.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.competition.title,
                                    style: nunitoSansBodySmallStyle(
                                      context,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  fixedTicketDateTime(
                                    widget.competition.date,
                                    time: TimeOfDay(
                                      // hour format "hour": "07:00:00",
                                      hour: hour != 0
                                          ? hour
                                          : widget.competition.date.hour,
                                      minute: minute != 0
                                          ? minute
                                          : widget.competition.date.minute,
                                    ),
                                  ),
                                  style: nunitoSansBodySmallStyle(
                                    context,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Inscrito',
                                  style: nunitoSansStyle(
                                    400,
                                    14,
                                    color: AppTheme.grey,
                                  ),
                                ),
                                Text(
                                  'Cantidad',
                                  style: nunitoSansStyle(
                                    400,
                                    14,
                                    color: AppTheme.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    participante['fullName'] ?? 'N/A',
                                    style: nunitoSansBodySmallStyle(
                                      context,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  'x${participantes.length}',
                                  style: nunitoSansBodySmallStyle(
                                    context,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Indicador de página
                      if (participantes.length > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            participantes.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: index == _currentIndex ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: index == _currentIndex
                                    ? LinearGradient(
                                        colors: [
                                          AppTheme.primary,
                                          AppTheme.secondary,
                                        ],
                                      )
                                    : null,
                                color: index == _currentIndex
                                    ? null
                                    : AppTheme.grey.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // bottomNavigationBar: Container(
      //   padding: const EdgeInsets.all(20),
      //   decoration: BoxDecoration(
      //     color: Colors.white,
      //     boxShadow: [
      //       BoxShadow(
      //         color: Colors.black.withValues(alpha: 0.05),
      //         blurRadius: 10,
      //         offset: const Offset(0, -5),
      //       ),
      //     ],
      //   ),
      //   child: SafeArea(
      //     child: InkWell(
      //       onTap: () {
      //         // TODO: Implementar descarga de e-ticket
      //         ScaffoldMessenger.of(context).showSnackBar(
      //           const SnackBar(
      //             content: Text('Función de descarga en desarrollo'),
      //             backgroundColor: Colors.orange,
      //           ),
      //         );
      //       },
      //       borderRadius: BorderRadius.circular(16),
      //       child: Container(
      //         width: double.infinity,
      //         height: 56,
      //         decoration: BoxDecoration(
      //           gradient: LinearGradient(
      //             colors: [AppTheme.primary, AppTheme.secondary],
      //             begin: Alignment.centerLeft,
      //             end: Alignment.centerRight,
      //           ),
      //           borderRadius: BorderRadius.circular(16),
      //         ),
      //         child: Center(
      //           child: Text(
      //             'Descargar e-ticket',
      //             style: nunitoSansStyle(600, 16, color: Colors.white),
      //           ),
      //         ),
      //       ),
      //     ),
      //   ),
      // ),
    );
  }
}

import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:running_app/src/data/constants/constants.dart';
import 'package:running_app/src/presentation/ui/profile/utils/money_utils.dart';
import 'package:running_app/config/theme/fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class DatafastPaymentScreen extends StatefulWidget {
  const DatafastPaymentScreen({
    super.key,
    required this.total,
    required this.serviceId,
    required this.token,
    required this.serviceLabel,
  });

  final num total;
  final String serviceLabel;
  final String serviceId;
  final String token;

  @override
  State<DatafastPaymentScreen> createState() => _DatafastPaymentScreenState();
}

class _DatafastPaymentScreenState extends State<DatafastPaymentScreen> {
  late final WebViewController _controller;
  bool _resultHandled = false;

  String? _unwrapJsResult(dynamic r) {
    if (r == null) return null;
    try {
      if (r is num || r is bool) return r.toString();
      if (r is String) {
        final s = r;
        if (s.length >= 2 &&
            ((s.startsWith('"') && s.endsWith('"')) ||
                (s.startsWith('\'') && s.endsWith('\'')))) {
          try {
            final unescaped = jsonDecode(s);
            if (unescaped is String) return unescaped;
            return unescaped.toString();
          } catch (_) {
            // fallthrough
          }
        }
        return s;
      }
      return r.toString();
    } catch (_) {
      return null;
    }
  }

  void _handleResult(dynamic data) {
    if (_resultHandled) return;
    _resultHandled = true;
    if (!mounted) return;
    try {
      Navigator.of(context).pop(data);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    final base = ApiConstants.datafastApiUrl.endsWith('/')
        ? ApiConstants.datafastApiUrl
        : '${ApiConstants.datafastApiUrl}/';
    final uri = Uri.parse('${base}datafast').replace(
      queryParameters: {
        widget.serviceLabel: widget.serviceId,
        'token': widget.token,
      },
    );
    if (kDebugMode) log('🔗 Loading Datafast URL: $uri');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            if (kDebugMode) log('onNavigationRequest url: $url');
            String frameInfo = 'unknown';
            try {
              final dynamic r = request as dynamic;
              frameInfo = r.isForMainFrame?.toString() ?? 'unknown';
            } catch (e) {
              frameInfo = 'unknown';
            }
            if (kDebugMode) {
              log('onNavigationRequest isForMainFrame: $frameInfo');
            }

            final parsed = Uri.tryParse(url);
            if (kDebugMode) {
              log(
                'onNavigationRequest host: ${parsed?.host} path: ${parsed?.path}',
              );
            }

            const resultPrefix = '${ApiConstants.apiUrl}/pasarela/result/';

            if ((url.startsWith(resultPrefix) ||
                    (parsed != null &&
                        parsed.path.contains('/pasarela/result'))) &&
                !_resultHandled) {
              if (kDebugMode) log('result URL: $url');
              // prevent the WebView from actually navigating
              final NavigationDecision decision = NavigationDecision.prevent;

              http
                  .get(Uri.parse(url))
                  .then((response) {
                    if (kDebugMode) {
                      log('Result HTTP status: ${response.statusCode}');
                    }
                    if (response.statusCode == 200) {
                      try {
                        final dynamic decodedBody = jsonDecode(response.body);
                        if (kDebugMode) {
                          final bodyPreview = response.body.length > 500
                              ? '${response.body.substring(0, 500)}...'
                              : response.body;
                          log('JSON result: $bodyPreview');
                          if (decodedBody is Map) {
                            log('JSON keys: ${decodedBody.keys.toList()}');
                          }
                        }
                        _handleResult(decodedBody);
                      } catch (e, st) {
                        if (kDebugMode) log('JSON error: $e\n$st');
                        _handleResult({'error': 'invalid_json'});
                      }
                    } else {
                      if (kDebugMode) {
                        log('HTTP ${response.statusCode}');
                      }
                      _handleResult({'error': 'http_${response.statusCode}'});
                    }
                  })
                  .catchError((e, st) {
                    if (kDebugMode) log('Fetch failed: $e\n$st');
                    _handleResult({'error': e.toString()});
                  });

              return decision;
            }

            if (kDebugMode) log('NavigationDecision: navigate for $url');
            return NavigationDecision.navigate;
          },
          onPageFinished: (u) async {
            if (kDebugMode) log('Page loaded: $u');
            try {
              final hrefRaw = await _controller.runJavaScriptReturningResult(
                'document.location.href',
              );
              final bodyRaw = await _controller.runJavaScriptReturningResult(
                'document.body && document.body.innerText',
              );
              final href = _unwrapJsResult(hrefRaw);
              final body = _unwrapJsResult(bodyRaw);
              if (kDebugMode) {
                log('JS document.location.href: $href');
                if (body != null) {
                  final preview = body.length > 1000
                      ? '${body.substring(0, 1000)}...'
                      : body;
                  log('JS document.body.innerText: $preview');
                } else {
                  log('JS document.body.innerText: null');
                }
              }

              if (!_resultHandled && body != null) {
                final text = body.trim();
                if (text.startsWith('{') || text.startsWith('[')) {
                  try {
                    final decoded = jsonDecode(text);
                    if (kDebugMode) {
                      log(
                        'JS fallback JSON keys: ${decoded is Map ? decoded.keys.toList() : 'array'}',
                      );
                    }
                    _handleResult(decoded);
                  } catch (e, st) {
                    if (kDebugMode) {
                      log('JS fallback JSON parse failed: $e\n$st');
                    }
                    _handleResult({'error': 'invalid_json'});
                  }
                }
              }
            } catch (e, st) {
              if (kDebugMode) log('JS fallback read failed: $e\n$st');
            }
          },
          onWebResourceError: (err) {
            if (kDebugMode) {
              log('WebView error: ${err.description} (${err.errorCode})');
            }
          },
        ),
      )
      ..loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        leading: IconButton(
          icon: Icon(context.platformIcons.back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: FittedBox(
          child: Text(
            'Total a pagar',
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
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}

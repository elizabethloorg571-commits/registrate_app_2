import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:running_app/app_localizations_context.dart';
import 'package:running_app/src/presentation/providers/translation/locale_provider.dart';
import 'package:running_app/config/theme/fonts.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  String? _selectedLanguageCode;

  final _languages = <Map<String, dynamic>>[
    <String, dynamic>{
      'code': 'es',
      'locale': const Locale('es'),
      'name': 'Español Latinoamérica',
    },
    <String, dynamic>{
      'code': 'en',
      'locale': const Locale('en'),
      'name': 'English (UK)',
    },
    <String, dynamic>{
      'code': 'pt',
      'locale': const Locale('pt'),
      'name': 'Português (BR)',
    },
    <String, dynamic>{
      'code': 'de',
      'locale': const Locale('de'),
      'name': 'Deutsch',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Inicializar con el idioma actual después de que el widget se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localeAsync = ref.read(localeProvider);
      localeAsync.whenData((locale) {
        if (mounted) {
          setState(() {
            _selectedLanguageCode = locale.languageCode;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          context.l1on.language,
          style: nunitoSansTitleLargeStyle(
            context,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          Expanded(
            child: ListView.separated(
              itemCount: _languages.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey.shade200,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final language = _languages[index];
                final isSelected = _selectedLanguageCode == language['code'];

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedLanguageCode = language['code'] as String;
                    });
                  },
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            language['name']!,
                            style: nunitoSansBodyLargeStyle(
                              context,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFF6366F1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          )
                        else
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedLanguageCode != null
                      ? () => _saveLanguage()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.l1on.save,
                    style: nunitoSansBodyLargeStyle(
                      context,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveLanguage() async {
    if (_selectedLanguageCode == null) return;

    // Cambiar el locale usando el provider
    await ref
        .read(localeProvider.notifier)
        .setLocale(Locale(_selectedLanguageCode!));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l1on.languageSavedSuccessfully,
            style: nunitoSansBodyMediumStyle(context, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF6366F1),
        ),
      );
      Navigator.of(context).pop();
    }
  }
}

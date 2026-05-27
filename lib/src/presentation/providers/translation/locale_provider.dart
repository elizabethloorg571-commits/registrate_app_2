import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeProvider = AsyncNotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

class LocaleNotifier extends AsyncNotifier<Locale> {
  @override
  Future<Locale> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String localeCode = prefs.getString('locale') ?? 'es';
    return Locale(localeCode);
  }

  Future<void> setLocale(Locale locale) async {
    state = AsyncValue.data(locale);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
  }
}

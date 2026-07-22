import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('fr'); // Default

  Locale  get locale  => _locale;
  bool    get isRTL   => _locale.languageCode == 'ar';

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs     = await SharedPreferences.getInstance();
    final langCode  = prefs.getString('language_code') ?? 'fr';
    _locale = Locale(langCode);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    if (!['fr', 'ar', 'en'].contains(languageCode)) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);

    _locale = Locale(languageCode);
    notifyListeners();
  }

  void toggleLanguage() {
    setLocale(isRTL ? 'fr' : 'ar');
  }
}
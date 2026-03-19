import 'app_translations.dart';
import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('ar');
  TextDirection _textDirection = TextDirection.rtl;

  Locale get locale => _locale;
  TextDirection get textDirection => _textDirection;

  void setLocale(Locale newLocale) {
    if (_locale != newLocale) {
      _locale = newLocale;
      AppTranslations.currentLang = newLocale.languageCode;
      if (newLocale.languageCode == 'ar') {
        _textDirection = TextDirection.rtl;
      } else {
        _textDirection = TextDirection.ltr;
      }
      notifyListeners();
    }
  }
}

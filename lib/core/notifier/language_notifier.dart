import 'package:flutter/material.dart';
import 'package:srpf/core/base/base_notifier.dart';

class LanguageNotifier extends BaseChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void switchLanguage() {
    _locale = _locale.languageCode == 'en'
        ? const Locale('ar')
        : const Locale('en');
    notifyListeners();
  }
}

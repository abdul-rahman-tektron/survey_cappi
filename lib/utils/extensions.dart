import 'package:flutter/material.dart';
import 'package:srpf/core/generated_locales/l10n.dart';


extension LocalizationX on BuildContext {
  AppLocalizations get locale => AppLocalizations.of(this)!;
}

extension StringExtensions on String {
  bool isArabic() {
    final arabicRegExp = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    return arabicRegExp.hasMatch(this);

  }
}
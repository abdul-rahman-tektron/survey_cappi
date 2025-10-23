import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';

class AppThemes {
  AppThemes._();

  /// Builds theme data based on language code
  static ThemeData lightTheme({required String languageCode}) {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: languageCode == 'ar' ? AppFonts.arabicFont : AppFonts.primaryFont,
      appBarTheme: AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.primary,
          statusBarIconBrightness: Brightness.light, // Android
          statusBarBrightness: Brightness.light,      // iOS (dark text → black, set to .dark for proper contrast)
        ),
        color: AppColors.backgroundSecondary,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.textPrimary,
        selectionColor: AppColors.primary.withOpacity(0.4),
        selectionHandleColor: AppColors.textPrimary,
      ),
      useMaterial3: true,
      // Extend with more theme customizations if needed
    );
  }
}

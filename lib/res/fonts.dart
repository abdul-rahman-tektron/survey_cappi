import 'package:flutter/material.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/utils/extensions.dart';
import 'package:srpf/utils/helpers/screen_size.dart';

// AppFonts provides font sizes with weights and colors
class AppFonts {
  AppFonts._();

  static const String primaryFont = 'Lexend'; // Default font (English)

  static const String arabicFont = 'DroidKufi';


  // Common font sizes as static getters returning helper class
  static _FontSizeStyles get text10 => const _FontSizeStyles(10);
  static _FontSizeStyles get text12 => const _FontSizeStyles(12);
  static _FontSizeStyles get text14 => const _FontSizeStyles(14);
  static _FontSizeStyles get text16 => const _FontSizeStyles(16);
  static _FontSizeStyles get text17 => const _FontSizeStyles(17);
  static _FontSizeStyles get text18 => const _FontSizeStyles(18);
  static _FontSizeStyles get text20 => const _FontSizeStyles(20);
  static _FontSizeStyles get text22 => const _FontSizeStyles(22);
  static _FontSizeStyles get text24 => const _FontSizeStyles(24);
  static _FontSizeStyles get text26 => const _FontSizeStyles(26);
  static _FontSizeStyles get text28 => const _FontSizeStyles(28);
  static _FontSizeStyles get text48 => const _FontSizeStyles(48);

  // Colors
  static const Color black = AppColors.textPrimary;
  static const Color white = AppColors.white;
  static const Color grey = AppColors.textSecondary;
  static const Color red = AppColors.error;
  static const Color blue = AppColors.textBlue;
}

class _FontSizeStyles {
  final double size;
  const _FontSizeStyles(this.size);

  _TextStyleBuilder get regular =>
      _TextStyleBuilder(size: size, weight: FontWeight.normal);

  _TextStyleBuilder get medium =>
      _TextStyleBuilder(size: size, weight: FontWeight.w500);

  _TextStyleBuilder get semiBold =>
      _TextStyleBuilder(size: size, weight: FontWeight.w600);

  _TextStyleBuilder get bold =>
      _TextStyleBuilder(size: size, weight: FontWeight.bold);
}

class _TextStyleBuilder {
  final double size;
  final FontWeight weight;
  final Color color;

  const _TextStyleBuilder({
    required this.size,
    required this.weight,
    this.color = AppFonts.black,
  });

  // Colors as getters returning new instances with changed color:
  _TextStyleBuilder get black => _copyWithColor(AppFonts.black);
  _TextStyleBuilder get white => _copyWithColor(AppFonts.white);
  _TextStyleBuilder get grey => _copyWithColor(AppFonts.grey);
  _TextStyleBuilder get red => _copyWithColor(AppFonts.red);
  _TextStyleBuilder get blue => _copyWithColor(AppFonts.blue);
  _TextStyleBuilder get primary => _copyWithColor(AppColors.primary);

  _TextStyleBuilder _copyWithColor(Color color) {
    return _TextStyleBuilder(size: size, weight: weight, color: color);
  }

  TextStyle get style {
    final width = ScreenSize.width;
    final adjustedSize = width < 380 ? size - 3 : size;

    return TextStyle(
      fontSize: adjustedSize,
      fontWeight: weight,
      color: color,
      letterSpacing: 0.5,
      // fontFamily is handled separately by FontResolver if needed
    );
  }
}

// FontResolver to switch fonts based on text language
class FontResolver {
  static TextStyle resolve(String text, TextStyle baseStyle) {
    final isArabic = text.isArabic();
    return baseStyle.copyWith(
      fontFamily: isArabic ? AppFonts.arabicFont : AppFonts.primaryFont,
    );
  }
}

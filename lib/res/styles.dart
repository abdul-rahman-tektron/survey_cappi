import 'package:flutter/material.dart';
import 'package:srpf/res/colors.dart';

class AppStyles {
  AppStyles._();

  static OutlineInputBorder fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.textSecondary, width: 0.5),
  );

  static OutlineInputBorder enabledFieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.textSecondary, width: 0.5),
  );

  static OutlineInputBorder focusedFieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.textSecondary, width: 1),
  );

  static OutlineInputBorder errorFieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.error),
  );

  static BoxDecoration commonDecoration = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(10),
    boxShadow: const [
      BoxShadow(color: Colors.black12, blurRadius: 7),
    ],
  );
}
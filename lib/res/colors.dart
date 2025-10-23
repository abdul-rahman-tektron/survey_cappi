import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // prevent instantiation

  // Primary brand color
  static const primary = Color(0xFF004A48); // Primary Teal-Green
  static const primaryLight = Color(0xFF80CBCB); // Soft aqua accent/light shade
  static const secondary = Color(0xFF1C1C1C); // Deep charcoal gray (neutral balance)

  // Backgrounds
  static const background = Color(0xFFF2F2F2); // Light Gray
  static const backgroundSecondary = Color(0xFFFFFFFF); // White card background

  // Text
  static const textPrimary = Color(0xFF000000); // Black
  static const textSecondary = Color(0xFF757575); // Muted gray text
  static const textBlue = Color(0xFF171F89); // Muted gray text

  // States
  static const error = Color(0xFFBE3D2A); // Error Red
  static const success = Color(0xFF1B873B); // Success Green

  // Extras (optional / util)
  static const polylineColor = Color(0xFF00008B); // Deep Blue (keep if needed)
  static const blueColor = Colors.blue;
  static const transparent = Colors.transparent;
  static const shadowColor = Color(0xFFC5C5C5);

  //Color
  static const white = Colors.white;
}
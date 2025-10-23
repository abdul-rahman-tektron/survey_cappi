import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/utils/helpers/app_crash_report.dart';
import 'package:toastification/toastification.dart';

class ToastHelper {
  ToastHelper._(); // Prevent instantiation

  static void showError(String message, {BuildContext? context, Object? error, StackTrace? stack}) {

    AppCrashReporter.recordError(
      error ?? Exception('ToastError: $message'),
      stack ?? StackTrace.current,
      context: {'toast_message': message},
      fatal: false,
    );

    _show(
      message,
      type: ToastificationType.error,
      backgroundColor: Colors.red,
      icon: Icon(LucideIcons.circleX, color: Colors.red),
      context: context,
    );
  }

  static void showSuccess(String message, {BuildContext? context}) {
    _show(
      message,
      type: ToastificationType.success,
      backgroundColor: Colors.green,
      icon: Icon(LucideIcons.circleCheck, color: Colors.green),
      context: context,
    );
  }

  static void showInfo(String message, {BuildContext? context}) {
    _show(
      message,
      type: ToastificationType.info,
      backgroundColor: Colors.blue,
      icon: const Icon(Icons.info, color: Colors.blue),
      context: context,
    );
  }

  static void showWarning(String message, {BuildContext? context}) {
    _show(
      message,
      type: ToastificationType.warning,
      icon: const Icon(Icons.warning, color: Colors.orange),
      context: context,
    );
  }

  static void _show(
      String message, {
        required ToastificationType type,
        required Widget icon,
        BuildContext? context,
        Color? backgroundColor,
        Duration duration = const Duration(milliseconds: 3000),
      }) {
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flat,
      title: Text(
        message,
        maxLines: 10,
        overflow: TextOverflow.visible,
      ),
      borderSide: BorderSide(
        color: backgroundColor ?? AppColors.primary,
        width: 1.5,
      ),
      autoCloseDuration: duration,
      alignment: Alignment.topRight,
      icon: icon,
      progressBarTheme: ProgressIndicatorThemeData(
        color: backgroundColor ?? AppColors.primary,
        borderRadius: BorderRadius.circular(8),
        linearMinHeight: 2,
      ),
      borderRadius: BorderRadius.circular(8),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      showProgressBar: true,
    );
  }
}

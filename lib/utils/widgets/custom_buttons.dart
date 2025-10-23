
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';
import 'package:srpf/utils/helpers/loader.dart';
import 'package:srpf/utils/helpers/screen_size.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final IconData? icon;
  final Color? iconColor;
  final double? iconSize;
  final bool iconOnLeft;
  final String? image;
  final double? imageSize;
  final bool imageOnLeft;
  final bool isLoading;
  final bool fullWidth;
  final double? height;
  final double? radius;
  final Color? borderColor;
  final EdgeInsets? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textStyle,
    this.icon,
    this.iconOnLeft = false,
    this.imageSize,
    this.image,
    this.imageOnLeft = false,
    this.isLoading = false,
    this.fullWidth = true,
    this.height,
    this.radius,
    this.borderColor,
    this.iconColor,
    this.iconSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedBgColor = onPressed == null
        ? (backgroundColor ?? AppColors.primary).withOpacity(0.5)
        : backgroundColor ?? AppColors.primary;

    final resolvedTextColor =
    (backgroundColor ?? AppColors.primary) == AppColors.primary
        ? Colors.white
        : AppColors.primary;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height ?? (MediaQuery.of(context).devicePixelRatio >= 3.0 ? 40 : 45),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: resolvedBgColor,
          foregroundColor: resolvedTextColor,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius ?? 10),
            side: BorderSide(
              color: borderColor ?? Colors.transparent,
              width: 1,
            ),
          ),
        ),
        child: isLoading
            ? const DotCircleSpinner(size: 40, dotSize: 3)
            : Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null && iconOnLeft) ...[
              Icon(icon, size: iconSize ?? 20, color: iconColor ?? resolvedTextColor),
              5.horizontalSpace,
            ],
            if (image != null && imageOnLeft) ...[
              Image.asset(image ?? "", height: imageSize ?? 20, width: imageSize ?? 20),
              5.horizontalSpace,
            ],
            FittedBox(
              child: Text(
                text,
                style: textStyle ?? AppFonts.text16.semiBold.white.style.copyWith(
                  fontSize: ScreenSize.width < 380 ? 12 : 16,
                ),
              ),
            ),
            if (icon != null && !iconOnLeft) ...[
              5.horizontalSpace,
              Icon(icon, size: iconSize ?? 20, color: iconColor ?? resolvedTextColor),
            ],
            if (image != null && !imageOnLeft) ...[
              5.horizontalSpace,
              Image.asset(image ?? "", height: imageSize ?? 20, width: imageSize ?? 20),
            ],
          ],
        ),
      ),
    );
  }
}

class CustomUploadButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final IconData? icon;
  final double? radius;

  const CustomUploadButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textStyle,
    this.icon,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius ?? 50),
          side: const BorderSide(color: AppColors.primary, width: 1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? LucideIcons.upload, color: AppColors.primary),
          8.horizontalSpace,
          Text(text, style: textStyle ?? AppFonts.text14.medium.white.style),
        ],
      ),
    );
  }
}

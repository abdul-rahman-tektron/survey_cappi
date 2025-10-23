import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:srpf/res/colors.dart';

class CustomLinearProgressIndicator extends StatelessWidget {
  final double percentage; // 0 to total
  final double height;
  final double total;
  final Color fillColor;
  final Color backgroundColor;
  final double borderRadius;

  const CustomLinearProgressIndicator({
    super.key,
    required this.percentage,
    this.height = 6,
    this.total = 100,
    this.fillColor = AppColors.primary,
    this.backgroundColor = const Color(0xFFE6E6E6),
    this.borderRadius = 4.0,
  });

  // Create a lighter version of the given color
  Color _lighten(Color color, [double amount = 0.3]) {
    final hsl = HSLColor.fromColor(color);
    final lightened = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return lightened.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final safeTotal = total > 0 ? total : 1; // avoid division by 0
    final clampedPercent = percentage.clamp(0, safeTotal);

    final percentText = total > 0
        ? "${(percentage / total * 100).clamp(0, 100).toStringAsFixed(0)}%"
        : "0%";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              percentText,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        4.verticalSpace,
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            height: height,
            width: double.infinity,
            color: backgroundColor,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: total > 0 ? clampedPercent / total : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _lighten(fillColor, 0.3), // lighter at start
                      fillColor,                // darker at end
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
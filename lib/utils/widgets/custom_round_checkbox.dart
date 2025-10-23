import 'package:flutter/material.dart';
import 'package:srpf/res/colors.dart';

class CustomRoundCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;
  final Color activeColor;
  final Color checkColor;
  final Color borderColor;

  const CustomRoundCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 20,
    this.activeColor = AppColors.primary,
    this.checkColor = AppColors.white,
    this.borderColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: value ? activeColor : Colors.transparent,
          border: Border.all(
            color: value ? activeColor : borderColor,
            width: 1,
          ),
        ),
        child: value
            ? Center(
          child: Icon(
            Icons.check,
            color: checkColor,
            size: size * 0.6,
          ),
        )
            : null,
      ),
    );
  }
}

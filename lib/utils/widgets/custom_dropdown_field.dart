import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';
import 'package:srpf/res/styles.dart';
import 'package:srpf/utils/helpers/validations.dart';

class CustomDropdownField<T> extends StatelessWidget {
  final String fieldName;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;

  // Behavior / Validation
  final bool isEnable;
  final bool skipValidation;
  final String? Function(T?)? validator;
  final bool isAutoValidate;

  // UI
  final String? hintText;
  final String? toolTipContent; // kept for API parity; not shown (no header)
  final Widget? prefixIcon;
  final bool useFieldNameAsLabel; // label inside field

  const CustomDropdownField({
    super.key,
    required this.fieldName,
    required this.items,
    required this.value,
    required this.onChanged,
    this.isEnable = true,
    this.skipValidation = false,
    this.validator,
    this.isAutoValidate = true,
    this.hintText,
    this.toolTipContent,
    this.prefixIcon,
    this.useFieldNameAsLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final border = AppStyles.fieldBorder;

    return DropdownButtonFormField<T>(
      value: value,
      onChanged: isEnable ? onChanged : null,
      autovalidateMode: isAutoValidate ? AutovalidateMode.onUserInteraction : null,
      validator: skipValidation
          ? null
          : (val) {
        if (validator != null) return validator!(val);
        // fallback "required" validation like your other fields
        return Validations.requiredField(context, val == null ? null : '');
      },
      icon: const Icon(
        LucideIcons.chevronsUpDown,
        size: 20,
        color: AppColors.textSecondary,
      ),
      items: items,
      decoration: InputDecoration(
        // match QDropdown* look
        filled: true,
        fillColor: isEnable ? AppColors.white.withOpacity(0.8) : Colors.black.withOpacity(0.04),

        // label lives inside the field (no external header)
        labelText: useFieldNameAsLabel ? fieldName : null,
        labelStyle: AppFonts.text14.regular.grey.style,
        floatingLabelStyle: AppFonts.text16.regular.style,

        hintText: hintText,
        hintStyle: AppFonts.text14.regular.grey.style,

        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        prefixIcon: prefixIcon,

        // borders
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: AppStyles.focusedFieldBorder,
        errorBorder: AppStyles.errorFieldBorder,
        focusedErrorBorder: AppStyles.errorFieldBorder,
        errorStyle: AppFonts.text14.regular.red.style,

        isDense: true,
      ),
      // keep menu style native; if you need fully white popup like QDropdown, wrap in Theme
      dropdownColor: Colors.white,
    );
  }
}
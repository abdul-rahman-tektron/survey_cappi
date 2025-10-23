import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';
import 'package:srpf/res/styles.dart';
import 'package:srpf/utils/helpers/validations.dart';

/// A lightweight wrapper around `dropdown_search` v6 that:
/// - accepts strongly-typed items <T>
/// - displays a field header (label + * + tooltip) when needed
/// - adapts a String-based validator to the widget's T?-based validator
class CustomSearchDropdown<T> extends StatelessWidget {
  // Data
  final List<T> items;
  final T? initialValue;

  // Labels & i18n
  final String fieldName;
  final String hintText;
  final String currentLang;
  final String Function(T, String) itemLabel;

  // Behavior
  final void Function(T?)? onSelected;
  final bool isEnable;
  final bool skipValidation; // if true -> not required
  final bool showFieldName;
  final bool isSmallFieldFont;

  // Validation (external, String? based)
  final String? Function(String?)? validator;

  // UI
  final String? toolTipContent;

  const CustomSearchDropdown({
    super.key,
    required this.items,
    required this.fieldName,
    required this.hintText,
    required this.itemLabel,
    required this.currentLang,
    this.onSelected,
    this.initialValue,
    this.isEnable = true,
    this.skipValidation = false,
    this.validator,
    this.toolTipContent,
    this.isSmallFieldFont = false,
    this.showFieldName = true,
  });

  @override
  Widget build(BuildContext context) {
    final T? selected = _resolveSelected(initialValue);
    final bool isRequired = !skipValidation; // used in fallback required check

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showFieldName && fieldName.isNotEmpty) ...[
          Row(
            children: [
              Text(
                fieldName,
                style: isSmallFieldFont
                    ? AppFonts.text12.regular.style
                    : AppFonts.text14.regular.style,
              ),
              const SizedBox(width: 3),
              if (isRequired)
                const Text("*", style: TextStyle(fontSize: 15, color: AppColors.error)),
              if (toolTipContent != null) ...[
                const SizedBox(width: 3),
                Tooltip(
                  message: toolTipContent!,
                  textAlign: TextAlign.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
        ],

        DropdownSearch<T>(
          // Core
          selectedItem: selected,
          // <- T? (never String?)
          enabled: isEnable,
          onChanged: onSelected,

          // v6 "items" is a function: (filter, loadProps?) => FutureOr<List<T>>
          items: (String filter, LoadProps? _) => _filteredItems(filter),

          // Display helpers
          itemAsString: (T item) => itemLabel(item, currentLang),
          compareFn: (T a, T b) => itemLabel(a, currentLang) == itemLabel(b, currentLang),

          // Validation: adapt T? -> String? for your String-based validator
          validator: skipValidation
              ? null
              : (T? val) {
                  if (validator != null) {
                    final String? label = val == null ? null : itemLabel(val, currentLang);
                    return validator!(label); // <- String? to external validator
                  }
                  // Fallback "required" check
                  if (isRequired && val == null) {
                    return Validations.requiredField(context, null);
                  }
                  return null;
                },
          autoValidateMode: skipValidation
              ? AutovalidateMode.disabled
              : AutovalidateMode.onUserInteraction,

          // Decorator (v6)
          decoratorProps: DropDownDecoratorProps(
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppFonts.text14.regular.grey.style,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: isEnable
                  ? AppColors.white.withOpacity(0.8)
                  : AppColors.textSecondary.withOpacity(0.2),
              border: AppStyles.fieldBorder,
              enabledBorder: AppStyles.fieldBorder,
              focusedBorder: AppStyles.focusedFieldBorder,
              errorBorder: AppStyles.errorFieldBorder,
              focusedErrorBorder: AppStyles.errorFieldBorder,
              errorStyle: const TextStyle(color: AppColors.error, fontSize: 14),
            ),
          ),

          // Popup (with search)
          popupProps: PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Search…',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: AppStyles.fieldBorder,
                enabledBorder: AppStyles.fieldBorder,
                focusedBorder: AppStyles.focusedFieldBorder,
                filled: true,
                fillColor: Colors.white, // search box bg
              ),
            ),
            itemBuilder: (BuildContext context, T item, bool isSelected, bool isDisabled) {
              final label = itemLabel(item, currentLang);
              return ListTile(
                dense: true,
                enabled: !isDisabled,
                title: Text(label, style: AppFonts.text17.regular.style),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppColors.primary, size: 20)
                    : null,
              );
            },

            // 👇 force popup/menu background to white
            containerBuilder: (ctx, popupWidget) => Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              child: popupWidget,
            ),
          ),

          // Suffix (includes clear + dropdown button) in v6
          suffixProps: DropdownSuffixProps(
            clearButtonProps: const ClearButtonProps(isVisible: true),
            dropdownButtonProps: DropdownButtonProps(
              iconOpened: _chevrons,
              iconClosed: _chevrons,
              padding: const EdgeInsets.only(right: 10.0, left: 10.0),
            ),
          ),
        ),
      ],
    );
  }

  // Icon used for opened/closed
  Icon get _chevrons =>
      const Icon(LucideIcons.chevronsUpDown, size: 20, color: AppColors.textSecondary);

  /// Filter items locally (v6 expects a function)
  FutureOr<List<T>> _filteredItems(String filter) {
    final f = filter.trim().toLowerCase();
    if (f.isEmpty) return items;
    return items.where((e) => itemLabel(e, currentLang).toLowerCase().contains(f)).toList();
  }

  /// Resolve selected item by matching label; returns a T? (never String?)
  T? _resolveSelected(T? initial) {
    if (initial == null) return null;
    final needle = itemLabel(initial, currentLang);
    for (final it in items) {
      if (itemLabel(it, currentLang) == needle) return it;
    }
    return null;
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';
import 'package:srpf/res/styles.dart';

class QDropdownMulti extends StatefulWidget {
  final Question q;
  final BaseQuestionnaireNotifier n;
  final String sid;

  const QDropdownMulti(this.q, this.n, this.sid, {super.key});

  @override
  State<QDropdownMulti> createState() => _QDropdownMultiState();
}

class _QDropdownMultiState extends State<QDropdownMulti> {
  Question get q => widget.q;

  List<AnswerOption> get _options => widget.n.getOptions(q);

  List<String> get _selectedIds =>
      (q.answer is List) ? List<String>.from(q.answer as List) : <String>[];

  List<AnswerOption> _selectedOptionsFromIds(List<String> ids) {
    final map = {for (final o in _options) o.id: o};
    return ids.map((id) => map[id]).whereType<AnswerOption>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final required = q.validation?.required ?? false;
    final minSel = q.validation?.minSelections ?? 0;
    final hasMax = q.validation?.maxSelections != null;
    final maxSel = q.validation?.maxSelections ?? 0x3fffffff;

    final selected = _selectedOptionsFromIds(_selectedIds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownSearch<AnswerOption>.multiSelection(
          enabled: !(q.readOnly ?? false),

          // Items (with local filter)
          items: (String filter, LoadProps? _) => _filter(_options, filter),

          // Selection plumbing
          selectedItems: selected,
          itemAsString: (it) => it.label,
          compareFn: (a, b) => a.id == b.id,

          onChanged: (values) {
            final next = List<AnswerOption>.from(values ?? const []);
            // Hard-cap (defense in depth)
            if (next.length > maxSel) {
              next.removeRange(maxSel, next.length);
            }
            widget.n.updateAnswer(
              widget.sid,
              q.id,
              next.map((e) => e.id).toList(), // store IDs only
            );
          },

          // Validate min/max
          validator: (vals) {
            final list = vals ?? const <AnswerOption>[];
            if (required && list.isEmpty) {
              return q.validation?.errorMessage ?? 'Please select at least 1 option';
            }
            if (list.length < minSel) return 'Select at least $minSel item(s)';
            if (hasMax && list.length > maxSel) return 'Select at most $maxSel item(s)';
            return null;
          },
          autoValidateMode:
          required ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,

          // Field decoration — mirrors your single dropdown style
          decoratorProps: DropDownDecoratorProps(
            decoration: InputDecoration(
              hintText: q.placeholder ?? q.hint ?? 'Select…',
              hintStyle: AppFonts.text14.regular.grey.style,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: (q.readOnly ?? false)
                  ? AppColors.textSecondary.withOpacity(0.2)
                  : AppColors.white.withOpacity(0.8),
              border: AppStyles.fieldBorder,
              enabledBorder: AppStyles.fieldBorder,
              focusedBorder: AppStyles.focusedFieldBorder,
              errorBorder: AppStyles.errorFieldBorder,
              focusedErrorBorder: AppStyles.errorFieldBorder,
              errorStyle: const TextStyle(color: AppColors.error, fontSize: 14),
            ),
          ),

          // Selected chips in the closed field
          dropdownBuilder: (context, selectedItems) {
            final items = selectedItems ?? const <AnswerOption>[];
            if (items.isEmpty) {
              return Text(
                q.placeholder ?? q.hint ?? 'Select…',
                style: AppFonts.text14.regular.grey.style,
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                return InputChip(
                  label: Text(item.label, style: const TextStyle(color: AppColors.white)),
                  backgroundColor: AppColors.primary,
                  onDeleted: (q.readOnly ?? false)
                      ? null
                      : () {
                    final current = _selectedOptionsFromIds(_selectedIds);
                    current.removeWhere((e) => e.id == item.id);
                    widget.n.updateAnswer(
                      widget.sid,
                      q.id,
                      current.map((e) => e.id).toList(),
                    );
                  },
                  deleteIconColor: AppColors.white,
                );
              }).toList(),
            );
          },

          // Popup menu (AppColors) + search
          popupProps: PopupPropsMultiSelection.menu(
            showSearchBox: true,

            // Disable new picks when at max (already-selected items stay enabled to allow unselect)
            disabledItemFn: (item) {
              final required = q.validation?.required ?? false; // not used here, but ok
              final maxSel   = q.validation?.maxSelections;
              if (maxSel == null) return false; // no limit ⇒ nothing disabled

              final selected = _selectedOptionsFromIds(_selectedIds);
              final atCap    = selected.length >= maxSel;

              // Disable only *new* picks once at cap; keep already-selected items enabled
              final alreadySelected = selected.any((s) => s.id == item.id);
              return atCap && !alreadySelected;
            },

            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Search…',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: AppStyles.fieldBorder,
                enabledBorder: AppStyles.fieldBorder,
                focusedBorder: AppStyles.focusedFieldBorder,
                filled: true,
                fillColor: AppColors.white, // use theme white
              ),
            ),
            itemBuilder: (context, item, isSelected, isDisabled) {
              return Container(
                color: AppColors.white, // menu row bg
                child: ListTile(
                  dense: true,
                  enabled: !isDisabled,
                  title: Text(item.label, style: AppFonts.text16.regular.style),
                  // trailing: isSelected
                  //     ? const Icon(Icons.check, color: AppColors.primary, size: 20)
                  //     : null,
                ),
              );
            },
            // force popup/material background to white
            containerBuilder: (ctx, popup) => Material(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              child: popup,
            ),
          ),

          // Suffix: clear + dropdown button
          suffixProps: const DropdownSuffixProps(
            clearButtonProps: ClearButtonProps(isVisible: true),
            dropdownButtonProps: DropdownButtonProps(),
          ),
        ),

        if (hasMax) ...[
          const SizedBox(height: 6),
          Text(
            '${selected.length}/$maxSel selected',
            style: AppFonts.text12.regular.grey.style,
          ),
        ],
      ],
    );
  }

  FutureOr<List<AnswerOption>> _filter(List<AnswerOption> items, String filter) {
    final f = filter.trim().toLowerCase();
    if (f.isEmpty) return items;
    return items.where((o) => o.label.toLowerCase().contains(f)).toList();
  }
}
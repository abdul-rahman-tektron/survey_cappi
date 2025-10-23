import 'package:flutter/material.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';
import 'package:srpf/utils/helpers/toast_helper.dart';

class QMultiSelectChips extends StatelessWidget {
  final Question q;
  final BaseQuestionnaireNotifier n;
  final String sid;

  const QMultiSelectChips(this.q, this.n, this.sid, {super.key});

  @override
  Widget build(BuildContext context) {
    final opts = n.getOptions(q);
    final List<String> selected =
    (q.answer is List) ? List<String>.from(q.answer as List) : <String>[];

    final int? maxSel = q.validation?.maxSelections; // e.g. 3
    final bool hasCap = maxSel != null && maxSel > 0;
    final bool reachedCap = hasCap && selected.length >= maxSel!;

    bool _isExclusiveId(String id) =>
        opts.any((x) => x.id == id && (x.exclusive == true));

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 8,
          runSpacing: 8,
          children: opts.map((o) {
            final bool isSelected = selected.contains(o.id);
            final bool isExclusive = (o.exclusive == true);

            // Disable if we hit the cap, this chip is NOT selected, and it’s not exclusive.
            final bool shouldDisable = reachedCap && !isSelected && !isExclusive;

            return FilterChip(
              label: Text(
                o.label,
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selected: isSelected,
              checkmarkColor: AppColors.white,
              showCheckmark: true,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.backgroundSecondary,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.shadowColor,
              ),
              onSelected: shouldDisable
                  ? null
                  : (sel) {
                final next = List<String>.from(selected);

                if (sel) {
                  if (isExclusive) {
                    // selecting an exclusive option clears everything else
                    next
                      ..clear()
                      ..add(o.id);
                  } else {
                    // remove any already selected exclusive options
                    next.removeWhere(_isExclusiveId);

                    if (hasCap && next.length >= maxSel!) {
                      ToastHelper.showError(
                          'You can select at most $maxSel items.');
                      return;
                    }
                    if (!next.contains(o.id)) next.add(o.id);
                  }
                } else {
                  next.remove(o.id);
                }

                n.updateAnswer(sid, q.id, next);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
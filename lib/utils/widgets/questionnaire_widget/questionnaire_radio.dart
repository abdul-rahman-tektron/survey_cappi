import 'package:flutter/material.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';

class QRadioChips extends StatelessWidget {
  final Question q;
  final BaseQuestionnaireNotifier n;
  final String sid;

  const QRadioChips(this.q, this.n, this.sid, {super.key});

  @override
  Widget build(BuildContext context) {
    final opts = n.getOptions(q);
    final String? selected = (q.answer is String) ? q.answer as String : null;

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
            final bool isSelected = selected == o.id;

            return ChoiceChip(
              label: Text(
                o.label,
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              showCheckmark: false, // radio look — no check
              backgroundColor: AppColors.backgroundSecondary,
              selectedColor: AppColors.primary,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.shadowColor,
              ),
              shape: const StadiumBorder(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              onSelected: (tap) {
                // Radio behavior: only change if different; don't deselect on re-tap
                if (!isSelected) {
                  n.updateAnswer(sid, q.id, o.id, context: context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
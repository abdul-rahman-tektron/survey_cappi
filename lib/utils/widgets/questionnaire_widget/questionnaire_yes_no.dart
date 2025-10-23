import 'package:flutter/material.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';
import 'package:srpf/res/colors.dart';

class QYesNo extends StatelessWidget {
  final Question q;
  final BaseQuestionnaireNotifier n;
  final String sid;

  const QYesNo(this.q, this.n, this.sid, {super.key});

  @override
  Widget build(BuildContext context) {
    final opts = [
      AnswerOption(id: 'yes', label: 'Yes'),
      AnswerOption(id: 'no', label: 'No'),
    ];
    final String? selected = (q.answer is String) ? q.answer as String : null;

    return Row(
      children: opts.map((o) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: selected == o.id ? AppColors.primary : AppColors.shadowColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: RadioListTile<String>(
              value: o.id,
              groupValue: selected,
              title: Text(
                o.label,
                style: TextStyle(
                  color: selected == o.id
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontWeight:
                  selected == o.id ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              activeColor: AppColors.primary,
              onChanged: (v) => n.updateAnswer(sid, q.id, v),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        );
      }).toList(),
    );
  }
}
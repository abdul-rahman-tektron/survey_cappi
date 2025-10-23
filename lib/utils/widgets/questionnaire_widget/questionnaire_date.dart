import 'package:flutter/material.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/res/fonts.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';
import 'package:srpf/res/colors.dart'; // ⬅️ import your AppColors

class QDate extends StatelessWidget {
  final Question q;
  final BaseQuestionnaireNotifier n;
  final String sid;

  const QDate(this.q, this.n, this.sid, {super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.textSecondary, width: 0.5 ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      ),
      onPressed: () async {
        final now = DateTime.now();
        final initial = (q.answer != null)
            ? DateTime.tryParse(q.answer.toString())
            : null;

        final d = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          initialDate: initial ?? now,
          builder: (context, child) {
            // apply app colors to the picker dialog
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: AppColors.white,
                  surface: AppColors.backgroundSecondary,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (d != null) {
          n.updateAnswer(
            sid,
            q.id,
            DateTime(d.year, d.month, d.day).toIso8601String(),
          );
        }
      },
      child: Text(
        q.answer == null ? 'Select date' : _formatDate(q.answer),
        style: AppFonts.text14.regular.grey.style,
      ),
    );
  }

  String _formatDate(dynamic answer) {
    try {
      final d = DateTime.parse(answer.toString());
      return "${d.day.toString().padLeft(2, '0')}/"
          "${d.month.toString().padLeft(2, '0')}/"
          "${d.year}";
    } catch (_) {
      return answer.toString();
    }
  }
}
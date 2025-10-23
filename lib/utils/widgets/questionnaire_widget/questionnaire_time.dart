import 'package:flutter/material.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';
import 'package:srpf/utils/helpers/toast_helper.dart';

class QTime extends StatelessWidget {
  final Question q;
  final BaseQuestionnaireNotifier n;
  final String sid;

  const QTime(this.q, this.n, this.sid, {super.key});

  @override
  Widget build(BuildContext context) {
    final String label = _formatStoredTime(q.answer?.toString(), context) ?? 'Select time';

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.textSecondary, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      ),
      onPressed: () async {
        final TimeOfDay initial = _parseTimeFlexible(q.answer?.toString()) ?? TimeOfDay.now();

        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: AppColors.white,
                  surface: AppColors.white,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked == null) return;

        // ⬇️ Guard: if this question has a min linked to another question (start time)
        final minFromQid = (q.captureConfig ?? const {})['minFromQuestion'] as String?;
        if (minFromQid != null && minFromQid.isNotEmpty) {
          final startStr = n.valueOfGlobal(minFromQid)?.toString();
          final startTod = _parseTimeFlexible(startStr);
          if (startTod != null) {
            final startSec = _sec(startTod);
            final endSec   = _sec(picked);

            if (endSec <= startSec) {
              // Block commit + tell the user
              ToastHelper.showError('End time must be after Start time.');
              return;
            }
          }
        }

        n.updateAnswer(sid, q.id, picked.format(context));
      },
      child: Text(label, style: AppFonts.text14.regular.grey.style),
    );
  }

  // --- helpers (unchanged + a tiny new one) ---

  int _sec(TimeOfDay t) => t.hour * 3600 + t.minute * 60;

  String? _formatStoredTime(String? input, BuildContext context) {
    final t = _parseTimeFlexible(input);
    if (t == null) return null;
    return t.format(context);
  }

  TimeOfDay? _parseTimeFlexible(String? input) {
    if (input == null) return null;
    final s = input.trim();
    if (s.isEmpty) return null;

    final isoMatch = RegExp(r'T(\d{2}):(\d{2})').firstMatch(s);
    if (isoMatch != null) {
      final h = int.tryParse(isoMatch.group(1)!);
      final m = int.tryParse(isoMatch.group(2)!);
      if (h != null && m != null) return TimeOfDay(hour: h, minute: m);
    }

    final r12 = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*([AaPp][Mm])\s*$');
    final m12 = r12.firstMatch(s);
    if (m12 != null) {
      int h = int.parse(m12.group(1)!);
      final int m = int.parse(m12.group(2)!);
      final String ap = m12.group(3)!.toLowerCase();
      if (ap == 'pm' && h != 12) h += 12;
      if (ap == 'am' && h == 12) h = 0;
      if (h >= 0 && h <= 23 && m >= 0 && m <= 59) {
        return TimeOfDay(hour: h, minute: m);
      }
    }

    final r24 = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*$');
    final m24 = r24.firstMatch(s);
    if (m24 != null) {
      final h = int.parse(m24.group(1)!);
      final m = int.parse(m24.group(2)!);
      if (h >= 0 && h <= 23 && m >= 0 && m <= 59) {
        return TimeOfDay(hour: h, minute: m);
      }
    }

    return null;
  }
}
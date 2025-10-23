// info (display-only helper text)
import 'package:flutter/material.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/res/fonts.dart';

class QInfo extends StatelessWidget {
  final Question q;
  const QInfo(this.q, {super.key});

  @override
  Widget build(BuildContext context) {
    // Prefer the provided answer, then hint, then tooltip.
    final String text = (() {
      final a = q.answer?.toString().trim();
      if (a != null && a.isNotEmpty) return a;
      if ((q.hint ?? '').trim().isNotEmpty) return q.hint!.trim();
      if ((q.tooltip ?? '').trim().isNotEmpty) return q.tooltip!.trim();
      return '';
    })();

    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      // width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppFonts.text14.regular.style,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/res/fonts.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';

class QSingleChip extends StatelessWidget {
  final Question q;
  final BaseQuestionnaireNotifier n;
  final String sid;
  final List<Map<String, String>> items;

  const QSingleChip(this.q, this.n, this.sid, this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    final selectedId = (q.answer is String) ? q.answer as String? : null;

    return SizedBox(
      height: 160, // enough space for image + label
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items.map((item) {
            final id = item['id']!;
            final label = item['label']!;
            final asset = item['asset']!;
            final isSelected = id == selectedId;

            return GestureDetector(
              onTap: q.readOnly ? null : () => n.updateAnswer(sid, q.id, id),
              child: Container(
                width: 150,
                height: 150,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade50 : Colors.white,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        asset,
                        height: 80,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppFonts.text14.regular.style.copyWith(color: isSelected ? Colors.blue : Colors.black87,)
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
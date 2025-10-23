// likert / matrix (rows with radio columns)
import 'package:flutter/material.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';

class QLikertMatrix extends StatelessWidget {
  final Question q; final BaseQuestionnaireNotifier n; final String sid;
  const QLikertMatrix(this.q, this.n, this.sid);

  @override Widget build(BuildContext context) {
    final rows = q.matrixRows ?? const <AnswerOption>[];
    final cols = q.matrixColumns ?? const <AnswerOption>[];
    // store as map: rowId -> colId
    final Map<String, String> ans = Map<String, String>.from(q.answer ?? {});
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows.map((row) {
        final rowVal = ans[row.id];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(row.label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Wrap(
              children: cols.map((c) => SizedBox(
                width: 180,
                child: RadioListTile<String>(
                  value: c.id,
                  groupValue: rowVal,
                  title: Text(c.label),
                  onChanged: (v) {
                    ans[row.id] = v!;
                    n.updateAnswer(sid, q.id, Map<String, String>.from(ans));
                  },
                ),
              )).toList(),
            ),
            const Divider(height: 8),
          ],
        );
      }).toList(),
    );
  }
}
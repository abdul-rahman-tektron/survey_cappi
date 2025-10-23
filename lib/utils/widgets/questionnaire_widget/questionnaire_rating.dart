// rating (1..5 slider, you can swap to star widgets later)
import 'package:flutter/material.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';

class QRating extends StatelessWidget {
  final Question q; final BaseQuestionnaireNotifier n; final String sid;
  const QRating(this.q, this.n, this.sid);
  @override Widget build(BuildContext context) {
    final double val = (q.answer is num) ? (q.answer as num).toDouble() : 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          value: val.clamp(1, 5),
          min: 1, max: 5, divisions: 4,
          label: val.toStringAsFixed(0),
          onChanged: (v) => n.updateAnswer(sid, q.id, v.round()),
        ),
        Text('Selected: ${val.round()} / 5'),
      ],
    );
  }
}
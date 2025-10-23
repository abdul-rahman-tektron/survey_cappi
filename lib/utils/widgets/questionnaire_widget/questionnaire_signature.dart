// signature (placeholder: open a pad)
import 'package:flutter/material.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';

class QSignature extends StatelessWidget {
  final Question q; final BaseQuestionnaireNotifier n; final String sid;
  const QSignature(this.q, this.n, this.sid);
  @override Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.gesture),
          label: const Text('Capture signature'),
          onPressed: () async {
            // TODO: show Signature widget; save as png bytes/base64
            n.updateAnswer(sid, q.id, {'signatureId': 'mock-signature-xyz'});
          },
        ),
        const SizedBox(width: 8),
        Text(q.answer == null ? 'No signature' : 'Signature saved'),
      ],
    );
  }
}
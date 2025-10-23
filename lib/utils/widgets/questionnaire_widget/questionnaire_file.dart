// file (placeholder: fake file id)
import 'package:flutter/material.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';

class QFile extends StatelessWidget {
  final Question q; final BaseQuestionnaireNotifier n; final String sid;
  const QFile(this.q, this.n, this.sid);
  @override Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.attach_file),
          label: const Text('Attach file'),
          onPressed: () async {
            // TODO: integrate file_picker and update with picked file path/id
            n.updateAnswer(sid, q.id, {'fileId': 'mock-file-123', 'name': 'example.pdf'});
          },
        ),
        const SizedBox(width: 8),
        Text(q.answer == null ? 'No file' : (q.answer['name'] ?? 'Attached')),
      ],
    );
  }
}
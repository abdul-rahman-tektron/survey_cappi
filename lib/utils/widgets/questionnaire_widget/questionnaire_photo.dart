// photo (placeholder: fake photo id)
import 'package:flutter/material.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';

class QPhoto extends StatelessWidget {
  final Question q; final BaseQuestionnaireNotifier n; final String sid;
  const QPhoto(this.q, this.n, this.sid);
  @override Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.photo_camera),
          label: const Text('Take photo'),
          onPressed: () async {
            // TODO: integrate image_picker/camera; store bytes/path
            n.updateAnswer(sid, q.id, {'photoId': 'mock-photo-001'});
          },
        ),
        const SizedBox(width: 8),
        Text(q.answer == null ? 'No photo' : 'Photo captured'),
      ],
    );
  }
}
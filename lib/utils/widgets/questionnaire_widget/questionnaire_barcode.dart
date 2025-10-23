// barcode (placeholder: random code)
import 'package:flutter/material.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';

class QBarcode extends StatelessWidget {
  final Question q; final BaseQuestionnaireNotifier n; final String sid;
  const QBarcode(this.q, this.n, this.sid);
  @override Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan code'),
          onPressed: () async {
            // TODO: integrate mobile_scanner / barcode_scan2
            n.updateAnswer(sid, q.id, {'format': 'QR', 'value': 'MOCK-123456'});
          },
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(q.answer == null ? 'No code' : '${q.answer['format']}: ${q.answer['value']}')),
      ],
    );
  }
}
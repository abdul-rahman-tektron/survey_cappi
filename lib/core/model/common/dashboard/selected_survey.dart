import 'package:srpf/utils/enums.dart';

class SelectedSurvey {
  final QuestionnaireType type;
  final String code;        // e.g., FR6, PR6, PB1, PH3, "Dubai Airport"
  final String? label;      // optional human label if you want (shown in UI)

  SelectedSurvey({
    required this.type,
    required this.code,
    this.label,
  });

  Map<String, dynamic> toMap() => {
    'type': type.name,   // store enum as string
    'code': code,
    'label': label,
  };

  factory SelectedSurvey.fromMap(Map<String, dynamic> m) {
    final tStr = (m['type'] ?? '') as String;
    final type = QuestionnaireType.values.firstWhere(
          (e) => e.name == tStr,
      orElse: () => QuestionnaireType.freightRsi,
    );
    return SelectedSurvey(
      type: type,
      code: (m['code'] ?? '') as String,
      label: (m['label'] as String?)?.trim().isEmpty == true ? null : m['label'] as String?,
    );
  }
}
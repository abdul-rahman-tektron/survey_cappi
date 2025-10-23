// q_location_styled.dart
import 'package:flutter/material.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/res/api_constants.dart';
import 'package:srpf/screens/common/location/location_screen.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';
import 'package:srpf/utils/widgets/custom_textfields.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/images.dart';

class QLocation extends StatefulWidget {
  final Question q;
  final BaseQuestionnaireNotifier n;
  final String sid;

  const QLocation(this.q, this.n, this.sid, {super.key});

  @override
  State<QLocation> createState() => _QLocationState();
}

class _QLocationState extends State<QLocation> {
  late final TextEditingController _c;

  Question get q => widget.q;
  QuestionValidation? get v => q.validation;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: _labelFromAnswer(_currentAnswer()));
  }

  @override
  void didUpdateWidget(covariant QLocation oldWidget) {
    super.didUpdateWidget(oldWidget);
    final label = _labelFromAnswer(_currentAnswer());
    if (_c.text != label) _c.text = label;
  }

  dynamic _currentAnswer() => widget.n.valueOfGlobal(q.id) ?? q.answer;


  String _labelFromAnswer(dynamic ans) {
    if (ans is Map) {
      final name  = (ans['name'] ?? '').toString().trim();
      final label = (ans['label'] ?? '').toString().trim();
      final addr  = (ans['address'] ?? '').toString().trim();

      if (name.isNotEmpty)  return name;
      if (label.isNotEmpty) return label;
      if (addr.isNotEmpty)  return addr;

      final lat = ans['lat'] ?? ans['latitude'];
      final lng = ans['lng'] ?? ans['lon'] ?? ans['longitude']; // ← also accept 'lon'
      if (lat != null && lng != null) return '($lat, $lng)';
    }
    return '';
  }

  Future<void> _openPicker() async {
    if (q.readOnly == true) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SelectLocationMap(
          googleApiKey: ApiConstants.apiKey,
        ),
      ),
    );

    if (!mounted || result == null) return;

    final normalized = {
      'lat': (result['lat'] ?? result['latitude']) as double?,
      'lng': (result['lng'] ?? result['lon'] ?? result['longitude']) as double?, // ← accept lon
      'name': (result['name'] ?? '').toString(),                                  // ← add this
      'label': (result['label'] ?? result['address'] ?? '').toString(),
      'building': result['building'] ?? '',
      'block': result['block'] ?? '',
      'community': result['community'] ?? '',
    };

    final label = _labelFromAnswer(normalized);
    _c.text = label;
    widget.n.updateAnswer(widget.sid, q.id, normalized);
  }

  String? _validator(String? text) {
    final required = v?.required ?? false;
    final value = (text ?? '').trim();
    if (required && value.isEmpty) {
      return v?.errorMessage ?? 'Please select a location';
    }
    return null;
    // You can add more checks (e.g., must contain lat/lng) if needed.
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRequired = v?.required ?? false;
    final readOnly = q.readOnly == true;

    // We want the whole field to be tappable to open the picker,
    // but still render with CustomTextField’s styling.
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        // Make the whole area tappable
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: readOnly ? null : _openPicker,
          child: IgnorePointer( // prevent keyboard/caret; we only show text
            child: CustomTextField(
              controller: _c,
              fieldName: q.question,
              hintText: q.placeholder ?? q.hint ?? 'Pick location',
              isEditable: false,             // <- visual only; no typing
              isEnable: true,
              showAsterisk: isRequired,
              isMaxLines: false,             // single-line look (set true if you prefer wrap)
              titleVisibility: false,        // title shown by the form header
              useFieldNameAsLabel: false,    // avoid double label
              onChanged: (_) {},             // no-typing scenario
              validator: _validator,
            ),
          ),
        ),

        // Trailing map button (still visible even if read-only)
        Positioned(
          right: 8,
          child: InkWell(
            onTap: readOnly ? null : _openPicker,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                AppImages.mapMarker,
                width: 25,
                height: 25,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Repeated location using the same look & feel as above
class QRepeatLocation extends StatelessWidget {
  final Question base;
  final BaseQuestionnaireNotifier notifier;
  final String sectionId;
  final int index; // 1-based
  final String? labelOverride;

  const QRepeatLocation({
    super.key,
    required this.base,
    required this.notifier,
    required this.sectionId,
    required this.index,
    this.labelOverride,
  });

  String get repeatedId => '${base.id}__$index';

  @override
  Widget build(BuildContext context) {
    final q = base.copyWith(
      id: repeatedId,
      question: labelOverride ?? '${base.question} (Drop #$index)',
    );
    return QLocation(q, notifier, sectionId);
  }
}
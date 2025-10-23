import 'package:flutter/material.dart';
import 'package:srpf/utils/widgets/custom_textfields.dart';

class OtherCompanionField extends StatefulWidget {
  final String fieldKey;          // e.g., rsi_a5_1__other
  final String label;
  final String hint;
  final String initialText;
  final ValueChanged<String> onChanged;

  const OtherCompanionField({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.hint,
    required this.initialText,
    required this.onChanged,
  });

  @override
  State<OtherCompanionField> createState() => _OtherCompanionFieldState();
}

class _OtherCompanionFieldState extends State<OtherCompanionField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void didUpdateWidget(covariant OtherCompanionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the key (qid__other) changes, reset the text accordingly
    if (oldWidget.fieldKey != widget.fieldKey) {
      _controller.text = widget.initialText;
    } else if (oldWidget.initialText != widget.initialText &&
        // Only push external value in if user hasn't changed it since
        // (prevents cursor jumps if parent rebuilds mid-typing)
        _controller.text.isEmpty) {
      _controller.text = widget.initialText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: _controller,
      fieldName: widget.label,
      hintText: widget.hint,
      useFieldNameAsLabel: true,
      isEditable: true,
      isEnable: true,
      skipValidation: false, // required when Other is selected
      onChanged: widget.onChanged,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';

// where your CustomTextField lives:
import 'package:srpf/utils/widgets/custom_textfields.dart'; // <-- adjust path

class QNumber extends StatefulWidget {
  final Question q;
  final BaseQuestionnaireNotifier n;
  final String sid;

  const QNumber(this.q, this.n, this.sid, {super.key});

  @override
  State<QNumber> createState() => _QNumberState();
}

class _QNumberState extends State<QNumber> {
  late final TextEditingController _c;

  Question get q => widget.q;
  QuestionValidation? get v => q.validation;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: _asText(q.answer));
  }

  @override
  void didUpdateWidget(covariant QNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newText = _asText(q.answer);
    if (_c.text != newText) _c.text = newText;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String _asText(dynamic val) => (val == null) ? '' : val.toString();

  // Build input formatters for integer/decimal/currency
  List<TextInputFormatter> _formatters() {
    final allowNegative = (q.captureConfig?['allowNegative'] as bool?) ?? false;
    final maxLength = v?.maxLength;

    // Regex per numeric kind
    RegExp re;
    switch (v?.numericKind ?? NumericKind.any) {
      case NumericKind.integer:
        re = allowNegative ? RegExp(r'^-?\d*$') : RegExp(r'^\d*$');
        break;
      case NumericKind.currency:
      case NumericKind.decimal:
      case NumericKind.any:
      default:
      // allow 0..N digits + optional single dot + digits; optional leading '-'
        re = allowNegative
            ? RegExp(r'^-?(\d+)?(\.\d{0,})?$')
            : RegExp(r'^(\d+)?(\.\d{0,})?$');
        break;
    }

    final list = <TextInputFormatter>[
      FilteringTextInputFormatter.allow(re),
    ];
    if (maxLength != null) {
      list.add(LengthLimitingTextInputFormatter(maxLength));
    }
    return list;
  }

  String? _validator(String? text) {
    final txt = (text ?? '').trim();
    final required = v?.required ?? false;

    if (required && txt.isEmpty) {
      return v?.errorMessage ?? 'This field is required';
    }
    if (txt.isEmpty) return null; // optional & empty is fine

    // parse number safely
    final num? parsed = num.tryParse(txt);
    if (parsed == null) return v?.errorMessage ?? 'Enter a valid number';

    // integer constraint
    if ((v?.numericKind ?? NumericKind.any) == NumericKind.integer && txt.contains('.')) {
      return v?.errorMessage ?? 'Enter a whole number';
    }

    // bounds
    if (v?.minValue != null && parsed < v!.minValue!) {
      return v?.errorMessage ?? 'Must be ≥ ${v!.minValue}';
    }
    if (v?.maxValue != null && parsed > v!.maxValue!) {
      return v?.errorMessage ?? 'Must be ≤ ${v!.maxValue}';
    }

    // currency-specific: optionally clamp to 2dp if you want strictness
    if ((v?.numericKind ?? NumericKind.any) == NumericKind.currency) {
      final parts = txt.split('.');
      if (parts.length == 2 && parts[1].length > 2) {
        return v?.errorMessage ?? 'Max 2 decimal places';
      }
    }

    return null;
  }

  void _onChanged(String value) {
    // Store null when empty, else parsed number
    final trimmed = value.trim();
    final parsed = trimmed.isEmpty ? null : num.tryParse(trimmed);

    // If currency and there are >2 decimals, we still store the raw text until valid
    if ((v?.numericKind ?? NumericKind.any) == NumericKind.currency &&
        trimmed.contains('.') &&
        trimmed.split('.').length == 2 &&
        trimmed.split('.')[1].length > 2) {
      // keep text; don't push invalid numeric
      widget.n.updateAnswer(widget.sid, q.id, trimmed);
      return;
    }

    widget.n.updateAnswer(widget.sid, q.id, parsed);
  }

  @override
  Widget build(BuildContext context) {
    final isInteger = (v?.numericKind ?? NumericKind.any) == NumericKind.integer;
    final keyboard = isInteger ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true);

    // ① Allow config-driven suffix; ② fallback specifically for petrol cost
    final suffix = (q.captureConfig?['suffix'] as String?) ??
        (q.id == 'c9_cost' ? 'AED' : null);

    return CustomTextField(
      controller: _c,
      fieldName: q.question,
      hintText: q.placeholder ?? q.hint,
      keyboardType: keyboard,
      inputFormatters: _formatters(),
      isEditable: !q.readOnly,
      isEnable: true,
      showAsterisk: v?.required ?? false,
      titleVisibility: false,          // hide title row
      useFieldNameAsLabel: false,      // NEW: don’t float label with fieldName
      onChanged: _onChanged,
      validator: _validator,
      // Optionally show a currency prefix if captureConfig says so
      prefix: (v?.numericKind == NumericKind.currency)
          ? const Icon(Icons.currency_exchange_rounded, size: 18)
          : null,
      suffixText: suffix,
    );
  }
}
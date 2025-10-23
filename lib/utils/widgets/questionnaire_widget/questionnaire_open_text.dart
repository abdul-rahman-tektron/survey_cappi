import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';
import 'package:srpf/utils/widgets/custom_textfields.dart'; // adjust path to your CustomTextField

class QOpenText extends StatefulWidget {
  final Question q;
  final BaseQuestionnaireNotifier n;
  final String sid;

  const QOpenText(this.q, this.n, this.sid, {super.key});

  @override
  State<QOpenText> createState() => _QOpenTextState();
}

class _QOpenTextState extends State<QOpenText> {
  late final TextEditingController _c;

  Question get q => widget.q;
  QuestionValidation? get v => q.validation;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: (q.answer ?? '').toString());
  }

  @override
  void didUpdateWidget(covariant QOpenText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newText = (q.answer ?? '').toString();
    if (_c.text != newText) _c.text = newText;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String? _validator(String? text) {
    final txt = (text ?? '').trim();
    final required = v?.required ?? false;

    if (required && txt.isEmpty) {
      return v?.errorMessage ?? 'This field is required';
    }
    if (v?.minLength != null && txt.length < v!.minLength!) {
      return v?.errorMessage ?? 'Enter at least ${v?.minLength} characters';
    }
    if (v?.maxLength != null && txt.length > v!.maxLength!) {
      return v?.errorMessage ?? 'Enter at most ${v?.maxLength} characters';
    }
    if (v?.regexPattern != null && v!.regexPattern!.isNotEmpty) {
      final re = RegExp(v?.regexPattern! ?? "");
      if (!re.hasMatch(txt)) {
        return v?.errorMessage ?? 'Invalid format';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: _c,
      fieldName: q.question,
      hintText: q.placeholder ?? q.hint ?? 'Type your response...',
      isEditable: !q.readOnly,
      isEnable: true,
      showAsterisk: v?.required ?? false,
      titleVisibility: false,        // don’t repeat the title (already shown outside)
      useFieldNameAsLabel: false,    // prevent floating duplicate label
      onChanged: (v) => widget.n.updateAnswer(widget.sid, q.id, v),
      validator: _validator,
    );
  }
}
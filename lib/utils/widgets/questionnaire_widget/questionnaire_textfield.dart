import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';

// import where YOUR CustomTextField lives:
import 'package:srpf/utils/widgets/custom_textfields.dart'; // <-- adjust path if different

class QTextField extends StatefulWidget {
  final Question q;
  final BaseQuestionnaireNotifier n;
  final String sid;

  const QTextField(this.q, this.n, this.sid, {super.key});

  @override
  State<QTextField> createState() => _QTextFieldState();
}

class _QTextFieldState extends State<QTextField> {
  late final TextEditingController _c;

  Question get q => widget.q;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: (q.answer ?? '').toString());
  }

  @override
  void didUpdateWidget(covariant QTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // keep controller in sync if answer was programmatically changed
    final newText = (q.answer ?? '').toString();
    if (_c.text != newText) _c.text = newText;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // build inputFormatters from validation (length limiting only; pattern left to validator)
    final vf = q.validation;
    final formatters = <TextInputFormatter>[];
    if (vf?.maxLength != null) {
      formatters.add(LengthLimitingTextInputFormatter(vf!.maxLength));
    }

    return CustomTextField(
      controller: _c,
      fieldName: q.question,
      hintText: q.placeholder ?? q.hint,
      isPassword: (q.captureConfig?['isPassword'] as bool?) ?? false,
      isEditable: !q.readOnly,
      isEnable: true,
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.text,
      inputFormatters: formatters,
      titleVisibility: false,          // hide title row
      useFieldNameAsLabel: false,      // NEW: don’t float label with fieldName
      showAsterisk: vf?.required ?? false,
      onChanged: (v) => widget.n.updateAnswer(widget.sid, q.id, v),

      // use your app-wide validation look & feel; map QuestionValidation to message
      validator: (value) {
        final v = value ?? '';
        if ((vf?.required ?? false) && v.trim().isEmpty) {
          return vf?.errorMessage ?? 'This field is required';
        }
        if (vf?.minLength != null && v.length < vf!.minLength!) {
          return vf.errorMessage ?? 'Enter at least ${vf.minLength} characters';
        }
        if (vf?.maxLength != null && v.length > vf!.maxLength!) {
          return vf.errorMessage ?? 'Enter at most ${vf.maxLength} characters';
        }
        if (vf?.regexPattern != null && vf!.regexPattern!.isNotEmpty) {
          final re = RegExp(vf.regexPattern!);
          if (!re.hasMatch(v)) {
            return vf.errorMessage ?? 'Invalid format';
          }
        }
        return null;
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';

// import your styled dropdown
import 'package:srpf/utils/widgets/custom_search_dropdown.dart';

class QDropdown extends StatefulWidget {
  final Question q;
  final BaseQuestionnaireNotifier n;
  final String sid;

  const QDropdown(this.q, this.n, this.sid, {super.key});

  @override
  State<QDropdown> createState() => _QDropdownState();
}

class _QDropdownState extends State<QDropdown> {
  late final TextEditingController _controller;

  Question get q => widget.q;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _syncControllerWithAnswer();
  }

  @override
  void didUpdateWidget(covariant QDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllerWithAnswer();
  }

  void _syncControllerWithAnswer() {
    final opts = widget.n.getOptions(q);
    final String? ansId = q.answer is String ? q.answer as String : null;
    final sel = ansId == null
        ? null
        : opts.where((o) => o.id == ansId).cast<AnswerOption?>().firstOrDefault();

    final label = sel?.label ?? '';
    if (_controller.text != label) {
      _controller.text = label;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opts = widget.n.getOptions(q); // List<AnswerOption>

    final String? ansId = q.answer is String ? q.answer as String : null;
    final AnswerOption? initial = ansId == null
        ? null
        : opts.where((o) => o.id == ansId).cast<AnswerOption?>().firstOrDefault();

    final required = q.validation?.required ?? false;

    return CustomSearchDropdown<AnswerOption>(
      items: opts,
      fieldName: '',
      // avoid duplicate label; outer UI shows the question
      hintText: q.placeholder ?? q.hint ?? 'Select…',
      currentLang: 'en',
      initialValue: initial,
      isEnable: !q.readOnly,
      skipValidation: !required,

      // ✅ validator now matches String? signature
      validator: (String? val) {
        if (required && (val == null || val.trim().isEmpty)) {
          return q.validation?.errorMessage ?? 'Please select an option';
        }
        return null;
      },

      itemLabel: (AnswerOption item, String lang) => item.label,

      onSelected: (AnswerOption? sel) {
        final id = sel?.id;
        if (id == null) return;

        if (q.id == 'scr_type_select') {
          // just pass context; base defers safely
          widget.n.updateAnswer(widget.sid, q.id, id, context: context);
        } else {
          widget.n.updateAnswer(widget.sid, q.id, id, context: context);
        }
      },
    );
  }
}

// tiny extension to avoid try/catch noise
extension _FirstOrNull<E> on Iterable<E> {
  E? firstOrDefault() => isEmpty ? null : first;
}

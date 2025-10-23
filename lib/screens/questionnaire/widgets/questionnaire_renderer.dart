// questionnaire_renderer.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/res/fonts.dart';
// ⬇️ use the abstract base
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';
import 'package:srpf/utils/widgets/custom_textfields.dart';

// widgets
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_barcode.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_composite.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_date.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_date_time.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_dropdown.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_dropdown_multi.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_file.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_info.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_integer_stepper.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_liker_matrix.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_location.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_money_pair.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_multi_select.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_number.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_open_text.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_other_field.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_photo.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_radio.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_rating.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_signature.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_single_chip.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_textfield.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_time.dart';
import 'package:srpf/utils/widgets/questionnaire_widget/questionnaire_yes_no.dart';

class QuestionRenderer extends StatelessWidget {
  final Question question;
  final BaseQuestionnaireNotifier notifier;
  final String sectionId;
  final int index; // section-level numbering
  final bool _debugOther = true;

  const QuestionRenderer({
    super.key,
    required this.question,
    required this.notifier,
    required this.sectionId,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    String numbered(String label) {
      final shouldNumber = question.type != QuestionType.info;
      return shouldNumber ? '${index + 1}. $label' : label;
    }

    final bool isClone = (question.captureConfig?['__isClone'] == true);
    final isComposite = (question.captureConfig?['composite'] == true);
    final bool isRequired = (question.validation?.required == true);
    final bool suppressLabel = (question.captureConfig?['__suppressLabel'] == true);

    // composite
    if (isComposite) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _labelWidget('${index + 1}. ${question.question}', isRequired),
            const SizedBox(height: 8),
            QComposite(question, notifier, sectionId),
          ],
        ),
      );
    }

    // ⬇️ Special-case: info inline row
    if (question.type == QuestionType.info) {
      if (suppressLabel) {
        // Parent drew the label already; show only the value
        return QInfo(question);
      }
      // Inline (label left, value right)
      return _inlineRow(
        context: context,
        label: _labelWidget(question.question, false), // no numbering for info
        control: QInfo(question),
      );
    }

    // helpers
    dynamic _getAny(String id) {
      final all = notifier.getAllAnswers();
      for (final entry in all.values) {
        if (entry is Map && entry.containsKey(id)) return entry[id];
      }
      return null;
    }

    bool _eq(dynamic a, dynamic b) => a == b;

    final rcfg = question.captureConfig ?? const {};
    final String? repeatFromId = rcfg['repeatFrom'] as String?;
    final Map<String, dynamic>? guard = rcfg['repeatGuard'] as Map<String, dynamic>?;
    final String? repeatLabel = rcfg['repeatLabel'] as String?;

    Question _cloneForRepeat(Question base, {required String id, String? label}) {
      final cfg = Map<String, dynamic>.from(base.captureConfig ?? const {});
      cfg.remove('repeatFromSelectedOf');
      cfg.remove('repeatLabelTpl');
      cfg.remove('idSuffixFromOptionId');
      cfg['__suppressLabel'] = true;
      cfg['__isClone'] = true;

      // copy validation but force required on the clone
      final v = base.validation;
      final cloneValidation = v == null
          ? const QuestionValidation(required: true)
          : QuestionValidation(
        required: true, // ← force required on clones
        minSelections: v.minSelections,
        maxSelections: v.maxSelections,
        minLength: v.minLength,
        maxLength: v.maxLength,
        minValue: v.minValue,
        maxValue: v.maxValue,
        numericKind: v.numericKind,
      );

      return Question(
        id: id,
        question: label ?? base.question,
        type: base.type,
        options: base.options,
        catalog: base.catalog,
        hint: base.hint,
        placeholder: base.placeholder,
        tooltip: base.tooltip,
        defaultValue: base.defaultValue,
        shuffleOptions: base.shuffleOptions,
        readOnly: base.readOnly,
        visibleIf: base.visibleIf,
        requiredIf: base.requiredIf,
        validation: cloneValidation, // ← required for clones
        matrixRows: base.matrixRows,
        matrixColumns: base.matrixColumns,
        captureConfig: cfg,
        allowOtherOption: base.allowOtherOption,
        allowSpecialAnswers: base.allowSpecialAnswers,
        answer: null,
      );
    }
    // repeat N-from count
    if (repeatFromId != null) {
      bool guardOk = true;
      if (guard != null) {
        final gid = (guard['id'] as String?) ?? '';
        final gval = guard['value'];
        final cur = _getAny(gid);
        guardOk = _eq(cur, gval);
      }

      int count = 0;
      final rawCount = _getAny(repeatFromId);
      if (rawCount is num) count = rawCount.toInt();
      if (rawCount is String) count = int.tryParse(rawCount) ?? 0;

      if (guardOk && count > 0) {
        if (question.type == QuestionType.dateTime) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(count, (i) {
              final idx = i + 1;
              final labelText = (repeatLabel == null)
                  ? '${question.question} (Drop #$idx)'
                  : repeatLabel.replaceAll('%i', '$idx');
              final repeatedId = '${question.id}__$idx';
              final qClone = _cloneForRepeat(question, id: repeatedId, label: labelText);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _inlineRow(
                  context: context,
                  label: _labelWidget(numbered(question.question), isRequired),
                  control: QDateTime(qClone, notifier, sectionId),
                ),
              );
            }),
          );
        } else if (question.type == QuestionType.location) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(count, (i) {
              final idx = i + 1;
              final labelText = (repeatLabel == null)
                  ? '${question.question} (Drop #$idx)'
                  : repeatLabel.replaceAll('%i', '$idx');
              final repeatedId = '${question.id}__$idx';
              final qClone = _cloneForRepeat(question, id: repeatedId, label: labelText);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(labelText, style: AppFonts.text16.regular.style),
                    const SizedBox(height: 8),
                    QLocation(qClone, notifier, sectionId),
                  ],
                ),
              );
            }),
          );
        }
      }
    }

    // alpha suffix for 2a, 2b...
    String _alphaSuffix(int i) {
      const letters = 'abcdefghijklmnopqrstuvwxyz';
      String s = '';
      int n = i;
      do {
        s = letters[n % 26] + s;
        n = (n ~/ 26) - 1;
      } while (n >= 0);
      return s;
    }

    // --- REPEAT FROM SELECTED OF (clone per selected option) ---
    final String? repeatFromSelectedOf = rcfg['repeatFromSelectedOf'] as String?;
    final String labelTpl = (rcfg['repeatLabelTpl'] as String?) ?? question.question;
    final bool useOptionIdSuffix = rcfg['idSuffixFromOptionId'] == true;

    if (repeatFromSelectedOf != null && !isClone) {
      final sel = notifier.valueOfGlobal(repeatFromSelectedOf);

      // normalize to [{id,label}]
      final List<Map<String, String>> picks = [];
      if (sel is List) {
        for (final v in sel) {
          if (v is AnswerOption) {
            picks.add({'id': v.id, 'label': v.label});
          } else if (v is Map && v['id'] is String) {
            picks.add({'id': v['id'] as String, 'label': (v['label'] as String?) ?? (v['id'] as String)});
          } else if (v is String) {
            picks.add({'id': v, 'label': v});
          }
        }
      }

      if (picks.isEmpty) {
        // template renders nothing (avoid blank dividers)
        return const SizedBox.shrink();
      }

      Widget _oneClone(Map<String, String> opt, int idx) {
        final suffix = _alphaSuffix(idx);               // a, b, c...
        final numberedPrefix = '${index + 1}$suffix.';  // "2a."
        final newId = useOptionIdSuffix
            ? '${question.id}__${opt['id']}'
            : '${question.id}__${idx + 1}';

        final baseLabel = labelTpl.replaceAll('%label%', opt['label'] ?? '');
        final displayLabel = '$numberedPrefix $baseLabel';

        final existing = _answerForId(newId);           // ⬅️ hydrate

        final cfg = <String, dynamic>{
          '__suppressLabel': true,
          '__isClone': true,
        };

        final qClone = Question(
          id: newId,
          question: baseLabel,
          type: question.type,
          options: question.options,
          catalog: question.catalog,
          hint: question.hint,
          placeholder: question.placeholder,
          tooltip: question.tooltip,
          defaultValue: question.defaultValue,
          shuffleOptions: question.shuffleOptions,
          readOnly: question.readOnly,
          visibleIf: question.visibleIf,
          requiredIf: question.requiredIf,
          validation: question.validation,
          matrixRows: question.matrixRows,
          matrixColumns: question.matrixColumns,
          captureConfig: cfg,
          allowOtherOption: question.allowOtherOption,
          allowSpecialAnswers: question.allowSpecialAnswers,
          answer: existing,                             // ⬅️ use stored value
        );

        final isReq = (qClone.validation?.required == true);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _labelWidget(displayLabel, isReq),
              const SizedBox(height: 8),
              // Force a clean rebuild per clone id
              KeyedSubtree(
                key: ValueKey('ctrl_$newId'),           // ⬅️ stable key
                child: _buildControlFor(qClone),
              ),
              if (_shouldShowOtherField(qClone)) ...[
                const SizedBox(height: 8),
                _buildOtherCompanion(context, qClone),
              ],
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (var i = 0; i < picks.length; i++) _oneClone(picks[i], i)],
      );
    }

    // normal rendering
    final Widget control = _buildControlFor(question);

    final showOther = _shouldShowOtherField(question);

    if (suppressLabel) {
      // parent clone drew the label already
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          control,
          if (showOther) ...[
            const SizedBox(height: 8),
            _buildOtherCompanion(context, question),
          ],
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelWidget(numbered(question.question), isRequired),
          const SizedBox(height: 8),
          control,
          if (showOther) ...[
            const SizedBox(height: 8),
            _buildOtherCompanion(context, question),
          ],
        ],
      ),
    );
  }

  // Renders the proper control widget for a given Question
  Widget _buildControlFor(Question q) {
    switch (q.type) {
      case QuestionType.textField:
        final useMoney = (q.captureConfig?['moneyPair'] == true);
        final useComposite = (q.captureConfig?['composite'] == true);
        if (useMoney) return QMoneyPair(q, notifier, sectionId);
        if (useComposite) return QComposite(q, notifier, sectionId);
        return QTextField(q, notifier, sectionId);

      case QuestionType.number:
        if (q.validation?.numericKind == NumericKind.integer) {
          return QIntegerStepper(q, notifier, sectionId);
        }
        return QNumber(q, notifier, sectionId);

      case QuestionType.dropdown:
        return QDropdown(q, notifier, sectionId);

      case QuestionType.radio:
        return QRadioChips(q, notifier, sectionId);

      case QuestionType.chipsSingle:
        final items = (q.captureConfig?['items'] as List?)?.cast<Map<String, String>>() ?? [];
        return QSingleChip(q, notifier, sectionId, items);

      case QuestionType.checkbox:
      case QuestionType.multiSelect:
        if (q.id == 'rsi_b4_single' || q.id == 'rsi_b4_multiple') {
          return QDropdownMulti(q, notifier, sectionId);
        }
        return QMultiSelectChips(q, notifier, sectionId);

      case QuestionType.date:
        return QDate(q, notifier, sectionId);

      case QuestionType.time:
        return QTime(q, notifier, sectionId);

      case QuestionType.dateTime:
        return QDateTime(q, notifier, sectionId);

      case QuestionType.openText:
        return QOpenText(q, notifier, sectionId);

      case QuestionType.yesNo:
        return QYesNo(q, notifier, sectionId);

      case QuestionType.rating:
        return QRating(q, notifier, sectionId);

      case QuestionType.likert:
      case QuestionType.matrix:
        return QLikertMatrix(q, notifier, sectionId);

      case QuestionType.file:
        return QFile(q, notifier, sectionId);

      case QuestionType.photo:
        return QPhoto(q, notifier, sectionId);

      case QuestionType.signature:
        return QSignature(q, notifier, sectionId);

      case QuestionType.location:
        return QLocation(q, notifier, sectionId);

      case QuestionType.barcode:
        return QBarcode(q, notifier, sectionId);

      case QuestionType.info:
        return QInfo(q);

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _labelWidget(String text, bool required) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text, style: AppFonts.text16.regular.style),
          if (required)
            TextSpan(
              text: ' *',
              style: AppFonts.text16.regular.style.copyWith(color: Colors.red),
            ),
        ],
      ),
    );
  }

  Widget _inlineRow({
    required BuildContext context,
    required Widget label,
    required Widget control,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: DefaultTextStyle(
              style: AppFonts.text16.regular.style,
              child: label,
            ),
          ),
          10.horizontalSpace,
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 160, maxWidth: 220),
            child: Align(alignment: Alignment.centerRight, child: control),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // "Other" handling
  // ────────────────────────────────────────────────────────────

  String? _normalizeId(dynamic v) {
    try {
      if (v == null) return null;
      if (v is String) return v.trim();
      if (v.runtimeType.toString() == 'AnswerOption') {
        final id = (v as dynamic).id;
        if (id is String) return id.trim();
      }
      if (v is Map && v['id'] is String) return (v['id'] as String).trim();
    } catch (_) {}
    return null;
  }

  bool _shouldShowOtherField(Question q) {
    final supportsOther =
        q.type == QuestionType.dropdown || q.type == QuestionType.radio || q.type == QuestionType.multiSelect;
    if (!supportsOther) return false;
    if (q.allowOtherOption != true) return false;

    final hydrated = notifier.getOptions(q);
    final opts = q.options ?? const <AnswerOption>[];
    final allOptions = hydrated.isNotEmpty ? hydrated : opts;
    if (allOptions.isEmpty) return false;

    final otherIds = allOptions.where((o) => o.isOther == true).map((o) => o.id.trim()).toSet();
    if (otherIds.isEmpty) return false;

    final ans = q.answer;
    if (ans is! List) {
      final id = _normalizeId(ans);
      return id != null && otherIds.contains(id);
    }

    for (final item in ans) {
      final id = _normalizeId(item);
      if (id != null && otherIds.contains(id)) return true;
    }
    return false;
  }

  dynamic _answerForId(String id) {
    final all = notifier.getAllAnswers();
    final sec = all[sectionId];
    if (sec is Map && sec.containsKey(id)) return sec[id];
    return null;
  }

  dynamic _flatAnswerOf(String key) {
    final all = notifier.getAllAnswers();
    for (final sec in all.values) {
      if (sec is Map && sec.containsKey(key)) {
        final v = sec[key];
        if (_debugOther) debugPrint('OTHER.read key=$key -> $v');
        return v;
      }
    }
    if (_debugOther) debugPrint('OTHER.read key=$key -> <null>');
    return null;
  }

  Widget _buildOtherCompanion(BuildContext context, Question q) {
    final otherKey = '${q.id}__other';
    final current = _flatAnswerOf(otherKey) ?? '';

    if (_debugOther) {
      debugPrint('OTHER.widget qid=${q.id} otherKey=$otherKey init="$current"');
    }

    return OtherCompanionField(
      key: ValueKey(otherKey),
      fieldKey: otherKey,
      label: 'Other',
      hint: 'Specify Here',
      initialText: current.toString(),
      onChanged: (txt) {
        if (_debugOther) debugPrint('OTHER.update $otherKey="$txt"');
        notifier.updateAnswer(sectionId, otherKey, txt);
      },
    );
  }
}
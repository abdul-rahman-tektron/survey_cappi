// flows/common/base_questionnaire_notifier.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:srpf/core/base/base_notifier.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/utils/enums.dart';

/// Base class with all *shared* questionnaire behavior.
/// Extend this for RSI and Passenger flows. Keep flow-specific code
/// (sections wiring, catalog API, submission payload, hard screening)
/// in the subclasses.
abstract class BaseQuestionnaireNotifier extends BaseChangeNotifier {
  BaseQuestionnaireNotifier(this.context, {required this.questionnaireType}) {
    // Subclasses should call buildInitialSections() inside onInit(),
    // but we still start the timer immediately.
    _startTimer();
    onInit(context);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Dependencies / context
  // ───────────────────────────────────────────────────────────────────────────

  @protected
  final BuildContext context;

  // The high-level flow that this instance represents (nullable for the
  // initial selector screen).
  QuestionnaireType? questionnaireType;

  int elapsedOffsetSeconds = 0;

  // ───────────────────────────────────────────────────────────────────────────
  // Primary state
  // ───────────────────────────────────────────────────────────────────────────

  List<QuestionnaireSection>? sections;
  int currentStep = 0;
  int furthestStep = 0;
  String? lastError;

  String? _queuedTypeChange;

  // Prevent changing type again once chosen.
  bool _typeLocked = false;

  // ───────────────────────────────────────────────────────────────────────────
  // Timer
  // ───────────────────────────────────────────────────────────────────────────

  DateTime? startedAt;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;

  String get elapsedText {
    final total = _elapsed.inSeconds + elapsedOffsetSeconds;
    final mm = (total ~/ 60).toString().padLeft(2, '0');
    final ss = (total % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  void _startTimer() {
    startedAt ??= DateTime.now();
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed = DateTime.now().difference(startedAt!);
      notifyListeners();
    });
  }

  @protected
  void stopTimer({bool reset = false}) {
    _ticker?.cancel();
    _ticker = null;
    if (reset) {
      startedAt = null;
      _elapsed = Duration.zero;
    }
    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Catalogs / options
  // ───────────────────────────────────────────────────────────────────────────

  /// Simple in-memory catalogs. Subclasses can fill/override per flow.
  @protected
  final Map<String, List<AnswerOption>> catalogs = {};

  /// Allow subclasses to push/replace a catalog after an API call.
  @protected
  void setCatalog(String key, List<AnswerOption> options, {bool notify = true}) {
    catalogs[key] = options;
    if (notify) notifyListeners();
  }

  List<AnswerOption> getOptions(Question q) {
    if (q.options != null) return q.options!;
    if (q.catalog != null) return catalogs[q.catalog!.key] ?? const [];
    return const [];
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Extras (for “Other” companions, repeat instances, etc.)
  // ───────────────────────────────────────────────────────────────────────────

  final Map<String, Map<String, dynamic>> _extraBySection = {}; // sectionId -> {key: value}

  @protected
  void setExtra(String sectionId, String key, dynamic value) {
    final m = _extraBySection.putIfAbsent(sectionId, () => {});
    m[key] = value;
    notifyListeners();
  }

  dynamic _getExtraByKey(String key) {
    for (final entry in _extraBySection.entries) {
      if (entry.value.containsKey(key)) return entry.value[key];
    }
    return null;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Visibility
  // ───────────────────────────────────────────────────────────────────────────

  bool isVisible(Question q) {
    // hide if captureConfig says so
    final cfg = q.captureConfig ?? const {};
    if (cfg['autoHidden'] == true) return false;

    if (q.visibleIf == null) return true;
    return _evalGroup(q.visibleIf!);
  }

  bool _evalGroup(ConditionGroup g) {
    final results = g.atoms.map(_evalAtom).toList();
    return g.join == LogicJoin.and ? results.every((e) => e) : results.any((e) => e);
  }

// BaseQuestionnaireNotifier.dart

  bool _evalAtom(ConditionAtom a) {
    final v = valueOfGlobal(a.questionId); // 👈 global
    switch (a.op) {
      case Operator.equals:    return v == a.value;
      case Operator.notEquals: return v != a.value;
      case Operator.inList:    return (a.value as List).contains(v);
      case Operator.notInList: return !(a.value as List).contains(v);
      case Operator.isEmpty:   return v == null || (v is String && v.isEmpty) || (v is List && v.isEmpty);
      case Operator.notEmpty:  return !(v == null || (v is String && v.isEmpty) || (v is List && v.isEmpty));
      default:                 return false;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Auto-capture (date/time/now…). Call this whenever (re)building sections.
  // ───────────────────────────────────────────────────────────────────────────

  @protected
  void applyAutoCapture() {
    if (sections == null) return;


    for (final s in sections!) {
      for (final q in s.questions) {
        final cfg = q.captureConfig ?? const {};
        if (cfg.isEmpty) continue;

        final auto = cfg['autoNow'];
        final overwrite = cfg['autoOverwrite'] == true;

        if (auto is String) {
          if (overwrite ||
              q.answer == null ||
              (q.answer is String && (q.answer as String).trim().isEmpty)) {
            q.answer = _autoValueFor(auto, cfg);
          }
        }
      }
    }

    // 👇 Seed rsi_b2 when multi-drop is selected and value is missing/too small.
    final isLoaded = valueOfGlobal('rsi_a8') == 'loaded';
    final isMulti  = valueOfGlobal('rsi_b1') == 'multi';
    if (isLoaded && isMulti) {
      final qB2 = _findQuestionById('rsi_b2');
      if (qB2 != null) {
        final int min = (qB2.validation?.minValue ?? 2).toInt();
        final dynamic cur = qB2.answer;
        final bool needsSeed = cur == null ||
            (cur is num && cur.toInt() < min) ||
            (cur is String && (int.tryParse(cur) ?? 0) < min);
        if (needsSeed) {
          qB2.answer = min;  // commit minimum (respects your new min=2)
        }
      }
    }
  }

  List<AnswerOption> optionsFor(String qid) => _optionsForQid(qid); // your existing logic

  String? sectionIdFor(String qid) {
    for (final s in (sections ?? const [])) {
      if (s.questions.any((q) => q.id == qid)) return s.id;
    }
    return null;
  }

  @protected
  List<AnswerOption> _optionsForQid(String qid) {
    final q = _findQuestionById(qid);
    if (q == null) return const [];

    // 1) Inline options on the question
    if (q.options != null && q.options!.isNotEmpty) {
      return q.options!;
    }

    // 2) Catalog-backed options
    if (q.catalog != null) {
      return catalogs[q.catalog!.key] ?? const [];
    }

    // 3) captureConfig-provided items (fallback)
    final items = q.captureConfig?['items'];
    if (items is List) {
      final out = <AnswerOption>[];
      for (final it in items) {
        if (it is Map) {
          final id = it['id']?.toString();
          final label = (it['label'] ?? it['name'] ?? it['title'])?.toString();
          if (id != null && (label?.trim().isNotEmpty ?? false)) {
            out.add(AnswerOption(id: id, label: label!.trim()));
          }
        }
      }
      return out;
    }

    return const [];
  }

  // ⬇️ add this private helper anywhere in BaseQuestionnaireNotifier
  Question? _findQuestionById(String qid) {
    for (final s in sections ?? const []) {
      for (final q in s.questions) {
        if (q.id == qid) return q;
      }
    }
    return null;
  }

  dynamic _autoValueFor(String auto, Map<String, dynamic> cfg) {
    switch (auto) {
      case 'dateTime':
        return DateTime.now().toIso8601String();
      case 'time':
        final now = DateTime.now();
        final hh = now.hour.toString().padLeft(2, '0');
        final mm = now.minute.toString().padLeft(2, '0');
        return '$hh:$mm';
      case 'date':
        final now = DateTime.now();
        final y = now.year.toString().padLeft(4, '0');
        final m = now.month.toString().padLeft(2, '0');
        final d = now.day.toString().padLeft(2, '0');
        return '$y-$m-$d';
      default:
        return null;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Answers
  // ───────────────────────────────────────────────────────────────────────────

  Map<String, dynamic> getAllAnswers() {
    final out = <String, Map<String, dynamic>>{
      for (var s in sections ?? []) s.id: {for (var q in s.questions) q.id: q.answer},
    };

    // merge extras per section
    _extraBySection.forEach((secId, extras) {
      out.putIfAbsent(secId, () => {});
      out[secId]!.addAll(extras);
    });

    return out;
  }

  dynamic valueOfGlobal(String qid) {
    final all = getAllAnswers();
    for (final sec in all.values) {
      if (sec is Map && sec.containsKey(qid)) return sec[qid];
    }
    return null;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Update answers (safe type-switch handling)
  // ───────────────────────────────────────────────────────────────────────────

  /// Call this from widgets to update a question’s answer.
  /// Pass [context] when you’re updating the survey *type* selector so we can
  /// safely rebuild after the dropdown overlay is gone.
  // In BaseQuestionnaireNotifier.updateAnswer(...)

// In BaseQuestionnaireNotifier (or wherever updateAnswer lives)

  bool _isSwitchingType = false;

  @override
  void updateAnswer(String sectionId, String questionId, dynamic value, {BuildContext? context}) {
    _logD('updateAnswer(section=$sectionId, q=$questionId, value=$value) phase=${SchedulerBinding.instance.schedulerPhase}');


    final section = sections!.firstWhere((s) => s.id == sectionId, orElse: () => sections!.first);
    final q = section.questions.where((qq) => qq.id == questionId).toList();

    if (q.isNotEmpty) {
      q.first.answer = value;

      if (questionId == 'scr_type_select' && value is String && context != null) {
        if (_isSwitchingType) return;
        _isSwitchingType = true;
        _logD('TYPE SELECTED="$value"; deferring rebuild until overlay fully closes');
        _applyTypeAfterOverlay(context, value);     // ⟵ NEW
        return; // do not notify here
      }

      notifyListeners();
      return;
    }

    setExtra(sectionId, questionId, value);
    notifyListeners();
  }

  @override
  void notifyListeners() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle || phase == SchedulerPhase.postFrameCallbacks) {
      super.notifyListeners();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => super.notifyListeners());
    }
  }

  /// Robustly wait for the dropdown popup route to completely finish reversing
  /// before rebuilding sections.
  Future<void> _applyTypeAfterOverlay(BuildContext context, String typeId) async {
    try {
      // Wait for several end-of-frame cycles (route reverse runs during frames)
      await SchedulerBinding.instance.endOfFrame;
      await SchedulerBinding.instance.endOfFrame;
      await SchedulerBinding.instance.endOfFrame;

      // Add a small cushion to be extra-safe vs popup reverse duration
      await Future<void>.delayed(const Duration(milliseconds: 250));

      if (!context.mounted) return;

      _logD('Overlay settled. APPLY onTypeSelected("$typeId")');
      await onTypeSelected(typeId, context); // ⟵ IMPORTANT: use the abstract hook
    } finally {
      _isSwitchingType = false;
    }
  }


  void _logD(String msg) {
    final now = DateTime.now();
    final ts = '${now.minute.toString().padLeft(2,'0')}:'
        '${now.second.toString().padLeft(2,'0')}.'
        '${now.millisecond.toString().padLeft(3,'0')}';
    debugPrint('[$ts] $msg');
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Validation (composite, moneyPair, repeatFrom, “Other”, etc.)
  // ───────────────────────────────────────────────────────────────────────────

  String? validateCurrentStep() {
    final section = sections![currentStep];

    bool _isEmpty(dynamic v) =>
        v == null || (v is String && v.trim().isEmpty) || (v is List && v.isEmpty);

    String _qnumLabel(Question q, int i, Map<String, dynamic> rcfg) {
      return (rcfg['repeatLabel'] as String?)?.replaceAll('%i', '$i') ??
          '${q.question} (Item #$i)';
    }

    dynamic _get(String id) => valueOfGlobal(id);

    for (final q in section.questions) {
      if (!isVisible(q)) continue;

      // captureConfig
      final cfg = q.captureConfig ?? const {};

      // Composite sub-fields
      if (cfg['composite'] == true) {
        final fields = (cfg['fields'] as List?) ?? const [];
        final Map<String, dynamic> map =
        (q.answer is Map) ? Map<String, dynamic>.from(q.answer as Map) : const {};

        for (final raw in fields) {
          final f = Map<String, dynamic>.from(raw as Map);
          final fid = f['id'] as String;
          final label = (f['label'] as String?) ?? fid;
          final type = (f['type'] as String?) ?? 'text';
          final req = f['required'] == true;
          final min = f['min'] as num?;
          final max = f['max'] as num?;
          final allowDecimal = f['decimal'] == true;
          final subVal = map[fid];

          if (req && _isEmpty(subVal)) {
            return '${q.question}: "$label" is required';
          }

          if (type == 'number' && !_isEmpty(subVal)) {
            final num? parsed = num.tryParse(subVal.toString());
            if (parsed == null) return '${q.question}: "$label" must be a number';
            if (min != null && parsed < min) return '${q.question}: "$label" must be ≥ $min';
            if (max != null && parsed > max) return '${q.question}: "$label" must be ≤ $max';
            if (!allowDecimal && parsed is double && parsed % 1 != 0) {
              return '${q.question}: "$label" must be an integer';
            }
          }
        }
        // composite handled; continue
        continue;
      }

      // Money pair
      if (cfg['moneyPair'] == true) {
        final specialCfg = (cfg['specialToggle'] as Map?) ?? const {};
        final amountCfg = (cfg['amount'] as Map?) ?? const {};
        final currCfg = (cfg['currency'] as Map?) ?? const {};

        final specialKey = (specialCfg['key'] as String?) ?? 'special';
        final amountKey = (amountCfg['key'] as String?) ?? 'amount';
        final currKey = (currCfg['key'] as String?) ?? 'currency';

        final Map<String, dynamic> valMap =
        (q.answer is Map) ? Map<String, dynamic>.from(q.answer) : <String, dynamic>{};

        final bool special = (valMap[specialKey] as bool?) ?? false;

        if (!special) {
          final num? amount = (valMap[amountKey] is num) ? valMap[amountKey] as num : null;
          final String? curr = valMap[currKey] as String?;

          if (q.validation?.required == true) {
            if (amount == null) {
              return '${q.question}: please enter an amount (or mark Unknown/Refused)';
            }
            if (curr == null || curr.trim().isEmpty) {
              return '${q.question}: please select a currency (or mark Unknown/Refused)';
            }
          }

          final num? min = amountCfg['min'] is num ? amountCfg['min'] as num : null;
          final num? max = amountCfg['max'] is num ? amountCfg['max'] as num : null;
          if (amount != null && min != null && amount < min) {
            return '${q.question}: amount must be ≥ $min';
          }
          if (amount != null && max != null && amount > max) {
            return '${q.question}: amount must be ≤ $max';
          }
        }
      }

      // Repeats
      final String? repeatFromId = cfg['repeatFrom'] as String?;
      if (repeatFromId != null) {
        final Map<String, dynamic>? guard = cfg['repeatGuard'] as Map<String, dynamic>?;
        bool guardOk = true;
        if (guard != null) {
          final gid = (guard['id'] as String?) ?? '';
          final gval = guard['value'];
          guardOk = (_get(gid) == gval);
        }

        int count = 0;
        final rc = _get(repeatFromId);
        if (rc is num) count = rc.toInt();
        if (rc is String) count = int.tryParse(rc) ?? 0;

        if (guardOk && count > 0 && (q.validation?.required ?? false)) {
          for (int i = 1; i <= count; i++) {
            final key = '${q.id}__$i';
            final val = _get(key);
            if (_isEmpty(val)) {
              return 'Please answer: ${_qnumLabel(q, i, cfg)}';
            }
          }
          continue; // validated all repeats
        }
      }

      // Standard required
      final v = q.answer;
      final val = q.validation;

      if (val?.required == true && _isEmpty(v)) {
        return 'Please answer: ${q.question}';
      }

      // Number ranges
      if (q.type == QuestionType.number && v is num) {
        if (val?.minValue != null && v < val!.minValue!) {
          return '${q.question}: must be ≥ ${val.minValue}';
        }
        if (val?.maxValue != null && v > val!.maxValue!) {
          return '${q.question}: must be ≤ ${val.maxValue}';
        }
      }

      // Multi-select bounds
      if ((q.type == QuestionType.multiSelect || q.type == QuestionType.checkbox) && v is List) {
        if (val?.minSelections != null && v.length < val!.minSelections!) {
          return '${q.question}: select at least ${val.minSelections}';
        }
        if (val?.maxSelections != null && v.length > val!.maxSelections!) {
          return '${q.question}: select at most ${val!.maxSelections}';
        }
      }

      // “Other (specify)” companion
      final supportsOther = q.type == QuestionType.dropdown ||
          q.type == QuestionType.radio ||
          q.type == QuestionType.multiSelect;

      if (supportsOther && q.allowOtherOption == true) {
        final hydrated = getOptions(q);
        final base = q.options ?? const <AnswerOption>[];
        final allOptions = hydrated.isNotEmpty ? hydrated : base;

        if (allOptions.isNotEmpty) {
          final otherIds =
          allOptions.where((o) => (o.isOther ?? false)).map((o) => o.id.trim()).toSet();

          if (otherIds.isNotEmpty) {
            // gather selected “other” ids
            final selectedOtherIds = <String>{};
            final ans = q.answer;
            if (ans is String) {
              if (otherIds.contains(ans.trim())) selectedOtherIds.add(ans.trim());
            } else if (ans is List) {
              for (final e in ans) {
                if (e is String && otherIds.contains(e.trim())) {
                  selectedOtherIds.add(e.trim());
                }
              }
            }

            if (selectedOtherIds.isNotEmpty) {
              final otherMode = q.captureConfig?['otherMode'] ?? 'perQuestion';

              if (otherMode == 'perOption' && q.type == QuestionType.multiSelect) {
                for (final oid in selectedOtherIds) {
                  final key = '${q.id}__other__$oid';
                  final ov = valueOfGlobal(key);
                  if (_isEmpty(ov)) {
                    return '${q.question}: please specify for "Other" ($oid)';
                  }
                }
              } else {
                final key = '${q.id}__other';
                final ov = valueOfGlobal(key);
                if (_isEmpty(ov)) {
                  return '${q.question}: please specify for "Other"';
                }
              }
            }
          }
        }
      }
    }

    return null; // OK
  }

  /// Call this instead of rebuilding immediately when the survey type changes.
  /// It defers the heavy rebuild until after the current frame + overlay pop.
  void queueTypeSelection(BuildContext context, String typeId) {
    // collapse bursts of changes
    if (_queuedTypeChange != null) return;
    _queuedTypeChange = typeId;

    // Wait until after this frame (overlay is closing), then a tiny delay.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 1));
      if (!context.mounted) {
        _queuedTypeChange = null;
        return;
      }
      final id = _queuedTypeChange!;
      _queuedTypeChange = null;
      await onTypeSelected(id, context); // implemented by RSI/Passenger notifiers
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Navigation
  // ───────────────────────────────────────────────────────────────────────────

  // NEW: centralized step jumping that also tracks furthest reached.
  void goToStep(int i) {
    if (sections == null) return;
    if (i < 0 || i >= sections!.length) return;

    currentStep = i;
    if (currentStep > furthestStep) {
      furthestStep = currentStep;
    }
    notifyListeners();
  }

  /// Hook to allow subclasses to run screening gates, etc.
  /// Return false to abort advancing.
  @protected
  Future<bool> beforeAdvance(BuildContext context, QuestionnaireSection section) async {
    return true;
  }

  Future<void> nextStep(BuildContext context) async {
    final err = validateCurrentStep();
    if (err != null) {
      lastError = err;
      notifyListeners();
      return;
    }
    lastError = null;

    final section = sections![currentStep];

    // Subclass hook for screening/guards.
    if (!await beforeAdvance(context, section)) {
      // The hook must set any state/messages itself.
      notifyListeners();
      return;
    }

    // Normal advance with skip-empty sections
    final total = sections?.length ?? 0;
    var next = currentStep + 1;

    while (next < total && !_sectionHasVisibleQuestions(sections![next])) {
      next++;
    }

    if (next < total) {
      // was: currentStep = next; notifyListeners();
      currentStep = next;
      if (currentStep > furthestStep) {
        furthestStep = currentStep;        // NEW
      }
      notifyListeners();
    } else {
      // Final submit
      final answers = getAllAnswers();
      answers['__meta'] = {
        'duration_seconds': _elapsed.inSeconds,
        'duration_text': elapsedText,
        'started_at_iso': startedAt?.toIso8601String(),
        'submitted_at_iso': DateTime.now().toIso8601String(),
      };

      await onSubmit(context, answers);
      // Keep duration for any post-submit UI; do not reset here.
      notifyListeners();
    }
  }

  void previousStep() {
    var prev = currentStep - 1;
    while (prev >= 0 && !_sectionHasVisibleQuestions(sections![prev])) {
      prev--;
    }
    if (prev >= 0) {
      currentStep = prev;
      notifyListeners();
    }
  }

  bool _sectionHasVisibleQuestions(QuestionnaireSection s) {
    final anyVisible = s.questions.any(isVisible);
    final idx = sections?.indexOf(s) ?? -1;

    if (!anyVisible) {
      // 🔍 When nothing is visible, dump the precise reasons.
      debugDumpVisibilityForSection(idx);
    } else {
      debugPrint('👀 _sectionHasVisibleQuestions[$idx] "${s.title}" -> $anyVisible');
    }
    return anyVisible;
  }

  // BaseQuestionnaireNotifier.dart

  void debugDumpVisibilityForSection(int idx) {
    if (sections == null || idx < 0 || idx >= sections!.length) return;
    final s = sections![idx];
    debugPrint('🔎 Visibility dump for section [$idx] "${s.title}"');

    for (final q in s.questions) {
      final vis = isVisible(q);
      if (q.visibleIf == null) {
        debugPrint('  • ${q.id}  visible=${vis}  (no visibleIf)');
      } else {
        final atoms = q.visibleIf!.atoms;
        final parts = <String>[];
        for (final a in atoms) {
          final val = valueOfGlobal(a.questionId);
          parts.add('${a.questionId} ${a.op} ${a.value}  [got: $val]');
        }
        debugPrint('  • ${q.id}  visible=${vis}  because: ${parts.join(" ; ")}  join=${q.visibleIf!.join}');
      }
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Errors
  // ───────────────────────────────────────────────────────────────────────────

  void clearError() {
    lastError = null;
    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Life-cycle
  // ───────────────────────────────────────────────────────────────────────────

  /// Subclass should build sections here (e.g. initial selector vs. flow).
  @protected
  Future<void> onInit(BuildContext context);

  /// Safe handler for type selection. Subclass should:
  ///  - map the id to a QuestionnaireType
  ///  - rebuild sections (including screening page if needed)
  ///  - call applyAutoCapture()
  ///  - notifyListeners()
  @protected
  Future<void> onTypeSelected(String typeId, BuildContext context);

  Future<void> saveDraft(BuildContext context) async {}

  /// Called when the last step is validated; subclass should submit.
  /// `allAnswers` contains merged answers + extras + `__meta`.
  @protected
  Future<void> onSubmit(BuildContext context, Map<String, dynamic> allAnswers);

  // ───────────────────────────────────────────────────────────────────────────
  // Reset
  // ───────────────────────────────────────────────────────────────────────────

  @protected
  void resetQuestionnaire({
    bool unlockType = true,
    bool resetTimer = true,
    List<QuestionnaireSection>? freshSections,
  }) {
    for (final s in sections ?? const []) {
      for (final q in s.questions) {
        q.answer = null;
      }
    }

    lastError = null;
    _extraBySection.clear();

    if (resetTimer) {
      stopTimer(reset: true);
      _startTimer(); // restart fresh session timing
    }

    if (unlockType) _typeLocked = false;

    sections = freshSections ?? sections;
    currentStep = 0;
    furthestStep = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
import 'dart:collection';
import 'package:flutter/foundation.dart'; // for kDebugMode, debugPrint
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';

class SelectionMapper {
  /// Prefill a multi-select strictly by exact matches (case & punctuation sensitive).
  /// Set [debug] true to get detailed logs.
  static void prefillMultiSelect({
    required String qId,
    required dynamic rawValue, // List | String (CSV)
    required BaseQuestionnaireNotifier notifier,
    bool debug = true, // flip to false in production if you prefer
  }) {
    if (rawValue == null) {
      _log(debug, () => '[$qId] skip: rawValue=null');
      return;
    }

    _log(debug, () => '[$qId] rawValue: ${_safePreview(rawValue)}');

    final parts = _splitParts(rawValue);
    if (parts.isEmpty) {
      _log(debug, () => '[$qId] no tokens after split');
      return;
    }

    _log(debug, () => '[$qId] tokens (${parts.length}): ${_inspectList(parts)}');

    final options = _safeOptionsFor(notifier, qId);
    if (options.isEmpty) {
      _log(debug, () => '[$qId] no options resolved for this question');
      return;
    }

    // Print a compact snapshot of options
    final optSnap = options
        .take(8)
        .map((o) => '[id="${o.id}" | label="${o.label}"]')
        .join(', ');
    _log(debug, () => '[$qId] options count=${options.length}, sample: $optSnap${options.length > 8 ? ' …' : ''}');

    // exact lookup maps (case-sensitive)
    final labelToId = <String, String>{};
    final idToId = <String, String>{};
    for (final o in options) {
      final id = o.id.toString();
      final lbl = o.label.toString();
      idToId[id] = id;
      labelToId[lbl] = id;
    }

    final matched = <String>[];
    final seen = <String>{};

    for (var i = 0; i < parts.length; i++) {
      final raw = parts[i];
      final inp = raw.trim(); // only trim — no other normalization

      if (inp.isEmpty) {
        _log(debug, () => '[$qId] token[$i] is empty after trim → skip');
        continue;
      }

      _log(debug, () => '[$qId] token[$i]="${_show(inp)}" (len=${inp.length}, codeUnits=${inp.codeUnits})');

      String? id;

      // 1) exact ID match
      if (idToId.containsKey(inp)) {
        id = idToId[inp];
        _log(debug, () => '[$qId] token[$i] matched by **ID** → "$id"');
      } else if (labelToId.containsKey(inp)) {
        // 2) exact label match
        id = labelToId[inp];
        _log(debug, () => '[$qId] token[$i] matched by **LABEL** → "$id"');
      } else {
        // No match — show nearest hints (same length or same prefix) to spot subtle differences
        final nearby = <String>[];
        for (final k in labelToId.keys) {
          if (k.length == inp.length || (k.isNotEmpty && inp.startsWith(k[0]))) {
            nearby.add('"$k"');
          }
          if (nearby.length >= 6) break;
        }
        _log(debug, () => '[$qId] token[$i] no exact match. nearby labels: ${nearby.join(', ')}');
      }

      if (id != null && !seen.contains(id)) {
        seen.add(id);
        matched.add(id);
      }
    }

    if (matched.isEmpty) {
      _log(debug, () => '[$qId] matched → [] (no selections will be set)');
      return;
    }

    final sectionId = _safeSectionIdFor(notifier, qId);
    _log(debug, () => '[$qId] sectionId=${sectionId ?? "(not found)"}; writing matched=${matched}');

    if (sectionId != null) {
      notifier.updateAnswer(sectionId, qId, matched);
    }
    notifier.updateAnswer('__global', qId, matched);

    final q = _safeFindQuestion(notifier, qId);
    if (q != null) q.answer = matched;

    _log(debug, () => '[$qId] DONE. __global value now: ${notifier.valueOfGlobal(qId)}');
  }

  // ───────── helpers ─────────

  static List<String> _splitParts(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => (e ?? '').toString())
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    // allow comma or semicolon lists
    return raw
        .toString()
        .split(RegExp(r'[;,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<AnswerOption> _safeOptionsFor(BaseQuestionnaireNotifier n, String qId) {
    try {
      final m = n.optionsFor(qId);
      if (m is List<AnswerOption>) return m;
      if (m is List) return m.whereType<AnswerOption>().toList();
    } catch (_) {/* fall back */}

    final out = <AnswerOption>[];
    for (final s in (n.sections ?? const [])) {
      for (final q in s.questions) {
        if (q.id == qId) {
          if (q.options != null && q.options!.isNotEmpty) {
            out.addAll(q.options!);
          } else if (q.catalog != null) {
            final cat = n.catalogs[q.catalog!.key] ?? const <AnswerOption>[];
            out.addAll(cat);
          } else {
            final items = q.captureConfig?['items'];
            if (items is List) {
              for (final it in items) {
                if (it is Map) {
                  final id = it['id']?.toString();
                  final label = (it['label'] ?? it['name'] ?? it['title'])?.toString();
                  if (id != null && (label?.trim().isNotEmpty ?? false)) {
                    out.add(AnswerOption(id: id, label: label!.trim()));
                  }
                }
              }
            }
          }
          return out;
        }
      }
    }
    return out;
  }

  static String? _safeSectionIdFor(BaseQuestionnaireNotifier n, String qId) {
    try {
      final id = n.sectionIdFor(qId);
      if (id is String && id.isNotEmpty) return id;
    } catch (_) {/* fall back */}
    for (final s in (n.sections ?? const [])) {
      if (s.questions.any((q) => q.id == qId)) return s.id;
    }
    return null;
  }

  static Question? _safeFindQuestion(BaseQuestionnaireNotifier n, String qId) {
    for (final s in (n.sections ?? const [])) {
      for (final q in s.questions) {
        if (q.id == qId) return q;
      }
    }
    return null;
  }

  // logging helpers
  static void _log(bool enabled, String Function() msg) {
    if (enabled && kDebugMode) debugPrint(msg());
  }

  static String _inspectList(List<String> items) {
    return items
        .asMap()
        .entries
        .map((e) => '[${e.key}] "${_show(e.value)}" len=${e.value.length}')
        .join(', ');
  }

  static String _show(String s) {
    // show original string; escaping newlines/tabs for readability
    return s.replaceAll('\n', r'\n').replaceAll('\t', r'\t');
  }

  static String _safePreview(dynamic v) {
    final s = v.toString();
    return s.length > 200 ? '${s.substring(0, 200)}… (len=${s.length})' : s;
  }
}
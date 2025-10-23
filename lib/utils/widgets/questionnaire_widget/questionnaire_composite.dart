// lib/utils/widgets/questionnaire_widget/questionnaire_composite.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';
import 'package:srpf/utils/widgets/custom_search_dropdown.dart';
import 'package:srpf/utils/widgets/custom_textfields.dart';

class QComposite extends StatefulWidget {
  final Question q;
  final BaseQuestionnaireNotifier n;
  final String sid;

  const QComposite(this.q, this.n, this.sid, {super.key});

  @override
  State<QComposite> createState() => _QCompositeState();
}

class _QCompositeState extends State<QComposite> {
  Map<String, TextEditingController> _controllers = {};
  String? _unitValue;

  Map<String, dynamic> get _cfg => widget.q.captureConfig ?? const {};
  List<Map<String, dynamic>> get _fields => ((_cfg['fields'] as List?) ?? const [])
      .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
      .toList();

  Map<String, dynamic> _value() {
    final raw = widget.q.answer;
    return (raw is Map) ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  @override
  void initState() {
    super.initState();
    final v = _value();

    for (final f in _fields) {
      final fid = f['id'] as String;
      _controllers[fid] = TextEditingController(text: v[fid]?.toString() ?? '');
    }

    final unitCfg = (_cfg['unitPicker'] as Map?)?.cast<String, dynamic>();
    if (unitCfg != null) {
      final key = unitCfg['id'] as String? ?? 'unit';
      final def = unitCfg['default'] as String? ?? 't';
      _unitValue = (v[key]?.toString().isNotEmpty ?? false) ? v[key].toString() : def;

      if (!v.containsKey(key)) {
        // ❌ was: widget.n.updateAnswer(...);  // caused notify during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final next = {...v, key: _unitValue};
          widget.n.updateAnswer(widget.sid, widget.q.id, next);
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant QComposite oldWidget) {
    super.didUpdateWidget(oldWidget);
    final v = _value();
    for (final f in _fields) {
      final fid = f['id'] as String;
      final txt = v[fid]?.toString() ?? '';
      final c = _controllers[fid] ?? TextEditingController(text: txt);
      if (c.text != txt) c.text = txt;
      _controllers[fid] = c;
    }

    final unitCfg = (_cfg['unitPicker'] as Map?)?.cast<String, dynamic>();
    if (unitCfg != null) {
      final key = unitCfg['id'] as String? ?? 'unit';
      final newVal = _value()[key]?.toString();
      if (newVal != null && newVal != _unitValue) {
        setState(() => _unitValue = newVal);
      }
    }

    final validIds = _fields.map((f) => f['id'] as String).toSet();
    _controllers.keys.where((k) => !validIds.contains(k)).toList().forEach((k) {
      _controllers[k]?.dispose();
      _controllers.remove(k);
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save(String fid, String raw, {bool asNumber = false, bool decimal = true}) {
    final next = _value();
    if (asNumber) {
      final t = raw.trim();
      if (t.isEmpty) {
        next.remove(fid);
      } else {
        try {
          next[fid] = decimal ? num.parse(t) : int.parse(t);
        } catch (_) {
          next[fid] = raw; // let validation catch
        }
      }
    } else {
      next[fid] = raw;
    }
    widget.n.updateAnswer(widget.sid, widget.q.id, next);
  }

  void _saveUnit(String id) {
    final unitCfg = (_cfg['unitPicker'] as Map?)?.cast<String, dynamic>();
    final key = unitCfg?['id'] as String? ?? 'unit';
    final next = _value()..[key] = id;
    widget.n.updateAnswer(widget.sid, widget.q.id, next);
    setState(() => _unitValue = id);
  }

  Widget _unitPicker() {
    final unitCfg = (_cfg['unitPicker'] as Map?)?.cast<String, dynamic>();
    if (unitCfg == null) return const SizedBox.shrink();

    final fieldLabel = unitCfg['label'] as String? ?? 'Unit';
    final itemsRaw = ((unitCfg['items'] as List?) ?? const [])
        .map<Map<String, String>>((e) => Map<String, String>.from(e as Map))
        .toList();

    final items = itemsRaw
        .map((m) => AnswerOption(id: m['id'] ?? '', label: (m['label'] ?? '').trim()))
        .where((o) => o.id.isNotEmpty && o.label.isNotEmpty)
        .toList();

    final selected = items.firstWhere(
          (o) => o.id == _unitValue,
      orElse: () => items.isEmpty ? const AnswerOption(id: '', label: '') : items.first,
    );

    return CustomSearchDropdown<AnswerOption>(
      items: items,
      fieldName: fieldLabel,
      hintText: 'Select unit…',
      currentLang: 'en',
      initialValue: selected.id.isEmpty ? null : selected,
      isEnable: true,
      skipValidation: false,
      validator: (String? val) => (val == null || val.isEmpty) ? 'Please select a unit' : null,
      itemLabel: (AnswerOption it, String lang) => it.label,
      onSelected: (AnswerOption? sel) {
        if (sel == null) return;
        _saveUnit(sel.id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cfg['composite'] != true) return const SizedBox.shrink();

    Widget buildField(Map<String, dynamic> f) {
      final fid   = f['id'] as String;
      final label = (f['label'] as String?) ?? fid;
      final type  = (f['type'] as String?) ?? 'text';
      final required = f['required'] == true;
      final allowDecimal = f['decimal'] == true;
      final ctrl = _controllers[fid]!;

      switch (type) {
        case 'number':
          return CustomTextField(
            controller: ctrl,
            fieldName: label,
            keyboardType: TextInputType.number,
            hintText: 'Enter value',
            skipValidation: !required,
            onChanged: (txt) => _save(fid, txt, asNumber: true, decimal: allowDecimal),
          );
        default:
          return CustomTextField(
            controller: ctrl,
            fieldName: label,
            hintText: 'Type here…',
            skipValidation: !required,
            onChanged: (txt) => _save(fid, txt),
          );
      }
    }

    // 🔹 Responsive layout:
    // - Narrow (< 720): stack (fields + unit) vertically
    // - Wide (>= 720): two fields side-by-side + unit picker on the right (for exactly 2 fields)
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final bool narrow = w < 720; // tweak breakpoint to your taste (e.g., 640/768)

        // Exactly two fields → special side-by-side on wide; stacked on narrow
        if (_fields.length == 2) {
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: EdgeInsets.only(bottom: 8.h), child: buildField(_fields[0])),
                Padding(padding: EdgeInsets.only(bottom: 8.h), child: buildField(_fields[1])),
                _unitPicker(),
              ],
            );
          } else {
            final double unitWidth = (220.w).clamp(180, 280).toDouble();
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 8.w, bottom: 8.h),
                    child: buildField(_fields[0]),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 8.w, bottom: 8.h),
                    child: buildField(_fields[1]),
                  ),
                ),
                SizedBox(width: unitWidth, child: _unitPicker()),
              ],
            );
          }
        }

        // 3+ fields or 1 field → grid on wide, stacked on narrow
        if (!narrow) {
          // Two-column grid on wider screens
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: _fields.map((f) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      // half the width minus spacing
                      maxWidth: (w - 8.w) / 2,
                    ),
                    child: buildField(f),
                  );
                }).toList(),
              ),
              8.verticalSpace,
              _unitPicker(),
            ],
          );
        }

        // Stacked (narrow)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final f in _fields)
              Padding(padding: EdgeInsets.only(bottom: 8.h), child: buildField(f)),
            _unitPicker(),
          ],
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';

class QIntegerStepper extends StatefulWidget {
  final Question q;
  final BaseQuestionnaireNotifier n;
  final String sid;

  const QIntegerStepper(this.q, this.n, this.sid, {super.key});

  @override
  State<QIntegerStepper> createState() => _QIntegerStepperState();
}

class _QIntegerStepperState extends State<QIntegerStepper> {
  late int _value;
  late int _min;
  late int _max;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _min = (widget.q.validation?.minValue ?? 0).toInt();
    _max = (widget.q.validation?.maxValue ?? 999999).toInt();

    _value = _clamp(_coerceToInt(widget.q.answer, fallback: _min), _min, _max);
    _controller = TextEditingController(text: _value.toString());

    // ✅ Only seed the store if it's truly unset; don't overwrite future prefill.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = widget.q.answer;
      final bool isUnset = current == null || (current is String && current.isEmpty);
      if (isUnset) {
        widget.n.updateAnswer(widget.sid, widget.q.id, _value);
      }
    });
  }

  @override
  void didUpdateWidget(covariant QIntegerStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 🔄 If the incoming answer changed (e.g., prefilled to 2), reflect it.
    final incoming = _clamp(_coerceToInt(widget.q.answer, fallback: _min), _min, _max);
    if (incoming != _value) {
      setState(() {
        _value = incoming;
        // Keep TextField in sync without triggering an extra onChanged write-back.
        _controller.value = _controller.value.copyWith(
          text: incoming.toString(),
          selection: TextSelection.collapsed(offset: incoming.toString().length),
          composing: TextRange.empty,
        );
      });
    }
  }

  int _coerceToInt(dynamic v, {required int fallback}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final parsed = int.tryParse(v);
      return parsed ?? fallback;
    }
    return fallback;
  }

  int _clamp(int x, int lo, int hi) => x < lo ? lo : (x > hi ? hi : x);

  void _apply(int next) {
    next = _clamp(next, _min, _max);
    if (next == _value) return;
    setState(() {
      _value = next;
      _controller.text = next.toString();
    });
    widget.n.updateAnswer(widget.sid, widget.q.id, next);
  }

  void _onTextChanged(String val) {
    final parsed = int.tryParse(val);
    if (parsed == null) return; // ignore invalid input until valid
    final clamped = _clamp(parsed, _min, _max);
    setState(() => _value = clamped);
    widget.n.updateAnswer(widget.sid, widget.q.id, clamped);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.primary, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconBtn(
            icon: Icons.remove,
            onTap: () => _apply(_value - 1),
            enabled: _value > _min,
          ),
          SizedBox(
            width: 70,
            child: TextField(
              controller: _controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppFonts.text16.semiBold.style.copyWith(color: AppColors.primary),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                border: InputBorder.none,
              ),
              onChanged: _onTextChanged,
            ),
          ),
          _IconBtn(
            icon: Icons.add,
            onTap: () => _apply(_value + 1),
            enabled: _value < _max,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _IconBtn({required this.icon, required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final bg = enabled ? AppColors.primary : AppColors.primary.withOpacity(0.25);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 22, color: Colors.white),
      ),
    );
  }
}
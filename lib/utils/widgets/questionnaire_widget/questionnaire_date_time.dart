import 'package:flutter/material.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/res/fonts.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';
import 'package:srpf/res/colors.dart';

class QDateTime extends StatefulWidget {
  final Question q;
  final BaseQuestionnaireNotifier n;
  final String sid;

  const QDateTime(this.q, this.n, this.sid, {super.key});

  @override
  State<QDateTime> createState() => _QDateTimeState();
}

class _QDateTimeState extends State<QDateTime> {
  DateTime? _parsed;              // full parsed answer if present
  DateTime? _selectedDateOnly;    // carries just the date (Y-M-D, time = 00:00)
  TimeOfDay? _selectedTimeOnly;   // carries just the time (H:M)

  @override
  void initState() {
    super.initState();
    _hydrateFromAnswer();
  }

  @override
  void didUpdateWidget(covariant QDateTime oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If external answer changed, re-hydrate local selections.
    if (oldWidget.q.answer != widget.q.answer) {
      _hydrateFromAnswer();
    }
  }

  DateTime? get _minDt {
    final cfg = widget.q.captureConfig ?? const {};
    final s = cfg['minDateTimeIso'] as String?;
    return (s == null) ? null : DateTime.tryParse(s);
  }

  void _hydrateFromAnswer() {
    _parsed = null;
    try {
      final v = widget.q.answer;
      if (v != null && v.toString().isNotEmpty) {
        _parsed = DateTime.tryParse(v.toString());
      }
    } catch (_) {}

    if (_parsed != null) {
      _selectedDateOnly = DateTime(_parsed!.year, _parsed!.month, _parsed!.day);
      _selectedTimeOnly = TimeOfDay(hour: _parsed!.hour, minute: _parsed!.minute);
    } else {
      _selectedDateOnly = null;
      _selectedTimeOnly = null;
    }
  }

  void _tryCommitAndGuard() {
    if (_selectedDateOnly == null || _selectedTimeOnly == null) return;

    final dt = DateTime(
      _selectedDateOnly!.year,
      _selectedDateOnly!.month,
      _selectedDateOnly!.day,
      _selectedTimeOnly!.hour,
      _selectedTimeOnly!.minute,
    );

    widget.n.updateAnswer(widget.sid, widget.q.id, dt.toIso8601String());

    // Ask RSI notifier to recompute inter-field constraints
    final n = widget.n;
    // Only RsiQuestionnaireNotifier implements enforceTimingGuards
    try {
      // ignore: invalid_use_of_protected_member
      (n as dynamic).enforceTimingGuards();
    } catch (_) {
      // no-op for other flows
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final anchor = _selectedDateOnly ?? DateTime.now();
    final min = _minDt;

    final picked = await showDatePicker(
      context: context,
      firstDate: min != null
          ? DateTime(min.year, min.month, min.day)
          : DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: anchor.isBefore((min ?? anchor)) ? (min ?? anchor) : anchor,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.white,
            surface: AppColors.backgroundSecondary,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    setState(() {
      _selectedDateOnly = DateTime(picked.year, picked.month, picked.day);
    });

    // If the chosen date equals the min date, make sure the time is >= min time
    if (min != null && _selectedDateOnly != null) {
      final sameDay =
          _selectedDateOnly!.year == min.year &&
              _selectedDateOnly!.month == min.month &&
              _selectedDateOnly!.day == min.day;

      if (sameDay) {
        if (_selectedTimeOnly == null ||
            (_selectedTimeOnly!.hour < min.hour) ||
            (_selectedTimeOnly!.hour == min.hour &&
                _selectedTimeOnly!.minute < min.minute)) {
          // auto-bump to min time on that day
          _selectedTimeOnly = TimeOfDay(hour: min.hour, minute: min.minute);
        }
      }
    }

    _tryCommitAndGuard();
  }


  Future<void> _pickTime(BuildContext context) async {
    final anchor = _selectedTimeOnly ??
        (_parsed != null ? TimeOfDay.fromDateTime(_parsed!) : TimeOfDay.now());

    final picked = await showTimePicker(
      context: context,
      initialTime: anchor,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.white,
            surface: AppColors.backgroundSecondary,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    var finalTime = picked;

    // If we have a min and same day, clamp to min time
    final min = _minDt;
    if (min != null && _selectedDateOnly != null) {
      final sameDay =
          _selectedDateOnly!.year == min.year &&
              _selectedDateOnly!.month == min.month &&
              _selectedDateOnly!.day == min.day;

      if (sameDay) {
        final beforeMin =
            (picked.hour < min.hour) ||
                (picked.hour == min.hour && picked.minute < min.minute);
        if (beforeMin) {
          // Option A (gentle): clamp
          finalTime = TimeOfDay(hour: min.hour, minute: min.minute);

          // Optionally show a hint:
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(content: Text('Time adjusted to be after the start time.')),
          // );
        }
      }
    }

    setState(() {
      _selectedTimeOnly = finalTime;
    });

    _tryCommitAndGuard();
  }


  @override
  Widget build(BuildContext context) {
    final dateLabel = _selectedDateOnly == null
        ? 'Select date'
        : _formatDate(_selectedDateOnly!);

    final timeLabel = _selectedTimeOnly == null
        ? 'Select time'
        : _formatTime(_selectedTimeOnly!);

    return Row(
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.textSecondary, width: 0.5 ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          ),
          onPressed: () => _pickDate(context),
          child: Text(
            dateLabel,
            style: AppFonts.text14.regular.grey.style,
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.textSecondary, width: 0.5 ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          ),
          onPressed: () => _pickTime(context),
          child: Text(
            timeLabel,
            style: AppFonts.text14.regular.grey.style,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  String _formatTime(TimeOfDay t) {
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(hour12)}:${two(t.minute)} $ampm';
  }
}

/// Repeatable variant (for Drop #1, #2, etc.)
class QRepeatDateTime extends StatelessWidget {
  final Question base;
  final BaseQuestionnaireNotifier notifier;
  final String sectionId;
  final int index; // 1-based
  final String? labelOverride;

  const QRepeatDateTime({
    super.key,
    required this.base,
    required this.notifier,
    required this.sectionId,
    required this.index,
    this.labelOverride,
  });

  String get repeatedId => '${base.id}__${index}';

  @override
  Widget build(BuildContext context) {
    final q = base.copyWith(
      id: repeatedId,
      question: labelOverride ?? '${base.question} (Drop #$index)',
    );
    return QDateTime(q, notifier, sectionId);
  }
}
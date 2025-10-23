import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srpf/core/questions/model/sp_model.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';

class SpOptionCard extends StatefulWidget {
  final SpOption option;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const SpOptionCard({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
    this.disabled = false,
  });

  @override
  State<SpOptionCard> createState() => _SpOptionCardState();
}

class _SpOptionCardState extends State<SpOptionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    if (widget.selected) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant SpOptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.selected && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _handleTap() async {
    if (widget.disabled) return;                      // ⬅️ block
    HapticFeedback.selectionClick();
    setState(() => _pressed = true);
    await Future.delayed(const Duration(milliseconds: 90));
    if (mounted) setState(() => _pressed = false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final option = widget.option;
    final selected = widget.selected;
    final disabled = widget.disabled;

    final borderColor = disabled
        ? AppColors.shadowColor.withOpacity(0.4)
        : (selected ? AppColors.primary : AppColors.shadowColor);    final pastel = AppColors.primary;

    final scale = disabled ? 1.0 : (_pressed ? 0.98 : (selected ? 1.01 : 1.0));

    return IgnorePointer(
      ignoring: disabled,
      child: Opacity(
        opacity: disabled ? 0.55 : 1.0,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color:  AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: selected ? 2.0 : 0.8),
              ),
              child: Stack(
                children: [
                  // contents
                  Column(
                    children: [
                      // ───── Header (icon + label + highlight chip)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withOpacity(0.08)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              spIcon(option.mode),
                              size: 22,
                              color: selected ? AppColors.primary : AppColors.textBlue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  spLabel(option.mode),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFonts.text14.regular.style.copyWith(color: selected
                                      ? AppColors.primary
                                      : AppColors.secondary,)

                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ───── Details (middle)
                      Expanded(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: _DetailsGrid(option: option),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ───── Totals bar (bottom)
                      _TotalsBar(
                        totalCost: option.totalCost,
                        totalTime: option.totalTime,
                        selected: selected,
                        pastel: pastel,
                      ),
                    ],
                  ),

                  // top-right check ribbon on select
                  Positioned(
                    right: 0,
                    top: 0,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutBack,
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: disabled
                          ? _DisabledRibbon()      // ⬅️ NEW “Not applicable”
                          : (selected ? _CheckRibbon(color: AppColors.primary) : const SizedBox.shrink()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _pastelForMode(SpMode mode) {
    // All derived from your theme; stay in-brand but soft.
    switch (mode) {
      case SpMode.car:
        return AppColors.primary.withOpacity(0.65);
      case SpMode.bus:
        return AppColors.secondary.withOpacity(0.55);
      case SpMode.rail:
        return AppColors.textBlue.withOpacity(0.55);
      case SpMode.taxi:
      // slightly warmer pastel from primary
        return AppColors.primaryLight.withOpacity(0.70);
    }
  }
}

class _DisabledRibbon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(8, -8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.shadowColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Not applicable',
          style: AppFonts.text14.regular.style.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

/// Tiny highlight chip under the option title (unique feature).
class _HighlightChip extends StatelessWidget {
  final SpOption option;
  final Color pastel;
  const _HighlightChip({required this.option, required this.pastel});

  @override
  Widget build(BuildContext context) {
    final String text = _highlightText(option);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: pastel.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: pastel.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: AppFonts.text14.regular.style.copyWith(
          color: AppColors.secondary.withOpacity(0.95),
        ),
      ),
    );
  }

  String _highlightText(SpOption o) {
    // heuristic: prefer clearer signal if available
    if (o.totalCost != null && o.totalCost! > 0 && o.totalTime != null) {
      // soft judgement: if time relatively small vs cost present, highlight time
      if (o.totalTime! <= 25) return 'Quicker total time';
      if (o.totalCost! <= 10) return 'Lower total cost';
    }
    if (o.totalCost != null && o.totalCost! <= 10) return 'Lower total cost';
    if (o.totalTime != null && o.totalTime! <= 25) return 'Quicker total time';
    // fallback to mode label
    return spLabel(o.mode);
  }
}

class _CheckRibbon extends StatelessWidget {
  final Color color;
  const _CheckRibbon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(8, -8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.85),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              'Selected',
              style: AppFonts.text14.regular.white.style,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact details grid with soft “pills”, no dividers.
class _DetailsGrid extends StatelessWidget {
  final SpOption option;
  const _DetailsGrid({required this.option});

  @override
  Widget build(BuildContext context) {
    final items = <_DetailItem>[];

    switch (option.mode) {
      case SpMode.car:
        items.addAll([
          _DetailItem('Fuel', option.fuelCost == null ? '—' : '${option.fuelCost} AED', Icons.local_gas_station),
          _DetailItem('Tolls', option.tollsCost == null ? '—' : '${option.tollsCost} AED', Icons.payments_rounded),
          _DetailItem('Parking', option.parkingCost == null ? '—' : '${option.parkingCost} AED', Icons.local_parking_rounded),
        ]);
        break;

      case SpMode.rail:
        items.addAll([
          _DetailItem('To/from stations',
              option.timeToFromStations == null ? '—' : '${option.timeToFromStations} mins', Icons.transfer_within_a_station),
          _DetailItem('Time on train',
              option.timeOnTrain == null ? '—' : '${option.timeOnTrain} mins', Icons.train_rounded),
        ]);
        break;

      case SpMode.bus:
        items.addAll([
          _DetailItem('To/from stops',
              option.timeToFromBusStops == null ? '—' : '${option.timeToFromBusStops} mins', Icons.transfer_within_a_station ),
          _DetailItem('Time on bus',
              option.timeOnBus == null ? '—' : '${option.timeOnBus} mins', Icons.directions_bus_filled_rounded),
        ]);
        break;

      case SpMode.taxi:
        items.addAll([
          _DetailItem('Fare', option.totalCost == null ? 'Metered' : '${option.totalCost} AED', Icons.local_taxi_rounded),
        ]);
        break;
    }

    return LayoutBuilder(
      builder: (_, c) {
        final twoCols = c.maxWidth > 480; // tablet-friendly
        final itemW = twoCols ? (c.maxWidth - 12) / 2 : c.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: items
              .map((e) => SizedBox(width: itemW, child: _DetailTile(item: e)))
              .toList(),
        );
      },
    );
  }
}

class _DetailItem {
  final String label;
  final String value;
  final IconData icon;
  _DetailItem(this.label, this.value, this.icon);
}

class _DetailTile extends StatelessWidget {
  final _DetailItem item;
  const _DetailTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        // color: AppColors.background.withOpacity(0.65),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.label,
              style: AppFonts.text14.regular.style.copyWith(color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.value,
            style: AppFonts.text14.regular.style.copyWith(
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom totals bar with soft pastel accent.
class _TotalsBar extends StatelessWidget {
  final num? totalCost;
  final num? totalTime;
  final bool selected;
  final Color pastel;

  const _TotalsBar({
    required this.totalCost,
    required this.totalTime,
    required this.selected,
    required this.pastel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _pill(
          title: 'Total Cost',
          value: totalCost == null ? '—' : '${totalCost} AED',
        ),
        const SizedBox(width: 10),
        _pill(
          title: 'Total Time',
          value: totalTime == null ? '—' : '${totalTime} mins',
        ),
      ],
    );
  }

  Widget _pill({required String title, required String value}) {
    final borderColor = selected ? AppColors.primary : AppColors.shadowColor;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          // color: pastel.withOpacity(0.09),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: AppFonts.text14.regular.style.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
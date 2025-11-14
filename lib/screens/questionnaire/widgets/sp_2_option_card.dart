import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srpf/core/questions/model/sp_2_model.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';

class Sp2OptionCard extends StatefulWidget {
  final Sp2Option option;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;
  const Sp2OptionCard({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
    this.disabled = false,
  });

  @override
  State<Sp2OptionCard> createState() => _Sp2OptionCardState();
}

class _Sp2OptionCardState extends State<Sp2OptionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
      lowerBound: 0.0, upperBound: 1.0,
    );
    if (widget.selected) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant Sp2OptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !_pulse.isAnimating) _pulse.repeat(reverse: true);
    else if (!widget.selected && _pulse.isAnimating) { _pulse.stop(); _pulse.value = 0; }
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  void _handleTap() async {
    if (widget.disabled) return;
    HapticFeedback.selectionClick();
    setState(() => _pressed = true);
    await Future.delayed(const Duration(milliseconds: 90));
    if (mounted) setState(() => _pressed = false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.option;
    final selected = widget.selected;
    final disabled = widget.disabled;

    final borderColor = disabled
        ? AppColors.shadowColor.withOpacity(0.4)
        : (selected ? AppColors.primary : AppColors.shadowColor);
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
              child: Column(
                children: [
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
                        child: Icon(sp2Icon(o.mode),
                          size: 22,
                          color: selected ? AppColors.primary : AppColors.textBlue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sp2Label(o.mode),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.text14.regular.style.copyWith(
                            color: selected ? AppColors.primary : AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Expanded(child: _DetailsGrid2(option: o)),

                  const SizedBox(height: 10),
                  _TotalsBar2(
                    totalCost: o.totalCost,
                    totalTime: o.totalTime,
                    selected: selected,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailsGrid2 extends StatelessWidget {
  final Sp2Option option;
  const _DetailsGrid2({required this.option});

  @override
  Widget build(BuildContext context) {
    List<_Item> items = [];
    switch (option.mode) {
      case Sp2Mode.car:
        items = [
          _Item('Fuel', option.fuelCost == null ? '—' : '${option.fuelCost} AED', Icons.local_gas_station),
          _Item('Tolls', option.tollsCost == null ? '—' : '${option.tollsCost} AED', Icons.payments_rounded),
          _Item('Parking', option.parkingCost == null ? '—' : '${option.parkingCost} AED', Icons.local_parking_rounded),
        ];
        break;
      case Sp2Mode.taxi:
        items = [
          _Item('Fare', option.totalCost == null ? 'Metered' : '${option.totalCost} AED', Icons.local_taxi_rounded),
        ];
        break;
      case Sp2Mode.shuttle:
        items = [
          _Item('To/from shuttle', option.timeToFromShuttleStops == null ? '—' : '${option.timeToFromShuttleStops} mins', Icons.transfer_within_a_station),
          _Item('Time on shuttle', option.timeOnShuttle == null ? '—' : '${option.timeOnShuttle} mins', Icons.directions_bus_filled_rounded),
        ];
        break;
      case Sp2Mode.bus:
        items = [
          _Item('To/from stops', option.timeToFromBusStops == null ? '—' : '${option.timeToFromBusStops} mins', Icons.transfer_within_a_station),
          _Item('Time on bus', option.timeOnBus == null ? '—' : '${option.timeOnBus} mins', Icons.directions_bus_filled_rounded),
        ];
        break;
    }

    return LayoutBuilder(
      builder: (_, c) {
        final twoCols = c.maxWidth > 480;
        final itemW = twoCols ? (c.maxWidth - 12) / 2 : c.maxWidth;
        return Wrap(
          spacing: 12, runSpacing: 10,
          children: items.map((e) => SizedBox(width: itemW, child: _Tile(item: e))).toList(),
        );
      },
    );
  }
}

class _Item { final String k, v; final IconData icon; _Item(this.k, this.v, this.icon); }
class _Tile extends StatelessWidget {
  final _Item item; const _Tile({required this.item});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(item.icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(item.k, style: AppFonts.text14.regular.style.copyWith(color: AppColors.textSecondary))),
          const SizedBox(width: 8),
          Text(item.v, style: AppFonts.text14.regular.style.copyWith(color: AppColors.secondary)),
        ],
      ),
    );
  }
}

class _TotalsBar2 extends StatelessWidget {
  final num? totalCost;
  final num? totalTime;
  final bool selected;
  const _TotalsBar2({this.totalCost, this.totalTime, required this.selected});

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.primary : AppColors.shadowColor;
    Widget pill(String t, String v) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(children: [
          Text(t, style: AppFonts.text14.regular.style.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(v, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
    return Row(
      children: [
        pill('Total Cost', totalCost == null ? '—' : '${totalCost} AED'),
        const SizedBox(width: 10),
        pill('Total Time', totalTime == null ? '—' : '${totalTime} mins'),
      ],
    );
  }
}
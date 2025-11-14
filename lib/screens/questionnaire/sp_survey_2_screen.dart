import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:srpf/core/questions/model/sp_2_model.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';
import 'package:srpf/screens/questionnaire/flows/stated_preference/stated_preference_2_notifier.dart';
import 'package:srpf/screens/questionnaire/widgets/sp_2_option_card.dart';
import 'package:srpf/utils/helpers/loader.dart';
import 'package:srpf/utils/helpers/toast_helper.dart';
import 'package:srpf/utils/widgets/custom_appbar.dart';
import 'package:srpf/utils/widgets/custom_buttons.dart';
import 'package:srpf/utils/widgets/custom_drawer.dart';

class Sp2SurveyScreen extends StatelessWidget {
  final List<Sp2Set> initialSets;
  final int? interviewMasterId;
  final int continuedElapsedSec;
  final String? startedIso;

  const Sp2SurveyScreen({
    super.key,
    required this.initialSets,
    this.interviewMasterId,
    this.continuedElapsedSec = 0,
    this.startedIso,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Sp2SurveyNotifier(
        sets: initialSets,
        interviewMasterId: interviewMasterId,
        continuedElapsedSec: continuedElapsedSec,
        startedIso: startedIso,
      ),
      child: LoadingOverlay<Sp2SurveyNotifier>(
        child: SafeArea(child: const _Sp2Scaffold()),
      ),
    );
  }
}

class _Sp2Scaffold extends StatelessWidget {
  const _Sp2Scaffold();

  @override
  Widget build(BuildContext context) {
    final n = context.watch<Sp2SurveyNotifier>();
    final s = n.currentSet;

    return Scaffold(
      appBar: const CustomAppBar(showDrawer: true),
      drawer: const CustomDrawer(),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _referenceHeader(s, n.currentIndex + 1, n.totalSets),
            const SizedBox(height: 24),
            Text(
              'Which option would you prefer between Origin to Station or Station to Origin?',
              style: AppFonts.text22.regular.style,
            ),
            const SizedBox(height: 18),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.25,
                children: s.options.map((o) {
                  final selected = s.selectedIndex != null && s.options[s.selectedIndex!].mode == o.mode;
                  final isDisabled = (o.mode == Sp2Mode.car) && (s.carOwner == false);

                  return Sp2OptionCard(
                    option: o,
                    selected: selected,
                    disabled: isDisabled,
                    onTap: () => context.read<Sp2SurveyNotifier>().selectOption(o.mode),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),
            _footerBar(context, n),
          ],
        ),
      ),
    );
  }

  Widget _referenceHeader(Sp2Set s, int idx, int total) {
    Widget chip(String k, String v) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(24)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$k: ', style: AppFonts.text14.regular.style.copyWith(color: AppColors.textSecondary)),
        Text(v, style: AppFonts.text14.regular.style),
      ]),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.shadowColor.withOpacity(0.25), blurRadius: 6, offset: const Offset(0,3))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          chip('Ref', s.reference),
          chip('From', "Origin / Station"),
          chip('To', "Station / Origin"),
          chip('Car Owner', s.carOwner ? "Yes" : "No"),
          chip('Set', '$idx / $total'),
        ],
      ),
    );
  }

  Widget _footerBar(BuildContext context, Sp2SurveyNotifier n) {
    final isLast = n.currentIndex == n.totalSets - 1;
    final elapsed = context.select<Sp2SurveyNotifier, String>((x) => x.elapsedText);

    return Row(
      children: [
        if (n.canGoPrev) CustomButton(fullWidth: false, onPressed: n.prev, text: 'Back'),
        const Spacer(),
        _TimerPill(timeText: elapsed),
        const Spacer(),
        CustomButton(
          fullWidth: false,
          onPressed: () async {
            if (!isLast) { n.next(); return; }
            if (!n.isComplete) { ToastHelper.showError('Please select an option for every set.'); return; }
            await n.submitFinal(context); // will navigate home on success
          },
          text: isLast ? 'Submit' : 'Next',
        ),
      ],
    );
  }
}

class _TimerPill extends StatelessWidget {
  final String timeText;
  const _TimerPill({required this.timeText});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: AppColors.shadowColor.withOpacity(0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.timer_rounded, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(timeText, style: AppFonts.text16.semiBold.style.copyWith(color: AppColors.primary)),
      ]),
    );
  }
}
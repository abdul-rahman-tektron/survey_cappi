import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:srpf/core/questions/model/sp_model.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';
import 'package:srpf/screens/questionnaire/flows/stated_preference/stated_preference_notifier.dart';
import 'package:srpf/screens/questionnaire/widgets/sp_option_card.dart';
import 'package:srpf/utils/helpers/loader.dart';
import 'package:srpf/utils/helpers/toast_helper.dart';
import 'package:srpf/utils/widgets/custom_appbar.dart';
import 'package:srpf/utils/widgets/custom_buttons.dart';
import 'package:srpf/utils/widgets/custom_drawer.dart';

class SpSurveyScreen extends StatelessWidget {
  final List<SpSet> initialSets;
  final int? interviewMasterId;
  final int continuedElapsedSec;
  final String? surveyType;
  final String? startedIso;

  const SpSurveyScreen({
    super.key,
    required this.initialSets,
    this.interviewMasterId,
    this.continuedElapsedSec = 0,
    this.surveyType,
    this.startedIso,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        debugPrint('SP⏱ SpSurveyScreen ctor args → '
            'continuedElapsedSec=$continuedElapsedSec startedIso=$startedIso');
        return SpSurveyNotifier(
          sets: initialSets,
          interviewMasterId: interviewMasterId,
          continuedElapsedSec: continuedElapsedSec,
          surveyType: surveyType,
          startedIso: startedIso,
        );
      },
      child: LoadingOverlay<SpSurveyNotifier>(child: SafeArea(child: const _SpScaffold())),
    );
  }
}

class _SpScaffold extends StatelessWidget {
  const _SpScaffold();

  @override
  Widget build(BuildContext context) {
    final n = context.watch<SpSurveyNotifier>();
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

            // --- SURVEY QUESTION ---
            Text(
              'Which of these options would you prefer to use for a trip between '
              '${s.origin} and ${s.destination}?',
              style: AppFonts.text22.regular.style,
            ),
            const SizedBox(height: 18),

            // --- OPTIONS GRID (4 cards) ---
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.25,
                children: s.options.map((o) {
                  final selected =
                      s.selectedIndex != null && s.options[s.selectedIndex!].mode == o.mode;

                  // ⬇️ Disable Car if carOwner is false
                  final isDisabled = (o.mode == SpMode.car) && (s.carOwner == false);

                  return SpOptionCard(
                    option: o,
                    selected: selected,
                    disabled: isDisabled, // NEW
                    onTap: () => context.read<SpSurveyNotifier>().selectOption(o.mode),
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

  // ────────────────────────────── HEADER
  Widget _referenceHeader(SpSet s, int idx, int total) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _chip('Ref', s.reference),
          _chip('From', s.origin),
          _chip('To', s.destination),
          _chip('Car Owner', s.carOwner ? "Yes" : "No"),
          _chip('High Speed', s.hsRailRelevant ? "Yes" : "No"),
          _chip('Set', '$idx / $total'),
        ],
      ),
    );
  }

  Widget _chip(String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$k: ',
            style: AppFonts.text14.regular.style.copyWith(color: AppColors.textSecondary),
          ),
          Text(v, style: AppFonts.text14.regular.style),
        ],
      ),
    );
  }

  // ────────────────────────────── FOOTER
  Widget _footerBar(BuildContext context, SpSurveyNotifier n) {
    final isLast = n.currentIndex == n.totalSets - 1;
    final elapsed = context.select<SpSurveyNotifier, String>((x) => x.elapsedText);

    return Row(
      children: [
        if (n.canGoPrev) CustomButton(fullWidth: false, onPressed: n.prev, text: 'Back'),
        const Spacer(),

        // ⏱️ pretty time pill
        _TimerPill(timeText: elapsed),

        const Spacer(),
        CustomButton(
          fullWidth: false,
          onPressed: () async {
            if (!isLast) {
              n.next();
              return;
            }
            if (!n.isComplete) {
              _toast(context, 'Please select an option for every set.');
              return;
            }
            await n.submitFinal(context);
          },
          text: isLast ? 'Submit' : 'Next',
        ),
      ],
    );
  }

  void _toast(BuildContext context, String msg) {
    ToastHelper.showError(msg);
  }
}

// nice, compact pill
class _TimerPill extends StatelessWidget {
  final String timeText;

  const _TimerPill({required this.timeText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.shadowColor.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            timeText, // "mm:ss"
            style: AppFonts.text16.semiBold.style.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

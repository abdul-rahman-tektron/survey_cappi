// questionnaire_screen.dart
//
// Unified screen that renders any questionnaire flow using the
// appropriate notifier implementation (RSI or Passenger).
//
// Assumptions:
//  - BaseQuestionnaireNotifier defines:
//      • fields: questionnaireType, sections, currentStep, lastError,
//                startedAt, elapsedText
//      • methods: isVisible(Question), nextStep(BuildContext),
//                 previousStep(), clearError(), getAllAnswers()
//  - You have these notifiers implemented:
//      • RsiQuestionnaireNotifier
//      • PassengerQuestionnaireNotifier
//  - UI widgets exist:
//      • StepBar, QuestionRenderer, CustomAppBar, CustomDrawer, CustomButton
//  - QuestionnaireType enum is available.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:srpf/res/fonts.dart';

import 'package:srpf/utils/enums.dart';
import 'package:srpf/utils/helpers/loader.dart';
import 'package:srpf/utils/helpers/toast_helper.dart';
import 'package:srpf/utils/router/routes.dart';
import 'package:srpf/utils/widgets/custom_appbar.dart';
import 'package:srpf/utils/widgets/custom_drawer.dart';
import 'package:srpf/utils/widgets/custom_buttons.dart';

import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/screens/questionnaire/widgets/step_bar.dart';
import 'package:srpf/screens/questionnaire/widgets/questionnaire_renderer.dart';

// Notifiers
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';
import 'package:srpf/screens/questionnaire/flows/rsi/rsi_questionnaire_notifier.dart';
import 'package:srpf/screens/questionnaire/flows/passenger/passenger_questionnaire_notifier.dart';
import 'package:srpf/utils/widgets/custom_popup.dart';

class QuestionnaireScreen extends StatelessWidget {
  final QuestionnaireType? questionnaireType;
  final int? editRsiId;

  const QuestionnaireScreen({super.key, this.questionnaireType, this.editRsiId,});

  @override
  Widget build(BuildContext context) {
    // Choose the concrete notifier: RSI vs Passenger (default).
    final bool isRsi = questionnaireType == QuestionnaireType.freightRsi;

    return ChangeNotifierProvider<BaseQuestionnaireNotifier>(
      create: (_) => isRsi
          ? RsiQuestionnaireNotifier(context, questionnaireType: questionnaireType, editRsiId: editRsiId)
          : PassengerQuestionnaireNotifier(context, questionnaireType: questionnaireType, editPassengerId: editRsiId),
      child: Consumer<BaseQuestionnaireNotifier>(
        builder: (context, notifier, _) => LoadingOverlay<BaseQuestionnaireNotifier>(
          child: WillPopScope(
            onWillPop: () async {
              // if no type chosen, allow direct back
              if (notifier.questionnaireType == null) return true;

              final shouldExit = await showExitSurveyDialog(context, notifier);
              return shouldExit;
            },
            child: SafeArea(child: _ScaffoldBody(notifier: notifier)),
          ),
        ),
      ),
    );
  }
}

class _ScaffoldBody extends StatefulWidget {
  final BaseQuestionnaireNotifier notifier;
  const _ScaffoldBody({required this.notifier});

  @override
  State<_ScaffoldBody> createState() => _ScaffoldBodyState();
}

class _ScaffoldBodyState extends State<_ScaffoldBody> {
  final _scrollCtrl = ScrollController();
  int? _lastSectionOriginalIndex;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToTop({bool animate = false}) {
    if (!_scrollCtrl.hasClients) return;
    if (animate) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollCtrl.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = widget.notifier;
    final allSections = notifier.sections ?? const <QuestionnaireSection>[];

    if (allSections.isEmpty || notifier.currentStep >= allSections.length) {
      return const Scaffold(
        appBar: CustomAppBar(showDrawer: true),
        drawer: CustomDrawer(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    bool _questionIsVisible(Question q) {
      if (!notifier.isVisible(q)) return false;
      final repOf = q.captureConfig?['repeatFromSelectedOf'] as String?;
      if (repOf == null) return true;
      final sel = notifier.valueOfGlobal(repOf);
      return (sel is List && sel.isNotEmpty);
    }

    bool _sectionHasVisibleQuestions(QuestionnaireSection s) =>
        s.questions.any(_questionIsVisible);

    final filtered = <({int originalIndex, QuestionnaireSection section})>[];
    for (var i = 0; i < allSections.length; i++) {
      final s = allSections[i];
      if (_sectionHasVisibleQuestions(s)) {
        filtered.add((originalIndex: i, section: s));
      }
    }

    final currentFilteredIndex =
    filtered.indexWhere((e) => e.originalIndex == notifier.currentStep);

    if (currentFilteredIndex == -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (filtered.isNotEmpty) {
          final newCurrent = filtered.first.originalIndex;
          notifier.currentStep = newCurrent;
          if (notifier.furthestStep < newCurrent) {
            notifier.furthestStep = newCurrent;
          }
          notifier.notifyListeners();
        }
      });
      return const Scaffold(
        appBar: CustomAppBar(showDrawer: true),
        drawer: CustomDrawer(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentEntry = filtered[currentFilteredIndex];
    final section = currentEntry.section;

    // 👇 If the original section index changed since last build, scroll to top
    if (_lastSectionOriginalIndex != currentEntry.originalIndex) {
      _lastSectionOriginalIndex = currentEntry.originalIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTop(animate: true));
    }

    final visibleQs = section.questions.where(_questionIsVisible).toList();

    if (notifier.lastError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ToastHelper.showError(notifier.lastError!);
        notifier.clearError();
      });
    }

    int furthestFilteredIndex = 0;
    for (var i = 0; i < filtered.length; i++) {
      if (filtered[i].originalIndex <= notifier.furthestStep) {
        furthestFilteredIndex = i;
      } else {
        break;
      }
    }

    return Scaffold(
      appBar: const CustomAppBar(showDrawer: true),
      drawer: const CustomDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StepBar(
            sections: filtered.map((e) => e.section).toList(),
            current: currentFilteredIndex,
            visitedUntil: furthestFilteredIndex,
            onStepTap: (i) {
              final targetOriginal = filtered[i].originalIndex;
              if (targetOriginal <= notifier.furthestStep) {
                notifier.goToStep(targetOriginal);
                notifier.clearError();
                // optional instant scroll (we also do it in the section-change hook)
                _scrollToTop();
              }
            },
          ),
          _HeaderRow(title: section.title, elapsedText: notifier.elapsedText),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl, // 👈 attach controller
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(visibleQs.length, (index) {
                  final q = visibleQs[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      QuestionRenderer(
                        question: q,
                        notifier: notifier,
                        sectionId: section.id,
                        index: index,
                      ),
                      const SizedBox(height: 16),
                      if (index != visibleQs.length - 1)
                        const Divider(thickness: 1, height: 24),
                    ],
                  );
                }),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (currentFilteredIndex > 0)
                  CustomButton(
                    text: "Back",
                    onPressed: () {
                      final targetOriginal = filtered[currentFilteredIndex - 1].originalIndex;
                      notifier.goToStep(targetOriginal);
                      _scrollToTop(); // ensure top when going back too
                    },
                    fullWidth: false,
                  ),
                const Spacer(),
                CustomButton(
                  text: "Save",
                  onPressed: () async {
                    await notifier.saveDraft(context);
                  },
                  fullWidth: false,
                ),
                10.horizontalSpace,
                CustomButton(
                  text: (currentFilteredIndex == filtered.length - 1) ? "Submit" : "Next",
                  onPressed: () async {
                    await notifier.nextStep(context);
                    // If moving to a different visible section, section-change hook will scroll.
                    // If staying in same section (e.g., hidden sections skipped), you can force:
                    // _scrollToTop();
                  },
                  fullWidth: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _HeaderRow extends StatelessWidget {
  final String title;
  final String elapsedText;

  const _HeaderRow({required this.title, required this.elapsedText});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final bool isTabletPortrait = w >= 600 && w < 900 && MediaQuery.of(context).orientation == Orientation.portrait;
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              title.replaceAll('\n', ' '),
              style: AppFonts.text22.regular.style.copyWith(fontSize: isTabletPortrait ? 22 : 16),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 18),
                const SizedBox(width: 6),
                Text(
                  elapsedText,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

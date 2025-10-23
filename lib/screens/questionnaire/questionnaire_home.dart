import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';
import 'package:srpf/utils/enums.dart';
import 'package:srpf/utils/router/routes.dart';
import 'package:srpf/utils/widgets/common_background.dart';
import 'package:srpf/utils/widgets/custom_appbar.dart';

class QuestionnaireHome extends StatelessWidget {
  final QuestionnaireType? questionnaireType;
  final int? editRsiId;
  const QuestionnaireHome({super.key, this.questionnaireType, this.editRsiId});

  @override
  Widget build(BuildContext context) {
    final bool isRsi = questionnaireType == QuestionnaireType.freightRsi;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: SafeArea(
        child: CommonBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double w = constraints.maxWidth;
              final bool isTabletPortrait = w >= 600 && w < 900 && MediaQuery.of(context).orientation == Orientation.portrait;

              // Page gutters
              final EdgeInsets pagePad = EdgeInsets.symmetric(
                horizontal: isTabletPortrait ? 15 : 16,
                vertical: 15,
              );

              // Max readable width (centered on tablet)
              final double maxContent = isTabletPortrait ? 720 : 560; // keep compact for readability

              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContent),
                child: SingleChildScrollView(
                  padding: pagePad.copyWith(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        isRsi ? 'Freight Survey' : 'Passenger Survey',
                        style: AppFonts.text22.bold.style,
                        textAlign: TextAlign.center,
                      ),
                      6.verticalSpace,
                      Text(
                        isRsi
                            ? 'Use this flow to capture roadside freight interviews. Please confirm consent and follow the steps below.'
                            : 'Use this flow to capture passenger interviews. Please confirm consent and follow the steps below.',
                        style: AppFonts.text14.regular.grey.style,
                        textAlign: TextAlign.center,
                      ),
                      16.verticalSpace,

                      // Meta row (wraps nicely)
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10.w,
                        runSpacing: 10.h,
                        children: const [
                          _MetaChip(icon: Icons.schedule, label: 'Est. 6–10 min'),
                          _MetaChip(icon: Icons.signal_cellular_alt, label: 'Works offline; sync later'),
                          _MetaChip(icon: Icons.lock_outline, label: 'Anonymous responses'),
                        ],
                      ),

                      16.verticalSpace,

                      // Cards
                      _CardBlock(
                        title: 'Before you begin',
                        children: [
                          const _Bullet('Introduce yourself & the survey purpose.'),
                          const _Bullet('Obtain verbal consent to proceed.'),
                          _Bullet(isRsi
                              ? 'Confirm vehicle is stationary/safe to interview.'
                              : 'Choose appropriate passenger type.'),
                          const _Bullet('If refusing, record minimal screening as applicable.'),
                        ],
                      ),
                      _CardBlock(
                        title: 'Tips',
                        children: const [
                          _Bullet('Keep questions in order; avoid skipping unless the app hides them.'),
                          _Bullet('Use “Other” fields for answers not listed.'),
                          _Bullet('Capture locations with the map pin when prompted.'),
                        ],
                      ),

                      30.verticalSpace,

                      // Start button — responsive circular size
                      _StartButton(
                        onTap: () {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.questionnaire,
                            arguments: {
                              'questionnaireType': questionnaireType,
                              'editRsiId': editRsiId,
                            },
                          );
                        },
                      ),
                      10.verticalSpace,
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w > 600 ? 5.w : 10.w, vertical: w > 600 ? 3.w :8.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(w > 600 ? 5.w : 10.r),
        border: Border.all(color: AppColors.primaryLight, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: w > 600 ? 10.w : 16.w, color: AppColors.primary),
          6.horizontalSpace,
          Text(label, style: AppFonts.text12.semiBold.style),
        ],
      ),
    );
  }
}

class _CardBlock extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _CardBlock({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      width: double.infinity,
      padding: EdgeInsets.all(w > 600 ? 10.w: 14.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(w > 600 ? 8.w : 12.r),
        border: Border.all(color: AppColors.shadowColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.08),
            blurRadius: 12.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppFonts.text16.semiBold.style),
          8.verticalSpace,
          ...children,
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(height: 1.2)),
          Expanded(child: Text(text, style: AppFonts.text14.regular.style)),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Button diameter scales by screen width, clamped for consistency
    final double w = MediaQuery.of(context).size.width;
    double d = w * 0.42; // default ~42% of width
    if (w >= 600) d = 180; // tablet portrait fixed size
    d = d.clamp(190, 280); // cap for phones and tablets

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          color: AppColors.primary,
          border: Border.all(color: AppColors.primaryLight, width: 1.5),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withOpacity(0.25),
              blurRadius: 10.r,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          'Start Now',
          style: AppFonts.text22.bold.white.style,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

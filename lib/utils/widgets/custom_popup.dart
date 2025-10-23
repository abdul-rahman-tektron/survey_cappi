import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';
import 'package:srpf/screens/common/home/home_notifier.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';
import 'package:srpf/utils/enums.dart';
import 'package:srpf/utils/router/routes.dart';

void showCategoryPicker(BuildContext context) {
  final n = context.read<HomeNotifier>();
  final data = n.categoryTop;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        backgroundColor: AppColors.backgroundSecondary, // dialog bg
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Start New Survey",
                      style: AppFonts.text20.semiBold.style.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    color: AppColors.primary,
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close, size: 24),
                  ),
                ],
              ),
              12.verticalSpace,

              // Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 420 ? 2 : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 1.5,
                      mainAxisSpacing: 12.h,
                      crossAxisSpacing: 10.w,
                    ),
                    itemBuilder: (context, index) {
                      final item = data[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx); // close dialog first
                          Navigator.pushNamed(
                            context,
                            AppRoutes.questionnaireHome,
                            arguments: {
                              "questionnaireType": item.type == TopLevelType.rsi
                                  ? QuestionnaireType.freightRsi
                                  : null,
                            },
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: AppColors.primary, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowColor.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item.icon, color: item.iconColor ?? AppColors.primary, size: 36.w),
                              12.verticalSpace,
                              Text(
                                item.label,
                                textAlign: TextAlign.center,
                                style: AppFonts.text16.semiBold.style.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}


Future<bool> showExitSurveyDialog(
    BuildContext context,
    BaseQuestionnaireNotifier notifier,
    ) async {
  final shouldExit = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: AppColors.white,
      title: const Text('Exit Survey?'),
      content: const Text('Are you sure you want to exit? Your progress will be lost.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppFonts.text14.bold.style,
          ),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppFonts.text14.bold.style,
          ),
          onPressed: () {
            notifier.resetQuestionnaire(); // clear state before exit
            Navigator.of(ctx).pushNamedAndRemoveUntil(
              AppRoutes.home,
                  (route) => false,
            );
          },
          child: const Text('Exit'),
        ),
      ],
    ),
  );

  return shouldExit ?? false;
}
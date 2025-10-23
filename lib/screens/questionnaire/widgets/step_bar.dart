import 'package:flutter/material.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';

class StepBar extends StatelessWidget {
  final List<QuestionnaireSection> sections;
  final int current;

  /// Highest index (in THIS list) the user has reached.
  /// If not provided, we fall back to `current`.
  final int? visitedUntil;

  final ValueChanged<int>? onStepTap;

  const StepBar({
    super.key,
    required this.sections,
    required this.current,
    this.visitedUntil,
    this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final int furthest = visitedUntil ?? current;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(color: AppColors.shadowColor.withOpacity(0.2)),
        ),
      ),
      child: Column(
        children: [
          // Steps row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(sections.length, (i) {
                final bool isActive = i == current;
                final bool isVisited = i <= furthest; // visited or current

                // Circle background
                final Color bgColor = isActive
                    ? AppColors.primary
                    : (isVisited
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.textSecondary.withOpacity(0.2));

                // Label text color
                final Color labelColor =
                (isActive || isVisited) ? AppColors.primary : AppColors.textSecondary;

                return GestureDetector(
                  onTap: (onStepTap != null && isVisited)
                      ? () => onStepTap!(i)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: bgColor,
                          child: Text(
                            '${i + 1}',
                            style: AppFonts.text14.medium.style.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 120, // max width for label
                          child: Text(
                            sections[i].title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.text12.regular.style.copyWith(
                              fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                              color: labelColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          // Progress bar
          LinearProgressIndicator(
            value: (current + 1) / sections.length,
            minHeight: 6,
            borderRadius: const BorderRadius.all(Radius.circular(3)),
            backgroundColor: AppColors.textSecondary.withOpacity(0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:srpf/core/questions/model/sp_model.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';
import 'package:srpf/res/images.dart';
import 'package:srpf/utils/router/routes.dart';
import 'package:srpf/utils/widgets/custom_appbar.dart';

class SpPreambleScreen extends StatelessWidget {
  final List<SpSet> initialSets;
  final int? interviewMasterId;
  final int continuedElapsedSec;
  final String? startedIso;
  final String? odResponse;

  const SpPreambleScreen({
    super.key,
    required this.initialSets,
    this.interviewMasterId,
    this.continuedElapsedSec = 0,
    this.startedIso,
    this.odResponse,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        showBackButton: false,
      ),
      body: Column(
        children: [
          // ─────────────── HEADER INTRO ───────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Welcome to Trip Preferences',
                  style: AppFonts.text20.semiBold.style.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                Text(
                  'We’ll show you different travel options for your trip.',
                  style: AppFonts.text14.regular.style.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // ─────────────── IMAGE ───────────────
          AspectRatio(
            aspectRatio: 20 / 12,
            child:  Image.asset(
              AppImages.spPreamble,
              fit: BoxFit.contain,
              width: double.infinity,
            )
          ),

          // ─────────────── CONTENT ───────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Intro (with OD highlighted)
                  Text.rich(
                    TextSpan(
                      style: AppFonts.text16.regular.style.copyWith(height: 1.6),
                      children: [
                        const TextSpan(text: 'Imagine you are planning another trip between '),
                        TextSpan(
                          text: '$odResponse. ',
                          style: AppFonts.text16.bold.style.copyWith(color: AppColors.primary),
                        ),
                        const TextSpan(
                          text:
                          'I am going to show you four options for this trip, by Car, Taxi, Bus or Train. Each option has a different travel time and cost. \n\n'
                              'Which of these options would you prefer to use, for a trip between ',
                        ),
                        TextSpan(
                          text: odResponse,
                          style: AppFonts.text16.bold.style.copyWith(color: AppColors.primary),
                        ),
                        const TextSpan(
                          text:
                          '? The total travel time and journey costs are shown on the right.\n',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Helpful chips
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _InfoChip(icon: Icons.directions, label: 'You’ll see 4 options'),
                      _InfoChip(icon: Icons.schedule_rounded, label: 'Time + Cost shown'),
                      _InfoChip(icon: Icons.view_module_rounded, label: '6 sets (based on OD)'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Bulleted details with icons
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowColor.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(color: AppColors.shadowColor.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BulletRow(
                          icon: Icons.directions_car_filled_rounded,
                          title: 'Car',
                          text:
                          'Total time includes walking to your car, driving to destination, and parking. '
                              'Costs includes fuel, parking, and tolls.',
                        ),
                        _BulletRow(
                          icon: Icons.local_taxi_rounded,
                          title: 'Taxi',
                          text: 'Fare depends on how many people share the ride.',
                        ),
                        _BulletRow(
                          icon: Icons.train_rounded,
                          title: 'Train',
                          text:
                          'The train option would be provided by Etihad Rail.  Etihad Rail are planning a new Rail Service between $odResponse. Time includes travel on the train plus access and egress to and from stations. Last mile options such as shuttle buses and car parking will be available to provide access. ',
                        ),
                        _BulletRow(
                          icon: Icons.directions_bus_filled_rounded,
                          title: 'Bus',
                          text:
                          'Time includes travel on the bus plus access and egress to and from bus stops.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─────────────── START BUTTON ───────────────
          SafeArea(
            top: false,
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.statedPreference,
                      arguments: {
                        'sets': initialSets,
                        'interviewMasterId': interviewMasterId,
                        'continuedElapsedSec': continuedElapsedSec,
                        'startedIso': startedIso,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Start',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(label, style: AppFonts.text14.semiBold.style),
      ]),
    );
  }
}

class _BulletRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _BulletRow({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppFonts.text14.regular.style.copyWith(color: AppColors.textPrimary),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: AppFonts.text14.semiBold.style,
                  ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
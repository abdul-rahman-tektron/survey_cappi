import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';
import 'package:srpf/res/styles.dart';
import 'package:srpf/screens/common/home/home_notifier.dart';
import 'package:srpf/utils/enums.dart';
import 'package:srpf/utils/router/routes.dart';
import 'package:srpf/utils/widgets/common_background.dart';
import 'package:srpf/utils/widgets/custom_appbar.dart';
import 'package:srpf/utils/widgets/custom_buttons.dart';
import 'package:srpf/utils/widgets/custom_drawer.dart';
import 'package:srpf/utils/widgets/custom_linear_progress_indicator.dart';
import 'package:srpf/utils/widgets/custom_popup.dart';

/// Responsive HomeScreen (phones + tablet portrait)
/// - Responsive paddings and grids
/// - No landscape/desktop-specific layouts
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeNotifier(),
      child: Consumer<HomeNotifier>(
        builder: (context, homeNotifier, _) {
          return _buildBody(context, homeNotifier);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeNotifier homeNotifier) {
    final double width = MediaQuery.of(context).size.width;
    final bool isTabletPortrait =
        width >= 600 && width < 900 && MediaQuery.of(context).orientation == Orientation.portrait;

    // Shell padding: slightly wider gutters on tablet portrait
    final EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: isTabletPortrait ? 20 : 15);

    return Scaffold(
      appBar: const CustomAppBar(showDrawer: true, showBackButton: false),
      drawer: const CustomDrawer(),
      bottomNavigationBar: const SizedBox(height: 20),
      body: SafeArea(
        child: CommonBackground(
          child: LayoutBuilder(
            builder: (context, vc) {
              final width = MediaQuery.of(context).size.width;
              final isTabletPortrait =
                  width >= 600 &&
                  width < 900 &&
                  MediaQuery.of(context).orientation == Orientation.portrait;

              if (!isTabletPortrait) {
                // phones: keep the old behavior
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      15.verticalSpace,
                      _welcomeRow(
                        context,
                        homeNotifier,
                        EdgeInsets.symmetric(horizontal: width >= 600 ? 20 : 15),
                      ),
                      _buildQuickStatsGrid(context, homeNotifier),
                      5.verticalSpace,
                      _sectionHeader(
                        context,
                        (!homeNotifier.isAdmin) ? 'Recent Surveys' : 'Enumerators',
                        EdgeInsets.symmetric(horizontal: width >= 600 ? 20 : 15),
                      ),
                      10.verticalSpace,
                      if (!homeNotifier.isAdmin)
                        _buildInterviewsTable(context, homeNotifier)
                      else
                        SizedBox(
                            height: 650,
                            child: _adminEnumeratorMap(context, homeNotifier, fill: true)),
                      20.verticalSpace,
                    ],
                  ),
                );
              }

              // tablet portrait: slivers with the table filling remaining height
              return CustomScrollView(
                physics: NeverScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: 15.verticalSpace),
                  SliverToBoxAdapter(
                    child: _welcomeRow(context, homeNotifier, EdgeInsets.symmetric(horizontal: 20)),
                  ),
                  SliverToBoxAdapter(child: _buildQuickStatsGrid(context, homeNotifier)),
                  SliverToBoxAdapter(child: 5.verticalSpace),
                  SliverToBoxAdapter(
                    child: _sectionHeader(
                      context,
                      (!homeNotifier.isAdmin) ? 'Recent Surveys' : 'Enumerators',
                      EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                  SliverToBoxAdapter(child: 10.verticalSpace),
                  // 👇 This makes the table take the remaining viewport height
                  if (!homeNotifier.isAdmin)
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 30),
                      sliver: SliverFillRemaining(
                        hasScrollBody: true, // child expands; body inside handles its own scrolling
                        child: _buildInterviewsTable(context, homeNotifier, fillRemaining: true),
                      ),
                    )
                  else
                    SliverFillRemaining(
                      hasScrollBody: false, // let child expand
                      child: _adminEnumeratorMap(context, homeNotifier, fill: true),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Header Row
  // ────────────────────────────────────────────────────────────────────────────
  Widget _welcomeRow(BuildContext context, HomeNotifier notifier, EdgeInsets pad) {
    final double width = MediaQuery.of(context).size.width;
    final bool isNarrow = width > 600; // very small phones
    final bool isNarrowSmall = width < 360; // very small phones

    return Padding(
      padding: pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Welcome, ',
                        style: AppFonts.text22.regular.style.copyWith(fontSize: isNarrow ? 22 : 16),
                      ),
                      TextSpan(
                        text: notifier.userData?.fullname ?? '',
                        style: AppFonts.text22.bold.blue.style.copyWith(
                          fontSize: isNarrow ? 22 : 16,
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isNarrowSmall)
                CustomButton(
                  text: 'New Survey',
                  fullWidth: false,
                  onPressed: () => showCategoryPicker(context),
                ),
            ],
          ),
          if (isNarrowSmall) ...[
            10.verticalSpace,
            CustomButton(text: 'New Survey', onPressed: () => showCategoryPicker(context)),
          ],
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Quick Stats (Responsive grid)
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildQuickStatsGrid(BuildContext context, HomeNotifier notifier) {
    final double width = MediaQuery.of(context).size.width;

    int cols;
    if (width >= 820) {
      cols = 4; // large tablet portrait
    } else if (width >= 600) {
      cols = 3; // small/medium tablet portrait
    } else if (width >= 380) {
      cols = 2; // regular phones
    } else {
      cols = 2; // tiny phones still 2 columns
    }

    // Aspect ratio adjusts slightly by width to keep tiles comfy
    final double aspect = width >= 820
        ? 2 / 1.3
        : width >= 600
        ? 2 / 1.2
        : 2 / 1.1;

    final bool isTabletPortrait = width >= 600;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: notifier.quickStats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        childAspectRatio: aspect,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 12.h,
      ),
      itemBuilder: (context, index) {
        final stat = notifier.quickStats[index];

        final isTarget = stat.label.toLowerCase().contains('target');
        final double progressValue = stat.total > 0
            ? ((stat.count ?? 0).clamp(0, stat.total)).toDouble()
            : 0.0;

        return Container(
          padding: EdgeInsets.all(5.w),
          decoration: AppStyles.commonDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      stat.label,
                      style: AppFonts.text14.regular.style,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isTarget
                          ? '${(stat.count ?? 0).toStringAsFixed(0)} / ${stat.total.toStringAsFixed(0)}'
                          : (stat.count ?? 0).toStringAsFixed(0),
                      style: AppFonts.text18.semiBold.style,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Container(
                      width: isTabletPortrait ? 12.w : 20.w,
                      height: isTabletPortrait ? 12.w : 20.w,
                      decoration: BoxDecoration(
                        color: stat.iconBgColor,
                        borderRadius: BorderRadius.circular(isTabletPortrait ? 20.w : 10.r),
                      ),
                      child: Icon(
                        stat.icon,
                        color: stat.iconColor,
                        size: isTabletPortrait ? 8.w : 12.w,
                      ),
                    ),
                  ],
                ),
              ),
              if (isTarget) ...[
                6.verticalSpace,
                CustomLinearProgressIndicator(
                  percentage: progressValue,
                  total: stat.total.toDouble(),
                  fillColor: stat.iconColor,
                  backgroundColor: Colors.grey.shade200,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Section Header
  // ────────────────────────────────────────────────────────────────────────────
  Widget _sectionHeader(BuildContext context, String title, EdgeInsets pad) {
    return Padding(
      padding: pad,
      child: Text(title, style: AppFonts.text18.semiBold.style),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Recent Surveys Table (keeps your scroll strategy, makes sizes responsive)
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildInterviewsTable(
    BuildContext context,
    HomeNotifier n, {
    bool fillRemaining = false, // pass true when used under SliverFillRemaining
  }) {
    final rows = n.interviews;

    // controllers
    final horizCtrl = ScrollController();
    final vertCtrl = ScrollController();

    // thresholds
    const int maxVisibleRowsNoScroll = 6;

    // sizes
    final double rowHeight = (45.h).clamp(40, 56);

    // column widths adjust slightly by device width
    final double deviceW = MediaQuery.of(context).size.width;
    final bool isTablet = deviceW >= 600;

    final double wId = isTablet ? 100 : 100;
    final double wName = isTablet ? 200 : 200;
    final double wType = isTablet ? 200 : 180;
    final double wDate = isTablet ? 200 : 200;
    final double wStatus = isTablet ? 130 : 120;

    final double tableWidth = wId + wName + wType + wDate + wStatus;

    Widget headerCell(String label, double width) {
      return Container(
        alignment: Alignment.centerLeft,
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Text(
          label,
          style: AppFonts.text14.bold.style.copyWith(color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    Widget bodyCell(Widget child, double width) {
      return Container(
        alignment: Alignment.centerLeft,
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: child,
      );
    }

    final header = Container(
      height: 48, // fixed header height (keeps math simple)
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          headerCell('ID', wId),
          headerCell('Name', wName),
          headerCell('Survey Type', wType),
          headerCell('Date', wDate),
          headerCell('Status', wStatus),
        ],
      ),
    );

    final _df = DateFormat('d MMM yyyy, hh:mm a');
    String _formatDate(DateTime? d) => d == null ? '-' : _df.format(d);

    Widget rowItem(int i) {
      final r = rows[i];
      final isEven = i.isEven;
      final int? rsiId = int.tryParse(r.interviewId);

      return InkWell(
        onTap: () {
          print("r.surveyType");
          print(r.surveyType);
          if (rsiId == null || r.status == InterviewStatus.complete) return;
          if (r.surveyType == "RSI") {
            Navigator.pushNamed(
              context,
              AppRoutes.questionnaire,
              arguments: {'questionnaireType': QuestionnaireType.freightRsi, 'editRsiId': rsiId},
            );
          } else {
            Navigator.pushNamed(
              context,
              AppRoutes.questionnaire,
              arguments: {
                'questionnaireType': QuestionnaireType.passengerPetrol, // or detected type
                'editRsiId': rsiId,
              },
            );
          }
        },
        child: Container(
          color: isEven ? AppColors.background.withOpacity(0.5) : Colors.transparent,
          height: rowHeight.toDouble(),
          child: Row(
            children: [
              bodyCell(Text(r.interviewId, style: AppFonts.text14.regular.style), wId),
              bodyCell(
                Text(r.name, style: AppFonts.text14.regular.style, softWrap: true, maxLines: 2),
                wName,
              ),
              bodyCell(Text(r.surveyType ?? '-', style: AppFonts.text14.regular.style), wType),
              bodyCell(
                Text(_formatDate(r.interviewDate), style: AppFonts.text14.regular.grey.style),
                wDate,
              ),
              bodyCell(_statusChip(r.status), wStatus),
            ],
          ),
        ),
      );
    }

    Widget tableCard({required Widget child}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.shadowColor.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
        ),
      );
    }

    // ──────────────────────────────────────────────────────────────────────
    // PHONE / DEFAULT (keep existing behavior)
    // ──────────────────────────────────────────────────────────────────────
    if (!fillRemaining) {
      final bool needsVerticalScroll = rows.length > maxVisibleRowsNoScroll;
      final double bodyHeightWhenNoScroll = rowHeight * rows.length;

      if (!needsVerticalScroll) {
        return tableCard(
          child: Scrollbar(
            controller: horizCtrl,
            thumbVisibility: true,
            notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              controller: horizCtrl,
              scrollDirection: Axis.horizontal,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  header,
                  SizedBox(
                    width: tableWidth,
                    height: bodyHeightWhenNoScroll,
                    child: Column(children: List.generate(rows.length, rowItem)),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final screenH = MediaQuery.of(context).size.height;
      final double maxBodyH = screenH * 0.61;
      final double contentH = rows.length * rowHeight;
      final double tableBodyH = contentH.clamp(rowHeight * 6, maxBodyH);

      return tableCard(
        child: Scrollbar(
          controller: horizCtrl,
          thumbVisibility: true,
          notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: horizCtrl,
            scrollDirection: Axis.horizontal,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                header,
                SizedBox(
                  width: tableWidth,
                  height: tableBodyH,
                  child: Scrollbar(
                    controller: vertCtrl,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: vertCtrl,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(rows.length, rowItem),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ──────────────────────────────────────────────────────────────────────
    // TABLET / FILL REMAINING HEIGHT (no LayoutBuilder here)
    // Works inside SliverFillRemaining without intrinsic errors.
    // ──────────────────────────────────────────────────────────────────────
    return tableCard(
      child: SizedBox.expand(
        // fill the height that SliverFillRemaining gives us
        child: Scrollbar(
          controller: horizCtrl,
          thumbVisibility: true,
          notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: horizCtrl,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth, // fixed table width
              height: double.infinity, // take all available height
              child: Column(
                children: [
                  header, // fixed 48px header
                  // Body fills the rest and is scrollable
                  Expanded(
                    child: Scrollbar(
                      controller: vertCtrl,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: vertCtrl,
                        padding: EdgeInsets.zero,
                        itemExtent: rowHeight.toDouble(),
                        // smooth scrolling & perf
                        itemCount: rows.length,
                        itemBuilder: (_, i) => rowItem(i),
                      ),
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

  // Legacy helper (kept for parity with your utils)
  String _formatDate(DateTime d) {
    final two = (int v) => v.toString().padLeft(2, '0');
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(h)}:${two(d.minute)} $ampm';
  }

  Widget _statusChip(InterviewStatus s) {
    final label = s == InterviewStatus.complete ? 'Complete' : 'Incomplete';
    final bg = s == InterviewStatus.complete
        ? AppColors.success
        : AppColors.error.withOpacity(0.85);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _adminEnumeratorMap(BuildContext context, HomeNotifier n, {bool fill = false}) {
    if (!n.isAdmin) return const SizedBox.shrink();

    final border = BorderRadius.circular(16);
    final Completer<GoogleMapController> controller = Completer();

    final map = Stack(
      children: [
        GoogleMap(
          initialCameraPosition: n.initialCamera,
          markers: n.markers,
          zoomControlsEnabled: false,
          myLocationEnabled: false,
          onTap: (_) => n.selectedEnumerator = null,
          onMapCreated: (c) async {
            controller.complete(c);
            if (n.enumerators.length >= 2) {
              final lats = n.enumerators.map((e) => e.lat).toList()..sort();
              final lons = n.enumerators.map((e) => e.lon).toList()..sort();
              final sw = LatLng(lats.first, lons.first);
              final ne = LatLng(lats.last, lons.last);
              final bounds = LatLngBounds(southwest: sw, northeast: ne);
              await Future.delayed(const Duration(milliseconds: 300));
              try {
                await c.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
              } catch (_) {}
            }
          },
        ),

        // Top Gradient Header
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xAA0A4D68), Color(0x880A4D68)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '📍 Enumerator Live Locations',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                Icon(Icons.map_rounded, color: Colors.white),
              ],
            ),
          ),
        ),

        // Floating Legend
        Positioned(
          right: 12,
          top: 80,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: n.surveyTypeColors.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: entry.value, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Floating reload / focus buttons
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            children: [
              _mapButton(Icons.my_location_rounded, 'Focus', () async {
                final e = n.selectedEnumerator;
                if (e == null) return;
                final c = await controller.future;
                await c.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: LatLng(e.lat, e.lon), zoom: 13),
                  ),
                );
              }),
              const SizedBox(height: 10),
              _mapButton(Icons.refresh, 'Reload', () async {
                await n.loadEnumeratorLocations();
              }),
            ],
          ),
        ),

        // Info card when marker selected
        if (n.selectedEnumerator != null)
          Positioned(left: 16, right: 16, bottom: 20, child: _enumInfoCard(n.selectedEnumerator!)),
      ],
    );

    final container = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: map,
    );

    if (fill) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(15, 16, 15, 8),
        child: SizedBox.expand(child: container),
      );
    } else {
      final double h = MediaQuery.of(context).size.height;
      final double mapHeight = (h * 0.45).clamp(260, 520).toDouble();
      return Padding(
        padding: const EdgeInsets.fromLTRB(15, 16, 15, 8),
        child: SizedBox(height: mapHeight, child: container),
      );
    }
  }

  Widget _legendItem(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black26.withOpacity(0.08), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _mapButton(IconData icon, String tooltip, VoidCallback onTap) {
    return FloatingActionButton.small(
      heroTag: tooltip,
      backgroundColor: Colors.white,
      onPressed: onTap,
      child: Icon(icon, color: AppColors.primary),
    );
  }

  Widget _enumInfoCard(EnumeratorPin e) {
    final completion = (e.completed ?? 0) / (e.target == 0 ? 1 : (e.target ?? 1));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_pin_circle_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(e.role ?? 'Enumerator', style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              if (e.phone != null)
                IconButton(
                  icon: const Icon(Icons.phone, color: AppColors.primary),
                  onPressed: () {},
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Chip(
                label: Text(e.surveyType ?? 'Survey'),
                backgroundColor: (e.surveyType ?? '').contains('Freight')
                    ? Colors.teal.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.2),
              ),
              const Spacer(),
              Text(
                'Target: ${e.target ?? '-'} | Done: ${e.completed ?? 0}',
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: completion.clamp(0, 1),
            backgroundColor: Colors.grey.shade200,
            color: (completion >= 0.8)
                ? Colors.green
                : (completion >= 0.4)
                ? Colors.orange
                : Colors.redAccent,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 18, color: Colors.black54),
              const SizedBox(width: 6),
              Text(
                e.lastSeen != null
                    ? 'Last seen: ${DateFormat('d MMM, hh:mm a').format(e.lastSeen!)}'
                    : 'No recent update',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';
import 'package:srpf/res/styles.dart';
import 'package:srpf/utils/widgets/custom_appbar.dart';

// ← use your shared widgets
import 'package:srpf/utils/widgets/custom_buttons.dart';
import 'package:srpf/utils/widgets/custom_dropdown_field.dart';
import 'package:srpf/utils/widgets/custom_textfields.dart';

import 'survey_list_notifier.dart';

class SurveyListScreen extends StatelessWidget {
  const SurveyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SurveyListNotifier(),
      child: Consumer<SurveyListNotifier>(
        builder: (context, n, _) {
          return Scaffold(
            appBar: const CustomAppBar(),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FiltersBar(n: n),
                    15.verticalSpace,
                    // give SurveyTable a fixed max height instead of Expanded
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery
                            .of(context)
                            .size
                            .height * 0.7,
                      ),
                      child: SurveyTable(n: n),
                    ),
                    15.verticalSpace,
                    PaginationBar(n: n),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FiltersBar extends StatefulWidget {
  final SurveyListNotifier n;
  const _FiltersBar({required this.n});

  @override
  State<_FiltersBar> createState() => _FiltersBarState();
}

class _FiltersBarState extends State<_FiltersBar> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.n;

    return Container(
      decoration: AppStyles.commonDecoration,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Search
          CustomTextField(
            controller: _searchCtrl,
            fieldName: 'Search',
            hintText: 'Search',
            useFieldNameAsLabel: false,
            titleVisibility: false,
            prefix: const Icon(Icons.search, color: AppColors.textSecondary),
            skipValidation: true,
            onChanged: n.onSearch,
          ),

          // Survey Type (All/Passenger/Freight/Bus/Airport)
          Row(
            children: [
              Expanded(
                child: CustomDropdownField<int>(
                  fieldName: 'Survey Type',
                  value: n.selectedSurveyType,
                  onChanged: (v) => n.onSurveyTypeChange(v ?? 0),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('All')),
                    DropdownMenuItem(value: 6, child: Text('Freight')),
                    DropdownMenuItem(value: 1, child: Text('Car(Petrol)')),
                    DropdownMenuItem(value: 2, child: Text('Car(Border)')),
                    DropdownMenuItem(value: 3, child: Text('Bus')),
                    DropdownMenuItem(value: 4, child: Text('Airport')),
                    DropdownMenuItem(value: 5, child: Text('Hotel')),
                  ],
                  hintText: 'Select…',
                  skipValidation: true,
                )
              ),
              10.horizontalSpace,
              // Status
              Expanded(
                child: CustomDropdownField<int>(
                  fieldName: 'Status',
                  value: n.selectedStatus,
                  onChanged: (v) => n.onStatusChange(v ?? 0),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('All')),
                    DropdownMenuItem(value: 1, child: Text('Complete')),
                    DropdownMenuItem(value: 2, child: Text('Incomplete')),
                  ],
                  hintText: 'Select…',
                  skipValidation: true,
                ),
              ),
              10.horizontalSpace,
              // Date range
              CustomButton(
                text: n.dateRangeLabel,
                icon: Icons.calendar_today,
                iconOnLeft: true,
                fullWidth: false,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: Colors.white,
                borderColor: AppColors.primary,
                textStyle: AppFonts.text14.medium.style.copyWith(color: AppColors.primary),
                iconColor: AppColors.primary,
                onPressed: () async {
                  final range = await _pickDateRangeDialog(
                    context,
                    first: DateTime(2020),
                    last: DateTime.now(),
                  );
                  n.onDateRangePicked(range);
                },
              )
            ],
          ),


          // Clear
          CustomButton(
            text: 'Clear Filters',
            fullWidth: false,
            backgroundColor: Colors.white,
            borderColor: AppColors.primary,
            textStyle: AppFonts.text14.semiBold.style.copyWith(color: AppColors.primary),
            onPressed: () {
              _searchCtrl.clear();
              n.clearFilters();
            },
          ),
        ],
      ),
    );
  }
}

class SurveyTable extends StatelessWidget {
  final SurveyListNotifier n;
  final bool fillRemaining; // set true if you want it to expand in a sliver

  const SurveyTable({super.key, required this.n, this.fillRemaining = false});

  @override
  Widget build(BuildContext context) {
    // Card container (same shadow/border style as Home)
    Widget tableCard({required Widget child}) {
      return Container(
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
      );
    }

    final horizCtrl = ScrollController();
    final vertCtrl = ScrollController();
    final rows = n.visibleSurveys;

    // Row height similar to Home table
    final double rowHeight = (45.h).clamp(40, 56);

    // Column widths (mirror Home)
    final deviceW = MediaQuery.of(context).size.width;
    final bool isTablet = deviceW >= 600;
    final double wId = isTablet ? 100 : 100;
    final double wName = isTablet ? 200 : 200;
    final double wType = isTablet ? 200 : 180;
    final double wDate = isTablet ? 200 : 200;
    final double wStatus = isTablet ? 130 : 120;
    final double tableWidth = wId + wName + wType + wDate + wStatus;

    // Header cell & body cell builders
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

    // Header bar (same as Home)
    final header = Container(
      height: 48,
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

    // Date format helper (use your notifier’s if you prefer)
    final df = DateFormat('d MMM yyyy, hh:mm a');
    String _formatDate(dynamic d) {
      if (d == null) return '-';
      if (d is DateTime) return df.format(d);
      // If your local data stores ISO string/epoch, adapt here:
      if (d is String) {
        final parsed = DateTime.tryParse(d);
        return parsed != null ? df.format(parsed) : d;
      }
      return d.toString();
    }

    Widget rowItem(int i) {
      final r = rows[i];
      final isEven = i.isEven;
      final isComplete = (r['status'] == 'Complete');

      return Container(
        color: isEven ? AppColors.background.withOpacity(0.5) : Colors.transparent,
        height: rowHeight.toDouble(),
        child: Row(
          children: [
            bodyCell(Text('${r["id"]}', style: AppFonts.text14.regular.style), wId),
            bodyCell(Text('${r["name"]}', style: AppFonts.text14.regular.style), wName),
            bodyCell(Text('${r["surveyType"]}', style: AppFonts.text14.regular.style), wType),
            bodyCell(Text(_formatDate(r["date"]), style: AppFonts.text14.regular.grey.style), wDate),
            bodyCell(_statusChip(isComplete), wStatus),
          ],
        ),
      );
    }

    // Empty state: single row matching the look
    Widget emptyBody() {
      return SizedBox(
        width: tableWidth,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 24),
          child: Text('No data found', style: AppFonts.text14.regular.grey.style),
        ),
      );
    }

    // When not filling remaining height (typical page)
    if (!fillRemaining) {
      final needsVerticalScroll = rows.length > 6;
      final contentHeight = (rowHeight * rows.length);
      final bodyHeight = needsVerticalScroll
          ? (contentHeight).clamp(rowHeight * 6, MediaQuery.of(context).size.height * 0.61)
          : contentHeight;

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
                  height: rows.isEmpty ? null : bodyHeight.toDouble(),
                  child: rows.isEmpty
                      ? emptyBody()
                      : Scrollbar(
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

    // Fill remaining height (e.g., inside SliverFillRemaining)
    return tableCard(
      child: SizedBox.expand(
        child: Scrollbar(
          controller: horizCtrl,
          thumbVisibility: true,
          notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: horizCtrl,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              height: double.infinity,
              child: Column(
                children: [
                  header,
                  Expanded(
                    child: rows.isEmpty
                        ? emptyBody()
                        : Scrollbar(
                      controller: vertCtrl,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: vertCtrl,
                        padding: EdgeInsets.zero,
                        itemExtent: rowHeight.toDouble(),
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

  Widget _statusChip(bool isComplete) {
    final label = isComplete ? 'Complete' : 'Incomplete';
    final bg = isComplete ? AppColors.success : AppColors.error.withOpacity(0.85);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class PaginationBar extends StatelessWidget {
  final SurveyListNotifier n;
  const PaginationBar({super.key, required this.n});

  @override
  Widget build(BuildContext context) {
    final totalPages = (n.totalItems / n.pageSize).ceil().clamp(1, 9999);

    return Container(
      // decoration: AppStyles.commonDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          // Right — navigation arrows + current page
          _pageButton(
            context,
            icon: LucideIcons.chevronLeft,
            onPressed: n.currentPage > 1 ? n.prevPage : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Page ${n.currentPage} of $totalPages',
              style: AppFonts.text14.medium.style,
            ),
          ),
          _pageButton(
            context,
            icon: LucideIcons.chevronRight,
            onPressed: (n.currentPage * n.pageSize) < n.totalItems ? n.nextPage : null,
          ),
        ],
      ),
    );
  }

  Widget _pageButton(BuildContext context,
      {required IconData icon, VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed == null
            ? AppColors.primary.withOpacity(0.4)
            : AppColors.primary,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        minimumSize: const Size(40, 40),
      ),
      child: Icon(icon, size: 22, color: Colors.white),
    );
  }
}

Future<DateTimeRange?> _pickDateRangeDialog(
    BuildContext context, {
      DateTimeRange? initial,
      required DateTime first,
      required DateTime last,
    }) {
  final theme = Theme.of(context).copyWith(
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
    ),
  );

  return showDateRangePicker(
    context: context,
    firstDate: first,
    lastDate: last,
    initialDateRange: initial,
    helpText: 'Select date range',
    cancelText: 'Cancel',
    confirmText: 'Apply',
    // initialEntryMode: DatePickerEntryMode.calendarOnly, // optional
    builder: (ctx, child) {
      // Compact, centered “dialog” like the time picker
      final mq = MediaQuery.of(ctx);
      final maxW = 420.0;
      final maxH = 520.0;

      return Theme(
        data: theme,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // keep it compact but responsive
              maxWidth: mq.size.width < maxW ? mq.size.width - 32 : maxW,
              maxHeight: mq.size.height < maxH ? mq.size.height - 32 : maxH,
            ),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: child!,
            ),
          ),
        ),
      );
    },
  );
}
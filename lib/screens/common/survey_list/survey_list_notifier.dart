// survey_list_notifier.dart

import 'package:flutter/material.dart' hide Table;
import 'package:intl/intl.dart';
import 'package:srpf/core/base/base_notifier.dart';

import 'package:srpf/core/model/common/dashboard/get_survey_data_request.dart';
import 'package:srpf/core/model/common/dashboard/get_survey_data_response.dart';

import 'package:srpf/core/remote/services/common_repository.dart';

class SurveyListNotifier extends BaseChangeNotifier {
  // Filters
  String searchQuery = '';
  int selectedSurveyType = 0; // 0 = All, 1=Passenger, 2=Freight, 3=Bus, 4=Airport, 5=Hotel
  int selectedStatus = 0;     // 0 = All, 1 = Complete, 2 = Incomplete
  DateTime? fromDate;
  DateTime? toDate;

  // Pagination
  int currentPage = 1;
  int pageSize = 14;
  int totalItems = 0;

  // Data
  List<Map<String, dynamic>> visibleSurveys = [];

  final List<DropdownMenuItem<int>> pageSizeOptions = const [
    DropdownMenuItem(value: 10, child: Text('10')),
    DropdownMenuItem(value: 20, child: Text('20')),
    DropdownMenuItem(value: 50, child: Text('50')),
  ];

  SurveyListNotifier() {
    fetchServerData();
  }

  // ---------------- Server fetch ----------------

  Future<void> fetchServerData() async {
    try {
      isLoading = true;
      notifyListeners();

      final req = _buildRequest();
      final resp = await CommonRepository.instance.apiGetSurveyData(req);

      // Default empty state
      visibleSurveys = [];
      totalItems = 0;

      if (resp is GetSurveyorDataResponse && (resp.status ?? false)) {
        final rows = resp.result?.table ?? const <Table>[];
        final serverCount = (resp.result?.table1?.isNotEmpty ?? false)
            ? (resp.result!.table1!.first.totalCount ?? rows.length)
            : rows.length;

        visibleSurveys = rows.map(_mapRowToItem).toList();
        totalItems = serverCount;
      }

      // If the current page is now out of range (e.g., filters shrank results), bounce back
      final maxPage = (totalItems == 0) ? 1 : ((totalItems - 1) ~/ pageSize) + 1;
      if (currentPage > maxPage) {
        currentPage = maxPage;
        // Re-fetch once at the corrected page (optional; comment out if your API returns any page)
        final req2 = _buildRequest();
        final resp2 = await CommonRepository.instance.apiGetSurveyData(req2);
        if (resp2 is GetSurveyorDataResponse && (resp2.status ?? false)) {
          final rows2 = resp2.result?.table ?? const <Table>[];
          visibleSurveys = rows2.map(_mapRowToItem).toList();
        } else {
          visibleSurveys = [];
        }
      }
    } catch (_) {
      visibleSurveys = [];
      totalItems = 0;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Build the POST body from filters + pagination
  GetSurveyorDataRequest _buildRequest() {
    String? _fmt(DateTime? d) =>
        d == null ? null : DateFormat('yyyy-MM-dd').format(d);

    int? _statusInt() {
      if (selectedStatus == 1) return 1; // Complete
      if (selectedStatus == 2) return 0; // Incomplete
      return null;                       // All
    }

    int? _surveyTypeInt() {
      switch (selectedSurveyType) {
        case 1: return 1; // Petrol
        case 2: return 2; // Border
        case 3: return 3; // Bus
        case 4: return 4; // Airport
        case 5: return 5; // Hotel
        case 6: return 6; // Freight
        default: return null; // All
      }
    }

    // IMPORTANT: Only send dates if BOTH are set, otherwise omit both keys.
    final fromStr = _fmt(fromDate);
    final toStr = _fmt(toDate);
    final sendDates = (fromStr != null && toStr != null);

    return GetSurveyorDataRequest(
      fromDate: sendDates ? fromStr : null,
      toDate:   sendDates ? toStr   : null,
      nStatus: _statusInt(),
      nSurveyType: _surveyTypeInt(),
      nPageNumber: currentPage,
      nPageSize: pageSize,
      sFullName: searchQuery.trim().isEmpty ? null : searchQuery.trim(),
    );
  }

  // ---------------- UI actions -> re-fetch server ----------------

  void setPageSize(int value) {
    pageSize = value;
    currentPage = 1;
    fetchServerData();
  }

  void clearFilters() {
    searchQuery = '';
    selectedSurveyType = 0;
    selectedStatus = 0;
    fromDate = null;
    toDate = null;
    currentPage = 1;
    fetchServerData();
  }

  String get dateRangeLabel {
    if (fromDate == null || toDate == null) return 'Select Date Range';
    return '${DateFormat('dd MMM yyyy').format(fromDate!)} → ${DateFormat('dd MMM yyyy').format(toDate!)}';
  }

  int get firstItemIndex =>
      totalItems == 0 ? 0 : ((currentPage - 1) * pageSize) + 1;

  int get lastItemIndex =>
      (firstItemIndex == 0) ? 0 : (firstItemIndex + visibleSurveys.length - 1);

  void onSearch(String value) {
    searchQuery = value;
    currentPage = 1;
    fetchServerData();
  }

  void onSurveyTypeChange(int value) {
    selectedSurveyType = value;
    currentPage = 1;
    fetchServerData();
  }

  void onStatusChange(int value) {
    selectedStatus = value;
    currentPage = 1;
    fetchServerData();
  }

  void onDateRangePicked(DateTimeRange? range) {
    if (range == null) return;
    fromDate = range.start;
    toDate = range.end;
    currentPage = 1;
    fetchServerData();
  }

  void nextPage() {
    if ((currentPage * pageSize) >= totalItems) return;
    currentPage++;
    fetchServerData();
  }

  void prevPage() {
    if (currentPage <= 1) return;
    currentPage--;
    fetchServerData();
  }

  String formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  // ---------------- mapping ----------------

  Map<String, dynamic> _mapRowToItem(Table t) {
    final id = t.id ?? 0;

    // Convert nStatus safely
    final status = (t.nStatus == 1 || t.nStatus == '1')
        ? 'Complete'
        : 'Incomplete';

    // Determine survey type (Freight = N_SurveyType == 0)
    String surveyType = 'Unknown';

    if (t.nSurveyType == 0) {
      surveyType = 'Freight';
    } else if (t.sSurveyType != null && t.sSurveyType!.trim().isNotEmpty) {
      final s = t.sSurveyType!.trim().toLowerCase();
      if (s.contains('petrol')) surveyType = 'Car(Petrol)';
      else if (s.contains('border')) surveyType = 'Car(Border)';
      else if (s.contains('bus')) surveyType = 'Bus';
      else if (s.contains('airport')) surveyType = 'Airport';
      else if (s.contains('hotel')) surveyType = 'Hotel';
      else if (s.contains('freight')) surveyType = 'Freight';
      else surveyType = t.sSurveyType!;
    }

    return {
      "id": id,
      "name": (t.sFullName ?? '').trim().isEmpty ? '—' : t.sFullName,
      "surveyType": surveyType,
      "status": status,
      "date": t.dtCreatedDate ?? DateTime.now(),
    };
  }
}

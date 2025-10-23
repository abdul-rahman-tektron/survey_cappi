import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:srpf/core/base/base_notifier.dart';
import 'package:srpf/core/model/common/dashboard/enumerator_count_request.dart';
import 'package:srpf/core/model/common/dashboard/enumerator_count_response.dart';
import 'package:srpf/core/model/common/dashboard/get_surveyor_location_response.dart';
import 'package:srpf/core/model/common/dashboard/survey_data_response.dart';
import 'package:srpf/core/remote/services/common_repository.dart';
import 'package:srpf/res/colors.dart';
import 'package:srpf/utils/enums.dart';

class HomeNotifier extends BaseChangeNotifier {
  // ── RSI (Freight)
  double _todayRsi = 0;
  double _targetRsi = 0;
  double _totalRsi = 0;

  // ── Passenger
  double _todayPassenger = 0;
  double _targetPassenger = 0;
  double _totalPassenger = 0;

  // (Optional) still available if you want to show it elsewhere
  double _totalSurveys = 0;

  // Expose getters if needed
  double get todayRsi => _todayRsi;

  double get targetRsi => _targetRsi;

  double get totalRsi => _totalRsi;

  double get todayPassenger => _todayPassenger;

  double get targetPassenger => _targetPassenger;

  double get totalPassenger => _totalPassenger;

  double get totalSurveys => _totalSurveys;

  double get overallTotal => _totalRsi + _totalPassenger;

  List<QuickStat> get quickStats {
    return [
      // Freight (RSI)
      QuickStat(
        icon: LucideIcons.box,
        iconColor: Colors.blue,
        iconBgColor: Colors.blue.withOpacity(0.1),
        label: "Today Freight (RSI)",
        count: _todayRsi,
        total: _targetRsi,
      ),
      QuickStat(
        icon: LucideIcons.flag,
        iconColor: Colors.indigo,
        iconBgColor: Colors.indigo.withOpacity(0.1),
        label: "Target Freight (RSI)",
        count: _totalRsi,
        total: _targetRsi,
        displayType: StatDisplayType.withProgress,
      ),
      QuickStat(
        icon: LucideIcons.packageCheck,
        iconColor: Colors.teal,
        iconBgColor: Colors.teal.withOpacity(0.1),
        label: "Total Freight (RSI)",
        count: _totalRsi,
        total: _totalRsi,
      ),

      // Passenger
      QuickStat(
        icon: LucideIcons.users,
        iconColor: Colors.orange,
        iconBgColor: Colors.orange.withOpacity(0.1),
        label: "Today Passenger",
        count: _todayPassenger,
        total: _targetPassenger,
      ),
      QuickStat(
        icon: LucideIcons.target,
        iconColor: Colors.pink,
        iconBgColor: Colors.pink.withOpacity(0.1),
        label: "Target Passenger",
        count: _totalPassenger,
        total: _targetPassenger,
        displayType: StatDisplayType.withProgress,
      ),
      QuickStat(
        icon: LucideIcons.userCheck,
        iconColor: Colors.red,
        iconBgColor: Colors.red.withOpacity(0.1),
        label: "Total Passenger",
        count: _totalPassenger,
        total: _totalPassenger,
      ),

      // Overall
      QuickStat(
        icon: LucideIcons.chartPie,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primary.withOpacity(0.1),
        label: "Overall Total Surveys",
        count: overallTotal,
        total: overallTotal,
      ),
    ];
  }

  /// Top-level categories: Passenger, RSI
  List<CategoryTop> get categoryTop => [
    CategoryTop(
      icon: LucideIcons.usersRound200,
      iconColor: AppColors.primary,
      iconBgColor: Colors.blue.withOpacity(0.1),
      type: TopLevelType.passenger,
      label: "Passenger",
    ),
    CategoryTop(
      icon: LucideIcons.trafficCone200,
      iconColor: AppColors.primary,
      iconBgColor: Colors.green.withOpacity(0.1),
      type: TopLevelType.rsi,
      label: "Freight",
    ),
  ];

  // Admin gate (tweak to match your user model)
  bool get isAdmin {
    final role = (userData?.nRoleId.toString() ?? '').toLowerCase();
    return role.contains('1');
  }

  // Enumerator map state
  final List<EnumeratorPin> _enumerators = [];

  List<EnumeratorPin> get enumerators => List.unmodifiable(_enumerators);

  Set<Marker> _markers = {};

  Set<Marker> get markers => _markers;

  // Optionally keep the last tapped enumerator for a bottom sheet / card
  EnumeratorPin? _selectedEnumerator;

  EnumeratorPin? get selectedEnumerator => _selectedEnumerator;

  set selectedEnumerator(EnumeratorPin? e) {
    _selectedEnumerator = e;
    notifyListeners();
  }

  // UAE-ish default (center between AUH/DXB)
  static const LatLng _uaeCenter = LatLng(24.4539, 54.3773);
  CameraPosition _initialCamera = const CameraPosition(target: _uaeCenter, zoom: 6.8);

  CameraPosition get initialCamera => _initialCamera;

  HomeNotifier() {
    loadUserData();
    loadApi();
  }

  Future<void> loadApi() async {
    await loadEnumeratorCount();
    await loadSurveyData();
    if (isAdmin) {
      await loadEnumeratorLocations(); // 👈 only for admins
    }
  }

  Future<void> loadEnumeratorLocations() async {
    try {
      // 🔹 1. Call the real API
      final resp = await CommonRepository.instance.apiGetSurveyorLocation({
        "N_CreatedBy": userData?.userId ?? 0, // optional filter if backend supports
      });

      if (resp is! GetSurveyorLocationResponse || resp.status != true || resp.result == null) {
        debugPrint('⚠️ No data or failed response from GetSurveyorLocation');
        _enumerators.clear();
        _markers.clear();
        notifyListeners();
        return;
      }

      final rows = resp.result?.table ?? [];

      // 🔹 2. Convert to EnumeratorPin list
      _enumerators
        ..clear()
        ..addAll(rows.map((r) => EnumeratorPin(
          id: r.nCreatedBy ?? 0,
          name: r.surveyor ?? 'Unknown',
          lat: r.sLattitudeActual ?? 0.0,
          lon: r.sLongitudeActual ?? 0.0,
          role: r.roleName ?? 'Enumerator',
          surveyType: r.surveyType ?? '-',
          target: r.targets ?? 0,
          completed: r.totalInterviews ?? 0, // API doesn't give this field yet
          lastSeen: r.dtRecorded ?? r.lastSeen,
        )));

      // 🔹 3. Create Google Map markers
      _markers = _enumerators.map((e) {
        final survey = (e.surveyType ?? '').trim();
        final color = surveyTypeColors.entries
            .firstWhere(
              (entry) => survey.toLowerCase().contains(entry.key.toLowerCase()),
          orElse: () => const MapEntry('default', Colors.grey),
        )
            .value;

        return Marker(
          markerId: MarkerId('enum_${e.id}'),
          position: LatLng(e.lat, e.lon),
          icon: BitmapDescriptor.defaultMarkerWithHue(_colorToHue(color)),
          infoWindow: InfoWindow(title: e.name, snippet: e.surveyType ?? ''),
          onTap: () => selectedEnumerator = e,
        );
      }).toSet();

      // 🔹 4. Center the camera on bounds
      if (_enumerators.length >= 2) {
        final lats = _enumerators.map((e) => e.lat).toList()..sort();
        final lons = _enumerators.map((e) => e.lon).toList()..sort();
        final sw = LatLng(lats.first, lons.first);
        final ne = LatLng(lats.last, lons.last);
        final midLat = (sw.latitude + ne.latitude) / 2;
        final midLon = (sw.longitude + ne.longitude) / 2;
        _initialCamera = CameraPosition(target: LatLng(midLat, midLon), zoom: 8.5);
      }

      notifyListeners();
      debugPrint('✅ Enumerator map updated with ${_enumerators.length} entries');
    } catch (e, st) {
      debugPrint('❌ loadEnumeratorLocations error: $e\n$st');
    }
  }

  double _colorToHue(Color c) {
    // convert Flutter color to GoogleMap hue (0-360)
    final hsl = HSLColor.fromColor(c);
    return hsl.hue;
  }

  final Map<String, Color> surveyTypeColors = {
    'Freight': Colors.teal, // freight RSI
    'Car Border': Colors.blue, // vehicle survey at border
    'Car Petrol': Colors.orange, // petrol station
    'Airport': Colors.purple, // airport surveys
    'Bus': Colors.redAccent, // bus station
    'Hotel': Colors.indigo, // hotel location
  };

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return '${diff.inDays} d ago';
  }

  String _search = '';

  set search(String v) {
    _search = v;
    notifyListeners();
  }

  String get search => _search;

  // HomeNotifier.dart (add near your fields)
  final List<InterviewRow> _surveyRows = [];

  List<InterviewRow> get interviews {
    // filter on ID / name / survey type
    if (_search.trim().isEmpty) return _surveyRows;
    final q = _search.trim().toLowerCase();
    return _surveyRows.where((r) {
      return r.interviewId.toLowerCase().contains(q) ||
          r.name.toLowerCase().contains(q) ||
          (r.surveyType?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> loadEnumeratorCount() async {
    try {
      final resp = await CommonRepository.instance.apiEnumeratorCount(
        EnumeratorCountRequest(nUserId: userData?.userId ?? 0),
      );

      if (resp is! EnumeratorCountResponse ||
          resp.status != true ||
          resp.result == null ||
          resp.result!.isEmpty) {
        notifyListeners();
        return;
      }

      final r = resp.result!.first;

      // Overall
      _totalSurveys = _toDouble(r.totalEnumerators);

      // ── Freight (RSI)
      _targetRsi = _toDouble(r.totalRsiTargetSurveys);
      _totalRsi = _toDouble(r.totalRsiSurveysCompleted);
      _todayRsi = _toDouble(r.todayRsiSurveysCompleted);
      // If you later want "approached", it's available as:
      // final todayRsiApproached = _toDouble(r.todayRsiSurveysApproached);

      // ── Passenger
      _targetPassenger = _toDouble(r.totalPassengerTargetSurveys);
      _totalPassenger = _toDouble(r.totalPassengerSurveysCompleted);
      _todayPassenger = _toDouble(r.todayPassengerSurveysCompleted);
      // final todayPassengerApproached = _toDouble(r.todayPassengerSurveysApproached);

      notifyListeners();
    } catch (e, st) {
      debugPrint('loadEnumeratorCount error: $e\n$st');
      notifyListeners();
    }
  }

  Future<void> loadSurveyData() async {
    try {
      final resp = await CommonRepository.instance.apiSurveyData(
        EnumeratorCountRequest(nUserId: userData?.userId ?? 0),
      );

      if (resp is! SurveyDataResponse || resp.status != true || resp.result == null) {
        notifyListeners();
        return;
      }

      // map API -> table rows
      _surveyRows
        ..clear()
        ..addAll(
          resp.result!.map(
            (s) => InterviewRow(
              interviewId: (s.recordId ?? 0).toString(),
              name: s.name?.trim().isNotEmpty == true ? s.name!.trim() : '-',
              interviewDate: s.surveyDate,
              // can be null
              status: _statusFromApi(s.status),
              // map string -> enum
              surveyType: s.surveyType?.trim(), // keep for filtering + display
            ),
          ),
        );

      notifyListeners();
    } catch (e, st) {
      debugPrint('loadSurveyData error: $e\n$st');
      notifyListeners();
    }
  }

  InterviewStatus _statusFromApi(String? s) {
    final t = (s ?? '').toLowerCase();
    if (t == 'complete' || t == 'completed' || t == 'done') {
      return InterviewStatus.complete;
    }
    return InterviewStatus.incomplete;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    final s = v.toString();
    final parsed = double.tryParse(s);
    return parsed ?? 0;
  }
}

enum StatDisplay { number, fraction }

class QuickStat {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final double? count;
  final String label;
  final double total;
  final StatDisplayType displayType;

  QuickStat({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.count,
    required this.label,
    required this.total,
    this.displayType = StatDisplayType.number,
  });
}

enum TopLevelType { passenger, rsi }

class CategoryTop {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final TopLevelType type;
  final String label;

  CategoryTop({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.type,
    required this.label,
  });
}

enum StatDisplayType { number, withProgress }

enum InterviewStatus { incomplete, complete }

class InterviewRow {
  final String interviewId;
  final String name;
  final DateTime? interviewDate; // make nullable
  final InterviewStatus status;
  final String? surveyType; // new

  InterviewRow({
    required this.interviewId,
    required this.name,
    required this.interviewDate,
    required this.status,
    this.surveyType,
  });
}

class EnumeratorPin {
  final int id;
  final String name;
  final double lat;
  final double lon;
  final DateTime? lastSeen;
  final String? phone;
  final String? surveyType; // "RSI" or "Passenger"
  final int? target;
  final int? completed;
  final String? role;

  EnumeratorPin({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    this.lastSeen,
    this.phone,
    this.surveyType,
    this.target,
    this.completed,
    this.role,
  });
}

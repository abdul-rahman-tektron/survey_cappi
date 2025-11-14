import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:srpf/core/base/base_notifier.dart';
import 'package:srpf/core/model/common/success/common_success_response.dart';
import 'package:srpf/core/model/common/error/common_response.dart';
import 'package:srpf/core/model/questionnaire/sp_questionnaire/add_sp_request.dart';
import 'package:srpf/core/questions/model/sp_2_model.dart';
import 'package:srpf/core/remote/services/common_repository.dart';
import 'package:srpf/utils/helpers/toast_helper.dart';
import 'package:srpf/utils/router/routes.dart';

class Sp2SurveyNotifier extends BaseChangeNotifier {
  final List<Sp2Set> sets;
  final int totalSets;
  final int? interviewMasterId;

  // carry timing across
  final int continuedElapsedSec;
  final String? startedIso;

  int _current = 0;
  Timer? _ticker;
  DateTime _startedAt = DateTime.now();

  Sp2SurveyNotifier({
    required this.sets,
    this.interviewMasterId,
    this.continuedElapsedSec = 0,
    this.startedIso,
  }) : totalSets = sets.length {
    _startedAt = _resolveStartedAt();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
    Future.microtask(() async => await loadUserData());
  }

  DateTime _resolveStartedAt() {
    if (startedIso != null && startedIso!.trim().isNotEmpty) {
      try { return DateTime.parse(startedIso!); } catch (_) {}
    }
    return DateTime.now().subtract(Duration(seconds: continuedElapsedSec));
  }

  int get totalElapsedSeconds => DateTime.now().difference(_startedAt).inSeconds;
  String get elapsedText {
    final s = totalElapsedSeconds.clamp(0, 24 * 60 * 60);
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  int get currentIndex => _current;
  Sp2Set get currentSet => sets[_current];
  bool get canGoPrev => _current > 0;
  bool get canGoNext => _current < totalSets - 1;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void prev() { if (!canGoPrev) return; _current--; notifyListeners(); }
  void next() { if (!canGoNext) return; _current++; notifyListeners(); }

  void selectOption(Sp2Mode mode) {
    if (mode == Sp2Mode.car && currentSet.carOwner == false) return;
    final idx = currentSet.options.indexWhere((o) => o.mode == mode);
    if (idx != -1) { currentSet.selectedIndex = idx; notifyListeners(); }
  }

  bool get isComplete => sets.every((s) => s.selectedIndex != null);

  AddSpRequest? _buildRequestForSet(
      Sp2Set s, {
        required int userId,
        required String startedIso,
        required String endedIso,
        required String totalTimeText,
      }) {
    final i = s.selectedIndex;
    if (i == null) return null;
    final picked = s.options[i];

    // IMPORTANT: Shuttle maps to RAIL fields — same API as SP1
    final isCar     = picked.mode == Sp2Mode.car;
    final isTaxi    = picked.mode == Sp2Mode.taxi;
    final isShuttle = picked.mode == Sp2Mode.shuttle;
    final isBus     = picked.mode == Sp2Mode.bus;

    return AddSpRequest(
      dtInterviewStartTime: startedIso,
      dtInterviewEndTime:   endedIso,
      sTotalTime:           totalTimeText,
      nInterviewMasterId:   interviewMasterId,
      nCreatedBy:           userId,
      action:               'add',
      spTime:               elapsedText,
      sSpTag:               _tagFor(picked.mode),   // for reporting tag

      sReference:   s.reference,
      sOdForSp:     s.origin,
      sDestination: s.destination,
      sCarOwner:    s.carOwner ? 'Yes' : 'No',
      sHsRailElig:  'No', // not used in SP2; set as needed
      nScenario:    s.scenario,

      spFuelCost: picked.fuelCost?.toString(),
      spTollCost: picked.tollsCost?.toString(),
      spParkingCost: picked.parkingCost?.toString(),

      spCarCost:   isCar  ? picked.totalCost?.toString() : null,
      spCarTime:   isCar  ? picked.totalTime?.toString() : null,
      spTaxiCost:  isTaxi ? picked.totalCost?.toString() : null,
      spTaxiTime:  isTaxi ? picked.totalTime?.toString() : null,

      // Shuttle → use Rail fields
      spRailCommuteTime: isShuttle ? picked.timeToFromShuttleStops?.toString() : null,
      spRailTime:        isShuttle ? picked.timeOnShuttle?.toString() : null,
      spRailCost:        isShuttle ? picked.totalCost?.toString() : null,
      spRailTotalTime:   isShuttle ? picked.totalTime?.toString() : null,

      // Bus
      spBusCommuteTime:  isBus ? picked.timeToFromBusStops?.toString() : null,
      spBusTime:         isBus ? picked.timeOnBus?.toString() : null,
      spBusCost:         isBus ? picked.totalCost?.toString() : null,
      spBusTotalTime:    isBus ? picked.totalTime?.toString() : null,
    );
  }

  String _tagFor(Sp2Mode m) {
    switch (m) {
      case Sp2Mode.car:     return 'car';
      case Sp2Mode.taxi:    return 'taxi';
      case Sp2Mode.shuttle: return 'shuttle';
      case Sp2Mode.bus:     return 'bus';
    }
  }

  Future<bool> submitFinal(BuildContext context) async {
    bool ok = false;

    await runWithLoadingVoid(() async {
      if (!isComplete) {
        ToastHelper.showError('Please complete all sets before submitting.');
        ok = false; return;
      }

      final uid = userData?.userId ?? 0;
      final startedIso = _startedAt.toIso8601String();
      final endedIso   = DateTime.now().toIso8601String();
      final totalTime  = elapsedText;

      final requests = <AddSpRequest>[];
      for (final s in sets) {
        final r = _buildRequestForSet(
          s,
          userId: uid,
          startedIso: startedIso,
          endedIso: endedIso,
          totalTimeText: totalTime,
        );
        if (r == null) { ok = false; return; }
        requests.add(r);
      }

      final resp = await CommonRepository.instance.apiAddSPData(requests);

      if (resp is CommonSuccessResponse && (resp.status ?? false)) {
        ToastHelper.showSuccess('SP2 (Shuttle) submitted successfully');
        ok = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
          }
        });
      } else {
        ok = false;
        ToastHelper.showError('Unable to submit SP2 data. Please try again.',
            error: 'Unable to submit SP2 data. Please try again.', stack: StackTrace.current);
      }
    });

    return ok;
  }
}

/// --- Mock (unchanged) ---
List<Sp2Set> mock2LoadSixSets() {
  Sp2Set makeSet(
      String ref, {
        required String origin,
        required String destination,
        required bool rail,
        required int scenario,
      }) {
    const opts = [
      Sp2Option(mode: Sp2Mode.car,  totalCost: 80,  totalTime: 45, fuelCost: 45, tollsCost: 25, parkingCost: 10),
      Sp2Option(mode: Sp2Mode.taxi, totalCost: 80, totalTime: 45),
      Sp2Option(mode: Sp2Mode.shuttle, totalCost: 80,  totalTime: 45, timeToFromShuttleStops: 15, timeOnShuttle: 30),
      Sp2Option(mode: Sp2Mode.bus,  totalCost: 80,  totalTime: 45, timeToFromBusStops: 15, timeOnBus: 30),
    ];

    return Sp2Set(
      reference: ref,
      origin: origin,
      destination: destination,
      carOwner: true,
      scenario: scenario,
      options: opts,
    );
  }

  return [
    makeSet('H2',  origin: 'Abu Dhabi', destination: 'Dubai',      rail: false, scenario: 1),
    makeSet('H3',  origin: 'Abu Dhabi', destination: 'Dubai',      rail: false, scenario: 2),
    makeSet('H8',  origin: 'Abu Dhabi', destination: 'Dubai',      rail: true,  scenario: 1),
    makeSet('H9',  origin: 'Abu Dhabi', destination: 'Dubai',      rail: true,  scenario: 2),
    makeSet('H26', origin: 'Dubai',     destination: 'Abu Dhabi',  rail: false, scenario: 1),
    makeSet('H32', origin: 'Dubai',     destination: 'Abu Dhabi',  rail: true,  scenario: 1),
  ];
}
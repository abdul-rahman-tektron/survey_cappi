import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:srpf/core/base/base_notifier.dart';
import 'package:srpf/core/model/common/error/common_response.dart';
import 'package:srpf/core/model/common/success/common_success_response.dart';
import 'package:srpf/core/model/questionnaire/sp_questionnaire/add_sp_request.dart';
import 'package:srpf/core/questions/model/sp_model.dart';
import 'package:srpf/core/remote/services/common_repository.dart';
import 'package:srpf/utils/helpers/toast_helper.dart';
import 'package:srpf/utils/router/routes.dart';

String spLabel(SpMode mode) {
  switch (mode) {
    case SpMode.car:  return 'car';
    case SpMode.taxi: return 'taxi';
    case SpMode.rail: return 'rail';
    case SpMode.bus:  return 'bus';
  }
}

class SpSurveyNotifier extends BaseChangeNotifier {
  final List<SpSet> sets;
  final int totalSets;
  final int? interviewMasterId;
  int _current = 0;
  /// ⏱ These two are new — passed from Passenger flow
  final int continuedElapsedSec;
  final String? startedIso;

  Timer? _ticker;
  DateTime _startedAt = DateTime.now();
  int _elapsedSec = 0;

  SpSurveyNotifier({required this.sets, this.interviewMasterId, this.continuedElapsedSec = 0,
    this.startedIso,})
      : totalSets = sets.length {
    _startedAt = _resolveStartedAt();            // set immediately
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
    Future.microtask(() async {
      await loadUserData();
    });
  }


  DateTime _resolveStartedAt() {
    // Prefer the real interview start you passed from Passenger
    if (startedIso != null && startedIso!.trim().isNotEmpty) {
      try { return DateTime.parse(startedIso!); } catch (_) {}
    }
    // Fallback: reconstruct from carried seconds
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
  SpSet get currentSet => sets[_current];

  bool get canGoPrev => _current > 0;
  bool get canGoNext => _current < totalSets - 1;


  String _formatMmSs(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

// SpSurveyNotifier
  void _startTimer() {
    _ticker?.cancel();
    debugPrint('SP⏱ _startTimer IN → continuedElapsedSec=$continuedElapsedSec '
        'startedIso=$startedIso');
    _startedAt = startedIso != null ? DateTime.parse(startedIso!) : DateTime.now();

    // ✅ Robust fallback: if the passed value is 0 but we have a start time, recompute.
    final fromStart = DateTime.now().difference(_startedAt).inSeconds;
    _elapsedSec = (continuedElapsedSec > 0) ? continuedElapsedSec : fromStart.clamp(0, 1 << 31);
    debugPrint('SP⏱ _startTimer SET → _elapsedSec=$_elapsedSec '
        '(fromStart=$fromStart startedAt=$_startedAt)');

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSec++;
      if (_elapsedSec % 10 == 0) {
        debugPrint('SP⏱ tick → $_elapsedSec sec');
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void prev() {
    if (!canGoPrev) return;
    _current--;
    notifyListeners();
  }

  void next() {
    if (!canGoNext) return;
    _current++;
    notifyListeners();
  }

  void selectOption(SpMode mode) {
    if (mode == SpMode.car && currentSet.carOwner == false) return;
    final idx = currentSet.options.indexWhere((o) => o.mode == mode);
    if (idx != -1) {
      currentSet.selectedIndex = idx;
      notifyListeners();
    }
  }

  bool get isComplete => sets.every((s) => s.selectedIndex != null);

  AddSpRequest? _buildRequestForSet(
      SpSet s, {
        required int userId,
        required int nStatus, // keep if your API needs it later
        required String startedIso,
        required String endedIso,
        required String totalTimeText,
      }) {
    final pickedIndex = s.selectedIndex;
    if (pickedIndex == null) return null;

    final picked = s.options[pickedIndex];
    final mode = picked.mode;

    return AddSpRequest(
      // If editing existing rows, set IDs & action='update' here.
      // nSpAnswerId: s.spAnswerId,
      // NEW timing fields
      dtInterviewStartTime: startedIso,
      dtInterviewEndTime:   endedIso,
      sTotalTime:           totalTimeText,
      nInterviewMasterId: interviewMasterId,
      nCreatedBy: userId,
      action: 'add', // or 'update' if editing
      spTime: elapsedText,
      sSpTag: spLabel(mode),
      sReference: s.reference,
      sOdForSp: s.origin,
      sDestination: s.destination,
      sCarOwner: s.carOwner ? 'Yes' : 'No',
      sHsRailElig: s.hsRailRelevant ? 'Yes' : 'No',
      nScenario: s.scenario,

      spFuelCost: picked.fuelCost?.toString(),
      spTollCost: picked.tollsCost?.toString(),
      spParkingCost: picked.parkingCost?.toString(),

      spCarCost:       mode == SpMode.car  ? picked.totalCost.toString() : null,
      spCarTime:       mode == SpMode.car  ? picked.totalTime.toString() : null,
      spTaxiCost:      mode == SpMode.taxi ? picked.totalCost.toString() : null,
      spTaxiTime:      mode == SpMode.taxi ? picked.totalTime.toString() : null,
      spRailCommuteTime: mode == SpMode.rail ? picked.timeToFromStations?.toString() : null,
      spRailTime:        mode == SpMode.rail ? picked.timeOnTrain?.toString() : null,
      spRailCost:        mode == SpMode.rail ? picked.totalCost.toString() : null,
      spRailTotalTime:   mode == SpMode.rail ? picked.totalTime.toString() : null,
      spBusCommuteTime:  mode == SpMode.bus  ? picked.timeToFromBusStops?.toString() : null,
      spBusTime:         mode == SpMode.bus  ? picked.timeOnBus?.toString() : null,
      spBusCost:         mode == SpMode.bus  ? picked.totalCost.toString() : null,
      spBusTotalTime:    mode == SpMode.bus  ? picked.totalTime.toString() : null,
    );
  }

  /// Submit all sets as ONE bulk payload (list of 6 maps).
  /// Returns true/false so your button handler can react.
  Future<bool> submitFinal(BuildContext context) async {
    bool ok = false;

    await runWithLoadingVoid(() async {
      if (!isComplete) {
        ToastHelper.showError('Please complete all sets before submitting.');
        ok = false;
        return;
      }

      final uid = userData?.userId ?? 0;

      // NEW: timing fields to attach to each row
      final startedIso   = _startedAt.toIso8601String();
      final endedIso     = DateTime.now().toIso8601String();
      final totalTimeTxt = elapsedText; // e.g., "mm:ss"

      // Build list payload
      final requests = <AddSpRequest>[];
      for (final s in sets) {
        final req = _buildRequestForSet(
          s,
          userId: uid,
          nStatus: 1,
          startedIso: startedIso,
          endedIso: endedIso,
          totalTimeText: totalTimeTxt,
        );
        if (req == null) {
          debugPrint('⚠️ Missing selection for set ${s.reference}');
          ok = false;
          return;
        }
        requests.add(req);
      }

      if (requests.length != sets.length) {
        ToastHelper.showError('Some sets are incomplete.');
        ok = false;
        return;
      }

      // 🔥 Call BULK API with the list
      final resp = await CommonRepository.instance.apiAddSPData(requests);


      if (resp is CommonSuccessResponse && (resp.status ?? false)) {
        ok = true;
        // ✅ Show success toast
        ToastHelper.showSuccess('SP Data submitted successfully');

        // ✅ Navigate back to home screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
                  (route) => false,
            );
          }
        });
      } else {
        ok = false;
        ToastHelper.showError('Unable to submit SP data. Please try again.', error: 'Unable to submit SP data. Please try again.', stack: StackTrace.current);
      }
    });

    return ok;
  }
}


/// --- Mock (unchanged) ---
List<SpSet> mockLoadSixSets() {
  SpSet makeSet(
      String ref, {
        required String origin,
        required String destination,
        required bool rail,
        required int scenario,
      }) {
    const opts = [
      SpOption(mode: SpMode.car,  totalCost: 80,  totalTime: 45, fuelCost: 45, tollsCost: 25, parkingCost: 10),
      SpOption(mode: SpMode.taxi, totalCost: 80, totalTime: 45),
      SpOption(mode: SpMode.rail, totalCost: 80,  totalTime: 45, timeToFromStations: 15, timeOnTrain: 30),
      SpOption(mode: SpMode.bus,  totalCost: 80,  totalTime: 45, timeToFromBusStops: 15, timeOnBus: 30),
    ];

    return SpSet(
      reference: ref,
      origin: origin,
      destination: destination,
      carOwner: true,
      hsRailRelevant: rail,
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
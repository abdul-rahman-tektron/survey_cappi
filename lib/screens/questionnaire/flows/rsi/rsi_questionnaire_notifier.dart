// flows/rsi/rsi_questionnaire_notifier.dart
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:srpf/core/model/common/dropdown/dropdown_request.dart';
import 'package:srpf/core/model/common/dropdown/dropdown_response.dart';
import 'package:srpf/core/model/questionnaire/rsi_questionnaire/get_rsi_data_request.dart';
import 'package:srpf/core/model/questionnaire/rsi_questionnaire/get_rsi_data_response.dart';
import 'package:srpf/core/model/questionnaire/rsi_questionnaire/rsi_questionnaire_request.dart';
import 'package:srpf/core/model/questionnaire/rsi_questionnaire/rsi_questionnaire_response.dart';
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/core/questions/rsi_question.dart';
import 'package:srpf/core/remote/services/common_repository.dart';
import 'package:srpf/res/api_constants.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';
import 'package:srpf/utils/enums.dart';
import 'package:srpf/utils/helpers/toast_helper.dart';
import 'package:srpf/utils/location_helper.dart';
import 'package:srpf/utils/router/routes.dart';

/// RSI-only notifier. No Passenger logic here.
/// - Builds RSI sections (A..E)
/// - Loads masters (commodities=20, hauler=22)
/// - Submits AddRsiRequest
class RsiQuestionnaireNotifier extends BaseQuestionnaireNotifier {
  final int? editRsiId;
  int _editBaselineSeconds = 0;
  RsiQuestionnaireNotifier(
      BuildContext context, {
        QuestionnaireType? questionnaireType,
        this.editRsiId,
      }) : super(
    context,
    questionnaireType: questionnaireType ?? QuestionnaireType.freightRsi,
  );

  // ───────────────────────────────────────────────────────────────────────────
  // Init / Sections
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Future<void> onInit(BuildContext context) async {
    // Local fallbacks first (used by several RSI questions)
    await loadUserData();
    _seedLocalCatalogs();

    // RSI sections are fixed (A..E)
    sections = [
      rsiSectionA,
      rsiSectionB,
      rsiSectionC,
      rsiSectionD,
      rsiSectionE,
    ];

    applyAutoCapture();
    enforceTimingGuards();
    notifyListeners();

    // Load remote masters (commodities / hauler)
    // fire-and-forget
    unawaited(_loadMasters(context));

    if (editRsiId != null) {
      unawaited(_prefillFromServer(editRsiId!));
    }
  }

  void _clearAllState() {
    _editBaselineSeconds = 0;
    elapsedOffsetSeconds = 0;
    // if you want to land on home with a completely fresh instance next time:
    questionnaireType = QuestionnaireType.freightRsi; // or null if you want a type picker elsewhere

    // Reset and rebuild clean RSI sections
    resetQuestionnaire(
      unlockType: true,
      resetTimer: true,
      freshSections: [
        rsiSectionA,
        rsiSectionB,
        rsiSectionC,
        rsiSectionD,
        rsiSectionE,
      ],
    );
  }


  Future<void> _prefillFromServer(int rsiId) async {
    try {
      final result = await CommonRepository.instance.apiGetRSIData(
        GetRsiDataRequest(nRsiid: rsiId),
      );

      if (result is GetRsiDataResponse && (result.status ?? false)) {
        final data = (result.result ?? const <GetRSIData>[]).isNotEmpty
            ? result.result!.first
            : null;
        if (data != null) {
          _editBaselineSeconds = _parseClockToSeconds(data.sTotalTime);
          elapsedOffsetSeconds = _editBaselineSeconds;
          _applyApiPrefillFrom(data);
          // after setting answers, re-run visibility/auto fields if needed
          applyAutoCapture();
          notifyListeners();
        }
      } else {
        debugPrint('⚠️ getRSIData failed or empty for id=$rsiId');
      }
    } catch (e, st) {
      debugPrint('❌ _prefillFromServer error: $e\n$st');
    }
  }

  String? _fmtDate(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    // Accept "2025-10-07" or "2025-10-07T00:00:00"
    final s = iso.trim();
    final core = s.contains('T') ? s.split('T').first : s;
    // return as yyyy-MM-dd (what most date fields expect)
    return core;
  }

  String? _fmtTime(dynamic t) {
    if (t == null) return null;

    // Already a DateTime?
    if (t is DateTime) {
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    // String cases: "HH:mm", "HH:mm:ss", "HH:mm:ss.SSSSSSS"
    final s = t.toString().trim();
    if (s.isEmpty) return null;
    final parts = s.split(':'); // ["HH","mm",...]
    if (parts.length >= 2) {
      final hh = parts[0].padLeft(2, '0');
      final mm = parts[1].padLeft(2, '0');
      return '$hh:$mm';
    }
    return s; // fallback
  }

  String? _combineDateTime(String? isoDate, String? time) {
    final d = _fmtDate(isoDate);
    final tt = _fmtTime(time);
    if (d == null || tt == null) return null;
    // Many DateTime inputs accept "yyyy-MM-dd HH:mm"
    return '$d $tt';
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return DateTime(v.year, v.month, v.day);
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    // Accepts "2025-10-07", "2025-10-07T00:00:00", etc.
    final dt = DateTime.tryParse(s);
    return dt == null ? null : DateTime(dt.year, dt.month, dt.day);
  }

  (int?, int?) _parseHhMm(dynamic v) {
    if (v == null) return (null, null);
    final s = v.toString().trim();
    if (s.isEmpty) return (null, null);
    final parts = s.split(':'); // "HH:mm", "HH:mm:ss", "HH:mm:ss.SSS..."
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      return (h, m);
    }
    return (null, null);
  }

  /// Merge a date (falling back to "today" if missing) with a time string.
  /// Returns ISO 8601 string ("yyyy-MM-ddTHH:mm:ss.mmmuuu").
  String? _mergeDateAndTime({dynamic date, dynamic time}) {
    final d = _parseDate(date) ?? DateTime.now();
    final (hh, mm) = _parseHhMm(time);
    if (hh == null || mm == null) return null;
    final merged = DateTime(d.year, d.month, d.day, hh, mm);
    return merged.toIso8601String();
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  bool _validateWeightsE1() {
    final e1 = valueOfGlobal('rsi_e1');
    if (e1 is! Map) return true; // nothing to validate yet

    final tare = _toDouble(e1['tare']);
    final gvw  = _toDouble(e1['gvw']);

    // only enforce if both are present numbers
    if (tare == null || gvw == null) return true;

    return gvw >= tare;
  }

  void _applyApiPrefillFrom(GetRSIData d) {
    // helpers ───────────────────────────────────────────────────────────────
    Question? _q(String id) => _questionById(id);

    // Set a question's answer safely (and log)
    void _set(String qid, dynamic value) {
      final q = _q(qid);
      if (q == null) return;
      q.answer = value;
      debugPrint('↩️ prefill $qid = $value');
    }

    // Map label -> option id for a given question (case-insensitive)
    String? _idForLabel(String qid, String? label) {
      if (label == null || label.trim().isEmpty) return null;
      final opts = _optionsForQid(qid);
      final lower = label.trim().toLowerCase();
      for (final o in opts) {
        if (o.label.trim().toLowerCase() == lower) return o.id;
      }
      // try contains match as a fallback
      for (final o in opts) {
        if (lower.contains(o.label.trim().toLowerCase())) return o.id;
      }
      return null;
    }

    // Map many labels (CSV) -> option ids list
    List<String> _idsForCsvLabels(String qid, String? csv) {
      if (csv == null || csv.trim().isEmpty) return const [];
      final parts = csv.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final out = <String>[];
      for (final p in parts) {
        final id = _idForLabel(qid, p);
        if (id != null) out.add(id);
      }
      return out;
    }


    String? _idOrLabel(String qid, dynamic incoming) {
      if (incoming == null) return null;
      final val = incoming.toString().trim();
      if (val.isEmpty) return null;

      // handle other(text)
      if (RegExp(r'^\s*other\s*\(.*\)\s*$', caseSensitive: false).hasMatch(val)) {
        final opt = _otherOptionFor(qid);
        return opt?.id;
      }

      final opts = _optionsForQid(qid);

      // id match
      if (opts.any((o) => o.id == val)) return val;

      // label match (case-insensitive)
      final lower = val.toLowerCase();
      for (final o in opts) {
        if (o.label.trim().toLowerCase() == lower) return o.id;
      }
      for (final o in opts) {
        if (lower.contains(o.label.trim().toLowerCase())) return o.id;
      }
      return null;
    }

    // location answer format your renderer expects (lat/lon map)
    Map<String, dynamic>? _loc(double? lat, double? lon) {
      if (lat == null || lon == null) return null;
      return {'lat': lat, 'lon': lon};
    }

    // parse "123 AED" → {'amount': 123, 'currency': 'AED'}
    Map<String, dynamic>? _parseMoney(String? s) {
      if (s == null || s.trim().isEmpty) return null;
      final parts = s.trim().split(RegExp(r'\s+'));
      if (parts.isEmpty) return null;
      double? amount = double.tryParse(parts.first.replaceAll(',', ''));
      String? currency = parts.length > 1 ? parts.last.toUpperCase() : null;
      if (amount == null) return null;
      return {'special': false, 'amount': amount, 'currency': currency ?? 'AED'};
    }

    // simple yes/no loaded mapping
    String? _loaded() {
      // API stores loaded flow fields; your AddRsi stored 'S_IsLoaded'
      // If you persisted it, prefer that. Otherwise, infer:
      // - If there’s cargo/weights → assume 'loaded'
      final hasCargo = (d.sTypeCargo != null && d.sTypeCargo!.toString().trim().isNotEmpty) ||
          (d.sWeight != null && d.sWeight!.toString().trim().isNotEmpty);
      return hasCargo ? 'loaded' : 'unloaded';
    }

    // ── A: Vehicle & Parties ────────────────────────────────────────────────
    _set('demo_b0_name', d.sFullName ?? ''); // you also store S_FullName during submit; use it if backend returns it

    final chosen = _idOrLabel('rsi_a2', d.sVehicleType);
    debugPrint('🚚 mapped S_VehicleType="${d.sVehicleType}" -> optionId="$chosen"');
    _set('rsi_a2', chosen);

    final rawOrigin = d.sOrigin?.toString().trim();
    if (rawOrigin != null && rawOrigin.toLowerCase().startsWith('other(')) {
      _prefillOtherPattern('rsi_a3', rawOrigin);
    } else {
      // try to map label->id; fall back to raw text if you truly support free text here
      _set('rsi_a3', _idOrLabel('rsi_a3', rawOrigin) ?? rawOrigin);
    }

    _set('rsi_a4', (d.nNoOfPassenger ?? 0) > 2 ? '3+' : (d.nNoOfPassenger?.toString() ?? '1'));

    // Driver residencies (CSV labels) -> set A5_1 and A5_2
    final drvCsv = d.sDriverResidency?.toString();
    final drvLabels = (drvCsv == null || drvCsv.trim().isEmpty)
        ? <String>[]
        : drvCsv.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    if (drvLabels.isNotEmpty) {
      final l0 = drvLabels[0];
      if (l0.toLowerCase().startsWith('other(')) {
        _prefillOtherPattern('rsi_a5_1', l0);
      } else {
        _set('rsi_a5_1', _idForLabel('rsi_a5_1', l0));
      }
    }
    if (drvLabels.length >= 2) {
      final l1 = drvLabels[1];
      if (l1.toLowerCase().startsWith('other(')) {
        _prefillOtherPattern('rsi_a5_2', l1);
      } else {
        _set('rsi_a5_2', _idForLabel('rsi_a5_2', l1));
      }
    }

    // Hauler company (ID)
    if (d.nHauler != null) {
      _set('rsi_a6', d.nHauler!.toString());
    }

    _set('rsi_a7', d.sClientCompany); // text

    _set('rsi_a8', _loaded()); // 'loaded' | 'unloaded'

    // ── B: Shipment & Commodity (only if loaded) ────────────────────────────
    if (_loaded() == 'loaded') {
      // B1 single/multi (infer from N_TripCount if server has no explicit flag)
      final b1 = (d.nTripCount ?? 0) > 1 ? 'multi' : 'single';
      _set('rsi_b1', b1);

      if (b1 == 'multi') {
        _set('rsi_b2', d.nTripCount?.toString());
      }

      // B3 single/multiple (infer from CSV commodity)
      final cargoCsv = d.sTypeCargo?.toString();
      final multiple = (cargoCsv != null && cargoCsv.contains(','));
      _set('rsi_b3', multiple ? 'multiple' : 'single');


      // B4 multi-select from CSV labels
      final b4idsSingle = _idsForCsvLabels('rsi_b4_single', cargoCsv);
      final b4idsMultiple = _idsForCsvLabels('rsi_b4_multiple', cargoCsv);

      if (multiple) {
        if (b4idsMultiple.isNotEmpty) _set('rsi_b4_multiple', b4idsMultiple);
      } else {
        if (b4idsSingle.isNotEmpty) _set('rsi_b4_single', b4idsSingle);
      }
    }

    // ── C: O/D & Stops ──────────────────────────────────────────────────────
    // C1a or C1b: origin location (based on loaded/unloaded)
    if (_loaded() == 'loaded') {
      if (d.sLattitude != null && d.sLongitude != null) {
        unawaited(_setLocationWithName('rsi_c1a', d.sLattitude, d.sLongitude));
      }
    } else {
      if (d.sLattitude != null && d.sLongitude != null) {
        unawaited(_setLocationWithName('rsi_c1b', d.sLattitude, d.sLongitude));
      }
    }

// C2
    if (d.sDestinationLat != null && d.sDestinationLong != null) {
      unawaited(_setLocationWithName('rsi_c2', d.sDestinationLat, d.sDestinationLong));
    }

// C3
    if (d.sLatFinal != null && d.sLonFinal != null) {
      unawaited(_setLocationWithName('rsi_c3', d.sLatFinal, d.sLonFinal));
    }

// C4
    if (d.sLatConclusion != null && d.sLonConclusion != null) {
      unawaited(_setLocationWithName('rsi_c4', d.sLatConclusion, d.sLonConclusion));
    }

    // ── D: Timing ────────────────────────────────────────────────────────────
    final baseDateIso =
        (d.dtInterviewDate ?? d.dtCreatedDate)?.toIso8601String() ?? DateTime.now().toIso8601String();
    final baseDate = _fmtDate(baseDateIso); // -> "yyyy-MM-dd"

// Combine date + time-only strings into "yyyy-MM-dd HH:mm"
    String? _mergeToUi(dynamic timeOnly) => _combineDateTime(baseDate, _fmtTime(timeOnly));

// rsi_a1 (Time of survey) – if you want to show/prefill it as well:
    final surveyStart = _mergeToUi(d.dtInterviewStartTime);
    if (surveyStart != null) _set('rsi_a1', surveyStart);

// D1/D2/D3:
    final dep = _mergeToUi(d.dtDepartureTime);
    final arr = _mergeToUi(d.dtArrivalTime);
    final reach = _mergeToUi(d.dtReachTime);

    if (dep != null)   _set('rsi_d1', dep);
    if (arr != null)   _set('rsi_d2', arr);
    if (reach != null) _set('rsi_d3', reach);

    enforceTimingGuards();

    // ── E: Weights & Charges (only if loaded) ───────────────────────────────
    if (_loaded() == 'loaded') {
      // E1 composite (tare/gvw/unit)
      final tare = (d.sCargoWeight?.toString()); // you store 'S_CargoWeight'
      final gvw  = (d.sWeight?.toString());      // you store 'S_Weight'
      final unit = 't'; // if backend returns one
      if ((tare != null && tare.isNotEmpty) || (gvw != null && gvw.isNotEmpty)) {
        _set('rsi_e1', {
          'tare': tare ?? '',
          'gvw':  gvw  ?? '',
          'unit': unit,
        });
      }

      // E2 weigh method (id/label)
      if (d.sWeighMethod != null && d.sWeighMethod!.toString().trim().isNotEmpty) {
        // try match by id first
        final method = d.sWeighMethod!.toString();
        final idDirect = _optionsForQid('rsi_e2').any((o) => o.id == method) ? method : null;
        _set('rsi_e2', idDirect ?? _idForLabel('rsi_e2', method));
      }

      // E3 cargo value: parse "amount currency"
      final cargoMoney = _parseMoney(d.sCargoCost?.toString());
      if (cargoMoney != null) _set('rsi_e3', cargoMoney);

      // E4 trip charge: parse "amount currency"
      final tripMoney = _parseMoney(d.sCostTrip?.toString());
      if (tripMoney != null) _set('rsi_e4', tripMoney);
    }
  }

  // RSI flow is fixed; if someone tries to “switch type” within RSI,
  // we simply rebuild RSI again.
  @override
  Future<void> onTypeSelected(String typeId, BuildContext context) async {
    questionnaireType = QuestionnaireType.freightRsi;
    await onInit(context);
  }

  @override
  Future<void> saveDraft(BuildContext context) => onSaveDraft(context);

  // No hard screening gates for RSI right now; default true is fine.
  // @override
  // Future<bool> beforeAdvance(BuildContext context, QuestionnaireSection section) async => true;
  @override
  Future<bool> beforeAdvance(BuildContext context, QuestionnaireSection section) async {
    // Only enforce for loaded flows, and on the Weights & Charges section
    if (section.id == 'rsi_e' && valueOfGlobal('rsi_a8') == 'loaded') {
      if (!_validateWeightsE1()) {
        ToastHelper.showError('Gross vehicle weight cannot be less than tare weight.');
        return false; // block next
      }
    }
    return true; // allow
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Catalogs
  // ───────────────────────────────────────────────────────────────────────────

  void _seedLocalCatalogs() {
    setCatalog('registration_origins', const [
      AnswerOption(id: 'AUH', label: 'Abu Dhabi (UAE)'),
      AnswerOption(id: 'DXB', label: 'Dubai (UAE)'),
      AnswerOption(id: 'SHJ', label: 'Sharjah (UAE)'),
      AnswerOption(id: 'QAJ', label: 'Ajman (UAE)'),
      AnswerOption(id: 'QIW', label: 'Umm Al Quwain (UAE)'),
      AnswerOption(id: 'RKT', label: 'Ras Al Khaimah (UAE)'),
      AnswerOption(id: 'FJR', label: 'Fujairah (UAE)'),
      AnswerOption(id: 'KSA', label: 'Saudi Arabia'),
      AnswerOption(id: 'OMN', label: 'Oman'),
      AnswerOption(id: 'QAT', label: 'Qatar'),
      AnswerOption(id: 'BHR', label: 'Bahrain'),
      AnswerOption(id: 'KWT', label: 'Kuwait'),
      AnswerOption(id: 'OTHER', label: 'Other'),
    ], notify: false);

    setCatalog('countries_gcc_plus_other', const [
      AnswerOption(id: 'UAE', label: 'UAE'),
      AnswerOption(id: 'KSA', label: 'Saudi Arabia'),
      AnswerOption(id: 'OMN', label: 'Oman'),
      AnswerOption(id: 'QAT', label: 'Qatar'),
      AnswerOption(id: 'BHR', label: 'Bahrain'),
      AnswerOption(id: 'KWT', label: 'Kuwait'),
      AnswerOption(id: 'OTHER', label: 'Other', isOther: true),
    ], notify: false);

    setCatalog('hauler_companies', const [
      AnswerOption(id: '1', label: 'Allied Transport (ATC)'),
      AnswerOption(id: '2', label: 'Aramex'),
      AnswerOption(id: '3', label: 'DP World Logistics'),
      AnswerOption(id: '4', label: 'Emirates Transport'),
      AnswerOption(id: '5', label: 'TruKKer'),
      AnswerOption(id: '6', label: 'Owner-operator / Individual'),
      AnswerOption(id: '99', label: 'Other', isOther: true),
    ], notify: false);
  }

  Future<void> _loadMasters(BuildContext context) async {
    try {
      await _apiDropdown(context, 20); // 'freight_commodities'
      await _apiDropdown(context, 22); // 'hauler_companies'
    } catch (e, st) {
      debugPrint('RSI masters load failed: $e\n$st');
    }
  }

  Future<void> _apiDropdown(BuildContext context, int masterCode) async {
    final result = await CommonRepository.instance
        .apiDropdown(DropdownRequest(nMasterCode: masterCode));
    _handleDropdownResponse(result as DropdownResponse, masterCode: masterCode);
  }

  void _handleDropdownResponse(DropdownResponse resp, {required int masterCode}) {
    if (resp.status != true || resp.result == null) return;

    final List<AnswerOption> opts = resp.result!
        .map((e) {
      final id = (e.nDetailedCode ?? '').toString();
      final label = (e.detailedNameA ?? '').trim().isNotEmpty
          ? e.detailedNameA!.trim()
          : (e.detailedNameE ?? '').trim();
      final isOther = label.toLowerCase().startsWith('other');
      return AnswerOption(id: id, label: label, isOther: isOther);
    })
        .where((o) => o.id.isNotEmpty && o.label.trim().isNotEmpty)
        .toList();

    if (opts.isEmpty) return;

    switch (masterCode) {
      case 20: // commodities
        setCatalog('freight_commodities', opts);
        break;

      case 22: // haulers
        setCatalog('hauler_companies', opts);
        break;
      default:
        debugPrint('Unhandled masterCode=$masterCode');
    }
  }

  String? _sectionIdOf(String qid) {
    for (final s in sections ?? const []) {
      if (s.questions.any((q) => q.id == qid)) return s.id;
    }
    return null;
  }

  AnswerOption? _otherOptionFor(String qid) {
    final opts = _optionsForQid(qid);
    for (final o in opts) {
      final lab = o.label.trim().toLowerCase();
      if (o.isOther == true || lab == 'other' || lab.startsWith('other ')) return o;
    }
    // also consider legacy ids
    for (final o in opts) {
      final up = o.id.trim().toUpperCase();
      if (up == 'OTHER' || up == '99') return o;
    }
    return null;
  }

  void _prefillOtherPattern(String qid, String raw) {
    // matches: other(any text here)
    final m = RegExp(r'^\s*other\s*\((.*)\)\s*$', caseSensitive: false).firstMatch(raw);
    if (m == null) return;

    final otherText = m.group(1)?.trim();
    final q = _questionById(qid);
    if (q == null) return;

    final otherOpt = _otherOptionFor(qid);
    if (otherOpt == null) return;

    // Select the "Other" option
    q.answer = otherOpt.id;

    // Inject companion text into the answers store so the renderer can read it
    final sid = _sectionIdOf(qid);
    if (sid != null && (otherText?.isNotEmpty ?? false)) {
      updateAnswer(sid, '${qid}__other', otherText);
    }
  }

  DateTime? _parseAnyDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString().trim();
    if (s.isEmpty) return null;

    // ISO first
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;

    // "yyyy-MM-dd HHmm"
    final re = RegExp(r'^(\d{4}-\d{2}-\d{2})\s+(\d{2})(\d{2})$');
    final m = re.firstMatch(s);
    if (m != null) {
      final date = DateTime.tryParse('${m.group(1)}T00:00:00');
      final hh = int.tryParse(m.group(2)!);
      final mm = int.tryParse(m.group(3)!);
      if (date != null && hh != null && mm != null) {
        return DateTime(date.year, date.month, date.day, hh, mm);
      }
    }

    // "yyyy-MM-dd HH:mm"
    final withColon = DateTime.tryParse(s.replaceFirst(' ', 'T'));
    return withColon;
  }

  DateTime? _dtOf(String qid) => _parseAnyDateTime(valueOfGlobal(qid));


  void _injectMin(String qid, DateTime min) {
    final q = _questionById(qid);
    if (q == null) return;

    final iso = min.toIso8601String();

    // If captureConfig already exists → mutate it
    if (q.captureConfig != null) {
      q.captureConfig!['minDateTimeIso'] = iso;
    } else {
      // Otherwise, create one dynamically (using the copyWith pattern)
      final newCfg = <String, dynamic>{'minDateTimeIso': iso};
      // use copyWith or reflection-style constructor if you have one
      // For plain data class (no setter), rebuild a new Question object
      final updated = Question(
        id: q.id,
        question: q.question,
        type: q.type,
        options: q.options,
        catalog: q.catalog,
        hint: q.hint,
        placeholder: q.placeholder,
        tooltip: q.tooltip,
        defaultValue: q.defaultValue,
        shuffleOptions: q.shuffleOptions,
        readOnly: q.readOnly,
        visibleIf: q.visibleIf,
        requiredIf: q.requiredIf,
        validation: q.validation,
        matrixRows: q.matrixRows,
        matrixColumns: q.matrixColumns,
        captureConfig: newCfg,
        allowOtherOption: q.allowOtherOption,
        allowSpecialAnswers: q.allowSpecialAnswers,
        answer: q.answer,
      );

      // Replace in your section list so UI updates see the new instance
      for (final s in sections ?? const []) {
        final i = s.questions.indexWhere((qq) => qq.id == qid);
        if (i != -1) {
          s.questions[i] = updated;
          break;
        }
      }
    }
  }

  void _clearIfEarlier(String qid, DateTime min) {
    final cur = _dtOf(qid);
    if (cur != null && cur.isBefore(min)) {
      final q = _questionById(qid);
      if (q != null) q.answer = null;
    }
  }

  /// Public: recompute & enforce D1/D2/D3 ordering.
  /// D2 >= D1;  D3 >= (D2 ?? D1)
  void enforceTimingGuards() {
    final d1 = _dtOf('rsi_d1');
    final d2 = _dtOf('rsi_d2');
    final d3 = _dtOf('rsi_d3');

    if (d1 != null) {
      _injectMin('rsi_d2', d1);
      _clearIfEarlier('rsi_d2', d1);
    }

    final minForD3 = d2 ?? d1;
    if (minForD3 != null) {
      _injectMin('rsi_d3', minForD3);
      _clearIfEarlier('rsi_d3', minForD3);
    }

    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Submit
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Future<void> onSubmit(BuildContext context, Map<String, dynamic> allAnswers) async {
    try {
      if (valueOfGlobal('rsi_a8') == 'loaded' && !_validateWeightsE1()) {
        ToastHelper.showError('Gross vehicle weight cannot be less than tare weight.');
        return;
      }
      runWithLoadingVoid(() async {
        final request = await _buildAddRsiRequest(nStatus: 1);
        final result = await CommonRepository.instance.apiAddRSIQuestionnaire(request);
        if (result is AddRsiResponse && (result.status ?? false)) {
          ToastHelper.showSuccess("Data updated successfully");

          _clearAllState();

          // After success, reset and go home
          resetQuestionnaire(unlockType: true, resetTimer: true, freshSections: [
            rsiSectionA,
            rsiSectionB,
            rsiSectionC,
            rsiSectionD,
            rsiSectionE,
          ]);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
            }
          });
          return;
        }

        // If we get here, treat as failure
        ToastHelper.showError('Unable to submit. Please try again.', error: 'Unable to submit. Please try again.', stack: StackTrace.current);
      },);
    } catch (e, st) {
      debugPrint('RSI submit error: $e\n$st');
      ToastHelper.showError('An error occurred. Please try again.', error: e, stack: st);
      notifyListeners();
    }
  }

  /// Maps Google 'administrative_area_level_1' name -> your 3-letter code
  static const _emirateNameToCode = {
    'Abu Dhabi': 'AUH',
    'Dubai': 'DXB',
    'Sharjah': 'SHJ',
    'Ajman': 'AJM',
    'Umm Al Quwain': 'UAQ',
    'Ras al Khaimah': 'RKT',
    'Ras Al-Khaimah': 'RKT',    // sometimes returned like this
    'Fujairah': 'FJR',
  };

  String? _emirateFromLatLon(double lat, double lon) {
    // Dubai
    if (lat >= 24.90 && lat <= 25.45 && lon >= 55.00 && lon <= 55.70) return 'Dubai';

    // Abu Dhabi (very large; coarse box)
    if (lat >= 22.40 && lat <= 25.60 && lon >= 51.50 && lon <= 55.35) return 'Abu Dhabi';

    // Sharjah (mainland chunk)
    if (lat >= 25.15 && lat <= 25.75 && lon >= 55.35 && lon <= 56.10) return 'Sharjah';

    // Ajman (tiny)
    if (lat >= 25.35 && lat <= 25.48 && lon >= 55.43 && lon <= 55.62) return 'Ajman';

    // UAQ
    if (lat >= 25.50 && lat <= 25.75 && lon >= 55.50 && lon <= 55.90) return 'Umm Al Quwain';

    // Ras Al Khaimah
    if (lat >= 25.60 && lat <= 26.40 && lon >= 55.70 && lon <= 56.60) return 'Ras Al Khaimah';

    // Fujairah (east coast)
    if (lat >= 24.95 && lat <= 25.70 && lon >= 56.00 && lon <= 56.60) return 'Fujairah';

    return null; // unknown / outside
  }

  Future<String?> emirateFromGoogle({
    required double lat,
    required double lon,
    required String apiKey,
  }) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    final url = 'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lon&key=$apiKey&language=en';

    try {
      final resp = await dio.get(url);

      if (resp.statusCode != 200 || resp.data == null) return null;

      final data = resp.data is Map<String, dynamic>
          ? resp.data as Map<String, dynamic>
          : jsonDecode(resp.data.toString());

      if (data['status'] != 'OK' || data['results'] is! List) return null;

      for (final result in (data['results'] as List)) {
        final comps = result['address_components'] as List<dynamic>? ?? const [];
        for (final c in comps) {
          final types = (c['types'] as List<dynamic>? ?? const []).cast<String>();
          if (types.contains('administrative_area_level_1')) {
            final name = (c['long_name'] as String?)?.trim();
            if (name != null && name.isNotEmpty) {
              final code = _emirateNameToCode[name];
              if (code != null) return code; // e.g. "DXB"
            }
          }
        }
      }
    } on DioException catch (e) {
      debugPrint('Google Geocode API error: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error getting emirate: $e');
    }
    return null;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Payload builder (unchanged semantics)
  // ───────────────────────────────────────────────────────────────────────────
  Future<String?> _reverseGeocodeName({
    required double lat,
    required double lon,
  }) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final resp = await dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '$lat,$lon',
          'key': ApiConstants.apiKey,
          'language': 'en',
        },
      );

      if (resp.statusCode != 200) return null;
      final data = resp.data as Map<String, dynamic>?;
      if (data == null || data['status'] != 'OK') return null;

      final results = (data['results'] as List).cast<Map<String, dynamic>>();
      if (results.isEmpty) return null;

      // Prefer a short-ish locality+country string; otherwise fall back to formatted_address
      String? locality, admin1, country;
      for (final r in results) {
        final comps = (r['address_components'] as List).cast<Map<String, dynamic>>();
        for (final c in comps) {
          final types = (c['types'] as List).cast<String>();
          if (types.contains('locality')) locality = c['long_name'];
          if (types.contains('administrative_area_level_1')) admin1 = c['long_name'];
          if (types.contains('country')) country = c['short_name']; // e.g., "AE"
        }
        if (locality != null || admin1 != null || country != null) break;
      }

      if (locality != null && country != null) return '$locality, $country';
      if (admin1 != null && country != null) return '$admin1, $country';

      // fallback
      return results.first['formatted_address'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _setLocationWithName(String qid, double? lat, double? lon) async {
    if (lat == null || lon == null) return;

    // set immediately with lat/lon so the UI has something right away
    final q = _questionById(qid);
    if (q == null) return;
    q.answer = {'lat': lat, 'lon': lon};
    notifyListeners();

    // enrich with a readable name
    final name = await _reverseGeocodeName(lat: lat, lon: lon);
    if (name != null) {
      q.answer = {'lat': lat, 'lon': lon, 'name': name};
      notifyListeners();
    }
  }


  Future<AddRsiRequest> _buildAddRsiRequest({int nStatus = 1}) async {
    // ---------- helpers ----------
    String? _asString(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    int? _asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      final s = v.toString().trim();
      if (RegExp(r'^\d+$').hasMatch(s)) return int.tryParse(s);
      if (s.endsWith('+')) return int.tryParse(s.replaceAll('+', ''));
      return int.tryParse(s);
    }

    (String?, String?) _coords(dynamic ans) {
      if (ans is Map) {
        final lat = _asString(ans['lat'] ?? ans['latitude']);
        final lon = _asString(ans['lon'] ?? ans['lng'] ?? ans['longitude']);
        return (lat, lon);
      }
      if (ans is String && ans.contains(',')) {
        final parts = ans.split(',');
        if (parts.length >= 2) return (_asString(parts[0]), _asString(parts[1]));
      }
      return (null, null);
    }

    String? _moneyToString(dynamic ans) {
      if (ans is Map) {
        final amount = ans['amount'];
        final curr = _asString(ans['currency']);
        if (amount != null && curr != null) return '${amount.toString()} $curr';
      }
      return null;
    }

    dynamic _get(String qid) => valueOfGlobal(qid);

    dynamic _getRepeatLast(String baseId, {int max = 200}) {
      int maxIdx = 0;
      for (var i = 1; i <= max; i++) {
        final v = _get('${baseId}__$i');
        if (v == null) break;
        maxIdx = i;
      }
      return maxIdx > 0 ? _get('${baseId}__$maxIdx') : _get(baseId);
    }

    // Build display label for one selection (injects other(<text>) if needed).
    String _displayForSelection(String qid, String id) {
      final opt = _optionForSelection(qid, id);
      if (_looksLikeOther(opt, id)) {
        final otherText = _otherCompanionFor(qid);
        return otherText == null ? 'Other' : 'other($otherText)';
      }
      return (opt?.label
          .trim()
          .isNotEmpty ?? false) ? opt!.label.trim() : id;
    }

    // ---------- build payload ----------
    final payload = <String, dynamic>{};

    // Fixed / meta
    payload['N_ProjectID'] = 6; // always 1

    final a8 = _asString(_get('rsi_a8')); // 'loaded' | 'unloaded'
    if (a8 != null) payload['S_IsLoaded'] = a8;
    final bool isLoaded = (a8 == 'loaded');

    final a2 = _asString(_get('rsi_a2')); // selected id
    if (a2 != null) {
      final label = _displayForSelection('rsi_a2', a2); // id -> label
      payload['S_VehicleType'] = label;                 // <-- LABEL string
    }

    final a3 = _asString(_get('rsi_a3')); // registration origin
    if (a3 != null) payload['S_Origin'] = a3;

    final a4 = _get('rsi_a4'); // drivers count (actually passenger count variable name kept)
    final a4i = _asInt(a4);
    if (a4i != null) payload['N_NoOfPassenger'] = a4i;

    // driver residencies (A5_1..2) → CSV string (labels)
    final drvLabels = <String>[];
    for (final qid in const ['rsi_a5_1', 'rsi_a5_2']) {
      final raw = _asString(_get(qid));
      if (raw != null && raw.isNotEmpty) {
        drvLabels.add(_displayForSelection(qid, raw));
      }
    }
    if (drvLabels.isNotEmpty) {
      payload['S_DriverResidency'] = drvLabels.join(',');
    }

    // Hauler → ID
    final a6 = _asString(_get('rsi_a6'));
    if (a6 != null) payload['N_Hauler'] = _asInt(a6);

    final a7 = _asString(_get('rsi_a7')); // client company
    if (a7 != null) payload['S_ClientCompany'] = a7;

    // B) Shipment / Commodity
    final b1 = _asString(_get('rsi_b1')); // 'single' | 'multi'
    if (b1 != null) payload['S_IsMultipleTrip'] = (b1 == 'multi') ? 'multi' : 'single';

    final b2 = _asInt(_get('rsi_b2'));
    if (b2 != null) payload['N_TripCount'] = b2;

    final b3 = _asString(_get('rsi_b3')); // 'single' | 'multiple'
    if (b3 != null) payload['S_IsMultipleCargo'] = (b3 == 'multiple') ? 'multiple' : 'single';

    // B4 — Commodity(ies) → CSV labels
    final dynamic b4Ans = (b3 == 'multiple') ? _get('rsi_b4_multiple') : _get('rsi_b4_single');
    if (b4Ans is List) {
      final ids = b4Ans
          .map((e) => _asString(e))
          .where((e) => e != null && e!.isNotEmpty)
          .cast<String>()
          .toList();

      if (ids.isNotEmpty) {
        final labels = ids.map((id) {
          final qid = (b3 == 'multiple') ? 'rsi_b4_multiple' : 'rsi_b4_single';
          return _displayForSelection(qid, id);
        }).toList();
        payload['S_TypeCargo'] = labels.join(',');
      }
    } else if (b4Ans != null) {
      final id = _asString(b4Ans);
      if (id != null && id.isNotEmpty) {
        final qid = (b3 == 'multiple') ? 'rsi_b4_multiple' : 'rsi_b4_single';
        payload['S_TypeCargo'] = _displayForSelection(qid, id);
      }
    }

    // C) O/D & stops
    final (oLat, oLon) = _coords(_get(isLoaded ? 'rsi_c1a' : 'rsi_c1b'));
    if (oLat != null) payload['S_Lattitude'] = oLat;
    if (oLon != null) payload['S_Longitude'] = oLon;

    final (dLat, dLon) = _coords(_get('rsi_c2')); // current leg dest
    if (dLat != null) payload['S_Destination_Lat'] = dLat;
    if (dLon != null) payload['S_Destination_Long'] = dLon;

    // final drop (repeat last)
    final (fLat, fLon) = _coords(_getRepeatLast('rsi_c3'));
    if (fLat != null) payload['S_LatFinal'] = fLat;
    if (fLon != null) payload['S_LonFinal'] = fLon;

    // destination after fully unloading
    final (cLat, cLon) = _coords(_get('rsi_c4'));
    if (cLat != null) payload['S_LatConclusion'] = cLat;
    if (cLon != null) payload['S_LonConclusion'] = cLon;

    // D) Timing
    final d1 = _asString(_get('rsi_d1'));
    if (d1 != null) payload['Dt_DepartureTime'] = d1;

    final d2 = _asString(_getRepeatLast('rsi_d2'));
    if (d2 != null) payload['Dt_ArrivalTime'] = d2;

    final d3 = _asString(_get('rsi_d3'));
    if (d3 != null) payload['Dt_ReachTime'] = d3;

    // E) Weights & charges
    final e1 = _get('rsi_e1'); // composite {tare, gvw, unit}
    if (e1 is Map) {
      final tare = _asString(e1['tare']);
      final gvw  = _asString(e1['gvw']);
      final unit = _asString(e1['unit']); // 't' or 'm3'
      if (tare != null) payload['S_CargoWeight'] = tare;
      if (gvw  != null) payload['S_Weight']      = gvw;
      if (unit != null) payload['S_WeightUnit']  = unit; // ← add this column if backend has it
    }

    final e2 = _asString(_get('rsi_e2')); // weigh method (id or label)
    if (e2 != null) payload['S_WeighMethod'] = e2;

    // Money as STRING "amount currency"
    final cargoCostStr = _moneyToString(_get('rsi_e3')); // "99 AED"
    if (cargoCostStr != null) payload['S_CargoCost'] = cargoCostStr;

    final tripCostStr = _moneyToString(_get('rsi_e4')); // "99 AED"
    if (tripCostStr != null) payload['S_CostTrip'] = tripCostStr;

    // Device location (Actual)
    final loc = await LocationHelper.getCurrentLocation();
    if (loc?.latitude != null) payload['S_Lattitude_Actual'] = loc!.latitude!.toString();
    if (loc?.longitude != null) payload['S_Longitude_Actual'] = loc!.longitude!.toString();

    // 👇 Derive emirate code from current location (Actual)
    if (loc?.latitude != null && loc?.longitude != null) {
      payload['S_Lattitude_Actual'] = loc!.latitude!.toString();
      payload['S_Longitude_Actual'] = loc.longitude!.toString();

      // Prefer Google reverse geocoding
      String? emirateCode;
      try {
        emirateCode = await emirateFromGoogle(
          lat: loc.latitude!,
          lon: loc.longitude!,
          apiKey: ApiConstants.apiKey,
        );
      } catch (_) {
        // swallow; we’ll fallback below
      }

      // Optional: fallback to your box helper if Google fails
      emirateCode ??= _emirateFromLatLon(loc.latitude!, loc.longitude!);

      if (emirateCode != null) {
        payload['S_Emirates'] = emirateCode;
      }
    }

    final now = DateTime.now();
    final int sessionSeconds = startedAt == null ? 0 : now.difference(startedAt!).inSeconds;
    final int combinedSeconds = _editBaselineSeconds + sessionSeconds;

// Meta
    payload['Dt_InterviewDate'] = now.toIso8601String();
    payload['Dt_Interview_StartTime'] = startedAt?.toIso8601String();
    payload['Dt_Interview_EndTime'] = now.toIso8601String();

// KEEP time continuous during edit
    payload['S_TotalTime'] = _formatMmSs(combinedSeconds);

    payload['N_Status'] = nStatus;
    payload['N_CreatedBy'] = userData?.userId ?? 0;
    final fullName = _asString(_get('demo_b0_name'));
    if (fullName != null) {
      payload['S_FullName'] = fullName;
    }

    final bool isEdit = editRsiId != null;
    payload['Action'] = isEdit ? 'update' : 'add';
    if (isEdit) {
      payload['N_RSIID'] = editRsiId;   // pass the id on update
    }

    return AddRsiRequest.fromJson(payload);
  }

  int _parseClockToSeconds(String? s) {
    if (s == null || s.trim().isEmpty) return 0;
    final parts = s.split(':').map((e) => e.trim()).toList(); // mm:ss or hh:mm(:ss)
    if (parts.any((p) => p.isEmpty)) return 0;

    int h = 0, m = 0, sec = 0;
    if (parts.length == 2) {
      // mm:ss
      m = int.tryParse(parts[0]) ?? 0;
      sec = int.tryParse(parts[1]) ?? 0;
    } else if (parts.length >= 3) {
      // hh:mm:ss
      h = int.tryParse(parts[0]) ?? 0;
      m = int.tryParse(parts[1]) ?? 0;
      sec = int.tryParse(parts[2]) ?? 0;
    } else {
      // "12" → minutes
      m = int.tryParse(parts[0]) ?? 0;
    }
    return h * 3600 + m * 60 + sec;
  }

  String? _formatMmSs(int? seconds) {
    if (seconds == null || seconds < 0) return null;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool _weightGuardBusy = false;

  void enforceWeightGuardLive() {
    if (_weightGuardBusy) return; // avoid re-entrancy
    _weightGuardBusy = true;
    try {
      final v = valueOfGlobal('rsi_e1');
      if (v is Map) {
        double? _toDouble(x) {
          if (x == null) return null;
          if (x is num) return x.toDouble();
          return double.tryParse(x.toString());
        }

        final tare = _toDouble(v['tare']);
        final gvw  = _toDouble(v['gvw']);

        if (tare != null && gvw != null && gvw < tare) {
          ToastHelper.showError('Gross vehicle weight must be greater than or equal to tare weight.');
          // Option A: clear GVW so user must re-enter
          final q = _questionById('rsi_e1');
          if (q != null && q.answer is Map) {
            final m = Map<String, dynamic>.from(q.answer as Map);
            m['gvw'] = null;
            q.answer = m;
            notifyListeners();
          }
          // Option B (alternative): clamp to tare
          // m['gvw'] = tare;
        }
      }
    } finally {
      _weightGuardBusy = false;
    }
  }

  Future<void> onSaveDraft(BuildContext context) async {
    try {
      if (valueOfGlobal('rsi_a8') == 'loaded' && !_validateWeightsE1()) {
        ToastHelper.showError('Gross vehicle weight cannot be less than tare weight.');
        return;
      }
      runWithLoadingVoid(() async {
        final request = await _buildAddRsiRequest(nStatus: 0);   // ✅ draft
        final result = await CommonRepository.instance.apiAddRSIQuestionnaire(request);
        if (result is AddRsiResponse && (result.status ?? false)) {
          ToastHelper.showSuccess("Draft saved");

          _clearAllState();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
            }
          });
        } else {
          ToastHelper.showError('Unable to save draft. Please try again.', error: 'Unable to save draft. Please try again.', stack: StackTrace.current);
        }
      });
    } catch (e, st) {
      debugPrint('RSI save draft error: $e\n$st');
      ToastHelper.showError('An error occurred while saving the draft.', error: e, stack: st);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Helpers for label resolution / “Other” text (used by payload)
  // ───────────────────────────────────────────────────────────────────────────

  Question? _questionById(String qid) {
    for (final s in sections ?? const []) {
      for (final q in s.questions) {
        if (q.id == qid) return q;
      }
    }
    return null;
  }

  List<AnswerOption> _optionsForQid(String qid) {
    final q = _questionById(qid);
    if (q == null) return const [];

    // 1) direct options
    if (q.options != null && q.options!.isNotEmpty) return q.options!;

    // 2) catalog-backed
    if (q.catalog != null) return catalogs[q.catalog!.key] ?? const [];

    // 3) captureConfig.items (e.g., rsi_a2 vehicle types)
    final items = q.captureConfig?['items'];
    if (items is List) {
      final opts = <AnswerOption>[];
      for (final it in items) {
        if (it is Map) {
          final id = it['id']?.toString();
          final label = it['label']?.toString() ?? it['name']?.toString() ?? it['title']?.toString();
          if (id != null && (label?.trim().isNotEmpty ?? false)) {
            opts.add(AnswerOption(id: id, label: label!.trim()));
          }
        }
      }
      return opts;
    }

    return const [];
  }

  AnswerOption? _optionForSelection(String qid, String id) {
    final opts = _optionsForQid(qid);
    for (final o in opts) {
      if (o.id == id) return o;
    }
    return null;
  }

  bool _looksLikeOther(AnswerOption? opt, String id) {
    // 1) If label looks like "Other", treat as other
    if (_labelLooksLikeOther(opt?.label)) return true;

    // 2) Keep your legacy id checks (if backend uses codes like "OTHER" or 99)
    final up = id.trim().toUpperCase();
    if (up == 'OTHER' || up == '99') return true;

    return false;
  }

  bool _labelLooksLikeOther(String? s) {
    if (s == null) return false;
    final t = s.trim().toLowerCase();
    // catches: "other", "other (specify)", "other- please specify", etc.
    return t == 'other' ||
        t.startsWith('other ') ||
        t.startsWith('other(') ||
        t.startsWith('other-') ||
        t.contains('other (specify)');
  }


  String? _otherCompanionFor(String qid) {
    final key = '${qid}__other';
    final v = valueOfGlobal(key);
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  @override
  void dispose() {
    try { _clearAllState(); } catch (_) {}
    super.dispose();
  }
}




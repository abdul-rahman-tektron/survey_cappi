// passenger_questionnaire_notifier.dart
//
// Concrete notifier for passenger flows. Matches BaseQuestionnaireNotifier’s
// constructor + abstract method signatures (Future<void>), and avoids calling
// helpers that may not exist in the base (startTimer, valueOf, elapsed).

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:srpf/core/model/common/dropdown/dropdown_request.dart';
import 'package:srpf/core/model/common/dropdown/dropdown_response.dart';
import 'package:srpf/core/model/common/dropdown/nationality_dropdown_response.dart';
import 'package:srpf/core/model/questionnaire/passenger_questionnaire/get_passenger_data_request.dart';
import 'package:srpf/core/model/questionnaire/passenger_questionnaire/get_passenger_data_response.dart';
import 'package:srpf/core/model/questionnaire/passenger_questionnaire/passenger_questionnaire_request.dart';
import 'package:srpf/core/model/questionnaire/rsi_questionnaire/rsi_questionnaire_response.dart';
import 'package:srpf/core/model/questionnaire/sp_questionnaire/get_sp_data_request.dart';
import 'package:srpf/core/model/questionnaire/sp_questionnaire/get_sp_data_response.dart';

import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/core/questions/model/sp_model.dart';
import 'package:srpf/core/remote/services/common_repository.dart';
import 'package:srpf/res/api_constants.dart';
import 'package:srpf/res/images.dart';
import 'package:srpf/screens/questionnaire/flows/common/base_questionnaire_notifier.dart';
import 'package:srpf/utils/enums.dart';
import 'package:srpf/utils/helpers/selection_mapper.dart';
import 'package:srpf/utils/helpers/toast_helper.dart';
import 'package:srpf/utils/location_helper.dart';
import 'package:srpf/utils/router/routes.dart';

import 'package:srpf/core/questions/screening_question.dart';
import 'package:srpf/core/questions/demographic_question.dart';
import 'package:srpf/core/questions/car_petrol_question.dart';
import 'package:srpf/core/questions/car_border_question.dart';
import 'package:srpf/core/questions/bus_question.dart';
import 'package:srpf/core/questions/airport_question.dart';
import 'package:srpf/core/questions/hotel_questions.dart';
import 'package:srpf/core/questions/stated_preference_question.dart';

class PassengerQuestionnaireNotifier extends BaseQuestionnaireNotifier {
  final int? editPassengerId;

  PassengerQuestionnaireNotifier(
      BuildContext context, {
        required QuestionnaireType? questionnaireType,
        this.editPassengerId, // ⬅️ NEW
      }) : super(context, questionnaireType: questionnaireType);

  // ───────────────────────────────────────────────────────────────────────────
  // Abstract hooks (match BaseQuestionnaireNotifier signatures)
  // ───────────────────────────────────────────────────────────────────────────

  List<GetSPDataResult> _spData = [];
  bool _spLoading = false;
  String? _spError;
  int _editBaselineSeconds = 0;

  List<GetSPDataResult> get spData => _spData;

  bool get spLoading => _spLoading;

  String? get spError => _spError;

  @override
  Future<void> onInit(BuildContext context) async {
    _seedLocalCatalogsPassenger();
    _loadSections(context);
    await loadUserData();
    unawaited(_loadPassengerMasters(context));

    if (editPassengerId != null) {
      unawaited(_prefillPassengerFromServer(editPassengerId!)); // ⬅️ NEW
    }
  }

  @override
  Future<void> onTypeSelected(String typeId, BuildContext context) async {
    // keep the raw id for logic/visibility
    updateAnswer('__global', 'scr_type_select', typeId);

    // also store a friendly label for display
    updateAnswer('__global', 'scr_type_label', _labelForTypeId(typeId));

    questionnaireType = _mapTypeId(typeId);
    _loadSections(context);
  }

  @override
  Future<void> onSubmit(BuildContext context, Map<String, dynamic> finalAnswers) async {
    runWithLoadingVoid(() async {
      await _submitPassenger(context, finalAnswers);
    });
  }

  String _labelForTypeId(String id) {
    switch (id) {
      case 'passengerPetrol':
        return 'Passenger – Petrol';
      case 'passengerBorder':
        return 'Passenger – Border';
      case 'bus':
        return 'Bus';
      case 'airport':
        return 'Airport';
      case 'hotel':
        return 'Hotel';
      case 'statedPreference':
        return 'Stated Preference';
      default:
        return id;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Per-flow section definitions
  // ───────────────────────────────────────────────────────────────────────────

  final List<QuestionnaireSection> _petrolSections = [demographicsSection, petrolSectionC];

  final List<QuestionnaireSection> _carBorderSections = [
    demographicsSection,
    borderCrossingSection,
  ];

  final List<QuestionnaireSection> _busSections = [
    demographicsSection, // <- Demographics FIRST
    busStopsSection, // <- Then the Bus section
  ];

  final List<QuestionnaireSection> _airportSections = [demographicsSection, airportSection];

  final List<QuestionnaireSection> _hotelSections = [demographicsSection, hotelSectionG];

  final List<QuestionnaireSection> _statedPrefSections = [statedPreferenceSection];

  // ───────────────────────────────────────────────────────────────────────────
  // Flow building & navigation
  // ───────────────────────────────────────────────────────────────────────────

  void _loadSections(BuildContext context) {
    final t = questionnaireType;

    if (t == null) {
      sections = [screeningSelectTypeSection()];
      currentStep = 0;
      furthestStep = 0;
      applyAutoCapture();
      notifyListeners();
      return;
    }

    final screening = screeningSectionFor(t, isEdit: editPassengerId != null);
    switch (t) {
      case QuestionnaireType.passengerPetrol:
        sections = [screening, ..._petrolSections];
        break;
      case QuestionnaireType.passengerBorder:
        sections = [screening, ..._carBorderSections];
        break;
      case QuestionnaireType.bus:
        sections = [screening, ..._busSections];
        break;
      case QuestionnaireType.airport:
        sections = [screening, ..._airportSections];
        break;
      case QuestionnaireType.hotel:
        sections = [screening, ..._hotelSections];
        break;
      case QuestionnaireType.statedPreference:
        sections = [screening, ..._statedPrefSections];
        break;

    // Not handled in passenger notifier; fall back to selector
      case QuestionnaireType.freightRsi:
        sections = [screeningSelectTypeSection()];
        questionnaireType = null;
        break;
    }

    currentStep = 0;
    furthestStep = 0;
    applyAutoCapture();
    notifyListeners();
  }

  void _seedLocalCatalogsPassenger() {
    // Optional local fallbacks (only if you want something before API loads)
    setCatalog('sp_od_pairs', const [
      AnswerOption(id: 'AUH-DXB', label: 'Abu Dhabi → Dubai'),
      AnswerOption(id: 'DXB-SHJ', label: 'Dubai → Sharjah'),
    ], notify: false);

    setCatalog('trip_purposes', const [
      AnswerOption(id: '1', label: 'Commute'),
      AnswerOption(id: '2', label: 'Business Trip'),
      AnswerOption(id: '5', label: 'Shopping/Leisure'),
      AnswerOption(id: '99', label: 'Other', isOther: true),
    ], notify: false);

    setCatalog('modes', const [
      AnswerOption(id: '1', label: 'Car (Driver)'),
      AnswerOption(id: '2', label: 'Car (Passenger)'),
      AnswerOption(id: '3', label: 'Taxi'),
      AnswerOption(id: '4', label: 'Bus'),
      AnswerOption(id: '5', label: 'Metro'),
      AnswerOption(id: '99', label: 'Other', isOther: true),
    ], notify: false);

    setCatalog('nationalities', const [
      AnswerOption(id: 'United Arab Emirates', label: 'United Arab Emirates'),
      AnswerOption(id: 'India', label: 'India'),
      AnswerOption(id: 'Pakistan', label: 'Pakistan'),
      AnswerOption(id: 'Philippines', label: 'Philippines'),
      AnswerOption(id: 'Other', label: 'Other', isOther: true),
    ], notify: false);
  }

  Future<void> _loadPassengerMasters(BuildContext context) async {
    try {
      // 23: OD for SP, 2: purpose, 1: modes
      await _apiDropdownPassenger(context, 23);
      await _apiDropdownPassenger(context, 2);
      await _apiDropdownPassenger(context, 1);
      await _apiNationality(context);
    } catch (e, st) {
      debugPrint('Passenger masters load failed: $e\n$st');
    }
  }

  Future<void> _apiDropdownPassenger(BuildContext context, int masterCode) async {
    final result = await CommonRepository.instance.apiDropdown(
      DropdownRequest(nMasterCode: masterCode),
    );
    if (result is! DropdownResponse) return;
    _handleDropdownPassenger(result, masterCode: masterCode);
  }

  void _handleDropdownPassenger(DropdownResponse resp, {required int masterCode}) {
    if (resp.status != true || resp.result == null) return;

    // Map API rows -> AnswerOption
    final List<AnswerOption> opts = resp.result!
        .map(
          (e) => AnswerOption(
        id: (e.nDetailedCode ?? '').toString(),
        // prefer Arabic name if non-empty, else English
        label: (e.detailedNameA ?? '').trim().isNotEmpty
            ? e.detailedNameA!.trim()
            : (e.detailedNameE ?? '').trim(),
      ),
    )
        .where((o) => o.id.isNotEmpty && o.label.trim().isNotEmpty)
        .toList();

    if (opts.isEmpty) return;

    switch (masterCode) {
      case 23: // OD pairs for SP
      // 🔹 Save label instead of id for SP OD pairs
        final labelBasedOpts = opts
            .map(
              (o) => AnswerOption(
            id: o.label, // use label as ID so that submitted value = label
            label: o.label,
          ),
        )
            .toList();

        setCatalog('sp_od_pairs', labelBasedOpts);
        debugPrint('📘 sp_od_pairs set using label as ID (${labelBasedOpts.length} items)');
        break;

      case 2: // Trip purposes
      // Ensure we have an "Other" if backend doesn’t send one
        final hasOther = opts.any(
              (o) => o.isOther == true || o.label.toLowerCase() == 'other' || o.id == '99',
        );
        final withOther = List<AnswerOption>.from(opts);
        if (!hasOther) {
          withOther.add(const AnswerOption(id: '99', label: 'Other', isOther: true));
        }
        setCatalog('trip_purposes', withOther);
        break;

      case 1: // Modes
        setCatalog('modes', opts);
        break;

      default:
        debugPrint('Unhandled passenger masterCode=$masterCode');
    }
  }

  Future<void> _apiNationality(BuildContext context) async {
    try {
      final resp = await CommonRepository.instance.apiNationalityDropdown(<String, dynamic>{});
      if (resp is NationalityDropdownResponse && (resp.status ?? false)) {
        final items = (resp.result ?? const <NationalityDropdownDetail>[])
            .map((e) {
          // Prefer Arabic if present, else English
          final label = (e.name ?? '').trim().isNotEmpty
              ? e.name!.trim()
              : (e.nameAr ?? '').trim();
          if (label.isEmpty) return null;

          // We want to SUBMIT the NAME, so set id = name as well
          return AnswerOption(
            id: label, // id == name (so downstream logic is simple)
            label: label, // shown in UI and submitted via _labelFor()
          );
        })
            .whereType<AnswerOption>()
            .toList();

        // Ensure an "Other" option exists
        final hasOther = items.any((o) => o.isOther == true || o.label.toLowerCase() == 'other');
        if (!hasOther) {
          items.add(const AnswerOption(id: 'Other', label: 'Other', isOther: true));
        }

        if (items.isNotEmpty) {
          setCatalog('nationalities', items);
        }
      }
    } catch (e, st) {
      debugPrint('Nationality dropdown load failed: $e\n$st');
    }
  }

  /// Public: call this after the user picks an OD pair in the SP screen.
  /// [odLabel] like "Abu Dhabi to Al Ruwais" or "Abu Dhabi → Dubai".
  Future<void> fetchSpDataForOdLabel(String odLabel) async {
    debugPrint('🔎 SP.fetchSpDataForOdLabel() raw="$odLabel"');

    final pair = _parseOd(odLabel);
    if (pair == null) {
      _spError = 'Invalid OD: "$odLabel"';
      debugPrint('❌ SP.parseOd FAILED for "$odLabel"');
      notifyListeners();
      return;
    }

    final (origin, destination) = pair;
    debugPrint('✅ SP.parseOd OK → origin="$origin", destination="$destination"');

    final carOwnerYesNo = _carOwnerYesNo(); // "Yes" / "No" / null
    const hsRailElig = 'Yes'; // for now

    final req = GetSpDataRequest(
      sOdForSp: origin,
      sDestination: destination,
      sCarOwner: carOwnerYesNo ?? 'No',
      sHsRailElig: hsRailElig,
    );

    debugPrint(
      '📤 SP.apiGetSPData request: '
          'S_ODForSP="$origin", S_Destination="$destination", '
          'S_CarOwner="${carOwnerYesNo ?? 'No'}", S_HSRailElig="$hsRailElig"',
    );

    _spLoading = true;
    _spError = null;
    notifyListeners();

    try {
      final resp = await CommonRepository.instance.apiGetSPData(req);
      debugPrint('📥 SP.apiGetSPData response type=${resp.runtimeType}');

      if (resp is GetSpDataResponse) {
        debugPrint(
          '📥 SP.apiGetSPData status=${resp.status} message="${resp.message}" '
              'rows=${resp.result?.length ?? 0}',
        );
      }

      if (resp is GetSpDataResponse && (resp.status ?? false)) {
        _spData = resp.result ?? const <GetSPDataResult>[];
        _spError = null;
        debugPrint('✅ SP.data loaded rows=${_spData.length}');
      } else {
        _spData = const [];
        _spError = (resp is GetSpDataResponse)
            ? (resp.message ?? 'Unknown error')
            : 'Unknown error';
        debugPrint('❌ SP.load error: $_spError');
      }
    } catch (e, st) {
      _spData = const [];
      _spError = 'Failed to load SP data';
      debugPrint('❌ SP.exception: $e\n$st');
    } finally {
      _spLoading = false;
      notifyListeners();
    }
  }

  // Find a question by id across all current sections (class-level)
  Question? _q(String qid) {
    for (final sec in (sections ?? const [])) {
      for (final q in sec.questions) {
        if (q.id == qid) return q;
      }
    }
    return null;
  }

  Future<void> _prefillPassengerFromServer(int passengerId) async {
    try {
      final result = await CommonRepository.instance.apiGetPassengerData(
        GetPassengerDataRequest(nPassengerRsiid: passengerId),
      );

      if (result is GetPassengerDataResponse && (result.status ?? false)) {
        final data = (result.result ?? const <GetPassengerData>[]).isNotEmpty
            ? result.result!.first
            : null;
        if (data == null) {
          debugPrint('⚠️ getPassengerData empty for id=$passengerId');
          return;
        }

        // 🔹 Set type and reload UI sections
        final type = _typeFromServerLabel(data.sSurveyType);
        if (type != null) {
          questionnaireType = type;
          _loadSections(context);
        }

        // 🔹 Prefill all questions
        _editBaselineSeconds = _parseClockToSeconds(data.sTotalTime);
        elapsedOffsetSeconds = _editBaselineSeconds;
        _applyPassengerApiPrefillFrom(data);

        // applyAutoCapture();
        notifyListeners();
      } else {
        debugPrint('⚠️ getPassengerData failed or empty for id=$passengerId');
      }
    } catch (e, st) {
      debugPrint('❌ _prefillPassengerFromServer error: $e\n$st');
    }
  }

  void safeSet(String section, String qid, dynamic value) {
    final current = valueOfGlobal(qid);
    if (current == null || (current is String && current.isEmpty)) {
      updateAnswer(section, qid, value);
    }
  }

  Question? _pq(String id) {
    for (final s in (sections ?? const [])) {
      for (final q in s.questions) {
        if (q.id == id) return q;
      }
    }
    return null;
  }

  /// Try to map a LABEL back to an option id for a given question.
  String? _idForLabelPassenger(String qid, String? label) {
    if (label == null || label.trim().isEmpty) return null;
    final q = _pq(qid);
    if (q == null || (q.options?.isEmpty ?? true)) return label;
    final lower = label.trim().toLowerCase();
    for (final o in q.options!) {
      if (o.label.trim().toLowerCase() == lower) return o.id;
    }
    // fallback contains match
    for (final o in q.options!) {
      if (lower.contains(o.label.trim().toLowerCase())) return o.id;
    }
    return null;
  }

  QuestionnaireType? _typeFromServerLabel(String? s) {
    if (s == null) return null;
    final x = s.toLowerCase();
    if (x.contains('petrol')) return QuestionnaireType.passengerPetrol;
    if (x.contains('border')) return QuestionnaireType.passengerBorder;
    if (x.contains('bus')) return QuestionnaireType.bus;
    if (x.contains('airport')) return QuestionnaireType.airport;
    if (x.contains('hotel')) return QuestionnaireType.hotel;
    return null;
  }

  (String? base, String? other)? _splitOtherText(String? label) {
    if (label == null) return null;
    final reg = RegExp(r'^\s*Other\s*\((.*?)\)\s*$', caseSensitive: false);
    final match = reg.firstMatch(label.trim());
    if (match != null) {
      final text = match.group(1)?.trim();
      return ('Other', text);
    }
    return (label, null);
  }

  void _applyPassengerApiPrefillFrom(GetPassengerData d) {
    void _set(String qid, dynamic value) {
      final q = _pq(qid);
      if (q == null) return;

      // 1) set the question’s own answer
      q.answer = value;

      // 2) also push into the section’s answer store + __global
      QuestionnaireSection? sec;
      for (final s in (sections ?? const [])) {
        if (s.questions.any((qq) => qq.id == qid)) {
          sec = s;
          break;
        }
      }
      if (sec != null) {
        updateAnswer(sec.id, qid, value);
      }
      updateAnswer('__global', qid, value);

      debugPrint('↩️ prefill $qid = $value (sec=${sec?.id})');
    }

    String? _opt(String qid, String? label) => _idForLabelPassenger(qid, label);

    // ───────── SCREENING ─────────
    if (d.sSurveyType != null) {
      final id = _opt('scr_type_select', d.sSurveyType);
      if (id != null) _set('scr_type_select', id);
    }
    if (d.sSetEligibility != null) {
      final raw = d.sSetEligibility!.trim().toLowerCase();
      // keep the raw value for API round-trip
      _set('scr_set_eligibility', raw);

      switch (questionnaireType) {
        case QuestionnaireType.bus:
          if (raw == 'got_off' || raw == 'waiting' || raw == 'no') {
            _set('scr_e1', raw == 'no' ? 'no' : raw);
          } else if (valueOfGlobal('scr_e1') == null) {
            // fallback to your old heuristics only if no clear id
            final hasRoute     = (d.sBusRoute?.trim().isNotEmpty ?? false);
            final hasFinalDest = (d.sFinalDestination?.trim().isNotEmpty ?? false);
            final hasPtAccess  = (d.sPtAccess?.trim().isNotEmpty ?? false);
            _set('scr_e1', (hasRoute || hasFinalDest) && !hasPtAccess ? 'got_off'
                : hasPtAccess && !(hasRoute || hasFinalDest)     ? 'waiting'
                : 'got_off');
          }
          break;

        case QuestionnaireType.airport:
          if (raw == 'leaving' || raw == 'arrived' || raw == 'no') {
            _set('scr_f1', raw);
          } else if (valueOfGlobal('scr_f1') == null) {
            _set('scr_f1', 'arrived'); // fallback default
          }
          break;

        case QuestionnaireType.hotel:
          if (raw == 'yes' || raw == 'no') {
            _set('scr_g1', raw);
          } else if (valueOfGlobal('scr_g1') == null) {
            _set('scr_g1', 'yes'); // fallback default
          }
          break;

        default:
        // petrol/border: nothing to gate
          break;
      }
    }

    // --- Prefill screening gate based on saved eligibility / flow ---
    final t = questionnaireType;

// Always set "no" if the saved record was ineligible.
    final String gateRaw = (d.sSetEligibility ?? '').trim().toLowerCase();
    final bool wasIneligible = gateRaw == 'no';
// BUS gate (scr_e1)
    if (t == QuestionnaireType.bus) {
      if (wasIneligible) {
        _set('scr_e1', 'no');
      } else if (valueOfGlobal('scr_e1') == null) {
        // 1) Trust the server gate if it’s explicit
        final gateRaw = (d.sSetEligibility ?? '').trim().toLowerCase();
        if (gateRaw == 'got_off' || gateRaw == 'got off') {
          _set('scr_e1', 'got_off');
        } else if (gateRaw == 'waiting') {
          _set('scr_e1', 'waiting');
        } else {
          // 2) Otherwise infer from bus-only fields
          final hasRoute        = (d.sBusRoute?.trim().isNotEmpty ?? false);          // got_off signal
          final hasFinalDest    = (d.sFinalDestination?.trim().isNotEmpty ?? false);  // got_off signal
          final hasPtAccess     = (d.sPtAccess?.trim().isNotEmpty ?? false);          // waiting signal

          String pick;
          if ((hasRoute || hasFinalDest) && !hasPtAccess) {
            pick = 'got_off';
          } else if (hasPtAccess && !(hasRoute || hasFinalDest)) {
            pick = 'waiting';
          } else {
            // tie/default — prefer got_off
            pick = 'got_off';
          }

          _set('scr_e1', pick);
        }

        debugPrint('🎯 Prefilled scr_e1="${valueOfGlobal('scr_e1')}" '
            '(elig:"$gateRaw", route:${d.sBusRoute}, finalDest:${d.sFinalDestination}, ptAccess:${d.sPtAccess})');
      }
    }

// AIRPORT gate (scr_f1)
    if (t == QuestionnaireType.airport) {
      if (wasIneligible) {
        _set('scr_f1', 'no');
      } else if (valueOfGlobal('scr_f1') == null) {
        // We can’t perfectly infer arrived vs leaving from payload names (they collapse at API),
        // so default to 'arrived' to satisfy required validation.
        _set('scr_f1', 'arrived');
      }

      if ((d.sTravellerType ?? '').trim().isNotEmpty) {
        final raw = d.sTravellerType!.trim().toLowerCase();
        String? id;
        if (raw.contains('tourist') || raw.contains('visiting')) id = 'tourist';
        else if (raw.contains('business')) id = 'business_traveller';
        else if (raw.contains('resident') || raw.contains('uae')) id = 'uae_resident';
        if (id != null) _set('air_f2', id);
      }
    }

// HOTEL gate (scr_g1)
    if (t == QuestionnaireType.hotel) {
      if (wasIneligible) {
        _set('scr_g1', 'no');
      } else if (valueOfGlobal('scr_g1') == null) {
        _set('scr_g1', 'yes');
      }
    }

    // IMPORTANT: set as INT, not string
    if (d.nCarPresent != null) _set('scr_a5_parked_count', d.nCarPresent);

    // ───────── DEMOGRAPHICS ─────────
    if (d.sFullName != null) _set('demo_b0_name', d.sFullName);
    if (d.sGender != null) _set('demo_b1_gender', _opt('demo_b1_gender', d.sGender));
    if (d.sAge != null) _set('demo_b2_age', _opt('demo_b2_age', d.sAge));

    // B3 — Nationality (handles Other(...))
    if (d.sNationality != null) {
      final split = _splitOtherText(d.sNationality);
      if (split != null) {
        final base = split.$1;
        final other = split.$2;
        final id = _opt('demo_b3_nationality', base);
        if (id != null) _set('demo_b3_nationality', id);
        if (other != null) {
          updateAnswer('__global', 'demo_b3_nationality__other', other);
        }
      } else {
        _set('demo_b3_nationality', _opt('demo_b3_nationality', d.sNationality));
      }
    }

    // B4a — Home suburb (handles Other(...))
    if (d.sSuburbs != null) {
      final split = _splitOtherText(d.sSuburbs);
      if (split != null) {
        final base = split.$1;
        final other = split.$2;
        final id = _opt('demo_b4a_home_suburb', base);
        if (id != null) _set('demo_b4a_home_suburb', id);
        if (other != null) {
          updateAnswer('__global', 'demo_b4a_home_suburb__other', other);
        }
      } else {
        _set('demo_b4a_home_suburb', _opt('demo_b4a_home_suburb', d.sSuburbs));
      }
    }

    // B4b — Residence country (handles Other(...))
    if (d.sDriverResidency != null) {
      final split = _splitOtherText(d.sDriverResidency);
      if (split != null) {
        final base = split.$1;
        final other = split.$2;
        final id = _opt('demo_b4b_residence_country', base);
        if (id != null) _set('demo_b4b_residence_country', id);
        if (other != null) {
          updateAnswer('__global', 'demo_b4b_residence_country__other', other);
        }
      } else {
        _set('demo_b4b_residence_country', _opt('demo_b4b_residence_country', d.sDriverResidency));
      }
    }

    if (d.sMonthlyIncome != null) {
      _set('demo_b5_income', _opt('demo_b5_income', d.sMonthlyIncome));
    }

    // B6 — Employment (handles Other(...))
    if (d.sOccupation != null) {
      final split = _splitOtherText(d.sOccupation);
      if (split != null) {
        final base = split.$1;
        final other = split.$2;
        final id = _opt('demo_b6_employment', base);
        if (id != null) _set('demo_b6_employment', id);
        if (other != null) {
          updateAnswer('__global', 'demo_b6_employment__other', other);
        }
      } else {
        _set('demo_b6_employment', _opt('demo_b6_employment', d.sOccupation));
      }
    }

    if (d.sPrivateCarAvailability != null) {
      _set('demo_b7_car_access', _opt('demo_b7_car_access', d.sPrivateCarAvailability));
    }

    // ───────── FLOW LOGIC ─────────
    final type = (d.sSurveyType ?? '').toLowerCase();

    // PETROL / CAR
    if (type.contains('petrol')) {
      if (d.nTrippurp != null) _set('c1_purpose', d.nTrippurp.toString());
      if (d.sOrigin != null)      { _set('c2_origin', _normalizeLocForUi(d.sOrigin)); unawaited(_enrichLocationLabelForQid('c2_origin')); }
      if (d.dtTripStartTime != null) _set('c3_start_time', d.dtTripStartTime);
      if (d.dtTripEndTime != null) _set('c3_arrival_time', d.dtTripEndTime);
      if (d.sLastActivity != null)
        _set('c4_last_activity', _opt('c4_last_activity', d.sLastActivity));
      if (d.sDestination != null) { _set('c5_destination', _normalizeLocForUi(d.sDestination)); unawaited(_enrichLocationLabelForQid('c5_destination')); }
      // if (d.sNextActivity != null)
      //   _set('c6_next_activity', _opt('c6_next_activity', d.sNextActivity));
      if (d.sODforSp != null) _set('c7_sp_odpair', _opt('c7_sp_odpair', d.sODforSp));
      if (d.sFrequency != null) _set('c8_frequency', _opt('c8_frequency', d.sFrequency));
      if (d.sCostTrip != null) _set('c9_cost', d.sCostTrip);
      if (d.nNoOfPassenger != null) _set('c10_occupancy', d.nNoOfPassenger.toString());
      if (d.sCostSharing != null) _set('c11_cost_share', _opt('c11_cost_share', d.sCostSharing));
    }
    // BORDER
    else if (type.contains('border')) {
      if (d.nTrippurp != null) _set('d1_purpose', d.nTrippurp.toString());
      if (d.sOrigin != null)      { _set('d2_origin', _normalizeLocForUi(d.sOrigin)); unawaited(_enrichLocationLabelForQid('d2_origin')); }
      if (d.dtTripStartTime != null) _set('d3_start_time', d.dtTripStartTime);
      if (d.dtTripEndTime != null) _set('d3_arrival_time', d.dtTripEndTime);
      if (d.sLastActivity != null)
        _set('d4_last_activity', _opt('d4_last_activity', d.sLastActivity));
      if (d.sDestination != null) { _set('d5_destination', _normalizeLocForUi(d.sDestination)); unawaited(_enrichLocationLabelForQid('d5_destination')); }
      // if (d.sNextActivity != null)
      //   _set('d6_next_activity', _opt('d6_next_activity', d.sNextActivity));
      if (d.sODforSp != null) _set('d7_sp_odpair', _opt('d7_sp_odpair', d.sODforSp));
      if (d.sFrequency != null) _set('d8_frequency', _opt('d8_frequency', d.sFrequency));
      if (d.sCostTrip != null) _set('d9_cost', d.sCostTrip);
      if (d.nNoOfPassenger != null) _set('d10_occupancy', d.nNoOfPassenger.toString());
      if (d.sCostSharing != null) _set('d11_cost_share', _opt('d11_cost_share', d.sCostSharing));
    }
    // BUS
    else if (type.contains('bus')) {
      if (d.nTrippurp != null) _set('bus_e2_purpose', d.nTrippurp.toString());
      if (d.sOrigin != null) { _set('bus_e3_origin', _normalizeLocForUi(d.sOrigin)); unawaited(_enrichLocationLabelForQid('bus_e3_origin')); }
      if (d.dtTripStartTime != null) _set('bus_e4_start_time', d.dtTripStartTime);
      if (d.dtTripEndTime != null) _set('bus_e4_arrival_time', d.dtTripEndTime);
      if (d.sLastActivity != null) _set('bus_e5_last_activity', _opt('bus_e5_last_activity', d.sLastActivity));

      // ✅ Route goes to different question depending on the screening gate
      final gate = (valueOfGlobal('scr_e1') ?? '').toString();
      if (d.sBusRoute != null && d.sBusRoute!.trim().isNotEmpty) {
        if (gate == 'waiting') {
          _set('bus_e11_route_waiting', d.sBusRoute);   // shown when Waiting
        } else {
          _set('bus_e6_route_used', d.sBusRoute);       // shown when Got off (default)
        }
      }

      if (d.sDestination != null) { _set('bus_e8_destination', _normalizeLocForUi(d.sDestination)); unawaited(_enrichLocationLabelForQid('bus_e8_destination')); }
      if (d.sODforSp != null) _set('bus_e12_od_for_sp', _opt('bus_e12_od_for_sp', d.sODforSp));
      if (d.sFrequency != null) _set('bus_e13_frequency', _opt('bus_e13_frequency', d.sFrequency));
      if (d.sIcModeChoice != null) _set('bus_e14_ic_mode_reason', d.sIcModeChoice);
      if (d.sCostTrip != null) _set('bus_e15_trip_cost', d.sCostTrip);

      // 🔹 NEW: generic multi-select prefill (labels/CSV → option IDs)
      // E10 (egress) when got_off:
      if (valueOfGlobal('scr_e1') == 'got_off' && d.sFinalDestination != null) {
        SelectionMapper.prefillMultiSelect(
          qId: 'bus_e10_egress_mode',
          rawValue: d.sFinalDestination, // e.g. "Another bus, Car (owned or hired)"
          notifier: this,
        );
      }

      // E7 (access) when waiting:
      if (valueOfGlobal('scr_e1') == 'waiting' && d.sPtAccess != null) {
        SelectionMapper.prefillMultiSelect(
          qId: 'bus_e7_access_mode',
          rawValue: d.sPtAccess, // e.g. "Walk, Taxi"
          notifier: this,
        );
      }
    }
    // AIRPORT
    else if (type.contains('airport')) {
      final arrived = valueOfGlobal('scr_f1') == 'arrived';
      if (d.sAirsideOd != null) _set(arrived ? 'air_f3' : 'air_f11', d.sAirsideOd);
      if (d.sAirline != null) _set(arrived ? 'air_f4' : 'air_f12', d.sAirline);
      if (d.sLandsideOd != null) {
        _set(arrived ? 'air_f5' : 'air_f13', _normalizeLocForUi(d.sLandsideOd));
        unawaited(_enrichLocationLabelForQid(arrived ? 'air_f5' : 'air_f13'));
      }
      final travellerId = _idForLabelPassenger('air_f2', d.sTravellerType?.toString());
      if (travellerId != null) {
        _set('air_f2', _isMultiQ('air_f2') ? <String>[travellerId] : travellerId);
      }



      // ✅ Prefill IC travel pattern chips from CSV of labels ("Ajman, Dubai")
      final icCsv = d.sIcTravelPattern ?? d.sIcTravelPattern; // handle either casing
      if (icCsv != null && icCsv.trim().isNotEmpty) {
        SelectionMapper.prefillMultiSelect(
          qId: arrived ? 'air_f9' : 'air_f17', // F9 for Arrived, F17 for Leaving
          rawValue: icCsv,                      // e.g., "Ajman, Dubai"
          notifier: this,
        );
      }

// Purpose → air_f6 (prefer code, else map label)
      String? purposeUiId;
      if (d.nTrippurp != null) {
        purposeUiId = d.nTrippurp!.toString();
      } else {
        // try label fallback if backend returns the English/Arabic purpose text
        purposeUiId = _idForLabelPassenger(arrived ? 'air_f6' : 'air_f14',
            (d.trippurpE ?? d.trippurpA)?.toString());
      }

      if (purposeUiId != null && purposeUiId.trim().isNotEmpty) {
        _set(arrived ? 'air_f6' : 'air_f14',
            _isMultiQ(arrived ? 'air_f6' : 'air_f14') ? <String>[purposeUiId] : purposeUiId);
      }

// Vehicle → air_f7 (N_VehicleType or N_VehicleType1, respect multi-select)
      final vehQid = arrived ? 'air_f7' : 'air_f15';

// New path: CSV of labels → map back to options
      if ((d.sVehicleType ?? '').trim().isNotEmpty) {
        SelectionMapper.prefillMultiSelect(
          qId: vehQid,
          rawValue: d.sVehicleType!, // e.g., "Taxi, Metro"
          notifier: this,
        );
      } else {
        // Legacy fallback if old records still have numeric codes
        final legacyVeh = (d.nVehicleType ?? d.nVehicleType1)?.toString();
        if (legacyVeh != null && legacyVeh.trim().isNotEmpty) {
          _set(vehQid, _isMultiQ(vehQid) ? <String>[legacyVeh] : legacyVeh);
        }
      }

      final stayQid = arrived ? 'air_f8' : 'air_f16';

      if ((d.sStayDuration ?? '').trim().isNotEmpty) {
        final raw = d.sStayDuration!.trim();

        // Try to map backend label (e.g. "1 (flying in and out...)" → "1")
        String? stayId = _idForLabelPassenger(stayQid, raw)
            ?? RegExp(r'^\s*(\d+)\b').firstMatch(raw)?.group(1);

        // Fallback if no match (keeps value visible)
        _set(stayQid, stayId ?? raw);
      }

// Group size (unchanged)
      String _groupSizeIdFromInt(int v) {
        switch (v) {
          case 1: return 'alone';
          case 2: return '1';
          case 3: return '2';
          default: return '3plus';
        }
      }

      if (d.nNoOfPassenger != null) {
        // Arrived → air_f10, Leaving → air_f18
        final groupQid = arrived ? 'air_f10' : 'air_f18';
        _set(groupQid, _groupSizeIdFromInt(d.nNoOfPassenger!));
      }
    }
    // HOTEL
    else if (type.contains('hotel')) {
      // G2 — destinations (multi). Server sends label(s). Map to IDs strictly.
      if ((d.sDestination ?? '').trim().isNotEmpty) {
        debugPrint('🏨 prefill G2 from S_Destination="${d.sDestination}"');
        SelectionMapper.prefillMultiSelect(
          qId: 'hotel_g2_destinations',
          rawValue: d.sDestination!,
          notifier: this,
        );

        notifyListeners();                       // let dependents react
        Future<void>.delayed(Duration.zero);
      }

      // Read back the selected destination IDs (e.g. ['hotel'] or ['home','work'])
      final selectedDestIds = (valueOfGlobal('hotel_g2_destinations') as List?)
          ?.map((e) => e?.toString().trim())
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList() ?? const [];

      debugPrint('🏨 G2 selected dest ids → $selectedDestIds');

      // G3 — modes (multi) repeated per destination:
      // NOTE: your payload has no labels for modes (S_VehicleType null, N_VehicleType=0),
      // so we skip unless you later supply CSV labels per-destination.
      // If you ever get labels, you can prefill like:
      //
      //   for (final destId in selectedDestIds) {
      //     final qid = 'hotel_g3_mode__$destId';
      //     SelectionMapper.prefillMultiSelect(
      //       qId: qid,
      //       rawValue: someCsvFromServer, // e.g. "Taxi/chauffeur, Metro"
      //       notifier: this,
      //       debug: true,
      //     );
      //   }

      // G4 — time (radio) repeated per destination:
      if ((d.sLocDuration ?? '').trim().isNotEmpty && selectedDestIds.isNotEmpty) {
        final raw = d.sLocDuration!.trim();
        for (final destId in selectedDestIds) {
          final qid = 'hotel_g4_time__$destId';
          debugPrint('🏨 prefill G4 "$qid" from S_LocDuration="$raw"');
          _setExactSingle(qid, raw); // exact id or exact label ("1-2h") → id
        }
      }

      // G5 — stay length (radio). Your payload has "6" → matches id "6" exactly.
      if ((d.sStayDuration ?? '').trim().isNotEmpty) {
        debugPrint('🏨 prefill G5 from S_StayDuration="${d.sStayDuration}"');
        _setExactSingle('hotel_g5_stay_days', d.sStayDuration);
      }

      // (Optional) If legacy integer vehicle type list arrives in future:
      // if ((d.nVehicleType ?? 0) != 0) { /* map to repeated G3 as needed */ }
    }

    debugPrint('✅ Passenger prefill complete');
  }

  void _clearAllState() {
    // clear passenger-specific caches
    _spData = const [];
    _spError = null;
    _spLoading = false;
    _editBaselineSeconds = 0;
    elapsedOffsetSeconds = 0;

    // reset the flow back to the type selector
    questionnaireType = null;
    resetQuestionnaire(
      unlockType: true,
      resetTimer: true,
      freshSections: [screeningSelectTypeSection()],
    );
  }

  String? _toIso1900(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final secs = _secondsSinceMidnight(raw);
    if (secs == null) {
      // If it's already ISO, keep it
      try { DateTime.parse(raw); return raw; } catch (_) {}
      return null; // or return raw; if you prefer pass-through
    }
    final h  = (secs ~/ 3600).toString().padLeft(2, '0');
    final m  = ((secs % 3600) ~/ 60).toString().padLeft(2, '0');
    final s  = (secs % 60).toString().padLeft(2, '0');
    return '1900-01-01T$h:$m:$s';
  }

  int _parseClockToSeconds(String? s) {
    if (s == null || s.trim().isEmpty) return 0;
    final parts = s.split(':').map((e) => e.trim()).toList();
    if (parts.isEmpty) return 0;
    int h = 0, m = 0, sec = 0;
    if (parts.length == 2) {
      m = int.tryParse(parts[0]) ?? 0;
      sec = int.tryParse(parts[1]) ?? 0;
    } else if (parts.length >= 3) {
      h = int.tryParse(parts[0]) ?? 0;
      m = int.tryParse(parts[1]) ?? 0;
      sec = int.tryParse(parts[2]) ?? 0;
    } else {
      m = int.tryParse(parts[0]) ?? 0;
    }
    return h * 3600 + m * 60 + sec;
  }

  String? _formatMmSs(int? seconds) {
    if (seconds == null || seconds < 0) return null;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }


  /// Class-level: return the DISPLAY LABEL for a single-select answer if possible,
  /// otherwise return the raw value as string.
  String? labelForDisplay(String qid) {
    final ans = valueOfGlobal(qid);
    if (ans == null) return null;

    final q = _q(qid);

    // If no options catalog, just stringify (join lists)
    if (q == null || (q.options?.isEmpty ?? true)) {
      if (ans is List) {
        final items = ans.map((e) => e?.toString().trim()).whereType<String>().where((s) => s.isNotEmpty).toList();
        return items.isEmpty ? null : items.join(', ');
      }
      final s = ans.toString().trim();
      return s.isEmpty ? null : s;
    }

    // Multi-select → map each id to its label and join
    if (ans is List) {
      final labels = <String>[];
      for (final item in ans) {
        final id = item?.toString() ?? '';
        if (id.isEmpty) continue;
        final opt = q.options!.firstWhere(
              (o) => o.id.toString() == id,
          orElse: () => AnswerOption(id: id, label: id),
        );
        final lbl = opt.label.trim().isEmpty ? id : opt.label.trim();
        labels.add(lbl);
      }
      return labels.isEmpty ? null : labels.join(', ');
    }

    // Single-select
    final id = ans.toString();
    final opt = q.options!.firstWhere(
          (o) => o.id.toString() == id,
      orElse: () => AnswerOption(id: id, label: id),
    );
    final lbl = opt.label.trim();
    return lbl.isEmpty ? id : lbl;
  }

  /// Optional helper: fetch based on the answer stored under a question id.
  /// Example qIds to try: 'sp_odpair', 'd7_sp_odpair', 'c7_sp_odpair', 'bus_e12_od_for_sp'.
  Future<void> fetchSpDataFromAnswer({
    List<String> qIds = const ['sp_odpair', 'd7_sp_odpair', 'c7_sp_odpair', 'bus_e12_od_for_sp'],
  }) async {
    String? label;
    for (final id in qIds) {
      final v = valueOfGlobal(id);
      if (v != null && v.toString().trim().isNotEmpty) {
        label = labelForDisplay(id) ?? v.toString();
        break;
      }
    }
    if (label == null) {
      _spError = 'No OD selected';
      notifyListeners();
      return;
    }
    await fetchSpDataForOdLabel(label);
  }

  /// Parses "Abu Dhabi to Al Ruwais" or "Abu Dhabi → Dubai"
  /// Returns (origin, destination) or null if it can't parse.
  (String, String)? _parseOd(String s) {
    final raw = s.trim();
    debugPrint('🔧 _parseOd IN="$raw"');
    if (raw.isEmpty) return null;

    // Normalize common separators to |
    var norm = raw
        .replaceAll(RegExp(r'\s+to\s+', caseSensitive: false), '|')
        .replaceAll(RegExp(r'\s+and\s+', caseSensitive: false), '|')
        .replaceAll('→', '|')
        .replaceAll('=>', '|')
        .replaceAll('->', '|')
        .replaceAll('>', '|')
        .replaceAll(RegExp(r'\s*[-–—]\s*'), '|');

    // AUH-DXB style codes map
    final codeRe = RegExp(r'^\s*([A-Za-z]{3})\s*\|\s*([A-Za-z]{3})\s*$');
    final map = {
      'AUH': 'Abu Dhabi',
      'DXB': 'Dubai',
      'SHJ': 'Sharjah',
      'AJM': 'Ajman',
      'UAQ': 'Umm Al Quwain',
      'RKT': 'Ras Al Khaimah',
      'FJR': 'Fujairah',
    };

    // Convert AUH-DXB (we replaced dashes to | already)
    final hyphenToPipe = raw.replaceAll(RegExp(r'\s*[-–—]\s*'), '|');
    if (codeRe.hasMatch(hyphenToPipe)) {
      final m = codeRe.firstMatch(hyphenToPipe)!;
      final a = map[m.group(1)!.toUpperCase()];
      final b = map[m.group(2)!.toUpperCase()];
      debugPrint('🔧 _parseOd CODE → "$a" | "$b"');
      if (a != null && b != null) return (a, b);
    }

    final parts = norm.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    debugPrint('🔧 _parseOd NORM="$norm" PARTS=$parts');

    if (parts.length == 2) {
      debugPrint('🔧 _parseOd OK origin="${parts[0]}", dest="${parts[1]}"');
      return (parts[0], parts[1]);
    }

    debugPrint('🔧 _parseOd FAIL');
    return null;
  }

  /// Maps demo_b7_car_access to "Yes"/"No"
  /// ids: no | own | shared
  String? _carOwnerYesNo() {
    final raw = valueOfGlobal('demo_b7_car_access')?.toString();
    if (raw == null) return null;
    if (raw == 'no') return 'No';
    // 'own' or 'shared' => Yes
    return 'Yes';
  }

  bool _isMultiQ(String qid) {
    final q = _pq(qid);
    if (q == null) return false;

    final type = q.captureConfig?['type']?.toString().toLowerCase();
    if (type != null) {
      const multiHints = {
        'multiselect', 'multi', 'checkbox', 'chips_multi', 'tags', 'select_multiple'
      };
      if (multiHints.contains(type)) return true;
    }

    final multipleFlag = q.captureConfig?['multiple'] == true;
    final maxVal = q.captureConfig?['max'];
    if (multipleFlag == true) return true;
    if (maxVal is num && maxVal > 1) return true;

    // Last resort: if the current answer is already a list, treat it as multi.
    return q.answer is List;
  }

  @override
  Future<void> nextStep(BuildContext context) async {
    debugPrint('🧭 Passenger.nextStep()');
    debugPrint('🧾 Answers (pre-validate): ${getAllAnswers()}');

    final err = validateCurrentStep();
    if (err != null) {
      lastError = err;
      notifyListeners();
      return;
    }
    lastError = null;

// Custom start/end time validation for the current section
    final section = sections![currentStep];
    final timeErr = _validateStartEndPairsForSection(section);
    if (timeErr != null) {
      lastError = timeErr;
      notifyListeners();
      return;
    }

    if (section.id == 'screening') {
      // read the raw gate answer based on flow
      String? rawGate;
      switch (questionnaireType) {
        case QuestionnaireType.bus:
          rawGate = valueOfGlobal('scr_e1') as String?;
          break;
        case QuestionnaireType.airport:
          rawGate = valueOfGlobal('scr_f1') as String?;
          break;
        case QuestionnaireType.hotel:
          rawGate = valueOfGlobal('scr_g1') as String?;
          break;
        default:
          rawGate = null; // petrol/border have no gate
      }

      // ✅ Store exactly the gate id for API
      if (rawGate != null) {
        updateAnswer('screening', 'scr_set_eligibility', rawGate); // S_SetEligibility ← got_off | waiting | no | leaving | arrived | yes
      } else {
        // optional: clear for petrol/border (no gate)
        updateAnswer('screening', 'scr_set_eligibility', null);
      }

      // keep your internal blocking logic unchanged, but base it on rawGate == 'no'
      final bool blocked = (questionnaireType == QuestionnaireType.bus     && rawGate == 'no') ||
          (questionnaireType == QuestionnaireType.airport && rawGate == 'no') ||
          (questionnaireType == QuestionnaireType.hotel   && rawGate == 'no');

      // (Optional) keep separate hidden mirrors if you still want them
      if (questionnaireType == QuestionnaireType.bus && rawGate != null) {
        updateAnswer('screening', 'scr_bus_gate', rawGate);
      }
      if (questionnaireType == QuestionnaireType.airport && rawGate != null) {
        updateAnswer('screening', 'scr_air_gate', rawGate);
      }
      if (questionnaireType == QuestionnaireType.hotel && rawGate != null) {
        updateAnswer('screening', 'scr_hotel_gate', rawGate);
      }

      // stamp end time on screening completion
      updateAnswer('screening', 'scr_end_time', DateTime.now().toIso8601String());

      if (blocked) {
        const msg = 'Respondent not eligible. Survey ended.';
        stopTimer(reset: true);
        questionnaireType = null;
        sections = [screeningSelectTypeSection()];
        currentStep = 0;
        furthestStep = 0;
        lastError = msg;
        notifyListeners();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
          }
        });
        return;
      }
    }

    // FIRST SCREEN: initial selector where user picks which passenger flow
    if (section.id == 'screening_init') {
      final typeId = valueOfGlobal('scr_type_select') as String?;
      if (typeId == null || typeId.isEmpty) {
        lastError = 'Please select the type of survey';
        notifyListeners();
        return;
      }
      await onTypeSelected(typeId, context); // rebuild to the chosen flow
      return;
    }

    // Normal advance with skip-empty sections
    final total = sections?.length ?? 0;
    var next = currentStep + 1;

    while (next < total && !_sectionHasVisibleQuestions(sections![next])) {
      next++;
    }

    if (next < total) {
      currentStep = next;
      furthestStep = (furthestStep < currentStep) ? currentStep : furthestStep;
      notifyListeners();
      return;
    }

    // Final submit
    final answers = getAllAnswers();

    // Avoid relying on a possibly-missing `elapsed` getter; compute seconds safely.
    final int durationSeconds = startedAt == null
        ? 0
        : DateTime.now().difference(startedAt!).inSeconds;

    answers['__meta'] = {
      'duration_seconds': durationSeconds,
      'duration_text': elapsedText, // base should expose this
      'started_at_iso': startedAt?.toIso8601String(),
      'submitted_at_iso': DateTime.now().toIso8601String(),
      'flow_type': questionnaireType.toString(),
    };

    debugPrint("✅ Passenger Final Answers: $answers");
    await onSubmit(context, answers);

    // Keep duration visible post-submit if your base supports it
    stopTimer();
    notifyListeners();
  }

  @override
  void previousStep() {
    var prev = currentStep - 1;
    while (prev >= 0 && !_sectionHasVisibleQuestions(sections![prev])) {
      prev--;
    }
    if (prev >= 0) {
      currentStep = prev;
      notifyListeners();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Submission wiring for passenger flows
  // ───────────────────────────────────────────────────────────────────────────

  // Future<void> _submitPassenger(BuildContext context, Map<String, dynamic> finalAnswers) async {
  //   try {
  //     final req = await _buildAddPassengerRequest(); // ⟵ build merged submit
  //     final result = await CommonRepository.instance.apiAddPassengerQuestionnaire(req);
  //
  //     // mirror RSI success path
  //     if (result is AddRsiResponse && (result.status ?? false)) {
  //       ToastHelper.showSuccess("Data updated successfully");
  //       resetQuestionnaire();
  //
  //       WidgetsBinding.instance.addPostFrameCallback((_) {
  //         if (context.mounted) {
  //           Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
  //         }
  //       });
  //       return;
  //     }
  //
  //     ToastHelper.showError('Unable to submit. Please try again.');
  //   } catch (e, st) {
  //     debugPrint('Passenger submit error: $e\n$st');
  //     ToastHelper.showError('An error occurred. Please try again.');
  //     notifyListeners();
  //   }
  // }

  @override
  Future<void> saveDraft(BuildContext context) => onSaveDraft(context);

  //For SP Initialization
  Future<void> _submitPassenger(BuildContext context, Map<String, dynamic> finalAnswers) async {
    GetSpDataRequest? spReq;     // request snapshot
    dynamic spRespForLog;
    try {
      final req = await _buildAddPassengerRequest(nStatus: 1);
      final result = await CommonRepository.instance.apiAddPassengerQuestionnaire(req);

      if (result is AddRsiResponse && (result.status ?? false)) {
        // 1) PassengerRSIID
        final id = (result.result?.isNotEmpty ?? false)
            ? result.result!.first.nPassengerRsiid
            : null;

        // 2) Resolve OD label
        String? odLabel;
        for (final qid in const [
          'sp_odpair',
          'd7_sp_odpair',
          'c7_sp_odpair',
          'bus_e12_od_for_sp',
        ]) {
          final v = valueOfGlobal(qid);
          if (v != null && v.toString().trim().isNotEmpty) {
            odLabel = labelForDisplay(qid) ?? v.toString();
            break;
          }
        }

        // If no OD pair → success toast + go home (don’t block on SP)
        if (odLabel == null) {
          _clearAllState();
          _showSuccessAndGoHome(context);
          return;
        }

        // 3) Parse OD
        final pair = _parseOd(odLabel);
        if (pair == null) {
          // Invalid OD format → success toast + go home
          _clearAllState();
          _showSuccessAndGoHome(context);
          return;
        }
        final (origin, destination) = pair;

        // 4) HS Rail eligibility rule
        bool _isAbuDhabiDubai(String a, String b) {
          String n(String s) => s.trim().toLowerCase();
          final oa = n(a), ob = n(b);
          return (oa.startsWith('abu dhabi') && ob.startsWith('dubai')) ||
              (oa.startsWith('dubai') && ob.startsWith('abu dhabi'));
        }

        final bool adDxb = _isAbuDhabiDubai(origin, destination);
        final String hsRailElig = adDxb && id != null ? (id % 2 == 0 ? 'No' : 'Yes') : 'No';

        // 5) Car owner
        final carOwner = _carOwnerYesNo() ?? 'No';

        // 6) Call SP API
        spReq = GetSpDataRequest(
          sOdForSp: origin,
          sDestination: destination,
          sCarOwner: carOwner,
          sHsRailElig: hsRailElig,
        );

        _spLoading = true;
        _spError = null;
        notifyListeners();

        final spResp = await CommonRepository.instance.apiGetSPData(spReq);
        spRespForLog = spResp;
        _spLoading = false;
        notifyListeners();

        // Any SP failure → success toast + go home
        if (spResp is! GetSpDataResponse || !(spResp.status ?? false)) {
          _clearAllState();
          _showSuccessAndGoHome(context);
          return;
        }

        _spData = spResp.result ?? const <GetSPDataResult>[];
        notifyListeners();

        // No SP rows → success toast + go home
        if (_spData.isEmpty) {
          _clearAllState();
          _showSuccessAndGoHome(context);
          return;
        }

        // 7) Build sets (first 6)
        final sets = _buildSpSetsFromApiRows(_spData).take(6).toList();

// ⏱ Recompute the elapsed so far (same logic you used in _buildAddPassengerRequest)
// ⏱ Capture BEFORE clearing state
        // ⏱ Capture BEFORE clearing state (DON'T clear yet)
        // ⏱ Capture BEFORE clearing state
        final int sessionSeconds = startedAt == null
            ? 0
            : DateTime.now().difference(startedAt!).inSeconds;
        final int totalElapsed = _editBaselineSeconds + sessionSeconds;
        final String startedIso = startedAt?.toIso8601String() ?? DateTime.now().toIso8601String();

// Now it’s safe to clear passenger state ONCE
        _clearAllState();

// → navigate using the captured values
        if (context.mounted) {
          debugPrint('SP⏱ compute: _editBaselineSeconds=$_editBaselineSeconds '
              'startedAt=$startedAt sessionSeconds=$sessionSeconds '
              '→ totalElapsed=$totalElapsed startedIso=$startedIso');

          Navigator.pushReplacementNamed(
            context,
            AppRoutes.statedPreferencePreamble,
            arguments: {
              'od': '$origin to $destination',
              'sets': sets,
              'interviewMasterId': id,
              'continuedElapsedSec': totalElapsed,
              'startedIso': startedIso,
            },
          );
        }
        return;
      }

      // AddPassenger failed
      ToastHelper.showError('Unable to submit. Please try again.', error: "Unable to submit. Please try again.", stack: StackTrace.current);
    } on DioException catch (e, st) {
      // If repository uses Dio internally, this gives you raw HTTP details
      final responseSnapshot = e.response == null
          ? null
          : {
        'statusCode': e.response?.statusCode,
        'headers': e.response?.headers.map,
        'data': (() {
          final d = e.response?.data;
          if (d is Map || d is List) return d;             // JSON-like
          try { return (d as dynamic).toJson(); } catch (_) {}
          return d?.toString();
        })(),
      };

      final Map<String, dynamic> errMap = {
        'api': 'CommonRepository.apiGetSPData',
        'request': (() {
          try { return spReq?.toJson(); } catch (_) { return spReq?.toString(); }
        })(),
        'response': responseSnapshot ?? (() {
          // fallback to whatever we captured from repository
          final r = spRespForLog;
          if (r is GetSpDataResponse) {
            return {
              'status': r.status,
              'message': r.message,
              'result_len': r.result?.length,
            };
          }
          if (r is Map || r is List) return r;
          try { return (r as dynamic).toJson(); } catch (_) {}
          return r?.toString();
        })(),
        'error': e.message ?? e.toString(),
      };

      debugPrint('Passenger submit error (Dio): $errMap\n$st');
      ToastHelper.showError(
        jsonEncode(errMap),
        context: context,
        error: e,
        stack: st,
      );
      notifyListeners();
    } catch (e, st) {
      // Generic errors (parsing, type cast, nulls, etc.)
      final Map<String, dynamic> errMap = {
        'api': 'CommonRepository.apiGetSPData',
        'request': (() {
          try { return spReq?.toJson(); } catch (_) { return spReq?.toString(); }
        })(),
        'response': (() {
          final r = spRespForLog;
          if (r is GetSpDataResponse) {
            return {
              'status': r.status,
              'message': r.message,
              'result_len': r.result?.length,
              // If you really want to see rows, uncomment (can be large):
              // 'result': r.result?.map((x) => x.toJson()).toList(),
            };
          }
          if (r is Map || r is List) return r;
          try { return (r as dynamic).toJson(); } catch (_) {}
          return r?.toString();
        })(),
        'error': e.toString(),
      };

      debugPrint('Passenger submit error: $errMap\n$st');
      ToastHelper.showError(
        jsonEncode(errMap),
        context: context,
        error: e,
        stack: st,
      );
      notifyListeners();
    }
  }

  // Exact match helpers (only trim)
  String? _exactIdFor(BaseQuestionnaireNotifier n, String qid, String? raw) {
    if (raw == null) return null;
    final inp = raw.trim();
    if (inp.isEmpty) return null;
    final opts = _optionsForQid(qid);
    for (final o in opts) {
      if (o.id.toString() == inp) return o.id.toString();     // exact id
    }
    for (final o in opts) {
      if (o.label.toString() == inp) return o.id.toString();   // exact label
    }
    return null;
  }

  /// For radio/single: set by exact id or exact label (trim only).
  void _setExactSingle(String qid, String? raw) {
    if (raw == null) return;

    // Try to resolve an exact match against clone first, then base id.
    final baseId = qid.contains('__') ? qid.split('__').first : qid;
    final id =
        _exactIdFor(this, qid, raw) ??
            _exactIdFor(this, baseId, raw) ?? // fallback to base question’s options
            raw.trim();

    // ✅ Always stash in the global store so later-built clones can pick it up
    updateAnswer('__global', qid, id);

    // If the clone already exists, set it now…
    final q = _pq(qid);
    if (q != null) {
      q.answer = id;

      QuestionnaireSection? sec;
      for (final s in (sections ?? const [])) {
        if (s.questions.any((qq) => qq.id == qid)) { sec = s; break; }
      }
      if (sec != null) updateAnswer(sec.id, qid, id);
      notifyListeners();
      return;
    }

    // …otherwise, re-apply after the UI lays out the repeated children
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final q2 = _pq(qid);
      if (q2 != null) {
        q2.answer = id;

        QuestionnaireSection? sec2;
        for (final s in (sections ?? const [])) {
          if (s.questions.any((qq) => qq.id == qid)) { sec2 = s; break; }
        }
        if (sec2 != null) updateAnswer(sec2.id, qid, id);
        notifyListeners();
      }
    });
  }

  void _showSuccessAndGoHome(BuildContext context) {
    ToastHelper.showSuccess('Data updated successfully');
    _clearAllState();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    }
  }

  // Parse "hh:mm AM/PM", "HH:mm", "HH:mm:ss", or ISO-ish strings into seconds since midnight.
  int? _secondsSinceMidnight(String? s) {
    if (s == null) return null;
    final raw = s.trim();
    if (raw.isEmpty) return null;

    // 1) Try ISO date/time → use time component if present
    try {
      final dt = DateTime.parse(raw); // throws if not ISO
      return dt.hour * 3600 + dt.minute * 60 + dt.second;
    } catch (_) {
      // not ISO — keep going
    }

    // 2) Try hh:mm AM/PM
    final ampm = RegExp(r'^\s*(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([AaPp][Mm])\s*$');
    final m1 = ampm.firstMatch(raw);
    if (m1 != null) {
      var h = int.parse(m1.group(1)!);
      final min = int.parse(m1.group(2)!);
      final sec = m1.group(3) != null ? int.parse(m1.group(3)!) : 0;
      final ap = m1.group(4)!.toUpperCase();

      if (ap == 'AM') {
        if (h == 12) h = 0;
      } else { // PM
        if (h < 12) h += 12;
      }
      return h * 3600 + min * 60 + sec;
    }

    // 3) Try 24h "HH:mm" or "HH:mm:ss"
    final hhmm = RegExp(r'^\s*(\d{1,2}):(\d{2})(?::(\d{2}))?\s*$');
    final m2 = hhmm.firstMatch(raw);
    if (m2 != null) {
      final h = int.parse(m2.group(1)!);
      final min = int.parse(m2.group(2)!);
      final sec = m2.group(3) != null ? int.parse(m2.group(3)!) : 0;
      if (h < 0 || h > 23 || min < 0 || min > 59 || sec < 0 || sec > 59) return null;
      return h * 3600 + min * 60 + sec;
    }

    return null; // unrecognized
  }

  String? _validateStartEndPairsForSection(QuestionnaireSection section) {
    // Known (start, end) pairs per flow
    const pairs = <(String,String)>[
      // Petrol
      ('c3_start_time', 'c3_arrival_time'),
      // Border
      ('d3_start_time', 'd3_arrival_time'),
      // Bus
      ('bus_e4_start_time', 'bus_e4_arrival_time'),
    ];

    // Only check the pairs that exist on this section and have values
    for (final (startId, endId) in pairs) {
      final startVal = valueOfGlobal(startId)?.toString();
      final endVal   = valueOfGlobal(endId)?.toString();

      // Skip if either missing on current section or unanswered
      final hasStartQ = section.questions.any((q) => q.id == startId);
      final hasEndQ   = section.questions.any((q) => q.id == endId);
      if (!hasStartQ || !hasEndQ) continue;
      if (startVal == null || startVal.trim().isEmpty) continue;
      if (endVal == null || endVal.trim().isEmpty) continue;

      final s = _secondsSinceMidnight(startVal);
      final e = _secondsSinceMidnight(endVal);
      if (s == null || e == null) continue; // if unparsable, don't block here

      if (e <= s) {
        // Human-friendly label lookup if you want:
        final startLabel = _q(startId)?.question ?? 'Start time';
        final endLabel   = _q(endId)?.question   ?? 'End time';
        return '$endLabel must be after $startLabel.';
      }
    }
    return null;
  }

  num? _numOrNull(String? s) {
    if (s == null) return null;
    final t = s.trim();
    if (t.isEmpty) return null;
    // accept "123", "123.4", "123 AED", "90 mins"
    final m = RegExp(r'(\d+(\.\d+)?)').firstMatch(t);
    if (m == null) return null;
    return num.tryParse(m.group(1)!);
  }

  int? _intOrNull(String? s) => _numOrNull(s)?.toInt();

  List<SpSet> _buildSpSetsFromApiRows(List<GetSPDataResult> rows) {
    return rows.map((r) {
      final railEligible = (r.sHsRailElig ?? '').toLowerCase() == 'yes';

      // Build 4 options with safe parsing
      final car = SpOption(
        mode: SpMode.car,
        totalCost: _numOrNull(r.spCarCost),
        totalTime: _numOrNull(r.spCarTime),
        fuelCost: _numOrNull(r.spFuelCost),
        tollsCost: _numOrNull(r.spTollCost),
        parkingCost: _numOrNull(r.spParkingCost),
      );

      final taxi = SpOption(
        mode: SpMode.taxi,
        totalCost: _numOrNull(r.spTaxiCost),
        totalTime: _numOrNull(r.spTaxiTime),
      );

      final rail = SpOption(
        mode: SpMode.rail,
        totalCost: _numOrNull(r.spRailCost),
        totalTime: _numOrNull(r.spRailTotalTime),
        timeToFromStations: _numOrNull(r.spRailCommuteTime),
        timeOnTrain: _numOrNull(r.spRailTime),
      );

      final bus = SpOption(
        mode: SpMode.bus,
        totalCost: _numOrNull(r.spBusCost),
        totalTime: _numOrNull(r.spBusTotalTime),
        timeToFromBusStops: _numOrNull(r.spBusCommuteTime),
        timeOnBus: _numOrNull(r.spBusTime),
      );

      // Only include rail if eligible
      final options = <SpOption>[car, taxi, rail, bus];

      return SpSet(
        reference: r.sReference ?? '',
        origin: r.sOdForSp ?? '',
        destination: r.sDestination ?? '',
        carOwner: (r.sCarOwner ?? '').toLowerCase() == 'yes',
        hsRailRelevant: railEligible,
        scenario: r.nScenario ?? 0,
        options: options,
        selectedIndex: null,
      );
    }).toList();
  }

  static const _emirateNameToCode = {
    'Abu Dhabi': 'Abu Dhabi',
    'Dubai': 'Dubai',
    'Sharjah': 'Sharjah',
    'Ajman': 'Ajman',
    'Umm Al Quwain': 'Umm Al Quwain',
    'Ras al Khaimah': 'Ras Al Khaimah',
    'Ras Al-Khaimah': 'Ras Al Khaimah',
    'Fujairah': 'Fujairah',
  };

  String? emirateFromLatLonFallback(double lat, double lon) {
    if (lat >= 24.90 && lat <= 25.45 && lon >= 55.00 && lon <= 55.70) return 'Dubai'; // Dubai
    if (lat >= 22.40 && lat <= 25.60 && lon >= 51.50 && lon <= 55.35)
      return 'Abu Dhabi'; // Abu Dhabi
    if (lat >= 25.15 && lat <= 25.75 && lon >= 55.35 && lon <= 56.10) return 'Sharjah'; // Sharjah
    if (lat >= 25.35 && lat <= 25.48 && lon >= 55.43 && lon <= 55.62) return 'Ajman'; // Ajman
    if (lat >= 25.50 && lat <= 25.75 && lon >= 55.50 && lon <= 55.90) return 'Umm Al Quwain'; // UAQ
    if (lat >= 25.60 && lat <= 26.40 && lon >= 55.70 && lon <= 56.60)
      return 'Ras Al Khaimah'; // RAK
    if (lat >= 24.95 && lat <= 25.70 && lon >= 56.00 && lon <= 56.60) return 'Fujairah'; // Fujairah
    return null;
  }

  Future<String?> emirateFromGoogle({
    required double lat,
    required double lon,
    required String apiKey,
  }) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lon&key=$apiKey&language=en';

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
              if (code != null) return code; // e.g., DXB
            }
          }
        }
      }
    } catch (e) {
      debugPrint('emirateFromGoogle error: $e');
    }
    return null;
  }

  Future<void> onSaveDraft(BuildContext context) async {
    try {
      await runWithLoadingVoid(() async {
        final req = await _buildAddPassengerRequest(nStatus: 0); // ⬅️ draft
        final result = await CommonRepository.instance.apiAddPassengerQuestionnaire(req);

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
      debugPrint('Passenger save draft error: $e\n$st');
      ToastHelper.showError('An error occurred while saving the draft.', error: e, stack: st);
    }
  }

  Future<AddPassengerRequest> _buildAddPassengerRequest({int nStatus = 1}) async {
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

    int? _intFromQSelection(String qid) {
      final ans = valueOfGlobal(qid);
      if (ans == null) return null;

      // If it's a multi, take the first
      final String s = (ans is List && ans.isNotEmpty ? ans.first : ans).toString().trim();

      // 1) If already numeric, use it
      final n = int.tryParse(s);
      if (n != null) return n;

      // 2) Try find option where LABEL matches -> return its ID as int
      final opts = _optionsForQid(qid);
      final optByLabel = opts.firstWhere(
            (o) => o.label.trim().toLowerCase() == s.toLowerCase(),
        orElse: () => AnswerOption(id: '', label: ''),
      );
      if (optByLabel.id.toString().isNotEmpty) {
        final idNum = int.tryParse(optByLabel.id.toString());
        if (idNum != null) return idNum;
      }

      // 3) Try find option where ID matches string (case-insensitive)
      final optById = opts.firstWhere(
            (o) => o.id.toString().trim().toLowerCase() == s.toLowerCase(),
        orElse: () => AnswerOption(id: '', label: ''),
      );
      if (optById.id.toString().isNotEmpty) {
        final idNum = int.tryParse(optById.id.toString());
        if (idNum != null) return idNum;
      }

      return null;
    }

    // Find a question by id across all current sections
    Question? _questionById(String qid) {
      for (final sec in (sections ?? const [])) {
        for (final q in sec.questions) {
          if (q.id == qid) return q;
        }
      }
      return null;
    }

    int? _borderPurposeId(dynamic rawIdOrLabel) {
      if (rawIdOrLabel == null) return null;
      final s = rawIdOrLabel.toString();
      // If it's already numeric, use it.
      final n = int.tryParse(s);
      if (n != null) return n;

      // Map string IDs (or labels) → numeric codes
      const byId = {
        'commute': 1,
        'biz_trip': 2,
        'school': 3,
        'university': 4,
        'retail': 5,
        'visit': 6,
        'tourism': 7,
        'other': 99,
      };
      if (byId.containsKey(s)) return byId[s];

      // fallback by label (case-insensitive contains)
      final l = s.toLowerCase();
      if (l.contains('commut')) return 1;
      if (l.contains('business')) return 2;
      if (l.contains('school')) return 3;
      if (l.contains('university') || l.contains('college')) return 4;
      if (l.contains('retail') || l.contains('food') || l.contains('entertainment')) return 5;
      if (l.contains('visit')) return 6;
      if (l.contains('touris')) return 7;
      return 99; // other
    }

    // map F7/F15 stay length id -> int
    int? _stayDays(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      if (s == '7plus') return 8; // bucket for "More than 7"
      return int.tryParse(s);
    }

    // multi-select → CSV of LABELS
    String? _labelsCsvFrom(String qid) {
      final ans = valueOfGlobal(qid);
      if (ans == null) return null;

      final ids = (ans is List)
          ? ans.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList()
          : <String>[ans.toString()];

      final labels = ids.map((id) {
        final opt = _optionForSelection(qid, id) ?? AnswerOption(id: id, label: id);
        if (_looksLikeOther(opt, id)) {
          final other = _otherCompanionFor(qid);
          if (other != null && other.isNotEmpty) return 'Other(${other.trim()})';
        }
        return (opt.label.trim().isNotEmpty) ? opt.label.trim() : id;
      }).toList();

      return labels.join(', ');
    }

    String normalizeSurveyType(dynamic raw) {
      // Handle both enum and string cases
      final typeString = raw?.toString().trim().toLowerCase() ?? '';

      switch (typeString) {
        case 'questionnairetype.passengerpetrol':
        case 'passengerpetrol':
          return 'Car (Petrol)';

        case 'questionnairetype.passengerborder':
        case 'passengerborder':
          return 'Car (Border)';

        case 'questionnairetype.bus':
          return 'Bus';

        case 'questionnairetype.airport':
          return 'Airport';

        case 'questionnairetype.hotel':
          return 'Hotel';

        case 'questionnairetype.freightrsi':
        case 'freightrsi':
          return 'Freight (RSI)';

        case 'questionnairetype.statedpreference':
        case 'statedpreference':
          return 'Stated Preference';

        default:
          return raw?.toString() ?? '';
      }
    }

    int _projectIdFor(QuestionnaireType? t) {
      switch (t) {
        case QuestionnaireType.passengerPetrol:
          return 1;
        case QuestionnaireType.passengerBorder:
          return 2;
        case QuestionnaireType.bus:
          return 3;
        case QuestionnaireType.airport:
          return 4;
        case QuestionnaireType.hotel:
          return 5;
      // Not used for passenger flows, but keep a sane default:
        case QuestionnaireType.freightRsi:
        case QuestionnaireType.statedPreference:
        default:
          return 1; // fallback
      }
    }

    // Return the label for a single-select answer (radio/dropdown)
    String? _labelFor(String qid) {
      final ans = valueOfGlobal(qid);
      if (ans == null) return null;

      final id = ans.toString();
      final opt = _optionForSelection(qid, id) ?? AnswerOption(id: id, label: id);
      if (_looksLikeOther(opt, id)) {
        final other = _otherCompanionFor(qid);
        if (other != null && other.isNotEmpty) {
          // Keep capitalized “Other(...)” as you requested.
          return 'Other(${other.trim()})';
        }
      }
      final lbl = opt.label.trim();
      return lbl.isEmpty ? id : lbl;
    }

    // Return the first label from a multiSelect answer
    String? _firstLabelFrom(String qid) {
      final ans = valueOfGlobal(qid);
      if (ans == null) return null;
      final q = _questionById(qid);
      if (q == null || (q.options?.isEmpty ?? true)) {
        // fallback to first raw
        if (ans is List && ans.isNotEmpty) return ans.first?.toString();
        return _asString(ans);
      }
      if (ans is List && ans.isNotEmpty) {
        final firstId = ans.first?.toString();
        final opt = q.options!.firstWhere(
              (o) => o.id.toString() == firstId,
          orElse: () => AnswerOption(id: firstId ?? '', label: firstId ?? ''),
        );
        return opt.label;
      }
      // if not a list, treat as single and map
      return _labelFor(qid);
    }

    dynamic _get(String qid) => valueOfGlobal(qid);

    String? _eitherVal(String a, String b) => _asString(_get(b)) ?? _asString(_get(a));
    String? _eitherLabel(String a, String b) => _labelFor(b) ?? _labelFor(a);

    // ───────── SCREENING ─────────
    final now = DateTime.now();
    final int sessionSeconds = startedAt == null ? 0 : now.difference(startedAt!).inSeconds;
    final int combinedSeconds = _editBaselineSeconds + sessionSeconds;

    final screening = ScreeningPayload(
      dtInterviewStartTime: startedAt?.toIso8601String(),
      dtInterviewEndTime: now.toIso8601String(),
      sTotalTime: _formatMmSs(combinedSeconds),
      sSurveyType: normalizeSurveyType(
        _labelFor('scr_type_select') ?? _asString(_get('scr_type_select')),
      ),
      nCarPresent: _asInt(_get('scr_a5_parked_count')),
      sSetEligibility: _asString(_get('scr_set_eligibility')),
      nCreatedBy: userData?.userId ?? 0,
    );

    // GPS from device
    final deviceLoc = await LocationHelper.getCurrentLocation();
    debugPrint('📍 deviceLoc -> lat=${deviceLoc?.latitude}, lon=${deviceLoc?.longitude}');

    if (deviceLoc?.latitude != null) {
      screening.sLattitude = deviceLoc!.latitude!.toString();
      debugPrint('✅ screening.sLattitude set -> ${screening.sLattitude}');
    }
    if (deviceLoc?.longitude != null) {
      screening.sLongitude = deviceLoc!.longitude!.toString();
      debugPrint('✅ screening.sLongitude set -> ${screening.sLongitude}');
    }

    if (deviceLoc?.latitude != null && deviceLoc?.longitude != null) {
      final lat = deviceLoc!.latitude!;
      final lon = deviceLoc.longitude!;
      String? emirate;

      // try Google first (Dio)
      try {
        debugPrint('🌐 resolving emirate via Google Geocoding for ($lat, $lon)…');
        emirate = await emirateFromGoogle(lat: lat, lon: lon, apiKey: ApiConstants.apiKey);
        debugPrint('🌐 Google result -> $emirate');
      } catch (e, st) {
        debugPrint('❌ emirateFromGoogle error: $e');
        debugPrint('$st');
      }

      // fallback to bbox
      if (emirate == null) {
        debugPrint('🧭 falling back to bbox heuristic…');
        emirate = emirateFromLatLonFallback(lat, lon);
        debugPrint('🧭 bbox result -> $emirate');
      }

      screening.sEmirates = emirate; // may be null if unresolved
      debugPrint('✅ screening.sEmirates set -> ${screening.sEmirates}');
    } else {
      debugPrint('⚠️ no device location; skipping S_Emirates resolution');
    }

    // ───────── DEMOGRAPHICS (labels everywhere) ─────────
    final demographics = DemographicsPayload(
      sGender: _labelFor('demo_b1_gender'),
      sFullName: _labelFor('demo_b0_name'),
      sAge: _labelFor('demo_b2_age'),
      sNationality: _labelFor('demo_b3_nationality'),
      sSuburbs: _labelFor('demo_b4a_home_suburb'),
      sDriverResidency: _labelFor('demo_b4b_residence_country'),
      sMonthlyIncome: _labelFor('demo_b5_income'),
      sOccupation: _labelFor('demo_b6_employment'),
      sPrivateCarAvailability: _labelFor('demo_b7_car_access'),
    );

    // ───────── CATEGORY: PETROL ─────────
    PetrolPayload? petrol;
    if (questionnaireType == QuestionnaireType.passengerPetrol) {
      petrol = PetrolPayload(
        // IDs updated to new C-set
        nTRIPPURP: _asInt(_get('c1_purpose')),
        // ID only
        sOrigin: _toApiLocString(_get('c2_origin')),          // <-- changed
        // map string or address
        dtTripStartTime: _toIso1900(_asString(_get('c3_start_time'))),   // ← changed
        dtTripEndTimeTrip: _toIso1900(_asString(_get('c3_arrival_time'))),// ← changed
        sLastActivity: _labelFor('c4_last_activity'),
        // label
        sDestination: _toApiLocString(_get('c5_destination')), // <-- changed
        // sNextActivity: _labelFor('c6_next_activity'),
        // label
        sODforSP: _labelFor('c7_sp_odpair'),
        // label
        sFrequency: _labelFor('c8_frequency'),
        // label
        sCostTrip: _asString(_get('c9_cost')),
        nNoOfPassenger:
        _asInt(_get('c10_occupancy')) ??
            (() {
              final v = _asString(_get('c10_occupancy'));
              if (v == 'alone') return 1;
              if (v == '5+') return 5;
              return int.tryParse(v ?? '');
            })(),
        sCostSharing: _labelFor('c11_cost_share'),
      );
    }

    BorderPayload? border;
    if (questionnaireType == QuestionnaireType.passengerBorder) {
      border = BorderPayload(
        // D1 — ID only
        nTRIPPURP: _asInt(_get('d1_purpose')),

        // D2 — string/location
        sOrigin: _toApiLocString(_get('d2_origin')),           // <-- changed

        // D3 — ISO or hh:mm; we pass the captured string
        dtTripStartTime: _toIso1900(_asString(_get('d3_start_time'))),      // ← changed
        dtTripEndTimeTrip: _toIso1900(_asString(_get('d3_arrival_time'))),  // ← changed
        // D4 — label
        sLastActivity: _labelFor('d4_last_activity'),

        // D5 — string/location
        sDestination: _toApiLocString(_get('d5_destination')), // <-- changed

        // D6 — label
        // sNextActivity: _labelFor('d6_next_activity'),

        // D7 — label
        sODforSP: _labelFor('d7_sp_odpair'),

        // D8 — label
        sFrequency: _labelFor('d8_frequency'),

        // D9 — number as string
        sCostTrip: _asString(_get('d9_cost')),

        // D10 — int (including buckets)
        nNoOfPassenger:
        _asInt(_get('d10_occupancy')) ??
            (() {
              final v = _asString(_get('d10_occupancy'));
              if (v == 'alone') return 1;
              if (v == '5+') return 5;
              return int.tryParse(v ?? '');
            })(),

        // D11 — label
        sCostSharing: _labelFor('d11_cost_share'),
      );
    }

    AirportPayload? airport;
    if (questionnaireType == QuestionnaireType.airport) {
      final arrived = valueOfGlobal('scr_f1') == 'arrived';

      final vehicleQid = arrived ? 'air_f7' : 'air_f15';
      final ans = valueOfGlobal(vehicleQid);

      // 🔎 dump raw answer + options/capture info
      debugPrint('🚕 [$vehicleQid] raw ans type=${ans.runtimeType} value=$ans');
      final opts = _optionsForQid(vehicleQid);
      debugPrint(
        '🚕 [$vehicleQid] options count=${opts.length} '
            'sample=${opts.take(6).map((o) => '${o.id}:${o.label}').toList()}',
      );

      String? vehicleId;

      if (ans is List) {
        debugPrint('🚕 [$vehicleQid] multiSelect length=${ans.length} values=$ans');
        if (ans.isNotEmpty) {
          final first = ans.first?.toString();
          debugPrint('🚕 [$vehicleQid] first selection="$first"');
          final mapped = _idForLabelPassenger(vehicleQid, first);
          vehicleId = mapped ?? first;
          debugPrint('🚕 [$vehicleQid] mapped="$mapped" -> vehicleId="$vehicleId"');
        } else {
          debugPrint('🚕 [$vehicleQid] empty list — no selection');
        }
      } else if (ans != null) {
        final s = ans.toString();
        debugPrint('🚕 [$vehicleQid] singleSelect="$s"');
        final mapped = _idForLabelPassenger(vehicleQid, s);
        vehicleId = mapped ?? s;
        debugPrint('🚕 [$vehicleQid] mapped="$mapped" -> vehicleId="$vehicleId"');
      } else {
        debugPrint('🚕 [$vehicleQid] no answer selected (null)');
      }

      final vehicleInt = _asInt(vehicleId);
      debugPrint('🚕 [$vehicleQid] parsed int from vehicleId="$vehicleId" -> $vehicleInt');

      final travellerTypeLabel = _labelFor('air_f2'); // handles multi/single internally

      final String? vehicleLabelsCsv = _labelsCsvFrom(vehicleQid);

      airport = AirportPayload(
        // Arrived: F3/F4/F5/F6/F7/F8/F10
        // Leaving: F11/F12/F13/F14/F15/F16/F18
        sAirsideOD: _asString(_get(arrived ? 'air_f3' : 'air_f11')),
        sAirline: _asString(_get(arrived ? 'air_f4' : 'air_f12')),
        sLandsideOD: _asString(_get(arrived ? 'air_f5' : 'air_f13')),
        nTRIPPURP:  _intFromQSelection(arrived ? 'air_f6' : 'air_f14'),
        sVehicleType: vehicleLabelsCsv,
        sTravellerType: travellerTypeLabel,
        sStayDuration: _labelFor(arrived ? 'air_f8' : 'air_f16'),
        sICTravelPattern: _labelsCsvFrom(arrived ? 'air_f9' : 'air_f17'),
        nNoOfPassenger: (() {
          final raw = _asString(_get(arrived ? 'air_f10' : 'air_f18'));
          if (raw == null) return null;
          if (raw == 'alone') return 1;
          if (raw == '1') return 2;
          if (raw == '2') return 3;
          if (raw == '3plus') return 4;
          return int.tryParse(raw);
        })(),
      );

      // Note: F2 traveller type is collected for gating/analytics.
      // If you need to persist it later, add a field to AirportPayload or Screening/Demographics.
    }

    BusPayload? bus;
    if (questionnaireType == QuestionnaireType.bus) {
      final gotOff = valueOfGlobal('scr_e1') == 'got_off';
      final waiting = valueOfGlobal('scr_e1') == 'waiting';

      String? _val(String a, String b) =>
          gotOff ? _asString(_get(a)) : (waiting ? _asString(_get(b)) : null);
      String? _labelsCsv(String qid) => _labelsCsvFrom(qid);

      bus = BusPayload(
        // E2: ID only
        nTRIPPURP: _asInt(_get('bus_e2_purpose')),

        // E3: origin (string/location)
        sOrigin: _toApiLocString(_get('bus_e3_origin')),         // <-- changed

        // E4: start time
        dtTripStartTime: _toIso1900(_asString(_get('bus_e4_start_time'))),     // ← changed
        dtTripEndTimeTrip: _toIso1900(_asString(_get('bus_e4_arrival_time'))), // ← changed

        // E5: last activity (label)
        sLastActivity: _labelFor('bus_e5_last_activity'),

        // E6 (got_off) / E11 (waiting): route
        sBusRoute: _val('bus_e6_route_used', 'bus_e11_route_waiting'),

        // E7 (waiting only): access modes → CSV labels
        sPTAccess: waiting ? _labelsCsv('bus_e7_access_mode') : null,

        // E8: destination (string/location)
        sDestination: _toApiLocString(_get('bus_e8_destination')), // <-- changed

        // E9: next activity (label)
        // sNextActivity: _labelFor('bus_e9_next_activity'),

        // E10 (got_off only): egress modes → CSV labels
        sFinalDestination: gotOff ? _labelsCsv('bus_e10_egress_mode') : null,

        // E12: OD for SP (label)
        sODforSP: _labelFor('bus_e12_od_for_sp'),

        // E13: frequency (label)
        sFrequency: _labelFor('bus_e13_frequency'),

        // E14: open text reason
        sICModeChoice: _asString(_get('bus_e14_ic_mode_reason')),

        // E15: cost
        sCostTrip: _asString(_get('bus_e15_trip_cost')),
      );
    }

    /// live  -> "0"
    String? _hotelStayValue() {
      final raw = valueOfGlobal('hotel_g5_stay_days');
      if (raw == null) return null;
      final id = raw.toString();
      if (id == 'live') return '0';
      if (id == '7plus') return '8';
      return id; // already "1".."7"
    }

    HotelPayload? hotel;
    if (questionnaireType == QuestionnaireType.hotel) {
      // Helper: map G5 id→int; '7plus'→8; 'live'→0

      // Collect G2 selections (labels) as CSV
      final String? destCsv = _labelsCsvFrom('hotel_g2_destinations');

      // G3/G4 are repeated by destination. We’ll gather all chosen labels (order matching G2)
      List<String> _labelsForRepeats(String baseId) {
        final List<String> out = [];
        final g2q = _questionById('hotel_g2_destinations');
        final selectedIds =
            (valueOfGlobal('hotel_g2_destinations') as List?)
                ?.map((e) => e?.toString())
                .whereType<String>()
                .toList() ??
                [];
        for (final id in selectedIds) {
          final qid = '${baseId}__$id';
          final lbl = _labelFor(qid);
          if (lbl != null && lbl.trim().isNotEmpty) out.add(lbl);
        }
        return out;
      }

      // G3 modes may be multi per destination; join each child’s multi as CSV, then flatten
      List<String> _labelsCsvForRepeatsMulti(String baseId) {
        final List<String> out = [];
        final selectedIds =
            (valueOfGlobal('hotel_g2_destinations') as List?)
                ?.map((e) => e?.toString())
                .whereType<String>()
                .toList() ??
                [];
        for (final id in selectedIds) {
          final qid = '${baseId}__$id';
          final lblCsv = _labelsCsvFrom(qid); // existing helper handles multi → CSV of labels
          if (lblCsv != null && lblCsv.trim().isNotEmpty) out.add(lblCsv);
        }
        return out;
      }

      final modesPerDest = _labelsCsvForRepeatsMulti('hotel_g3_mode'); // list of CSV strings
      final durationsPerDest = _labelsForRepeats('hotel_g4_time'); // list of single labels

      // helper: get selected IDs (as strings) for a repeated multi-select q like 'hotel_g3_mode__<destId>'
      List<String> _idCsvListForRepeats(String baseId) {
        final selectedDestIds =
            (valueOfGlobal('hotel_g2_destinations') as List?)
                ?.map((e) => e?.toString())
                .whereType<String>()
                .toList() ??
                const [];

        final out = <String>[];
        for (final destId in selectedDestIds) {
          final qid = '${baseId}__$destId';
          final ans = valueOfGlobal(qid);

          // normalize to list of strings
          final items = (ans is List ? ans : [ans])
              .where((e) => e != null)
              .map((e) => e.toString())
              .where((s) => s.trim().isNotEmpty)
              .toList();

          for (final sel in items) {
            // If already a numeric id, keep it
            final asInt = int.tryParse(sel);
            if (asInt != null) {
              out.add(asInt.toString());
              continue;
            }
            // Otherwise map LABEL -> ID via options
            final opt =
                _optionForSelection(qid, sel) ??
                    _optionsForQid(qid).firstWhere(
                          (o) => o.label.trim().toLowerCase() == sel.trim().toLowerCase(),
                      orElse: () => AnswerOption(id: sel, label: sel),
                    );
            out.add(opt.id.toString());
          }
        }
        return out;
      }

      final vehicleTypeIdStrings = _idCsvListForRepeats('hotel_g3_mode');
      final vehicleTypeIdInts = vehicleTypeIdStrings
          .map((s) => int.tryParse(s))
          .whereType<int>()
          .toList();
      final vehicleTypeCsvIds = vehicleTypeIdInts.isEmpty
          ? null
          : vehicleTypeIdInts.map((n) => n.toString()).join(','); // "1,3,5"

      hotel = HotelPayload(
        // G2 → CSV of destination type labels
        sDestination: destCsv,

        // G3 → spec says “Add in comma separated if multiple”
        // We’ll flatten: join each per-destination CSV as individual items into one CSV
        nVehicleType: vehicleTypeCsvIds,

        // G4 → CSV (one per destination, in the same order as G2)
        sLocDuration: durationsPerDest.isEmpty ? null : durationsPerDest.join(', '),

        // G5 → int (map 7plus→8, live→0)
        sHotelStayDuration: _labelFor('hotel_g5_stay_days'),

        // G6 → int
        // nNoOfTrips: _asInt(valueOfGlobal('hotel_g6_trips_per_day')),
      );
    }

    final bool isEdit = editPassengerId != null;
    final String action = isEdit ? 'update' : 'add';
    final int? passengerId = editPassengerId;

    // Build request (Action + ProjectID included)
    final req = AddPassengerRequest.fromSections(
      nStatus: nStatus,
      action: action,
      // ⬅️ "update" when editing, otherwise "add"
      nPassengerRsiid: passengerId,
      projectId: _projectIdFor(questionnaireType),
      screening: screening,
      demographics: demographics,
      petrol: petrol,
      border: border,
      bus: bus,
      airport: airport,
      hotel: hotel, // ← add this
    );

    return req;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Helpers
  // ───────────────────────────────────────────────────────────────────────────

  QuestionnaireType _mapTypeId(String id) {
    switch (id) {
      case 'passengerPetrol':
        return QuestionnaireType.passengerPetrol;
      case 'passengerBorder':
        return QuestionnaireType.passengerBorder;
      case 'bus':
        return QuestionnaireType.bus;
      case 'airport':
        return QuestionnaireType.airport;
      case 'hotel':
        return QuestionnaireType.hotel;
      case 'statedPreference':
        return QuestionnaireType.statedPreference;
      default:
      // Fallback to a default passenger flow if needed
        return QuestionnaireType.passengerPetrol;
    }
  }

  bool _sectionHasVisibleQuestions(QuestionnaireSection s) {
    final anyVisible = s.questions.any(isVisible);
    if (kDebugMode) {
      final idx = sections?.indexOf(s) ?? -1;
      debugPrint('👀 _sectionHasVisibleQuestions[$idx] "${s.title}" -> $anyVisible');
    }
    return anyVisible;
  }

  // Return all options for a question, incl. catalog/captureConfig sources.
  List<AnswerOption> _optionsForQid(String qid) {
    List<AnswerOption> _fromQuestion(Question? qq) {
      if (qq == null) return const [];

      // explicit options
      final opts = qq.options;
      if (opts != null && opts.isNotEmpty) return opts;

      // catalog
      final cat = qq.catalog;
      if (cat != null) return catalogs[cat.key] ?? const [];

      // captureConfig.items
      final items = qq.captureConfig?['items'];
      if (items is List) {
        final out = <AnswerOption>[];
        for (final it in items) {
          if (it is Map) {
            final id = it['id']?.toString();
            final labelRaw = (it['label'] ?? it['name'] ?? it['title']);
            final label = labelRaw?.toString().trim();
            if (id != null && label != null && label.isNotEmpty) {
              out.add(AnswerOption(id: id, label: label));
            }
          }
        }
        if (out.isNotEmpty) return out;
      }

      return const [];
    }

    // 1) Try the exact qid (clone or base)
    final q = _q(qid);
    var out = _fromQuestion(q);
    if (out.isNotEmpty) return out;

    // 2) If it's a repeated clone, fall back to the base question's options
    final sep = qid.indexOf('__');
    if (sep != -1) {
      final baseId = qid.substring(0, sep);
      out = _fromQuestion(_q(baseId));
      if (out.isNotEmpty) return out;
    }

    return const [];
  }

  AnswerOption? _optionForSelection(String qid, String id) {
    for (final o in _optionsForQid(qid)) {
      if (o.id.toString() == id) return o;
    }
    return null;
  }

  bool _looksLikeOther(AnswerOption? opt, String id) {
    if (opt?.isOther == true) return true;
    final up = id.trim().toUpperCase();
    return up == 'OTHER' || up == '99';
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
    try {
      _clearAllState();
    } catch (_) {}
    super.dispose();
  }
}


extension _LocationBinding on PassengerQuestionnaireNotifier {
  /// Parse whatever came from API into a normalized Map for the UI widget.
  Map<String, dynamic>? _normalizeLocForUi(dynamic raw) {
    final lv = LocationValue.fromAny(raw);
    return lv?.toMap();
  }

  /// Convert whatever is stored in answers back into API string.
  String? _toApiLocString(dynamic stored) {
    final lv = LocationValue.fromAny(stored);
    return lv?.toApiString();
  }
}

class LocationValue {
  final double lat;
  final double lng;
  final String? label; // optional address / place name

  const LocationValue({required this.lat, required this.lng, this.label});

  Map<String, dynamic> toMap() => {"lat": lat, "lng": lng, if (label != null) "label": label};

  String toApiString() => '$lat,$lng'; // change if your API wants another format
  String toDisplayString() => label ?? '$lat, $lng';

  static LocationValue? fromAny(dynamic v) {
    if (v == null) return null;

    // Already normalized map
    if (v is Map) {
      final lat = _asDouble(v['lat']) ?? _asDouble(v['latitude']);
      final lng = _asDouble(v['lng']) ?? _asDouble(v['lon']) ?? _asDouble(v['longitude']);
      if (lat != null && lng != null) {
        return LocationValue(lat: lat, lng: lng, label: v['label']?.toString());
      }
      // Sometimes nested (e.g., {"location":{"lat":..,"lng":..}})
      final loc = v['location'];
      if (loc is Map) {
        final lat2 = _asDouble(loc['lat']) ?? _asDouble(loc['latitude']);
        final lng2 = _asDouble(loc['lng']) ?? _asDouble(loc['lon']) ?? _asDouble(loc['longitude']);
        if (lat2 != null && lng2 != null) {
          return LocationValue(lat: lat2, lng: lng2, label: v['label']?.toString());
        }
      }
    }

    // String cases (your broken {lat: .., lng: ..,)
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;

      // Try clean JSON first
      try {
        final m = jsonDecode(s);
        final lv = LocationValue.fromAny(m);
        if (lv != null) return lv;
      } catch (_) {/*continue*/}

      // Try "lat,lng"
      final csv = RegExp(r'^\s*(-?\d+(\.\d+)?)\s*,\s*(-?\d+(\.\d+)?)\s*$');
      final mCsv = csv.firstMatch(s);
      if (mCsv != null) {
        final lat = double.tryParse(mCsv.group(1)!);
        final lng = double.tryParse(mCsv.group(3)!);
        if (lat != null && lng != null) return LocationValue(lat: lat, lng: lng);
      }

      // Try sloppy "{lat: xx, lng: yy, ...}" (missing brace/extra commas ok)
      final latRe = RegExp(r'lat\s*:\s*(-?\d+(\.\d+)?)', caseSensitive: false);
      final lngRe = RegExp(r'lng\s*:\s*(-?\d+(\.\d+)?)', caseSensitive: false);
      final mLat = latRe.firstMatch(s);
      final mLng = lngRe.firstMatch(s);
      if (mLat != null && mLng != null) {
        final lat = double.tryParse(mLat.group(1)!);
        final lng = double.tryParse(mLng.group(1)!);
        if (lat != null && lng != null) return LocationValue(lat: lat, lng: lng);
      }
    }

    return null;
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

extension _LocAnswerEnrichment on PassengerQuestionnaireNotifier {
  Future<void> _enrichLocationLabelForQid(String qid) async {
    // read current
    final raw = valueOfGlobal(qid);
    final lv = LocationValue.fromAny(raw);
    if (lv == null) return;
    if (lv.label != null && lv.label!.trim().isNotEmpty) return;

    final label = await LocationLabeler.instance.labelFor(
      lat: lv.lat,
      lng: lv.lng,
      googleApiKey: ApiConstants.apiKey, // already used elsewhere in your file
    );
    if (label == null || label.trim().isEmpty) return;

    // build new value with label
    final updated = {"lat": lv.lat, "lng": lv.lng, "label": label};

    // find the section that holds this question, then update both section + __global
    QuestionnaireSection? sec;
    for (final s in (sections ?? const [])) {
      if (s.questions.any((q) => q.id == qid)) {
        sec = s;
        break;
      }
    }
    if (sec != null) {
      updateAnswer(sec.id, qid, updated);
    }
    updateAnswer('__global', qid, updated);

    // also set it on the question model so widgets see it immediately
    final q = _q(qid);
    if (q != null) q.answer = updated;

    notifyListeners();
  }
}

class LocationLabeler {
  LocationLabeler._();
  static final LocationLabeler instance = LocationLabeler._();

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // very small in-memory cache: "lat,lng" -> "label"
  final Map<String, String> _cache = <String, String>{};

  Future<String?> labelFor({
    required double lat,
    required double lng,
    required String googleApiKey,
  }) async {
    final key = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
    if (_cache.containsKey(key)) return _cache[key];

    try {
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$googleApiKey&language=en';
      final resp = await _dio.get(url);
      if (resp.statusCode != 200 || resp.data == null) return null;

      final data = resp.data is Map<String, dynamic>
          ? resp.data as Map<String, dynamic>
          : jsonDecode(resp.data.toString());

      if (data['status'] != 'OK') return null;
      final results = (data['results'] as List?) ?? const [];

      // 1) Prefer a "point of interest" / premise / street_address if present
      String? pickFormatted(Map r) {
        final types = (r['types'] as List?)?.cast<String>() ?? const [];
        if (types.contains('point_of_interest') ||
            types.contains('premise') ||
            types.contains('street_address') ||
            types.contains('route')) {
          return r['formatted_address']?.toString();
        }
        return null;
      }

      String? formatted;
      for (final r in results) {
        formatted = pickFormatted(r as Map) ?? formatted;
      }
      // 2) Fallback to the first formatted_address
      formatted ??= results.isNotEmpty ? (results.first as Map)['formatted_address']?.toString() : null;

      if (formatted != null && formatted.trim().isNotEmpty) {
        _cache[key] = formatted;
      }
      return formatted;
    } catch (_) {
      return null;
    }
  }
}
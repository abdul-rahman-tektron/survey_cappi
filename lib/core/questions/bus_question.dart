// bus_stop_questions.dart (spec-aligned to Section E)
// Shows the right subset based on E1 (alighted vs waiting)

import 'package:srpf/core/questions/model/question_model.dart';

final _kPurpose = <AnswerOption>[
  AnswerOption(id: 'commute',  label: 'Commuting'),
  AnswerOption(id: 'school',   label: 'School / Education'),
  AnswerOption(id: 'business', label: 'Business'),
  AnswerOption(id: 'tourism',  label: 'Tourism / Leisure'),
  AnswerOption(id: 'vff',      label: 'Visiting Friends / Family'),
  AnswerOption(id: 'shopping', label: 'Shopping'),
  AnswerOption(id: 'other',    label: 'Other (please specify)', isOther: true),
];

final _kActivity = <AnswerOption>[
  AnswerOption(id: 'home',        label: 'home'),
  AnswerOption(id: 'holidayhome', label: 'holiday home'),
  AnswerOption(id: 'work',        label: 'work (usual workplace)'),
  AnswerOption(id: 'business',    label: 'business (not my usual place of work)'),
  AnswerOption(id: 'school',      label: 'school (including drop off/pick up)'),
  AnswerOption(id: 'university',  label: 'university (including drop off/pick up)'),
  AnswerOption(id: 'visit',       label: 'visiting friends/family'),
  AnswerOption(id: 'shopping',    label: 'shopping'),
  AnswerOption(id: 'tourism',     label: 'tourism'),
  AnswerOption(id: 'rfe',         label: 'other leisure (retail/food/entertainment)'),
  AnswerOption(id: 'other',       label: 'other (please state)', isOther: true),
];

final _kAccessEgress = <AnswerOption>[
  AnswerOption(id: 'walk',       label: 'Walk'),
  AnswerOption(id: 'anotherbus', label: 'Another bus'),
  AnswerOption(id: 'car',        label: 'Car (owned or hired)'),
  AnswerOption(id: 'car_drop_off',        label: 'Car drop off'),
  AnswerOption(id: 'taxi',       label: 'Taxi'),
  AnswerOption(id: 'careemuber', label: 'Careem / Uber'),
  AnswerOption(id: 'chauffeur',  label: 'Private chauffeur or similar'),
  AnswerOption(id: 'metro',      label: 'Metro'),
  AnswerOption(id: 'active',     label: 'Active modes (eg. bike, scooter)'),
  AnswerOption(id: 'other',      label: 'Other', isOther: true),
];

final _kAccessEgressDest = <AnswerOption>[
  AnswerOption(id: 'walk',       label: 'Walk'),
  AnswerOption(id: 'anotherbus', label: 'Another bus'),
  AnswerOption(id: 'car',        label: 'Car (owned or hired)'),
  AnswerOption(id: 'car_pick_up',        label: 'Car pick up'),
  AnswerOption(id: 'taxi',       label: 'Taxi'),
  AnswerOption(id: 'careemuber', label: 'Careem / Uber'),
  AnswerOption(id: 'chauffeur',  label: 'Private chauffeur or similar'),
  AnswerOption(id: 'metro',      label: 'Metro'),
  AnswerOption(id: 'active',     label: 'Active modes (eg. bike, scooter)'),
  AnswerOption(id: 'other',      label: 'Other', isOther: true),
];

final _kFrequency = <AnswerOption>[
  AnswerOption(id: 'lt_month', label: 'Less than once per month'),
  AnswerOption(id: 'month',    label: 'Once per month'),
  AnswerOption(id: '1w',       label: '1 trip per week'),
  AnswerOption(id: '2w',       label: '2 trips per week'),
  AnswerOption(id: '3w',       label: '3 trips per week'),
  AnswerOption(id: '4w',       label: '4 trips per week'),
  AnswerOption(id: '5w',       label: '5+ trips per week'),
];

/// Helper: 15-minute time list (hh:mm AM/PM)
List<AnswerOption> _time15Options() {
  final out = <AnswerOption>[];
  for (int h = 0; h < 24; h++) {
    for (final m in [0, 15, 30, 45]) {
      final hour12 = ((h % 12) == 0) ? 12 : (h % 12);
      final mm = m.toString().padLeft(2, '0');
      final ampm = h < 12 ? 'AM' : 'PM';
      final label = '$hour12:$mm $ampm';
      out.add(AnswerOption(id: label, label: label));
    }
  }
  return out;
}

final QuestionnaireSection busStopsSection = QuestionnaireSection(
  id: 'bus_e',
  title: 'Intercity Bus \nStops',
  questions: [
    // E2 — Primary purpose (ID only)
    Question(
      id: 'bus_e2_purpose',
      question: 'What is your primary purpose for travel?',
      type: QuestionType.radio,
      allowOtherOption: true,
      catalog: CatalogRef('trip_purposes'),
      validation: QuestionValidation(required: true),
      captureConfig: const {'apiKey': 'N_TRIPPURP'}, // ID only
    ),

    // E3 — Origin (location)
    Question(
      id: 'bus_e3_origin',
      question: 'Where are you travelling from?',
      type: QuestionType.location,
      validation: QuestionValidation(required: true),
      captureConfig: const {'apiKey': 'S_Origin'},
    ),

    // E4 — Trip start time (dropdown hh:mm)
    Question(
      id: 'bus_e4_start_time',
      question: 'What time did you start your trip?',
      type: QuestionType.time,                 // ← use time picker
      placeholder: 'Select time',              // optional
      validation: QuestionValidation(required: true),
      captureConfig: const {
        'apiKey': 'Dt_TripStartTime',

      },
    ),

    Question(
      id: 'bus_e4_arrival_time',
      question: 'What time will you arrive at your destination?',
      type: QuestionType.time,
      placeholder: 'Select time',
      validation: QuestionValidation(required: true),
      captureConfig: const {
        'apiKey': 'Dt_TripEndTimeTrip',
        'minFromQuestion': 'bus_e4_start_time',
      },
    ),

    // E5 — Last activity before this trip
    Question(
      id: 'bus_e5_last_activity',
      question: 'What was your last activity before this trip?',
      type: QuestionType.radio,
      options: _kActivity,
      allowOtherOption: true,
      validation: QuestionValidation(required: true),
      captureConfig: const {'apiKey': 'S_LastActivity'},
    ),

    // E6 — Route used (if alighted)
    Question(
      id: 'bus_e6_route_used',
      question: 'Which bus route did you use to get to this bus station?',
      type: QuestionType.openText,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'scr_e1', op: Operator.equals, value: 'got_off'),
      ]),
      validation: QuestionValidation(required: true, minLength: 1),
      captureConfig: const {'apiKey': 'S_BusRoute'},
    ),

    // E7 — Access mode (if waiting)
    Question(
      id: 'bus_e7_access_mode',
      question: 'How did you get to this bus station?',
      type: QuestionType.multiSelect,
      options: _kAccessEgress,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'scr_e1', op: Operator.equals, value: 'waiting'),
      ]),
      validation: QuestionValidation(required: true, minSelections: 1),
      captureConfig: const {
        'apiKey': 'S_PTAccess',
        'apiJoin': 'comma',
        'apiUseLabel': true,
      },
    ),

    // E8 — Final destination after station
    Question(
      id: 'bus_e8_destination',
      question: 'Where are you travelling to when you leave this bus station (your final destination for this trip)?',
      type: QuestionType.location,
      validation: QuestionValidation(required: true),
      captureConfig: const {'apiKey': 'S_Destination'},
    ),

    // E9 — Next activity at destination
    // Question(
    //   id: 'bus_e9_next_activity',
    //   question: 'What is your next activity when you reach your destination?',
    //   type: QuestionType.radio,
    //   options: _kActivity,
    //   allowOtherOption: true,
    //   validation: QuestionValidation(required: true),
    //   captureConfig: const {'apiKey': 'S_NextActivity'},
    // ),

    // E10 — Egress mode (if alighted)
    Question(
      id: 'bus_e10_egress_mode',
      question: 'How will you get to your final destination?',
      type: QuestionType.multiSelect,
      options: _kAccessEgressDest,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'scr_e1', op: Operator.equals, value: 'got_off'),
      ]),
      validation: QuestionValidation(required: true, minSelections: 1),
      allowOtherOption: true,
      captureConfig: const {
        'apiKey': 'S_FinalDestination',
        'apiJoin': 'comma',
        'apiUseLabel': true,
      },
    ),

    // E11 — Route waiting for (if waiting)
    Question(
      id: 'bus_e11_route_waiting',
      question: 'Which bus route are you waiting for?',
      type: QuestionType.openText,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'scr_e1', op: Operator.equals, value: 'waiting'),
      ]),
      validation: QuestionValidation(required: true, minLength: 1),
      captureConfig: const {'apiKey': 'S_BusRoute'},
    ),

    // E12 — OD for SP (VALUE/label)
    Question(
      id: 'bus_e12_od_for_sp',
      question: 'Please select if the respondent is travelling between these two cities:',
      type: QuestionType.dropdown,
      catalog: CatalogRef('sp_od_pairs'),
      validation: QuestionValidation(required: true),
      captureConfig: const {
        'apiKey': 'S_ODforSP',
        'apiUseLabel': true,
      },
    ),

    // E13 — Frequency
    Question(
      id: 'bus_e13_frequency',
      question: 'How frequently do you do this same trip?',
      type: QuestionType.radio,
      options: _kFrequency,
      validation: QuestionValidation(required: true),
      captureConfig: const {'apiKey': 'S_Frequency'},
    ),

    // E14 — IC mode choice reason (open)
    Question(
      id: 'bus_e14_ic_mode_reason',
      question: 'Why do you choose to use the bus to travel between these cities?',
      type: QuestionType.openText,
      captureConfig: const {'apiKey': 'S_ICModeChoice'},
    ),

    // E15 — Trip cost
    Question(
      id: 'bus_e15_trip_cost',
      question:
      'What is the approximate cost of this trip, one-way? If you took multiple modes, please sum the total cost (AED).',
      type: QuestionType.number,
      validation: QuestionValidation(minValue: 0, maxValue: 1000000),
      captureConfig: const {'apiKey': 'S_CostTrip'},
    ),
  ],
);
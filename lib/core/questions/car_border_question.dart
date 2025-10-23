// border_crossing_question.dart
import 'package:srpf/core/questions/model/question_model.dart';

/// Shared lists (reused with Petrol)
const _kPurposePrimary = <AnswerOption>[
  AnswerOption(id: '1',  label: 'Commuting'),
  AnswerOption(id: '3',  label: 'School / Education'),
  AnswerOption(id: '2',  label: 'Business'),
  AnswerOption(id: '7',  label: 'Tourism / Leisure'),
  AnswerOption(id: '6',  label: 'Visiting Friends / Family'),
  AnswerOption(id: '5',  label: 'Shopping'),
  AnswerOption(id: '99', label: 'Other (please specify)', isOther: true),
];

const _kActivity = <AnswerOption>[
  AnswerOption(id: 'home',          label: 'home'),
  AnswerOption(id: 'holiday_home',  label: 'holiday home'),
  AnswerOption(id: 'work_usual',    label: 'work (usual workplace)'),
  AnswerOption(id: 'work_biz',      label: 'business (not my usual place of work)'),
  AnswerOption(id: 'school',        label: 'school (including drop off/pick up)'),
  AnswerOption(id: 'university',    label: 'university (including drop off/pick up)'),
  AnswerOption(id: 'visit',         label: 'visiting friends/family'),
  AnswerOption(id: 'shopping',      label: 'shopping'),
  AnswerOption(id: 'tourism',       label: 'tourism'),
  AnswerOption(id: 'rfe',           label: 'other leisure (retail/food/entertainment)'),
  AnswerOption(id: 'other',         label: 'other (please state)', isOther: true),
];

// const _kODPairsForSP = <AnswerOption>[
//   AnswerOption(id: 'auh_ruwais', label: 'Abu Dhabi and Al Ruwais'),
//   AnswerOption(id: 'auh_dxb',    label: 'Abu Dhabi and Dubai'),
//   AnswerOption(id: 'auh_fjr',    label: 'Abu Dhabi and Fujairah'),
//   AnswerOption(id: 'auh_shj',    label: 'Abu Dhabi and Sharjah'),
//   AnswerOption(id: 'dxb_shj',    label: 'Dubai and Sharjah'),
//   AnswerOption(id: 'dxb_fjr',    label: 'Dubai and Fujairah'),
//   AnswerOption(id: 'none',       label: 'None of the above'),
// ];

const _kFrequency = <AnswerOption>[
  AnswerOption(id: 'lt_month', label: 'Less than once per month'),
  AnswerOption(id: '1_month',  label: 'Once per month'),
  AnswerOption(id: '1_wk',     label: '1 trip per week'),
  AnswerOption(id: '2_wk',     label: '2 trips per week'),
  AnswerOption(id: '3_wk',     label: '3 trips per week'),
  AnswerOption(id: '4_wk',     label: '4 trips per week'),
  AnswerOption(id: '5p_wk',    label: '5+ trips per week'),
];

const _kOccupancy = <AnswerOption>[
  AnswerOption(id: 'alone', label: 'Travelling alone'),
  AnswerOption(id: '2',     label: '2'),
  AnswerOption(id: '3',     label: '3'),
  AnswerOption(id: '4',     label: '4'),
  AnswerOption(id: '5+',    label: '5+'),
];

const _kCostShare = <AnswerOption>[
  AnswerOption(id: 'no',      label: 'No – I’m paying the full cost'),
  AnswerOption(id: 'equal',   label: 'Yes – we are splitting the cost equally'),
  AnswerOption(id: 'unequal', label: 'Yes – we are splitting the cost unequally'),
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

/// ─────────────────────────────────────────────────────────────────────────
/// D. BORDER CROSSINGS (new 9+2 format)
/// Maps 1:1 to the doc’s D1–D11 fields
/// ─────────────────────────────────────────────────────────────────────────
final QuestionnaireSection borderCrossingSection = QuestionnaireSection(
  id: 'border_d',
  title: 'Border \nCrossings',
  questions: [
    // D1 — Primary purpose → N_TRIPPURP (ID only)
    Question(
      id: 'd1_purpose',
      question: 'What is your primary purpose for travel?',
      type: QuestionType.radio,
      options: _kPurposePrimary,
      catalog: CatalogRef('trip_purposes'),
      allowOtherOption: true,
      validation: QuestionValidation(required: true),
      captureConfig: const {'apiKey': 'N_TRIPPURP'},
    ),

    // D2 — Origin (map/list) → S_Origin
    Question(
      id: 'd2_origin',
      question: 'Where are you travelling from?',
      type: QuestionType.location,
      captureConfig: const {
        'mode': 'map',
        'requireCoordinates': true,
        'apiKey': 'S_Origin',
      },
      validation: QuestionValidation(required: true),
    ),

    // D3 — Trip start time → Dt_TripStartTime
    Question(
      id: 'd3_start_time',
      question: 'What time did you start your trip?',
      type: QuestionType.time,                 // ← use time picker
      placeholder: 'Select time',              // optional
      validation: QuestionValidation(required: true),
      captureConfig: const {
        'apiKey': 'Dt_TripStartTime',
      },
    ),

    Question(
      id: 'd3_arrival_time',
      question: 'What time will you arrive at your destination?',
      type: QuestionType.time,
      placeholder: 'Select time',
      validation: QuestionValidation(required: true),
      captureConfig: const {
        'apiKey': 'Dt_TripEndTimeTrip',
        'minFromQuestion': 'd3_start_time',
      },
    ),

    // D4 — Last activity → S_LastActivity
    Question(
      id: 'd4_last_activity',
      question: 'What was your last activity before this trip?',
      type: QuestionType.radio,
      options: _kActivity,
      allowOtherOption: true,
      validation: QuestionValidation(required: true),
      captureConfig: const {'apiKey': 'S_LastActivity'},
    ),

    // D5 — Destination (map/list) → S_Destination
    Question(
      id: 'd5_destination',
      question: 'Where are you travelling to?',
      type: QuestionType.location,
      captureConfig: const {
        'mode': 'map',
        'requireCoordinates': true,
        'apiKey': 'S_Destination',
      },
      validation: QuestionValidation(required: true),
    ),

    // D6 — Next activity → S_NextActivity
    // Question(
    //   id: 'd6_next_activity',
    //   question: 'What is your next activity when you reach your destination?',
    //   type: QuestionType.radio,
    //   options: _kActivity,
    //   allowOtherOption: true,
    //   validation: QuestionValidation(required: true),
    //   captureConfig: const {'apiKey': 'S_NextActivity'},
    // ),

    // D7 — OD for SP (surveyor) → S_ODforSP
    Question(
      id: 'd7_sp_odpair',
      question: 'Please select if the respondent is travelling between these two cities:',
      type: QuestionType.dropdown,
      catalog: CatalogRef('sp_od_pairs'),
      validation: QuestionValidation(required: true),
      captureConfig: const {'apiKey': 'S_ODforSP'},
    ),

    // D8 — Frequency → S_Frequency
    Question(
      id: 'd8_frequency',
      question: 'How frequently do you do this same trip?',
      type: QuestionType.radio,
      options: _kFrequency,
      validation: QuestionValidation(required: true),
      captureConfig: const {'apiKey': 'S_Frequency'},
    ),

    // D9 — Trip cost → S_CostTrip
    Question(
      id: 'd9_cost',
      question:
      'What is the approximate cost of this trip, one-way? Please include the cost of tolls and fuels if applicable.',
      type: QuestionType.number,
      validation: QuestionValidation(required: true, minValue: 0, maxValue: 1000000),
      captureConfig: const {'apiKey': 'S_CostTrip'},
    ),

    // D10 — Occupancy (optional) → N_NoOfPassenger
    Question(
      id: 'd10_occupancy',
      question: 'Number of people in vehicle, including driver?',
      type: QuestionType.radio,
      options: _kOccupancy,
      captureConfig: const {
        'apiKey': 'N_NoOfPassenger',
        'apiMap': {'alone': 1, '2': 2, '3': 3, '4': 4, '5+': 5},
      },
    ),

    // D11 — Cost sharing (optional; visible if not alone) → S_CostSharing
    Question(
      id: 'd11_cost_share',
      question: 'Are you sharing the cost of your trip with others in your vehicle?',
      type: QuestionType.radio,
      options: _kCostShare,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'd10_occupancy', op: Operator.notEquals, value: 'alone'),
      ]),
      captureConfig: const {'apiKey': 'S_CostSharing'},
    ),
  ],
);
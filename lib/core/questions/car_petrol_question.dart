// passenger_petrol_questions.dart
import 'package:srpf/core/questions/model/question_model.dart';

/// ---------- Shared option sets from the document ----------

final _kPrimaryPurpose = <AnswerOption>[
  AnswerOption(id: '1',  label: 'Commuting'),
  AnswerOption(id: '2',  label: 'School / Education'),
  AnswerOption(id: '3',  label: 'Business'),
  AnswerOption(id: '4',  label: 'Tourism / Leisure'),
  AnswerOption(id: '5',  label: 'Visiting Friends / Family'),
  AnswerOption(id: '6',  label: 'Shopping'),
  AnswerOption(id: '99', label: 'Other (please specify)', isOther: true),
];

final _kActivityTypes = <AnswerOption>[
  AnswerOption(id: 'home',         label: 'home'),
  AnswerOption(id: 'holiday_home', label: 'holiday home'),
  AnswerOption(id: 'work_usual',   label: 'work (usual workplace)'),
  AnswerOption(id: 'business',     label: 'business (not my usual place of work)'),
  AnswerOption(id: 'school',       label: 'school (including drop off/pick up)'),
  AnswerOption(id: 'university',   label: 'university (including drop off/pick up)'),
  AnswerOption(id: 'visiting',     label: 'visiting friends/family'),
  AnswerOption(id: 'shopping',     label: 'shopping'),
  AnswerOption(id: 'tourism',      label: 'tourism'),
  AnswerOption(id: 'rfe',          label: 'other leisure (retail/food/entertainment)'),
  AnswerOption(id: 'other',        label: 'other (please state)', isOther: true),
];


final _kFrequency = <AnswerOption>[
  AnswerOption(id: 'lt_month', label: 'Less than once per month'),
  AnswerOption(id: 'month',    label: 'Once per month'),
  AnswerOption(id: '1pw',      label: '1 trip per week'),
  AnswerOption(id: '2pw',      label: '2 trips per week'),
  AnswerOption(id: '3pw',      label: '3 trips per week'),
  AnswerOption(id: '4pw',      label: '4 trips per week'),
  AnswerOption(id: '5pw',      label: '5+ trips per week'),
];

final _kOccupancy = <AnswerOption>[
  AnswerOption(id: 'alone', label: 'Travelling alone'),
  AnswerOption(id: '2',     label: '2'),
  AnswerOption(id: '3',     label: '3'),
  AnswerOption(id: '4',     label: '4'),
  AnswerOption(id: '5+',    label: '5+'),
];

final _kCostShare = <AnswerOption>[
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
/// C. PETROL STATIONS SET  (updated to match the new doc)
/// ─────────────────────────────────────────────────────────────────────────
final QuestionnaireSection petrolSectionC = QuestionnaireSection(
  id: 'petrol_c',
  title: 'Petrol \nStations',
  questions: [
    // C1 — Primary purpose → N_TRIPPURP (ID ONLY)
    Question(
      id: 'c1_purpose',
      question: 'What is your primary purpose for travel?',
      type: QuestionType.radio,
      options: _kPrimaryPurpose,
      catalog: CatalogRef('trip_purposes'), // (still supports API master #2)
      allowOtherOption: true,
      validation: QuestionValidation(required: true),
      captureConfig: const {
        // NOTE: we will submit the numeric ID (string -> int in payload builder).
      },
    ),

    // C2 — Origin (prefilled list OR map). We'll keep map capture with lat/lon.
    Question(
      id: 'c2_origin',
      question: 'Where are you travelling from?',
      type: QuestionType.location,
      captureConfig: const {
        'mode': 'map',
        'requireCoordinates': false,
        'apiKey': 'S_Origin', // you can stringify as address or "lat,lon"
      },
      validation: QuestionValidation(required: true),
    ),

    // C3 — Trip start time (15-minute increments)
    Question(
      id: 'c3_start_time',
      question: 'What time did you start your trip?',
      type: QuestionType.time,                 // ← use time picker
      placeholder: 'Select time',              // optional
      validation: QuestionValidation(required: true),
      captureConfig: const {
        'apiKey': 'Dt_TripStartTime',
      },
    ),

    Question(
      id: 'c3_arrival_time',
      question: 'What time will you arrive at your destination?',
      type: QuestionType.time,
      placeholder: 'Select time',
      validation: QuestionValidation(required: true),
      captureConfig: const {
        'apiKey': 'Dt_TripEndTimeTrip',
        'minFromQuestion': 'c3_start_time',
      },
    ),

    // C4 — Last activity before this trip → label
    Question(
      id: 'c4_last_activity',
      question: 'What was your last activity before this trip?',
      type: QuestionType.radio,
      options: _kActivityTypes,
      allowOtherOption: true,
      validation: QuestionValidation(required: true),
      captureConfig: const {
        'apiKey': 'S_LastActivity',
      },
    ),

    // C5 — Destination (prefilled list OR map). Keep map capture.
    Question(
      id: 'c5_destination',
      question: 'Where are you travelling to?',
      type: QuestionType.location,
      captureConfig: const {
        'mode': 'map',
        'requireCoordinates': false,
        'apiKey': 'S_Destination',
      },
      validation: QuestionValidation(required: true),
    ),

    // C6 — Next activity at destination → label
    // Question(
    //   id: 'c6_next_activity',
    //   question: 'What is your next activity when you reach your destination?',
    //   type: QuestionType.radio,
    //   options: _kActivityTypes,
    //   allowOtherOption: true,
    //   validation: QuestionValidation(required: true),
    //   captureConfig: const {
    //     'apiKey': 'S_NextActivity',
    //   },
    // ),

    // C7 — SURVEYOR: OD for SP (single choice)
    Question(
      id: 'c7_sp_odpair',
      question: 'Is the respondent travelling between these two cities?',
      type: QuestionType.dropdown,
      catalog: CatalogRef('sp_od_pairs'), // API master #23
      validation: QuestionValidation(required: true),
      captureConfig: const {
        'apiKey': 'S_ODforSP',
      },
    ),

    // C8 — Frequency of same trip
    Question(
      id: 'c8_frequency',
      question: 'How frequently do you do this same trip?',
      type: QuestionType.radio,
      options: _kFrequency,
      validation: QuestionValidation(required: true),
      captureConfig: const {
        'apiKey': 'S_Frequency', // NEW suggested key
      },
    ),

    // C9 — Trip cost (open text – cost in AED)
    Question(
      id: 'c9_cost',
      question:
      'What is the approximate cost of this trip, one-way? Please include tolls and fuels if applicable.',
      type: QuestionType.number, // (Open text per document)
      validation: QuestionValidation(required: true, minLength: 1, ),
      captureConfig: const {
        'apiKey': 'S_CostTrip',
        'suffix': 'AED',
      },
    ),

    // C10 — SURVEYOR: Number of people incl. driver (or ask if at petrol station)
    Question(
      id: 'c10_occupancy',
      question: 'Number of people in vehicle, including driver',
      type: QuestionType.radio,
      options: _kOccupancy,
      captureConfig: const {
        'apiKey': 'N_NoOfPassenger',
        'apiMap': {
          'alone': 1,
          '2': 2,
          '3': 3,
          '4': 4,
          '5+': 5,
        },
      },
      validation: QuestionValidation(required: true),
    ),

    // C11 — Cost sharing (if not alone)
    Question(
      id: 'c11_cost_share',
      question: 'Are you sharing the cost of your trip with others in your vehicle?',
      type: QuestionType.radio,
      options: _kCostShare,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'c10_occupancy', op: Operator.notEquals, value: 'alone'),
      ]),
      captureConfig: const {
        'apiKey': 'S_CostSharing',
      },
    ),
  ],
);
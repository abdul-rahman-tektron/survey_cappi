// screening_sections.dart
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/utils/enums.dart';

/// A3 — SURVEYOR TO COMPLETE: Type of survey (list used on the init screen)
const surveyTypeOptions = <AnswerOption>[
  AnswerOption(id: 'passengerPetrol',  label: 'Car Driver - Petrol Station'),
  AnswerOption(id: 'passengerBorder',  label: 'Car Driver - Border Crossing'),
  AnswerOption(id: 'bus',              label: 'Public Transport - Intercity Bus Stop'),
  AnswerOption(id: 'airport',          label: 'Airport'),
  AnswerOption(id: 'hotel',            label: 'Hotels'),
];

String _typeIdFor(QuestionnaireType t) {
  switch (t) {
    case QuestionnaireType.passengerPetrol:  return 'passengerPetrol';
    case QuestionnaireType.passengerBorder:  return 'passengerBorder';
    case QuestionnaireType.bus:              return 'bus';
    case QuestionnaireType.airport:          return 'airport';
    case QuestionnaireType.hotel:            return 'hotel';
    case QuestionnaireType.freightRsi:       return 'freightRsi';
    case QuestionnaireType.statedPreference:
      throw UnimplementedError();
  }
}

String _typeLabelFor(QuestionnaireType t) {
  switch (t) {
    case QuestionnaireType.passengerPetrol:  return 'Passenger vehicle RSI (petrol station)';
    case QuestionnaireType.passengerBorder:  return 'Passenger vehicle RSI (border crossing)';
    case QuestionnaireType.bus:              return 'Bus station';
    case QuestionnaireType.airport:          return 'Airport';
    case QuestionnaireType.hotel:            return 'Hotel';
    case QuestionnaireType.freightRsi:       return 'RSI Survey';
    case QuestionnaireType.statedPreference:
      throw UnimplementedError();
  }
}

/// Section A — Screening (for the chosen flow)
/// Includes a HIDDEN echo of the selected type under id `scr_type_select`
/// so any later `visibleIf` rules that depend on it still work after the
/// init section is removed. Adds apiKey tags for backend mapping.
QuestionnaireSection screeningSectionFor(QuestionnaireType type, {bool isEdit = false}) {
  final typeId = _typeIdFor(type);
  final typeLabel = _typeLabelFor(type);

  final qs = <Question>[
    // ─────────────────────────────────────────────────────────
    // Hidden auto-captures for API mapping (screening meta)
    // ─────────────────────────────────────────────────────────

    // Start time → Dt_Interview_StartTime (auto now)
    Question(
      id: 'scr_start_time',
      question: 'Interview start time',
      type: QuestionType.dateTime,
      captureConfig: const {
        'autoHidden': true,
        'autoNow': 'dateTime',
        'withTimezone': true,
        'apiKey': 'Dt_Interview_StartTime',
      },
      readOnly: true,
    ),

    // End time → Dt_Interview_EndTime (usually set at submit)
    // Keep hidden; your submit code can overwrite with "now".
    Question(
      id: 'scr_end_time',
      question: 'Interview end time',
      type: QuestionType.dateTime,
      captureConfig: const {
        'autoHidden': true,
        'withTimezone': true,
        'apiKey': 'Dt_Interview_EndTime',
      },
      readOnly: true,
    ),

    // Device location (hidden “slot”) → S_Lattitude / S_Longitude
    // If your QLocation supports 'mode': 'device', it can fill here.
    // Otherwise, set these in submit via LocationHelper.
    Question(
      id: 'scr_device_location',
      question: 'Interview location (device)',
      type: QuestionType.info,
      captureConfig: const {
        'autoHidden': true,
        'apiKeyLat': 'S_Lattitude',
        'apiKeyLon': 'S_Longitude',
      },
      readOnly: true,
    ),

    // Hidden echo of the selected type id (keeps visibleIf stable) + N_SurveyType
    Question(
      id: 'scr_type_select',
      question: 'Selected survey type',
      type: QuestionType.info,
      answer: typeId, // e.g., 'passengerBorder'
      captureConfig: const {
        'autoHidden': true,
        'apiKey': 'S_SurveyType',
        // TODO: Adjust to match your backend codes if different
        'apiMap': {
          'passengerPetrol': 1,
          'passengerBorder': 2,
          'bus': 3,
          'airport': 4,
          'hotel': 5,
        },
      },
      readOnly: true,
    ),

    // N_CreatedBy — hidden, set during submit from auth user id
    Question(
      id: 'scr_created_by',
      question: 'Created by (user id)',
      type: QuestionType.info,
      captureConfig: const {
        'autoHidden': true,
        'apiKey': 'N_CreatedBy',
      },
      readOnly: true,
    ),

    // S_SetEligibility — hidden; set to 'eligible' / reason string by notifier
    Question(
      id: 'scr_set_eligibility',
      question: 'Eligibility status',
      type: QuestionType.info,
      captureConfig: const {
        'autoHidden': true,
        'apiKey': 'S_SetEligibility',
      },
      readOnly: true,
    ),

    // ─── Visible type label (for the interviewer UX)
    Question(
      id: 'scr_type',
      question: 'Type of survey',
      type: QuestionType.info,
      readOnly: true,
      answer: typeLabel,
    ),
  ];

  // Parked vehicles count (A5) — petrol/border only → N_CarPresent
  if (type == QuestionnaireType.passengerPetrol || type == QuestionnaireType.passengerBorder) {
    qs.add(
      Question(
        id: 'scr_a5_parked_count',
        question: 'How many vehicles are currently parked at this location?',
        type: QuestionType.number,
        validation: const QuestionValidation(
          required: true,
          minValue: 1,
          maxValue: 500,
          numericKind: NumericKind.integer,
        ),
        captureConfig: const {
          'apiKey': 'N_CarPresent',
        },
      ),
    );
  }

  // E1 gate (Bus)
  if (type == QuestionnaireType.bus) {
    qs.add(
      Question(
        id: 'scr_e1',
        question: 'Are you making a trip between two different cities in the UAE today?',
        type: QuestionType.radio,
        options: const [
          AnswerOption(id: 'got_off', label: 'Yes – I have alighted from an intercity bus'),
          AnswerOption(id: 'waiting', label: 'Yes – I am waiting for an intercity bus'),
          AnswerOption(id: 'no',      label: 'No'),
        ],
        validation: isEdit ? null : const QuestionValidation(required: true),
        // You can also mirror an eligibility reason to S_SetEligibility in the notifier.
      ),
    );
  }

  // F1 gate (Airport)
  if (type == QuestionnaireType.airport) {
    qs.add(
      Question(
        id: 'scr_f1',
        question: 'Are you taking a flight today?',
        type: QuestionType.radio,
        options: const [
          AnswerOption(id: 'leaving', label: 'Yes – I am leaving the UAE and flying to a different country'),
          AnswerOption(id: 'arrived', label: 'Yes – I have arrived in the UAE from a different country'),
          AnswerOption(id: 'no',      label: 'No'),
        ],
        validation: const QuestionValidation(required: true),
      ),
    );
  }

  // G1 gate (Hotel)
  if (type == QuestionnaireType.hotel) {
    qs.add(
      Question(
        id: 'scr_g1',
        question: 'Are you currently staying at this hotel?',
        type: QuestionType.yesNo,
        options: const [
          AnswerOption(id: 'yes', label: 'Yes'),
          AnswerOption(id: 'no',  label: 'No'),
        ],
        validation: const QuestionValidation(required: true),
      ),
    );
  }

  return QuestionnaireSection(
    id: 'screening',
    title: 'Survey Details \n& Screening',
    questions: qs,
  );
}

/// Initial type selector (first screen)
/// Adds apiKey for N_SurveyType so a submission from the init page can also map.
QuestionnaireSection screeningSelectTypeSection() {
  return QuestionnaireSection(
    id: 'screening_init',
    title: 'Survey Details \n& Screening',
    questions: [
      Question(
        id: 'scr_type_select',
        question: 'Type of survey',
        type: QuestionType.radio,
        options: surveyTypeOptions,
        validation: QuestionValidation(required: true),
        captureConfig: const {
          'apiKey': 'S_SurveyType',
          // Keep mapping in sync with screeningSectionFor above.
          'apiMap': {
            'passengerPetrol': 1,
            'passengerBorder': 2,
            'bus': 3,
            'airport': 4,
            'hotel': 5,
          },
        },
      ),
    ],
  );
}
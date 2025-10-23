// hotel_section.dart
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/utils/enums.dart';

const _kHotelDestTypes = <AnswerOption>[
  AnswerOption(id: 'home',      label: 'A home residence (own, family, friend, etc)'),
  AnswerOption(id: 'hotel',     label: 'A different hotel or temporary accommodation'),
  AnswerOption(id: 'work',      label: 'A workplace'),
  AnswerOption(id: 'retail',    label: 'A retail, hospitality, or entertainment venue'),
  AnswerOption(id: 'hospital',  label: 'A hospital'),
  AnswerOption(id: 'education', label: 'An education facility'),
  AnswerOption(id: 'other',     label: 'Other (please specify)', isOther: true),
];

const _kHotelModes = <AnswerOption>[
  AnswerOption(id: 'car',      label: 'Car (owned or hired)'),
  AnswerOption(id: 'taxi',     label: 'Taxi/chauffeur'),
  AnswerOption(id: 'icbus',    label: 'Intercity bus'),
  AnswerOption(id: 'lpbus',    label: 'Local public bus'),
  AnswerOption(id: 'company',  label: 'Company/school bus'),
  AnswerOption(id: 'minibus',  label: 'Minibus / shared vehicle'),
  AnswerOption(id: 'metro',    label: 'Metro'),
  AnswerOption(id: 'active',   label: 'Active modes (eg. bike, scooter)'),
  AnswerOption(id: 'walk5',    label: 'Walk (more than 5 minutes)'),
  AnswerOption(id: 'other',    label: 'Other (open text)', isOther: true),
];

const _kHotelDurations = <AnswerOption>[
  AnswerOption(id: '<1h',   label: 'Less than an hour'),
  AnswerOption(id: '1-2h',  label: 'Between 1 and 2 hours'),
  AnswerOption(id: '2-4h',  label: 'Between 2 and 4 hours'),
  AnswerOption(id: '>4h',   label: 'More than 4 hours'),
];

const _kStayLenWithResident = <AnswerOption>[
  AnswerOption(id: '1',     label: '1 (flying in and out on the same day)'),
  AnswerOption(id: '2',     label: '2'),
  AnswerOption(id: '3',     label: '3'),
  AnswerOption(id: '4',     label: '4'),
  AnswerOption(id: '5',     label: '5'),
  AnswerOption(id: '6',     label: '6'),
  AnswerOption(id: '7',     label: '7'),
  AnswerOption(id: '7plus', label: 'More than 7'),
  AnswerOption(id: 'live',  label: 'I live here'),
];

final QuestionnaireSection hotelSectionG = QuestionnaireSection(
  id: 'hotel_g',
  title: 'Hotel \nDetails',
  questions: [
    // G2 — destinations (multi)
    Question(
      id: 'hotel_g2_destinations',
      question: 'Which locations will you be travelling to today?',
      type: QuestionType.multiSelect,
      options: _kHotelDestTypes,
      allowOtherOption: true,
      validation: QuestionValidation(required: true, minSelections: 1),
      captureConfig: {
        'apiKey': 'S_Destination',
        'apiJoin': 'comma',
        'apiUseLabel': true,
      },
    ),

    // G3 — repeat once per selected destination from G2 (multi-choice modes)
    // Each clone id becomes: hotel_g3_mode__<destId>
    Question(

      id: 'hotel_g3_mode',
      question: 'How will you be travelling to %label%?',
      type: QuestionType.multiSelect,
      options: _kHotelModes,
      allowOtherOption: true,
      captureConfig: {
        'repeatFromSelectedOf': 'hotel_g2_destinations',
        'repeatLabelTpl': 'How will you be travelling to %label%?',
        'idSuffixFromOptionId': true,
        // note: we still aggregate in notifier to build one CSV for N_VehicleType
      },
      validation: QuestionValidation(required: false, minSelections: 1),
    ),

    // G4 — repeat once per selected destination from G2 (single duration)
    // Each clone id becomes: hotel_g4_time__<destId>
    Question(
      id: 'hotel_g4_time',
      question: 'How long will you spend at %label%?',
      type: QuestionType.radio,
      options: _kHotelDurations,
      captureConfig: {
        'repeatFromSelectedOf': 'hotel_g2_destinations',
        'repeatLabelTpl': 'How long will you spend at %label%?',
        'idSuffixFromOptionId': true,
      },
      validation: QuestionValidation(required: false),
    ),

    // G5 — stay length incl. resident
    Question(
      id: 'hotel_g5_stay_days',
      question: 'How many days will you be in the UAE?',
      type: QuestionType.radio,
      options: _kStayLenWithResident,
      validation: QuestionValidation(required: true),
      captureConfig: {
        'apiKey': 'S_StayDuration',
        'apiUseLabel': true, // send label ("More than 7", "I live here", etc.)
      },
    ),

    // G6 — trips per day (shown only if not resident)
    // Keep this as an open-text for now (number validation). If you have a
    // matrix/day-by-day UI, you can swap to your matrix type later.
    // Question(
    //   id: 'hotel_g6_trips_per_day',
    //   question:
    //   'How many trips will you take per day whilst you are visiting the UAE? '
    //       'A trip is defined as moving from one place to an end-destination (eg. from the hotel to a shop)',
    //   type: QuestionType.number,
    //   visibleIf: ConditionGroup(atoms: [
    //     ConditionAtom(questionId: 'hotel_g5_stay_days', op: Operator.notEquals, value: 'live'),
    //   ]),
    //   validation: QuestionValidation(required: true, minValue: 0, maxValue: 50),
    //   captureConfig: {
    //     // (optional) annotate intent if you later pivot to a matrix-by-day
    //     'note': 'Could be a matrix sized by chosen days in G5; currently numeric input.',
    //   },
    // ),
  ],
);
// airport_section.dart
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/utils/enums.dart';

/// Shared option sets (unchanged)
const _kPurposeLocOpts = <AnswerOption>[
  AnswerOption(id: 'home',       label: 'A home residence (own, family, friend, etc)'),
  AnswerOption(id: 'hotel',      label: 'A hotel or temporary accommodation'),
  AnswerOption(id: 'work',       label: 'A workplace'),
  AnswerOption(id: 'retail',     label: 'A retail, hospitality, or entertainment venue'),
  AnswerOption(id: 'hospital',   label: 'A hospital'),
  AnswerOption(id: 'education',  label: 'An education facility'),
  AnswerOption(id: 'other',      label: 'Other (please specify)', isOther: true),
];


const _kGroupSize = <AnswerOption>[
  AnswerOption(id: 'alone', label: 'I’m travelling alone'),
  AnswerOption(id: '1',     label: 'One other person'),
  AnswerOption(id: '2',     label: 'Two other people'),
  AnswerOption(id: '3plus', label: '3+ other people'),
];

const _kStayLength = <AnswerOption>[
  AnswerOption(id: '1',     label: '1 (flying in and out on the same day)'),
  AnswerOption(id: '2',     label: '2'),
  AnswerOption(id: '3',     label: '3'),
  AnswerOption(id: '4',     label: '4'),
  AnswerOption(id: '5',     label: '5'),
  AnswerOption(id: '6',     label: '6'),
  AnswerOption(id: '7',     label: '7'),
  AnswerOption(id: '7plus', label: 'More than 7'),
];

const _kEmiratesMulti = <AnswerOption>[
  AnswerOption(id: 'auh', label: 'Abu Dhabi'),
  AnswerOption(id: 'dxb', label: 'Dubai'),
  AnswerOption(id: 'shj', label: 'Sharjah'),
  AnswerOption(id: 'ajm', label: 'Ajman'),
  AnswerOption(id: 'uaq', label: 'UAQ'),
  AnswerOption(id: 'rak', label: 'RAK'),
  AnswerOption(id: 'fuj', label: 'Fujairah'),
];

/// New per-spec traveller type (F2)
const _kTravellerType = <AnswerOption>[
  AnswerOption(id: 'tourist',            label: 'Tourist / visiting family'),
  AnswerOption(id: 'business_traveller', label: 'Business traveller'),
  AnswerOption(id: 'uae_resident',       label: 'UAE resident (returning home or about to travel overseas)'),
];


/// Airport Question Set (per latest spec)
/// If `scr_f1 == arrived` → ask F3–F10, then end
/// If `scr_f1 == leaving` → ask F11–F18, then end
final QuestionnaireSection airportSection = QuestionnaireSection(
  id: 'air_f',
  title: 'Airport \nLandside',
  questions: [
    // F2 — Traveller type (NEW first question in set)
    // Spec: “What kind of traveller are you?”
    Question(
      id: 'air_f2',
      question: 'What kind of traveller are you?',
      type: QuestionType.radio,
      options: _kTravellerType,
      // Always visible when in airport flow (screening chooses airport)
      validation: QuestionValidation(required: true),
      captureConfig: const {'apiKey': 'S_TravellerType'},
    ),

    // --------------------- ARRIVED TODAY (F3–F10) ---------------------

    // F3 — S_AirsideOD
    Question(
      id: 'air_f3',
      question:
      'Which airport did you fly in from? If you have taken multiple flights today, please indicate the last airport you departed from (ie. the last leg of your trip).',
      type: QuestionType.openText,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'scr_f1', op: Operator.equals, value: 'arrived'),
      ]),
      validation: QuestionValidation(required: true),
      captureConfig: const {'apiKey': 'S_AirsideOD'},
    ),

    // F4 — S_Airline
    Question(
      id: 'air_f4',
      question: 'Which airline did you fly with?',
      type: QuestionType.openText,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'scr_f1', op: Operator.equals, value: 'arrived'),
      ]),
      captureConfig: const {'apiKey': 'S_Airline'},
    ),

    // F5 — S_LandsideOD
    Question(
      id: 'air_f5',
      question:
      'When you leave the airport today, what is the address/suburb of where you are going (your first destination today)?',
      type: QuestionType.location,
      captureConfig: const {'mode': 'map', 'requireCoordinates': true, 'apiKey': 'S_LandsideOD'},
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'scr_f1', op: Operator.equals, value: 'arrived'),
      ]),
      validation: QuestionValidation(required: true),
    ),

    // F6 — N_TRIPPURP (ID only)
    Question(
      id: 'air_f6',
      question: 'When you leave the airport today, what type of location are you travelling to?',
      type: QuestionType.radio,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'scr_f1', op: Operator.equals, value: 'arrived'),
      ]),
      options: _kPurposeLocOpts,
      allowOtherOption: true,
      validation: QuestionValidation(required: true),
      captureConfig: const {'apiKey': 'S_Purp'},
    ),

    // F7 — N_VehicleType (string; pick first)
    Question(
      id: 'air_f7',
      question: 'How will you leave the airport today?',
      type: QuestionType.multiSelect,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'scr_f1', op: Operator.equals, value: 'arrived'),
      ]),
      allowOtherOption: true,
      catalog: CatalogRef('modes'),
      validation: QuestionValidation(required: true, minSelections: 1),
      captureConfig: const {'apiKey': 'S_VehicleType', 'apiPick': 'first'},
    ),

    // F8 — S_StayDuration (int)
    Question(
      id: 'air_f8',
      question: 'How many days will you be in the UAE?',
      type: QuestionType.radio,
      options: _kStayLength,
      visibleIf: ConditionGroup(
        join: LogicJoin.and,
        atoms: [
          ConditionAtom(questionId: 'scr_f1', op: Operator.equals, value: 'arrived'),
          ConditionAtom(
            questionId: 'air_f2',
            op: Operator.inList,
            value: ['tourist', 'business_traveller'],
          ),
        ],
      ),
      validation: QuestionValidation(required: true),
      captureConfig: const {
        'apiKey': 'S_StayDuration',
        'apiMap': {'1': 1,'2': 2,'3': 3,'4': 4,'5': 5,'6': 6,'7': 7,'7plus': 8},
      },
    ),

    // F9 — S_ICTravelPattern (multi → CSV)
    Question(
      id: 'air_f9',
      question: 'Will you be visiting other emirates during your trip to the UAE?',
      type: QuestionType.multiSelect,
      options: _kEmiratesMulti,
      visibleIf: ConditionGroup(
        join: LogicJoin.and,
        atoms: [
          ConditionAtom(questionId: 'scr_f1', op: Operator.equals, value: 'arrived'),
          ConditionAtom(
            questionId: 'air_f2',
            op: Operator.inList,
            value: ['tourist', 'business_traveller'],
          ),
        ],
      ),
      validation: QuestionValidation(required: true, minSelections: 1),
      captureConfig: const {'apiKey': 'S_ICTravelPattern', 'apiJoin': 'comma'},
    ),

    // F10 — N_NoOfPassenger (int) — optional in spec
    Question(
      id: 'air_f10',
      question: 'How many people did you fly to the UAE with?',
      type: QuestionType.radio,
      options: _kGroupSize,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'scr_f1', op: Operator.equals, value: 'arrived'),
      ]),
      // no validation => optional
      captureConfig: const {
        'apiKey': 'N_NoOfPassenger',
        'apiMap': {'alone': 1,'1': 2,'2': 3,'3plus': 4},
      },
    ),

    // --------------------- LEAVING TODAY (F11–F18) ---------------------

    // F11 — S_AirsideOD
    Question(
      id: 'air_f11',
      question:
      'Which airport are you flying to today? If you are taking multiple flights today, please indicate the first airport you will land at (ie. The first leg of your trip).',
      type: QuestionType.openText,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'scr_f1', op: Operator.equals, value: 'leaving'),
      ]),
      validation: QuestionValidation(required: true),
      captureConfig: const {'apiKey': 'S_AirsideOD'},
    ),

    // F12 — S_Airline
    Question(
      id: 'air_f12',
      question: 'Which airline are you flying with?',
      type: QuestionType.openText,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'scr_f1', op: Operator.equals, value: 'leaving'),
      ]),
      captureConfig: const {'apiKey': 'S_Airline'},
    ),

    // F13 — S_LandsideOD
    Question(
      id: 'air_f13',
      question: 'When you travelled to the airport today, what address/suburb did you start your trip at?',
      type: QuestionType.location,
      captureConfig: const {'mode': 'map', 'requireCoordinates': true, 'apiKey': 'S_LandsideOD'},
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'scr_f1', op: Operator.equals, value: 'leaving'),
      ]),
      validation: QuestionValidation(required: true),
    ),

    // F14 — N_TRIPPURP (ID only)
    Question(
      id: 'air_f14',
      question: 'When you travelled to the airport today, what type of location did you come from?',
      type: QuestionType.radio,
      // options: _kPurposeLocOpts,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'scr_f1', op: Operator.equals, value: 'leaving'),
      ])                                                                                      ,
      allowOtherOption: true,
      options: _kPurposeLocOpts,
      validation: QuestionValidation(required: true),
      captureConfig: const {'apiKey': 'S_Purp'},
    ),

    // F15 — N_VehicleType (string; pick first)
    Question(
      id: 'air_f15',
      question: 'How did you travel to the airport today?',
      type: QuestionType.multiSelect,
      catalog: CatalogRef('modes'),
      allowOtherOption: true,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'scr_f1', op: Operator.equals, value: 'leaving'),
      ]),
      validation: QuestionValidation(required: true, minSelections: 1),
      captureConfig: const {'apiKey': 'S_VehicleType', 'apiPick': 'first'},
    ),

    // F16 — N_StayDuration (int)
    Question(
      id: 'air_f16',
      question: 'How many days were you in the UAE?',
      type: QuestionType.radio,
      options: _kStayLength,
      visibleIf: ConditionGroup(
        join: LogicJoin.and,
        atoms: [
          ConditionAtom(questionId: 'scr_f1', op: Operator.equals, value: 'leaving'),
          ConditionAtom(
            questionId: 'air_f2',
            op: Operator.inList,
            value: ['tourist', 'business_traveller'],
          ),
        ],
      ),
      validation: QuestionValidation(required: true),
      captureConfig: const {
        'apiKey': 'N_StayDuration',
        'apiMap': {'1': 1,'2': 2,'3': 3,'4': 4,'5': 5,'6': 6,'7': 7,'7plus': 8},
      },
    ),

    // F17 — S_ICTravelPattern (multi → CSV)
    Question(
      id: 'air_f17',
      question: 'Did you visit other emirates during your trip to the UAE?',
      type: QuestionType.multiSelect,
      options: _kEmiratesMulti,
      visibleIf: ConditionGroup(
        join: LogicJoin.and,
        atoms: [
          ConditionAtom(questionId: 'scr_f1', op: Operator.equals, value: 'leaving'),
          ConditionAtom(
            questionId: 'air_f2',
            op: Operator.inList,
            value: ['tourist', 'business_traveller'],
          ),
        ],
      ),
      validation: QuestionValidation(required: true, minSelections: 1),
      captureConfig: const {'apiKey': 'S_ICTravelPattern', 'apiJoin': 'comma'},
    ),

    // F18 — N_NoOfPassenger (int) — optional in spec
    Question(
      id: 'air_f18',
      question: 'How many people are you flying with today?',
      type: QuestionType.radio,
      options: _kGroupSize,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'scr_f1', op: Operator.equals, value: 'leaving'),
      ]),
      captureConfig: const {
        'apiKey': 'N_NoOfPassenger',
        'apiMap': {'alone': 1,'1': 2,'2': 3,'3plus': 4},
      },
    ),
  ],
);
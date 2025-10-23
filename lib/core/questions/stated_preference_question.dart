import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/utils/enums.dart';

/// Reusable SP mode options
const spModes = <AnswerOption>[
  AnswerOption(id: 'car',  label: 'Car'),
  AnswerOption(id: 'taxi', label: 'Taxi'),
  AnswerOption(id: 'bus',  label: 'Bus'),
  AnswerOption(id: 'rail', label: 'Train'), // doc titles this to public as "Rail"
];

/// Helper: visibility condition “C5 or D3 or E10 is not none”
ConditionGroup _spVisibleIfAnyOdChosen() => ConditionGroup(
  join: LogicJoin.or,
  atoms: const [
    ConditionAtom(questionId: 'petrol_c5_od', op: Operator.notEquals, value: 'none'),
    ConditionAtom(questionId: 'border_d3_od', op: Operator.notEquals, value: 'none'),
    ConditionAtom(questionId: 'bus_e10_od',   op: Operator.notEquals, value: 'none'),
  ],
);

/// H. STATED PREFERENCE (document §H)
/// NOTE: The doc requires: show SP only if (A2 is an SP location) AND (C5/D3/E10 != none).
/// If you don’t have the “A2 is SP location” flag yet, keep the OR-part below;
/// add the A2 flag later as another AND group.
final QuestionnaireSection statedPreferenceSection = QuestionnaireSection(
  id: 'sp_h',
  title: 'H. Stated Preference',
  questions: [
    // H1 – preamble/instructions (display only)
    Question(
      id: 'sp_h1_preamble',
      type: QuestionType.info,
        question: 'Dummy',
      readOnly: true,
      // Piped OD placeholder — your renderer can replace [OD] using whichever of C5/D3/E10 is answered.
      hint:
      'Imagine you are planning another trip between [OD from C5/D3/E10]. '
          'I am going to show you four options for this trip: Car, Taxi, Bus or Train. '
          'Each option has a different travel time and cost.',
      visibleIf: _spVisibleIfAnyOdChosen(),
    ),

    // H2/H13/H24/H35/H46/H57 – First scenario (single choice)
    Question(
      id: 'sp_h2_first',
      question: 'Which option would you prefer for a trip between [OD from C5/D3/E10]?',
      type: QuestionType.radio,
      options: spModes,
      validation: QuestionValidation(required: true),
      // Visible when any OD was chosen upstream
      visibleIf: _spVisibleIfAnyOdChosen(),
    ),

    // Subsequent scenarios (H3+, H4+, H7+ etc. in the doc). We keep it simple:
    // show three more scenarios after H2 is answered (you can wire your experimental design later).
    Question(
      id: 'sp_h3_second',
      question: 'Of these new four options, which would you prefer to use? (Scenario 2)',
      type: QuestionType.radio,
      options: spModes,
      validation: QuestionValidation(required: true),
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'sp_h2_first', op: Operator.notEmpty, value: null),
      ]),
    ),
    Question(
      id: 'sp_h4_third',
      question: 'Of these new four options, which would you prefer to use? (Scenario 3)',
      type: QuestionType.radio,
      options: spModes,
      validation: QuestionValidation(required: true),
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'sp_h2_first', op: Operator.notEmpty, value: null),
      ]),
    ),
    Question(
      id: 'sp_h7_fourth',
      question: 'Of these new four options, which would you prefer to use? (Scenario 4)',
      type: QuestionType.radio,
      options: spModes,
      validation: QuestionValidation(required: true),
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'sp_h2_first', op: Operator.notEmpty, value: null),
      ]),
    ),
  ],
);

/// (Optional) If you later want to map exact H-codes by OD pair as per Table B-2:
/// - Abu Dhabi–Al Ruwais: H2 first, H3–H12 subsequent
/// - Abu Dhabi–Dubai:     H13 first, H14–H23 subsequent
/// - Abu Dhabi–Sharjah:   H24 first, H25–H34 subsequent
/// - Abu Dhabi–Fujairah:  H35 first, H36–H45 subsequent
/// - Dubai–Sharjah:       H46 first, H47–H56 subsequent
/// - Dubai–Fujairah:      H57 first, H58–H67 subsequent
/// This scaffold keeps a single set of 4 scenarios; swap in the exact IDs once you add OD routing.
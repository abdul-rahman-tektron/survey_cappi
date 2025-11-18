import 'package:srpf/core/questions/model/question_model.dart';

/// Catalogs (unchanged)
final kYesNo = [
  AnswerOption(id: 'yes', label: 'Yes'),
  AnswerOption(id: 'no',  label: 'No'),
];

final atcVehicleTypes = [
  {'id': '7',  'label': 'Light Goods Truck',            'asset': 'assets/images/vehicles/7.png'},
  {'id': '15', 'label': 'Tractor Only',                 'asset': 'assets/images/vehicles/15.jpeg'},
  {'id': '8',  'label': 'Medium Goods Enclosed Truck',  'asset': 'assets/images/vehicles/8.jpeg'},
  {'id': '9',  'label': 'Medium Goods Flatbed Truck',   'asset': 'assets/images/vehicles/9.jpeg'},
  {'id': '13', 'label': 'Medium Bulk Truck',            'asset': 'assets/images/vehicles/13.png'},
  {'id': '10', 'label': 'Heavy Goods Enclosed Truck',   'asset': 'assets/images/vehicles/10.jpeg'},
  {'id': '11', 'label': 'Heavy Goods Flatbed Truck',    'asset': 'assets/images/vehicles/11.jpeg'},
  {'id': '12', 'label': 'Heavy Goods Tanker Truck',     'asset': 'assets/images/vehicles/12.jpeg'},
  {'id': '14', 'label': 'Heavy Bulk Truck',             'asset': 'assets/images/vehicles/14.jpeg'},
  {'id': '16', 'label': 'Container Truck (20ft)',       'asset': 'assets/images/vehicles/16.jpeg'},
  {'id': '17', 'label': 'Container Truck (40ft)',       'asset': 'assets/images/vehicles/17.jpeg'},
  {'id': '18', 'label': 'Multi-container / Long-bed',   'asset': 'assets/images/vehicles/18.jpeg'},
];

final kDriversCount = [
  AnswerOption(id: '1',  label: '1'),
  AnswerOption(id: '2',  label: '2'),
  AnswerOption(id: '3+', label: '3+'),
];

final kWeightSource = [
  AnswerOption(id: 'weighbridge', label: 'Weighbridge Ticket'),
  AnswerOption(id: 'onboard',     label: 'On-Board Scale'),
  AnswerOption(id: 'estimate',    label: 'Estimate'),
];

final kCurrency = [
  AnswerOption(id: 'AED', label: 'AED'),
  AnswerOption(id: 'USD', label: 'USD'),
];

/// ----- Section A: Survey, vehicle and parties -----
final QuestionnaireSection rsiSectionA = QuestionnaireSection(
  id: 'rsi_a',
  title: 'Vehicle\n& Parties',
  questions: [
    Question(
      id: 'demo_b0_name',
      question: 'Respondent name',
      type: QuestionType.textField,
      validation: QuestionValidation(required: false, minLength: 2),
      captureConfig: const {'apiKey': 'S_FullName'},
    ),

    // A1 — auto-captured (hidden)
    Question(
      id: 'rsi_a1',
      question: 'Time of survey',
      type: QuestionType.dateTime,
      validation: QuestionValidation(required: true),
      captureConfig: {
        'withTimezone': true,
        'autoHidden': true,
        'autoNow': 'dateTime',
        // display hint for HHMM if your renderer supports it
        'displayFormat': 'HHmm',
        // 'apiKey': 'Dt_InterviewDate',
      },
    ),

    // A2 — Vehicle type (chips with images)
    Question(
      id: 'rsi_a2',
      question: 'Vehicle type (ATC classification)',
      type: QuestionType.chipsSingle,
      validation: QuestionValidation(required: true),
      captureConfig: {
        'items': atcVehicleTypes,
        'apiKey': 'S_VehicleType',
      },
    ),

    // A3 — Observed registration origin (now free text)
    Question(
      id: 'rsi_a3',
      question: 'Observed vehicle registration location',
      type: QuestionType.radio,   // 👈 new type (single chip select)
      catalog: CatalogRef('registration_origins'),
      allowOtherOption: true,
      validation: QuestionValidation(required: true),
      captureConfig: {
        'apiKey': 'S_Origin',
      },
    ),

    // A4 — Number of drivers
    Question(
      id: 'rsi_a4',
      question: 'How many drivers are operating this truck on this journey?',
      type: QuestionType.radio,
      options: [
        AnswerOption(id: '1',  label: '1'),
        AnswerOption(id: '2',  label: '2'),
        AnswerOption(id: '3+', label: '3+'),
      ],
      validation: QuestionValidation(required: true),
      captureConfig: {'apiKey': 'N_NoOfPassenger'},
    ),

    // A5.1 — Driver 1 residency
    Question(
      id: 'rsi_a5_1',
      question: 'Driver 1 country of residence',
      type: QuestionType.radio,
      catalog: CatalogRef('countries_gcc_plus_other'),
      allowOtherOption: true,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'rsi_a4', op: Operator.inList, value: ['1', '2', '3+']),
      ]),
      validation: QuestionValidation(required: true),
      captureConfig: {'apiKey': 'S_DriverResidency', 'apiJoin': 'comma'},
    ),

    // A5.2 — Driver 2 residency
    Question(
      id: 'rsi_a5_2',
      question: 'Driver 2 country of residence',
      type: QuestionType.radio,
      catalog: CatalogRef('countries_gcc_plus_other'),
      allowOtherOption: true,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'rsi_a4', op: Operator.inList, value: ['2', '3+']),
      ]),
      validation: QuestionValidation(required: true),
      captureConfig: {'apiKey': 'S_DriverResidency', 'apiJoin': 'comma'},
    ),

    // A6 — Hauler company
    Question(
      id: 'rsi_a6',
      question: 'Which hauler/transport company are you working for today?',
      type: QuestionType.dropdown,
      catalog: CatalogRef('hauler_companies'),
      allowOtherOption: true,
      validation: QuestionValidation(required: true),
      captureConfig: {'apiKey': 'N_Hauler'},
    ),

    // A7 — Client company
    Question(
      id: 'rsi_a7',
      question: 'Company (shipper/consignee/client) you are transporting goods for',
      type: QuestionType.textField,
      validation: QuestionValidation(required: true, minLength: 2),
      captureConfig: {'apiKey': 'S_ClientCompany'},
    ),

    // A8 — NEW: Loaded/Unloaded gate
    Question(
      id: 'rsi_a8',
      question: 'Is the vehicle loaded or unloaded?',
      type: QuestionType.radio,
      options: [
        AnswerOption(id: 'loaded',   label: 'Loaded'),
        AnswerOption(id: 'unloaded', label: 'Unloaded'),
      ],
      validation: QuestionValidation(required: true),
      captureConfig: {'apiKey': 'S_IsLoaded'},
    ),
  ],
);

/// ----- Section B: Shipment pattern & commodity -----
/// Visible only if A8 == yes
// ----- Section B: Shipment pattern & commodity -----
final QuestionnaireSection rsiSectionB = QuestionnaireSection(
  id: 'rsi_b',
  title: 'Shipment \n& Commodity',
  visibleIf: ConditionGroup(atoms: [
    ConditionAtom(questionId: 'rsi_a8', op: Operator.equals, value: 'loaded'),
  ]),
  questions: [
    // B1 (unchanged)
    Question(
      id: 'rsi_b1',
      question: 'Is the shipment to a single location or multiple drops?',
      type: QuestionType.radio,
      options: [
        AnswerOption(id: 'single', label: 'Single'),
        AnswerOption(id: 'multi',  label: 'Multi-drop'),
      ],
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'rsi_a8', op: Operator.equals, value: 'loaded'),
      ]),
      validation: QuestionValidation(required: true),
      captureConfig: {'apiKey': 'N_IsMultipleTrip', 'apiMap': {'single': 0, 'multi': 1}},
    ),

    // B2 — only if loaded AND multi
    Question(
      id: 'rsi_b2',
      question: 'How many delivery points are being made on this journey?',
      type: QuestionType.number,
      defaultValue: "2", // 👈 add this
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'rsi_a8', op: Operator.equals, value: 'loaded'),
        ConditionAtom(questionId: 'rsi_b1', op: Operator.equals, value: 'multi'),
      ]),
      validation: QuestionValidation(
          required: true, minValue: 2, maxValue: 50, numericKind: NumericKind.integer
      ),
      captureConfig: {'apiKey': 'N_TripCount'},
    ),

    // B3 — choose single vs multiple
    Question(
      id: 'rsi_b3',
      question: 'Is the shipment single commodity or multiple commodities?',
      type: QuestionType.radio,
      options: [
        AnswerOption(id: 'single',   label: 'Single'),
        AnswerOption(id: 'multiple', label: 'Multiple'),
      ],
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'rsi_a8', op: Operator.equals, value: 'loaded'),
      ]),
      validation: QuestionValidation(required: true),
      captureConfig: {
        'apiKey': 'N_IsMultipleCargo',
        'apiMap': {'single': 0, 'multiple': 1},
      },
    ),

// B4a — SINGLE: exactly one selection
    Question(
      id: 'rsi_b4_single',
      question: 'What commodity are you carrying?',
      type: QuestionType.multiSelect,           // or `select` if you have single-select
      catalog: CatalogRef('freight_commodities'),
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'rsi_a8', op: Operator.equals, value: 'loaded'),
        ConditionAtom(questionId: 'rsi_b3', op: Operator.equals, value: 'single'),
      ]),
      validation: QuestionValidation(required: true, minSelections: 1, maxSelections: 1),
      captureConfig: {'apiKey': 'N_TypeCargo', 'apiJoin': 'comma'},
    ),

// B4b — MULTIPLE: up to three selections
    Question(
      id: 'rsi_b4_multiple',
      question: 'What commodities are you carrying?',
      type: QuestionType.multiSelect,
      catalog: CatalogRef('freight_commodities'),
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'rsi_a8', op: Operator.equals, value: 'loaded'),
        ConditionAtom(questionId: 'rsi_b3', op: Operator.equals, value: 'multiple'),
      ]),
      validation: QuestionValidation(required: true, minSelections: 1, maxSelections: 3),
      // Use the SAME apiKey so downstream mapping stays identical.
      // Only one of these will be visible, so there’s no conflict.
      captureConfig: {'apiKey': 'N_TypeCargo', 'apiJoin': 'comma'},
    ),
  ],
);

/// ----- Section C: O/D & stops -----
// ----- Section C: O/D & stops -----
final QuestionnaireSection rsiSectionC = QuestionnaireSection(
  id: 'rsi_c',
  title: 'Origin–Destination\n& Stops',
  questions: [
    // C1a — cargo origin (if Loaded = loaded)
    Question(
      id: 'rsi_c1a',
      question: 'What is the origin of the cargo? (where the goods were loaded)',
      type: QuestionType.location,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'rsi_a8', op: Operator.equals, value: 'loaded'),
      ]),
      captureConfig: {
        'mode': 'map',
        'requireCoordinates': true,
        'apiKeyLat': 'S_Lattitude',
        'apiKeyLon': 'S_Longitude',
      },
      validation: QuestionValidation(required: true),
    ),

    // C1b — trip origin (if Loaded = unloaded)
    Question(
      id: 'rsi_c1b',
      question: 'where did you unload your cargo?',
      type: QuestionType.location,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'rsi_a8', op: Operator.equals, value: 'unloaded'),
      ]),
      captureConfig: {
        'mode': 'map',
        'requireCoordinates': true,
        'apiKeyLat': 'S_Lattitude',
        'apiKeyLon': 'S_Longitude',
      },
      validation: QuestionValidation(required: true),
    ),

    // C2 — next stop (always required)
    Question(
      id: 'rsi_c2',
      question: 'What is the destination of the current leg? (next stop on this journey)',
      type: QuestionType.location,
      captureConfig: {
        'mode': 'map',
        'requireCoordinates': true,
        'apiKeyLat': 'S_Destination_Lat',
        'apiKeyLon': 'S_Destination_Long',
      },
      validation: QuestionValidation(required: true),
    ),

    // C3 — final drop (only if loaded AND multi)
    Question(
      id: 'rsi_c3',
      question: 'What is the final drop location for this shipment?',
      type: QuestionType.location,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'rsi_a8', op: Operator.equals, value: 'loaded'),
        ConditionAtom(questionId: 'rsi_b1', op: Operator.equals, value: 'multi'),
      ]),
      captureConfig: {
        'mode': 'map',
        'requireCoordinates': true,
        'apiKeyLat': 'S_LatFinal',
        'apiKeyLon': 'S_LonFinal',
      },
      validation: QuestionValidation(required: false),
    ),
    // C4 — post-unloading destination (only if Loaded = loaded)
    Question(
      id: 'rsi_c4',
      question: 'What is the destination of the vehicle after fully unloading?',
      type: QuestionType.location,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'rsi_a8', op: Operator.equals, value: 'loaded'),
      ]),
      captureConfig: {
        'mode': 'map',
        'requireCoordinates': true,
        'apiKeyLat': 'S_LatConclusion',
        'apiKeyLon': 'S_LonConclusion',
      },
      validation: QuestionValidation(required: true),
    ),
  ],
);

/// ----- Section D: Timing -----
// ----- Section D: Timing -----
final QuestionnaireSection rsiSectionD = QuestionnaireSection(
  id: 'rsi_d',
  title: 'Trip\nTiming',
  questions: [
    // D1 — start time (unchanged)
    Question(
      id: 'rsi_d1',
      question: 'What date/time did you start your journey?',
      type: QuestionType.dateTime,
      validation: QuestionValidation(required: true),
      captureConfig: {
        'withTimezone': true,
        'apiKey': 'Dt_DepartureTime',
        'displayFormat': 'yyyy-MM-dd HHmm',
      },
    ),

    // D2 — (unchanged)
    Question(
      id: 'rsi_d2',
      question: 'What is the planned arrival date/time of your current leg? (next stop on this journey)',
      type: QuestionType.dateTime,
      validation: QuestionValidation(required: false),
      captureConfig: {
        'withTimezone': true,
        'apiKey': 'Dt_ArrivalTime',
        'displayFormat': 'yyyy-MM-dd HHmm',
      },
    ),

    // D3 — only if loaded AND multi
    Question(
      id: 'rsi_d3',
      question: 'What is the planned arrival date/time of your final drop for this shipment?',
      type: QuestionType.dateTime,
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'rsi_a8', op: Operator.equals, value: 'loaded'),
        ConditionAtom(questionId: 'rsi_b1', op: Operator.equals, value: 'multi'),
      ]),
      validation: QuestionValidation(required: true),
      captureConfig: {
        'withTimezone': true,
        'apiKey': 'Dt_ReachTime',
        'displayFormat': 'yyyy-MM-dd HHmm',
      },
    ),
  ],
);

/// ----- Section E: Quantity, value, charges -----
/// Entire section only if Loaded = yes
// ----- Section E: Quantity, value, charges -----
final QuestionnaireSection rsiSectionE = QuestionnaireSection(
  id: 'rsi_e',
  title: 'Weights\n& Charges',
  visibleIf: ConditionGroup(atoms: [
    ConditionAtom(questionId: 'rsi_a8', op: Operator.equals, value: 'loaded'),
  ]),
  questions: [
    // E1 — simplified (tare + gvw) in tonnes; NO unit picker
    Question(
      id: 'rsi_e1',
      question: 'What quantity of cargo are you carrying?',
      type: QuestionType.textField, // renderer switches via captureConfig
      validation: QuestionValidation(required: true),
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'rsi_a8', op: Operator.equals, value: 'loaded'),
      ]),
      captureConfig: {
        'composite': true,
        'fields': [
          {
            'id': 'tare',
            'label': 'Tare weight',
            'type': 'number',
            'required': true,
            'min': 0,
            'max': 100000,
            'decimal': true
          },
          {
            'id': 'gvw',
            'label': 'Gross vehicle weight',
            'type': 'number',
            'required': true,
            'min': 0,
            'max': 100000,
            'decimal': true
          },
        ],

        // NEW: simple unit picker (shared for this composite)
        'unitPicker': {
        'id': 'unit',
        'label': 'Unit',        // <- title shown above the picker
        'default': 't',
        'items': [
          {'id': 't',  'label': 'tons'},
          {'id': 'm3', 'label': 'cubic metres'},
        ]
      },

        // (if you later want to map this to API)
        // 'apiCompositeMap': {'gvw':'S_Weight','tare':'S_CargoWeight','unit':'S_WeightUnit'},
      },
    ),

    // E2, E3, E4 — unchanged except section-level visibility handles "loaded"
    Question(
      id: 'rsi_e2',
      question: 'How do you know the weight?',
      type: QuestionType.radio,
      options: [
        AnswerOption(id: 'weighbridge', label: 'Weighbridge Ticket'),
        AnswerOption(id: 'onboard',     label: 'On-Board Scale'),
        AnswerOption(id: 'estimate',    label: 'Estimate'),
      ],
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'rsi_a8', op: Operator.equals, value: 'loaded'),
      ]),
      validation: QuestionValidation(required: true),
      captureConfig: {'apiKey': 'S_WeighMethod','apiUseLabel': true},
    ),

    Question(
      id: 'rsi_e3',
      question: 'What is the cargo value noted in the bill of lading?',
      type: QuestionType.textField,
      validation: QuestionValidation(required: true),
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'rsi_a8', op: Operator.equals, value: 'loaded'),
      ]),
      captureConfig: {
        'moneyPair': true,
        'specialToggle': {'key': 'special', 'label': 'Unknown / Refused'},
        'amount':  {'key': 'amount','label': 'Amount','min': 0,'max': 100000000,'decimal': true,'required': true},
        'currency':{'key': 'currency','label': 'Currency','required': true,
          'options': [{'id': 'AED','label': 'AED'}, {'id': 'USD','label': 'USD'}]},
        'apiKey': 'N_CargoCost',
        'apiMoney': {'format': 'amount currency','toString': true},
      },
    ),

    Question(
      id: 'rsi_e4',
      question: 'How much have you / your company charged to transport the goods from origin to destination?',
      type: QuestionType.textField,
      validation: QuestionValidation(required: true),
      visibleIf: ConditionGroup(atoms: [
        ConditionAtom(questionId: 'rsi_a8', op: Operator.equals, value: 'loaded'),
      ]),
      captureConfig: {
        'moneyPair': true,
        'specialToggle': {'key': 'special', 'label': 'Unknown / Refused'},
        'amount':  {'key': 'amount','label': 'Amount','min': 0,'max': 100000000,'decimal': true,'required': true},
        'currency':{'key': 'currency','label': 'Currency','required': true,
          'options': [{'id': 'AED','label': 'AED'}, {'id': 'USD','label': 'USD'}]},
        'apiKey': 'N_CostTrip',
        'apiMoney': {'format': 'amount currency','toString': true},
      },
    ),
  ],
);
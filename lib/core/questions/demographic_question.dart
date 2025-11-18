// demographic_section.dart
import 'package:srpf/core/questions/model/question_model.dart';
import 'package:srpf/utils/enums.dart';

/// --- B1: Gender -------------------------------------------------------------
final demoGender = [
  AnswerOption(id: 'male', label: 'Male'),
  AnswerOption(id: 'female', label: 'Female'),
];

/// --- B2: Age bands ----------------------------------------------------------
final demoAgeBands = [
  AnswerOption(id: '-18', label: 'Below 18'),
  AnswerOption(id: '18-30', label: '18-30 years old'),
  AnswerOption(id: '31-50', label: '31-50 years old'),
  AnswerOption(id: '50-65', label: '50-65 years old'),
  AnswerOption(id: '65+',   label: 'Over 65'),
  AnswerOption(id: 'no_age',   label: 'Prefer not to say'),
];

/// --- B3a: Traveller type ----------------------------------------------------
final demoTravellerType = [
  AnswerOption(id: 'uae_resident',       label: 'UAE resident'),
  AnswerOption(id: 'business_traveller', label: 'Business traveller'),
  AnswerOption(id: 'tourist',            label: 'Tourist'),
];


/// --- B5a: UAE (and nearby) suburb/locality list (expanded) --------------------
final demoUaeSuburbOptions = <AnswerOption>[
  // ──────────────────────────────── ABU DHABI ────────────────────────────────
  AnswerOption(id: 'AUH-CBD', label: 'Abu Dhabi City'),
  AnswerOption(id: 'AUH-MHD', label: 'Mohammed Bin Zayed City'),
  AnswerOption(id: 'AUH-MSA', label: 'Mussafah'),
  AnswerOption(id: 'AUH-KHALIFA-A', label: 'Khalifa City A'),
  AnswerOption(id: 'AUH-BANIYAS', label: 'Baniyas'),
  AnswerOption(id: 'AUH-SHAMKHA', label: 'Al Shamkha'),
  AnswerOption(id: 'AUH-REEM', label: 'Al Reem Island'),
  AnswerOption(id: 'AUH-SAADIYAT', label: 'Saadiyat Island'),
  AnswerOption(id: 'AUH-YAS', label: 'Yas Island'),
  AnswerOption(id: 'AUH-AL-AIN', label: 'Al Ain'),
  AnswerOption(id: 'AUH-AL-FALAH', label: 'Al Falah'),
  AnswerOption(id: 'AUH-RUW', label: 'Al Ruwais'),
  AnswerOption(id: 'AUH-MADINATZAYED', label: 'Madinat Zayed (Western Region)'),
  AnswerOption(id: 'AUH-LIWA', label: 'Liwa'),

  // ──────────────────────────────── DUBAI ────────────────────────────────
  AnswerOption(id: 'DXB-DCC', label: 'Deira'),
  AnswerOption(id: 'DXB-BUR', label: 'Bur Dubai'),
  AnswerOption(id: 'DXB-KARAMA', label: 'Al Karama'),
  AnswerOption(id: 'DXB-JBR', label: 'Jumeirah Beach Residence'),
  AnswerOption(id: 'DXB-JVC', label: 'Jumeirah Village Circle'),
  AnswerOption(id: 'DXB-JVT', label: 'Jumeirah Village Triangle'),
  AnswerOption(id: 'DXB-MRN', label: 'Dubai Marina'),
  AnswerOption(id: 'DXB-DSO', label: 'Dubai Silicon Oasis'),
  AnswerOption(id: 'DXB-MIRDIF', label: 'Mirdif'),
  AnswerOption(id: 'DXB-DISC', label: 'Discovery Gardens'),
  AnswerOption(id: 'DXB-ALBARSHA', label: 'Al Barsha'),
  AnswerOption(id: 'DXB-BUSINESSBAY', label: 'Business Bay'),
  AnswerOption(id: 'DXB-DOWNTOWN', label: 'Downtown Dubai'),
  AnswerOption(id: 'DXB-JUMEIRAH', label: 'Jumeirah'),
  AnswerOption(id: 'DXB-ALNAHDA', label: 'Al Nahda (Dubai)'),
  AnswerOption(id: 'DXB-INTERNATIONALCITY', label: 'International City'),
  AnswerOption(id: 'DXB-DAMACHILLS2', label: 'Damac Hills 2'),
  AnswerOption(id: 'DXB-ARJAN', label: 'Arjan'),
  AnswerOption(id: 'DXB-DIP', label: 'Dubai Investment Park'),

  // ──────────────────────────────── SHARJAH ────────────────────────────────
  AnswerOption(id: 'SHJ-ALMAJ', label: 'Al Majaz'),
  AnswerOption(id: 'SHJ-ALNAH', label: 'Al Nahda (Sharjah)'),
  AnswerOption(id: 'SHJ-ROLLA', label: 'Rollah'),
  AnswerOption(id: 'SHJ-MUWAILAH', label: 'Muwaileh'),
  AnswerOption(id: 'SHJ-ALKHAN', label: 'Al Khan'),
  AnswerOption(id: 'SHJ-BUHAIRA', label: 'Al Buhaira Corniche'),
  AnswerOption(id: 'SHJ-INDAREA', label: 'Industrial Area'),
  AnswerOption(id: 'SHJ-UNIVERSITY', label: 'University City'),
  AnswerOption(id: 'SHJ-MUWAI', label: 'Muwailih Commercial'),

  // ──────────────────────────────── AJMAN ────────────────────────────────
  AnswerOption(id: 'AJM-ALNU', label: 'Al Nuaimiya'),
  AnswerOption(id: 'AJM-RASHIDIYA', label: 'Al Rashidiya'),
  AnswerOption(id: 'AJM-MOWAIHAT', label: 'Al Mowaihat'),
  AnswerOption(id: 'AJM-ALRAWDA', label: 'Al Rawda'),
  AnswerOption(id: 'AJM-ALJURF', label: 'Al Jurf'),

  // ──────────────────────────────── UMM AL QUWAIN ────────────────────────────────
  AnswerOption(id: 'UAQ-CITY', label: 'UAQ City'),
  AnswerOption(id: 'UAQ-ALRAAS', label: 'Al Raas'),
  AnswerOption(id: 'UAQ-FALAJ', label: 'Falaj Al Mualla'),

  // ──────────────────────────────── RAS AL KHAIMAH ────────────────────────────────
  AnswerOption(id: 'RAK-ALHAM', label: 'Al Hamra'),
  AnswerOption(id: 'RAK-RAKCT', label: 'Ras Al Khaimah City'),
  AnswerOption(id: 'RAK-ALNAKHIL', label: 'Al Nakheel'),
  AnswerOption(id: 'RAK-JAZEERAH', label: 'Al Jazirah Al Hamra'),
  AnswerOption(id: 'RAK-KHOR', label: 'Khor Khwair'),

  // ──────────────────────────────── FUJAIRAH ────────────────────────────────
  AnswerOption(id: 'FJR-CITY', label: 'Fujairah City'),
  AnswerOption(id: 'FJR-DIBB', label: 'Dibba Al-Fujairah'),
  AnswerOption(id: 'FJR-MIRBAH', label: 'Mirbah'),
  AnswerOption(id: 'FJR-QIDFA', label: 'Qidfa'),
  AnswerOption(id: 'FJR-KALBA', label: 'Kalba'),

  // ──────────────────────────────── OMAN (Nearby Border) ────────────────────────────────
  AnswerOption(id: 'OMN-MCT', label: 'Muscat'),
  AnswerOption(id: 'OMN-SHIN', label: 'Shinas'),
  AnswerOption(id: 'OMN-ALBURAIMI', label: 'Al Buraimi'),
  AnswerOption(id: 'OMN-SOHAR', label: 'Sohar'),

  // ──────────────────────────────── CATCH-ALL ────────────────────────────────
  AnswerOption(id: 'OTHER', label: 'Other (specify)', isOther: true),
];

/// --- B9: Income -------------------------------------------------------------
final demoIncome = [
  AnswerOption(id: '<3k',   label: 'Less than 3k AED'),
  AnswerOption(id: '3-6k', label: '3-6k'),
  AnswerOption(id: '6-12k',label: '6-12k'),
  AnswerOption(id: '12-30k',label: '12-30k'),
  AnswerOption(id: '30-40k',label: '30-40k'),
  AnswerOption(id: '40-75k',label: '40-75k'),
  AnswerOption(id: '75k+',  label: '75k+ AED'),
  AnswerOption(id: 'Not Preferred',  label: 'Prefer Not to Say'),
];

/// --- B10: Employment --------------------------------------------------------
final demoEmployment = [
  AnswerOption(id: 'construction',   label: 'I work on a construction site'),
  AnswerOption(id: 'manufacturing',  label: 'I work in a manufacturing or industrial facility'),
  AnswerOption(id: 'office',         label: 'I work in an office'),
  AnswerOption(id: 'school',         label: 'I work in primary or secondary school'),
  AnswerOption(id: 'university',     label: 'I work in a college or university'),
  AnswerOption(id: 'healthcare',     label: 'I work in a healthcare facility'),
  AnswerOption(id: 'leisure',        label: 'I work in a leisure or hospitality facility'),
  AnswerOption(id: 'mall',           label: 'I work in a shopping mall'),
  AnswerOption(id: 'retail',         label: 'I work in retail'),
  AnswerOption(id: 'residential',    label: 'I work in a residential setting'),
  AnswerOption(id: 'seeking',        label: 'I am seeking work'),
  AnswerOption(id: 'retired',        label: 'I am retired'),
  AnswerOption(id: 'other',          label: 'Other', isOther: true),
];

/// --- B6: Employment (new, compressed set) -----------------------------------
final demoEmploymentV2 = [
  AnswerOption(id: 'employer',        label: 'Employer'),
  AnswerOption(id: 'white_collar',    label: 'Employed - White Collar'),
  AnswerOption(id: 'blue_collar',     label: 'Employed - Blue Collar'),
  AnswerOption(id: 'homemaker',       label: 'Homemaker'),
  AnswerOption(id: 'student',         label: 'Student'),
  AnswerOption(id: 'seeking',         label: 'Seeking work'),
  AnswerOption(id: 'unemployed',      label: 'Unemployed'),
  AnswerOption(id: 'other',           label: 'Other', isOther: true),
];

/// --- B11: Car Access --------------------------------------------------------
///
final demoCarAccess = [
  AnswerOption(id: 'no',     label: 'No'),
  AnswerOption(id: 'own',    label: 'Yes – my own car'),
  AnswerOption(id: 'shared', label: 'Yes – a car I share with someone else'),
];

/// ─────────────────────────────────────────────────────────────────────────────
/// Demographics section (B)
/// ─────────────────────────────────────────────────────────────────────────────
final QuestionnaireSection demographicsSection = QuestionnaireSection(
  id: 'demo_b',
  title: 'Demographics \nDetails',
  questions: [
    // B0 — name (unchanged)
    Question(
      id: 'demo_b0_name',
      question: 'Respondent name',
      type: QuestionType.textField,
      validation: QuestionValidation(required: false, minLength: 2),
      captureConfig: const {'apiKey': 'S_FullName'},
    ),

    // B1 — Gender (unchanged: single choice)
    Question(
      id: 'demo_b1_gender',
      question: 'What is your gender?',
      type: QuestionType.radio,
      options: demoGender,
      validation: QuestionValidation(required: true),
      captureConfig: const {'apiKey': 'S_Gender'},
    ),

    // B2 — Age: now SINGLE CHOICE (age bands)
    Question(
      id: 'demo_b2_age',
      question: 'What is your age?',
      type: QuestionType.radio,
      options: demoAgeBands,
      validation: QuestionValidation(required: true),
      captureConfig: const {'apiKey': 'N_Age'}, // keep same API key unless backend says otherwise
    ),

    // B3 — Nationality: now MULTI-SELECT (from catalog of countries)
    Question(
      id: 'demo_b3_nationality', // <-- new id to avoid clashes if you prefer; or keep original id.
      question: 'Nationality?',
      type: QuestionType.dropdown,
      catalog: CatalogRef('nationalities'),
      allowOtherOption: true,
      validation: QuestionValidation(required: true, minSelections: 1),
      captureConfig: const {
        'apiKey': 'S_Nationality',
      },
    ),

    // B4a — Home suburb (unchanged logic; single choice)
    Question(
      id: 'demo_b4a_home_suburb',
      question: 'Where do you live? Please select the most applicable suburb',
      type: QuestionType.dropdown,
      options: demoUaeSuburbOptions,
      allowOtherOption: true,
      visibleIf: ConditionGroup(
        atoms: [
          ConditionAtom(questionId: 'scr_type_select', op: Operator.notEquals, value: 'passengerBorder'),
        ],
      ),
      validation: QuestionValidation(required: true),
      captureConfig: const {'apiKey': 'S_Suburbs'},
    ),

    // B4b — Residence country (unchanged structure; single choice + other text)
    Question(
      id: 'demo_b4b_residence_country',
      question: 'What is your usual place of residence?',
      type: QuestionType.dropdown,
      allowOtherOption: true,
      options: const [
        AnswerOption(id: 'UAE',  label: 'UAE'),
        AnswerOption(id: 'OMN',  label: 'Oman'),
        AnswerOption(id: 'KSA',  label: 'KSA'),
        AnswerOption(id: 'QAT',  label: 'Qatar'),
        AnswerOption(id: 'BHR',  label: 'Bahrain'),
        AnswerOption(id: 'KWT',  label: 'Kuwait'),
        AnswerOption(id: 'split_gcc', label: 'I split my time evenly between the UAE and another GCC country'),
        AnswerOption(id: 'OTHER', label: 'Other', isOther: true),
      ],
      visibleIf: ConditionGroup(
        atoms: [ConditionAtom(questionId: 'scr_type_select', op: Operator.equals, value: 'passengerBorder')],
      ),
      validation: QuestionValidation(required: true),
      captureConfig: const {'apiKey': 'S_DriverResidency'},
    ),

    // B5 — Income (unchanged)
    Question(
      id: 'demo_b5_income',
      question: 'Which category best reflects your monthly household income?',
      type: QuestionType.radio,
      options: demoIncome,
      validation: QuestionValidation(required: true),
      captureConfig: const {'apiKey': 'S_MonthlyIncome'},
    ),

    // B6 — Employment: replace with new compact list
    Question(
      id: 'demo_b6_employment',
      question: 'Which best describes your employment or occupation?',
      type: QuestionType.radio,
      options: demoEmploymentV2,
      allowOtherOption: true,
      validation: QuestionValidation(required: true),
      captureConfig: const {'apiKey': 'S_Occupation'},
    ),

    // B7 — Car access (unchanged)
    Question(
      id: 'demo_b7_car_access',
      question: 'Do you have access to a car?',
      type: QuestionType.radio,
      options: demoCarAccess,
      validation: QuestionValidation(required: true),
      captureConfig: const {'apiKey': 'S_PrivateCarAvailability'},
    ),
  ],
);
// ================== CORE ENUMS ==================
enum QuestionType {
  textField, number, dropdown, radio, checkbox, multiSelect,
  date, time, dateTime, openText, yesNo, rating, likert, matrix,
  file, photo, signature, location, barcode, info, chipsSingle
}

enum Operator {
  equals, notEquals, greaterThan, greaterOrEqual, lessThan, lessOrEqual,
  contains, notContains, inList, notInList, isEmpty, notEmpty, anyTrue, allTrue,
}

enum LogicJoin { and, or }

enum NumericKind { any, integer, decimal, currency }

// For “don’t know / refused / unknown” capture
enum SpecialAnswer { unknown, refused }

// ================== OPTIONS & CATALOGS ==================
class AnswerOption {
  final String id;                 // stable code (e.g., "AUH-DXB", "male")
  final String label;              // user-visible text
  final String? description;       // helper text
  final bool exclusive;            // e.g., "None of the above"
  final bool isOther;              // triggers open text
  final Map<String, dynamic>? meta;// e.g., OD pair payload, fare/time, color

  const AnswerOption({
    required this.id,
    required this.label,
    this.description,
    this.exclusive = false,
    this.isOther = false,
    this.meta,
  });
}

/// Reference to hydrated lists like emirates/suburbs, countries, hauler/commodity codes, 15-min times, etc.
class CatalogRef {
  final String key;                // e.g., "emirates", "suburbs", "commodityCodes"
  final Map<String, dynamic>? args;// e.g., {"emirate":"AUH"} for cascading dropdowns
  const CatalogRef(this.key, {this.args});
}

// ================== VALIDATION ==================
class QuestionValidation {
  final bool required;
  final int? minLength;
  final int? maxLength;
  final num? minValue;
  final num? maxValue;
  final String? regexPattern;
  final String? errorMessage;

  // Multi/select constraints
  final int? minSelections;
  final int? maxSelections;

  // Date/time windows
  final DateTime? minDate;
  final DateTime? maxDate;

  // Numeric kind
  final NumericKind numericKind;

  const QuestionValidation({
    this.required = false,
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.regexPattern,
    this.errorMessage,
    this.minSelections,
    this.maxSelections,
    this.minDate,
    this.maxDate,
    this.numericKind = NumericKind.any,
  });
}

// ================== CONDITIONAL LOGIC ==================
class ConditionAtom {
  final String questionId;   // dependency id
  final Operator op;
  final dynamic value;       // for inList: List<dynamic>

  const ConditionAtom({
    required this.questionId,
    required this.op,
    this.value,
  });
}

class ConditionGroup {
  final LogicJoin join;
  final List<ConditionAtom> atoms;
  const ConditionGroup({this.join = LogicJoin.and, required this.atoms});
}

// ================== QUESTION ==================
class Question {
  final String id;
  final String question;
  final QuestionType type;

  // Choice sources
  final List<AnswerOption>? options; // explicit options
  final CatalogRef? catalog;         // dynamic options from catalogs

  // UI
  final String? hint;
  final String? placeholder;
  final String? tooltip;
  final String? defaultValue;        // serialized default
  final bool shuffleOptions;         // randomize choices (SP scenarios etc.)
  final bool readOnly;

  // Visibility / requirement logic
  final ConditionGroup? visibleIf;
  final ConditionGroup? requiredIf;

  // Validation
  final QuestionValidation? validation;

  // Matrix/Likert
  final List<AnswerOption>? matrixRows;    // statements
  final List<AnswerOption>? matrixColumns; // scale options

  // Capture configs (camera, gps, file constraints, etc.)
  final Map<String, dynamic>? captureConfig;

  // “Other (specify)” toggle
  final bool allowOtherOption;

  // Special answer capture (unknown/refused)
  final bool allowSpecialAnswers;

  // Answer storage (dynamic; normalize at repo layer)
  dynamic answer;

  Question({
    required this.id,
    required this.question,
    required this.type,
    this.options,
    this.catalog,
    this.hint,
    this.placeholder,
    this.tooltip,
    this.defaultValue,
    this.shuffleOptions = false,
    this.readOnly = false,
    this.visibleIf,
    this.requiredIf,
    this.validation,
    this.matrixRows,
    this.matrixColumns,
    this.captureConfig,
    this.allowOtherOption = false,
    this.allowSpecialAnswers = false,
    this.answer,
  });

  // 👇 Add this method
  Question copyWith({
    String? id,
    String? question,
    QuestionType? type,
    List<AnswerOption>? options,
    CatalogRef? catalog,
    String? hint,
    String? placeholder,
    String? tooltip,
    String? defaultValue,
    bool? shuffleOptions,
    bool? readOnly,
    ConditionGroup? visibleIf,
    ConditionGroup? requiredIf,
    QuestionValidation? validation,
    List<AnswerOption>? matrixRows,
    List<AnswerOption>? matrixColumns,
    Map<String, dynamic>? captureConfig,
    bool? allowOtherOption,
    bool? allowSpecialAnswers,
    dynamic answer,
  }) {
    return Question(
      id: id ?? this.id,
      question: question ?? this.question,
      type: type ?? this.type,
      options: options ?? this.options,
      catalog: catalog ?? this.catalog,
      hint: hint ?? this.hint,
      placeholder: placeholder ?? this.placeholder,
      tooltip: tooltip ?? this.tooltip,
      defaultValue: defaultValue ?? this.defaultValue,
      shuffleOptions: shuffleOptions ?? this.shuffleOptions,
      readOnly: readOnly ?? this.readOnly,
      visibleIf: visibleIf ?? this.visibleIf,
      requiredIf: requiredIf ?? this.requiredIf,
      validation: validation ?? this.validation,
      matrixRows: matrixRows ?? this.matrixRows,
      matrixColumns: matrixColumns ?? this.matrixColumns,
      captureConfig: captureConfig ?? this.captureConfig,
      allowOtherOption: allowOtherOption ?? this.allowOtherOption,
      allowSpecialAnswers: allowSpecialAnswers ?? this.allowSpecialAnswers,
      answer: answer ?? this.answer,
    );
  }
}
// ================== SECTION ==================
class QuestionnaireSection {
  final String id;
  final String title;
  final List<Question> questions;

  // Section display gating (e.g., Petrol/Border/Bus/Airport/Hotel)
  final ConditionGroup? visibleIf;

  // Repeatable loop (e.g., Hotel G2 → ask G3/G4 per destination)
  final bool repeatable;
  final int? minRepeats;
  final int? maxRepeats;

  const QuestionnaireSection({
    required this.id,
    required this.title,
    required this.questions,
    this.visibleIf,
    this.repeatable = false,
    this.minRepeats,
    this.maxRepeats,
  });
}

// ================== SURVEY (ROOT) ==================
class SurveyDefinition {
  final String id;
  final String name;
  final String version;
  final String locale;                     // 'en', 'ar', etc.
  final List<QuestionnaireSection> sections;

  // Global text piping variables (e.g., OD labels for SP)
  final Map<String, String>? globals;

  // Required metadata keys (surveyorId, deviceId, tz, appVersion…)
  final List<String>? requiredMetadataKeys;

  // Termination rules (eligibility fails: scrap response/do not tally)
  final List<ConditionGroup> terminators;

  const SurveyDefinition({
    required this.id,
    required this.name,
    required this.version,
    required this.locale,
    required this.sections,
    this.globals,
    this.requiredMetadataKeys,
    this.terminators = const [],
  });
}

// ================== RESPONSE ENVELOPE ==================
class SurveyResponse {
  final String surveyId;
  final String version;
  final String instanceId;               // UUID per interview
  final DateTime startedAt;
  DateTime? submittedAt;

  // device/user/geo context for QA + offline sync + audit
  final Map<String, dynamic> metadata;   // {surveyorId, deviceId, lat, lng, accuracy, tz, appVersion}
  final Map<String, dynamic> answers;    // questionId -> value
  final SpecialAnswer? special;          // interview-level (rare)

  bool get isSubmitted => submittedAt != null;

  SurveyResponse({
    required this.surveyId,
    required this.version,
    required this.instanceId,
    required this.startedAt,
    this.submittedAt,
    this.metadata = const {},
    this.answers = const {},
    this.special,
  });
}

// ================== STATED PREFERENCE (H) SUPPORT ==================
// Optional helper for scenario sets keyed by OD pairs (e.g., AUH-DXB)
class ScenarioOption {
  final String modeId;                   // car / taxi / bus / train
  final Map<String, num> attributes;     // {time: minutes, cost: AED, headway: ...}
  const ScenarioOption({required this.modeId, this.attributes = const {}});
}

class StatedPreferenceSet {
  final String odCode;                   // e.g., "AUH-DXB"
  final List<List<ScenarioOption>> scenarios; // list of 4-mode choice sets
  final bool randomize;                  // randomize rail variant / order

  const StatedPreferenceSet({
    required this.odCode,
    required this.scenarios,
    this.randomize = true,
  });
}
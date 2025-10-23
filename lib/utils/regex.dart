class RegexPatterns {
  RegexPatterns._();

  /// Email validation
  static const email = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';

  /// 10-digit phone number (adjust as needed for international)
  static const String phone = r'^\d{8,14}$';

  /// Strong password (min 8 chars, at least 1 letter, 1 number)
  static const password = r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*?&]{8,}$';

  /// Only alphabets (no spaces)
  static const alphabets = r'^[A-Za-z]+$';

  /// Only alphabets with spaces
  static const alphabetsWithSpace = r'^[A-Za-z ]+$';

  /// Only numbers (no decimals)
  static const numbers = r'^\d+$';

  /// Alphanumeric (no special characters)
  static const alphanumeric = r'^[A-Za-z0-9]+$';

  /// Alphanumeric with spaces
  static const alphanumericWithSpace = r'^[A-Za-z0-9 ]+$';

  /// Decimal number (integer or decimal, positive only)
  static const decimalNumber = r'^\d+(\.\d+)?$';

  /// URL validation
  static const url = r'^(http|https):\/\/[^\s$.?#].[^\s]*$';

  /// Date format YYYY-MM-DD (basic check)
  static const dateYYYYMMDD = r'^\d{4}-\d{2}-\d{2}$';
}

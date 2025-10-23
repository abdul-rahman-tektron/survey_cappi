import 'dart:convert';

/// Parse JSON to ErrorResponse
ErrorResponse errorResponseFromJson(String str) =>
    ErrorResponse.fromJson(json.decode(str));

/// Convert ErrorResponse to JSON
String errorResponseToJson(ErrorResponse data) => json.encode(data.toJson());

class ErrorResponse {
  String? type;
  String? title;
  int? status;
  Errors? errors;
  String? traceId;

  ErrorResponse({
    this.type,
    this.title,
    this.status,
    this.errors,
    this.traceId,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) => ErrorResponse(
    type: json["type"],
    title: json["title"],
    status: json["status"],
    errors: json["errors"] == null ? null : Errors.fromJson(json["errors"]),
    traceId: json["traceId"],
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "title": title,
    "status": status,
    "errors": errors?.toJson(),
    "traceId": traceId,
  };

  /// Returns a user-friendly error message
  String getFriendlyMessage() {
    if (errors != null) {
      final allErrors = errors!.toMap();
      if (allErrors.isNotEmpty) {
        return allErrors.entries
            .map((e) => "${e.key}: ${e.value.join(', ')}")
            .join("\n");
      }
    }
    return title ?? "An error occurred";
  }
}

class Errors {
  /// Dynamic map to hold all possible field errors
  Map<String, List<String>> _fields = {};

  Errors({Map<String, List<String>>? fields}) {
    if (fields != null) _fields = fields;
  }

  /// Factory to parse any dynamic JSON into the map
  factory Errors.fromJson(Map<String, dynamic> json) {
    final Map<String, List<String>> temp = {};
    json.forEach((key, value) {
      if (value is List) {
        temp[key] = value.map((e) => e.toString()).toList();
      }
    });
    return Errors(fields: temp);
  }

  /// Convert back to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    _fields.forEach((key, value) {
      map[key] = value;
    });
    return map;
  }

  /// Get dynamic map
  Map<String, List<String>> toMap() => _fields;
}
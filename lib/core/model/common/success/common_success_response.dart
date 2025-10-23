// To parse this JSON data, do
//
//     final commonSuccessResponse = commonSuccessResponseFromJson(jsonString);

import 'dart:convert';

CommonSuccessResponse commonSuccessResponseFromJson(String str) => CommonSuccessResponse.fromJson(json.decode(str));

String commonSuccessResponseToJson(CommonSuccessResponse data) => json.encode(data.toJson());

class CommonSuccessResponse {
  bool? status;
  String? message;
  List<dynamic>? result;

  CommonSuccessResponse({
    this.status,
    this.message,
    this.result,
  });

  factory CommonSuccessResponse.fromJson(Map<String, dynamic> json) => CommonSuccessResponse(
    status: json["Status"],
    message: json["Message"],
    result: json["Result"] == null ? [] : List<dynamic>.from(json["Result"]!.map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "Status": status,
    "Message": message,
    "Result": result == null ? [] : List<dynamic>.from(result!.map((x) => x)),
  };
}

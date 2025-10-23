// To parse this JSON data, do
//
//     final commonBasicResponse = commonBasicResponseFromJson(jsonString);

import 'dart:convert';

CommonBasicResponse commonBasicResponseFromJson(String str) => CommonBasicResponse.fromJson(json.decode(str));

String commonBasicResponseToJson(CommonBasicResponse data) => json.encode(data.toJson());

class CommonBasicResponse {
  bool? success;
  String? message;

  CommonBasicResponse({
    this.success,
    this.message,
  });

  factory CommonBasicResponse.fromJson(Map<String, dynamic> json) => CommonBasicResponse(
    success: json["success"],
    message: json["message"],
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
  };
}

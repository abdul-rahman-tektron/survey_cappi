// To parse this JSON data, do
//
//     final commonResponse = commonResponseFromJson(jsonString);

import 'dart:convert';

CommonResponse commonResponseFromJson(String str) => CommonResponse.fromJson(json.decode(str));

String commonResponseToJson(CommonResponse data) => json.encode(data.toJson());

class CommonResponse {
  bool? success;
  String? message;
  String? uniqueId;
  DateTime? timestamp;
  dynamic data;

  CommonResponse({
    this.success,
    this.message,
    this.uniqueId,
    this.timestamp,
    this.data,
  });

  factory CommonResponse.fromJson(Map<String, dynamic> json) => CommonResponse(
    success: json["success"],
    message: json["message"],
    uniqueId: json["uniqueId"],
    timestamp: json["timestamp"] == null ? null : DateTime.parse(json["timestamp"]),
    data: json["data"],
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "uniqueId": uniqueId,
    "timestamp": timestamp?.toIso8601String(),
    "data": data,
  };
}

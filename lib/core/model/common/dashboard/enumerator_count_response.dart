// To parse this JSON data, do
//
//     final enumeratorCountResponse = enumeratorCountResponseFromJson(jsonString);

import 'dart:convert';

EnumeratorCountResponse enumeratorCountResponseFromJson(String str) => EnumeratorCountResponse.fromJson(json.decode(str));

String enumeratorCountResponseToJson(EnumeratorCountResponse data) => json.encode(data.toJson());

class EnumeratorCountResponse {
  bool? status;
  String? message;
  List<EnumeratorCountResult>? result;

  EnumeratorCountResponse({
    this.status,
    this.message,
    this.result,
  });

  factory EnumeratorCountResponse.fromJson(Map<String, dynamic> json) => EnumeratorCountResponse(
    status: json["Status"],
    message: json["Message"],
    result: json["Result"] == null ? [] : List<EnumeratorCountResult>.from(json["Result"]!.map((x) => EnumeratorCountResult.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "Status": status,
    "Message": message,
    "Result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
  };
}

class EnumeratorCountResult {
  int? totalEnumerators;
  dynamic totalRsiTargetSurveys;
  int? totalRsiSurveysCompleted;
  int? todayRsiSurveysCompleted;
  int? todayRsiSurveysApproached;
  dynamic totalPassengerTargetSurveys;
  int? totalPassengerSurveysCompleted;
  int? todayPassengerSurveysCompleted;
  int? todayPassengerSurveysApproached;

  EnumeratorCountResult({
    this.totalEnumerators,
    this.totalRsiTargetSurveys,
    this.totalRsiSurveysCompleted,
    this.todayRsiSurveysCompleted,
    this.todayRsiSurveysApproached,
    this.totalPassengerTargetSurveys,
    this.totalPassengerSurveysCompleted,
    this.todayPassengerSurveysCompleted,
    this.todayPassengerSurveysApproached,
  });

  factory EnumeratorCountResult.fromJson(Map<String, dynamic> json) => EnumeratorCountResult(
    totalEnumerators: json["TotalEnumerators"],
    totalRsiTargetSurveys: json["TotalRSITargetSurveys"],
    totalRsiSurveysCompleted: json["TotalRSISurveysCompleted"],
    todayRsiSurveysCompleted: json["TodayRSISurveysCompleted"],
    todayRsiSurveysApproached: json["TodayRSISurveysApproached"],
    totalPassengerTargetSurveys: json["TotalPassengerTargetSurveys"],
    totalPassengerSurveysCompleted: json["TotalPassengerSurveysCompleted"],
    todayPassengerSurveysCompleted: json["TodayPassengerSurveysCompleted"],
    todayPassengerSurveysApproached: json["TodayPassengerSurveysApproached"],
  );

  Map<String, dynamic> toJson() => {
    "TotalEnumerators": totalEnumerators,
    "TotalRSITargetSurveys": totalRsiTargetSurveys,
    "TotalRSISurveysCompleted": totalRsiSurveysCompleted,
    "TodayRSISurveysCompleted": todayRsiSurveysCompleted,
    "TodayRSISurveysApproached": todayRsiSurveysApproached,
    "TotalPassengerTargetSurveys": totalPassengerTargetSurveys,
    "TotalPassengerSurveysCompleted": totalPassengerSurveysCompleted,
    "TodayPassengerSurveysCompleted": todayPassengerSurveysCompleted,
    "TodayPassengerSurveysApproached": todayPassengerSurveysApproached,
  };
}

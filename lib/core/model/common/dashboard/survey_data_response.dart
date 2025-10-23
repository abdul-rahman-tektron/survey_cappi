// To parse this JSON data, do
//
//     final surveyDataResponse = surveyDataResponseFromJson(jsonString);

import 'dart:convert';

SurveyDataResponse surveyDataResponseFromJson(String str) => SurveyDataResponse.fromJson(json.decode(str));

String surveyDataResponseToJson(SurveyDataResponse data) => json.encode(data.toJson());

class SurveyDataResponse {
  bool? status;
  String? message;
  List<SurveyDetail>? result;

  SurveyDataResponse({
    this.status,
    this.message,
    this.result,
  });

  factory SurveyDataResponse.fromJson(Map<String, dynamic> json) => SurveyDataResponse(
    status: json["Status"],
    message: json["Message"],
    result: json["Result"] == null ? [] : List<SurveyDetail>.from(json["Result"]!.map((x) => SurveyDetail.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "Status": status,
    "Message": message,
    "Result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
  };
}

class SurveyDetail {
  int? recordId;
  String? name;
  String? surveyType;
  DateTime? surveyDate;
  String? status;
  String? sourceTable;

  SurveyDetail({
    this.recordId,
    this.name,
    this.surveyType,
    this.surveyDate,
    this.status,
    this.sourceTable,
  });

  factory SurveyDetail.fromJson(Map<String, dynamic> json) => SurveyDetail(
    recordId: json["RecordID"],
    name: json["Name"],
    surveyType: json["SurveyType"],
    surveyDate: json["SurveyDate"] == null ? null : DateTime.parse(json["SurveyDate"]),
    status: json["Status"],
    sourceTable: json["SourceTable"],
  );

  Map<String, dynamic> toJson() => {
    "RecordID": recordId,
    "Name": name,
    "SurveyType": surveyType,
    "SurveyDate": surveyDate?.toIso8601String(),
    "Status": status,
    "SourceTable": sourceTable,
  };
}

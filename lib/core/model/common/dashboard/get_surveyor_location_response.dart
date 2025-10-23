// To parse this JSON data, do
//
//     final getSurveyorLocationResponse = getSurveyorLocationResponseFromJson(jsonString);

import 'dart:convert';

GetSurveyorLocationResponse getSurveyorLocationResponseFromJson(String str) => GetSurveyorLocationResponse.fromJson(json.decode(str));

String getSurveyorLocationResponseToJson(GetSurveyorLocationResponse data) => json.encode(data.toJson());

class GetSurveyorLocationResponse {
  bool? status;
  String? message;
  GetSurveyorLocationResult? result;

  GetSurveyorLocationResponse({
    this.status,
    this.message,
    this.result,
  });

  factory GetSurveyorLocationResponse.fromJson(Map<String, dynamic> json) => GetSurveyorLocationResponse(
    status: json["Status"],
    message: json["Message"],
    result: json["Result"] == null ? null : GetSurveyorLocationResult.fromJson(json["Result"]),
  );

  Map<String, dynamic> toJson() => {
    "Status": status,
    "Message": message,
    "Result": result?.toJson(),
  };
}

class GetSurveyorLocationResult {
  List<GetSurveyorLocationData>? table;

  GetSurveyorLocationResult({
    this.table,
  });

  factory GetSurveyorLocationResult.fromJson(Map<String, dynamic> json) => GetSurveyorLocationResult(
    table: json["Table"] == null ? [] : List<GetSurveyorLocationData>.from(json["Table"]!.map((x) => GetSurveyorLocationData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "Table": table == null ? [] : List<dynamic>.from(table!.map((x) => x.toJson())),
  };
}

class GetSurveyorLocationData {
  int? nCreatedBy;
  String? surveyor;
  int? roleId;
  String? roleName;
  String? surveyType;
  int? targets;
  int? totalInterviews;
  double? sLattitudeActual;
  double? sLongitudeActual;
  DateTime? lastSeen;
  DateTime? dtRecorded;

  GetSurveyorLocationData({
    this.nCreatedBy,
    this.surveyor,
    this.roleId,
    this.roleName,
    this.surveyType,
    this.targets,
    this.totalInterviews,
    this.sLattitudeActual,
    this.sLongitudeActual,
    this.lastSeen,
    this.dtRecorded,
  });

  factory GetSurveyorLocationData.fromJson(Map<String, dynamic> json) => GetSurveyorLocationData(
    nCreatedBy: json["N_CreatedBy"],
    surveyor: json["Surveyor"],
    roleId: json["RoleID"],
    roleName: json["RoleName"],
    surveyType: json["SurveyType"],
    targets: json["Targets"],
    totalInterviews: json["TotalInterviews"],
    sLattitudeActual: json["S_Lattitude_Actual"]?.toDouble(),
    sLongitudeActual: json["S_Longitude_Actual"]?.toDouble(),
    lastSeen: json["LastSeen"] == null ? null : DateTime.parse(json["LastSeen"]),
    dtRecorded: json["Dt_Recorded"] == null ? null : DateTime.parse(json["Dt_Recorded"]),
  );

  Map<String, dynamic> toJson() => {
    "N_CreatedBy": nCreatedBy,
    "Surveyor": surveyor,
    "RoleID": roleId,
    "RoleName": roleName,
    "SurveyType": surveyType,
    "Targets": targets,
    "TotalInterviews": totalInterviews,
    "S_Lattitude_Actual": sLattitudeActual,
    "S_Longitude_Actual": sLongitudeActual,
    "LastSeen": lastSeen?.toIso8601String(),
    "Dt_Recorded": dtRecorded?.toIso8601String(),
  };
}

// To parse this JSON data, do
//
//     final getSurveyorDataRequest = getSurveyorDataRequestFromJson(jsonString);

import 'dart:convert';

GetSurveyorDataRequest getSurveyorDataRequestFromJson(String str) => GetSurveyorDataRequest.fromJson(json.decode(str));

String getSurveyorDataRequestToJson(GetSurveyorDataRequest data) => json.encode(data.toJson());

class GetSurveyorDataRequest {
  String? fromDate;
  String? toDate;
  int? nStatus;
  int? nSurveyType;
  int? nPageNumber;
  int? nPageSize;
  String? sFullName;

  GetSurveyorDataRequest({
    this.fromDate,
    this.toDate,
    this.nStatus,
    this.nSurveyType,
    this.nPageNumber,
    this.nPageSize,
    this.sFullName,
  });

  factory GetSurveyorDataRequest.fromJson(Map<String, dynamic> json) => GetSurveyorDataRequest(
    fromDate: json["FromDate"],
    toDate: json["ToDate"],
    nStatus: json["N_Status"],
    nSurveyType: json["N_SurveyType"],
    nPageNumber: json["N_PageNumber"],
    nPageSize: json["N_PageSize"],
    sFullName: json["S_FullName"],
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    void addIfNotNull(String key, dynamic value) {
      if (value != null) data[key] = value;
    }

    addIfNotNull("FromDate", fromDate);
    addIfNotNull("ToDate", toDate);
    addIfNotNull("N_Status", nStatus);
    addIfNotNull("N_SurveyType", nSurveyType);
    addIfNotNull("N_PageNumber", nPageNumber);
    addIfNotNull("N_PageSize", nPageSize);
    addIfNotNull("S_FullName", sFullName);

    return data;
  }
}

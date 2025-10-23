// To parse this JSON data, do
//
//     final getSurveyorDataResponse = getSurveyorDataResponseFromJson(jsonString);

import 'dart:convert';

GetSurveyorDataResponse getSurveyorDataResponseFromJson(String str) => GetSurveyorDataResponse.fromJson(json.decode(str));

String getSurveyorDataResponseToJson(GetSurveyorDataResponse data) => json.encode(data.toJson());

class GetSurveyorDataResponse {
  bool? status;
  String? message;
  GetSurveyDataResult? result;

  GetSurveyorDataResponse({
    this.status,
    this.message,
    this.result,
  });

  factory GetSurveyorDataResponse.fromJson(Map<String, dynamic> json) => GetSurveyorDataResponse(
    status: json["Status"],
    message: json["Message"],
    result: json["Result"] == null ? null : GetSurveyDataResult.fromJson(json["Result"]),
  );

  Map<String, dynamic> toJson() => {
    "Status": status,
    "Message": message,
    "Result": result?.toJson(),
  };
}

class GetSurveyDataResult {
  List<Table>? table;
  List<Table1>? table1;

  GetSurveyDataResult({
    this.table,
    this.table1,
  });

  factory GetSurveyDataResult.fromJson(Map<String, dynamic> json) => GetSurveyDataResult(
    table: json["Table"] == null ? [] : List<Table>.from(json["Table"]!.map((x) => Table.fromJson(x))),
    table1: json["Table1"] == null ? [] : List<Table1>.from(json["Table1"]!.map((x) => Table1.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "Table": table == null ? [] : List<dynamic>.from(table!.map((x) => x.toJson())),
    "Table1": table1 == null ? [] : List<dynamic>.from(table1!.map((x) => x.toJson())),
  };
}

class Table {
  int? id;
  String? sFullName;
  String? sSurveyType;
  int? nSurveyType;
  DateTime? dtCreatedDate;
  int? nStatus; // ✅ change from String? → int?

  Table({
    this.id,
    this.sFullName,
    this.sSurveyType,
    this.nSurveyType,
    this.dtCreatedDate,
    this.nStatus,
  });

  factory Table.fromJson(Map<String, dynamic> json) => Table(
    id: json["ID"],
    sFullName: json["S_FullName"],
    sSurveyType: json["S_SurveyType"],
    nSurveyType: _toInt(json["N_SurveyType"]),
    dtCreatedDate: _toDate(json["Dt_CreatedDate"]),
    nStatus: _toInt(json["N_Status"]), // ✅ safely handles "0"/"1"
  );

  Map<String, dynamic> toJson() => {
    "ID": id,
    "S_FullName": sFullName,
    "S_SurveyType": sSurveyType,
    "N_SurveyType": nSurveyType,
    "Dt_CreatedDate": dtCreatedDate?.toIso8601String(),
    "N_Status": nStatus,
  };

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final s = v.toString().trim();
    return s.isEmpty ? null : int.tryParse(s);
  }
}

class Table1 {
  int? totalCount;

  Table1({
    this.totalCount,
  });

  factory Table1.fromJson(Map<String, dynamic> json) => Table1(
    totalCount: json["TotalCount"],
  );

  Map<String, dynamic> toJson() => {
    "TotalCount": totalCount,
  };
}

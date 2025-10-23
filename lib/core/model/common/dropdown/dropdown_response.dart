// To parse this JSON data, do
//
//     final dropdownResponse = dropdownResponseFromJson(jsonString);

import 'dart:convert';

DropdownResponse dropdownResponseFromJson(String str) => DropdownResponse.fromJson(json.decode(str));

String dropdownResponseToJson(DropdownResponse data) => json.encode(data.toJson());

class DropdownResponse {
  bool? status;
  String? message;
  List<DropdownData>? result;

  DropdownResponse({
    this.status,
    this.message,
    this.result,
  });

  factory DropdownResponse.fromJson(Map<String, dynamic> json) => DropdownResponse(
    status: json["Status"],
    message: json["Message"],
    result: json["Result"] == null ? [] : List<DropdownData>.from(json["Result"]!.map((x) => DropdownData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "Status": status,
    "Message": message,
    "Result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
  };
}

class DropdownData {
  int? nDetailedCode;
  int? nMasterCode;
  String? detailedNameA;
  String? detailedNameE;
  String? masterNameA;
  String? masterNameE;
  String? sUniqueCode;
  String? sMasterUniqueCode;
  dynamic sDescription;

  DropdownData({
    this.nDetailedCode,
    this.nMasterCode,
    this.detailedNameA,
    this.detailedNameE,
    this.masterNameA,
    this.masterNameE,
    this.sUniqueCode,
    this.sMasterUniqueCode,
    this.sDescription,
  });

  factory DropdownData.fromJson(Map<String, dynamic> json) => DropdownData(
    nDetailedCode: json["N_DetailedCode"],
    nMasterCode: json["N_MasterCode"],
    detailedNameA: json["DetailedName_A"],
    detailedNameE: json["DetailedName_E"],
    masterNameA: json["MasterName_A"],
    masterNameE: json["MasterName_E"],
    sUniqueCode: json["S_UniqueCode"],
    sMasterUniqueCode: json["S_MasterUniqueCode"],
    sDescription: json["S_Description"],
  );

  Map<String, dynamic> toJson() => {
    "N_DetailedCode": nDetailedCode,
    "N_MasterCode": nMasterCode,
    "DetailedName_A": detailedNameA,
    "DetailedName_E": detailedNameE,
    "MasterName_A": masterNameA,
    "MasterName_E": masterNameE,
    "S_UniqueCode": sUniqueCode,
    "S_MasterUniqueCode": sMasterUniqueCode,
    "S_Description": sDescription,
  };
}

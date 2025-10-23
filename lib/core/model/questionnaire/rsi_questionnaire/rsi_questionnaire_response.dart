// To parse this JSON data, do
//
//     final addRsiResponse = addRsiResponseFromJson(jsonString);

import 'dart:convert';

AddRsiResponse addRsiResponseFromJson(String str) => AddRsiResponse.fromJson(json.decode(str));

String addRsiResponseToJson(AddRsiResponse data) => json.encode(data.toJson());

class AddRsiResponse {
  bool? status;
  String? message;
  List<AddRSIData>? result;

  AddRsiResponse({
    this.status,
    this.message,
    this.result,
  });

  factory AddRsiResponse.fromJson(Map<String, dynamic> json) => AddRsiResponse(
    status: json["Status"],
    message: json["Message"],
    result: json["Result"] == null ? [] : List<AddRSIData>.from(json["Result"]!.map((x) => AddRSIData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "Status": status,
    "Message": message,
    "Result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
  };
}

class AddRSIData {
  int? nPassengerRsiid;

  AddRSIData({
    this.nPassengerRsiid,
  });

  factory AddRSIData.fromJson(Map<String, dynamic> json) => AddRSIData(
    nPassengerRsiid: json["N_PassengerRSIID"],
  );

  Map<String, dynamic> toJson() => {
    "N_PassengerRSIID": nPassengerRsiid,
  };
}

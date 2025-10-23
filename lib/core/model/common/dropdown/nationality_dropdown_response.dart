// To parse this JSON data, do
//
//     final nationalityDropdownResponse = nationalityDropdownResponseFromJson(jsonString);

import 'dart:convert';

NationalityDropdownResponse nationalityDropdownResponseFromJson(String str) =>
    NationalityDropdownResponse.fromJson(json.decode(str));

String nationalityDropdownResponseToJson(NationalityDropdownResponse data) =>
    json.encode(data.toJson());

class NationalityDropdownResponse {
  bool? status;
  String? message;
  List<NationalityDropdownDetail>? result;

  NationalityDropdownResponse({this.status, this.message, this.result});

  factory NationalityDropdownResponse.fromJson(Map<String, dynamic> json) =>
      NationalityDropdownResponse(
        status: json["Status"],
        message: json["Message"],
        result: json["Result"] == null
            ? []
            : List<NationalityDropdownDetail>.from(
                json["Result"]!.map((x) => NationalityDropdownDetail.fromJson(x)),
              ),
      );

  Map<String, dynamic> toJson() => {
    "Status": status,
    "Message": message,
    "Result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
  };
}

class NationalityDropdownDetail {
  int? id;
  String? name;
  String? nameAr;
  String? iso3;
  String? folderflag;
  String? flag;

  NationalityDropdownDetail({
    this.id,
    this.name,
    this.nameAr,
    this.iso3,
    this.folderflag,
    this.flag,
  });

  factory NationalityDropdownDetail.fromJson(Map<String, dynamic> json) =>
      NationalityDropdownDetail(
        id: json["id"],
        name: json["name"],
        nameAr: json["name_Ar"],
        iso3: json["iso3"],
        folderflag: json["folderflag"],
        flag: json["Flag"],
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "name_Ar": nameAr,
    "iso3": iso3,
    "folderflag": folderflag,
    "Flag": flag,
  };
}

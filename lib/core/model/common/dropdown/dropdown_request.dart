// To parse this JSON data, do
//
//     final dropdownRequest = dropdownRequestFromJson(jsonString);

import 'dart:convert';

DropdownRequest dropdownRequestFromJson(String str) => DropdownRequest.fromJson(json.decode(str));

String dropdownRequestToJson(DropdownRequest data) => json.encode(data.toJson());

class DropdownRequest {
  int? nMasterCode;

  DropdownRequest({
    this.nMasterCode,
  });

  factory DropdownRequest.fromJson(Map<String, dynamic> json) => DropdownRequest(
    nMasterCode: json["N_MasterCode"],
  );

  Map<String, dynamic> toJson() => {
    "N_MasterCode": nMasterCode,
  };
}

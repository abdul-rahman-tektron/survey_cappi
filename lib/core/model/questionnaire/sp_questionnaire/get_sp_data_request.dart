// To parse this JSON data, do
//
//     final getSpDataRequest = getSpDataRequestFromJson(jsonString);

import 'dart:convert';

GetSpDataRequest getSpDataRequestFromJson(String str) => GetSpDataRequest.fromJson(json.decode(str));

String getSpDataRequestToJson(GetSpDataRequest data) => json.encode(data.toJson());

class GetSpDataRequest {
  String? sOdForSp;
  String? sDestination;
  String? sCarOwner;
  String? sHsRailElig;

  GetSpDataRequest({
    this.sOdForSp,
    this.sDestination,
    this.sCarOwner,
    this.sHsRailElig,
  });

  factory GetSpDataRequest.fromJson(Map<String, dynamic> json) => GetSpDataRequest(
    sOdForSp: json["S_ODForSP"],
    sDestination: json["S_Destination"],
    sCarOwner: json["S_CarOwner"],
    sHsRailElig: json["S_HSRailElig"],
  );

  Map<String, dynamic> toJson() => {
    "S_ODForSP": sOdForSp,
    "S_Destination": sDestination,
    "S_CarOwner": sCarOwner,
    "S_HSRailElig": sHsRailElig,
  };
}

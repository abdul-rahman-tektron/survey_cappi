// To parse this JSON data, do
//
//     final getPassengerDataRequest = getPassengerDataRequestFromJson(jsonString);

import 'dart:convert';

GetPassengerDataRequest getPassengerDataRequestFromJson(String str) => GetPassengerDataRequest.fromJson(json.decode(str));

String getPassengerDataRequestToJson(GetPassengerDataRequest data) => json.encode(data.toJson());

class GetPassengerDataRequest {
  int? nPassengerRsiid;

  GetPassengerDataRequest({
    this.nPassengerRsiid,
  });

  factory GetPassengerDataRequest.fromJson(Map<String, dynamic> json) => GetPassengerDataRequest(
    nPassengerRsiid: json["N_PassengerRSIID"],
  );

  Map<String, dynamic> toJson() => {
    "N_PassengerRSIID": nPassengerRsiid,
  };
}

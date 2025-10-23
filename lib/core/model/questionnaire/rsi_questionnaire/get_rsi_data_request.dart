// To parse this JSON data, do
//
//     final getRsiDataRequest = getRsiDataRequestFromJson(jsonString);

import 'dart:convert';

GetRsiDataRequest getRsiDataRequestFromJson(String str) => GetRsiDataRequest.fromJson(json.decode(str));

String getRsiDataRequestToJson(GetRsiDataRequest data) => json.encode(data.toJson());

class GetRsiDataRequest {
  int? nRsiid;

  GetRsiDataRequest({
    this.nRsiid,
  });

  factory GetRsiDataRequest.fromJson(Map<String, dynamic> json) => GetRsiDataRequest(
    nRsiid: json["N_RSIID"],
  );

  Map<String, dynamic> toJson() => {
    "N_RSIID": nRsiid,
  };
}

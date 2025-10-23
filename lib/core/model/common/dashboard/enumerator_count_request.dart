// To parse this JSON data, do
//
//     final enumeratorCountRequest = enumeratorCountRequestFromJson(jsonString);

import 'dart:convert';

EnumeratorCountRequest enumeratorCountRequestFromJson(String str) => EnumeratorCountRequest.fromJson(json.decode(str));

String enumeratorCountRequestToJson(EnumeratorCountRequest data) => json.encode(data.toJson());

class EnumeratorCountRequest {
  int? nUserId;

  EnumeratorCountRequest({
    this.nUserId,
  });

  factory EnumeratorCountRequest.fromJson(Map<String, dynamic> json) => EnumeratorCountRequest(
    nUserId: json["N_UserID"],
  );

  Map<String, dynamic> toJson() => {
    "N_UserID": nUserId,
  };
}

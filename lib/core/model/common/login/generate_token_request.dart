// To parse this JSON data, do
//
//     final generateTokenRequest = generateTokenRequestFromJson(jsonString);

import 'dart:convert';

GenerateTokenRequest generateTokenRequestFromJson(String str) => GenerateTokenRequest.fromJson(json.decode(str));

String generateTokenRequestToJson(GenerateTokenRequest data) => json.encode(data.toJson());

class GenerateTokenRequest {
  String? userName;
  String? password;
  String? grantType;

  GenerateTokenRequest({
    this.userName,
    this.password,
    this.grantType,
  });

  factory GenerateTokenRequest.fromJson(Map<String, dynamic> json) => GenerateTokenRequest(
    userName: json["UserName"],
    password: json["Password"],
    grantType: json["GrantType"],
  );

  Map<String, dynamic> toJson() => {
    "UserName": userName,
    "Password": password,
    "GrantType": grantType,
  };
}
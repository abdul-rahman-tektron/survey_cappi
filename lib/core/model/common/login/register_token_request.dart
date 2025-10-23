// To parse this JSON data, do
//
//     final registerTokenRequest = registerTokenRequestFromJson(jsonString);

import 'dart:convert';

RegisterTokenRequest registerTokenRequestFromJson(String str) => RegisterTokenRequest.fromJson(json.decode(str));

String registerTokenRequestToJson(RegisterTokenRequest data) => json.encode(data.toJson());

class RegisterTokenRequest {
  String? userId;
  String? token;

  RegisterTokenRequest({
    this.userId,
    this.token,
  });

  factory RegisterTokenRequest.fromJson(Map<String, dynamic> json) => RegisterTokenRequest(
    userId: json["userId"],
    token: json["token"],
  );

  Map<String, dynamic> toJson() => {
    "userId": userId,
    "token": token,
  };
}

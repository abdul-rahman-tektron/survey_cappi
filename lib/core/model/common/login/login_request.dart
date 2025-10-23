// To parse this JSON data, do
//
//     final loginRequest = loginRequestFromJson(jsonString);

import 'dart:convert';

LoginRequest loginRequestFromJson(String str) => LoginRequest.fromJson(json.decode(str));

String loginRequestToJson(LoginRequest data) => json.encode(data.toJson());

class LoginRequest {
  int? userId;
  String? username;
  String? password;

  LoginRequest({
    this.userId,
    this.username,
    this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) => LoginRequest(
    userId: json["user_id"],
    username: json["username"],
    password: json["password"],
  );

  Map<String, dynamic> toJson() => {
    "user_id": userId,
    "username": username,
    "password": password,
  };
}


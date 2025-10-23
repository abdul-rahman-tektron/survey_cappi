// To parse this JSON data, do
//
//     final generateTokenResponse = generateTokenResponseFromJson(jsonString);

import 'dart:convert';

GenerateTokenResponse generateTokenResponseFromJson(String str) => GenerateTokenResponse.fromJson(json.decode(str));

String generateTokenResponseToJson(GenerateTokenResponse data) => json.encode(data.toJson());

class GenerateTokenResponse {
  String? accessToken;
  String? tokenType;
  int? expiresIn;
  String? refreshToken;
  String? error;

  GenerateTokenResponse({
    this.accessToken,
    this.tokenType,
    this.expiresIn,
    this.refreshToken,
    this.error,
  });

  factory GenerateTokenResponse.fromJson(Map<String, dynamic> json) => GenerateTokenResponse(
    accessToken: json["access_token"],
    tokenType: json["token_type"],
    expiresIn: json["expires_in"],
    refreshToken: json["refresh_token"],
    error: json["error"],
  );

  Map<String, dynamic> toJson() => {
    "access_token": accessToken,
    "token_type": tokenType,
    "expires_in": expiresIn,
    "refresh_token": refreshToken,
    "error": error,
  };
}

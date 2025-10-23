// To parse this JSON data, do
//
//     final loginResponse = loginResponseFromJson(jsonString);

import 'dart:convert';

LoginResponse loginResponseFromJson(String str) => LoginResponse.fromJson(json.decode(str));

String loginResponseToJson(LoginResponse data) => json.encode(data.toJson());

class LoginResponse {
  bool? status;
  String? message;
  List<LoginDetail>? result;

  LoginResponse({
    this.status,
    this.message,
    this.result,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    status: json["Status"],
    message: json["Message"],
    result: json["Result"] == null ? [] : List<LoginDetail>.from(json["Result"]!.map((x) => LoginDetail.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "Status": status,
    "Message": message,
    "Result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
  };
}

class LoginDetail {
  int? userId;
  String? firstname;
  String? lastname;
  String? fullname;
  String? username;
  String? password;
  String? email;
  dynamic sPhotoUpload;
  dynamic sPhotoContentType;
  String? mobile;
  int? isDeleted;
  int? nUserId;
  int? nRoleId;
  int? nIsAdUser;

  LoginDetail({
    this.userId,
    this.firstname,
    this.lastname,
    this.fullname,
    this.username,
    this.password,
    this.email,
    this.sPhotoUpload,
    this.sPhotoContentType,
    this.mobile,
    this.isDeleted,
    this.nUserId,
    this.nRoleId,
    this.nIsAdUser,
  });

  factory LoginDetail.fromJson(Map<String, dynamic> json) => LoginDetail(
    userId: json["user_id"],
    firstname: json["firstname"],
    lastname: json["lastname"],
    fullname: json["fullname"],
    username: json["username"],
    password: json["password"],
    email: json["email"],
    sPhotoUpload: json["S_PhotoUpload"],
    sPhotoContentType: json["S_PhotoContentType"],
    mobile: json["mobile"],
    isDeleted: json["Is_Deleted"],
    nUserId: json["N_UserID"],
    nRoleId: json["N_RoleID"],
    nIsAdUser: json["N_IsADUser"],
  );

  Map<String, dynamic> toJson() => {
    "user_id": userId,
    "firstname": firstname,
    "lastname": lastname,
    "fullname": fullname,
    "username": username,
    "password": password,
    "email": email,
    "S_PhotoUpload": sPhotoUpload,
    "S_PhotoContentType": sPhotoContentType,
    "mobile": mobile,
    "Is_Deleted": isDeleted,
    "N_UserID": nUserId,
    "N_RoleID": nRoleId,
    "N_IsADUser": nIsAdUser,
  };
}

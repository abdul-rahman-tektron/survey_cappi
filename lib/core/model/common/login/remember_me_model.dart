class RememberMeModel {
  final String userName;
  final String password;

  RememberMeModel({
    required this.userName,
    required this.password,
  });

  factory RememberMeModel.fromJson(Map<String, dynamic> json) {
    return RememberMeModel(
      userName: json['userName'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'userName': userName, 'password': password};
  }
}

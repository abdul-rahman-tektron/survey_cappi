import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:srpf/core/base/base_notifier.dart';
import 'package:srpf/core/model/common/login/generate_token_request.dart';
import 'package:srpf/core/model/common/login/generate_token_response.dart';
import 'package:srpf/core/model/common/login/login_request.dart';
import 'package:srpf/core/model/common/login/login_response.dart';
import 'package:srpf/core/model/common/login/remember_me_model.dart';
import 'package:srpf/core/remote/services/common_repository.dart';
import 'package:srpf/res/strings.dart';
import 'package:srpf/utils/helpers/toast_helper.dart';
import 'package:srpf/utils/router/routes.dart';
import 'package:srpf/utils/storage/hive_storage.dart';
import 'package:srpf/utils/storage/secure_storage.dart';

class LoginNotifier extends BaseChangeNotifier {
  // Controllers
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  bool isChecked = false;

  LoginNotifier() {
    rememberMeData();
  }

  @override
  void dispose() {
    userNameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> performLogin(BuildContext context) async {
    if (isLoading) return; // prevent double-taps
    if (!validateAndSave()) return;

    _setLoading(true);

    final username = userNameController.text.trim();
    final password = passwordController.text.trim();

    try {
      // 1) Generate token
      final tokenReq = GenerateTokenRequest(userName: "vmsuser", password: "Vms!@#\$");
      final tokenRes = await CommonRepository.instance.apiGenerateToken(tokenReq);

      if (tokenRes is! GenerateTokenResponse) {
        ToastHelper.showError('Unable to authenticate. Please try again.');
        _setLoading(false);
        return;
      }

      final accessToken = tokenRes.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        ToastHelper.showError(tokenRes.error ?? 'Token not received.');
        _setLoading(false);
        return;
      }

      // Save token before login so repository can attach it to headers
      await SecureStorageService.setToken(accessToken);

      // 2) Login details
      final loginReq = LoginRequest(
        username: username,
        password: password,
        userId: 0,
      );

      final loginRes = await CommonRepository.instance.apiLogin(loginReq);

      if (loginRes is! LoginResponse) {
        ToastHelper.showError('Login failed. Please try again.');
        _setLoading(false);
        return;
      }

      if (loginRes.status != true) {
        // optional: clear token on failure
        await SecureStorageService.setToken('');
        ToastHelper.showError(loginRes.message ?? 'Invalid username or password.');
        _setLoading(false);
        return;
      }

      // 3) Persist user information
      final userJson = jsonEncode((loginRes.result?.isNotEmpty ?? false) ? loginRes.result![0] : {});
      await HiveStorageService.setUserData(userJson);

      // 4) Remember me (optional)
      await _handleRememberMe();

      ToastHelper.showSuccess('Login successful');

      // 5) Navigate
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e, st) {
      // Don’t print secrets; generic message for user, details for debug
      debugPrint('Login error: $e\n$st');
      ToastHelper.showError('An unexpected error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  bool validateAndSave() {
    final form = formKey.currentState;
    if (form == null) return false;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  Future<void> _handleRememberMe() async {
    if (isChecked) {
      final remember = RememberMeModel(
        userName: userNameController.text,
        password: passwordController.text,
      );
      await HiveStorageService.setRememberMe(jsonEncode(remember));
    } else {
      await HiveStorageService.remove(AppStrings.rememberMeKey);
    }
  }

  void toggleRememberMe(bool? value) {
    isChecked = value ?? false;
    notifyListeners();
  }

  Future<void> rememberMeData() async {
    final data = HiveStorageService.getRememberMe();

    if (data == null) return;
    try {
      final remember = RememberMeModel.fromJson(jsonDecode(data));
      userNameController.text = remember.userName;
      passwordController.text = remember.password;
      isChecked = true;
      notifyListeners();
    } catch (_) {
      // corrupted remember-me; clear it
      await HiveStorageService.remove(AppStrings.rememberMeKey);
    }
  }

  void _setLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }
}
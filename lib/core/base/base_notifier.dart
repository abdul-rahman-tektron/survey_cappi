import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:srpf/core/model/common/login/login_response.dart';
import 'package:srpf/utils/enums.dart';
import 'package:srpf/utils/storage/hive_storage.dart';

abstract class BaseChangeNotifier with ChangeNotifier {
  // ----- Private Fields -----
  String _userRole = '';
  bool _isLoading = false;
  LoadingState _loadingState = LoadingState.idle;
  bool _disposed = false;


  // ----- Getters -----
  String get userRole => _userRole;
  bool get isLoading => _isLoading;
  LoadingState get loadingState => _loadingState;

  LoginDetail? _userData;
  LoginDetail? get userData => _userData;


  // ----- Setters with Notification -----
  set userRole(String value) {
    if (value != _userRole && value.length >= 2) {
      _userRole = value;
      notifyListeners();
    }
  }

  set isLoading(bool value) {
    if (value != _isLoading) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void setLoadingState(LoadingState state) {
    if (state != _loadingState) {
      _loadingState = state;
      notifyListeners();
    }
  }

  Future<void> loadUserRole() async {
    // final role = HiveStorageService.getUserCategory();
    // if (role != null) {
    //   _userRole = role;
    //   notifyListeners();
    // }
  }

  Future<void> loadUserData() async {
    final userJson = HiveStorageService.getUserData();
    if (userJson != null) {
      _userData = LoginDetail.fromJson(jsonDecode(userJson));
      notifyListeners();
    }
  }

  Future<void> runWithLoadingVoid(Future<void> Function() task, {BaseChangeNotifier? target}) async {
    final notifier = target ?? this;
    try {
      notifier.setLoadingState(LoadingState.busy);
      await task();
    } finally {
      notifier.setLoadingState(LoadingState.idle);
    }
  }

  // ----- Shared Preference Loader -----
  // Future<void> loadData() async {
  //   final value = await SharedPreferencesMobileWeb.instance.getCountry('country');
  //   countryBName = value ?? '';
  // }

  // ----- Safe Notify -----
  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ----- Optional Logger -----
  void logPrint(Object? object) {
    const int chunkSize = 1000;
    final text = object?.toString() ?? '';
    for (int i = 0; i < text.length; i += chunkSize) {
      debugPrint(text.substring(i, i + chunkSize > text.length ? text.length : i + chunkSize));
    }
  }
}

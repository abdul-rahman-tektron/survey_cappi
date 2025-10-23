import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:srpf/core/remote/network/api_url.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:srpf/main.dart';
import 'package:srpf/utils/enums.dart';
import 'package:srpf/utils/helpers/app_crash_report.dart';
import 'package:srpf/utils/router/routes.dart';
import 'package:srpf/utils/storage/hive_storage.dart';
import 'package:srpf/utils/storage/secure_storage.dart';


/// Standardized API error model
class ApiError {
  final int statusCode;
  final String message;
  final dynamic raw;

  ApiError({required this.statusCode, required this.message, this.raw});
}

class NetworkRepository {
  NetworkRepository._internal() {
    _dio.interceptors.add(_buildInterceptor());
  }

  static final NetworkRepository _instance = NetworkRepository._internal();

  factory NetworkRepository() => _instance;

  bool _authRedirecting = false;

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static final BaseOptions _baseOptions = BaseOptions(
    baseUrl: ApiUrls.baseUrl,
    responseType: ResponseType.json,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 60),
  );

  final Dio _dio = Dio(_baseOptions);

// inside NetworkRepository._buildInterceptor()
  InterceptorsWrapper _buildInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        _logger.i("➡️ Request => ${options.method} ${options.uri}");
        if (options.data != null) {
          _logger.d("Request Body: ${options.data}");
          log("Request Body Log: ${options.data}");
        }

        // Save a friendly apiName + request snapshot to use later
        // You can override apiName by setting options.extra['apiName'] when calling.
        options.extra['apiName'] = options.extra['apiName'] ?? options.path;
        options.extra['requestBody'] = options.data;

        handler.next(options);
      },
      onResponse: (response, handler) async {
        _logger.i("✅ Response [${response.statusCode}] from ${response.realUri}");
        _logger.d("Response Data: ${jsonEncode(response.data)}");
        log("Response Data: ${jsonEncode(response.data)}");

        // If API returned a failure that you consider an "issue", record it
        try {
          final isHttpOk = (response.statusCode ?? 0) >= 200 && (response.statusCode ?? 0) < 300;

          // Example: backend returns {Status:false,...} to signal failure
          final bool backendFailed = (response.data is Map) &&
              ((response.data['Status'] == false) || (response.data['status'] == false));

          if (!isHttpOk || backendFailed) {
            final apiName = (response.requestOptions.extra['apiName'] ?? response.requestOptions.path).toString();
            final req = response.requestOptions.extra['requestBody'];
            final res = response.data;

            final uid = SessionContext.userId();
            final uname = SessionContext.userName();

            await AppCrashReporter.reportApiIssue(
              apiName: apiName,
              requestBody: req,
              responseBody: res,
              statusCode: response.statusCode,
              userId: uid,
              userName: uname,
              timestamp: DateTime.now(),
            );
          }

          // Handle unauthorized → redirect to login (your existing logic)
          if (response.statusCode == 200 && response.data is Map) {
            final map = response.data as Map;
            final status = map['Status'];
            final message = (map['Message'] ?? '').toString().toLowerCase();
            if (status == false && message.contains('unauthorized')) {
              await _redirectToLogin();
              return;
            }
          }
        } catch (_) {}

        handler.next(response);
      },
      onError: (DioException e, handler) async {
        _logger.e("❌ DioError: ${e.message}");

        try {
          final apiName = (e.requestOptions.extra['apiName'] ?? e.requestOptions.path).toString();
          final req = e.requestOptions.extra['requestBody'];
          final res = e.response?.data;
          final status = e.response?.statusCode;

          final uid = SessionContext.userId();
          final uname = SessionContext.userName();

          await AppCrashReporter.reportApiIssue(
            apiName: apiName,
            requestBody: req,
            responseBody: res,
            statusCode: status,
            userId: uid,
            userName: uname,
            timestamp: DateTime.now(),
            error: e,
            stackTrace: e.stackTrace,
          );
        } catch (_) {}

        handler.next(e);
      },
    );
  }

  /// Generic API call without parser
  Future<Response?> call({
    required String pathUrl,
    Method method = Method.get,
    dynamic body,
    String? queryParam,
    Map<String, dynamic>? headers,
    bool urlEncoded = false,
    ResponseType? responseType,
    CancelToken? cancelToken,
    int retryCount = 0,
  }) async {
    final url = _buildUrl(pathUrl, queryParam);

    final options = Options(
      headers: urlEncoded
          ? {'Content-Type': Headers.formUrlEncodedContentType, ...?headers}
          : headers,
      responseType: responseType,
    );

    int attempts = 0;
    while (true) {
      try {
        late Response response;

        switch (method) {
          case Method.get:
            response = await _dio.get(
              url,
              options: options,
              cancelToken: cancelToken,
            );
            break;
          case Method.post:
            response = await _dio.post(
              url,
              data: body,
              options: options,
              cancelToken: cancelToken,
            );
            break;
          case Method.put:
            response = await _dio.put(
              url,
              data: body,
              options: options,
              cancelToken: cancelToken,
            );
            break;
          case Method.delete:
            response = await _dio.delete(
              url,
              data: body,
              options: options,
              cancelToken: cancelToken,
            );
            break;
        }

        return response;
      } on DioException catch (e) {
        if (attempts < retryCount &&
            (e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout ||
                e.error is SocketException)) {
          attempts++;
          _logger.w("Retrying... attempt $attempts for $url");
          continue; // retry
        }
        await _handleError(e);
        return e.response;
      } catch (e) {
        _logger.e("Unexpected error during request to $url: $e");
        return Response(
          requestOptions: RequestOptions(path: url),
          statusCode: HttpStatus.internalServerError,
          statusMessage: "An unexpected error occurred",
        );
      }
    }
  }

  String _buildUrl(String pathUrl, String? queryParam) {
    return Uri.encodeFull('$pathUrl${queryParam ?? ''}');
  }

  Future<ApiError> _handleError(DioException error) async {
    final status = error.response?.statusCode ?? 0;
    final url = error.requestOptions.path;

    _logger.e("DioError [$status] from $url");
    _logger.e("Error response: ${error.response?.data}");

    // Treat 401 & 403 the same for auth failures
    if (status == HttpStatus.unauthorized || status == HttpStatus.forbidden) {
      await _redirectToLogin();
    }

    return ApiError(
      statusCode: status,
      message: error.message ?? "Unknown error",
      raw: error.response?.data,
    );
  }

  Future<void> _redirectToLogin() async {
    if (_authRedirecting) return;
    _authRedirecting = true;

    try {
      // Clear any auth state you use
      await SecureStorageService.clearData(); // implement this if you don't have it
      // await SecureStorageService.clearData();   // optional broader clear

      // Nuke the stack and go to login
      MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.login,
            (_) => false,
      );
    } finally {
      // leave it true to block flapping during a burst of failing calls
      // or set a short delayed reset if you prefer:
      // Future.delayed(const Duration(seconds: 2), () => _authRedirecting = false);
    }
  }
}

class SessionContext {
  /// Parses userData JSON from Hive (if available) and returns a Map.
  static Map<String, dynamic>? _getUserData() {
    try {
      final raw = HiveStorageService.getUserData();
      if (raw == null || raw.isEmpty) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static String? userId() {
    final map = _getUserData();
    if (map == null) return null;

    // adjust the key names according to your actual login JSON
    return map['userId']?.toString() ??
        map['id']?.toString() ??
        map['N_UserID']?.toString();
  }

  static String? userName() {
    final map = _getUserData();
    if (map == null) return null;

    return map['userName']?.toString() ??
        map['UserName']?.toString() ??
        map['FullName']?.toString() ??
        map['name']?.toString();
  }
}
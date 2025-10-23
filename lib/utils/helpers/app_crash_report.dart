// lib/core/monitoring/app_crash_reporter.dart
import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralized Crashlytics helper.
/// - Call AppCrashReporter.init() once in main()
/// - Optionally set user with setUser(id,name,email)
/// - Report API problems with reportApiIssue(...)
class AppCrashReporter {
  AppCrashReporter._();

  static final FirebaseCrashlytics _clx = FirebaseCrashlytics.instance;

  /// Call this once early in app startup (before runApp) and
  /// wrap runApp in runZonedGuarded as shown below.
  static Future<void> init({bool enableInDebug = true}) async {
    // Opt-in for debug/profile if you want to see events during dev
    await _clx.setCrashlyticsCollectionEnabled(kDebugMode ? enableInDebug : true);

    // Route Flutter framework errors to Crashlytics
    FlutterError.onError = _clx.recordFlutterFatalError;

    // Catch unhandled async errors (Dart zone)
    PlatformDispatcher.instance.onError = (error, stack) {
      _clx.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Set user information once after login so it’s attached to all reports.
  static Future<void> setUser({
    required String userId,
    String? name,
    String? email,
  }) async {
    await _clx.setUserIdentifier(userId);
    if (name != null && name.isNotEmpty) await _clx.setCustomKey('user_name', name);
    if (email != null && email.isNotEmpty) await _clx.setCustomKey('user_email', email);
  }

  /// Clear user on logout
  static Future<void> clearUser() async {
    await _clx.setUserIdentifier('');
    await _clx.setCustomKey('user_name', '');
    await _clx.setCustomKey('user_email', '');
  }

  /// Record a handled API issue (non-fatal). This will show up in Crashlytics.
  ///
  /// NOTE: Avoid logging secrets/PII in request/response.
  static Future<void> reportApiIssue({
    required String apiName,               // e.g., /api/v1/SubmitSurvey
    required dynamic requestBody,          // Map or raw
    dynamic responseBody,                  // Map, String, etc.
    int? statusCode,
    String? userId,
    String? userName,
    String? surveyType,                    // e.g., 'Passenger' / 'Freight' / etc.
    DateTime? timestamp,                   // defaults to now()
    Object? error,                         // pass DioException or any caught error
    StackTrace? stackTrace,
  }) async {
    final nowIso = (timestamp ?? DateTime.now()).toUtc().toIso8601String();

    // Safely toString JSON-ish payloads (and truncate if huge)
    String _safeJson(dynamic v) {
      try {
        final j = (v is String) ? v : jsonEncode(v);
        // Crashlytics has message length limits; truncate to ~10k chars
        return j.length > 10000 ? '${j.substring(0, 9990)}…[truncated]' : j;
      } catch (_) {
        return v?.toString() ?? '';
      }
    }

    // Attach structured keys (visible in Crashlytics keys pane)
    await _clx.setCustomKey('api_name', apiName);
    await _clx.setCustomKey('api_status', statusCode ?? -1);
    await _clx.setCustomKey('survey_type', surveyType ?? '');
    await _clx.setCustomKey('event_time_utc', nowIso);

    if (userId != null) await _clx.setCustomKey('user_id', userId);
    if (userName != null) await _clx.setCustomKey('user_name', userName);

    // Log long payloads via log() and short snapshots as keys
    final reqStr = _safeJson(requestBody);
    final resStr = _safeJson(responseBody);

    log('API ISSUE: $apiName [$statusCode] @ $nowIso\n'
        'Request: $reqStr\nResponse: $resStr',
        name: 'CrashReporter');

    // Short snapshots as keys (keep them tiny)
    await _clx.setCustomKey('req_preview', reqStr.substring(0, reqStr.length > 1000 ? 1000 : reqStr.length));
    await _clx.setCustomKey('res_preview', resStr.substring(0, resStr.length > 1000 ? 1000 : resStr.length));

    // Record as a *non-fatal* (handled) error so it shows in Crashlytics
    final ex = error ??
        Exception('API_FAILURE: $apiName status=${statusCode ?? 'n/a'} survey=$surveyType user=$userId');

    await _clx.recordError(ex, stackTrace, fatal: false);
  }

  /// Convenience to record any caught error with some context.
  static Future<void> recordError(Object error, StackTrace stack,
      {Map<String, Object?>? context,
        bool fatal = false}) async {
    if (context != null) {
      for (final entry in context.entries) {
        await _clx.setCustomKey(entry.key, entry.value?.toString() ?? '');
      }
    }
    await _clx.recordError(error, stack, fatal: fatal);
  }
}
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:srpf/core/remote/network/network_repository.dart';

class BaseRepository with ChangeNotifier {
  final NetworkRepository networkRepository = NetworkRepository();

  // Common headers for JSON APIs (default)
  static const Map<String, String> _defaultJsonHeaders = {
    HttpHeaders.contentTypeHeader: "application/json",
    HttpHeaders.acceptHeader: "application/json",
  };

  // Headers for PDF downloads or special cases
  static const Map<String, String> _pdfHeaders = {
    HttpHeaders.contentTypeHeader: "application/json",
    HttpHeaders.acceptHeader: "application/json, text/plain, */*",
    HttpHeaders.acceptEncodingHeader: "gzip, deflate, br",
    HttpHeaders.connectionHeader: "keep-alive",
  };

  // Headers for form data (file upload)
  static const Map<String, String> _formDataHeaders = {
    HttpHeaders.contentTypeHeader: "multipart/form-data",
    HttpHeaders.acceptHeader: "application/json",
  };

  // Headers for URL-encoded forms
  static const Map<String, String> _urlEncodedHeaders = {
    HttpHeaders.contentTypeHeader: "application/x-www-form-urlencoded",
    HttpHeaders.acceptHeader: "application/json",
  };

  // Build header with optional auth token
  Map<String, String> buildHeaders({String? token, bool isPdf = false, bool isFormData = false, bool isUrlEncoded = false}) {
    Map<String, String> headers;

    if (isPdf) {
      headers = Map.of(_pdfHeaders);
    } else if (isFormData) {
      headers = Map.of(_formDataHeaders);
    } else if (isUrlEncoded) {
      headers = Map.of(_urlEncodedHeaders);
    } else {
      headers = Map.of(_defaultJsonHeaders);
    }

    if (token != null && token.isNotEmpty) {
      headers[HttpHeaders.authorizationHeader] = _formatToken(token);
    }

    return headers;
  }

  String _formatToken(String token) => 'Bearer $token';
}

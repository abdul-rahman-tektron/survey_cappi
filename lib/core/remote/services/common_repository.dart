import 'dart:convert';
import 'dart:io';
import 'package:srpf/core/model/common/dashboard/enumerator_count_request.dart';
import 'package:srpf/core/model/common/dashboard/enumerator_count_response.dart';
import 'package:srpf/core/model/common/dashboard/get_survey_data_request.dart';
import 'package:srpf/core/model/common/dashboard/get_survey_data_response.dart';
import 'package:srpf/core/model/common/dashboard/get_surveyor_location_response.dart';
import 'package:srpf/core/model/common/dashboard/survey_data_response.dart';
import 'package:srpf/core/model/common/dropdown/dropdown_request.dart';
import 'package:srpf/core/model/common/dropdown/dropdown_response.dart';
import 'package:srpf/core/model/common/dropdown/nationality_dropdown_response.dart';
import 'package:srpf/core/model/common/error/common_response.dart';
import 'package:srpf/core/model/common/error/error_response.dart';
import 'package:srpf/core/model/common/login/generate_token_request.dart';
import 'package:srpf/core/model/common/login/generate_token_response.dart';
import 'package:srpf/core/model/common/login/login_request.dart';
import 'package:srpf/core/model/common/login/login_response.dart';
import 'package:srpf/core/model/common/success/common_success_response.dart';
import 'package:srpf/core/model/questionnaire/passenger_questionnaire/get_passenger_data_request.dart';
import 'package:srpf/core/model/questionnaire/passenger_questionnaire/get_passenger_data_response.dart';
import 'package:srpf/core/model/questionnaire/passenger_questionnaire/passenger_questionnaire_request.dart';
import 'package:srpf/core/model/questionnaire/rsi_questionnaire/get_rsi_data_request.dart';
import 'package:srpf/core/model/questionnaire/rsi_questionnaire/get_rsi_data_response.dart';
import 'package:srpf/core/model/questionnaire/rsi_questionnaire/rsi_questionnaire_request.dart';
import 'package:srpf/core/model/questionnaire/rsi_questionnaire/rsi_questionnaire_response.dart';
import 'package:srpf/core/model/questionnaire/sp_questionnaire/add_sp_request.dart';
import 'package:srpf/core/model/questionnaire/sp_questionnaire/get_sp_data_request.dart';
import 'package:srpf/core/model/questionnaire/sp_questionnaire/get_sp_data_response.dart';
import 'package:srpf/core/remote/network/api_url.dart';
import 'package:srpf/core/remote/network/base_repository.dart';
import 'package:srpf/utils/enums.dart';
import 'package:srpf/utils/storage/hive_storage.dart';
import 'package:srpf/utils/storage/secure_storage.dart';


class CommonRepository extends BaseRepository {
  CommonRepository._internal();
  static final instance = CommonRepository._internal();

  /// POST: /Auth/login
  /// Purpose: Authenticates a user and retrieves an access token
  /// Stores the token in secure storage and saves user data in Hive for quick access
  Future<Object?> apiGenerateToken(GenerateTokenRequest requestParams) async {
    final response = await networkRepository.call(
      method: Method.post,
      pathUrl: ApiUrls.pathGenerateToken,
      body: jsonEncode(requestParams.toJson()),
      headers: buildHeaders(),
    );

    final statusCode = response?.statusCode;
    final data = response?.data;

    if (statusCode == HttpStatus.ok) {
      final generateTokenResponse = generateTokenResponseFromJson(jsonEncode(data));

      return generateTokenResponse;
    }

    if (statusCode == HttpStatus.unauthorized) {
      return ErrorResponse(title: "Invalid credentials");
    }

    return ErrorResponse.fromJson(data ?? {});
  }

  Future<Object?> apiLogin(LoginRequest requestParams) async {
    final response = await networkRepository.call(
      method: Method.post,
      pathUrl: ApiUrls.pathLogin,
      body: jsonEncode(requestParams.toJson()),
      headers: buildHeaders(),
    );

    final statusCode = response?.statusCode;
    final data = response?.data;

    if (statusCode == HttpStatus.ok) {
      final loginResponse = loginResponseFromJson(jsonEncode(data));

      return loginResponse;
    }

    if (statusCode == HttpStatus.unauthorized) {
      return ErrorResponse(title: "Invalid credentials");
    }

    return ErrorResponse.fromJson(data ?? {});
  }

  Future<Object?> apiAddRSIQuestionnaire(AddRsiRequest requestParams) async {
    final token = await SecureStorageService.getToken();

    print("token");
    print(token);

    final response = await networkRepository.call(
      method: Method.post,
      pathUrl: ApiUrls.pathRSIQuestionnaire,
      body: jsonEncode(requestParams.toJson()),
      headers: buildHeaders(token: token),
    );

    if (response?.statusCode == HttpStatus.ok) {
      final addRsiResponse = addRsiResponseFromJson(jsonEncode(response?.data));
      return addRsiResponse;
    } else {
      throw ErrorResponse.fromJson(response?.data ?? {});
    }
  }

  Future<Object?> apiAddPassengerQuestionnaire(AddPassengerRequest requestParams) async {
    final token = await SecureStorageService.getToken();

    final response = await networkRepository.call(
      method: Method.post,
      pathUrl: ApiUrls.pathPassengerQuestionnaire,
      body: jsonEncode(requestParams.toJson()),
      headers: buildHeaders(token: token),
    );

    if (response?.statusCode == HttpStatus.ok) {
      final addRsiResponse = addRsiResponseFromJson(jsonEncode(response?.data));
      return addRsiResponse;
    } else {
      throw ErrorResponse.fromJson(response?.data ?? {});
    }
  }

  /// GET: /Service
  /// Purpose: Fetches the list of available jobs (used in dropdowns)
  Future<Object?> apiDropdown(DropdownRequest requestParams) async {
    final token = await SecureStorageService.getToken();

    print("token");
    print(token);

    final response = await networkRepository.call(
      method: Method.post,
      pathUrl: ApiUrls.pathDropdown,
      body: jsonEncode(requestParams.toJson()),
      headers: buildHeaders(token: token),
    );

    if (response?.statusCode == HttpStatus.ok) {
      final dropdownResponse = dropdownResponseFromJson(jsonEncode(response?.data));
      return dropdownResponse;
    } else {
      throw ErrorResponse.fromJson(response?.data ?? {});
    }
  }

  Future<Object?> apiNationalityDropdown(Map requestParams) async {
    final token = await SecureStorageService.getToken();

    print("token");
    print(token);

    final response = await networkRepository.call(
      method: Method.post,
      pathUrl: ApiUrls.pathNationalityDropdown,
      body: jsonEncode(requestParams),
      headers: buildHeaders(token: token),
    );

    if (response?.statusCode == HttpStatus.ok) {
      final nationalityDropdownResponse = nationalityDropdownResponseFromJson(jsonEncode(response?.data));
      return nationalityDropdownResponse;
    } else {
      throw ErrorResponse.fromJson(response?.data ?? {});
    }
  }

  Future<Object?> apiEnumeratorCount(EnumeratorCountRequest requestParams) async {
    final token = await SecureStorageService.getToken();

    final response = await networkRepository.call(
      method: Method.post,
      pathUrl: ApiUrls.pathEnumeratorCount,
      body: jsonEncode(requestParams.toJson()),
      headers: buildHeaders(token: token),
    );

    if (response?.statusCode == HttpStatus.ok) {
      final enumeratorCountResponse = enumeratorCountResponseFromJson(jsonEncode(response?.data));
      return enumeratorCountResponse;
    } else {
      throw ErrorResponse.fromJson(response?.data ?? {});
    }
  }

  Future<Object?> apiSurveyData(EnumeratorCountRequest requestParams) async {
    final token = await SecureStorageService.getToken();

    final response = await networkRepository.call(
      method: Method.post,
      pathUrl: ApiUrls.pathSurveyData,
      body: jsonEncode(requestParams.toJson()),
      headers: buildHeaders(token: token),
    );

    if (response?.statusCode == HttpStatus.ok) {
      final surveyDataResponse = surveyDataResponseFromJson(jsonEncode(response?.data));
      return surveyDataResponse;
    } else {
      throw ErrorResponse.fromJson(response?.data ?? {});
    }
  }

  Future<Object?> apiGetRSIData(GetRsiDataRequest requestParams) async {
    final token = await SecureStorageService.getToken();

    final response = await networkRepository.call(
      method: Method.post,
      pathUrl: ApiUrls.pathGetRSIData,
      body: jsonEncode(requestParams.toJson()),
      headers: buildHeaders(token: token),
    );

    if (response?.statusCode == HttpStatus.ok) {
      final getRSIDataResponse = getRsiDataResponseFromJson(jsonEncode(response?.data));
      return getRSIDataResponse;
    } else {
      throw ErrorResponse.fromJson(response?.data ?? {});
    }
  }

  Future<Object?> apiGetPassengerData(GetPassengerDataRequest requestParams) async {
    final token = await SecureStorageService.getToken();

    final response = await networkRepository.call(
      method: Method.post,
      pathUrl: ApiUrls.pathGetPassengerData,
      body: jsonEncode(requestParams.toJson()),
      headers: buildHeaders(token: token),
    );

    if (response?.statusCode == HttpStatus.ok) {
      final getPassengerDataResponse = getPassengerDataResponseFromJson(jsonEncode(response?.data));
      return getPassengerDataResponse;
    } else {
      throw ErrorResponse.fromJson(response?.data ?? {});
    }
  }

  Future<Object?> apiGetSurveyorLocation(Map requestParams) async {
    final token = await SecureStorageService.getToken();

    final response = await networkRepository.call(
      method: Method.post,
      pathUrl: ApiUrls.pathGetSurveyorLocation,
      body: jsonEncode(requestParams),
      headers: buildHeaders(token: token),
    );

    if (response?.statusCode == HttpStatus.ok) {
      final getSurveyorLocationResponse = getSurveyorLocationResponseFromJson(jsonEncode(response?.data));
      return getSurveyorLocationResponse;
    } else {
      throw ErrorResponse.fromJson(response?.data ?? {});
    }
  }

  Future<Object?> apiGetSPData(GetSpDataRequest requestParams) async {
    final token = await SecureStorageService.getToken();

    final response = await networkRepository.call(
      method: Method.post,
      pathUrl: ApiUrls.pathGetSPData,
      body: jsonEncode(requestParams.toJson()),
      headers: buildHeaders(token: token),
    );

    if (response?.statusCode == HttpStatus.ok) {
      final getSpDataResponse = getSpDataResponseFromJson(jsonEncode(response?.data));
      return getSpDataResponse;
    } else {
      throw ErrorResponse.fromJson(response?.data ?? {});
    }
  }

  Future<Object?> apiGetSurveyData(GetSurveyorDataRequest requestParams) async {
    final token = await SecureStorageService.getToken();

    final response = await networkRepository.call(
      method: Method.post,
      pathUrl: ApiUrls.pathGetSurveyorData,
      body: jsonEncode(requestParams.toJson()),
      headers: buildHeaders(token: token),
    );

    if (response?.statusCode == HttpStatus.ok) {
      final getSurveyorDataResponse = getSurveyorDataResponseFromJson(jsonEncode(response?.data));
      return getSurveyorDataResponse;
    } else {
      throw ErrorResponse.fromJson(response?.data ?? {});
    }
  }

  Future<Object?> apiAddSPData(List<AddSpRequest> requestParams) async {
    final token = await SecureStorageService.getToken();

    final response = await networkRepository.call(
      method: Method.post,
      pathUrl: ApiUrls.pathAddSpData,
      body: jsonEncode(requestParams.map((e) => e.toJson()).toList()),
      headers: buildHeaders(token: token),
    );

    if (response?.statusCode == HttpStatus.ok) {
      final addSpDataResponse = commonSuccessResponseFromJson(jsonEncode(response?.data));
      return addSpDataResponse;
    } else {
      throw ErrorResponse.fromJson(response?.data ?? {});
    }
  }
}

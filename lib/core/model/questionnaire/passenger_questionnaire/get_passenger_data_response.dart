// To parse this JSON data, do
//
//     final getPassengerDataResponse = getPassengerDataResponseFromJson(jsonString);

import 'dart:convert';

GetPassengerDataResponse getPassengerDataResponseFromJson(String str) => GetPassengerDataResponse.fromJson(json.decode(str));

String getPassengerDataResponseToJson(GetPassengerDataResponse data) => json.encode(data.toJson());

class GetPassengerDataResponse {
  bool? status;
  String? message;
  List<GetPassengerData>? result;

  GetPassengerDataResponse({
    this.status,
    this.message,
    this.result,
  });

  factory GetPassengerDataResponse.fromJson(Map<String, dynamic> json) => GetPassengerDataResponse(
    status: json["Status"],
    message: json["Message"],
    result: json["Result"] == null ? [] : List<GetPassengerData>.from(json["Result"]!.map((x) => GetPassengerData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "Status": status,
    "Message": message,
    "Result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
  };
}

class GetPassengerData {
  int? nPassengerRsiid;
  int? nProjectId;
  int? nTripId;
  dynamic dtInterviewDate;
  String? sVehicleType;
  String? sTotalTime;
  DateTime? dtInterviewStartTime;
  DateTime? dtInterviewEndTime;
  dynamic dtTripStartTime;
  dynamic dtTripEndTime;
  double? sLattitudeActual;
  double? sLongitudeActual;
  String? sSurveyType;
  int? nCarPresent;
  String? sFullName;
  String? sSetEligibility;
  dynamic sTravellerType;
  String? sNationality;
  dynamic sSuburbs;
  dynamic sDriverResidency;
  String? sMonthlyIncome;
  String? sOccupation;
  String? sPrivateCarAvailability;
  dynamic sOrigin;
  dynamic sOriginType;
  String? sDestination;
  dynamic sODforSp;
  dynamic sLastActivity;
  dynamic sNextActivity;
  dynamic sFrequency;
  dynamic sDestType;
  int? nTrippurp;
  int? nVehicleType;
  dynamic sCostTrip;
  int? nNoOfPassenger;
  dynamic sCostSharing;
  dynamic sPtAccess;
  dynamic sFinalDestination;
  dynamic sIcModeChoice;
  dynamic sAirsideOd;
  dynamic sAirline;
  dynamic sLandsideOd;
  String? sStayDuration;
  dynamic sIcTravelPattern;
  dynamic sBusRoute;
  String? sLocDuration;
  int? nNoOfTrips;
  DateTime? dtCreatedDate;
  int? nCreatedBy;
  dynamic dtUpdatedDate;
  dynamic nUpdatedBy;
  int? nIsDeleted;
  int? nStatus;
  String? sEmirates;
  int? nVehicleType1;
  int? nNoOfPassenger1;
  String? sGender;
  String? sAge;
  dynamic vehicleTypeA;
  dynamic vehicleTypeE;
  dynamic vehicleTypeCod;
  dynamic trippurpA;
  dynamic trippurpE;
  dynamic trippurpCod;
  String? createdBy;
  dynamic updatedBy;

  GetPassengerData({
    this.nPassengerRsiid,
    this.nProjectId,
    this.nTripId,
    this.dtInterviewDate,
    this.sTotalTime,
    this.dtInterviewStartTime,
    this.dtInterviewEndTime,
    this.dtTripStartTime,
    this.dtTripEndTime,
    this.sLattitudeActual,
    this.sLongitudeActual,
    this.sSurveyType,
    this.nCarPresent,
    this.sFullName,
    this.sSetEligibility,
    this.sTravellerType,
    this.sNationality,
    this.sSuburbs,
    this.sDriverResidency,
    this.sMonthlyIncome,
    this.sOccupation,
    this.sPrivateCarAvailability,
    this.sOrigin,
    this.sOriginType,
    this.sDestination,
    this.sODforSp,
    this.sLastActivity,
    this.sNextActivity,
    this.sFrequency,
    this.sDestType,
    this.nTrippurp,
    this.nVehicleType,
    this.sCostTrip,
    this.sVehicleType,   // ✅ NEW
    this.nNoOfPassenger,
    this.sCostSharing,
    this.sPtAccess,
    this.sFinalDestination,
    this.sIcModeChoice,
    this.sAirsideOd,
    this.sAirline,
    this.sLandsideOd,
    this.sStayDuration,
    this.sIcTravelPattern,
    this.sBusRoute,
    this.sLocDuration,
    this.nNoOfTrips,
    this.dtCreatedDate,
    this.nCreatedBy,
    this.dtUpdatedDate,
    this.nUpdatedBy,
    this.nIsDeleted,
    this.nStatus,
    this.sEmirates,
    this.nVehicleType1,
    this.nNoOfPassenger1,
    this.sGender,
    this.sAge,
    this.vehicleTypeA,
    this.vehicleTypeE,
    this.vehicleTypeCod,
    this.trippurpA,
    this.trippurpE,
    this.trippurpCod,
    this.createdBy,
    this.updatedBy,
  });

  factory GetPassengerData.fromJson(Map<String, dynamic> json) => GetPassengerData(
    nPassengerRsiid: json["N_PassengerRSIID"],
    nProjectId: json["N_ProjectID"],
    nTripId: json["N_TripID"],
    dtInterviewDate: json["Dt_InterviewDate"],
    sTotalTime: json["S_TotalTime"],
    dtInterviewStartTime: json["Dt_Interview_StartTime"] == null ? null : DateTime.parse(json["Dt_Interview_StartTime"]),
    dtInterviewEndTime: json["Dt_Interview_EndTime"] == null ? null : DateTime.parse(json["Dt_Interview_EndTime"]),
    dtTripStartTime: json["Dt_TripStartTime"],
    dtTripEndTime: json["Dt_TripEndTimeTrip"],
    sVehicleType: json["S_VehicleType"], // ✅ NEW
    sLattitudeActual: json["S_Lattitude_Actual"],
    sLongitudeActual: json["S_Longitude_Actual"],
    sSurveyType: json["S_SurveyType"],
    nCarPresent: json["N_CarPresent"],
    sFullName: json["S_FullName"],
    sSetEligibility: json["S_SetEligibility"],
    sTravellerType: json["S_TravellerType"],
    sNationality: json["S_Nationality"],
    sSuburbs: json["S_Suburbs"],
    sDriverResidency: json["S_DriverResidency"],
    sMonthlyIncome: json["S_MonthlyIncome"],
    sOccupation: json["S_Occupation"],
    sPrivateCarAvailability: json["S_PrivateCarAvailability"],
    sOrigin: json["S_Origin"],
    sOriginType: json["S_OriginType"],
    sDestination: json["S_Destination"],
    sODforSp: json["S_ODforSP"],
    sLastActivity: json["S_LastActivity"],
    sNextActivity: json["S_NextActivity"],
    sFrequency: json["S_Frequency"],
    sDestType: json["S_DestType"],
    nTrippurp: json["N_TRIPPURP"],
    nVehicleType: json["N_VehicleType"],
    sCostTrip: json["S_CostTrip"],
    nNoOfPassenger: json["N_NoOfPassenger"],
    sCostSharing: json["S_CostSharing"],
    sPtAccess: json["S_PTAccess"],
    sFinalDestination: json["S_FinalDestination"],
    sIcModeChoice: json["S_ICModeChoice"],
    sAirsideOd: json["S_AirsideOD"],
    sAirline: json["S_Airline"],
    sLandsideOd: json["S_LandsideOD"],
    sStayDuration: json["S_StayDuration"],
    sIcTravelPattern: json["S_ICTravelPattern"],
    sBusRoute: json["S_BusRoute"],
    sLocDuration: json["S_LocDuration"],
    nNoOfTrips: json["N_NoOfTrips"],
    dtCreatedDate: json["Dt_CreatedDate"] == null ? null : DateTime.parse(json["Dt_CreatedDate"]),
    nCreatedBy: json["N_CreatedBy"],
    dtUpdatedDate: json["Dt_UpdatedDate"],
    nUpdatedBy: json["N_UpdatedBy"],
    nIsDeleted: json["N_Is_Deleted"],
    nStatus: json["N_Status"],
    sEmirates: json["S_Emirates"],
    nVehicleType1: json["N_VehicleType1"],
    nNoOfPassenger1: json["N_NoOfPassenger1"],
    sGender: json["S_Gender"],
    sAge: json["S_Age"],
    vehicleTypeA: json["VehicleType_A"],
    vehicleTypeE: json["VehicleType_E"],
    vehicleTypeCod: json["VehicleType_COD"],
    trippurpA: json["TRIPPURP_A"],
    trippurpE: json["TRIPPURP_E"],
    trippurpCod: json["TRIPPURP_COD"],
    createdBy: json["CreatedBy"],
    updatedBy: json["UpdatedBy"],
  );

  Map<String, dynamic> toJson() => {
    "N_PassengerRSIID": nPassengerRsiid,
    "N_ProjectID": nProjectId,
    "N_TripID": nTripId,
    "Dt_InterviewDate": dtInterviewDate,
    "S_TotalTime": sTotalTime,
    "Dt_Interview_StartTime": dtInterviewStartTime?.toIso8601String(),
    "Dt_Interview_EndTime": dtInterviewEndTime?.toIso8601String(),
    "Dt_TripStartTime": dtTripStartTime,
    "Dt_TripEndTimeTrip": dtTripEndTime,
    "S_Lattitude_Actual": sLattitudeActual,
    "S_VehicleType": sVehicleType, // ✅ NEW
    "S_Longitude_Actual": sLongitudeActual,
    "S_SurveyType": sSurveyType,
    "N_CarPresent": nCarPresent,
    "S_FullName": sFullName,
    "S_SetEligibility": sSetEligibility,
    "S_TravellerType": sTravellerType,
    "S_Nationality": sNationality,
    "S_Suburbs": sSuburbs,
    "S_DriverResidency": sDriverResidency,
    "S_MonthlyIncome": sMonthlyIncome,
    "S_Occupation": sOccupation,
    "S_PrivateCarAvailability": sPrivateCarAvailability,
    "S_Origin": sOrigin,
    "S_OriginType": sOriginType,
    "S_Destination": sDestination,
    "S_ODforSP": sODforSp,
    "S_LastActivity": sLastActivity,
    "S_NextActivity": sNextActivity,
    "S_Frequency": sFrequency,
    "S_DestType": sDestType,
    "N_TRIPPURP": nTrippurp,
    "N_VehicleType": nVehicleType,
    "S_CostTrip": sCostTrip,
    "N_NoOfPassenger": nNoOfPassenger,
    "S_CostSharing": sCostSharing,
    "S_PTAccess": sPtAccess,
    "S_FinalDestination": sFinalDestination,
    "S_ICModeChoice": sIcModeChoice,
    "S_AirsideOD": sAirsideOd,
    "S_Airline": sAirline,
    "S_LandsideOD": sLandsideOd,
    "S_StayDuration": sStayDuration,
    "S_ICTravelPattern": sIcTravelPattern,
    "S_BusRoute": sBusRoute,
    "S_LocDuration": sLocDuration,
    "N_NoOfTrips": nNoOfTrips,
    "Dt_CreatedDate": dtCreatedDate?.toIso8601String(),
    "N_CreatedBy": nCreatedBy,
    "Dt_UpdatedDate": dtUpdatedDate,
    "N_UpdatedBy": nUpdatedBy,
    "N_Is_Deleted": nIsDeleted,
    "N_Status": nStatus,
    "S_Emirates": sEmirates,
    "N_VehicleType1": nVehicleType1,
    "N_NoOfPassenger1": nNoOfPassenger1,
    "S_Gender": sGender,
    "S_Age": sAge,
    "VehicleType_A": vehicleTypeA,
    "VehicleType_E": vehicleTypeE,
    "VehicleType_COD": vehicleTypeCod,
    "TRIPPURP_A": trippurpA,
    "TRIPPURP_E": trippurpE,
    "TRIPPURP_COD": trippurpCod,
    "CreatedBy": createdBy,
    "UpdatedBy": updatedBy,
  };
}

// To parse this JSON data, do
//
//     final getRsiDataResponse = getRsiDataResponseFromJson(jsonString);

import 'dart:convert';

GetRsiDataResponse getRsiDataResponseFromJson(String str) => GetRsiDataResponse.fromJson(json.decode(str));

String getRsiDataResponseToJson(GetRsiDataResponse data) => json.encode(data.toJson());

class GetRsiDataResponse {
  bool? status;
  String? message;
  List<GetRSIData>? result;

  GetRsiDataResponse({
    this.status,
    this.message,
    this.result,
  });

  factory GetRsiDataResponse.fromJson(Map<String, dynamic> json) => GetRsiDataResponse(
    status: json["Status"],
    message: json["Message"],
    result: json["Result"] == null ? [] : List<GetRSIData>.from(json["Result"]!.map((x) => GetRSIData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "Status": status,
    "Message": message,
    "Result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
  };
}

class GetRSIData {
  int? nRsiid;
  int? nProjectId;
  int? nTripId;
  String? sFullName;
  DateTime? dtInterviewDate;
  String? sTotalTime;
  String? dtInterviewStartTime;
  String? dtInterviewEndTime;
  int? nNoOfPassenger;
  int? nNationality;
  int? nMonthlyIncome;
  dynamic sGeoCode;
  double? sLattitude;
  double? sLongitude;
  dynamic sGeoCodeActual;
  double? sLattitudeActual;
  double? sLongitudeActual;
  String? sOrigin;
  String? dtDepartureTime;
  dynamic sDestination;
  String? dtArrivalTime;
  dynamic dtReachTime;
  dynamic sReachDistance;
  double? sDestinationLat;
  double? sDestinationLong;
  int? nTripFrequency;
  int? nTypeTrip;
  dynamic sCostTrip;
  dynamic sTypeCargo;
  dynamic sDistance;
  dynamic sWeight;
  int? nCommodity;
  dynamic sGoods;
  dynamic sNotes;
  int? nTripCount;
  DateTime? dtCreatedDate;
  int? nCreatedBy;
  dynamic dtUpdatedDate;
  dynamic nUpdatedBy;
  int? nIsDeleted;
  String? sVehicleType;
  dynamic sEmirates;
  int? nHauler;
  String? sDriverResidency;
  dynamic sCargoCost;
  dynamic sWeighMethod;
  dynamic sCargoWeight;
  dynamic sLatConclusion;
  dynamic sLonConclusion;
  dynamic sLatFinal;
  dynamic sLonFinal;
  String? sClientCompany;
  String? sDriverResidency1;
  dynamic monthlyIncomeA;
  dynamic monthlyIncomeE;
  dynamic monthlyIncomeCod;
  String? haulerA;
  String? haulerE;
  dynamic tripFrequencyA;
  dynamic tripFrequencyE;
  dynamic tripFrequencyCod;
  dynamic typeTripA;
  dynamic typeTripE;
  dynamic typeTripCod;
  dynamic nationalityA;
  dynamic nationalityE;
  dynamic nationalityCod;
  dynamic typeCargoA;
  dynamic typeCargoE;
  dynamic typeCargoCod;
  dynamic commodityA;
  dynamic commodityE;
  dynamic commodityCod;
  String? createdBy;
  dynamic updatedBy;

  GetRSIData({
    this.nRsiid,
    this.nProjectId,
    this.nTripId,
    this.sFullName,
    this.dtInterviewDate,
    this.sTotalTime,
    this.dtInterviewStartTime,
    this.dtInterviewEndTime,
    this.nNoOfPassenger,
    this.nNationality,
    this.nMonthlyIncome,
    this.sGeoCode,
    this.sLattitude,
    this.sLongitude,
    this.sGeoCodeActual,
    this.sLattitudeActual,
    this.sLongitudeActual,
    this.sOrigin,
    this.dtDepartureTime,
    this.sDestination,
    this.dtArrivalTime,
    this.dtReachTime,
    this.sReachDistance,
    this.sDestinationLat,
    this.sDestinationLong,
    this.nTripFrequency,
    this.nTypeTrip,
    this.sCostTrip,
    this.sTypeCargo,
    this.sDistance,
    this.sWeight,
    this.nCommodity,
    this.sGoods,
    this.sNotes,
    this.nTripCount,
    this.dtCreatedDate,
    this.nCreatedBy,
    this.dtUpdatedDate,
    this.nUpdatedBy,
    this.nIsDeleted,
    this.sVehicleType,
    this.sEmirates,
    this.nHauler,
    this.sDriverResidency,
    this.sCargoCost,
    this.sWeighMethod,
    this.sCargoWeight,
    this.sLatConclusion,
    this.sLonConclusion,
    this.sLatFinal,
    this.sLonFinal,
    this.sClientCompany,
    this.sDriverResidency1,
    this.monthlyIncomeA,
    this.monthlyIncomeE,
    this.monthlyIncomeCod,
    this.haulerA,
    this.haulerE,
    this.tripFrequencyA,
    this.tripFrequencyE,
    this.tripFrequencyCod,
    this.typeTripA,
    this.typeTripE,
    this.typeTripCod,
    this.nationalityA,
    this.nationalityE,
    this.nationalityCod,
    this.typeCargoA,
    this.typeCargoE,
    this.typeCargoCod,
    this.commodityA,
    this.commodityE,
    this.commodityCod,
    this.createdBy,
    this.updatedBy,
  });

  factory GetRSIData.fromJson(Map<String, dynamic> json) => GetRSIData(
    nRsiid: json["N_RSIID"],
    nProjectId: json["N_ProjectID"],
    sFullName: json["S_FullName"],
    nTripId: json["N_TripID"],
    dtInterviewDate: json["Dt_InterviewDate"] == null ? null : DateTime.parse(json["Dt_InterviewDate"]),
    sTotalTime: json["S_TotalTime"],
    dtInterviewStartTime: json["Dt_Interview_StartTime"],
    dtInterviewEndTime: json["Dt_Interview_EndTime"],
    nNoOfPassenger: json["N_NoOfPassenger"],
    nNationality: json["N_Nationality"],
    nMonthlyIncome: json["N_MonthlyIncome"],
    sGeoCode: json["S_GeoCode"],
    sLattitude: json["S_Lattitude"]?.toDouble(),
    sLongitude: json["S_Longitude"]?.toDouble(),
    sGeoCodeActual: json["S_GeoCode_Actual"],
    sLattitudeActual: json["S_Lattitude_Actual"]?.toDouble(),
    sLongitudeActual: json["S_Longitude_Actual"]?.toDouble(),
    sOrigin: json["S_Origin"],
    dtDepartureTime: json["Dt_DepartureTime"],
    sDestination: json["S_Destination"],
    dtArrivalTime: json["Dt_ArrivalTime"],
    dtReachTime: json["Dt_ReachTime"],
    sReachDistance: json["S_ReachDistance"],
    sDestinationLat: json["S_Destination_Lat"]?.toDouble(),
    sDestinationLong: json["S_Destination_Long"]?.toDouble(),
    nTripFrequency: json["N_TripFrequency"],
    nTypeTrip: json["N_TypeTrip"],
    sCostTrip: json["S_CostTrip"],
    sTypeCargo: json["S_TypeCargo"],
    sDistance: json["S_Distance"],
    sWeight: json["S_Weight"],
    nCommodity: json["N_Commodity"],
    sGoods: json["S_Goods"],
    sNotes: json["S_Notes"],
    nTripCount: json["N_TripCount"],
    dtCreatedDate: json["Dt_CreatedDate"] == null ? null : DateTime.parse(json["Dt_CreatedDate"]),
    nCreatedBy: json["N_CreatedBy"],
    dtUpdatedDate: json["Dt_UpdatedDate"],
    nUpdatedBy: json["N_UpdatedBy"],
    nIsDeleted: json["N_Is_Deleted"],
    sVehicleType: json["S_VehicleType"],
    sEmirates: json["S_Emirates"],
    nHauler: json["N_Hauler"],
    sDriverResidency: json["S_DriverResidency"],
    sCargoCost: json["S_CargoCost"],
    sWeighMethod: json["S_WeighMethod"],
    sCargoWeight: json["S_CargoWeight"],
    sLatConclusion: json["S_LatConclusion"],
    sLonConclusion: json["S_LonConclusion"],
    sLatFinal: json["S_LatFinal"],
    sLonFinal: json["S_LonFinal"],
    sClientCompany: json["S_ClientCompany"],
    sDriverResidency1: json["S_DriverResidency1"],
    monthlyIncomeA: json["MonthlyIncome_A"],
    monthlyIncomeE: json["MonthlyIncome_E"],
    monthlyIncomeCod: json["MonthlyIncome_COD"],
    haulerA: json["Hauler_A"],
    haulerE: json["Hauler_E"],
    tripFrequencyA: json["TripFrequency_A"],
    tripFrequencyE: json["TripFrequency_E"],
    tripFrequencyCod: json["TripFrequency_COD"],
    typeTripA: json["TypeTrip_A"],
    typeTripE: json["TypeTrip_E"],
    typeTripCod: json["TypeTrip_COD"],
    nationalityA: json["Nationality_A"],
    nationalityE: json["Nationality_E"],
    nationalityCod: json["Nationality_COD"],
    typeCargoA: json["TypeCargo_A"],
    typeCargoE: json["TypeCargo_E"],
    typeCargoCod: json["TypeCargo_COD"],
    commodityA: json["Commodity_A"],
    commodityE: json["Commodity_E"],
    commodityCod: json["Commodity_COD"],
    createdBy: json["CreatedBy"],
    updatedBy: json["UpdatedBy"],
  );

  Map<String, dynamic> toJson() => {
    "N_RSIID": nRsiid,
    "N_ProjectID": nProjectId,
    "N_TripID": nTripId,
    "S_FullName": sFullName,
    "Dt_InterviewDate": dtInterviewDate?.toIso8601String(),
    "S_TotalTime": sTotalTime,
    "Dt_Interview_StartTime": dtInterviewStartTime,
    "Dt_Interview_EndTime": dtInterviewEndTime,
    "N_NoOfPassenger": nNoOfPassenger,
    "N_Nationality": nNationality,
    "N_MonthlyIncome": nMonthlyIncome,
    "S_GeoCode": sGeoCode,
    "S_Lattitude": sLattitude,
    "S_Longitude": sLongitude,
    "S_GeoCode_Actual": sGeoCodeActual,
    "S_Lattitude_Actual": sLattitudeActual,
    "S_Longitude_Actual": sLongitudeActual,
    "S_Origin": sOrigin,
    "Dt_DepartureTime": dtDepartureTime,
    "S_Destination": sDestination,
    "Dt_ArrivalTime": dtArrivalTime,
    "Dt_ReachTime": dtReachTime,
    "S_ReachDistance": sReachDistance,
    "S_Destination_Lat": sDestinationLat,
    "S_Destination_Long": sDestinationLong,
    "N_TripFrequency": nTripFrequency,
    "N_TypeTrip": nTypeTrip,
    "S_CostTrip": sCostTrip,
    "S_TypeCargo": sTypeCargo,
    "S_Distance": sDistance,
    "S_Weight": sWeight,
    "N_Commodity": nCommodity,
    "S_Goods": sGoods,
    "S_Notes": sNotes,
    "N_TripCount": nTripCount,
    "Dt_CreatedDate": dtCreatedDate?.toIso8601String(),
    "N_CreatedBy": nCreatedBy,
    "Dt_UpdatedDate": dtUpdatedDate,
    "N_UpdatedBy": nUpdatedBy,
    "N_Is_Deleted": nIsDeleted,
    "S_VehicleType": sVehicleType,
    "S_Emirates": sEmirates,
    "N_Hauler": nHauler,
    "S_DriverResidency": sDriverResidency,
    "S_CargoCost": sCargoCost,
    "S_WeighMethod": sWeighMethod,
    "S_CargoWeight": sCargoWeight,
    "S_LatConclusion": sLatConclusion,
    "S_LonConclusion": sLonConclusion,
    "S_LatFinal": sLatFinal,
    "S_LonFinal": sLonFinal,
    "S_ClientCompany": sClientCompany,
    "S_DriverResidency1": sDriverResidency1,
    "MonthlyIncome_A": monthlyIncomeA,
    "MonthlyIncome_E": monthlyIncomeE,
    "MonthlyIncome_COD": monthlyIncomeCod,
    "Hauler_A": haulerA,
    "Hauler_E": haulerE,
    "TripFrequency_A": tripFrequencyA,
    "TripFrequency_E": tripFrequencyE,
    "TripFrequency_COD": tripFrequencyCod,
    "TypeTrip_A": typeTripA,
    "TypeTrip_E": typeTripE,
    "TypeTrip_COD": typeTripCod,
    "Nationality_A": nationalityA,
    "Nationality_E": nationalityE,
    "Nationality_COD": nationalityCod,
    "TypeCargo_A": typeCargoA,
    "TypeCargo_E": typeCargoE,
    "TypeCargo_COD": typeCargoCod,
    "Commodity_A": commodityA,
    "Commodity_E": commodityE,
    "Commodity_COD": commodityCod,
    "CreatedBy": createdBy,
    "UpdatedBy": updatedBy,
  };
}

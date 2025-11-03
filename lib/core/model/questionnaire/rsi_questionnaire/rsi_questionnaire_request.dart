// To parse this JSON data, do
//
//     final addRsiRequest = addRsiRequestFromJson(jsonString);

import 'dart:convert';

AddRsiRequest addRsiRequestFromJson(String str) => AddRsiRequest.fromJson(json.decode(str));

String addRsiRequestToJson(AddRsiRequest data) => json.encode(data.toJson());

class AddRsiRequest {
  int? nRsiid;
  int? nProjectId;
  int? nTripId;
  String? sEmirates;
  String? dtInterviewDate;
  String? sTotalTime;
  String? dtInterviewStartTime;
  String? dtInterviewEndTime;
  int? nSurveyType;
  String? sVehicleType;
  int? nNoOfPassenger;
  int? sGender;
  int? nAge;
  int? nNationality;
  String? sDriverResidency;
  int? nMonthlyIncome;
  int? nHauler;
  String? sHauler;
  String? sClientCompany;
  String? sGeoCode;
  String? sLattitude;
  String? sLongitude;
  String? sGeoCodeActual;
  String? sLattitudeActual;
  String? sLongitudeActual;
  int? nUsepubtr;
  String? sOrigin;
  String? dtDepartureTime;
  String? sDestination;
  String? dtArrivalTime;
  String? dtReachTime;
  String? sReachDistance;
  String? sDestinationLat;
  String? sDestinationLong;
  String? sLatFinal;
  String? sLonFinal;
  String? sLatConclusion;
  String? sLonConclusion;
  int? nTripFrequency;
  int? nTypeTrip;
  String? sCostTrip;
  String? sCargoCost;
  String? nTypeCargo;
  int? nTypeCargoDuc;
  String? sTypeCargo;
  String? sIsMultipleCargo;
  int? nTrippurp;
  int? nTrippurpDuc;
  String? sTrippurp;
  int? nTaxifare;
  int? nTaxitype;
  int? nTaxitypeDuc;
  String? sTaxitype;
  String? sDistance;
  String? sWeight;
  String? sCargoWeight;
  String? sWeighMethod;
  int? nCommodity;
  int? nCommodityDuc;
  String? sCommodity;
  String? sGoods;
  String? sBusRoute;
  int? nTypeBus;
  int? nNoSeats;
  int? nAccmode;
  int? nAccmodeDuc;
  String? sAccmode;
  int? nEgrmode;
  int? nEgrmodeDuc;
  String? sEgrmode;
  int? nTicketType;
  int? nTicketTypeDuc;
  String? sTicketType;
  int? nPrivateCarAvailability;
  String? sNotes;
  int? nTripCount;
  String? dtCreatedDate;
  int? nCreatedBy;
  String? dtUpdatedDate;
  int? nUpdatedBy;
  int? nIsDeleted;
  String? sIsMultipleTrip;
  String? dtAnticipatedJourneyTime;
  String? dtFinalEta;
  String? action;
  String? sFullName;
  int? nStatus;
  String? locCode;
  String? sIsLoaded;

  AddRsiRequest({
    this.nRsiid,
    this.nProjectId,
    this.nTripId,
    this.dtInterviewDate,
    this.sTotalTime,
    this.dtInterviewStartTime,
    this.dtInterviewEndTime,
    this.nSurveyType,
    this.sVehicleType,
    this.nNoOfPassenger,
    this.sGender,
    this.nAge,
    this.nNationality,
    this.sDriverResidency,
    this.nMonthlyIncome,
    this.nHauler,
    this.sHauler,
    this.sClientCompany,
    this.sGeoCode,
    this.sLattitude,
    this.sLongitude,
    this.sGeoCodeActual,
    this.sLattitudeActual,
    this.sLongitudeActual,
    this.nUsepubtr,
    this.sOrigin,
    this.dtDepartureTime,
    this.sDestination,
    this.dtArrivalTime,
    this.dtReachTime,
    this.sReachDistance,
    this.sDestinationLat,
    this.sDestinationLong,
    this.sLatFinal,
    this.sLonFinal,
    this.sLatConclusion,
    this.sLonConclusion,
    this.nTripFrequency,
    this.nTypeTrip,
    this.sCostTrip,
    this.sCargoCost,
    this.nTypeCargo,
    this.nTypeCargoDuc,
    this.sTypeCargo,
    this.sIsMultipleCargo,
    this.nTrippurp,
    this.nTrippurpDuc,
    this.sTrippurp,
    this.nTaxifare,
    this.nTaxitype,
    this.nTaxitypeDuc,
    this.sTaxitype,
    this.sDistance,
    this.sWeight,
    this.sCargoWeight,
    this.sWeighMethod,
    this.nCommodity,
    this.nCommodityDuc,
    this.sCommodity,
    this.sGoods,
    this.sBusRoute,
    this.nTypeBus,
    this.nNoSeats,
    this.nAccmode,
    this.nAccmodeDuc,
    this.sAccmode,
    this.nEgrmode,
    this.nEgrmodeDuc,
    this.sEgrmode,
    this.nTicketType,
    this.nTicketTypeDuc,
    this.sTicketType,
    this.nPrivateCarAvailability,
    this.sNotes,
    this.nTripCount,
    this.dtCreatedDate,
    this.nCreatedBy,
    this.dtUpdatedDate,
    this.nUpdatedBy,
    this.nIsDeleted,
    this.sIsMultipleTrip,
    this.dtAnticipatedJourneyTime,
    this.dtFinalEta,
    this.action,
    this.sFullName,
    this.nStatus,
    this.sEmirates,
    this.locCode,
    this.sIsLoaded,
  });

  factory AddRsiRequest.fromJson(Map<String, dynamic> json) => AddRsiRequest(
    nRsiid: json["N_RSIID"],
    nProjectId: json["N_ProjectID"],
    nTripId: json["N_TripID"],
    dtInterviewDate: json["Dt_InterviewDate"],
    sTotalTime: json["S_TotalTime"],
    dtInterviewStartTime: json["Dt_Interview_StartTime"],
    dtInterviewEndTime: json["Dt_Interview_EndTime"],
    nSurveyType: json["N_SurveyType"],
    sVehicleType: json["S_VehicleType"],
    nNoOfPassenger: json["N_NoOfPassenger"],
    sGender: json["S_Gender"],
    nAge: json["N_Age"],
    nNationality: json["N_Nationality"],
    sDriverResidency: json["S_DriverResidency"],
    nMonthlyIncome: json["N_MonthlyIncome"],
    nHauler: json["N_Hauler"],
    sHauler: json["S_Hauler"],
    sClientCompany: json["S_ClientCompany"],
    sGeoCode: json["S_GeoCode"],
    sLattitude: json["S_Lattitude"],
    sLongitude: json["S_Longitude"],
    sGeoCodeActual: json["S_GeoCode_Actual"],
    sLattitudeActual: json["S_Lattitude_Actual"],
    sLongitudeActual: json["S_Longitude_Actual"],
    nUsepubtr: json["N_USEPUBTR"],
    sOrigin: json["S_Origin"],
    dtDepartureTime: json["Dt_DepartureTime"],
    sDestination: json["S_Destination"],
    dtArrivalTime: json["Dt_ArrivalTime"],
    dtReachTime: json["Dt_ReachTime"],
    sReachDistance: json["S_ReachDistance"],
    sDestinationLat: json["S_Destination_Lat"],
    sDestinationLong: json["S_Destination_Long"],
    sLatFinal: json["S_LatFinal"],
    sLonFinal: json["S_LonFinal"],
    sLatConclusion: json["S_LatConclusion"],
    sLonConclusion: json["S_LonConclusion"],
    nTripFrequency: json["N_TripFrequency"],
    nTypeTrip: json["N_TypeTrip"],
    sCostTrip: json["S_CostTrip"],
    sCargoCost: json["S_CargoCost"],
    nTypeCargo: json["N_TypeCargo"],
    nTypeCargoDuc: json["N_TypeCargo_DUC"],
    sTypeCargo: json["S_TypeCargo"],
    sIsMultipleCargo: json["S_IsMultipleCargo"],
    nTrippurp: json["N_TRIPPURP"],
    nTrippurpDuc: json["N_TRIPPURP_DUC"],
    sTrippurp: json["S_TRIPPURP"],
    nTaxifare: json["N_TAXIFARE"],
    nTaxitype: json["N_TAXITYPE"],
    nTaxitypeDuc: json["N_TAXITYPE_DUC"],
    sTaxitype: json["S_TAXITYPE"],
    sDistance: json["S_Distance"],
    sWeight: json["S_Weight"],
    sCargoWeight: json["S_CargoWeight"],
    sWeighMethod: json["S_WeighMethod"],
    nCommodity: json["N_Commodity"],
    nCommodityDuc: json["N_Commodity_DUC"],
    sCommodity: json["S_Commodity"],
    sGoods: json["S_Goods"],
    sBusRoute: json["S_BusRoute"],
    nTypeBus: json["N_TypeBus"],
    nNoSeats: json["N_NoSeats"],
    nAccmode: json["N_ACCMODE"],
    nAccmodeDuc: json["N_ACCMODE_DUC"],
    sAccmode: json["S_ACCMODE"],
    nEgrmode: json["N_EGRMODE"],
    nEgrmodeDuc: json["N_EGRMODE_DUC"],
    sEgrmode: json["S_EGRMODE"],
    nTicketType: json["N_TicketType"],
    nTicketTypeDuc: json["N_TicketType_DUC"],
    sTicketType: json["S_TicketType"],
    nPrivateCarAvailability: json["N_PrivateCarAvailability"],
    sNotes: json["S_Notes"],
    nTripCount: json["N_TripCount"],
    dtCreatedDate: json["Dt_CreatedDate"],
    nCreatedBy: json["N_CreatedBy"],
    dtUpdatedDate: json["Dt_UpdatedDate"],
    nUpdatedBy: json["N_UpdatedBy"],
    nIsDeleted: json["N_Is_Deleted"],
    sIsMultipleTrip: json["S_IsMultipleTrip"],
    dtAnticipatedJourneyTime: json["Dt_AnticipatedJourneyTime"],
    dtFinalEta: json["Dt_FinalETA"],
    action: json["Action"],
    sFullName: json["S_FullName"],
    nStatus: json["N_Status"],
    sEmirates: json["S_Emirates"],
    locCode: json["locCode"],
    sIsLoaded: json["S_IsLoaded"],
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    void put(String key, dynamic value) {
      if (value != null) data[key] = value;
    }

    put("N_RSIID", nRsiid);
    put("N_ProjectID", nProjectId);
    put("N_TripID", nTripId);
    put("Dt_InterviewDate", dtInterviewDate);
    put("S_TotalTime", sTotalTime);
    put("Dt_Interview_StartTime", dtInterviewStartTime);
    put("Dt_Interview_EndTime", dtInterviewEndTime);
    put("N_SurveyType", nSurveyType);
    put("S_VehicleType", sVehicleType);
    put("N_NoOfPassenger", nNoOfPassenger);
    put("S_Gender", sGender);
    put("N_Age", nAge);
    put("N_Nationality", nNationality);
    put("S_DriverResidency", sDriverResidency);
    put("N_MonthlyIncome", nMonthlyIncome);
    put("N_Hauler", nHauler);
    put("S_Hauler", sHauler);
    put("S_ClientCompany", sClientCompany);
    put("S_GeoCode", sGeoCode);
    put("S_Lattitude", sLattitude);
    put("S_Longitude", sLongitude);
    put("S_GeoCode_Actual", sGeoCodeActual);
    put("S_Lattitude_Actual", sLattitudeActual);
    put("S_Longitude_Actual", sLongitudeActual);
    put("N_USEPUBTR", nUsepubtr);
    put("S_Origin", sOrigin);
    put("Dt_DepartureTime", dtDepartureTime);
    put("S_Destination", sDestination);
    put("Dt_ArrivalTime", dtArrivalTime);
    put("Dt_ReachTime", dtReachTime);
    put("S_ReachDistance", sReachDistance);
    put("S_Destination_Lat", sDestinationLat);
    put("S_Destination_Long", sDestinationLong);
    put("S_LatFinal", sLatFinal);
    put("S_LonFinal", sLonFinal);
    put("S_LatConclusion", sLatConclusion);
    put("S_LonConclusion", sLonConclusion);
    put("N_TripFrequency", nTripFrequency);
    put("N_TypeTrip", nTypeTrip);
    put("S_CostTrip", sCostTrip);
    put("S_CargoCost", sCargoCost);
    put("N_TypeCargo", nTypeCargo);
    put("N_TypeCargo_DUC", nTypeCargoDuc);
    put("S_TypeCargo", sTypeCargo);
    put("S_IsMultipleCargo", sIsMultipleCargo);
    put("N_TRIPPURP", nTrippurp);
    put("N_TRIPPURP_DUC", nTrippurpDuc);
    put("S_TRIPPURP", sTrippurp);
    put("N_TAXIFARE", nTaxifare);
    put("N_TAXITYPE", nTaxitype);
    put("N_TAXITYPE_DUC", nTaxitypeDuc);
    put("S_TAXITYPE", sTaxitype);
    put("S_Distance", sDistance);
    put("S_Weight", sWeight);
    put("S_CargoWeight", sCargoWeight);
    put("S_WeighMethod", sWeighMethod);
    put("N_Commodity", nCommodity);
    put("N_Commodity_DUC", nCommodityDuc);
    put("S_Commodity", sCommodity);
    put("S_Goods", sGoods);
    put("S_BusRoute", sBusRoute);
    put("N_TypeBus", nTypeBus);
    put("N_NoSeats", nNoSeats);
    put("N_ACCMODE", nAccmode);
    put("N_ACCMODE_DUC", nAccmodeDuc);
    put("S_ACCMODE", sAccmode);
    put("N_EGRMODE", nEgrmode);
    put("N_EGRMODE_DUC", nEgrmodeDuc);
    put("S_EGRMODE", sEgrmode);
    put("N_TicketType", nTicketType);
    put("N_TicketType_DUC", nTicketTypeDuc);
    put("S_TicketType", sTicketType);
    put("N_PrivateCarAvailability", nPrivateCarAvailability);
    put("S_Notes", sNotes);
    put("N_TripCount", nTripCount);
    put("Dt_CreatedDate", dtCreatedDate);
    put("N_CreatedBy", nCreatedBy);
    put("Dt_UpdatedDate", dtUpdatedDate);
    put("N_UpdatedBy", nUpdatedBy);
    put("N_Is_Deleted", nIsDeleted);
    put("S_IsMultipleTrip", sIsMultipleTrip);
    put("Dt_AnticipatedJourneyTime", dtAnticipatedJourneyTime);
    put("Dt_FinalETA", dtFinalEta);
    put("Action", action);
    put("S_FullName", sFullName);
    put("N_Status", nStatus);
    put("S_Emirates", sEmirates);
    put("locCode", locCode);
    put("S_IsLoaded", sIsLoaded);

    return data;
  }
}




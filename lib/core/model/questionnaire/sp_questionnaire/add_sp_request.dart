// To parse this JSON data, do
//
//     final addSpRequest = addSpRequestFromJson(jsonString);

import 'dart:convert';

List<AddSpRequest> addSpRequestFromJson(String str) => List<AddSpRequest>.from(json.decode(str).map((x) => AddSpRequest.fromJson(x)));

String addSpRequestToJson(List<AddSpRequest> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class AddSpRequest {
  int? nSpAnswerId;
  String? spTime;
  int? nInterviewMasterId;
  String? sSpTag;
  String? sReference;
  String? sOdForSp;
  String? sDestination;
  String? sCarOwner;
  String? sHsRailElig;
  int? nScenario;
  String? spFuelCost;
  String? spTollCost;
  String? spParkingCost;
  String? spCarCost;
  String? spCarTime;
  String? spTaxiCost;
  String? spTaxiTime;
  String? spRailCommuteTime;
  String? spRailTime;
  String? spRailCost;
  String? spRailTotalTime;
  String? spBusCommuteTime;
  String? spBusTime;
  String? spBusCost;
  String? spBusTotalTime;
  int? nCreatedBy;
  String? action;
  String? dtInterviewStartTime; // Dt_Interview_StartTime
  String? dtInterviewEndTime;   // Dt_Interview_EndTime
  String? sTotalTime;           // S_TotalTime

  AddSpRequest({
    this.nSpAnswerId,
    this.nInterviewMasterId,
    this.sSpTag,
    this.spTime,
    this.sReference,
    this.sOdForSp,
    this.sDestination,
    this.sCarOwner,
    this.sHsRailElig,
    this.nScenario,
    this.spFuelCost,
    this.spTollCost,
    this.spParkingCost,
    this.spCarCost,
    this.spCarTime,
    this.spTaxiCost,
    this.spTaxiTime,
    this.spRailCommuteTime,
    this.spRailTime,
    this.spRailCost,
    this.spRailTotalTime,
    this.spBusCommuteTime,
    this.spBusTime,
    this.spBusCost,
    this.spBusTotalTime,
    this.nCreatedBy,
    this.action,
    // NEW
    this.dtInterviewStartTime,
    this.dtInterviewEndTime,
    this.sTotalTime,
  });

  factory AddSpRequest.fromJson(Map<String, dynamic> json) => AddSpRequest(
    nSpAnswerId: json["N_SP_AnswerID"],
    nInterviewMasterId: json["N_InterviewMasterID"],
    sSpTag: json["S_SPTag"],
    spTime: json["SP_Time"],
    sReference: json["S_Reference"],
    sOdForSp: json["S_ODForSP"],
    sDestination: json["S_Destination"],
    sCarOwner: json["S_CarOwner"],
    sHsRailElig: json["S_HSRailElig"],
    nScenario: json["N_Scenario"],
    spFuelCost: json["SP_FuelCost"],
    spTollCost: json["SP_TollCost"],
    spParkingCost: json["SP_ParkingCost"],
    spCarCost: json["SP_CarCost"],
    spCarTime: json["SP_CarTime"],
    spTaxiCost: json["SP_TaxiCost"],
    spTaxiTime: json["SP_TaxiTime"],
    spRailCommuteTime: json["SP_RailCommuteTime"],
    spRailTime: json["SP_RailTime"],
    spRailCost: json["SP_RailCost"],
    spRailTotalTime: json["SP_RailTotalTime"],
    spBusCommuteTime: json["SP_BusCommuteTime"],
    spBusTime: json["SP_BusTime"],
    spBusCost: json["SP_BusCost"],
    spBusTotalTime: json["SP_BusTotalTime"],
    nCreatedBy: json["N_CreatedBy"],
    action: json["Action"],
    // NEW
    dtInterviewStartTime: json["Dt_Interview_StartTime"],
    dtInterviewEndTime:   json["Dt_Interview_EndTime"],
    sTotalTime:           json["S_TotalTime"],
  );

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      "N_InterviewMasterID": nInterviewMasterId,
      "S_SPTag": sSpTag,
      "S_Reference": sReference,
      "S_ODForSP": sOdForSp,
      "S_Destination": sDestination,
      "S_CarOwner": sCarOwner,
      "S_HSRailElig": sHsRailElig,
      "N_Scenario": nScenario,
      'SP_Time': spTime,
      "N_CreatedBy": nCreatedBy,
      "Action": action,
      "SP_FuelCost": spFuelCost,
      "SP_TollCost": spTollCost,
      "SP_ParkingCost": spParkingCost,
      "SP_CarCost": spCarCost,
      "SP_CarTime": spCarTime,
      "SP_TaxiCost": spTaxiCost,
      "SP_TaxiTime": spTaxiTime,
      "SP_RailCommuteTime": spRailCommuteTime,
      "SP_RailTime": spRailTime,
      "SP_RailCost": spRailCost,
      "SP_RailTotalTime": spRailTotalTime,
      "SP_BusCommuteTime": spBusCommuteTime,
      "SP_BusTime": spBusTime,
      "SP_BusCost": spBusCost,
      "SP_BusTotalTime": spBusTotalTime,
      // NEW
      "Dt_Interview_StartTime": dtInterviewStartTime,
      "Dt_Interview_EndTime":   dtInterviewEndTime,
      "S_TotalTime":            sTotalTime,
    };

    // Only include N_SP_AnswerID if not null
    if (nSpAnswerId != null) {
      data["N_SP_AnswerID"] = nSpAnswerId;
    }

    // Remove any keys with null values (optional, cleanest payload)
    data.removeWhere((k, v) => v == null);
    return data;
  }
}

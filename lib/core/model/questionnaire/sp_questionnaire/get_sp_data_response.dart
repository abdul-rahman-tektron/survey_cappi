// To parse this JSON data, do
//
//     final getSpDataResponse = getSpDataResponseFromJson(jsonString);

import 'dart:convert';

GetSpDataResponse getSpDataResponseFromJson(String str) => GetSpDataResponse.fromJson(json.decode(str));

String getSpDataResponseToJson(GetSpDataResponse data) => json.encode(data.toJson());

class GetSpDataResponse {
  bool? status;
  String? message;
  List<GetSPDataResult>? result;

  GetSpDataResponse({
    this.status,
    this.message,
    this.result,
  });

  factory GetSpDataResponse.fromJson(Map<String, dynamic> json) => GetSpDataResponse(
    status: json["Status"],
    message: json["Message"],
    result: json["Result"] == null ? [] : List<GetSPDataResult>.from(json["Result"]!.map((x) => GetSPDataResult.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "Status": status,
    "Message": message,
    "Result": result == null ? [] : List<dynamic>.from(result!.map((x) => x.toJson())),
  };
}

class GetSPDataResult {
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

  GetSPDataResult({
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
  });

  factory GetSPDataResult.fromJson(Map<String, dynamic> json) => GetSPDataResult(
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
  );

  Map<String, dynamic> toJson() => {
    "S_Reference": sReference,
    "S_ODForSP": sOdForSp,
    "S_Destination": sDestination,
    "S_CarOwner": sCarOwner,
    "S_HSRailElig": sHsRailElig,
    "N_Scenario": nScenario,
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
  };
}

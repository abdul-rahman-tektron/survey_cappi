// add_passenger_request.dart
//
// One-shot Passenger submit model (same-to-same approach as AddRsiRequest).
// - Always include Screening + Demographics
// - Include exactly one category (petrol/border/bus/airport/hotel)
// - Submit via your existing apiAddRSIQuestionnaire() with toJson().

import 'dart:convert';

/// Helper: only include non-null fields in JSON
void _putIfNotNull(Map<String, dynamic> dst, String key, dynamic value) {
  if (value != null) dst[key] = value;
}

/// Optional: category type (can be useful if you want to enforce one category)
enum PassengerCategory { petrol, border, bus, airport, hotel }

/// ─────────────────────────────────────────────────────────────────────────
/// COMBINED SUBMIT MODEL (same-to-same as RSI shape)
/// ─────────────────────────────────────────────────────────────────────────
class AddPassengerRequest {
  // NEW meta
  String? action;       // -> "Action"
  int? nProjectId;      // -> "N_ProjectID"
  int? nStatus;      // -> "N_ProjectID"
  String? sEmirates; // NEW
  int? nPassengerRsiid;
  int? nVehicleType;

  // ── Screening (always present)
  String? dtInterviewStartTime; // Dt_Interview_StartTime
  String? sTotalTime; // Dt_Interview_StartTime
  String? dtInterviewEndTime;   // Dt_Interview_EndTime
  String? sLattitude;           // S_Lattitude
  String? sLongitude;           // S_Longitude
  String? sSurveyType;             // S_SurveyType
  int? nCreatedBy;              // N_CreatedBy
  int? nCarPresent;             // N_CarPresent
  String? sSetEligibility;      // S_SetEligibility

  // ── Demographics (always present)
  String? sGender;                 // S_Gender
  String? sFullName;                 // S_Gender
  String? sAge;                       // S_Age
  String? sTravellerType;          // S_TravellerType
  String? sNationality;               // S_Nationality
  String? sSuburbs;                // S_Suburbs
  String? sDriverResidency;        // S_DriverResidency
  String? sMonthlyIncome;             // S_MonthlyIncome
  String? sOccupation;             // S_Occupation
  String? sPrivateCarAvailability;    // S_PrivateCarAvailability

  // ── Category-specific (exactly one block set below)
  // PETROL
  String? sOrigin;              // S_Origin
  int?    nTRIPPURP;            // N_TRIPPURP (ID only)
  String? dtTripStartTime;      // Dt_TripStartTime   ✅ NEW
  String? sLastActivity;        // S_LastActivity     ✅ NEW
  String? sDestination;         // S_Destination
  String? sNextActivity;        // S_NextActivity     ✅ NEW
  String? sODforSP;             // S_ODforSP
  String? sFrequency;           // S_Frequency        ✅ NEW
  String? sCostTrip;            // S_CostTrip
  int?    nNoOfPassenger;       // N_NoOfPassenger
  String? sCostSharing;         // S_CostSharing
  String? dtTripEndTimeTrip;


  // ── AIRPORT
  String? sAirsideOD;        // S_AirsideOD  (F2/F10)
  String? sAirline;          // S_Airline    (F3/F11)
  String? sLandsideOD;       // S_LandsideOD (F4/F12)
  String? sStayDuration;     // S_StayDuration (F7/F15)
  String? sICTravelPattern;  // S_ICTravelPattern (F8/F16)
  String? sVehicleType;

  // Future blocks (you’ll give keys later). Add fields here when ready:
  // // BORDER: ...
  // BUS
  String? sPTAccess;          // S_PTAccess (E3/E7)
  String? sFinalDestination;  // S_FinalDestination (E5)
  String? sICModeChoice;      // S_ICModeChoice (E19)
  String? sBusRoute;          // S_BusRoute (E8)

  // // AIRPORT: ...
  // // HOTEL: ...
  String? sHotelDestinationCsv;
  String? nHotelVehicleTypeCsv;
  String? sHotelLocDurationCsv;
  String? sHotelStayDuration;
  int? nHotelNoOfTrips;

  AddPassengerRequest({
    this.action,
    this.nProjectId,
    this.nStatus,
    this.sEmirates,
    this.nVehicleType,
    // screening
    this.dtInterviewStartTime,
    this.sTotalTime,
    this.dtInterviewEndTime,
    this.sLattitude,
    this.sLongitude,
    this.sSurveyType,
    this.nCreatedBy,
    this.nCarPresent,
    this.sSetEligibility,
    // demo
    this.sFullName,
    this.sGender,
    this.sAge,
    this.sTravellerType,
    this.sNationality,
    this.sSuburbs,
    this.sDriverResidency,
    this.sMonthlyIncome,
    this.sOccupation,
    this.sPrivateCarAvailability,
    // petrol
    this.sOrigin,
    this.nTRIPPURP,
    this.dtTripStartTime,
    this.sLastActivity,
    this.sDestination,
    this.sNextActivity,
    this.sODforSP,
    this.sFrequency,
    this.sCostTrip,
    this.nNoOfPassenger,
    this.sCostSharing,
    this.dtTripEndTimeTrip,

    //airport
    this.sAirsideOD,
    this.sAirline,
    this.sLandsideOD,
    this.sStayDuration,
    this.sICTravelPattern,
    this.sVehicleType,

    //Bus
    this.sPTAccess,
    this.sFinalDestination,
    this.sICModeChoice,
    this.sBusRoute,

    //Hotel
    this.sHotelDestinationCsv,
    this.nHotelVehicleTypeCsv,
    this.sHotelLocDurationCsv,
    this.sHotelStayDuration,
    this.nHotelNoOfTrips,
    this.nPassengerRsiid,
  });

  /// Build from smaller section payloads (screening + demographics + ONE category)
  factory AddPassengerRequest.fromSections({
    String action = 'add',
    required int projectId,
    required int nStatus,
    required ScreeningPayload screening,
    required DemographicsPayload demographics,
    int? nPassengerRsiid,
    PetrolPayload? petrol,
    BorderPayload? border,
    BusPayload? bus,
    AirportPayload? airport,
    HotelPayload? hotel,
  }) {
    final merged = <String, dynamic>{
      'Action': action,
      'N_ProjectID': projectId,
      'N_Status': nStatus,
      if (nPassengerRsiid != null) 'N_PassengerRSIID': nPassengerRsiid,
    }
      ..addAll(screening.toJson())
      ..addAll(demographics.toJson());

    if (petrol != null)  merged.addAll(petrol.toJson());
    if (border != null)  merged.addAll(border.toJson());
    if (bus != null)     merged.addAll(bus.toJson());
    if (airport != null) merged.addAll(airport.toJson());
    if (hotel != null)   merged.addAll(hotel.toJson());

    return AddPassengerRequest.fromJson(merged);
  }

  factory AddPassengerRequest.fromJson(Map<String, dynamic> json) =>
      AddPassengerRequest(
        // screening
        action: json['Action'],
        sEmirates: json['S_Emirates'],
        nProjectId: json['N_ProjectID'],
        nStatus: json['N_Status'],
        nPassengerRsiid: json['N_PassengerRSIID'],
        dtInterviewStartTime: json['Dt_Interview_StartTime'],
        sTotalTime: json['S_TotalTime'],
        dtInterviewEndTime: json['Dt_Interview_EndTime'],
        sLattitude: json['S_Lattitude_Actual'],
        sLongitude: json['S_Longitude_Actual'],
        sSurveyType: json['S_SurveyType'],
        nCreatedBy: json['N_CreatedBy'],
        nCarPresent: json['N_CarPresent'],
        sSetEligibility: json['S_SetEligibility'],
        sVehicleType: json['S_VehicleType'],

        // demo
        sGender: json['S_Gender'],
        sFullName: json['S_FullName'],
        sAge: json['S_Age'],
        sTravellerType: json['S_TravellerType'],
        sNationality: json['S_Nationality'],
        sSuburbs: json['S_Suburbs'],
        sDriverResidency: json['S_DriverResidency'],
        sMonthlyIncome: json['S_MonthlyIncome'],
        sOccupation: json['S_Occupation'],
        sPrivateCarAvailability: json['S_PrivateCarAvailability'],

        // petrol (new spec)
        sOrigin: json['S_Origin'],
        nTRIPPURP: json['N_TRIPPURP'],
        dtTripStartTime: json['Dt_TripStartTime'],
        sLastActivity: json['S_LastActivity'],
        sDestination: json['S_Destination'],
        sNextActivity: json['S_NextActivity'],
        sODforSP: json['S_ODforSP'],
        sFrequency: json['S_Frequency'],
        sCostTrip: json['S_CostTrip'],
        nNoOfPassenger: json['N_NoOfPassenger'],
        sCostSharing: json['S_CostSharing'],
        //airport
        sAirsideOD: json['S_AirsideOD'],
        sAirline: json['S_Airline'],
        sLandsideOD: json['S_LandsideOD'],
        sStayDuration: json['S_StayDuration'],
        sICTravelPattern: json['S_ICTravelPattern'],

        // bus
        sPTAccess: json['S_PTAccess'],
        sFinalDestination: json['S_FinalDestination'],
        sICModeChoice: json['S_ICModeChoice'],
        sBusRoute: json['S_BusRoute'],

        //hotel
        sHotelDestinationCsv: json['S_Destination'],
        nHotelVehicleTypeCsv: (json['N_VehicleType'] is String)
                  ? json['N_VehicleType'] as String
                 : null,
        sHotelLocDurationCsv: json['S_LocDuration'],
        sHotelStayDuration:   json['S_StayDuration'],
        nHotelNoOfTrips:      json['N_NoOfTrips'],

        dtTripEndTimeTrip: json['Dt_TripEndTimeTrip'],
      );

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};

    _putIfNotNull(m, 'Action', action ?? 'add');
    _putIfNotNull(m, 'S_Emirates', sEmirates);
    _putIfNotNull(m, 'N_ProjectID', nProjectId);
    _putIfNotNull(m, 'N_Status', nStatus);
    _putIfNotNull(m, 'N_PassengerRSIID', nPassengerRsiid);

    // screening
    _putIfNotNull(m, 'Dt_Interview_StartTime', dtInterviewStartTime);
    _putIfNotNull(m, 'S_TotalTime', sTotalTime);
    _putIfNotNull(m, 'Dt_Interview_EndTime', dtInterviewEndTime);
    _putIfNotNull(m, 'S_Lattitude_Actual', sLattitude);
    _putIfNotNull(m, 'S_Longitude_Actual', sLongitude);
    _putIfNotNull(m, 'S_SurveyType', sSurveyType);
    _putIfNotNull(m, 'N_CreatedBy', nCreatedBy);
    _putIfNotNull(m, 'N_CarPresent', nCarPresent);
    _putIfNotNull(m, 'S_SetEligibility', sSetEligibility);

    // demographics
    _putIfNotNull(m, 'S_Gender', sGender);
    _putIfNotNull(m, 'S_FullName', sFullName);
    _putIfNotNull(m, 'S_Age', sAge);
    _putIfNotNull(m, 'S_TravellerType', sTravellerType);
    _putIfNotNull(m, 'S_Nationality', sNationality);
    _putIfNotNull(m, 'S_Suburbs', sSuburbs);
    _putIfNotNull(m, 'S_DriverResidency', sDriverResidency);
    _putIfNotNull(m, 'S_MonthlyIncome', sMonthlyIncome);
    _putIfNotNull(m, 'S_Occupation', sOccupation);
    _putIfNotNull(m, 'S_PrivateCarAvailability', sPrivateCarAvailability);
    _putIfNotNull(m, 'Dt_TripEndTimeTrip', dtTripEndTimeTrip); // NEW

    // petrol (new spec)
    _putIfNotNull(m, 'S_Origin', sOrigin);
    _putIfNotNull(m, 'N_TRIPPURP', nTRIPPURP);
    _putIfNotNull(m, 'Dt_TripStartTime', dtTripStartTime); // NEW
    _putIfNotNull(m, 'S_LastActivity', sLastActivity);     // NEW
    _putIfNotNull(m, 'S_Destination', sDestination);
    _putIfNotNull(m, 'S_NextActivity', sNextActivity);     // NEW
    _putIfNotNull(m, 'S_ODforSP', sODforSP);
    _putIfNotNull(m, 'S_Frequency', sFrequency);           // NEW
    _putIfNotNull(m, 'S_CostTrip', sCostTrip);
    _putIfNotNull(m, 'N_NoOfPassenger', nNoOfPassenger);
    _putIfNotNull(m, 'S_CostSharing', sCostSharing);

    //airport
    _putIfNotNull(m, 'S_AirsideOD', sAirsideOD);
    _putIfNotNull(m, 'S_Airline', sAirline);
    _putIfNotNull(m, 'S_LandsideOD', sLandsideOD);
    _putIfNotNull(m, 'S_StayDuration', sStayDuration);
    _putIfNotNull(m, 'S_ICTravelPattern', sICTravelPattern);
    _putIfNotNull(m, 'S_VehicleType', sVehicleType);
    // bus
    _putIfNotNull(m, 'S_PTAccess', sPTAccess);
    _putIfNotNull(m, 'S_FinalDestination', sFinalDestination);
    _putIfNotNull(m, 'S_ICModeChoice', sICModeChoice);
    _putIfNotNull(m, 'S_BusRoute', sBusRoute);

    // hotel
    _putIfNotNull(m, 'N_VehicleType', nHotelVehicleTypeCsv);
    _putIfNotNull(m, 'S_LocDuration', sHotelLocDurationCsv);
    _putIfNotNull(m, 'S_StayDuration', sHotelStayDuration);
    _putIfNotNull(m, 'N_NoOfTrips', nHotelNoOfTrips);

    return m;
  }

  String toJsonString() => json.encode(toJson());
}

/// ─────────────────────────────────────────────────────────────────────────
/// SMALL SECTION PAYLOADS (reuse from earlier reply; kept here for clarity)
/// ─────────────────────────────────────────────────────────────────────────
class ScreeningPayload {
  String? dtInterviewStartTime;
  String? sTotalTime;
  String? dtInterviewEndTime;
  String? sLattitude;
  String? sLongitude;
  String? sSurveyType;
  int? nCreatedBy;
  int? nCarPresent;
  String? sSetEligibility;
  String? sEmirates;

  ScreeningPayload({
    this.sTotalTime,
    this.dtInterviewStartTime,
    this.dtInterviewEndTime,
    this.sLattitude,
    this.sLongitude,
    this.sSurveyType,
    this.nCreatedBy,
    this.nCarPresent,
    this.sSetEligibility,
    this.sEmirates,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    _putIfNotNull(m, 'Dt_Interview_StartTime', dtInterviewStartTime);
    _putIfNotNull(m, 'S_TotalTime', sTotalTime);
    _putIfNotNull(m, 'Dt_Interview_EndTime', dtInterviewEndTime);
    _putIfNotNull(m, 'S_Lattitude_Actual', sLattitude);
    _putIfNotNull(m, 'S_Longitude_Actual', sLongitude);
    _putIfNotNull(m, 'S_SurveyType', sSurveyType);
    _putIfNotNull(m, 'N_CreatedBy', nCreatedBy);
    _putIfNotNull(m, 'N_CarPresent', nCarPresent);
    _putIfNotNull(m, 'S_SetEligibility', sSetEligibility);
    _putIfNotNull(m, 'S_Emirates', sEmirates);
    return m;
  }
}

class DemographicsPayload {
  final String? sGender;
  final String? sFullName;
  final String? sAge;
  final String? sTravellerType;
  final String? sNationality;
  final String? sSuburbs;
  final String? sDriverResidency;
  final String? sMonthlyIncome;
  final String? sOccupation;
  final String? sPrivateCarAvailability;

  DemographicsPayload({
    this.sGender,
    this.sFullName,
    this.sAge,
    this.sTravellerType,
    this.sNationality,
    this.sSuburbs,
    this.sDriverResidency,
    this.sMonthlyIncome,
    this.sOccupation,
    this.sPrivateCarAvailability,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    _putIfNotNull(m, 'S_FullName', sFullName);
    _putIfNotNull(m, 'S_Gender', sGender);
    _putIfNotNull(m, 'S_Age', sAge);
    _putIfNotNull(m, 'S_TravellerType', sTravellerType);
    _putIfNotNull(m, 'S_Nationality', sNationality);
    _putIfNotNull(m, 'S_Suburbs', sSuburbs);
    _putIfNotNull(m, 'S_DriverResidency', sDriverResidency);
    _putIfNotNull(m, 'S_MonthlyIncome', sMonthlyIncome);
    _putIfNotNull(m, 'S_Occupation', sOccupation);
    _putIfNotNull(m, 'S_PrivateCarAvailability', sPrivateCarAvailability);
    return m;
  }
}

/// ── PETROL (updated)
class PetrolPayload {
  final String? sOrigin;           // S_Origin
  final int?    nTRIPPURP;         // N_TRIPPURP (ID)
  final String? dtTripStartTime;   // Dt_TripStartTime  ✅ NEW
  final String? sLastActivity;     // S_LastActivity    ✅ NEW
  final String? sDestination;      // S_Destination
  final String? sNextActivity;     // S_NextActivity    ✅ NEW
  final String? sODforSP;          // S_ODforSP
  final String? sFrequency;        // S_Frequency       ✅ NEW
  final String? sCostTrip;         // S_CostTrip
  final int?    nNoOfPassenger;    // N_NoOfPassenger
  final String? sCostSharing;      // S_CostSharing
  final String? dtTripEndTimeTrip;

  // Legacy (kept for back-compat; not set by new petrol flow)
  @Deprecated('Legacy petrol field; not used by new C-set')
  final String? sOriginType;       // S_OriginType
  @Deprecated('Legacy petrol field; not used by new C-set')
  final String? sDestType;         // S_DestType
  @Deprecated('Legacy petrol field; not used by new C-set')
  final String? sVehicleType;      // S_VehicleType

  PetrolPayload({
    this.sOrigin,
    this.nTRIPPURP,
    this.dtTripStartTime,
    this.sLastActivity,
    this.sDestination,
    this.sNextActivity,
    this.sODforSP,
    this.sFrequency,
    this.sCostTrip,
    this.nNoOfPassenger,
    this.sCostSharing,
    // legacy
    this.sOriginType,
    this.sDestType,
    this.sVehicleType,
    this.dtTripEndTimeTrip,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    _putIfNotNull(m, 'S_Origin', sOrigin);
    _putIfNotNull(m, 'N_TRIPPURP', nTRIPPURP);
    _putIfNotNull(m, 'Dt_TripStartTime', dtTripStartTime); // NEW
    _putIfNotNull(m, 'S_LastActivity', sLastActivity);     // NEW
    _putIfNotNull(m, 'S_Destination', sDestination);
    _putIfNotNull(m, 'S_NextActivity', sNextActivity);     // NEW
    _putIfNotNull(m, 'S_ODforSP', sODforSP);
    _putIfNotNull(m, 'S_Frequency', sFrequency);           // NEW
    _putIfNotNull(m, 'S_CostTrip', sCostTrip);
    _putIfNotNull(m, 'N_NoOfPassenger', nNoOfPassenger);
    _putIfNotNull(m, 'S_CostSharing', sCostSharing);

    // legacy keys (harmless if unused)
    _putIfNotNull(m, 'S_OriginType', sOriginType);
    _putIfNotNull(m, 'S_DestType', sDestType);
    _putIfNotNull(m, 'S_VehicleType', sVehicleType);
    _putIfNotNull(m, 'Dt_TripEndTimeTrip', dtTripEndTimeTrip); // NEW
    return m;
  }
}

class BorderPayload {
  // NEW per D-set
  final int?    nTRIPPURP;        // D1 (ID only)
  final String? sOrigin;          // D2
  final String? dtTripStartTime;  // D3 → Dt_TripStartTime
  final String? sLastActivity;    // D4
  final String? sDestination;     // D5
  final String? sNextActivity;    // D6
  final String? sODforSP;         // D7
  final String? sFrequency;       // D8
  final String? sCostTrip;        // D9
  final int?    nNoOfPassenger;   // D10
  final String? sCostSharing;     // D11
  final String? dtTripEndTimeTrip;

  BorderPayload({
    this.nTRIPPURP,
    this.sOrigin,
    this.dtTripStartTime,
    this.sLastActivity,
    this.sDestination,
    this.sNextActivity,
    this.sODforSP,
    this.sFrequency,
    this.sCostTrip,
    this.nNoOfPassenger,
    this.sCostSharing,
    this.dtTripEndTimeTrip,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    _putIfNotNull(m, 'N_TRIPPURP', nTRIPPURP);
    _putIfNotNull(m, 'S_Origin', sOrigin);
    _putIfNotNull(m, 'Dt_TripStartTime', dtTripStartTime);
    _putIfNotNull(m, 'S_LastActivity', sLastActivity);
    _putIfNotNull(m, 'S_Destination', sDestination);
    _putIfNotNull(m, 'S_NextActivity', sNextActivity);
    _putIfNotNull(m, 'S_ODforSP', sODforSP);
    _putIfNotNull(m, 'S_Frequency', sFrequency);
    _putIfNotNull(m, 'S_CostTrip', sCostTrip);
    _putIfNotNull(m, 'N_NoOfPassenger', nNoOfPassenger);
    _putIfNotNull(m, 'S_CostSharing', sCostSharing);
    _putIfNotNull(m, 'Dt_TripEndTimeTrip', dtTripEndTimeTrip);
    return m;
  }
}

class AirportPayload {
  final String? sAirsideOD;
  final String? sAirline;
  final String? sLandsideOD;
  final int?    nTRIPPURP;        // only ID
  final String? sTravellerType; // NEW
  final String? sVehicleType; // string/label
  final String?    sStayDuration;
  final String? sICTravelPattern; // multi → CSV labels
  final int?    nNoOfPassenger;

  AirportPayload({
    this.sAirsideOD,
    this.sAirline,
    this.sLandsideOD,
    this.nTRIPPURP,
    this.sTravellerType,
    this.sVehicleType,
    this.sStayDuration,
    this.sICTravelPattern,
    this.nNoOfPassenger,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    _putIfNotNull(m, 'S_AirsideOD', sAirsideOD);
    _putIfNotNull(m, 'S_Airline', sAirline);
    _putIfNotNull(m, 'S_LandsideOD', sLandsideOD);
    _putIfNotNull(m, 'N_TRIPPURP', nTRIPPURP);
    _putIfNotNull(m, 'S_TravellerType', sTravellerType);
    _putIfNotNull(m, 'S_VehicleType', sVehicleType);
    _putIfNotNull(m, 'S_StayDuration', sStayDuration);
    _putIfNotNull(m, 'S_ICTravelPattern', sICTravelPattern);
    _putIfNotNull(m, 'N_NoOfPassenger', nNoOfPassenger);
    return m;
  }
}

// ── New BusPayload
class BusPayload {
  final String? sOrigin;            // E3  → S_Origin
  final String? sPTAccess;          // E7  → S_PTAccess (CSV of labels)
  final String? sDestination;       // E8  → S_Destination
  final String? sFinalDestination;  // E10 → S_FinalDestination (CSV of labels)
  final String? sODforSP;           // E12 → S_ODforSP (label)
  final int?    nTRIPPURP;          // E2  → N_TRIPPURP (ID only)
  final String? sICModeChoice;      // E14 → S_ICModeChoice
  final String? sCostTrip;          // E15 → S_CostTrip
  final String? sBusRoute;          // E6/E11 → S_BusRoute
  final String? dtTripEndTimeTrip;

  // NEW (Bus)
  final String? dtTripStartTime;    // E4
  final String? sLastActivity;      // E5
  final String? sNextActivity;      // E9
  final String? sFrequency;         // E13

  BusPayload({
    this.sOrigin,
    this.sPTAccess,
    this.sDestination,
    this.sFinalDestination,
    this.sODforSP,
    this.nTRIPPURP,
    this.sICModeChoice,
    this.sCostTrip,
    this.sBusRoute,
    this.dtTripStartTime,
    this.sLastActivity,
    this.sNextActivity,
    this.sFrequency,
    this.dtTripEndTimeTrip,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    _putIfNotNull(m, 'S_Origin', sOrigin);
    _putIfNotNull(m, 'S_PTAccess', sPTAccess);
    _putIfNotNull(m, 'S_Destination', sDestination);
    _putIfNotNull(m, 'S_FinalDestination', sFinalDestination);
    _putIfNotNull(m, 'S_ODforSP', sODforSP);
    _putIfNotNull(m, 'N_TRIPPURP', nTRIPPURP);
    _putIfNotNull(m, 'S_ICModeChoice', sICModeChoice);
    _putIfNotNull(m, 'S_CostTrip', sCostTrip);
    _putIfNotNull(m, 'S_BusRoute', sBusRoute);
    _putIfNotNull(m, 'Dt_TripEndTimeTrip', dtTripEndTimeTrip);

    // NEW
    _putIfNotNull(m, 'Dt_TripStartTime', dtTripStartTime);
    _putIfNotNull(m, 'S_LastActivity',   sLastActivity);
    _putIfNotNull(m, 'S_NextActivity',   sNextActivity);
    _putIfNotNull(m, 'S_Frequency',      sFrequency);
    return m;
  }
}

class HotelPayload {
  final String? sDestination;   // G2  → S_Destination (CSV of labels)
  final String? nVehicleType;   // G3  → N_VehicleType (CSV; spec asks for comma-sep if multiple)
  final String? sLocDuration;   // G4  → S_LocDuration (CSV; one per G2 selection)
  final String? sHotelStayDuration; // <— NEW: G5 as STRING (S_StayDuration)
  final int?    nNoOfTrips;     // G6  → N_NoOfTrips   (int)

  HotelPayload({
    this.sDestination,
    this.nVehicleType,
    this.sLocDuration,
    this.sHotelStayDuration,
    this.nNoOfTrips,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    _putIfNotNull(m, 'S_Destination', sDestination);
    _putIfNotNull(m, 'N_VehicleType', nVehicleType);
    _putIfNotNull(m, 'S_LocDuration', sLocDuration);
    _putIfNotNull(m, 'S_StayDuration', sHotelStayDuration);
    _putIfNotNull(m, 'N_NoOfTrips', nNoOfTrips);
    return m;
  }
}
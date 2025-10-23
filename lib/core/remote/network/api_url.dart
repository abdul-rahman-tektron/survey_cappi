class ApiUrls {
  ApiUrls._();

  ///Base
  static const baseHttp = "https://";
  static const baseHost = "teksmartsolutions.com/Arup_Project";

  ///Test
  // static const baseHttp = "http://";
  // static const baseHost = "192.168.10.30/CommunityServiceAPI/api";

  static const baseUrl = "$baseHttp$baseHost";

  ///Common
  static const pathGenerateToken = "/Api/Login/GenerateToken"; // POST
  static const pathLogin = "/Api/Login/GetLoginsDetails"; // POST
  static const pathRSIQuestionnaire = "/Api/RSI/AddUpdateRSI"; // POST
  static const pathPassengerQuestionnaire = "/Api/Passenger/AddUpdatePassenger"; // POST
  static const pathDropdown = "/Api/Configuration/GetAllDetailedCodesByMaster"; // POST
  static const pathNationalityDropdown = "/API/TravelDiary/GetAllCountries"; // POST
  static const pathEnumeratorCount = "/Api/Reports/GetAllRSIEnumeratorsCount"; // POST
  static const pathSurveyData = "/Api/Reports/GetSurveyData"; // POST
  static const pathGetRSIData = "/Api/RSI/GetInterviewRSI"; // POST
  static const pathGetSPData = "/Api/Passenger/GetSPData"; // POST
  static const pathAddSpData = "/Api/Passenger/AddUpdateSPData"; // POST
  static const pathGetPassengerData = "/Api/RSI/GetInterviewPassenger"; // POST
  static const pathGetSurveyorLocation = "/Api/Passenger/GetSurveyorLocations"; // POST
  static const pathGetSurveyorData = "/Api/Reports/GetSurveyPaged"; // POST
}

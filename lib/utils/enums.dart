enum LoadingState { idle, busy }

enum Method { get, post, put, delete }

enum UserRole { superAdmin, interviewer }

enum QuestionnaireType {
  freightRsi,      // Freight Roadside Interviews (Appendix C)
  passengerPetrol, // Passenger vehicle RSI – petrol station
  passengerBorder, // Passenger vehicle RSI – border crossing
  bus,             // Intercity bus station
  airport,         // Airport landside
  hotel,           // Hotel
  statedPreference // Scenario-based SP (conditional on OD)
}


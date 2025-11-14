import 'package:flutter/material.dart';

// ───────────── Modes, icons, labels for SP2
enum Sp2Mode { car, taxi, shuttle, bus }

IconData sp2Icon(Sp2Mode m) {
  switch (m) {
    case Sp2Mode.car:     return Icons.directions_car_filled_rounded;
    case Sp2Mode.taxi:    return Icons.local_taxi_rounded;
    case Sp2Mode.shuttle: return Icons.directions_bus_filled_rounded;
    case Sp2Mode.bus:     return Icons.directions_bus_filled_rounded;
  }
}

String sp2Label(Sp2Mode m) {
  switch (m) {
    case Sp2Mode.car:     return 'Car';
    case Sp2Mode.taxi:    return 'Taxi';
    case Sp2Mode.shuttle: return 'Etihad Rail Shuttle Bus';
    case Sp2Mode.bus:     return 'Bus';
  }
}

// ───────────── Option + Set for SP2 (fields parallel your SP1 model)
class Sp2Option {
  final Sp2Mode mode;
  final num? totalCost; // AED
  final num? totalTime; // mins

  // Car breakdown
  final num? fuelCost;
  final num? tollsCost;
  final num? parkingCost;

  // Shuttle breakdown
  final num? timeToFromShuttleStops;
  final num? timeOnShuttle;

  // Bus breakdown
  final num? timeToFromBusStops;
  final num? timeOnBus;

  const Sp2Option({
    required this.mode,
    this.totalCost,
    this.totalTime,
    this.fuelCost,
    this.tollsCost,
    this.parkingCost,
    this.timeToFromShuttleStops,
    this.timeOnShuttle,
    this.timeToFromBusStops,
    this.timeOnBus,
  });
}

class Sp2Set {
  final String reference;     // e.g., H2
  final String origin;        // e.g., Abu Dhabi
  final String destination;   // e.g., Dubai
  final bool carOwner;        // Yes/No
  final int scenario;         // 1..12
  final List<Sp2Option> options;

  int? selectedIndex;

  Sp2Set({
    required this.reference,
    required this.origin,
    required this.destination,
    required this.carOwner,
    required this.scenario,
    required this.options,
    this.selectedIndex,
  });
}
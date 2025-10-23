import 'package:flutter/material.dart';

enum SpMode { car, taxi, rail, bus }

IconData spIcon(SpMode m) {
  switch (m) {
    case SpMode.car:  return Icons.directions_car_filled_rounded;
    case SpMode.taxi: return Icons.local_taxi_rounded;
    case SpMode.rail: return Icons.train_rounded;
    case SpMode.bus:  return Icons.directions_bus_filled_rounded;
  }
}

String spLabel(SpMode m) {
  switch (m) {
    case SpMode.car:  return 'Car';
    case SpMode.taxi: return 'Taxi';
    case SpMode.rail: return 'Rail';
    case SpMode.bus:  return 'Bus';
  }
}

/// A single option’s metrics shown on the card (cost/time + optional breakdown)
class SpOption {
  final SpMode mode;
  final num? totalCost; // AED
  final num? totalTime; // mins

  // Optional drill-down
  final num? fuelCost;
  final num? tollsCost;
  final num? parkingCost;

  final num? timeToFromStations; // rail
  final num? timeOnTrain;        // rail

  final num? timeToFromBusStops; // bus
  final num? timeOnBus;          // bus

  const SpOption({
    required this.mode,
    this.totalCost,
    this.totalTime,
    this.fuelCost,
    this.tollsCost,
    this.parkingCost,
    this.timeToFromStations,
    this.timeOnTrain,
    this.timeToFromBusStops,
    this.timeOnBus,
  });
}

/// A single “set” (1 of 6) that contains 4 options and the reference banner.
class SpSet {
  final String reference;     // e.g., H2
  final String origin;        // e.g., Abu Dhabi
  final String destination;   // e.g., Dubai
  final bool carOwner;        // Yes/No
  final bool hsRailRelevant;  // true only for AUH<->DXB
  final int scenario;         // 1..12
  final List<SpOption> options;

  /// selected option index within [options], or null if not chosen yet
  int? selectedIndex;

  SpSet({
    required this.reference,
    required this.origin,
    required this.destination,
    required this.carOwner,
    required this.hsRailRelevant,
    required this.scenario,
    required this.options,
    this.selectedIndex,
  });
}
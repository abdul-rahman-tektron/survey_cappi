// lib/utils/location/location_picker_notifier.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:location/location.dart';

/// A notifier that manages the map, selected coordinates, and address details.
class LocationPickerNotifier extends ChangeNotifier {
  GoogleMapController? _mapController;

  LatLng? _selectedPosition;
  String? _selectedPlaceName;

  final locationController = TextEditingController();

  String? building;
  String? block;
  String? community;


  LatLng? get selectedPosition => _selectedPosition;
  String? get selectedPlaceName => _selectedPlaceName;

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Sets the map position and reverse-geocodes details.
  Future<void> setPlaceDetails({
    required LatLng position,
    required String placeName,
  }) async {
    _selectedPosition = position;
    _selectedPlaceName = placeName;

    await _reverseGeocode(position);

    _mapController?.animateCamera(CameraUpdate.newLatLng(position));
    notifyListeners();
  }

  /// Reverse-geocode the coordinates into human-readable info.
  Future<void> _reverseGeocode(LatLng position) async {
    try {
      final placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        final street = p.thoroughfare ?? '';
        final blockName = p.subLocality ?? '';
        final city = p.administrativeArea ?? '';

        final parts = [
          if (street.isNotEmpty) street,
          if (blockName.isNotEmpty) blockName,
          if (city.isNotEmpty) city,
        ];

        _selectedPlaceName = parts.join(", ");
        building = p.subThoroughfare?.isNotEmpty == true ? p.subThoroughfare : p.name;
        block = blockName;
        community = p.locality ?? '';
      }
    } catch (e) {
      debugPrint("Reverse geocode error: $e");
      building = null;
      block = null;
      community = null;
    }
  }

  /// Fetches device's current location and updates marker.
  Future<void> fetchCurrentLocation() async {
    try {
      final location = Location();

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled && !await location.requestService()) return;

      PermissionStatus permission = await location.hasPermission();
      if (permission == PermissionStatus.denied &&
          await location.requestPermission() != PermissionStatus.granted) {
        return;
      }

      final current = await location.getLocation();
      if (current.latitude != null && current.longitude != null) {
        await setPlaceDetails(
          position: LatLng(current.latitude!, current.longitude!),
          placeName: "Current Location",
        );
      }
    } catch (e) {
      debugPrint("Error fetching current location: $e");
    }
  }

  void clear() {
    _selectedPosition = null;
    _selectedPlaceName = null;
    building = null;
    block = null;
    community = null;
    locationController.clear();
    notifyListeners();
  }
}
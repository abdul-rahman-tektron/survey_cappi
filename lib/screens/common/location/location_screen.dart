// lib/utils/widgets/location/select_location_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:provider/provider.dart';
import 'package:srpf/res/api_constants.dart';

import 'package:srpf/res/colors.dart';
import 'package:srpf/res/fonts.dart';
import 'package:srpf/screens/common/location/location_notifier.dart';
import 'package:srpf/utils/widgets/custom_buttons.dart';

// ⬇️ Make sure you have this notifier (you pasted it earlier).
// Adjust the import path to where you placed LocationPickerNotifier.

class SelectLocationMap extends StatelessWidget {
  /// Google Places API key (required for the autocomplete search bar).
  /// If you don't want the search bar, pass an empty string.
  final String googleApiKey;

  /// Optional initial camera target (defaults to Dubai)
  final LatLng initialTarget;

  /// Optional initial zoom
  final double initialZoom;

  const SelectLocationMap({
    super.key,
    required this.googleApiKey,
    this.initialTarget = const LatLng(25.2048, 55.2708),
    this.initialZoom = 12,
  });

  @override
  Widget build(BuildContext context) {
    print("googleApiKey");
    print(googleApiKey);
    return ChangeNotifierProvider<LocationPickerNotifier>(
      create: (_) => LocationPickerNotifier(),
      child: Consumer<LocationPickerNotifier>(
        builder: (context, notifier, _) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.textPrimary,
              title: const Text('Select Location'),
              elevation: 0.5,
            ),
            body: Stack(
              children: [
                // ── Google Map ────────────────────────────────────────────────
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: initialTarget,
                    zoom: initialZoom,
                  ),
                  myLocationButtonEnabled: false,
                  myLocationEnabled: false,
                  onMapCreated: notifier.setMapController,
                  onTap: (pos) {
                    notifier.setPlaceDetails(
                      position: pos,
                      placeName: "Dropped pin",
                    );
                  },
                  markers: notifier.selectedPosition == null
                      ? {}
                      : {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: notifier.selectedPosition!,
                    ),
                  },
                ),

                // ── Places Search Bar (if API key provided) ───────────────────
                if (googleApiKey.trim().isNotEmpty)
                  Positioned(
                    top: 15.h,
                    left: 15.w,
                    right: 15.w,
                    child: Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(8.r),
                      child: GooglePlaceAutoCompleteTextField(
                        textEditingController: notifier.locationController,
                        googleAPIKey: ApiConstants.apiKey, // <- your Places API key
                        debounceTime: 300,
                        countries: const ["ae", "sa", "om", "qa"],
                        isLatLngRequired: true,
                        inputDecoration: InputDecoration(
                          hintText: "Search your address",
                          filled: true,
                          hintStyle: const TextStyle(color: AppColors.textSecondary),
                          isDense: true,
                          fillColor: AppColors.white,
                          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                        ),

                        // This is called only when isLatLngRequired = true
                        getPlaceDetailWithLatLng: (prediction) {
                          // prediction.lat / prediction.lng are strings
                          final lat = double.tryParse(prediction.lat ?? '');
                          final lng = double.tryParse(prediction.lng ?? '');
                          if (lat != null && lng != null) {
                            notifier.setPlaceDetails(
                              position: LatLng(lat, lng),
                              placeName: prediction.description ?? 'Selected place',
                            );
                          } else {
                            // Fallback (rare): ask user to pick on map or handle gracefully
                            debugPrint('Coordinates missing from place details.');
                          }
                        },

                        // Just update the text field on tap (coords arrive in getPlaceDetailWithLatLng)
                        itemClick: (prediction) {
                          final desc = prediction.description ?? '';
                          notifier.locationController.text = desc;
                          notifier.locationController.selection = TextSelection.fromPosition(
                            TextPosition(offset: desc.length),
                          );
                        },

                        // Optional custom row
                        itemBuilder: (context, index, prediction) => Container(
                          color: AppColors.white,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on),
                              const SizedBox(width: 8),
                              Expanded(child: Text(prediction.description ?? "")),
                            ],
                          ),
                        ),
                        isCrossBtnShown: true,
                        containerHorizontalPadding: 10,
                        boxDecoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        keyboardType: TextInputType.text,
                      ),
                    ),
                  ),

                // ── Current location button ───────────────────────────────────
                Positioned(
                  bottom: 100.h,
                  right: 12.w,
                  child: FloatingActionButton(
                    heroTag: 'currentLocationBtn',
                    backgroundColor: AppColors.white,
                    mini: true,
                    elevation: 2,
                    onPressed: () => notifier.fetchCurrentLocation(),
                    child: const Icon(Icons.my_location, color: AppColors.secondary),
                  ),
                ),

                // ── Info card + Select button ─────────────────────────────────
                if (notifier.selectedPosition != null)
                  Positioned(
                    bottom: 20.h,
                    left: 16.w,
                    right: 16.w,
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowColor.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notifier.selectedPlaceName ?? "Dropped pin",
                            style: AppFonts.text16.semiBold.style,
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            "Lat: ${notifier.selectedPosition!.latitude.toStringAsFixed(6)}",
                            style: AppFonts.text14.regular.style,
                          ),
                          Text(
                            "Lng: ${notifier.selectedPosition!.longitude.toStringAsFixed(6)}",
                            style: AppFonts.text14.regular.style,
                          ),
                          if ((notifier.building ?? '').isNotEmpty)
                            Text("Building: ${notifier.building}", style: AppFonts.text14.regular.style),
                          if ((notifier.block ?? '').isNotEmpty)
                            Text("Block: ${notifier.block}", style: AppFonts.text14.regular.style),
                          if ((notifier.community ?? '').isNotEmpty)
                            Text("Community: ${notifier.community}", style: AppFonts.text14.regular.style),
                          SizedBox(height: 12.h),
                          CustomButton(
                            text: "Select This Location",
                            onPressed: () {
                              final pos = notifier.selectedPosition!;
                              Navigator.pop(context, {
                                'lat': pos.latitude,
                                'lng': pos.longitude,
                                'address': notifier.selectedPlaceName ?? '',
                                'building': notifier.building ?? '',
                                'block': notifier.block ?? '',
                                'community': notifier.community ?? '',
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
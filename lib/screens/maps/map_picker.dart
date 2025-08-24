import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/widgets/custom_form_field.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? selectedLatLng;
  String? address;

  late MapController mapController;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _moveToCurrentLocation();
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      final position = await getCurrentPosition(); // your function
      final latLng = LatLng(position.latitude, position.longitude);

      mapController.move(latLng, 15);

      setState(() {
        selectedLatLng = latLng;
      });

      await _getAddress(latLng);
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> _getAddress(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          address = "${place.street}, ${place.locality}, ${place.country}";
        });
      }
    } catch (e) {
      print("Error reverse geocoding: $e");
      setState(() {
        address = "Unknown location";
      });
    }
  }

  List<String> get currentAddresses => currentUserModel.addresses;

  bool get isLocationValid =>
      selectedLatLng != null &&
      address != null &&
      address != "Unknown location";

  Future<void> _searchLocation(String query) async {
    try {
      if (query.isEmpty) return;

      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);

        // Update map position
        mapController.move(latLng, 15);

        // Update selected pin and address
        setState(() {
          selectedLatLng = latLng;
        });

        await _getAddress(latLng);

        searchController.clear();
      }
    } catch (e) {
      print("Error searching location: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Location not found")));
      }
    }
  }

  @override
  void dispose() {
    mapController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text("Select your address")),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: selectedLatLng ?? LatLng(0, 0),
              initialZoom: 13.0,
              onTap: (tapPosition, latLng) {
                setState(() {
                  selectedLatLng = latLng;
                });
                _getAddress(latLng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.matajer.matajer',
              ),
              if (selectedLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedLatLng!,
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (address != null)
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Column(
                  spacing: 10,
                  children: [
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    lang == 'en' ? 7 : 0,
                                    6,
                                    lang == 'en' ? 0 : 7,
                                    6,
                                  ),
                                  child: Material(
                                    color: lightGreyColor.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12.r),
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Icon(
                                          backIcon(),
                                          color: textColor,
                                          size: 26,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: Text(
                              S.of(context).add_new_location,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                          Expanded(child: SizedBox(width: 0)),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: secondaryColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          address!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Search field positioned above the bottom button
          Positioned(
            bottom: 10, // above the select button (height + padding)
            left: 10,
            child: Container(
              width: 0.75.sw,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: // Inside the search field
              CustomFormField(
                controller: searchController,
                color: Colors.white,
                keyboardType: TextInputType.webSearch,
                suffix: IconButton(
                  onPressed: () {
                    searchController.clear();
                  },
                  icon: Icon(Icons.clear),
                ),
                hint: "Search location",
                onSubmit: (value) {
                  if (value != null && value.isNotEmpty) {
                    _searchLocation(value); // directly call the async function
                  }
                },
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Material(
            color:
                isLocationValid &&
                    (address != null && !currentAddresses.contains(address))
                ? primaryColor
                : Colors.grey, // disabled color if already exists
            borderRadius: BorderRadius.circular(12.r),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: isLocationValid && !currentAddresses.contains(address)
                    ? () {
                        Navigator.pop(context, address);
                      }
                    : null,
                child: Center(
                  child: Text(
                    currentAddresses.contains(address)
                        ? "Location already saved"
                        : "Select this location",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _moveToCurrentLocation,
        tooltip: 'Go to current location',
        shape: CircleBorder(),
        backgroundColor: secondaryColor,
        foregroundColor: primaryColor,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../config/theme/app_colors.dart';

/// Full-screen location picker. User can tap on map or search address.
/// Returns a LocationPickerResult with coordinates and address info.
class LocationPickerResult {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? country;

  const LocationPickerResult({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.country,
  });
}

class LocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final _searchController = TextEditingController();

  LatLng? _selectedPosition;
  String? _selectedAddress;
  String? _selectedCity;
  String? _selectedCountry;
  bool _loading = false;
  bool _searching = false;
  List<Location> _searchResults = [];

  // Default: Santiago, Chile
  static const _defaultPosition = LatLng(-33.4489, -70.6693);

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedPosition = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
    _initLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    if (_selectedPosition != null) return;

    setState(() => _loading = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          setState(() {
            _selectedPosition = _defaultPosition;
            _loading = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _selectedPosition = _defaultPosition;
          _loading = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      setState(() {
        _selectedPosition = LatLng(pos.latitude, pos.longitude);
        _loading = false;
      });
      _reverseGeocode(_selectedPosition!);
    } catch (_) {
      setState(() {
        _selectedPosition ??= _defaultPosition;
        _loading = false;
      });
    }
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        setState(() {
          _selectedAddress = [p.street, p.subLocality, p.locality]
              .where((s) => s != null && s.isNotEmpty)
              .join(', ');
          _selectedCity = p.locality ?? p.subAdministrativeArea;
          _selectedCountry = p.country;
        });
      }
    } catch (_) {}
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().length < 3) return;
    setState(() => _searching = true);
    try {
      final results = await locationFromAddress(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _searching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _selectSearchResult(Location loc) async {
    final pos = LatLng(loc.latitude, loc.longitude);
    setState(() {
      _selectedPosition = pos;
      _searchResults = [];
      _searchController.clear();
    });
    FocusScope.of(context).unfocus();

    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
    _reverseGeocode(pos);
  }

  void _onMapTap(LatLng pos) {
    setState(() => _selectedPosition = pos);
    _reverseGeocode(pos);
  }

  void _confirmLocation() {
    if (_selectedPosition == null) return;
    Navigator.of(context).pop(LocationPickerResult(
      latitude: _selectedPosition!.latitude,
      longitude: _selectedPosition!.longitude,
      address: _selectedAddress,
      city: _selectedCity,
      country: _selectedCountry,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          if (_loading || _selectedPosition == null)
            const Center(child: CircularProgressIndicator(color: AtrioColors.neonLimeDark))
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedPosition!,
                zoom: 15,
              ),
              onMapCreated: (c) {
                if (!_mapController.isCompleted) _mapController.complete(c);
              },
              onTap: _onMapTap,
              markers: _selectedPosition == null
                  ? {}
                  : {
                      Marker(
                        markerId: const MarkerId('selected'),
                        position: _selectedPosition!,
                        draggable: true,
                        onDragEnd: (pos) {
                          setState(() => _selectedPosition = pos);
                          _reverseGeocode(pos);
                        },
                      ),
                    },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),

          // Search bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                          ),
                          child: const Icon(Icons.arrow_back, size: 22),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Search field
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar dirección...',
                              hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchResults = []);
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            style: GoogleFonts.inter(fontSize: 14),
                            onChanged: (v) => setState(() {}),
                            onSubmitted: _searchAddress,
                            textInputAction: TextInputAction.search,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Search results
                  if (_searchResults.isNotEmpty || _searching)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                      ),
                      child: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _searchResults.length,
                              itemBuilder: (_, i) {
                                final loc = _searchResults[i];
                                return ListTile(
                                  leading: const Icon(Icons.location_on, color: AtrioColors.neonLimeDark),
                                  title: Text(
                                    '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                  onTap: () => _selectSearchResult(loc),
                                  dense: true,
                                );
                              },
                            ),
                    ),
                ],
              ),
            ),
          ),

          // My location FAB
          Positioned(
            right: 16, bottom: 140,
            child: FloatingActionButton.small(
              heroTag: 'my_loc',
              backgroundColor: Colors.white,
              onPressed: () async {
                try {
                  final pos = await Geolocator.getCurrentPosition(
                    locationSettings: const LocationSettings(
                      accuracy: LocationAccuracy.high,
                      timeLimit: Duration(seconds: 8),
                    ),
                  );
                  final latLng = LatLng(pos.latitude, pos.longitude);
                  setState(() => _selectedPosition = latLng);
                  final c = await _mapController.future;
                  c.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
                  _reverseGeocode(latLng);
                } catch (_) {}
              },
              child: const Icon(Icons.my_location, color: Colors.black87, size: 20),
            ),
          ),

          // Bottom card with address and confirm
          if (_selectedPosition != null)
            Positioned(
              left: 16, right: 16, bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AtrioColors.neonLimeDark, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedAddress ?? 'Toca el mapa para seleccionar',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedCity != null || _selectedCountry != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [_selectedCity, _selectedCountry].where((s) => s != null).join(', '),
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _confirmLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AtrioColors.neonLimeDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Confirmar ubicación', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

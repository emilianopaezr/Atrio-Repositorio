import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Read-only map widget that shows a single marker at the given coordinates.
/// Used in listing detail, booking detail, etc.
class LocationMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? title;
  final double height;
  final bool interactive;
  final double zoomLevel;

  const LocationMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.title,
    this.height = 200,
    this.interactive = false,
    this.zoomLevel = 15,
  });

  @override
  State<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<LocationMapWidget> {
  final Completer<GoogleMapController> _controller = Completer();

  @override
  Widget build(BuildContext context) {
    final position = LatLng(widget.latitude, widget.longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: position,
                zoom: widget.zoomLevel,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('listing'),
                  position: position,
                  infoWindow: widget.title != null
                      ? InfoWindow(title: widget.title)
                      : InfoWindow.noText,
                ),
              },
              onMapCreated: (controller) {
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
              },
              scrollGesturesEnabled: widget.interactive,
              zoomGesturesEnabled: widget.interactive,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              liteModeEnabled: !widget.interactive,
            ),
            if (!widget.interactive)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showFullMap(context, position),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFullMap(BuildContext context, LatLng position) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Ubicación',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: position,
                  zoom: widget.zoomLevel,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('listing'),
                    position: position,
                    infoWindow: widget.title != null
                        ? InfoWindow(title: widget.title)
                        : InfoWindow.noText,
                  ),
                },
                zoomControlsEnabled: true,
                mapToolbarEnabled: true,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

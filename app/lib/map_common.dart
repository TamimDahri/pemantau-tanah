import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'app_state.dart';
import 'models.dart';
import 'theme.dart';

/// OpenStreetMap tiles as the base map until the real GIS layers are added.
/// Tiles need an internet connection; lot data in this demo does not.
List<Widget> baseMapLayers() {
  return [
    if (appState.loadTiles)
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'my.pemantautanah.pemantau_tanah_demo',
        maxNativeZoom: 19,
      ),
  ];
}

const mapAttribution = SimpleAttributionWidget(
  source: Text('OpenStreetMap contributors'),
);

/// Blue dot plus a circle whose radius is the reported GPS error in meters.
List<Widget> userLocationLayers(LocationFix? fix) {
  if (fix == null) return const [];
  return [
    CircleLayer(
      circles: [
        CircleMarker(
          point: fix.point,
          radius: fix.accuracyM,
          useRadiusInMeter: true,
          color: AppColors.blue.withValues(alpha: 0.18),
          borderColor: AppColors.blue.withValues(alpha: 0.5),
          borderStrokeWidth: 1,
        ),
      ],
    ),
    MarkerLayer(
      markers: [
        Marker(
          point: fix.point,
          width: 18,
          height: 18,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    ),
  ];
}

class MapNote extends StatelessWidget {
  const MapNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        boundaryNote,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: Color(0xFF3C4742)),
      ),
    );
  }
}

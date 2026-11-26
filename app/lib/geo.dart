import 'dart:math';

import 'package:latlong2/latlong.dart';

const double _metersPerDegree = 111320.0;

/// Moves [origin] by a distance in meters (flat-earth approximation, fine for
/// lot-sized distances).
LatLng offsetMeters(LatLng origin, double eastM, double northM) {
  final lat = origin.latitude + northM / _metersPerDegree;
  final lng = origin.longitude +
      eastM / (_metersPerDegree * cos(origin.latitude * pi / 180));
  return LatLng(lat, lng);
}

/// Position of [p] in meters east/north of [origin].
Point<double> toLocalMeters(LatLng origin, LatLng p) {
  return Point(
    (p.longitude - origin.longitude) *
        _metersPerDegree *
        cos(origin.latitude * pi / 180),
    (p.latitude - origin.latitude) * _metersPerDegree,
  );
}

double distanceMeters(LatLng a, LatLng b) {
  final d = toLocalMeters(a, b);
  return sqrt(d.x * d.x + d.y * d.y);
}

LatLng centroidOf(List<LatLng> points) {
  var lat = 0.0;
  var lng = 0.0;
  for (final p in points) {
    lat += p.latitude;
    lng += p.longitude;
  }
  return LatLng(lat / points.length, lng / points.length);
}

bool pointInPolygon(LatLng p, List<LatLng> polygon) {
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final a = polygon[i];
    final b = polygon[j];
    final crosses = (a.latitude > p.latitude) != (b.latitude > p.latitude) &&
        p.longitude <
            (b.longitude - a.longitude) *
                    (p.latitude - a.latitude) /
                    (b.latitude - a.latitude) +
                a.longitude;
    if (crosses) inside = !inside;
  }
  return inside;
}

/// Zero when [p] is inside the polygon, otherwise the distance in meters to
/// the nearest edge. Used for the geofence check: inside boundary + buffer.
double distanceToPolygonMeters(LatLng p, List<LatLng> polygon) {
  if (pointInPolygon(p, polygon)) return 0;
  var best = double.infinity;
  for (var i = 0; i < polygon.length; i++) {
    final a = toLocalMeters(p, polygon[i]);
    final b = toLocalMeters(p, polygon[(i + 1) % polygon.length]);
    best = min(best, _originToSegment(a, b));
  }
  return best;
}

double _originToSegment(Point<double> a, Point<double> b) {
  final dx = b.x - a.x;
  final dy = b.y - a.y;
  final len2 = dx * dx + dy * dy;
  final t = len2 == 0
      ? 0.0
      : (-(a.x * dx + a.y * dy) / len2).clamp(0.0, 1.0).toDouble();
  final cx = a.x + t * dx;
  final cy = a.y + t * dy;
  return sqrt(cx * cx + cy * cy);
}

/// Display-only outline of the buffer zone: every vertex pushed away from the
/// centroid. The geofence decision itself uses [distanceToPolygonMeters].
List<LatLng> bufferPolygon(List<LatLng> polygon, double meters) {
  final c = centroidOf(polygon);
  return [
    for (final v in polygon) _pushOut(c, v, meters * 1.35),
  ];
}

LatLng _pushOut(LatLng center, LatLng vertex, double meters) {
  final d = toLocalMeters(center, vertex);
  final len = sqrt(d.x * d.x + d.y * d.y);
  if (len == 0) return vertex;
  final k = (len + meters) / len;
  return offsetMeters(center, d.x * k, d.y * k);
}

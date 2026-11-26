import 'package:latlong2/latlong.dart';

enum Role { fieldOfficer, supervisor }

enum LotStatus { current, due, alert, unverified }

enum WorkStatus { todo, alertSent, done }

enum AlertState { open, acknowledged, falseAlarm }

class BoundaryStone {
  const BoundaryStone(this.label, this.point);

  final String label;
  final LatLng point;
}

class PhotoPost {
  const PhotoPost(this.seq, this.point);

  final int seq;
  final LatLng point;
}

class Lot {
  Lot({
    required this.id,
    required this.name,
    required this.lotNo,
    required this.mukim,
    required this.areaHa,
    required this.landType,
    required this.boundarySource,
    required this.officer,
    required this.supervisor,
    required this.boundary,
    required this.stones,
    required this.posts,
    required this.status,
    required this.verifiedOnSite,
    this.bufferM = 15,
    this.lastVisit,
    this.lastVisitResult,
  });

  final String id;
  final String name;
  final String lotNo;
  final String mukim;
  final double areaHa;
  final String landType;
  final String boundarySource;
  final String officer;
  final String supervisor;

  /// Approximate boundary. Never a legal reference (CLAUDE.md rule 3).
  final List<LatLng> boundary;
  final List<BoundaryStone> stones;
  final List<PhotoPost> posts;
  final double bufferM;

  LotStatus status;
  bool verifiedOnSite;
  DateTime? lastVisit;
  String? lastVisitResult;
}

class WorkItem {
  WorkItem({
    required this.id,
    required this.lotId,
    required this.type,
    required this.due,
    this.status = WorkStatus.todo,
    this.doneAt,
  });

  final String id;
  final String lotId;
  final String type;
  final DateTime due;
  WorkStatus status;
  DateTime? doneAt;
}

/// Evidence stored with every photo (CLAUDE.md rule 2).
class PhotoRecord {
  const PhotoRecord({
    required this.lotId,
    required this.postSeq,
    required this.path,
    required this.takenAt,
    required this.sha256,
    this.lat,
    this.lng,
    this.accuracyM,
    this.headingDeg,
    this.fallback = false,
    this.mockLocation = false,
    this.simulated = false,
  });

  final String lotId;
  final int postSeq;

  /// Empty when the camera was unavailable and a placeholder was recorded.
  final String path;
  final DateTime takenAt;
  final String sha256;
  final double? lat;
  final double? lng;
  final double? accuracyM;
  final double? headingDeg;

  /// Pole missing: photo taken at the pin coordinate instead.
  final bool fallback;
  final bool mockLocation;
  final bool simulated;
}

class AlertItem {
  AlertItem({
    required this.id,
    required this.lotId,
    required this.source,
    required this.categories,
    required this.note,
    required this.createdAt,
    required this.reportedBy,
    this.photos = const [],
    this.state = AlertState.open,
    this.decidedAt,
  });

  final String id;
  final String lotId;
  final String source;
  final List<String> categories;
  final String note;
  final DateTime createdAt;

  /// Shown to supervisor and admin only (CLAUDE.md rule 7).
  final String reportedBy;
  final List<PhotoRecord> photos;
  AlertState state;
  DateTime? decidedAt;
}

class LocationFix {
  const LocationFix({
    required this.point,
    required this.accuracyM,
    required this.at,
    this.headingDeg,
    this.mocked = false,
    this.simulated = false,
  });

  final LatLng point;
  final double accuracyM;
  final DateTime at;
  final double? headingDeg;

  /// Reported by the OS as coming from a mock-location provider.
  final bool mocked;

  /// Demo switch "simulate being at the lot" is on.
  final bool simulated;
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'demo_data.dart';
import 'geo.dart';
import 'models.dart';

/// Where the phone is. Abstract so tests can run without the GPS plugin.
abstract class LocationSource {
  Future<LocationFix?> current();
  Stream<LocationFix> watch();
}

class DeviceLocationSource implements LocationSource {
  Future<bool> _allowed() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  LocationFix _fix(Position p) => LocationFix(
        point: LatLng(p.latitude, p.longitude),
        accuracyM: p.accuracy,
        at: p.timestamp,
        headingDeg: p.heading > 0 ? p.heading : null,
        mocked: p.isMocked,
      );

  @override
  Future<LocationFix?> current() async {
    if (!await _allowed()) return null;
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return _fix(p);
    } catch (_) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        return last == null ? null : _fix(last);
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Stream<LocationFix> watch() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).map(_fix).handleError((Object _) {});
  }
}

/// All demo state, held in memory. Nothing is persisted and nothing is sent
/// to a server: closing the app resets it.
class AppState extends ChangeNotifier {
  /// Used when the phone gives no position (Shah Alam town centre).
  static const fallbackCenter = LatLng(3.0733, 101.5185);

  bool ready = false;
  bool loadTiles = true;
  bool usingRealLocation = false;
  Role role = Role.fieldOfficer;
  LatLng center = fallbackCenter;

  List<Lot> lots = [];
  List<WorkItem> work = [];
  List<AlertItem> alerts = [];

  LocationFix? _deviceFix;

  /// Demo switch: pretend the phone is standing inside the selected lot.
  bool simulateAtLot = false;

  final Map<String, DateTime> _checkIns = {};
  final Map<String, Map<int, PhotoRecord>> _visitPhotos = {};
  StreamSubscription<LocationFix>? _watch;

  Future<void> init({LocationSource? source, bool loadTiles = true}) async {
    this.loadTiles = loadTiles;
    final location = source ?? DeviceLocationSource();
    final first = await location.current();
    if (first != null) {
      _deviceFix = first;
      center = first.point;
      usingRealLocation = true;
    } else {
      simulateAtLot = true;
    }
    final data = buildDemoData(center, DateTime.now());
    lots = data.lots;
    work = data.work;
    alerts = data.alerts;
    ready = true;
    notifyListeners();
    if (usingRealLocation) {
      _watch = location.watch().listen((fix) {
        _deviceFix = fix;
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _watch?.cancel();
    super.dispose();
  }

  Lot lotById(String id) => lots.firstWhere((l) => l.id == id);

  LocationFix? get deviceFix => _deviceFix;

  /// Position used for a lot: the real GPS fix, or a simulated one inside the
  /// lot when the demo switch is on.
  LocationFix? fixFor(Lot lot) {
    if (simulateAtLot) {
      final c = centroidOf(lot.boundary);
      return LocationFix(
        point: offsetMeters(c, 6, -5),
        accuracyM: 4,
        at: DateTime.now(),
        simulated: true,
      );
    }
    return _deviceFix;
  }

  double distanceToLot(Lot lot, LocationFix fix) =>
      distanceToPolygonMeters(fix.point, lot.boundary);

  /// Geofence rule: inside the approximate boundary plus the lot's buffer.
  bool withinGeofence(Lot lot, LocationFix fix) =>
      distanceToLot(lot, fix) <= lot.bufferM;

  void setRole(Role value) {
    role = value;
    notifyListeners();
  }

  void setSimulate(bool value) {
    simulateAtLot = value;
    notifyListeners();
  }

  DateTime? checkInOf(Lot lot) => _checkIns[lot.id];

  void checkIn(Lot lot) {
    _checkIns[lot.id] = DateTime.now();
    notifyListeners();
  }

  Map<int, PhotoRecord> photosOf(Lot lot) => _visitPhotos[lot.id] ?? const {};

  void addPhoto(PhotoRecord photo) {
    _visitPhotos.putIfAbsent(photo.lotId, () => {})[photo.postSeq] = photo;
    notifyListeners();
  }

  /// A visit can only be completed once every post has a photo.
  bool allPostsDone(Lot lot) =>
      lot.posts.isNotEmpty && photosOf(lot).length >= lot.posts.length;

  WorkItem? openWorkFor(Lot lot) {
    for (final w in work) {
      if (w.lotId == lot.id && w.status == WorkStatus.todo) return w;
    }
    return null;
  }

  /// Finishes a visit or files a direct report. A reported change raises an
  /// alert for the supervisor; the system's scope ends once it is acknowledged.
  void submitReport(
    Lot lot, {
    required bool noChange,
    List<String> categories = const [],
    String note = '',
    bool direct = false,
  }) {
    final now = DateTime.now();
    final photos = photosOf(lot).values.toList()
      ..sort((a, b) => a.postSeq.compareTo(b.postSeq));
    if (!direct) {
      final item = openWorkFor(lot);
      if (item != null) {
        item.status = noChange ? WorkStatus.done : WorkStatus.alertSent;
        item.doneAt = now;
      }
      lot.lastVisit = now;
      lot.lastVisitResult =
          noChange ? 'Tiada perubahan' : 'Perubahan dilaporkan';
    }
    final poleMissing = photos.any((p) => p.fallback);
    if (!noChange || poleMissing) {
      alerts.insert(
        0,
        AlertItem(
          id: 'a${alerts.length + 1}-${now.millisecondsSinceEpoch}',
          lotId: lot.id,
          source: noChange ? 'Tiang hilang' : 'Laporan pegawai',
          categories: noChange ? const ['Tiang hilang'] : categories,
          note: note,
          createdAt: now,
          reportedBy: demoOfficer,
          photos: photos,
        ),
      );
      lot.status = LotStatus.alert;
    } else if (!direct) {
      lot.status = LotStatus.current;
    }
    if (!direct) {
      _visitPhotos.remove(lot.id);
      _checkIns.remove(lot.id);
    }
    notifyListeners();
  }

  void decideAlert(AlertItem alert, AlertState decision) {
    alert.state = decision;
    alert.decidedAt = DateTime.now();
    final lot = lotById(alert.lotId);
    final stillOpen =
        alerts.any((a) => a.lotId == lot.id && a.state == AlertState.open);
    if (!stillOpen && lot.status == LotStatus.alert) {
      lot.status = LotStatus.current;
    }
    for (final w in work) {
      if (w.lotId == lot.id && w.status == WorkStatus.alertSent && !stillOpen) {
        w.status = WorkStatus.done;
      }
    }
    notifyListeners();
  }

  /// Whole days past the target date. Zero or negative means not late.
  static int daysLate(DateTime due, DateTime at) {
    final d0 = DateTime(due.year, due.month, due.day);
    final d1 = DateTime(at.year, at.month, at.day);
    return d1.difference(d0).inDays;
  }

  /// SPEC 6.1: early or up to 3 days late counts as on time. No marks.
  static bool isOnTime(WorkItem w) =>
      w.doneAt != null && daysLate(w.due, w.doneAt!) <= 3;

  List<WorkItem> get finishedWork =>
      work.where((w) => w.doneAt != null).toList();

  int get onTimeCount => finishedWork.where(isOnTime).length;

  /// Overdue first, then upcoming by date, then waiting, then finished.
  List<WorkItem> get sortedWork {
    final now = DateTime.now();
    int rank(WorkItem w) {
      if (w.status == WorkStatus.todo) return daysLate(w.due, now) > 0 ? 0 : 1;
      return w.status == WorkStatus.alertSent ? 2 : 3;
    }

    return [...work]..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.due.compareTo(b.due);
      });
  }
}

final appState = AppState();

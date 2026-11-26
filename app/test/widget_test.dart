import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:pemantau_tanah_demo/app_state.dart';
import 'package:pemantau_tanah_demo/geo.dart';
import 'package:pemantau_tanah_demo/main.dart';
import 'package:pemantau_tanah_demo/models.dart';

class FakeLocation implements LocationSource {
  FakeLocation(this.fix);

  final LocationFix? fix;

  @override
  Future<LocationFix?> current() async => fix;

  @override
  Stream<LocationFix> watch() => const Stream.empty();
}

void main() {
  const origin = LatLng(3.0733, 101.5185);
  final square = [
    offsetMeters(origin, -50, 50),
    offsetMeters(origin, 50, 50),
    offsetMeters(origin, 50, -50),
    offsetMeters(origin, -50, -50),
  ];

  group('geofence geometry', () {
    test('a point inside the lot is zero meters away', () {
      expect(pointInPolygon(origin, square), isTrue);
      expect(distanceToPolygonMeters(origin, square), 0);
    });

    test('a point 10 m outside an edge measures about 10 m', () {
      final p = offsetMeters(origin, 60, 0);
      expect(pointInPolygon(p, square), isFalse);
      expect(distanceToPolygonMeters(p, square), closeTo(10, 0.5));
    });

    test('a point diagonal to a corner measures to the corner', () {
      final p = offsetMeters(origin, 80, 90);
      expect(distanceToPolygonMeters(p, square), closeTo(50, 0.5));
    });
  });

  group('business rules', () {
    test('on time means early or up to 3 days late', () {
      final due = DateTime(2026, 11, 10);
      WorkItem done(int lateDays) => WorkItem(
            id: 'x',
            lotId: 'lot-01',
            type: 't',
            due: due,
            doneAt: due.add(Duration(days: lateDays)),
          );
      expect(AppState.isOnTime(done(-2)), isTrue);
      expect(AppState.isOnTime(done(3)), isTrue);
      expect(AppState.isOnTime(done(4)), isFalse);
    });

    test('check-in is allowed inside boundary plus buffer only', () async {
      final state = AppState();
      await state.init(
        source: FakeLocation(LocationFix(
            point: origin, accuracyM: 4, at: DateTime(2026, 11, 26))),
        loadTiles: false,
      );
      final lot = state.lotById('lot-01');
      LocationFix at(double east) => LocationFix(
          point: offsetMeters(origin, east, 0),
          accuracyM: 4,
          at: DateTime(2026, 11, 26));
      expect(state.withinGeofence(lot, at(0)), isTrue);
      expect(state.withinGeofence(lot, at(55)), isTrue);
      expect(state.withinGeofence(lot, at(90)), isFalse);
    });

    test('a reported change raises an alert and marks the lot', () async {
      final state = AppState();
      await state.init(source: FakeLocation(null), loadTiles: false);
      final lot = state.lotById('lot-01');
      final before = state.alerts.length;
      state.submitReport(lot, noChange: false, categories: ['Pagar']);
      expect(state.alerts.length, before + 1);
      expect(lot.status, LotStatus.alert);
      state.decideAlert(state.alerts.first, AlertState.acknowledged);
      expect(lot.status, LotStatus.current);
    });

    test('an acknowledged alert opens a case that is tracked to closure',
        () async {
      final state = AppState();
      await state.init(source: FakeLocation(null), loadTiles: false);
      final lot = state.lotById('lot-01');
      state.submitReport(lot, noChange: false, categories: ['Pondok']);
      final alert = state.alerts.first;
      final before = state.cases.length;
      state.decideAlert(alert, AlertState.acknowledged);
      expect(state.cases.length, before + 1);
      final c = state.caseForAlert(alert)!;
      expect(c.stage, CaseStage.confirmed);
      expect(lot.risk, RiskLevel.high);
      for (var i = 0; i < 5; i++) {
        state.advanceCase(c);
      }
      expect(c.stage, CaseStage.closed);
      expect(c.closedAt, isNotNull);
      expect(c.events.length, 7);
    });

    test('a false alarm opens no case', () async {
      final state = AppState();
      await state.init(source: FakeLocation(null), loadTiles: false);
      final lot = state.lotById('lot-01');
      state.submitReport(lot, noChange: false, categories: ['Pagar']);
      final before = state.cases.length;
      state.decideAlert(state.alerts.first, AlertState.falseAlarm);
      expect(state.cases.length, before);
    });

    test('no change completes the work without an alert', () async {
      final state = AppState();
      await state.init(source: FakeLocation(null), loadTiles: false);
      final lot = state.lotById('lot-01');
      final before = state.alerts.length;
      state.submitReport(lot, noChange: true);
      expect(state.alerts.length, before);
      expect(lot.status, LotStatus.current);
      expect(state.openWorkFor(lot), isNull);
    });
  });

  testWidgets('app opens on the district map with sample lots', (tester) async {
    await appState.init(source: FakeLocation(null), loadTiles: false);
    await tester.pumpWidget(const DemoApp(initialize: false));
    await tester.pump();
    expect(find.text('Peta daerah'), findsOneWidget);
    expect(find.textContaining('lot didigitalkan'), findsOneWidget);
    expect(find.text('Lihat butiran lot'), findsOneWidget);

    await tester.tap(find.text('Kerja'));
    await tester.pump();
    expect(find.text('Kerja saya'), findsOneWidget);
    expect(find.textContaining('Peringatan:'), findsOneWidget);

    await tester.tap(find.text('Kes'));
    await tester.pump();
    expect(find.text('Kes pencerobohan'), findsOneWidget);
    expect(find.textContaining('K-2026-031'), findsOneWidget);
  });
}

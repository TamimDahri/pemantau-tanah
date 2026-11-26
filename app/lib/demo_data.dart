import 'dart:math';

import 'package:latlong2/latlong.dart';

import 'geo.dart';
import 'models.dart';

/// Mock data only. There is no database in this demo build: everything here
/// lives in memory and is rebuilt on every launch.
class DemoData {
  const DemoData(this.lots, this.work, this.alerts, this.cases);

  final List<Lot> lots;
  final List<WorkItem> work;
  final List<AlertItem> alerts;
  final List<EncroachmentCase> cases;
}

const demoOfficer = 'Pegawai Contoh';
const demoSupervisor = 'Penyelia Contoh';

/// Builds sample lots around [center]. Lot 01 sits on [center] itself, so when
/// [center] is the phone's real position the geofence check passes on site.
DemoData buildDemoData(LatLng center, DateTime now) {
  var n = 0;

  Lot lot(
    double east,
    double north,
    double w,
    double h,
    double rotationDeg, {
    required String landType,
    required String mukim,
    required LotStatus status,
    required Agency agency,
    required RiskLevel risk,
    int posts = 3,
    DateTime? lastVisit,
    String? lastVisitResult,
  }) {
    n++;
    final c = offsetMeters(center, east, north);
    final r = rotationDeg * pi / 180;
    LatLng at(double x, double y) =>
        offsetMeters(c, x * cos(r) - y * sin(r), x * sin(r) + y * cos(r));
    final boundary = [
      at(-w / 2, h / 2),
      at(w / 2, h / 2),
      at(w / 2, -h / 2),
      at(-w / 2, -h / 2),
    ];
    const spots = [
      [-0.25, 0.2],
      [0.25, 0.22],
      [0.05, -0.22],
      [-0.28, -0.2],
    ];
    final id = n.toString().padLeft(2, '0');
    return Lot(
      id: 'lot-$id',
      name: 'Lot Contoh $id',
      lotNo: 'Contoh ${1000 + n}',
      mukim: mukim,
      areaHa: w * h / 10000,
      landType: landType,
      boundarySource: 'Pelan ukur (contoh)',
      officer: demoOfficer,
      supervisor: demoSupervisor,
      boundary: boundary,
      stones: [
        for (var i = 0; i < boundary.length; i++)
          BoundaryStone('BS${i + 1}', boundary[i]),
      ],
      posts: [
        for (var i = 0; i < posts; i++)
          PhotoPost(i + 1, at(spots[i][0] * w, spots[i][1] * h)),
      ],
      status: status,
      agency: agency,
      risk: risk,
      verifiedOnSite: status != LotStatus.unverified,
      lastVisit: lastVisit,
      lastVisitResult: lastVisitResult,
    );
  }

  DateTime days(int d) => now.add(Duration(days: d));

  final lots = [
    lot(0, 0, 90, 70, 8,
        landType: 'Tapak surau (warta s.62)',
        agency: Agency.jais,
        risk: RiskLevel.medium,
        mukim: 'Mukim Contoh A',
        status: LotStatus.due,
        lastVisit: days(-33),
        lastVisitResult: 'Tiada perubahan'),
    lot(-420, 260, 120, 90, -12,
        landType: 'Tanah wakaf khas',
        agency: Agency.pws,
        risk: RiskLevel.high,
        mukim: 'Mukim Contoh A',
        status: LotStatus.alert,
        posts: 4,
        lastVisit: days(-1),
        lastVisitResult: 'Perubahan dilaporkan'),
    lot(380, 330, 100, 80, 20,
        landType: 'Tanah perkuburan (warta s.62)',
        agency: Agency.jais,
        risk: RiskLevel.low,
        mukim: 'Mukim Contoh A',
        status: LotStatus.current,
        posts: 2,
        lastVisit: days(-12),
        lastVisitResult: 'Tiada perubahan'),
    lot(520, -180, 110, 80, 5,
        landType: 'Tapak masjid (wakaf irsod)',
        agency: Agency.mais,
        risk: RiskLevel.medium,
        mukim: 'Mukim Contoh B',
        status: LotStatus.due,
        posts: 2,
        lastVisit: days(-28),
        lastVisitResult: 'Tiada perubahan'),
    lot(-300, -350, 130, 100, 30,
        landType: 'Tanah wakaf khas',
        agency: Agency.pws,
        risk: RiskLevel.medium,
        mukim: 'Mukim Contoh B',
        status: LotStatus.current,
        lastVisit: days(-9),
        lastVisitResult: 'Tiada perubahan'),
    lot(140, -520, 90, 90, -5,
        landType: 'Tapak surau (wakaf irsod)',
        agency: Agency.mais,
        risk: RiskLevel.high,
        mukim: 'Mukim Contoh B',
        status: LotStatus.unverified,
        posts: 0),
    lot(-640, -60, 100, 70, 15,
        landType: 'Tanah wakaf khas',
        agency: Agency.pws,
        risk: RiskLevel.low,
        mukim: 'Mukim Contoh A',
        status: LotStatus.current,
        lastVisit: days(-20),
        lastVisitResult: 'Tiada perubahan'),
    lot(720, 420, 120, 80, -20,
        landType: 'Tanah perkuburan (warta s.62)',
        agency: Agency.jais,
        risk: RiskLevel.high,
        mukim: 'Mukim Contoh A',
        status: LotStatus.unverified,
        posts: 0),
    lot(-120, 560, 100, 100, 0,
        landType: 'Tapak masjid (warta s.62)',
        agency: Agency.jais,
        risk: RiskLevel.low,
        mukim: 'Mukim Contoh A',
        status: LotStatus.current,
        posts: 2,
        lastVisit: days(-5),
        lastVisitResult: 'Tiada perubahan'),
    lot(300, -330, 80, 110, 12,
        landType: 'Tanah wakaf khas',
        agency: Agency.pws,
        risk: RiskLevel.high,
        mukim: 'Mukim Contoh B',
        status: LotStatus.due,
        posts: 2,
        lastVisit: days(-25),
        lastVisitResult: 'Tiada perubahan'),
  ];

  final work = [
    WorkItem(
        id: 'w1',
        lotId: 'lot-01',
        type: 'Lawatan pemantauan',
        due: days(-3)),
    WorkItem(
        id: 'w2', lotId: 'lot-04', type: 'Kerja pembangunan', due: days(2)),
    WorkItem(
        id: 'w3',
        lotId: 'lot-10',
        type: 'Lawatan pemantauan',
        due: days(5)),
    WorkItem(
        id: 'w4',
        lotId: 'lot-02',
        type: 'Lawatan pemantauan',
        due: days(-2),
        status: WorkStatus.alertSent,
        doneAt: days(-1)),
    WorkItem(
        id: 'w5',
        lotId: 'lot-03',
        type: 'Lawatan pemantauan',
        due: days(-13),
        status: WorkStatus.done,
        doneAt: days(-12)),
    WorkItem(
        id: 'w6',
        lotId: 'lot-05',
        type: 'Lawatan pemantauan',
        due: days(-9),
        status: WorkStatus.done,
        doneAt: days(-9)),
    WorkItem(
        id: 'w7',
        lotId: 'lot-09',
        type: 'Lawatan pemantauan',
        due: days(-6),
        status: WorkStatus.done,
        doneAt: days(-5)),
  ];

  final alerts = [
    AlertItem(
      id: 'a1',
      lotId: 'lot-02',
      source: 'Laporan pegawai',
      categories: const ['Pagar'],
      note: 'Pagar baharu di sebelah timur (contoh).',
      createdAt: days(-1),
      reportedBy: demoOfficer,
    ),
  ];

  final cases = [
    EncroachmentCase(
      id: 'K-2026-031',
      lotId: 'lot-10',
      openedAt: days(-132),
      summary: 'Struktur sementara di bahagian timur lot (contoh).',
      stage: CaseStage.pdtAction,
      pdtRef: 'PDT/ADU/[No. rujukan]',
      events: [
        CaseEvent(days(-132), demoOfficer, 'Laporan perubahan',
            'Dikesan semasa lawatan bulanan. 6 gambar berlokasi.'),
        CaseEvent(days(-131), demoSupervisor, 'Pencerobohan disahkan',
            'Gambar dibandingkan dengan gambar asas.'),
        CaseEvent(days(-128), demoSupervisor, 'Pek aduan dijana'),
        CaseEvent(days(-128), demoSupervisor, 'Aduan dihantar ke PDT',
            'Salinan kepada unit pembangunan agensi.'),
        CaseEvent(days(-41), demoSupervisor, 'Tindakan PDT direkod',
            'Notis dikeluarkan kepada penghuni. Tempoh notis 30 hari.'),
      ],
    ),
    EncroachmentCase(
      id: 'K-2026-019',
      lotId: 'lot-05',
      openedAt: days(-210),
      summary: 'Longgokan bahan binaan di sudut barat daya (contoh).',
      stage: CaseStage.closed,
      closedAt: days(-150),
      events: [
        CaseEvent(days(-210), demoOfficer, 'Laporan perubahan'),
        CaseEvent(days(-209), demoSupervisor, 'Pencerobohan disahkan'),
        CaseEvent(days(-207), demoSupervisor, 'Aduan dihantar ke PDT'),
        CaseEvent(days(-160), demoSupervisor, 'Tindakan PDT direkod',
            'Bahan dialihkan oleh pemilik.'),
        CaseEvent(days(-150), demoOfficer,
            'Tapak disahkan bersih, kes ditutup'),
      ],
    ),
  ];

  return DemoData(lots, work, alerts, cases);
}

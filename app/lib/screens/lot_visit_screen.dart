import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../app_state.dart';
import '../geo.dart';
import '../map_common.dart';
import '../models.dart';
import '../theme.dart';
import 'capture_screen.dart';
import 'review_submit_screen.dart';

/// Phase 2 screen: lot map with geofence check-in, then a photo at each post.
class LotVisitScreen extends StatelessWidget {
  const LotVisitScreen({super.key, required this.lot});

  final Lot lot;

  Future<void> _capture(BuildContext context, PhotoPost post,
      {required bool fallback}) async {
    final photo = await Navigator.of(context).push<PhotoRecord>(
      MaterialPageRoute(
        builder: (_) => CaptureScreen(lot: lot, post: post, fallback: fallback),
      ),
    );
    if (photo != null) appState.addPhoto(photo);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final fix = appState.fixFor(lot);
        final inside = fix != null && appState.withinGeofence(lot, fix);
        final checkedIn = appState.checkInOf(lot);
        final photos = appState.photosOf(lot);
        final buffer = bufferPolygon(lot.boundary, lot.bufferM);
        return Scaffold(
          appBar: AppBar(title: Text(lot.name)),
          body: Column(
            children: [
              SizedBox(
                height: 300,
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCameraFit: CameraFit.bounds(
                          bounds: LatLngBounds.fromPoints(buffer),
                          padding: const EdgeInsets.all(28),
                        ),
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        ...baseMapLayers(),
                        PolygonLayer(
                          polygons: [
                            Polygon(
                              points: buffer,
                              color: AppColors.green.withValues(alpha: 0.16),
                              borderColor:
                                  AppColors.green.withValues(alpha: 0.5),
                              borderStrokeWidth: 1,
                            ),
                            Polygon(
                              points: lot.boundary,
                              color: Colors.white.withValues(alpha: 0.25),
                              borderColor: AppColors.green,
                              borderStrokeWidth: 2.5,
                              pattern:
                                  StrokePattern.dashed(segments: const [8, 6]),
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            for (final s in lot.stones)
                              Marker(
                                point: s.point,
                                width: 14,
                                height: 14,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.text,
                                    border: Border.all(
                                        color: Colors.white, width: 1.5),
                                  ),
                                ),
                              ),
                            for (final p in lot.posts)
                              Marker(
                                point: p.point,
                                width: 28,
                                height: 28,
                                child: _PostPin(
                                    seq: p.seq,
                                    done: photos.containsKey(p.seq)),
                              ),
                          ],
                        ),
                        ...userLocationLayers(fix),
                        mapAttribution,
                      ],
                    ),
                    Positioned(
                        left: 10, top: 10, child: _AccuracyPill(fix: fix)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                    if (fix != null && fix.mocked) ...[
                      const Banner2(
                        icon: Icons.warning_amber_rounded,
                        fg: AppColors.criticalDark,
                        bg: AppColors.criticalSoft,
                        text:
                            'Lokasi palsu dikesan. Lawatan ini ditanda mencurigakan.',
                      ),
                      const SizedBox(height: 8),
                    ],
                    _GeofenceBanner(
                        lot: lot,
                        fix: fix,
                        inside: inside,
                        checkedIn: checkedIn),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('Simulasi berada di lot (demo)'),
                      subtitle: const Text(
                          'Hidupkan jika anda tidak berada di lot contoh.'),
                      value: appState.simulateAtLot,
                      onChanged: appState.setSimulate,
                    ),
                    const Text(boundaryNote,
                        style:
                            TextStyle(fontSize: 12, color: AppColors.muted)),
                    const SizedBox(height: 12),
                    if (lot.posts.isEmpty)
                      const SectionCard(
                        child: Text(
                          'Lot ini belum disahkan di tapak, jadi belum ada pos gambar. '
                          'Dalam aplikasi sebenar, pegawai merekod batu sempadan dan '
                          'menetapkan pos di sini.',
                          style: TextStyle(fontSize: 13),
                        ),
                      )
                    else if (checkedIn == null)
                      FilledButton(
                        onPressed: inside ? () => appState.checkIn(lot) : null,
                        child: const Text('Check-in di lot'),
                      )
                    else ...[
                      for (final post in lot.posts)
                        _PostRow(
                          post: post,
                          photo: photos[post.seq],
                          onCapture: () =>
                              _capture(context, post, fallback: false),
                          onMissing: () =>
                              _capture(context, post, fallback: true),
                        ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: appState.allPostsDone(lot)
                            ? () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ReviewSubmitScreen(lot: lot),
                                  ),
                                )
                            : null,
                        child: Text(
                          appState.allPostsDone(lot)
                              ? 'Semak dan hantar'
                              : 'Ambil gambar di semua pos dahulu '
                                  '(${photos.length}/${lot.posts.length})',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PostPin extends StatelessWidget {
  const _PostPin({required this.seq, required this.done});

  final int seq;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: done ? AppColors.green : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
            color: done ? Colors.white : AppColors.amber, width: 3),
      ),
      child: Text(
        '$seq',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: done ? Colors.white : AppColors.amberDark,
        ),
      ),
    );
  }
}

class _AccuracyPill extends StatelessWidget {
  const _AccuracyPill({required this.fix});

  final LocationFix? fix;

  @override
  Widget build(BuildContext context) {
    final f = fix;
    // SPEC 4.4: green under 5 m, amber 5 to 10 m, red above 10 m.
    final color = f == null
        ? AppColors.muted
        : f.accuracyM < 5
            ? AppColors.green
            : f.accuracyM <= 10
                ? AppColors.amber
                : AppColors.critical;
    final text = f == null
        ? 'Tiada lokasi GPS'
        : 'Ketepatan GPS: ±${f.accuracyM.round()} m'
            '${f.simulated ? ' (simulasi)' : ''}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _GeofenceBanner extends StatelessWidget {
  const _GeofenceBanner({
    required this.lot,
    required this.fix,
    required this.inside,
    required this.checkedIn,
  });

  final Lot lot;
  final LocationFix? fix;
  final bool inside;
  final DateTime? checkedIn;

  @override
  Widget build(BuildContext context) {
    final f = fix;
    if (checkedIn != null) {
      return Banner2(
        icon: Icons.check_circle_outline,
        fg: AppColors.greenDark,
        bg: AppColors.greenSoft,
        text: 'Kehadiran direkod ${formatTime(checkedIn!)}.',
      );
    }
    if (f == null) {
      return const Banner2(
        icon: Icons.location_off_outlined,
        fg: AppColors.amberDark,
        bg: AppColors.amberSoft,
        text: 'Lokasi GPS tidak diperoleh. Benarkan akses lokasi, atau guna '
            'simulasi di bawah.',
      );
    }
    if (inside) {
      return const Banner2(
        icon: Icons.check_circle_outline,
        fg: AppColors.greenDark,
        bg: AppColors.greenSoft,
        text: 'Anda berada dalam kawasan lot. Check-in dibenarkan.',
      );
    }
    final away = appState.distanceToLot(lot, f).round();
    return Banner2(
      icon: Icons.info_outline,
      fg: AppColors.amberDark,
      bg: AppColors.amberSoft,
      text: 'Anda $away m di luar kawasan lot (penimbal '
          '${lot.bufferM.round()} m). Check-in belum dibenarkan.',
    );
  }
}

class _PostRow extends StatelessWidget {
  const _PostRow({
    required this.post,
    required this.photo,
    required this.onCapture,
    required this.onMissing,
  });

  final PhotoPost post;
  final PhotoRecord? photo;
  final VoidCallback onCapture;
  final VoidCallback onMissing;

  @override
  Widget build(BuildContext context) {
    final p = photo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Pos ${post.seq}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                if (p != null)
                  Pill(
                    p.fallback ? 'Bergambar (tiang hilang)' : 'Bergambar',
                    fg: p.fallback
                        ? AppColors.amberDark
                        : AppColors.greenDark,
                    bg: p.fallback
                        ? AppColors.amberSoft
                        : AppColors.greenSoft,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (p != null)
              Text(
                '${formatTime(p.takenAt)} · GPS '
                '${p.accuracyM == null ? 'tiada' : '±${p.accuracyM!.round()} m'}'
                ' · hash ${p.sha256.substring(0, 10)}…',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: onCapture,
                      child: const Text('Imbas tiang dan ambil gambar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onMissing,
                    child: const Text('Tiang hilang'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

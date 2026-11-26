import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import 'lot_visit_screen.dart';
import 'review_submit_screen.dart';

/// Phase 1 screen: the digitised record of one lot.
class LotDetailScreen extends StatelessWidget {
  const LotDetailScreen({super.key, required this.lot});

  final Lot lot;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final openWork = appState.openWorkFor(lot);
        final late = openWork == null
            ? 0
            : AppState.daysLate(openWork.due, DateTime.now());
        return Scaffold(
          appBar: AppBar(title: Text(lot.name)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Pill(lot.status.label,
                      fg: lot.status.dark, bg: lot.status.soft),
                  if (lot.verifiedOnSite)
                    const Pill('Disahkan di tapak',
                        fg: AppColors.greenDark, bg: AppColors.greenSoft),
                ],
              ),
              const SizedBox(height: 12),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Maklumat lot',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    InfoRow('Nombor lot', lot.lotNo),
                    InfoRow('Mukim', lot.mukim),
                    InfoRow(
                        'Keluasan', '${lot.areaHa.toStringAsFixed(2)} ha'),
                    InfoRow('Jenis tanah', lot.landType),
                    InfoRow('Sumber sempadan', lot.boundarySource),
                    InfoRow('Pegawai kawasan', lot.officer),
                    InfoRow('Penyelia', lot.supervisor),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Tile(
                      lot.verifiedOnSite
                          ? '${lot.stones.length}/${lot.stones.length}'
                          : '0/${lot.stones.length}',
                      'Batu sempadan disahkan',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _Tile('${lot.posts.length}', 'Pos gambar')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Tile(
                      lot.lastVisit == null
                          ? 'Tiada'
                          : formatDate(lot.lastVisit!),
                      'Lawatan terakhir',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kerja',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    if (openWork == null)
                      const InfoRow('Kerja terbuka', 'Tiada')
                    else
                      InfoRow(
                        openWork.type,
                        late > 0
                            ? 'Tertunggak $late hari'
                            : 'Sasaran ${formatDate(openWork.due)}',
                        valueColor: late > 0 ? AppColors.amberDark : null,
                      ),
                    InfoRow('Keputusan terakhir',
                        lot.lastVisitResult ?? 'Belum pernah dilawat'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(boundaryNote,
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ReviewSubmitScreen(lot: lot, direct: true),
                        ),
                      ),
                      child: const Text('Lapor terus'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => LotVisitScreen(lot: lot)),
                      ),
                      child: const Text('Mula lawatan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );
  }
}

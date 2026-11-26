import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import 'cases_screen.dart';
import 'review_submit_screen.dart';

extension AlertStateUi on AlertState {
  String get label => switch (this) {
        AlertState.open => 'Belum diakui',
        AlertState.acknowledged => 'Diakui, kes dibuka',
        AlertState.falseAlarm => 'Amaran palsu',
      };

  Color get fg => switch (this) {
        AlertState.open => AppColors.criticalDark,
        AlertState.acknowledged => AppColors.greenDark,
        AlertState.falseAlarm => const Color(0xFF3C4742),
      };

  Color get bg => switch (this) {
        AlertState.open => AppColors.criticalSoft,
        AlertState.acknowledged => AppColors.greenSoft,
        AlertState.falseAlarm => AppColors.greySoft,
      };
}

/// Alerts raised by reports. The supervisor acknowledges them; the system's
/// scope ends there (CLAUDE.md rule 6).
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final isSupervisor = appState.role == Role.supervisor;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            const Text('Amaran',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            Text(
              isSupervisor
                  ? 'Paparan penyelia: semak dan akui amaran'
                  : 'Paparan pegawai kawasan: status amaran yang dihantar',
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            if (!isSupervisor)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Tukar peranan kepada Penyelia di bar atas untuk mengakui amaran.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            if (appState.alerts.isEmpty)
              const SectionCard(child: Text('Tiada amaran.')),
            for (final a in appState.alerts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => AlertDetailScreen(alert: a)),
                  ),
                  child: SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${appState.lotById(a.lotId).name} · ${a.categories.join(', ')}',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Pill(a.state.label, fg: a.state.fg, bg: a.state.bg),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${a.source} · ${formatDate(a.createdAt)}, ${formatTime(a.createdAt)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key, required this.alert});

  final AlertItem alert;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final lot = appState.lotById(alert.lotId);
        final isSupervisor = appState.role == Role.supervisor;
        final first = alert.photos.isEmpty ? null : alert.photos.first;
        return Scaffold(
          appBar: AppBar(title: const Text('Amaran')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              Banner2(
                icon: Icons.warning_amber_rounded,
                fg: AppColors.criticalDark,
                bg: AppColors.criticalSoft,
                text: '${lot.name} · ${alert.categories.join(', ')}',
              ),
              const SizedBox(height: 10),
              if (alert.photos.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: alert.photos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => PhotoThumb(photo: alert.photos[i]),
                  ),
                )
              else
                const SectionCard(
                  child: Text(
                    'Amaran contoh ini tiada gambar. Buat satu lawatan dan hantar '
                    'laporan untuk melihat gambar sebenar di sini.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              const SizedBox(height: 10),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Laporan pegawai kawasan',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    InfoRow('Sumber', alert.source),
                    InfoRow('Kategori', alert.categories.join(', ')),
                    InfoRow('Catatan',
                        alert.note.isEmpty ? 'Tiada' : alert.note),
                    InfoRow('Diterima',
                        '${formatDate(alert.createdAt)}, ${formatTime(alert.createdAt)}'),
                    if (first != null) ...[
                      InfoRow(
                        'Lokasi gambar',
                        'Pos ${first.postSeq} · GPS '
                            '${first.accuracyM == null ? 'tiada' : '±${first.accuracyM!.round()} m'}'
                            '${first.simulated ? ' (simulasi)' : ''}',
                      ),
                      InfoRow('Bukti',
                          'Kamera aplikasi · hash ${first.sha256.substring(0, 10)}…'),
                      if (alert.photos.any((p) => p.mockLocation))
                        const InfoRow('Semakan', 'Lokasi palsu dikesan',
                            valueColor: AppColors.criticalDark),
                    ],
                    // CLAUDE.md rule 7: only supervisor and admin see who reported.
                    if (isSupervisor)
                      InfoRow('Pegawai kawasan', alert.reportedBy),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Jika tidak diakui dalam tempoh yang ditetapkan agensi, amaran '
                'ini dinaikkan ke peringkat atas. Amaran yang diakui menjadi kes '
                'pencerobohan dan dijejak sehingga ditutup.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              if (alert.state != AlertState.open) ...[
                Banner2(
                  icon: Icons.check_circle_outline,
                  fg: alert.state.fg,
                  bg: alert.state.bg,
                  text: '${alert.state.label} pada '
                      '${formatDate(alert.decidedAt!)}, ${formatTime(alert.decidedAt!)}.',
                ),
                if (appState.caseForAlert(alert) != null) ...[
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CaseDetailScreen(
                            caseItem: appState.caseForAlert(alert)!),
                      ),
                    ),
                    child: const Text('Lihat kes'),
                  ),
                ],
              ] else if (isSupervisor) ...[
                FilledButton(
                  onPressed: () =>
                      appState.decideAlert(alert, AlertState.acknowledged),
                  child: const Text('Sahkan pencerobohan dan buka kes'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () =>
                      appState.decideAlert(alert, AlertState.falseAlarm),
                  child: const Text('Tanda sebagai amaran palsu'),
                ),
              ] else
                const Banner2(
                  icon: Icons.hourglass_empty,
                  fg: AppColors.amberDark,
                  bg: AppColors.amberSoft,
                  text: 'Menunggu penyelia mengakui amaran ini.',
                ),
            ],
          ),
        );
      },
    );
  }
}

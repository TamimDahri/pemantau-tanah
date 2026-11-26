import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import 'lot_detail_screen.dart';
import 'lot_visit_screen.dart';

/// Phase 2 screen: work assigned to the officer, overdue first, with the
/// automatic reminder shown as a banner.
class MyWorkScreen extends StatelessWidget {
  const MyWorkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final now = DateTime.now();
        final items = appState.sortedWork;
        final overdue = items
            .where((w) =>
                w.status == WorkStatus.todo &&
                AppState.daysLate(w.due, now) > 0)
            .toList();
        final finished = appState.finishedWork.length;
        final isOfficer = appState.role == Role.fieldOfficer;
        final first = overdue.isNotEmpty ? overdue.first : null;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            Text(isOfficer ? 'Kerja saya' : 'Kerja kawasan',
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            Text(
              isOfficer
                  ? 'Pegawai kawasan · Kawasan Contoh'
                  : 'Paparan penyelia · Kawasan Contoh',
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            if (first != null) ...[
              Banner2(
                icon: Icons.notifications_active_outlined,
                fg: AppColors.amberDark,
                bg: AppColors.amberSoft,
                text:
                    'Peringatan: ${first.type.toLowerCase()} ${appState.lotById(first.lotId).name} '
                    'tertunggak ${AppState.daysLate(first.due, now)} hari.',
              ),
              const SizedBox(height: 12),
            ],
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _Stat('Tepat masa bulan ini',
                            '${appState.onTimeCount} daripada $finished',
                            color: AppColors.greenDark),
                      ),
                      Expanded(
                        child: _Stat('Kerja tertunggak', '${overdue.length}'),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: AppColors.greySoft),
                  const Text(
                    'Lewat 7 hari atau lebih dimaklumkan kepada penyelia. '
                    'Tiada markah, hanya status.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Senarai kerja',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text('Tertunggak di atas',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
            const SizedBox(height: 8),
            for (final w in items) _WorkCard(item: w, now: now),
            if (first != null && isOfficer) ...[
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        LotVisitScreen(lot: appState.lotById(first.lotId)),
                  ),
                ),
                child:
                    Text('Mula lawatan ${appState.lotById(first.lotId).name}'),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color ?? AppColors.text)),
      ],
    );
  }
}

class _WorkCard extends StatelessWidget {
  const _WorkCard({required this.item, required this.now});

  final WorkItem item;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final lot = appState.lotById(item.lotId);
    final late = AppState.daysLate(item.due, now);
    final (label, fg, bg, detail) = switch (item.status) {
      WorkStatus.todo when late > 0 => (
          'Tertunggak',
          AppColors.amberDark,
          AppColors.amberSoft,
          'lewat $late hari'
        ),
      WorkStatus.todo => (
          'Perlu dibuat',
          const Color(0xFF3C4742),
          AppColors.greySoft,
          late == 0 ? 'sasaran hari ini' : 'sasaran ${-late} hari lagi'
        ),
      WorkStatus.alertSent => (
          'Amaran dihantar',
          AppColors.criticalDark,
          AppColors.criticalSoft,
          'menunggu penyelia'
        ),
      WorkStatus.done => (
          'Selesai',
          AppColors.greenDark,
          AppColors.greenSoft,
          AppState.isOnTime(item)
              ? 'dibuat ${formatDate(item.doneAt!)}, tepat masa'
              : 'dibuat ${formatDate(item.doneAt!)}, lewat'
        ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => LotDetailScreen(lot: lot)),
        ),
        child: SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(lot.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                  Pill(label, fg: fg, bg: bg),
                ],
              ),
              const SizedBox(height: 4),
              Text('${item.type} · $detail',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

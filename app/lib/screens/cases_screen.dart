import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

/// Encroachment cases, tracked from confirmation until the site is confirmed
/// clear. Enforcement stays with the Land Administrator (PDT), outside the app.
class CasesScreen extends StatelessWidget {
  const CasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final now = DateTime.now();
        final cases = appState.sortedCases;
        final open = appState.openCaseCount;
        final over90 = cases
            .where((c) => c.stage != CaseStage.closed && c.ageDays(now) > 90)
            .length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            const Text('Kes pencerobohan',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            const Text(
              'Setiap kes dijejak sehingga tapak disahkan bersih',
              style: TextStyle(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _Stat('$open', 'Kes terbuka')),
                const SizedBox(width: 8),
                Expanded(
                  child: _Stat('$over90', 'Melebihi 90 hari',
                      color: over90 > 0 ? AppColors.criticalDark : null),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Stat(
                      '${cases.length - open}', 'Ditutup'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (cases.isEmpty)
              const SectionCard(
                child: Text(
                    'Tiada kes. Kes dibuka apabila penyelia mengakui amaran.'),
              ),
            for (final c in cases)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => CaseDetailScreen(caseItem: c)),
                  ),
                  child: SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${c.id} · ${appState.lotById(c.lotId).name}',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              '${c.ageDays(now)} hari',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.stage != CaseStage.closed &&
                                        c.ageDays(now) > 90
                                    ? AppColors.criticalDark
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Pill(c.stage.label, fg: c.stage.fg, bg: c.stage.bg),
                            Pill(
                              appState.lotById(c.lotId).agency.label,
                              fg: AppColors.text,
                              bg: AppColors.greySoft,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            const Text(
              'Sistem tidak menguatkuasa. Siasatan, notis dan penguatkuasaan '
              'oleh Pentadbir Tanah dan SOP agensi.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        );
      },
    );
  }
}

class CaseDetailScreen extends StatelessWidget {
  const CaseDetailScreen({super.key, required this.caseItem});

  final EncroachmentCase caseItem;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final c = caseItem;
        final lot = appState.lotById(c.lotId);
        final isSupervisor = appState.role == Role.supervisor;
        final now = DateTime.now();
        final action = c.stage.nextAction;
        return Scaffold(
          appBar: AppBar(title: Text(c.id)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              Text(lot.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              Text('${lot.lotNo} · ${lot.mukim} · ${lot.landType}',
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Pill(c.stage.label, fg: c.stage.fg, bg: c.stage.bg),
                  Pill('Umur kes ${c.ageDays(now)} hari',
                      fg: AppColors.text, bg: AppColors.greySoft),
                  Pill(lot.agency.label,
                      fg: AppColors.text, bg: AppColors.greySoft),
                ],
              ),
              const SizedBox(height: 12),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ringkasan',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(c.summary.isEmpty ? 'Tiada catatan' : c.summary,
                        style: const TextStyle(fontSize: 13)),
                    if (c.pdtRef != null) InfoRow('Rujukan aduan', c.pdtRef!),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Garis masa kes',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    for (var i = 0; i < c.events.length; i++)
                      _TimelineRow(
                        event: c.events[i],
                        last: i == c.events.length - 1 && action == null,
                      ),
                    if (action != null)
                      _NextRow(text: 'Seterusnya: $action'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (action == null)
                const Banner2(
                  icon: Icons.check_circle_outline,
                  fg: AppColors.greenDark,
                  bg: AppColors.greenSoft,
                  text: 'Kes ditutup. Gambar asas baharu menjadi rujukan lot.',
                )
              else if (isSupervisor)
                FilledButton(
                  style: c.stage == CaseStage.confirmed
                      ? FilledButton.styleFrom(
                          backgroundColor: AppColors.amber)
                      : null,
                  onPressed: () async {
                    if (c.stage == CaseStage.confirmed) {
                      final ok = await showPackSheet(context, c);
                      if (ok == true) appState.advanceCase(c);
                    } else {
                      appState.advanceCase(c);
                    }
                  },
                  child: Text(action),
                )
              else
                const Banner2(
                  icon: Icons.info_outline,
                  fg: AppColors.amberDark,
                  bg: AppColors.amberSoft,
                  text: 'Tukar peranan kepada Penyelia di bar atas untuk '
                      'mengemas kini kes.',
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Contents of the evidence pack attached to a complaint to the PDT.
Future<bool?> showPackSheet(BuildContext context, EncroachmentCase c) {
  final lot = appState.lotById(c.lotId);
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pek aduan PDT',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            Text('${c.id} · ${lot.name}',
                style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 12),
            const _PackRow('Pelan lot dan sempadan', true),
            const _PackRow('Rujukan warta atau hakmilik', true),
            const _PackRow('Gambar bertarikh dan berkoordinat', true),
            const _PackRow('Laporan pegawai dan pengesahan penyelia', true),
            const _PackRow('Surat iringan (templat agensi)', false),
            const SizedBox(height: 10),
            const Text(
              'Dalam demo ini pek tidak dijana sebagai fail. Versi sebenar '
              'menghasilkan PDF untuk dilampirkan dalam aduan.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sahkan pek aduan'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PackRow extends StatelessWidget {
  const _PackRow(this.label, this.ready);

  final String label;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(ready ? Icons.check_circle : Icons.edit_note,
              size: 20,
              color: ready ? AppColors.green : AppColors.amberDark),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(ready ? 'Sedia' : 'Perlu tandatangan',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ready ? AppColors.greenDark : AppColors.amberDark)),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event, required this.last});

  final CaseEvent event;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                      color: AppColors.green, shape: BoxShape.circle),
                ),
                if (!last)
                  Expanded(
                    child: Container(width: 2, color: AppColors.border),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${formatDate(event.at)} · ${event.actor}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted)),
                  Text(event.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  if (event.note.isNotEmpty)
                    Text(event.note, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextRow extends StatelessWidget {
  const _NextRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          margin: const EdgeInsets.only(left: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.amber, width: 2),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.amberDark)),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, {this.color});

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color ?? AppColors.green)),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );
  }
}

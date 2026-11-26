import 'dart:io';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

const reportCategories = [
  'Struktur baharu',
  'Pagar',
  'Tebangan',
  'Batu sempadan hilang/beralih',
  'Longgokan bahan',
  'Lain-lain',
];

/// Phase 2 screen: after all posts, choose "no change" or report a change.
/// With [direct] it is a direct report outside a scheduled visit.
class ReviewSubmitScreen extends StatefulWidget {
  const ReviewSubmitScreen({super.key, required this.lot, this.direct = false});

  final Lot lot;
  final bool direct;

  @override
  State<ReviewSubmitScreen> createState() => _ReviewSubmitScreenState();
}

class _ReviewSubmitScreenState extends State<ReviewSubmitScreen> {
  final _selected = <String>{};
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _submit({required bool noChange}) {
    appState.submitReport(
      widget.lot,
      noChange: noChange,
      categories: _selected.toList(),
      note: _note.text.trim(),
      direct: widget.direct,
    );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    messenger.showSnackBar(
      SnackBar(
        content: Text(noChange
            ? 'Lawatan ${widget.lot.name} direkod: tiada perubahan.'
            : 'Laporan dihantar. Amaran dicipta untuk penyelia.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lot = widget.lot;
    final photos = appState.photosOf(lot).values.toList()
      ..sort((a, b) => a.postSeq.compareTo(b.postSeq));
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.direct ? 'Lapor terus' : 'Semak dan hantar'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          Text(
            widget.direct
                ? '${lot.name} · laporan di luar lawatan berjadual'
                : '${lot.name} · ${photos.length} daripada ${lot.posts.length} pos selesai',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.green),
          ),
          const SizedBox(height: 12),
          if (photos.isNotEmpty) ...[
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => PhotoThumb(photo: photos[i]),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Sokongan AI',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    Pill('Fasa 3',
                        fg: Color(0xFF3C4742), bg: AppColors.greySoft),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Belum aktif dalam demo. Nanti AI membandingkan gambar baharu '
                  'dengan gambar asas dan memberi skor sebagai cadangan sahaja.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('Apa yang anda lihat?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in reportCategories)
                FilterChip(
                  label: Text(c),
                  selected: _selected.contains(c),
                  selectedColor: AppColors.greenSoft,
                  backgroundColor: Colors.white,
                  onSelected: (on) => setState(
                      () => on ? _selected.add(c) : _selected.remove(c)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _note,
            decoration: InputDecoration(
              labelText: 'Catatan ringkas (pilihan)',
              hintText: 'Contoh: bangsal kayu, belum beratap',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Demo: laporan disimpan dalam telefon sahaja dan hilang apabila '
            'aplikasi ditutup. Aplikasi sebenar menyimpan dahulu, kemudian '
            'memuat naik apabila ada liputan.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (!widget.direct) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _submit(noChange: true),
                    child: const Text('Tiada perubahan'),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => _submit(noChange: false),
                  child: const Text('Hantar laporan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PhotoThumb extends StatelessWidget {
  const PhotoThumb({super.key, required this.photo});

  final PhotoRecord photo;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 150,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo.path.isEmpty)
              Container(
                color: AppColors.border,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported_outlined,
                    color: AppColors.muted),
              )
            else
              Image.file(File(photo.path), fit: BoxFit.cover),
            Positioned(
              left: 6,
              top: 6,
              child: Pill(
                'Pos ${photo.postSeq}${photo.fallback ? ' · sandaran' : ''}',
                fg: Colors.white,
                bg: const Color(0xFF121815),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

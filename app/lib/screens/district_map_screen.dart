import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app_state.dart';
import '../geo.dart';
import '../map_common.dart';
import '../models.dart';
import '../theme.dart';
import 'lot_detail_screen.dart';

/// Phase 1 screen: every digitised lot in the district on one map.
class DistrictMapScreen extends StatefulWidget {
  const DistrictMapScreen({super.key});

  @override
  State<DistrictMapScreen> createState() => _DistrictMapScreenState();
}

class _DistrictMapScreenState extends State<DistrictMapScreen> {
  String? _selectedId = 'lot-01';
  LotStatus? _filter;
  String _query = '';

  bool _matches(Lot lot) {
    if (_filter != null && lot.status != _filter) return false;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return lot.name.toLowerCase().contains(q) ||
        lot.lotNo.toLowerCase().contains(q) ||
        lot.mukim.toLowerCase().contains(q);
  }

  void _selectAt(LatLng point, List<Lot> lots) {
    for (final lot in lots) {
      if (pointInPolygon(point, bufferPolygon(lot.boundary, 25))) {
        setState(() => _selectedId = lot.id);
        return;
      }
    }
  }

  int _count(LotStatus status) =>
      appState.lots.where((l) => l.status == status).length;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final lots = appState.lots.where(_matches).toList();
        final selected = lots.where((l) => l.id == _selectedId).firstOrNull;
        final allPoints = [for (final l in appState.lots) ...l.boundary];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Peta daerah',
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                  Text(
                    'Daerah Contoh · ${appState.lots.length} lot didigitalkan',
                    style:
                        const TextStyle(fontSize: 14, color: AppColors.muted),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Cari nombor lot atau mukim',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip('Semua ${appState.lots.length}', null),
                        _chip('Perlu lawatan ${_count(LotStatus.due)}',
                            LotStatus.due),
                        _chip('Amaran ${_count(LotStatus.alert)}',
                            LotStatus.alert),
                        _chip(
                            'Belum disahkan ${_count(LotStatus.unverified)}',
                            LotStatus.unverified),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCameraFit: CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(allPoints),
                        padding: const EdgeInsets.all(36),
                      ),
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onTap: (_, point) => _selectAt(point, lots),
                    ),
                    children: [
                      ...baseMapLayers(),
                      PolygonLayer(
                        polygons: [
                          for (final lot in lots)
                            Polygon(
                              points: lot.boundary,
                              color: lot.status.color.withValues(alpha: 0.32),
                              borderColor: lot.id == _selectedId
                                  ? AppColors.text
                                  : lot.status.color,
                              borderStrokeWidth: lot.id == _selectedId ? 3 : 2,
                              pattern: lot.status == LotStatus.unverified
                                  ? StrokePattern.dashed(segments: const [6, 4])
                                  : const StrokePattern.solid(),
                            ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          for (final lot in lots)
                            Marker(
                              point: centroidOf(lot.boundary),
                              width: 30,
                              height: 30,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedId = lot.id),
                                child: _LotPin(
                                  status: lot.status,
                                  selected: lot.id == _selectedId,
                                ),
                              ),
                            ),
                        ],
                      ),
                      ...userLocationLayers(appState.deviceFix),
                      mapAttribution,
                    ],
                  ),
                  const Positioned(
                      left: 8, right: 8, top: 8, child: MapNote()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Column(
                children: [
                  const Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _Legend(LotStatus.current),
                      _Legend(LotStatus.due),
                      _Legend(LotStatus.alert),
                      _Legend(LotStatus.unverified),
                    ],
                  ),
                  if (selected != null) ...[
                    const SizedBox(height: 10),
                    _SelectedCard(lot: selected),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _chip(String label, LotStatus? value) {
    final on = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: on,
        showCheckmark: false,
        selectedColor: AppColors.greenSoft,
        backgroundColor: Colors.white,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }
}

class _LotPin extends StatelessWidget {
  const _LotPin({required this.status, required this.selected});

  final LotStatus status;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: status.color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.text : Colors.white,
          width: selected ? 3 : 2,
        ),
      ),
      child: Icon(
        switch (status) {
          LotStatus.current => Icons.check,
          LotStatus.due => Icons.schedule,
          LotStatus.alert => Icons.priority_high,
          LotStatus.unverified => Icons.question_mark,
        },
        size: 14,
        color: Colors.white,
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.status);

  final LotStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: status.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(status.label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF3C4742))),
      ],
    );
  }
}

class _SelectedCard extends StatelessWidget {
  const _SelectedCard({required this.lot});

  final Lot lot;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(lot.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              Pill(lot.status.label,
                  fg: lot.status.dark, bg: lot.status.soft),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${lot.landType} · ${lot.mukim} · ${lot.areaHa.toStringAsFixed(2)} ha',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => LotDetailScreen(lot: lot)),
            ),
            child: const Text('Lihat butiran lot'),
          ),
        ],
      ),
    );
  }
}

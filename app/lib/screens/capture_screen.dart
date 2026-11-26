import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

/// In-app camera only. There is deliberately no gallery picker anywhere in
/// the app (CLAUDE.md rule 1).
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({
    super.key,
    required this.lot,
    required this.post,
    this.fallback = false,
  });

  final Lot lot;
  final PhotoPost post;

  /// Pole missing or damaged: photo taken at the pin coordinate instead.
  final bool fallback;

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  CameraController? _controller;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw StateError('no camera');
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller =
          CameraController(back, ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Kamera tidak dapat dibuka pada peranti ini.');
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _shoot() async {
    final controller = _controller;
    if (controller == null || _busy) return;
    setState(() => _busy = true);
    try {
      final file = await controller.takePicture();
      final bytes = await File(file.path).readAsBytes();
      _finish(file.path, sha256.convert(bytes).toString());
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Gambar gagal diambil. Cuba lagi.';
        });
      }
    }
  }

  /// Demo only: lets the flow continue on a device without a usable camera.
  void _placeholder() {
    final stamp = '${widget.lot.id}-${widget.post.seq}-${DateTime.now()}';
    _finish('', sha256.convert(utf8.encode(stamp)).toString());
  }

  void _finish(String path, String hash) {
    if (!mounted) return;
    final fix = appState.fixFor(widget.lot);
    Navigator.of(context).pop(
      PhotoRecord(
        lotId: widget.lot.id,
        postSeq: widget.post.seq,
        path: path,
        takenAt: DateTime.now(),
        sha256: hash,
        lat: fix?.point.latitude,
        lng: fix?.point.longitude,
        accuracyM: fix?.accuracyM,
        headingDeg: fix?.headingDeg,
        fallback: widget.fallback,
        mockLocation: fix?.mocked ?? false,
        simulated: fix?.simulated ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final fix = appState.fixFor(widget.lot);
    return Scaffold(
      backgroundColor: const Color(0xFF121815),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121815),
        foregroundColor: Colors.white,
        title: Text('Pos ${widget.post.seq} daripada ${widget.lot.posts.length}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  Icon(
                    widget.fallback ? Icons.report_problem_outlined : Icons.check,
                    size: 16,
                    color: const Color(0xFF8FD3B0),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.fallback
                          ? '${widget.lot.name} · Tiang hilang: guna pin koordinat'
                          : '${widget.lot.name} · Kod tiang disahkan (simulasi)',
                      style: const TextStyle(
                        color: Color(0xFF8FD3B0),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (controller != null)
                    ClipRect(child: CameraPreview(controller))
                  else
                    Container(
                      color: const Color(0xFF2B3630),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      child: _error == null
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white)),
                    ),
                  const IgnorePointer(child: _Crosshair()),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121815),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Gambar pertama di pos ini menjadi gambar asas. '
                        'Lawatan seterusnya memaparkannya sebagai lapisan lutsinar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(fix == null
                          ? 'GPS tiada'
                          : 'GPS ±${fix.accuracyM.round()} m'
                              '${fix.simulated ? ' (simulasi)' : ''}'),
                      _Chip(fix?.headingDeg == null
                          ? 'Arah: tiada kompas'
                          : 'Arah ${fix!.headingDeg!.round()}°'),
                      _Chip(formatTime(DateTime.now())),
                      const _Chip('Zoom dan nisbah dikunci'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (controller != null)
                    Semantics(
                      button: true,
                      label: 'Tangkap gambar',
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _busy ? null : _shoot,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _busy ? Colors.grey : Colors.white,
                            border: Border.all(
                                color: const Color(0xFF121815), width: 5),
                            boxShadow: const [
                              BoxShadow(color: Colors.white, spreadRadius: 3),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (_error != null)
                    FilledButton(
                      onPressed: _placeholder,
                      child: const Text('Teruskan tanpa kamera (demo)'),
                    ),
                  const SizedBox(height: 10),
                  const Text(
                    'Kamera aplikasi sahaja. Gambar galeri tidak diterima.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFB9C4BC), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Pill(label,
        fg: const Color(0xFFBFE8D2), bg: const Color(0xFF1F3A2D));
  }
}

class _Crosshair extends StatelessWidget {
  const _Crosshair();

  @override
  Widget build(BuildContext context) {
    final line = Colors.white.withValues(alpha: 0.35);
    return Stack(
      children: [
        Center(child: Container(height: 1, color: line)),
        Center(child: Container(width: 1, color: line)),
      ],
    );
  }
}

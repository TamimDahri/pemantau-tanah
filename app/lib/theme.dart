import 'package:flutter/material.dart';

import 'models.dart';

/// Palette from docs/SPEC.md section 10.
class AppColors {
  static const bg = Color(0xFFF5F6F3);
  static const text = Color(0xFF1B2420);
  static const muted = Color(0xFF55615B);
  static const border = Color(0xFFDDE2DC);
  static const green = Color(0xFF1F6B4A);
  static const greenDark = Color(0xFF17543A);
  static const greenSoft = Color(0xFFD9EEE3);
  static const amber = Color(0xFFB45309);
  static const amberDark = Color(0xFF8A4B00);
  static const amberSoft = Color(0xFFFBEBD0);
  static const critical = Color(0xFFB42318);
  static const criticalDark = Color(0xFF8E1B12);
  static const criticalSoft = Color(0xFFFBDCD8);
  static const grey = Color(0xFF8A948D);
  static const greySoft = Color(0xFFECEFEA);
  static const blue = Color(0xFF2563EB);
}

/// Fixed note required on every map (CLAUDE.md rule 3).
const boundaryNote =
    'Sempadan anggaran. Rujukan sah: batu sempadan dan pelan ukur.';

ThemeData buildTheme() {
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  const buttonText = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      primary: AppColors.green,
      surface: AppColors.bg,
      error: AppColors.critical,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: shape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        backgroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: shape,
        side: const BorderSide(color: Color(0xFFC5CCC4)),
        textStyle: buttonText,
      ),
    ),
  );
}

extension LotStatusUi on LotStatus {
  String get label => switch (this) {
        LotStatus.current => 'Terkini',
        LotStatus.due => 'Perlu lawatan',
        LotStatus.alert => 'Amaran',
        LotStatus.unverified => 'Belum disahkan di tapak',
      };

  Color get color => switch (this) {
        LotStatus.current => AppColors.green,
        LotStatus.due => AppColors.amber,
        LotStatus.alert => AppColors.critical,
        LotStatus.unverified => AppColors.muted,
      };

  Color get dark => switch (this) {
        LotStatus.current => AppColors.greenDark,
        LotStatus.due => AppColors.amberDark,
        LotStatus.alert => AppColors.criticalDark,
        LotStatus.unverified => AppColors.text,
      };

  Color get soft => switch (this) {
        LotStatus.current => AppColors.greenSoft,
        LotStatus.due => AppColors.amberSoft,
        LotStatus.alert => AppColors.criticalSoft,
        LotStatus.unverified => AppColors.greySoft,
      };
}

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, required this.fg, required this.bg});

  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Banner2 extends StatelessWidget {
  const Banner2({
    super.key,
    required this.icon,
    required this.text,
    required this.fg,
    required this.bg,
  });

  final IconData icon;
  final String text;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

String formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
    'Jul', 'Ogo', 'Sep', 'Okt', 'Nov', 'Dis',
  ];
  return '${d.day} ${months[d.month - 1]}';
}

String formatTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'pg' : 'ptg'}';
}

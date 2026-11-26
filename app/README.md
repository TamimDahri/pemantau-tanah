# Pemantau Tanah: app demo

Draf Flutter untuk tunjuk aliran kerja kepada JAIS. Ini **demo**, bukan Fasa 1 sebenar.

## Apa yang ada

- Tiada pangkalan data dan tiada pelayan. Semua lot, kerja dan amaran ialah data contoh dalam `lib/demo_data.dart`, disimpan dalam memori dan hilang apabila app ditutup.
- Peta asas: jubin OpenStreetMap melalui `flutter_map`, sementara lapisan GIS sebenar belum dimasukkan. Jubin perlukan internet.
- Lot contoh dijana di sekeliling lokasi telefon semasa app dibuka. Lot Contoh 01 terletak tepat di kedudukan telefon, jadi check-in geofencing boleh dicuba di tempat anda berada. Tanpa GPS, app guna Shah Alam dan suis "Simulasi berada di lot".
- Skrin: Peta daerah, Butiran lot, Kerja saya, Peta lot dan geofencing, Kamera, Semak dan hantar, Amaran. Tukar peranan (Pegawai kawasan atau Penyelia) di bar atas.
- Kamera dalam app sahaja; tiada pemilih galeri. Setiap gambar direkod bersama koordinat, ketepatan GPS, masa dan hash SHA-256.

## Apa yang belum ada

- Simpanan kekal, muat naik luar talian dan log masuk.
- Imbasan kod tiang (QR atau NFC): butang dalam demo hanya simulasi.
- Lapisan lutsinar gambar terdahulu, arah kompas sebenar, dan kunci zoom kamera.
- Notifikasi peringatan: demo hanya memaparkan sepanduk dalam app.
- Sokongan AI (Fasa 3).

## Bina dan uji

```
flutter test
flutter build apk --release
```

APK terhasil di `build/app/outputs/flutter-apk/app-release.apk`. Ia ditandatangani dengan kunci debug, sesuai untuk demo sahaja dan bukan untuk Play Store.

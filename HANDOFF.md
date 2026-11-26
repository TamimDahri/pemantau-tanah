# Serahan kerja: Pemantau Tanah

Tarikh: 26 Nov 2026. Fail ini untuk sesiapa yang menyambung kerja.

## Ringkasnya

- **Apa:** cadangan PLT kepada JAIS untuk mendigitalkan tanah ke dalam satu peta GIS, kemudian mengagih dan memantau kerja tapak melalui app telefon.
- **Pakej cadangan:** siap. Kertas cadangan, slaid dan contoh UI sudah ditulis ikut konsep terkini, dan slaid sudah disemak oleh pemilik projek.
- **App demo:** siap dibina (APK). Lulus analyzer dan 8 ujian, tetapi **belum dicuba pada telefon sebenar**.
- **App sebenar:** belum bermula. Pelan Fasa 1 sudah ditulis dan **menunggu kelulusan**.

## Baca dahulu, ikut susunan

1. `CLAUDE.md`: konsep, stack dan 8 peraturan yang tidak boleh dilanggar.
2. `docs/SPEC.md`: skop, peranan, tiga fasa, peraturan perniagaan, soalan terbuka.
3. `docs/PLAN-FASA-1.md`: langkah F0.1 hingga F4.1 dan keputusan K1 hingga K8.
4. `app/README.md`: apa yang ada dan tiada dalam app demo.

## Kandungan folder

| Laluan | Kandungan |
| --- | --- |
| `CLAUDE.md` | Arahan projek. Dibaca automatik oleh Claude Code |
| `docs/SPEC.md` | Spesifikasi terkini (26 Nov 2026) |
| `docs/PLAN-FASA-1.md` | Pelan kerja Fasa 1: Peta GIS |
| `docs/submission/` | PDF slaid (10 halaman) dan kertas cadangan (9 halaman) |
| `docs/design-source/` | Salinan sumber slaid dan 7 skrin UI |
| `app/` | App demo Flutter: data contoh, tiada pangkalan data, peta OpenStreetMap |
| `apk/` | APK demo arm64 untuk dipasang di telefon Android |
| `supabase/schema.sql` | Draf skema **lama**. Jangan guna; perlu ditulis semula dalam F0.1 |

## Keputusan konsep (26 Nov 2026)

Konsep asal (pasukan kariah memantau dengan ganjaran) telah ditukar. Yang berkuat kuasa sekarang:

- Peta GIS dibina dahulu (Fasa 1). Agihan kerja dan pemantauan ialah Fasa 2. AI ialah Fasa 3.
- Kerja tapak dibuat oleh pegawai kawasan JAIS. Tiada ganjaran atau upah.
- Kariah tiada peranan dalam rintis.
- Amaran pergi kepada penyelia pegawai, dengan eskalasi.
- Lawatan lewat direkod sebagai status tepat masa, tanpa markah. Lewat 7 hari atau lebih dimaklumkan kepada penyelia.
- Rintis: semua lot dalam satu daerah. Bilangan lot dan tempoh belum diketahui.

## Status setiap bahagian

### Kertas cadangan, slaid, UI

- Salinan hidup berada di claude.ai dan **peribadi kepada pemilik projek**. Minta pemilik kongsi melalui menu Share jika perlu menyunting di sana.
- PDF dalam `docs/submission/` ialah versi terkini.
- Belum diisi: `[TARIKH]` pada slaid kulit, dan pegawai perhubungan PLT di hujung kertas cadangan.
- Tajuk dokumen di claude.ai mungkin masih memaparkan nama lama "Berasaskan Kariah". Namakan semula di halaman dokumen.

### App demo (`app/`)

- Flutter 3.44.4, Dart 3.12.2. Pakej: `flutter_map` 8, `latlong2`, `geolocator` 14, `camera` 0.12, `crypto`.
- Semua data dalam memori (`lib/demo_data.dart`). Lot contoh dijana di sekeliling lokasi telefon; Lot Contoh 01 tepat di kedudukan telefon supaya check-in boleh dicuba.
- Bina dan uji:

  ```
  cd app
  flutter pub get
  flutter test
  flutter build apk --release --split-per-abi
  ```

- APK ditandatangani dengan kunci debug: untuk demo sahaja.
- Belum ada: imbasan kod tiang, lapisan lutsinar gambar terdahulu, kompas, notifikasi, simpanan kekal, AI.

### App sebenar

- Belum ada kod. Ikut `docs/PLAN-FASA-1.md`.
- Syarat pemilik projek: jangan tulis kod sebelum pelan dipersetujui; satu langkah kecil pada satu masa; selepas setiap langkah, beri cara uji di telefon.

## Langkah seterusnya

1. Cuba APK demo pada telefon sebenar dan catat masalah.
2. Dapatkan persetujuan pelan Fasa 1 dan keputusan K1 hingga K8.
3. Untuk mula F0.1 perlu: projek Supabase awan, serta jawapan K4 (struktur tanggungjawab) dan K5 (maklumat lot wajib).
4. Mula F0.1: skema baharu dengan PostGIS, RLS, log audit dan ujian.

## Perkara yang perlu disahkan

- **Peraturan 7 dalam `CLAUDE.md`** telah diubah: identiti pegawai pelapor dipaparkan kepada penyelia dan admin sahaja. Sahkan dengan pemilik projek.
- **"Kerja pembangunan"** ditafsir sebagai satu jenis kerja yang diagihkan pada lot. Skop sebenarnya belum disahkan.
- **Jenis tanah dan agensi:** contoh UI menyebut tapak surau, tapak masjid, tanah wakaf dan tanah perkuburan. Pastikan agensi yang betul bagi setiap jenis sebelum hantar.
- **Sistem koordinat pelan ukur (K2):** pelan lama dan baharu mungkin menggunakan datum berbeza. Sahkan dengan juruukur atau JUPEM sebelum mengimport lot sebenar.
- **Peta asas (K6):** pelayan OpenStreetMap tidak membenarkan muat turun pukal untuk kegunaan luar talian.

## Menyambung dengan Claude Code

Buka folder ini dalam Claude Code dan mulakan dengan:

> Baca HANDOFF.md, CLAUDE.md, docs/SPEC.md dan docs/PLAN-FASA-1.md. Jangan tulis kod dahulu. Beritahu apa yang kau faham dan apa yang diperlukan untuk mula F0.1.

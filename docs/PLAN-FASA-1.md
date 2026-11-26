# Pelan kerja Fasa 1: Peta GIS

Status: draf untuk kelulusan. Belum ada kod app sebenar ditulis. Rujukan skop: `docs/SPEC.md` bahagian 3.

## Matlamat

Setiap lot dalam daerah rintis berada di atas satu peta, dengan sempadan anggaran, maklumat lot, batu sempadan, pos gambar dan gambar asas, serta boleh dilihat tanpa liputan.

## Tidak termasuk

- Agihan kerja, peringatan, lawatan berjadual, laporan dan amaran (Fasa 2).
- AI (Fasa 3).
- Melukis poligon dalam app. Fasa 1 mengimport sempadan; suntingan dibuat di luar app (lihat K3).

## Seni bina

- Data tempatan dahulu: UI membaca dari SQLite (Drift) dalam telefon. Tulisan masuk ke pangkalan tempatan dan baris gilir muat naik dalam satu transaksi. ID dijana dalam telefon supaya cubaan semula tidak mencipta pendua.
- Pelayan ialah penentu akhir: Supabase dengan PostGIS. Peraturan "disahkan di tapak" disemak semula di pelayan.
- Pakej: `flutter_riverpod`, `go_router`, `supabase_flutter`, `drift`, `flutter_map`, `latlong2`, `geolocator`, `flutter_compass`, `camera`, `crypto`.
- App demo dipindah ke `demo/` dan kekal boleh dibina. App sebenar bermula di `app/`, dengan `geo.dart`, tema dan susun atur skrin diguna semula daripada demo.

## Skema ringkas

| Jadual | Kandungan |
| --- | --- |
| `districts`, `profiles` | Daerah; pengguna dengan peranan, daerah dan penyelia |
| `lots` | Nombor lot, mukim, keluasan, jenis tanah, status semasa, pegawai kawasan, penyelia, tarikh disahkan |
| `lot_boundaries` | Poligon PostGIS berversi: sumber, rujukan sumber, siapa, bila, sebab. Versi lama tidak dipadam |
| `boundary_stones`, `stone_checks` | Pin batu sempadan; setiap semakan (dijumpai, hilang, beralih) ialah rekod baharu dengan gambar |
| `posts` | Pos gambar: nombor, kod tiang, kedudukan, arah |
| `photos` | Gambar rujukan dan gambar asas dengan lat, lng, ketepatan, arah kompas, masa, hash. Tidak boleh diubah atau dipadam |
| `audit_log`, `app_settings` | Log tambah-sahaja; nilai yang boleh dikonfigurasi |

## Akses (RLS)

| Data | `field_officer` | `supervisor` | `admin` |
| --- | --- | --- | --- |
| Lot dan sempadan | Baca lot sendiri | Baca lot dalam daerah | Baca dan tulis semua |
| Semakan batu, pos, gambar | Baca dan tambah untuk lot sendiri | Baca dalam daerah | Baca semua |
| Sempadan versi baharu | Tiada | Tiada | Tambah sahaja |
| Ubah atau padam gambar dan semakan | Tiada | Tiada | Tiada |
| Log audit | Tiada | Tiada | Baca |

Bacaan oleh penyelia dan admin dilog. Peranan dan daerah pada `profiles` tidak boleh diubah oleh pengguna sendiri.

## Langkah

Setiap langkah siap dengan arahan uji di telefon dalam `docs/TESTING.md`. APK dihantar selepas setiap langkah yang mengubah app.

| Langkah | Kerja | Cara uji |
| --- | --- | --- |
| F0.1 | Skema baharu, PostGIS, RLS, trigger tidak boleh ubah, log audit, storan gambar peribadi, data contoh, ujian pgTAP | Jalankan ujian di SQL Editor: setiap peranan cuba baca dan tulis data yang dibenarkan dan yang dilarang |
| F0.2 | Pindah demo ke `demo/`; rangka app sebenar, tema, teks BM, log masuk, skrin utama ikut peranan | Pasang APK; log masuk dengan 3 akaun ujian; skrin berbeza ikut peranan |
| F0.3 | Pangkalan tempatan, tarik data lot ikut skop pengguna, baris gilir muat naik | Log masuk, mod kapal terbang, tutup paksa, buka semula: lot masih ada |
| F1.1 | Import GeoJSON: templat, semakan (geometri sah, medan wajib, pendua, keluasan munasabah), laporan baris yang ditolak | Import fail contoh 3 lot; lot muncul dalam app; fail rosak ditolak dengan sebab |
| F1.2 | Sempadan berversi dan log perubahan | Import semula satu lot dengan poligon berubah; app papar yang baharu; sejarah tunjuk 2 versi |
| F2.1 | Peta daerah: semua lot diwarnakan ikut status, nota tetap, peta asas boleh dikonfigurasi | Lihat lot contoh; dalam mod kapal terbang poligon masih dipaparkan |
| F2.2 | Carian dan tapisan: mukim, jenis tanah, pegawai, status | Cari nombor lot; tapis ikut status |
| F2.3 | Butiran lot: maklumat, sumber sempadan, batu sempadan, pos, sejarah versi | Buka satu lot; semak setiap medan dengan data import |
| F3.1 | Kedudukan pengguna, bulatan ralat, warna ketepatan, pengesanan lokasi palsu | Banding di luar dan dalam bangunan; cuba app lokasi palsu |
| F3.2 | Semakan batu sempadan dengan gambar kamera app dan metadata penuh | Rekod 4 batu untuk satu lot; lihat skrin metadata setiap gambar |
| F3.3 | Tetapkan pos gambar dan ambil gambar asas | Tanda 3 pos di tempat berdiri; ambil gambar asas |
| F3.4 | Peraturan "disahkan di tapak", disemak di telefon dan di pelayan | Butang sahkan kekal kelabu selagi ada batu atau pos belum lengkap |
| F3.5 | Kukuhkan muat naik; ujian terima luar talian | Sahkan satu lot penuh dalam mod kapal terbang; sambung talian; jalankan query semakan pendua |
| F4.1 | Paparan penyelia: peratus lot didigitalkan dan disahkan, ikut mukim dan pegawai | Log masuk sebagai penyelia; angka sepadan dengan data contoh |

## Keputusan yang diperlukan

Nilai lalai dalam kurungan. Yang belum diketahui dibuat boleh dikonfigurasi dan ditanda `TODO(SPEC §9)`.

- **K1. Sumber sempadan pertama.** Pelan ukur bercetak, data kadaster digital, atau senarai lot sahaja? *(Lalai: PLT menyediakan GeoJSON daripada pelan ukur menggunakan QGIS.)*
- **K2. Sistem koordinat pelan ukur.** Pelan lama dan baharu mungkin menggunakan datum berbeza, dan tersilap datum boleh menganjak sempadan beratus meter. Perlu disahkan dengan juruukur atau JUPEM sebelum lot sebenar diimport. *(Lalai: tiada andaian; setiap import merekod sistem koordinat sumber.)*
- **K3. Peta web untuk pejabat.** *(Lalai: tidak dalam Fasa 1. Import dibuat oleh PLT; melukis poligon dalam telefon tidak praktikal.)*
- **K4. Struktur tanggungjawab.** Lot terus kepada seorang pegawai, atau lot kepada kawasan dan kawasan kepada pegawai? *(Lalai: lot terus kepada pegawai kawasan dan penyelia.)*
- **K5. Maklumat lot wajib.** *(Lalai: nombor lot, mukim, keluasan, jenis tanah, status semasa. Pilihan: nombor hakmilik, nombor pelan.)*
- **K6. Peta asas dan imej satelit.** Pelayan OpenStreetMap tidak membenarkan muat turun pukal untuk luar talian. *(Lalai: OpenStreetMap dalam talian dengan cache kawasan yang pernah dilihat; URL pembekal boleh dikonfigurasi.)*
- **K7. Log masuk.** *(Lalai: e-mel dan kata laluan; akaun dicipta oleh admin.)*
- **K8. Hos data.** Bergantung pada dasar data JAIS. *(Lalai untuk rintis: projek Supabase awan; tiada andaian dalam kod.)*

## Untuk mula F0.1

- Projek Supabase awan dan rantaunya.
- Jawapan K4 dan K5, kerana kedua-duanya menentukan skema.

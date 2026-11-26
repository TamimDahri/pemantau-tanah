# Spesifikasi: Pemantau Tanah (rintis)

Dikemas kini 26 Nov 2026. Konsep berubah: peta GIS menjadi asas (Fasa 1), kerja tapak dibuat oleh pegawai kawasan JAIS (bukan pasukan kariah), dan ganjaran digugurkan.

## 1. Pengguna dan peranan

| Peranan | Siapa | Akses |
| --- | --- | --- |
| `field_officer` | Pegawai kawasan JAIS (pegawai bertugas) | Lot dalam kawasannya: peta, kerja, lawatan, gambar, laporan |
| `supervisor` | Penyelia atau ketua unit JAIS | Lot dalam daerahnya: agihan kerja, amaran, perbandingan gambar, status tepat masa |
| `admin` | Pengurusan JAIS / PLT (rintis) | Semua lot: data GIS, pengguna dan kawasan, selang lawatan, tempoh eskalasi, had skor AI |

Setiap lot ada seorang pegawai kawasan dan seorang penyelia. Kariah tiada peranan dalam rintis.

## 2. Skop rintis (cadangan, belum dimuktamadkan dengan JAIS)

1 daerah. Semua lot dalam daerah itu didigitalkan. Bilangan lot dan tempoh belum diketahui (lihat soalan terbuka).

## 3. Fasa 1: Peta GIS (pendigitalan)

### 3.1 Data lot
- Setiap lot: poligon sempadan anggaran, nombor lot, mukim, keluasan, jenis tanah, status semasa, pegawai kawasan, penyelia.
- Sumber sempadan direkod bagi setiap lot (pelan ukur, data sempadan sedia ada, atau ukur GPS di tapak) bersama tarikh.
- Batu sempadan: pin, gambar rujukan, status (dijumpai, hilang, beralih).
- Terima jika: setiap lot rintis ada poligon, maklumat wajib dan pegawai kawasan.

### 3.2 Import dan suntingan
- Admin mengimport sempadan (GeoJSON sebagai format asas) atau melukis dan menyunting poligon.
- Setiap perubahan sempadan disimpan sebagai versi baharu dengan siapa, bila dan sebab. Versi lama tidak dipadam.

### 3.3 Peta daerah
- Papar semua lot dalam daerah, diwarnakan mengikut status. Carian dan tapisan mengikut mukim, jenis tanah, pegawai dan status.
- Ketik lot untuk butiran: maklumat lot, batu sempadan, pos gambar, kerja akan datang.
- Peta dan data lot boleh dilihat di telefon tanpa liputan.
- Nota tetap: "Sempadan anggaran. Rujukan sah: batu sempadan dan pelan ukur."

### 3.4 Pengesahan di tapak
- Pegawai kawasan merekod status setiap batu sempadan dengan gambar, menetapkan kedudukan pos gambar dan mengambil gambar asas di setiap pos.
- Kamera dalam app sahaja. Simpan bersama gambar: lat, lng, ketepatan (m), arah kompas, masa, hash SHA-256.
- Terima jika: lot ditanda "disahkan di tapak" hanya selepas semua batu sempadan direkod statusnya dan semua pos ada gambar asas.

## 4. Fasa 2: Agihan kerja dan pemantauan tapak

### 4.1 Kerja
- Kerja diagihkan pada lot: jenis kerja, pegawai, tarikh sasaran. Jenis kerja boleh dikonfigurasi (lawatan pemantauan, kerja pembangunan, lain-lain).
- Lawatan pemantauan berulang mengikut selang lot (lalai bulanan).

### 4.2 Peringatan automatik
- Peringatan dihantar kepada pegawai bertugas apabila sampai masa, dan berulang sehingga kerja selesai.
- Lewat 7 hari atau lebih: penyelia dimaklumkan.

### 4.3 Kerja saya
- Senarai kerja pegawai dengan status: tertunggak, perlu dibuat, amaran dihantar, selesai.
- Terima jika: kerja tertunggak disusun di atas; status dikemas kini selepas kerja tanpa perlu muat semula manual.

### 4.4 Peta lot dan geofencing
- Papar garisan sempadan anggaran dengan zon penimbal, pin batu sempadan (dengan gambar rujukan), pin pos gambar, kedudukan pengguna dan bulatan ralat GPS.
- Papar teks ketepatan, contoh "±4 m", dengan warna: hijau di bawah 5 m, kuning 5 hingga 10 m, merah lebih 10 m.
- Check-in sah jika pengguna berada dalam sempadan + penimbal (lalai 15 m, boleh dilaras setiap lot).

### 4.5 Gambar di pos tetap
- Setiap pos ada tiang dengan kod (QR atau NFC). Imbas kod untuk kenal pasti lot dan pos.
- Kamera dalam app sahaja. Papar gambar terdahulu secara separa lutsinar untuk sejajarkan sudut. Kunci zoom dan nisbah gambar.
- Mod sandaran: jika tiang hilang atau rosak, ambil gambar di pin koordinat pos. Tanda gambar `fallback = true` dan cipta amaran "tiang hilang" secara automatik.
- Terima jika: lawatan hanya boleh diselesaikan selepas semua pos lot itu bergambar.

### 4.6 Laporan
- Selepas semua pos: pilih "Tiada perubahan" atau "Lapor perubahan".
- Kategori: struktur baharu, pagar, tebangan, batu sempadan hilang atau beralih, longgokan bahan, lain-lain. Catatan ringkas pilihan.
- Laporan terus juga boleh dibuat pada bila-bila masa, di luar lawatan berjadual.

### 4.7 Amaran dan eskalasi
- Amaran dicipta apabila pegawai melapor perubahan, atau tiang hilang. (Fasa 3: atau skor AI melepasi had.)
- Penyelia menerima notifikasi, melihat gambar asas dan gambar baharu, kemudian memilih "Akui dan buka siasatan" atau "Tanda sebagai amaran palsu".
- Jika tidak diakui dalam tempoh yang ditetapkan admin, amaran dinaikkan ke peringkat atas.
- Sistem tamat di sini.

### 4.8 Luar talian
- Peta, kerja, gambar dan laporan disimpan dalam telefon dan dimuat naik secara beratur apabila ada liputan.
- Terima jika: lawatan penuh boleh dibuat dalam mod kapal terbang, dan data sampai ke pelayan selepas talian kembali tanpa pendua.

## 5. Fasa 3: Sokongan AI

- Bagi setiap pos, banding gambar baharu dengan gambar asas. Hasil: skor buatan manusia (0 hingga 10), skor alam (0 hingga 10), ringkasan satu ayat.
- Pendekatan dua lapis yang dirancang: model segmentasi mengukur perubahan, model bahasa-visual menulis ringkasan. Untuk permulaan, model bahasa-visual sahaja sudah memadai. Model ditetapkan melalui konfigurasi.
- Had skor yang mencetuskan amaran ditetapkan admin, boleh dilaras setiap lot.
- Gambar mod sandaran ditanda keyakinan rendah.
- Penyelia menanda setiap amaran benar atau palsu; simpan untuk melaras had.
- Gambar asas boleh ditetapkan semula oleh penyelia atau admin selepas perubahan yang diluluskan, dengan log siapa dan bila.
- Jika panggilan AI gagal, laporan dan amaran manual tetap berjalan.

## 6. Peraturan perniagaan

### 6.1 Status tepat masa

| Masa kerja berbanding tarikh sasaran | Status |
| --- | --- |
| Awal, atau lewat sehingga 3 hari | Tepat masa |
| Lewat 4 hari atau lebih | Lewat |
| Lewat 7 hari atau lebih | Lewat; penyelia dimaklumkan |

Tiada markah. Penyelia melihat status bagi setiap lot dan pegawai. Had hari boleh dikonfigurasi.

### 6.2 Ganjaran

Tiada. Kerja tapak ialah skop tugas pegawai kawasan. App tidak merekod sebarang bayaran.

## 7. Keselamatan dan data

- RLS Supabase pada semua jadual, mengikut peranan, daerah dan kawasan.
- Senarai dan lokasi lot ialah data sensitif. Log setiap akses oleh penyelia dan admin.
- Gambar dalam Storage peribadi (bukan public bucket); akses melalui URL bertandatangan.
- Kesan lokasi palsu (mock location) dan tanda lawatan yang mencurigakan.

## 8. Di luar skop

- Siasatan, notis dan penguatkuasaan (SOP JAIS).
- Ganjaran atau bayaran.
- Penglibatan kariah dan aduan orang awam (boleh dipertimbang selepas rintis).
- Pemantauan satelit atau dron.

## 9. Soalan terbuka

- Sumber dan format data sempadan sedia ada (pelan ukur, data kadaster, senarai lot).
- Bilangan lot dalam daerah rintis, dan tempoh rintis.
- Maklumat lot yang wajib diisi.
- Struktur kawasan JAIS: siapa pegawai kawasan dan penyelia bagi setiap lot.
- Jenis kerja selain lawatan pemantauan, contohnya "kerja pembangunan": apa yang perlu direkod.
- Perlukah peta web untuk pejabat dalam Fasa 1, atau memadai app telefon dengan import oleh PLT.
- Tempoh eskalasi amaran (ditetapkan JAIS).
- Hos data dan pemilikan data selepas rintis.
- Kod tiang: QR sahaja, atau NFC juga.

## 10. Skrin rujukan

Tujuh skrin direka sebagai pengenalan: Peta daerah, Butiran lot, Kerja saya, Peta lot dan geofencing, Gambar di pos tetap, Semak dan hantar, Amaran kepada penyelia. Palet: latar #F5F6F3, teks #1B2420, hijau utama #1F6B4A, amaran #B45309, kritikal #B42318. Fon: Inter.

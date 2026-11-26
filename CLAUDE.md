# Pemantau Tanah

App dalaman untuk pendigitalan dan pemantauan tanah oleh kakitangan JAIS, dicadangkan oleh Pertubuhan Literasi Tanah (PLT) kepada JAIS. Status: projek rintis (pilot). Nama app masih sementara.

Prinsip teras: peta GIS ialah asas, dan semua kerja tapak diagihkan di atas peta. Manusia ialah teras, teknologi hanya untuk kecekapan dan bukti. AI ialah sokongan, bukan pembuat keputusan.

Perubahan konsep (26 Nov 2026): kerja tapak dibuat oleh pegawai kawasan JAIS, bukan pasukan kariah. Ganjaran digugurkan kerana kerja ini skop tugas pegawai. Kariah tiada peranan dalam rintis.

## Stack

- App mudah alih: Flutter (Android dan iOS, satu codebase)
- Backend: Supabase (Postgres dengan PostGIS, Auth, Storage, Edge Functions) untuk fasa rintis
- AI (Fasa 3 sahaja): dipanggil dari Edge Function, model mesti boleh ditukar melalui konfigurasi

## Dokumen

- `docs/SPEC.md`: skop, peraturan perniagaan, skrin, kriteria terima
- `docs/PLAN-FASA-1.md`: pelan kerja Fasa 1 (Peta GIS), langkah F0.1 hingga F4.1 dan keputusan K1 hingga K8
- `supabase/schema.sql`: draf skema LAMA, ditulis sebelum perubahan konsep. Perlu ditulis semula sebelum diguna; RLS belum ada.
- `app/`: app demo Flutter untuk pembentangan. Data contoh dalam memori, tiada pangkalan data, peta asas OpenStreetMap. Bukan Fasa 1 sebenar; lihat `app/README.md`.
- `docs/submission/`: PDF slaid dan kertas cadangan untuk semakan.

## Peraturan yang tidak boleh dilanggar

1. Gambar hanya dari kamera dalam app. Jangan benarkan pilih dari galeri.
2. Setiap gambar simpan koordinat, masa, ketepatan GPS (meter), arah kompas dan hash fail.
3. Sempadan pada peta dan geofencing ialah anggaran, bukan penentu sempadan. Paparkan nilai ralat GPS. Rujukan sah ialah batu sempadan dan pelan ukur.
4. App mesti berfungsi luar talian: simpan dahulu, muat naik bila ada liputan.
5. AI tidak mencetuskan tindakan. Ia hanya memberi skor dan ringkasan; penyelia yang mengesahkan.
6. Skop sistem tamat apabila amaran diterima dan diakui penyelia. Siasatan dan penguatkuasaan ialah SOP JAIS, di luar app.
7. Identiti pegawai pelapor hanya dipaparkan kepada penyelia dan admin, tidak dalam rekod kes yang dilihat pihak lain.
8. Rekod gambar, laporan dan amaran tidak boleh dipadam atau diubah oleh pegawai kawasan. Simpan log audit.

## Susunan kerja

1. Fasa 1: Peta GIS (pendigitalan lot). Bina ini dahulu sehingga lengkap.
2. Fasa 2: Agihan kerja dan pemantauan tapak.
3. Fasa 3: Sokongan AI. Jangan mula sebelum Fasa 2 berfungsi hujung ke hujung.

## Bahasa

UI dalam Bahasa Malaysia. Kod, nama jadual dan komen dalam Bahasa Inggeris.

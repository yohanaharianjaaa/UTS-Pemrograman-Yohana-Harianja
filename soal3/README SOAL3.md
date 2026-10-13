# Soal 3 — Voucher Kas Keluar

## Struktur

- `frontend/`: HTML, CSS, dan JavaScript untuk formulir web, autentikasi, validasi langsung, koneksi Supabase, serta riwayat audit.
- `backend/supabase.sql`: skema PostgreSQL, RLS, audit trail, pemeriksaan checksum, penguncian voucher POSTED, dan RPC untuk simpan/posting/reversal.
- `backend/README.md`: panduan konfigurasi Supabase dan penjelasan batasan.

## Menjalankan

1. Ikuti langkah konfigurasi pada [`backend/README.md`](./backend/README.md), termasuk menjalankan `backend/supabase.sql`.
2. Isi URL proyek dan publishable/anon key pada `frontend/supabase-config.js`. Jangan gunakan service-role key.
3. Buka folder `frontend` melalui server lokal, seperti **Live Server** pada VS Code. Jangan membuka HTML menggunakan `file://` karena Supabase Auth memerlukan origin web.
4. Daftar atau masuk dengan akun Supabase, lalu simpan draft atau posting voucher.

Tanpa konfigurasi proyek Supabase, aplikasi menampilkan petunjuk konfigurasi dan belum dapat menyimpan data.

# Backend Supabase — Soal 3

Backend Soal 3 berdiri sendiri dan tidak menggunakan tabel Soal 1. Implementasinya memakai Supabase Auth, PostgreSQL, RLS, trigger, dan RPC sehingga tidak memerlukan server Node.js/Express tambahan untuk purwarupa ini.

## Menyiapkan Supabase

1. Buat proyek Supabase.
2. Buka **SQL Editor**, jalankan seluruh isi `supabase.sql`.
3. Di **Project Settings → API**, salin Project URL dan publishable key (atau anon key lama) ke `../frontend/supabase-config.js`.
4. Jangan pernah meletakkan `service_role` key di frontend.
5. Di **Authentication → Providers**, pastikan Email aktif. Untuk uji coba lokal, atur konfirmasi email sesuai kebutuhan kelas/proyek.
6. Jalankan aplikasi melalui server statis lokal (misalnya ekstensi Live Server di VS Code), lalu daftar/masuk dengan akun Supabase Auth.

## Alur yang diterapkan

- Frontend membaca akun aktif dari `chart_of_accounts`.
- `save_cash_voucher` menyimpan draft atau mem-posting header dan baris jurnal dalam satu transaksi database. Posting menghitung ulang keseimbangan di PostgreSQL; validasi browser bukan satu-satunya pengaman.
- `created_by` berasal dari `auth.uid()`, sementara `created_at` dibuat oleh database.
- Posting membentuk `hash_checksum` SHA-256 atas metadata voucher dan baris jurnal.
- RLS membatasi pembacaan voucher ke pemiliknya dan hanya menyediakan hak baca langsung; perubahan dilakukan lewat RPC.
- Trigger menolak UPDATE/DELETE header POSTED dan perubahan baris milik voucher POSTED.
- `reverse_cash_voucher` membuat voucher POSTED baru dengan debit/kredit tertukar dan mencatat event pembalikan di audit log. Voucher sumber tetap utuh.
- `check_cash_voucher_checksum` menghitung ulang SHA-256 dari data yang tersimpan dan membandingkannya dengan checksum posting; tombol **Cek hash** tersedia di riwayat audit.
- Audit log bersifat immutable dan dapat dibaca pemilik event melalui tabel **Riwayat Audit Terbaru**.

## Batasan dan pemeriksaan untuk implementasi nyata

Checksum membantu mendeteksi perubahan data, tetapi bukan tanda tangan digital dan tidak melindungi dari administrator database yang memiliki hak istimewa. Untuk penggunaan produksi, tentukan juga kebijakan otorisasi/role perusahaan, periode akuntansi, nomor voucher, retensi log, proses backup, dan prosedur pemulihan. Contoh akun dalam SQL hanya data awal untuk purwarupa.

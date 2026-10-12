# Dokumentasi Penggunaan AI

Dokumen ini merangkum penggunaan alat AI yang disebutkan dalam pengerjaan UTS dan membedakan informasi yang dapat diperiksa pada berkas project dari keterangan penggunaan alat yang belum memiliki arsip prompt atau sumber pendukung di project. Tujuannya adalah transparansi: uraian di bawah tidak menyamakan rancangan dengan fitur yang sudah diimplementasikan dan tidak mengklaim pengujian atau akses sumber yang tidak dapat dibuktikan.

## Status arsip prompt dan sumber

Pemeriksaan berkas project menemukan dokumentasi Soal 1 pada [`Soal_1/log_prompt_ai.md`](../Soal_1/log_prompt_ai.md) dan purwarupa Voucher Kas Keluar pada folder [`Soal_3/voucher-kas-keluar/`](../Soal_3/voucher-kas-keluar/). Tidak ditemukan transkrip prompt asli Gemini Canvas atau NotebookLM, catatan notebook, daftar sumber NotebookLM, maupun hasil ekspor percakapan dari kedua alat tersebut.

Oleh karena itu, bagian untuk kedua alat menggunakan judul **Ringkasan Prompt yang Digunakan**, bukan kutipan prompt verbatim. Ringkasan tersebut menyampaikan tujuan dan substansi permintaan, bukan merekonstruksi redaksi yang tidak tersedia. Informasi tentang penggunaan Gemini Canvas dan NotebookLM di bagian ini dicatat berdasarkan keterangan pemilik tugas; kontribusi alat tertentu tidak dapat diverifikasi hanya dari berkas project.

## 1. Gemini Canvas — purwarupa Voucher Entri Transaksi Kas Keluar

### Tujuan penggunaan

Berdasarkan keterangan pemilik tugas, Gemini Canvas digunakan sebagai alat bantu untuk membuat purwarupa antarmuka web Voucher Entri Transaksi Kas Keluar menggunakan HTML, Tailwind CSS, dan JavaScript. Purwarupa dimaksudkan untuk memperlihatkan pengisian informasi voucher dan rincian jurnal serta validasi dasar sebelum simulasi submit.

### Ringkasan Prompt yang Digunakan

Teks prompt asli Gemini Canvas tidak ditemukan pada berkas project. Ringkasan substansi permintaan yang didokumentasikan adalah membuat purwarupa Voucher Kas Keluar dengan formulir informasi umum voucher dan baris jurnal; menyediakan data akun contoh; menampilkan dan menghitung Total Debit, Total Kredit, serta Selisih; memperlihatkan indikator `BALANCED` atau `UNBALANCED`; memvalidasi kelengkapan dan keseimbangan jurnal sebelum Submit; dan menyediakan tindakan tambah/hapus baris, Simpan Draft, Reset, serta konfirmasi Submit. Purwarupa diminta tetap jelas sebagai simulasi dan tidak boleh mengaku menyimpan transaksi ke database bila backend belum tersedia.

Ringkasan ini bukan salinan prompt asli dan tidak menyatakan bahwa teks prompt tersebut pernah dimasukkan persis dengan redaksi ini.

### Hasil atau kontribusi yang dapat diperiksa

Berkas purwarupa saat ini memperlihatkan implementasi berikut:

- [`Soal_3/voucher-kas-keluar/index.html`](../Soal_3/voucher-kas-keluar/index.html) menyediakan formulir voucher, tabel rincian jurnal, tampilan total dan selisih, indikator keseimbangan, tombol, serta modal konfirmasi dan pesan. HTML memuat Tailwind CSS dan Font Awesome melalui CDN.
- [`Soal_3/voucher-kas-keluar/app.js`](../Soal_3/voucher-kas-keluar/app.js) memuat data akun contoh, pembuatan dan penghapusan baris, kalkulasi nominal, validasi, reset, dan alur simulasi Draft/Submit.
- [`Soal_3/voucher-kas-keluar/styles.css`](../Soal_3/voucher-kas-keluar/styles.css) memuat CSS khusus seperti font, latar, scrollbar tabel, dan pengaturan spinner input angka.
- Kode validasi memeriksa tanggal, penerima, deskripsi, nominal negatif/tidak valid, akun yang belum dipilih pada baris bernominal, sekurang-kurangnya dua baris jurnal valid, jumlah debit dan kredit yang tidak sama-sama nol, dan keseimbangan total. Satu baris tidak boleh memiliki debit dan kredit positif sekaligus.
- Simpan Draft hanya menampilkan pesan simulasi di browser. Submit meminta konfirmasi, lalu menampilkan pesan bahwa data tidak dikirim atau disimpan ke database dan voucher belum berstatus `POSTED`.

Berkas-berkas tersebut membuktikan keadaan kode yang tersedia saat dokumentasi ini dibuat. Berkas itu tidak membuktikan sendiri alat mana yang menghasilkan setiap bagiannya atau bahwa fitur pernah diuji oleh Gemini Canvas.

### Batasan, status fitur, dan hal yang perlu diverifikasi

| Status | Uraian |
|---|---|
| **Tersedia pada kode purwarupa** | Formulir voucher dan rincian jurnal, akun contoh, tambah/hapus baris (dengan batas minimal dua baris), kalkulasi debit/kredit/selisih, indikator keseimbangan, validasi, tombol Simpan Draft dan Reset, serta modal konfirmasi Submit. |
| **Simulasi saja** | Simpan Draft dan Submit tidak menyimpan data ke database. Tampilan status awal tetap `DRAFT`; simulasi Submit tidak membukukan jurnal atau mengubah status menjadi `POSTED`. |
| **Rancangan/kebutuhan lanjutan, bukan fitur yang dibuktikan tersedia** | Integrasi Supabase/PostgreSQL, penyimpanan transaksi, identitas pembuat dan waktu pembuatan untuk audit trail, kebijakan/penguncian perubahan transaksi yang sudah berstatus `POSTED`, serta proses jurnal pembalik untuk koreksi transaksi yang sudah dibukukan. Catatan arsitektur di halaman menyebut topik-topik tersebut sebagai pertimbangan integrasi, bukan sebagai implementasi. |
| **Perlu diverifikasi pemilik tugas** | Kesesuaian tampilan dan validasi dengan rubrik; kecocokan akun contoh dan aturan akuntansi dengan kebutuhan tugas; cara memperoleh nomor voucher; serta seluruh kebutuhan integrasi dan kontrol sebelum aplikasi digunakan selain sebagai purwarupa. |

Tidak ada koneksi database palsu yang dinyatakan dalam dokumentasi ini. Tidak ada klaim bahwa transaksi telah disimpan, diposting, atau dibukukan.

## 2. NotebookLM — penelaahan sumber akuntansi dan aturan bisnis

### Tujuan penggunaan

Berdasarkan keterangan pemilik tugas, NotebookLM digunakan sebagai alat bantu untuk menelaah sumber yang tersedia mengenai definisi kas dan setara kas, aspek akuntansi pembayaran kas, keseimbangan debit-kredit, relevansi PSAK 207, dan aturan bisnis yang sebaiknya diperiksa sebelum transaksi diposting.

### Ringkasan Prompt yang Digunakan

Prompt asli NotebookLM, berkas sumber yang dimasukkan, dan catatan keluarannya tidak ditemukan di project. Karena itu, redaksi prompt verbatim maupun daftar dokumen sumber tidak dapat dicantumkan. Ringkasan tujuan permintaannya adalah meminta NotebookLM menelaah sumber yang tersedia pada topik-topik tersebut dan memisahkan (1) kesimpulan yang didukung langsung oleh sumber, (2) rekomendasi desain aplikasi, dan (3) hal yang masih perlu diverifikasi. Ringkasan ini menjelaskan maksud penggunaan berdasarkan keterangan pemilik tugas, bukan kutipan prompt asli.

### Hasil atau kontribusi yang dapat dipertanggungjawabkan

Tidak ada sumber NotebookLM, jawaban, catatan sitasi, atau ekspor notebook di project yang memungkinkan isi analisisnya diverifikasi. Dengan demikian, dokumentasi ini tidak mengatribusikan kesimpulan akuntansi tertentu kepada NotebookLM, tidak mengutip sumber, dan tidak menyajikan nomor paragraf PSAK 207.

Sebagai batas dokumentasi, topik kas/setara kas, pembayaran kas, keseimbangan debit-kredit, PSAK 207, dan aturan posting dicatat sebagai **ruang lingkup penelaahan yang dilaporkan oleh pemilik tugas**, bukan sebagai temuan yang sudah dibuktikan dari sumber. Kode purwarupa di [`Soal_3/voucher-kas-keluar/`](../Soal_3/voucher-kas-keluar/) menunjukkan validasi keseimbangan debit-kredit di antarmuka, tetapi bukan bukti penelaahan NotebookLM atau penetapan perlakuan akuntansi berdasarkan PSAK.

### Batasan dan hal yang perlu diverifikasi

- Pemilik tugas perlu memeriksa kembali kesimpulan terhadap sumber resmi dan materi kuliah yang benar-benar digunakan, termasuk edisi/keberlakuan PSAK 207 dan rujukan paragrafnya bila akan dicantumkan dalam laporan.
- Setiap klaim yang disebut didukung sumber harus disertai identitas sumber dan kutipan/rujukan yang dapat ditemukan kembali. Rekomendasi aplikasi harus diberi label sebagai rekomendasi, bukan ketentuan standar akuntansi.
- Aturan bisnis sebelum posting—misalnya kelengkapan bukti, otorisasi, periode transaksi, akun yang diperbolehkan, serta keseimbangan jurnal—perlu dicocokkan dengan instruksi soal dan kebijakan entitas. Daftar ini adalah hal untuk diperiksa, bukan klaim bahwa NotebookLM telah memvalidasi semuanya.
- Tidak ada klaim bahwa NotebookLM membaca kode, menjalankan pemeriksaan statis, membuka atau menjalankan aplikasi, melakukan pengujian browser, atau memverifikasi koneksi database.

## Pemeriksaan manual sebelum dikumpulkan

1. Jika tersedia, simpan atau periksa kembali prompt asli Gemini Canvas dan NotebookLM, lalu ganti ringkasan prompt hanya bila redaksi aslinya dapat dipastikan. Jangan menyajikan ringkasan sebagai kutipan.
2. Periksa arsip NotebookLM untuk memastikan sumber yang benar-benar dipakai, kesimpulan yang didukung langsung sumber, dan rujukan PSAK 207. Tambahkan rujukan yang akurat jika diwajibkan laporan.
3. Pastikan deskripsi hasil AI sesuai dengan kontribusi yang benar-benar terjadi dan instruksi mata kuliah; dokumentasi ini sendiri tidak mengesahkan kebenaran interpretasi akuntansi.
4. Pastikan fitur yang disebut “tersedia” masih ada pada versi berkas purwarupa yang akan dikumpulkan dan pertahankan keterangan bahwa penyimpanan/posting database belum tersedia.

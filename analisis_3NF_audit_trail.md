# Soal 1.3 — Analisis Audit Trail dan Normalisasi 3NF

## Pemisahan header dan lines

`journal_headers` menyimpan informasi yang berlaku untuk satu transaksi secara keseluruhan: tanggal, nomor referensi/bukti, deskripsi, dan status posting. `journal_lines` menyimpan rincian akun serta nominal debit dan kredit. Karena satu transaksi dapat melibatkan beberapa akun, satu header dapat mempunyai beberapa baris jurnal.

Contoh transaksi pembelian perlengkapan secara tunai:

**Header** (`journal_headers`)

| journal_id | transaction_date | reference_number | description | posting_status |
|---:|---|---|---|---|
| 1001 | 2026-10-12 | BK-001 | Pembelian perlengkapan tunai | POSTED |

**Lines** (`journal_lines`)

| journal_line_id | header_id | account_id | debit | credit |
|---:|---:|---:|---:|---:|
| 1 | 1001 | 510 | 500000.00 | 0.00 |
| 2 | 1001 | 110 | 0.00 | 500000.00 |

Baris pertama mendebit akun perlengkapan dan baris kedua mengkredit akun kas. Kedua baris terhubung ke transaksi yang sama melalui `header_id = 1001`. Informasi tanggal, referensi, deskripsi, dan status cukup disimpan satu kali di header karena nilainya berlaku untuk keseluruhan transaksi, bukan nilai yang berbeda di setiap baris.

## 1. Audit trail

Pemisahan ini membentuk batas yang jelas antara identitas transaksi dan rincian pembukuannya. Auditor dapat menemukan transaksi melalui nomor bukti atau tanggal pada header, lalu menelusuri semua rincian akun dan nominal yang terkait melalui `header_id`. Status posting juga berada pada tingkat transaksi, sehingga tidak perlu disalin dan berisiko berbeda antarbaris dari jurnal yang sama.

Jika seluruh informasi ditulis berulang pada tabel datar, perubahan deskripsi atau status harus diterapkan pada setiap baris transaksi. Kelalaian memperbarui sebagian baris dapat menghasilkan uraian atau status yang tidak konsisten. Pemisahan header-line mengurangi pengulangan tersebut dan membuat hubungan antara satu bukti transaksi dengan seluruh dampak akun lebih mudah ditelusuri. Desain ini membantu jejak audit, tetapi dengan sendirinya bukan mekanisme pencatatan riwayat perubahan; pencatatan siapa dan kapan mengubah data memerlukan rancangan audit tambahan.

## 2. Normalisasi bentuk normal ketiga (3NF)

Pada tabel datar yang menyimpan satu baris per akun jurnal, atribut header seperti tanggal, referensi, deskripsi, dan status akan berulang untuk setiap baris dalam transaksi yang sama. Jika `journal_line_id` menjadi primary key, ketergantungan datanya secara konseptual adalah:

```text
journal_line_id -> header_id -> transaction_date, reference_number,
                               description, posting_status
```

Atribut header bergantung pada `header_id`, bukan langsung pada rincian baris. Ketergantungan transitif ini menimbulkan redundansi dan anomali:

- **Anomali pembaruan:** perubahan deskripsi transaksi harus diperbarui pada semua baris terkait; bila hanya sebagian yang berubah, data menjadi tidak konsisten.
- **Anomali penyisipan:** informasi header tidak dapat disimpan secara terpisah sebelum ada baris jurnal tanpa membuat baris rincian yang belum nyata atau mengisi nilai-nilai buatan.
- **Anomali penghapusan:** menghapus baris terakhir suatu transaksi pada tabel datar sekaligus menghilangkan informasi header transaksi itu.

Dengan menyimpan atribut transaksi di `journal_headers` dan atribut rincian di `journal_lines`, atribut nonkunci berada pada tabel yang sesuai dengan entitas dan kuncinya. Tabel akun juga dipisahkan: nama, saldo normal, dan klasifikasi laporan disimpan satu kali untuk setiap `account_id`, bukan diulang pada setiap pemakaian akun. Pemisahan ini mendukung 3NF, mengurangi redundansi, dan mencegah anomali tersebut.

## Batas integritas yang perlu diperhatikan

Constraint pada DDL memeriksa bahwa debit dan kredit tiap baris tidak negatif dan tidak keduanya nol. Pemeriksaan per baris tersebut **tidak** membuktikan bahwa jumlah debit sama dengan jumlah kredit untuk seluruh baris dalam satu jurnal. Keseimbangan total adalah aturan lintas baris dan memerlukan mekanisme tambahan bila hendak ditegakkan otomatis di database. Mekanisme itu berada di luar lingkup DDL yang diminta pada soal ini.

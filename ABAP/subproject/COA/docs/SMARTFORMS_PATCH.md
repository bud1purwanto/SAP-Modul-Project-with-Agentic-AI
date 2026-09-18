# Panduan Patch Smart Forms via XML

Panduan ini melengkapi `COA.md` untuk perubahan Smart Forms yang lebih cepat dan terukur. Gunakan hanya pada sandbox yang diizinkan oleh panduan proyek.

## Alur aman

1. Export XML dari Smart Form yang sedang aktif.
2. Simpan hasil export sebagai baseline dan jangan mengubahnya.
3. Buat salinan kandidat, lalu patch hanya node yang diperlukan.
4. Import kandidat ke SAP, activate, dan generate function module.
5. Export ulang Smart Form aktif setelah import.
6. Bandingkan struktur penting dan hash hasil export dengan kandidat.
7. Jalankan generated function module dan periksa PDF aktual, bukan hanya XML.
8. Simpan XML live hasil verifikasi sebagai artefak rollback/audit.

## Trik tabel agar style konsisten

Untuk tabel baru, gunakan tabel lama yang tampil benar sebagai referensi. Jangan hanya menyalin lebar kolom atau `PATTERN`.

- Salin struktur `PATTERN`, termasuk `FRAME`, ukuran garis, dan unitnya.
- Salin struktur `BORDERS` pada setiap `CELL`. Border pada level tabel saja tidak menjamin garis sel tampil.
- Pastikan unit border konsisten. Contoh yang telah terbukti pada form COA adalah ketebalan `15.00` dengan unit `TW`.
- Gunakan format teks header yang sama dengan tabel referensi, misalnya `<H1>...</>`.
- Gunakan format teks data yang sama dengan tabel referensi, misalnya `<D1>...</>`.
- Hapus paragraf kosong tambahan pada node teks karena dapat membuat tinggi baris dan jarak antarbagian berubah.
- Header dan data harus menggunakan definisi kolom/cell yang sama. Jangan menyelaraskan keduanya dengan spasi manual.

## Pemeriksaan regresi sebelum import

Kandidat minimal harus diperiksa untuk kondisi berikut:

- seluruh cell mempunyai border kiri, atas, kanan, dan bawah;
- format header dan data sesuai tabel referensi;
- tidak ada paragraf kosong yang tidak diperlukan;
- jumlah cell header sama dengan jumlah cell data;
- urutan field sesuai mapping program pemanggil;
- orientasi halaman utama tidak berubah bila perubahan hanya untuk lampiran.

Contoh hasil pemeriksaan yang diharapkan:

```text
STYLE_TEST_OK []
```

Jika masih muncul `CELL_BORDER`, `HEADER_FONT`, `DATA_FONT`, atau `EMPTY_LINE`, kandidat belum boleh di-import.

## Verifikasi setelah import

Keberhasilan import belum membuktikan layout benar. Lakukan seluruh langkah berikut:

1. Pastikan Smart Form aktif dan generated function module tersedia.
2. Export ulang objek aktif dan jalankan pemeriksaan struktur yang sama.
3. Generate OTF/PDF menggunakan function module aktif.
4. Periksa secara visual: font, border, alignment, wrapping, pemisahan halaman, dan tanda tangan.
5. Jalankan ulang program pemanggil agar preview lama dari sesi sebelumnya tidak dianggap sebagai hasil terbaru.

Contoh pemanggilan yang kompatibel dengan ABAP 7.31:

```abap
CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
  EXPORTING
    formname = 'ZQMF_COA_BATCH'
  IMPORTING
    fm_name  = lv_fm_name
  EXCEPTIONS
    no_form            = 1
    no_function_module = 2
    OTHERS             = 3.
```

## Catatan penting

- Generated function module `/1BCDWB/SF...` dapat berubah setelah aktivasi. Program harus memperoleh namanya melalui `SSF_FUNCTION_MODULE_NAME`, bukan menyimpan nama generated FM secara tetap.
- Patch tabel lampiran tidak boleh mengubah Smart Form halaman utama jika requirement hanya menyentuh batch list.
- Patch XML berisiko merusak layout bila struktur internal tidak lengkap. Selalu simpan baseline dan gunakan mekanisme rollback proyek.
- Perubahan layout tidak menambah akses database. Dampak performa utamanya berada pada jumlah baris tabel dan proses rendering OTF/PDF.
- Objek lokal `$TMP` tidak masuk transport. Jika akan dipindahkan antar-system, tetapkan package dan transport request sesuai prosedur SAP.

## TCODE terkait

- `SMARTFORMS`: inspeksi, aktivasi, dan generate Smart Form.
- `SE38`/transaksi program pemanggil: pengujian preview end-to-end.
- `ST22`: analisis dump, terutama parameter generated function module yang tidak cocok.
- `SP01`: pemeriksaan spool bila output dibuat melalui spool.

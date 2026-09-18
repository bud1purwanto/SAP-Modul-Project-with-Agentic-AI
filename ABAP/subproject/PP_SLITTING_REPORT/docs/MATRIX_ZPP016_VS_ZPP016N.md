# Matriks Perbedaan ZPP016 dan ZPP016N

Tanggal analisis: 10 September 2026  
Sistem source: TRD (Development Windows), diverifikasi keberadaan tcode lintas DEV/QA/TRS/PRT/TRP.

## Klarifikasi nama

Objek bernama persis `ZPP106` tidak ditemukan di TSTC, TSTCT, TRDIR/TADIR, maupun RAG. SAP memiliki pasangan berikut dengan judul transaksi yang sama, `Rekap Slitting Harian`:

- `ZPP016` -> `ZPPR_SLITTING_REKAP_DAILY`
- `ZPP016N` -> `ZPPR_SLITTING_REKAP_PC_V2`

Karena itu, matriks di bawah membandingkan `ZPP016` dengan `ZPP016N`. Kemungkinan besar `ZPP106` adalah salah ketik dari `ZPP016`.

## Matriks

| Aspek | ZPP016 | ZPP016N | Perbedaan utama |
|---|---|---|---|
| Judul transaksi | Rekap Slitting Harian | Rekap Slitting Harian | Judul sama, report di belakangnya berbeda. |
| Program utama | `ZPPR_SLITTING_REKAP_DAILY` | `ZPPR_SLITTING_REKAP_PC_V2` | Dua codebase terpisah, bukan sekadar transaction variant. |
| Fokus bisnis | Detail eksekusi produksi slitting dan performa proses | Detail hasil roll/batch serta traceability sampai kondisi/final batch | ZPP016 lebih execution-oriented; ZPP016N lebih batch/output-oriented. |
| Input umum | Material, Plant, Material Group, Posting Date, Production Line | Material, Plant, Material Group, Posting Date, Production Line | Hampir sama. |
| Input tambahan | Tidak ada filter batch pada selection screen | Batch (`ZCHARG`) dan checkbox `V_SCON`, default aktif | ZPP016N dapat membatasi langsung ke batch tertentu. |
| Material scope | Material type `ZFGS`, default material group `300001`-`300024` | Material type `ZFGS`, default material group `300001`-`300024` | Sama. |
| Sumber transaksi material utama | 101, 261 untuk Condux/CX, 531 untuk transfer FG-to-FG | 101, 531; reversal 102/532; 411/412/413/414 dipakai menelusuri Sales Order | ZPP016 menangkap consumption/CX; ZPP016N memperkuat transfer, reversal, dan SO traceability. |
| Reversal | Menghapus dokumen yang direferensikan sebagai reversal melalui `SMBLN` | Menghapus 101 yang direversal 102 dan 531 yang direversal 532 | ZPP016N lebih eksplisit per pasangan movement. |
| Data order | Combined Order, Original Order, Original Order Type | Order Number dan atribut output roll | ZPP016 menampilkan struktur order lebih lengkap. |
| Data proses mesin | Resource, start/finish date-time, process time, speed, entered-at | Resource dan entry time; tersedia rekap per shift berdasarkan entry time | ZPP016 menyajikan KPI eksekusi langsung; ZPP016N menyediakan agregasi shift. |
| Data film/batch umum | Film type, batch, roll, criteria, grade, treatment, packing, width, length, extra length, core type | Field umum yang sama, ditambah description grade dan last grade/criteria/quantity | ZPP016N lebih kaya untuk status batch historis. |
| Data khusus MS/SS | MS/SS, turunan dan posisi MS/SS | Tidak ada field MS/SS tersebut | Hanya ZPP016 yang mendukung detail turunan/posisi MS dan SS. |
| Final batch/history | Tidak memakai `ZBATCHISTORY` | Memakai `ZBATCHISTORY`: final batch, final no. roll, final grade, final criteria, final qty | Kemampuan utama ZPP016N adalah traceability ke identitas akhir batch. |
| Current/final stock | Stock digunakan terutama untuk last quantity | Membaca `MCHB`, `MSKA`, `MSLB`, `MSKU` untuk last qty dan final qty actual | ZPP016N lebih lengkap untuk posisi kuantitas aktual lintas stock category. |
| Field Toyobo/label | Tidak ada | Category, Type Label, Grade Toyobo, No. Roll Toyobo, No. Lot Toyobo, Type Alias | Hanya ZPP016N. |
| Sales/customer | SO, item, sales document type, sold-to, customer name | SO, item, customer dan customer description; ada drilldown/rekap sales | ZPP016 menyimpan tipe dokumen; ZPP016N lebih berorientasi penelusuran hasil roll ke sales. |
| Tampilan utama | Classic ALV grid | Classic ALV grid | Sama-sama ALV. |
| Fitur tambahan layar | Tidak terlihat submenu agregasi pada source utama | Rekap Grade, Rekap Shift, Sales, drilldown batch ke `MSC3N` | ZPP016N lebih interaktif untuk analisis hasil. |
| Download lokal | Tidak teridentifikasi sebagai fitur utama | Download rekap grade/shift/sales via `GUI_DOWNLOAD` format DBF | Keunggulan ZPP016N. |
| Mode OLAP | Native SQL connection `TRIASDB05`; refresh `XZPP016`; lalu `SP_MERGE_ZPP016` | Native SQL connection `TRIASDB04`; refresh `XSR_MPAGI` | Target database dan struktur staging berbeda. |
| Dampak mode OLAP | Menghapus seluruh isi staging `XZPP016`, insert ulang, lalu menjalankan stored procedure merge | Menghapus seluruh isi `XSR_MPAGI`, lalu insert ulang | Keduanya bukan read-only bila radio OLAP dipilih. |
| Otorisasi | Plant `Z_WERKS`, akses OLAP `Z_OLAP`; source mengecek `ZOLAP/ZTCODE = ZPP016N` | Plant `Z_WERKS`, akses OLAP `Z_OLAP`, dan `ZOLAP/ZTCODE = ZPP016N` | Pemeriksaan nama ZPP016N di program ZPP016 patut dicatat sebagai kemungkinan copy/config dependency. |
| Pengguna/use case dari RAG | Tidak ditemukan referensi eksplisit yang kuat untuk tcode lama | Staff PPIC; Report Slitting Harian untuk melacak aktivitas produksi setelah Slitting Execution | Dokumentasi blueprint mengarahkan proses bisnis aktif ke ZPP016N. |

## Kesimpulan

- Gunakan **ZPP016** ketika fokusnya adalah detail eksekusi order dan performa proses: combined/original order, Condux/CX, MS/SS, start-finish, process time, dan speed.
- Gunakan **ZPP016N** ketika fokusnya adalah output roll/batch dan traceability: filter batch, last/final batch, final grade/criteria/quantity, final stock actual, data Toyobo/label, serta rekap grade/shift/sales.
- Untuk proses bisnis operasional yang terdokumentasi di blueprint, RAG secara konsisten menunjuk **ZPP016N** sebagai Report Slitting Harian bagi Staff PPIC.

## Referensi RAG

- `PPPE02 Production Process of Slit Roll BOPP v2`, halaman 8, document ID `a7b282f5-999f-4007-b01b-caaee8f2945d`.
- `PPPE06 Production Process of Slit Roll Metalizing (Updated for CPP OPP)`, halaman 8-9, document ID `f3edab47-64c5-42dd-b067-5ef5db6efea8`.
- `PPPE26 Production Process of Slit Roll CPP v2`, halaman 8, document ID `ba97ebc9-6941-49d8-871b-35288cae3c62`.
- `PPPE08 Production Process of Slit Roll Coating v2`, halaman 9, document ID `fdf07f5c-c68f-4766-b016-1de1dd8caf07`.

## Referensi source SAP

- TSTC/TSTCT: mapping transaction dan judul.
- `ZPPR_SLITTING_REKAP_DAILY`, include `ZPPR_SLITTING_REKAP_DAILY_TOP` dan `ZPPR_SLITTING_REKAP_DAILY_F01`.
- `ZPPR_SLITTING_REKAP_PC_V2`, include `ZPPR_SLITTING_REKAP_PC_V2_TOP`, `..._F01`, `..._O01`, dan `..._I01`.

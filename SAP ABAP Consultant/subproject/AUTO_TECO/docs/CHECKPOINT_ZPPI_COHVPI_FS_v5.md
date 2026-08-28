# TRANSFER KONTEKS — ZPPI_COHVPI (Auto TECO) / Penyusunan FS v5

## 1. METADATA SESI
- **Nama Proyek:** Auto TECO Process Order — program `ZPPI_COHVPI` (PT Trias, modul PP)
- **Tanggal:** 05 Agustus 2026
- **Model AI asal:** Claude Opus 5 (Cowork, project "SAP ABAP Consultant")
- **Status Sesi:** Terputus — limit token. Deliverable FS v5 **belum selesai dibuat**.
- **Sistem:** SAP ECC 6.0 EHP6, ABAP 7.31, Oracle. Alias MCP `sandbox-new` ⇒ nyatanya **SID TRD, client 130**, host `eccdevlinux` (alias `dev-aix` = sistem yang SAMA).

## 2. RINGKASAN EKSEKUTIF
Tugas terakhir user: **memperbarui Functional Specification** berdasarkan file `FunctSpec_Auto_TECO_Closing_ZPPI_COHVPI.DOCX` yang sudah user edit sendiri, menyesuaikan dengan **program terbaru** (email sudah TIDAK memakai mapping ZMAP_TYPE lagi), dan menyertakan **contoh hasil email berupa screenshot**.

Screenshot email **SUDAH SELESAI dibuat dan terverifikasi**. Yang tersisa: merakit dokumen `.docx` FS v5.

## 3. STATUS & CAPAIAN SAAT INI

### Sudah selesai
- ✅ Baca program terbaru dari server `sandbox-new`: **1602 baris, SUM(STRLEN) = 55755**.
- ✅ Terkonfirmasi user **menghapus** mapping email di ZMAP_TYPE dari program. Sudah tidak ada: `GT_ETX`, `TY_ETX`, `LOAD_EMAIL_TEXT`, `SUBST_TEXT`, `APPEND_ETX`, `BODY_DEFAULT`, string `'EMAIL TEXT'`.
- ✅ User **menambahkan** FORM baru: `APPEND_HTML`, `HTML_ESC`, `APPEND_HTML_PARAGRAPH`, `APPEND_SUMMARY_HTML`, `BUILD_HTML_EMAIL`, `F_SORT`.
- ✅ Email sekarang **HTML** (`CL_DOCUMENT_BCS=>CREATE_DOCUMENT( I_TYPE = 'HTM' )`), subject hardcode `'Status Process Order' + YYYY-MM`.
- ✅ **Screenshot email dibuat & diverifikasi** (render via LibreOffice → PDF → PNG, auto-crop):
  - `email_preview_mode_transaksi.png` (mode Transaksi TECO — kolom Result: OK / Review / Test Run)
  - `email_preview_mode_report.png` (mode Report TECO — kolom Result: Completed / Pending / Review)
  - Source HTML: `m1.html`, `m2.html` (di folder proyek)

### Belum selesai
- ❌ Dokumen **FS v5 (.docx)** belum dirakit. Helper docx-js di `/tmp/fs4` HILANG karena workspace restart; `/tmp/fs5` sudah dibuat + `npm install docx` sudah jalan, tapi `build.js` belum ditulis ulang.

## 4. BATASAN & PREFERENSI PENGGUNA
- **Bahasa penjelasan:** Indonesia; terminologi SAP/TCODE/keyword ABAP tetap Inggris.
- **ABAP 7.31 klasik saja** — dilarang `DATA(...)`, `NEW`/`VALUE`/`REDUCE`, string template `|...|`, Open SQL `@`.
- **Server:** analisis boleh di `dev`, tapi **semua perubahan program WAJIB di `sandbox-new`**. User: *"ini saya testing di dev, saya deploy lewat tools, kalau kamu debugging di dev gpp, tapi perubahan tetap di sandbox"*.
- **JANGAN full-push program.** Selalu `READ REPORT` + bandingkan `LINES` & `SUM(STRLEN)` dulu; gunakan **targeted patch**. Pernah terjadi full-push menghapus edit manual user.
- **Edit manual user yang wajib dipertahankan:** baris `PERFORM SET_INDICATOR USING 1 1 C_STEP_GET C_TOTAL_STEP 'Mencari data movement...'.` di awal `FORM GET_DATA`.
- Gaya dokumen FS: bahasa awam/non-teknis di bab awal, banner berwarna, card per grup order type, tabel rapi. Ikuti struktur 10 bab milik user.

## 5. REPOSITORI MEMORI UTAMA

### 5.1 Koreksi fakta yang HARUS masuk FS v5 (dokumen user masih stale)
| Isi di docx user | Fakta sebenarnya |
|---|---|
| "Variant CLOSING" | Nama variant di sistem adalah **TECO** |
| Parameter `S_AUART` di Bab 7 | **Sudah dihapus** — order type kini dari mapping `ZMAP_TYPE` |
| "Email hasil TECO (CSV)" | **Excel (SpreadsheetML 2003 .XLS), 1 file per grup order type** |
| "7.000+ kartu" | Angka belum diverifikasi — sebaiknya dihapus/di-generalisasi |
| "Plant 2000" | Program **tidak memfilter plant sama sekali** (tidak ada WERKS di WHERE) |
| Belum ada | `S_AUFNR`, radio mode Transaksi/Report, checkbox Test Run, checkbox Send Email + PA_TO/PA_CC/PA_BCC |

### 5.2 Layar seleksi program saat ini (baris 146–173)
```
RB1 / RB2      radio group, USER-COMMAND UCMD   (Transaksi TECO / Report TECO)
S_BUDAT        posting date (TIDAK obligatory, divalidasi manual di FORM VALIDATION)
S_AUFNR        nomor PRO
S_AUTYP        order category (default 40)
S_BWART        movement type (default 101 102 261 262 531 532 901 902)
P_TEST         Test Run                       MODIF ID M1  (mode Transaksi)
P_SEND         Send Email, USER-COMMAND UC2
P_REL / P_TECO filter status                  MODIF ID M2  (mode Report)
PA_TO/PA_CC/PA_BCC                            MODIF ID M3  (muncul bila P_SEND = 'X')
```

### 5.3 Daftar FORM (baris) — program 1602 baris
```
VALIDATION 219 | LOAD_ORDER_TYPE_MAP 247 | GET_GROUP 285 | SET_SCREEN_MODE 302
FILTER_REPORT_STATUS 330 | GET_DATA 356 | SET_BWART_DEFAULT 448 | PREFETCH_STATUS 469
PREFETCH_MILL 503 | GET_STATUS_CACHED 518 | REFRESH 533 | TECO 613 | ROLLBACK 721
CHECK_TECO_ELIGIBLE 737 | SEND_EMAIL 827 | APPEND_HTML 918 | HTML_ESC 924
APPEND_HTML_PARAGRAPH 932 | APPEND_SUMMARY_HTML 946 | BUILD_HTML_EMAIL 1065
ADD_LINKED_ORDERS 1102 | ADD_XLS_ATTACH 1128 | XML_ESC 1180 | XCELL 1194 | BUILD_XLS 1210
COMMIT 1324 | GET_ORDER_STATUS 1343 | BAPI_COMMIT 1360 | SET_CELL_COLOURS 1380
DISPLAY_ALV 1394 | F_SORT 1404 | F_FIELD_CATALOG_PREVIEW 1426 | F_LAYOUT 1459
F_LIST_DETAIL_PREVIEW 1476 | F_GUI_STATUS 1507 | F_USER_COMMAND 1518
SET_INDICATOR 1548 | CONVERSION_INPUT 1580 | CONVERSION_OUTPUT 1596
```

### 5.4 Logika tabel ringkasan email (`APPEND_SUMMARY_HTML`)
Kolom: **Group (30%) | Order (15%) | Status (25%) | Result (30%)**.
Header row: `background:#2f3a46; color:#ffffff`. Tabel `width:100%; max-width:640px; border-collapse:collapse; font-size:12px; border-color:#c9cfd6; text-align:center; table-layout:fixed`.

```
Status : semua TECO -> 'TECO' ; semua REL -> 'REL' ; selain itu -> 'Mixed'
Result (mode Report / RB2):
   semua TECO -> 'Completed'  (hijau #2e7d32)
   semua REL  -> 'Pending'    (row bg #fff8e1, teks #9a6700)
   lainnya    -> 'Review'     (row bg #fbf1f1, teks #b03636)
Result (mode Transaksi / RB1):
   L_ERR > 0    -> 'Review'   (merah)
   P_TEST = 'X' -> 'Test Run' (row bg #eef5fb, teks #1f5f8b)
   lainnya      -> 'OK'       (hijau #2e7d32)
```

### 5.5 Mapping ZMAP_TYPE — ORDER TYPE (109 record, masih AKTIF dipakai)
Key: `TCODE + PROG + TYPE + OPT + VALUE`; tabel **cross-client** (tanpa MANDT).
`PROG = 'ZPPI_COHVPI'`, `TYPE = 'ORDER TYPE'`, `OPT` = nama grup, `VALUE` = kode order type.

```
JR (31)          ZP01 ZP02 ZP03 ZP04 ZP05 ZP06 ZP07 ZP08 ZP09 ZP10 ZP11 ZP12 ZP13
                 ZP14 ZP15 ZP16 ZP17 ZP18 ZTR1 ZTR2 ZTR3 ZTR4 ZTR5 ZTR6 ZTR7 ZTR8
                 ZTR9 ZTRA ZTRB ZTRC ZTRD
SR COMBINE (18)  ZCA1 ZCA2 ZCB1 ZCB2 ZCC2 ZCD2 ZCE2 ZCL1 ZCL2 ZCP2 ZCR2 ZCS2 ZCT2
                 ZCX2 ZCZ1 ZCZ2 ZTC1 ZTC2
SR ORIGINAL (28) TPA1 TPA2 TPT2 TPZ1 TPZ2 ZPE2 ZPL1 ZPL2 ZPP1 ZPP2 ZPR2 ZPS2 ZPX2
                 ZTO1 ZTO2 ZPB1 ZPB2 CPE2 CPP2 CPZ2 BPZ1 BPZ2 EPZ2 PPA1 PPA2 PPT2
                 PPZ1 PPZ2
OTHERS (32)      ZM11 ZM13 ZM14 ZM16 ZM1C ZM21 ZM22 ZM23 ZM24 ZM25 ZM26 ZM27 ZM28
                 ZM29 ZM2A ZM2B ZM2C ZMM1 ZMMS ZAD1 ZAD2 ZBS1 ZBS2 ZRR1 ZRR2 ZR01
                 ZR02 ZP90 ZP91 ZP92 ZP93 ZP99
```
> Catatan: 16 record `TYPE = 'EMAIL TEXT'` **masih ada di tabel** tapi sudah **tidak dibaca** program. Perlu keputusan: dihapus atau dibiarkan.

### 5.6 Fakta teknis penting lain
- `BAPI_PROCORD_COMPLETE_TECH` **tidak punya parameter TEST**; commit di work-process terpisah ⇒ `BAPI_TRANSACTION_ROLLBACK` tidak reliable (sudah dikonfirmasi user via test manual). Karena itu Test Run diimplementasi tanpa memanggil BAPI.
- `AFPO-MILL_OC_AUFNR_U` ada di order **SR COMBINE** dan menunjuk ke order **SR ORIGINAL** (terverifikasi data DEV nyata). Field ini **tidak punya index** ⇒ full scan; user memilih dibiarkan.
- Status code (TJ02T): REL=`I0002`, TECO=`I0045`, CLSD=`I0046`, DLFL=`I0076`, LKD=`I0043`.
- Index terverifikasi: `MKPF~BUD` (MANDT+BUDAT+MBLNR) aktif; join MSEG/AUFK/AFPO/AFKO/MAKT lewat PK.
- Push program: gunakan `Z_RFC_PROGRAM_UPDATE` (`IV_PROGRAM_NAME`, `IV_PACKAGE='$TMP'`, `IV_CORRNUMBER=' '`, `IT_SOURCE`). Bootstrap kompleks: `RFC_ABAP_INSTALL_AND_RUN` (**max 72 char/baris**).
- ⚠️ Anchor bug yang pernah terjadi: `'FORM SEND_EMAIL.'` juga cocok dengan `'PERFORM SEND_EMAIL.'`. Selalu pakai anchor `'\nFORM X.\n'` atau `T-LINE(n) = 'FORM X.'` offset 0.

### 5.7 Aset yang sudah tersedia di folder proyek
```
C:\Users\Lenovo\Claude\Projects\SAP ABAP Consultant\
  email_preview_mode_transaksi.png   <- screenshot email mode Transaksi (1096x639)
  email_preview_mode_report.png      <- screenshot email mode Report   (1096x639)
  m1.html / m2.html                  <- source HTML kedua screenshot
  FS_Auto_TECO_ZPPI_COHVPI_v4.docx   <- FS v4 (SUPERSEDED: masih ada bab mapping email)
```
File lokal `ZPPI_COHVPI_fixed.txt` (1550 baris) **STALE** vs server (1602). **Jangan dipakai untuk full push.**

## 6. LANGKAH SEGERA BERIKUTNYA
- [ ] Tulis ulang helper docx-js di `/tmp/fs5/build.js` (`p, h1, h2, cell, table, hdr, row, banner, card, flow, sp`; lebar halaman `W = 9000` DXA). `npm install docx` sudah selesai di `/tmp/fs5`.
- [ ] Rakit **`FunctSpec_Auto_TECO_Closing_ZPPI_COHVPI_v5.docx`** dengan struktur:
  1. Ringkasan Non-Teknis (pertahankan teks user)
  2. Dua Mode Penggunaan (Transaksi TECO vs Report TECO) + diagram alur masing-masing
  3. Order yang Di-TECO — 4 card grup (JR / SR COMBINE / SR ORIGINAL / OTHERS, urutan sesuai edit user) + 3.1 Movement Type + 3.2 Status Order + **3.3 Aturan Mapping ZMAP_TYPE (baru)**
  4. Bagaimana Jika Gagal + penjelasan Test Run
  5. Hubungan dengan Closing
  6. Contoh Kendala Umum
  7. Layar Seleksi & Variant TECO (**tulis ulang total**, lihat §5.2)
  8. **Email Hasil & Lampiran (BARU)** — sisipkan 2 screenshot via `ImageRun` (`type:"png"`, `transformation:{width:600,height:350}`), jelaskan tabel ringkasan (§5.4) + lampiran Excel per grup
  9. Kriteria Sukses UAT
  10. Rencana Pengembangan
  11. Open Items
- [ ] Terapkan semua koreksi fakta di §5.1.
- [ ] Pertahankan seluruh edit redaksional user (deskripsi SR Combine "membatasi batch yang terbentuk", SR Original "mengikuti status Order Combine", 901/902 = "Pemakaian bahan baku order trial", ZMMS/ZM2C di OTHERS, Open Items tinggal 3 poin).
- [ ] Simpan ke `C:\Users\Lenovo\Claude\Projects\SAP ABAP Consultant\` lalu present ke user.

### Backlog terbuka (di luar FS)
- [ ] **Bug:** kolom "Hasil" menandai order yang di-*skip* (bukan REL) sebagai `OK`, sama seperti yang benar-benar sukses. Perlu nilai terpisah, mis. `Skipped`.
- [ ] Sinkronkan salinan lokal program (1550) dengan server (1602) — atau hapus salinan lokal agar tidak salah pakai.
- [ ] Putuskan nasib 16 record `ZMAP_TYPE TYPE='EMAIL TEXT'` yang sudah yatim.
- [ ] Klarifikasi ke user: apakah benar ada sistem sandbox TRS terpisah? Config `sap-servers.json` menyesatkan (lihat memory `sap_server_alias_sandbox_equals_dev`).

# Peta Output Type → Driver Print & Logic Last Price (KAPPL='EF')

## 1. Mapping NAST (output type) → driver PDF
Dibaca dari TNAPR (KAPPL='EF'). Yang relevan (driver cetak PO):

| KSCHL | Driver / SmartForm | Company | Tipe | Logic last price |
|---|---|---|---|---|
| Z01 | ZMMF_PO_LOCAL (FONAM klasik) | umum | Local (lama) | **SIMPLE** (beda) |
| Z03 | ZMMF_PO_LOCAL_PDF | umum | Local | NETPR-override |
| Z04 | ZMMF_PO_IMPORT_PDF | umum | Import | NETPR-override |
| Z05 | ZMMF_UNG_PO_LOCAL_PDF | UNG | Local | NETPR-override |
| Z06 | ZMMF_UNG_PO_IMPORT_PDF | UNG | Import | NETPR-override |
| Z07 | ZMMF_TTA_PO_LOCAL_PDF | TTA | Local | NETPR-override |
| Z08 | ZMMF_TTA_PO_IMPORT_PDF | TTA | Import | NETPR-override |
| Z09 | ZMMF_TTE_PO_LOCAL_PDF | TTE | Local | NETPR-override |
| Z10 | ZMMF_TTE_PO_IMPORT_PDF | TTE | Import | NETPR-override |

(KSCHL non-PO seperti NEU/AUFB/MAHN/ET01/WEZL pakai MEDRUCK/label/RSNASTED — bukan cetak PO, abaikan.)

## 2. Cara report tahu tipe PO (per PO)
Dua opsi (report punya `LS_EKKO`):
- **Output type (paling akurat):** baca `NAST` (KAPPL='EF', OBJKY=EBELN, VSTAT terbaru) → KSCHL. Petakan via tabel di atas.
- **EKORG (paling praktis, sudah ada):** contoh TTE → `LTTE`=Local (Z09), `ITTE`=Import (Z10). (Pola sama utuk TTA/UNG bila dipakai.)

## 3. TEMUAN PENTING — logic last price SAMA untuk semua *_PDF (Z03–Z10)
Diverifikasi (signature + diff blok): **Z03 s/d Z10 memakai algoritma last price yang IDENTIK.**
Beda LOCAL vs IMPORT hanya:
- LOCAL: WAERS diambil dari `SELECT SINGLE KBETR WAERS` (KONV) PO acuan.
- IMPORT: WAERS diambil dari `A~WAERS` (EKKO) PO acuan.
→ nilainya praktis sama; hasil akhir identik.

Algoritma bersama (semua *_PDF):
1. Batch khusus material RPV/RPC/RPM (mtart ZRAW) → pakai CHARG.
2. PO acuan = **KNUMV tertinggi** (EBELN<current, FRGZU='X', LOEKZ='') → sumber **WAERS**.
3. **KBETR = EKPO-NETPR** PO acuan **EBELN tertinggi** (`ORDER BY EBELN ASC`).
4. Konversi 2-hop via IDR pakai kurs **SY-DATUM** + `CURRENCY_AMOUNT_SAP_TO_DISPLAY`.

**Konsekuensi:** cukup **SATU** `F_GET_LPRINT` (versi NETPR-override yang sudah diuji → PO 4518000081 = **6.672.300,22** = print) untuk mencocokkan **SEMUA** PO yang dicetak via driver *_PDF (Z03–Z10), local maupun import, semua company (umum/UNG/TTA/TTE).

## 4. Pengecualian: Z01 (ZMMF_PO_LOCAL klasik)
Driver lama Z01 pakai include `ZMMF_PO_LOCAL_F01` dgn logic **SIMPLE**:
- PO acuan KNUMV tertinggi → **KBETR (PB00/PBXX)** langsung (TANPA override NETPR) → konversi 2-hop.
- Untuk PO 4518000081 logic ini menghasilkan **3.085.980** (bukan 6.672.300,22).

Jadi HANYA jika masih ada PO aktif yang output type-nya **Z01**, report perlu cabang terpisah. Cek pemakaian Z01: `SELECT ... FROM NAST WHERE KAPPL='EF' AND KSCHL='Z01'`. Kalau sudah tidak dipakai → abaikan.

## 5. Rekomendasi implementasi di uint report (ZMMI_PO_EMAIL, inline, tanpa function)
- Pakai **satu** `F_GET_LPRINT` = versi NETPR-override (file `IMPL_LASTPRICE_match_TTE.md`). Ini otomatis cocok semua PO cetakan *_PDF.
- Opsional (kalau Z01 masih dipakai): tambahkan cabang di awal F_GET_LPRINT —
  baca output type PO; jika `KSCHL='Z01'` jalankan logic SIMPLE (ambil KBETR PB00/PBXX, tanpa override NETPR), selain itu jalankan logic NETPR-override.
- Deteksi tipe cukup pakai `LS_EKKO-EKORG` atau baca NAST-KSCHL bila mau presisi penuh.

## 6. Verifikasi
1. PO local TTE (Z09) 4518000081 → 6.672.300,22 (sudah cocok, diuji live).
2. Ambil 1 PO import (Z10/Z04) & 1 UNG/TTA → jalankan F_GET_LPRINT, bandingkan reprint.
3. Bila ada PO Z01 → uji cabang simple.

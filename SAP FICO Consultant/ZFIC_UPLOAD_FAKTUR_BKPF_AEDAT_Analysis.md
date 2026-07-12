# Analisis: BKPF-AEDAT (Changed On) Tidak Terupdate — ZFIC_UPLOAD_FAKTUR

**Program**: ZFIC_UPLOAD_FAKTUR
**TCODE**: ZFI106
**Server**: Development AIX (TRD)
**Tanggal analisis**: 2026-07-09
**Untuk**: SAP ABAP Developer

---

## 1. Ringkasan Masalah

Program `ZFIC_UPLOAD_FAKTUR` mengupdate field `BKPF-XBLNR` (nomor faktur pajak) melalui FM standar `CHANGE_DOCUMENT`, tetapi field `BKPF-AEDAT` ("Date of the Last Document Change by Transaction") tidak ikut terupdate setelah proses selesai.

## 2. Lokasi Kode Bermasalah

FORM `EXECUTION`:

```abap
FORM EXECUTION.
  LOOP AT ITAB WHERE BOX = 'X' AND ERR = ''.
    REFRESH: IT_BKPF.

    SELECT * FROM BKPF INTO TABLE IT_BKPF
      WHERE BUKRS = ITAB-BUKRS
        AND BELNR = ITAB-BELNR
        AND GJAHR = ITAB-GJAHR.

    LOOP AT IT_BKPF.
      IT_BKPF-XBLNR = ITAB-FAKTUR+1(16).
      MODIFY IT_BKPF.
    ENDLOOP.

    CALL FUNCTION 'CHANGE_DOCUMENT'
      TABLES
        T_BKDF = IT_BKDF
        T_BKPF = IT_BKPF
        T_BSEC = IT_BSEC
        T_BSED = IT_BSED
        T_BSEG = IT_BSEG
        T_BSET = IT_BSET
      EXCEPTIONS
        OTHERS = 1.

    IF SY-SUBRC EQ 0.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          WAIT = 'X'.
      ...
```

## 3. Root Cause

1. Program membaca record `BKPF` existing via `SELECT *`, lalu **hanya mengubah field `XBLNR`** pada internal table `IT_BKPF`. Field `AEDAT` ikut terbawa dari hasil SELECT tapi nilainya **tidak pernah diubah** sebelum dikirim ke FM.
2. FM `CHANGE_DOCUMENT` (function group F040) adalah FM level rendah yang murni mengupdate field yang **berbeda** antara data lama dan data yang dikirim, serta mencatat change document. FM ini **tidak otomatis men-stamp `AEDAT = SY-DATUM`** — itu tanggung jawab program pemanggil.
3. Transaksi standar FB02 (via include `SAPMF05A` / `FI_DOCUMENT_CHANGE`) secara eksplisit set `BKPF-AEDAT = SY-DATUM` sebelum memanggil FM level rendah ini. `ZFIC_UPLOAD_FAKTUR` tidak melakukan langkah tersebut.
4. Confirm: data element `AEDAT_BKPF` = *"Date of the Last Document Change by Transaction"* (DD04T, EN).

## 4. Gap Tambahan yang Perlu Diperiksa

- **CDHDR/CDPOS (Change Document, `OBJECTCLAS = 'BELEG'`)** — tabel audit trail yang muncul di FB03 → *Environment → Document Changes* (mencatat user, tanggal, jam, field, nilai lama→baru, tcode). Interface FM `CHANGE_DOCUMENT` yang dipakai hanya menerima satu versi tabel (`T_BKPF`), tanpa pasangan old/new eksplisit — kemungkinan besar perubahan XBLNR **tidak tercatat** di CDHDR/CDPOS. BKPF sendiri tidak punya field "changed by"/"changed time"; jejak itu hanya ada di CDHDR.
- Jika dibutuhkan audit trail lengkap, perlu generate change document eksplisit: `CHANGEDOCUMENT_OPEN` → `CHANGEDOCUMENT_SINGLE_CASE` → `CHANGEDOCUMENT_CLOSE` (object `BELEG`).

## 5. Field yang JANGAN Diubah

Field berikut merepresentasikan histori *pembuatan* dokumen (bukan perubahan) — jangan disentuh:

| Field | Keterangan |
|---|---|
| `CPUDT` / `CPUTM` | Tanggal/jam entry (posting asli) |
| `USNAM` | User yang membuat dokumen |
| `TCODE` | Transaksi saat dokumen dibuat |
| `UPDDT` | "Date of the Last Document Update" — semantik berbeda dari AEDAT, konteks pemakaian spesifik (bukan general changed-on) |

## 6. Rekomendasi Fix

Tambahkan 1 baris di FORM `EXECUTION`, sebelum `MODIFY IT_BKPF`:

```abap
LOOP AT IT_BKPF.
  IT_BKPF-XBLNR = ITAB-FAKTUR+1(16).
  IT_BKPF-AEDAT = SY-DATUM.        "<-- tambahan
  MODIFY IT_BKPF.
ENDLOOP.
```

**Opsional (jika audit trail FB03 wajib)**: tambahkan pemanggilan change document object `BELEG` secara eksplisit setelah update berhasil, karena FM `CHANGE_DOCUMENT` yang dipakai saat ini kemungkinan tidak menghasilkan entry CDHDR/CDPOS secara otomatis.

## 7. Langkah Verifikasi Setelah Fix

1. Transport fix ke Development, test upload 1 dokumen faktur.
2. Cek `BKPF-AEDAT` via SE16N — harus sama dengan tanggal eksekusi.
3. Cek FB03 → *Environment → Document Changes* — pastikan perubahan XBLNR tercatat (jika opsi CDHDR/CDPOS di poin 6 diimplementasikan).
4. Regression test: pastikan field lain (`CPUDT`, `CPUTM`, `USNAM`, `TCODE`) tidak berubah.

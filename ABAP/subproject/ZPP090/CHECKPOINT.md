# CHECKPOINT — ZPP090 (ZPPI_CHANGE_JR_NUMBER)

**Status:** Analisis Akar Masalah & Live Testing Terverifikasi
**Tanggal:** 2026-09-22
**TCODE:** `ZPP090`
**Program Utama:** `ZPPI_CHANGE_JR_NUMBER`
**Tabel Terkait:** `ZSEQNUM` (Master Counter Sequence JR), `ZLOG_JRNO` (Audit Log Perubahan)

---

## 1. Latar Belakang Masalah

Pada mesin **CPP 1** (`JRCPP01`), kode line pada nomor roll memiliki panjang **2 digit/karakter** (yaitu `P1`, contoh aktual di `MKPF-BKTXT`: `P1 VAX 072 009` atau `P1 VAX 096 340`).
Sedangkan pada kebanyakan line lain (BOPP, BOPET, dll.), kode line hanya **1 digit/karakter** (contoh: `7 W1B 096 039`, `6 AB3 072 001`, `1 ALR 112 001`).

Program `ZPPI_CHANGE_JR_NUMBER` memiliki asumsi hardcoded offset substring `+6(2)` dan `+10(3)` pada parameter `P_ROLJR` yang **hanya cocok untuk line 1 digit**. Akibatnya, setiap pemunduran nomor roll untuk line CPP (2 digit) **pasti gagal** dengan error:
> *"Tidak bisa change selain bulan sekarang..!"*

---

## 2. Analisis Kode Sumber & Akar Masalah (Root Cause)

Di dalam include / FORM `VALIDASI_UPDATE_JR`:

```abap
193:  SPLIT P_ROLJR AT ' ' INTO V_LINE V_CODE V_DATE V_SQNO.
...
252:  "Cek bulan mundur JR harus sama dengan bulan sekarang
253:  READ TABLE ITAB INDEX 1.
254:  IF ITAB-ZMONTH NE SY-DATUM+4(2) OR P_ROLJR+6(2) NE SY-DATUM+4(2).
255:    MESSAGE 'Tidak bisa change selain bulan sekarang..!' TYPE 'I'.
256:    LEAVE TO SCREEN 0.
257:  ENDIF.
258:
259:  "Cek sequence 1, untuk tidak memundurkan sequence 0
260:  IF ITAB-ZSEQNO EQ 1 OR P_ROLJR+10(3) EQ 001.
261:    MESSAGE 'Mundur JR number maksimal 001, tidak dapat mereset ke 000..!' TYPE 'I'.
262:    LEAVE TO SCREEN 0.
263:  ENDIF.
```

### Bedah Offset Karakter `P_ROLJR`:

| Line Type | Contoh `P_ROLJR` | `V_LINE` (Pos 0) | `V_CODE` | `V_DATE` | `P_ROLJR+6(2)` | Status Baris 254 | `P_ROLJR+10(3)` |
|---|---|---|---|---|---|---|---|
| **1 Digit (BOPP 7)** | `7 W1B 096 039` | `7` (1 char) | `W1B` | `096` | `'09'` (Pos 6..7) | **PASS** (cocok dengan bulan berjalan `09`) | `'039'` (Pos 10..12) |
| **2 Digit (CPP 1)** | `P1 VAX 096 340` | `P1` (2 char) | `VAX` | `096` | `' 0'` (Pos 6..7 = spasi & nol) | **REJECTED** (`' 0' NE '09'`) -> Error Bulan | `' 34'` (Pos 10..12 = spasi & 34) |

### Dampak Fatal:
1. **Baris 254:** `P_ROLJR+6(2)` mengambil karakter ke-7 dan ke-8 (index 6 dan 7). Karena line `P1` menambah 1 karakter di depan, posisi index 6 adalah karakter spasi `' '`, dan index 7 adalah `'0'`. Nilai `' 0'` tidak pernah sama dengan bulan berjalan `SY-DATUM+4(2)` (`'09'`). Program langsung exit via `LEAVE TO SCREEN 0`.
2. **Baris 260:** `P_ROLJR+10(3)` membaca index 10 (spasi) dan sequence tergeser 1 digit (`' 34'`). Jika nomor roll adalah `001`, kondisi `P_ROLJR+10(3) EQ 001` tidak akan pernah match karena bernilai `' 00'`.

---

## 3. Bukti Live Testing Eksekusi di SAP TRS (Sandbox New Company)

Eksekusi bootstrap via `RFC_ABAP_INSTALL_AND_RUN` membuktikan perbedaan hasil evaluasi antara logika lama vs perbaikan dinamis:

```text
INPUT: 7 W1B 096 039 (Line 1 Digit)
 [OLD Line 254] PASSED Month: 09
 [NEW Line 254] PASSED Month: 09
 [OLD Line 260] SEQ=1 NO MATCH: 039
 [NEW Line 260] SEQ=1 NO MATCH: 039

INPUT: P1 VAX 096 340 (Line 2 Digit - Kasus CPP 1)
 [OLD Line 254] REJECTED Month:  0  <-- GAGAL (Membaca spasi dan nol)
 [NEW Line 254] PASSED Month: 09   <-- SUKSES (Menggunakan V_DATE(2))
 [OLD Line 260] SEQ=1 NO MATCH:  34 <-- TERGESER (Offset +10(3) membaca spasi 34)
 [NEW Line 260] SEQ=1 NO MATCH: 340 <-- AKURAT (Menggunakan V_SQNO)

INPUT: P1 VAX 096 001 (Line 2 Digit - Kasus Sequence 1)
 [OLD Line 254] REJECTED Month:  0
 [NEW Line 254] PASSED Month: 09
 [OLD Line 260] SEQ=1 NO MATCH:  00 <-- GAGAL mendeteksi sequence 001
 [NEW Line 260] SEQ=1 MATCH: 001   <-- SUKSES mendeteksi sequence 001
```

---

## 4. Solusi Perbaikan (Zero Scope Creep & Minimal Diff)

Karena pada baris 193 sudah dilakukan:
```abap
SPLIT P_ROLJR AT ' ' INTO V_LINE V_CODE V_DATE V_SQNO.
```
Variabel `V_DATE` dan `V_SQNO` sudah memegang segmen tanggal dan sequence secara independen dari panjang karakter `V_LINE`.

### Perbaikan final dengan scope minimal:
- **Baris 254:** Ganti `P_ROLJR+6(2)` menjadi `V_DATE+0(2)`.
- **Baris 260:** Ganti `P_ROLJR+10(3)` menjadi `V_SQNO` agar validasi
  batas `001` juga tidak bergantung pada panjang production line.

### Deployment sandbox-new:
- Target: Sandbox New Company (`192.168.6.243`).
- `Z_RFC_PROGRAM_UPDATE`: `EV_SUCCESS = 'X'`.
- Read-back source SAP identik dengan source lokal.
- `SYNTAX-CHECK`: PASS.
- Test line satu digit: PASS.
- Test CPP line dua digit: PASS.
- Test batas sequence `001` untuk line satu digit: PASS.
- Test batas sequence `001` untuk CPP: PASS.
- Audit seluruh source: tidak ada lagi fixed offset `P_ROLJR+...`.
- `ZSEQNUM-JRCPP01` sebelum dan sesudah test tidak berubah.

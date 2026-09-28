# Rancangan Implementasi — Last Price Report SAMA PERSIS dgn Print PO

## Masalah (fakta by data, PO 4518000081, material SRCBCO, WAERS IDR)
- **Report** Last Price = **3.085.980,00** = PO acuan KNUMV tertinggi **4503000427** (KBETR **150 EUR**) × kurs EUR→IDR 20.573,2.
- **Print** Last Prc = **6.672.300,22** = **324,32 × 20.573,2** (kurs EUR). 324,32 = KBETR PO IDR (mis. 4518000080) / harga unit current.
- Kandidat PO acuan (urut KNUMV desc): 4503000427 (150 EUR) → 4503000410 (150 EUR) → 4512000153 (20 IDR) → 4518000080 (324,32 IDR) → dst.

## Akar beda
Di blok last-price print (`ZMMF_PO_LOCAL_F01`, FORM `F_FIND_ITEM_DATA`):
```abap
SELECT SINGLE KBETR WAERS INTO (LC_KBETR, IT_KONV_LAST-WAERS) FROM KONV
  WHERE KNUMV = ... AND KPOSN = ... AND ( KSCHL = 'PB00' OR KSCHL = 'PBXX' ).
```
`SELECT SINGLE` + kondisi `OR` **tanpa ORDER BY** = **non-deterministic** jika ada >1 baris kondisi (PB00 dan PBXX) pada PO acuan. DB bisa balikin baris berbeda antar-run/antar-sistem → KBETR/WAERS beda → hasil beda. Report ambil 150 EUR; print (kemungkinan) ambil baris 324,32 dgn WAERS EUR → dikali kurs EUR → 6.672.300,22.

> Perlu 1 konfirmasi data (jalankan saat SAP normal): list semua baris KONV `KNUMV=1000025530 KPOSN=000010` — cek apakah ada PB00 (150 EUR) DAN PBXX (324,32 / WAERS EUR). Ini yang bikin print & report ambil beda.

## Solusi definitif: SATU sumber logic (dipakai print & report)
Supaya **report == print dijamin by construction** (bukan tebak angka): ekstrak blok last-price print ke **1 Function Module**, panggil dari KEDUA program.

### 1. Buat Function Module `Z_MM_GET_LAST_PRICE`
Import:
- `IV_MATNR TYPE MATNR`
- `IV_EBELN TYPE EBELN` (PO current)
- `IV_WAERS TYPE WAERS` (currency PO current)
- `IV_DATUM TYPE SY-DATUM` (default SY-DATUM)

Export:
- `EV_LAST_PRICE TYPE P DECIMALS 2`
- `EV_WAERS TYPE WAERS`

Body (PERSIS logic print + **1 perbaikan determinisme**: pilih PB00 dulu, baru PBXX, deterministik):
```abap
FUNCTION Z_MM_GET_LAST_PRICE.
  DATA: LV_KNUMV TYPE KONV-KNUMV,
        LV_KPOSN TYPE KONV-KPOSN,
        LV_LW    TYPE KONV-WAERS,
        LC_KBETR TYPE KONV-KBETR,
        LV_KURS  TYPE RKB1K-EXCHR,
        LV_NEW   TYPE WMTO_S-AMOUNT.

  CLEAR: EV_LAST_PRICE, EV_WAERS.
  CLEAR: LV_KNUMV, LV_KPOSN.

* PO acuan: KNUMV tertinggi (SELECT..ENDSELECT ORDER BY ASC = baris terakhir)
  SELECT A~KNUMV B~EBELP INTO (LV_KNUMV, LV_KPOSN)
    FROM EKKO AS A INNER JOIN EKPO AS B ON B~EBELN = A~EBELN
    WHERE B~MATNR = IV_MATNR
      AND B~LOEKZ = SPACE
      AND A~EBELN < IV_EBELN
      AND A~FRGZU = 'X'
    ORDER BY A~KNUMV ASCENDING.
  ENDSELECT.
  IF SY-SUBRC NE 0.
    RETURN.
  ENDIF.

* KBETR base price. DETERMINISTIK: coba PB00 dulu, fallback PBXX.
  CLEAR: LC_KBETR, LV_LW.
  SELECT SINGLE KBETR WAERS INTO (LC_KBETR, LV_LW)
    FROM KONV WHERE KNUMV = LV_KNUMV AND KPOSN = LV_KPOSN AND KSCHL = 'PB00'.
  IF SY-SUBRC NE 0.
    SELECT SINGLE KBETR WAERS INTO (LC_KBETR, LV_LW)
      FROM KONV WHERE KNUMV = LV_KNUMV AND KPOSN = LV_KPOSN AND KSCHL = 'PBXX'.
    IF SY-SUBRC NE 0.
      RETURN.
    ENDIF.
  ENDIF.

* Konversi 2-hop via IDR pakai kurs IV_DATUM (persis print)
  CLEAR: LV_KURS, LV_NEW.
  IF IV_WAERS NE LV_LW.
    IF LV_LW EQ 'IDR'.
      LC_KBETR = LC_KBETR.
    ELSE.
      CALL FUNCTION 'RKC_SINGLE_EXCHANGE_RATE_GET'
        EXPORTING DATUM = IV_DATUM KURST = 'M' NCURR = 'IDR' VCURR = LV_LW
        IMPORTING EXCHR = LV_KURS
        EXCEPTIONS NO_RATE_FOUND = 1 OTHERS = 2.
      LC_KBETR = LC_KBETR * LV_KURS.
    ENDIF.
    LV_NEW = LC_KBETR.
    CALL FUNCTION 'CURRENCY_AMOUNT_SAP_TO_DISPLAY'
      EXPORTING CURRENCY = LV_LW AMOUNT_INTERNAL = LV_NEW
      IMPORTING AMOUNT_DISPLAY = LV_NEW.
    LC_KBETR = LV_NEW.
    IF IV_WAERS EQ 'IDR'.
      LC_KBETR = LC_KBETR.
    ELSE.
      CALL FUNCTION 'RKC_SINGLE_EXCHANGE_RATE_GET'
        EXPORTING DATUM = IV_DATUM KURST = 'M' NCURR = 'IDR' VCURR = IV_WAERS
        IMPORTING EXCHR = LV_KURS
        EXCEPTIONS NO_RATE_FOUND = 1 OTHERS = 2.
      LC_KBETR = LC_KBETR * 1 / LV_KURS.
    ENDIF.
  ELSE.
    LV_NEW = LC_KBETR.
    CALL FUNCTION 'CURRENCY_AMOUNT_SAP_TO_DISPLAY'
      EXPORTING CURRENCY = LV_LW AMOUNT_INTERNAL = LV_NEW
      IMPORTING AMOUNT_DISPLAY = LV_NEW.
    LC_KBETR = LV_NEW.
  ENDIF.

  EV_LAST_PRICE = LC_KBETR.
  EV_WAERS      = LV_LW.
ENDFUNCTION.
```

### 2. Ubah PRINT (`ZMMF_PO_LOCAL_F01`, blok "find last price by material")
Ganti seluruh blok SELECT KNUMV + SELECT SINGLE KBETR + konversi dgn:
```abap
DATA LV_LP TYPE P DECIMALS 2.
DATA LV_LPW TYPE WAERS.
CALL FUNCTION 'Z_MM_GET_LAST_PRICE'
  EXPORTING IV_MATNR = IT_PO-MATNR
            IV_EBELN = IT_PO-EBELN
            IV_WAERS = IT_PO-WAERS
            IV_DATUM = SY-DATUM
  IMPORTING EV_LAST_PRICE = LV_LP
            EV_WAERS      = LV_LPW.
WRITE LV_LP TO I_ZPO_LOCAL-ZLASTPRICE.
```

### 3. Ubah REPORT (`ZMMI_PO_EMAIL`, FORM F_GET_LPRINT)
Isi F_GET_LPRINT cukup panggil FM yang sama:
```abap
FORM F_GET_LPRINT USING P_MATNR TYPE MATNR
                        P_EBELN TYPE EBELN
                        P_WAERS TYPE WAERS
                  CHANGING P_LAST_PRICE TYPE P.
  DATA LV_LPW TYPE WAERS.
  CLEAR P_LAST_PRICE.
  CALL FUNCTION 'Z_MM_GET_LAST_PRICE'
    EXPORTING IV_MATNR = P_MATNR
              IV_EBELN = P_EBELN
              IV_WAERS = P_WAERS
              IV_DATUM = SY-DATUM
    IMPORTING EV_LAST_PRICE = P_LAST_PRICE
              EV_WAERS      = LV_LPW.
ENDFORM.
```
Call-site di item-loop tetap: `IF P_RPT EQ 'X'. PERFORM F_GET_LPRINT ... . ENDIF.`

## Hasil
- Print & report **panggil FM sama** → **angka Last Price identik selamanya**, apa pun kuirk-nya. "Samakan hasilnya" tercapai by construction.
- Perbaikan `PB00 dulu, fallback PBXX` menghilangkan non-determinisme `SELECT SINGLE` → nilai stabil (tidak beda-beda antar-run).

## CATATAN PENTING sebelum eksekusi
1. **Konfirmasi angka target.** Kalau yang "benar" menurut Baginda = **6.672.300,22**, jalankan dulu cek baris KONV `KNUMV=1000025530 KPOSN=000010`. Kalau print ambil PBXX/EUR 324,32, sesuaikan urutan pemilihan KSCHL di FM (mis. PBXX dulu) supaya FM mereproduksi 6.672.300,22. Determinisme FM = kunci; tinggal set prioritas KSCHL sesuai yang Baginda mau.
2. **Server target:** channel `call_function` sekarang eksekusi di **DEV (TRD/eccdevlinux)**, bukan sandbox TRS. Pastikan sesuai izin sebelum tulis/aktivasi.
3. Panjang baris source ≤72 char kalau lewat RFC_ABAP_INSTALL_AND_RUN; ≤255 kalau lewat editor/Z_RFC_PROGRAM_UPDATE.

## Verifikasi
1. Aktivasi FM + kedua program bersih.
2. Jalankan report PO 4518000081 & reprint PO 4518000081 → kolom Last Price harus **sama angka**.
3. Uji 2-3 material lain (currency sama & beda).

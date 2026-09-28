# Rancangan — Last Price = Print PO, INLINE di ZMMI_PO_EMAIL (tanpa Function Module)

Semua di satu program `ZMMI_PO_EMAIL`. Tidak ada FM, tidak ubah program lain.
Logic Last Price = **replika PERSIS** blok print `ZMMF_PO_LOCAL_F01` (FORM F_FIND_ITEM_DATA), ditaruh di FORM `F_GET_LPRINT`.

## Perubahan 1 — call-site di item-loop (mode Report)
Di `START-OF-SELECTION`, item-loop `LOOP AT LT_EKPOD INTO LS_EKPOD`, blok kolom Last Price.

Ganti blok lama:
```abap
          IF P_RPT EQ 'X' AND LV_HASMAT EQ 'X'.
            PERFORM F_CALC_LAST_PRICE USING LS_LASTM
                                            LS_EKKO-WAERS
                                            LS_EKPOD-BPRME
                                   CHANGING LS_RESULT-LAST_PRICE.
          ENDIF.
```
Jadi:
```abap
*         Kolom Report: Last Price = replika PERSIS print PO (ZMMF_PO_LOCAL)
          IF P_RPT EQ 'X'.
            PERFORM F_GET_LPRINT USING LS_EKPOD-MATNR
                                       LS_EKKO-EBELN
                                       LS_EKKO-WAERS
                                 CHANGING LS_RESULT-LAST_PRICE.
          ENDIF.
```
(`PERFORM F_GET_LAST ... CHANGING LS_LASTM LV_HASMAT.` di atasnya dibiarkan — masih dipakai cek exception. `F_CALC_LAST_PRICE` jadi tak terpakai, boleh dibiarkan.)

## Perubahan 2 — FORM F_GET_LPRINT (inline, tiru print PERSIS)
Sisipkan sebelum `FORM F_CHK_NAIK`. SELECT KBETR memakai bentuk **sama persis print** (`PB00 OR PBXX`) supaya baris yang diambil sama dengan print:
```abap
*&---------------------------------------------------------------*
*& Form F_GET_LPRINT -- Last Price tiru PERSIS print (ZMMF_PO_LOCAL)
*&   1. PO acuan: material sama, released, EBELN<current, KNUMV tertinggi
*&   2. KBETR (PB00/PBXX) dari KONV PO acuan
*&   3. Konversi 2-hop via IDR kurs SY-DATUM + CURRENCY_AMOUNT_SAP_TO_DISPLAY
*&---------------------------------------------------------------*
FORM F_GET_LPRINT USING P_MATNR TYPE MATNR
                        P_EBELN TYPE EBELN
                        P_WAERS TYPE WAERS
                  CHANGING P_LAST_PRICE TYPE P.
  DATA: LV_KNUMV  TYPE KONV-KNUMV,
        LV_KPOSN  TYPE KONV-KPOSN,
        LV_LW     TYPE KONV-WAERS,
        LC_KBETR  TYPE KONV-KBETR,
        LV_KURS   TYPE RKB1K-EXCHR,
        LV_NEW    TYPE WMTO_S-AMOUNT.

  CLEAR P_LAST_PRICE.
  CLEAR: LV_KNUMV, LV_KPOSN.

  SELECT A~KNUMV B~EBELP INTO (LV_KNUMV, LV_KPOSN)
    FROM EKKO AS A INNER JOIN EKPO AS B ON B~EBELN = A~EBELN
    WHERE B~MATNR = P_MATNR
      AND B~LOEKZ = SPACE
      AND A~EBELN < P_EBELN
      AND A~FRGZU = 'X'
    ORDER BY A~KNUMV ASCENDING.
  ENDSELECT.
  IF SY-SUBRC NE 0.
    RETURN.
  ENDIF.

  CLEAR: LC_KBETR, LV_LW.
  SELECT SINGLE KBETR WAERS INTO (LC_KBETR, LV_LW)
    FROM KONV
    WHERE KNUMV = LV_KNUMV
      AND KPOSN = LV_KPOSN
      AND ( KSCHL = 'PB00' OR KSCHL = 'PBXX' ).
  IF SY-SUBRC NE 0.
    RETURN.
  ENDIF.

  CLEAR: LV_KURS, LV_NEW.
  IF P_WAERS NE LV_LW.
    IF LV_LW EQ 'IDR'.
      LC_KBETR = LC_KBETR.
    ELSE.
      CALL FUNCTION 'RKC_SINGLE_EXCHANGE_RATE_GET'
        EXPORTING DATUM = SY-DATUM KURST = 'M' NCURR = 'IDR' VCURR = LV_LW
        IMPORTING EXCHR = LV_KURS
        EXCEPTIONS NO_RATE_FOUND = 1 OTHERS = 2.
      LC_KBETR = LC_KBETR * LV_KURS.
    ENDIF.
    LV_NEW = LC_KBETR.
    CALL FUNCTION 'CURRENCY_AMOUNT_SAP_TO_DISPLAY'
      EXPORTING CURRENCY = LV_LW AMOUNT_INTERNAL = LV_NEW
      IMPORTING AMOUNT_DISPLAY = LV_NEW.
    LC_KBETR = LV_NEW.
    IF P_WAERS EQ 'IDR'.
      LC_KBETR = LC_KBETR.
    ELSE.
      CALL FUNCTION 'RKC_SINGLE_EXCHANGE_RATE_GET'
        EXPORTING DATUM = SY-DATUM KURST = 'M' NCURR = 'IDR' VCURR = P_WAERS
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

  P_LAST_PRICE = LC_KBETR.
ENDFORM.                    "F_GET_LPRINT
```

## TITIK KRUSIAL supaya angka = print (6.672.300,22)
Fakta uji: dgn PO acuan KNUMV tertinggi = 4503000427, `SELECT SINGLE ... (PB00 OR PBXX)` di run saya balik **PB00 = 150 EUR** → 3.085.980. Print keluar 6.672.300,22 = **324,32 × kurs EUR** → berarti print mengambil baris kondisi **lain** (kemungkinan **PBXX = 324,32 EUR**) pada PO acuan yang sama.

Karena `SELECT SINGLE` dgn `OR` tanpa ORDER = **non-deterministic**, hasil report bisa beda dgn print walau statement sama. Untuk mengunci agar SELALU = print, **1 langkah data wajib** (jalankan saat SAP normal):

Ambil semua baris KONV PO acuan:
```
KONV: KNUMV = 1000025530, KPOSN = 000010  -> list KSCHL, KBETR, WAERS
```
Lalu kunci pemilihan KSCHL di F_GET_LPRINT sesuai baris yang dipakai print:
- Jika print pakai **PBXX (324,32)** → ganti SELECT jadi ambil **PBXX dulu**, fallback PB00:
```abap
  SELECT SINGLE KBETR WAERS INTO (LC_KBETR, LV_LW)
    FROM KONV WHERE KNUMV = LV_KNUMV AND KPOSN = LV_KPOSN AND KSCHL = 'PBXX'.
  IF SY-SUBRC NE 0.
    SELECT SINGLE KBETR WAERS INTO (LC_KBETR, LV_LW)
      FROM KONV WHERE KNUMV = LV_KNUMV AND KPOSN = LV_KPOSN AND KSCHL = 'PB00'.
    IF SY-SUBRC NE 0.
      RETURN.
    ENDIF.
  ENDIF.
```
- Jika print pakai **PB00 (150)** → berarti print seharusnya 3.085.980 (screenshot lama), report sudah benar.

> Ringkas: struktur inline sudah final; yang menentukan angka = **baris KONV mana yang dipakai**. Kunci prioritas KSCHL = kunci kecocokan dgn print.

## Catatan push
- Semua dalam 1 program → push via `Z_RFC_PROGRAM_UPDATE` (ganti seluruh source) ATAU patcher `RFC_ABAP_INSTALL_AND_RUN` (READ REPORT → REPLACE/INSERT 2 perubahan → INSERT REPORT).
- Pastikan target server benar (call_function saat ini eksekusi di DEV/TRD — `SY-HOST=eccdevlinux`).
- Baris source ≤72 char kalau via RFC_ABAP_INSTALL_AND_RUN.

## Verifikasi
1. Aktivasi bersih.
2. Report PO 4518000081 vs reprint PO 4518000081 → Last Price sama angka.
3. Uji material lain (currency sama & beda).

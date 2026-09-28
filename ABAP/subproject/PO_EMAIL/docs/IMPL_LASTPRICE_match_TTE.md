# Rancangan FINAL — Last Price Report = Print PO (6.672.300,22)

## Root cause (TERBUKTI live di DEV, FINAL=6.672.300,22 = print)
Driver print PO 4518000081 = **`ZMMF_TTE_PO_LOCAL_PDF`** (output type Z09), BUKAN `ZMMF_PO_LOCAL`.
Logic last-price-nya (modif "Yulius") mencampur 2 PO acuan berbeda:
1. **WAERS** diambil dari `SELECT SINGLE KBETR WAERS` pada PO **KNUMV tertinggi** (mis. 4503000427 → **EUR**).
2. **KBETR ditimpa** `EKPO-NETPR` dari PO **EBELN tertinggi** (`ORDER BY EBELN ASCENDING` + ENDSELECT = baris terakhir = EBELN terbesar, mis. 4518000080 → NETPR **324,32**).
3. Karena WAERS = EUR (dari PO lain) & NETPR = 324,32, currency mismatch → 324,32 × kurs EUR→IDR (20.573,2) = **6.672.300,22**.

Ada juga cabang batch khusus material **RPV/RPC/RPM** (mtart ZRAW) yang pakai CHARG. Untuk material lain → cabang ELSE.

Uji live (RFC_ABAP_INSTALL_AND_RUN, dev): STEP1 WAERS=EUR, STEP2 NETPR=324,32, **FINAL=6.672.300,22**. Cocok print.

## Implementasi (INLINE di ZMMI_PO_EMAIL, tanpa function)

### Perubahan 1 — call-site item-loop (tambah kirim EBELP)
Ganti blok Last Price lama (`PERFORM F_CALC_LAST_PRICE ...`) jadi:
```abap
*         Kolom Report: Last Price = replika PERSIS driver print TTE
*         (ZMMF_TTE_PO_LOCAL_PDF): WAERS dari PO KNUMV tertinggi,
*         KBETR = NETPR PO EBELN tertinggi, konversi via IDR.
          IF P_RPT EQ 'X'.
            PERFORM F_GET_LPRINT USING LS_EKPOD-MATNR
                                       LS_EKKO-EBELN
                                       LS_EKPOD-EBELP
                                       LS_EKKO-WAERS
                                 CHANGING LS_RESULT-LAST_PRICE.
          ENDIF.
```

### Perubahan 2 — FORM F_GET_LPRINT (replika PERSIS driver TTE)
Sisipkan sebelum `FORM F_CHK_NAIK` (ganti versi F_GET_LPRINT sebelumnya bila sudah ada):
```abap
*&---------------------------------------------------------------*
*& Form F_GET_LPRINT -- Last Price replika PERSIS print PO
*&   (driver ZMMF_TTE_PO_LOCAL_PDF / output type Z09).
*&   Catatan: sengaja tiru perilaku driver (WAERS dari PO KNUMV
*&   tertinggi, KBETR = NETPR PO EBELN tertinggi) supaya angka
*&   SAMA PERSIS dengan hasil cetak PO.
*&---------------------------------------------------------------*
FORM F_GET_LPRINT USING P_MATNR TYPE MATNR
                        P_EBELN TYPE EBELN
                        P_EBELP TYPE EBELP
                        P_WAERS TYPE WAERS
                  CHANGING P_LAST_PRICE TYPE P.
  DATA: LV_KNUMV TYPE KONV-KNUMV,
        LV_KPOSN TYPE KONV-KPOSN,
        LV_LW    TYPE KONV-WAERS,
        LC_KBETR TYPE KONV-KBETR,
        LV_KURS  TYPE RKB1K-EXCHR,
        LV_NEW   TYPE WMTO_S-AMOUNT,
        LV_MTART TYPE MARA-MTART,
        LV_CHARG TYPE EKET-CHARG.

  CLEAR P_LAST_PRICE.
  CLEAR: LV_KNUMV, LV_KPOSN, LV_MTART, LV_CHARG.

* Batch hanya utk RPV/RPC/RPM (ZRAW), spt driver.
  IF P_MATNR = 'RPV' OR P_MATNR = 'RPC' OR P_MATNR = 'RPM'.
    SELECT SINGLE MTART INTO LV_MTART FROM MARA
      WHERE MATNR = P_MATNR AND MTART = 'ZRAW'.
    IF SY-SUBRC = 0.
      SELECT SINGLE CHARG INTO LV_CHARG FROM EKET
        WHERE EBELN = P_EBELN AND EBELP = P_EBELP.
    ENDIF.
  ENDIF.

* 1. PO acuan KNUMV tertinggi -> KNUMV/KPOSN (sumber WAERS).
  IF LV_CHARG IS NOT INITIAL.
    SELECT A~KNUMV B~EBELP INTO (LV_KNUMV, LV_KPOSN)
      FROM EKKO AS A JOIN EKPO AS B ON B~EBELN = A~EBELN
                     JOIN EKET AS C ON C~EBELN = B~EBELN
                          AND C~EBELP = B~EBELP AND C~CHARG = LV_CHARG
      WHERE B~MATNR = P_MATNR AND B~LOEKZ = SPACE
        AND A~EBELN < P_EBELN AND A~FRGZU = 'X'
      ORDER BY A~KNUMV ASCENDING.
    ENDSELECT.
  ELSE.
    SELECT A~KNUMV B~EBELP INTO (LV_KNUMV, LV_KPOSN)
      FROM EKKO AS A JOIN EKPO AS B ON B~EBELN = A~EBELN
      WHERE B~MATNR = P_MATNR AND B~LOEKZ = SPACE
        AND A~EBELN < P_EBELN AND A~FRGZU = 'X'
      ORDER BY A~KNUMV ASCENDING.
    ENDSELECT.
  ENDIF.
  IF SY-SUBRC NE 0.
    RETURN.
  ENDIF.

* 2. WAERS dari KONV PO KNUMV tertinggi (PB00/PBXX). KBETR ditimpa di step 3.
  CLEAR: LC_KBETR, LV_LW.
  SELECT SINGLE KBETR WAERS INTO (LC_KBETR, LV_LW) FROM KONV
    WHERE KNUMV = LV_KNUMV AND KPOSN = LV_KPOSN
      AND ( KSCHL = 'PB00' OR KSCHL = 'PBXX' ).

* 3. KBETR = NETPR PO EBELN tertinggi (ORDER BY EBELN ASC -> baris terakhir).
  IF LV_CHARG IS NOT INITIAL.
    SELECT B~NETPR INTO LC_KBETR
      FROM EKKO AS A JOIN EKPO AS B ON B~EBELN = A~EBELN
                     JOIN EKET AS C ON C~EBELN = B~EBELN
                          AND C~EBELP = B~EBELP AND C~CHARG = LV_CHARG
      WHERE B~MATNR = P_MATNR AND B~LOEKZ = SPACE
        AND A~EBELN < P_EBELN AND A~FRGZU = 'X'
      ORDER BY A~KNUMV ASCENDING.
    ENDSELECT.
  ELSE.
    SELECT B~NETPR INTO LC_KBETR
      FROM EKKO AS A JOIN EKPO AS B ON B~EBELN = A~EBELN
      WHERE B~MATNR = P_MATNR AND B~LOEKZ = SPACE
        AND A~EBELN < P_EBELN AND A~FRGZU = 'X'
      ORDER BY A~EBELN ASCENDING.
    ENDSELECT.
  ENDIF.

* 4. Konversi 2-hop via IDR pakai WAERS dari step 2 (persis driver).
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

## Hasil (live test dev)
Untuk PO 4518000081 (SRCBCO, IDR): STEP1 WAERS=EUR, STEP2 NETPR=324,32 → **FINAL 6.672.300,22** = **sama print**. ✔

## Catatan
- Ini sengaja meniru perilaku driver TTE apa adanya (termasuk "quirk" WAERS dari 1 PO & NETPR dari PO lain) supaya angka report == cetak. Kalau nanti driver print diperbaiki, samakan lagi.
- Push: semua di 1 program (ZMMI_PO_EMAIL). Baris source ≤72 char kalau lewat RFC_ABAP_INSTALL_AND_RUN; ≤255 kalau editor/Z_RFC_PROGRAM_UPDATE.
- F_CALC_LAST_PRICE & F_GET_LAST lama biarkan (F_GET_LAST masih dipakai cek exception).

## Verifikasi
1. Aktivasi bersih.
2. Report PO 4518000081 → Last Price = 6.672.300,22 (sama reprint).
3. Uji material lain + material batch RPV/RPC/RPM.

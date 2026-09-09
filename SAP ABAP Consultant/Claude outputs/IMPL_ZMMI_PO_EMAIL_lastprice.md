# Rancangan Implementasi — Last Price ZMMI_PO_EMAIL = value print PO

## Tujuan
Kolom **Last Price** di report ZMMI_PO_EMAIL harus menghasilkan **value yang sama persis** dengan hasil cetak PO (SmartForm driver `ZMMF_PO_LOCAL`, kolom "Last Prc"). Logic lama (berbasis `EKPO-NETPR/PEINH` + kurs `BEDAT`) diganti menjadi **replika persis** logic print. Perubahan ini **independen** dari logic tier/exception (F_GET_LAST/F_CHK_NAIK tetap dipakai untuk exception, tidak diubah).

## Sumber kebenaran (logic print di ZMMF_PO_LOCAL_F01, FORM F_FIND_ITEM_DATA, blok "find last price by material")
1. Pilih PO acuan: material sama, `EKPO-LOEKZ = ''`, `EKKO-EBELN < EBELN berjalan`, `EKKO-FRGZU = 'X'`, `ORDER BY EKKO-KNUMV ASCENDING` via `SELECT ... ENDSELECT` (tanpa `UP TO`) → efektif mengambil baris **KNUMV tertinggi**. (Tidak ada filter BSTYP, tidak pakai BEDAT.)
2. Ambil `KONV-KBETR` + `KONV-WAERS` dengan `SELECT SINGLE` di `KNUMV`/`KPOSN` PO acuan, kondisi `KSCHL = 'PB00' OR KSCHL = 'PBXX'`. KBETR dipakai **mentah** (tanpa dibagi PEINH/KPEIN).
3. Konversi mata uang 2-hop lewat IDR memakai kurs **`SY-DATUM`** (`KURST='M'`, FM `RKC_SINGLE_EXCHANGE_RATE_GET`), plus `CURRENCY_AMOUNT_SAP_TO_DISPLAY` — persis urutan print.

---

## Perubahan 1 — Ganti pemanggilan di item-loop (mode Report)

**Lokasi:** di dalam `START-OF-SELECTION`, item-loop `LOOP AT LT_EKPOD INTO LS_EKPOD`, blok kolom Last Price (setelah `PERFORM F_GET_LAST ...`).

**HAPUS blok lama ini:**
```abap
*         Kolom Report: Hitung Last Price dari data histori (hanya bila mode Report)
          IF P_RPT EQ 'X' AND LV_HASMAT EQ 'X'.
            PERFORM F_CALC_LAST_PRICE USING LS_LASTM
                                            LS_EKKO-WAERS
                                            LS_EKPOD-BPRME
                                   CHANGING LS_RESULT-LAST_PRICE.
          ENDIF.
```

**GANTI dengan:**
```abap
*         Kolom Report: Last Price = REPLIKA persis logic print PO
*         (ZMMF_PO_LOCAL). Ambil KBETR (PB00/PBXX) dari PO acuan KNUMV
*         tertinggi, konversi 2-hop via IDR pakai kurs SY-DATUM.
*         Independen dari logic exception/tier di bawah.
          IF P_RPT EQ 'X'.
            PERFORM F_GET_LPRINT USING LS_EKPOD-MATNR
                                       LS_EKKO-EBELN
                                       LS_EKKO-WAERS
                                 CHANGING LS_RESULT-LAST_PRICE.
          ENDIF.
```

Catatan: `PERFORM F_GET_LAST ... CHANGING LS_LASTM LV_HASMAT.` di atasnya **tetap dibiarkan** (masih dipakai cek exception MaterialBaru/HrgNaikMat). FORM `F_CALC_LAST_PRICE` jadi tidak terpakai — boleh dibiarkan (aman) atau dihapus terpisah.

---

## Perubahan 2 — Tambah FORM baru `F_GET_LPRINT`

**Lokasi:** sisipkan sebagai FORM baru (mis. tepat sebelum `FORM F_CHK_NAIK`).

```abap
*&---------------------------------------------------------------*
*& Form F_GET_LPRINT -- Last Price REPLIKA PERSIS print PO
*&   (ZMMF_PO_LOCAL, FORM F_FIND_ITEM_DATA). Tujuan: value kolom
*&   Last Price di report SAMA dgn hasil cetak PO.
*&   1. PO acuan: material sama, released (FRGZU='X'), belum dihapus,
*&      EBELN < current -> ambil KNUMV TERTINGGI.
*&   2. KBETR (PB00/PBXX) dari KONV PO acuan (raw, tanpa PEINH).
*&   3. Konversi 2-hop via IDR pakai kurs SY-DATUM (KURST='M') +
*&      CURRENCY_AMOUNT_SAP_TO_DISPLAY spt print.
*&---------------------------------------------------------------*
FORM F_GET_LPRINT USING P_MATNR TYPE MATNR
                        P_EBELN TYPE EBELN
                        P_WAERS TYPE WAERS
                  CHANGING P_LAST_PRICE TYPE P.
  DATA: LV_KNUMV    TYPE KONV-KNUMV,
        LV_KPOSN    TYPE KONV-KPOSN,
        LV_LWAERS   TYPE KONV-WAERS,
        LC_KBETR    TYPE KONV-KBETR,
        LV_KURS     TYPE RKB1K-EXCHR,
        LV_NEWAMT   TYPE WMTO_S-AMOUNT.

  CLEAR P_LAST_PRICE.
  CLEAR: LV_KNUMV, LV_KPOSN.

* 1. PO acuan -> KNUMV tertinggi (SELECT..ENDSELECT ORDER BY ASC,
*    baris terakhir yg ke-assign = KNUMV terbesar), spt print.
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

* 2. KBETR base price (PB00/PBXX) dari PO acuan.
  CLEAR: LC_KBETR, LV_LWAERS.
  SELECT SINGLE KBETR WAERS INTO (LC_KBETR, LV_LWAERS)
    FROM KONV
    WHERE KNUMV = LV_KNUMV
      AND KPOSN = LV_KPOSN
      AND ( KSCHL = 'PB00' OR KSCHL = 'PBXX' ).
  IF SY-SUBRC NE 0.
    RETURN.
  ENDIF.

* 3. Konversi currency (persis print).
  CLEAR: LV_KURS, LV_NEWAMT.
  IF P_WAERS NE LV_LWAERS.
*   3a. ke IDR
    IF LV_LWAERS EQ 'IDR'.
      LC_KBETR = LC_KBETR.
    ELSE.
      CALL FUNCTION 'RKC_SINGLE_EXCHANGE_RATE_GET'
        EXPORTING
          DATUM         = SY-DATUM
          KURST         = 'M'
          NCURR         = 'IDR'
          VCURR         = LV_LWAERS
        IMPORTING
          EXCHR         = LV_KURS
        EXCEPTIONS
          NO_RATE_FOUND = 1
          OTHERS        = 2.
      LC_KBETR = LC_KBETR * LV_KURS.
    ENDIF.

    LV_NEWAMT = LC_KBETR.
    CALL FUNCTION 'CURRENCY_AMOUNT_SAP_TO_DISPLAY'
      EXPORTING
        CURRENCY        = LV_LWAERS
        AMOUNT_INTERNAL = LV_NEWAMT
      IMPORTING
        AMOUNT_DISPLAY  = LV_NEWAMT.
    LC_KBETR = LV_NEWAMT.

*   3b. dari IDR ke currency PO
    IF P_WAERS EQ 'IDR'.
      LC_KBETR = LC_KBETR.
    ELSE.
      CALL FUNCTION 'RKC_SINGLE_EXCHANGE_RATE_GET'
        EXPORTING
          DATUM         = SY-DATUM
          KURST         = 'M'
          NCURR         = 'IDR'
          VCURR         = P_WAERS
        IMPORTING
          EXCHR         = LV_KURS
        EXCEPTIONS
          NO_RATE_FOUND = 1
          OTHERS        = 2.
      LC_KBETR = LC_KBETR * 1 / LV_KURS.
    ENDIF.
  ELSE.
*   Currency sama -> tetap konversi format tampilan spt print.
    LV_NEWAMT = LC_KBETR.
    CALL FUNCTION 'CURRENCY_AMOUNT_SAP_TO_DISPLAY'
      EXPORTING
        CURRENCY        = LV_LWAERS
        AMOUNT_INTERNAL = LV_NEWAMT
      IMPORTING
        AMOUNT_DISPLAY  = LV_NEWAMT.
    LC_KBETR = LV_NEWAMT.
  ENDIF.

  P_LAST_PRICE = LC_KBETR.
ENDFORM.                    "F_GET_LPRINT
```

---

## Catatan eksekusi / push
- RFC `Z_RFC_PROGRAM_UPDATE` **mengganti seluruh source** program (tidak ada mode partial). Kalau pakai RFC ini, kirim seluruh source hasil edit.
- Alternatif hemat (kirim delta saja): jalankan patcher via `RFC_ABAP_INSTALL_AND_RUN` yang `READ REPORT` source live, `REPLACE`/`INSERT` kedua perubahan di internal table, lalu `INSERT REPORT ... FROM itab`, kemudian aktivasi.
- **Target server:** pastikan channel eksekusi menulis ke sandbox **TRS (192.168.6.243)**. Cek dengan `WRITE SY-SYSID, SY-HOST` — host sandbox, **bukan** `eccdevlinux` (itu DEV/TRD).
- Panjang baris source maksimal 255 char (aman, kode ini max ~90 char).

## Verifikasi setelah push
1. Aktivasi bersih (tanpa error syntax).
2. Jalankan report mode Report untuk PO uji (mis. **4518000081**), bandingkan kolom **Last Price** dengan hasil cetak `ZMMF_PO_LOCAL` — harus sama.
3. Cek beberapa material lain (currency sama & beda) untuk memastikan konversi cocok.
```
```

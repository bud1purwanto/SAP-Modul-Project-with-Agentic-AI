*&---------------------------------------------------------------*
*& Report  ZMMI_PO_EMAIL  (Sprint 2 - Routing + Exception + Email)
*&  Fokus: routing approver Tier T1/T2, exception flagging, dan
*&  notifikasi email per grup approver (multi-recipient, HTML+Excel).
*&  Auto-release (nilai <= threshold auto) DITANGANI Sprint 1
*&  (program ZMMI_PO_RELEASE) -> di program ini PO tsb di-SKIP.
*&---------------------------------------------------------------*

REPORT ZMMI_PO_EMAIL LINE-SIZE 210.

TABLES: EKKO, EKPO.

*----------------------------------------------------------------*
* Konstanta konfigurasi exception
*----------------------------------------------------------------*
CONSTANTS: GC_MAP_PROG   TYPE ZMAP_TYPE-PROG VALUE 'ZMMI_PO_EMAIL',
           GC_NEW_DAYS   TYPE I              VALUE 90,     " master baru
           GC_STALE_DAYS TYPE I              VALUE 730,    " 24 bulan
           GC_PRICE_TOL  TYPE P DECIMALS 2   VALUE '1.10', " naik >10%
           GC_PSTYP_SVC  TYPE EKPO-PSTYP     VALUE '9',    " service
           GC_KNTTP_CPX  TYPE EKPO-KNTTP     VALUE 'A'.    " asset/capex

*----------------------------------------------------------------*
* LEGENDA FLAG EXCEPTION (kolom EXC_REASON / email)
*----------------------------------------------------------------*
* VendorBaru   : Vendor baru dibuat < 90 hari ATAU belum pernah
*                bertransaksi (tidak ada PO released sebelumnya).
* MaterialBaru : Material baru dibuat < 90 hari ATAU belum pernah
*                dibeli (tidak ada histori harga).
* HrgNaikMat   : Harga naik > 10% dibanding harga terakhir MATERIAL
*                ini (dari vendor manapun), dinormalisasi ke USD.
* HrgNaikVen   : Harga naik > 10% dibanding harga terakhir dari
*                VENDOR yang sama untuk material ini.
* StaleHist    : Pembelian terakhir > 24 bulan lalu; harga acuan
*                dianggap usang, cek kenaikan harga di-skip.
* SvcCapex     : PO jasa (PSTYP='9') atau aset/capex (KNTTP='A').
* -> Bila satu PO kena > 1 kriteria, token digabung dgn ';'.
* -> Flag hanya dihitung utk PO Tier T1/T2 (routing), bukan T0.
*----------------------------------------------------------------*

*----------------------------------------------------------------*
* Types & Data
*----------------------------------------------------------------*
TYPES: BEGIN OF TY_EKKO,
         EBELN TYPE EKKO-EBELN,
         BUKRS TYPE EKKO-BUKRS,
         EKORG TYPE EKKO-EKORG,
         EKGRP TYPE EKKO-EKGRP,
         BSART TYPE EKKO-BSART,
         FRGRL TYPE EKKO-FRGRL,
         FRGGR TYPE EKKO-FRGGR,
         FRGSX TYPE EKKO-FRGSX,
         WAERS TYPE EKKO-WAERS,
         BEDAT TYPE EKKO-BEDAT,
         LIFNR TYPE EKKO-LIFNR,
         LOEKZ TYPE EKKO-LOEKZ,
       END OF TY_EKKO.

TYPES: BEGIN OF TY_THRESHOLD,
         OPT    TYPE ZMAP_TYPE-OPT,
         VALUE  TYPE ZMAP_TYPE-VALUE,
         TEXT1  TYPE ZMAP_TYPE-TEXT1,
         USDVAL TYPE P DECIMALS 2,
       END OF TY_THRESHOLD.

TYPES: BEGIN OF TY_APPROVER,
         OPT   TYPE ZMAP_TYPE-OPT,
         VALUE TYPE ZMAP_TYPE-VALUE,
         TEXT1 TYPE ZMAP_TYPE-TEXT1,   " username (skema baru) / email penuh (lama)
         TEXT2 TYPE ZMAP_TYPE-TEXT2,   " domain, mis. @trst.co.id
         TEXT3 TYPE ZMAP_TYPE-TEXT3,   " gender: M=Bapak, F=Ibu, kosong=tanpa sapaan
       END OF TY_APPROVER.

TYPES: BEGIN OF TY_EKPOD,
         EBELP TYPE EKPO-EBELP,
         MATNR TYPE EKPO-MATNR,
         NETPR TYPE EKPO-NETPR,
         PEINH TYPE EKPO-PEINH,
         BPRME TYPE EKPO-BPRME,
         PSTYP TYPE EKPO-PSTYP,
         KNTTP TYPE EKPO-KNTTP,
       END OF TY_EKPOD.

TYPES: BEGIN OF TY_LAST,
         NETPR TYPE EKPO-NETPR,
         PEINH TYPE EKPO-PEINH,
         BPRME TYPE EKPO-BPRME,
         WAERS TYPE EKKO-WAERS,
         AEDAT TYPE EKKO-AEDAT,
       END OF TY_LAST.

TYPES: BEGIN OF TY_RESULT,
         EBELN     TYPE EKKO-EBELN,
         LIFNR     TYPE EKKO-LIFNR,
         USDVAL    TYPE P DECIMALS 2,
         TIER      TYPE ZMAP_TYPE-OPT,
         APPR_OPT  TYPE ZMAP_TYPE-OPT,
         APPR_NAME TYPE ZMAP_TYPE-VALUE,
         APPR_MAIL TYPE AD_SMTPADR,
         STATUS    TYPE CHAR1,
         EXC_FLAG  TYPE CHAR1,
         EXC_REASON TYPE C LENGTH 120,
         MESSAGE   TYPE BAPI_MSG,
       END OF TY_RESULT.

* Struktur pengumpul email: APPR_OPT WAJIB field pertama (utk AT NEW)
TYPES: BEGIN OF TY_MAIL,
         APPR_OPT   TYPE ZMAP_TYPE-OPT,
         EBELN      TYPE EKKO-EBELN,
         LIFNR      TYPE EKKO-LIFNR,
         USDVAL     TYPE P DECIMALS 2,
         TIER       TYPE ZMAP_TYPE-OPT,
         EXC_FLAG   TYPE CHAR1,
         EXC_REASON TYPE C LENGTH 120,
       END OF TY_MAIL.

DATA: LT_EKKO      TYPE STANDARD TABLE OF TY_EKKO,
      LS_EKKO      TYPE TY_EKKO,
      LT_THRESHOLD TYPE STANDARD TABLE OF TY_THRESHOLD,
      LS_THRESHOLD TYPE TY_THRESHOLD,
      LT_APPROVER  TYPE STANDARD TABLE OF TY_APPROVER,
      LS_APPROVER  TYPE TY_APPROVER,
      LT_EKPOD     TYPE STANDARD TABLE OF TY_EKPOD,
      LS_EKPOD     TYPE TY_EKPOD,
      LT_RESULT    TYPE STANDARD TABLE OF TY_RESULT,
      LS_RESULT    TYPE TY_RESULT,
      GT_MAIL      TYPE STANDARD TABLE OF TY_MAIL,
      LS_MAIL      TYPE TY_MAIL.

DATA: LV_NETWR     TYPE EKPO-NETWR,
      LV_REAL_NETWR TYPE BAPICURR-BAPICURR,
      LV_USDVAL    TYPE P DECIMALS 2,
      LV_KURS      TYPE RKB1K-EXCHR,
      LV_LINES     TYPE I,
      LV_FOUND     TYPE CHAR1,
      LV_AUTO      TYPE CHAR1,
      LV_APPROPT   TYPE ZMAP_TYPE-OPT,
      LV_MAILTO    TYPE AD_SMTPADR.

* Kerja exception
DATA: LV_EXC        TYPE CHAR1,
      LV_CUTNEW     TYPE SY-DATUM,
      LV_CUTSTALE   TYPE SY-DATUM,
      LV_ERDAT      TYPE LFA1-ERDAT,
      LV_ERSDA      TYPE MARA-ERSDA,
      LV_DUMMY      TYPE EKKO-EBELN,
      LV_CURUNIT    TYPE P DECIMALS 4,
      LV_CURUSD     TYPE P DECIMALS 4,
      LS_LASTM      TYPE TY_LAST,
      LS_LASTV      TYPE TY_LAST,
      LV_LASTUSD    TYPE P DECIMALS 4,
      LV_HASMAT     TYPE CHAR1,
      LV_HASVEN     TYPE CHAR1.

* Objek email (CL_BCS) + tabel kerja email
CLASS CL_BCS DEFINITION LOAD.
DATA: LO_SEND    TYPE REF TO CL_BCS,
      LO_DOC     TYPE REF TO CL_DOCUMENT_BCS,
      LO_SENDER  TYPE REF TO IF_SENDER_BCS,
      LO_RECIP   TYPE REF TO IF_RECIPIENT_BCS,
      LX_BCS     TYPE REF TO CX_BCS.

DATA: GT_BODY    TYPE BCSY_TEXT,
      GS_BODY    TYPE SOLI,
      GT_RCP     TYPE STANDARD TABLE OF AD_SMTPADR,
      GV_XLS_XML TYPE STRING,
      GV_DATE_ID TYPE STRING,
      GV_XSTR    TYPE XSTRING,
      GT_BIN     TYPE SOLIX_TAB,
      GV_ERR     TYPE STRING.

*----------------------------------------------------------------*
* Selection Screen
*----------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK B1 WITH FRAME TITLE TEXT-001.
SELECT-OPTIONS: S_BUKRS FOR EKKO-BUKRS,
                S_EKORG FOR EKKO-EKORG,
                S_EKGRP FOR EKKO-EKGRP,
                S_BSART FOR EKKO-BSART,
                S_EBELN FOR EKKO-EBELN.
SELECTION-SCREEN END OF BLOCK B1.

SELECTION-SCREEN BEGIN OF BLOCK B2 WITH FRAME TITLE TEXT-002.
PARAMETERS: P_TEST TYPE C AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK B2.

*----------------------------------------------------------------*
START-OF-SELECTION.

  LV_CUTNEW   = SY-DATUM - GC_NEW_DAYS.
  LV_CUTSTALE = SY-DATUM - GC_STALE_DAYS.

*----------------------------------------------------------------*
* 1. Load mapping THRESHOLD (semua tier) dari ZMAP_TYPE
*----------------------------------------------------------------*
  REFRESH LT_THRESHOLD.
  SELECT OPT VALUE TEXT1
    INTO CORRESPONDING FIELDS OF TABLE LT_THRESHOLD
    FROM ZMAP_TYPE
    WHERE PROG = GC_MAP_PROG
      AND TYPE = 'THRESHOLD'
      AND DELETION = SPACE.

  IF LT_THRESHOLD IS INITIAL.
    WRITE: / 'Mapping THRESHOLD belum ada di ZMAP_TYPE. Program dihentikan.'.
    EXIT.
  ENDIF.

  LOOP AT LT_THRESHOLD INTO LS_THRESHOLD.
    LS_THRESHOLD-USDVAL = LS_THRESHOLD-VALUE.
    MODIFY LT_THRESHOLD FROM LS_THRESHOLD.
  ENDLOOP.

  SORT LT_THRESHOLD BY USDVAL ASCENDING.

*----------------------------------------------------------------*
* 2. Load mapping APPROVER dari ZMAP_TYPE (semua baris, multi per OPT)
*    Email dibentuk saat kirim: TEXT1 (username) + TEXT2 (domain).
*----------------------------------------------------------------*
  REFRESH LT_APPROVER.
  SELECT OPT VALUE TEXT1 TEXT2 TEXT3
    INTO CORRESPONDING FIELDS OF TABLE LT_APPROVER
    FROM ZMAP_TYPE
    WHERE PROG = GC_MAP_PROG
      AND TYPE = 'APPROVER'
      AND DELETION = SPACE.

  IF LT_APPROVER IS INITIAL.
    WRITE: / 'Mapping APPROVER belum ada di ZMAP_TYPE. Program dihentikan.'.
    EXIT.
  ENDIF.

  SORT LT_APPROVER BY OPT VALUE.

*----------------------------------------------------------------*
* 3. Ambil PO yang masih PENDING RELEASE (FRGRL = 'X')
*----------------------------------------------------------------*
  REFRESH LT_EKKO.
  SELECT EBELN BUKRS EKORG EKGRP BSART FRGRL FRGGR FRGSX WAERS BEDAT LIFNR LOEKZ
    INTO TABLE LT_EKKO
    FROM EKKO
    WHERE FRGRL EQ 'X'
      AND BUKRS IN S_BUKRS
      AND EKORG IN S_EKORG
      AND EKGRP IN S_EKGRP
      AND BSART IN S_BSART
      AND EBELN IN S_EBELN
      AND BSTYP EQ 'F'
      AND LOEKZ EQ SPACE.

  IF LT_EKKO IS INITIAL.
    WRITE: / 'Tidak ada PO yang perlu diproses sesuai kriteria seleksi.'.
    EXIT.
  ENDIF.

  SORT LT_EKKO BY EBELN.

*----------------------------------------------------------------*
* 4. Proses tiap PO
*----------------------------------------------------------------*
  LOOP AT LT_EKKO INTO LS_EKKO.

    CLEAR: LS_RESULT, LV_NETWR, LV_USDVAL, LV_AUTO, LV_APPROPT.
    LS_RESULT-EBELN = LS_EKKO-EBELN.
    LS_RESULT-LIFNR = LS_EKKO-LIFNR.

*   --- 4a. Total nilai PO ---
    SELECT SUM( NETWR ) INTO LV_NETWR
      FROM EKPO
      WHERE EBELN = LS_EKKO-EBELN
        AND LOEKZ EQ SPACE.

*   --- 4b. Konversi ke USD pakai KURS PADA TANGGAL PO (BEDAT) ---
    IF LS_EKKO-WAERS EQ 'USD'.
      LV_USDVAL = LV_NETWR.
    ELSE.
      CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_EXTERNAL'
        EXPORTING
          CURRENCY        = LS_EKKO-WAERS
          AMOUNT_INTERNAL = LV_NETWR
        IMPORTING
          AMOUNT_EXTERNAL = LV_REAL_NETWR.

      CLEAR LV_KURS.
      CALL FUNCTION 'RKC_SINGLE_EXCHANGE_RATE_GET'
        EXPORTING
          DATUM         = LS_EKKO-BEDAT
          KURST         = 'M'
          NCURR         = 'USD'
          VCURR         = LS_EKKO-WAERS
        IMPORTING
          EXCHR         = LV_KURS
        EXCEPTIONS
          NO_RATE_FOUND = 1
          OTHERS        = 2.

      IF SY-SUBRC NE 0.
        LS_RESULT-STATUS  = 'E'.
        LS_RESULT-MESSAGE = 'Kurs (TCURR, KURST=M) pada tanggal PO (BEDAT) tidak ditemukan -- skip, wajib manual'.
        APPEND LS_RESULT TO LT_RESULT.
        CONTINUE.
      ENDIF.

      LV_USDVAL = LV_REAL_NETWR * LV_KURS.
    ENDIF.

    LS_RESULT-USDVAL = LV_USDVAL.

*   --- 4c. Tentukan TIER dari mapping THRESHOLD (ascending) ---
    CLEAR: LV_FOUND, LV_AUTO.
    LOOP AT LT_THRESHOLD INTO LS_THRESHOLD.
      IF LV_USDVAL <= LS_THRESHOLD-USDVAL.
        LV_FOUND = 'X'.
        EXIT.
      ENDIF.
    ENDLOOP.

    IF LV_FOUND IS INITIAL.
      LS_RESULT-STATUS  = 'E'.
      LS_RESULT-MESSAGE = 'Nilai PO melebihi tier tertinggi di mapping THRESHOLD -- wajib manual'.
      APPEND LS_RESULT TO LT_RESULT.
      CONTINUE.
    ENDIF.

    LS_RESULT-TIER = LS_THRESHOLD-OPT.
    IF LS_THRESHOLD-TEXT1 EQ 'X'.
      LV_AUTO = 'X'.
    ENDIF.

*   ================================================================
*   4d. Tier AUTO (nilai <= threshold auto) -> DI-SKIP.
*   Auto-release ditangani program Sprint 1 (ZMMI_PO_RELEASE),
*   BUKAN di sini. Program ini fokus routing + exception + email,
*   jadi PO tier auto langsung dilewati (tidak diemail, tidak
*   masuk daftar hasil).
*   ================================================================
    IF LV_AUTO EQ 'X'.

      CONTINUE.

*   ================================================================
*   4e. JALUR ROUTING (Tier T1/T2) -> approver + EXCEPTION FLAGGING
*   ================================================================
    ELSE.

*     --- 4e-1. Identifikasi grup approver (OPT) ---
      CLEAR LS_APPROVER.
      IF LS_RESULT-TIER EQ 'T2'.
        LV_APPROPT = 'GM_FIXED'.
        READ TABLE LT_APPROVER INTO LS_APPROVER WITH KEY OPT = 'GM_FIXED'.
      ELSE.
        LV_APPROPT = LS_EKKO-EKGRP.
        READ TABLE LT_APPROVER INTO LS_APPROVER WITH KEY OPT = LS_EKKO-EKGRP.
        IF SY-SUBRC NE 0.
          LV_APPROPT = 'DEFAULT'.
          READ TABLE LT_APPROVER INTO LS_APPROVER WITH KEY OPT = 'DEFAULT'.
        ENDIF.
      ENDIF.

      IF SY-SUBRC EQ 0.
        LS_RESULT-APPR_OPT  = LV_APPROPT.
        LS_RESULT-APPR_NAME = LS_APPROVER-VALUE.
        PERFORM F_BUILD_EMAIL USING LS_APPROVER-TEXT1 LS_APPROVER-TEXT2
                              CHANGING LS_RESULT-APPR_MAIL.
        LS_RESULT-STATUS    = 'M'.
        LS_RESULT-MESSAGE   = 'Perlu approval manual di SAP; notifikasi email dikirim ke grup approver'.
      ELSE.
        LS_RESULT-STATUS = 'E'.
        IF LS_RESULT-TIER EQ 'T2'.
          LS_RESULT-MESSAGE = 'Tidak ada mapping GM Purchasing (OPT=GM_FIXED) di ZMAP_TYPE'.
        ELSE.
          LS_RESULT-MESSAGE = 'Tidak ada mapping APPROVER utk EKGRP ini, baris DEFAULT juga tidak ada'.
        ENDIF.
      ENDIF.

*     --- 4e-2. EXCEPTION FLAGGING (hanya T1/T2) ---
      CLEAR: LV_EXC, LS_RESULT-EXC_FLAG, LS_RESULT-EXC_REASON.

*     ============================================================
*     Kriteria VendorBaru (cek 1x per PO, di level header):
*       (a) Vendor master baru: LFA1-ERDAT >= cutoff 90 hari, ATAU
*       (b) Belum pernah bertransaksi: tidak ada PO lain milik
*           vendor ini yang sudah released (FRGZU='X').
*       Salah satu terpenuhi -> flag 'VendorBaru'.
*     ============================================================
      CLEAR LV_ERDAT.
      SELECT SINGLE ERDAT INTO LV_ERDAT FROM LFA1
        WHERE LIFNR = LS_EKKO-LIFNR.
      IF SY-SUBRC EQ 0 AND LV_ERDAT GE LV_CUTNEW.
        LV_EXC = 'X'.
        PERFORM F_ADD_REASON USING 'VendorBaru'
                             CHANGING LS_RESULT-EXC_REASON.
      ELSE.
        CLEAR LV_DUMMY.
        SELECT EBELN INTO LV_DUMMY UP TO 1 ROWS
          FROM EKKO
          WHERE LIFNR = LS_EKKO-LIFNR
            AND EBELN NE LS_EKKO-EBELN
            AND FRGZU = 'X'
            AND BSTYP = 'F'.
        ENDSELECT.
        IF SY-SUBRC NE 0.
          LV_EXC = 'X'.
          PERFORM F_ADD_REASON USING 'VendorBaru'
                               CHANGING LS_RESULT-EXC_REASON.
        ENDIF.
      ENDIF.

*     Ambil detail item PO ini untuk cek per material (cek berikut
*     berlaku per baris item: SvcCapex, MaterialBaru, kenaikan harga).
      REFRESH LT_EKPOD.
      SELECT EBELP MATNR NETPR PEINH BPRME PSTYP KNTTP
        INTO TABLE LT_EKPOD
        FROM EKPO
        WHERE EBELN = LS_EKKO-EBELN
          AND LOEKZ EQ SPACE.

      LOOP AT LT_EKPOD INTO LS_EKPOD.

*       Kriteria SvcCapex: item jasa (PSTYP='9') ATAU
*       aset/capex (KNTTP='A') -> flag 'SvcCapex'.
        IF LS_EKPOD-PSTYP EQ GC_PSTYP_SVC OR LS_EKPOD-KNTTP EQ GC_KNTTP_CPX.
          LV_EXC = 'X'.
          PERFORM F_ADD_REASON USING 'SvcCapex'
                               CHANGING LS_RESULT-EXC_REASON.
        ENDIF.

*       Item tanpa nomor material (jasa/teks bebas) -> lewati cek
*       material & harga, lanjut ke item berikutnya.
        IF LS_EKPOD-MATNR IS INITIAL.
          CONTINUE.
        ENDIF.

*       Kriteria MaterialBaru (a): material master baru
*       (MARA-ERSDA >= cutoff 90 hari) -> flag 'MaterialBaru'.
        CLEAR LV_ERSDA.
        SELECT SINGLE ERSDA INTO LV_ERSDA FROM MARA
          WHERE MATNR = LS_EKPOD-MATNR.
        IF SY-SUBRC EQ 0 AND LV_ERSDA GE LV_CUTNEW.
          LV_EXC = 'X'.
          PERFORM F_ADD_REASON USING 'MaterialBaru'
                               CHANGING LS_RESULT-EXC_REASON.
        ENDIF.

*       Hitung harga satuan item sekarang -> normalisasi per PEINH,
*       lalu konversi ke USD (dipakai utk banding kenaikan harga).
        CLEAR: LV_CURUNIT, LV_CURUSD.
        IF LS_EKPOD-PEINH > 0.
          LV_CURUNIT = LS_EKPOD-NETPR / LS_EKPOD-PEINH.
        ELSE.
          LV_CURUNIT = LS_EKPOD-NETPR.
        ENDIF.
        PERFORM F_TO_USD USING LV_CURUNIT LS_EKKO-WAERS LS_EKKO-BEDAT
                         CHANGING LV_CURUSD.

*       Ambil harga terakhir dari PO released sebelumnya:
*       - LS_LASTM = harga terakhir MATERIAL ini (vendor manapun).
*       - LS_LASTV = harga terakhir dari VENDOR yang sama utk material ini.
        CLEAR: LS_LASTM, LV_HASMAT.
        PERFORM F_GET_LAST USING LS_EKPOD-MATNR SPACE LS_EKKO-EBELN
                           CHANGING LS_LASTM LV_HASMAT.

        CLEAR: LS_LASTV, LV_HASVEN.
        PERFORM F_GET_LAST USING LS_EKPOD-MATNR LS_EKKO-LIFNR LS_EKKO-EBELN
                           CHANGING LS_LASTV LV_HASVEN.

*       Sumbu MATERIAL:
*       - Tidak ada histori sama sekali -> MaterialBaru (b: never purchased).
*       - Ada histori tapi > 24 bulan  -> StaleHist (acuan usang,
*         cek kenaikan harga di-skip krn tidak bermakna).
*       - Ada histori & fresh          -> cek HrgNaikMat (> 10%).
        IF LV_HASMAT IS INITIAL.
          LV_EXC = 'X'.
          PERFORM F_ADD_REASON USING 'MaterialBaru'
                               CHANGING LS_RESULT-EXC_REASON.
        ELSE.
          IF LS_LASTM-AEDAT LT LV_CUTSTALE.
            LV_EXC = 'X'.
            PERFORM F_ADD_REASON USING 'StaleHist'
                                 CHANGING LS_RESULT-EXC_REASON.
          ELSE.
            PERFORM F_CHK_NAIK USING LV_CURUSD LS_EKPOD-BPRME LS_LASTM
                               'HrgNaikMat'
                               CHANGING LV_EXC LS_RESULT-EXC_REASON.
          ENDIF.
        ENDIF.

*       Sumbu VENDOR (terpisah dari sumbu material):
*       hanya bila ada histori vendor & masih fresh -> cek HrgNaikVen (> 10%).
        IF LV_HASVEN IS NOT INITIAL AND LS_LASTV-AEDAT GE LV_CUTSTALE.
          PERFORM F_CHK_NAIK USING LV_CURUSD LS_EKPOD-BPRME LS_LASTV
                             'HrgNaikVen'
                             CHANGING LV_EXC LS_RESULT-EXC_REASON.
        ENDIF.

      ENDLOOP.

      LS_RESULT-EXC_FLAG = LV_EXC.

*     --- 4e-3. Kumpulkan utk email (hanya bila approver ketemu) ---
      IF LS_RESULT-APPR_OPT IS NOT INITIAL.
        CLEAR LS_MAIL.
        LS_MAIL-APPR_OPT   = LS_RESULT-APPR_OPT.
        LS_MAIL-EBELN      = LS_RESULT-EBELN.
        LS_MAIL-LIFNR      = LS_RESULT-LIFNR.
        LS_MAIL-USDVAL     = LS_RESULT-USDVAL.
        LS_MAIL-TIER       = LS_RESULT-TIER.
        LS_MAIL-EXC_FLAG   = LS_RESULT-EXC_FLAG.
        LS_MAIL-EXC_REASON = LS_RESULT-EXC_REASON.
        APPEND LS_MAIL TO GT_MAIL.
      ENDIF.

    ENDIF.

    APPEND LS_RESULT TO LT_RESULT.

  ENDLOOP.

*----------------------------------------------------------------*
* 5. Kirim email per grup approver
*----------------------------------------------------------------*
  PERFORM F_SEND_ALL.

*----------------------------------------------------------------*
* 6. Output hasil
*----------------------------------------------------------------*
  DESCRIBE TABLE LT_RESULT LINES LV_LINES.

  WRITE: / 'Hasil PO Routing + Exception + Email (ZMMI_PO_EMAIL)', 60 'Mode:', P_TEST AS CHECKBOX.
  WRITE: / 'Total PO T1/T2 diproses:', LV_LINES,
           '(PO tier auto di-skip, ditangani Sprint 1)'.
  SKIP.
  WRITE: / SY-ULINE.
  WRITE: / 'PO Number', 15 'USD Val', 35 'Tier',
           42 'Approver', 60 'Email', 84 'St', 88 'Ex',
           92 'Alasan Exception', 155 'Keterangan'.
  WRITE: / SY-ULINE.

  LOOP AT LT_RESULT INTO LS_RESULT.
    WRITE: / LS_RESULT-EBELN,
             15 LS_RESULT-USDVAL,
             35 LS_RESULT-TIER,
             42 LS_RESULT-APPR_NAME,
             60 LS_RESULT-APPR_MAIL,
             84 LS_RESULT-STATUS,
             88 LS_RESULT-EXC_FLAG,
             92(60) LS_RESULT-EXC_REASON,
             155 LS_RESULT-MESSAGE.
  ENDLOOP.

*&---------------------------------------------------------------*
*& Form F_BUILD_EMAIL  -- gabung username + domain jadi email
*&   TEXT2 kosong => TEXT1 dianggap email penuh (kompatibel data lama)
*&---------------------------------------------------------------*
FORM F_BUILD_EMAIL USING P_T1 TYPE ZMAP_TYPE-TEXT1
                         P_T2 TYPE ZMAP_TYPE-TEXT2
                   CHANGING P_EMAIL TYPE AD_SMTPADR.
  DATA: LV_T1 TYPE ZMAP_TYPE-TEXT1,
        LV_T2 TYPE ZMAP_TYPE-TEXT2.
  CLEAR P_EMAIL.
  LV_T1 = P_T1.
  LV_T2 = P_T2.
  CONDENSE LV_T1 NO-GAPS.
  CONDENSE LV_T2 NO-GAPS.
  IF LV_T2 IS INITIAL.
    P_EMAIL = LV_T1.
  ELSE.
    CONCATENATE LV_T1 LV_T2 INTO P_EMAIL.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------*
*& Form F_ADD_HTML  -- tambah 1 baris ke body HTML email
*&---------------------------------------------------------------*
FORM F_ADD_HTML USING P_LINE TYPE STRING.
  CLEAR GS_BODY.
  GS_BODY-LINE = P_LINE.
  APPEND GS_BODY TO GT_BODY.
ENDFORM.

*&---------------------------------------------------------------*
*& Form F_SEND_ALL  -- kirim email per grup approver (control break)
*&---------------------------------------------------------------*
FORM F_SEND_ALL.
  IF GT_MAIL IS INITIAL.
    RETURN.
  ENDIF.

  SORT GT_MAIL BY APPR_OPT EBELN.

  LOOP AT GT_MAIL INTO LS_MAIL.

    AT NEW APPR_OPT.
      PERFORM F_MAIL_START USING LS_MAIL-APPR_OPT.
    ENDAT.

    PERFORM F_MAIL_ROW USING LS_MAIL.

    AT END OF APPR_OPT.
      PERFORM F_MAIL_SEND USING LS_MAIL-APPR_OPT.
    ENDAT.

  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------*
*& Form F_MAIL_START  -- inisialisasi body + recipients per grup
*&---------------------------------------------------------------*
FORM F_MAIL_START USING P_OPT TYPE ZMAP_TYPE-OPT.
  DATA: LV_LINE  TYPE STRING,
        LV_MAIL  TYPE AD_SMTPADR,
        LV_NM    TYPE STRING,
        LV_SEX   TYPE C LENGTH 1,
        LV_NAMES TYPE STRING.

  REFRESH: GT_BODY, GT_RCP.
  CLEAR: GV_XLS_XML, LV_NAMES.

* Recipients: semua approver grup ini (jadi TO). Sekalian susun
* sapaan dari kolom VALUE (nama apa adanya) + TEXT3 (gender):
*   M = 'Bapak <nama>', F = 'Ibu <nama>', kosong = '<nama>' saja.
  LOOP AT LT_APPROVER INTO LS_APPROVER WHERE OPT = P_OPT.
    CLEAR LV_MAIL.
    PERFORM F_BUILD_EMAIL USING LS_APPROVER-TEXT1 LS_APPROVER-TEXT2
                          CHANGING LV_MAIL.
    IF LV_MAIL CS '@'.
      APPEND LV_MAIL TO GT_RCP.
    ENDIF.
    CLEAR: LV_NM, LV_SEX.
    LV_NM  = LS_APPROVER-VALUE.
    LV_SEX = LS_APPROVER-TEXT3.
    CONDENSE LV_NM.
    CONDENSE LV_SEX NO-GAPS.
    TRANSLATE LV_SEX TO UPPER CASE.
    IF LV_NM IS NOT INITIAL.
      IF LV_SEX EQ 'M'.
        CONCATENATE 'Bapak' LV_NM INTO LV_NM SEPARATED BY SPACE.
      ELSEIF LV_SEX EQ 'F'.
        CONCATENATE 'Ibu' LV_NM INTO LV_NM SEPARATED BY SPACE.
      ENDIF.
    ENDIF.
    IF LV_NM IS NOT INITIAL.
      IF LV_NAMES IS INITIAL.
        LV_NAMES = LV_NM.
      ELSE.
        CONCATENATE LV_NAMES LV_NM INTO LV_NAMES SEPARATED BY ', '.
      ENDIF.
    ENDIF.
  ENDLOOP.
  IF LV_NAMES IS INITIAL.
    LV_NAMES = 'Bapak/Ibu Approver'.
  ENDIF.

* HTML header
  PERFORM F_ADD_HTML USING '<html><body style="font-family:Arial,sans-serif;font-size:13px;color:#1F2328;">'.
  CONCATENATE '<p>Yth.' LV_NAMES INTO LV_LINE SEPARATED BY SPACE.
  CONCATENATE LV_LINE ',</p>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<p>Berikut Purchase Order yang menunggu persetujuan Anda (grup'
              P_OPT INTO LV_LINE SEPARATED BY SPACE.
  CONCATENATE LV_LINE '):</p>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  PERFORM F_ADD_HTML USING '<table border="1" cellspacing="0" cellpadding="5" style="border-collapse:collapse;font-size:12px;">'.
  PERFORM F_ADD_HTML USING '<tr style="background:#2F3A46;color:#ffffff;">'.
  PERFORM F_ADD_HTML USING '<th>No PO</th><th>Vendor</th><th>Nilai (USD)</th><th>Tier</th><th>Flag</th><th>Alasan Exception</th></tr>'.

ENDFORM.

*&---------------------------------------------------------------*
*& Form F_MAIL_ROW  -- tambah 1 baris PO ke body HTML
*&---------------------------------------------------------------*
FORM F_MAIL_ROW USING P_MAIL TYPE TY_MAIL.
  DATA: LV_LINE  TYPE STRING,
        LV_USD   TYPE C LENGTH 20,
        LV_FLAG  TYPE STRING,
        LV_STYLE TYPE STRING,
        LV_REAS  TYPE STRING,
        LV_EBELN TYPE C LENGTH 10.

  WRITE P_MAIL-USDVAL TO LV_USD.
  CONDENSE LV_USD.
  LV_EBELN = P_MAIL-EBELN.
  LV_REAS  = P_MAIL-EXC_REASON.
* Ubah token exception jadi label ramah + beri spasi antar-token.
  PERFORM F_PRETTY_REASON CHANGING LV_REAS.
  IF LV_REAS IS INITIAL.
    LV_REAS = '-'.
  ENDIF.

  IF P_MAIL-EXC_FLAG EQ 'X'.
    LV_STYLE = ' style="background:#FBECEC;"'.
    LV_FLAG  = '<span style="color:#B03636;font-weight:bold;">Perhatian</span>'.
  ELSE.
    CLEAR LV_STYLE.
    LV_FLAG  = '<span style="color:#2E7D32;">OK</span>'.
  ENDIF.

  CONCATENATE '<tr' LV_STYLE '>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<td>' LV_EBELN '</td>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<td>' P_MAIL-LIFNR '</td>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<td align="right">' LV_USD '</td>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<td align="center">' P_MAIL-TIER '</td>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<td align="center">' LV_FLAG '</td>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<td>' LV_REAS '</td></tr>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
ENDFORM.

*&---------------------------------------------------------------*
*& Form F_MAIL_SEND  -- tutup HTML, lampirkan Excel, kirim via CL_BCS
*&---------------------------------------------------------------*
FORM F_MAIL_SEND USING P_OPT TYPE ZMAP_TYPE-OPT.
  DATA: LV_SUBJ TYPE SOOD-OBJDES,
        LV_ATTS TYPE SOOD-OBJDES.

* Tutup tabel + penutup
  PERFORM F_ADD_HTML USING '</table>'.
  PERFORM F_ADD_HTML USING '<p>Baris dengan tanda "Perhatian" memiliki catatan exception. Mohon diperiksa sebelum menyetujui.</p>'.
* Legenda arti flag exception (biar approver paham)
  PERFORM F_ADD_HTML USING '<p style="font-size:11px;color:#444;"><b>Keterangan flag:</b></p>'.
  PERFORM F_ADD_HTML USING '<ul style="font-size:11px;color:#444;margin-top:0;">'.
  PERFORM F_ADD_HTML USING '<li><b>Vendor Baru</b> = vendor baru (&lt; 90 hari) atau belum pernah bertransaksi.</li>'.
  PERFORM F_ADD_HTML USING '<li><b>Material Baru</b> = material baru (&lt; 90 hari) atau belum pernah dibeli.</li>'.
  PERFORM F_ADD_HTML USING '<li><b>Harga Naik (Material)</b> = harga naik &gt; 10% dibanding harga terakhir material ini (vendor manapun).</li>'.
  PERFORM F_ADD_HTML USING '<li><b>Harga Naik (Vendor)</b> = harga naik &gt; 10% dibanding harga terakhir dari vendor yang sama.</li>'.
  PERFORM F_ADD_HTML USING '<li><b>Histori Usang</b> = pembelian terakhir &gt; 24 bulan lalu (harga acuan usang).</li>'.
  PERFORM F_ADD_HTML USING '<li><b>Jasa/Capex</b> = PO jasa atau aset/capex.</li>'.
  PERFORM F_ADD_HTML USING '</ul>'.
  PERFORM F_ADD_HTML USING '<p>Mohon lakukan persetujuan melalui transaksi ME29N.</p>'.
  PERFORM F_ADD_HTML USING '<p style="color:#6B7280;font-size:11px;">Email ini dikirim otomatis oleh sistem. Mohon tidak membalas email ini.</p>'.
  PERFORM F_ADD_HTML USING '</body></html>'.

* Tidak ada penerima valid -> lewati
  IF GT_RCP IS INITIAL.
    RETURN.
  ENDIF.

* Bangun lampiran SpreadsheetML (.XLS) untuk grup approver ini.
* Tanggal Indonesia dipakai konsisten di subject, nama file, dan header.
  PERFORM F_FORMAT_DATE_ID USING SY-DATUM CHANGING GV_DATE_ID.
  PERFORM F_BUILD_XLS USING P_OPT GV_DATE_ID CHANGING GV_XLS_XML.
  CONCATENATE 'Detail PO -' GV_DATE_ID INTO LV_ATTS
              SEPARATED BY SPACE.

* Test mode: tidak mengirim, hanya catat di list output
  IF P_TEST EQ 'X'.
    WRITE: / 'TEST MODE - email TIDAK dikirim. Grup:', P_OPT.
    WRITE: / '   would-attach XLS:', LV_ATTS.
    LOOP AT GT_RCP INTO LV_MAILTO.
      WRITE: / '   would-send TO:', LV_MAILTO.
    ENDLOOP.
    RETURN.
  ENDIF.

  CONCATENATE 'PO Menunggu Persetujuan -' GV_DATE_ID
              INTO LV_SUBJ SEPARATED BY SPACE.

  TRY.
      LO_SEND = CL_BCS=>CREATE_PERSISTENT( ).

      LO_DOC = CL_DOCUMENT_BCS=>CREATE_DOCUMENT(
                 I_TYPE    = 'HTM'
                 I_TEXT    = GT_BODY
                 I_SUBJECT = LV_SUBJ ).

*     Lampiran Excel SpreadsheetML (.XLS), mengikuti pola ZPPI_COHVPI.
      CLEAR: GV_XSTR, GT_BIN.
      CALL FUNCTION 'HR_KR_STRING_TO_XSTRING'
        EXPORTING
          CODEPAGE_TO      = '4110'
          UNICODE_STRING   = GV_XLS_XML
        IMPORTING
          XSTRING_STREAM   = GV_XSTR
        EXCEPTIONS
          INVALID_CODEPAGE = 1
          INVALID_STRING   = 2
          OTHERS           = 3.
      IF SY-SUBRC EQ 0.
        CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
          EXPORTING
            BUFFER     = GV_XSTR
          TABLES
            BINARY_TAB = GT_BIN.
        LO_DOC->ADD_ATTACHMENT(
          I_ATTACHMENT_TYPE    = 'XLS'
          I_ATTACHMENT_SUBJECT = LV_ATTS
          I_ATT_CONTENT_HEX    = GT_BIN ).
      ENDIF.

      LO_SEND->SET_DOCUMENT( LO_DOC ).

      LO_SENDER = CL_SAPUSER_BCS=>CREATE( SY-UNAME ).
      LO_SEND->SET_SENDER( I_SENDER = LO_SENDER ).

      LOOP AT GT_RCP INTO LV_MAILTO.
        CLEAR LO_RECIP.
        LO_RECIP = CL_CAM_ADDRESS_BCS=>CREATE_INTERNET_ADDRESS( LV_MAILTO ).
        LO_SEND->ADD_RECIPIENT( I_RECIPIENT = LO_RECIP ).
      ENDLOOP.

      LO_SEND->SEND( I_WITH_ERROR_SCREEN = 'X' ).
      COMMIT WORK.
      WRITE: / 'Email terkirim untuk grup:', P_OPT.

    CATCH CX_BCS INTO LX_BCS.
      GV_ERR = LX_BCS->GET_TEXT( ).
      WRITE: / 'Email GAGAL grup', P_OPT, ':', GV_ERR.
  ENDTRY.
ENDFORM.

*&---------------------------------------------------------------*
*& Form F_FORMAT_DATE_ID -- format tanggal: 29 Juli 2026
*&---------------------------------------------------------------*
FORM F_FORMAT_DATE_ID USING P_DATE TYPE SY-DATUM
                      CHANGING P_TEXT TYPE STRING.
  DATA: LV_DAY   TYPE C LENGTH 2,
        LV_MONTH TYPE C LENGTH 2,
        LV_YEAR  TYPE C LENGTH 4,
        LV_NAME  TYPE STRING.

  CLEAR: P_TEXT, LV_DAY, LV_MONTH, LV_YEAR, LV_NAME.
  LV_DAY   = P_DATE+6(2).
  LV_MONTH = P_DATE+4(2).
  LV_YEAR  = P_DATE(4).

  CASE LV_MONTH.
    WHEN '01'. LV_NAME = 'Januari'.
    WHEN '02'. LV_NAME = 'Februari'.
    WHEN '03'. LV_NAME = 'Maret'.
    WHEN '04'. LV_NAME = 'April'.
    WHEN '05'. LV_NAME = 'Mei'.
    WHEN '06'. LV_NAME = 'Juni'.
    WHEN '07'. LV_NAME = 'Juli'.
    WHEN '08'. LV_NAME = 'Agustus'.
    WHEN '09'. LV_NAME = 'September'.
    WHEN '10'. LV_NAME = 'Oktober'.
    WHEN '11'. LV_NAME = 'November'.
    WHEN '12'. LV_NAME = 'Desember'.
  ENDCASE.

  CONCATENATE LV_DAY LV_NAME LV_YEAR INTO P_TEXT SEPARATED BY SPACE.
ENDFORM.

*&---------------------------------------------------------------*
*& Form F_XML_ESC -- amankan teks untuk SpreadsheetML XML
*&---------------------------------------------------------------*
FORM F_XML_ESC CHANGING P_TEXT TYPE STRING.
  REPLACE ALL OCCURRENCES OF '&' IN P_TEXT WITH '&amp;'.
  REPLACE ALL OCCURRENCES OF '<' IN P_TEXT WITH '&lt;'.
  REPLACE ALL OCCURRENCES OF '>' IN P_TEXT WITH '&gt;'.
  REPLACE ALL OCCURRENCES OF '"' IN P_TEXT WITH '&quot;'.
ENDFORM.

*&---------------------------------------------------------------*
*& Form F_BUILD_XLS -- Excel SpreadsheetML mengikuti ZPPI_COHVPI
*& Header biru, kolom tetap, AutoFilter, freeze header, dan
*& baris merah muda untuk PO dengan exception.
*&---------------------------------------------------------------*
FORM F_BUILD_XLS USING P_OPT  TYPE ZMAP_TYPE-OPT
                       P_DATE TYPE STRING
                 CHANGING P_XML TYPE STRING.
  DATA: LT_X      TYPE STANDARD TABLE OF STRING,
        LS_MAIL   TYPE TY_MAIL,
        LV_NL     TYPE STRING,
        LV_ROW    TYPE STRING,
        LV_EBELN  TYPE STRING,
        LV_VENDOR TYPE STRING,
        LV_USD    TYPE STRING,
        LV_TIER   TYPE STRING,
        LV_FLAG   TYPE STRING,
        LV_REAS   TYPE STRING,
        LV_STYLE  TYPE STRING,
        LV_NSTYLE TYPE STRING.

  CLEAR P_XML.
  LV_NL = CL_ABAP_CHAR_UTILITIES=>NEWLINE.

* SpreadsheetML 2003: dibuka langsung oleh Microsoft Excel sebagai XLS.
  APPEND '<?xml version="1.0"?>' TO LT_X.
  APPEND '<?mso-application progid="Excel.Sheet"?>' TO LT_X.
  APPEND '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"' TO LT_X.
  APPEND ' xmlns:o="urn:schemas-microsoft-com:office:office"' TO LT_X.
  APPEND ' xmlns:x="urn:schemas-microsoft-com:office:excel"' TO LT_X.
  APPEND ' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">' TO LT_X.

  APPEND '<Styles>' TO LT_X.
  APPEND '<Style ss:ID="title"><Font ss:Bold="1" ss:Size="14" ss:Color="#1F1F1F"/>' TO LT_X.
  APPEND '<Alignment ss:Horizontal="Left" ss:Vertical="Center"/></Style>' TO LT_X.
  APPEND '<Style ss:ID="sub"><Font ss:Italic="1" ss:Color="#666666"/>' TO LT_X.
  APPEND '<Alignment ss:Horizontal="Left" ss:Vertical="Center"/></Style>' TO LT_X.
  APPEND '<Style ss:ID="header"><Font ss:Bold="1" ss:Color="#FFFFFF"/>' TO LT_X.
  APPEND '<Interior ss:Color="#1F4E78" ss:Pattern="Solid"/>' TO LT_X.
  APPEND '<Alignment ss:Horizontal="Center" ss:Vertical="Center"/>' TO LT_X.
  APPEND '<Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous"/>' TO LT_X.
  APPEND '<Border ss:Position="Top" ss:LineStyle="Continuous"/>' TO LT_X.
  APPEND '<Border ss:Position="Left" ss:LineStyle="Continuous"/>' TO LT_X.
  APPEND '<Border ss:Position="Right" ss:LineStyle="Continuous"/></Borders></Style>' TO LT_X.
  APPEND '<Style ss:ID="text"><NumberFormat ss:Format="@"/></Style>' TO LT_X.
  APPEND '<Style ss:ID="number"><NumberFormat ss:Format="#,##0.00"/>' TO LT_X.
  APPEND '<Alignment ss:Horizontal="Right"/></Style>' TO LT_X.
  APPEND '<Style ss:ID="warn"><Interior ss:Color="#FCE4D6" ss:Pattern="Solid"/>' TO LT_X.
  APPEND '<NumberFormat ss:Format="@"/></Style>' TO LT_X.
  APPEND '<Style ss:ID="warnnum"><Interior ss:Color="#FCE4D6" ss:Pattern="Solid"/>' TO LT_X.
  APPEND '<NumberFormat ss:Format="#,##0.00"/><Alignment ss:Horizontal="Right"/></Style>' TO LT_X.
  APPEND '</Styles>' TO LT_X.

  APPEND '<Worksheet ss:Name="PO Approval"><Table>' TO LT_X.
  APPEND '<Column ss:Width="100"/><Column ss:Width="125"/>' TO LT_X.
  APPEND '<Column ss:Width="95"/><Column ss:Width="55"/>' TO LT_X.
  APPEND '<Column ss:Width="95"/><Column ss:Width="260"/>' TO LT_X.
  APPEND '<Row ss:Height="24"><Cell ss:StyleID="title" ss:MergeAcross="5">' TO LT_X.
  APPEND '<Data ss:Type="String">Detail PO Menunggu Persetujuan</Data></Cell></Row>' TO LT_X.
  CONCATENATE '<Row><Cell ss:StyleID="sub" ss:MergeAcross="5"><Data ss:Type="String">Tanggal Pengiriman: '
              P_DATE '</Data></Cell></Row>' INTO LV_ROW.
  APPEND LV_ROW TO LT_X.
  CONCATENATE '<Row><Cell ss:StyleID="sub" ss:MergeAcross="5"><Data ss:Type="String">Grup Approver: '
              P_OPT '</Data></Cell></Row>' INTO LV_ROW.
  APPEND LV_ROW TO LT_X.
  APPEND '<Row><Cell ss:StyleID="header"><Data ss:Type="String">No. PO</Data></Cell>' TO LT_X.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Vendor</Data></Cell>' TO LT_X.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Nilai (USD)</Data></Cell>' TO LT_X.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Tier</Data></Cell>' TO LT_X.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Flag</Data></Cell>' TO LT_X.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Alasan Exception</Data></Cell></Row>' TO LT_X.

  LOOP AT LT_MAIL INTO LS_MAIL WHERE APPR_OPT = P_OPT.
    CLEAR: LV_EBELN, LV_VENDOR, LV_USD, LV_TIER, LV_FLAG, LV_REAS,
           LV_STYLE, LV_NSTYLE.
    LV_EBELN  = LS_MAIL-EBELN.
    LV_VENDOR = LS_MAIL-LIFNR.
    LV_TIER   = LS_MAIL-TIER.
    LV_REAS   = LS_MAIL-EXC_REASON.
    PERFORM F_PRETTY_REASON CHANGING LV_REAS.
    IF LV_REAS IS INITIAL.
      LV_REAS = '-'.
    ENDIF.
    WRITE LS_MAIL-USDVAL TO LV_USD NO-GROUPING DECIMALS 2.
    CONDENSE LV_USD.
    REPLACE ALL OCCURRENCES OF ',' IN LV_USD WITH '.'.
    PERFORM F_XML_ESC CHANGING LV_EBELN.
    PERFORM F_XML_ESC CHANGING LV_VENDOR.
    PERFORM F_XML_ESC CHANGING LV_TIER.
    PERFORM F_XML_ESC CHANGING LV_REAS.

    IF LS_MAIL-EXC_FLAG EQ 'X'.
      LV_FLAG   = 'PERHATIAN'.
      LV_STYLE  = 'warn'.
      LV_NSTYLE = 'warnnum'.
    ELSE.
      LV_FLAG   = 'OK'.
      LV_STYLE  = 'text'.
      LV_NSTYLE = 'number'.
    ENDIF.

    CONCATENATE '<Row><Cell ss:StyleID="' LV_STYLE '"><Data ss:Type="String">'
                LV_EBELN '</Data></Cell><Cell ss:StyleID="' LV_STYLE
                '"><Data ss:Type="String">' LV_VENDOR '</Data></Cell>'
                INTO LV_ROW.
    APPEND LV_ROW TO LT_X.
    CONCATENATE '<Cell ss:StyleID="' LV_NSTYLE '"><Data ss:Type="Number">'
                LV_USD '</Data></Cell><Cell ss:StyleID="' LV_STYLE
                '"><Data ss:Type="String">' LV_TIER '</Data></Cell>'
                INTO LV_ROW.
    APPEND LV_ROW TO LT_X.
    CONCATENATE '<Cell ss:StyleID="' LV_STYLE '"><Data ss:Type="String">'
                LV_FLAG '</Data></Cell><Cell ss:StyleID="' LV_STYLE
                '"><Data ss:Type="String">' LV_REAS
                '</Data></Cell></Row>' INTO LV_ROW.
    APPEND LV_ROW TO LT_X.
  ENDLOOP.

  APPEND '</Table>' TO LT_X.
  APPEND '<AutoFilter x:Range="R4C1:R999C6" xmlns="urn:schemas-microsoft-com:office:excel"/>' TO LT_X.
  APPEND '<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">' TO LT_X.
  APPEND '<FreezePanes/><FrozenNoSplit/><SplitHorizontal>4</SplitHorizontal>' TO LT_X.
  APPEND '<TopRowBottomPane>4</TopRowBottomPane></WorksheetOptions>' TO LT_X.
  APPEND '</Worksheet></Workbook>' TO LT_X.
  CONCATENATE LINES OF LT_X INTO P_XML SEPARATED BY LV_NL.
ENDFORM.

*&---------------------------------------------------------------*
*& Form F_ADD_REASON  -- tambah token reason bila belum ada
*&---------------------------------------------------------------*
FORM F_ADD_REASON USING P_TOKEN TYPE C
                  CHANGING P_REASON TYPE C.
  IF P_REASON CS P_TOKEN.
    RETURN.
  ENDIF.
  IF P_REASON IS INITIAL.
    P_REASON = P_TOKEN.
  ELSE.
    CONCATENATE P_REASON P_TOKEN INTO P_REASON SEPARATED BY ';'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------*
*& Form F_TO_USD  -- konversi amount ke USD di tanggal tertentu
*&---------------------------------------------------------------*
FORM F_TO_USD USING P_AMT TYPE P P_WAERS TYPE WAERS P_DATE TYPE SY-DATUM
              CHANGING P_USD TYPE P.
  DATA: LV_R TYPE RKB1K-EXCHR,
        LV_REAL_AMT TYPE BAPICURR-BAPICURR.
  IF P_WAERS EQ 'USD'.
    P_USD = P_AMT.
    RETURN.
  ENDIF.

  CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_EXTERNAL'
    EXPORTING
      CURRENCY        = P_WAERS
      AMOUNT_INTERNAL = P_AMT
    IMPORTING
      AMOUNT_EXTERNAL = LV_REAL_AMT.

  CLEAR LV_R.
  CALL FUNCTION 'RKC_SINGLE_EXCHANGE_RATE_GET'
    EXPORTING
      DATUM         = P_DATE
      KURST         = 'M'
      NCURR         = 'USD'
      VCURR         = P_WAERS
    IMPORTING
      EXCHR         = LV_R
    EXCEPTIONS
      NO_RATE_FOUND = 1
      OTHERS        = 2.
  IF SY-SUBRC EQ 0.
    P_USD = LV_REAL_AMT * LV_R.
  ELSE.
    P_USD = 0.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------*
*& Form F_GET_LAST  -- harga PO released terakhir utk material
*&                     (opsional filter vendor). EBELN < current.
*&---------------------------------------------------------------*
FORM F_GET_LAST USING P_MATNR TYPE MATNR P_LIFNR TYPE LIFNR
                      P_EBELN TYPE EBELN
                CHANGING P_LAST TYPE TY_LAST P_HAS TYPE C.
  CLEAR: P_LAST, P_HAS.
  IF P_LIFNR IS INITIAL.
    SELECT B~NETPR B~PEINH B~BPRME A~WAERS A~AEDAT
      INTO P_LAST UP TO 1 ROWS
      FROM EKKO AS A INNER JOIN EKPO AS B ON B~EBELN = A~EBELN
      WHERE B~MATNR = P_MATNR
        AND B~LOEKZ = SPACE
        AND A~EBELN < P_EBELN
        AND A~FRGZU = 'X'
        AND A~BSTYP = 'F'
      ORDER BY A~EBELN DESCENDING.
    ENDSELECT.
  ELSE.
    SELECT B~NETPR B~PEINH B~BPRME A~WAERS A~AEDAT
      INTO P_LAST UP TO 1 ROWS
      FROM EKKO AS A INNER JOIN EKPO AS B ON B~EBELN = A~EBELN
      WHERE B~MATNR = P_MATNR
        AND A~LIFNR = P_LIFNR
        AND B~LOEKZ = SPACE
        AND A~EBELN < P_EBELN
        AND A~FRGZU = 'X'
        AND A~BSTYP = 'F'
      ORDER BY A~EBELN DESCENDING.
    ENDSELECT.
  ENDIF.
  IF SY-SUBRC EQ 0.
    P_HAS = 'X'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------*
*& Form F_CHK_NAIK  -- bandingkan harga USD skrg vs harga terakhir
*&                     (normalisasi PEINH + USD), unit BPRME sama.
*&---------------------------------------------------------------*
FORM F_CHK_NAIK USING P_CURUSD TYPE P P_BPRME TYPE BPRME
                      P_LAST TYPE TY_LAST P_TOKEN TYPE C
                CHANGING P_EXC TYPE C P_REASON TYPE C.
  DATA: LV_UNIT TYPE P DECIMALS 4,
        LV_USD  TYPE P DECIMALS 4.
  IF P_LAST-BPRME NE P_BPRME.
    RETURN.
  ENDIF.
  IF P_LAST-PEINH > 0.
    LV_UNIT = P_LAST-NETPR / P_LAST-PEINH.
  ELSE.
    LV_UNIT = P_LAST-NETPR.
  ENDIF.
  PERFORM F_TO_USD USING LV_UNIT P_LAST-WAERS P_LAST-AEDAT
                   CHANGING LV_USD.
  IF LV_USD > 0 AND P_CURUSD > LV_USD * GC_PRICE_TOL.
    P_EXC = 'X'.
    PERFORM F_ADD_REASON USING P_TOKEN CHANGING P_REASON.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------*
*& Form F_PRETTY_REASON  -- token exception -> label ramah + spasi
*&   (hanya utk tampilan; token asli di EXC_REASON tidak berubah)
*&---------------------------------------------------------------*
FORM F_PRETTY_REASON CHANGING P_TXT TYPE STRING.
  REPLACE ALL OCCURRENCES OF 'HrgNaikMat'   IN P_TXT WITH 'Harga Naik (Material)'.
  REPLACE ALL OCCURRENCES OF 'HrgNaikVen'   IN P_TXT WITH 'Harga Naik (Vendor)'.
  REPLACE ALL OCCURRENCES OF 'VendorBaru'   IN P_TXT WITH 'Vendor Baru'.
  REPLACE ALL OCCURRENCES OF 'MaterialBaru' IN P_TXT WITH 'Material Baru'.
  REPLACE ALL OCCURRENCES OF 'StaleHist'    IN P_TXT WITH 'Histori Usang'.
  REPLACE ALL OCCURRENCES OF 'SvcCapex'     IN P_TXT WITH 'Jasa/Capex'.
  REPLACE ALL OCCURRENCES OF ';' IN P_TXT WITH '; '.
ENDFORM.

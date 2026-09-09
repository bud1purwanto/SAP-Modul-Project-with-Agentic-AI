*&---------------------------------------------------------------*
*& Report  ZMMI_PO_EMAIL  (Sprint 2 - Routing + Exception + Email)
*&  Fokus: routing approver Tier T1/T2, exception flagging, dan
*&  notifikasi email per grup approver (multi-recipient, HTML+Excel).
*&  Auto-release (nilai <= threshold auto) DITANGANI Sprint 1
*&  (program ZMMI_PO_RELEASE) -> di program ini PO tsb di-SKIP.
*&---------------------------------------------------------------*

REPORT ZMMI_PO_EMAIL LINE-SIZE 210.

TABLES: EKKO, EKPO.
TYPE-POOLS: SLIS, ICON.

*----------------------------------------------------------------*
* Konfigurasi exception dibaca dinamis dari ZMAP_TYPE:
* PROG=SY-CPROG, TYPE='EXC_RULE', DELETION=SPACE.
*----------------------------------------------------------------*

*----------------------------------------------------------------*
* LEGENDA FLAG EXCEPTION (kolom EXC_REASON / email)
*----------------------------------------------------------------*
* VendorBaru   : Sesuai rule aktif VENDOR_NEW (DAYS/NO_HISTORY).
* MaterialBaru : Sesuai rule aktif MATERIAL_NEW (DAYS/NO_HISTORY).
* HrgNaikMat   : Harga naik di atas PERCENT mapping dibanding MATERIAL
*                ini (dari vendor manapun), dinormalisasi ke USD.
* HrgNaikVen   : Harga naik di atas PERCENT mapping dari
*                VENDOR yang sama untuk material ini.
* StaleHist    : Sesuai mapping PRICE_HISTORY/STALE_DAYS; harga acuan
*                dianggap usang, cek kenaikan harga di-skip.
* SvcCapex     : Sesuai seluruh mapping aktif OPT=PSTYP/KNTTP.
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
         FRGZU TYPE EKKO-FRGZU,
       END OF TY_EKKO.

TYPES: BEGIN OF TY_RELCODE,
         FRGCO TYPE T16FV-FRGCO,
       END OF TY_RELCODE.

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

TYPES: BEGIN OF TY_EXC_RULE,
         OPT   TYPE ZMAP_TYPE-OPT,
         VALUE TYPE ZMAP_TYPE-VALUE,
         TEXT1 TYPE ZMAP_TYPE-TEXT1,
         TEXT2 TYPE ZMAP_TYPE-TEXT2,
         TEXT3 TYPE ZMAP_TYPE-TEXT3,
       END OF TY_EXC_RULE.

TYPES: BEGIN OF TY_EKPOD,
         EBELP TYPE EKPO-EBELP,
         MATNR TYPE EKPO-MATNR,
         WERKS TYPE EKPO-WERKS,
         TXZ01 TYPE EKPO-TXZ01,
         NETPR TYPE EKPO-NETPR,
         PEINH TYPE EKPO-PEINH,
         BPRME TYPE EKPO-BPRME,
         MEINS TYPE EKPO-MEINS,
         NETWR TYPE EKPO-NETWR,
         PSTYP TYPE EKPO-PSTYP,
         KNTTP TYPE EKPO-KNTTP,
         RETPO TYPE EKPO-RETPO,
       END OF TY_EKPOD.

TYPES: BEGIN OF TY_LAST,
         NETPR TYPE EKPO-NETPR,
         PEINH TYPE EKPO-PEINH,
         BPRME TYPE EKPO-BPRME,
         WAERS TYPE EKKO-WAERS,
         BEDAT TYPE EKKO-BEDAT,
       END OF TY_LAST.

* Satu baris = satu ITEM PO (bukan header) sesuai kebutuhan tampilan.
TYPES: BEGIN OF TY_RESULT,
         SEL       TYPE CHAR1,
         LINE_COLOR TYPE CHAR4,
         ICONS     TYPE ICON_D,
         EBELN     TYPE EKKO-EBELN,
         EBELP     TYPE EKPO-EBELP,
         BSART     TYPE EKKO-BSART,
         BSART_DESC TYPE T161T-BATXT,
         LIFNR     TYPE EKKO-LIFNR,
         NAME1     TYPE LFA1-NAME1,
         EKGRP     TYPE EKKO-EKGRP,
         MATNR     TYPE EKPO-MATNR,
         TXZ01     TYPE EKPO-TXZ01,
         WAERS     TYPE EKKO-WAERS,
         PRICE_NATIVE TYPE P DECIMALS 2,
         PRICE_USD    TYPE P DECIMALS 2,
         MEINS        TYPE EKPO-MEINS,
         LAST_PRICE   TYPE P DECIMALS 2,
         NETWR_NATIVE TYPE P DECIMALS 2,
         TOTAL_NETWR  TYPE P DECIMALS 2,
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
* Satu baris = satu ITEM PO, selaras dgn TY_RESULT.
TYPES: BEGIN OF TY_MAIL,
         APPR_OPT   TYPE ZMAP_TYPE-OPT,
         EBELN      TYPE EKKO-EBELN,
         EBELP      TYPE EKPO-EBELP,
         BSART      TYPE EKKO-BSART,
         BSART_DESC TYPE T161T-BATXT,
         LIFNR      TYPE EKKO-LIFNR,
         NAME1      TYPE LFA1-NAME1,
         MATNR      TYPE EKPO-MATNR,
         TXZ01      TYPE EKPO-TXZ01,
         WAERS      TYPE EKKO-WAERS,
         PRICE_NATIVE TYPE P DECIMALS 2,
         PRICE_USD    TYPE P DECIMALS 2,
         MEINS      TYPE EKPO-MEINS,
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
      LT_EXC_RULE  TYPE STANDARD TABLE OF TY_EXC_RULE,
      LS_EXC_RULE  TYPE TY_EXC_RULE,
      LT_EKPOD     TYPE STANDARD TABLE OF TY_EKPOD,
      LS_EKPOD     TYPE TY_EKPOD,
      LT_RESULT    TYPE STANDARD TABLE OF TY_RESULT,
      LS_RESULT    TYPE TY_RESULT,
      LS_RESULT_HDR TYPE TY_RESULT,
      GT_MAIL      TYPE STANDARD TABLE OF TY_MAIL,
      LS_MAIL      TYPE TY_MAIL,
      GT_SELECTED_EBELN TYPE STANDARD TABLE OF EKKO-EBELN.

* Exception level VENDOR (berlaku sama utk semua item dalam 1 PO)
DATA: LV_EXC_VEND    TYPE CHAR1,
      LV_REASON_VEND TYPE C LENGTH 120.

DATA: LV_NETWR     TYPE EKPO-NETWR,
      LV_REAL_NETWR TYPE BAPICURR-BAPICURR,
      LV_TOTAL_NETWR TYPE P DECIMALS 2,
      LV_USDVAL    TYPE P DECIMALS 2,
      LV_KURS      TYPE RKB1K-EXCHR,
      LV_LINES     TYPE I,
      LV_FOUND     TYPE CHAR1,
      LV_AUTO      TYPE CHAR1,
      LV_APPROPT   TYPE ZMAP_TYPE-OPT,
      LV_MAILTO    TYPE AD_SMTPADR.

* Kerja exception
DATA: LV_EXC        TYPE CHAR1,
      LV_CUTVEND    TYPE SY-DATUM,
      LV_CUTMAT     TYPE SY-DATUM,
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

* Konfigurasi exception aktif (tidak ada baris = rule nonaktif)
DATA: LV_RULE_VEND_HIST TYPE CHAR1,
      LV_RULE_VEND_DAYS TYPE CHAR1,
      LV_RULE_MAT_HIST  TYPE CHAR1,
      LV_RULE_MAT_DAYS  TYPE CHAR1,
      LV_RULE_PRICE     TYPE CHAR1,
      LV_RULE_PRICE_MAT TYPE CHAR1,
      LV_RULE_PRICE_VEN TYPE CHAR1,
      LV_RULE_STALE     TYPE CHAR1,
      LV_VENDOR_DAYS    TYPE I,
      LV_MATERIAL_DAYS  TYPE I,
      LV_STALE_DAYS     TYPE I,
      LV_STALE_MONTHS   TYPE I,
      LV_PRICE_PCT      TYPE P DECIMALS 2,
      LV_PRICE_FACTOR   TYPE P DECIMALS 4,
      LV_RULEVAL        TYPE ZMAP_TYPE-VALUE,
      LV_CFGTXT         TYPE ZMAP_TYPE-TEXT1.

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

* Objek ALV untuk mode report user (foreground).
DATA: GT_FIELDCAT TYPE SLIS_T_FIELDCAT_ALV,
      GS_FIELDCAT TYPE SLIS_FIELDCAT_ALV,
      GS_LAYOUT   TYPE SLIS_LAYOUT_ALV.

*----------------------------------------------------------------*
* Class LCL_EVENT_HANDLER -- Event handler toolbar & command ALV
*----------------------------------------------------------------*
CLASS LCL_EVENT_HANDLER DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      ON_TOOLBAR FOR EVENT TOOLBAR OF CL_GUI_ALV_GRID
        IMPORTING E_OBJECT E_INTERACTIVE,
      ON_USER_COMMAND FOR EVENT USER_COMMAND OF CL_GUI_ALV_GRID
        IMPORTING E_UCOMM.
ENDCLASS.                    "LCL_EVENT_HANDLER DEFINITION

CLASS LCL_EVENT_HANDLER IMPLEMENTATION.
  METHOD ON_TOOLBAR.
    DATA: LS_TOOLBAR TYPE STB_BUTTON.

    " Sisipkan tombol Release PO di posisi PALING KIRI (Index 1)
    CLEAR LS_TOOLBAR.
    LS_TOOLBAR-FUNCTION  = 'REL_PO'.
    LS_TOOLBAR-ICON      = ICON_RELEASE. " '@0V@' (Centang Hijau)
    LS_TOOLBAR-TEXT      = 'Release PO'.
    LS_TOOLBAR-QUICKINFO = 'Release PO Terpilih'.
    LS_TOOLBAR-BUTN_TYPE = 0. " Normal Button
    INSERT LS_TOOLBAR INTO E_OBJECT->MT_TOOLBAR INDEX 1.

    " Tambahkan pemisah di sebelah kanan tombol (Index 2)
    CLEAR LS_TOOLBAR.
    LS_TOOLBAR-BUTN_TYPE = 3. " Separator
    INSERT LS_TOOLBAR INTO E_OBJECT->MT_TOOLBAR INDEX 2.
  ENDMETHOD.                    "ON_TOOLBAR

  METHOD ON_USER_COMMAND.
    DATA: LR_GRID TYPE REF TO CL_GUI_ALV_GRID,
          LS_STBL TYPE LVC_S_STBL,
          LV_IDX  TYPE SY-TABIX.

    IF E_UCOMM EQ 'REL_PO'.
      PERFORM F_RELEASE_SELECTED_PO.

      CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
        IMPORTING
          E_GRID = LR_GRID.

      IF LR_GRID IS BOUND.
        LS_STBL-ROW = 'X'.
        LS_STBL-COL = 'X'.
        CALL METHOD LR_GRID->REFRESH_TABLE_DISPLAY
          EXPORTING
            IS_STABLE = LS_STBL.
      ENDIF.
    ENDIF.
  ENDMETHOD.                    "ON_USER_COMMAND
ENDCLASS.                    "LCL_EVENT_HANDLER IMPLEMENTATION

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
PARAMETERS: P_RPT  RADIOBUTTON GROUP G1 USER-COMMAND G1 DEFAULT 'X',
            P_MAIL RADIOBUTTON GROUP G1.
SELECTION-SCREEN END OF BLOCK B2.

SELECTION-SCREEN BEGIN OF BLOCK B3 WITH FRAME TITLE TEXT-003.
PARAMETERS: P_VARI   TYPE DISVARIANT-VARIANT MODIF ID RPT,
            P_TEST   TYPE C AS CHECKBOX DEFAULT 'X' MODIF ID TST,
            P_SENDER TYPE AD_SMTPADR LOWER CASE DEFAULT 'po-approval@trst.co.id' MODIF ID TST,
            P_NAME   TYPE AD_SMTPADR LOWER CASE DEFAULT 'PO Approval Notification' MODIF ID TST.
SELECTION-SCREEN END OF BLOCK B3.

*----------------------------------------------------------------*
* INITIALIZATION -- Inisialisasi default layout ALV
*----------------------------------------------------------------*
INITIALIZATION.
  PERFORM F_INIT_LAYOUT.

*----------------------------------------------------------------*
* AT SELECTION-SCREEN ON VALUE-REQUEST -- F4 Help untuk Layout ALV
*----------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR P_VARI.
  PERFORM F_F4_LAYOUT.

*----------------------------------------------------------------*
* AT SELECTION-SCREEN ON P_VARI -- Validasi eksistensi Layout ALV
*----------------------------------------------------------------*
AT SELECTION-SCREEN ON P_VARI.
  PERFORM F_VALIDATE_LAYOUT.

*----------------------------------------------------------------*
* Block B3 (Options):
* - Mode Report: Menampilkan List Layout (P_VARI).
* - Mode Send Email: Menampilkan Test Run, Sender Email, Sender Name.
* USER-COMMAND pada radio button memicu refresh segera saat mode diganti.
*----------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.
  IF P_VARI IS INITIAL.
    PERFORM F_INIT_LAYOUT.
  ENDIF.

  LOOP AT SCREEN.
    IF SCREEN-GROUP1 EQ 'TST'.
      IF P_RPT EQ 'X'.
        SCREEN-ACTIVE = 0.
      ELSE.
        SCREEN-ACTIVE = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.

    IF SCREEN-GROUP1 EQ 'RPT'.
      IF P_RPT EQ 'X'.
        SCREEN-ACTIVE = 1.
      ELSE.
        SCREEN-ACTIVE = 0.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

*----------------------------------------------------------------*
START-OF-SELECTION.

  IF P_RPT EQ 'X' AND P_VARI IS INITIAL.
    PERFORM F_INIT_LAYOUT.
  ENDIF.

*----------------------------------------------------------------*
* 1. Load mapping THRESHOLD (semua tier) dari ZMAP_TYPE
*----------------------------------------------------------------*
  REFRESH LT_THRESHOLD.
  SELECT OPT VALUE TEXT1
    INTO CORRESPONDING FIELDS OF TABLE LT_THRESHOLD
    FROM ZMAP_TYPE
    WHERE PROG = SY-CPROG
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
    WHERE PROG = SY-CPROG
      AND TYPE = 'APPROVER'
      AND DELETION = SPACE.

  IF LT_APPROVER IS INITIAL.
    WRITE: / 'Mapping APPROVER belum ada di ZMAP_TYPE. Program dihentikan.'.
    EXIT.
  ENDIF.

  SORT LT_APPROVER BY OPT VALUE.

*----------------------------------------------------------------*
* 3. Load konfigurasi EXC_RULE (baris aktif saja)
*----------------------------------------------------------------*
  REFRESH LT_EXC_RULE.
  SELECT OPT VALUE TEXT1 TEXT2 TEXT3
    INTO CORRESPONDING FIELDS OF TABLE LT_EXC_RULE
    FROM ZMAP_TYPE
    WHERE PROG = SY-CPROG
      AND TYPE = 'EXC_RULE'
      AND DELETION = SPACE.

  SORT LT_EXC_RULE BY OPT VALUE.
  CLEAR: LV_RULE_VEND_HIST, LV_RULE_VEND_DAYS,
         LV_RULE_MAT_HIST, LV_RULE_MAT_DAYS,
         LV_RULE_PRICE, LV_RULE_PRICE_MAT, LV_RULE_PRICE_VEN,
         LV_RULE_STALE,
         LV_VENDOR_DAYS, LV_MATERIAL_DAYS, LV_STALE_DAYS,
         LV_PRICE_PCT, LV_PRICE_FACTOR.

* Rule vendor/material tanpa histori aktif berdasarkan keberadaan baris.
  READ TABLE LT_EXC_RULE INTO LS_EXC_RULE
    WITH KEY OPT = 'VENDOR_NEW' VALUE = 'NO_HISTORY'
    BINARY SEARCH.
  IF SY-SUBRC EQ 0.
    LV_RULE_VEND_HIST = 'X'.
  ENDIF.

  READ TABLE LT_EXC_RULE INTO LS_EXC_RULE
    WITH KEY OPT = 'MATERIAL_NEW' VALUE = 'NO_HISTORY'
    BINARY SEARCH.
  IF SY-SUBRC EQ 0.
    LV_RULE_MAT_HIST = 'X'.
  ENDIF.

* Persentase disimpan sebagai angka bisnis: 10 berarti 10 persen.
  READ TABLE LT_EXC_RULE INTO LS_EXC_RULE
    WITH KEY OPT = 'PRICE_INCREASE' VALUE = 'PERCENT'
    BINARY SEARCH.
  IF SY-SUBRC EQ 0.
    LV_CFGTXT = LS_EXC_RULE-TEXT1.
    CONDENSE LV_CFGTXT NO-GAPS.
    TRY.
        LV_PRICE_PCT = LV_CFGTXT.
        IF LV_PRICE_PCT GE 0.
          LV_RULE_PRICE = 'X'.
          LV_PRICE_FACTOR = 1 + ( LV_PRICE_PCT / 100 ).
        ELSE.
          WRITE: / 'WARNING EXC_RULE PRICE_INCREASE/PERCENT negatif; rule di-skip.'.
        ENDIF.
      CATCH CX_SY_CONVERSION_ERROR.
        WRITE: / 'WARNING EXC_RULE PRICE_INCREASE/PERCENT bukan angka; rule di-skip.'.
    ENDTRY.
  ENDIF.

* Pembanding harga diaktifkan terpisah melalui mapping.
* MATERIAL = harga terakhir material dari vendor mana pun.
  READ TABLE LT_EXC_RULE INTO LS_EXC_RULE
    WITH KEY OPT = 'PRICE_INCREASE' VALUE = 'MATERIAL'
    BINARY SEARCH.
  IF SY-SUBRC EQ 0.
    LV_RULE_PRICE_MAT = 'X'.
  ENDIF.

*----------------------------------------------------------------*
* 4. Ambil PO yang masih PENDING RELEASE (FRGRL = 'X')
*----------------------------------------------------------------*
  REFRESH LT_EKKO.
  SELECT EBELN BUKRS EKORG EKGRP BSART FRGRL FRGGR FRGSX WAERS BEDAT LIFNR LOEKZ FRGZU
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
* 4. Proses tiap PO (satu baris output per ITEM PO)
*----------------------------------------------------------------*
  LOOP AT LT_EKKO INTO LS_EKKO.

    CLEAR: LS_RESULT, LS_RESULT_HDR, LV_NETWR, LV_TOTAL_NETWR, LV_USDVAL, LV_AUTO, LV_APPROPT.
    IF LS_EKKO-FRGZU EQ 'X' OR LS_EKKO-FRGRL IS INITIAL.
      LS_RESULT-ICONS = '@08@'.   " Hijau (Released)
    ELSE.
      LS_RESULT-ICONS = '@09@'.   " Kuning (Belum Release)
    ENDIF.
    LS_RESULT-EBELN = LS_EKKO-EBELN.
    LS_RESULT-LIFNR = LS_EKKO-LIFNR.
    LS_RESULT-EKGRP = LS_EKKO-EKGRP.
    LS_RESULT-BSART = LS_EKKO-BSART.

    SELECT SINGLE NAME1 INTO LS_RESULT-NAME1
      FROM LFA1
      WHERE LIFNR = LS_EKKO-LIFNR.

    CLEAR LS_RESULT-BSART_DESC.
    SELECT SINGLE BATXT INTO LS_RESULT-BSART_DESC
      FROM T161T
      WHERE BSART = LS_EKKO-BSART
        AND SPRAS = SY-LANGU.

*   --- 4a. Total nilai PO ---
    SELECT SUM( NETWR ) INTO LV_NETWR
      FROM EKPO
      WHERE EBELN = LS_EKKO-EBELN
        AND LOEKZ EQ SPACE.

*   --- 4b. Konversi ke USD pakai KURS PADA TANGGAL PO (BEDAT) ---
    CLEAR: LV_TOTAL_NETWR.
    IF LS_EKKO-WAERS EQ 'USD'.
      LV_TOTAL_NETWR = LV_NETWR.
      LV_USDVAL      = LV_NETWR.
    ELSE.
      CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_EXTERNAL'
        EXPORTING
          CURRENCY        = LS_EKKO-WAERS
          AMOUNT_INTERNAL = LV_NETWR
        IMPORTING
          AMOUNT_EXTERNAL = LV_REAL_NETWR.

      LV_TOTAL_NETWR = LV_REAL_NETWR.

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
        LS_RESULT-TOTAL_NETWR = LV_TOTAL_NETWR.
        LS_RESULT-STATUS      = 'E'.
        LS_RESULT-MESSAGE     = 'Kurs (TCURR, KURST=M) pada tanggal PO (BEDAT) tidak ditemukan -- skip, wajib manual'.
        APPEND LS_RESULT TO LT_RESULT.
        CONTINUE.
      ENDIF.

      LV_USDVAL = LV_REAL_NETWR * LV_KURS.
    ENDIF.

    LS_RESULT-TOTAL_NETWR = LV_TOTAL_NETWR.
    LS_RESULT-USDVAL      = LV_USDVAL.

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
        LV_APPROPT = 'GM'.
        READ TABLE LT_APPROVER INTO LS_APPROVER WITH KEY OPT = 'GM'.
      ELSE.
*       T1: utamakan mapping Purchasing Group dari EKKO-EKGRP.
*       Jika tidak ada, gunakan DEFAULT. Variant job membatasi scope PO.
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
          LS_RESULT-MESSAGE = 'Tidak ada mapping GM Purchasing (OPT=GM) di ZMAP_TYPE'.
        ELSE.
          LS_RESULT-MESSAGE = 'Tidak ada mapping APPROVER utk EKGRP dan DEFAULT'.
        ENDIF.
      ENDIF.

*     --- 4e-2. Exception level VENDOR (sama utk semua item PO ini) ---
      CLEAR: LV_EXC_VEND, LV_REASON_VEND.

*     ============================================================
*     Kriteria VendorBaru (rule independen, OR):
*       VENDOR_NEW/DAYS       = umur vendor master sesuai TEXT1.
*       VENDOR_NEW/NO_HISTORY = tidak ada released PO sebelumnya.
*       Baris mapping tidak aktif/tidak ada -> cek tersebut di-skip.
*     ============================================================
      IF LV_RULE_VEND_HIST EQ 'X'.
        CLEAR LV_DUMMY.
        SELECT EBELN INTO LV_DUMMY UP TO 1 ROWS
          FROM EKKO
          WHERE LIFNR = LS_EKKO-LIFNR
            AND EBELN NE LS_EKKO-EBELN
            AND FRGZU = 'X'
            AND BSTYP = 'F'.
        ENDSELECT.
        IF SY-SUBRC NE 0.
          LV_EXC_VEND = 'X'.
          PERFORM F_ADD_REASON USING 'VendorBaru'
                               CHANGING LV_REASON_VEND.
        ENDIF.
      ENDIF.

*     --- 4e-3. Simpan template header, dipakai ulang tiap baris item ---
      LS_RESULT_HDR = LS_RESULT.

*     --- 4e-4. Ambil semua item PO ini -> satu baris output per item ---
      REFRESH LT_EKPOD.
      SELECT EBELP MATNR WERKS TXZ01 NETPR PEINH BPRME MEINS NETWR PSTYP KNTTP RETPO
        INTO TABLE LT_EKPOD
        FROM EKPO
        WHERE EBELN = LS_EKKO-EBELN
          AND LOEKZ EQ SPACE.

*     Tampilan Report: Hitung Total Net Value berdasarkan plus minus item return
      CLEAR LV_TOTAL_NETWR.
      LOOP AT LT_EKPOD INTO LS_EKPOD.
        CLEAR: LV_REAL_NETWR.
        IF LS_EKKO-WAERS EQ 'USD'.
          LV_REAL_NETWR = LS_EKPOD-NETWR.
        ELSE.
          CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_EXTERNAL'
            EXPORTING
              CURRENCY        = LS_EKKO-WAERS
              AMOUNT_INTERNAL = LS_EKPOD-NETWR
            IMPORTING
              AMOUNT_EXTERNAL = LV_REAL_NETWR.
        ENDIF.
        IF LS_EKPOD-RETPO EQ 'X'.
          LV_REAL_NETWR = LV_REAL_NETWR * -1.
        ENDIF.
        LV_TOTAL_NETWR = LV_TOTAL_NETWR + LV_REAL_NETWR.
      ENDLOOP.
      LS_RESULT_HDR-TOTAL_NETWR = LV_TOTAL_NETWR.

      LOOP AT LT_EKPOD INTO LS_EKPOD.

        LS_RESULT = LS_RESULT_HDR.
        LS_RESULT-EBELP = LS_EKPOD-EBELP.
        LS_RESULT-MATNR = LS_EKPOD-MATNR.
        LS_RESULT-TXZ01 = LS_EKPOD-TXZ01.
        LS_RESULT-WAERS = LS_EKKO-WAERS.

*       Indikator status (ZPPI_SR_EXEC): Kuning = Belum Release, Hijau = Released
*       Hanya tampil di baris PO paling awal / item 1 saja
        IF SY-TABIX EQ 1.
          IF LS_EKKO-FRGZU EQ 'X' OR LS_EKKO-FRGRL IS INITIAL.
            LS_RESULT-ICONS = '@08@'.   " Hijau (Released)
          ELSE.
            LS_RESULT-ICONS = '@09@'.   " Kuning (Belum Release)
          ENDIF.
        ELSE.
          CLEAR LS_RESULT-ICONS.
        ENDIF.

        CLEAR LS_RESULT-MEINS.
        CALL FUNCTION 'CONVERSION_EXIT_CUNIT_OUTPUT'
          EXPORTING
            INPUT          = LS_EKPOD-MEINS
            LANGUAGE       = SY-LANGU
          IMPORTING
            OUTPUT         = LS_RESULT-MEINS
          EXCEPTIONS
            UNIT_NOT_FOUND = 1
            OTHERS         = 2.
        IF SY-SUBRC NE 0 OR LS_RESULT-MEINS IS INITIAL.
          LS_RESULT-MEINS = LS_EKPOD-MEINS.
        ENDIF.

*       Harga satuan (normalisasi per PEINH) native currency + versi USD.
        CLEAR: LV_REAL_NETWR, LV_CURUNIT, LV_CURUSD.

*       1. Nilai asli per unit (konversi format eksternal mata uang untuk PRICE_NATIVE)
        IF LS_EKKO-WAERS EQ 'USD'.
          LV_REAL_NETWR = LS_EKPOD-NETPR.
        ELSE.
          CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_EXTERNAL'
            EXPORTING
              CURRENCY        = LS_EKKO-WAERS
              AMOUNT_INTERNAL = LS_EKPOD-NETPR
            IMPORTING
              AMOUNT_EXTERNAL = LV_REAL_NETWR.
        ENDIF.

        IF LS_EKPOD-PEINH > 0.
          LS_RESULT-PRICE_NATIVE = LV_REAL_NETWR / LS_EKPOD-PEINH.
        ELSE.
          LS_RESULT-PRICE_NATIVE = LV_REAL_NETWR.
        ENDIF.

*       2. Nilai USD per unit menggunakan PERFORM F_TO_USD (untuk PRICE_USD)
        IF LS_EKPOD-PEINH > 0.
          LV_CURUNIT = LS_EKPOD-NETPR / LS_EKPOD-PEINH.
        ELSE.
          LV_CURUNIT = LS_EKPOD-NETPR.
        ENDIF.

        PERFORM F_TO_USD USING LV_CURUNIT LS_EKKO-WAERS LS_EKKO-BEDAT
                         CHANGING LV_CURUSD.
        LS_RESULT-PRICE_USD = LV_CURUSD.

*       3. Net Value item (EKPO-NETWR) konversi format eksternal mata uang
        CLEAR: LV_REAL_NETWR.
        IF LS_EKKO-WAERS EQ 'USD'.
          LV_REAL_NETWR = LS_EKPOD-NETWR.
        ELSE.
          CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_EXTERNAL'
            EXPORTING
              CURRENCY        = LS_EKKO-WAERS
              AMOUNT_INTERNAL = LS_EKPOD-NETWR
            IMPORTING
              AMOUNT_EXTERNAL = LV_REAL_NETWR.
        ENDIF.
        IF LS_EKPOD-RETPO EQ 'X'.
          LV_REAL_NETWR = LV_REAL_NETWR * -1.
        ENDIF.
        LS_RESULT-NETWR_NATIVE = LV_REAL_NETWR.

*       Mulai dari exception level VENDOR, lalu tambahkan cek per item.
        LV_EXC = LV_EXC_VEND.
        LS_RESULT-EXC_REASON = LV_REASON_VEND.

*       Item tanpa nomor material (jasa/teks bebas) -> lewati cek
*       material & harga; baris tetap tampil dgn flag vendor (bila ada).
        CLEAR: LS_RESULT-LAST_PRICE.
        IF LS_EKPOD-MATNR IS NOT INITIAL.

*         Ambil histori 1x saja:
*         - Saat mode Report (P_RPT = 'X') untuk isi kolom Last Price
*         - Atau saat rule exception aktif (hemat akses DB saat mode Send Email)
          CLEAR: LS_LASTM, LV_HASMAT.
          IF P_RPT EQ 'X'
             OR LV_RULE_MAT_HIST EQ 'X'
             OR ( LV_RULE_PRICE EQ 'X' AND LV_RULE_PRICE_MAT EQ 'X' ).
            PERFORM F_GET_LAST USING LS_EKPOD-MATNR SPACE LS_EKKO-EBELN
                               CHANGING LS_LASTM LV_HASMAT.
          ENDIF.

*         Kolom Report: Last Price dinamis berbasis Plant (T001W)
          IF P_RPT EQ 'X'.
            PERFORM F_GET_LPRINT USING LS_EKPOD-WERKS
                                       LS_EKPOD-MATNR
                                       LS_EKKO-EBELN
                                       LS_EKPOD-EBELP
                                       LS_EKKO-WAERS
                                 CHANGING LS_RESULT-LAST_PRICE.
          ENDIF.

*         Sumbu MATERIAL:
*         Masing-masing cabang hanya berjalan jika mapping aktif.
          IF LV_HASMAT IS INITIAL.
            IF LV_RULE_MAT_HIST EQ 'X'.
              LV_EXC = 'X'.
              PERFORM F_ADD_REASON USING 'MaterialBaru'
                                   CHANGING LS_RESULT-EXC_REASON.
            ENDIF.
          ELSE.
            IF LV_RULE_PRICE EQ 'X' AND LV_RULE_PRICE_MAT EQ 'X'.
              PERFORM F_CHK_NAIK USING LV_CURUSD LS_EKPOD-BPRME LS_LASTM
                                 'HrgNaikMat'
                                 CHANGING LV_EXC LS_RESULT-EXC_REASON.
            ENDIF.
          ENDIF.

        ENDIF.

        LS_RESULT-EXC_FLAG = LV_EXC.

*       --- Kumpulkan utk email (hanya bila approver ketemu) ---
        IF LS_RESULT-APPR_OPT IS NOT INITIAL.
          CLEAR LS_MAIL.
          LS_MAIL-APPR_OPT     = LS_RESULT-APPR_OPT.
          LS_MAIL-EBELN        = LS_RESULT-EBELN.
          LS_MAIL-EBELP        = LS_RESULT-EBELP.
          LS_MAIL-BSART        = LS_RESULT-BSART.
          LS_MAIL-BSART_DESC   = LS_RESULT-BSART_DESC.
          LS_MAIL-LIFNR        = LS_RESULT-LIFNR.
          LS_MAIL-NAME1        = LS_RESULT-NAME1.
          LS_MAIL-MATNR        = LS_RESULT-MATNR.
          LS_MAIL-TXZ01        = LS_RESULT-TXZ01.
          LS_MAIL-WAERS        = LS_RESULT-WAERS.
          LS_MAIL-PRICE_NATIVE = LS_RESULT-PRICE_NATIVE.
          LS_MAIL-PRICE_USD    = LS_RESULT-PRICE_USD.
          LS_MAIL-MEINS        = LS_RESULT-MEINS.
          LS_MAIL-TIER         = LS_RESULT-TIER.
          LS_MAIL-EXC_FLAG     = LS_RESULT-EXC_FLAG.
          LS_MAIL-EXC_REASON   = LS_RESULT-EXC_REASON.
          APPEND LS_MAIL TO GT_MAIL.
        ENDIF.

        APPEND LS_RESULT TO LT_RESULT.

      ENDLOOP.

    ENDIF.

  ENDLOOP.

*----------------------------------------------------------------*
* 5. Kirim email hanya dalam mode Email Notification (variant job).
*----------------------------------------------------------------*
  IF P_MAIL EQ 'X'.
    PERFORM F_SEND_ALL.
  ENDIF.

*----------------------------------------------------------------*
* 6. Output hasil: ALV untuk user; list/spool untuk background job.
*----------------------------------------------------------------*
  IF P_RPT EQ 'X' AND SY-BATCH IS INITIAL.
    PERFORM F_DISPLAY_ALV.
  ELSE.
    PERFORM F_OUTPUT_LIST.
  ENDIF.

*&---------------------------------------------------------------*
*& Form F_DISPLAY_ALV -- report interaktif untuk user Purchasing
*&---------------------------------------------------------------*
FORM F_DISPLAY_ALV.
  DATA: LV_REASON TYPE STRING,
        LT_EVENTS TYPE SLIS_T_EVENT,
        LS_EVENT  TYPE SLIS_ALV_EVENT.

* Format token teknis hanya untuk tampilan ALV.
* Proses email sudah selesai sebelum FORM ini dipanggil.
  LOOP AT LT_RESULT INTO LS_RESULT.
    LV_REASON = LS_RESULT-EXC_REASON.
    PERFORM F_PRETTY_REASON_ALV CHANGING LV_REASON.
    LS_RESULT-EXC_REASON = LV_REASON.
    MODIFY LT_RESULT FROM LS_RESULT.
  ENDLOOP.

  CLEAR: GT_FIELDCAT, GS_LAYOUT, GT_SELECTED_EBELN, LT_EVENTS.

  CLEAR LS_EVENT.
  LS_EVENT-NAME = SLIS_EV_CALLER_EXIT_AT_START.
  LS_EVENT-FORM = 'F_CALLER_EXIT'.
  APPEND LS_EVENT TO LT_EVENTS.

* Kolom kunci dan exception diletakkan lebih awal untuk pembacaan cepat.
  PERFORM F_ADD_FIELDCAT USING 'SEL'   'Pilih'  4 'X'.
  PERFORM F_ADD_FIELDCAT USING 'ICONS' 'Status' 6 'X'.
  PERFORM F_ADD_FIELDCAT USING 'EBELN' 'No. PO' 10 'X'.
  PERFORM F_ADD_FIELDCAT USING 'EBELP' 'Item PO' 5 'X'.
  PERFORM F_ADD_FIELDCAT USING 'BSART' 'PO Type' 8 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'BSART_DESC' 'PO Type Description' 15 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'EKGRP' 'Purch. Group' 8 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'LIFNR' 'Vendor' 10 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'NAME1' 'Vendor Name' 30 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'MATNR' 'Material' 18 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'TXZ01' 'Short text' 40 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'WAERS' 'Currency' 6 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'PRICE_NATIVE' 'Price per Unit' 15 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'PRICE_USD' 'Price per Unit (USD)' 18 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'MEINS' 'Order Unit' 10 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'LAST_PRICE' 'Last Price' 15 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'NETWR_NATIVE' 'Net Value' 15 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'TOTAL_NETWR'  'Total Net Value' 18 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'USDVAL' 'Total Net Value (USD)' 20 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'TIER' 'Tier' 5 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'EXC_FLAG' 'Flag' 6 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'EXC_REASON' 'Alasan Exception' 26 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'APPR_OPT' 'Grup Approver' 12 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'APPR_NAME' 'Approver' 16 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'APPR_MAIL' 'Email Penerima' 28 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'STATUS' 'Status' 6 SPACE.
  PERFORM F_ADD_FIELDCAT USING 'MESSAGE'    'Keterangan'       65 SPACE.

  GS_LAYOUT-ZEBRA             = 'X'.
  GS_LAYOUT-INFO_FIELDNAME    = 'LINE_COLOR'.
  GS_LAYOUT-COLWIDTH_OPTIMIZE = SPACE.
  GS_LAYOUT-WINDOW_TITLEBAR   = 'PO Pending Approval'.

  DATA: LS_DISVAR TYPE DISVARIANT.

  CLEAR LS_DISVAR.
  LS_DISVAR-REPORT  = SY-REPID.
  LS_DISVAR-VARIANT = P_VARI.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      I_CALLBACK_PROGRAM          = SY-REPID
      I_CALLBACK_PF_STATUS_SET    = 'F_SET_PF_STATUS'
      I_CALLBACK_USER_COMMAND     = 'F_USER_COMMAND'
      IS_LAYOUT                   = GS_LAYOUT
      IT_FIELDCAT                 = GT_FIELDCAT
      IT_EVENTS                   = LT_EVENTS
      I_SAVE                      = 'A'
      IS_VARIANT                  = LS_DISVAR
    TABLES
      T_OUTTAB                    = LT_RESULT
    EXCEPTIONS
      PROGRAM_ERROR               = 1
      OTHERS                      = 2.
  IF SY-SUBRC NE 0.
    WRITE: / 'ALV tidak dapat ditampilkan; gunakan output list/spool.'.
  ENDIF.
ENDFORM.                    "F_DISPLAY_ALV

*&---------------------------------------------------------------*
*& Form F_SET_PF_STATUS -- Standard GUI Status ALV
*&---------------------------------------------------------------*
FORM F_SET_PF_STATUS USING RT_EXTAB TYPE SLIS_T_EXTAB.
  DATA: LS_EXTAB TYPE SLIS_EXTAB.

  CLEAR LS_EXTAB.
  LS_EXTAB-FCODE = '&ALL'.
  APPEND LS_EXTAB TO RT_EXTAB.
  CLEAR LS_EXTAB.
  LS_EXTAB-FCODE = '&SAL'.
  APPEND LS_EXTAB TO RT_EXTAB.
  CLEAR LS_EXTAB.
  LS_EXTAB-FCODE = '&OAA'.
  APPEND LS_EXTAB TO RT_EXTAB.
  CLEAR LS_EXTAB.
  LS_EXTAB-FCODE = '&OAD'.
  APPEND LS_EXTAB TO RT_EXTAB.

  SET PF-STATUS 'STANDARD_FULLSCREEN' EXCLUDING RT_EXTAB.
ENDFORM.                    "F_SET_PF_STATUS

*&---------------------------------------------------------------*
*& Form F_CALLER_EXIT -- Hook Toolbar event handler CL_GUI_ALV_GRID
*&---------------------------------------------------------------*
FORM F_CALLER_EXIT USING E_GRID TYPE SLIS_DATA_CALLER_EXIT.
  DATA: LR_GRID TYPE REF TO CL_GUI_ALV_GRID.

  CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
    IMPORTING
      E_GRID = LR_GRID.

  IF LR_GRID IS BOUND.
    SET HANDLER LCL_EVENT_HANDLER=>ON_TOOLBAR FOR LR_GRID.
    SET HANDLER LCL_EVENT_HANDLER=>ON_USER_COMMAND FOR LR_GRID.
  ENDIF.
ENDFORM.                    "F_CALLER_EXIT

*&---------------------------------------------------------------*
*& Form F_ADD_FIELDCAT -- tambah kolom ALV report
*&---------------------------------------------------------------*
FORM F_ADD_FIELDCAT USING P_FIELD TYPE SLIS_FIELDNAME
                           P_TEXT  TYPE SCRTEXT_L
                           P_LEN   TYPE I
                           P_HOT   TYPE C.
  CLEAR GS_FIELDCAT.
  GS_FIELDCAT-FIELDNAME = P_FIELD.
  GS_FIELDCAT-SELTEXT_L = P_TEXT.
  GS_FIELDCAT-OUTPUTLEN = P_LEN.
  GS_FIELDCAT-HOTSPOT   = P_HOT.
  IF P_FIELD EQ 'SEL'.
    GS_FIELDCAT-CHECKBOX = 'X'.
    GS_FIELDCAT-JUST     = 'C'.
  ENDIF.
  IF P_FIELD EQ 'ICONS'.
    GS_FIELDCAT-ICON     = 'X'.
    GS_FIELDCAT-JUST     = 'C'.
  ENDIF.
  IF P_FIELD EQ 'LAST_PRICE'.
    GS_FIELDCAT-NO_ZERO  = 'X'.
    GS_FIELDCAT-JUST     = 'R'.
  ENDIF.
  APPEND GS_FIELDCAT TO GT_FIELDCAT.
ENDFORM.                    "F_ADD_FIELDCAT

*&---------------------------------------------------------------*
*& Form F_USER_COMMAND -- user command ALV & double-click
*&---------------------------------------------------------------*
FORM F_USER_COMMAND USING P_UCOMM LIKE SY-UCOMM
                          PS_SELFIELD TYPE SLIS_SELFIELD.
  DATA: LV_TARGET_EBELN TYPE EKKO-EBELN,
        LV_IDX          TYPE SY-TABIX.

  IF P_UCOMM EQ 'REL_PO' OR P_UCOMM EQ '&REL'.
    PERFORM F_RELEASE_SELECTED_PO.
    PS_SELFIELD-REFRESH = 'X'.
    RETURN.
  ENDIF.


  IF P_UCOMM EQ '&IC1'.
    IF PS_SELFIELD-FIELDNAME EQ 'EBELN'.
      SET PARAMETER ID 'BES' FIELD PS_SELFIELD-VALUE.
      CALL TRANSACTION 'ME23N' AND SKIP FIRST SCREEN.
      RETURN.
    ENDIF.
  ENDIF.

* Sinkronkan centang (SEL) dan highlight warna (LINE_COLOR) ke semua item PO yang sama (Multi-PO persistent)
  IF PS_SELFIELD-TABINDEX > 0.
    READ TABLE LT_RESULT INTO LS_RESULT INDEX PS_SELFIELD-TABINDEX.
    IF SY-SUBRC EQ 0.
      LV_TARGET_EBELN = LS_RESULT-EBELN.

      READ TABLE GT_SELECTED_EBELN WITH KEY TABLE_LINE = LV_TARGET_EBELN
           TRANSPORTING NO FIELDS.
      IF SY-SUBRC EQ 0.
        " Sudah terpilih -> batalkan pilihan PO ini
        DELETE GT_SELECTED_EBELN WHERE TABLE_LINE = LV_TARGET_EBELN.
      ELSE.
        " Belum terpilih -> tambahkan PO ini ke daftar terpilih
        APPEND LV_TARGET_EBELN TO GT_SELECTED_EBELN.
      ENDIF.

      " Terapkan seleksi ke SELURUH baris internal table LT_RESULT
      LOOP AT LT_RESULT INTO LS_RESULT.
        LV_IDX = SY-TABIX.
        READ TABLE GT_SELECTED_EBELN WITH KEY TABLE_LINE = LS_RESULT-EBELN
             TRANSPORTING NO FIELDS.
        IF SY-SUBRC EQ 0.
          LS_RESULT-SEL        = 'X'.
          LS_RESULT-LINE_COLOR = 'C310'. " Highlight oranye/kuning
        ELSE.
          LS_RESULT-SEL        = SPACE.
          LS_RESULT-LINE_COLOR = SPACE.
        ENDIF.
        MODIFY LT_RESULT FROM LS_RESULT INDEX LV_IDX TRANSPORTING SEL LINE_COLOR.
      ENDLOOP.

      PS_SELFIELD-REFRESH = 'X'.
    ENDIF.
  ENDIF.
ENDFORM.                    "F_USER_COMMAND

*&---------------------------------------------------------------*
*& Form F_RELEASE_SELECTED_PO -- Eksekusi Release PO terpilih
*&---------------------------------------------------------------*
FORM F_RELEASE_SELECTED_PO.
  DATA: LT_EBELN_SEL   TYPE STANDARD TABLE OF EKKO-EBELN,
        LV_EBELN       TYPE EKKO-EBELN,
        LS_EKKO_REL    TYPE TY_EKKO,
        LT_RELCODE     TYPE STANDARD TABLE OF TY_RELCODE,
        LS_RELCODE     TYPE TY_RELCODE,
        LT_RETURN      TYPE STANDARD TABLE OF BAPIRETURN,
        LS_RETURN      TYPE BAPIRETURN,
        LV_RELSTATUS   TYPE BAPIMMPARA-REL_STATUS,
        LV_RELIND      TYPE BAPIMMPARA-PO_REL_IND,
        LV_RETCODE     TYPE SY-SUBRC,
        LV_RELEASED    TYPE CHAR1,
        LV_SUCCESS_CNT TYPE I,
        LV_ERR_MSG     TYPE STRING,
        LV_MSG_TXT     TYPE STRING,
        LV_FIRST       TYPE CHAR1.

* 1. Kumpulkan seluruh nomor PO unik yang dicentang (SEL = 'X')
  REFRESH LT_EBELN_SEL.
  LOOP AT LT_RESULT INTO LS_RESULT WHERE SEL = 'X'.
    APPEND LS_RESULT-EBELN TO LT_EBELN_SEL.
  ENDLOOP.
  SORT LT_EBELN_SEL.
  DELETE ADJACENT DUPLICATES FROM LT_EBELN_SEL.

* 2. Validasi: Jika tidak ada yang dicentang
  IF LT_EBELN_SEL IS INITIAL.
    MESSAGE 'Tidak ada data PO yang dipilih' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  CLEAR LV_SUCCESS_CNT.

* 3. Proses release per Header PO
  LOOP AT LT_EBELN_SEL INTO LV_EBELN.
    CLEAR: LS_EKKO_REL, LV_RELEASED, LV_ERR_MSG.

    " Ambil data header PO terkini dari database
    SELECT SINGLE EBELN BUKRS EKORG EKGRP BSART FRGRL FRGGR FRGSX WAERS BEDAT LIFNR LOEKZ FRGZU
      INTO LS_EKKO_REL
      FROM EKKO
      WHERE EBELN = LV_EBELN.

    IF SY-SUBRC NE 0.
      CONTINUE.
    ENDIF.

    " Validasi: Jika PO sudah direlease -> skip (tidak perlu dieksekusi)
    IF LS_EKKO_REL-FRGZU EQ 'X' OR LS_EKKO_REL-FRGRL IS INITIAL.
      LV_FIRST = 'X'.
      LOOP AT LT_RESULT INTO LS_RESULT WHERE EBELN = LV_EBELN.
        IF LV_FIRST EQ 'X'.
          LS_RESULT-ICONS = '@08@'.   " Hijau (Released)
          CLEAR LV_FIRST.
        ELSE.
          CLEAR LS_RESULT-ICONS.
        ENDIF.
        LS_RESULT-SEL        = SPACE.
        LS_RESULT-LINE_COLOR = SPACE.
        LS_RESULT-STATUS     = 'S'.
        LS_RESULT-MESSAGE    = 'PO sudah dalam status Released'.
        MODIFY LT_RESULT FROM LS_RESULT TRANSPORTING ICONS SEL LINE_COLOR STATUS MESSAGE.
      ENDLOOP.
      DELETE GT_SELECTED_EBELN WHERE TABLE_LINE = LV_EBELN.
      CONTINUE.
    ENDIF.

    " Cari kandidat release code (T16FV)
    REFRESH LT_RELCODE.
    SELECT FRGCO
      INTO TABLE LT_RELCODE
      FROM T16FV
      WHERE FRGGR = LS_EKKO_REL-FRGGR
        AND FRGSX = LS_EKKO_REL-FRGSX.

    IF LT_RELCODE IS INITIAL.
      LOOP AT LT_RESULT INTO LS_RESULT WHERE EBELN = LV_EBELN.
        LS_RESULT-STATUS  = 'E'.
        LS_RESULT-MESSAGE = 'Kombinasi FRGGR/FRGSX tidak ditemukan di T16FV'.
        MODIFY LT_RESULT FROM LS_RESULT TRANSPORTING STATUS MESSAGE.
      ENDLOOP.
      CONTINUE.
    ENDIF.

    LOOP AT LT_RELCODE INTO LS_RELCODE.
      CLEAR: LV_RELSTATUS, LV_RELIND.
      REFRESH LT_RETURN.

      CALL FUNCTION 'BAPI_PO_RELEASE'
        EXPORTING
          PURCHASEORDER          = LV_EBELN
          PO_REL_CODE            = LS_RELCODE-FRGCO
          USE_EXCEPTIONS         = 'X'
          NO_COMMIT              = 'X'
        IMPORTING
          REL_STATUS_NEW         = LV_RELSTATUS
          REL_INDICATOR_NEW      = LV_RELIND
        TABLES
          RETURN                 = LT_RETURN
        EXCEPTIONS
          AUTHORITY_CHECK_FAIL   = 1
          DOCUMENT_NOT_FOUND     = 2
          ENQUEUE_FAIL           = 3
          PREREQUISITE_FAIL      = 4
          RELEASE_ALREADY_POSTED = 5
          RESPONSIBILITY_FAIL    = 6
          OTHERS                 = 7.

      LV_RETCODE = SY-SUBRC.

      IF LV_RETCODE EQ 0.
        READ TABLE LT_RETURN INTO LS_RETURN WITH KEY TYPE = 'E'.
        IF SY-SUBRC NE 0.
          READ TABLE LT_RETURN INTO LS_RETURN WITH KEY TYPE = 'A'.
        ENDIF.

        IF SY-SUBRC EQ 0.
          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
          LV_ERR_MSG = LS_RETURN-MESSAGE.
          EXIT.
        ENDIF.

        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            WAIT = 'X'.

        LV_RELEASED = 'X'.
        LV_SUCCESS_CNT = LV_SUCCESS_CNT + 1.
        EXIT.

      ELSE.
        CLEAR LS_RETURN.
        READ TABLE LT_RETURN INTO LS_RETURN INDEX 1.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

        IF LV_RETCODE EQ 4 OR LV_RETCODE EQ 6.
          CONTINUE.
        ELSE.
          IF LS_RETURN-MESSAGE IS NOT INITIAL.
            LV_ERR_MSG = LS_RETURN-MESSAGE.
          ELSE.
            LV_ERR_MSG = 'BAPI_PO_RELEASE gagal'.
          ENDIF.
          EXIT.
        ENDIF.
      ENDIF.
    ENDLOOP.

    " Update internal table LT_RESULT sesuai hasil release
    IF LV_RELEASED EQ 'X'.
      LV_FIRST = 'X'.
      LOOP AT LT_RESULT INTO LS_RESULT WHERE EBELN = LV_EBELN.
        IF LV_FIRST EQ 'X'.
          LS_RESULT-ICONS = '@08@'.   " Berubah jadi HIJAU!
          CLEAR LV_FIRST.
        ELSE.
          CLEAR LS_RESULT-ICONS.
        ENDIF.
        LS_RESULT-SEL        = SPACE.
        LS_RESULT-LINE_COLOR = SPACE.
        LS_RESULT-STATUS     = 'S'.
        LS_RESULT-MESSAGE    = 'PO berhasil di-release'.
        MODIFY LT_RESULT FROM LS_RESULT TRANSPORTING ICONS SEL LINE_COLOR STATUS MESSAGE.
      ENDLOOP.
      DELETE GT_SELECTED_EBELN WHERE TABLE_LINE = LV_EBELN.
    ELSE.
      IF LV_ERR_MSG IS INITIAL.
        LV_ERR_MSG = 'Tidak ada release code yang applicable saat ini'.
      ENDIF.
      LOOP AT LT_RESULT INTO LS_RESULT WHERE EBELN = LV_EBELN.
        LS_RESULT-STATUS  = 'E'.
        LS_RESULT-MESSAGE = LV_ERR_MSG.
        MODIFY LT_RESULT FROM LS_RESULT TRANSPORTING STATUS MESSAGE.
      ENDLOOP.
    ENDIF.

  ENDLOOP.

* 4. Pesan hasil akhir
  IF LV_SUCCESS_CNT > 0.
    DATA: LV_CNT_STR TYPE C LENGTH 10.
    WRITE LV_SUCCESS_CNT TO LV_CNT_STR NO-GROUPING.
    CONDENSE LV_CNT_STR.
    CONCATENATE LV_CNT_STR 'PO berhasil di-release' INTO LV_MSG_TXT SEPARATED BY SPACE.
    MESSAGE LV_MSG_TXT TYPE 'S'.
  ELSE.
    IF LV_ERR_MSG IS NOT INITIAL.
      MESSAGE LV_ERR_MSG TYPE 'S' DISPLAY LIKE 'E'.
    ENDIF.
  ENDIF.

ENDFORM.                    "F_RELEASE_SELECTED_PO

*&---------------------------------------------------------------*
*& Form F_OUTPUT_LIST -- log untuk mode email atau background job
*&---------------------------------------------------------------*
FORM F_OUTPUT_LIST.
  DESCRIBE TABLE LT_RESULT LINES LV_LINES.

  WRITE: / 'Hasil PO Routing + Exception + Email (ZMMI_PO_EMAIL)',
           60 'Mode:', P_TEST AS CHECKBOX.
  WRITE: / 'Total baris item PO T1/T2 diproses:', LV_LINES,
           '(PO tier auto di-skip, ditangani Sprint 1)'.
  SKIP.
  WRITE: / SY-ULINE.
  WRITE: / 'PO Number', 12 'Item', 18 'Material', 36 'Purch. Grp',
           49 'USD Val', 66 'Tier',
           73 'Approver', 91 'Email', 115 'St', 119 'Ex',
           123 'Alasan Exception', 186 'Keterangan'.
  WRITE: / SY-ULINE.

  LOOP AT LT_RESULT INTO LS_RESULT.
    WRITE: / LS_RESULT-EBELN,
             12 LS_RESULT-EBELP,
             18 LS_RESULT-MATNR,
             36 LS_RESULT-EKGRP,
             49 LS_RESULT-USDVAL,
             66 LS_RESULT-TIER,
             73 LS_RESULT-APPR_NAME,
             91 LS_RESULT-APPR_MAIL,
             115 LS_RESULT-STATUS,
             119 LS_RESULT-EXC_FLAG,
             123(60) LS_RESULT-EXC_REASON,
             186 LS_RESULT-MESSAGE.
  ENDLOOP.
ENDFORM.                    "F_OUTPUT_LIST

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
ENDFORM.                    "F_BUILD_EMAIL

*&---------------------------------------------------------------*
*& Form F_ADD_HTML  -- tambah 1 baris ke body HTML email
*&---------------------------------------------------------------*
FORM F_ADD_HTML USING P_LINE TYPE STRING.
  CLEAR GS_BODY.
  GS_BODY-LINE = P_LINE.
  APPEND GS_BODY TO GT_BODY.
ENDFORM.                    "F_ADD_HTML

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
ENDFORM.                    "F_SEND_ALL

*&---------------------------------------------------------------*
*& Form F_MAIL_START  -- inisialisasi body + recipients per grup
*&---------------------------------------------------------------*
FORM F_MAIL_START USING P_OPT TYPE ZMAP_TYPE-OPT.
  DATA: LV_LINE  TYPE STRING,
        LV_MAIL  TYPE AD_SMTPADR,
        LV_NM    TYPE STRING,
        LV_SEX   TYPE C LENGTH 1,
        LV_NAMES TYPE STRING,
        LV_PENDING TYPE I,
        LV_COUNT TYPE C LENGTH 20,
        LT_EBELN TYPE STANDARD TABLE OF EKKO-EBELN.

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

* Hitung PO pending khusus grup recipient ini (header PO unik).
  CLEAR: LV_PENDING, LV_COUNT.
  REFRESH LT_EBELN.
  LOOP AT GT_MAIL INTO LS_MAIL WHERE APPR_OPT = P_OPT.
    APPEND LS_MAIL-EBELN TO LT_EBELN.
  ENDLOOP.
  SORT LT_EBELN.
  DELETE ADJACENT DUPLICATES FROM LT_EBELN.
  DESCRIBE TABLE LT_EBELN LINES LV_PENDING.
  WRITE LV_PENDING TO LV_COUNT NO-GROUPING.
  CONDENSE LV_COUNT.

* HTML header
  PERFORM F_ADD_HTML USING '<html><body style="font-family:Arial,sans-serif;font-size:13px;color:#1F2328;">'.
  CONCATENATE '<p>Yth.' LV_NAMES INTO LV_LINE SEPARATED BY SPACE.
  CONCATENATE LV_LINE ',</p>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<p><b>Terdapat' LV_COUNT
              'PO yang menunggu persetujuan.</b></p>'
              INTO LV_LINE SEPARATED BY SPACE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<p>Berikut Purchase Order yang menunggu persetujuan Anda (grup'
              P_OPT INTO LV_LINE SEPARATED BY SPACE.
  CONCATENATE LV_LINE '):</p>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  PERFORM F_ADD_HTML USING '<table border="1" cellspacing="0" cellpadding="5" style="border-collapse:collapse;font-size:12px;">'.
  PERFORM F_ADD_HTML USING '<tr style="background:#2F3A46;color:#ffffff;">'.
  PERFORM F_ADD_HTML USING '<th>No PO</th><th>Item PO</th><th>PO Type</th><th>PO Type Description</th><th>Vendor</th><th>Vendor Name</th><th>Material</th>'.
  PERFORM F_ADD_HTML USING '<th>Short text</th><th>Currency</th><th>Price per Unit</th><th>Price per Unit (USD)</th><th>Order Unit</th><th>Tier</th><th>Flag</th><th>Alasan Exception</th></tr>'.

ENDFORM.                    "F_MAIL_START

*&---------------------------------------------------------------*
*& Form F_MAIL_ROW  -- tambah 1 baris PO ke body HTML
*&---------------------------------------------------------------*
FORM F_MAIL_ROW USING P_MAIL TYPE TY_MAIL.
  DATA: LV_LINE  TYPE STRING,
        LV_PNAT  TYPE C LENGTH 20,
        LV_PUSD  TYPE C LENGTH 20,
        LV_FLAG  TYPE STRING,
        LV_STYLE TYPE STRING,
        LV_REAS  TYPE STRING,
        LV_EBELN TYPE C LENGTH 10,
        LV_EBELP TYPE C LENGTH 5.

  WRITE P_MAIL-PRICE_NATIVE TO LV_PNAT.
  CONDENSE LV_PNAT.
  WRITE P_MAIL-PRICE_USD TO LV_PUSD.
  CONDENSE LV_PUSD.
  LV_EBELN = P_MAIL-EBELN.
  LV_EBELP = P_MAIL-EBELP.
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
  CONCATENATE '<td>' LV_EBELP '</td>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<td>' P_MAIL-BSART '</td>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<td>' P_MAIL-BSART_DESC '</td>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<td>' P_MAIL-LIFNR '</td>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<td>' P_MAIL-NAME1 '</td>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<td>' P_MAIL-MATNR '</td>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<td>' P_MAIL-TXZ01 '</td>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<td>' P_MAIL-WAERS '</td>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<td align="right">' LV_PNAT '</td>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<td align="right">' LV_PUSD '</td>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<td>' P_MAIL-MEINS '</td>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<td align="center">' P_MAIL-TIER '</td>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<td align="center">' LV_FLAG '</td>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
  CONCATENATE '<td>' LV_REAS '</td></tr>' INTO LV_LINE.
  PERFORM F_ADD_HTML USING LV_LINE.
ENDFORM.                    "F_MAIL_ROW

*&---------------------------------------------------------------*
*& Form F_MAIL_SEND  -- tutup HTML, lampirkan Excel, kirim via CL_BCS
*&---------------------------------------------------------------*
FORM F_MAIL_SEND USING P_OPT TYPE ZMAP_TYPE-OPT.
  DATA: LV_SUBJ TYPE SOOD-OBJDES,
        LV_ATTS TYPE SOOD-OBJDES,
        LV_LINE TYPE STRING,
        LV_NUM  TYPE C LENGTH 20,
        LV_CFGOPT  TYPE STRING,
        LV_CFGVAL  TYPE STRING,
        LV_CFGDESC TYPE STRING,
        LV_CFGKEY  TYPE STRING,
        LV_CFG_LIST TYPE STRING.

* Tutup tabel + penutup
  PERFORM F_ADD_HTML USING '</table>'.
  PERFORM F_ADD_HTML USING '<p>Baris dengan tanda "Perhatian" memiliki catatan exception. Mohon diperiksa sebelum menyetujui.</p>'.
* Legenda arti flag exception (biar approver paham)
  PERFORM F_ADD_HTML USING '<p style="font-size:11px;color:#444;"><b>Keterangan flag:</b></p>'.
  PERFORM F_ADD_HTML USING '<ul style="font-size:11px;color:#444;margin-top:0;">'.

  IF LV_RULE_VEND_HIST EQ 'X' OR LV_RULE_VEND_DAYS EQ 'X'.
    IF LV_RULE_VEND_HIST EQ 'X' AND LV_RULE_VEND_DAYS EQ 'X'.
      WRITE LV_VENDOR_DAYS TO LV_NUM NO-GROUPING.
      CONDENSE LV_NUM.
      CONCATENATE '<li><b>Vendor Baru</b> = belum pernah bertransaksi atau umur master maksimal'
                  LV_NUM 'hari.</li>' INTO LV_LINE SEPARATED BY SPACE.
    ELSEIF LV_RULE_VEND_HIST EQ 'X'.
      LV_LINE = '<li><b>Vendor Baru</b> = belum pernah bertransaksi.</li>'.
    ELSE.
      WRITE LV_VENDOR_DAYS TO LV_NUM NO-GROUPING.
      CONDENSE LV_NUM.
      CONCATENATE '<li><b>Vendor Baru</b> = umur master maksimal'
                  LV_NUM 'hari.</li>' INTO LV_LINE SEPARATED BY SPACE.
    ENDIF.
    PERFORM F_ADD_HTML USING LV_LINE.
  ENDIF.

  IF LV_RULE_MAT_HIST EQ 'X' OR LV_RULE_MAT_DAYS EQ 'X'.
    IF LV_RULE_MAT_HIST EQ 'X' AND LV_RULE_MAT_DAYS EQ 'X'.
      WRITE LV_MATERIAL_DAYS TO LV_NUM NO-GROUPING.
      CONDENSE LV_NUM.
      CONCATENATE '<li><b>Material Baru</b> = belum pernah dibeli atau umur master maksimal'
                  LV_NUM 'hari.</li>' INTO LV_LINE SEPARATED BY SPACE.
    ELSEIF LV_RULE_MAT_HIST EQ 'X'.
      LV_LINE = '<li><b>Material Baru</b> = belum pernah dibeli.</li>'.
    ELSE.
      WRITE LV_MATERIAL_DAYS TO LV_NUM NO-GROUPING.
      CONDENSE LV_NUM.
      CONCATENATE '<li><b>Material Baru</b> = umur master maksimal'
                  LV_NUM 'hari.</li>' INTO LV_LINE SEPARATED BY SPACE.
    ENDIF.
    PERFORM F_ADD_HTML USING LV_LINE.
  ENDIF.

  IF LV_RULE_PRICE EQ 'X' AND LV_RULE_PRICE_MAT EQ 'X'.
    WRITE LV_PRICE_PCT TO LV_NUM NO-GROUPING DECIMALS 2.
    CONDENSE LV_NUM.
    REPLACE ALL OCCURRENCES OF '.00' IN LV_NUM WITH ''.
    REPLACE ALL OCCURRENCES OF ',00' IN LV_NUM WITH ''.
    CONCATENATE '<li><b>Harga Naik (Material)</b> = harga naik &gt;'
                LV_NUM '% dibanding harga terakhir material ini (vendor manapun).</li>'
                INTO LV_LINE SEPARATED BY SPACE.
    PERFORM F_ADD_HTML USING LV_LINE.
  ENDIF.

  IF LV_RULE_PRICE EQ 'X' AND LV_RULE_PRICE_VEN EQ 'X'.
    WRITE LV_PRICE_PCT TO LV_NUM NO-GROUPING DECIMALS 2.
    CONDENSE LV_NUM.
    REPLACE ALL OCCURRENCES OF '.00' IN LV_NUM WITH ''.
    REPLACE ALL OCCURRENCES OF ',00' IN LV_NUM WITH ''.
    CONCATENATE '<li><b>Harga Naik (Vendor)</b> = harga naik &gt;'
                LV_NUM '% dibanding harga terakhir dari vendor yang sama.</li>'
                INTO LV_LINE SEPARATED BY SPACE.
    PERFORM F_ADD_HTML USING LV_LINE.
  ENDIF.

  IF LV_RULE_STALE EQ 'X'.
    LV_STALE_MONTHS = LV_STALE_DAYS DIV 30.
    WRITE LV_STALE_MONTHS TO LV_NUM NO-GROUPING.
    CONDENSE LV_NUM.
    CONCATENATE '<li><b>Histori Usang</b> = pembelian terakhir lebih lama dari'
                LV_NUM 'bulan (' INTO LV_LINE SEPARATED BY SPACE.
    WRITE LV_STALE_DAYS TO LV_NUM NO-GROUPING.
    CONDENSE LV_NUM.
    CONCATENATE LV_LINE LV_NUM ' hari).</li>' INTO LV_LINE.
    PERFORM F_ADD_HTML USING LV_LINE.
  ENDIF.

  CLEAR LV_CFG_LIST.
  LOOP AT LT_EXC_RULE INTO LS_EXC_RULE
    WHERE OPT = 'PSTYP' OR OPT = 'KNTTP'.
    CLEAR: LV_CFGOPT, LV_CFGVAL, LV_CFGDESC, LV_CFGKEY, LV_LINE.
    LV_CFGOPT  = LS_EXC_RULE-OPT.
    LV_CFGVAL  = LS_EXC_RULE-VALUE.
    LV_CFGDESC = LS_EXC_RULE-TEXT2.
    PERFORM F_XML_ESC CHANGING LV_CFGOPT.
    PERFORM F_XML_ESC CHANGING LV_CFGVAL.
    PERFORM F_XML_ESC CHANGING LV_CFGDESC.
    CONCATENATE LV_CFGOPT '=' LV_CFGVAL INTO LV_CFGKEY.
    IF LV_CFGDESC IS NOT INITIAL.
      CONCATENATE '(' LV_CFGDESC ')' INTO LV_CFGDESC.
    ENDIF.
    IF LV_CFG_LIST IS INITIAL.
      CONCATENATE LV_CFGKEY LV_CFGDESC INTO LV_CFG_LIST SEPARATED BY SPACE.
    ELSE.
      CONCATENATE LV_CFG_LIST ',' INTO LV_CFG_LIST.
      CONCATENATE LV_CFG_LIST LV_CFGKEY LV_CFGDESC
                  INTO LV_CFG_LIST SEPARATED BY SPACE.
    ENDIF.
  ENDLOOP.
  IF LV_CFG_LIST IS NOT INITIAL.
    CONCATENATE '<li><b>Jasa/Capex</b> = kategori'
                LV_CFG_LIST '.</li>' INTO LV_LINE SEPARATED BY SPACE.
    PERFORM F_ADD_HTML USING LV_LINE.
  ENDIF.

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

*     Sender alias custom (dinamis via parameter/variant).
      IF P_SENDER IS NOT INITIAL.
        LO_SENDER = CL_CAM_ADDRESS_BCS=>CREATE_INTERNET_ADDRESS(
                      I_ADDRESS_STRING = P_SENDER
                      I_ADDRESS_NAME   = P_NAME ).
        LO_SEND->SET_SENDER( I_SENDER = LO_SENDER ).
      ELSE.
        LO_SENDER = CL_SAPUSER_BCS=>CREATE( SY-UNAME ).
        LO_SEND->SET_SENDER( I_SENDER = LO_SENDER ).
      ENDIF.

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
ENDFORM.                    "F_MAIL_SEND

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
ENDFORM.                    "F_FORMAT_DATE_ID

*&---------------------------------------------------------------*
*& Form F_XML_ESC -- amankan teks untuk SpreadsheetML XML
*&---------------------------------------------------------------*
FORM F_XML_ESC CHANGING P_TEXT TYPE STRING.
  REPLACE ALL OCCURRENCES OF '&' IN P_TEXT WITH '&amp;'.
  REPLACE ALL OCCURRENCES OF '<' IN P_TEXT WITH '&lt;'.
  REPLACE ALL OCCURRENCES OF '>' IN P_TEXT WITH '&gt;'.
  REPLACE ALL OCCURRENCES OF '"' IN P_TEXT WITH '&quot;'.
ENDFORM.                    "F_XML_ESC

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
        LV_EBELP  TYPE STRING,
        LV_BSART  TYPE STRING,
        LV_BDESC  TYPE STRING,
        LV_VENDOR TYPE STRING,
        LV_VNAME  TYPE STRING,
        LV_MATNR  TYPE STRING,
        LV_TXZ01  TYPE STRING,
        LV_WAERS  TYPE STRING,
        LV_PNAT   TYPE C LENGTH 30,
        LV_PUSD   TYPE C LENGTH 30,
        LV_MEINS  TYPE STRING,
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
  APPEND '<Column ss:Width="80"/><Column ss:Width="55"/>' TO LT_X.
  APPEND '<Column ss:Width="70"/><Column ss:Width="160"/>' TO LT_X.
  APPEND '<Column ss:Width="100"/><Column ss:Width="125"/>' TO LT_X.
  APPEND '<Column ss:Width="95"/><Column ss:Width="180"/>' TO LT_X.
  APPEND '<Column ss:Width="65"/><Column ss:Width="90"/>' TO LT_X.
  APPEND '<Column ss:Width="100"/><Column ss:Width="75"/>' TO LT_X.
  APPEND '<Column ss:Width="55"/><Column ss:Width="95"/>' TO LT_X.
  APPEND '<Column ss:Width="260"/>' TO LT_X.
  APPEND '<Row ss:Height="24"><Cell ss:StyleID="title" ss:MergeAcross="14">' TO LT_X.
  APPEND '<Data ss:Type="String">Detail PO Menunggu Persetujuan</Data></Cell></Row>' TO LT_X.
  CONCATENATE '<Row><Cell ss:StyleID="sub" ss:MergeAcross="14"><Data ss:Type="String">Tanggal Pengiriman: '
              P_DATE '</Data></Cell></Row>' INTO LV_ROW.
  APPEND LV_ROW TO LT_X.
  CONCATENATE '<Row><Cell ss:StyleID="sub" ss:MergeAcross="14"><Data ss:Type="String">Grup Approver: '
              P_OPT '</Data></Cell></Row>' INTO LV_ROW.
  APPEND LV_ROW TO LT_X.
  APPEND '<Row><Cell ss:StyleID="header"><Data ss:Type="String">No. PO</Data></Cell>' TO LT_X.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Item PO</Data></Cell>' TO LT_X.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">PO Type</Data></Cell>' TO LT_X.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">PO Type Description</Data></Cell>' TO LT_X.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Vendor</Data></Cell>' TO LT_X.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Vendor Name</Data></Cell>' TO LT_X.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Material</Data></Cell>' TO LT_X.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Short text</Data></Cell>' TO LT_X.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Currency</Data></Cell>' TO LT_X.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Price per Unit</Data></Cell>' TO LT_X.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Price per Unit (USD)</Data></Cell>' TO LT_X.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Order Unit</Data></Cell>' TO LT_X.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Tier</Data></Cell>' TO LT_X.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Flag</Data></Cell>' TO LT_X.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Alasan Exception</Data></Cell></Row>' TO LT_X.

  LOOP AT GT_MAIL INTO LS_MAIL WHERE APPR_OPT = P_OPT.
    CLEAR: LV_EBELN, LV_EBELP, LV_BSART, LV_BDESC, LV_VENDOR, LV_VNAME,
           LV_MATNR, LV_TXZ01, LV_WAERS, LV_PNAT, LV_PUSD, LV_MEINS,
           LV_TIER, LV_FLAG, LV_REAS, LV_STYLE, LV_NSTYLE.
    LV_EBELN  = LS_MAIL-EBELN.
    LV_EBELP  = LS_MAIL-EBELP.
    LV_BSART  = LS_MAIL-BSART.
    LV_BDESC  = LS_MAIL-BSART_DESC.
    LV_VENDOR = LS_MAIL-LIFNR.
    LV_VNAME  = LS_MAIL-NAME1.
    LV_MATNR  = LS_MAIL-MATNR.
    LV_TXZ01  = LS_MAIL-TXZ01.
    LV_WAERS  = LS_MAIL-WAERS.
    LV_MEINS  = LS_MAIL-MEINS.
    LV_TIER   = LS_MAIL-TIER.
    LV_REAS   = LS_MAIL-EXC_REASON.
    PERFORM F_PRETTY_REASON CHANGING LV_REAS.
    IF LV_REAS IS INITIAL.
      LV_REAS = '-'.
    ENDIF.
    WRITE LS_MAIL-PRICE_NATIVE TO LV_PNAT NO-GROUPING DECIMALS 2.
    CONDENSE LV_PNAT.
    REPLACE ALL OCCURRENCES OF ',' IN LV_PNAT WITH '.'.
    WRITE LS_MAIL-PRICE_USD TO LV_PUSD NO-GROUPING DECIMALS 2.
    CONDENSE LV_PUSD.
    REPLACE ALL OCCURRENCES OF ',' IN LV_PUSD WITH '.'.
    PERFORM F_XML_ESC CHANGING LV_EBELN.
    PERFORM F_XML_ESC CHANGING LV_BSART.
    PERFORM F_XML_ESC CHANGING LV_BDESC.
    PERFORM F_XML_ESC CHANGING LV_VENDOR.
    PERFORM F_XML_ESC CHANGING LV_VNAME.
    PERFORM F_XML_ESC CHANGING LV_MATNR.
    PERFORM F_XML_ESC CHANGING LV_TXZ01.
    PERFORM F_XML_ESC CHANGING LV_WAERS.
    PERFORM F_XML_ESC CHANGING LV_MEINS.
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
                '"><Data ss:Type="String">' LV_EBELP '</Data></Cell>'
                INTO LV_ROW.
    APPEND LV_ROW TO LT_X.
    CONCATENATE '<Cell ss:StyleID="' LV_STYLE '"><Data ss:Type="String">'
                LV_BSART '</Data></Cell><Cell ss:StyleID="' LV_STYLE
                '"><Data ss:Type="String">' LV_BDESC '</Data></Cell>'
                INTO LV_ROW.
    APPEND LV_ROW TO LT_X.
    CONCATENATE '<Cell ss:StyleID="' LV_STYLE '"><Data ss:Type="String">'
                LV_VENDOR '</Data></Cell><Cell ss:StyleID="' LV_STYLE
                '"><Data ss:Type="String">' LV_VNAME '</Data></Cell>'
                INTO LV_ROW.
    APPEND LV_ROW TO LT_X.
    CONCATENATE '<Cell ss:StyleID="' LV_STYLE '"><Data ss:Type="String">'
                LV_MATNR '</Data></Cell><Cell ss:StyleID="' LV_STYLE
                '"><Data ss:Type="String">' LV_TXZ01 '</Data></Cell>'
                INTO LV_ROW.
    APPEND LV_ROW TO LT_X.
    CONCATENATE '<Cell ss:StyleID="' LV_STYLE '"><Data ss:Type="String">'
                LV_WAERS '</Data></Cell>' INTO LV_ROW.
    APPEND LV_ROW TO LT_X.
    CONCATENATE '<Cell ss:StyleID="' LV_NSTYLE '"><Data ss:Type="Number">'
                LV_PNAT '</Data></Cell><Cell ss:StyleID="' LV_NSTYLE
                '"><Data ss:Type="Number">' LV_PUSD '</Data></Cell>'
                INTO LV_ROW.
    APPEND LV_ROW TO LT_X.
    CONCATENATE '<Cell ss:StyleID="' LV_STYLE '"><Data ss:Type="String">'
                LV_MEINS '</Data></Cell><Cell ss:StyleID="' LV_STYLE
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
  APPEND '<AutoFilter x:Range="R4C1:R999C15" xmlns="urn:schemas-microsoft-com:office:excel"/>' TO LT_X.
  APPEND '<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">' TO LT_X.
  APPEND '<FreezePanes/><FrozenNoSplit/><SplitHorizontal>4</SplitHorizontal>' TO LT_X.
  APPEND '<TopRowBottomPane>4</TopRowBottomPane></WorksheetOptions>' TO LT_X.
  APPEND '</Worksheet></Workbook>' TO LT_X.
  CONCATENATE LINES OF LT_X INTO P_XML SEPARATED BY LV_NL.
ENDFORM.                    "F_BUILD_XLS

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
ENDFORM.                    "F_ADD_REASON

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
ENDFORM.                    "F_TO_USD

*&---------------------------------------------------------------*
*& Form F_GET_LAST  -- harga PO released terakhir menurut BEDAT
*&                     (opsional filter vendor). EBELN < current.
*&---------------------------------------------------------------*
FORM F_GET_LAST USING P_MATNR TYPE MATNR P_LIFNR TYPE LIFNR
                      P_EBELN TYPE EBELN
                CHANGING P_LAST TYPE TY_LAST P_HAS TYPE C.
  CLEAR: P_LAST, P_HAS.
  IF P_LIFNR IS INITIAL.
    SELECT B~NETPR B~PEINH B~BPRME A~WAERS A~BEDAT
      INTO P_LAST UP TO 1 ROWS
      FROM EKKO AS A INNER JOIN EKPO AS B ON B~EBELN = A~EBELN
      WHERE B~MATNR = P_MATNR
        AND B~LOEKZ = SPACE
        AND A~EBELN < P_EBELN
        AND A~FRGZU = 'X'
        AND A~BSTYP = 'F'
      ORDER BY A~BEDAT DESCENDING A~EBELN DESCENDING.
    ENDSELECT.
  ELSE.
    SELECT B~NETPR B~PEINH B~BPRME A~WAERS A~BEDAT
      INTO P_LAST UP TO 1 ROWS
      FROM EKKO AS A INNER JOIN EKPO AS B ON B~EBELN = A~EBELN
      WHERE B~MATNR = P_MATNR
        AND A~LIFNR = P_LIFNR
        AND B~LOEKZ = SPACE
        AND A~EBELN < P_EBELN
        AND A~FRGZU = 'X'
        AND A~BSTYP = 'F'
      ORDER BY A~BEDAT DESCENDING A~EBELN DESCENDING.
    ENDSELECT.
  ENDIF.
  IF SY-SUBRC EQ 0.
    P_HAS = 'X'.
  ENDIF.
ENDFORM.                    "F_GET_LAST

*&---------------------------------------------------------------*
*& Form F_GET_LPRINT -- Router Last Price Dinamis Berbasis Plant
*&   Deteksi Plant (T001W / T001K) untuk routing:
*&   - TTE          -> F_GET_LP_TTE
*&   - TTA          -> F_GET_LP_TTA
*&   - Trias/Unggul -> F_GET_LP_TRIAS (PO Biasa)
*&---------------------------------------------------------------*
FORM F_GET_LPRINT USING P_WERKS TYPE WERKS_D
                        P_MATNR TYPE MATNR
                        P_EBELN TYPE EBELN
                        P_EBELP TYPE EBELP
                        P_WAERS TYPE WAERS
                  CHANGING P_LAST_PRICE TYPE P.
  TYPES: BEGIN OF TY_PLANT_MAP,
           WERKS TYPE WERKS_D,
           TYPE  TYPE CHAR10,
         END OF TY_PLANT_MAP.
  STATICS: ST_PLANT_MAP TYPE TABLE OF TY_PLANT_MAP.
  DATA: LS_PMAP  TYPE TY_PLANT_MAP,
        LV_NAME1 TYPE T001W-NAME1,
        LV_BWKEY TYPE T001W-BWKEY,
        LV_BUKRS TYPE T001K-BUKRS.

  CLEAR P_LAST_PRICE.
  CHECK P_MATNR IS NOT INITIAL.

* 1. Buffer memori per plant agar tidak query berulang
  READ TABLE ST_PLANT_MAP INTO LS_PMAP WITH KEY WERKS = P_WERKS.
  IF SY-SUBRC NE 0.
    CLEAR: LS_PMAP, LV_NAME1, LV_BWKEY, LV_BUKRS.
    LS_PMAP-WERKS = P_WERKS.
    LS_PMAP-TYPE  = 'TRIAS'. " Default: Trias PO biasa / Unggul

    SELECT SINGLE NAME1 BWKEY INTO (LV_NAME1, LV_BWKEY)
      FROM T001W
      WHERE WERKS = P_WERKS.
    IF SY-SUBRC = 0.
      SELECT SINGLE BUKRS INTO LV_BUKRS
        FROM T001K
        WHERE BWKEY = LV_BWKEY.

      IF P_WERKS CP 'TTE*' OR LV_NAME1 CS 'TOYO'
         OR LV_NAME1 CS 'TTE' OR LV_BUKRS = '2000'.
        LS_PMAP-TYPE = 'TTE'.
      ELSEIF P_WERKS CP 'TTA*' OR LV_NAME1 CS 'TIRTA'
         OR LV_NAME1 CS 'TTA' OR LV_BUKRS = '3000'.
        LS_PMAP-TYPE = 'TTA'.
      ELSE.
        " Termasuk 'UNGGUL' / Trias biasa -> tetap 'TRIAS'
        LS_PMAP-TYPE = 'TRIAS'.
      ENDIF.
    ENDIF.

    APPEND LS_PMAP TO ST_PLANT_MAP.
  ENDIF.

* 2. Router ke sub-form sesuai entitas
  CASE LS_PMAP-TYPE.
    WHEN 'TTE'.
      PERFORM F_GET_LP_TTE USING P_MATNR P_EBELN P_EBELP P_WAERS
                           CHANGING P_LAST_PRICE.

    WHEN 'TTA'.
      PERFORM F_GET_LP_TTA USING P_MATNR P_EBELN P_EBELP P_WAERS
                           CHANGING P_LAST_PRICE.

    WHEN OTHERS. " 'TRIAS' (Trias PO biasa & Unggul)
      PERFORM F_GET_LP_TRIAS USING P_MATNR P_EBELN P_WAERS
                             CHANGING P_LAST_PRICE.
  ENDCASE.
ENDFORM.                    "F_GET_LPRINT

*&---------------------------------------------------------------*
*& Form F_GET_LP_TTE -- Last Price Entitas TTE
*&   (driver ZMMF_TTE_PO_LOCAL_PDF / output type Z09)
*&   WAERS dari PO KNUMV tertinggi, KBETR = NETPR PO EBELN tertinggi
*&---------------------------------------------------------------*
FORM F_GET_LP_TTE USING P_MATNR TYPE MATNR
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

  CLEAR: P_LAST_PRICE, LV_KNUMV, LV_KPOSN, LV_MTART, LV_CHARG.

* Batch hanya utk RPV/RPC/RPM (ZRAW), spt driver TTE
  IF P_MATNR = 'RPV' OR P_MATNR = 'RPC' OR P_MATNR = 'RPM'.
    SELECT SINGLE MTART INTO LV_MTART FROM MARA
      WHERE MATNR = P_MATNR AND MTART = 'ZRAW'.
    IF SY-SUBRC = 0.
      SELECT SINGLE CHARG INTO LV_CHARG FROM EKET
        WHERE EBELN = P_EBELN AND EBELP = P_EBELP.
    ENDIF.
  ENDIF.

* 1. PO acuan KNUMV tertinggi -> KNUMV/KPOSN (sumber WAERS)
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

* 2. WAERS dari KONV PO KNUMV tertinggi (PB00/PBXX)
  CLEAR: LC_KBETR, LV_LW.
  SELECT SINGLE KBETR WAERS INTO (LC_KBETR, LV_LW) FROM KONV
    WHERE KNUMV = LV_KNUMV AND KPOSN = LV_KPOSN
      AND ( KSCHL = 'PB00' OR KSCHL = 'PBXX' ).

* 3. KBETR = NETPR PO EBELN tertinggi (baris terakhir ORDER BY ASC)
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

* 4. Konversi 2-hop via IDR pakai WAERS dari step 2
  CLEAR: LV_KURS, LV_NEW.
  IF P_WAERS NE LV_LW.
    IF LV_LW EQ 'IDR'.
      LC_KBETR = LC_KBETR.
    ELSE.
      CALL FUNCTION 'RKC_SINGLE_EXCHANGE_RATE_GET'
        EXPORTING
          DATUM         = SY-DATUM
          KURST         = 'M'
          NCURR         = 'IDR'
          VCURR         = LV_LW
        IMPORTING
          EXCHR         = LV_KURS
        EXCEPTIONS
          NO_RATE_FOUND = 1
          OTHERS        = 2.
      LC_KBETR = LC_KBETR * LV_KURS.
    ENDIF.
    LV_NEW = LC_KBETR.
    CALL FUNCTION 'CURRENCY_AMOUNT_SAP_TO_DISPLAY'
      EXPORTING
        CURRENCY        = LV_LW
        AMOUNT_INTERNAL = LV_NEW
      IMPORTING
        AMOUNT_DISPLAY  = LV_NEW.
    LC_KBETR = LV_NEW.
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
    LV_NEW = LC_KBETR.
    CALL FUNCTION 'CURRENCY_AMOUNT_SAP_TO_DISPLAY'
      EXPORTING
        CURRENCY        = LV_LW
        AMOUNT_INTERNAL = LV_NEW
      IMPORTING
        AMOUNT_DISPLAY  = LV_NEW.
    LC_KBETR = LV_NEW.
  ENDIF.

  P_LAST_PRICE = LC_KBETR.
ENDFORM.                    "F_GET_LP_TTE

*&---------------------------------------------------------------*
*& Form F_GET_LP_TTA -- Last Price Entitas TTA
*&   (driver ZMMF_TTA_PO_LOCAL_PDF / output type Z07)
*&   Sesuai driver TTA: hybrid KNUMV (WAERS) + EBELN (NETPR)
*&---------------------------------------------------------------*
FORM F_GET_LP_TTA USING P_MATNR TYPE MATNR
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

  CLEAR: P_LAST_PRICE, LV_KNUMV, LV_KPOSN, LV_MTART, LV_CHARG.

* Batch hanya utk RPV/RPC/RPM (ZRAW)
  IF P_MATNR = 'RPV' OR P_MATNR = 'RPC' OR P_MATNR = 'RPM'.
    SELECT SINGLE MTART INTO LV_MTART FROM MARA
      WHERE MATNR = P_MATNR AND MTART = 'ZRAW'.
    IF SY-SUBRC = 0.
      SELECT SINGLE CHARG INTO LV_CHARG FROM EKET
        WHERE EBELN = P_EBELN AND EBELP = P_EBELP.
    ENDIF.
  ENDIF.

* 1. PO acuan KNUMV tertinggi -> KNUMV/KPOSN (sumber WAERS)
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

* 2. WAERS dari KONV PO KNUMV tertinggi (PB00/PBXX)
  CLEAR: LC_KBETR, LV_LW.
  SELECT SINGLE KBETR WAERS INTO (LC_KBETR, LV_LW) FROM KONV
    WHERE KNUMV = LV_KNUMV AND KPOSN = LV_KPOSN
      AND ( KSCHL = 'PB00' OR KSCHL = 'PBXX' ).

* 3. KBETR = NETPR PO EBELN tertinggi
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

* 4. Konversi 2-hop via IDR pakai WAERS dari step 2
  CLEAR: LV_KURS, LV_NEW.
  IF P_WAERS NE LV_LW.
    IF LV_LW EQ 'IDR'.
      LC_KBETR = LC_KBETR.
    ELSE.
      CALL FUNCTION 'RKC_SINGLE_EXCHANGE_RATE_GET'
        EXPORTING
          DATUM         = SY-DATUM
          KURST         = 'M'
          NCURR         = 'IDR'
          VCURR         = LV_LW
        IMPORTING
          EXCHR         = LV_KURS
        EXCEPTIONS
          NO_RATE_FOUND = 1
          OTHERS        = 2.
      LC_KBETR = LC_KBETR * LV_KURS.
    ENDIF.
    LV_NEW = LC_KBETR.
    CALL FUNCTION 'CURRENCY_AMOUNT_SAP_TO_DISPLAY'
      EXPORTING
        CURRENCY        = LV_LW
        AMOUNT_INTERNAL = LV_NEW
      IMPORTING
        AMOUNT_DISPLAY  = LV_NEW.
    LC_KBETR = LV_NEW.
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
    LV_NEW = LC_KBETR.
    CALL FUNCTION 'CURRENCY_AMOUNT_SAP_TO_DISPLAY'
      EXPORTING
        CURRENCY        = LV_LW
        AMOUNT_INTERNAL = LV_NEW
      IMPORTING
        AMOUNT_DISPLAY  = LV_NEW.
    LC_KBETR = LV_NEW.
  ENDIF.

  P_LAST_PRICE = LC_KBETR.
ENDFORM.                    "F_GET_LP_TTA

*&---------------------------------------------------------------*
*& Form F_GET_LP_TRIAS -- Last Price Entitas Trias & Unggul
*&   (driver ZMMF_PO_LOCAL / PO Biasa)
*&   1. PO acuan: material sama, released, EBELN<current, KNUMV max
*&   2. KBETR murni dari KONV (PB00/PBXX) PO acuan
*&   3. Konversi 2-hop via IDR kurs SY-DATUM
*&---------------------------------------------------------------*
FORM F_GET_LP_TRIAS USING P_MATNR TYPE MATNR
                          P_EBELN TYPE EBELN
                          P_WAERS TYPE WAERS
                    CHANGING P_LAST_PRICE TYPE P.
  DATA: LV_KNUMV TYPE KONV-KNUMV,
        LV_KPOSN TYPE KONV-KPOSN,
        LV_LW    TYPE KONV-WAERS,
        LC_KBETR TYPE KONV-KBETR,
        LV_KURS  TYPE RKB1K-EXCHR,
        LV_NEW   TYPE WMTO_S-AMOUNT.

  CLEAR: P_LAST_PRICE, LV_KNUMV, LV_KPOSN.

* 1. PO acuan KNUMV tertinggi
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

* 2. KBETR & WAERS murni dari KONV (PB00/PBXX) PO acuan tsb
  CLEAR: LC_KBETR, LV_LW.
  SELECT SINGLE KBETR WAERS INTO (LC_KBETR, LV_LW)
    FROM KONV
    WHERE KNUMV = LV_KNUMV
      AND KPOSN = LV_KPOSN
      AND ( KSCHL = 'PB00' OR KSCHL = 'PBXX' ).
  IF SY-SUBRC NE 0.
    RETURN.
  ENDIF.

* 3. Konversi 2-hop via IDR kurs SY-DATUM
  CLEAR: LV_KURS, LV_NEW.
  IF P_WAERS NE LV_LW.
    IF LV_LW EQ 'IDR'.
      LC_KBETR = LC_KBETR.
    ELSE.
      CALL FUNCTION 'RKC_SINGLE_EXCHANGE_RATE_GET'
        EXPORTING
          DATUM         = SY-DATUM
          KURST         = 'M'
          NCURR         = 'IDR'
          VCURR         = LV_LW
        IMPORTING
          EXCHR         = LV_KURS
        EXCEPTIONS
          NO_RATE_FOUND = 1
          OTHERS        = 2.
      LC_KBETR = LC_KBETR * LV_KURS.
    ENDIF.
    LV_NEW = LC_KBETR.
    CALL FUNCTION 'CURRENCY_AMOUNT_SAP_TO_DISPLAY'
      EXPORTING
        CURRENCY        = LV_LW
        AMOUNT_INTERNAL = LV_NEW
      IMPORTING
        AMOUNT_DISPLAY  = LV_NEW.
    LC_KBETR = LV_NEW.
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
    LV_NEW = LC_KBETR.
    CALL FUNCTION 'CURRENCY_AMOUNT_SAP_TO_DISPLAY'
      EXPORTING
        CURRENCY        = LV_LW
        AMOUNT_INTERNAL = LV_NEW
      IMPORTING
        AMOUNT_DISPLAY  = LV_NEW.
    LC_KBETR = LV_NEW.
  ENDIF.

  P_LAST_PRICE = LC_KBETR.
ENDFORM.                    "F_GET_LP_TRIAS

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
  PERFORM F_TO_USD USING LV_UNIT P_LAST-WAERS P_LAST-BEDAT
                   CHANGING LV_USD.
  IF LV_USD > 0 AND P_CURUSD > LV_USD * LV_PRICE_FACTOR.
    P_EXC = 'X'.
    PERFORM F_ADD_REASON USING P_TOKEN CHANGING P_REASON.
  ENDIF.
ENDFORM.                    "F_CHK_NAIK

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
ENDFORM.                    "F_PRETTY_REASON

*&---------------------------------------------------------------*
*& Form F_PRETTY_REASON_ALV -- label exception + separator report
*&---------------------------------------------------------------*
FORM F_PRETTY_REASON_ALV CHANGING P_TXT TYPE STRING.
  DATA: LT_REASON TYPE STANDARD TABLE OF STRING,
        LS_REASON TYPE STRING,
        LV_OUT    TYPE STRING.

  PERFORM F_PRETTY_REASON CHANGING P_TXT.
  SPLIT P_TXT AT ';' INTO TABLE LT_REASON.
  CLEAR LV_OUT.
  LOOP AT LT_REASON INTO LS_REASON.
    CONDENSE LS_REASON.
    IF LV_OUT IS INITIAL.
      LV_OUT = LS_REASON.
    ELSE.
      CONCATENATE LV_OUT LS_REASON INTO LV_OUT SEPARATED BY '; '.
    ENDIF.
  ENDLOOP.
  P_TXT = LV_OUT.
ENDFORM.                    "F_PRETTY_REASON_ALV

*&---------------------------------------------------------------*
*& Form F_INIT_LAYOUT -- Inisialisasi default layout ALV
*&---------------------------------------------------------------*
FORM F_INIT_LAYOUT.
  DATA: LS_VARIANT TYPE DISVARIANT.

  CLEAR LS_VARIANT.
  LS_VARIANT-REPORT = SY-CPROG.

  CALL FUNCTION 'REUSE_ALV_VARIANT_DEFAULT_GET'
    EXPORTING
      I_SAVE     = 'A'
    CHANGING
      CS_VARIANT = LS_VARIANT
    EXCEPTIONS
      OTHERS     = 1.

  IF SY-SUBRC EQ 0 AND LS_VARIANT-VARIANT IS NOT INITIAL.
    P_VARI = LS_VARIANT-VARIANT.
  ELSE.
    " Jika tidak ada default setting, pilih layout teratas
    CLEAR P_VARI.
    SELECT VARIANT FROM LTDX INTO P_VARI UP TO 1 ROWS
      WHERE REPORT = SY-CPROG
        AND ( USERNAME = SY-UNAME OR USERNAME = SPACE )
      ORDER BY USERNAME DESCENDING VARIANT ASCENDING.
    ENDSELECT.
  ENDIF.
ENDFORM.                    "F_INIT_LAYOUT

*&---------------------------------------------------------------*
*& Form F_F4_LAYOUT -- Value help dialog untuk layout ALV
*&---------------------------------------------------------------*
FORM F_F4_LAYOUT.
  DATA: LS_VARIANT TYPE DISVARIANT,
        LV_EXIT    TYPE CHAR1.

  CLEAR LS_VARIANT.
  LS_VARIANT-REPORT = SY-CPROG.

  CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
    EXPORTING
      IS_VARIANT = LS_VARIANT
      I_SAVE     = 'A'
    IMPORTING
      E_EXIT     = LV_EXIT
      ES_VARIANT = LS_VARIANT
    EXCEPTIONS
      OTHERS     = 1.

  IF SY-SUBRC EQ 0 AND LV_EXIT IS INITIAL.
    P_VARI = LS_VARIANT-VARIANT.
  ENDIF.
ENDFORM.                    "F_F4_LAYOUT

*&---------------------------------------------------------------*
*& Form F_VALIDATE_LAYOUT -- Validasi eksistensi Layout ALV
*&---------------------------------------------------------------*
FORM F_VALIDATE_LAYOUT.
  DATA: LS_CHECK_VAR TYPE DISVARIANT.

  IF SY-UCOMM EQ 'G1'.
    RETURN.
  ENDIF.

  IF P_RPT EQ 'X' AND P_VARI IS NOT INITIAL.
    CLEAR LS_CHECK_VAR.
    LS_CHECK_VAR-REPORT  = SY-CPROG.
    LS_CHECK_VAR-VARIANT = P_VARI.

    CALL FUNCTION 'REUSE_ALV_VARIANT_EXISTENCE'
      EXPORTING
        I_SAVE     = 'A'
      CHANGING
        CS_VARIANT = LS_CHECK_VAR
      EXCEPTIONS
        OTHERS     = 1.

    IF SY-SUBRC NE 0.
      MESSAGE E000(0K) WITH 'Layout tidak ditemukan'(004).
    ENDIF.
  ENDIF.
ENDFORM.                    "F_VALIDATE_LAYOUT
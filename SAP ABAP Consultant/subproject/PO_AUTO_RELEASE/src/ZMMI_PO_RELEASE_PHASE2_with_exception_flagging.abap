*&---------------------------------------------------------------*
*& Report  ZMMI_PO_RELEASE_PHASE2  (Sprint 2 - Routing Approval)
*&---------------------------------------------------------------*
*& Basis: ZMMI_PO_RELEASE v10 (Sprint 1) yang sudah bersih.
*& Referensi logika routing: ZPO_AUTO_RELEASE_PHASE2 v5 (lama).
*&
*& FOKUS TAHAP INI: ROUTING APPROVAL saja.
*& - Tentukan TIER PO dari mapping THRESHOLD (ascending):
*&     T0 (<= USD 500, TEXT1='X') -> AUTO release (jalur Sprint 1).
*&     T1 (<= USD 5.000)          -> approver by EKGRP (fallback DEFAULT).
*&     T2 (di atas T1)            -> SELALU GM Purchasing (OPT=GM_FIXED),
*&                                   TIDAK berdasarkan EKGRP.
*& - Untuk T1/T2: program HANYA mengidentifikasi approver (nama+email)
*&   dari ZMAP_TYPE dan set status 'M' (perlu approval manual di SAP).
*&   BELUM kirim email (email notif = tahap berikutnya).
*&
*& CATATAN mapping: semua baris ZMAP_TYPE dibaca dengan PROG tetap
*& = GC_MAP_PROG ('ZMMI_PO_RELEASE'), BUKAN SY-CPROG. Ini supaya
*& program PHASE2 reuse mapping yang sudah benar tanpa duplikasi.
*&
*& Warisan fix Sprint 1 yang DIPERTAHANKAN:
*& - Seleksi PO pending pakai FRGRL='X' (index EKKO~2), bukan FRGKE.
*& - Konversi USD pakai EKKO-BEDAT (tgl PO), bukan SY-DATUM.
*& - Test mode (P_TEST='X') pada jalur AUTO: TIDAK panggil BAPI_PO_
*&   RELEASE sama sekali (rollback terbukti tidak bisa membatalkan).
*& - AUTHORITY-CHECK sengaja tidak dipakai (background job IT user).
*&---------------------------------------------------------------*
*&
*& CATATAN ROLLBACK (2026-07-17): versi ini ADALAH versi dengan
*& exception flagging (5 kriteria: VendorBaru, MaterialBaru,
*& HargaNaik10pct, NoPriceHistory/PriceHistoryStale, ServiceCapex).
*& Diarsipkan atas permintaan Baginda untuk dibandingkan dengan
*& versi routing-only sebelum exception flagging ditambahkan.
*& Program LIVE di sandbox-new sudah di-rollback ke versi tanpa
*& exception flagging -- file ini HANYA arsip, tidak live di SAP.
*&
*& Review findings yang belum diperbaiki di versi ini (lihat chat):
*& - Exception flagging jalan untuk SEMUA tier (T0/T1/T2), padahal
*&   requirement email eksplisit membatasi hanya T1/T2.
*& - Kriteria harga & price history pakai EINE (info record price),
*&   bukan harga PO terakhir yang sebenarnya (seharusnya EIPA/EKBE).
*&   Belum ada normalisasi PEINH (price unit).
*& - ServiceCapex pakai PSTYP <> '0' (terlalu lebar, ikut menangkap
*&   subcontracting/consignment/third-party). Seharusnya PSTYP='9'
*&   khusus untuk service.
*& - EKPO-MATNR tidak ada index pendukung untuk cek MaterialBaru --
*&   risiko performa di volume produksi (100rb+ PO).
*&---------------------------------------------------------------*

REPORT ZMMI_PO_RELEASE_PHASE2 LINE-SIZE 150.

TABLES: EKKO, EKPO.

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
         LOEKZ TYPE EKKO-LOEKZ,
         LIFNR TYPE EKKO-LIFNR,
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
         TEXT1 TYPE ZMAP_TYPE-TEXT1,
       END OF TY_APPROVER.

TYPES: BEGIN OF TY_RELCODE,
         FRGCO TYPE T16FV-FRGCO,
       END OF TY_RELCODE.

TYPES: BEGIN OF TY_EKPOD,
         MATNR TYPE EKPO-MATNR,
         NETPR TYPE EKPO-NETPR,
         PSTYP TYPE EKPO-PSTYP,
         KNTTP TYPE EKPO-KNTTP,
         WERKS TYPE EKPO-WERKS,
       END OF TY_EKPOD.

TYPES: BEGIN OF TY_RESULT,
         EBELN     TYPE EKKO-EBELN,
         USDVAL    TYPE P DECIMALS 2,
         TIER      TYPE ZMAP_TYPE-OPT,
         REL_CODE  TYPE BAPIMMPARA-PO_REL_COD,
         APPR_NAME TYPE ZMAP_TYPE-VALUE,
         APPR_MAIL TYPE ZMAP_TYPE-TEXT1,
         STATUS    TYPE CHAR1,
         MESSAGE   TYPE BAPI_MSG,
         EXC_FLAG   TYPE CHAR1,
         EXC_REASON TYPE C LENGTH 100,
       END OF TY_RESULT.

DATA: LT_EKKO      TYPE STANDARD TABLE OF TY_EKKO,
      LS_EKKO      TYPE TY_EKKO,
      LT_THRESHOLD TYPE STANDARD TABLE OF TY_THRESHOLD,
      LS_THRESHOLD TYPE TY_THRESHOLD,
      LT_APPROVER  TYPE STANDARD TABLE OF TY_APPROVER,
      LS_APPROVER  TYPE TY_APPROVER,
      LT_RELCODE   TYPE STANDARD TABLE OF TY_RELCODE,
      LS_RELCODE   TYPE TY_RELCODE,
      LT_EKPOD     TYPE STANDARD TABLE OF TY_EKPOD,
      LS_EKPOD     TYPE TY_EKPOD,
      LT_RESULT    TYPE STANDARD TABLE OF TY_RESULT,
      LS_RESULT    TYPE TY_RESULT.

DATA: LV_NETWR     TYPE EKPO-NETWR,
      LV_USDVAL    TYPE P DECIMALS 2,
      LV_KURS      TYPE RKB1K-EXCHR,
      LV_RELSTATUS TYPE BAPIMMPARA-REL_STATUS,
      LV_RELIND    TYPE BAPIMMPARA-PO_REL_IND,
      LV_RETCODE   TYPE SY-SUBRC,
      LV_RELEASED  TYPE CHAR1,
      LV_LINES     TYPE I,
      LV_FOUND     TYPE CHAR1,
      LV_AUTO      TYPE CHAR1.

DATA: LT_RETURN TYPE STANDARD TABLE OF BAPIRETURN,
      LS_RETURN TYPE BAPIRETURN.

DATA: LV_DUMMY_EBELN TYPE EKKO-EBELN,
      LV_EXC         TYPE CHAR1,
      LV_EINE_PRICE  TYPE EINE-NETPR,
      LV_EINE_DATE   TYPE EINE-PRDAT,
      LV_CUTOFF      TYPE SY-DATUM,
      LV_EXCCNT      TYPE I.

CONSTANTS: GC_MAP_PROG TYPE ZMAP_TYPE-PROG VALUE 'ZMMI_PO_RELEASE'.

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

  LV_CUTOFF = SY-DATUM - 730.

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
* 2. Load mapping APPROVER (HANYA baris ber-email) dari ZMAP_TYPE
*----------------------------------------------------------------*
  REFRESH LT_APPROVER.
  SELECT OPT VALUE TEXT1
    INTO CORRESPONDING FIELDS OF TABLE LT_APPROVER
    FROM ZMAP_TYPE
    WHERE PROG = GC_MAP_PROG
      AND TYPE = 'APPROVER'
      AND DELETION = SPACE
      AND TEXT1 LIKE '%@%'.

  IF LT_APPROVER IS INITIAL.
    WRITE: / 'Mapping APPROVER (ber-email) belum ada di ZMAP_TYPE. Program dihentikan.'.
    EXIT.
  ENDIF.

*----------------------------------------------------------------*
* 3. Ambil PO yang masih PENDING RELEASE (FRGRL = 'X')
*----------------------------------------------------------------*
  REFRESH LT_EKKO.
  SELECT EBELN BUKRS EKORG EKGRP BSART FRGRL FRGGR FRGSX WAERS BEDAT LOEKZ LIFNR
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

    CLEAR: LS_RESULT, LV_NETWR, LV_USDVAL, LV_RELEASED, LV_AUTO.
    LS_RESULT-EBELN = LS_EKKO-EBELN.

*   --- 4a. Total nilai PO ---
    SELECT SUM( NETWR ) INTO LV_NETWR
      FROM EKPO
      WHERE EBELN = LS_EKKO-EBELN
        AND LOEKZ EQ SPACE.

*   --- 4b. Konversi ke USD pakai KURS PADA TANGGAL PO DIBUAT (BEDAT) ---
    IF LS_EKKO-WAERS EQ 'USD'.
      LV_USDVAL = LV_NETWR.
    ELSE.
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

      LV_USDVAL = LV_NETWR * LV_KURS.
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
*   4c2. EXCEPTION FLAGGING (4 kriteria dari email Douglas, independen
*        dari tier/routing -- jalan utk semua PO yang sudah lolos tier)
*   ================================================================
    CLEAR: LV_EXC, LS_RESULT-EXC_FLAG, LS_RESULT-EXC_REASON.

*   Kriteria 1: Vendor baru (belum pernah ada PO lain dari vendor ini)
    CLEAR LV_DUMMY_EBELN.
    SELECT SINGLE EBELN INTO LV_DUMMY_EBELN
      FROM EKKO
      WHERE LIFNR = LS_EKKO-LIFNR
        AND EBELN NE LS_EKKO-EBELN
        AND BSTYP EQ 'F'.
    IF SY-SUBRC NE 0.
      LV_EXC = 'X'.
      CONCATENATE LS_RESULT-EXC_REASON 'VendorBaru;' INTO LS_RESULT-EXC_REASON.
    ENDIF.

*   Ambil detail item PO ini utk cek material/harga/service-capex
    REFRESH LT_EKPOD.
    SELECT MATNR NETPR PSTYP KNTTP WERKS
      INTO TABLE LT_EKPOD
      FROM EKPO
      WHERE EBELN = LS_EKKO-EBELN
        AND LOEKZ EQ SPACE.

    LOOP AT LT_EKPOD INTO LS_EKPOD.

*     Kriteria 5: PO service / capex (item non-stock atau akun Asset)
      IF LS_EKPOD-PSTYP NE '0' OR LS_EKPOD-KNTTP EQ 'A'.
        LV_EXC = 'X'.
        IF LS_RESULT-EXC_REASON NS 'ServiceCapex'.
          CONCATENATE LS_RESULT-EXC_REASON 'ServiceCapex;' INTO LS_RESULT-EXC_REASON.
        ENDIF.
      ENDIF.

      IF LS_EKPOD-MATNR IS INITIAL.
        CONTINUE.
      ENDIF.

*     Kriteria 2: Material baru (belum pernah ada PO lain utk material ini)
      CLEAR LV_DUMMY_EBELN.
      SELECT SINGLE EBELN INTO LV_DUMMY_EBELN
        FROM EKPO
        WHERE MATNR = LS_EKPOD-MATNR
          AND EBELN NE LS_EKKO-EBELN.
      IF SY-SUBRC NE 0.
        LV_EXC = 'X'.
        IF LS_RESULT-EXC_REASON NS 'MaterialBaru'.
          CONCATENATE LS_RESULT-EXC_REASON 'MaterialBaru;' INTO LS_RESULT-EXC_REASON.
        ENDIF.
      ENDIF.

*     Kriteria 3 & 4: harga naik >10% dari info record / price history
*     stale (>24 bulan) atau tidak ada sama sekali.
      CLEAR: LV_EINE_PRICE, LV_EINE_DATE.
      SELECT SINGLE B~NETPR B~PRDAT
        INTO (LV_EINE_PRICE, LV_EINE_DATE)
        FROM EINA AS A INNER JOIN EINE AS B
          ON A~INFNR = B~INFNR
        WHERE A~MATNR = LS_EKPOD-MATNR
          AND A~LIFNR = LS_EKKO-LIFNR
          AND B~EKORG = LS_EKKO-EKORG.

      IF SY-SUBRC NE 0.
        LV_EXC = 'X'.
        IF LS_RESULT-EXC_REASON NS 'NoPriceHistory'.
          CONCATENATE LS_RESULT-EXC_REASON 'NoPriceHistory;' INTO LS_RESULT-EXC_REASON.
        ENDIF.
      ELSE.
        IF LV_EINE_DATE LT LV_CUTOFF.
          LV_EXC = 'X'.
          IF LS_RESULT-EXC_REASON NS 'PriceHistoryStale'.
            CONCATENATE LS_RESULT-EXC_REASON 'PriceHistoryStale;' INTO LS_RESULT-EXC_REASON.
          ENDIF.
        ENDIF.
        IF LV_EINE_PRICE GT 0 AND LS_EKPOD-NETPR > LV_EINE_PRICE * '1.1'.
          LV_EXC = 'X'.
          IF LS_RESULT-EXC_REASON NS 'HargaNaik10pct'.
            CONCATENATE LS_RESULT-EXC_REASON 'HargaNaik10pct;' INTO LS_RESULT-EXC_REASON.
          ENDIF.
        ENDIF.
      ENDIF.

    ENDLOOP.

    LS_RESULT-EXC_FLAG = LV_EXC.

*   ================================================================
*   4d. JALUR AUTO (Tier T0) -> release lewat BAPI (warisan Sprint 1)
*   ================================================================
    IF LV_AUTO EQ 'X'.

      REFRESH LT_RELCODE.
      SELECT FRGCO
        INTO TABLE LT_RELCODE
        FROM T16FV
        WHERE FRGGR = LS_EKKO-FRGGR
          AND FRGSX = LS_EKKO-FRGSX.

      IF LT_RELCODE IS INITIAL.
        LS_RESULT-STATUS  = 'W'.
        LS_RESULT-MESSAGE = 'Tier auto tapi kombinasi FRGGR/FRGSX tidak ditemukan di T16FV'.
        APPEND LS_RESULT TO LT_RESULT.
        CONTINUE.
      ENDIF.

      LOOP AT LT_RELCODE INTO LS_RELCODE.

*       Test mode: TIDAK panggil BAPI sama sekali (aman).
        IF P_TEST EQ 'X'.
          LS_RESULT-REL_CODE = LS_RELCODE-FRGCO.
          LS_RESULT-STATUS   = 'S'.
          LS_RESULT-MESSAGE  = 'Simulasi OK (Test Mode) -- AUTO release, BAPI TIDAK dipanggil'.
          LV_RELEASED = 'X'.
          EXIT.
        ENDIF.

        CLEAR: LV_RELSTATUS, LV_RELIND.
        REFRESH LT_RETURN.

        CALL FUNCTION 'BAPI_PO_RELEASE'
          EXPORTING
            PURCHASEORDER     = LS_EKKO-EBELN
            PO_REL_CODE       = LS_RELCODE-FRGCO
            USE_EXCEPTIONS    = 'X'
          IMPORTING
            REL_STATUS_NEW    = LV_RELSTATUS
            REL_INDICATOR_NEW = LV_RELIND
          TABLES
            RETURN            = LT_RETURN
          EXCEPTIONS
            AUTHORITY_CHECK_FAIL    = 1
            DOCUMENT_NOT_FOUND      = 2
            ENQUEUE_FAIL            = 3
            PREREQUISITE_FAIL       = 4
            RELEASE_ALREADY_POSTED  = 5
            RESPONSIBILITY_FAIL     = 6
            OTHERS                  = 7.

        LV_RETCODE = SY-SUBRC.

        IF LV_RETCODE EQ 0.
          LS_RESULT-REL_CODE = LS_RELCODE-FRGCO.
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
            EXPORTING
              WAIT = 'X'.
          LS_RESULT-STATUS  = 'S'.
          LS_RESULT-MESSAGE = 'PO berhasil di-release otomatis (Tier T0)'.
          LV_RELEASED = 'X'.
          EXIT.
        ELSE.
          CLEAR LS_RETURN.
          READ TABLE LT_RETURN INTO LS_RETURN INDEX 1.
          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
          IF LV_RETCODE EQ 4 OR LV_RETCODE EQ 6.
            CONTINUE.
          ELSE.
            LS_RESULT-STATUS = 'E'.
            IF LS_RETURN-MESSAGE IS NOT INITIAL.
              LS_RESULT-MESSAGE = LS_RETURN-MESSAGE.
            ELSE.
              LS_RESULT-MESSAGE = 'BAPI_PO_RELEASE gagal, cek exception'.
            ENDIF.
            EXIT.
          ENDIF.
        ENDIF.

      ENDLOOP.

      IF LV_RELEASED IS INITIAL AND LS_RESULT-STATUS IS INITIAL.
        LS_RESULT-STATUS  = 'W'.
        LS_RESULT-MESSAGE = 'Tidak ada release code yang applicable saat ini'.
      ENDIF.

*   ================================================================
*   4e. JALUR ROUTING (Tier T1/T2) -> identifikasi approver, TIDAK release
*   ================================================================
    ELSE.

      CLEAR LS_APPROVER.
      IF LS_RESULT-TIER EQ 'T2'.
*       Tier T2: SELALU GM Purchasing (OPT=GM_FIXED), abaikan EKGRP.
        READ TABLE LT_APPROVER INTO LS_APPROVER WITH KEY OPT = 'GM_FIXED'.
      ELSE.
*       Tier T1: approver by EKGRP, fallback ke DEFAULT.
        READ TABLE LT_APPROVER INTO LS_APPROVER WITH KEY OPT = LS_EKKO-EKGRP.
        IF SY-SUBRC NE 0.
          READ TABLE LT_APPROVER INTO LS_APPROVER WITH KEY OPT = 'DEFAULT'.
        ENDIF.
      ENDIF.

      IF SY-SUBRC EQ 0.
        LS_RESULT-APPR_NAME = LS_APPROVER-VALUE.
        LS_RESULT-APPR_MAIL = LS_APPROVER-TEXT1.
        LS_RESULT-STATUS    = 'M'.
        LS_RESULT-MESSAGE   = 'Perlu approval manual di SAP (email notif belum diaktifkan)'.
      ELSE.
        LS_RESULT-STATUS = 'E'.
        IF LS_RESULT-TIER EQ 'T2'.
          LS_RESULT-MESSAGE = 'Tidak ada mapping GM Purchasing (OPT=GM_FIXED) di ZMAP_TYPE'.
        ELSE.
          LS_RESULT-MESSAGE = 'Tidak ada mapping APPROVER utk EKGRP ini, baris DEFAULT juga tidak ada'.
        ENDIF.
      ENDIF.

*     --- TAHAP BERIKUTNYA (belum di sini): kirim email reminder ke
*         LS_RESULT-APPR_MAIL via SO_NEW_DOCUMENT_ATT_SEND_API1.

    ENDIF.

    APPEND LS_RESULT TO LT_RESULT.

  ENDLOOP.

*----------------------------------------------------------------*
* 5. Output hasil
*----------------------------------------------------------------*
  DESCRIBE TABLE LT_RESULT LINES LV_LINES.

  WRITE: / 'Hasil PO Routing Approval (PHASE2)', 55 'Mode:', P_TEST AS CHECKBOX.
  WRITE: / 'Total PO diproses:', LV_LINES.
  SKIP.
  WRITE: / SY-ULINE.
  WRITE: / 'PO Number', 15 'USD Val', 30 'Tier', 37 'RelCd', 45 'Approver', 62 'Email', 85 'St', 89 'Exc', 93 'Alasan Exception'.
  WRITE: / SY-ULINE.

  LOOP AT LT_RESULT INTO LS_RESULT.
    WRITE: / LS_RESULT-EBELN,
             15 LS_RESULT-USDVAL,
             30 LS_RESULT-TIER,
             37 LS_RESULT-REL_CODE,
             45 LS_RESULT-APPR_NAME,
             62 LS_RESULT-APPR_MAIL,
             85 LS_RESULT-STATUS,
             89 LS_RESULT-EXC_FLAG,
             93 LS_RESULT-EXC_REASON.
  ENDLOOP.

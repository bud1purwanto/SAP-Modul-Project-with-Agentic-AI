*&---------------------------------------------------------------*
*& Report  ZPO_AUTO_RELEASE  (v6 - SPRINT 1 SCOPE ONLY)
*&---------------------------------------------------------------*
*& Tujuan : Auto-release PO dengan nilai < USD 500 lewat BAPI_
*&          PO_RELEASE standar. HANYA itu. Untuk PO >= USD 500,
*&          program cuma melaporkan status 'di luar scope Sprint 1'
*&          tanpa identifikasi approver/nama/email sama sekali.
*&
*& PERUBAHAN dari v5 (deliberate scope reduction, bukan bug):
*& - Dihapus SELURUH logic identifikasi APPROVER (Lisa/Melisa/
*&   Fenny/GM_FIXED), field TIER, APPR_NAME, APPR_MAIL, dan mapping
*&   ZMAP_TYPE TYPE='APPROVER'. Itu scope SPRINT 2 (approval flow,
*&   email notification, exception flagging) -- akan dibangun
*&   terpisah saat Sprint 2 mulai, TIDAK dicampur ke program Sprint
*&   1 ini lagi (pelajaran dari revisi timeframe sebelumnya).
*& - Baca mapping THRESHOLD disederhanakan: cuma ambil SATU baris
*&   (TEXT1='X', yaitu baris auto-release), tidak perlu lagi baca
*&   & sort semua tier T0/T1/T2 karena Sprint 1 tidak peduli T1/T2.
*&
*& Release ABAP : 7.31 (tanpa inline DATA(), NEW, VALUE, string
*&                template, atau FOR ALL ENTRIES tanpa guard).
*&---------------------------------------------------------------*

REPORT zpo_auto_release.

TABLES: ekko, ekpo.

*----------------------------------------------------------------*
* Types & Data
*----------------------------------------------------------------*
TYPES: BEGIN OF ty_ekko,
         ebeln TYPE ekko-ebeln,
         bukrs TYPE ekko-bukrs,
         ekorg TYPE ekko-ekorg,
         ekgrp TYPE ekko-ekgrp,
         bsart TYPE ekko-bsart,
         frgke TYPE ekko-frgke,
         frggr TYPE ekko-frggr,
         frgsx TYPE ekko-frgsx,
         waers TYPE ekko-waers,
         loekz TYPE ekko-loekz,
       END OF ty_ekko.

TYPES: BEGIN OF ty_relcode,
         frgco TYPE t16fv-frgco,
       END OF ty_relcode.

TYPES: BEGIN OF ty_result,
         ebeln    TYPE ekko-ebeln,
         netwr    TYPE ekpo-netwr,
         usdval   TYPE p DECIMALS 2,
         rel_code TYPE bapimmpara-po_rel_cod,
         status   TYPE char1,
         message  TYPE bapi_msg,
       END OF ty_result.

DATA: lt_ekko    TYPE STANDARD TABLE OF ty_ekko,
      ls_ekko    TYPE ty_ekko,
      lt_relcode TYPE STANDARD TABLE OF ty_relcode,
      ls_relcode TYPE ty_relcode,
      lt_result  TYPE STANDARD TABLE OF ty_result,
      ls_result  TYPE ty_result.

DATA: lv_netwr          TYPE ekpo-netwr,
      lv_usdval         TYPE p DECIMALS 2,
      lv_kurs           TYPE rkb1k-exchr,
      lv_relstatus      TYPE bapimmpara-rel_status,
      lv_relind         TYPE bapimmpara-po_rel_ind,
      lv_retcode        TYPE sy-subrc,
      lv_released       TYPE char1,
      lv_lines          TYPE i,
      lv_threshold_val  TYPE zmap_type-value,
      lv_threshold_usd  TYPE p DECIMALS 2.

DATA: lt_return TYPE STANDARD TABLE OF bapireturn,
      ls_return TYPE bapireturn.

CONSTANTS: gc_prog TYPE zmap_type-prog VALUE 'ZPO_AUTO_RELEASE'.

*----------------------------------------------------------------*
* Selection Screen
*----------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
SELECT-OPTIONS: s_bukrs FOR ekko-bukrs,
                s_ekorg FOR ekko-ekorg,
                s_ekgrp FOR ekko-ekgrp,
                s_bsart FOR ekko-bsart.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE text-002.
PARAMETERS: p_test TYPE c AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b2.

*----------------------------------------------------------------*
START-OF-SELECTION.

  AUTHORITY-CHECK OBJECT 'M_EINK_FRG'
           ID 'FRGGR' DUMMY
           ID 'FRGSX' DUMMY
           ID 'ACTVT' FIELD '02'.

  IF sy-subrc NE 0.
    WRITE: / 'User tidak memiliki otorisasi release PO (M_EINK_FRG). Program dihentikan.'.
    EXIT.
  ENDIF.

*----------------------------------------------------------------*
* 1. Baca threshold auto-release (SATU baris, TEXT1='X') dari ZMAP_TYPE
*----------------------------------------------------------------*
  CLEAR: lv_threshold_val, lv_threshold_usd.
  SELECT SINGLE value INTO lv_threshold_val
    FROM zmap_type
    WHERE prog = gc_prog
      AND type = 'THRESHOLD'
      AND text1 = 'X'
      AND deletion = space.

  IF sy-subrc NE 0.
    WRITE: / 'Mapping THRESHOLD auto-release (TEXT1=X) belum ada di ZMAP_TYPE. Program dihentikan.'.
    EXIT.
  ENDIF.

  lv_threshold_usd = lv_threshold_val.

*----------------------------------------------------------------*
* 2. Ambil PO yang masih blocked
*----------------------------------------------------------------*
  REFRESH lt_ekko.
  SELECT ebeln bukrs ekorg ekgrp bsart frgke frggr frgsx waers loekz
    INTO TABLE lt_ekko
    FROM ekko
    WHERE bukrs IN s_bukrs
      AND ekorg IN s_ekorg
      AND ekgrp IN s_ekgrp
      AND bsart IN s_bsart
      AND bstyp EQ 'F'
      AND frgke NE space
      AND loekz EQ space.

  IF lt_ekko IS INITIAL.
    WRITE: / 'Tidak ada PO yang perlu diproses sesuai kriteria seleksi.'.
    EXIT.
  ENDIF.

  SORT lt_ekko BY ebeln.

*----------------------------------------------------------------*
* 3. Proses tiap PO
*----------------------------------------------------------------*
  LOOP AT lt_ekko INTO ls_ekko.

    CLEAR: ls_result, lv_netwr, lv_usdval, lv_released.
    ls_result-ebeln = ls_ekko-ebeln.

*   --- 3a. Total nilai PO ---
    SELECT SUM( netwr ) INTO lv_netwr
      FROM ekpo
      WHERE ebeln = ls_ekko-ebeln
        AND loekz EQ space.

    ls_result-netwr = lv_netwr.

*   --- 3b. Konversi ke USD ---
    IF ls_ekko-waers EQ 'USD'.
      lv_usdval = lv_netwr.
    ELSE.
      CLEAR lv_kurs.
      CALL FUNCTION 'RKC_SINGLE_EXCHANGE_RATE_GET'
        EXPORTING
          datum         = sy-datum
          kurst         = 'M'
          ncurr         = 'USD'
          vcurr         = ls_ekko-waers
        IMPORTING
          exchr         = lv_kurs
        EXCEPTIONS
          no_rate_found = 1
          OTHERS        = 2.

      IF sy-subrc NE 0.
        ls_result-status  = 'E'.
        ls_result-message = 'Kurs (TCURR, KURST=M) tidak ditemukan untuk konversi ke USD -- skip'.
        APPEND ls_result TO lt_result.
        CONTINUE.
      ENDIF.

      lv_usdval = lv_netwr * lv_kurs.
    ENDIF.

    ls_result-usdval = lv_usdval.

*   --- 3c. Cek scope Sprint 1: HANYA proses kalau nilai < threshold auto ---
    IF lv_usdval > lv_threshold_usd.
      ls_result-status  = 'M'.
      ls_result-message = 'Di luar scope Sprint 1 (nilai >= threshold auto-release). Approval routing & notifikasi ditangani di Sprint 2.'.
      APPEND ls_result TO lt_result.
      CONTINUE.
    ENDIF.

*   --- 3d. Auto-release lewat BAPI_PO_RELEASE ---
    REFRESH lt_relcode.
    SELECT frgco
      INTO TABLE lt_relcode
      FROM t16fv
      WHERE frggr = ls_ekko-frggr
        AND frgsx = ls_ekko-frgsx.

    IF lt_relcode IS INITIAL.
      ls_result-status  = 'W'.
      ls_result-message = 'Dalam scope Sprint 1 tapi kombinasi FRGGR/FRGSX tidak ditemukan di T16FV'.
      APPEND ls_result TO lt_result.
      CONTINUE.
    ENDIF.

    LOOP AT lt_relcode INTO ls_relcode.

      CLEAR: lv_relstatus, lv_relind.
      REFRESH lt_return.

      CALL FUNCTION 'BAPI_PO_RELEASE'
        EXPORTING
          purchaseorder     = ls_ekko-ebeln
          po_rel_code       = ls_relcode-frgco
          use_exceptions    = 'X'
        IMPORTING
          rel_status_new    = lv_relstatus
          rel_indicator_new = lv_relind
        TABLES
          return            = lt_return
        EXCEPTIONS
          authority_check_fail    = 1
          document_not_found      = 2
          enqueue_fail            = 3
          prerequisite_fail       = 4
          release_already_posted  = 5
          responsibility_fail     = 6
          OTHERS                  = 7.

      lv_retcode = sy-subrc.   " simpan SEGERA

      IF lv_retcode EQ 0.
        ls_result-rel_code = ls_relcode-frgco.

        IF p_test EQ space.
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
            EXPORTING
              wait = 'X'.
          ls_result-status  = 'S'.
          ls_result-message = 'PO berhasil di-release otomatis (Sprint 1)'.
        ELSE.
          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
          ls_result-status  = 'S'.
          ls_result-message = 'Simulasi OK (Test Mode) -- tidak di-commit'.
        ENDIF.

        lv_released = 'X'.
        EXIT.

      ELSE.
        CLEAR ls_return.
        READ TABLE lt_return INTO ls_return INDEX 1.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

        IF lv_retcode EQ 4 OR lv_retcode EQ 6.
          CONTINUE.
        ELSE.
          ls_result-status = 'E'.
          IF ls_return-message IS NOT INITIAL.
            ls_result-message = ls_return-message.
          ELSE.
            ls_result-message = 'BAPI_PO_RELEASE gagal, cek exception'.
          ENDIF.
          EXIT.
        ENDIF.
      ENDIF.

    ENDLOOP.

    IF lv_released IS INITIAL AND ls_result-status IS INITIAL.
      ls_result-status  = 'W'.
      ls_result-message = 'Tidak ada release code yang applicable saat ini'.
    ENDIF.

    APPEND ls_result TO lt_result.

  ENDLOOP.

*----------------------------------------------------------------*
* 4. Output hasil
*----------------------------------------------------------------*
  DESCRIBE TABLE lt_result LINES lv_lines.

  WRITE: / 'Hasil PO Auto-Release Sprint 1 (v6)', 50 'Mode:', p_test AS CHECKBOX.
  WRITE: / 'Threshold auto-release: USD', lv_threshold_usd.
  WRITE: / 'Total PO diproses:', lv_lines.
  SKIP.
  WRITE: / sy-uline.
  WRITE: / 'PO Number', 15 'USD Val', 28 'Rel.Code', 38 'Status', 42 'Keterangan'.
  WRITE: / sy-uline.

  LOOP AT lt_result INTO ls_result.
    WRITE: / ls_result-ebeln,
             15 ls_result-usdval,
             28 ls_result-rel_code,
             38 ls_result-status,
             42 ls_result-message.
  ENDLOOP.

*----------------------------------------------------------------*
* SPRINT 2 (belum dibangun di sini -- sengaja dipisah):
* - Identifikasi approver (Lisa/Melisa/Fenny/GM Purchasing) utk PO
*   >= threshold, berdasarkan mapping ZMAP_TYPE TYPE='APPROVER'.
* - Email notifikasi ke approver (SO_NEW_DOCUMENT_ATT_SEND_API1).
* - Exception flagging (vendor/material baru, harga naik >10%,
*   no price history/stale >24 bulan, service/capex PO).
*----------------------------------------------------------------*

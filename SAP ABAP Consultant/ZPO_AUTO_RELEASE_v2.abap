*&---------------------------------------------------------------*
*& Report  ZPO_AUTO_RELEASE  (v2 - berbasis ZMAP_TYPE)
*&---------------------------------------------------------------*
*& Tujuan : Automation release PO dengan tier threshold (USD) dan
*&          approver berbasis Purchasing Group (EKGRP), keduanya
*&          dibaca dari tabel mapping ZMAP_TYPE (PROG='ZPO_AUTO_RELEASE'),
*&          bukan hardcode. Release tetap lewat BAPI_PO_RELEASE
*&          standar, bukan direct update EKKO.
*&
*& Release ABAP : 7.31 (tanpa inline DATA(), NEW, VALUE, string
*&                template, atau FOR ALL ENTRIES tanpa guard).
*&
*& Sumber requirement : email Douglas Tjokrosetio -> tim IT,
*&                       8 Juli 2026, thread "Purchasing Restructure",
*&                       berdasarkan kesepakatan final Chin Siong Lai
*&                       (GM Purchasing) 6 Juli 2026.
*&
*& PRASYARAT SEBELUM DIPAKAI:
*& 1. Baris mapping di ZMAP_TYPE (TYPE='THRESHOLD' dan TYPE='APPROVER',
*&    PROG='ZPO_AUTO_RELEASE') HARUS sudah diupload -- lihat file
*&    ZMAP_TYPE_upload_ZPO_AUTO_RELEASE.xlsx.
*& 2. Release code yang dipakai di mapping (LS/ML/FN/GM, atau kode
*&    lain sesuai keputusan Customizing) HARUS sudah terdaftar valid
*&    di release strategy (T16FC/T16FS/T16FV via SPRO). Kalau belum,
*&    BAPI_PO_RELEASE akan gagal dengan PREREQUISITE_FAIL untuk semua PO.
*& 3. Notifikasi email dan exception-flag bisnis (vendor baru, harga
*&    naik >10%, dst.) BELUM diimplementasikan di versi ini -- sesuai
*&    keputusan fokus ke automasi dulu. Field TEXT3 (email) di mapping
*&    APPROVER sudah disiapkan untuk fase berikutnya.
*&
*& CATATAN SoD: user teknis yang menjalankan program ini WAJIB
*& otorisasi M_EINK_FRG yang sudah dibatasi sesuai matriks approval
*& resmi -- jangan pernah pakai user dengan SAP_ALL.
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

TYPES: BEGIN OF ty_threshold,
         opt    TYPE zmap_type-opt,
         value  TYPE zmap_type-value,
         text1  TYPE zmap_type-text1,
         text2  TYPE zmap_type-text2,
         usdval TYPE p DECIMALS 2,
       END OF ty_threshold.

TYPES: BEGIN OF ty_approver,
         opt   TYPE zmap_type-opt,
         value TYPE zmap_type-value,
         text1 TYPE zmap_type-text1,
         text2 TYPE zmap_type-text2,
       END OF ty_approver.

TYPES: BEGIN OF ty_relcode,
         frgco TYPE t16fv-frgco,
       END OF ty_relcode.

TYPES: BEGIN OF ty_result,
         ebeln    TYPE ekko-ebeln,
         netwr    TYPE ekpo-netwr,
         usdval   TYPE p DECIMALS 2,
         tier     TYPE zmap_type-opt,
         rel_code TYPE bapimmpara-po_rel_cod,
         status   TYPE char1,
         message  TYPE bapi_msg,
       END OF ty_result.

DATA: lt_ekko      TYPE STANDARD TABLE OF ty_ekko,
      ls_ekko      TYPE ty_ekko,
      lt_threshold TYPE STANDARD TABLE OF ty_threshold,
      ls_threshold TYPE ty_threshold,
      lt_approver  TYPE STANDARD TABLE OF ty_approver,
      ls_approver  TYPE ty_approver,
      lt_relcode   TYPE STANDARD TABLE OF ty_relcode,
      ls_relcode   TYPE ty_relcode,
      lt_result    TYPE STANDARD TABLE OF ty_result,
      ls_result    TYPE ty_result.

DATA: lv_netwr     TYPE ekpo-netwr,
      lv_usdval    TYPE p DECIMALS 2,
      lv_kurs      TYPE rkb1k-exchr,
      lv_relstatus TYPE bapimmpara-rel_status,
      lv_relind    TYPE bapimmpara-po_rel_ind,
      lv_retcode   TYPE sy-subrc,
      lv_released  TYPE char1,
      lv_lines     TYPE i,
      lv_found     TYPE char1.

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
* 1. Load mapping THRESHOLD dari ZMAP_TYPE
*----------------------------------------------------------------*
  REFRESH lt_threshold.
  SELECT opt value text1 text2
    INTO TABLE lt_threshold
    FROM zmap_type
    WHERE prog = gc_prog
      AND type = 'THRESHOLD'
      AND deletion = space.

  IF lt_threshold IS INITIAL.
    WRITE: / 'Mapping THRESHOLD belum ada di ZMAP_TYPE untuk PROG =', gc_prog, '. Program dihentikan.'.
    EXIT.
  ENDIF.

  LOOP AT lt_threshold INTO ls_threshold.
    ls_threshold-usdval = ls_threshold-value.
    MODIFY lt_threshold FROM ls_threshold.
  ENDLOOP.

  SORT lt_threshold BY usdval ASCENDING.

*----------------------------------------------------------------*
* 2. Load mapping APPROVER dari ZMAP_TYPE
*----------------------------------------------------------------*
  REFRESH lt_approver.
  SELECT opt value text1 text2
    INTO TABLE lt_approver
    FROM zmap_type
    WHERE prog = gc_prog
      AND type = 'APPROVER'
      AND deletion = space.

  IF lt_approver IS INITIAL.
    WRITE: / 'Mapping APPROVER belum ada di ZMAP_TYPE untuk PROG =', gc_prog, '. Program dihentikan.'.
    EXIT.
  ENDIF.

*----------------------------------------------------------------*
* 3. Ambil PO yang masih blocked
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
    WRITE: / 'Tidak ada PO yang perlu di-release sesuai kriteria seleksi.'.
    EXIT.
  ENDIF.

  SORT lt_ekko BY ebeln.

*----------------------------------------------------------------*
* 4. Proses tiap PO
*----------------------------------------------------------------*
  LOOP AT lt_ekko INTO ls_ekko.

    CLEAR: ls_result, lv_netwr, lv_usdval, lv_released.
    ls_result-ebeln = ls_ekko-ebeln.

*   --- 4a. Total nilai PO ---
    SELECT SUM( netwr ) INTO lv_netwr
      FROM ekpo
      WHERE ebeln = ls_ekko-ebeln
        AND loekz EQ space.

    ls_result-netwr = lv_netwr.

*   --- 4b. Konversi ke USD (pola sama seperti ZMMF_PO_IMPORT_F01) ---
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
        ls_result-message = 'Kurs (TCURR) tidak ditemukan untuk konversi ke USD -- skip'.
        APPEND ls_result TO lt_result.
        CONTINUE.
      ENDIF.

      lv_usdval = lv_netwr * lv_kurs.
    ENDIF.

    ls_result-usdval = lv_usdval.

*   --- 4c. Tentukan tier dari mapping THRESHOLD (ascending) ---
    CLEAR lv_found.
    LOOP AT lt_threshold INTO ls_threshold.
      IF lv_usdval <= ls_threshold-usdval.
        lv_found = 'X'.
        EXIT.
      ENDIF.
    ENDLOOP.

    IF lv_found IS INITIAL.
      ls_result-status  = 'E'.
      ls_result-message = 'Nilai PO melebihi tier tertinggi di mapping THRESHOLD -- wajib manual'.
      APPEND ls_result TO lt_result.
      CONTINUE.
    ENDIF.

    ls_result-tier = ls_threshold-opt.

*   --- 4d. Tentukan release code sesuai tier ---
    REFRESH lt_relcode.

    IF ls_threshold-text1 EQ 'X'.
*     Tier auto (mis. T0) -> coba semua release code yang pending utk PO ini
      SELECT frgco
        INTO TABLE lt_relcode
        FROM t16fv
        WHERE frggr = ls_ekko-frggr
          AND frgsx = ls_ekko-frgsx.

      IF lt_relcode IS INITIAL.
        ls_result-status  = 'W'.
        ls_result-message = 'Tier auto tapi kombinasi FRGGR/FRGSX tidak ditemukan di T16FV'.
        APPEND ls_result TO lt_result.
        CONTINUE.
      ENDIF.

    ELSEIF ls_threshold-text2 IS NOT INITIAL.
*     Tier dengan release code tetap (mis. GM Purchasing)
      ls_relcode-frgco = ls_threshold-text2.
      APPEND ls_relcode TO lt_relcode.

    ELSE.
*     Tier butuh lookup approver by EKGRP, fallback ke baris DEFAULT
      READ TABLE lt_approver INTO ls_approver WITH KEY opt = ls_ekko-ekgrp.
      IF sy-subrc NE 0.
        READ TABLE lt_approver INTO ls_approver WITH KEY opt = 'DEFAULT'.
      ENDIF.

      IF sy-subrc NE 0.
        ls_result-status  = 'E'.
        ls_result-message = 'Tidak ada mapping APPROVER utk EKGRP ini, baris DEFAULT juga tidak ada'.
        APPEND ls_result TO lt_result.
        CONTINUE.
      ENDIF.

      ls_relcode-frgco = ls_approver-value.
      APPEND ls_relcode TO lt_relcode.
    ENDIF.

*   --- 4e. Eksekusi release ---
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

      lv_retcode = sy-subrc.   " simpan SEGERA, sebelum statement lain menimpa sy-subrc

      IF lv_retcode EQ 0.
        ls_result-rel_code = ls_relcode-frgco.

        IF p_test EQ space.
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
            EXPORTING
              wait = 'X'.
          ls_result-status  = 'S'.
          ls_result-message = 'PO berhasil di-release'.
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
*         PREREQUISITE_FAIL / RESPONSIBILITY_FAIL -> lanjut coba kandidat berikutnya
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
      ls_result-message = 'Tidak ada release code yang applicable saat ini (cek Customizing release strategy)'.
    ENDIF.

    APPEND ls_result TO lt_result.

  ENDLOOP.

*----------------------------------------------------------------*
* 5. Output hasil
*----------------------------------------------------------------*
  DESCRIBE TABLE lt_result LINES lv_lines.

  WRITE: / 'Hasil PO Auto-Release (ZMAP_TYPE-based)', 45 'Mode:', p_test AS CHECKBOX.
  WRITE: / 'Total PO diproses:', lv_lines.
  SKIP.
  WRITE: / sy-uline.
  WRITE: / 'PO Number', 15 'USD Val', 30 'Tier', 36 'Rel.Code', 46 'Status', 56 'Keterangan'.
  WRITE: / sy-uline.

  LOOP AT lt_result INTO ls_result.
    WRITE: / ls_result-ebeln,
             15 ls_result-usdval,
             30 ls_result-tier,
             36 ls_result-rel_code,
             46 ls_result-status,
             56 ls_result-message.
  ENDLOOP.

*----------------------------------------------------------------*
* TITIK ENHANCEMENT (belum diimplementasikan, fase berikutnya):
* - Exception flag bisnis (vendor baru, harga naik >10%, no price
*   history, Service/Capex PO) -- akan override tier apapun jadi manual.
* - Notifikasi email ke approver (pakai TEXT3 di mapping APPROVER
*   yang sudah disiapkan sekarang, isi dulu emailnya di ZMAP_TYPE).
* - Audit log permanen (SLG1 / tabel Z) untuk setiap release otomatis.
*----------------------------------------------------------------*

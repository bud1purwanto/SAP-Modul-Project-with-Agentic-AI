*&---------------------------------------------------------------*
*& Report  ZPO_AUTO_RELEASE  (v4)
*&---------------------------------------------------------------*
*& Tujuan : Auto-release HANYA untuk PO < USD 500 (Tier T0, tanpa
*&          approver) lewat BAPI_PO_RELEASE standar. Untuk PO >=
*&          USD 500 (Tier T1/T2), program TIDAK memanggil release
*&          apa pun -- cuma mengidentifikasi approver (nama+email)
*&          dari mapping ZMAP_TYPE berbasis Purchasing Group (EKGRP)
*&          dan melaporkan status "perlu approval manual". Field
*&          email disiapkan untuk fase notifikasi berikutnya
*&          (belum dikirim otomatis di versi ini).
*&
*& Release ABAP : 7.31 (tanpa inline DATA(), NEW, VALUE, string
*&                template, atau FOR ALL ENTRIES tanpa guard).
*&
*& PERUBAHAN dari v3:
*& - Tabel ZMAP_TYPE TYPE='APPROVER' sekarang berisi CAMPURAN baris
*&   lama (VALUE=kode singkat spt LS/ML/FN, TEXT1=nama, dipakai utk
*&   keperluan mapping lain di luar program ini) dan baris baru
*&   (VALUE=nama lengkap, TEXT1=alamat email). Supaya tidak ambigu,
*&   SELECT sekarang HANYA mengambil baris yang TEXT1-nya berformat
*&   email (mengandung '@') via 'TEXT1 CP '*@*''. Baris lama otomatis
*&   diabaikan tanpa perlu dihapus dari tabel.
*&
*& CATATAN: konversi ke USD masih pakai RKC_SINGLE_EXCHANGE_RATE_GET
*& (KURST='M'). Di sandbox TRS saat ini rate IDR->USD KURST='M' TIDAK
*& tersedia di TCURR (data sandbox belum update) -- PO ber-WAERS IDR
*& akan otomatis di-skip dengan status 'E' sampai data TCURR dilengkapi.
*& Ini keterbatasan data, bukan bug program.
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
         usdval TYPE p DECIMALS 2,
       END OF ty_threshold.

TYPES: BEGIN OF ty_approver,
         opt   TYPE zmap_type-opt,     " EKGRP atau 'DEFAULT'
         value TYPE zmap_type-value,   " Nama approver
         text1 TYPE zmap_type-text1,   " Email approver
       END OF ty_approver.

TYPES: BEGIN OF ty_relcode,
         frgco TYPE t16fv-frgco,
       END OF ty_relcode.

TYPES: BEGIN OF ty_result,
         ebeln     TYPE ekko-ebeln,
         netwr     TYPE ekpo-netwr,
         usdval    TYPE p DECIMALS 2,
         tier      TYPE zmap_type-opt,
         rel_code  TYPE bapimmpara-po_rel_cod,
         appr_name TYPE zmap_type-value,
         appr_mail TYPE zmap_type-text1,
         status    TYPE char1,
         message   TYPE bapi_msg,
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
  SELECT opt value text1
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
* 2. Load mapping APPROVER dari ZMAP_TYPE (HANYA baris ber-email)
*    Baris lama (VALUE=kode singkat, TEXT1=nama tanpa '@') dipakai
*    utk keperluan mapping lain di luar program ini -- diabaikan
*    di sini dgn filter TEXT1 CP '*@*'.
*----------------------------------------------------------------*
  REFRESH lt_approver.
  SELECT opt value text1
    INTO TABLE lt_approver
    FROM zmap_type
    WHERE prog = gc_prog
      AND type = 'APPROVER'
      AND deletion = space
      AND text1 CP '*@*'.

  IF lt_approver IS INITIAL.
    WRITE: / 'Mapping APPROVER (dengan email) belum ada di ZMAP_TYPE untuk PROG =', gc_prog, '. Program dihentikan.'.
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
    WRITE: / 'Tidak ada PO yang perlu diproses sesuai kriteria seleksi.'.
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

*   --- 4b. Konversi ke USD ---
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

*   --- 4d. Tier T0 (auto, TEXT1='X') -> release lewat BAPI. Tier lain -> manual ---
    IF ls_threshold-text1 EQ 'X'.

      REFRESH lt_relcode.
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
            ls_result-message = 'PO berhasil di-release otomatis (Tier T0)'.
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

    ELSE.
*     --- Tier T1/T2: TIDAK release, cuma identifikasi approver utk notifikasi nanti ---
      READ TABLE lt_approver INTO ls_approver WITH KEY opt = ls_ekko-ekgrp.
      IF sy-subrc NE 0.
        READ TABLE lt_approver INTO ls_approver WITH KEY opt = 'DEFAULT'.
      ENDIF.

      IF sy-subrc EQ 0.
        ls_result-appr_name = ls_approver-value.
        ls_result-appr_mail = ls_approver-text1.
        ls_result-status    = 'M'.
        ls_result-message   = 'Perlu approval manual di SAP (belum kirim email otomatis)'.
      ELSE.
        ls_result-status  = 'E'.
        ls_result-message = 'Tidak ada mapping APPROVER (ber-email) utk EKGRP ini, baris DEFAULT juga tidak ada'.
      ENDIF.

    ENDIF.

    APPEND ls_result TO lt_result.

  ENDLOOP.

*----------------------------------------------------------------*
* 5. Output hasil
*----------------------------------------------------------------*
  DESCRIBE TABLE lt_result LINES lv_lines.

  WRITE: / 'Hasil PO Auto-Release (ZMAP_TYPE-based, v4)', 50 'Mode:', p_test AS CHECKBOX.
  WRITE: / 'Total PO diproses:', lv_lines.
  SKIP.
  WRITE: / sy-uline.
  WRITE: / 'PO Number', 15 'USD Val', 28 'Tier', 34 'Rel.Code', 44 'Approver', 58 'Email', 80 'Status', 84 'Keterangan'.
  WRITE: / sy-uline.

  LOOP AT lt_result INTO ls_result.
    WRITE: / ls_result-ebeln,
             15 ls_result-usdval,
             28 ls_result-tier,
             34 ls_result-rel_code,
             44 ls_result-appr_name,
             58 ls_result-appr_mail,
             80 ls_result-status,
             84 ls_result-message.
  ENDLOOP.

*----------------------------------------------------------------*
* TITIK ENHANCEMENT (belum diimplementasikan, fase berikutnya):
* - Kirim email notifikasi otomatis ke ls_result-appr_mail untuk
*   setiap baris status = 'M' (pakai FM SO_NEW_DOCUMENT_ATT_SEND_API1
*   atau sejenis).
* - Exception flag bisnis (vendor baru, harga naik >10%, dst).
* - Audit log permanen (SLG1 / tabel Z) untuk setiap release otomatis.
*----------------------------------------------------------------*

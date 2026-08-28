*&---------------------------------------------------------------*
*& Report  ZPO_AUTO_RELEASE
*&---------------------------------------------------------------*
*& Tujuan : Automation release Purchase Order (PO) yang masih
*&          "blocked" pada release strategy, menggunakan BAPI
*&          standar BAPI_PO_RELEASE (bukan direct update EKKO).
*&
*& Release ABAP  : 7.31 (tidak menggunakan inline DATA(), NEW,
*&                 VALUE, string template, atau FOR ALL ENTRIES
*&                 tanpa guard).
*&
*& TCODE terkait  : SE38/SE80 (buat/edit program),
*&                   SE37 (cek BAPI_PO_RELEASE),
*&                   SM36/SM37 (schedule background job),
*&                   ME29N (cross-check release manual),
*&                   SLG1 (opsional, application log audit)
*&
*& CATATAN PENTING - BACA SEBELUM PAKAI DI PRODUCTION:
*& Program ini MENG-OTOMATISASI keputusan approval PO. Release
*& strategy dibuat justru untuk segregation-of-duty (SoD) --
*& approval oleh manusia berwenang. Menjalankan release otomatis
*& tanpa batasan yang ketat berisiko melanggar kontrol internal /
*& audit. Karena itu program ini WAJIB dijalankan dengan:
*&   1. P_TEST = 'X' (default) saat pertama kali dicoba -> hanya
*&      simulasi, BAPI_TRANSACTION_ROLLBACK selalu dipanggil.
*&   2. Batasan nilai PO (P_WMAX) dan scope (BUKRS/EKORG/EKGRP/
*&      BSART) yang disepakati dengan tim Finance/Procurement,
*&      bukan release "semua PO blocked" secara membabi buta.
*&   3. User teknis (RFC/background job) yang menjalankan program
*&      ini harus punya otorisasi object M_EINK_FRG yang SUDAH
*&      dibatasi sesuai matriks approval resmi -- BAPI_PO_RELEASE
*&      akan menolak (exception AUTHORITY_CHECK_FAIL) jika tidak
*&      berwenang, tapi desain otorisasi tetap harus benar dari
*&      awal (jangan beri SAP_ALL ke user job ini).
*&   4. Idealnya setiap release otomatis dicatat ke Application
*&      Log (SLG1) atau tabel Z custom untuk audit trail -- lihat
*&      catatan di akhir source untuk titik enhancement-nya.
*&---------------------------------------------------------------*

REPORT zpo_auto_release.

TABLES: ekko, ekpo.

*----------------------------------------------------------------*
* Types & Data (deklarasi eksplisit -- tidak pakai inline DATA()) *
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
         loekz TYPE ekko-loekz,
       END OF ty_ekko.

TYPES: BEGIN OF ty_relcode,
         frgco TYPE t16fv-frgco,
       END OF ty_relcode.

TYPES: BEGIN OF ty_result,
         ebeln    TYPE ekko-ebeln,
         netwr    TYPE ekpo-netwr,
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

DATA: lv_netwr     TYPE ekpo-netwr,
      lv_relstatus TYPE bapimmpara-rel_status,
      lv_relind    TYPE bapimmpara-po_rel_ind,
      lv_retcode   TYPE sy-subrc,
      lv_released  TYPE char1,
      lv_lines     TYPE i.

DATA: lt_return TYPE STANDARD TABLE OF bapireturn,
      ls_return TYPE bapireturn.

*----------------------------------------------------------------*
* Selection Screen                                                *
*----------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
SELECT-OPTIONS: s_bukrs FOR ekko-bukrs,
                s_ekorg FOR ekko-ekorg,
                s_ekgrp FOR ekko-ekgrp,
                s_bsart FOR ekko-bsart.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE text-002.
PARAMETERS: p_wmax TYPE ekpo-netwr DEFAULT '10000.00',
            p_test TYPE c AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b2.

*----------------------------------------------------------------*
* Authority-Check awal (defense in depth -- BAPI juga cek sendiri)*
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
* Ambil daftar PO yang masih blocked (FRGKE <> space, LOEKZ space)*
*----------------------------------------------------------------*
  REFRESH lt_ekko.

  SELECT ebeln bukrs ekorg ekgrp bsart frgke frggr frgsx loekz
    INTO TABLE lt_ekko
    FROM ekko
    WHERE bukrs IN s_bukrs
      AND ekorg IN s_ekorg
      AND ekgrp IN s_ekgrp
      AND bsart IN s_bsart
      AND bstyp EQ 'F'          " hanya Purchase Order, bukan kontrak/RFQ
      AND frgke NE space        " ada release strategy aktif
      AND loekz EQ space.       " dokumen belum di-flag delete

  IF lt_ekko IS INITIAL.
    WRITE: / 'Tidak ada PO yang perlu di-release sesuai kriteria seleksi.'.
    EXIT.
  ENDIF.

  SORT lt_ekko BY ebeln.

*----------------------------------------------------------------*
* Proses tiap PO                                                  *
*----------------------------------------------------------------*
  LOOP AT lt_ekko INTO ls_ekko.

    CLEAR: ls_result, lv_netwr, lv_released.
    ls_result-ebeln = ls_ekko-ebeln.

*   --- Validasi nilai total PO terhadap batas auto-release ---
    SELECT SUM( netwr ) INTO lv_netwr
      FROM ekpo
      WHERE ebeln = ls_ekko-ebeln
        AND loekz EQ space.

    ls_result-netwr = lv_netwr.

    IF lv_netwr > p_wmax.
      ls_result-status  = 'E'.
      ls_result-message = 'Nilai PO melebihi batas auto-release (P_WMAX), wajib release manual'.
      APPEND ls_result TO lt_result.
      CONTINUE.
    ENDIF.

*   --- Ambil kandidat release code untuk FRGGR/FRGSX PO ini ---
    REFRESH lt_relcode.
    SELECT frgco
      INTO TABLE lt_relcode
      FROM t16fv
      WHERE frggr = ls_ekko-frggr
        AND frgsx = ls_ekko-frgsx.

    IF lt_relcode IS INITIAL.
      ls_result-status  = 'W'.
      ls_result-message = 'Kombinasi FRGGR/FRGSX tidak ditemukan di T16FV -- kemungkinan sudah full release'.
      APPEND ls_result TO lt_result.
      CONTINUE.
    ENDIF.

*   --- Coba release memakai tiap release code yang relevan.     ---
*   --- BAPI akan menolak (PREREQUISITE_FAIL/RESPONSIBILITY_FAIL) --
*   --- kalau code tersebut bukan giliran/step yang berlaku.      ---
    LOOP AT lt_relcode INTO ls_relcode.

      CLEAR: lv_relstatus, lv_relind, lv_retcode.
      REFRESH lt_return.

      CALL FUNCTION 'BAPI_PO_RELEASE'
        EXPORTING
          purchaseorder     = ls_ekko-ebeln
          po_rel_code       = ls_relcode-frgco
          use_exceptions    = 'X'
        IMPORTING
          rel_status_new    = lv_relstatus
          rel_indicator_new = lv_relind
          ret_code          = lv_retcode
        TABLES
          return            = lt_return
        EXCEPTIONS
          authority_check_fail   = 1
          document_not_found     = 2
          enqueue_fail            = 3
          prerequisite_fail       = 4
          release_already_posted = 5
          responsibility_fail     = 6
          OTHERS                  = 7.

      IF sy-subrc EQ 0.
*       --- Berhasil untuk release code ini ---
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
          ls_result-message = 'Simulasi OK (Test Mode) -- tidak di-commit, jalankan ulang dgn P_TEST kosong utk eksekusi nyata'.
        ENDIF.

        lv_released = 'X'.
        EXIT.  " keluar dari LOOP relcode, lanjut ke PO berikutnya

      ELSE.
*       --- Gagal untuk kode ini: cek pesan, lanjut coba kode lain ---
        CLEAR ls_return.
        READ TABLE lt_return INTO ls_return INDEX 1.

        IF sy-subrc EQ 4 OR sy-subrc EQ 6.
*         PREREQUISITE_FAIL / RESPONSIBILITY_FAIL -> memang bukan
*         giliran code ini, lanjut ke kandidat berikutnya tanpa error.
          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
          CONTINUE.
        ELSE.
*         Error lain (authority, enqueue, document not found, dsb)
*         -> catat dan hentikan percobaan untuk PO ini.
          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
          ls_result-status = 'E'.
          IF ls_return-message IS NOT INITIAL.
            ls_result-message = ls_return-message.
          ELSE.
            ls_result-message = 'BAPI_PO_RELEASE gagal, cek SY-SUBRC / exception'.
          ENDIF.
          EXIT.
        ENDIF.
      ENDIF.

    ENDLOOP.

    IF lv_released IS INITIAL AND ls_result-status IS INITIAL.
      ls_result-status  = 'W'.
      ls_result-message = 'Tidak ada release code yang applicable saat ini (bukan giliran approval)'.
    ENDIF.

    APPEND ls_result TO lt_result.

  ENDLOOP.

*----------------------------------------------------------------*
* Output hasil (classic list -- bisa diganti REUSE_ALV_GRID_DISPLAY)
*----------------------------------------------------------------*
  DESCRIBE TABLE lt_result LINES lv_lines.

  WRITE: / 'Hasil PO Auto-Release', 40 'Mode:', p_test AS CHECKBOX.
  WRITE: / 'Total PO diproses:', lv_lines.
  SKIP.
  WRITE: / sy-uline.
  WRITE: / 'PO Number', 15 'Nilai (NETWR)', 35 'Rel.Code', 45 'Status', 55 'Keterangan'.
  WRITE: / sy-uline.

  LOOP AT lt_result INTO ls_result.
    WRITE: / ls_result-ebeln,
             15 ls_result-netwr,
             35 ls_result-rel_code,
             45 ls_result-status,
             55 ls_result-message.
  ENDLOOP.

*----------------------------------------------------------------*
* TITIK ENHANCEMENT (opsional, tidak diimplementasi di sini):     *
* - Tulis lt_result ke tabel Z custom (ZPO_AUTO_REL_LOG) atau     *
*   Application Log (fungsi BAL_LOG_CREATE / BAL_LOG_MSG_ADD /    *
*   BAL_DB_SAVE) untuk audit trail permanen (SLG1).               *
* - Kirim notifikasi email/IDoc ke PO creator (LIFNR/ERNAM) saat  *
*   PO gagal release atau melebihi threshold.                     *
* - Jadwalkan sebagai background job via SM36 dgn variant berisi  *
*   scope BUKRS/EKORG/EKGRP/BSART yang sudah disepakati bisnis.   *
*----------------------------------------------------------------*

*&---------------------------------------------------------------*
*& Class      : ZCL_IM_ME_PROCESS_PO_CUST
*& Method     : IF_EX_ME_PROCESS_PO_CUST~POST
*& BAdI       : ME_PROCESS_PO_CUST
*& Implementation Name : ZME_PROCESS_PO_CUS
*&
*& CATATAN PENTING SEBELUM ACTIVATE:
*& 1. Method ini dipanggil untuk SEMUA PO yang disimpan (ME21N/
*&    ME22N), bukan cuma yang mau di-auto-release. Filter scope
*&    di Langkah 2 (BSART/EKORG) WAJIB direview & disepakati
*&    dengan tim Procurement/Finance -- nilai 'PO07'/'TPOL' di
*&    bawah ini diambil dari data sample sandbox, BUKAN keputusan
*&    bisnis final.
*& 2. Batas nilai (lv_wmax = 10000.00) juga masih placeholder.
*& 3. TIDAK ada BAPI_TRANSACTION_COMMIT/ROLLBACK di sini secara
*&    sengaja -- method POST berjalan di dalam LUW SAVE ME21N/
*&    ME22N yang sama; commit/rollback ditangani proses SAVE
*&    standar SAP. JANGAN tambahkan COMMIT/ROLLBACK manual di sini.
*& 4. Kalau BAPI_PO_RELEASE gagal (user tidak authorized, bukan
*&    giliran approval, dll) -> method ini diam-diam RETURN/lanjut
*&    ke kode berikutnya, TIDAK raise error ke user. PO tetap
*&    tersimpan normal, hanya belum ter-release otomatis -- approval
*&    manual via ME29N tetap tersedia sebagai fallback yang aman.
*&---------------------------------------------------------------*

METHOD IF_EX_ME_PROCESS_PO_CUST~POST.

  TYPES: BEGIN OF ty_relcode,
           frgco TYPE t16fv-frgco,
         END OF ty_relcode.

  DATA: lv_ebeln     TYPE ekko-ebeln,
        ls_header    TYPE mepoheader,
        lv_netwr     TYPE ekpo-netwr,
        lv_wmax      TYPE ekpo-netwr VALUE '10000.00',
        lv_frggr     TYPE ekko-frggr,
        lv_frgsx     TYPE ekko-frgsx,
        lv_relstatus TYPE bapimmpara-rel_status,
        lv_relind    TYPE bapimmpara-po_rel_ind,
        lt_relcode   TYPE STANDARD TABLE OF ty_relcode,
        ls_relcode   TYPE ty_relcode,
        lt_return    TYPE STANDARD TABLE OF bapireturn,
        ls_return    TYPE bapireturn,
        lv_released  TYPE char1.

* --- 1. Ambil nomor & header PO ---
  lv_ebeln  = im_header->get_number( ).
  ls_header = im_header->get_data( ).

* --- 2. Filter scope: HANYA proses BSART/EKORG yang disepakati --- *
*     GANTI hardcode ini kalau scope bisnis berbeda / sering        *
*     berubah, idealnya lookup ke tabel Z config, bukan hardcode.   *
  IF ls_header-bsart NE 'PO07'.
    RETURN.
  ENDIF.

  IF ls_header-ekorg NE 'TPOL'.
    RETURN.
  ENDIF.

* --- 3. Cek nilai total PO terhadap batas auto-release --- *
  CLEAR lv_netwr.
  SELECT SUM( netwr ) INTO lv_netwr
    FROM ekpo
    WHERE ebeln = lv_ebeln
      AND loekz EQ space.

  IF lv_netwr > lv_wmax.
    RETURN.   " lewat batas, biarkan approval manual seperti biasa
  ENDIF.

* --- 4. Ambil release group/sub-group PO ini dari EKKO --- *
  CLEAR: lv_frggr, lv_frgsx.
  SELECT SINGLE frggr frgsx
    INTO (lv_frggr, lv_frgsx)
    FROM ekko
    WHERE ebeln = lv_ebeln.

  IF lv_frggr IS INITIAL.
    RETURN.   " belum ada release strategy -> tidak perlu release
  ENDIF.

* --- 5. Ambil kandidat release code & coba release --- *
  REFRESH lt_relcode.
  SELECT frgco
    INTO TABLE lt_relcode
    FROM t16fv
    WHERE frggr = lv_frggr
      AND frgsx = lv_frgsx.

  IF lt_relcode IS INITIAL.
    RETURN.
  ENDIF.

  CLEAR lv_released.

  LOOP AT lt_relcode INTO ls_relcode.

    CLEAR: lv_relstatus, lv_relind.
    REFRESH lt_return.

    CALL FUNCTION 'BAPI_PO_RELEASE'
      EXPORTING
        purchaseorder     = lv_ebeln
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

    IF sy-subrc EQ 0.
      lv_released = 'X'.
      EXIT.
    ENDIF.
*   Kalau gagal (prerequisite/responsibility/authority/dst) -> lanjut
*   cek kandidat kode berikutnya, tanpa raise error ke user.

  ENDLOOP.

ENDMETHOD.

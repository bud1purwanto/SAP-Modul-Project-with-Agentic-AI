*----------------------------------------------------------------------*
* Snapshot backup of ZPPR_GI_JR_CLOSING from TRS (sandbox-new)
* Date: 2026-09-09
*----------------------------------------------------------------------*
REPORT zppr_gi_jr_closing.

TYPE-POOLS: slis.

TABLES: mseg,
        mkpf,
        aufk,
        ausp.

CONSTANTS: gc_atnam_line TYPE cabn-atnam VALUE 'ZZPRODLINE',
           gc_atnam_roll TYPE cabn-atnam VALUE 'ZZNOMORROLL',
           gc_map_line   TYPE zmap_type-type VALUE 'PRODLINE',
           gc_map_mail   TYPE zmap_type-type VALUE 'EMAIL_RECIPIENT'.

DATA: gv_line TYPE ausp-atwrt.

SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE text-001.
PARAMETERS: p_rpt  RADIOBUTTON GROUP g01 DEFAULT 'X'
                   USER-COMMAND mod,
            p_mail RADIOBUTTON GROUP g01.
SELECTION-SCREEN END OF BLOCK b01.

SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME TITLE text-002.
PARAMETERS: r_no261 RADIOBUTTON GROUP g02 DEFAULT 'X',
            r_diff  RADIOBUTTON GROUP g02,
            r_less  RADIOBUTTON GROUP g02.
SELECTION-SCREEN END OF BLOCK b02.

SELECTION-SCREEN BEGIN OF BLOCK b03 WITH FRAME TITLE text-003.
SELECT-OPTIONS: s_werks FOR mseg-werks OBLIGATORY,
                s_budat FOR mkpf-budat OBLIGATORY,
                s_line  FOR gv_line,
                s_aufnr FOR aufk-aufnr.
PARAMETERS: p_tol  TYPE mseg-menge DEFAULT '0.001',
            p_vari TYPE disvariant-variant MODIF ID rpt.
SELECTION-SCREEN END OF BLOCK b03.

SELECTION-SCREEN BEGIN OF BLOCK b04 WITH FRAME TITLE text-004.
PARAMETERS: p_test  AS CHECKBOX DEFAULT 'X' MODIF ID mai,
            p_tmail AS CHECKBOX MODIF ID mai,
            p_taddr TYPE ad_smtpadr LOWER CASE MODIF ID mai.
SELECTION-SCREEN END OF BLOCK b04.

TYPES: BEGIN OF ty_mov,
         mblnr TYPE mseg-mblnr,
         mjahr TYPE mseg-mjahr,
         zeile TYPE mseg-zeile,
         bwart TYPE mseg-bwart,
         matnr TYPE mseg-matnr,
         werks TYPE mseg-werks,
         charg TYPE mseg-charg,
         menge TYPE mseg-menge,
         meins TYPE mseg-meins,
         aufnr TYPE mseg-aufnr,
         budat TYPE mkpf-budat,
         bktxt TYPE mkpf-bktxt,
       END OF ty_mov.

TYPES: BEGIN OF ty_out,
         werks       TYPE mseg-werks,
         prodline    TYPE char20,
         line_desc   TYPE char30,
         line_raw    TYPE ausp-atwrt,
         jr_number   TYPE ausp-atwrt,
         matnr       TYPE mseg-matnr,
         maktx       TYPE makt-maktx,
         gr_date     TYPE mkpf-budat,
         aufnr       TYPE mseg-aufnr,
         charg       TYPE mseg-charg,
         qty_gr      TYPE mseg-menge,
         qty_gi      TYPE p DECIMALS 3,
         qty_diff    TYPE p DECIMALS 3,
         meins       TYPE mseg-meins,
         auart       TYPE aufk-auart,
         bktxt       TYPE mkpf-bktxt,
         cnt_261     TYPE i,
         trace_stat  TYPE char20,
         mail_status TYPE char30,
       END OF ty_out.

TYPES: BEGIN OF ty_rel,
         out_order TYPE aufnr,
         mov_order TYPE aufnr,
       END OF ty_rel.

TYPES: BEGIN OF ty_afpo,
         aufnr          TYPE afpo-aufnr,
         parent_order   TYPE afpo-mill_oc_aufnr_u,
       END OF ty_afpo.

TYPES: BEGIN OF ty_gi,
         aufnr   TYPE mseg-aufnr,
         bktxt   TYPE mkpf-bktxt,
         qty_gi  TYPE p DECIMALS 3,
         cnt_261 TYPE i,
       END OF ty_gi.

TYPES: BEGIN OF ty_batch,
         matnr    TYPE mch1-matnr,
         charg    TYPE mch1-charg,
         cuobj_bm TYPE mch1-cuobj_bm,
         objek    TYPE ausp-objek,
       END OF ty_batch.

TYPES: BEGIN OF ty_char,
         objek TYPE ausp-objek,
         atinn TYPE ausp-atinn,
         atwrt TYPE ausp-atwrt,
       END OF ty_char.

TYPES: BEGIN OF ty_makt,
         matnr TYPE makt-matnr,
         maktx TYPE makt-maktx,
       END OF ty_makt.

TYPES: BEGIN OF ty_aufk,
         aufnr TYPE aufk-aufnr,
         auart TYPE aufk-auart,
       END OF ty_aufk.

TYPES: BEGIN OF ty_rec,
         email TYPE ad_smtpadr,
         role  TYPE char3,
       END OF ty_rec.

DATA: gt_gr       TYPE STANDARD TABLE OF ty_mov,
      gt_gimov    TYPE STANDARD TABLE OF ty_mov,
      gt_out      TYPE SORTED TABLE OF ty_out
                  WITH UNIQUE KEY werks matnr charg aufnr bktxt,
      gt_result   TYPE STANDARD TABLE OF ty_out,
      gt_rel      TYPE SORTED TABLE OF ty_rel
                  WITH UNIQUE KEY out_order mov_order,
      gt_afpo     TYPE STANDARD TABLE OF ty_afpo,
      gt_gi       TYPE SORTED TABLE OF ty_gi
                  WITH UNIQUE KEY aufnr bktxt,
      gt_batch    TYPE SORTED TABLE OF ty_batch
                  WITH UNIQUE KEY matnr charg,
      gt_char     TYPE STANDARD TABLE OF ty_char,
      gt_makt     TYPE SORTED TABLE OF ty_makt
                  WITH UNIQUE KEY matnr,
      gt_aufk     TYPE SORTED TABLE OF ty_aufk
                  WITH UNIQUE KEY aufnr,
      gt_map_line TYPE STANDARD TABLE OF zmap_type,
      gt_map_rec  TYPE STANDARD TABLE OF zmap_type,
      gt_fcat     TYPE slis_t_fieldcat_alv,
      gs_variant  TYPE disvariant.

INITIALIZATION.
  PERFORM get_default_variant.

AT SELECTION-SCREEN OUTPUT.
  PERFORM modify_screen.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_vari.
  PERFORM variant_f4.

AT SELECTION-SCREEN.
  PERFORM validate_selection.

START-OF-SELECTION.
  PERFORM get_data.
  IF gt_result IS INITIAL.
    MESSAGE text-010 TYPE 'S'.
    RETURN.
  ENDIF.

  IF p_mail = 'X'.
    PERFORM process_email.
  ENDIF.

  PERFORM display_report.

FORM modify_screen.
  LOOP AT SCREEN.
    IF screen-group1 = 'RPT'.
      IF p_rpt = 'X'.
        screen-active = '1'.
      ELSE.
        screen-active = '0'.
      ENDIF.
      MODIFY SCREEN.
    ELSEIF screen-group1 = 'MAI'.
      IF p_mail = 'X'.
        screen-active = '1'.
      ELSE.
        screen-active = '0'.
      ENDIF.
      IF screen-name = 'P_TADDR' AND p_tmail IS INITIAL.
        screen-input = '0'.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDFORM.

FORM validate_selection.
  DATA: ls_variant TYPE disvariant.

  IF p_mail = 'X' AND p_test = 'X' AND p_tmail = 'X'.
    MESSAGE e398(00) WITH text-011.
  ENDIF.

  IF p_mail = 'X' AND p_tmail = 'X' AND p_taddr IS INITIAL.
    MESSAGE e398(00) WITH text-012.
  ENDIF.

  IF p_rpt = 'X' AND p_vari IS NOT INITIAL.
    ls_variant-report  = sy-repid.
    ls_variant-variant = p_vari.
    CALL FUNCTION 'REUSE_ALV_VARIANT_EXISTENCE'
      EXPORTING
        i_save     = 'A'
      CHANGING
        cs_variant = ls_variant
      EXCEPTIONS
        wrong_input = 1
        not_found   = 2
        program_error = 3
        OTHERS      = 4.
    IF sy-subrc <> 0.
      MESSAGE e398(00) WITH text-013.
    ENDIF.
  ENDIF.
ENDFORM.

FORM get_default_variant.
  CLEAR gs_variant.
  gs_variant-report = sy-repid.
  CALL FUNCTION 'REUSE_ALV_VARIANT_DEFAULT_GET'
    EXPORTING
      i_save     = 'A'
    CHANGING
      cs_variant = gs_variant
    EXCEPTIONS
      not_found = 2
      OTHERS    = 3.
  IF sy-subrc = 0.
    p_vari = gs_variant-variant.
  ENDIF.
ENDFORM.

FORM variant_f4.
  DATA: ls_variant TYPE disvariant,
        lv_exit    TYPE char1.

  ls_variant-report  = sy-repid.
  ls_variant-variant = p_vari.
  CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
    EXPORTING
      is_variant = ls_variant
      i_save     = 'A'
    IMPORTING
      e_exit     = lv_exit
      es_variant = ls_variant
    EXCEPTIONS
      not_found = 2
      program_error = 3
      OTHERS = 4.
  IF sy-subrc = 0 AND lv_exit IS INITIAL.
    p_vari = ls_variant-variant.
  ENDIF.
ENDFORM.

FORM get_data.
  DATA: ls_mov      TYPE ty_mov,
        ls_out      TYPE ty_out,
        ls_rel      TYPE ty_rel,
        ls_afpo     TYPE ty_afpo,
        ls_gi       TYPE ty_gi,
        ls_batch    TYPE ty_batch,
        ls_char     TYPE ty_char,
        ls_makt     TYPE ty_makt,
        ls_aufk     TYPE ty_aufk,
        ls_map      TYPE zmap_type,
        lv_atinn_ln TYPE cabn-atinn,
        lv_atinn_jr TYPE cabn-atinn,
        lv_abs      TYPE p DECIMALS 3,
        lv_keep     TYPE char1.

  CLEAR: gt_gr, gt_gimov, gt_out, gt_result, gt_rel, gt_afpo,
         gt_gi, gt_batch, gt_char, gt_makt, gt_aufk,
         gt_map_line, gt_map_rec.

  SELECT a~mblnr a~mjahr a~zeile a~bwart a~matnr a~werks
         a~charg a~menge a~meins a~aufnr b~budat b~bktxt
    INTO CORRESPONDING FIELDS OF TABLE gt_gr
    FROM mseg AS a INNER JOIN mkpf AS b
      ON b~mblnr = a~mblnr
     AND b~mjahr = a~mjahr
   WHERE a~werks IN s_werks
     AND a~aufnr IN s_aufnr
     AND b~budat IN s_budat
     AND ( a~bwart = '101' OR a~bwart = '102' ).

  LOOP AT gt_gr INTO ls_mov.
    READ TABLE gt_out INTO ls_out
      WITH TABLE KEY werks = ls_mov-werks
                     matnr = ls_mov-matnr
                     charg = ls_mov-charg
                     aufnr = ls_mov-aufnr
                     bktxt = ls_mov-bktxt.
    IF sy-subrc <> 0.
      CLEAR ls_out.
      ls_out-werks   = ls_mov-werks.
      ls_out-matnr   = ls_mov-matnr.
      ls_out-charg   = ls_mov-charg.
      ls_out-aufnr   = ls_mov-aufnr.
      ls_out-bktxt   = ls_mov-bktxt.
      ls_out-meins   = ls_mov-meins.
      ls_out-gr_date = ls_mov-budat.
    ENDIF.
    IF ls_mov-bwart = '101'.
      ls_out-qty_gr = ls_out-qty_gr + ls_mov-menge.
      IF ls_out-gr_date IS INITIAL OR ls_mov-budat < ls_out-gr_date.
        ls_out-gr_date = ls_mov-budat.
      ENDIF.
    ELSE.
      ls_out-qty_gr = ls_out-qty_gr - ls_mov-menge.
    ENDIF.
    MODIFY TABLE gt_out FROM ls_out.
  ENDLOOP.

  DELETE gt_out WHERE qty_gr <= 0.
  IF gt_out IS INITIAL.
    RETURN.
  ENDIF.

  LOOP AT gt_out INTO ls_out.
    ls_rel-out_order = ls_out-aufnr.
    ls_rel-mov_order = ls_out-aufnr.
    INSERT ls_rel INTO TABLE gt_rel.
  ENDLOOP.

  SELECT aufnr mill_oc_aufnr_u AS parent_order
    INTO CORRESPONDING FIELDS OF TABLE gt_afpo
    FROM afpo
    FOR ALL ENTRIES IN gt_out
   WHERE mill_oc_aufnr_u = gt_out-aufnr.

  LOOP AT gt_afpo INTO ls_afpo.
    ls_rel-out_order = ls_afpo-parent_order.
    ls_rel-mov_order = ls_afpo-aufnr.
    INSERT ls_rel INTO TABLE gt_rel.
  ENDLOOP.

  IF gt_rel IS NOT INITIAL.
    SELECT a~mblnr a~mjahr a~zeile a~bwart a~matnr a~werks
           a~charg a~menge a~meins a~aufnr b~budat b~bktxt
      INTO CORRESPONDING FIELDS OF TABLE gt_gimov
      FROM mseg AS a INNER JOIN mkpf AS b
        ON b~mblnr = a~mblnr
       AND b~mjahr = a~mjahr
      FOR ALL ENTRIES IN gt_rel
     WHERE a~aufnr = gt_rel-mov_order
       AND a~werks IN s_werks
       AND b~budat IN s_budat
       AND ( a~bwart = '261' OR a~bwart = '262' ).
  ENDIF.

  LOOP AT gt_gimov INTO ls_mov.
    READ TABLE gt_gi INTO ls_gi
      WITH TABLE KEY aufnr = ls_mov-aufnr bktxt = ls_mov-bktxt.
    IF sy-subrc <> 0.
      CLEAR ls_gi.
      ls_gi-aufnr = ls_mov-aufnr.
      ls_gi-bktxt = ls_mov-bktxt.
    ENDIF.
    IF ls_mov-bwart = '261'.
      ls_gi-qty_gi  = ls_gi-qty_gi - ls_mov-menge.
      ls_gi-cnt_261 = ls_gi-cnt_261 + 1.
    ELSE.
      ls_gi-qty_gi = ls_gi-qty_gi + ls_mov-menge.
    ENDIF.
    MODIFY TABLE gt_gi FROM ls_gi.
  ENDLOOP.

  SELECT SINGLE atinn INTO lv_atinn_ln FROM cabn
   WHERE atnam = gc_atnam_line.
  SELECT SINGLE atinn INTO lv_atinn_jr FROM cabn
   WHERE atnam = gc_atnam_roll.

  SELECT matnr charg cuobj_bm
    INTO CORRESPONDING FIELDS OF TABLE gt_batch
    FROM mch1
    FOR ALL ENTRIES IN gt_out
   WHERE matnr = gt_out-matnr
     AND charg = gt_out-charg.

  IF gt_batch IS NOT INITIAL.
    LOOP AT gt_batch INTO ls_batch.
      ls_batch-objek = ls_batch-cuobj_bm.
      MODIFY TABLE gt_batch FROM ls_batch.
    ENDLOOP.
    SELECT objek atinn atwrt
      INTO CORRESPONDING FIELDS OF TABLE gt_char
      FROM ausp
      FOR ALL ENTRIES IN gt_batch
     WHERE objek = gt_batch-objek
       AND klart = '023'
       AND ( atinn = lv_atinn_ln OR atinn = lv_atinn_jr ).
  ENDIF.

  SELECT matnr maktx
    INTO CORRESPONDING FIELDS OF TABLE gt_makt
    FROM makt
    FOR ALL ENTRIES IN gt_out
   WHERE matnr = gt_out-matnr
     AND spras = sy-langu.

  SELECT aufnr auart
    INTO CORRESPONDING FIELDS OF TABLE gt_aufk
    FROM aufk
    FOR ALL ENTRIES IN gt_out
   WHERE aufnr = gt_out-aufnr.

  SELECT * INTO TABLE gt_map_line FROM zmap_type
   WHERE prog = sy-cprog
     AND type = gc_map_line
     AND opt  = gc_atnam_line
     AND deletion = space.

  LOOP AT gt_out INTO ls_out.
    CLEAR: ls_out-qty_gi, ls_out-cnt_261.
    LOOP AT gt_rel INTO ls_rel WHERE out_order = ls_out-aufnr.
      READ TABLE gt_gi INTO ls_gi
        WITH TABLE KEY aufnr = ls_rel-mov_order bktxt = ls_out-bktxt.
      IF sy-subrc = 0.
        ls_out-qty_gi  = ls_out-qty_gi + ls_gi-qty_gi.
        ls_out-cnt_261 = ls_out-cnt_261 + ls_gi-cnt_261.
      ENDIF.
    ENDLOOP.
    ls_out-qty_diff = ls_out-qty_gr + ls_out-qty_gi.

    IF ls_out-bktxt IS INITIAL.
      ls_out-trace_stat = 'BKTXT_EMPTY'.
    ELSEIF ls_out-cnt_261 = 0.
      ls_out-trace_stat = 'NO_261'.
    ELSE.
      ls_out-trace_stat = 'MATCHED'.
    ENDIF.

    READ TABLE gt_batch INTO ls_batch
      WITH TABLE KEY matnr = ls_out-matnr charg = ls_out-charg.
    IF sy-subrc = 0.
      LOOP AT gt_char INTO ls_char WHERE objek = ls_batch-objek.
        IF ls_char-atinn = lv_atinn_ln.
          ls_out-line_raw = ls_char-atwrt.
        ELSEIF ls_char-atinn = lv_atinn_jr.
          ls_out-jr_number = ls_char-atwrt.
        ENDIF.
      ENDLOOP.
    ENDIF.

    IF ls_out-jr_number IS INITIAL.
      ls_out-jr_number = ls_out-charg.
    ENDIF.

    ls_out-prodline = ls_out-line_raw.
    READ TABLE gt_map_line INTO ls_map WITH KEY value = ls_out-line_raw.
    IF sy-subrc = 0.
      IF ls_map-text1 IS NOT INITIAL.
        ls_out-prodline = ls_map-text1.
      ENDIF.
      ls_out-line_desc = ls_map-text2.
    ELSE.
      IF ls_out-line_raw IS INITIAL.
        ls_out-prodline = 'UNASSIGNED'.
      ENDIF.
      IF ls_out-trace_stat = 'MATCHED'.
        ls_out-trace_stat = 'UNMAPPED_LINE'.
      ENDIF.
    ENDIF.

    IF s_line[] IS NOT INITIAL AND ls_out-prodline NOT IN s_line.
      CONTINUE.
    ENDIF.

    READ TABLE gt_makt INTO ls_makt
      WITH TABLE KEY matnr = ls_out-matnr.
    IF sy-subrc = 0.
      ls_out-maktx = ls_makt-maktx.
    ENDIF.
    READ TABLE gt_aufk INTO ls_aufk
      WITH TABLE KEY aufnr = ls_out-aufnr.
    IF sy-subrc = 0.
      ls_out-auart = ls_aufk-auart.
    ENDIF.

    lv_abs = ls_out-qty_diff.
    IF lv_abs < 0.
      lv_abs = lv_abs * -1.
    ENDIF.
    CLEAR lv_keep.
    IF r_no261 = 'X' AND ls_out-cnt_261 = 0.
      lv_keep = 'X'.
    ELSEIF r_diff = 'X' AND ls_out-cnt_261 > 0 AND lv_abs > p_tol.
      lv_keep = 'X'.
    ELSEIF r_less = 'X' AND ls_out-cnt_261 > 0
       AND ( ls_out-qty_gi * -1 ) < ( ls_out-qty_gr - p_tol ).
      lv_keep = 'X'.
    ENDIF.
    IF lv_keep = 'X'.
      APPEND ls_out TO gt_result.
    ENDIF.
  ENDLOOP.

  SORT gt_result BY prodline gr_date aufnr charg.
ENDFORM.

FORM process_email.
  DATA: lt_line TYPE SORTED TABLE OF char20 WITH UNIQUE KEY table_line,
        lv_line TYPE char20,
        ls_out  TYPE ty_out,
        lv_sent TYPE char1,
        lv_stat TYPE char30.

  SELECT * INTO TABLE gt_map_rec FROM zmap_type
   WHERE prog = sy-cprog
     AND type = gc_map_mail
     AND deletion = space.

  LOOP AT gt_result INTO ls_out.
    INSERT ls_out-prodline INTO TABLE lt_line.
  ENDLOOP.

  LOOP AT lt_line INTO lv_line.
    CLEAR: lv_sent, lv_stat.
    PERFORM send_line_email USING lv_line CHANGING lv_sent lv_stat.
    LOOP AT gt_result INTO ls_out WHERE prodline = lv_line.
      ls_out-mail_status = lv_stat.
      MODIFY gt_result FROM ls_out TRANSPORTING mail_status.
    ENDLOOP.
  ENDLOOP.
ENDFORM.

FORM send_line_email USING    pv_line TYPE char20
                     CHANGING pv_sent TYPE char1
                              pv_stat TYPE char30.
  DATA: lt_rec      TYPE SORTED TABLE OF ty_rec
                    WITH UNIQUE KEY email role,
        ls_rec      TYPE ty_rec,
        ls_map      TYPE zmap_type,
        lt_body     TYPE soli_tab,
        lt_attach   TYPE soli_tab,
        ls_soli     TYPE soli,
        ls_out      TYPE ty_out,
        lo_send     TYPE REF TO cl_bcs,
        lo_doc      TYPE REF TO cl_document_bcs,
        lo_address  TYPE REF TO if_recipient_bcs,
        lx_bcs      TYPE REF TO cx_bcs,
        lv_subject  TYPE so_obj_des,
        lv_email    TYPE ad_smtpadr,
        lv_role     TYPE char3,
        lv_copy     TYPE os_boolean,
        lv_blind    TYPE os_boolean,
        lv_has_line TYPE char1,
        lv_has_to   TYPE char1,
        lv_qty_gr   TYPE char20,
        lv_qty_gi   TYPE char20,
        lv_diff     TYPE char20,
        lv_date     TYPE char10.

  IF p_tmail = 'X'.
    ls_rec-email = p_taddr.
    ls_rec-role  = 'TO'.
    INSERT ls_rec INTO TABLE lt_rec.
  ELSE.
    LOOP AT gt_map_rec INTO ls_map WHERE opt = pv_line.
      lv_has_line = 'X'.
      PERFORM map_to_recipient USING ls_map CHANGING ls_rec.
      IF ls_rec-email IS NOT INITIAL.
        INSERT ls_rec INTO TABLE lt_rec.
      ENDIF.
    ENDLOOP.
    IF lv_has_line IS INITIAL.
      LOOP AT gt_map_rec INTO ls_map WHERE opt = 'DEFAULT'.
        PERFORM map_to_recipient USING ls_map CHANGING ls_rec.
        IF ls_rec-email IS NOT INITIAL.
          INSERT ls_rec INTO TABLE lt_rec.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  LOOP AT lt_rec INTO ls_rec.
    IF ls_rec-role = 'TO'.
      lv_has_to = 'X'.
      EXIT.
    ENDIF.
  ENDLOOP.
  IF lv_has_to IS INITIAL.
    pv_stat = 'NO_TO_RECIPIENT'.
    RETURN.
  ENDIF.

  WRITE sy-datum TO lv_date.
  CONCATENATE 'Observasi GI JR -' pv_line '-' lv_date
    INTO lv_subject SEPARATED BY space.
  IF p_tmail = 'X'.
    CONCATENATE '[TEST]' lv_subject INTO lv_subject SEPARATED BY space.
  ENDIF.

  ls_soli-line = '<html><body><p>Dear User,</p>'.
  APPEND ls_soli TO lt_body.
  CONCATENATE '<p>Berikut exception observasi GI Jumbo Roll untuk line <b>'
              pv_line '</b>.</p>' INTO ls_soli-line.
  APPEND ls_soli TO lt_body.
  ls_soli-line = '<table border="1" cellspacing="0" cellpadding="4">'.
  APPEND ls_soli TO lt_body.
  ls_soli-line = '<tr><th>JR Number</th><th>Material</th><th>GR Date</th>'.
  APPEND ls_soli TO lt_body.
  ls_soli-line = '<th>Order</th><th>Batch</th><th>Qty JR</th>'.
  APPEND ls_soli TO lt_body.
  ls_soli-line = '<th>Qty GI</th><th>Diff</th><th>Status</th></tr>'.
  APPEND ls_soli TO lt_body.

  ls_soli-line = 'JR Number;Production Line;Material;Description;GR Date;Order;Batch;Qty JR;Qty GI;Diff;UoM;Order Type;BKTXT;Trace Status'.
  APPEND ls_soli TO lt_attach.

  LOOP AT gt_result INTO ls_out WHERE prodline = pv_line.
    WRITE ls_out-qty_gr TO lv_qty_gr NO-GROUPING.
    WRITE ls_out-qty_gi TO lv_qty_gi NO-GROUPING.
    WRITE ls_out-qty_diff TO lv_diff NO-GROUPING.
    CONDENSE: lv_qty_gr, lv_qty_gi, lv_diff.

    CONCATENATE '<tr><td>' ls_out-jr_number '</td><td>'
                ls_out-matnr '</td><td>' ls_out-gr_date '</td>'
      INTO ls_soli-line.
    APPEND ls_soli TO lt_body.
    CONCATENATE '<td>' ls_out-aufnr '</td><td>' ls_out-charg
                '</td><td>' lv_qty_gr '</td>' INTO ls_soli-line.
    APPEND ls_soli TO lt_body.
    CONCATENATE '<td>' lv_qty_gi '</td><td>' lv_diff '</td><td>'
                ls_out-trace_stat '</td></tr>' INTO ls_soli-line.
    APPEND ls_soli TO lt_body.

    CONCATENATE ls_out-jr_number pv_line ls_out-matnr ls_out-maktx
                ls_out-gr_date ls_out-aufnr ls_out-charg lv_qty_gr
                lv_qty_gi lv_diff ls_out-meins ls_out-auart
                ls_out-bktxt ls_out-trace_stat
      INTO ls_soli-line SEPARATED BY ';'.
    APPEND ls_soli TO lt_attach.
  ENDLOOP.

  ls_soli-line = '</table><p>Email dibuat otomatis oleh SAP.</p></body></html>'.
  APPEND ls_soli TO lt_body.

  IF p_test = 'X'.
    pv_stat = 'TEST_RUN_PREVIEW'.
    RETURN.
  ENDIF.

  TRY.
      lo_send = cl_bcs=>create_persistent( ).
      lo_doc = cl_document_bcs=>create_document(
          i_type    = 'HTM'
          i_text    = lt_body
          i_subject = lv_subject ).
      lo_doc->add_attachment(
          i_attachment_type    = 'CSV'
          i_attachment_subject = lv_subject
          i_att_content_text    = lt_attach ).
      lo_send->set_document( lo_doc ).

      LOOP AT lt_rec INTO ls_rec.
        lo_address = cl_cam_address_bcs=>create_internet_address(
                       ls_rec-email ).
        CLEAR: lv_copy, lv_blind.
        lv_role = ls_rec-role.
        IF lv_role = 'CC'.
          lv_copy = 'X'.
        ELSEIF lv_role = 'BCC'.
          lv_blind = 'X'.
        ENDIF.
        lo_send->add_recipient(
            i_recipient  = lo_address
            i_copy       = lv_copy
            i_blind_copy = lv_blind ).
      ENDLOOP.

      pv_sent = lo_send->send( i_with_error_screen = space ).
      COMMIT WORK.
      IF pv_sent = 'X'.
        pv_stat = 'EMAIL_SENT'.
      ELSE.
        pv_stat = 'EMAIL_NOT_SENT'.
      ENDIF.
    CATCH cx_bcs INTO lx_bcs.
      pv_stat = 'EMAIL_ERROR'.
  ENDTRY.
ENDFORM.

FORM map_to_recipient USING    ps_map TYPE zmap_type
                      CHANGING ps_rec TYPE ty_rec.
  DATA: lv_domain TYPE char45.

  CLEAR ps_rec.
  IF ps_map-text5 CS '@'.
    ps_rec-email = ps_map-text5.
  ELSEIF ps_map-text1 IS NOT INITIAL AND ps_map-text2 IS NOT INITIAL.
    lv_domain = ps_map-text2.
    IF lv_domain+0(1) <> '@'.
      CONCATENATE '@' lv_domain INTO lv_domain.
    ENDIF.
    CONCATENATE ps_map-text1 lv_domain INTO ps_rec-email.
  ENDIF.
  ps_rec-role = ps_map-text3.
  TRANSLATE ps_rec-role TO UPPER CASE.
  IF ps_rec-role <> 'TO' AND ps_rec-role <> 'CC'
     AND ps_rec-role <> 'BCC'.
    CLEAR ps_rec.
  ENDIF.
ENDFORM.

FORM display_report.
  DATA: ls_layout TYPE slis_layout_alv.

  PERFORM build_fieldcat.
  gs_variant-report  = sy-repid.
  gs_variant-variant = p_vari.
  ls_layout-colwidth_optimize = 'X'.
  ls_layout-zebra = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = sy-repid
      is_layout          = ls_layout
      it_fieldcat        = gt_fcat
      i_save             = 'A'
      is_variant         = gs_variant
    TABLES
      t_outtab           = gt_result
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.
  IF sy-subrc <> 0.
    MESSAGE e398(00) WITH text-014.
  ENDIF.
ENDFORM.

FORM build_fieldcat.
  CLEAR gt_fcat.
  PERFORM add_field USING 'WERKS'       'Plant'            4.
  PERFORM add_field USING 'PRODLINE'    'Production Line' 20.
  PERFORM add_field USING 'JR_NUMBER'   'JR Number'       20.
  PERFORM add_field USING 'MATNR'       'Material'        18.
  PERFORM add_field USING 'MAKTX'       'Description'     30.
  PERFORM add_field USING 'GR_DATE'     'GR Date'         10.
  PERFORM add_field USING 'AUFNR'       'Order'           12.
  PERFORM add_field USING 'CHARG'       'Batch'           10.
  PERFORM add_field USING 'QTY_GR'      'Qty JR'          15.
  PERFORM add_field USING 'QTY_GI'      'Qty GI'          15.
  PERFORM add_field USING 'QTY_DIFF'    'Diff'            15.
  PERFORM add_field USING 'MEINS'       'UoM'              5.
  PERFORM add_field USING 'AUART'       'Order Type'       6.
  PERFORM add_field USING 'BKTXT'       'BKTXT'           25.
  PERFORM add_field USING 'TRACE_STAT'  'Trace Status'    20.
  PERFORM add_field USING 'MAIL_STATUS' 'Email Status'    30.
ENDFORM.

FORM add_field USING pv_field TYPE slis_fieldname
                     pv_text  TYPE char40
                     pv_len   TYPE i.
  DATA: ls_fcat TYPE slis_fieldcat_alv.
  CLEAR ls_fcat.
  ls_fcat-fieldname = pv_field.
  ls_fcat-seltext_l = pv_text.
  ls_fcat-seltext_m = pv_text.
  ls_fcat-seltext_s = pv_text.
  ls_fcat-outputlen = pv_len.
  APPEND ls_fcat TO gt_fcat.
ENDFORM.

*&---------------------------------------------------------------------*
*&  Include           ZPPR_SLITTING_REKAP_PC_V2_F0
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  VB_INIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM VB_INIT .
  CALL FUNCTION 'VB_INIT'
    EXPORTING
      INIT_RESET = 'X'.
ENDFORM.                    " VB_INIT

*&---------------------------------------------------------------------*
*&      Form  F_INITITIALIZATION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_INITITIALIZATION .
  SELECT * INTO CORRESPONDING FIELDS OF TABLE IT_CABN FROM CABN WHERE ATNAM LIKE 'ZZ%'.

  READ TABLE IT_CABN WITH KEY ATNAM = 'ZZNOMORROLL'.
  IF SY-SUBRC EQ 0.
    V_ZZNOMORROLL = IT_CABN-ATINN.
  ENDIF.

  READ TABLE IT_CABN WITH KEY ATNAM = 'ZZWIDTH'.
  IF SY-SUBRC EQ 0.
    V_ZZWIDTH = IT_CABN-ATINN.
  ENDIF.

  READ TABLE IT_CABN WITH KEY ATNAM = 'ZZCONVERSIONROLLKG'.
  IF SY-SUBRC EQ 0.
    V_ZZCONVERSIONROLLKG = IT_CABN-ATINN.
  ENDIF.

  READ TABLE IT_CABN WITH KEY ATNAM = 'ZZEXLENGTH'.
  IF SY-SUBRC EQ 0.
    V_ZZEXLENGTH = IT_CABN-ATINN.
  ENDIF.

  READ TABLE IT_CABN WITH KEY ATNAM = 'ZZCORETYPE'.
  IF SY-SUBRC EQ 0.
    V_ZZCORETYPE = IT_CABN-ATINN.
  ENDIF.

  READ TABLE IT_CABN WITH KEY ATNAM = 'ZZTAILORED'.
  IF SY-SUBRC EQ 0.
    V_ZZTAILORED = IT_CABN-ATINN.
  ENDIF.

  READ TABLE IT_CABN WITH KEY ATNAM = 'ZZLABEL'.
  IF SY-SUBRC EQ 0.
    V_ZZLABEL = IT_CABN-ATINN.
  ENDIF.

  READ TABLE IT_CABN WITH KEY ATNAM = 'ZZNOROLLTOYOBO'.
  IF SY-SUBRC EQ 0.
    V_ZZNOROLLTOYOBO = IT_CABN-ATINN.
  ENDIF.

  READ TABLE IT_CABN WITH KEY ATNAM = 'ZZNOLOTTOYOBO'.
  IF SY-SUBRC EQ 0.
    V_ZZNOLOTTOYOBO = IT_CABN-ATINN.
  ENDIF.

  READ TABLE IT_CABN WITH KEY ATNAM = 'ZZCODE'.
  IF SY-SUBRC EQ 0.
    V_ZZCODE = IT_CABN-ATINN.
  ENDIF.

  READ TABLE IT_CABN WITH KEY ATNAM = 'ZZPRODLINE'.
  IF SY-SUBRC EQ 0.
    V_ZZPRODLINE = IT_CABN-ATINN.
  ENDIF.

  READ TABLE IT_CABN WITH KEY ATNAM = 'ZZTREATMENT'.
  IF SY-SUBRC EQ 0.
    V_ZZTREATMENT = IT_CABN-ATINN.
  ENDIF.

  READ TABLE IT_CABN WITH KEY ATNAM = 'ZZPACKING'.
  IF SY-SUBRC EQ 0.
    V_ZZPACKING = IT_CABN-ATINN.
  ENDIF.

  READ TABLE IT_CABN WITH KEY ATNAM = 'ZZCRITERIA'.
  IF SY-SUBRC EQ 0.
    V_ZZCRITERIA = IT_CABN-ATINN.
  ENDIF.

  READ TABLE IT_CABN WITH KEY ATNAM = 'ZZGRADE'.
  IF SY-SUBRC EQ 0.
    V_ZZGRADE = IT_CABN-ATINN.
  ENDIF.

  READ TABLE IT_CABN WITH KEY ATNAM = 'ZZALIAS'.
  IF SY-SUBRC EQ 0.
    V_ZZALIAS = IT_CABN-ATINN.
  ENDIF.

  CLEAR V_LINE.
  REFRESH V_LINE.

  IF V_ZZPRODLINE NE '0000000000'.
    SELECT CAWN~ATWRT CAWNT~ATWTB
      INTO TABLE V_LINE
      FROM CAWN
     INNER JOIN CAWNT ON CAWNT~ATINN = CAWN~ATINN AND CAWNT~ATZHL = CAWN~ATZHL
     WHERE CAWN~ATINN = V_ZZPRODLINE.
  ENDIF.

  " Start Add 22.09.2025 by Fiqih
  " Judul untuk halaman utama ZPP016A
  IF SY-TCODE = 'ZPP016A'.
    SY-TITLE = 'Rekap Slitting Harian - Single Batch (TTA)'.
  ENDIF.
  " End Add 22.09.2025 by Fiqih

ENDFORM.                    " F_INITITIALIZATION
*&---------------------------------------------------------------------*
*&      Form  f_get_values_request
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_s_atwrt1  text
*----------------------------------------------------------------------*
FORM F_GET_VALUES_REQUEST CHANGING FC_ATWRT.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      RETFIELD        = 'ATWRT'
      DYNPPROG        = SY-REPID
      DYNPNR          = SY-DYNNR
      DYNPROFIELD     = 'ATWRT'
      VALUE_ORG       = 'S'
    TABLES
      VALUE_TAB       = V_LINE
    EXCEPTIONS
      PARAMETER_ERROR = 1
      NO_VALUES_FOUND = 2
      OTHERS          = 3.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    "f_get_values_request
*&---------------------------------------------------------------------*
*&      Form  GET_DEC_NOTATION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_DEC_NOTATION CHANGING RIBUAN PULUHAN.

  DATA: USR01_EXP LIKE USR01.

  CALL FUNCTION 'CETA_USR01_READ'
    EXPORTING
      BNAME     = SY-UNAME
    IMPORTING
      USR01_EXP = USR01_EXP
    EXCEPTIONS
      NO_ENTRY  = 1
      OTHERS    = 2.
  IF SY-SUBRC <> 0.
* Implement suitable error handling here
  ENDIF.

  IF USR01_EXP-DCPFM EQ ''.
    RIBUAN  = '.'.
    PULUHAN = ','.
  ELSEIF USR01_EXP-DCPFM EQ 'X'.
    RIBUAN  = ','.
    PULUHAN = '.'.
  ELSEIF USR01_EXP-DCPFM EQ 'Y'.
    RIBUAN  = SPACE.
    PULUHAN = ','.
  ENDIF.

ENDFORM.                    " GET_DEC_NOTATION
*&---------------------------------------------------------------------*
*&      Form  define_auart
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DEFINE_AUART.

  CLEAR V_AUART.
  REFRESH V_AUART.

  V_AUART-SIGN    =  'I'.
  V_AUART-OPTION  =  'EQ'.
  V_AUART-LOW     =  'ZAD1'.
  APPEND V_AUART.
  CLEAR V_AUART.

  V_AUART-SIGN    =  'I'.
  V_AUART-OPTION  =  'EQ'.
  V_AUART-LOW     =  'ZAD2'.
  APPEND V_AUART.
  CLEAR V_AUART.

  V_AUART-SIGN    =  'I'.
  V_AUART-OPTION  =  'EQ'.
  V_AUART-LOW     =  'ZBS1'.
  APPEND V_AUART.
  CLEAR V_AUART.

  V_AUART-SIGN    =  'I'.
  V_AUART-OPTION  =  'EQ'.
  V_AUART-LOW     =  'ZBS2'.
  APPEND V_AUART.
  CLEAR V_AUART.

  V_AUART-SIGN    =  'I'.
  V_AUART-OPTION  =  'EQ'.
  V_AUART-LOW     =  'ZRR1'.
  APPEND V_AUART.
  CLEAR V_AUART.

  V_AUART-SIGN    =  'I'.
  V_AUART-OPTION  =  'EQ'.
  V_AUART-LOW     =  'ZRR2'.
  APPEND V_AUART.
  CLEAR V_AUART.

  "ADDED BY FATHIR ON 28.05.2020
  " Order Type Slitting, akan dijadikan parameter query GR 101
  V_AUARTSL-LOW = 'PPA1'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'PPA2'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'PPT2'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'PPZ1'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'PPZ2'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'TPA1'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'TPA2'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'TPT2'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'TPZ1'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'TPZ2'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'ZPE2'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'ZPL2'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'ZPP1'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'ZPP2'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'ZPR2'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'ZPS2'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'ZPX2'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'ZTO1'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'ZTO2'.
  APPEND V_AUARTSL.
  " Added by William at 24.07.2022 (OPP7 CPP1)
  V_AUARTSL-LOW = 'CPZ2'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'EPZ2'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'BPZ1'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'BPZ2'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'CPP2'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'CPE2'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'ZPB1'.
  APPEND V_AUARTSL.
  V_AUARTSL-LOW = 'ZPB2'.
  APPEND V_AUARTSL.
  " Added by William at 24.07.2022 (OPP7 CPP1)
  V_AUARTSL-LOW = 'ZPL1'.
  APPEND V_AUARTSL.

  V_AUARTSL-SIGN = 'I'.
  V_AUARTSL-OPTION = 'EQ'.
  MODIFY V_AUARTSL TRANSPORTING SIGN OPTION WHERE SIGN = ''.

  "ADDED BY FATHIR ON 28.05.2020
  " Order Type Transfer Mat FGS to Mat FGS, akan dijadikan parameter query GR 531 (ZPP029)
  V_AUARTTR-SIGN = 'I'.
  V_AUARTTR-OPTION = 'EQ'.
  V_AUARTTR-LOW = 'ZMM1'.
  APPEND V_AUARTTR.

ENDFORM.                    " define_auart
*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_DATA.
  DATA : BEGIN OF IT_MATNR OCCURS 0,
          MATNR LIKE MARA-MATNR,
         END OF IT_MATNR.
  RANGES :  R_MATNR FOR MARA-MATNR,
            R_BUDAT FOR MKPF-BUDAT.

  DATA : V_BUDAT_LOW LIKE P0001-BEGDA,
         V_BUDAT_HIGH LIKE P0001-BEGDA.

  CLEAR : IT_MATNR,IT_MATNR[].
  SELECT MATNR
    INTO TABLE IT_MATNR
    FROM MARA
    WHERE MATNR IN MATNR AND MATKL IN MATKL AND
         MTART = 'ZFGS'.

  CLEAR : R_MATNR, R_MATNR[].
  LOOP AT IT_MATNR.
    R_MATNR-SIGN = 'I'.
    R_MATNR-OPTION = 'EQ'.
    R_MATNR-LOW = IT_MATNR-MATNR.
    APPEND R_MATNR.
    CLEAR R_MATNR.
  ENDLOOP.

  IF BUDAT-HIGH IS NOT INITIAL.

    V_BUDAT_LOW = BUDAT-LOW.
    V_BUDAT_HIGH = BUDAT-HIGH.

    CLEAR : R_BUDAT.
    R_BUDAT-SIGN = 'I'.
    R_BUDAT-OPTION = 'EQ'.
    R_BUDAT-LOW = V_BUDAT_LOW.
    APPEND R_BUDAT.
    CLEAR : R_BUDAT.

    WHILE V_BUDAT_LOW < V_BUDAT_HIGH.
      V_BUDAT_LOW = V_BUDAT_LOW + 1.

      R_BUDAT-SIGN = 'I'.
      R_BUDAT-OPTION = 'EQ'.
      R_BUDAT-LOW = V_BUDAT_LOW.
      APPEND R_BUDAT.
      CLEAR : R_BUDAT.
    ENDWHILE.
  ELSE.
    R_BUDAT[] = BUDAT[].
  ENDIF.

  "CHANGED BY FATHIR ON 26.05.2020
  " Get GRN 101
  PERFORM F_GETGRN01 TABLES R_MATNR R_BUDAT.

  "CHANGED BY FATHIR ON 15.05.2020
  " Get Order untuk Transfer Mat FGS to Mat FGS, fine tuning
  CLEAR: R_AUFNR.
  REFRESH R_AUFNR.
  PERFORM F_GETORDER_MTM TABLES R_BUDAT.

  " Get GRN untuk Transfer Mat FGS to Mat FGS, fine tuning
  PERFORM F_GETGRN_MTM TABLES R_AUFNR R_MATNR R_BUDAT.

  IF IT_MSEG[] IS INITIAL.
    MESSAGE 'No data selected' TYPE 'I'.                    "#EC NOTEXT
    EXIT.
  ENDIF.

*- add by ALF case of GRN MAterial O TTE
  DELETE IT_MSEG WHERE AUFNR EQ ''.

  PERFORM GET_STOCK.

  "ADDED BY FATHIR ON 29.05.2020
  " get data reversal untuk GR 101 yang sudah cancel
  UNASSIGN <FS_MSEG>.
  LOOP AT IT_MSEG ASSIGNING <FS_MSEG> WHERE BWART = '101'.
    SELECT SINGLE SMBLN SMBLP
      INTO (<FS_MSEG>-SMBLN,<FS_MSEG>-SMBLP)
      FROM MSEG
     WHERE SMBLN = <FS_MSEG>-MBLNR AND SJAHR = <FS_MSEG>-MJAHR AND
           SMBLP = <FS_MSEG>-ZEILE AND BWART = '102'.
  ENDLOOP.

  " hapus batch GR yang sudah cancel
  DELETE IT_MSEG WHERE SMBLN NE ''.

  "CHANGED BY FATHIR ON 29.05.2020
  " get data pendukung setiap batch (characteristics, etc)
  PERFORM F_PARSEBATCHEXE.

  IF ZLINE IS NOT INITIAL.
    DELETE IT_MSEG WHERE LINECD NOT IN ZLINE.
  ENDIF.
  IF V_SCON = ''.
    DELETE IT_MSEG WHERE AUFNR = ''.
  ENDIF.

**Additional Case Order Type 8 January 2013
  DELETE IT_MSEG WHERE AUART IN V_AUART.
**End Additional Case Order Type 8 January 2013

  UNASSIGN <FS_MSEG>.
  READ TABLE IT_MSEG ASSIGNING <FS_MSEG> INDEX 1.
  IF SY-SUBRC NE 0.
    MESSAGE 'No data selected' TYPE 'I'.                    "#EC NOTEXT
    EXIT.
  ENDIF.

ENDFORM.                    " GET_DATA
*&---------------------------------------------------------------------*
*&      Form  TO_SCREEN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM TO_SCREEN .

  UNASSIGN <FS_MSEG>.
  READ TABLE IT_MSEG ASSIGNING <FS_MSEG> INDEX 1.
  IF SY-SUBRC NE 0.
    EXIT.
  ENDIF.

  PERFORM F_FIELD_CATALOG.
  PERFORM F_LAYOUT.
  PERFORM F_LIST_DETAIL.

ENDFORM.                    " TO_SCREEN

*&---------------------------------------------------------------------*
*&      Form  f_field_catalog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_FIELD_CATALOG .
  REFRESH: T_FIELDCAT.
*  PERFORM f_alv_fieldcatg_icon USING 'IT_MSEG' :

  " Field umum (muncul di semua T-Code atau hanya untuk ZPP016N)
  PERFORM F_ALV_FIELDCATG_ICON_WT_ZERO USING 'IT_MSEG' :
   'CPUTM'  '' ''  '' '10' 'Entry Time'           '' ' ' '' '', "#EC NOTEXT
   'ZZCODE' '' ''  '' '30' 'Type Film'            '' ' ' '' '', "#EC NOTEXT
   'NOROLL' '' ''  '' '30' 'No Roll'              '' ' ' '' '', "#EC NOTEXT
   'WIDTH'  '' ''  '' '30' 'Lebar'                '' ' ' '' '', "#EC NOTEXT
   'LENGTH' '' ''  '' '30' 'Panjang'              '' ' ' '' '', "#EC NOTEXT
   'ZEXTRA' '' ''  '' '12' 'Extra Length'         '' ' ' '' '', "#EC NOTEXT
   'GRADE'  '' ''  '' '10' 'Grade'                '' ' ' '' '', "#EC NOTEXT
   'GRADETXT'  '' ''  '' '20' 'Description Grade'                '' ' ' '' '', "#EC NOTEXT
   'MENGE'  '' ''  '' '16' 'Quantity'             '' ' ' '' '', "#EC NOTEXT
   'ARBPL'  '' ''  '' '15' 'Resource'             '' ' ' '' '', "#EC NOTEXT
   'LINE'   '' ''  '' '30' 'Production Line'      '' ' ' '' '', "#EC NOTEXT
   'CRIT'   '' ''  '' '30' 'Criteria'             '' ' ' '' '', "#EC NOTEXT
   'BUDAT'  '' ''  '' '10' 'Prod.Date'            '' ' ' '' '', "#EC NOTEXT
   'MATNR'  '' ''  '' '10' 'Material'             '' ' ' '' '', "#EC NOTEXT
   'WERKS'  '' ''  '' '4'  'Plant'                '' ' ' '' '', "#EC NOTEXT
   'LGORT'  '' ''  '' '4'  'SLoc'                 '' ' ' '' '', "#EC NOTEXT
   'MEINS'  '' ''  '' '3'  'UoM'                  '' ' ' '' '', "#EC NOTEXT
   'CHARG'  '' ''  '' '10' 'Batch'                '' 'X' '' '', "#EC NOTEXT
   'TREAT'  '' ''  '' '15' 'Treatment'            '' ' ' '' '', "#EC NOTEXT
   'PCKNG'  '' ''  '' '15' 'Packing'              '' ' ' '' '', "#EC NOTEXT
   'AUFNR'  '' ''  '' '15' 'Order Number'         '' ' ' '' '', "#EC NOTEXT
   'V_LASTGRADE' '' ''  '' '15' 'Last Grade'      '' ' ' '' '', "#EC NOTEXT
   'V_LASTGRADETXT' '' ''  '' '20' 'Description Last Grade'      '' ' ' '' '', "#EC NOTEXT
   'V_LASTCRIT' '' ''  '' '15' 'Last Crit.Grade'  '' ' ' '' '', "#EC NOTEXT
   'V_LASTQTY'  '' ''  '' '15' 'Last Qty'         '' ' ' '' '', "#EC NOTEXT
   'KDAUF2' '' ''  '' '10' 'Sales Order'          '' ' ' '' '', "#EC NOTEXT
   'KDPOS2' '' ''  '' '10' 'SO Item'              '' ' ' '' '', "#EC NOTEXT
   'KUNNR'  '' ''  '' '10' 'Customer'             '' ' ' '' '', "#EC NOTEXT
   'NAME1'  '' ''  '' '35' 'Cust.Description'     '' ' ' '' '', "#EC NOTEXT
   'ZZCORETYPE' '' '' '' '20' 'Core Type'         '' ' ' '' ''. "#EC NOTEXT

  " --------------------------
  " Field tambahan khusus ZPP016A
  " --------------------------
  " Start Add 22.09.2025 by Fiqih
*  IF SY-TCODE = 'ZPP016A'.
  PERFORM F_ALV_FIELDCATG_ICON_WT_ZERO USING 'IT_MSEG' :
  'ZZTAILORED'     '' ''  '' '30' 'Category'          '' ' ' '' '', "#EC NOTEXT
  'ZZLABEL'    '' ''  '' '30' 'Type Label'            '' ' ' '' '', "#EC NOTEXT
  'ZTYBGRADE'    '' ''  '' '15' 'Grade Toyobo'        '' ' ' '' '', "#EC NOTEXT
  'ZZNOROLLTOYOBO' '' ''  '' '15' 'No Roll Toyobo'    '' ' ' '' '', "#EC NOTEXT
  'ZZNOLOTTOYOBO'  '' ''  '' '15' 'No Lot Toyobo'     '' ' ' '' '', "#EC NOTEXT
  'ZZALIAS'  '' ''  '' '15' 'Type Alias'              '' ' ' '' '', "#EC NOTEXT
  " End Add 22.09.2025 by Fiqih

  " Start Add 22.09.2025 by Fiqih
  'NCHARG'     '' ''  '' '30' 'Final Batch'          '' ' ' '' '', "#EC NOTEXT
  'NOROLL2'    '' ''  '' '30' 'Final No Roll'        '' ' ' '' '', "#EC NOTEXT
  'GRADE2'    '' ''  '' '15' 'Final Grade'           '' ' ' '' '', "#EC NOTEXT
  'DCRITB'    '' ''  '' '15' 'Final Crit. Grade'     '' ' ' '' '', "#EC NOTEXT
  'NWEIGHT'    '' ''  '' '15' 'Final Qty'            '' ' ' '' '', "#EC NOTEXT
  'NWEIGHT_A'    '' ''  '' '20' 'Final Qty Actual'   '' ' ' '' ''. "#EC NOTEXT
  " End Add 22.09.2025 by Fiqih
*  ENDIF.

ENDFORM.                    " f_field_catalog

*&---------------------------------------------------------------------*
*&      Form  f_layout
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_LAYOUT .
  WA_LAYOUT-ZEBRA = 'X'.
  WA_LAYOUT-CONFIRMATION_PROMPT = 'X'.
  WA_LAYOUT-SUBTOTALS_TEXT = 'Sub Total'.                   "#EC NOTEXT
  WA_LAYOUT-TOTALS_TEXT = 'Total'.                          "#EC NOTEXT
  WA_LAYOUT-BOX_FIELDNAME = 'BOX'.
*  WA_LAYOUT-BOX_TABNAME = 'T_HEADER'.
*  WA_LAYOUT-EXPAND_FIELDNAME = 'EXPAND'.
*  wa_layout-expand_all = 'X'.
  WA_LAYOUT-CELL_MERGE = 'X'.
  WA_LAYOUT-COLWIDTH_OPTIMIZE = 'X'.
ENDFORM.                    " f_layout

*&---------------------------------------------------------------------*
*&      Form  f_list_detail
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_LIST_DETAIL .
  D_REPID = SY-REPID.
  T_PRINT-NO_PRINT_LISTINFOS = 'X'.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      I_CALLBACK_PROGRAM       = D_REPID
      I_CALLBACK_USER_COMMAND  = 'F_USER_COMMAND'
      I_CALLBACK_PF_STATUS_SET = 'F_GUI_STATUS'
      IS_LAYOUT                = WA_LAYOUT
      IT_FIELDCAT              = T_FIELDCAT[]
      IT_EVENTS                = T_EVENTS[]
      IT_EVENT_EXIT            = T_EVENT_EXIT[]
      I_DEFAULT                = 'X'
      I_SAVE                   = 'A'
      IS_VARIANT               = WA_VARIANTE
      IS_PRINT                 = T_PRINT
      IT_SORT                  = T_SORT[]
      IT_EXCLUDING             = T_EXCLUDING[]
      I_BYPASSING_BUFFER       = 'X'
    TABLES
      T_OUTTAB                 = IT_MSEG
    EXCEPTIONS
      PROGRAM_ERROR            = 1
      OTHERS                   = 2.

ENDFORM.                    " f_list_detail

*&---------------------------------------------------------------------
*&      Form  F_GUI_STATUS
*&---------------------------------------------------------------------
FORM F_GUI_STATUS USING FT_EXTAB TYPE SLIS_T_EXTAB.
  REFRESH FT_EXTAB.
  CLEAR FT_EXTAB.
  APPEND 'DETAIL' TO FT_EXTAB.

  SET PF-STATUS 'STANDARD_FULLSCREEN' EXCLUDING FT_EXTAB.
ENDFORM.                    " F_ALV_STATUS

*&---------------------------------------------------------------------*
*&      Form  F_USER_COMMAND
*&---------------------------------------------------------------------*
FORM F_USER_COMMAND USING FU_UCOMM LIKE SY-UCOMM
                          FU_SELFIELD TYPE SLIS_SELFIELD.
  DATA: LT_HUS TYPE HUM_VENUM_T.

  SY-LSIND = 0.
  CASE FU_UCOMM.
    WHEN '&IC1'.
      UNASSIGN <FS_MSEG>.
      READ TABLE IT_MSEG ASSIGNING <FS_MSEG> INDEX FU_SELFIELD-TABINDEX.
*******      CASE fu_selfield-sel_tab_field.
*******        WHEN 'IT_MSEG-CHARG'.
*******          IF <fs_mseg>-matnr ne '' AND <fs_mseg>-charg ne ''.
*******            SET PARAMETER ID 'MAT' FIELD <fs_mseg>-matnr.
*******            SET PARAMETER ID 'CHA' FIELD <fs_mseg>-charg.
*******            CALL TRANSACTION 'MSC3N' AND SKIP FIRST SCREEN. "#EC CI_CALLTA
*******          ENDIF.
*******        WHEN 'IT_MSEG-AUFNR'.
*******          IF <fs_mseg>-aufnr ne ''.
*******            SET PARAMETER ID 'BR1' FIELD <fs_mseg>-aufnr.
*******            CALL TRANSACTION 'COR3' AND SKIP FIRST SCREEN. "#EC CI_CALLTA
*******          ENDIF.
*******      ENDCASE.
      CASE FU_SELFIELD-FIELDNAME.
        WHEN 'CHARG'.
          IF <FS_MSEG>-MATNR NE '' AND <FS_MSEG>-CHARG NE ''.
            SET PARAMETER ID 'MAT' FIELD <FS_MSEG>-MATNR.
            SET PARAMETER ID 'CHA' FIELD <FS_MSEG>-CHARG.
            CALL TRANSACTION 'MSC3N' AND SKIP FIRST SCREEN. "#EC CI_CALLTA
          ENDIF.
*******        WHEN 'AUFNR'.
*******          IF <fs_mseg>-aufnr ne ''.
*******            SET PARAMETER ID 'BR1' FIELD <fs_mseg>-aufnr.
*******            CALL TRANSACTION 'COR3' AND SKIP FIRST SCREEN. "#EC CI_CALLTA
*******          ENDIF.
      ENDCASE.
    WHEN  'GRADE'.
      PERFORM COLLECT_DATA_GRADE.
      PERFORM DISPLAY_DATA_GRADE.
    WHEN  'SHIFT'.
      PERFORM COLLECT_DATA_SHIFT.
      PERFORM DISPLAY_DATA_SHIFT.
    WHEN  'SALES'.
      PERFORM SELECT_DATA_SALES.
      PERFORM WRITE_DATA_SALES.
    WHEN '&F12'.
      MESSAGE 'AHA' TYPE 'I'.
      CALL SCREEN 1000.

  ENDCASE.

*  fu_selfield-refresh = 'X'.

ENDFORM.                    "F_USER_COMMAND
*&---------------------------------------------------------------------*
*&      Form  COLLECT_DATA_GRADE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM COLLECT_DATA_GRADE .

  CLEAR: IT_CRIT, IT_MSEG2.
  REFRESH: IT_CRIT, IT_MSEG2.

  IT_MSEG2[] = IT_MSEG[].

  UNASSIGN <FS_MSEG2>.
  SORT IT_MSEG2 BY LINE CRIT ZZCODE GRADE.
  LOOP AT IT_MSEG2 ASSIGNING <FS_MSEG2>.
    IT_CRIT-LINE   = <FS_MSEG2>-LINE.
    IT_CRIT-ZZCODE = <FS_MSEG2>-ZZCODE.
    IT_CRIT-GRADE  = <FS_MSEG2>-GRADE.
    IT_CRIT-MENGE  = <FS_MSEG2>-MENGE.
    IT_CRIT-MEINS  = <FS_MSEG2>-MEINS.

    COLLECT IT_CRIT.
    CLEAR IT_CRIT.
  ENDLOOP.

ENDFORM.                    " COLLECT_DATA_GRADE
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_DATA_GRADE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DISPLAY_DATA_GRADE .
  CALL SCREEN 100 STARTING AT 10 01
                  ENDING   AT 75 24.
ENDFORM.                    " DISPLAY_DATA_GRADE
*&---------------------------------------------------------------------*
*&      Form  print_grade
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM PRINT_GRADE .
  DATA: BEGIN OF IT_DOWN OCCURS 10,
          LINE   LIKE  AUSP-ATWRT,
          ZZCODE LIKE  AUSP-ATWRT,
          GRADE  LIKE  AUSP-ATWRT,
          MENGE  LIKE  AUSP-ATWRT,
          MEINS  LIKE  MSEG-MEINS,
        END OF IT_DOWN.

  DATA : BEGIN OF IT_FIELDNAMES OCCURS 0,
           FIELD(30),
         END OF IT_FIELDNAMES.

  TABLES RLGRAP.
  DATA DEF_PATH LIKE RLGRAP-FILENAME.
  DATA: TMP_FILENAME LIKE RLGRAP-FILENAME.
  DATA V_FILENAME TYPE STRING.

  CLEAR IT_DOWN.
  REFRESH IT_DOWN.

  LOOP AT IT_CRIT.
    IT_DOWN-LINE   =  IT_CRIT-LINE.
    IT_DOWN-ZZCODE =  IT_CRIT-ZZCODE.
    IT_DOWN-GRADE  =  IT_CRIT-GRADE.
    WRITE IT_CRIT-MENGE TO IT_DOWN-MENGE DECIMALS 3.
    IT_DOWN-MEINS  =  IT_CRIT-MEINS.

    APPEND IT_DOWN.
    CLEAR IT_DOWN.
  ENDLOOP.

  REFRESH IT_FIELDNAMES.
  CLEAR IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Production Line'.                  "#EC NOTEXT

  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Type Film'.                        "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Grade Film'.                       "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Quantity'.                         "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'UoM'.                              "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  CALL FUNCTION 'WS_FILENAME_GET'
    EXPORTING
      DEF_FILENAME     = RLGRAP-FILENAME
      DEF_PATH         = DEF_PATH
*     MASK             = '*txt'
*     mask             = tmp_mask
*     mode             = mode
*     TITLE            = ' '
    IMPORTING
      FILENAME         = TMP_FILENAME
*     RC               =
    EXCEPTIONS
      INV_WINSYS       = 01
      NO_BATCH         = 02
      SELECTION_CANCEL = 03
      SELECTION_ERROR  = 04.

  IF SY-SUBRC = 0.
    RLGRAP-FILENAME = TMP_FILENAME.
  ELSE.
    EXIT.
  ENDIF.

  V_FILENAME = RLGRAP-FILENAME.

  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      FILENAME                = V_FILENAME
      FILETYPE                = 'DBF'
    TABLES
      DATA_TAB                = IT_DOWN
      FIELDNAMES              = IT_FIELDNAMES
    EXCEPTIONS
      FILE_WRITE_ERROR        = 1
      NO_BATCH                = 2
      GUI_REFUSE_FILETRANSFER = 3
      INVALID_TYPE            = 4
      NO_AUTHORITY            = 5
      UNKNOWN_ERROR           = 6
      HEADER_NOT_ALLOWED      = 7
      SEPARATOR_NOT_ALLOWED   = 8
      FILESIZE_NOT_ALLOWED    = 9
      HEADER_TOO_LONG         = 10
      DP_ERROR_CREATE         = 11
      DP_ERROR_SEND           = 12
      DP_ERROR_WRITE          = 13
      UNKNOWN_DP_ERROR        = 14
      ACCESS_DENIED           = 15
      DP_OUT_OF_MEMORY        = 16
      DISK_FULL               = 17
      DP_TIMEOUT              = 18
      FILE_NOT_FOUND          = 19
      DATAPROVIDER_EXCEPTION  = 20
      CONTROL_FLUSH_ERROR     = 21
      OTHERS                  = 22.

  IF SY-SUBRC <> 0.
    MESSAGE I000(0K) WITH 'Download error'.                 "#EC NOTEXT
    STOP.
  ENDIF.
ENDFORM.                    " print_grade

*----------------------------------------------------------------------*
*   INCLUDE TABLECONTROL_FORMS                                         *
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  USER_OK_TC                                               *
*&---------------------------------------------------------------------*
FORM USER_OK_TC USING    P_TC_NAME TYPE DYNFNAM
                         P_TABLE_NAME
                         P_MARK_NAME
                CHANGING P_OK      LIKE SY-UCOMM.

*&SPWIZARD: BEGIN OF LOCAL DATA----------------------------------------*
  DATA: L_OK              TYPE SY-UCOMM,
        L_OFFSET          TYPE I.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

*&SPWIZARD: Table control specific operations                          *
*&SPWIZARD: evaluate TC name and operations                            *
  SEARCH P_OK FOR P_TC_NAME.
  IF SY-SUBRC <> 0.
    EXIT.
  ENDIF.
  L_OFFSET = STRLEN( P_TC_NAME ) + 1.
  L_OK = P_OK+L_OFFSET.
*&SPWIZARD: execute general and TC specific operations                 *
  CASE L_OK.
    WHEN 'INSR'.                      "insert row
      PERFORM FCODE_INSERT_ROW USING    P_TC_NAME
                                        P_TABLE_NAME.
      CLEAR P_OK.

    WHEN 'DELE'.                      "delete row
      PERFORM FCODE_DELETE_ROW USING    P_TC_NAME
                                        P_TABLE_NAME
                                        P_MARK_NAME.
      CLEAR P_OK.

    WHEN 'P--' OR                     "top of list
         'P-'  OR                     "previous page
         'P+'  OR                     "next page
         'P++'.                       "bottom of list
      PERFORM COMPUTE_SCROLLING_IN_TC USING P_TC_NAME
                                            L_OK.
      CLEAR P_OK.
*     WHEN 'L--'.                       "total left
*       PERFORM FCODE_TOTAL_LEFT USING P_TC_NAME.
*
*     WHEN 'L-'.                        "column left
*       PERFORM FCODE_COLUMN_LEFT USING P_TC_NAME.
*
*     WHEN 'R+'.                        "column right
*       PERFORM FCODE_COLUMN_RIGHT USING P_TC_NAME.
*
*     WHEN 'R++'.                       "total right
*       PERFORM FCODE_TOTAL_RIGHT USING P_TC_NAME.
*
    WHEN 'MARK'.                      "mark all filled lines
      PERFORM FCODE_TC_MARK_LINES USING P_TC_NAME
                                        P_TABLE_NAME
                                        P_MARK_NAME   .
      CLEAR P_OK.

    WHEN 'DMRK'.                      "demark all filled lines
      PERFORM FCODE_TC_DEMARK_LINES USING P_TC_NAME
                                          P_TABLE_NAME
                                          P_MARK_NAME .
      CLEAR P_OK.

*     WHEN 'SASCEND'   OR
*          'SDESCEND'.                  "sort column
*       PERFORM FCODE_SORT_TC USING P_TC_NAME
*                                   l_ok.

  ENDCASE.

ENDFORM.                              " USER_OK_TC

*&---------------------------------------------------------------------*
*&      Form  FCODE_INSERT_ROW                                         *
*&---------------------------------------------------------------------*
FORM FCODE_INSERT_ROW
              USING    P_TC_NAME           TYPE DYNFNAM
                       P_TABLE_NAME             .

*&SPWIZARD: BEGIN OF LOCAL DATA----------------------------------------*
  DATA L_LINES_NAME       LIKE FELD-NAME.
  DATA L_SELLINE          LIKE SY-STEPL.
  DATA L_LASTLINE         TYPE I.
  DATA L_LINE             TYPE I.
  DATA L_TABLE_NAME       LIKE FELD-NAME.
  FIELD-SYMBOLS <TC>                 TYPE CXTAB_CONTROL.
  FIELD-SYMBOLS <TABLE>              TYPE STANDARD TABLE.
  FIELD-SYMBOLS <LINES>              TYPE I.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

  ASSIGN (P_TC_NAME) TO <TC>.

*&SPWIZARD: get the table, which belongs to the tc                     *
  CONCATENATE P_TABLE_NAME '[]' INTO L_TABLE_NAME. "table body
  ASSIGN (L_TABLE_NAME) TO <TABLE>.                "not headerline

*&SPWIZARD: get looplines of TableControl                              *
  CONCATENATE 'G_' P_TC_NAME '_LINES' INTO L_LINES_NAME.
  ASSIGN (L_LINES_NAME) TO <LINES>.

*&SPWIZARD: get current line                                           *
  GET CURSOR LINE L_SELLINE.
  IF SY-SUBRC <> 0.                   " append line to table
    L_SELLINE = <TC>-LINES + 1.
*&SPWIZARD: set top line                                               *
    IF L_SELLINE > <LINES>.
      <TC>-TOP_LINE = L_SELLINE - <LINES> + 1 .
    ELSE.
      <TC>-TOP_LINE = 1.
    ENDIF.
  ELSE.                               " insert line into table
    L_SELLINE = <TC>-TOP_LINE + L_SELLINE - 1.
    L_LASTLINE = <TC>-TOP_LINE + <LINES> - 1.
  ENDIF.
*&SPWIZARD: set new cursor line                                        *
  L_LINE = L_SELLINE - <TC>-TOP_LINE + 1.

*&SPWIZARD: insert initial line                                        *
  INSERT INITIAL LINE INTO <TABLE> INDEX L_SELLINE.
  <TC>-LINES = <TC>-LINES + 1.
*&SPWIZARD: set cursor                                                 *
  SET CURSOR LINE L_LINE.

ENDFORM.                              " FCODE_INSERT_ROW

*&---------------------------------------------------------------------*
*&      Form  FCODE_DELETE_ROW                                         *
*&---------------------------------------------------------------------*
FORM FCODE_DELETE_ROW
              USING    P_TC_NAME           TYPE DYNFNAM
                       P_TABLE_NAME
                       P_MARK_NAME   .

*&SPWIZARD: BEGIN OF LOCAL DATA----------------------------------------*
  DATA L_TABLE_NAME       LIKE FELD-NAME.

  FIELD-SYMBOLS <TC>         TYPE CXTAB_CONTROL.
  FIELD-SYMBOLS <TABLE>      TYPE STANDARD TABLE.
  FIELD-SYMBOLS <WA>.
  FIELD-SYMBOLS <MARK_FIELD>.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

  ASSIGN (P_TC_NAME) TO <TC>.

*&SPWIZARD: get the table, which belongs to the tc                     *
  CONCATENATE P_TABLE_NAME '[]' INTO L_TABLE_NAME. "table body
  ASSIGN (L_TABLE_NAME) TO <TABLE>.                "not headerline

*&SPWIZARD: delete marked lines                                        *
  DESCRIBE TABLE <TABLE> LINES <TC>-LINES.

  LOOP AT <TABLE> ASSIGNING <WA>.

*&SPWIZARD: access to the component 'FLAG' of the table header         *
    ASSIGN COMPONENT P_MARK_NAME OF STRUCTURE <WA> TO <MARK_FIELD>.

    IF <MARK_FIELD> = 'X'.
      DELETE <TABLE> INDEX SYST-TABIX.
      IF SY-SUBRC = 0.
        <TC>-LINES = <TC>-LINES - 1.
      ENDIF.
    ENDIF.
  ENDLOOP.

ENDFORM.                              " FCODE_DELETE_ROW

*&---------------------------------------------------------------------*
*&      Form  COMPUTE_SCROLLING_IN_TC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_TC_NAME  name of tablecontrol
*      -->P_OK       ok code
*----------------------------------------------------------------------*
FORM COMPUTE_SCROLLING_IN_TC USING    P_TC_NAME
                                      P_OK.
*&SPWIZARD: BEGIN OF LOCAL DATA----------------------------------------*
  DATA L_TC_NEW_TOP_LINE     TYPE I.
  DATA L_TC_NAME             LIKE FELD-NAME.
  DATA L_TC_LINES_NAME       LIKE FELD-NAME.
  DATA L_TC_FIELD_NAME       LIKE FELD-NAME.

  FIELD-SYMBOLS <TC>         TYPE CXTAB_CONTROL.
  FIELD-SYMBOLS <LINES>      TYPE I.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

  ASSIGN (P_TC_NAME) TO <TC>.
*&SPWIZARD: get looplines of TableControl                              *
  CONCATENATE 'G_' P_TC_NAME '_LINES' INTO L_TC_LINES_NAME.
  ASSIGN (L_TC_LINES_NAME) TO <LINES>.


*&SPWIZARD: is no line filled?                                         *
  IF <TC>-LINES = 0.
*&SPWIZARD: yes, ...                                                   *
    L_TC_NEW_TOP_LINE = 1.
  ELSE.
*&SPWIZARD: no, ...                                                    *
    CALL FUNCTION 'SCROLLING_IN_TABLE'
      EXPORTING
        ENTRY_ACT             = <TC>-TOP_LINE
        ENTRY_FROM            = 1
        ENTRY_TO              = <TC>-LINES
        LAST_PAGE_FULL        = 'X'
        LOOPS                 = <LINES>
        OK_CODE               = P_OK
        OVERLAPPING           = 'X'
      IMPORTING
        ENTRY_NEW             = L_TC_NEW_TOP_LINE
      EXCEPTIONS
*       NO_ENTRY_OR_PAGE_ACT  = 01
*       NO_ENTRY_TO           = 02
*       NO_OK_CODE_OR_PAGE_GO = 03
        OTHERS                = 0.
  ENDIF.

*&SPWIZARD: get actual tc and column                                   *
  GET CURSOR FIELD L_TC_FIELD_NAME
             AREA  L_TC_NAME.

  IF SYST-SUBRC = 0.
    IF L_TC_NAME = P_TC_NAME.
*&SPWIZARD: et actual column                                           *
      SET CURSOR FIELD L_TC_FIELD_NAME LINE 1.
    ENDIF.
  ENDIF.

*&SPWIZARD: set the new top line                                       *
  <TC>-TOP_LINE = L_TC_NEW_TOP_LINE.


ENDFORM.                              " COMPUTE_SCROLLING_IN_TC

*&---------------------------------------------------------------------*
*&      Form  FCODE_TC_MARK_LINES
*&---------------------------------------------------------------------*
*       marks all TableControl lines
*----------------------------------------------------------------------*
*      -->P_TC_NAME  name of tablecontrol
*----------------------------------------------------------------------*
FORM FCODE_TC_MARK_LINES USING P_TC_NAME
                               P_TABLE_NAME
                               P_MARK_NAME.
*&SPWIZARD: EGIN OF LOCAL DATA-----------------------------------------*
  DATA L_TABLE_NAME       LIKE FELD-NAME.

  FIELD-SYMBOLS <TC>         TYPE CXTAB_CONTROL.
  FIELD-SYMBOLS <TABLE>      TYPE STANDARD TABLE.
  FIELD-SYMBOLS <WA>.
  FIELD-SYMBOLS <MARK_FIELD>.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

  ASSIGN (P_TC_NAME) TO <TC>.

*&SPWIZARD: get the table, which belongs to the tc                     *
  CONCATENATE P_TABLE_NAME '[]' INTO L_TABLE_NAME. "table body
  ASSIGN (L_TABLE_NAME) TO <TABLE>.                "not headerline

*&SPWIZARD: mark all filled lines                                      *
  LOOP AT <TABLE> ASSIGNING <WA>.

*&SPWIZARD: access to the component 'FLAG' of the table header         *
    ASSIGN COMPONENT P_MARK_NAME OF STRUCTURE <WA> TO <MARK_FIELD>.

    <MARK_FIELD> = 'X'.
  ENDLOOP.
ENDFORM.                                          "fcode_tc_mark_lines

*&---------------------------------------------------------------------*
*&      Form  FCODE_TC_DEMARK_LINES
*&---------------------------------------------------------------------*
*       demarks all TableControl lines
*----------------------------------------------------------------------*
*      -->P_TC_NAME  name of tablecontrol
*----------------------------------------------------------------------*
FORM FCODE_TC_DEMARK_LINES USING P_TC_NAME
                                 P_TABLE_NAME
                                 P_MARK_NAME .
*&SPWIZARD: BEGIN OF LOCAL DATA----------------------------------------*
  DATA L_TABLE_NAME       LIKE FELD-NAME.

  FIELD-SYMBOLS <TC>         TYPE CXTAB_CONTROL.
  FIELD-SYMBOLS <TABLE>      TYPE STANDARD TABLE.
  FIELD-SYMBOLS <WA>.
  FIELD-SYMBOLS <MARK_FIELD>.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

  ASSIGN (P_TC_NAME) TO <TC>.

*&SPWIZARD: get the table, which belongs to the tc                     *
  CONCATENATE P_TABLE_NAME '[]' INTO L_TABLE_NAME. "table body
  ASSIGN (L_TABLE_NAME) TO <TABLE>.                "not headerline

*&SPWIZARD: demark all filled lines                                    *
  LOOP AT <TABLE> ASSIGNING <WA>.

*&SPWIZARD: access to the component 'FLAG' of the table header         *
    ASSIGN COMPONENT P_MARK_NAME OF STRUCTURE <WA> TO <MARK_FIELD>.

    <MARK_FIELD> = SPACE.
  ENDLOOP.
ENDFORM.                                          "fcode_tc_mark_lines
*&---------------------------------------------------------------------*
*&      Form  COLLECT_DATA_SHIFT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM COLLECT_DATA_SHIFT .

  CLEAR: IT_SHIFT, IT_MSEG2, V_ROLL1, V_ROLL2, V_ROLL3.
  REFRESH: IT_SHIFT, IT_MSEG2.

  IT_MSEG2[] = IT_MSEG[].

  DELETE IT_MSEG2 WHERE LINE EQ ''.

  UNASSIGN <FS_MSEG2>.
  SORT IT_MSEG2 BY LINE CRIT ZZCODE GRADE.
  LOOP AT IT_MSEG2 ASSIGNING <FS_MSEG2>.

    IT_SHIFT-LINE   = <FS_MSEG2>-LINE.
    IT_SHIFT-ARBPL  = <FS_MSEG2>-ARBPL.
    IT_SHIFT-MATNR  = <FS_MSEG2>-MATNR.
    IT_SHIFT-ZZCODE = <FS_MSEG2>-ZZCODE.
    IT_SHIFT-CRIT   = <FS_MSEG2>-CRIT.
    IT_SHIFT-GRADE  = <FS_MSEG2>-GRADE.
    CONDENSE <FS_MSEG2>-LENGTH NO-GAPS.
    IT_SHIFT-LENGTH = <FS_MSEG2>-LENGTH.
    CONDENSE <FS_MSEG2>-WIDTH NO-GAPS.
    IT_SHIFT-WIDTH  =  <FS_MSEG2>-WIDTH.
    IF <FS_MSEG2>-CPUTM >= '000000' AND <FS_MSEG2>-CPUTM <=  '065959'.
      IT_SHIFT-MENG1  = <FS_MSEG2>-MENGE.
*      v_roll1 = v_roll1 + 1.
*      it_shift-roll1  = v_roll1.
      IT_SHIFT-ROLL1  = 1.
    ELSEIF <FS_MSEG2>-CPUTM >= '070000' AND <FS_MSEG2>-CPUTM <=  '152959'.
      IT_SHIFT-MENG2  =  <FS_MSEG2>-MENGE.
*      v_roll2 = v_roll2 + 1.
*      it_shift-roll2  = v_roll2.
      IT_SHIFT-ROLL2  = 1.
    ELSEIF <FS_MSEG2>-CPUTM >= '153000' AND <FS_MSEG2>-CPUTM <=  '235959'.
      IT_SHIFT-MENG3  =  <FS_MSEG2>-MENGE.
*      v_roll3 = v_roll3 + 1.
*      it_shift-roll3  = v_roll3.
      IT_SHIFT-ROLL3  = 1.
    ENDIF.
    IT_SHIFT-TOTAL  =  IT_SHIFT-MENG1 + IT_SHIFT-MENG2 + IT_SHIFT-MENG3.
    IT_SHIFT-TROLL  =  IT_SHIFT-ROLL1 + IT_SHIFT-ROLL2 + IT_SHIFT-ROLL3.

    COLLECT IT_SHIFT.
    CLEAR IT_SHIFT.

  ENDLOOP.

****** modify by ALV
*****  delete it_shift where line eq ''.

ENDFORM.                    " COLLECT_DATA_SHIFT
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_DATA_SHIFT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DISPLAY_DATA_SHIFT .
  CALL SCREEN 200 STARTING AT 10 01
                  ENDING   AT 100 24.
ENDFORM.                    " DISPLAY_DATA_SHIFT

*&---------------------------------------------------------------------*
*&      Form  print_shift
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM PRINT_SHIFT .
  DATA: BEGIN OF IT_DOWN OCCURS 10,
          LINE   LIKE  AUSP-ATWRT,
          MATNR  LIKE  AUSP-ATWRT,
          ZZCODE LIKE  AUSP-ATWRT,
          CRIT   LIKE  AUSP-ATWRT,
          GRADE  LIKE  AUSP-ATWRT,
          LENGTH LIKE  AUSP-ATWRT,
          WIDTH  LIKE  AUSP-ATWRT,
          MENG1  LIKE  AUSP-ATWRT,
          ROLL1  LIKE  AUSP-ATWRT,
          MENG2  LIKE  AUSP-ATWRT,
          ROLL2  LIKE  AUSP-ATWRT,
          MENG3  LIKE  AUSP-ATWRT,
          ROLL3  LIKE  AUSP-ATWRT,
          TOTAL  LIKE  AUSP-ATWRT,
          TROLL  LIKE  AUSP-ATWRT,
          ARBPL  LIKE  AUSP-ATWRT,
        END OF IT_DOWN.

  DATA : BEGIN OF IT_FIELDNAMES OCCURS 0,
           FIELD(30),
         END OF IT_FIELDNAMES.

  DATA DEF_PATH LIKE RLGRAP-FILENAME.
  DATA: TMP_FILENAME LIKE RLGRAP-FILENAME.
  DATA V_FILENAME TYPE STRING.

  CLEAR IT_DOWN.
  REFRESH IT_DOWN.

  LOOP AT IT_SHIFT.
    IT_DOWN-LINE   =  IT_SHIFT-LINE.
    IT_DOWN-MATNR  =  IT_SHIFT-MATNR.
    IT_DOWN-ZZCODE =  IT_SHIFT-ZZCODE.
    IT_DOWN-CRIT   =  IT_SHIFT-CRIT.
    IT_DOWN-GRADE  =  IT_SHIFT-GRADE.
    IT_DOWN-LENGTH =  IT_SHIFT-LENGTH.
    IT_DOWN-WIDTH  =  IT_SHIFT-WIDTH.
    IT_DOWN-ARBPL  =  IT_SHIFT-ARBPL.
    WRITE IT_SHIFT-MENG1 TO IT_DOWN-MENG1 DECIMALS 3.
    WRITE IT_SHIFT-ROLL1 TO IT_DOWN-ROLL1 DECIMALS 3.
    WRITE IT_SHIFT-MENG2 TO IT_DOWN-MENG2 DECIMALS 3.
    WRITE IT_SHIFT-ROLL2 TO IT_DOWN-ROLL2 DECIMALS 3.
    WRITE IT_SHIFT-MENG3 TO IT_DOWN-MENG3 DECIMALS 3.
    WRITE IT_SHIFT-ROLL3 TO IT_DOWN-ROLL3 DECIMALS 3.
    WRITE IT_SHIFT-TOTAL TO IT_DOWN-TOTAL DECIMALS 3.
    WRITE IT_SHIFT-TROLL TO IT_DOWN-TROLL DECIMALS 3.

    APPEND IT_DOWN.
    CLEAR IT_DOWN.
  ENDLOOP.

  REFRESH IT_FIELDNAMES.
  CLEAR IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Production Line'.                  "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Material'.                         "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Type Film'.                        "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Criteria Film'.                    "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Grade Film'.                       "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Length'.                           "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Width'.                            "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Qty Shift 1'.                      "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Roll Shift 1'.                     "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Qty Shift 2'.                      "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Roll Shift 2'.                     "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Qty Shift 3'.                      "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Roll Shift 3'.                     "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Total'.                            "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Total Roll'.                       "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  CALL FUNCTION 'WS_FILENAME_GET'
    EXPORTING
      DEF_FILENAME     = RLGRAP-FILENAME
      DEF_PATH         = DEF_PATH
*     MASK             = '*txt'
*     mask             = tmp_mask
*     mode             = mode
*     TITLE            = ' '
    IMPORTING
      FILENAME         = TMP_FILENAME
*     RC               =
    EXCEPTIONS
      INV_WINSYS       = 01
      NO_BATCH         = 02
      SELECTION_CANCEL = 03
      SELECTION_ERROR  = 04.

  IF SY-SUBRC = 0.
    RLGRAP-FILENAME = TMP_FILENAME.
  ELSE.
    EXIT.
  ENDIF.

  V_FILENAME = RLGRAP-FILENAME.

  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      FILENAME                = V_FILENAME
      FILETYPE                = 'DBF'
*     MODE                    = ' '
*     write_field_separator   = 'X'
    TABLES
      DATA_TAB                = IT_DOWN
      FIELDNAMES              = IT_FIELDNAMES
    EXCEPTIONS
      FILE_WRITE_ERROR        = 1
      NO_BATCH                = 2
      GUI_REFUSE_FILETRANSFER = 3
      INVALID_TYPE            = 4
      NO_AUTHORITY            = 5
      UNKNOWN_ERROR           = 6
      HEADER_NOT_ALLOWED      = 7
      SEPARATOR_NOT_ALLOWED   = 8
      FILESIZE_NOT_ALLOWED    = 9
      HEADER_TOO_LONG         = 10
      DP_ERROR_CREATE         = 11
      DP_ERROR_SEND           = 12
      DP_ERROR_WRITE          = 13
      UNKNOWN_DP_ERROR        = 14
      ACCESS_DENIED           = 15
      DP_OUT_OF_MEMORY        = 16
      DISK_FULL               = 17
      DP_TIMEOUT              = 18
      FILE_NOT_FOUND          = 19
      DATAPROVIDER_EXCEPTION  = 20
      CONTROL_FLUSH_ERROR     = 21
      OTHERS                  = 22.

  IF SY-SUBRC <> 0.
    MESSAGE I000(0K) WITH 'Download error'.                 "#EC NOTEXT
    STOP.
  ENDIF.

ENDFORM.                    " print_shift
*&---------------------------------------------------------------------*
*&      Form  SELECT_DATA_SALES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SELECT_DATA_SALES .

  CLEAR: IT_MSEG2, IT_SALE, IT_DATS, IT_DATT.
  REFRESH: IT_MSEG2, IT_SALE, IT_DATS, IT_DATT.

  IT_MSEG2[] = IT_MSEG[].

  UNASSIGN <FS_MSEG2>.
  SORT IT_MSEG2 BY CHARG.

  LOOP AT IT_MSEG2 ASSIGNING <FS_MSEG2>.
    CLEAR: <FS_MSEG2>-BOX.
    MOVE-CORRESPONDING <FS_MSEG2> TO IT_SALE.
    IT_SALE-PCONV  =  <FS_MSEG2>-ZCONV.
    MOVE-CORRESPONDING <FS_MSEG2> TO IT_DATT.
    IF <FS_MSEG2>-CHARG NE SPACE.
      AT NEW CHARG.

        CLEAR IT_MSKA.
        REFRESH IT_MSKA.

        SELECT MATNR CHARG VBELN POSNR WERKS LGORT KALAB KASPE INTO TABLE IT_MSKA FROM MSKA WHERE MATNR = <FS_MSEG2>-MATNR AND
                                                                                                  CHARG = <FS_MSEG2>-CHARG.
      ENDAT.

      IF IT_MSKA[] IS NOT INITIAL.
        LOOP AT IT_MSKA WHERE KALAB <> 0 OR KASPE <> 0.
          IT_SALE-VBELN  =  IT_MSKA-VBELN.
          IT_SALE-POSNR  =  IT_MSKA-POSNR.

          SELECT SINGLE PERNR INTO VBPA-PERNR FROM VBPA WHERE VBELN = IT_SALE-VBELN AND PARVW = 'VE'.
          SELECT SINGLE ENAME INTO IT_SALE-ZNAME FROM PA0001 WHERE PERNR = VBPA-PERNR.

          SELECT SINGLE KUNNR INTO VBPA-KUNNR FROM VBPA WHERE VBELN = IT_SALE-VBELN AND PARVW = 'WE'.
          SELECT SINGLE NAME1 INTO IT_SALE-NAME1 FROM KNA1 WHERE KUNNR = VBPA-KUNNR.

          SELECT SINGLE KUNNR INTO VBPA-KUNNR FROM VBPA WHERE VBELN = IT_SALE-VBELN AND PARVW = 'AG'.
          SELECT SINGLE NAME1 INTO IT_SALE-NAME2 FROM KNA1 WHERE KUNNR = VBPA-KUNNR.

          IT_DATT-VBELN  =  IT_MSKA-VBELN.
          IT_DATT-POSNR  =  IT_MSKA-POSNR.
*          EXIT.
        ENDLOOP.

        IF SY-SUBRC <> 0.
          READ TABLE IT_MSKA WITH KEY WERKS = <FS_MSEG2>-WERKS
                                     LGORT = <FS_MSEG2>-LGORT.
          IF SY-SUBRC = 0.
            IT_SALE-VBELN  =  ''.
            IT_SALE-POSNR  =  ''.

            IF IT_SALE-VBELN NE ''.
              SELECT SINGLE PERNR INTO VBPA-PERNR FROM VBPA WHERE VBELN = IT_SALE-VBELN AND PARVW = 'VE'.
              SELECT SINGLE ENAME INTO IT_SALE-ZNAME FROM PA0001 WHERE PERNR = VBPA-PERNR.

              SELECT SINGLE KUNNR INTO VBPA-KUNNR FROM VBPA WHERE VBELN = IT_SALE-VBELN AND PARVW = 'WE'.
              SELECT SINGLE NAME1 INTO IT_SALE-NAME1 FROM KNA1 WHERE KUNNR = VBPA-KUNNR.

              SELECT SINGLE KUNNR INTO VBPA-KUNNR FROM VBPA WHERE VBELN = IT_SALE-VBELN AND PARVW = 'AG'.
              SELECT SINGLE NAME1 INTO IT_SALE-NAME2 FROM KNA1 WHERE KUNNR = VBPA-KUNNR.
            ENDIF.

            IT_DATT-VBELN  =  IT_MSKA-VBELN.
            IT_DATT-POSNR  =  IT_MSKA-POSNR.
          ENDIF.
        ENDIF.

      ENDIF.
    ENDIF.

    IF <FS_MSEG2>-CHARG NE ''.
      COLLECT IT_SALE.
    ENDIF.

    APPEND IT_DATT.
    CLEAR IT_DATT.
    CLEAR IT_SALE.

  ENDLOOP.

ENDFORM.                    " SELECT_DATA_SALES
*&---------------------------------------------------------------------*
*&      Form  WRITE_DATA_SALES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM WRITE_DATA_SALES .
  PERFORM F_FIELD_CATALOG_SALES.
  PERFORM F_LAYOUT_SALES.
  PERFORM F_LIST_DETAIL_SALES.
ENDFORM.                    " WRITE_DATA_SALES

*&---------------------------------------------------------------------*
*&      Form  f_field_catalog_sales
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_FIELD_CATALOG_SALES .
  REFRESH: T_FIELDCAT.
  PERFORM F_ALV_FIELDCATG_ICON USING 'IT_SALE' :
   'VBELN'  '' ''  '' '10' 'SO Number'      '' 'X' '' '',   "#EC NOTEXT
   'POSNR'  '' ''  '' '6'  'SO Item'        '' ' ' '' '',   "#EC NOTEXT
   'ZZCODE' '' ''  '' '10' 'Type Film'      '' ' ' '' '',   "#EC NOTEXT
   'WIDTH'  '' ''  '' '10' 'Width'          '' ' ' '' '',   "#EC NOTEXT
   'LENGTH' '' ''  '' '10' 'Length'         '' ' ' '' '',   "#EC NOTEXT
   'TREAT'  '' ''  '' '10' 'Treatment'      '' ' ' '' '',   "#EC NOTEXT
   'ZCONV'  '' ''  '' '10' 'Qty Produced'   '' ' ' '' '',   "#EC NOTEXT
   'ZNAME'  '' ''  '' '20' 'Sales Employee' '' ' ' '' '',   "#EC NOTEXT
   'NAME1'  '' ''  '' '20' 'Ship To Party'  '' ' ' '' '',   "#EC NOTEXT
   'LINE'   '' ''  '' '12' 'Prod. Line'  '' ' ' '' ''.      "#EC NOTEXT

ENDFORM.                    " f_field_catalog_sales


*&---------------------------------------------------------------------*
*&      Form  f_layout_sales
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_LAYOUT_SALES .
  CLEAR WA_LAYOUT.
  WA_LAYOUT-ZEBRA = 'X'.
  WA_LAYOUT-CONFIRMATION_PROMPT = 'X'.
  WA_LAYOUT-SUBTOTALS_TEXT = 'Sub Total'.                   "#EC NOTEXT
  WA_LAYOUT-TOTALS_TEXT = 'Total'.                          "#EC NOTEXT
  WA_LAYOUT-BOX_FIELDNAME = 'BOX'.
  WA_LAYOUT-CELL_MERGE = 'X'.
  WA_LAYOUT-COLWIDTH_OPTIMIZE = 'X'.
ENDFORM.                    " f_layout_sales


*&---------------------------------------------------------------------*
*&      Form  f_list_detail_sales
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_LIST_DETAIL_SALES .
  D_REPID = SY-REPID.
  T_PRINT-NO_PRINT_LISTINFOS = 'X'.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      I_CALLBACK_PROGRAM       = D_REPID
      I_CALLBACK_USER_COMMAND  = 'F_USER_COMMAND_SALES'
      I_CALLBACK_PF_STATUS_SET = 'F_GUI_STATUS_SALES'
      IS_LAYOUT                = WA_LAYOUT
      IT_FIELDCAT              = T_FIELDCAT[]
      IT_EVENTS                = T_EVENTS[]
      IT_EVENT_EXIT            = T_EVENT_EXIT[]
      I_DEFAULT                = 'X'
      I_SAVE                   = 'A'
      IS_VARIANT               = WA_VARIANTE
      IS_PRINT                 = T_PRINT
      IT_SORT                  = T_SORT[]
      IT_EXCLUDING             = T_EXCLUDING[]
      I_BYPASSING_BUFFER       = 'X'
    TABLES
      T_OUTTAB                 = IT_SALE
    EXCEPTIONS
      PROGRAM_ERROR            = 1
      OTHERS                   = 2.

ENDFORM.                    " f_list_detail_sales

*&---------------------------------------------------------------------
*&      Form  F_GUI_STATUS
*&---------------------------------------------------------------------
FORM F_GUI_STATUS_SALES USING FT_EXTAB TYPE SLIS_T_EXTAB.
  REFRESH FT_EXTAB.
  CLEAR FT_EXTAB.
  APPEND 'GRADE' TO FT_EXTAB.
  APPEND 'SALES' TO FT_EXTAB.
  APPEND 'SHIFT' TO FT_EXTAB.

  SET PF-STATUS 'STANDARD_FULLSCREEN' EXCLUDING FT_EXTAB.
ENDFORM.                    " F_ALV_STATUS

*&---------------------------------------------------------------------*
*&      Form  F_USER_COMMAND
*&---------------------------------------------------------------------*
FORM F_USER_COMMAND_SALES USING FU_UCOMM LIKE SY-UCOMM
                          FU_SELFIELD TYPE SLIS_SELFIELD.
  DATA: LT_HUS TYPE HUM_VENUM_T.

  SY-LSIND = 0.
  CASE FU_UCOMM.
    WHEN '&IC1'.
      READ TABLE IT_SALE INDEX FU_SELFIELD-TABINDEX.
      CASE FU_SELFIELD-SEL_TAB_FIELD.
        WHEN 'IT_SALE-VBELN'.
          IF IT_SALE-VBELN NE ''.
            SET PARAMETER ID 'AUN' FIELD IT_SALE-VBELN.
            CALL TRANSACTION 'VA03' AND SKIP FIRST SCREEN. "#EC CI_CALLTA
          ENDIF.
      ENDCASE.
    WHEN 'DETAIL'.
      READ TABLE IT_SALE WITH KEY BOX = 'X'.
      IF SY-SUBRC = 0.
        PERFORM SELECT_STOCK.
      ELSE.
*        MESSAGE i001(00) WITH 'Please select at least one line'. "#EC NOTEXT
        MESSAGE 'Please select at least one line' TYPE 'I'. "#EC NOTEXT
        EXIT.
      ENDIF.
  ENDCASE.

ENDFORM.                    "F_USER_COMMAND

*&---------------------------------------------------------------------*
*&      Form  select_stock
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SELECT_STOCK .
  CLEAR IT_DATS.
  REFRESH IT_DATS.

  LOOP AT IT_SALE WHERE BOX = 'X'.
    LOOP AT IT_DATT WHERE VBELN = IT_SALE-VBELN AND POSNR = IT_SALE-POSNR.
      MOVE-CORRESPONDING IT_DATT TO IT_DATS.
      CONDENSE IT_DATS-LENGTH NO-GAPS.
      CONDENSE IT_DATS-WIDTH  NO-GAPS.

      APPEND IT_DATS.
      CLEAR IT_DATS.
    ENDLOOP.
  ENDLOOP.

  CALL SCREEN 300 STARTING AT 10 01
                  ENDING   AT 75 24.

ENDFORM.                    " select_stock
*&---------------------------------------------------------------------*
*&      Form  DOWNLOAD_SALES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DOWNLOAD_SALES .

  DATA: BEGIN OF IT_DOWN OCCURS 10,
          VBELN  LIKE  VBAP-VBELN,
          POSNR  LIKE  VBAP-POSNR,
          MATNR  LIKE  VBAP-MATNR,
          CHARG  LIKE  MSEG-CHARG,
          MENGE  LIKE  AUSP-ATWRT,
          MEINS  LIKE  MSEG-MEINS,
          BUDAT  LIKE  MKPF-BUDAT,
          CPUTM  LIKE  MKPF-CPUTM,
          THICK  LIKE  AUSP-ATWRT,
          ZZCODE LIKE  AUSP-ATWRT,
          WIDTH  LIKE  AUSP-ATWRT,
          LENGTH LIKE  AUSP-ATWRT,
          NOROLL LIKE  CAWN-ATWRT,
        END OF IT_DOWN.

  DATA : BEGIN OF IT_FIELDNAMES OCCURS 0,
           FIELD(30),
         END OF IT_FIELDNAMES.

  DATA DEF_PATH LIKE RLGRAP-FILENAME.
  DATA: TMP_FILENAME LIKE RLGRAP-FILENAME.
  DATA V_FILENAME TYPE STRING.
  DATA: VMESS TYPE STRING.

  CLEAR IT_DOWN.
  REFRESH IT_DOWN.

  UNASSIGN <FS_MSEG>.
*  LOOP AT it_mseg ASSIGNING <fs_mseg>.
  LOOP AT IT_DATS ASSIGNING <FS_MSEG>.
    CLEAR: VMESS.
    IT_DOWN-VBELN  = <FS_MSEG>-VBELN.
    IT_DOWN-POSNR  = <FS_MSEG>-POSNR.
    IT_DOWN-MATNR  = <FS_MSEG>-MATNR.
    IT_DOWN-CHARG  = <FS_MSEG>-CHARG.
    WRITE <FS_MSEG>-MENGE TO IT_DOWN-MENGE EXPONENT 0 DECIMALS 3.
    IT_DOWN-MEINS  = <FS_MSEG>-MEINS.
    IT_DOWN-BUDAT  = <FS_MSEG>-BUDAT.
    IT_DOWN-CPUTM  = <FS_MSEG>-CPUTM.
*    it_down-zzcode = <fs_mseg>-zzcode.
    FIND '-' IN <FS_MSEG>-ZZCODE.
    IF SY-SUBRC = 0.
      SPLIT <FS_MSEG>-ZZCODE AT '-' INTO IT_DOWN-THICK IT_DOWN-ZZCODE.
    ELSE.
      IT_DOWN-ZZCODE  = <FS_MSEG>-ZZCODE.
    ENDIF.
    IT_DOWN-WIDTH  = <FS_MSEG>-WIDTH.
    IT_DOWN-LENGTH = <FS_MSEG>-LENGTH.
    IT_DOWN-NOROLL = <FS_MSEG>-NOROLL.

    APPEND IT_DOWN.
    CLEAR IT_DOWN.
  ENDLOOP.

  REFRESH IT_FIELDNAMES.
  CLEAR IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'SO Number'.                        "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'SO Item'.                          "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Material'.                         "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Batch Number'.                     "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Qty'.                              "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'UoM'.                              "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Prod.Date'.                        "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Prod.Time'.                        "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Type Film'.                        "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Thickness'.                        "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Width'.                            "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Length'.                           "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  IT_FIELDNAMES-FIELD = 'Roll Number'.                      "#EC NOTEXT
  APPEND IT_FIELDNAMES.

  CALL FUNCTION 'WS_FILENAME_GET'
    EXPORTING
      DEF_FILENAME     = RLGRAP-FILENAME
      DEF_PATH         = DEF_PATH
    IMPORTING
      FILENAME         = TMP_FILENAME
    EXCEPTIONS
      INV_WINSYS       = 01
      NO_BATCH         = 02
      SELECTION_CANCEL = 03
      SELECTION_ERROR  = 04.

  IF SY-SUBRC = 0.
    RLGRAP-FILENAME = TMP_FILENAME.
  ELSE.
    EXIT.
  ENDIF.

  V_FILENAME = RLGRAP-FILENAME.

  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      FILENAME                = V_FILENAME
      FILETYPE                = 'DBF'
    TABLES
      DATA_TAB                = IT_DOWN
      FIELDNAMES              = IT_FIELDNAMES
    EXCEPTIONS
      FILE_WRITE_ERROR        = 1
      NO_BATCH                = 2
      GUI_REFUSE_FILETRANSFER = 3
      INVALID_TYPE            = 4
      NO_AUTHORITY            = 5
      UNKNOWN_ERROR           = 6
      HEADER_NOT_ALLOWED      = 7
      SEPARATOR_NOT_ALLOWED   = 8
      FILESIZE_NOT_ALLOWED    = 9
      HEADER_TOO_LONG         = 10
      DP_ERROR_CREATE         = 11
      DP_ERROR_SEND           = 12
      DP_ERROR_WRITE          = 13
      UNKNOWN_DP_ERROR        = 14
      ACCESS_DENIED           = 15
      DP_OUT_OF_MEMORY        = 16
      DISK_FULL               = 17
      DP_TIMEOUT              = 18
      FILE_NOT_FOUND          = 19
      DATAPROVIDER_EXCEPTION  = 20
      CONTROL_FLUSH_ERROR     = 21
      OTHERS                  = 22.

  IF SY-SUBRC <> 0.
    MESSAGE I000(0K) WITH 'Download error'.                 "#EC NOTEXT
    STOP.
  ENDIF.

ENDFORM.                    " DOWNLOAD_SALES
*&---------------------------------------------------------------------*
*&      Form  WRITE_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM WRITE_DATA .

  DATA : V_THICK  TYPE STRING,
         V_THICK2 TYPE I,
         V_PDATE  TYPE CHAR10.
  DATA:  V_NAME1 LIKE KNA1-NAME1,
         V_VBELN LIKE VBAP-VBELN.

  EXEC SQL.
    CONNECT TO 'TRIASDB04' AS 'DBTRIAL'
  ENDEXEC.

  EXEC SQL.
    SET CONNECTION 'DBTRIAL'
  ENDEXEC.

  EXEC SQL.
    DELETE FROM XSR_MPAGI
  ENDEXEC.

** -- bagus
  EXEC SQL.
    COMMIT WORK
  ENDEXEC.
*
  UNASSIGN <FS_MSEG>.
  SORT IT_MSEG BY VBELN POSNR.
  LOOP AT IT_MSEG ASSIGNING <FS_MSEG>.
    CLEAR: V_THICK, V_PDATE.
    FIND '-' IN <FS_MSEG>-ZZCODE.
    IF SY-SUBRC = 0.
      SPLIT <FS_MSEG>-ZZCODE AT '-' INTO <FS_MSEG>-ZZCODE V_THICK.
      V_THICK2 = V_THICK.
    ENDIF.
    CONCATENATE <FS_MSEG>-BUDAT+6(2) '/' <FS_MSEG>-BUDAT+4(2) '/' <FS_MSEG>-BUDAT+0(4) INTO V_PDATE.
    CONDENSE V_PDATE NO-GAPS.
*- get name1
    IF <FS_MSEG>-VBELN NE V_VBELN.
      CLEAR V_NAME1.
      SELECT SINGLE B~NAME1 INTO V_NAME1
        FROM VBPA AS A JOIN ADRC AS B ON A~ADRNR = B~ADDRNUMBER
       WHERE A~VBELN = <FS_MSEG>-VBELN AND A~PARVW = 'SP'.
      IF SY-SUBRC NE 0.
        SELECT SINGLE NAME1 INTO V_NAME1
          FROM VBPA AS A JOIN KNA1 AS B ON A~KUNNR = B~KUNNR
          WHERE A~VBELN = <FS_MSEG>-VBELN.
      ENDIF.
    ENDIF.

*    <FS_MSEG>-PCKNG = V_NAME1.
    V_VBELN = <FS_MSEG>-VBELN.
*- end get name1

    "ADDED BY FATHIR ON 29.05.2020
    " extend program runtime
    CALL FUNCTION 'TH_REDISPATCH'
      EXPORTING
        CHECK_RUNTIME = 0.

    "Modified by J. Budi on 07.05.2020 for add Column for Olap Report
    "Modified by William at 20.10.2020 (Fixing data to download to SQL)
    EXEC SQL.
      INSERT INTO XSR_MPAGI(COL001,COL002,COL003,COL004,COL005,COL006,COL007,COL008,COL009,COL010,COL011,COL012,COL013,COL014,COL015,
                            COL016,COL017,COL018,COL019,COL020,COL021,COL022,COL023,COL024,COL025,COL026,COL027,COL028,COL029,COL030,COL031,COL032,COL033)
      VALUES(:V_PDATE,:<FS_MSEG>-CPUTM,:<FS_MSEG>-LINE,:<FS_MSEG>-WERKS,:<FS_MSEG>-LGORT,:<FS_MSEG>-MATNR,
             :<FS_MSEG>-LENGTH,:<FS_MSEG>-WIDTH,:<FS_MSEG>-MENGE,:<FS_MSEG>-GRADE,:<FS_MSEG>-ZZCODE,:V_THICK2,
             :<FS_MSEG>-NOROLL,:<FS_MSEG>-CHARG,:<FS_MSEG>-ZEXTRA,:<FS_MSEG>-KDAUF2,:<FS_MSEG>-KDPOS2, :<FS_MSEG>-NAME1,
             :<FS_MSEG>-ARBPL,:<FS_MSEG>-AUFNR,:<FS_MSEG>-TREAT,:<FS_MSEG>-PCKNG,:<FS_MSEG>-CRIT,:<FS_MSEG>-MEINS,
             :<FS_MSEG>-V_LASTGRADE,:<FS_MSEG>-V_LASTCRIT,:<FS_MSEG>-V_LASTQTY, :<FS_MSEG>-NCHARG, :<FS_MSEG>-NOROLL2,
             :<FS_MSEG>-GRADE2, :<FS_MSEG>-DCRITB, :<FS_MSEG>-NWEIGHT, :<FS_MSEG>-NWEIGHT_A)
    ENDEXEC.
  ENDLOOP.

  MESSAGE 'Penyimpanan Data ke SQL sukses!!!' TYPE 'I'.

ENDFORM.                    " WRITE_DATA


*&---------------------------------------------------------------------*
*&      Form  fill_so
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM FILL_SO.
  LOOP AT IT_MSEG ASSIGNING <FS_MSEG>.
    "ADDED BY FATHIR ON 29.05.2020
    " extend program runtime
    CALL FUNCTION 'TH_REDISPATCH'
      EXPORTING
        CHECK_RUNTIME = 0.

*    CLEAR <FS_MSEG>-PCKNG.   "clear to fill with customer name
    SELECT SINGLE KDAUF KDPOS
      INTO (<FS_MSEG>-VBELN, <FS_MSEG>-POSNR)
      FROM AFPO
      WHERE AUFNR = <FS_MSEG>-AUFNR.
  ENDLOOP.
ENDFORM.   "fill_so.

*&---------------------------------------------------------------------*
*&      Form  GET_STOCK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM GET_STOCK.
  CLEAR: IT_STOCK.
  REFRESH: IT_STOCK.

  SELECT DISTINCT MATNR WERKS LGORT CHARG
                  CLABS AS LABST "Unrestricted
                  CINSM AS INSME "In Qual. Insp.
                  CEINM AS EINME "Restricted-Use
                  CSPEM AS SPEME "Blocked
   INTO CORRESPONDING FIELDS OF TABLE IT_STOCK
   FROM MCHB
   FOR ALL ENTRIES IN IT_MSEG
   WHERE MATNR EQ IT_MSEG-MATNR AND
         WERKS EQ IT_MSEG-WERKS AND
         CHARG EQ IT_MSEG-CHARG AND
         ( CLABS > 0 OR CINSM > 0 OR CEINM > 0 OR CSPEM > 0 ).

  SELECT DISTINCT MATNR WERKS LGORT CHARG
                  KALAB AS LABST "Unrestricted
                  KAINS AS INSME "In Qual. Insp.
                  KAEIN AS EINME "Restricted-Use
                  KASPE AS SPEME "Blocked
  APPENDING CORRESPONDING FIELDS OF TABLE IT_STOCK
  FROM MSKA
  FOR ALL ENTRIES IN IT_MSEG
  WHERE MATNR EQ IT_MSEG-MATNR AND
        WERKS EQ IT_MSEG-WERKS AND
        CHARG EQ IT_MSEG-CHARG AND
        CHARG NE '' AND
        ( KALAB > 0 OR KAINS > 0 OR KAEIN > 0 OR KASPE > 0 ).

  SELECT DISTINCT MATNR WERKS CHARG
                  LBLAB AS LABST "Unrestricted
                  LBINS AS INSME "In Qual. Insp.
                  LBEIN AS EINME "Restricted-Use
  APPENDING CORRESPONDING FIELDS OF TABLE IT_STOCK
  FROM MSLB
  FOR ALL ENTRIES IN IT_MSEG
  WHERE MATNR EQ IT_MSEG-MATNR AND
        WERKS EQ IT_MSEG-WERKS AND
        CHARG EQ IT_MSEG-CHARG AND
        ( LBLAB > 0 OR LBINS > 0 OR LBEIN > 0 ).

  SELECT DISTINCT MATNR WERKS CHARG
                  KULAB AS LABST
                  KUINS AS INSME
                  KUEIN AS EINME
  APPENDING CORRESPONDING FIELDS OF TABLE IT_STOCK
  FROM MSKU
  FOR ALL ENTRIES IN IT_MSEG
  WHERE MATNR EQ IT_MSEG-MATNR AND
        WERKS EQ IT_MSEG-WERKS AND
        CHARG EQ IT_MSEG-CHARG AND
        ( KULAB > 0 OR KUINS > 0 OR KUEIN > 0 ).

  DELETE IT_STOCK WHERE LABST EQ 0 AND INSME EQ 0 AND EINME EQ 0 AND SPEME EQ 0.

ENDFORM.                    "GET_STOCK

*&---------------------------------------------------------------------*
*&      Form  GET_STOCK_FINAL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM GET_STOCK_FINAL.
  CLEAR: IT_STOCK_FINAL.
  REFRESH: IT_STOCK_FINAL.

  SELECT DISTINCT MATNR WERKS LGORT CHARG
                  CLABS AS LABST "Unrestricted
                  CINSM AS INSME "In Qual. Insp.
                  CEINM AS EINME "Restricted-Use
                  CSPEM AS SPEME "Blocked
   INTO CORRESPONDING FIELDS OF TABLE IT_STOCK_FINAL
   FROM MCHB
   FOR ALL ENTRIES IN IT_ZBATCHISTORY
   WHERE MATNR EQ IT_ZBATCHISTORY-MATNR AND
         WERKS EQ IT_ZBATCHISTORY-WERKS AND
         CHARG EQ IT_ZBATCHISTORY-NCHARG AND
         ( CLABS > 0 OR CINSM > 0 OR CEINM > 0 OR CSPEM > 0 ).

  SELECT DISTINCT MATNR WERKS LGORT CHARG
                  KALAB AS LABST "Unrestricted
                  KAINS AS INSME "In Qual. Insp.
                  KAEIN AS EINME "Restricted-Use
                  KASPE AS SPEME "Blocked
  APPENDING CORRESPONDING FIELDS OF TABLE IT_STOCK_FINAL
  FROM MSKA
  FOR ALL ENTRIES IN IT_ZBATCHISTORY
  WHERE MATNR EQ IT_ZBATCHISTORY-MATNR AND
        WERKS EQ IT_ZBATCHISTORY-WERKS AND
        CHARG EQ IT_ZBATCHISTORY-NCHARG AND
        CHARG NE '' AND
        ( KALAB > 0 OR KAINS > 0 OR KAEIN > 0 OR KASPE > 0 ).

  SELECT DISTINCT MATNR WERKS CHARG
                  LBLAB AS LABST "Unrestricted
                  LBINS AS INSME "In Qual. Insp.
                  LBEIN AS EINME "Restricted-Use
  APPENDING CORRESPONDING FIELDS OF TABLE IT_STOCK_FINAL
  FROM MSLB
  FOR ALL ENTRIES IN IT_ZBATCHISTORY
  WHERE MATNR EQ IT_ZBATCHISTORY-MATNR AND
        WERKS EQ IT_ZBATCHISTORY-WERKS AND
        CHARG EQ IT_ZBATCHISTORY-NCHARG AND
        ( LBLAB > 0 OR LBINS > 0 OR LBEIN > 0 ).

  SELECT DISTINCT MATNR WERKS CHARG
                  KULAB AS LABST
                  KUINS AS INSME
                  KUEIN AS EINME
  APPENDING CORRESPONDING FIELDS OF TABLE IT_STOCK_FINAL
  FROM MSKU
  FOR ALL ENTRIES IN IT_ZBATCHISTORY
  WHERE MATNR EQ IT_ZBATCHISTORY-MATNR AND
        WERKS EQ IT_ZBATCHISTORY-WERKS AND
        CHARG EQ IT_ZBATCHISTORY-NCHARG AND
        ( KULAB > 0 OR KUINS > 0 OR KUEIN > 0 ).

  DELETE IT_STOCK_FINAL WHERE LABST EQ 0 AND INSME EQ 0 AND EINME EQ 0 AND SPEME EQ 0.

ENDFORM.                    "GET_STOCK

*&---------------------------------------------------------------------*
*&      Form  F_GETORDERMTM
*&---------------------------------------------------------------------*
*       ADDED BY FATHIR ON 29.05.2020
*       Get data Order untuk transaksi Transfer Mat FGS to Mat FGS
*----------------------------------------------------------------------*
*      -->P_DATE     text
*----------------------------------------------------------------------*
FORM F_GETORDER_MTM TABLES P_DATE LIKE R_DATE[].
  DATA: V_AUFNR LIKE AUFK-AUFNR.

  SELECT AUFNR AS LOW
    INTO CORRESPONDING FIELDS OF TABLE R_AUFNR
    FROM AUFK
    WHERE ERDAT IN P_DATE
      AND AUFK~AUART IN V_AUARTTR %_HINTS ORACLE 'INDEX("AUFK" "AUFK~Z03")'.

  IF SY-SUBRC = 0.
    R_AUFNR-SIGN = 'I'.
    R_AUFNR-OPTION = 'EQ'.
    MODIFY R_AUFNR TRANSPORTING SIGN OPTION WHERE SIGN = ''.
  ENDIF.

  SORT R_AUFNR BY LOW ASCENDING.

ENDFORM.                    "F_GETORDERMTM

*&---------------------------------------------------------------------*
*&      Form  F_GETGRNMTM
*&---------------------------------------------------------------------*
*       ADDED BY FATHIR ON 29.05.2020
*       Get data GRN untuk transaksi Transfer Mat FGS to Mat FGS
*----------------------------------------------------------------------*
*      -->P_AUFK     text
*      -->P_DATE     text
*----------------------------------------------------------------------*
FORM F_GETGRN_MTM TABLES P_AUFNR LIKE R_AUFNR[]
                         P_MATNO LIKE R_MATNO[]
                         P_DATE LIKE R_DATE[].

  "ADDED BY FATHIR ON 04.06.2020
  " definisi variabel temporary
  DATA: IT_TMSEG TYPE STANDARD TABLE OF TY_MSEG WITH HEADER LINE,     " GRN 531
        IT_TREVMSEG TYPE STANDARD TABLE OF TY_MSEG WITH HEADER LINE,  " GRN 532 - temp
        IT_REVMSEG TYPE STANDARD TABLE OF TY_MSEG WITH HEADER LINE.   " GRN 532

  " jika Order tidak kosong, maka cari GRN Transfer Mat FGS to Mat FGS
  IF P_AUFNR[] IS NOT INITIAL.

    "CHANGED BY FATHIR ON 04.06.2020
    " cacah pencarian GRN 531 per hari
    LOOP AT P_DATE.

      " get GRN 531 (Transfer Mat FGS to Mat FGS)
      REFRESH: IT_TMSEG.
      SELECT MSEG~MBLNR MSEG~MJAHR MSEG~ZEILE MSEG~SMBLN MSEG~SMBLP MSEG~BWART
         MSEG~MATNR MSEG~CHARG MSEG~WERKS MSEG~LGORT MSEG~MENGE MSEG~MEINS
         MSEG~AUFNR MSEG~KDAUF MSEG~KDPOS MSEG~ABLAD MSEG~BUDAT_MKPF AS BUDAT
         MKPF~CPUTM MKPF~XABLN AS ARBPL
        INTO CORRESPONDING FIELDS OF TABLE IT_TMSEG
        FROM MKPF JOIN MSEG ON MKPF~MBLNR = MSEG~MBLNR AND MKPF~MJAHR = MSEG~MJAHR
        WHERE MSEG~MANDT = SY-MANDT AND MSEG~BWART = '531' AND
              MSEG~AUFNR IN P_AUFNR AND MSEG~MATNR IN P_MATNO AND
              MSEG~BUDAT_MKPF = P_DATE-LOW AND MSEG~CHARG <> ''.

      IF SY-SUBRC = 0.

        " filter GRN 531 berdasarkan input Plant
        SORT IT_TMSEG BY WERKS ASCENDING.
        DELETE IT_TMSEG WHERE WERKS NOT IN WERKS.

        " filter GRN 531 berdasarkan input Batch
        SORT IT_TMSEG BY CHARG ASCENDING.
        DELETE IT_TMSEG WHERE CHARG NOT IN ZCHARG.

        IF IT_TMSEG[] IS NOT INITIAL.
          " append GRN 531 dari temp ITAB ke IT_MSEG3
          APPEND LINES OF IT_TMSEG TO IT_MSEG3.

          " get GRN 532 (Transfer Mat FGS to Mat FGS)
          REFRESH: IT_TREVMSEG.
          SELECT MSEG~MBLNR MSEG~MJAHR MSEG~ZEILE MSEG~SMBLN MSEG~SMBLP MSEG~BWART
             MSEG~MATNR MSEG~CHARG MSEG~WERKS MSEG~LGORT MSEG~MENGE MSEG~MEINS
             MSEG~AUFNR MSEG~KDAUF MSEG~KDPOS MSEG~ABLAD MSEG~BUDAT_MKPF AS BUDAT
            INTO CORRESPONDING FIELDS OF TABLE IT_TREVMSEG
            FROM MSEG
            FOR ALL ENTRIES IN IT_TMSEG
            WHERE MSEG~BWART = '532' AND MSEG~MANDT = SY-MANDT AND
                  MSEG~SMBLN = IT_TMSEG-MBLNR AND MSEG~SJAHR = IT_TMSEG-MJAHR AND
                  MSEG~SMBLP = IT_TMSEG-ZEILE AND MSEG~WERKS = IT_TMSEG-WERKS AND
                  MSEG~MATNR = IT_TMSEG-MATNR AND MSEG~CHARG = IT_TMSEG-CHARG AND
                  MSEG~AUFNR = IT_TMSEG-AUFNR.

          IF SY-SUBRC = 0.
            APPEND LINES OF IT_TREVMSEG TO IT_REVMSEG.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.

  ENDIF.

  " jika data GRN ditemukan
  IF IT_MSEG3 IS NOT INITIAL.
    SORT IT_MSEG3 BY MBLNR ASCENDING.
    SORT IT_REVMSEG BY SMBLN ASCENDING.

    " hapus GRN yang sudah ter-cancel
    LOOP AT IT_REVMSEG.
      DELETE IT_MSEG3 WHERE MBLNR = IT_REVMSEG-SMBLN.
    ENDLOOP.

    " tambah data GRN ke tabel display
    APPEND LINES OF IT_MSEG3 TO IT_MSEG.
    SORT IT_MSEG BY MBLNR MJAHR ZEILE ASCENDING.
  ENDIF.

ENDFORM.                    "F_GETGRNMTM

*&---------------------------------------------------------------------*
*&      Form  F_GETSO
*&---------------------------------------------------------------------*
*       ADDED BY FATHIR ON 06.05.2020
*       Get SO untuk setiap batch
*----------------------------------------------------------------------*
FORM F_GETSO.
  RANGES: R_BUDAT FOR MKPF-BUDAT.
  DATA: V_BUDAT_LOW LIKE P0001-BEGDA,
        V_BUDAT_HIGH LIKE P0001-BEGDA.
  DATA: WA_MSEG2 TYPE TY_MSEG.
  REFRESH: R_CHARG, IT_MSEG2.
  CLEAR: R_CHARG, IT_MSEG2.

  " Isi range Posting Date
  IF BUDAT-HIGH IS NOT INITIAL.

    V_BUDAT_LOW = BUDAT-LOW.
    V_BUDAT_HIGH = BUDAT-HIGH.

    CLEAR : R_BUDAT.
    R_BUDAT-SIGN = 'I'.
    R_BUDAT-OPTION = 'EQ'.
    R_BUDAT-LOW = V_BUDAT_LOW.
    APPEND R_BUDAT.
    CLEAR : R_BUDAT.

    WHILE V_BUDAT_LOW < V_BUDAT_HIGH.
      V_BUDAT_LOW = V_BUDAT_LOW + 1.

      R_BUDAT-SIGN = 'I'.
      R_BUDAT-OPTION = 'EQ'.
      R_BUDAT-LOW = V_BUDAT_LOW.
      APPEND R_BUDAT.
      CLEAR : R_BUDAT.
    ENDWHILE.
  ELSE.
    R_BUDAT[] = BUDAT[].
  ENDIF.

  "CHANGED BY FATHIR ON 04.06.2020
  " Isi Range batch dengan batch GR 101
  SORT IT_MSEG BY BWART ASCENDING.
  " isi itab untuk menampung batch GRN 101
  REFRESH: IT_CHARG.
  UNASSIGN <FS_MSEG>.
  LOOP AT IT_MSEG ASSIGNING <FS_MSEG> WHERE BWART = '101'.
    APPEND <FS_MSEG> TO IT_CHARG.
  ENDLOOP.

  "CHANGED BY FATHIR ON 18.05.2020
  " cari SO untuk batch GR 101 saja
  IF IT_CHARG[] IS NOT INITIAL.
    "CHANGED BY FATHIR ON 04.06.2020
    " Get SO untuk setiap batch dari transaksi SO-to-SO / SO-to-Free (per 5000 batch)
    PERFORM F_PARSESOEXE TABLES IT_CHARG.

    " Hapus matdoc yang tercancel
    " untuk SO-to-SO
    SORT IT_MSEG2 BY BWART DESCENDING.
    UNASSIGN <FS_MSEG>.
    LOOP AT IT_MSEG2 ASSIGNING <FS_MSEG> WHERE BWART = '414'.
      DELETE IT_MSEG2 WHERE MBLNR = <FS_MSEG>-SMBLN AND BWART = '413'.
    ENDLOOP.

    " Hapus matdoc yang tercancel
    " untuk SO-to-Free
    SORT IT_MSEG2 BY BWART DESCENDING.
    UNASSIGN <FS_MSEG>.
    LOOP AT IT_MSEG2 ASSIGNING <FS_MSEG> WHERE BWART = '412'.
      DELETE IT_MSEG2 WHERE MBLNR = <FS_MSEG>-SMBLN AND BWART = '411'.
    ENDLOOP.

    " Delete matdoc cancel
    DELETE IT_MSEG2 WHERE BWART = '412' OR BWART = '414'.

    " Filter data Debit/Credit = S dan XAUTO = X
    SORT IT_MSEG2 BY BWART DESCENDING.
    DELETE IT_MSEG2 WHERE BWART = '413' AND SHKZG <> 'S' AND XAUTO <> 'X'.
    DELETE IT_MSEG2 WHERE BWART = '411' AND SHKZG <> 'S' AND XAUTO <> 'X'.

  ENDIF.

  " Set sales order untuk setiap batch
  SORT IT_MSEG BY BWART ASCENDING.    "ADDED BY FATHIR ON 15.05.2020
  UNASSIGN <FS_MSEG>.
  LOOP AT IT_MSEG ASSIGNING <FS_MSEG> WHERE BWART = '101'.    "CHANGED BY FATHIR ON 15.05.2020
    " Get SO default
    SELECT SINGLE MAT_KDAUF MAT_KDPOS
      INTO (<FS_MSEG>-KDAUF2, <FS_MSEG>-KDPOS2)
      FROM MSEG
      WHERE MBLNR EQ <FS_MSEG>-MBLNR
        AND CHARG EQ <FS_MSEG>-CHARG
        AND BWART EQ '101'
        AND SHKZG EQ 'S'
        AND AUFNR NE ''.

    " Replace SO default, jika batch masuk dalam SO-to-SO / SO-to-Free
    CLEAR WA_MSEG2.
    READ TABLE IT_MSEG2 INTO WA_MSEG2 WITH KEY CHARG = <FS_MSEG>-CHARG.
    IF SY-SUBRC = 0.
      <FS_MSEG>-KDAUF2 = WA_MSEG2-KDAUF2.
      <FS_MSEG>-KDPOS2 = WA_MSEG2-KDPOS2.
    ENDIF.

    " Get customer name
    IF <FS_MSEG>-KDAUF2 IS NOT INITIAL.
      SELECT SINGLE A~KUNNR B~NAME1 INTO (<FS_MSEG>-KUNNR, <FS_MSEG>-NAME1)
      FROM VBAK AS A JOIN KNA1 AS B ON A~KUNNR EQ B~KUNNR
      WHERE A~VBELN EQ <FS_MSEG>-KDAUF2.
    ENDIF.

    SHIFT <FS_MSEG>-KDAUF2 LEFT DELETING LEADING '0'.
    MODIFY IT_MSEG FROM <FS_MSEG> TRANSPORTING KDAUF2 KDPOS2 KUNNR NAME1 WHERE CHARG EQ <FS_MSEG>-CHARG.

    " extend program runtiem
    CALL FUNCTION 'TH_REDISPATCH'
      EXPORTING
        CHECK_RUNTIME = 0.
  ENDLOOP.

ENDFORM.                    "F_GETSO

*&---------------------------------------------------------------------*
*&      Form  F_PARSEBATCHEXE
*&---------------------------------------------------------------------*
*       ADDED BY FATHIR ON 29.05.2020
*       Get data pendukung untuk data display (characteristics, etc)
*----------------------------------------------------------------------*
FORM F_PARSEBATCHEXE.
  SORT IT_MSEG BY CHARG BWART ASCENDING.

  IF IT_MSEG[] IS NOT INITIAL.
    "Get Data Final
    SELECT MATNR CHARG WERKS NCHARG NOROLL2 GRADE2 DCRITB NWEIGHT
      INTO CORRESPONDING FIELDS OF TABLE IT_ZBATCHISTORY
      FROM ZBATCHISTORY
       FOR ALL ENTRIES IN IT_MSEG
     WHERE CHARG = IT_MSEG-CHARG %_HINTS ORACLE 'INDEX("ZBATCHISTORY" "ZBATCHISTORY~Z01")'.

    DELETE IT_ZBATCHISTORY WHERE NCHARG IS INITIAL.
    SORT IT_ZBATCHISTORY BY BUDAT DESCENDING UZEIT DESCENDING.

    IF IT_ZBATCHISTORY[] IS NOT INITIAL.
      "Get Characteristic Final
      SELECT CHARG
             AUSP~ATINN AS ATINN
             AUSP~ATWRT AS ATWRT
             AUSP~ATFLV AS ATFLV
        FROM MCH1
        JOIN AUSP  ON AUSP~OBJEK EQ MCH1~CUOBJ_BM
        APPENDING CORRESPONDING FIELDS OF TABLE CHAR_OF_BATCH_NEW
         FOR ALL ENTRIES IN IT_ZBATCHISTORY
       WHERE MATNR EQ IT_ZBATCHISTORY-MATNR
         AND CHARG EQ IT_ZBATCHISTORY-NCHARG
         AND KLART EQ '023'
         AND AUSP~ATINN IN (V_ZZNOMORROLL, V_ZZGRADE, V_ZZCONVERSIONROLLKG, V_ZZALIAS, V_ZZCRITERIA).

      "Get Characteristic Final
      PERFORM GET_STOCK_FINAL.
    ENDIF.
  ENDIF.

  "Get Mapping Label Toyobo
  SELECT CAWNT~ATINN ATWRT ATWTB
    INTO CORRESPONDING FIELDS OF TABLE CHAR_OF_BATCH_DESC
    FROM CAWN
    JOIN CAWNT ON CAWN~ATINN  EQ CAWNT~ATINN AND CAWN~ATZHL EQ CAWNT~ATZHL
   WHERE CAWN~ATINN  IN (V_ZZGRADE, V_ZZCRITERIA, V_ZZPRODLINE, V_ZZCODE, V_ZZPACKING, V_ZZTREATMENT)
     AND CAWNT~SPRAS EQ 'E'.

  SELECT ZMAP~ATNAM AS ATNAM
         ZMAP~ZCODE AS ATWTB
         ZMAP~VALUE AS ATWRT
    FROM ZMAP_LABEL_TYB AS ZMAP
    APPENDING CORRESPONDING FIELDS OF TABLE CHAR_OF_LABEL
    WHERE ZMAP~ATNAM IN ('ZTYBGRADE').

  UNASSIGN <FS_MSEG>.
  LOOP AT IT_MSEG ASSIGNING <FS_MSEG>.

    " order type
    SELECT SINGLE AUART
      INTO <FS_MSEG>-AUART
      FROM AUFK
      WHERE AUFNR = <FS_MSEG>-AUFNR.

    CHECK <FS_MSEG>-AUART NOT IN V_AUART.

    IF <FS_MSEG>-BWART = '101'.

      " entered at
      SELECT SINGLE CPUTM
        INTO <FS_MSEG>-CPUTM
        FROM MKPF
        WHERE MBLNR = <FS_MSEG>-MBLNR AND MJAHR = <FS_MSEG>-MJAHR.

      " combine order
      SELECT SINGLE AUFNR
        INTO <FS_MSEG>-COMB
        FROM AFPO
        WHERE MILL_OC_AUFNR_U = <FS_MSEG>-AUFNR.

      " object id
      CLEAR: V_ARBID.
      SELECT SINGLE ARBID
        INTO V_ARBID
        FROM AFRU
        WHERE AUFNR = <FS_MSEG>-COMB.

      " resource
      SELECT SINGLE ARBPL
        INTO <FS_MSEG>-ARBPL
        FROM CRHD
        WHERE OBJID = V_ARBID.

    ELSE.
      " combine order
      UNASSIGN <FS_MSEG3>.
      READ TABLE IT_MSEG3 ASSIGNING <FS_MSEG3> WITH KEY CHARG = <FS_MSEG>-CHARG.
      IF SY-SUBRC = 0.
        <FS_MSEG>-COMB = <FS_MSEG3>-AUFNR.
      ENDIF.
    ENDIF.

    " length, grade, criteria grade
    SPLIT <FS_MSEG>-ABLAD AT '/' INTO <FS_MSEG>-LENGTH <FS_MSEG>-GRADE <FS_MSEG>-CRIT.

    " Added by William at 10.11.2025 (Description Grade)
    " Description Grade
    IF <FS_MSEG>-GRADE NE ''.
      " deskripsi grade (by MKPF)
      READ TABLE CHAR_OF_BATCH_DESC WITH KEY ATINN = V_ZZGRADE ATWRT = <FS_MSEG>-GRADE.
      IF SY-SUBRC EQ 0.
        <FS_MSEG>-GRADETXT = CHAR_OF_BATCH_DESC-ATWTB.
      ENDIF.
    ENDIF.

    IF <FS_MSEG>-CRIT NE ''.
      " deskripsi criteria grade (by MKPF)
      READ TABLE CHAR_OF_BATCH_DESC WITH KEY ATINN = V_ZZCRITERIA ATWRT = <FS_MSEG>-CRIT.
      IF SY-SUBRC EQ 0.
        <FS_MSEG>-CRIT = CHAR_OF_BATCH_DESC-ATWTB.
      ENDIF.
    ENDIF.

******Kalau v_scon ga di tick, jangan ambil characteristic batch nya biar lebih cepat
    IF V_SCON = ''.
      CHECK <FS_MSEG>-AUFNR NE ''.
    ENDIF.

    CLEAR: CHAR_OF_BATCH.
    REFRESH: CHAR_OF_BATCH.

******Get Object Per Material dan Batch
    " internal object
    SELECT SINGLE CUOBJ_BM INTO <FS_MSEG>-CUOBJ_BM
      FROM MCH1
     WHERE MCH1~MATNR  = <FS_MSEG>-MATNR AND MCH1~CHARG  = <FS_MSEG>-CHARG.

    CHECK SY-SUBRC = 0.
    CHECK <FS_MSEG>-CUOBJ_BM NE ''.

    " extend program runtime
    CALL FUNCTION 'TH_REDISPATCH'
      EXPORTING
        CHECK_RUNTIME = 0.

    " Start Select Edited 22.09.2025 by Fiqih
    SELECT AUSP~ATINN AS ATINN
           AUSP~ATWRT AS ATWRT
           AUSP~ATFLV AS ATFLV
      FROM AUSP
      INTO CORRESPONDING FIELDS OF TABLE CHAR_OF_BATCH
      WHERE OBJEK  = <FS_MSEG>-CUOBJ_BM
      AND   ATINN IN (V_ZZNOMORROLL, V_ZZWIDTH, V_ZZCONVERSIONROLLKG, V_ZZEXLENGTH, V_ZZCORETYPE, V_ZZTREATMENT,
                      V_ZZTAILORED, V_ZZLABEL, V_ZZNOROLLTOYOBO, V_ZZNOLOTTOYOBO, V_ZZALIAS, V_ZZGRADE, V_ZZCRITERIA,
                      V_ZZCODE, V_ZZPACKING, V_ZZPRODLINE).
    " End Select Edited 22.09.2025 by Fiqih

    READ TABLE CHAR_OF_BATCH INDEX 1. " Add 21 January 2013
    CHECK SY-SUBRC = 0.

    UNASSIGN <FS_CHAR_OF_BATCH>.
    READ TABLE CHAR_OF_BATCH ASSIGNING <FS_CHAR_OF_BATCH> WITH KEY ATINN = V_ZZCODE.
    IF SY-SUBRC = 0.
      READ TABLE CHAR_OF_BATCH_DESC WITH KEY ATINN = V_ZZCODE ATWRT = <FS_CHAR_OF_BATCH>-ATWRT.
      IF SY-SUBRC EQ 0.
        <FS_MSEG>-ZZCODE = CHAR_OF_BATCH_DESC-ATWTB.
      ENDIF.
    ENDIF.

    UNASSIGN <FS_CHAR_OF_BATCH>.
    READ TABLE CHAR_OF_BATCH ASSIGNING <FS_CHAR_OF_BATCH> WITH KEY ATINN = V_ZZNOMORROLL.
    IF SY-SUBRC = 0.
      <FS_MSEG>-NOROLL = <FS_CHAR_OF_BATCH>-ATWRT.
    ENDIF.

    UNASSIGN <FS_CHAR_OF_BATCH>.
    READ TABLE CHAR_OF_BATCH ASSIGNING <FS_CHAR_OF_BATCH> WITH KEY ATINN = V_ZZCORETYPE.
    IF SY-SUBRC = 0.
      <FS_MSEG>-ZZCORETYPE = <FS_CHAR_OF_BATCH>-ATWRT.
    ENDIF.

    UNASSIGN <FS_CHAR_OF_BATCH>.
    READ TABLE CHAR_OF_BATCH ASSIGNING <FS_CHAR_OF_BATCH> WITH KEY ATINN = V_ZZWIDTH.
    IF SY-SUBRC = 0.
      <FS_MSEG>-WIDTH2 = <FS_CHAR_OF_BATCH>-ATFLV.
      <FS_MSEG>-WIDTH = <FS_MSEG>-WIDTH2.
    ENDIF.

    UNASSIGN <FS_CHAR_OF_BATCH>.
*    PERFORM GET_ATINN USING 'ZZPRODLINE' CHANGING V_ATINN.
    READ TABLE CHAR_OF_BATCH ASSIGNING <FS_CHAR_OF_BATCH> WITH KEY ATINN = V_ZZPRODLINE.
    IF SY-SUBRC = 0.
      <FS_MSEG>-LINECD = <FS_CHAR_OF_BATCH>-ATWRT.
      READ TABLE CHAR_OF_BATCH_DESC WITH KEY ATINN = V_ZZPRODLINE ATWRT = <FS_CHAR_OF_BATCH>-ATWRT.
      IF SY-SUBRC EQ 0.
        <FS_MSEG>-LINE = CHAR_OF_BATCH_DESC-ATWTB.
      ENDIF.
    ENDIF.

    UNASSIGN <FS_CHAR_OF_BATCH>.
    READ TABLE CHAR_OF_BATCH ASSIGNING <FS_CHAR_OF_BATCH> WITH KEY ATINN = V_ZZTREATMENT.
    IF SY-SUBRC = 0.
      READ TABLE CHAR_OF_BATCH_DESC WITH KEY ATINN = V_ZZTREATMENT ATWRT = <FS_CHAR_OF_BATCH>-ATWRT.
      IF SY-SUBRC EQ 0.
        <FS_MSEG>-TREAT = CHAR_OF_BATCH_DESC-ATWTB.
      ENDIF.
    ENDIF.

    UNASSIGN <FS_CHAR_OF_BATCH>.
    READ TABLE CHAR_OF_BATCH ASSIGNING <FS_CHAR_OF_BATCH> WITH KEY ATINN = V_ZZPACKING.
    IF SY-SUBRC = 0.
      READ TABLE CHAR_OF_BATCH_DESC WITH KEY ATINN = V_ZZPACKING ATWRT = <FS_CHAR_OF_BATCH>-ATWRT.
      IF SY-SUBRC EQ 0.
        <FS_MSEG>-PCKNG = CHAR_OF_BATCH_DESC-ATWTB.
      ENDIF.
    ENDIF.

    UNASSIGN <FS_CHAR_OF_BATCH>.
    READ TABLE CHAR_OF_BATCH ASSIGNING <FS_CHAR_OF_BATCH> WITH KEY ATINN = V_ZZCONVERSIONROLLKG.
    IF SY-SUBRC = 0.
      <FS_MSEG>-ZCONV = <FS_CHAR_OF_BATCH>-ATFLV.
    ENDIF.
*-- add by ALF
    UNASSIGN <FS_CHAR_OF_BATCH>.
    READ TABLE CHAR_OF_BATCH ASSIGNING <FS_CHAR_OF_BATCH> WITH KEY ATINN = V_ZZEXLENGTH.
    IF SY-SUBRC = 0.
      <FS_MSEG>-ZEXTRA = <FS_CHAR_OF_BATCH>-ATFLV.
    ENDIF.

    "---- start ADD 6.6.2017
    UNASSIGN <FS_CHAR_OF_BATCH>.
    READ TABLE CHAR_OF_BATCH ASSIGNING <FS_CHAR_OF_BATCH> WITH KEY ATINN = V_ZZGRADE.
    IF SY-SUBRC = 0.
      <FS_MSEG>-V_LASTGRADE = <FS_CHAR_OF_BATCH>-ATWRT.
    ENDIF.

    " Added by William at 10.11.2025 (Description Last Grade)
    " Description Last Grade
    IF <FS_MSEG>-V_LASTGRADE NE ''.
      " deskripsi grade (by MKPF)
      READ TABLE CHAR_OF_BATCH_DESC WITH KEY ATINN = V_ZZGRADE ATWRT =  <FS_MSEG>-V_LASTGRADE.
      IF SY-SUBRC EQ 0.
        <FS_MSEG>-V_LASTGRADETXT = CHAR_OF_BATCH_DESC-ATWTB.
      ENDIF.
    ENDIF.

    UNASSIGN <FS_CHAR_OF_BATCH>.
    READ TABLE CHAR_OF_BATCH ASSIGNING <FS_CHAR_OF_BATCH> WITH KEY ATINN = V_ZZCRITERIA.
    IF SY-SUBRC = 0.
      READ TABLE CHAR_OF_BATCH_DESC WITH KEY ATINN = V_ZZCRITERIA ATWRT = <FS_CHAR_OF_BATCH>-ATWRT.
      IF SY-SUBRC EQ 0.
        <FS_MSEG>-V_LASTCRIT = CHAR_OF_BATCH_DESC-ATWTB.
      ENDIF.
    ENDIF.

    " Start Add 22.09.2025 by Fiqih
*    --- ZZTAILORED
    UNASSIGN <FS_CHAR_OF_BATCH>.
    READ TABLE CHAR_OF_BATCH ASSIGNING <FS_CHAR_OF_BATCH> WITH KEY ATINN = V_ZZTAILORED.
    IF SY-SUBRC = 0.
      <FS_MSEG>-ZZTAILORED = <FS_CHAR_OF_BATCH>-ATWRT.
    ENDIF.

*    --- ZZLABEL
    UNASSIGN <FS_CHAR_OF_BATCH>.
    READ TABLE CHAR_OF_BATCH ASSIGNING <FS_CHAR_OF_BATCH> WITH KEY ATINN = V_ZZLABEL.
    IF SY-SUBRC = 0.
      <FS_MSEG>-ZZLABEL = <FS_CHAR_OF_BATCH>-ATWRT.
    ENDIF.

*    --- ZZNOROLLTOYOBO
    UNASSIGN <FS_CHAR_OF_BATCH>.
    READ TABLE CHAR_OF_BATCH ASSIGNING <FS_CHAR_OF_BATCH> WITH KEY ATINN = V_ZZNOROLLTOYOBO.
    IF SY-SUBRC = 0.
      <FS_MSEG>-ZZNOROLLTOYOBO = <FS_CHAR_OF_BATCH>-ATWRT.
    ENDIF.

*    --- ZZNOLOTTOYOBO
    UNASSIGN <FS_CHAR_OF_BATCH>.
    READ TABLE CHAR_OF_BATCH ASSIGNING <FS_CHAR_OF_BATCH> WITH KEY ATINN = V_ZZNOLOTTOYOBO.
    IF SY-SUBRC = 0.
      <FS_MSEG>-ZZNOLOTTOYOBO = <FS_CHAR_OF_BATCH>-ATWRT.
    ENDIF.

    READ TABLE CHAR_OF_LABEL WITH KEY ATNAM = 'ZTYBGRADE' ATWTB = <FS_MSEG>-ZZLABEL.
    IF SY-SUBRC = 0.
      IF CHAR_OF_LABEL-ATWRT = 'GRDFORMULA2'.
        " --- Panggil FORM untuk hitung grade By JR Position (UoM)

        PERFORM GET_GRDFORMULA2 USING V_GRD.
        <FS_MSEG>-ZTYBGRADE = V_GRD.

      ELSEIF CHAR_OF_LABEL-ATWRT = 'GRDFORMULA3'.
        " --- Ambil nilai ZZGRADE
        UNASSIGN <FS_CHAR_OF_BATCH>.
        READ TABLE CHAR_OF_BATCH ASSIGNING <FS_CHAR_OF_BATCH> WITH KEY ATINN = V_ZZGRADE.
        IF SY-SUBRC = 0.
          <FS_MSEG>-ZTYBGRADE = <FS_CHAR_OF_BATCH>-ATWRT.
        ENDIF.

      ELSE.
        " --- Default langsung isi dari ATWRT
        <FS_MSEG>-ZTYBGRADE = CHAR_OF_LABEL-ATWRT.
      ENDIF.
    ENDIF.

    " Select Final Batch, Final No Roll, Last Final Grade
    READ TABLE IT_ZBATCHISTORY WITH KEY CHARG = <FS_MSEG>-CHARG.
    IF SY-SUBRC EQ 0.
      <FS_MSEG>-NCHARG   = IT_ZBATCHISTORY-NCHARG.
      <FS_MSEG>-NOROLL2  = IT_ZBATCHISTORY-NOROLL2.
      <FS_MSEG>-GRADE2   = IT_ZBATCHISTORY-GRADE2.
      <FS_MSEG>-DCRITB   = IT_ZBATCHISTORY-DCRITB.
      <FS_MSEG>-NWEIGHT  = IT_ZBATCHISTORY-NWEIGHT.
    ELSE.
      <FS_MSEG>-NCHARG   = <FS_MSEG>-CHARG.
      <FS_MSEG>-NWEIGHT  = <FS_MSEG>-MENGE.
    ENDIF.
    " End Add 22.09.2025 by Fiqih

    IF <FS_MSEG>-NCHARG = <FS_MSEG>-CHARG.
      UNASSIGN <FS_CHAR_OF_BATCH>.
      READ TABLE CHAR_OF_BATCH ASSIGNING <FS_CHAR_OF_BATCH> WITH KEY ATINN = V_ZZNOMORROLL.
      IF SY-SUBRC = 0.
        <FS_MSEG>-NOROLL2 = <FS_CHAR_OF_BATCH>-ATWRT.
      ENDIF.

      UNASSIGN <FS_CHAR_OF_BATCH>.
      READ TABLE CHAR_OF_BATCH ASSIGNING <FS_CHAR_OF_BATCH> WITH KEY ATINN = V_ZZGRADE.
      IF SY-SUBRC = 0.
        <FS_MSEG>-GRADE2 = <FS_CHAR_OF_BATCH>-ATWRT.
      ENDIF.

      READ TABLE CHAR_OF_BATCH ASSIGNING <FS_CHAR_OF_BATCH> WITH KEY ATINN = V_ZZCRITERIA.
      IF SY-SUBRC = 0.
        READ TABLE CHAR_OF_BATCH_DESC WITH KEY ATINN = V_ZZCRITERIA ATWRT = <FS_CHAR_OF_BATCH>-ATWRT.
        IF SY-SUBRC EQ 0.
          <FS_MSEG>-DCRITB = CHAR_OF_BATCH_DESC-ATWTB.
        ENDIF.
      ENDIF.

      " Get Type Alias
      UNASSIGN <FS_CHAR_OF_BATCH>.
      READ TABLE CHAR_OF_BATCH ASSIGNING <FS_CHAR_OF_BATCH> WITH KEY ATINN = V_ZZALIAS.
      IF SY-SUBRC = 0.
        <FS_MSEG>-ZZALIAS = <FS_CHAR_OF_BATCH>-ATWRT.
      ENDIF.
    ELSE.
      UNASSIGN <FS_CHAR_OF_BATCH_NEW>.
      READ TABLE CHAR_OF_BATCH_NEW ASSIGNING <FS_CHAR_OF_BATCH_NEW> WITH KEY ATINN = V_ZZNOMORROLL CHARG = <FS_MSEG>-NCHARG.
      IF SY-SUBRC = 0.
        <FS_MSEG>-NOROLL2 = <FS_CHAR_OF_BATCH_NEW>-ATWRT.
      ENDIF.

      UNASSIGN <FS_CHAR_OF_BATCH_NEW>.
      READ TABLE CHAR_OF_BATCH_NEW ASSIGNING <FS_CHAR_OF_BATCH_NEW> WITH KEY ATINN = V_ZZGRADE CHARG = <FS_MSEG>-NCHARG.
      IF SY-SUBRC = 0.
        <FS_MSEG>-GRADE2 = <FS_CHAR_OF_BATCH_NEW>-ATWRT.
      ENDIF.

      READ TABLE CHAR_OF_BATCH_NEW ASSIGNING <FS_CHAR_OF_BATCH_NEW> WITH KEY ATINN = V_ZZCRITERIA CHARG = <FS_MSEG>-NCHARG.
      IF SY-SUBRC = 0.
        READ TABLE CHAR_OF_BATCH_DESC WITH KEY ATINN = V_ZZCRITERIA ATWRT = <FS_CHAR_OF_BATCH_NEW>-ATWRT.
        IF SY-SUBRC EQ 0.
          <FS_MSEG>-DCRITB = CHAR_OF_BATCH_DESC-ATWTB.
        ENDIF.
      ENDIF.

      " Get Type Alias
      UNASSIGN <FS_CHAR_OF_BATCH_NEW>.
      READ TABLE CHAR_OF_BATCH_NEW ASSIGNING <FS_CHAR_OF_BATCH_NEW> WITH KEY ATINN = V_ZZALIAS CHARG = <FS_MSEG>-NCHARG.
      IF SY-SUBRC = 0.
        <FS_MSEG>-ZZALIAS = <FS_CHAR_OF_BATCH_NEW>-ATWRT.
      ENDIF.
    ENDIF.

    "Final Qty Actual
    CLEAR: IT_STOCK_FINAL.
    READ TABLE IT_STOCK_FINAL WITH KEY CHARG = <FS_MSEG>-NCHARG.
    IF SY-SUBRC = 0.
      IF IT_STOCK_FINAL-LABST > 0.
        <FS_MSEG>-NWEIGHT_A = IT_STOCK_FINAL-LABST.
      ELSEIF IT_STOCK_FINAL-INSME > 0.
        <FS_MSEG>-NWEIGHT_A = IT_STOCK_FINAL-INSME.
      ELSEIF IT_STOCK_FINAL-SPEME > 0.
        <FS_MSEG>-NWEIGHT_A = IT_STOCK_FINAL-SPEME.
      ELSEIF IT_STOCK_FINAL-EINME > 0.
        <FS_MSEG>-NWEIGHT_A = IT_STOCK_FINAL-EINME.
      ENDIF.
    ELSE.
      CLEAR: IT_STOCK.
      READ TABLE IT_STOCK WITH KEY CHARG = <FS_MSEG>-NCHARG.
      IF SY-SUBRC = 0.
        IF IT_STOCK-LABST > 0.
          <FS_MSEG>-NWEIGHT_A = IT_STOCK-LABST.
        ELSEIF IT_STOCK-INSME > 0.
          <FS_MSEG>-NWEIGHT_A = IT_STOCK-INSME.
        ELSEIF IT_STOCK-SPEME > 0.
          <FS_MSEG>-NWEIGHT_A = IT_STOCK-SPEME.
        ELSEIF IT_STOCK-EINME > 0.
          <FS_MSEG>-NWEIGHT_A = IT_STOCK-EINME.
        ENDIF.
      ENDIF.
    ENDIF.

    "
    CLEAR: IT_STOCK.
    READ TABLE IT_STOCK WITH KEY CHARG = <FS_MSEG>-CHARG.
    IF SY-SUBRC = 0.
      IF IT_STOCK-LABST > 0.
        <FS_MSEG>-V_LASTQTY = IT_STOCK-LABST.
      ELSEIF IT_STOCK-INSME > 0.
        <FS_MSEG>-V_LASTQTY = IT_STOCK-INSME.
      ELSEIF IT_STOCK-SPEME > 0.
        <FS_MSEG>-V_LASTQTY = IT_STOCK-SPEME.
      ELSEIF IT_STOCK-EINME > 0.
        <FS_MSEG>-V_LASTQTY = IT_STOCK-EINME.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.                    "F_PARSEBATCHEXE

*&---------------------------------------------------------------------*
*&      Form  F_PARSESOEXE
*&---------------------------------------------------------------------*
*       CHANGED BY FATHIR ON 04.06.2020
*       Cacah eksekusi GET SO per 5000 batch
*----------------------------------------------------------------------*
*      -->P_GRN101    text
*----------------------------------------------------------------------*
FORM F_PARSESOEXE TABLES P_GRN101 LIKE IT_CHARG[].
  RANGES: R_LOCCHARG FOR MCH1-CHARG.
  DATA: V_IDXLOW TYPE I VALUE 1,
        V_IDXHIGH TYPE I VALUE 5000,
        V_IDXCUR TYPE I,
        V_ROWS TYPE I.
  DATA: V_ISLAST(1).

  "ADDED BY FATHIR ON 04.06.2020
  " temp ITAB untuk hasil query SO dan GRN101 (per 5000 batch)
  DATA: IT_TMSEG TYPE STANDARD TABLE OF TY_MSEG WITH HEADER LINE,
        IT_TGRN101 TYPE STANDARD TABLE OF TY_MSEG WITH HEADER LINE.

  "CHANGED BY FATHIR ON 04.06.2020
  " get total batch yang ditemukan
  DESCRIBE TABLE P_GRN101 LINES V_ROWS.

  " cacah query get data SO setiap 5000 batch
  WHILE V_ISLAST = ''.
    " jika total row < 5000, maka isi batas atas dengan jumlah row
    IF V_IDXHIGH > V_ROWS.
      V_IDXHIGH = V_ROWS.
      V_ISLAST = 'X'.
    ENDIF.

    "CHANGED BY FATHIR ON 04.06.2020
    " copy data batch per 5000 baris ke ranges temporary
    REFRESH: IT_TGRN101.
    LOOP AT P_GRN101 FROM V_IDXLOW TO V_IDXHIGH.
      V_IDXCUR = SY-TABIX.
      APPEND P_GRN101 TO IT_TGRN101.

      IF V_IDXCUR = V_IDXHIGH.
        EXIT.
      ENDIF.
    ENDLOOP.

    " tambah batas bawah dan atas index.
    V_IDXLOW = V_IDXHIGH + 1.
    V_IDXHIGH = V_IDXHIGH + 5000.

    "CHANGED BY FATHIR ON 04.06.2020
    " Get SO untuk setiap batch dari transaksi SO-to-SO / SO-to-Free
    LOOP AT IT_TGRN101.

      REFRESH: IT_TMSEG.
      SELECT MSEG~MBLNR MSEG~MJAHR MSEG~SMBLN MSEG~SMBLP MSEG~BWART
           MSEG~MATNR MSEG~CHARG MSEG~WERKS MSEG~LGORT AUFK~AUFNR
           MSEG~KDAUF MSEG~KDPOS MSEG~MAT_KDAUF AS KDAUF2 MSEG~MAT_KDPOS AS KDPOS2
           MSEG~SHKZG MSEG~XAUTO MSEG~BUDAT_MKPF AS BUDAT
      APPENDING CORRESPONDING FIELDS OF TABLE IT_TMSEG
      FROM MSEG
      JOIN AUFK ON MSEG~AUFNR = AUFK~AUFNR
      WHERE MSEG~MANDT = SY-MANDT AND MSEG~BWART IN ('413', '414','411', '412') AND
            MSEG~XAUTO = 'X' AND
            MSEG~AUFNR NE '' AND MSEG~CHARG = IT_TGRN101-CHARG AND
            AUFK~AUART = IT_TGRN101-AUART AND
            MSEG~BUDAT_MKPF = IT_TGRN101-BUDAT %_HINTS ORACLE 'INDEX("MSEG" "MSEG~Z15")'.

      IF SY-SUBRC = 0.
        APPEND LINES OF IT_TMSEG TO IT_MSEG2.
      ENDIF.

    ENDLOOP.

    "ADDED BY FATHIR ON 04.06.2020
    " extend program runtime
    CALL FUNCTION 'TH_REDISPATCH'
      EXPORTING
        CHECK_RUNTIME = 0.

  ENDWHILE.

ENDFORM.                    "F_PARSESOEXE

*&---------------------------------------------------------------------*
*&      Form  F_GETGRN01
*&---------------------------------------------------------------------*
*       ADDED BY FATHIR ON 04.06.2020
*       get data GRN 101
*----------------------------------------------------------------------*
*      -->P_MATNR    text
*      -->P_DATE     text
*----------------------------------------------------------------------*
FORM F_GETGRN01 TABLES P_MATNR LIKE R_MATNO[]
                       P_DATE LIKE R_DATE[].

  DATA: IT_TMSEG TYPE STANDARD TABLE OF TY_MSEG WITH HEADER LINE.

  LOOP AT P_DATE.

    REFRESH: IT_TMSEG.

    " tanpa join AUFK
    SELECT MSEG~MBLNR MSEG~MJAHR MSEG~ZEILE MSEG~SMBLN MSEG~SMBLP MSEG~BWART
           MSEG~MATNR MSEG~CHARG MSEG~WERKS MSEG~LGORT MSEG~MENGE MSEG~MEINS
           MSEG~AUFNR MSEG~KDAUF MSEG~KDPOS MSEG~ABLAD MSEG~BUDAT_MKPF AS BUDAT
      INTO CORRESPONDING FIELDS OF TABLE IT_TMSEG
      FROM MSEG
      WHERE MSEG~MANDT = SY-MANDT AND MSEG~MATNR IN P_MATNR AND
           MSEG~BWART = '101' AND MSEG~BUDAT_MKPF = P_DATE-LOW.

    IF SY-SUBRC = 0.

      " filter GRN 101 berdasarkan input Plant
      SORT IT_TMSEG BY WERKS ASCENDING.
      DELETE IT_TMSEG WHERE WERKS NOT IN WERKS.

      " filter GRN 531 berdasarkan input Batch
      SORT IT_TMSEG BY CHARG ASCENDING.
      DELETE IT_TMSEG WHERE CHARG NOT IN ZCHARG.

      " append GRN 101
      IF IT_TMSEG[] IS NOT INITIAL.
        APPEND LINES OF IT_TMSEG TO IT_MSEG.
      ENDIF.

    ENDIF.

  ENDLOOP.

ENDFORM.                    "F_GETGRN01

" Start Add 22.09.2025 by Fiqih
*&---------------------------------------------------------------------*
*&      Form  GET_GRDFORMULA2
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->V_GRD      text
*----------------------------------------------------------------------*
FORM GET_GRDFORMULA2 USING V_GRD.

  CLEAR: VX_ATNROL,VX_ATNUOM,VX_ROLNO,VX_MATNR_JR,VX_CHARG_JR,VX_UOM.

  " Ambil ATINN dari characteristic
  SELECT SINGLE ATINN INTO VX_ATNROL FROM CABN WHERE ATNAM = 'ZZNOMORROLL'.
  SELECT SINGLE ATINN INTO VX_ATNUOM FROM CABN WHERE ATNAM = 'ZZUNITOFMEASURE'.

  " Cari nomor roll dari batch
  SELECT SINGLE AUSP~ATWRT INTO VX_ROLNO
    FROM AUSP JOIN MCH1 ON AUSP~OBJEK = MCH1~CUOBJ_BM
    WHERE MCH1~MATNR = <FS_MSEG>-MATNR
      AND MCH1~CHARG = <FS_MSEG>-CHARG
      AND AUSP~ATINN = VX_ATNROL.

  VX_ROLNO = VX_ROLNO+0(13).

  " Ambil mother roll dengan movement type 101
  SELECT SINGLE MSEG~MATNR MSEG~CHARG
    INTO (VX_MATNR_JR, VX_CHARG_JR)
    FROM MSEG
    JOIN MKPF ON MSEG~MBLNR = MKPF~MBLNR
             AND MSEG~MJAHR = MKPF~MJAHR
    WHERE MSEG~BWART = '101'
      AND MKPF~BKTXT = VX_ROLNO.

  IF SY-SUBRC NE 0.
    CONCATENATE 'Data Mother Roll Batch' IT_CHARG-CHARG 'tidak ditemukan..!'
      INTO VX_MSG SEPARATED BY SPACE.
    EXIT.
  ENDIF.

  " Baca kode posisi dari characteristic ZZUNITOFMEASURE
  SELECT SINGLE AUSP~ATWRT INTO VX_UOM
    FROM AUSP JOIN MCH1 ON AUSP~OBJEK = MCH1~CUOBJ_BM
    WHERE MCH1~MATNR = VX_MATNR_JR
      AND MCH1~CHARG = VX_CHARG_JR
      AND AUSP~ATINN = VX_ATNUOM.

  IF SY-SUBRC NE 0.
    CONCATENATE 'Kode Posisi Batch' IT_CHARG-CHARG 'tidak ditemukan..!'
      INTO VX_MSG SEPARATED BY SPACE.
    EXIT.
  ENDIF.

  ITAB-CHARG_JR = VX_CHARG_JR.

  V_GRD = VX_UOM.
  CONCATENATE 'A' V_GRD INTO V_GRD.

ENDFORM.                    "GET_GRDFORMULA2
" End Add 22.09.2025 by Fiqih
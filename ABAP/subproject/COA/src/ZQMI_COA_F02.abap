*&---------------------------------------------------------------------*
*&  Include           ZQMI_CERTIFICATE_F02
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE STATUS_0100 OUTPUT.
  SET PF-STATUS 'PF0100'.
*  SET TITLEBAR 'xxx'.

ENDMODULE.                 " STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE USER_COMMAND_0100 INPUT.
  DATA : T_DETAIL LIKE STANDARD TABLE OF IT_DATA WITH HEADER LINE,
         T_DETAIL1 LIKE STANDARD TABLE OF IT_DATA WITH HEADER LINE,
         IT_DETAIL1 LIKE STANDARD TABLE OF IT_DETAIL WITH HEADER LINE,
         IT_DETAIL2 LIKE STANDARD TABLE OF IT_DETAIL WITH HEADER LINE,
         CSTAT TYPE I,
         CTR TYPE I,
         MICMITV TYPE P DECIMALS 2,
         MICMIT TYPE P DECIMALS 2,
         CMIT TYPE C LENGTH 17,
         MSTAT TYPE I,
         MAX TYPE C LENGTH 6,
         HTYPE  LIKE  DD01V-DATATYPE.
  CASE SY-UCOMM.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
    WHEN 'XPORT'.
      PERFORM DOWNLOAD.
    WHEN 'SELALL'.
      PERFORM SELALL.
    WHEN 'DESALL'.
      PERFORM DESALL.
    WHEN 'SELMAP'.
      PERFORM SELMAPPING.
    WHEN 'SAVE'.
      PERFORM SAVE_ADD_INFO.
    WHEN 'EXEC'.
      READ TABLE IT_DATA WITH KEY CHK = 'X'.
      IF SY-SUBRC = 0.
        LOOP AT IT_DATA WHERE CHK EQ 'X'.
          IF IT_DATA-CMICMIT <> IT_DATA-SAVED_CMICMIT.
            MESSAGE 'Harap Save perubahan nilai (Preview) terlebih dahulu!' TYPE 'E'.
          ENDIF.
        ENDLOOP.
      ENDIF.

      CLEAR:CSTAT, TBATCH, IT_DETAIL, T_DETAIL1, IT_DETAIL1, T_DETAIL,IT_WIDTH,WIDTH,CLENG,HTYPE,CMIT.
      REFRESH: TBATCH, IT_DETAIL, T_DETAIL1, IT_DETAIL1, T_DETAIL,IT_WIDTH.

      LOOP AT IT_DATA WHERE CHK EQ 'X'.
        CLEAR : MAX, IT_DETAIL.
        VBELN = IT_DATA-VBELN.
        IT_DETAIL-MIC = IT_DATA-MIC.
        IT_DETAIL-NUM = IT_DATA-NUM.
        IT_DETAIL-NUMMIC = IT_DATA-NUMMIC.
        IT_DETAIL-MICDES = IT_DATA-MICDES.
        IT_DETAIL-UOM = IT_DATA-UOM.
        IT_DETAIL-METHOD = IT_DATA-METHOD.
        SELECT MAX( VERSION ) INTO MAX
          FROM QPMK
          WHERE MKMNR = IT_DATA-MIC
          AND WERKS = IT_DATA-WERKS.

        IT_DETAIL-MICMIN = IT_DATA-MICMIN.
        IT_DETAIL-MICMAX = IT_DATA-MICMAX.
        IT_DETAIL-RAW_MICMIN = IT_DATA-RAW_MICMIN.
        IT_DETAIL-RAW_MICMAX = IT_DATA-RAW_MICMAX.
        IT_DETAIL-CMICMIT = IT_DATA-CMICMIT.
        IT_DETAIL-CHK = IT_DATA-CHK.
        CONDENSE IT_DETAIL-CMICMIT.
        CLEAR IT_WIDTH.
        CALL FUNCTION 'VB_INIT'
          EXPORTING
            INIT_RESET = 'X'.
        CALL FUNCTION 'VB_BATCH_GET_DETAIL'
          EXPORTING
            MATNR              = IT_DATA-MATNR
            CHARG              = IT_DATA-CHARG
            WERKS              = IT_DATA-WERKS
            GET_CLASSIFICATION = 'X'
          TABLES
            CHAR_OF_BATCH      = TBATCH
          EXCEPTIONS
            NO_MATERIAL        = 1
            NO_BATCH           = 2
            NO_PLANT           = 3
            MATERIAL_NOT_FOUND = 4
            PLANT_NOT_FOUND    = 5
            NO_AUTHORITY       = 6
            BATCH_NOT_EXIST    = 7
            LOCK_ON_BATCH      = 8
            OTHERS             = 9.
        IF SY-SUBRC <> 0.
* Implement suitable error handling here
        ENDIF.
*        BREAK-POINT.
        READ TABLE TBATCH WITH KEY ATNAM = 'ZZWIDTH'.
        IF SY-SUBRC EQ 0.
*          IT_WIDTH-WIDTHP = TBATCH-ATWTB.
          WRITE TBATCH-ATWTB TO IT_WIDTH-WIDTH DECIMALS 2.
          IT_WIDTH-CLENG = STRLEN( IT_WIDTH-WIDTH ) + 1.
          APPEND IT_WIDTH.
        ENDIF.
        CMIT = IT_DETAIL-CMICMIT.
        REPLACE ALL OCCURRENCES OF '.' IN CMIT WITH ' '.
        CALL FUNCTION 'NUMERIC_CHECK'
          EXPORTING
            STRING_IN = CMIT
          IMPORTING
            HTYPE     = HTYPE.
        IF HTYPE EQ 'NUMC'.
          IT_DETAIL-TYPE = 'X'.
        ELSE.
          IT_DETAIL-TYPE = 'Y'.
        ENDIF.
        APPEND IT_DETAIL.
      ENDLOOP.

      READ TABLE TBATCH WITH KEY ATNAM = 'ZZCODE'.
      IF SY-SUBRC EQ 0.
        PRODUCT = TBATCH-ATWTB.
        READ TABLE TBATCH WITH KEY ATNAM = 'ZZALIAS'.
        IF SY-SUBRC = 0.
          PRODUCT = TBATCH-ATWTB.  "ambil value ALIAS
        ENDIF.
      ENDIF.
      SORT IT_WIDTH BY WIDTH ASCENDING.
      DELETE ADJACENT DUPLICATES FROM IT_WIDTH COMPARING WIDTH.
      LOOP AT IT_WIDTH.
        CLENG = CLENG + IT_WIDTH-CLENG.
        IF CLENG LE 40.
          CONCATENATE WIDTH IT_WIDTH-WIDTH INTO WIDTH SEPARATED BY ';'.
          SHIFT WIDTH LEFT DELETING LEADING ';'.
        ELSE.
          EXIT.
        ENDIF.
      ENDLOOP.
      CLEAR : NTGEW, QUANT.
      SELECT SINGLE KNA1~NAME1 NTGEW INTO (NAME1,QUANT)
        FROM KNA1
        JOIN LIKP ON LIKP~KUNAG = KNA1~KUNNR
        WHERE LIKP~VBELN = VBELN.
      CONDENSE NAME1.
      NTGEW = QUANT.
      IF IT_DATA[] IS INITIAL.
        MESSAGE 'Tidak ada data yang dipilih!' TYPE 'I'.
      ELSE.
        T_DETAIL[] = IT_DATA[].
        DELETE T_DETAIL WHERE CHK NE 'X'.
        T_DETAIL1[] = T_DETAIL[].
        SORT T_DETAIL BY VBELN ASCENDING.
        DELETE ADJACENT DUPLICATES FROM T_DETAIL COMPARING VBELN.
        SORT T_DETAIL1 BY MATNR ASCENDING.
        DELETE ADJACENT DUPLICATES FROM T_DETAIL1 COMPARING MATNR.
        CLEAR : CSTAT,MSTAT.
        CSTAT = LINES( T_DETAIL ).
        MSTAT = LINES( T_DETAIL1 ).
        IF CSTAT NE 1.
          MESSAGE 'Pilih 1 ODO!' TYPE 'I'.
        ELSEIF MSTAT NE 1.
          MESSAGE 'Tipe film tidak boleh berbeda!' TYPE 'I'.
        ELSE.
          CLEAR: CTR,MICMIT,IT_DETAIL1.
          REFRESH IT_DETAIL1.
          IT_DETAIL1[] = IT_DETAIL[].
          IT_DETAIL2[] = IT_DETAIL[].
          SORT IT_DETAIL BY MIC ASCENDING.
          DELETE ADJACENT DUPLICATES FROM IT_DETAIL COMPARING MIC.
          DELETE IT_DETAIL2 WHERE CMICMIT EQ ''.
          DELETE IT_DETAIL2 WHERE CMICMIT EQ '0.00'.
          DELETE IT_DETAIL2 WHERE CMICMIT IS INITIAL.
          SORT IT_DETAIL2 BY MIC TYPE ASCENDING.
          DELETE ADJACENT DUPLICATES FROM IT_DETAIL2 COMPARING MIC TYPE.
          LOOP AT IT_DETAIL.
            CTR = 0.
            LOOP AT IT_DETAIL2 WHERE MIC = IT_DETAIL-MIC.
              CTR = CTR + 1.
            ENDLOOP.
            IF  CTR GE 2.
              CLEAR CSTAT.
              CSTAT = 5.
            ENDIF.
          ENDLOOP.
          IF CSTAT NE 5.
            LOOP AT IT_DETAIL WHERE TYPE EQ 'X' .
              CLEAR : CTR,MICMIT,MICMITV.
              CTR = 0.
              LOOP AT IT_DETAIL1 WHERE MIC = IT_DETAIL-MIC.
                MICMIT = MICMIT + IT_DETAIL1-CMICMIT.
                CTR = CTR + 1.
              ENDLOOP.
              IF CTR NE 0.
                MICMITV = MICMIT / CTR.
*              IT_DETAIL-CMICMIT = MICMITV.
                WRITE MICMITV TO IT_DETAIL-CMICMIT DECIMALS 2.
                CONDENSE IT_DETAIL-CMICMIT.
                MODIFY IT_DETAIL.
              ENDIF.
            ENDLOOP.
            SHIFT VBELN LEFT DELETING LEADING '0'.
            SORT IT_DETAIL BY NUMMIC NUM ASCENDING.
            CALL SCREEN 0200.
          ELSE.
            MESSAGE 'Value mic tidak dapat qualitatif dan quantitatif!' TYPE 'I'.
          ENDIF.
        ENDIF.
      ENDIF.
  ENDCASE.
  CLEAR SY-UCOMM.
ENDMODULE.                 " USER_COMMAND_0100  INPUT

*&SPWIZARD: OUTPUT MODULE FOR TC 'TCERTI'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: UPDATE LINES FOR EQUIVALENT SCROLLBAR
MODULE TCERTI_CHANGE_TC_ATTR OUTPUT.
  DESCRIBE TABLE IT_DATA LINES TCERTI-LINES.
ENDMODULE.                    "TCERTI_CHANGE_TC_ATTR OUTPUT

*&SPWIZARD: OUTPUT MODULE FOR TC 'TCERTI'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: GET LINES OF TABLECONTROL
MODULE TCERTI_GET_LINES OUTPUT.
  G_TCERTI_LINES = SY-LOOPC.
ENDMODULE.                    "TCERTI_GET_LINES OUTPUT

*&SPWIZARD: INPUT MODULE FOR TC 'TCERTI'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: PROCESS USER COMMAND
MODULE TCERTI_USER_COMMAND INPUT.
  OK_CODE = SY-UCOMM.
  PERFORM USER_OK_TC USING    'TCERTI'
                              'IT_DATA'
                              ' '
                     CHANGING OK_CODE.
  SY-UCOMM = OK_CODE.
ENDMODULE.                    "TCERTI_USER_COMMAND INPUT

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
*&      Module  TCTIMB_MODIFY  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE TCTIMB_MODIFY INPUT.
  MODIFY IT_DATA
*    FROM WA_TIMBANG
    INDEX TCERTI-CURRENT_LINE.
ENDMODULE.                 " TCTIMB_MODIFY  INPUT

*&SPWIZARD: OUTPUT MODULE FOR TC 'TDETAIL'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: UPDATE LINES FOR EQUIVALENT SCROLLBAR
MODULE TDETAIL_CHANGE_TC_ATTR OUTPUT.
  DESCRIBE TABLE IT_DETAIL LINES TDETAIL-LINES.
ENDMODULE.                    "TDETAIL_CHANGE_TC_ATTR OUTPUT

*&SPWIZARD: OUTPUT MODULE FOR TC 'TDETAIL'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: GET LINES OF TABLECONTROL
MODULE TDETAIL_GET_LINES OUTPUT.
  G_TDETAIL_LINES = SY-LOOPC.
ENDMODULE.                    "TDETAIL_GET_LINES OUTPUT

*&SPWIZARD: INPUT MODULE FOR TC 'TDETAIL'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: PROCESS USER COMMAND
MODULE TDETAIL_USER_COMMAND INPUT.
  OK_CODE = SY-UCOMM.
  PERFORM USER_OK_TC USING    'TDETAIL'
                              'IT_DETAIL'
                              ' '
                     CHANGING OK_CODE.
  SY-UCOMM = OK_CODE.
  CASE SY-UCOMM.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
    WHEN 'DLOAD'.
      PERFORM DOWNLOAD_DETAIL.
    WHEN 'BATLIST'.
      PERFORM DOWNLOAD_BATCH_LIST_XLSX.
    WHEN 'PRNT'.
      DATA: LV_EMPTY_FOUND TYPE C.
      DATA: LV_RANGE_FOUND TYPE C.
      DATA: LV_CHK_STR TYPE C LENGTH 17.
      DATA: LV_CHK_VAL TYPE QAMR-MITTELWERT.
      CLEAR: LV_EMPTY_FOUND, LV_RANGE_FOUND.
      LOOP AT IT_DETAIL WHERE CMICMIT EQ '-' OR CMICMIT IS INITIAL OR CMICMIT EQ '00000000' OR CMICMIT EQ '0' OR CMICMIT EQ '0.00' OR CMICMIT EQ '0.000'.
        LV_EMPTY_FOUND = 'X'.
        EXIT.
      ENDLOOP.

      IF LV_EMPTY_FOUND IS INITIAL.
        LOOP AT IT_DETAIL WHERE TYPE EQ 'X'.
          IF IT_DETAIL-MICMIN IS INITIAL AND IT_DETAIL-MICMAX IS INITIAL.
            CONTINUE.
          ENDIF.
          CLEAR: LV_CHK_STR, LV_CHK_VAL.
          LV_CHK_STR = IT_DETAIL-CMICMIT.
          REPLACE ALL OCCURRENCES OF ',' IN LV_CHK_STR WITH '.'.
          CONDENSE LV_CHK_STR NO-GAPS.
          TRY.
              LV_CHK_VAL = LV_CHK_STR.
            CATCH CX_ROOT.
              CONTINUE.
          ENDTRY.
          IF ( IT_DETAIL-RAW_MICMIN IS NOT INITIAL AND LV_CHK_VAL < IT_DETAIL-RAW_MICMIN ) OR
             ( IT_DETAIL-RAW_MICMAX IS NOT INITIAL AND LV_CHK_VAL > IT_DETAIL-RAW_MICMAX ).
            LV_RANGE_FOUND = 'X'.
            EXIT.
          ENDIF.
        ENDLOOP.
      ENDIF.

      IF LV_EMPTY_FOUND = 'X'.
        MESSAGE 'Ada data MIC yang belum di-record (kosong), tidak bisa cetak COA!' TYPE 'I' DISPLAY LIKE 'E'.
      ELSEIF LV_RANGE_FOUND = 'X'.
        MESSAGE 'Ada value MIC yang keluar dari Lower/Upper Limit. Ubah value & Save (kembali ke layar sebelumnya) sebelum Print!' TYPE 'I' DISPLAY LIKE 'E'.
      ELSE.
        PERFORM F_PRINT.
      ENDIF.
  ENDCASE.
  CLEAR SY-UCOMM.
ENDMODULE.                    "TDETAIL_USER_COMMAND INPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE STATUS_0200 OUTPUT.
  SET PF-STATUS 'PF0200'.
*  SET TITLEBAR 'xxx'.

ENDMODULE.                 " STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  TDETAIL_MODIFY  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE TDETAIL_MODIFY INPUT.
  MODIFY IT_DETAIL
*    FROM WA_TIMBANG
    INDEX TDETAIL-CURRENT_LINE.
ENDMODULE.                 " TDETAIL_MODIFY  INPUT

*&---------------------------------------------------------------------*
*&      Form  SAVE_ADD_INFO
*&---------------------------------------------------------------------*
FORM SAVE_ADD_INFO.
  DATA: V_INDEX TYPE I,
        V_TOTAL TYPE I.
  DATA: LT_DATA LIKE IT_DATA OCCURS 0 WITH HEADER LINE.
  DATA: LS_SUBRC TYPE SY-SUBRC,
        MESS TYPE STRING,
        ZSTAT TYPE STRING,
        ERR TYPE C.
  DATA: LV_KUNNR TYPE KUNNR.
  DATA: LV_STR_VAL TYPE STRING,
        LV_VALUE1 TYPE ZLOG_COA-VALUE1.
  DATA: WA_ZLOG TYPE ZLOG_COA.
  DATA: LV_TERMINAL TYPE ZLOG_COA-TERM1.
  DATA: LV_HAS_CHANGES TYPE C,
        LV_ANSWER TYPE C.

  " Tables for deferred update
  DATA: LT_ZLOG_UPDATE TYPE TABLE OF ZLOG_COA WITH HEADER LINE.
  DATA: LT_ZLOG_INSERT TYPE TABLE OF ZLOG_COA WITH HEADER LINE.
  DATA: LT_IT_DATA_UPDATE LIKE IT_DATA OCCURS 0 WITH HEADER LINE.

  CALL FUNCTION 'TERMINAL_ID_GET'
    EXPORTING
      USERNAME             = SY-UNAME
    IMPORTING
      TERMINAL             = LV_TERMINAL
    EXCEPTIONS
      MULTIPLE_TERMINAL_ID = 1
      NO_TERMINAL_FOUND    = 2
      OTHERS               = 3.
  IF SY-SUBRC <> 0.
    CLEAR LV_TERMINAL.
  ENDIF.

  LT_DATA[] = IT_DATA[].
  DELETE LT_DATA WHERE CHK NE 'X'.

  IF LT_DATA[] IS INITIAL.
    MESSAGE 'Pilih data terlebih dahulu!' TYPE 'I'.
    EXIT.
  ENDIF.

  DESCRIBE TABLE LT_DATA LINES V_TOTAL.
  V_INDEX = 0.
  CLEAR LV_HAS_CHANGES.
  REFRESH: LT_ZLOG_UPDATE, LT_ZLOG_INSERT, LT_IT_DATA_UPDATE.

  " Tahap 1: Pengecekan data mana saja yang benar-benar berubah
  LOOP AT LT_DATA.
    V_INDEX = V_INDEX + 1.
    PERFORM SET_INDICATOR USING V_INDEX V_TOTAL 1 1 'Mengecek perubahan data...'.

    " Get KUNNR
    CLEAR LV_KUNNR.
    SELECT SINGLE KUNAG INTO LV_KUNNR FROM LIKP WHERE VBELN = LT_DATA-VBELN.

    " Try converting input to FLOAT
    CLEAR LV_VALUE1.
    LV_STR_VAL = LT_DATA-CMICMIT.
    REPLACE ALL OCCURRENCES OF ',' IN LV_STR_VAL WITH '.'.
    CONDENSE LV_STR_VAL NO-GAPS.

    TRY.
      LV_VALUE1 = LV_STR_VAL.
    CATCH CX_ROOT.
      CLEAR LV_VALUE1.
    ENDTRY.

    " Check existing in ZLOG_COA
    CLEAR WA_ZLOG.
    SELECT SINGLE * INTO WA_ZLOG FROM ZLOG_COA
      WHERE PRUEFLOS = LT_DATA-INSLOT
        AND MIC = LT_DATA-MIC
        AND KUNNR = LV_KUNNR
        AND DELETION <> 'X'.

    DATA: LV_SAVE_REQUIRED TYPE C.
    DATA: LV_MAX_SEQ TYPE ZLOG_COA-SEQ.
    LV_SAVE_REQUIRED = ''.

    IF SY-SUBRC = 0.
      " Data exists in ZLOG_COA. Check if different.
      DATA: LV_ZLOG_STR TYPE C LENGTH 17.
      IF WA_ZLOG-VALUE2 IS NOT INITIAL.
        LV_ZLOG_STR = WA_ZLOG-VALUE2.
      ELSEIF WA_ZLOG-VALUE1 IS NOT INITIAL.
        WRITE WA_ZLOG-VALUE1 TO LV_ZLOG_STR EXPONENT 0 DECIMALS 3 LEFT-JUSTIFIED.
      ENDIF.

      IF LT_DATA-CMICMIT <> LV_ZLOG_STR.
        LV_SAVE_REQUIRED = 'X'.

        " Set old record to deleted
        WA_ZLOG-DELETION = 'X'.
        WA_ZLOG-AEDAT = SY-DATUM.
        WA_ZLOG-PSOTM = SY-UZEIT.
        WA_ZLOG-AENAM = SY-UNAME.
        WA_ZLOG-TERM2 = LV_TERMINAL.
        LT_ZLOG_UPDATE = WA_ZLOG.
        APPEND LT_ZLOG_UPDATE.

        " Create new record
        CLEAR WA_ZLOG.
        WA_ZLOG-PRUEFLOS = LT_DATA-INSLOT.
        WA_ZLOG-MIC = LT_DATA-MIC.
        WA_ZLOG-KUNNR = LV_KUNNR.
        WA_ZLOG-CPUDT = SY-DATUM.
        WA_ZLOG-CPUTM = SY-UZEIT.
        WA_ZLOG-USNAM = SY-UNAME.
        WA_ZLOG-TERM1 = LV_TERMINAL.

        " Get next SEQ
        SELECT SINGLE MAX( SEQ ) INTO LV_MAX_SEQ FROM ZLOG_COA
          WHERE PRUEFLOS = LT_DATA-INSLOT AND MIC = LT_DATA-MIC AND KUNNR = LV_KUNNR.
        WA_ZLOG-SEQ = LV_MAX_SEQ + 1.
      ENDIF.
    ELSE.
      " Not in ZLOG_COA yet. Check if different from ORIGINAL QM VALUE!
      IF LT_DATA-CMICMIT <> LT_DATA-ORIG_CMICMIT.
        LV_SAVE_REQUIRED = 'X'.
        CLEAR WA_ZLOG.
        WA_ZLOG-PRUEFLOS = LT_DATA-INSLOT.
        WA_ZLOG-MIC = LT_DATA-MIC.
        WA_ZLOG-KUNNR = LV_KUNNR.
        WA_ZLOG-CPUDT = SY-DATUM.
        WA_ZLOG-CPUTM = SY-UZEIT.
        WA_ZLOG-USNAM = SY-UNAME.
        WA_ZLOG-TERM1 = LV_TERMINAL.

        " Get next SEQ
        SELECT SINGLE MAX( SEQ ) INTO LV_MAX_SEQ FROM ZLOG_COA
          WHERE PRUEFLOS = LT_DATA-INSLOT AND MIC = LT_DATA-MIC AND KUNNR = LV_KUNNR.
        WA_ZLOG-SEQ = LV_MAX_SEQ + 1.
      ENDIF.
    ENDIF.

    IF LV_SAVE_REQUIRED = 'X'.
      LV_HAS_CHANGES = 'X'.
      " Cek apakah nilai CMICMIT merupakan huruf atau angka
      IF LV_VALUE1 IS NOT INITIAL OR LT_DATA-CMICMIT = '0'.
        WA_ZLOG-VALUE1 = LV_VALUE1.
        WA_ZLOG-VALUE2 = LT_DATA-CMICMIT.
      ELSE.
        WA_ZLOG-VALUE1 = 0.
        WA_ZLOG-VALUE2 = LT_DATA-CMICMIT.
      ENDIF.

      LT_ZLOG_INSERT = WA_ZLOG.
      APPEND LT_ZLOG_INSERT.

      LT_IT_DATA_UPDATE = LT_DATA.
      APPEND LT_IT_DATA_UPDATE.
    ENDIF.
  ENDLOOP.

  " Tahap 2: Konfirmasi dan Simpan
  IF LV_HAS_CHANGES = 'X'.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        TITLEBAR              = 'Konfirmasi Simpan'
        TEXT_QUESTION         = 'Ada perubahan nilai MIC. Apakah Anda yakin ingin menyimpan perubahan ini ke log?'
        TEXT_BUTTON_1         = 'Ya'(001)
        TEXT_BUTTON_2         = 'Tidak'(002)
        DISPLAY_CANCEL_BUTTON = ' '
      IMPORTING
        ANSWER                = LV_ANSWER
      EXCEPTIONS
        TEXT_NOT_FOUND        = 1
        OTHERS                = 2.

    IF LV_ANSWER = '1'.
      " User klik Ya, lakukan update dan insert
      LOOP AT LT_ZLOG_UPDATE.
        MODIFY ZLOG_COA FROM LT_ZLOG_UPDATE.
      ENDLOOP.

      LOOP AT LT_ZLOG_INSERT.
        INSERT ZLOG_COA FROM LT_ZLOG_INSERT.
      ENDLOOP.

      LOOP AT LT_IT_DATA_UPDATE.
        IT_DATA-ORIG_CMICMIT = LT_IT_DATA_UPDATE-CMICMIT.
        IT_DATA-SAVED_CMICMIT = LT_IT_DATA_UPDATE-CMICMIT.
        MODIFY IT_DATA TRANSPORTING ORIG_CMICMIT SAVED_CMICMIT
          WHERE INSLOT = LT_IT_DATA_UPDATE-INSLOT AND MIC = LT_IT_DATA_UPDATE-MIC.
      ENDLOOP.

      COMMIT WORK AND WAIT.
      MESSAGE 'Data saved successfully.' TYPE 'S'.
    ELSE.
      " User klik Tidak
      MESSAGE 'Penyimpanan dibatalkan.' TYPE 'S'.
    ENDIF.
  ELSE.
    " Jika tidak ada perubahan sama sekali, tidak perlu popup konfirmasi
    MESSAGE 'Tidak ada data yang berubah. Tidak ada yang disimpan.' TYPE 'S'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  CANCEL_UD
*&---------------------------------------------------------------------*
FORM CANCEL_UD USING PRUEFLOS CHANGING LS_SUBRC MESS ZSTAT ERR.
  DATA: UDSTAT TYPE C,
        OPT TYPE CTU_PARAMS.

  CLEAR: UDSTAT, LS_SUBRC.
  REFRESH : MESSTAB, BDCDATA.

  "Check UD Status
  SELECT SINGLE QALS~STAT35
    INTO UDSTAT
    FROM QALS
   WHERE PRUEFLOS = PRUEFLOS.

  "If Not UD
  IF UDSTAT NE 'X'.
    LS_SUBRC = 0.
    EXIT.
  ENDIF.

  PERFORM BDC_DYNPRO      USING 'SAPMQEVA'          '0100'.
  PERFORM BDC_FIELD       USING 'BDC_CURSOR'        'QALS-PRUEFLOS'.
  PERFORM BDC_FIELD       USING 'BDC_OKCODE'        '/00'.
  PERFORM BDC_FIELD       USING 'QALS-PRUEFLOS'     PRUEFLOS.
  PERFORM BDC_DYNPRO      USING 'SAPMQEVA'          '0200'.
  PERFORM BDC_FIELD       USING 'BDC_OKCODE'        '=+FC1'.
  PERFORM BDC_FIELD       USING 'BDC_CURSOR'        'RQEVA-MHD_01'.
  PERFORM BDC_DYNPRO      USING 'SAPLSPO1'          '0500'.
  PERFORM BDC_FIELD       USING 'BDC_OKCODE'        '=OPT1'.
  PERFORM BDC_DYNPRO      USING 'SAPMQEVA'          '0200'.
  PERFORM BDC_FIELD       USING 'BDC_OKCODE'        '=BU'.
  PERFORM BDC_FIELD       USING 'BDC_CURSOR'        'RQEVA-MHD_01'.
  PERFORM BDC_DYNPRO      USING 'SAPLSTXX'          '1100'.
  PERFORM BDC_FIELD       USING 'BDC_CURSOR'        'RSTXT-TXLINE(02)'.
  PERFORM BDC_FIELD       USING 'BDC_OKCODE'        '=TXBA'.
  OPT-DISMODE   = 'N'.
  OPT-UPDMODE   = 'S'.
  OPT-DEFSIZE   = 'X'.
  OPT-RACOMMIT  = 'X'.
  OPT-NOBINPT   = ''.
  CALL TRANSACTION 'QA12' USING BDCDATA OPTIONS FROM OPT MESSAGES INTO MESSTAB.
  READ TABLE MESSTAB WITH KEY MSGTYP = 'E'.
  IF SY-SUBRC = 0.
    SELECT SINGLE TEXT INTO MESS FROM T100 WHERE SPRSL = 'E' AND ARBGB = MESSTAB-MSGID AND MSGNR = MESSTAB-MSGNR.
    REPLACE FIRST OCCURRENCE OF '&' IN MESS WITH MESSTAB-MSGV2.
    REPLACE FIRST OCCURRENCE OF '&' IN MESS WITH MESSTAB-MSGV1.
    CONCATENATE 'Cancel UD:' MESS INTO MESS SEPARATED BY SPACE.
    ZSTAT    = 'ERROR'.
    ERR      = 'X'.
    LS_SUBRC = -1.
  ELSE.
    COMMIT WORK AND WAIT.
    LS_SUBRC = 0.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  BDC_DYNPRO
*&---------------------------------------------------------------------*
FORM BDC_DYNPRO USING PROGRAM DYNPRO.
  CLEAR BDCDATA.
  BDCDATA-PROGRAM  = PROGRAM.
  BDCDATA-DYNPRO   = DYNPRO.
  BDCDATA-DYNBEGIN = 'X'.
  APPEND BDCDATA.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  BDC_FIELD
*&---------------------------------------------------------------------*
FORM BDC_FIELD USING FNAM FVAL.
  CLEAR BDCDATA.
  BDCDATA-FNAM = FNAM.
  BDCDATA-FVAL = FVAL.
  APPEND BDCDATA.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  SET_INDICATOR
*&---------------------------------------------------------------------*
FORM SET_INDICATOR USING INDEX COUNT_INDEX PROCESS COUNT_PROCESS TEXT.
  DATA: PERCENT TYPE P.
  CLEAR: PERCENT.
  PERCENT =  ( ( INDEX + ( COUNT_INDEX * PROCESS ) - COUNT_INDEX ) / ( COUNT_INDEX * COUNT_PROCESS ) )  * 100.
  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
    EXPORTING
      PERCENTAGE = PERCENT
      TEXT       = TEXT.
ENDFORM.

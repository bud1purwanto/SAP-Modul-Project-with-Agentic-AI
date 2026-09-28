
*&---------------------------------------------------------------------*
*&  Report     :  ZPPI_CHANGE_JR_NUMBER                                *
*&  Appl. Area :  PP                                                   *
*&  Created by :  ....                                            *
*&  Created on :  15 May 2020                                          *
*&---------------------------------------------------------------------*

REPORT  ZPPI_CHANGE_JR_NUMBER.
TABLES: CRHD.

DATA: OK_CODE LIKE SY-UCOMM,
      SAVE_OK LIKE SY-UCOMM,
      DIALOG_BOX  TYPE REF TO CL_GUI_DIALOGBOX_CONTAINER,
      GRID1  TYPE REF TO CL_GUI_ALV_GRID,
      G_CUSTOM_CONTAINER TYPE REF TO CL_GUI_CUSTOM_CONTAINER,
      GS_LAYOUT TYPE LVC_S_LAYO,
      G_MAX TYPE I VALUE 10,
      GT_FIELDCAT TYPE LVC_T_FCAT,
      GS_VARIANT TYPE DISVARIANT,
      LT_ROW_NO TYPE LVC_T_ROID WITH HEADER LINE.

DATA: GT_STABLE TYPE LVC_S_STBL.

TABLES: ZSEQNUM.
DATA: IT_ZSEQNUM LIKE ZSEQNUM OCCURS 0 WITH HEADER LINE.
DATA: IT_ZLOG_JRNO LIKE ZLOG_JRNO OCCURS 0 WITH HEADER LINE.
DATA: V_LINE LIKE AUSP-ATWRT,
      V_CODE LIKE AUSP-ATWRT,
      V_DATE LIKE AUSP-ATWRT,
      V_SQNO LIKE AUSP-ATWRT,
      V_RSRC LIKE ZSEQNUM-ARBPL,
      V_SQNO2 LIKE AUSP-ATWRT.

DATA: BEGIN OF IT_JRCANCEL OCCURS 0,
      MBLNR       LIKE MSEG-MBLNR,
      ZEILE       LIKE MSEG-ZEILE,
      MJAHR       LIKE MSEG-MJAHR,
      SMBLN       LIKE MSEG-SMBLN,
      SMBLP       LIKE MSEG-SMBLP,
      BWART       LIKE MSEG-BWART,
      BUDAT       LIKE MKPF-BUDAT,
      CPUTM       LIKE MKPF-CPUTM,
   END OF IT_JRCANCEL.

DATA: IT_JREXEC LIKE IT_JRCANCEL OCCURS 0 WITH HEADER LINE.

DATA: IT_FIELD  TYPE STANDARD TABLE OF DFIES,
      WA_FIELD  TYPE DFIES.

DATA: BEGIN OF ITAB OCCURS 0,
        ARBPL   LIKE ZSEQNUM-ARBPL,
        ZMONTH  LIKE ZSEQNUM-ZMONTH,
        ZSEQNO  LIKE ZSEQNUM-ZSEQNO,
        ZSEQNO2 LIKE ZSEQNUM-ZSEQNO,
        WERKS   LIKE CRHD-WERKS,
        KTEXT   LIKE CRTX-KTEXT,
      END OF ITAB.

DATA : V_ARBPL LIKE ZSEQNUM-ARBPL,
       V_ATINN LIKE AUSP-ATINN,
       V_SEQNOW(4),
       V_MSG(50),
       V_JRCANCEL TYPE I,
       V_JREXEC TYPE I.

RANGES : R_CHARG FOR MSEG-CHARG.

SELECTION-SCREEN BEGIN OF BLOCK BLOCK5 WITH FRAME TITLE TEXT-003.
PARAMETER : P_OPTYP1 RADIOBUTTON GROUP GR1 USER-COMMAND AC DEFAULT 'X',
            P_OPTYP2 RADIOBUTTON GROUP GR1.
SELECTION-SCREEN END OF BLOCK BLOCK5.

SELECTION-SCREEN BEGIN OF BLOCK BLOCK1 WITH FRAME TITLE TEXT-001.
PARAMETER : P_ROLJR LIKE AUSP-ATWRT MODIF ID B1.
SELECTION-SCREEN END OF BLOCK BLOCK1.

SELECTION-SCREEN BEGIN OF BLOCK BLOCK2 WITH FRAME TITLE TEXT-003.
SELECT-OPTIONS: S_ARBPL FOR CRHD-ARBPL MODIF ID B2 NO INTERVALS.
SELECTION-SCREEN END OF BLOCK BLOCK2.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR S_ARBPL-LOW.
  PERFORM F_HELPARBPL.

START-OF-SELECTION.
  CALL SCREEN 100.

END-OF-SELECTION.

AT SELECTION-SCREEN OUTPUT.
  IF P_OPTYP1 = 'X'.
    LOOP AT SCREEN.
      IF SCREEN-GROUP1 = 'B2'.
        SCREEN-INPUT = 0.
        SCREEN-ACTIVE = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ELSEIF P_OPTYP2 = 'X'.
    LOOP AT SCREEN.
      IF SCREEN-GROUP1 = 'B1'.
        SCREEN-INPUT = 0.
        SCREEN-ACTIVE = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.
*----------------------------------------------------------------------*
*  MODULE awal OUTPUT
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
MODULE AWAL OUTPUT.
  IF SY-UCOMM = ''.
    PERFORM VALIDATION_DATA.

    IF P_OPTYP1 = 'X'.            "MODE 1
      PERFORM SHOW_DATA.
    ELSEIF P_OPTYP2 = 'X'.        "MODE 2
      PERFORM REPORT_DATA.
    ENDIF.

    PERFORM DISPLAY_ALV.
  ENDIF.
ENDMODULE.                    "awal OUTPUT

*&---------------------------------------------------------------------*
*&      Form  VALIDATION_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM VALIDATION_DATA.
  IF P_OPTYP1 = 'X'.
    IF P_ROLJR IS INITIAL.
      MESSAGE 'Masukkan No Roll!' TYPE 'I'.
      LEAVE TO SCREEN 0.
    ENDIF.
  ELSEIF P_OPTYP2 = 'X'.
    IF S_ARBPL IS INITIAL.
      MESSAGE 'Masukkan Resource!' TYPE 'I'.
      LEAVE TO SCREEN 0.
    ENDIF.
  ENDIF.
ENDFORM.                    "VALIDATION_DATA

*&---------------------------------------------------------------------*
*&      Form  SHOW_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM SHOW_DATA .
  SELECT SINGLE CRHD~ARBPL
     INTO V_ARBPL
     FROM CRHD
       JOIN AFVC ON CRHD~OBJID = AFVC~ARBID
       JOIN AFKO ON AFKO~AUFPL = AFVC~AUFPL
       JOIN MSEG ON MSEG~AUFNR = AFKO~AUFNR
       JOIN MKPF ON MSEG~MBLNR EQ MKPF~MBLNR
                AND MSEG~MJAHR EQ MKPF~MJAHR
     AND MKPF~BKTXT EQ P_ROLJR.

  IF SY-SUBRC NE 0.
    MESSAGE 'Data tidak ditemukan!' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE TO SCREEN 0.
  ENDIF.

  SELECT * INTO TABLE ITAB FROM ZSEQNUM WHERE ARBPL = V_ARBPL.

  LOOP AT ITAB.
    CLEAR: V_LINE, V_CODE, V_DATE, V_SQNO.

    SPLIT P_ROLJR AT ' ' INTO V_LINE V_CODE V_DATE V_SQNO.

    V_SQNO2 = V_SQNO.
    ITAB-ZSEQNO2 = ( V_SQNO2 ) - 1.
    MODIFY ITAB.
  ENDLOOP.
ENDFORM.                    "SHOW_DATA


*&---------------------------------------------------------------------*
*&      Form  VALIDASI_ROLLJR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM VALIDASI_UPDATE_JR.
  CLEAR: V_LINE, V_CODE, V_DATE, V_SQNO, V_RSRC, IT_JRCANCEL, IT_JREXEC, V_LINE, V_CODE, V_DATE, V_SQNO.
  REFRESH: IT_JRCANCEL, IT_JREXEC.

  SPLIT P_ROLJR AT ' ' INTO V_LINE V_CODE V_DATE V_SQNO.

  "Cek JR harus urutan terakhir
  READ TABLE ITAB WITH KEY ZSEQNO = V_SQNO.
  IF SY-SUBRC NE 0.
    MESSAGE 'Roll JR tidak sesuai urutan terakhir..!!' TYPE 'I'.
    LEAVE TO SCREEN 0.
  ENDIF.

  CALL FUNCTION 'CONVERSION_EXIT_ATINN_INPUT'
    EXPORTING
      INPUT  = 'ZZNOMORROLL'
    IMPORTING
      OUTPUT = V_ATINN.

  SELECT MCH1~CHARG AS LOW INTO CORRESPONDING FIELDS OF R_CHARG
  FROM MCH1 JOIN AUSP ON AUSP~OBJEK EQ MCH1~CUOBJ_BM
  WHERE AUSP~ATWRT = P_ROLJR
    AND MCH1~FVDT1 = '00000000'
    AND AUSP~KLART = '023'
    AND AUSP~MAFID = 'O'
    AND AUSP~ATINN = V_ATINN.
    APPEND R_CHARG.
  ENDSELECT.

  IF SY-SUBRC EQ 0.
    R_CHARG-SIGN = 'I'.
    R_CHARG-OPTION = 'EQ'.
    MODIFY R_CHARG TRANSPORTING OPTION SIGN WHERE SIGN = ''.

    SELECT
      MSEG~MBLNR MSEG~MJAHR MSEG~ZEILE MSEG~SMBLN
      MSEG~SJAHR MSEG~SMBLP MSEG~BWART MSEG~CHARG
      MSEG~SGTXT MSEG~ABLAD MSEG~MENGE MKPF~BKTXT
      MKPF~BUDAT MKPF~CPUTM
    INTO CORRESPONDING FIELDS OF TABLE IT_JREXEC
    FROM MSEG
    JOIN MKPF ON MSEG~MBLNR EQ MKPF~MBLNR
     AND MSEG~MJAHR EQ MKPF~MJAHR
   WHERE MSEG~CHARG IN R_CHARG
     AND BWART IN ('101','102').
  ENDIF.

  IT_JRCANCEL[] = IT_JREXEC[].
  DELETE IT_JRCANCEL WHERE SMBLN IS INITIAL.
  DELETE IT_JREXEC WHERE SMBLN IS NOT INITIAL OR BWART EQ '102'.

  DESCRIBE TABLE IT_JREXEC LINES V_JREXEC.
  DESCRIBE TABLE IT_JRCANCEL LINES V_JRCANCEL.

  "Cek JR harus sudah dicancel
  IF IT_JRCANCEL[] IS INITIAL.
    MESSAGE 'Roll JR belum dicancel..!' TYPE 'I'.
    LEAVE TO SCREEN 0.
  ELSEIF V_JREXEC > V_JRCANCEL.
    MESSAGE 'Batch JR belum dicancel semua..!' TYPE 'I'.
    LEAVE TO SCREEN 0.
  ENDIF.

  "Cek bulan mundur JR harus sama dengan bulan sekarang
  READ TABLE ITAB INDEX 1.
  IF ITAB-ZMONTH NE SY-DATUM+4(2) OR V_DATE+0(2) NE SY-DATUM+4(2).
    MESSAGE 'Tidak bisa change selain bulan sekarang..!' TYPE 'I'.
    LEAVE TO SCREEN 0.
  ENDIF.

  "Cek sequence 1, untuk tidak memundurkan sequence 0
  IF ITAB-ZSEQNO EQ 1 OR V_SQNO EQ '001'.
    MESSAGE 'Mundur JR number maksimal 001, tidak dapat mereset ke 000..!' TYPE 'I'.
    LEAVE TO SCREEN 0.
  ENDIF.
ENDFORM.                    " VALIDASI_ROLLJR

*&---------------------------------------------------------------------*
*&      Form  UPDATE_JR_NUMBER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->ZARBPL     text
*      -->ZSQNO      text
*      -->ZMODE      text
*----------------------------------------------------------------------*
FORM UPDATE_JR_NUMBER USING ZARBPL ZSQNO.
  DATA: V_TITLE TYPE  WFCSR_UI_POPUP_TEXT.
  DATA: V_ANS TYPE WFCST_CHAR1,
        V_SQN(4),
        V_WARNING(100).

  SET PF-STATUS 'MAIN100' EXCLUDING 'CHANGE'.

  V_SQN =  ZSQNO - 1.
  CONCATENATE 'Yakin akan mengupdate nomor JR menjadi' V_SQN '?' INTO V_WARNING SEPARATED BY SPACE.

  V_TITLE-TITLEBAR = ''.
  V_TITLE-QUESTION = V_WARNING.

  CALL FUNCTION 'WFCS_POPUP_YES_NO'
    EXPORTING
      PI_UI_POPUP_TEXT  = V_TITLE
    CHANGING
      PE_ANSWER         = V_ANS
    EXCEPTIONS
      ERROR_USING_POPUP = 1
      OTHERS            = 2.

  IF V_ANS <> 1.
    LEAVE TO SCREEN 0.
  ENDIF.

  SELECT SINGLE * INTO IT_ZSEQNUM FROM ZSEQNUM WHERE ARBPL = ZARBPL.

  IT_ZSEQNUM-ZSEQNO = ZSQNO - 1.

  UPDATE ZSEQNUM FROM IT_ZSEQNUM.
  COMMIT WORK.

  IF P_OPTYP1 = 'X'.
    PERFORM INSERT_SQL.
  ENDIF.

  MODIFY ITAB  INDEX 1.

  "Menambahkan LOG
  DATA: VTERM LIKE USR41-TERMINAL.
  CALL FUNCTION 'TERMINAL_ID_GET'
    EXPORTING
      USERNAME             = SY-UNAME
    IMPORTING
      TERMINAL             = IT_ZLOG_JRNO-TERMINAL
    EXCEPTIONS
      MULTIPLE_TERMINAL_ID = 1
      NO_TERMINAL_FOUND    = 2
      OTHERS               = 3.

  IT_ZLOG_JRNO-UNAME = SY-UNAME.
  IT_ZLOG_JRNO-ERDAT = SY-DATUM.
  IT_ZLOG_JRNO-CPUTM = SY-UZEIT.
  IT_ZLOG_JRNO-ARBPL = ITAB-ARBPL.
  IT_ZLOG_JRNO-ZSEQNO1 = ITAB-ZSEQNO.
  IT_ZLOG_JRNO-ZSEQNO2 = ITAB-ZSEQNO2.
  SELECT MAX( ID ) INTO IT_ZLOG_JRNO-ID FROM ZLOG_JRNO.
  IT_ZLOG_JRNO-ID = IT_ZLOG_JRNO-ID + 1.

  INSERT ZLOG_JRNO FROM IT_ZLOG_JRNO.
  COMMIT WORK.

  V_SEQNOW = IT_ZSEQNUM-ZSEQNO.
  CONDENSE V_SEQNOW NO-GAPS.
  CONCATENATE 'JR berhasil diupdate ke' V_SEQNOW '!' INTO V_MSG SEPARATED BY SPACE.
  MESSAGE V_MSG TYPE 'I'.
  LEAVE TO SCREEN 0.

ENDFORM.                    " UPDATE_JR_NUMBER

*&---------------------------------------------------------------------*
*&      Form  REPORT_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM REPORT_DATA.
  CLEAR: ITAB.
  REFRESH: ITAB.

  SELECT
    SQ~ARBPL
    SQ~ZMONTH
    SQ~ZSEQNO
    MD~WERKS
    TX~KTEXT
  INTO CORRESPONDING FIELDS OF TABLE ITAB FROM ZSEQNUM AS SQ
    JOIN CRHD AS MD ON SQ~ARBPL EQ MD~ARBPL
    JOIN CRTX AS TX ON MD~OBJID EQ TX~OBJID
    WHERE SQ~ARBPL IN S_ARBPL.

  DELETE ITAB WHERE ARBPL IS INITIAL.
  SORT ITAB BY ARBPL.

  IF ITAB[] IS INITIAL.
    MESSAGE 'Data tidak ditemukan!' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE TO SCREEN 0.
  ENDIF.

  SET PF-STATUS 'MAIN100' EXCLUDING 'CHANGE'.
ENDFORM.                    "REPORT_DATA

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE USER_COMMAND_0100 INPUT.
  CASE SY-UCOMM.
    WHEN 'EXIT'.
      SET SCREEN 0.
    WHEN 'CHANGE'.
      IF P_OPTYP1 = 'X'.
        PERFORM VALIDASI_UPDATE_JR.
        IF ITAB-ZSEQNO NE V_SQNO - 1.
          PERFORM UPDATE_JR_NUMBER USING V_ARBPL V_SQNO.
        ELSE.
          MESSAGE 'Nomor JR sudah dimundurkan dan sesuai..!' TYPE 'S' DISPLAY LIKE 'E'.
          LEAVE TO SCREEN 0.
        ENDIF.
      ENDIF.
  ENDCASE.

ENDMODULE.                 " USER_COMMAND_0100  INPUT


*&---------------------------------------------------------------------*
*&      Form  display_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM DISPLAY_ALV.
  DATA: LT_EXCLUDE TYPE UI_FUNCTIONS.

  PERFORM PREPARE_LAYOUT CHANGING GS_LAYOUT .
  PERFORM PREPARE_FIELD_CATALOG CHANGING GT_FIELDCAT .

  GS_LAYOUT-STYLEFNAME = 'CELLTAB'.

  CREATE OBJECT GRID1
    EXPORTING
      I_PARENT = DIALOG_BOX.

  CALL METHOD GRID1->SET_TABLE_FOR_FIRST_DISPLAY
    EXPORTING
      IS_LAYOUT            = GS_LAYOUT
      IT_TOOLBAR_EXCLUDING = LT_EXCLUDE
      IS_VARIANT           = GS_VARIANT
      I_SAVE               = 'A'
    CHANGING
      IT_OUTTAB            = ITAB[]
      IT_FIELDCATALOG      = GT_FIELDCAT.

ENDFORM.                    "display_alv


*&---------------------------------------------------------------------*
*&      Form  prepare_layout
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GS_LAYOUT  text
*----------------------------------------------------------------------*
FORM PREPARE_LAYOUT  CHANGING P_GS_LAYOUT TYPE LVC_S_LAYO.
  P_GS_LAYOUT-EDIT = ''.
  P_GS_LAYOUT-SEL_MODE = 'A'.
  GS_VARIANT-REPORT = SY-REPID.
ENDFORM.                    " prepare_layout



*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE STATUS_0100 OUTPUT.
  SET PF-STATUS 'MAIN100'.
  SET TITLEBAR 'MAIN100'.
ENDMODULE.                 " STATUS_0100  OUTPUT


*&---------------------------------------------------------------------*
*&      Form  prepare_field_catalog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_FCAT     text
*----------------------------------------------------------------------*
FORM PREPARE_FIELD_CATALOG  CHANGING P_FCAT TYPE LVC_T_FCAT .
  DATA: V_POS LIKE SY-TABIX.
  DATA M_FIELDCAT TYPE LVC_S_FCAT .

  IF P_OPTYP1 = 'X'.

    CLEAR M_FIELDCAT .
    M_FIELDCAT-COL_POS = V_POS + 1.
    M_FIELDCAT-TABNAME = 'ITAB'.
    M_FIELDCAT-FIELDNAME = 'ARBPL'.
    M_FIELDCAT-OUTPUTLEN = 10.
    M_FIELDCAT-REPTEXT = 'Resource'.
    M_FIELDCAT-KEY = 'X'.
    APPEND M_FIELDCAT TO P_FCAT.

    CLEAR M_FIELDCAT .
    M_FIELDCAT-COL_POS = V_POS + 1.
    M_FIELDCAT-FIELDNAME = 'ZMONTH'.
    M_FIELDCAT-OUTPUTLEN = 8.
    M_FIELDCAT-REPTEXT = 'Month'.
    APPEND M_FIELDCAT TO P_FCAT.

    CLEAR M_FIELDCAT .
    M_FIELDCAT-COL_POS = V_POS + 1.
    M_FIELDCAT-FIELDNAME = 'ZSEQNO'.
    M_FIELDCAT-OUTPUTLEN = 26.
    M_FIELDCAT-REPTEXT = 'JR Number (before Changed)'.
    APPEND M_FIELDCAT TO P_FCAT.

    CLEAR M_FIELDCAT .
    M_FIELDCAT-COL_POS = V_POS + 1.
    M_FIELDCAT-FIELDNAME = 'ZSEQNO2'.
    M_FIELDCAT-OUTPUTLEN = 26.
    M_FIELDCAT-REPTEXT = 'JR Number (after Changed)'.
    APPEND M_FIELDCAT TO P_FCAT.

  ELSEIF P_OPTYP2 = 'X'.

    CLEAR M_FIELDCAT .
    M_FIELDCAT-COL_POS = V_POS + 1.
    M_FIELDCAT-TABNAME = 'ITAB'.
    M_FIELDCAT-FIELDNAME = 'ARBPL'.
    M_FIELDCAT-OUTPUTLEN = 10.
    M_FIELDCAT-REPTEXT = 'Resource'.
    M_FIELDCAT-KEY = 'X'.
    APPEND M_FIELDCAT TO P_FCAT.

    CLEAR M_FIELDCAT .
    M_FIELDCAT-COL_POS = V_POS + 1.
    M_FIELDCAT-TABNAME = 'ITAB'.
    M_FIELDCAT-FIELDNAME = 'KTEXT'.
    M_FIELDCAT-OUTPUTLEN = 15.
    M_FIELDCAT-REPTEXT = 'Description'.
    M_FIELDCAT-KEY = 'X'.
    APPEND M_FIELDCAT TO P_FCAT.

    CLEAR M_FIELDCAT .
    M_FIELDCAT-COL_POS = V_POS + 1.
    M_FIELDCAT-TABNAME = 'ITAB'.
    M_FIELDCAT-FIELDNAME = 'WERKS'.
    M_FIELDCAT-OUTPUTLEN = 8.
    M_FIELDCAT-REPTEXT = 'Plant'.
    M_FIELDCAT-KEY = 'X'.
    APPEND M_FIELDCAT TO P_FCAT.

    CLEAR M_FIELDCAT .
    M_FIELDCAT-COL_POS = V_POS + 1.
    M_FIELDCAT-FIELDNAME = 'ZMONTH'.
    M_FIELDCAT-OUTPUTLEN = 8.
    M_FIELDCAT-REPTEXT = 'Month'.
    APPEND M_FIELDCAT TO P_FCAT.

    CLEAR M_FIELDCAT .
    M_FIELDCAT-COL_POS = V_POS + 1.
    M_FIELDCAT-FIELDNAME = 'ZSEQNO'.
    M_FIELDCAT-OUTPUTLEN = 26.
    M_FIELDCAT-REPTEXT = 'JR Number'.
    APPEND M_FIELDCAT TO P_FCAT.

  ENDIF.
ENDFORM.                    "prepare_field_catalog

*&---------------------------------------------------------------------*
*&      Form  INSERT_SQL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM INSERT_SQL.
  SUBMIT ZTPPR_NEW_LIST_JR WITH S_CHARG IN R_CHARG AND RETURN.
  SUBMIT ZTPPR_JR_DAILY_PROCESS_CV_TH WITH S_CHARG IN R_CHARG AND RETURN.
  SUBMIT ZTPPI_CHANGE_BOM_PO WITH S_CHARG IN R_CHARG AND RETURN.
ENDFORM.                    "INSERT_SQL

*&---------------------------------------------------------------------*
*&      Form  F_HELPARBPL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM F_HELPARBPL.
  DATA: BEGIN OF IT_VHARBPL OCCURS 0,
          ARBPL LIKE CRHD-ARBPL,
        END OF IT_VHARBPL.

  SELECT ARBPL
    INTO CORRESPONDING FIELDS OF TABLE IT_VHARBPL
    FROM ZSEQNUM.

  DELETE ADJACENT DUPLICATES FROM IT_VHARBPL COMPARING ALL FIELDS.

  IF IT_VHARBPL[] IS NOT INITIAL.
    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        RETFIELD     = 'ARBPL'
        WINDOW_TITLE = 'Resource Help List'
        VALUE_ORG    = 'S'
        DYNPPROG     = SY-REPID
        DYNPNR       = SY-DYNNR
        DYNPROFIELD  = 'S_ARBPL'
      TABLES
        VALUE_TAB    = IT_VHARBPL.
  ELSE.
    MESSAGE 'No values found!' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.                    "F_HELPARBPL

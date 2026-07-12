*&---------------------------------------------------------------------*
*&  Report     :  ZPPI_COHVPI                                          *
*&  Appl. Area :  QM                                                   *
*&  Created by :  J. Budi                                              *
*&  Created on :  6 August 2025                                        *
*&---------------------------------------------------------------------*

REPORT  ZPPI_COHVPI.

TYPES: BEGIN OF T_TAB,
       AUFNR          TYPE AUFNR,
       AUART          TYPE AUART,
       START          TYPE PM_ORDGSTRP,
       END            TYPE CO_GLTRP,
       AUTYP          TYPE AUFTYP,
       ERDAT          TYPE ERDAT,
       STATUS         TYPE CHAR100,
       MATNR          TYPE MATNR,           "Material No
       TARGET         TYPE GAMNG,
       TARGET2        TYPE CHAR50,
       MEINS          TYPE MEINS,
       MAKTX          TYPE MAKTX,
       WERKS          TYPE WERKS_D,         "Plant
       LGORT          TYPE LGORT_D,         "Storage Location
       CHARG          TYPE CHARG_D,         "Batch
       MBLNR          TYPE MBLNR,           "Matdoc SR Number
       SMBLN          TYPE MBLNR,           "Matdoc SR Number Cancel
       MJAHR          TYPE MJAHR,           "Matdoc SR Year
       SJAHR          TYPE MJAHR,           "Matdoc SR Year Cancel
       ZEILE          TYPE MBLPO,           "Matdoc SR Item
       SMBLP          TYPE MBLPO,           "Matdoc SR Item Cancel
       BWART          TYPE BWART,           "Movement Type
       COMB_ORD       TYPE AUFNR,
       "Custom ALV
       LINE_COLOR     TYPE C LENGTH 4,      "Color
       BOX,                                 "Choice
       ERR,                                 "Error Mark
       INDC           TYPE C LENGTH 4,      "Indicator
       MESS           TYPE C LENGTH 150,    "Message
       END OF T_TAB.

"For Display
DATA: IT_MOVEMENT TYPE STANDARD TABLE OF T_TAB WITH HEADER LINE.

DATA: IT_CHECK_CANC LIKE IT_MOVEMENT OCCURS 0 WITH HEADER LINE.
DATA: IT_AUFNR      LIKE IT_MOVEMENT OCCURS 0 WITH HEADER LINE.
DATA: ITAB          LIKE IT_MOVEMENT OCCURS 0 WITH HEADER LINE.

"Other Internal Table
DATA: WA_CELL_COLOR   TYPE LVC_S_SCOL,
      CELL_COLOUR     LIKE WA_CELL_COLOR-COLOR-COL,
      L_REF_GRID      TYPE REF TO CL_GUI_ALV_GRID.

CONSTANTS:
      ERROR(4)        TYPE C VALUE '@0A@',       "Error
      SUCCES(4)       TYPE C VALUE '@08@',       "Success
      WARNING(4)      TYPE C VALUE '@09@',       "Warning
      GREY(4)         TYPE C VALUE '@EB@'.       "Grey

"ALV
DATA: OK_CODE         LIKE SY-UCOMM,
      SAVE_OK         LIKE SY-UCOMM,
      DIALOG_BOX      TYPE REF TO CL_GUI_DIALOGBOX_CONTAINER,
      GRID1           TYPE REF TO CL_GUI_ALV_GRID,
      GS_LAYOUT       TYPE LVC_S_LAYO,
      G_MAX           TYPE I VALUE 10,
      GT_FIELDCAT     TYPE LVC_T_FCAT,
      GS_VARIANT      TYPE DISVARIANT,
      LT_ROW_NO       TYPE LVC_T_ROID WITH HEADER LINE.

DATA: TY_EMAIL TYPE AD_SMTPADR,
      V_OBJNR           LIKE AUFK-OBJNR,
      V_ORD_STAT        LIKE BSVX-STTXT.

"Create Order
DATA: TORDER            LIKE BAPI_PI_ORDER_CREATE,
      ORDERO            LIKE BAPI_ORDER_KEY-ORDER_NUMBER,
      TECOORDER         LIKE BAPI_ORDER_KEY OCCURS 0 WITH HEADER LINE,
      IT_TECO           LIKE JSTAT OCCURS 0 WITH HEADER LINE.

CLASS CL_BCS DEFINITION LOAD.
DATA: LO_SEND_REQUEST TYPE REF TO CL_BCS VALUE IS INITIAL,
      LO_DOCUMENT TYPE REF TO CL_DOCUMENT_BCS VALUE IS INITIAL, "document object
      I_TEXT TYPE BCSY_TEXT, "Table for body
      W_TEXT LIKE LINE OF I_TEXT, "work area for message body
      LO_SENDER TYPE REF TO IF_SENDER_BCS VALUE IS INITIAL, "sender
      LO_RECIPIENT TYPE REF TO IF_RECIPIENT_BCS VALUE IS INITIAL. "recipient

DATA: LV_STRING TYPE STRING,
      LV_STRING2 TYPE STRING,
      LV_DATA_STRING TYPE STRING,
      LV_XSTRING TYPE XSTRING,
      LIT_BINARY_CONTENT TYPE SOLIX_TAB,
      L_ATTSUBJECT TYPE SOOD-OBJDES.

"For Return
DATA: IT_RETURN         LIKE STANDARD TABLE OF BAPIRET2 WITH HEADER LINE.
DATA: IT_DETAIL_RETURN  LIKE STANDARD TABLE OF BAPI_ORDER_RETURN WITH HEADER LINE.

INCLUDE ZABAPALV.

TABLES: AUFK, MKPF.


SELECTION-SCREEN BEGIN OF BLOCK BLK1 WITH FRAME TITLE TEXT-001.
SELECT-OPTIONS: S_BUDAT FOR MKPF-BUDAT    MODIF ID B1 OBLIGATORY.
SELECT-OPTIONS: S_AUART FOR AUFK-AUART    MODIF ID B1 NO INTERVALS.
SELECT-OPTIONS: S_AUTYP FOR AUFK-AUTYP    MODIF ID B1 NO INTERVALS.
SELECTION-SCREEN END OF BLOCK BLK1.

SELECTION-SCREEN BEGIN OF BLOCK BLK2 WITH FRAME TITLE TEXT-002.
SELECT-OPTIONS: PA_TO  FOR TY_EMAIL NO INTERVALS OBLIGATORY.
SELECT-OPTIONS: PA_CC  FOR TY_EMAIL NO INTERVALS.
SELECT-OPTIONS: PA_BCC FOR TY_EMAIL NO INTERVALS.
SELECTION-SCREEN END OF BLOCK BLK2.

START-OF-SELECTION.
  PERFORM VALIDATION.
  PERFORM GET_DATA.
*  PERFORM DISPLAY_ALV.
  PERFORM TECO.
  PERFORM REFRESH.
  PERFORM SEND_EMAIL.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*&      Form  VALIDATION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM VALIDATION.
  IF S_BUDAT[] IS INITIAL.
    MESSAGE 'Please fill the parameters!' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

*  IF S_WERKS[] IS INITIAL.
*    MESSAGE 'Please fill plant!' TYPE 'S' DISPLAY LIKE 'E'.
*    LEAVE LIST-PROCESSING.
*  ENDIF.

ENDFORM.                    "VALIDATION

*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM GET_DATA.
  "Get Preview
  SELECT
    MSEG~AUFNR
    AUFK~AUART
    AUFK~AUTYP
    AUFK~ERDAT
    MSEG~MATNR
    MSEG~WERKS
    MSEG~LGORT
    MSEG~CHARG
    MSEG~MBLNR
    MSEG~SMBLN
    MSEG~MJAHR
    MSEG~SJAHR
    MSEG~ZEILE
    MSEG~SMBLP
    MSEG~BWART
    MSEG~WERKS
    INTO CORRESPONDING FIELDS OF TABLE IT_MOVEMENT
    FROM MKPF
    JOIN MSEG ON MSEG~MBLNR EQ MKPF~MBLNR AND MSEG~MJAHR EQ MKPF~MJAHR
    JOIN AUFK ON AUFK~AUFNR EQ MSEG~AUFNR
    JOIN AFPO ON AFPO~AUFNR EQ MSEG~AUFNR
   WHERE MKPF~BUDAT IN S_BUDAT
       AND AUFK~AUART IN S_AUART
       AND AUFK~AUTYP IN S_AUTYP.
*     AND MILL_OC_AUFNR_U EQ ''.
*     AND MSEG~BWART IN (101, 102).

  IT_CHECK_CANC[] = IT_MOVEMENT[].
  "Delete Cancel
  DELETE IT_CHECK_CANC WHERE SMBLN IS INITIAL.
  LOOP AT IT_CHECK_CANC.
    DELETE IT_MOVEMENT WHERE MBLNR EQ IT_CHECK_CANC-SMBLN AND MJAHR EQ IT_CHECK_CANC-SJAHR AND ZEILE EQ IT_CHECK_CANC-SMBLP.
  ENDLOOP.
*  DELETE IT_MOVEMENT WHERE SMBLN IS NOT INITIAL OR BWART EQ 102.

  IT_AUFNR[] = IT_MOVEMENT[].
  SORT IT_AUFNR BY AUFNR.
  DELETE ADJACENT DUPLICATES FROM IT_AUFNR COMPARING AUFNR.
*
*  SELECT * INTO CORRESPONDING FIELDS OF TABLE ITAB
*      FROM AUFK
*     WHERE ERDAT IN S_BUDAT
*       AND AUART IN S_AUART.

  LOOP AT IT_AUFNR.
    MOVE-CORRESPONDING IT_AUFNR TO ITAB.

    PERFORM GET_ORDER_STATUS USING IT_AUFNR-AUFNR CHANGING V_ORD_STAT.
*    IF V_ORD_STAT CP '*TECO*'.
*      DELETE ITAB.
*      CONTINUE.
*    ENDIF.

    SELECT SINGLE AUFNR INTO IT_AUFNR-COMB_ORD FROM AFPO WHERE MILL_OC_AUFNR_U EQ IT_AUFNR-AUFNR.
    IF SY-SUBRC EQ 0.
      IT_AUFNR-STATUS = V_ORD_STAT.
      MODIFY IT_AUFNR.
      CLEAR IT_AUFNR.
    ELSE.
      ITAB-STATUS = V_ORD_STAT.
      APPEND ITAB.
      CLEAR ITAB.
    ENDIF.
  ENDLOOP.

  IF ITAB[] IS INITIAL.
    MESSAGE 'Data not found!' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

  PERFORM REFRESH.
ENDFORM.                    "GET_PREVIEW

*&---------------------------------------------------------------------*
*&      Form  REFRESH
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM REFRESH.
  LOOP AT ITAB.
    CLEAR V_ORD_STAT.

    SELECT SINGLE GAMNG GMEIN GSTRP GLTRP INTO (ITAB-TARGET, ITAB-MEINS, ITAB-START, ITAB-END) FROM AFKO WHERE AUFNR EQ ITAB-AUFNR.

    ITAB-TARGET2 = ITAB-TARGET.
    CONDENSE ITAB-TARGET2 NO-GAPS.

    SELECT SINGLE MAKTX INTO (ITAB-MAKTX) FROM MAKT WHERE MATNR EQ ITAB-MATNR.

    PERFORM GET_ORDER_STATUS USING ITAB-AUFNR CHANGING V_ORD_STAT.
    ITAB-STATUS = V_ORD_STAT.

    IF ITAB-INDC IS INITIAL.
      ITAB-INDC = GREY.
    ENDIF.

    MODIFY ITAB.
    CLEAR ITAB.
  ENDLOOP.
ENDFORM.                    "REFRESH

*&---------------------------------------------------------------------*
*&      Form  TECO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM TECO.
  DATA: LV_RETURN TYPE BAPIRET2.

  LOOP AT ITAB.
    CLEAR:   TECOORDER, IT_RETURN, IT_DETAIL_RETURN, LV_RETURN.
    REFRESH: TECOORDER, IT_RETURN, IT_DETAIL_RETURN.

    IF ITAB-STATUS CP '*REL*'.
      TECOORDER-ORDER_NUMBER = ITAB-AUFNR.
      APPEND TECOORDER.
    ENDIF.

    LOOP AT IT_AUFNR WHERE COMB_ORD EQ ITAB-AUFNR.
      CLEAR V_ORD_STAT.
      PERFORM GET_ORDER_STATUS USING IT_AUFNR-AUFNR CHANGING V_ORD_STAT.
      IF V_ORD_STAT CP '*REL*'.
        TECOORDER-ORDER_NUMBER = IT_AUFNR-AUFNR.
        APPEND TECOORDER.
      ENDIF.
    ENDLOOP.

    IF TECOORDER[] IS INITIAL.
      CONTINUE.
    ENDIF.

    CALL FUNCTION 'BAPI_PROCORD_COMPLETE_TECH'
      EXPORTING
        SCOPE_COMPL_TECH   = '1'
        WORK_PROCESS_GROUP = 'COWORK_BAPI'
        WORK_PROCESS_MAX   = 99
      IMPORTING
        RETURN             = LV_RETURN
      TABLES
        ORDERS             = TECOORDER
        DETAIL_RETURN      = IT_DETAIL_RETURN.

*   Fix #1: evaluasi hasil per-order via DETAIL_RETURN (E=error, A=abort),
*           bukan via struktur RETURN tunggal.
    CLEAR ITAB-MESS.
    IF LV_RETURN-TYPE CA 'EA'.
      ITAB-MESS = LV_RETURN-MESSAGE.
    ENDIF.
    LOOP AT IT_DETAIL_RETURN WHERE TYPE CA 'EA'.
      IF ITAB-MESS IS INITIAL.
        ITAB-MESS = IT_DETAIL_RETURN-MESSAGE.
      ENDIF.
    ENDLOOP.

    IF ITAB-MESS IS NOT INITIAL.
*     Fix #2: ada error -> rollback, jangan commit.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      CONCATENATE 'Teco Orders:' ITAB-MESS INTO ITAB-MESS SEPARATED BY SPACE.
      ITAB-ERR   = 'X'.
      ITAB-INDC  = ERROR.
    ELSE.
*     Bersih -> commit.
      PERFORM COMMIT.
      ITAB-ERR   = ''.
      ITAB-INDC  = SUCCES.
    ENDIF.

    MODIFY ITAB.
    CLEAR ITAB.
  ENDLOOP.
ENDFORM.                    "TECO

*&---------------------------------------------------------------------*
*&      Form  SEND_EMAIL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM SEND_EMAIL.
  DATA : SUBJECT_EMAIL(50).

  CLEAR : W_TEXT.
  REFRESH : I_TEXT.

  SUBJECT_EMAIL = 'Status Process Order September 2025'.

  CONCATENATE 'Status Process Order' SY-DATUM+4(2)'-' SY-DATUM+0(4) INTO SUBJECT_EMAIL SEPARATED BY SPACE.

  LO_SEND_REQUEST = CL_BCS=>CREATE_PERSISTENT( ).
*--Message body and subject
  W_TEXT-LINE = 'Dear All,'.
  APPEND W_TEXT TO I_TEXT.
  CLEAR W_TEXT.

  CONCATENATE '' '' INTO W_TEXT-LINE SEPARATED BY CL_ABAP_CHAR_UTILITIES=>NEWLINE.
  APPEND W_TEXT TO I_TEXT.
  CLEAR W_TEXT.

  CONCATENATE 'Berikut terlampir data PRO yang terdapat movement di bulan' SY-DATUM+4(2) '-' SY-DATUM+0(4) 'dan telah dilakukan TECO' INTO W_TEXT-LINE SEPARATED BY SPACE.
  APPEND W_TEXT TO I_TEXT.
  CLEAR W_TEXT.

  CONCATENATE '' '' INTO W_TEXT-LINE SEPARATED BY CL_ABAP_CHAR_UTILITIES=>NEWLINE.
  APPEND W_TEXT TO I_TEXT.
  CLEAR W_TEXT.

  W_TEXT-LINE = 'Best Regards,'.
  APPEND W_TEXT TO I_TEXT.
  CLEAR W_TEXT.

  CONCATENATE '' '' INTO W_TEXT-LINE SEPARATED BY CL_ABAP_CHAR_UTILITIES=>NEWLINE.
  APPEND W_TEXT TO I_TEXT.
  CLEAR W_TEXT.

  W_TEXT-LINE = SY-UNAME.
  APPEND W_TEXT TO I_TEXT.
  CLEAR W_TEXT.

*  W_TEXT-LINE = 'Please find enclosed herewith the attached file.'.
*  APPEND W_TEXT TO I_TEXT.
*  CLEAR W_TEXT.

  LO_DOCUMENT = CL_DOCUMENT_BCS=>CREATE_DOCUMENT( "create document
  I_TYPE = 'TXT' "TYPE OF DOCUMENT HTM, TXT ETC
  I_TEXT =  I_TEXT "email body internal table
  I_SUBJECT = SUBJECT_EMAIL ). "email subject here p_sub input parameter
* Pass the document to send request
  LO_SEND_REQUEST->SET_DOCUMENT( LO_DOCUMENT ).

  "GENERATE FORMAT TO EXCEL
  CLEAR: LV_DATA_STRING, LV_STRING.

*  LV_DATA_STRING = 'FRSED23B'.
  CONCATENATE 'Indicator' 'Order' 'Material' 'Order Type' 'Plant' 'Target Qty' 'Unit' 'Basic Start' 'Basic Finish' 'System Status' 'Material Description' 'Message'
               INTO LV_STRING SEPARATED BY ','.

  CONCATENATE LV_DATA_STRING LV_STRING INTO LV_DATA_STRING SEPARATED BY CL_ABAP_CHAR_UTILITIES=>NEWLINE.

  LOOP AT ITAB.
    CONCATENATE ITAB-INDC ITAB-AUFNR ITAB-MATNR ITAB-AUART ITAB-WERKS ITAB-TARGET2 ITAB-MEINS ITAB-START ITAB-END ITAB-STATUS ITAB-MAKTX ITAB-MESS
                INTO LV_STRING SEPARATED BY ','.
    CONCATENATE LV_DATA_STRING LV_STRING INTO LV_DATA_STRING SEPARATED BY CL_ABAP_CHAR_UTILITIES=>NEWLINE.
  ENDLOOP.

**Convert string to xstring
  CALL FUNCTION 'HR_KR_STRING_TO_XSTRING'
    EXPORTING
      CODEPAGE_TO      = '4110'
      UNICODE_STRING   = LV_DATA_STRING
*     OUT_LEN          =
    IMPORTING
      XSTRING_STREAM   = LV_XSTRING
    EXCEPTIONS
      INVALID_CODEPAGE = 1
      INVALID_STRING   = 2
      OTHERS           = 3.
  IF SY-SUBRC <> 0.
    IF SY-SUBRC = 1 .

    ELSEIF SY-SUBRC = 2 .
      WRITE:/ 'invalid string ' .
    ENDIF.
  ENDIF.

  CLEAR : LIT_BINARY_CONTENT.
  REFRESH : LIT_BINARY_CONTENT.

***Xstring to binary
  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
    EXPORTING
      BUFFER     = LV_XSTRING
    TABLES
      BINARY_TAB = LIT_BINARY_CONTENT.
**add attachment
  CLEAR L_ATTSUBJECT .
  "CONCATENATE 'FESTA Stock' S_CPUDT-HIGH INTO L_ATTSUBJECT SEPARATED BY SPACE.
  L_ATTSUBJECT = 'TECO Result'.
* Create Attachment
  TRY.
    LO_DOCUMENT->ADD_ATTACHMENT( EXPORTING
                                    I_ATTACHMENT_TYPE = 'CSV'
                                    I_ATTACHMENT_SUBJECT = L_ATTSUBJECT
                                    I_ATT_CONTENT_HEX = LIT_BINARY_CONTENT  ).
*          CATCH cx_document_bcs INTO lx_document_bcs.
  ENDTRY.

  "SET EMAIL SENDER
  TRY.
    LO_SENDER = CL_SAPUSER_BCS=>CREATE('DDIC').
    LO_SEND_REQUEST->SET_SENDER(
    EXPORTING
    I_SENDER = LO_SENDER ).
  ENDTRY.

  "Set Recipient
  IF PA_TO IS NOT INITIAL.
    LOOP AT PA_TO.
      CLEAR LO_RECIPIENT.
      LO_RECIPIENT = CL_CAM_ADDRESS_BCS=>CREATE_INTERNET_ADDRESS( PA_TO-LOW ).
      LO_SEND_REQUEST->ADD_RECIPIENT( I_RECIPIENT = LO_RECIPIENT ).
    ENDLOOP.
  ENDIF.

  "Set CC
  IF PA_CC IS NOT INITIAL.
    LOOP AT PA_CC.
      CLEAR LO_RECIPIENT.
      LO_RECIPIENT = CL_CAM_ADDRESS_BCS=>CREATE_INTERNET_ADDRESS( PA_CC-LOW ).
      LO_SEND_REQUEST->ADD_RECIPIENT( I_RECIPIENT = LO_RECIPIENT
                                   I_COPY      = 'X' ).
    ENDLOOP.
  ENDIF.

  "Set BCC
  IF PA_BCC IS NOT INITIAL.
    LOOP AT PA_BCC.
      CLEAR LO_RECIPIENT.
      LO_RECIPIENT = CL_CAM_ADDRESS_BCS=>CREATE_INTERNET_ADDRESS( PA_BCC-LOW ).
      LO_SEND_REQUEST->ADD_RECIPIENT( I_RECIPIENT  = LO_RECIPIENT
                                   I_BLIND_COPY = 'X').
    ENDLOOP.
  ENDIF.

  TRY.
    "Send email
    LO_SEND_REQUEST->SEND(
    EXPORTING
    I_WITH_ERROR_SCREEN = 'X' ).
    COMMIT WORK.
    IF SY-SUBRC = 0. "mail sent successfully
      WRITE :/ 'Mail for Stock Report Sent Successfully'.
    ENDIF.
*    CATCH CX_SEND_REQ_BCS INTO BCS_EXCEPTION .
*catch exception here
  ENDTRY.
ENDFORM.                    "SEND_EMAIL
*&---------------------------------------------------------------------*
*&      Form  COMMIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM COMMIT.
  CALL FUNCTION 'DB_COMMIT'.
  CALL FUNCTION 'DEQUEUE_ALL'
    EXPORTING
      _SYNCHRON = 'X'.
  COMMIT WORK AND WAIT.

  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      WAIT = 'X'.
ENDFORM.                    "TECO
*&---------------------------------------------------------------------*
*&      Form  GET_ORDER_STATUS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->ORDER      text
*      -->STAT       text
*----------------------------------------------------------------------*
FORM GET_ORDER_STATUS USING ORDER CHANGING STAT.
  CLEAR: V_OBJNR.

  SELECT SINGLE OBJNR INTO V_OBJNR FROM AUFK WHERE AUFNR = ORDER.

  CALL FUNCTION 'AIP9_STATUS_READ'
    EXPORTING
      I_OBJNR = V_OBJNR
      I_SPRAS = SY-LANGU
    IMPORTING
      E_SYSST = STAT.
ENDFORM.                    "GET_ORDER_STATUS
*&---------------------------------------------------------------------*
*&      Form  BAPI_COMMIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM BAPI_COMMIT .
  CALL FUNCTION 'DB_COMMIT'.
  CALL FUNCTION 'DEQUEUE_ALL'
    EXPORTING
      _SYNCHRON = 'X'.
  COMMIT WORK AND WAIT.

  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      WAIT = 'X'.
ENDFORM.                    "BAPI_COMMIT

*&---------------------------------------------------------------------*
*&      Form  SET_CELL_COLOURS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->COLUMN_NAME  text
*      -->REMARK       text
*----------------------------------------------------------------------*
FORM SET_CELL_COLOURS TABLES CELL_COLOUR USING COLUMN_NAME COLOR .
  WA_CELL_COLOR-FNAME = COLUMN_NAME.
  WA_CELL_COLOR-COLOR-COL = COLOR.  "Yellow, Range: 1-7
  WA_CELL_COLOR-COLOR-INT = 1.
  WA_CELL_COLOR-COLOR-INV = 1.
  APPEND WA_CELL_COLOR TO CELL_COLOUR.
  CLEAR: WA_CELL_COLOR.
ENDFORM.                    "SET_CELL_COLOURS

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM DISPLAY_ALV.
  PERFORM F_FIELD_CATALOG_PREVIEW.
  PERFORM F_LAYOUT.
  PERFORM F_LIST_DETAIL_PREVIEW.
ENDFORM.                    "DISPLAY_alv

*&---------------------------------------------------------------------*
*&      Form  F_FIELD_CATALOG_PREVIEW
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM F_FIELD_CATALOG_PREVIEW.
  CLEAR T_FIELDCAT.
  REFRESH: T_FIELDCAT.
  PERFORM F_ALV_FIELDCATG_ICON USING 'ITAB' :
    'INDC'            'X' 'X'  '' '8'    'Indicator'              '' '' '' '',
    'AUFNR'           ''  'X'  '' '12'   'Order Number'           '' '' '' '',
    'AUART'           ''  'X'  '' '8'    'Order Type'             '' '' '' '',
    'ERDAT'           ''  'X'  '' '10'   'Created On'              '' '' '' '',
    'STATUS'          ''  ''   '' '10'   'Status Order'           '' '' '' '',
    'MESS'            ''  ''   '' '50'   'Message'            '' '' '' ''.

  T_FIELDCAT-NO_ZERO = ''.
  MODIFY T_FIELDCAT TRANSPORTING NO_ZERO WHERE FIELDNAME EQ 'AUFNR'.

  T_FIELDCAT-JUST = 'C'.
  MODIFY T_FIELDCAT TRANSPORTING JUST WHERE FIELDNAME NE 'MESS'.

*  T_FIELDCAT-FIX_COLUMN = ''.
*  MODIFY T_FIELDCAT TRANSPORTING FIX_COLUMN WHERE FIELDNAME NE 'MATNR'
*                                              AND FIELDNAME NE 'WERKS'
*                                              AND FIELDNAME NE 'LGORT'
*                                              AND FIELDNAME NE 'CHARG'
*                                              AND FIELDNAME NE 'LGPLA'
*                                              AND FIELDNAME NE 'EXIDV'
*                                              AND FIELDNAME NE 'TYPE'.

ENDFORM.                    "F_FIELD_CATALOG_PREVIEW

*&---------------------------------------------------------------------*
*&      Form  F_LAYOUT_PREVIEW
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM F_LAYOUT.
  CLEAR WA_LAYOUT.
  WA_LAYOUT-ZEBRA                 = 'X'.
  WA_LAYOUT-CONFIRMATION_PROMPT   = ''.
  WA_LAYOUT-SUBTOTALS_TEXT        = 'Sub Total'.
  WA_LAYOUT-TOTALS_TEXT           = 'Total'.
  WA_LAYOUT-BOX_FIELDNAME         = 'BOX'.
  WA_LAYOUT-CELL_MERGE            = 'X'.
  WA_LAYOUT-INFO_FIELDNAME        = 'LINE_COLOR'.
  WA_LAYOUT-COLTAB_FIELDNAME      = 'CELL_COLOR'.
ENDFORM.                    "F_LAYOUT_PREVIEW

*&---------------------------------------------------------------------*
*&      Form  F_LIST_DETAIL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM F_LIST_DETAIL_PREVIEW.
  DATA: LWA_SORT  TYPE LVC_S_SORT.

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
      I_DEFAULT                = 'X'
      I_SAVE                   = 'A'
      IS_VARIANT               = WA_VARIANTE
      IS_PRINT                 = T_PRINT
      IT_SORT                  = T_SORT[]
      IT_EXCLUDING             = T_EXCLUDING[]
      I_BYPASSING_BUFFER       = 'X'
    TABLES
      T_OUTTAB                 = ITAB
    EXCEPTIONS
      PROGRAM_ERROR            = 1
      OTHERS                   = 2.
ENDFORM.                    " f_list_detail


*&---------------------------------------------------------------------
*&      Form  F_GUI_STATUS
*&---------------------------------------------------------------------
FORM F_GUI_STATUS USING FT_EXTAB TYPE SLIS_T_EXTAB.
  DATA: LT_FCODE TYPE TABLE OF SY-UCOMM.

  SET PF-STATUS 'COHVPI'.
  SET TITLEBAR  'COHVPI'.
ENDFORM.                    " F_ALV_STATUS


*&---------------------------------------------------------------------*
*&      Form  F_USER_COMMAND
*&---------------------------------------------------------------------*
FORM F_USER_COMMAND USING FU_UCOMM LIKE SY-UCOMM
                          FU_SELFIELD TYPE SLIS_SELFIELD.

  CASE FU_UCOMM.
    WHEN 'EXEC'.
      PERFORM TECO.
      PERFORM REFRESH.
      PERFORM SEND_EMAIL.
  ENDCASE.

  FU_SELFIELD-REFRESH = 'X'.

ENDFORM.                    "F_USER_COMMAND

*&---------------------------------------------------------------------*
*&      Form  SET_INDICATOR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->INDEX          text
*      -->COUNT_INDEX    text
*      -->PROCESS        text
*      -->COUNT_PROCESS  text
*      -->TEXT           text
*----------------------------------------------------------------------*
FORM SET_INDICATOR USING INDEX COUNT_INDEX PROCESS COUNT_PROCESS TEXT.
  DATA: PERCENT TYPE P.
  CLEAR: PERCENT.
  PERCENT =  ( ( INDEX + ( COUNT_INDEX * PROCESS ) - COUNT_INDEX ) / ( COUNT_INDEX * COUNT_PROCESS ) )  * 100.

  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
    EXPORTING
      PERCENTAGE = PERCENT
      TEXT       = TEXT.
ENDFORM.                    "SET_INDICATOR


*&---------------------------------------------------------------------*
*&      Form  CONVERSION_INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->INPUT      text
*      -->OUTPUT     text
*----------------------------------------------------------------------*
FORM CONVERSION_INPUT USING INPUT CHANGING OUTPUT.
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      INPUT  = INPUT
    IMPORTING
      OUTPUT = OUTPUT.
ENDFORM.                    "CONVERSION_INPUT

*&---------------------------------------------------------------------*
*&      Form  CONVERSION_OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->INPUT      text
*      -->OUTPUT     text
*----------------------------------------------------------------------*
FORM CONVERSION_OUTPUT USING INPUT CHANGING OUTPUT.
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
    EXPORTING
      INPUT  = INPUT
    IMPORTING
      OUTPUT = OUTPUT.
ENDFORM.                    "CONVERSION_OUTPUT

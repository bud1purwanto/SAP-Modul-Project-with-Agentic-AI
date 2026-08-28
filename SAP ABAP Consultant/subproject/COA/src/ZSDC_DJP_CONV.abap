*&---------------------------------------------------------------------*
*& Report  ZSDC_DJP_CONV
*&
*&---------------------------------------------------------------------*
*&
*& develop by fany 10.01.2025
*&---------------------------------------------------------------------*

REPORT  ZSDC_DJP_CONV.

DATA : IT_ZDJP_CONV LIKE ZDJP_CONV OCCURS 0 WITH HEADER LINE.
DATA : V_ERRMSG TYPE STRING.
DATA : V_ANSWER TYPE STRING,
       FILENAME1 TYPE STRING
       .


SELECTION-SCREEN BEGIN OF BLOCK BLOCK1 WITH FRAME TITLE TEXT-001.
*  PARAMETER : P_SOURCE TYPE STRING OBLIGATORY.
PARAMETERS: FILENAME LIKE RLGRAP-FILENAME LOWER CASE MODIF ID B1
DEFAULT 'D:\'.  "'D:/'.
SELECTION-SCREEN END OF BLOCK BLOCK1.

SELECTION-SCREEN PUSHBUTTON /12(79) TEMPL USER-COMMAND TEMPL MODIF ID B1.

INITIALIZATION.
  MOVE 'Download Template' TO TEMPL.

AT SELECTION-SCREEN.
  IF SY-UCOMM = 'TEMPL'.
    PERFORM DOWNLOAD_TEMPLATE.
  ENDIF.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR FILENAME.
  CALL FUNCTION 'WS_FILENAME_GET'
    EXPORTING
      MODE             = 'O'
      TITLE            = 'Select File'
    IMPORTING
      FILENAME         = FILENAME
    EXCEPTIONS
      INV_WINSYS       = 1
      NO_BATCH         = 2
      SELECTION_CANCEL = 3
      SELECTION_ERROR  = 4
      OTHERS           = 5.

START-OF-SELECTION.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      TITLEBAR              = 'Confirmation Dialog'
      TEXT_QUESTION         = 'Are yoou sure wan to upload this file?'
      TEXT_BUTTON_1         = 'Yes'(002)
      TEXT_BUTTON_2         = 'No'(005)
      DEFAULT_BUTTON        = '1'
      DISPLAY_CANCEL_BUTTON = ''
    IMPORTING
      ANSWER                = V_ANSWER.

  IF V_ANSWER EQ 1.
    MOVE FILENAME TO FILENAME1.
    CALL FUNCTION 'GUI_UPLOAD'
      EXPORTING
        FILENAME            = FILENAME1
        FILETYPE            = 'ASC'
        HAS_FIELD_SEPARATOR = 'X'
      TABLES
        DATA_TAB            = IT_ZDJP_CONV
      EXCEPTIONS
        CONVERSION_ERROR    = 1
        INVALID_TABLE_WIDTH = 2
        INVALID_TYPE        = 3
        NO_BATCH            = 4
        UNKNOWN_ERROR       = 5
        FILE_OPEN_ERROR     = 6
        FILE_READ_ERROR     = 7
        OTHERS              = 8.

    IF SY-SUBRC EQ 0.
      LOOP AT IT_ZDJP_CONV.
        SELECT SINGLE COUNT( * ) FROM ZDJP_CONV WHERE OBJECT = IT_ZDJP_CONV-OBJECT AND DJP_VAL = IT_ZDJP_CONV-DJP_VAL AND SAP_VAL = IT_ZDJP_CONV-SAP_VAL. "Check if duplicate
        IF SY-SUBRC EQ 0.
          CONCATENATE 'DATA' IT_ZDJP_CONV-OBJECT IT_ZDJP_CONV-DJP_VAL IT_ZDJP_CONV-SAP_VAL 'IS ALREADY EXISTS ' INTO V_ERRMSG SEPARATED BY SPACE.
          MESSAGE V_ERRMSG TYPE 'I'.
          FILENAME = ''.
          LEAVE LIST-PROCESSING.
          EXIT.
        ENDIF.
      ENDLOOP.
      INSERT ZDJP_CONV CLIENT SPECIFIED FROM TABLE  IT_ZDJP_CONV.
      IF SY-SUBRC EQ 0.
        MESSAGE 'INSERT SUKSES' TYPE 'I'.
      ENDIF.
    ELSE.
      MESSAGE 'FAILED TO LOAD FILE' TYPE 'I'.
    ENDIF.
  ENDIF.

END-OF-SELECTION.
*&---------------------------------------------------------------------*
*&      Form  DOWNLOAD_TEMPLATE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DOWNLOAD_TEMPLATE .
  DATA: V_ERROR TYPE CHAR128.

  CALL FUNCTION 'ZBC_DOWNLOAD_TEMPLATE'
    EXPORTING
      TCODE  = SY-TCODE
      FORMAT = 'xlsx'
    IMPORTING
      ERROR  = V_ERROR.

  IF V_ERROR IS NOT INITIAL.
    MESSAGE V_ERROR TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.                    " DOWNLOAD_TEMPLATE
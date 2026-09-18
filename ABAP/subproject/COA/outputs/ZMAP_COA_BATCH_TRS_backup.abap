*&---------------------------------------------------------------------*
*& Report     :  ZMAP_COA_BATCH                                        *
*& Appl. Area :  QM / SD                                               *
*& Description:  Mapping Atribut Roll/Batch COA Dinamis per Customer   *
*&---------------------------------------------------------------------*

REPORT ZMAP_COA_BATCH.

TABLES: ZQM_COA_CUST_COL, KNA1.

TYPE-POOLS: SLIS, ICON.

*----------------------------------------------------------------------*
* Global Types & Data Declarations
*----------------------------------------------------------------------*
TYPES: BEGIN OF TY_DISPLAY,
         BOX(1)       TYPE C,
         KUNNR        TYPE ZQM_COA_CUST_COL-KUNNR,
         NAME1        TYPE KNA1-NAME1,
         FIELD_NAME   TYPE ZQM_COA_CUST_COL-FIELD_NAME,
         FIELD_LABEL  TYPE ZQM_COA_CUST_COL-FIELD_LABEL,
         COL_SIZE     TYPE ZQM_COA_CUST_COL-COL_SIZE,
         SEQ_NO       TYPE ZQM_COA_CUST_COL-SEQ_NO,
         ACTIVE       TYPE ZQM_COA_CUST_COL-ACTIVE,
         STATUS_TXT   TYPE C LENGTH 40,
         LINE_COLOR   TYPE C LENGTH 4,
         CELLTAB      TYPE LVC_T_STYL,
       END OF TY_DISPLAY.

TYPES: BEGIN OF TY_FIELD_F4,
         FIELD_NAME   TYPE CHAR30,
         FIELD_LABEL  TYPE CHAR40,
         CATEGORY     TYPE CHAR20,
         COL_SIZE     TYPE CHAR1,
       END OF TY_FIELD_F4.

TYPES: BEGIN OF TY_UPLOAD,
         KUNNR       TYPE ZQM_COA_CUST_COL-KUNNR,
         FIELD_NAME  TYPE ZQM_COA_CUST_COL-FIELD_NAME,
         FIELD_LABEL TYPE ZQM_COA_CUST_COL-FIELD_LABEL,
         COL_SIZE    TYPE ZQM_COA_CUST_COL-COL_SIZE,
         SEQ_NO      TYPE ZQM_COA_CUST_COL-SEQ_NO,
         ACTIVE      TYPE ZQM_COA_CUST_COL-ACTIVE,
       END OF TY_UPLOAD.

* Forward declaration for Event Receiver Class
CLASS LCL_EVENT_RECEIVER DEFINITION DEFERRED.

DATA: GT_DISPLAY        TYPE TABLE OF TY_DISPLAY WITH HEADER LINE,
      GT_ORIGINAL       TYPE TABLE OF TY_DISPLAY WITH HEADER LINE,
      GT_FIELD_F4       TYPE TABLE OF TY_FIELD_F4 WITH HEADER LINE,
      GT_UPLOAD         TYPE TABLE OF TY_UPLOAD WITH HEADER LINE,
      GO_EVENT_RECEIVER TYPE REF TO LCL_EVENT_RECEIVER,
      GO_GRID           TYPE REF TO CL_GUI_ALV_GRID.

* ALV Grid Objects
DATA: GS_LAYOUT    TYPE LVC_S_LAYO,
      GT_FIELDCAT  TYPE LVC_T_FCAT.

*----------------------------------------------------------------------*
* Class LCL_EVENT_RECEIVER Definition
*----------------------------------------------------------------------*
CLASS LCL_EVENT_RECEIVER DEFINITION.
  PUBLIC SECTION.
    METHODS:
      HANDLE_TOOLBAR FOR EVENT TOOLBAR OF CL_GUI_ALV_GRID
        IMPORTING E_OBJECT E_INTERACTIVE,
      HANDLE_USER_COMMAND FOR EVENT USER_COMMAND OF CL_GUI_ALV_GRID
        IMPORTING E_UCOMM.
ENDCLASS.

*----------------------------------------------------------------------*
* Selection Screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK BLK0 WITH FRAME TITLE T_BLK0.
PARAMETERS: R_UPL RADIOBUTTON GROUP R_UP USER-COMMAND AC DEFAULT 'X',
            R_CRT RADIOBUTTON GROUP R_UP,
            R_EDT RADIOBUTTON GROUP R_UP,
            R_DSP RADIOBUTTON GROUP R_UP.
SELECTION-SCREEN END OF BLOCK BLK0.

SELECTION-SCREEN BEGIN OF BLOCK BLK_UPL WITH FRAME TITLE T_BLKU.
PARAMETERS: P_FILE TYPE RLGRAP-FILENAME MODIF ID UPL.
SELECTION-SCREEN SKIP 1.
SELECTION-SCREEN PUSHBUTTON /33(35) TEMPL USER-COMMAND TEMPL MODIF ID UPL.
SELECTION-SCREEN END OF BLOCK BLK_UPL.

SELECTION-SCREEN BEGIN OF BLOCK BLK1 WITH FRAME TITLE T_BLK1.
SELECT-OPTIONS: S_KUNNR FOR ZQM_COA_CUST_COL-KUNNR MODIF ID PRM,
                S_NAME1 FOR KNA1-NAME1             MODIF ID PRM.
SELECTION-SCREEN END OF BLOCK BLK1.

SELECTION-SCREEN BEGIN OF BLOCK BLK2 WITH FRAME TITLE T_BLK2.
PARAMETERS: P_DEL AS CHECKBOX DEFAULT 'X' MODIF ID UPL.
SELECTION-SCREEN END OF BLOCK BLK2.

*----------------------------------------------------------------------*
* Initialization & Screen Modification
*----------------------------------------------------------------------*
INITIALIZATION.
  T_BLK0 = 'Processing Mode'.
  T_BLK1 = 'Customer Selection'.
  T_BLK2 = 'Upload Options'.
  T_BLKU = 'Upload File Parameter'.
  MOVE 'Download Template' TO TEMPL.
  PERFORM INIT_FIELD_DICTIONARY.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF R_UPL = 'X'.
      IF SCREEN-GROUP1 = 'PRM'.
        SCREEN-ACTIVE = 0.
      ELSEIF SCREEN-GROUP1 = 'UPL'.
        SCREEN-ACTIVE = 1.
      ENDIF.
    ELSEIF R_CRT = 'X'.
      IF SCREEN-GROUP1 = 'UPL' OR SCREEN-GROUP1 = 'PRM'.
        SCREEN-ACTIVE = 0.
      ENDIF.
    ELSE.
      IF SCREEN-GROUP1 = 'UPL'.
        SCREEN-ACTIVE = 0.
      ELSEIF SCREEN-GROUP1 = 'PRM'.
        SCREEN-ACTIVE = 1.
      ENDIF.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.

AT SELECTION-SCREEN.
  IF SY-UCOMM = 'TEMPL'.
    PERFORM DOWNLOAD_TEMPLATE.
  ENDIF.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR P_FILE.
  CALL FUNCTION 'F4_FILENAME'
    EXPORTING
      PROGRAM_NAME  = SY-CPROG
      DYNPRO_NUMBER = SY-DYNNR
      FIELD_NAME    = 'P_FILE'
    IMPORTING
      FILE_NAME     = P_FILE.

*----------------------------------------------------------------------*
* Start of Selection
*----------------------------------------------------------------------*
START-OF-SELECTION.
  IF R_UPL = 'X'.
    IF P_FILE IS INITIAL.
      MESSAGE 'Silakan pilih file upload terlebih dahulu!' TYPE 'S' DISPLAY LIKE 'E'.
      STOP.
    ENDIF.
    PERFORM UPLOAD_FILE_DATA.
  ELSEIF R_CRT = 'X'.
    PERFORM INIT_CREATE_DATA.
  ELSE. " R_EDT or R_DSP
    PERFORM GET_DATABASE_DATA.
  ENDIF.

  IF GT_DISPLAY[] IS INITIAL AND
     ( R_EDT = 'X' OR R_DSP = 'X' ).
    MESSAGE 'No data' TYPE 'S'.
    STOP.
  ENDIF.

  PERFORM DISPLAY_ALV_GRID.

*----------------------------------------------------------------------*
* Class LCL_EVENT_RECEIVER Implementation
*----------------------------------------------------------------------*
CLASS LCL_EVENT_RECEIVER IMPLEMENTATION.
  METHOD HANDLE_TOOLBAR.
    DATA: LS_TOOLBAR TYPE STB_BUTTON.
    IF R_DSP <> 'X'.
      CLEAR LS_TOOLBAR.
      LS_TOOLBAR-BUTN_TYPE = 3. " Separator
      APPEND LS_TOOLBAR TO E_OBJECT->MT_TOOLBAR.

      CLEAR LS_TOOLBAR.
      LS_TOOLBAR-FUNCTION  = 'DEL_ROW'.
      LS_TOOLBAR-ICON      = ICON_DELETE.
      LS_TOOLBAR-QUICKINFO = 'Delete Selected Row(s) (Hapus Baris)'.
      LS_TOOLBAR-TEXT      = 'Delete Row'.
      APPEND LS_TOOLBAR TO E_OBJECT->MT_TOOLBAR.

      CLEAR LS_TOOLBAR.
      LS_TOOLBAR-FUNCTION  = 'ADD_ROW'.
      LS_TOOLBAR-ICON      = ICON_INSERT_ROW.
      LS_TOOLBAR-QUICKINFO = 'Add Row (Tambah Baris)'.
      LS_TOOLBAR-TEXT      = 'Add Row'.
      APPEND LS_TOOLBAR TO E_OBJECT->MT_TOOLBAR.
    ENDIF.
  ENDMETHOD.

  METHOD HANDLE_USER_COMMAND.
    CASE E_UCOMM.
      WHEN 'DEL_ROW' OR 'DELETE'.
        PERFORM F_DELETE_DATA.
      WHEN 'UNDELETE' OR 'ACTIVATE'.
        PERFORM F_UNDELETE_DATA.
      WHEN 'ADD_ROW'.
        PERFORM ADD_NEW_ROW.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.

*&---------------------------------------------------------------------*
*&      Form  INIT_FIELD_DICTIONARY
*&---------------------------------------------------------------------*
FORM INIT_FIELD_DICTIONARY.
  REFRESH GT_FIELD_F4.
  DEFINE _ADD_F4.
    CLEAR GT_FIELD_F4.
    GT_FIELD_F4-FIELD_NAME   = &1.
    GT_FIELD_F4-FIELD_LABEL  = &2.
    GT_FIELD_F4-CATEGORY     = &3.
    GT_FIELD_F4-COL_SIZE     = &4.
    APPEND GT_FIELD_F4.
  END-OF-DEFINITION.

  _ADD_F4 'DO_NUMBER'           'DO Number'                  'Delivery'     'M'.
  _ADD_F4 'PO_NUMBER'           'PO Number'                  'Order'        'L'.
  _ADD_F4 'HU_NUMBER'           'HU Number'                  'Handling'     'M'.
  _ADD_F4 'NO_PALET'            'No Palet'                   'Packaging'    'M'.
  _ADD_F4 'TYPE'                'Type'                       'Material'     'S'.
  _ADD_F4 'THICK'               'Thick'                      'Dimension'    'S'.
  _ADD_F4 'ROLL_NUMBER'         'Roll Number'                'Identifier'   'L'.
  _ADD_F4 'BATCH_NUMBER'        'Batch Number'               'Identifier'   'M'.
  _ADD_F4 'TEXT_BARCODE'        'Text Barcode'               'Identifier'   'M'.
  _ADD_F4 'WIDTH'               'Width'                      'Dimension'    'S'.
  _ADD_F4 'LENGTH'              'Length'                     'Dimension'    'S'.
  _ADD_F4 'WEIGHT_PER_ROL'      'Weight Per Roll'            'Dimension'    'S'.
  _ADD_F4 'JOINT'               'Joint'                      'Spec'         'S'.
  _ADD_F4 'QTY'                 'Qty'                        'Quantity'     'S'.
  _ADD_F4 'TOTAL_ROLL'          'Total Roll'                 'Quantity'     'S'.
  _ADD_F4 'TOTAL_WEIGHT_PALET'  'Total Weight Per Pallet'    'Quantity'     'S'.
  _ADD_F4 'GG_PART_NUMBER'      'GG Part Number (OPR)'       'Customer Mat' 'M'.
  _ADD_F4 'EXPIRED_DATE'        'Expired Date'               'Date'         'M'.
  _ADD_F4 'PRODUCTION_DATE'     'Production Date'            'Date'         'M'.
  _ADD_F4 'USED_BEFORE'         'Used Before'                'Date'         'M'.
  _ADD_F4 'MANUFACTURING_DATE'  'Manufacturing Date'         'Date'         'M'.
  _ADD_F4 'NUMBER_OF_JOINT'     'Number Of Joint (Splice)'   'Spec'         'S'.
  _ADD_F4 'LENGTH_OF_SPLICE'    'Length Of Splice'           'Spec'         'S'.
  _ADD_F4 'LOT_NUMBER'          'Lot Number'                 'Identifier'   'M'.
  _ADD_F4 'NO_PALET_TRIAS'      'No Palet Trias'             'Packaging'    'M'.
  _ADD_F4 'BARCODE'             'Barcode'                    'Identifier'   'L'.
  _ADD_F4 'SO_NUMBER'           'SO Number'                  'Order'        'M'.
  _ADD_F4 'TREATMENT_IN'        'Treatment IN'               'Spec'         'M'.
  _ADD_F4 'TREATMENT_OUT'       'Treatment OUT'              'Spec'         'M'.
  _ADD_F4 'NO'                  'No'                         'Identifier'   'S'.
  _ADD_F4 'CORE'                'Core'                       'Dimension'    'S'.
ENDFORM.                    " INIT_FIELD_DICTIONARY

*&---------------------------------------------------------------------*
*&      Form  INIT_CREATE_DATA
*&---------------------------------------------------------------------*
FORM INIT_CREATE_DATA.
  REFRESH GT_DISPLAY.
  DATA: LV_IDX TYPE NUMC2,
        LS_STYLE TYPE LVC_S_STYL.
  DO 10 TIMES.
    LV_IDX = SY-INDEX.
    CLEAR GT_DISPLAY.
    GT_DISPLAY-SEQ_NO     = LV_IDX.
    GT_DISPLAY-ACTIVE     = 'X'.
    GT_DISPLAY-STATUS_TXT = 'New Entry'.
    GT_DISPLAY-LINE_COLOR = ''. " Clean default color
    CLEAR LS_STYLE.
    LS_STYLE-FIELDNAME = 'STATUS_TXT'.
    LS_STYLE-STYLE = CL_GUI_ALV_GRID=>MC_STYLE_DISABLED.
    INSERT LS_STYLE INTO TABLE GT_DISPLAY-CELLTAB.
    APPEND GT_DISPLAY.
  ENDDO.
ENDFORM.                    " INIT_CREATE_DATA

*&---------------------------------------------------------------------*
*&      Form  GET_DATABASE_DATA
*&---------------------------------------------------------------------*
FORM GET_DATABASE_DATA.
  DATA: LT_DB TYPE TABLE OF ZQM_COA_CUST_COL WITH HEADER LINE,
        LT_KNA1 TYPE TABLE OF KNA1 WITH HEADER LINE,
        LS_STYLE TYPE LVC_S_STYL.

  REFRESH: GT_DISPLAY.

  IF R_EDT = 'X'.
    " Di Edit mode: Hanya tampilkan record yang ACTIVE = 'X'
    SELECT * FROM ZQM_COA_CUST_COL
      INTO TABLE LT_DB
      WHERE KUNNR IN S_KUNNR
        AND ACTIVE = 'X'
      ORDER BY KUNNR SEQ_NO ASCENDING.
  ELSE.
    " Di Display mode (R_DSP = 'X'): Tampilkan SEMUA record (Active & Inactive)
    SELECT * FROM ZQM_COA_CUST_COL
      INTO TABLE LT_DB
      WHERE KUNNR IN S_KUNNR
      ORDER BY KUNNR SEQ_NO ASCENDING.
  ENDIF.

  IF LT_DB[] IS NOT INITIAL.
    SELECT KUNNR NAME1 FROM KNA1
      INTO CORRESPONDING FIELDS OF TABLE LT_KNA1
      FOR ALL ENTRIES IN LT_DB
      WHERE KUNNR = LT_DB-KUNNR.
  ENDIF.

  LOOP AT LT_DB.
    CLEAR GT_DISPLAY.
    GT_DISPLAY-KUNNR        = LT_DB-KUNNR.
    GT_DISPLAY-FIELD_NAME   = LT_DB-FIELD_NAME.
    GT_DISPLAY-FIELD_LABEL  = LT_DB-FIELD_LABEL.
    GT_DISPLAY-COL_SIZE     = LT_DB-COL_SIZE.
    GT_DISPLAY-SEQ_NO       = LT_DB-SEQ_NO.
    GT_DISPLAY-ACTIVE       = LT_DB-ACTIVE.

    IF GT_DISPLAY-KUNNR = 'DOM_DEFAUL'.
      GT_DISPLAY-NAME1 = 'STANDARD DOMESTIC BASELINE'.
    ELSE.
      READ TABLE LT_KNA1 WITH KEY KUNNR = GT_DISPLAY-KUNNR.
      IF SY-SUBRC = 0.
        GT_DISPLAY-NAME1 = LT_KNA1-NAME1.
      ENDIF.
    ENDIF.

    IF S_NAME1[] IS NOT INITIAL AND GT_DISPLAY-NAME1 NOT IN S_NAME1.
      CONTINUE.
    ENDIF.

    IF GT_DISPLAY-ACTIVE = 'X'.
      GT_DISPLAY-STATUS_TXT = 'Active in Database'.
      GT_DISPLAY-LINE_COLOR = ''.
    ELSE.
      GT_DISPLAY-STATUS_TXT = 'Inactive (Deactivated)'.
      GT_DISPLAY-LINE_COLOR = 'C600'. " Merah untuk Inactive
    ENDIF.

    IF R_EDT = 'X'.
      CLEAR LS_STYLE.
      LS_STYLE-FIELDNAME = 'KUNNR'.
      LS_STYLE-STYLE = CL_GUI_ALV_GRID=>MC_STYLE_DISABLED.
      INSERT LS_STYLE INTO TABLE GT_DISPLAY-CELLTAB.

      CLEAR LS_STYLE.
      LS_STYLE-FIELDNAME = 'NAME1'.
      LS_STYLE-STYLE = CL_GUI_ALV_GRID=>MC_STYLE_DISABLED.
      INSERT LS_STYLE INTO TABLE GT_DISPLAY-CELLTAB.

      CLEAR LS_STYLE.
      LS_STYLE-FIELDNAME = 'FIELD_NAME'.
      LS_STYLE-STYLE = CL_GUI_ALV_GRID=>MC_STYLE_DISABLED.
      INSERT LS_STYLE INTO TABLE GT_DISPLAY-CELLTAB.

      CLEAR LS_STYLE.
      LS_STYLE-FIELDNAME = 'STATUS_TXT'.
      LS_STYLE-STYLE = CL_GUI_ALV_GRID=>MC_STYLE_DISABLED.
      INSERT LS_STYLE INTO TABLE GT_DISPLAY-CELLTAB.
    ENDIF.

    APPEND GT_DISPLAY.
  ENDLOOP.

  GT_ORIGINAL[] = GT_DISPLAY[].
ENDFORM.                    " GET_DATABASE_DATA

*&---------------------------------------------------------------------*
*&      Form  UPLOAD_FILE_DATA
*&---------------------------------------------------------------------*
FORM UPLOAD_FILE_DATA.
  DATA: LV_FILENAME TYPE STRING.
  LV_FILENAME = P_FILE.

  CLEAR GT_UPLOAD[].

  " Upload file TXT/Notepad (Tab-delimited) persis seperti ZMAP_COA_MIC
  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      FILENAME            = LV_FILENAME
      FILETYPE            = 'ASC'
      HAS_FIELD_SEPARATOR = 'X'
    TABLES
      DATA_TAB            = GT_UPLOAD
    EXCEPTIONS
      FILE_OPEN_ERROR     = 1
      FILE_READ_ERROR     = 2
      OTHERS              = 17.

  IF SY-SUBRC <> 0.
    MESSAGE 'Error saat membaca file upload!' TYPE 'I' DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

  CLEAR GT_DISPLAY[].
  DATA: LV_FIRST     TYPE C VALUE 'X',
        LV_HDR_CHECK TYPE STRING.

  LOOP AT GT_UPLOAD.
    IF LV_FIRST = 'X'.
      CLEAR LV_FIRST.
      CONCATENATE GT_UPLOAD-KUNNR GT_UPLOAD-FIELD_NAME INTO LV_HDR_CHECK.
      TRANSLATE LV_HDR_CHECK TO UPPER CASE.
      IF LV_HDR_CHECK CS 'CUSTOMER' OR LV_HDR_CHECK CS 'KUNNR'
         OR LV_HDR_CHECK CS 'ROLL' OR LV_HDR_CHECK CS 'FIELD'.
        CONTINUE.
      ENDIF.
    ENDIF.

    IF GT_UPLOAD-KUNNR IS INITIAL AND GT_UPLOAD-FIELD_NAME IS INITIAL.
      CONTINUE.
    ENDIF.

    CLEAR GT_DISPLAY.
    GT_DISPLAY-KUNNR       = GT_UPLOAD-KUNNR.
    GT_DISPLAY-FIELD_NAME  = GT_UPLOAD-FIELD_NAME.
    GT_DISPLAY-FIELD_LABEL = GT_UPLOAD-FIELD_LABEL.
    GT_DISPLAY-COL_SIZE    = GT_UPLOAD-COL_SIZE.
    GT_DISPLAY-SEQ_NO      = GT_UPLOAD-SEQ_NO.
    GT_DISPLAY-ACTIVE      = GT_UPLOAD-ACTIVE.

    PERFORM VALIDATE_UPLOAD_RECORD.
  ENDLOOP.
ENDFORM.                    " UPLOAD_FILE_DATA

*&---------------------------------------------------------------------*
*&      Form  VALIDATE_UPLOAD_RECORD
*&---------------------------------------------------------------------*
FORM VALIDATE_UPLOAD_RECORD.
  DATA: LV_ERR     TYPE C VALUE ' ',
        LV_ERR_MSG TYPE C LENGTH 40,
        LS_F4      TYPE TY_FIELD_F4.

  CONDENSE GT_DISPLAY-KUNNR.
  CONDENSE GT_DISPLAY-FIELD_NAME.
  CONDENSE GT_DISPLAY-FIELD_LABEL.
  CONDENSE GT_DISPLAY-COL_SIZE.
  CONDENSE GT_DISPLAY-SEQ_NO.
  CONDENSE GT_DISPLAY-ACTIVE.

  TRANSLATE GT_DISPLAY-FIELD_NAME TO UPPER CASE.
  TRANSLATE GT_DISPLAY-COL_SIZE   TO UPPER CASE.
  TRANSLATE GT_DISPLAY-ACTIVE     TO UPPER CASE.

  " Format leading zeros untuk customer jika numerik
  IF GT_DISPLAY-KUNNR IS NOT INITIAL AND GT_DISPLAY-KUNNR <> 'DOM_DEFAUL'.
    IF GT_DISPLAY-KUNNR CO '0123456789 '.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          INPUT  = GT_DISPLAY-KUNNR
        IMPORTING
          OUTPUT = GT_DISPLAY-KUNNR.
    ENDIF.
  ENDIF.

  " Default Active = 'X' jika kosong atau bernilai positif
  IF GT_DISPLAY-ACTIVE IS INITIAL OR GT_DISPLAY-ACTIVE = 'V'
     OR GT_DISPLAY-ACTIVE = '1'   OR GT_DISPLAY-ACTIVE = 'Y'.
    GT_DISPLAY-ACTIVE = 'X'.
  ENDIF.

  " 1. Validasi Customer Code
  IF GT_DISPLAY-KUNNR IS INITIAL.
    LV_ERR     = 'X'.
    LV_ERR_MSG = 'Customer Code kosong'.
  ELSEIF GT_DISPLAY-KUNNR = 'DOM_DEFAUL'.
    GT_DISPLAY-NAME1 = 'STANDARD DOMESTIC BASELINE'.
  ELSE.
    SELECT SINGLE NAME1 FROM KNA1 INTO GT_DISPLAY-NAME1 WHERE KUNNR = GT_DISPLAY-KUNNR.
    IF SY-SUBRC <> 0.
      LV_ERR     = 'X'.
      LV_ERR_MSG = 'Customer tidak ditemukan di KNA1'.
    ENDIF.
  ENDIF.

  " 2. Validasi Roll Field
  IF LV_ERR IS INITIAL.
    IF GT_DISPLAY-FIELD_NAME IS INITIAL.
      LV_ERR     = 'X'.
      LV_ERR_MSG = 'Roll Field kosong'.
    ELSE.
      READ TABLE GT_FIELD_F4 INTO LS_F4 WITH KEY FIELD_NAME = GT_DISPLAY-FIELD_NAME.
      IF SY-SUBRC <> 0.
        READ TABLE GT_FIELD_F4 INTO LS_F4 WITH KEY FIELD_LABEL = GT_DISPLAY-FIELD_NAME.
        IF SY-SUBRC = 0.
          GT_DISPLAY-FIELD_NAME = LS_F4-FIELD_NAME.
        ELSE.
          LV_ERR     = 'X'.
          LV_ERR_MSG = 'Roll Field tidak terdaftar'.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

  " Default Label & Size jika belum diisi dari dictionary F4
  IF LS_F4-FIELD_NAME IS NOT INITIAL.
    IF GT_DISPLAY-FIELD_LABEL IS INITIAL.
      GT_DISPLAY-FIELD_LABEL = LS_F4-FIELD_LABEL.
    ENDIF.
    IF GT_DISPLAY-COL_SIZE IS INITIAL.
      GT_DISPLAY-COL_SIZE = LS_F4-COL_SIZE.
    ENDIF.
  ENDIF.

  " 3. Validasi COL_SIZE (Harus S, M, atau L)
  IF LV_ERR IS INITIAL.
    IF GT_DISPLAY-COL_SIZE IS NOT INITIAL
       AND GT_DISPLAY-COL_SIZE <> 'S'
       AND GT_DISPLAY-COL_SIZE <> 'M'
       AND GT_DISPLAY-COL_SIZE <> 'L'.
      LV_ERR     = 'X'.
      LV_ERR_MSG = 'Size tidak valid (Harus S/M/L)'.
    ENDIF.
  ENDIF.

  " 4. Validasi Duplikasi Customer + Field Name di tabel upload
  IF LV_ERR IS INITIAL.
    READ TABLE GT_DISPLAY WITH KEY KUNNR      = GT_DISPLAY-KUNNR
                                   FIELD_NAME = GT_DISPLAY-FIELD_NAME.
    IF SY-SUBRC = 0.
      LV_ERR     = 'X'.
      LV_ERR_MSG = 'Duplikat Customer & Roll Field'.
    ENDIF.
  ENDIF.

  " 5. Tentukan Status & Warna Baris
  IF LV_ERR = 'X'.
    GT_DISPLAY-STATUS_TXT = LV_ERR_MSG.
    GT_DISPLAY-LINE_COLOR = 'C600'. " Merah (Gagal)
  ELSE.
    GT_DISPLAY-STATUS_TXT = 'Uploaded (Ready to Save)'.
    GT_DISPLAY-LINE_COLOR = 'C300'. " Kuning (Siap simpan)
  ENDIF.

  APPEND GT_DISPLAY.
ENDFORM.                    " VALIDATE_UPLOAD_RECORD

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV_GRID
*&---------------------------------------------------------------------*
FORM DISPLAY_ALV_GRID.
  DATA: LT_EVENTS TYPE SLIS_T_EVENT,
        LS_EVENT  TYPE SLIS_ALV_EVENT.

  PERFORM BUILD_FIELDCAT.
  PERFORM BUILD_LAYOUT.

  CLEAR LS_EVENT.
  LS_EVENT-NAME = SLIS_EV_CALLER_EXIT_AT_START.
  LS_EVENT-FORM = 'CALLER_EXIT'.
  APPEND LS_EVENT TO LT_EVENTS.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      I_CALLBACK_PROGRAM       = SY-REPID
      I_CALLBACK_PF_STATUS_SET = 'SET_PF_STATUS'
      I_CALLBACK_USER_COMMAND  = 'USER_COMMAND'
      IS_LAYOUT_LVC            = GS_LAYOUT
      IT_FIELDCAT_LVC          = GT_FIELDCAT
      IT_EVENTS                = LT_EVENTS
      I_SAVE                   = 'A'
    TABLES
      T_OUTTAB                 = GT_DISPLAY
    EXCEPTIONS
      PROGRAM_ERROR            = 1
      OTHERS                   = 2.
ENDFORM.                    " DISPLAY_ALV_GRID

*&---------------------------------------------------------------------*
*&      Form  CALLER_EXIT
*&---------------------------------------------------------------------*
FORM CALLER_EXIT USING E_GRID TYPE SLIS_DATA_CALLER_EXIT.
  DATA: LT_DROP TYPE LVC_T_DROP,
        LS_DROP TYPE LVC_S_DROP.

  CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
    IMPORTING
      E_GRID = GO_GRID.

  IF GO_GRID IS BOUND.
    IF GO_EVENT_RECEIVER IS INITIAL.
      CREATE OBJECT GO_EVENT_RECEIVER.
    ENDIF.
    SET HANDLER GO_EVENT_RECEIVER->HANDLE_TOOLBAR FOR GO_GRID.
    SET HANDLER GO_EVENT_RECEIVER->HANDLE_USER_COMMAND FOR GO_GRID.

    CLEAR LS_DROP.
    LS_DROP-HANDLE = 1.
    LS_DROP-VALUE = 'S'.
    APPEND LS_DROP TO LT_DROP.
    LS_DROP-VALUE = 'M'.
    APPEND LS_DROP TO LT_DROP.
    LS_DROP-VALUE = 'L'.
    APPEND LS_DROP TO LT_DROP.
    CALL METHOD GO_GRID->SET_DROP_DOWN_TABLE
      EXPORTING
        IT_DROP_DOWN = LT_DROP.
  ENDIF.
ENDFORM.                    " CALLER_EXIT

*&---------------------------------------------------------------------*
*&      Form  SET_PF_STATUS
*&---------------------------------------------------------------------*
FORM SET_PF_STATUS USING RT_EXTAB TYPE SLIS_T_EXTAB.
  IF R_CRT = 'X' OR R_UPL = 'X'.
    SET TITLEBAR 'MAIN101'.
    SET PF-STATUS 'MAIN101' EXCLUDING RT_EXTAB.
  ELSEIF R_EDT = 'X'.
    SET TITLEBAR 'MAIN102'.
    SET PF-STATUS 'MAIN102' EXCLUDING RT_EXTAB.
  ELSEIF R_DSP = 'X'.
    SET TITLEBAR 'MAIN103'.
    SET PF-STATUS 'MAIN103' EXCLUDING RT_EXTAB.
  ENDIF.
ENDFORM.                    " SET_PF_STATUS

*&---------------------------------------------------------------------*
*&      Form  USER_COMMAND
*&---------------------------------------------------------------------*
FORM USER_COMMAND USING R_UCOMM LIKE SY-UCOMM
                        RS_SELFIELD TYPE SLIS_SELFIELD.
  CASE R_UCOMM.
    WHEN 'DELETE' OR 'DEL_ROW' OR 'DEL'.
      PERFORM F_DELETE_DATA.
      RS_SELFIELD-REFRESH = 'X'.
    WHEN 'UNDELETE' OR 'ACTIVATE' OR 'UN_DEL'.
      PERFORM F_UNDELETE_DATA.
      RS_SELFIELD-REFRESH = 'X'.
    WHEN 'CHANGE' OR 'CREATE' OR 'SAVE' OR '&DATA_SAVE'.
      PERFORM SAVE_DATABASE_CHANGES.
      RS_SELFIELD-REFRESH = 'X'.
    WHEN 'RELOAD'.
      PERFORM GET_DATABASE_DATA.
      RS_SELFIELD-REFRESH = 'X'.
    WHEN 'CLEAR'.
      PERFORM F_CLEAR_DATA.
      RS_SELFIELD-REFRESH = 'X'.
    WHEN 'ADD_ROW' OR 'ADD' OR 'INSERT'.
      PERFORM ADD_NEW_ROW.
      RS_SELFIELD-REFRESH = 'X'.
    WHEN 'EXIT' OR 'BACK' OR 'CANCEL' OR '&F03' OR '&F15' OR '&F12'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDFORM.                    " USER_COMMAND

*&---------------------------------------------------------------------*
*&      Form  BUILD_FIELDCAT
*&---------------------------------------------------------------------*
FORM BUILD_FIELDCAT.
  REFRESH GT_FIELDCAT.
  DATA: LS_FCAT TYPE LVC_S_FCAT.
  DATA: LV_EDIT     TYPE C VALUE ' ',
        LV_KEY_EDIT TYPE C VALUE ' '.

  IF R_CRT = 'X' OR R_EDT = 'X' OR R_UPL = 'X'.
    LV_EDIT = 'X'.
  ENDIF.

  IF R_CRT = 'X' OR R_UPL = 'X'.
    LV_KEY_EDIT = 'X'.
  ENDIF.

  DEFINE _ADD_FCAT.
    CLEAR LS_FCAT.
    LS_FCAT-FIELDNAME = &1.
    LS_FCAT-COLTEXT   = &2.
    LS_FCAT-OUTPUTLEN = &3.
    LS_FCAT-EDIT      = &4.
    LS_FCAT-F4AVAILABL = &5.
    APPEND LS_FCAT TO GT_FIELDCAT.
  END-OF-DEFINITION.

  _ADD_FCAT 'KUNNR'        'Customer Code'    12  LV_KEY_EDIT 'X'.
  IF R_CRT <> 'X'.
    _ADD_FCAT 'NAME1'      'Customer Name'    30  ' '         ' '.
  ENDIF.
  _ADD_FCAT 'FIELD_NAME'   'Roll Field (F4)'  20  LV_KEY_EDIT 'X'.
  _ADD_FCAT 'FIELD_LABEL'  'Header Label'     25  LV_EDIT ' '.
  _ADD_FCAT 'COL_SIZE'     'Size (S/M/L)'       8  LV_EDIT ' '.
  READ TABLE GT_FIELDCAT INTO LS_FCAT WITH KEY FIELDNAME = 'COL_SIZE'.
  IF SY-SUBRC = 0.
    LS_FCAT-DRDN_HNDL = 1.
    MODIFY GT_FIELDCAT FROM LS_FCAT INDEX SY-TABIX.
  ENDIF.
  _ADD_FCAT 'SEQ_NO'       'Seq'              5   LV_EDIT ' '.
  _ADD_FCAT 'ACTIVE'       'Act'              4   LV_EDIT ' '.
  _ADD_FCAT 'STATUS_TXT'   'Status'           35  ' '     ' '.
ENDFORM.                    " BUILD_FIELDCAT

*&---------------------------------------------------------------------*
*&      Form  BUILD_LAYOUT
*&---------------------------------------------------------------------*
FORM BUILD_LAYOUT.
  CLEAR GS_LAYOUT.
  GS_LAYOUT-ZEBRA      = 'X'.
  GS_LAYOUT-CWIDTH_OPT = 'X'.
  GS_LAYOUT-BOX_FNAME  = 'BOX'.
  GS_LAYOUT-INFO_FNAME = 'LINE_COLOR'.
  GS_LAYOUT-STYLEFNAME = 'CELLTAB'.
  IF R_CRT = 'X'.
    GS_LAYOUT-GRID_TITLE = 'Create COA Batch Mapping'.
  ELSEIF R_EDT = 'X'.
    GS_LAYOUT-GRID_TITLE = 'Edit COA Batch Mapping'.
  ELSEIF R_DSP = 'X'.
    GS_LAYOUT-GRID_TITLE = 'Display COA Batch Mapping'.
  ELSEIF R_UPL = 'X'.
    GS_LAYOUT-GRID_TITLE = 'Upload COA Batch Mapping'.
  ENDIF.
  IF R_CRT = 'X' OR R_EDT = 'X' OR R_UPL = 'X'.
    GS_LAYOUT-EDIT = 'X'.
  ENDIF.
ENDFORM.                    " BUILD_LAYOUT

*&---------------------------------------------------------------------*
*&      Form  F_DELETE_DATA
*&---------------------------------------------------------------------*
FORM F_DELETE_DATA.
  IF GO_GRID IS BOUND.
    GO_GRID->CHECK_CHANGED_DATA( ).
  ENDIF.

  DATA: V_ANS TYPE C,
        LV_DELETED TYPE I VALUE 0.

  " 1. Cek baris yang dicentang
  READ TABLE GT_DISPLAY WITH KEY BOX = 'X'.
  IF SY-SUBRC <> 0.
    MESSAGE 'Pilih/centang baris yang ingin dihapus terlebih dahulu.' TYPE 'S' DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

  " 2. Konfirmasi Popup seperti ZMAP_COA_MIC
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      TITLEBAR              = 'Confirmation'
      TEXT_QUESTION         = 'Are you sure want to delete data?'
      TEXT_BUTTON_1         = 'Yes'
      TEXT_BUTTON_2         = 'No'
      DEFAULT_BUTTON        = '2'
      DISPLAY_CANCEL_BUTTON = ''
    IMPORTING
      ANSWER                = V_ANS.

  IF V_ANS <> '1'.
    EXIT.
  ENDIF.

  " 3. Hapus data di DB: set ACTIVE = ' '
  LOOP AT GT_DISPLAY WHERE BOX = 'X'.
    UPDATE ZQM_COA_CUST_COL
      SET ACTIVE = ' '
      WHERE KUNNR = GT_DISPLAY-KUNNR
        AND FIELD_NAME = GT_DISPLAY-FIELD_NAME.
    IF SY-SUBRC = 0.
      LV_DELETED = LV_DELETED + 1.
    ENDIF.
  ENDLOOP.

  IF LV_DELETED > 0.
    COMMIT WORK AND WAIT.
    " Hapus dari tampilan edit karena edit mode hanya menampilkan ACTIVE = 'X'
    DELETE GT_DISPLAY WHERE BOX = 'X'.
    MESSAGE 'Baris mapping berhasil dihapus (dinonaktifkan).' TYPE 'S'.
  ELSE.
    DELETE GT_DISPLAY WHERE BOX = 'X'.
    MESSAGE 'Baris berhasil dihapus dari tabel.' TYPE 'S'.
  ENDIF.

  IF GO_GRID IS BOUND.
    DATA: LS_STBL TYPE LVC_S_STBL.
    LS_STBL-ROW = 'X'.
    LS_STBL-COL = 'X'.
    GO_GRID->REFRESH_TABLE_DISPLAY( IS_STABLE = LS_STBL ).
  ENDIF.
ENDFORM.                    " F_DELETE_DATA

*&---------------------------------------------------------------------*
*&      Form  F_UNDELETE_DATA
*&---------------------------------------------------------------------*
FORM F_UNDELETE_DATA.
  IF GO_GRID IS BOUND.
    GO_GRID->CHECK_CHANGED_DATA( ).
  ENDIF.

  DATA: V_ANS TYPE C,
        LV_ACTIVATED TYPE I VALUE 0.

  " 1. Cek baris yang dicentang
  READ TABLE GT_DISPLAY WITH KEY BOX = 'X'.
  IF SY-SUBRC <> 0.
    MESSAGE 'Pilih/centang baris yang ingin diaktifkan terlebih dahulu.' TYPE 'S' DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

  " 2. Konfirmasi Popup
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      TITLEBAR              = 'Confirmation'
      TEXT_QUESTION         = 'Are you sure want to activate data?'
      TEXT_BUTTON_1         = 'Yes'
      TEXT_BUTTON_2         = 'No'
      DEFAULT_BUTTON        = '2'
      DISPLAY_CANCEL_BUTTON = ''
    IMPORTING
      ANSWER                = V_ANS.

  IF V_ANS <> '1'.
    EXIT.
  ENDIF.

  " 3. Update DB: set ACTIVE = 'X'
  LOOP AT GT_DISPLAY WHERE BOX = 'X'.
    UPDATE ZQM_COA_CUST_COL
      SET ACTIVE = 'X'
      WHERE KUNNR = GT_DISPLAY-KUNNR
        AND FIELD_NAME = GT_DISPLAY-FIELD_NAME.
    IF SY-SUBRC = 0.
      GT_DISPLAY-ACTIVE     = 'X'.
      GT_DISPLAY-STATUS_TXT = 'Active in Database'.
      GT_DISPLAY-LINE_COLOR = ''.
      GT_DISPLAY-BOX        = ' '.
      MODIFY GT_DISPLAY.
      LV_ACTIVATED = LV_ACTIVATED + 1.
    ENDIF.
  ENDLOOP.

  IF LV_ACTIVATED > 0.
    COMMIT WORK AND WAIT.
    MESSAGE 'Baris mapping berhasil diaktifkan kembali.' TYPE 'S'.
  ENDIF.

  IF GO_GRID IS BOUND.
    DATA: LS_STBL TYPE LVC_S_STBL.
    LS_STBL-ROW = 'X'.
    LS_STBL-COL = 'X'.
    GO_GRID->REFRESH_TABLE_DISPLAY( IS_STABLE = LS_STBL ).
  ENDIF.
ENDFORM.                    " F_UNDELETE_DATA

*&---------------------------------------------------------------------*
*&      Form  F_CLEAR_DATA
*&---------------------------------------------------------------------*
FORM F_CLEAR_DATA.
  REFRESH GT_DISPLAY.
  IF GO_GRID IS BOUND.
    DATA: LS_STBL TYPE LVC_S_STBL.
    LS_STBL-ROW = 'X'.
    LS_STBL-COL = 'X'.
    GO_GRID->REFRESH_TABLE_DISPLAY( IS_STABLE = LS_STBL ).
  ENDIF.
ENDFORM.                    " F_CLEAR_DATA

*&---------------------------------------------------------------------*
*&      Form  ADD_NEW_ROW
*&---------------------------------------------------------------------*
FORM ADD_NEW_ROW.
  IF GO_GRID IS BOUND.
    GO_GRID->CHECK_CHANGED_DATA( ).
  ENDIF.

  DATA: LV_MAX_SEQ TYPE NUMC2 VALUE 0,
        LV_KUNNR   TYPE KUNNR,
        LV_NAME1   TYPE KNA1-NAME1,
        LS_STYLE   TYPE LVC_S_STYL.

  LOOP AT GT_DISPLAY.
    IF GT_DISPLAY-KUNNR IS NOT INITIAL.
      LV_KUNNR = GT_DISPLAY-KUNNR.
      LV_NAME1 = GT_DISPLAY-NAME1.
    ENDIF.
    IF GT_DISPLAY-SEQ_NO > LV_MAX_SEQ.
      LV_MAX_SEQ = GT_DISPLAY-SEQ_NO.
    ENDIF.
  ENDLOOP.

  LV_MAX_SEQ = LV_MAX_SEQ + 1.

  CLEAR GT_DISPLAY.
  GT_DISPLAY-KUNNR        = LV_KUNNR.
  GT_DISPLAY-NAME1        = LV_NAME1.
  GT_DISPLAY-SEQ_NO       = LV_MAX_SEQ.
  GT_DISPLAY-ACTIVE       = 'X'.
  GT_DISPLAY-STATUS_TXT   = 'New Entry (Unsaved)'.
  GT_DISPLAY-LINE_COLOR   = 'C300'. " Yellow
  IF R_CRT = 'X' OR R_EDT = 'X'.
    CLEAR LS_STYLE.
    LS_STYLE-FIELDNAME = 'STATUS_TXT'.
    LS_STYLE-STYLE = CL_GUI_ALV_GRID=>MC_STYLE_DISABLED.
    INSERT LS_STYLE INTO TABLE GT_DISPLAY-CELLTAB.
  ENDIF.
  APPEND GT_DISPLAY.

  IF GO_GRID IS BOUND.
    DATA: LS_STBL TYPE LVC_S_STBL.
    LS_STBL-ROW = 'X'.
    LS_STBL-COL = 'X'.
    GO_GRID->REFRESH_TABLE_DISPLAY( IS_STABLE = LS_STBL ).
  ENDIF.

  MESSAGE 'Baris baru ditambahkan.' TYPE 'S'.
ENDFORM.                    " ADD_NEW_ROW

*&---------------------------------------------------------------------*
*&      Form  DOWNLOAD_TEMPLATE
*&---------------------------------------------------------------------*
FORM DOWNLOAD_TEMPLATE.
  DATA: V_ERROR  TYPE CHAR128,
        LV_TCODE TYPE TCODE.

  LV_TCODE = SY-TCODE.
  IF LV_TCODE = 'SE38' OR LV_TCODE = 'SA38' OR LV_TCODE IS INITIAL.
    LV_TCODE = 'ZQM001'.
  ENDIF.

  CALL FUNCTION 'ZBC_DOWNLOAD_TEMPLATE'
    EXPORTING
      TCODE  = LV_TCODE
      FORMAT = 'xlsx'
    IMPORTING
      ERROR  = V_ERROR.

  IF V_ERROR IS NOT INITIAL.
    MESSAGE V_ERROR TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.                    " DOWNLOAD_TEMPLATE

*&---------------------------------------------------------------------*
*&      Form  SAVE_DATABASE_CHANGES
*&---------------------------------------------------------------------*
FORM SAVE_DATABASE_CHANGES.
  IF GO_GRID IS BOUND.
    GO_GRID->CHECK_CHANGED_DATA( ).
  ENDIF.

  DATA: LT_INS      TYPE TABLE OF ZQM_COA_CUST_COL WITH HEADER LINE,
        LV_COUNT    TYPE I,
        LS_F4_CHK   TYPE TY_FIELD_F4,
        LV_HAS_ERR  TYPE C VALUE ' '.

  " Re-validasi baris sebelum menyimpan (jika user sudah memperbaiki baris error di ALV)
  LOOP AT GT_DISPLAY.
    IF GT_DISPLAY-LINE_COLOR = 'C600'.
      CLEAR LS_F4_CHK.
      IF GT_DISPLAY-KUNNR IS NOT INITIAL AND GT_DISPLAY-FIELD_NAME IS NOT INITIAL.
        IF GT_DISPLAY-KUNNR = 'DOM_DEFAUL'.
          GT_DISPLAY-NAME1 = 'STANDARD DOMESTIC BASELINE'.
        ELSE.
          SELECT SINGLE NAME1 FROM KNA1 INTO GT_DISPLAY-NAME1 WHERE KUNNR = GT_DISPLAY-KUNNR.
        ENDIF.
        READ TABLE GT_FIELD_F4 INTO LS_F4_CHK WITH KEY FIELD_NAME = GT_DISPLAY-FIELD_NAME.
        IF SY-SUBRC = 0 AND GT_DISPLAY-NAME1 IS NOT INITIAL.
          GT_DISPLAY-LINE_COLOR = 'C300'.
          GT_DISPLAY-STATUS_TXT = 'Uploaded (Ready to Save)'.
          MODIFY GT_DISPLAY.
        ENDIF.
      ENDIF.
    ENDIF.

    IF GT_DISPLAY-LINE_COLOR = 'C600'.
      LV_HAS_ERR = 'X'.
    ENDIF.
  ENDLOOP.

  IF LV_HAS_ERR = 'X'.
    MESSAGE 'Terdapat baris error (merah). Perbaiki atau hapus sebelum simpan!' TYPE 'S' DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

  " Handle opsi Upload Overwrite (P_DEL = 'X' AND R_UPL = 'X')
  IF P_DEL = 'X' AND R_UPL = 'X'.
    DATA: LT_CUST_DEL TYPE TABLE OF KUNNR WITH HEADER LINE.
    LOOP AT GT_DISPLAY.
      LT_CUST_DEL = GT_DISPLAY-KUNNR.
      COLLECT LT_CUST_DEL.
    ENDLOOP.
    LOOP AT LT_CUST_DEL.
      DELETE FROM ZQM_COA_CUST_COL WHERE KUNNR = LT_CUST_DEL.
    ENDLOOP.
  ENDIF.

  " Kumpulkan baris yang valid untuk disimpan / diupdate
  CLEAR LT_INS. REFRESH LT_INS.
  LOOP AT GT_DISPLAY.
    IF GT_DISPLAY-KUNNR IS INITIAL OR GT_DISPLAY-FIELD_NAME IS INITIAL.
      CONTINUE.
    ENDIF.
    CLEAR LT_INS.
    LT_INS-MANDT        = SY-MANDT.
    LT_INS-KUNNR        = GT_DISPLAY-KUNNR.
    LT_INS-FIELD_NAME   = GT_DISPLAY-FIELD_NAME.
    LT_INS-FIELD_LABEL  = GT_DISPLAY-FIELD_LABEL.
    LT_INS-COL_SIZE     = GT_DISPLAY-COL_SIZE.
    LT_INS-SEQ_NO       = GT_DISPLAY-SEQ_NO.
    LT_INS-ACTIVE       = GT_DISPLAY-ACTIVE.
    APPEND LT_INS.
  ENDLOOP.

  IF LT_INS[] IS NOT INITIAL.
    MODIFY ZQM_COA_CUST_COL FROM TABLE LT_INS.
    IF SY-SUBRC = 0.
      COMMIT WORK AND WAIT.
      DESCRIBE TABLE LT_INS LINES LV_COUNT.
      MESSAGE 'Data mapping berhasil disimpan ke database.' TYPE 'S'.
      LOOP AT GT_DISPLAY.
        IF GT_DISPLAY-ACTIVE = 'X'.
          GT_DISPLAY-STATUS_TXT = 'Active in Database'.
          GT_DISPLAY-LINE_COLOR = ''.
        ELSE.
          GT_DISPLAY-STATUS_TXT = 'Inactive (Deactivated)'.
          GT_DISPLAY-LINE_COLOR = 'C600'.
        ENDIF.
        GT_DISPLAY-BOX = ' '.
      ENDLOOP.
      GT_ORIGINAL[] = GT_DISPLAY[].
    ELSE.
      ROLLBACK WORK.
      MESSAGE 'Gagal menyimpan ke database!' TYPE 'E'.
      EXIT.
    ENDIF.
  ELSE.
    MESSAGE 'Tidak ada data untuk disimpan.' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.

  IF GO_GRID IS BOUND.
    DATA: LS_STBL TYPE LVC_S_STBL.
    LS_STBL-ROW = 'X'.
    LS_STBL-COL = 'X'.
    GO_GRID->REFRESH_TABLE_DISPLAY( IS_STABLE = LS_STBL ).
  ENDIF.
ENDFORM.                    " SAVE_DATABASE_CHANGES

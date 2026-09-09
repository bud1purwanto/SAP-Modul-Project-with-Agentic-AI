REPORT ZPPR_GI_JR_CLOSING.

TYPE-POOLS: SLIS.

TABLES: MSEG,
        MKPF,
        AUFK,
        AUSP.

CONSTANTS: GC_ATNAM_LINE TYPE CABN-ATNAM VALUE 'ZZPRODLINE',
           GC_ATNAM_ROLL TYPE CABN-ATNAM VALUE 'ZZNOMORROLL',
           GC_MAP_MAIL   TYPE ZMAP_TYPE-TYPE VALUE 'EMAIL_RECIPIENT',
           GC_MAP_OTYPE  TYPE ZMAP_TYPE-TYPE VALUE 'ORDER TYPE',
           GC_OPT_JR     TYPE ZMAP_TYPE-OPT  VALUE 'JR'.

DATA: GV_LINE TYPE AUSP-ATWRT.

SELECTION-SCREEN BEGIN OF BLOCK B01 WITH FRAME TITLE TEXT-001.
PARAMETERS: P_RPT  RADIOBUTTON GROUP G01 DEFAULT 'X'
                   USER-COMMAND MOD,
            P_MAIL RADIOBUTTON GROUP G01.
SELECTION-SCREEN END OF BLOCK B01.

SELECTION-SCREEN BEGIN OF BLOCK B02 WITH FRAME TITLE TEXT-002.
PARAMETERS: R_ALL  RADIOBUTTON GROUP G02 DEFAULT 'X',
            R_NOGI RADIOBUTTON GROUP G02,
            R_LESS RADIOBUTTON GROUP G02.
SELECTION-SCREEN END OF BLOCK B02.

SELECTION-SCREEN BEGIN OF BLOCK B03 WITH FRAME TITLE TEXT-003.
SELECT-OPTIONS: S_BUDAT FOR MKPF-BUDAT,
                S_WERKS FOR MSEG-WERKS NO INTERVALS,
                S_LINE  FOR GV_LINE    NO INTERVALS,
                S_AUFNR FOR AUFK-AUFNR NO INTERVALS.
PARAMETERS: P_TOL  TYPE MSEG-MENGE DEFAULT '0.001',
            P_VARI TYPE DISVARIANT-VARIANT MODIF ID RPT.
SELECTION-SCREEN END OF BLOCK B03.

SELECTION-SCREEN BEGIN OF BLOCK B04 WITH FRAME TITLE TEXT-004.
PARAMETERS: P_TEST AS CHECKBOX DEFAULT ' ' MODIF ID MAI.
SELECTION-SCREEN END OF BLOCK B04.

TYPES: BEGIN OF TY_MOV,
         MBLNR TYPE MSEG-MBLNR,
         MJAHR TYPE MSEG-MJAHR,
         ZEILE TYPE MSEG-ZEILE,
         BWART TYPE MSEG-BWART,
         MATNR TYPE MSEG-MATNR,
         WERKS TYPE MSEG-WERKS,
         CHARG TYPE MSEG-CHARG,
         MENGE TYPE MSEG-MENGE,
         MEINS TYPE MSEG-MEINS,
         AUFNR TYPE MSEG-AUFNR,
         SMBLN TYPE MSEG-SMBLN,
         SJAHR TYPE MSEG-SJAHR,
         SMBLP TYPE MSEG-SMBLP,
         BUDAT TYPE MKPF-BUDAT,
         BKTXT TYPE MKPF-BKTXT,
         AUART TYPE AUFK-AUART,
       END OF TY_MOV.

TYPES: BEGIN OF TY_OUT,
         WERKS       TYPE MSEG-WERKS,
         PRODLINE    TYPE CHAR20,
         LINE_RAW    TYPE AUSP-ATWRT,
         JR_NUMBER   TYPE AUSP-ATWRT,
         MATNR       TYPE MSEG-MATNR,
         MAKTX       TYPE MAKT-MAKTX,
         GR_DATE     TYPE MKPF-BUDAT,
         AUFNR       TYPE MSEG-AUFNR,
         CHARG       TYPE MSEG-CHARG,
         QTY_GR      TYPE MSEG-MENGE,
         QTY_GI      TYPE P DECIMALS 3,
         QTY_DIFF    TYPE P DECIMALS 3,
         MEINS       TYPE MSEG-MEINS,
         AUART       TYPE AUFK-AUART,
         BKTXT       TYPE MKPF-BKTXT,
         CNT_261     TYPE I,
         TRACE_STAT  TYPE CHAR30,
         MAIL_STATUS TYPE CHAR30,
       END OF TY_OUT.

TYPES: BEGIN OF TY_REL,
         OUT_ORDER TYPE AUFNR,
         MOV_ORDER TYPE AUFNR,
       END OF TY_REL.

TYPES: BEGIN OF TY_AFPO,
         AUFNR          TYPE AFPO-AUFNR,
         PARENT_ORDER   TYPE AFPO-MILL_OC_AUFNR_U,
       END OF TY_AFPO.

TYPES: BEGIN OF TY_GI,
         AUFNR   TYPE MSEG-AUFNR,
         BKTXT   TYPE MKPF-BKTXT,
         QTY_GI  TYPE P DECIMALS 3,
         CNT_261 TYPE I,
       END OF TY_GI.

TYPES: BEGIN OF TY_BATCH,
         MATNR    TYPE MCH1-MATNR,
         CHARG    TYPE MCH1-CHARG,
         CUOBJ_BM TYPE MCH1-CUOBJ_BM,
         OBJEK    TYPE AUSP-OBJEK,
       END OF TY_BATCH.

TYPES: BEGIN OF TY_CHAR,
         OBJEK TYPE AUSP-OBJEK,
         ATINN TYPE AUSP-ATINN,
         ATWRT TYPE AUSP-ATWRT,
       END OF TY_CHAR.

TYPES: BEGIN OF TY_MAKT,
         MATNR TYPE MAKT-MATNR,
         MAKTX TYPE MAKT-MAKTX,
       END OF TY_MAKT.

TYPES: BEGIN OF TY_AUFK,
         AUFNR TYPE AUFK-AUFNR,
         AUART TYPE AUFK-AUART,
       END OF TY_AUFK.

TYPES: BEGIN OF TY_REC,
         EMAIL TYPE AD_SMTPADR,
         ROLE  TYPE CHAR3,
       END OF TY_REC.

DATA: GT_GR       TYPE STANDARD TABLE OF TY_MOV,
      GT_GIMOV    TYPE STANDARD TABLE OF TY_MOV,
      GT_OUT      TYPE SORTED TABLE OF TY_OUT
                  WITH UNIQUE KEY WERKS MATNR CHARG AUFNR,
      GT_RESULT   TYPE STANDARD TABLE OF TY_OUT,
      GT_REL      TYPE SORTED TABLE OF TY_REL
                  WITH UNIQUE KEY OUT_ORDER MOV_ORDER,
      GT_AFPO     TYPE STANDARD TABLE OF TY_AFPO,
      GT_GI       TYPE SORTED TABLE OF TY_GI
                  WITH UNIQUE KEY AUFNR BKTXT,
      GT_BATCH    TYPE SORTED TABLE OF TY_BATCH
                  WITH UNIQUE KEY MATNR CHARG,
      GT_CHAR     TYPE STANDARD TABLE OF TY_CHAR,
      GT_MAKT     TYPE SORTED TABLE OF TY_MAKT
                  WITH UNIQUE KEY MATNR,
      GT_AUFK     TYPE SORTED TABLE OF TY_AUFK
                  WITH UNIQUE KEY AUFNR,
      GT_MAP_REC  TYPE STANDARD TABLE OF ZMAP_TYPE,
      GT_FCAT     TYPE SLIS_T_FIELDCAT_ALV,
      GS_VARIANT  TYPE DISVARIANT.

INITIALIZATION.
  PERFORM GET_DEFAULT_VARIANT.

AT SELECTION-SCREEN OUTPUT.
  PERFORM MODIFY_SCREEN.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR P_VARI.
  PERFORM VARIANT_F4.

AT SELECTION-SCREEN.
  IF SY-UCOMM = 'MOD'.
    RETURN.
  ENDIF.

START-OF-SELECTION.
  DATA: LV_VAL_ERR TYPE CHAR1.
  PERFORM VALIDATE_SELECTION CHANGING LV_VAL_ERR.
  IF LV_VAL_ERR = 'X'.
    STOP.
  ENDIF.

  PERFORM GET_DATA.
  IF GT_RESULT IS INITIAL.
    MESSAGE TEXT-010 TYPE 'S'.
    RETURN.
  ENDIF.

  IF P_MAIL = 'X'.
    PERFORM VALIDATE_LINE_RECIPIENTS CHANGING LV_VAL_ERR.
    IF LV_VAL_ERR = 'X'.
      RETURN.
    ENDIF.
    PERFORM PROCESS_EMAIL.
  ENDIF.

  PERFORM DISPLAY_REPORT.

*&---------------------------------------------------------------------*
*&      Form  modify_screen
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM MODIFY_SCREEN.
  LOOP AT SCREEN.
    IF SCREEN-GROUP1 = 'RPT'.
      IF P_RPT = 'X'.
        SCREEN-ACTIVE = '1'.
      ELSE.
        SCREEN-ACTIVE = '0'.
      ENDIF.
      MODIFY SCREEN.
    ELSEIF SCREEN-GROUP1 = 'MAI'.
      IF P_MAIL = 'X'.
        SCREEN-ACTIVE = '1'.
      ELSE.
        SCREEN-ACTIVE = '0'.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDFORM.                    "modify_screen

*&---------------------------------------------------------------------*
*&      Form  validate_selection
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->CV_ERROR   text
*----------------------------------------------------------------------*
FORM VALIDATE_SELECTION CHANGING CV_ERROR TYPE CHAR1.
  DATA: LS_VARIANT TYPE DISVARIANT.

  CLEAR CV_ERROR.

  IF S_WERKS[] IS INITIAL.
    MESSAGE 'Plant wajib diisi.' TYPE 'S' DISPLAY LIKE 'E'.
    CV_ERROR = 'X'.
    RETURN.
  ENDIF.

  IF S_BUDAT[] IS INITIAL.
    MESSAGE 'Posting Date wajib diisi.' TYPE 'S' DISPLAY LIKE 'E'.
    CV_ERROR = 'X'.
    RETURN.
  ENDIF.

  IF P_RPT = 'X' AND P_VARI IS NOT INITIAL.
    LS_VARIANT-REPORT  = SY-CPROG.
    LS_VARIANT-VARIANT = P_VARI.
    CALL FUNCTION 'REUSE_ALV_VARIANT_EXISTENCE'
      EXPORTING
        I_SAVE        = 'A'
      CHANGING
        CS_VARIANT    = LS_VARIANT
      EXCEPTIONS
        WRONG_INPUT   = 1
        NOT_FOUND     = 2
        PROGRAM_ERROR = 3
        OTHERS        = 4.
    IF SY-SUBRC <> 0.
      MESSAGE TEXT-013 TYPE 'S' DISPLAY LIKE 'E'.
      CV_ERROR = 'X'.
      RETURN.
    ENDIF.
  ENDIF.
ENDFORM.                    "validate_selection

*&---------------------------------------------------------------------*
*&      Form  get_default_variant
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM GET_DEFAULT_VARIANT.
  CLEAR GS_VARIANT.
  GS_VARIANT-REPORT = SY-REPID.
  CALL FUNCTION 'REUSE_ALV_VARIANT_DEFAULT_GET'
    EXPORTING
      I_SAVE     = 'A'
    CHANGING
      CS_VARIANT = GS_VARIANT
    EXCEPTIONS
      NOT_FOUND  = 2
      OTHERS     = 3.
  IF SY-SUBRC = 0.
    P_VARI = GS_VARIANT-VARIANT.
  ENDIF.
ENDFORM.                    "get_default_variant

*&---------------------------------------------------------------------*
*&      Form  variant_f4
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM VARIANT_F4.
  DATA: LS_VARIANT TYPE DISVARIANT,
        LV_EXIT    TYPE CHAR1.

  LS_VARIANT-REPORT  = SY-REPID.
  LS_VARIANT-VARIANT = P_VARI.
  CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
    EXPORTING
      IS_VARIANT    = LS_VARIANT
      I_SAVE        = 'A'
    IMPORTING
      E_EXIT        = LV_EXIT
      ES_VARIANT    = LS_VARIANT
    EXCEPTIONS
      NOT_FOUND     = 2
      PROGRAM_ERROR = 3
      OTHERS        = 4.
  IF SY-SUBRC = 0 AND LV_EXIT IS INITIAL.
    P_VARI = LS_VARIANT-VARIANT.
  ENDIF.
ENDFORM.                    "variant_f4

*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM GET_DATA.
  DATA: LS_MOV        TYPE TY_MOV,
        LS_OUT        TYPE TY_OUT,
        LS_BATCH      TYPE TY_BATCH,
        LS_CHAR       TYPE TY_CHAR,
        LS_MAKT       TYPE TY_MAKT,
        LS_AUFK       TYPE TY_AUFK,
        LV_ATINN_LN   TYPE CABN-ATINN,
        LV_ATINN_JR   TYPE CABN-ATINN,
        LV_KEEP       TYPE CHAR1,
        LV_MATCHED    TYPE CHAR1,
        LT_MOV_STORNO TYPE STANDARD TABLE OF TY_MOV,
        LS_STORNO     TYPE TY_MOV,
        LT_MAP_AUART  TYPE STANDARD TABLE OF ZMAP_TYPE-VALUE,
        LV_AUART_VAL  TYPE ZMAP_TYPE-VALUE.
  RANGES: LR_JR_AUART FOR AUFK-AUART.

  CLEAR: GT_GR, GT_GIMOV, GT_OUT, GT_RESULT, GT_REL, GT_AFPO,
         GT_GI, GT_BATCH, GT_CHAR, GT_MAKT, GT_AUFK,
         GT_MAP_REC.

  SELECT VALUE
    FROM ZMAP_TYPE
    INTO TABLE LT_MAP_AUART
   WHERE ( PROG = 'ZPPR_GI_JR_CLOSING' OR PROG = 'ZPPI_COHVPI' )
     AND TYPE = GC_MAP_OTYPE
     AND OPT  = GC_OPT_JR.

  REFRESH LR_JR_AUART.
  LR_JR_AUART-SIGN   = 'I'.
  LR_JR_AUART-OPTION = 'EQ'.
  LOOP AT LT_MAP_AUART INTO LV_AUART_VAL.
    LR_JR_AUART-LOW = LV_AUART_VAL.
    APPEND LR_JR_AUART.
  ENDLOOP.

  SELECT A~MBLNR A~MJAHR A~ZEILE A~BWART A~MATNR A~WERKS
         A~CHARG A~MENGE A~MEINS A~AUFNR A~SMBLN A~SJAHR
         A~SMBLP B~BUDAT B~BKTXT C~AUART
    INTO CORRESPONDING FIELDS OF TABLE GT_GR
    FROM MKPF AS B INNER JOIN MSEG AS A
      ON A~MBLNR = B~MBLNR
     AND A~MJAHR = B~MJAHR
     INNER JOIN AUFK AS C
      ON C~AUFNR = A~AUFNR
   WHERE B~BUDAT IN S_BUDAT
     AND A~WERKS IN S_WERKS
     AND A~AUFNR IN S_AUFNR
     AND C~AUART IN LR_JR_AUART
     AND ( A~BWART = '101' OR A~BWART = '102' OR
           A~BWART = '531' OR A~BWART = '532' )
     AND A~CHARG NE SPACE.

  LT_MOV_STORNO[] = GT_GR[].
  DELETE LT_MOV_STORNO WHERE SMBLN IS INITIAL.
  LOOP AT LT_MOV_STORNO INTO LS_MOV.
    DELETE GT_GR WHERE MBLNR = LS_MOV-SMBLN
                   AND MJAHR = LS_MOV-SJAHR
                   AND ZEILE = LS_MOV-SMBLP.
  ENDLOOP.
  DELETE GT_GR WHERE SMBLN IS NOT INITIAL
                  OR BWART = '102' OR BWART = '532'.

  IF GT_GR IS NOT INITIAL.
    REFRESH LT_MOV_STORNO.
    SELECT MBLNR MJAHR ZEILE SMBLN SJAHR SMBLP BWART
      INTO CORRESPONDING FIELDS OF TABLE LT_MOV_STORNO
      FROM MSEG
      FOR ALL ENTRIES IN GT_GR
     WHERE SMBLN = GT_GR-MBLNR
       AND SJAHR = GT_GR-MJAHR
       AND SMBLP = GT_GR-ZEILE
       AND ( BWART = '102' OR BWART = '532' ).
    LOOP AT LT_MOV_STORNO INTO LS_STORNO.
      DELETE GT_GR WHERE MBLNR = LS_STORNO-SMBLN
                     AND MJAHR = LS_STORNO-SJAHR
                     AND ZEILE = LS_STORNO-SMBLP.
    ENDLOOP.
  ENDIF.

  LOOP AT GT_GR INTO LS_MOV.
    READ TABLE GT_OUT INTO LS_OUT
      WITH TABLE KEY WERKS = LS_MOV-WERKS
                     MATNR = LS_MOV-MATNR
                     CHARG = LS_MOV-CHARG
                     AUFNR = LS_MOV-AUFNR.
    IF SY-SUBRC <> 0.
      CLEAR LS_OUT.
      LS_OUT-WERKS   = LS_MOV-WERKS.
      LS_OUT-MATNR   = LS_MOV-MATNR.
      LS_OUT-CHARG   = LS_MOV-CHARG.
      LS_OUT-AUFNR   = LS_MOV-AUFNR.
      LS_OUT-AUART   = LS_MOV-AUART.
      LS_OUT-BKTXT   = LS_MOV-BKTXT.
      LS_OUT-MEINS   = LS_MOV-MEINS.
      LS_OUT-GR_DATE = LS_MOV-BUDAT.
      LS_OUT-QTY_GR  = LS_MOV-MENGE.
      INSERT LS_OUT INTO TABLE GT_OUT.
    ELSE.
      LS_OUT-QTY_GR = LS_OUT-QTY_GR + LS_MOV-MENGE.
      IF LS_OUT-GR_DATE IS INITIAL OR LS_MOV-BUDAT < LS_OUT-GR_DATE.
        LS_OUT-GR_DATE = LS_MOV-BUDAT.
      ENDIF.
      MODIFY TABLE GT_OUT FROM LS_OUT.
    ENDIF.
  ENDLOOP.

  DELETE GT_OUT WHERE QTY_GR <= 0.
  IF GT_OUT IS INITIAL.
    RETURN.
  ENDIF.

  SELECT A~MBLNR A~MJAHR A~ZEILE A~BWART A~MATNR A~WERKS
         A~CHARG A~MENGE A~MEINS A~AUFNR A~SMBLN A~SJAHR
         A~SMBLP B~BUDAT B~BKTXT
    INTO CORRESPONDING FIELDS OF TABLE GT_GIMOV
    FROM MSEG AS A INNER JOIN MKPF AS B
      ON B~MBLNR = A~MBLNR
     AND B~MJAHR = A~MJAHR
     FOR ALL ENTRIES IN GT_OUT
   WHERE A~CHARG = GT_OUT-CHARG
     AND ( A~BWART = '261' OR A~BWART = '262' OR
           A~BWART = '901' OR A~BWART = '902' ).

  IF GT_GIMOV IS NOT INITIAL.
    LT_MOV_STORNO[] = GT_GIMOV[].
    DELETE LT_MOV_STORNO WHERE SMBLN IS INITIAL.
    LOOP AT LT_MOV_STORNO INTO LS_MOV.
      DELETE GT_GIMOV WHERE MBLNR = LS_MOV-SMBLN
                        AND MJAHR = LS_MOV-SJAHR
                        AND ZEILE = LS_MOV-SMBLP.
    ENDLOOP.
    DELETE GT_GIMOV WHERE SMBLN IS NOT INITIAL
                       OR BWART = '262' OR BWART = '902'.

    IF GT_GIMOV IS NOT INITIAL.
      REFRESH LT_MOV_STORNO.
      SELECT MBLNR MJAHR ZEILE SMBLN SJAHR SMBLP BWART
        INTO CORRESPONDING FIELDS OF TABLE LT_MOV_STORNO
        FROM MSEG
        FOR ALL ENTRIES IN GT_GIMOV
       WHERE SMBLN = GT_GIMOV-MBLNR
         AND SJAHR = GT_GIMOV-MJAHR
         AND SMBLP = GT_GIMOV-ZEILE
         AND ( BWART = '262' OR BWART = '902' ).
      LOOP AT LT_MOV_STORNO INTO LS_STORNO.
        DELETE GT_GIMOV WHERE MBLNR = LS_STORNO-SMBLN
                          AND MJAHR = LS_STORNO-SJAHR
                          AND ZEILE = LS_STORNO-SMBLP.
      ENDLOOP.
    ENDIF.
  ENDIF.

  SELECT SINGLE ATINN INTO LV_ATINN_LN FROM CABN
   WHERE ATNAM = GC_ATNAM_LINE.
  SELECT SINGLE ATINN INTO LV_ATINN_JR FROM CABN
   WHERE ATNAM = GC_ATNAM_ROLL.

  SELECT MATNR CHARG CUOBJ_BM
    INTO CORRESPONDING FIELDS OF TABLE GT_BATCH
    FROM MCH1
    FOR ALL ENTRIES IN GT_OUT
   WHERE MATNR = GT_OUT-MATNR
     AND CHARG = GT_OUT-CHARG.

  IF GT_BATCH IS NOT INITIAL.
    LOOP AT GT_BATCH INTO LS_BATCH.
      LS_BATCH-OBJEK = LS_BATCH-CUOBJ_BM.
      MODIFY TABLE GT_BATCH FROM LS_BATCH.
    ENDLOOP.
    SELECT OBJEK ATINN ATWRT
      INTO CORRESPONDING FIELDS OF TABLE GT_CHAR
      FROM AUSP
      FOR ALL ENTRIES IN GT_BATCH
     WHERE OBJEK = GT_BATCH-OBJEK
       AND KLART = '023'
       AND ( ATINN = LV_ATINN_LN OR ATINN = LV_ATINN_JR ).
  ENDIF.

  SELECT MATNR MAKTX
    INTO CORRESPONDING FIELDS OF TABLE GT_MAKT
    FROM MAKT
    FOR ALL ENTRIES IN GT_OUT
   WHERE MATNR = GT_OUT-MATNR
     AND SPRAS = SY-LANGU.

  SELECT AUFNR AUART
    INTO CORRESPONDING FIELDS OF TABLE GT_AUFK
    FROM AUFK
    FOR ALL ENTRIES IN GT_OUT
   WHERE AUFNR = GT_OUT-AUFNR.

  LOOP AT GT_OUT INTO LS_OUT.
    CLEAR: LS_OUT-QTY_GI, LS_OUT-CNT_261, LV_MATCHED.
    LOOP AT GT_GIMOV INTO LS_MOV WHERE CHARG = LS_OUT-CHARG.
      LS_OUT-QTY_GI  = LS_OUT-QTY_GI + LS_MOV-MENGE.
      LS_OUT-CNT_261 = LS_OUT-CNT_261 + 1.
      IF LS_OUT-BKTXT IS NOT INITIAL AND LS_MOV-BKTXT = LS_OUT-BKTXT.
        LV_MATCHED = 'X'.
      ENDIF.
    ENDLOOP.
    LS_OUT-QTY_DIFF = LS_OUT-QTY_GR - LS_OUT-QTY_GI.

    IF LS_OUT-CNT_261 = 0.
      LS_OUT-TRACE_STAT = 'Belum Ada GI Sama Sekali'.
    ELSEIF LS_OUT-QTY_GI < ( LS_OUT-QTY_GR - P_TOL ).
      LS_OUT-TRACE_STAT = 'GI Parsial (Kurang dari JR)'.
    ELSEIF LS_OUT-QTY_GI > ( LS_OUT-QTY_GR + P_TOL ).
      LS_OUT-TRACE_STAT = 'GI Melebihi JR'.
    ELSE.
      LS_OUT-TRACE_STAT = 'GI Sudah Lengkap'.
    ENDIF.

    READ TABLE GT_BATCH INTO LS_BATCH
      WITH TABLE KEY MATNR = LS_OUT-MATNR CHARG = LS_OUT-CHARG.
    IF SY-SUBRC = 0.
      LOOP AT GT_CHAR INTO LS_CHAR WHERE OBJEK = LS_BATCH-OBJEK.
        IF LS_CHAR-ATINN = LV_ATINN_LN.
          LS_OUT-LINE_RAW = LS_CHAR-ATWRT.
        ELSEIF LS_CHAR-ATINN = LV_ATINN_JR.
          LS_OUT-JR_NUMBER = LS_CHAR-ATWRT.
        ENDIF.
      ENDLOOP.
    ENDIF.

    IF LS_OUT-JR_NUMBER IS INITIAL.
      LS_OUT-JR_NUMBER = LS_OUT-CHARG.
    ENDIF.

    LS_OUT-PRODLINE = LS_OUT-LINE_RAW.
    IF LS_OUT-PRODLINE IS INITIAL.
      LS_OUT-PRODLINE = 'UNASSIGNED'.
    ENDIF.

    IF S_LINE[] IS NOT INITIAL AND LS_OUT-PRODLINE NOT IN S_LINE.
      CONTINUE.
    ENDIF.

    READ TABLE GT_MAKT INTO LS_MAKT
      WITH TABLE KEY MATNR = LS_OUT-MATNR.
    IF SY-SUBRC = 0.
      LS_OUT-MAKTX = LS_MAKT-MAKTX.
    ENDIF.
    READ TABLE GT_AUFK INTO LS_AUFK
      WITH TABLE KEY AUFNR = LS_OUT-AUFNR.
    IF SY-SUBRC = 0.
      LS_OUT-AUART = LS_AUFK-AUART.
    ENDIF.

    CLEAR LV_KEEP.
    IF R_ALL = 'X'.
      IF LS_OUT-CNT_261 = 0.
        LV_KEEP = 'X'.
      ELSEIF LS_OUT-CNT_261 > 0 AND LS_OUT-QTY_GI < ( LS_OUT-QTY_GR - P_TOL ).
        LV_KEEP = 'X'.
      ENDIF.
    ELSEIF R_NOGI = 'X'.
      IF LS_OUT-CNT_261 = 0.
        LV_KEEP = 'X'.
      ENDIF.
    ELSEIF R_LESS = 'X'.
      IF LS_OUT-CNT_261 > 0 AND LS_OUT-QTY_GI < ( LS_OUT-QTY_GR - P_TOL ).
        LV_KEEP = 'X'.
      ENDIF.
    ENDIF.
    IF LV_KEEP = 'X'.
      APPEND LS_OUT TO GT_RESULT.
    ENDIF.
  ENDLOOP.

  SORT GT_RESULT BY PRODLINE GR_DATE AUFNR CHARG.
ENDFORM.                    "get_data

*&---------------------------------------------------------------------*
*&      Form  validate_line_recipients
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--CV_ERROR   text
*----------------------------------------------------------------------*
FORM VALIDATE_LINE_RECIPIENTS CHANGING CV_ERROR TYPE CHAR1.
  DATA: LT_LINE      TYPE SORTED TABLE OF CHAR20 WITH UNIQUE KEY TABLE_LINE,
        LV_LINE      TYPE CHAR20,
        LS_OUT       TYPE TY_OUT,
        LS_MAP       TYPE ZMAP_TYPE,
        LS_REC       TYPE TY_REC,
        LV_HAS_TO    TYPE CHAR1,
        LT_ERR_LINES TYPE STANDARD TABLE OF CHAR20,
        LV_ERR_STR   TYPE STRING,
        LV_MSG       TYPE STRING.

  CLEAR CV_ERROR.

  SELECT * INTO TABLE GT_MAP_REC FROM ZMAP_TYPE
   WHERE PROG = SY-CPROG
     AND TYPE = GC_MAP_MAIL
     AND DELETION = SPACE.

  LOOP AT GT_RESULT INTO LS_OUT.
    INSERT LS_OUT-PRODLINE INTO TABLE LT_LINE.
  ENDLOOP.

  LOOP AT LT_LINE INTO LV_LINE.
    CLEAR LV_HAS_TO.
    LOOP AT GT_MAP_REC INTO LS_MAP WHERE OPT = LV_LINE.
      PERFORM MAP_TO_RECIPIENT USING LS_MAP CHANGING LS_REC.
      IF LS_REC-ROLE = 'TO' AND LS_REC-EMAIL IS NOT INITIAL.
        LV_HAS_TO = 'X'.
        EXIT.
      ENDIF.
    ENDLOOP.
    IF LV_HAS_TO IS INITIAL.
      APPEND LV_LINE TO LT_ERR_LINES.
    ENDIF.
  ENDLOOP.

  IF LT_ERR_LINES IS NOT INITIAL.
    LOOP AT LT_ERR_LINES INTO LV_LINE.
      IF LV_ERR_STR IS INITIAL.
        LV_ERR_STR = LV_LINE.
      ELSE.
        CONCATENATE LV_ERR_STR ', ' LV_LINE INTO LV_ERR_STR.
      ENDIF.
    ENDLOOP.
    CONCATENATE 'Penerima email Prod. Line' LV_ERR_STR
                'belum di-setting di ZMAP_TYPE.'
           INTO LV_MSG SEPARATED BY SPACE.
    MESSAGE LV_MSG TYPE 'S' DISPLAY LIKE 'E'.
    CV_ERROR = 'X'.
  ENDIF.
ENDFORM.                    "validate_line_recipients

*&---------------------------------------------------------------------*
*&      Form  process_email
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM PROCESS_EMAIL.
  DATA: LT_LINE TYPE SORTED TABLE OF CHAR20 WITH UNIQUE KEY TABLE_LINE,
        LV_LINE TYPE CHAR20,
        LS_OUT  TYPE TY_OUT,
        LV_SENT TYPE CHAR1,
        LV_STAT TYPE CHAR30.

  SELECT * INTO TABLE GT_MAP_REC FROM ZMAP_TYPE
   WHERE PROG = SY-CPROG
     AND TYPE = GC_MAP_MAIL
     AND DELETION = SPACE.

  LOOP AT GT_RESULT INTO LS_OUT.
    INSERT LS_OUT-PRODLINE INTO TABLE LT_LINE.
  ENDLOOP.

  LOOP AT LT_LINE INTO LV_LINE.
    CLEAR: LV_SENT, LV_STAT.
    PERFORM SEND_LINE_EMAIL USING LV_LINE CHANGING LV_SENT LV_STAT.
    LOOP AT GT_RESULT INTO LS_OUT WHERE PRODLINE = LV_LINE.
      LS_OUT-MAIL_STATUS = LV_STAT.
      MODIFY GT_RESULT FROM LS_OUT TRANSPORTING MAIL_STATUS.
    ENDLOOP.
  ENDLOOP.
ENDFORM.                    "process_email

*&---------------------------------------------------------------------*
*&      Form  send_line_email
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->PV_LINE    text
*      -->PV_SENT    text
*      -->PV_STAT    text
*----------------------------------------------------------------------*
FORM SEND_LINE_EMAIL USING    PV_LINE TYPE CHAR20
                     CHANGING PV_SENT TYPE CHAR1
                              PV_STAT TYPE CHAR30.
  DATA: LT_REC      TYPE SORTED TABLE OF TY_REC
                    WITH UNIQUE KEY EMAIL ROLE,
        LS_REC      TYPE TY_REC,
        LS_MAP      TYPE ZMAP_TYPE,
        LT_BODY     TYPE SOLI_TAB,
        LT_ATTACH   TYPE SOLI_TAB,
        LS_SOLI     TYPE SOLI,
        LS_OUT      TYPE TY_OUT,
        LO_SEND     TYPE REF TO CL_BCS,
        LO_DOC      TYPE REF TO CL_DOCUMENT_BCS,
        LO_ADDRESS  TYPE REF TO IF_RECIPIENT_BCS,
        LX_BCS      TYPE REF TO CX_BCS,
        LV_SUBJECT  TYPE SO_OBJ_DES,
        LV_EMAIL    TYPE AD_SMTPADR,
        LV_ROLE     TYPE CHAR3,
        LV_COPY     TYPE OS_BOOLEAN,
        LV_BLIND    TYPE OS_BOOLEAN,
        LV_HAS_LINE TYPE CHAR1,
        LV_HAS_TO   TYPE CHAR1,
        LV_QTY_GR   TYPE CHAR20,
        LV_QTY_GI   TYPE CHAR20,
        LV_DIFF     TYPE CHAR20,
        LV_DATE     TYPE CHAR10.

  CLEAR: LT_REC, LS_REC, LV_HAS_TO.
  LOOP AT GT_MAP_REC INTO LS_MAP WHERE OPT = PV_LINE.
    PERFORM MAP_TO_RECIPIENT USING LS_MAP CHANGING LS_REC.
    IF LS_REC-EMAIL IS NOT INITIAL.
      INSERT LS_REC INTO TABLE LT_REC.
    ENDIF.
  ENDLOOP.

  LOOP AT LT_REC INTO LS_REC.
    IF LS_REC-ROLE = 'TO'.
      LV_HAS_TO = 'X'.
      EXIT.
    ENDIF.
  ENDLOOP.
  IF LV_HAS_TO IS INITIAL.
    PV_STAT = 'NO_TO_RECIPIENT'.
    RETURN.
  ENDIF.

  WRITE SY-DATUM TO LV_DATE.
  CONCATENATE 'Observasi GI JR -' PV_LINE '-' LV_DATE
    INTO LV_SUBJECT SEPARATED BY SPACE.
  IF P_TEST = 'X'.
    CONCATENATE '[TEST]' LV_SUBJECT INTO LV_SUBJECT SEPARATED BY SPACE.
  ENDIF.

  LS_SOLI-LINE = '<html><body><p>Dear User,</p>'.
  APPEND LS_SOLI TO LT_BODY.
  CONCATENATE '<p>Berikut exception observasi GI Jumbo Roll untuk line <b>'
              PV_LINE '</b>.</p>' INTO LS_SOLI-LINE.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '<table border="1" cellspacing="0" cellpadding="4">'.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '<tr><th>JR Number</th><th>Material</th><th>GR Date</th>'.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '<th>Order</th><th>Batch</th><th>Qty JR</th>'.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '<th>Qty GI</th><th>Diff</th><th>Status</th></tr>'.
  APPEND LS_SOLI TO LT_BODY.

  LS_SOLI-LINE = 'JR Number;Production Line;Material;Description;GR Date;Order;Batch;Qty JR;Qty GI;Diff;UoM;Order Type;BKTXT;Trace Status'.
  APPEND LS_SOLI TO LT_ATTACH.

  LOOP AT GT_RESULT INTO LS_OUT WHERE PRODLINE = PV_LINE.
    WRITE LS_OUT-QTY_GR TO LV_QTY_GR NO-GROUPING.
    WRITE LS_OUT-QTY_GI TO LV_QTY_GI NO-GROUPING.
    WRITE LS_OUT-QTY_DIFF TO LV_DIFF NO-GROUPING.
    CONDENSE: LV_QTY_GR, LV_QTY_GI, LV_DIFF.

    CONCATENATE '<tr><td>' LS_OUT-JR_NUMBER '</td><td>'
                LS_OUT-MATNR '</td><td>' LS_OUT-GR_DATE '</td>'
      INTO LS_SOLI-LINE.
    APPEND LS_SOLI TO LT_BODY.
    CONCATENATE '<td>' LS_OUT-AUFNR '</td><td>' LS_OUT-CHARG
                '</td><td>' LV_QTY_GR '</td>' INTO LS_SOLI-LINE.
    APPEND LS_SOLI TO LT_BODY.
    CONCATENATE '<td>' LV_QTY_GI '</td><td>' LV_DIFF '</td><td>'
                LS_OUT-TRACE_STAT '</td></tr>' INTO LS_SOLI-LINE.
    APPEND LS_SOLI TO LT_BODY.

    CONCATENATE LS_OUT-JR_NUMBER PV_LINE LS_OUT-MATNR LS_OUT-MAKTX
                LS_OUT-GR_DATE LS_OUT-AUFNR LS_OUT-CHARG LV_QTY_GR
                LV_QTY_GI LV_DIFF LS_OUT-MEINS LS_OUT-AUART
                LS_OUT-BKTXT LS_OUT-TRACE_STAT
      INTO LS_SOLI-LINE SEPARATED BY ';'.
    APPEND LS_SOLI TO LT_ATTACH.
  ENDLOOP.

  LS_SOLI-LINE = '</table><p>Email dibuat otomatis oleh SAP.</p></body></html>'.
  APPEND LS_SOLI TO LT_BODY.

  IF P_TEST = 'X'.
    PV_STAT = 'TEST_RUN_PREVIEW'.
    RETURN.
  ENDIF.

  TRY.
      LO_SEND = CL_BCS=>CREATE_PERSISTENT( ).
      LO_DOC = CL_DOCUMENT_BCS=>CREATE_DOCUMENT(
          I_TYPE    = 'HTM'
          I_TEXT    = LT_BODY
          I_SUBJECT = LV_SUBJECT ).
      LO_DOC->ADD_ATTACHMENT(
          I_ATTACHMENT_TYPE    = 'CSV'
          I_ATTACHMENT_SUBJECT = LV_SUBJECT
          I_ATT_CONTENT_TEXT    = LT_ATTACH ).
      LO_SEND->SET_DOCUMENT( LO_DOC ).

      LOOP AT LT_REC INTO LS_REC.
        LO_ADDRESS = CL_CAM_ADDRESS_BCS=>CREATE_INTERNET_ADDRESS(
                       LS_REC-EMAIL ).
        CLEAR: LV_COPY, LV_BLIND.
        LV_ROLE = LS_REC-ROLE.
        IF LV_ROLE = 'CC'.
          LV_COPY = 'X'.
        ELSEIF LV_ROLE = 'BCC'.
          LV_BLIND = 'X'.
        ENDIF.
        LO_SEND->ADD_RECIPIENT(
            I_RECIPIENT  = LO_ADDRESS
            I_COPY       = LV_COPY
            I_BLIND_COPY = LV_BLIND ).
      ENDLOOP.

      PV_SENT = LO_SEND->SEND( I_WITH_ERROR_SCREEN = SPACE ).
      COMMIT WORK.
      IF PV_SENT = 'X'.
        PV_STAT = 'EMAIL_SENT'.
      ELSE.
        PV_STAT = 'EMAIL_NOT_SENT'.
      ENDIF.
    CATCH CX_BCS INTO LX_BCS.
      PV_STAT = 'EMAIL_ERROR'.
  ENDTRY.
ENDFORM.                    "send_line_email

*&---------------------------------------------------------------------*
*&      Form  map_to_recipient
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->PS_MAP     text
*      -->PS_REC     text
*----------------------------------------------------------------------*
FORM MAP_TO_RECIPIENT USING    PS_MAP TYPE ZMAP_TYPE
                      CHANGING PS_REC TYPE TY_REC.
  DATA: LV_DOMAIN TYPE CHAR45.

  CLEAR PS_REC.
  IF PS_MAP-TEXT5 CS '@'.
    PS_REC-EMAIL = PS_MAP-TEXT5.
  ELSEIF PS_MAP-TEXT1 IS NOT INITIAL AND PS_MAP-TEXT2 IS NOT INITIAL.
    LV_DOMAIN = PS_MAP-TEXT2.
    IF LV_DOMAIN+0(1) <> '@'.
      CONCATENATE '@' LV_DOMAIN INTO LV_DOMAIN.
    ENDIF.
    CONCATENATE PS_MAP-TEXT1 LV_DOMAIN INTO PS_REC-EMAIL.
  ENDIF.
  PS_REC-ROLE = PS_MAP-TEXT3.
  TRANSLATE PS_REC-ROLE TO UPPER CASE.
  IF PS_REC-ROLE <> 'TO' AND PS_REC-ROLE <> 'CC'
     AND PS_REC-ROLE <> 'BCC'.
    CLEAR PS_REC.
  ENDIF.
ENDFORM.                    "map_to_recipient

*&---------------------------------------------------------------------*
*&      Form  display_report
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM DISPLAY_REPORT.
  DATA: LS_LAYOUT TYPE SLIS_LAYOUT_ALV.

  PERFORM BUILD_FIELDCAT.
  GS_VARIANT-REPORT  = SY-REPID.
  GS_VARIANT-VARIANT = P_VARI.
  LS_LAYOUT-COLWIDTH_OPTIMIZE = 'X'.
  LS_LAYOUT-ZEBRA = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      I_CALLBACK_PROGRAM = SY-REPID
      IS_LAYOUT          = LS_LAYOUT
      IT_FIELDCAT        = GT_FCAT
      I_SAVE             = 'A'
      IS_VARIANT         = GS_VARIANT
    TABLES
      T_OUTTAB           = GT_RESULT
    EXCEPTIONS
      PROGRAM_ERROR      = 1
      OTHERS             = 2.
  IF SY-SUBRC <> 0.
    MESSAGE E398(00) WITH TEXT-014.
  ENDIF.
ENDFORM.                    "display_report

*&---------------------------------------------------------------------*
*&      Form  build_fieldcat
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM BUILD_FIELDCAT.
  CLEAR GT_FCAT.
  PERFORM ADD_FIELD USING 'WERKS'       'Plant'               6  SPACE.
  PERFORM ADD_FIELD USING 'PRODLINE'    'Prod. Line'         10  SPACE.
  PERFORM ADD_FIELD USING 'JR_NUMBER'   'JR Number'          24  SPACE.
  PERFORM ADD_FIELD USING 'MATNR'       'Material'           18  SPACE.
  PERFORM ADD_FIELD USING 'MAKTX'       'Description'        30  SPACE.
  PERFORM ADD_FIELD USING 'GR_DATE'     'GR Date'            10  SPACE.
  PERFORM ADD_FIELD USING 'AUFNR'       'Order'              12  SPACE.
  PERFORM ADD_FIELD USING 'CHARG'       'Batch'              10  SPACE.
  PERFORM ADD_FIELD USING 'QTY_GR'      'Qty JR'             14  'MEINS'.
  PERFORM ADD_FIELD USING 'QTY_GI'      'Qty GI'             14  'MEINS'.
  PERFORM ADD_FIELD USING 'QTY_DIFF'    'Diff'               14  'MEINS'.
  PERFORM ADD_FIELD USING 'MEINS'       'UoM'                 5  SPACE.
  PERFORM ADD_FIELD USING 'AUART'       'Order Type'         10  SPACE.
  PERFORM ADD_FIELD USING 'BKTXT'       'BKTXT'              16  SPACE.
  PERFORM ADD_FIELD USING 'TRACE_STAT'  'Status Penelusuran' 28  SPACE.
  PERFORM ADD_FIELD USING 'MAIL_STATUS' 'Status Email'       16  SPACE.
ENDFORM.                    "build_fieldcat

*&---------------------------------------------------------------------*
*&      Form  add_field
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->PV_FIELD   text
*      -->PV_TEXT    text
*      -->PV_LEN     text
*      -->PV_QREF    text
*----------------------------------------------------------------------*
FORM ADD_FIELD USING PV_FIELD TYPE SLIS_FIELDNAME
                     PV_TEXT  TYPE CHAR40
                     PV_LEN   TYPE I
                     PV_QREF  TYPE SLIS_FIELDNAME.
  DATA: LS_FCAT TYPE SLIS_FIELDCAT_ALV.
  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME     = PV_FIELD.
  LS_FCAT-REPTEXT_DDIC  = PV_TEXT.
  LS_FCAT-SELTEXT_L     = PV_TEXT.
  LS_FCAT-SELTEXT_M     = PV_TEXT.
  LS_FCAT-SELTEXT_S     = PV_TEXT.
  LS_FCAT-DDICTXT       = 'L'.
  LS_FCAT-OUTPUTLEN     = PV_LEN.
  IF PV_QREF IS NOT INITIAL.
    LS_FCAT-QFIELDNAME  = PV_QREF.
  ENDIF.
  APPEND LS_FCAT TO GT_FCAT.
ENDFORM.                    "add_field
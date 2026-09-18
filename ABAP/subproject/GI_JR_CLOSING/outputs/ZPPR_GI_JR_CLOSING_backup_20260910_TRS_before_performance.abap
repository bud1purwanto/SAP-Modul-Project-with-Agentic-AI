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
PARAMETERS: P_TMAIL AS CHECKBOX MODIF ID MAI.
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
  IF GT_RESULT IS INITIAL
     AND NOT ( P_MAIL = 'X' AND P_TMAIL = 'X' ).
    MESSAGE TEXT-010 TYPE 'S'.
    RETURN.
  ENDIF.

  IF P_MAIL = 'X'.
    PERFORM VALIDATE_LINE_RECIPIENTS CHANGING LV_VAL_ERR.
    IF LV_VAL_ERR = 'X'.
      RETURN.
    ENDIF.
    PERFORM PROCESS_EMAIL.
    IF P_TMAIL = 'X'.
      RETURN.
    ENDIF.
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
        LS_REL        TYPE TY_REL,
        LS_REL_PARENT TYPE TY_REL,
        LS_REL_NEW    TYPE TY_REL,
        LS_AFPO       TYPE TY_AFPO,
        LT_PARENT     TYPE SORTED TABLE OF AUFNR
                      WITH UNIQUE KEY TABLE_LINE,
        LT_NEXT       TYPE SORTED TABLE OF AUFNR
                      WITH UNIQUE KEY TABLE_LINE,
        LV_PARENT     TYPE AUFNR,
        LV_ATINN_LN   TYPE CABN-ATINN,
        LV_ATINN_JR   TYPE CABN-ATINN,
        LV_KEEP       TYPE CHAR1,
        LV_MATCHED    TYPE CHAR1,
        LT_MOV_STORNO TYPE STANDARD TABLE OF TY_MOV,
        LS_STORNO     TYPE TY_MOV,
        LT_MAP_AUART  TYPE STANDARD TABLE OF ZMAP_TYPE-VALUE,
        LV_AUART_VAL  TYPE ZMAP_TYPE-VALUE,
        LV_CUTOFF     TYPE MKPF-BUDAT.
  RANGES: LR_JR_AUART FOR AUFK-AUART.

  CLEAR LV_CUTOFF.
  LOOP AT S_BUDAT.
    IF S_BUDAT-HIGH IS NOT INITIAL AND S_BUDAT-HIGH > LV_CUTOFF.
      LV_CUTOFF = S_BUDAT-HIGH.
    ELSEIF S_BUDAT-LOW > LV_CUTOFF.
      LV_CUTOFF = S_BUDAT-LOW.
    ENDIF.
  ENDLOOP.

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
     AND ( A~BWART = '101' OR A~BWART = '102' )
     AND A~CHARG NE SPACE.

  LT_MOV_STORNO[] = GT_GR[].
  DELETE LT_MOV_STORNO WHERE SMBLN IS INITIAL.
  LOOP AT LT_MOV_STORNO INTO LS_MOV.
    DELETE GT_GR WHERE MBLNR = LS_MOV-SMBLN
                   AND MJAHR = LS_MOV-SJAHR
                   AND ZEILE = LS_MOV-SMBLP.
  ENDLOOP.
  DELETE GT_GR WHERE SMBLN IS NOT INITIAL
                  OR BWART = '102'.

  IF GT_GR IS NOT INITIAL.
    REFRESH LT_MOV_STORNO.
    SELECT A~MBLNR A~MJAHR A~ZEILE A~SMBLN A~SJAHR A~SMBLP
           A~BWART B~BUDAT
      INTO CORRESPONDING FIELDS OF TABLE LT_MOV_STORNO
      FROM MSEG AS A INNER JOIN MKPF AS B
        ON A~MBLNR = B~MBLNR
       AND A~MJAHR = B~MJAHR
      FOR ALL ENTRIES IN GT_GR
     WHERE A~SMBLN = GT_GR-MBLNR
       AND A~SJAHR = GT_GR-MJAHR
       AND A~SMBLP = GT_GR-ZEILE
       AND A~BWART = '102'
       AND B~BUDAT LE LV_CUTOFF.
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

  LOOP AT GT_OUT INTO LS_OUT.
    CLEAR LS_REL.
    LS_REL-OUT_ORDER = LS_OUT-AUFNR.
    LS_REL-MOV_ORDER = LS_OUT-AUFNR.
    INSERT LS_REL INTO TABLE GT_REL.
    INSERT LS_OUT-AUFNR INTO TABLE LT_PARENT.
  ENDLOOP.

  WHILE LT_PARENT IS NOT INITIAL.
    REFRESH: GT_AFPO, LT_NEXT.
    SELECT AUFNR MILL_OC_AUFNR_U
      INTO TABLE GT_AFPO
      FROM AFPO
      FOR ALL ENTRIES IN LT_PARENT
     WHERE MILL_OC_AUFNR_U = LT_PARENT-TABLE_LINE.

    LOOP AT GT_AFPO INTO LS_AFPO.
      LOOP AT GT_REL INTO LS_REL_PARENT
        WHERE MOV_ORDER = LS_AFPO-PARENT_ORDER.
        CLEAR LS_REL_NEW.
        LS_REL_NEW-OUT_ORDER = LS_REL_PARENT-OUT_ORDER.
        LS_REL_NEW-MOV_ORDER = LS_AFPO-AUFNR.
        INSERT LS_REL_NEW INTO TABLE GT_REL.
        IF SY-SUBRC = 0.
          INSERT LS_AFPO-AUFNR INTO TABLE LT_NEXT.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
    LT_PARENT[] = LT_NEXT[].
  ENDWHILE.

  SELECT A~MBLNR A~MJAHR A~ZEILE A~BWART A~MATNR A~WERKS
         A~CHARG A~MENGE A~MEINS A~AUFNR A~SMBLN A~SJAHR
         A~SMBLP B~BUDAT B~BKTXT
    INTO CORRESPONDING FIELDS OF TABLE GT_GIMOV
    FROM MSEG AS A INNER JOIN MKPF AS B
      ON B~MBLNR = A~MBLNR
     AND B~MJAHR = A~MJAHR
     FOR ALL ENTRIES IN GT_REL
   WHERE B~BUDAT LE LV_CUTOFF
     AND A~AUFNR = GT_REL-MOV_ORDER
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
      SELECT A~MBLNR A~MJAHR A~ZEILE A~SMBLN A~SJAHR A~SMBLP
             A~BWART B~BUDAT
        INTO CORRESPONDING FIELDS OF TABLE LT_MOV_STORNO
        FROM MSEG AS A INNER JOIN MKPF AS B
          ON A~MBLNR = B~MBLNR
         AND A~MJAHR = B~MJAHR
        FOR ALL ENTRIES IN GT_GIMOV
       WHERE A~SMBLN = GT_GIMOV-MBLNR
         AND A~SJAHR = GT_GIMOV-MJAHR
         AND A~SMBLP = GT_GIMOV-ZEILE
         AND ( A~BWART = '262' OR A~BWART = '902' )
         AND B~BUDAT LE LV_CUTOFF.
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
    CLEAR: LS_OUT-QTY_GI, LS_OUT-CNT_261.
    LOOP AT GT_REL INTO LS_REL WHERE OUT_ORDER = LS_OUT-AUFNR.
      LOOP AT GT_GIMOV INTO LS_MOV
        WHERE AUFNR = LS_REL-MOV_ORDER
          AND WERKS = LS_OUT-WERKS
          AND MATNR = LS_OUT-MATNR
          AND CHARG = LS_OUT-CHARG
          AND BKTXT = LS_OUT-BKTXT.
        LS_OUT-QTY_GI  = LS_OUT-QTY_GI + LS_MOV-MENGE.
        LS_OUT-CNT_261 = LS_OUT-CNT_261 + 1.
      ENDLOOP.
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

  LOOP AT GT_MAP_REC INTO LS_MAP.
    PERFORM MAP_TO_RECIPIENT USING LS_MAP CHANGING LS_REC.
    IF LS_REC-EMAIL IS INITIAL OR LS_REC-EMAIL NP '*@*.*'.
      CONCATENATE 'Mapping email tidak valid:' LS_MAP-OPT LS_MAP-VALUE
        INTO LV_MSG SEPARATED BY SPACE.
      MESSAGE LV_MSG TYPE 'S' DISPLAY LIKE 'E'.
      CV_ERROR = 'X'.
      RETURN.
    ENDIF.
  ENDLOOP.

  LOOP AT GT_RESULT INTO LS_OUT.
    INSERT LS_OUT-PRODLINE INTO TABLE LT_LINE.
  ENDLOOP.
  IF LT_LINE IS INITIAL AND P_TMAIL = 'X'.
    LV_LINE = 'DEFAULT'.
    INSERT LV_LINE INTO TABLE LT_LINE.
  ENDIF.

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
      LOOP AT GT_MAP_REC INTO LS_MAP WHERE OPT = 'DEFAULT'.
        PERFORM MAP_TO_RECIPIENT USING LS_MAP CHANGING LS_REC.
        IF LS_REC-ROLE = 'TO' AND LS_REC-EMAIL IS NOT INITIAL.
          LV_HAS_TO = 'X'.
          EXIT.
        ENDIF.
      ENDLOOP.
    ENDIF.
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
        LT_BIN      TYPE SOLIX_TAB,
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
        LV_DATE     TYPE CHAR10,
        LV_XLS_XML  TYPE STRING,
        LV_XSTR     TYPE XSTRING,
        LV_ATTS     TYPE SO_OBJ_DES,
        LS_BUDAT    LIKE LINE OF S_BUDAT,
        LV_PERIOD   TYPE CHAR30,
        LV_DATE_FMT TYPE CHAR10,
        LV_COUNT    TYPE I,
        LV_COUNT_TXT TYPE CHAR10,
        LV_TOTAL_GR TYPE P DECIMALS 3,
        LV_TOTAL_GI TYPE P DECIMALS 3,
        LV_TOTAL_DF TYPE P DECIMALS 3,
        LV_TGR_TXT  TYPE CHAR20,
        LV_TGI_TXT  TYPE CHAR20,
        LV_TDF_TXT  TYPE CHAR20,
        LV_LINE_TXT TYPE STRING,
        LV_JR_TXT   TYPE STRING,
        LV_MAT_TXT  TYPE STRING,
        LV_DESC_TXT TYPE STRING,
        LV_ORD_TXT  TYPE STRING,
        LV_BAT_TXT  TYPE STRING,
        LV_UOM_TXT  TYPE STRING,
        LV_STAT_TXT TYPE STRING,
        LV_ROW_CLR  TYPE CHAR7.

  CLEAR: LT_REC, LS_REC, LV_HAS_TO.
  LOOP AT GT_MAP_REC INTO LS_MAP WHERE OPT = PV_LINE.
    PERFORM MAP_TO_RECIPIENT USING LS_MAP CHANGING LS_REC.
    IF LS_REC-EMAIL IS NOT INITIAL.
      INSERT LS_REC INTO TABLE LT_REC.
    ENDIF.
  ENDLOOP.
  LOOP AT LT_REC INTO LS_REC WHERE ROLE = 'TO'.
    LV_HAS_TO = 'X'.
    EXIT.
  ENDLOOP.
  IF LV_HAS_TO IS INITIAL.
    LOOP AT GT_MAP_REC INTO LS_MAP WHERE OPT = 'DEFAULT'.
      PERFORM MAP_TO_RECIPIENT USING LS_MAP CHANGING LS_REC.
      IF LS_REC-EMAIL IS NOT INITIAL.
        INSERT LS_REC INTO TABLE LT_REC.
      ENDIF.
    ENDLOOP.
  ENDIF.

  CLEAR LV_HAS_TO.
  LOOP AT LT_REC INTO LS_REC WHERE ROLE = 'TO'.
    LV_HAS_TO = 'X'.
    EXIT.
  ENDLOOP.
  IF LV_HAS_TO IS INITIAL.
    PV_STAT = 'NO_TO_RECIPIENT'.
    RETURN.
  ENDIF.

  WRITE SY-DATUM TO LV_DATE.
  CONCATENATE 'Observasi GI JR -' PV_LINE '-' LV_DATE
    INTO LV_SUBJECT SEPARATED BY SPACE.
  IF P_TMAIL = 'X'.
    CONCATENATE '[TEST]' LV_SUBJECT INTO LV_SUBJECT SEPARATED BY SPACE.
  ENDIF.

  CLEAR: LV_COUNT, LV_TOTAL_GR, LV_TOTAL_GI, LV_TOTAL_DF.
  LOOP AT GT_RESULT INTO LS_OUT WHERE PRODLINE = PV_LINE.
    ADD 1 TO LV_COUNT.
    LV_TOTAL_GR = LV_TOTAL_GR + LS_OUT-QTY_GR.
    LV_TOTAL_GI = LV_TOTAL_GI + LS_OUT-QTY_GI.
    LV_TOTAL_DF = LV_TOTAL_DF + LS_OUT-QTY_DIFF.
  ENDLOOP.
  WRITE LV_COUNT TO LV_COUNT_TXT NO-GROUPING.
  CONDENSE LV_COUNT_TXT.
  WRITE LV_TOTAL_GR TO LV_TGR_TXT NO-GROUPING DECIMALS 3.
  WRITE LV_TOTAL_GI TO LV_TGI_TXT NO-GROUPING DECIMALS 3.
  WRITE LV_TOTAL_DF TO LV_TDF_TXT NO-GROUPING DECIMALS 3.
  CONDENSE: LV_TGR_TXT, LV_TGI_TXT, LV_TDF_TXT.

  CLEAR LV_PERIOD.
  READ TABLE S_BUDAT INTO LS_BUDAT INDEX 1.
  IF SY-SUBRC = 0.
    CONCATENATE LS_BUDAT-LOW+6(2) '.' LS_BUDAT-LOW+4(2) '.'
                LS_BUDAT-LOW(4) INTO LV_PERIOD.
    IF LS_BUDAT-HIGH IS NOT INITIAL.
      CONCATENATE LV_PERIOD ' - ' LS_BUDAT-HIGH+6(2) '.'
                  LS_BUDAT-HIGH+4(2) '.' LS_BUDAT-HIGH(4)
             INTO LV_PERIOD.
    ENDIF.
  ENDIF.
  LV_LINE_TXT = PV_LINE.
  PERFORM XML_ESCAPE CHANGING LV_LINE_TXT.

  LS_SOLI-LINE = '<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8">'.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '<style>body{margin:0;background:#f3f6f9;font-family:Arial,sans-serif;color:#1f2937;}'.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '.wrap{max-width:1180px;margin:18px auto;background:#fff;border:1px solid #d9e2f3;}'.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '.head{background:#1f4e78;color:#fff;padding:20px 24px;}.head h2{margin:0;font-size:22px;}'.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '.content{padding:22px 24px;}.summary{width:100%;border-collapse:separate;border-spacing:8px;}'.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '.card{background:#eef4fb;border-left:4px solid #5b9bd5;padding:10px;font-size:12px;}'.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '.data{width:100%;border-collapse:collapse;font-size:11px;margin-top:16px;}'.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '.data th{background:#1f4e78;color:#fff;padding:9px 6px;border:1px solid #163a5b;}'.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '.data td{padding:8px 6px;border:1px solid #d9e2f3;vertical-align:top;}'.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '.num{text-align:right;white-space:nowrap;}.badge{color:#9c5700;font-weight:bold;}'.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '.note{background:#fff4ce;border-left:4px solid #ffc000;padding:10px;margin:14px 0;}'.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '.foot{color:#6b7280;font-size:11px;border-top:1px solid #e5e7eb;padding-top:14px;}</style></head>'.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '<body><div class="wrap"><div class="head"><h2>Observasi GI Jumbo Roll Closing</h2>'.
  APPEND LS_SOLI TO LT_BODY.
  CONCATENATE '<div style="margin-top:6px;">Production Line: <b>' LV_LINE_TXT
              '</b> &nbsp;|&nbsp; Periode: <b>' LV_PERIOD
              '</b></div></div><div class="content">' INTO LS_SOLI-LINE.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '<p>Yth. Tim Produksi,</p><p>SAP menemukan exception proses GI Jumbo Roll yang memerlukan perhatian.</p>'.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '<table class="summary"><tr>'.
  APPEND LS_SOLI TO LT_BODY.
  CONCATENATE '<td class="card"><b>Jumlah Exception</b><br><span style="font-size:20px;">'
              LV_COUNT_TXT '</span> JR</td>' INTO LS_SOLI-LINE.
  APPEND LS_SOLI TO LT_BODY.
  CONCATENATE '<td class="card"><b>Total Qty JR</b><br><span style="font-size:20px;">'
              LV_TGR_TXT '</span></td>' INTO LS_SOLI-LINE.
  APPEND LS_SOLI TO LT_BODY.
  CONCATENATE '<td class="card"><b>Total Qty GI</b><br><span style="font-size:20px;">'
              LV_TGI_TXT '</span></td>' INTO LS_SOLI-LINE.
  APPEND LS_SOLI TO LT_BODY.
  CONCATENATE '<td class="card"><b>Total Selisih</b><br><span style="font-size:20px;">'
              LV_TDF_TXT '</span></td></tr></table>' INTO LS_SOLI-LINE.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '<div class="note"><b>Catatan:</b> Selisih dihitung dari Qty JR (GR) dikurangi Qty GI.</div>'.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '<table class="data"><tr><th>JR Number</th><th>Material</th><th>Description</th>'.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '<th>GR Date</th><th>Order</th><th>Batch</th><th>Qty JR</th><th>Qty GI</th>'.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '<th>Diff</th><th>UoM</th><th>Status</th></tr>'.
  APPEND LS_SOLI TO LT_BODY.

  CLEAR LV_COUNT.
  LOOP AT GT_RESULT INTO LS_OUT WHERE PRODLINE = PV_LINE.
    ADD 1 TO LV_COUNT.
    WRITE LS_OUT-QTY_GR TO LV_QTY_GR NO-GROUPING DECIMALS 3.
    WRITE LS_OUT-QTY_GI TO LV_QTY_GI NO-GROUPING DECIMALS 3.
    WRITE LS_OUT-QTY_DIFF TO LV_DIFF NO-GROUPING DECIMALS 3.
    CONDENSE: LV_QTY_GR, LV_QTY_GI, LV_DIFF.
    CONCATENATE LS_OUT-GR_DATE+6(2) '.' LS_OUT-GR_DATE+4(2) '.'
                LS_OUT-GR_DATE(4) INTO LV_DATE_FMT.
    LV_JR_TXT = LS_OUT-JR_NUMBER.
    LV_MAT_TXT = LS_OUT-MATNR.
    LV_DESC_TXT = LS_OUT-MAKTX.
    LV_ORD_TXT = LS_OUT-AUFNR.
    LV_BAT_TXT = LS_OUT-CHARG.
    LV_UOM_TXT = LS_OUT-MEINS.
    LV_STAT_TXT = LS_OUT-TRACE_STAT.
    PERFORM XML_ESCAPE CHANGING LV_JR_TXT.
    PERFORM XML_ESCAPE CHANGING LV_MAT_TXT.
    PERFORM XML_ESCAPE CHANGING LV_DESC_TXT.
    PERFORM XML_ESCAPE CHANGING LV_ORD_TXT.
    PERFORM XML_ESCAPE CHANGING LV_BAT_TXT.
    PERFORM XML_ESCAPE CHANGING LV_UOM_TXT.
    PERFORM XML_ESCAPE CHANGING LV_STAT_TXT.
    IF LV_COUNT MOD 2 = 0.
      LV_ROW_CLR = '#f7fbff'.
    ELSE.
      LV_ROW_CLR = '#ffffff'.
    ENDIF.
    CONCATENATE '<tr style="background:' LV_ROW_CLR ';"><td><b>' LV_JR_TXT
                '</b></td><td>' LV_MAT_TXT '</td><td>' LV_DESC_TXT
                '</td>' INTO LS_SOLI-LINE.
    APPEND LS_SOLI TO LT_BODY.
    CONCATENATE '<td style="white-space:nowrap;">' LV_DATE_FMT '</td><td>'
                LV_ORD_TXT '</td><td>' LV_BAT_TXT '</td>'
                INTO LS_SOLI-LINE.
    APPEND LS_SOLI TO LT_BODY.
    CONCATENATE '<td class="num">' LV_QTY_GR '</td><td class="num">'
                LV_QTY_GI '</td><td class="num"><b>' LV_DIFF
                '</b></td><td>' LV_UOM_TXT '</td>' INTO LS_SOLI-LINE.
    APPEND LS_SOLI TO LT_BODY.
    CONCATENATE '<td><span class="badge">' LV_STAT_TXT
                '</span></td></tr>' INTO LS_SOLI-LINE.
    APPEND LS_SOLI TO LT_BODY.
  ENDLOOP.

  LS_SOLI-LINE = '</table><p style="margin-top:16px;"><b>Detail lengkap tersedia pada attachment Excel.</b></p>'.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '<div class="foot">Email ini dibuat otomatis oleh SAP. Mohon tidak membalas email ini.</div>'.
  APPEND LS_SOLI TO LT_BODY.
  LS_SOLI-LINE = '</div></div></body></html>'.
  APPEND LS_SOLI TO LT_BODY.

  PERFORM BUILD_XLS USING PV_LINE CHANGING LV_XLS_XML.
  CONCATENATE 'Observasi_GI_JR_' PV_LINE INTO LV_ATTS.

  IF P_TMAIL = 'X'.
    WRITE: / 'TEST EMAIL PREVIEW - TIDAK DIKIRIM',
           / 'Subject:', LV_SUBJECT,
           / 'Recipient dari ZMAP_TYPE:'.
    LOOP AT LT_REC INTO LS_REC.
      WRITE: / LS_REC-ROLE, LS_REC-EMAIL.
    ENDLOOP.
    WRITE: / 'Attachment preview:', LV_ATTS, '(formatted Excel table)',
           / 'Body:'.
    LOOP AT LT_BODY INTO LS_SOLI.
      WRITE: / LS_SOLI-LINE.
    ENDLOOP.
    PV_STAT = 'TEST_PREVIEW'.
    RETURN.
  ENDIF.

  CLEAR: LV_XSTR, LT_BIN.
  CALL FUNCTION 'HR_KR_STRING_TO_XSTRING'
    EXPORTING
      CODEPAGE_TO      = '4110'
      UNICODE_STRING   = LV_XLS_XML
    IMPORTING
      XSTRING_STREAM   = LV_XSTR
    EXCEPTIONS
      INVALID_CODEPAGE = 1
      INVALID_STRING   = 2
      OTHERS           = 3.
  IF SY-SUBRC <> 0.
    PV_STAT = 'XLS_CONVERT_ERROR'.
    RETURN.
  ENDIF.
  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
    EXPORTING
      BUFFER     = LV_XSTR
    TABLES
      BINARY_TAB = LT_BIN.

  TRY.
      LO_SEND = CL_BCS=>CREATE_PERSISTENT( ).
      LO_DOC = CL_DOCUMENT_BCS=>CREATE_DOCUMENT(
          I_TYPE    = 'HTM'
          I_TEXT    = LT_BODY
          I_SUBJECT = LV_SUBJECT ).
      LO_DOC->ADD_ATTACHMENT(
          I_ATTACHMENT_TYPE    = 'XLS'
          I_ATTACHMENT_SUBJECT = LV_ATTS
          I_ATT_CONTENT_HEX     = LT_BIN ).
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
*&      Form  xml_escape
*&---------------------------------------------------------------------*
FORM XML_ESCAPE CHANGING PV_TEXT TYPE STRING.
  REPLACE ALL OCCURRENCES OF '&' IN PV_TEXT WITH '&amp;'.
  REPLACE ALL OCCURRENCES OF '<' IN PV_TEXT WITH '&lt;'.
  REPLACE ALL OCCURRENCES OF '>' IN PV_TEXT WITH '&gt;'.
  REPLACE ALL OCCURRENCES OF '"' IN PV_TEXT WITH '&quot;'.
ENDFORM.                    "xml_escape

*&---------------------------------------------------------------------*
*&      Form  build_xls
*&---------------------------------------------------------------------*
FORM BUILD_XLS USING    PV_LINE TYPE CHAR20
               CHANGING PV_XML  TYPE STRING.
  DATA: LT_XML    TYPE STANDARD TABLE OF STRING,
        LS_OUT    TYPE TY_OUT,
        LV_NL     TYPE STRING,
        LV_ROW    TYPE STRING,
        LV_LINE   TYPE STRING,
        LV_JR     TYPE STRING,
        LV_MATNR  TYPE STRING,
        LV_MAKTX  TYPE STRING,
        LV_DATE   TYPE STRING,
        LV_AUFNR  TYPE STRING,
        LV_CHARG  TYPE STRING,
        LV_GR     TYPE C LENGTH 30,
        LV_GI     TYPE C LENGTH 30,
        LV_DIFF   TYPE C LENGTH 30,
        LV_MEINS  TYPE STRING,
        LV_AUART  TYPE STRING,
        LV_BKTXT  TYPE STRING,
        LV_STATUS TYPE STRING,
        LV_STYLE  TYPE STRING,
        LV_COUNT  TYPE I.

  CLEAR PV_XML.
  LV_NL = CL_ABAP_CHAR_UTILITIES=>NEWLINE.
  APPEND '<?xml version="1.0"?>' TO LT_XML.
  APPEND '<?mso-application progid="Excel.Sheet"?>' TO LT_XML.
  APPEND '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"' TO LT_XML.
  APPEND ' xmlns:o="urn:schemas-microsoft-com:office:office"' TO LT_XML.
  APPEND ' xmlns:x="urn:schemas-microsoft-com:office:excel"' TO LT_XML.
  APPEND ' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">' TO LT_XML.
  APPEND '<Styles>' TO LT_XML.
  APPEND '<Style ss:ID="title"><Font ss:Bold="1" ss:Size="15" ss:Color="#1F1F1F"/>' TO LT_XML.
  APPEND '<Alignment ss:Vertical="Center"/></Style>' TO LT_XML.
  APPEND '<Style ss:ID="sub"><Font ss:Italic="1" ss:Color="#666666"/></Style>' TO LT_XML.
  APPEND '<Style ss:ID="header"><Font ss:Bold="1" ss:Color="#FFFFFF"/>' TO LT_XML.
  APPEND '<Interior ss:Color="#1F4E78" ss:Pattern="Solid"/>' TO LT_XML.
  APPEND '<Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>' TO LT_XML.
  APPEND '<Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous"/>' TO LT_XML.
  APPEND '<Border ss:Position="Top" ss:LineStyle="Continuous"/>' TO LT_XML.
  APPEND '<Border ss:Position="Left" ss:LineStyle="Continuous"/>' TO LT_XML.
  APPEND '<Border ss:Position="Right" ss:LineStyle="Continuous"/></Borders></Style>' TO LT_XML.
  APPEND '<Style ss:ID="text"><NumberFormat ss:Format="@"/>' TO LT_XML.
  APPEND '<Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Color="#D9E2F3"/>' TO LT_XML.
  APPEND '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Color="#D9E2F3"/>' TO LT_XML.
  APPEND '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Color="#D9E2F3"/></Borders></Style>' TO LT_XML.
  APPEND '<Style ss:ID="alt"><Interior ss:Color="#DDEBF7" ss:Pattern="Solid"/>' TO LT_XML.
  APPEND '<NumberFormat ss:Format="@"/><Borders>' TO LT_XML.
  APPEND '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Color="#D9E2F3"/>' TO LT_XML.
  APPEND '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Color="#D9E2F3"/>' TO LT_XML.
  APPEND '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Color="#D9E2F3"/></Borders></Style>' TO LT_XML.
  APPEND '<Style ss:ID="number"><NumberFormat ss:Format="#,##0.000"/>' TO LT_XML.
  APPEND '<Alignment ss:Horizontal="Right"/><Borders>' TO LT_XML.
  APPEND '<Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Color="#D9E2F3"/>' TO LT_XML.
  APPEND '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Color="#D9E2F3"/>' TO LT_XML.
  APPEND '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Color="#D9E2F3"/></Borders></Style>' TO LT_XML.
  APPEND '<Style ss:ID="altnum"><Interior ss:Color="#DDEBF7" ss:Pattern="Solid"/>' TO LT_XML.
  APPEND '<NumberFormat ss:Format="#,##0.000"/><Alignment ss:Horizontal="Right"/>' TO LT_XML.
  APPEND '<Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Color="#D9E2F3"/>' TO LT_XML.
  APPEND '<Border ss:Position="Left" ss:LineStyle="Continuous" ss:Color="#D9E2F3"/>' TO LT_XML.
  APPEND '<Border ss:Position="Right" ss:LineStyle="Continuous" ss:Color="#D9E2F3"/></Borders></Style>' TO LT_XML.
  APPEND '</Styles>' TO LT_XML.

  APPEND '<Worksheet ss:Name="GI JR Closing"><Table>' TO LT_XML.
  APPEND '<Column ss:Width="105"/><Column ss:Width="85"/>' TO LT_XML.
  APPEND '<Column ss:Width="95"/><Column ss:Width="210"/>' TO LT_XML.
  APPEND '<Column ss:Width="75"/><Column ss:Width="90"/>' TO LT_XML.
  APPEND '<Column ss:Width="90"/><Column ss:Width="75"/>' TO LT_XML.
  APPEND '<Column ss:Width="75"/><Column ss:Width="75"/>' TO LT_XML.
  APPEND '<Column ss:Width="45"/><Column ss:Width="70"/>' TO LT_XML.
  APPEND '<Column ss:Width="145"/><Column ss:Width="190"/>' TO LT_XML.
  APPEND '<Row ss:Height="25"><Cell ss:StyleID="title" ss:MergeAcross="13">' TO LT_XML.
  APPEND '<Data ss:Type="String">Observasi GI Jumbo Roll Closing</Data></Cell></Row>' TO LT_XML.
  LV_LINE = PV_LINE.
  PERFORM XML_ESCAPE CHANGING LV_LINE.
  CONCATENATE '<Row><Cell ss:StyleID="sub" ss:MergeAcross="13"><Data ss:Type="String">Production Line: '
              LV_LINE '</Data></Cell></Row>' INTO LV_ROW.
  APPEND LV_ROW TO LT_XML.
  APPEND '<Row></Row>' TO LT_XML.
  APPEND '<Row ss:Height="30"><Cell ss:StyleID="header"><Data ss:Type="String">JR Number</Data></Cell>' TO LT_XML.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Production Line</Data></Cell>' TO LT_XML.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Material</Data></Cell>' TO LT_XML.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Description</Data></Cell>' TO LT_XML.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">GR Date</Data></Cell>' TO LT_XML.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Order</Data></Cell>' TO LT_XML.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Batch</Data></Cell>' TO LT_XML.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Qty JR</Data></Cell>' TO LT_XML.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Qty GI</Data></Cell>' TO LT_XML.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Diff</Data></Cell>' TO LT_XML.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">UoM</Data></Cell>' TO LT_XML.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Order Type</Data></Cell>' TO LT_XML.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">BKTXT</Data></Cell>' TO LT_XML.
  APPEND '<Cell ss:StyleID="header"><Data ss:Type="String">Trace Status</Data></Cell></Row>' TO LT_XML.

  LOOP AT GT_RESULT INTO LS_OUT WHERE PRODLINE = PV_LINE.
    ADD 1 TO LV_COUNT.
    CLEAR: LV_JR, LV_MATNR, LV_MAKTX, LV_DATE, LV_AUFNR, LV_CHARG,
           LV_GR, LV_GI, LV_DIFF, LV_MEINS, LV_AUART, LV_BKTXT,
           LV_STATUS.
    LV_JR = LS_OUT-JR_NUMBER.
    LV_MATNR = LS_OUT-MATNR.
    LV_MAKTX = LS_OUT-MAKTX.
    LV_DATE = LS_OUT-GR_DATE.
    LV_AUFNR = LS_OUT-AUFNR.
    LV_CHARG = LS_OUT-CHARG.
    WRITE LS_OUT-QTY_GR TO LV_GR NO-GROUPING DECIMALS 3.
    WRITE LS_OUT-QTY_GI TO LV_GI NO-GROUPING DECIMALS 3.
    WRITE LS_OUT-QTY_DIFF TO LV_DIFF NO-GROUPING DECIMALS 3.
    CONDENSE: LV_GR, LV_GI, LV_DIFF.
    REPLACE ALL OCCURRENCES OF ',' IN LV_GR WITH '.'.
    REPLACE ALL OCCURRENCES OF ',' IN LV_GI WITH '.'.
    REPLACE ALL OCCURRENCES OF ',' IN LV_DIFF WITH '.'.
    LV_MEINS = LS_OUT-MEINS.
    LV_AUART = LS_OUT-AUART.
    LV_BKTXT = LS_OUT-BKTXT.
    LV_STATUS = LS_OUT-TRACE_STAT.
    PERFORM XML_ESCAPE CHANGING LV_JR.
    PERFORM XML_ESCAPE CHANGING LV_MATNR.
    PERFORM XML_ESCAPE CHANGING LV_MAKTX.
    PERFORM XML_ESCAPE CHANGING LV_DATE.
    PERFORM XML_ESCAPE CHANGING LV_AUFNR.
    PERFORM XML_ESCAPE CHANGING LV_CHARG.
    PERFORM XML_ESCAPE CHANGING LV_MEINS.
    PERFORM XML_ESCAPE CHANGING LV_AUART.
    PERFORM XML_ESCAPE CHANGING LV_BKTXT.
    PERFORM XML_ESCAPE CHANGING LV_STATUS.
    IF LV_COUNT MOD 2 = 0.
      LV_STYLE = 'alt'.
    ELSE.
      LV_STYLE = 'text'.
    ENDIF.
    CONCATENATE '<Row><Cell ss:StyleID="' LV_STYLE '"><Data ss:Type="String">'
                LV_JR '</Data></Cell><Cell ss:StyleID="' LV_STYLE
                '"><Data ss:Type="String">' LV_LINE '</Data></Cell>'
                INTO LV_ROW.
    APPEND LV_ROW TO LT_XML.
    CONCATENATE '<Cell ss:StyleID="' LV_STYLE '"><Data ss:Type="String">'
                LV_MATNR '</Data></Cell><Cell ss:StyleID="' LV_STYLE
                '"><Data ss:Type="String">' LV_MAKTX '</Data></Cell>'
                INTO LV_ROW.
    APPEND LV_ROW TO LT_XML.
    CONCATENATE '<Cell ss:StyleID="' LV_STYLE '"><Data ss:Type="String">'
                LV_DATE '</Data></Cell><Cell ss:StyleID="' LV_STYLE
                '"><Data ss:Type="String">' LV_AUFNR '</Data></Cell>'
                INTO LV_ROW.
    APPEND LV_ROW TO LT_XML.
    CONCATENATE '<Cell ss:StyleID="' LV_STYLE '"><Data ss:Type="String">'
                LV_CHARG '</Data></Cell>' INTO LV_ROW.
    APPEND LV_ROW TO LT_XML.
    IF LV_COUNT MOD 2 = 0.
      LV_STYLE = 'altnum'.
    ELSE.
      LV_STYLE = 'number'.
    ENDIF.
    CONCATENATE '<Cell ss:StyleID="' LV_STYLE '"><Data ss:Type="Number">'
                LV_GR '</Data></Cell><Cell ss:StyleID="' LV_STYLE
                '"><Data ss:Type="Number">' LV_GI '</Data></Cell><Cell ss:StyleID="'
                LV_STYLE '"><Data ss:Type="Number">' LV_DIFF '</Data></Cell>'
                INTO LV_ROW.
    APPEND LV_ROW TO LT_XML.
    IF LV_COUNT MOD 2 = 0.
      LV_STYLE = 'alt'.
    ELSE.
      LV_STYLE = 'text'.
    ENDIF.
    CONCATENATE '<Cell ss:StyleID="' LV_STYLE '"><Data ss:Type="String">'
                LV_MEINS '</Data></Cell><Cell ss:StyleID="' LV_STYLE
                '"><Data ss:Type="String">' LV_AUART '</Data></Cell>'
                INTO LV_ROW.
    APPEND LV_ROW TO LT_XML.
    CONCATENATE '<Cell ss:StyleID="' LV_STYLE '"><Data ss:Type="String">'
                LV_BKTXT '</Data></Cell><Cell ss:StyleID="' LV_STYLE
                '"><Data ss:Type="String">' LV_STATUS
                '</Data></Cell></Row>' INTO LV_ROW.
    APPEND LV_ROW TO LT_XML.
  ENDLOOP.

  APPEND '</Table>' TO LT_XML.
  APPEND '<AutoFilter x:Range="R4C1:R999C14" xmlns="urn:schemas-microsoft-com:office:excel"/>' TO LT_XML.
  APPEND '<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">' TO LT_XML.
  APPEND '<FreezePanes/><FrozenNoSplit/><SplitHorizontal>4</SplitHorizontal>' TO LT_XML.
  APPEND '<TopRowBottomPane>4</TopRowBottomPane></WorksheetOptions>' TO LT_XML.
  APPEND '</Worksheet></Workbook>' TO LT_XML.
  CONCATENATE LINES OF LT_XML INTO PV_XML SEPARATED BY LV_NL.
ENDFORM.                    "build_xls

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

REPORT  ZMMR_LABELPACK LINE-COUNT 100 MESSAGE-ID VV.
TABLES: VBCO3, TVST, MSKA.
INCLUDE PALIDATA.
INCLUDE RVADTABL.
DATA : V_CHARG_QTY LIKE VBDPL-CHARG,
       V_SUM_NETWEIGHT_ZCONV TYPE P DECIMALS 2.
.
DATA V_COPIES(3) VALUE 1.
*for alias
DATA : V_TYPE_HU  LIKE API_VALI-ATWRT,
       V_FLAG_ZZALIAS_HU(1) VALUE '',
       V_FLAG_LABEL(10) TYPE C,
       V_DER(1) TYPE C,
       V_AUFNR TYPE AFPO-AUFNR,
       V_POS(2) TYPE C,
       FLAG_VENUM(8) TYPE C.
DATA: V_IS_ZEBRA_LABELPACK(1).
INCLUDE ZHUR_LABELPACK_INCL.
INCLUDE: ZHUR_LABELPACK_INCH.
DATA: RETCODE LIKE SY-SUBRC,             "Returncode
      XSCREEN(1) TYPE C.                 "Ausgabe Printer/Screen
DATA: V_COUNT(1).
DATA : V_SVAL_2 LIKE SVAL OCCURS 10 WITH HEADER LINE.
DATA : V_LVBPLP LIKE LVBPLP OCCURS 10 WITH HEADER LINE.
DATA : BEGIN OF DATA_BATCH OCCURS 0,
            BATCH_CHARG TYPE CHARG_D,                       "(255),
       END OF DATA_BATCH.
DATA: VPROGNAME LIKE TSTC-PGMNA.  "Add by Akbar 24.04.2019 (for label HU Under Windo
DATA : BEGIN OF DATA_BATCH_DIGIT OCCURS 0,
            VENUM LIKE VEKP-VENUM,
            CHARG LIKE MCHA-CHARG,
            DERIVATIVEMS(2), " LIKE zdigitctl-derivativems,
            POSITIONMS(2), " LIKE zdigitctl-positionms,
            DERIVATIVESS(2), " LIKE zdigitctl-derivativess,
            POSITIONSS(2), " LIKE zdigitctl-positionss,
            AUFNR LIKE AFPO-AUFNR,
            GRADE(2), "LIKE zdigitctl-grade,
            ZCONV(35), " LIKE zdigitctl-zconv,
       END OF DATA_BATCH_DIGIT.
*&--------------------------------------------------------------------*
*&      Form  ENTRY
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
*      -->RETURN_CODEtext
*      -->US_SCREEN  text
*---------------------------------------------------------------------*
FORM ENTRY USING RETURN_CODE US_SCREEN.
  CLEAR RETCODE.
  XSCREEN = US_SCREEN.
  PERFORM PROCESSING USING XSCREEN.
  IF RETCODE NE 0.
    RETURN_CODE = 1.
  ELSE.
    RETURN_CODE = 0.
  ENDIF.
ENDFORM.                    "ENTRY
*&---------------------------------------------------------------------*
*&      Form  processing
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->PROC_SCREEN  text
*----------------------------------------------------------------------*
FORM PROCESSING USING PROC_SCREEN.
  PERFORM CEK_QAPASS.
  PERFORM GET_DATA.
  CHECK RETCODE = 0.
ENDFORM.                    "PROCESSING
*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM GET_DATA.
  DATA : V_VENUM TYPE VBCO3-VENUM.
  REFRESH: LVBPLK, LVBPLA, LVBPLP.
  CLEAR: LVBPLK, LVBPLA, LVBPLP.
  CLEAR: V_CHARG_QTY, V_SUM_NETWEIGHT, V_SUM_NETWEIGHT_TEMP, V_SUM_NETWEIGHT_ZCONV,
         V_TOT_ROLL, V_TOT_BOX.
** Data declaration for Digit Control Checking
  DATA  D_FLAG_NO_DC TYPE BOOLEAN.
  VBCO3-VENUM = NAST-OBJKY.                                 "00000.....
  VBCO3-SPRAS = NAST-SPRAS.      "D
  VBCO3-KUNDE = NAST-PARNR.      "KUNDE
  VBCO3-PARVW = NAST-PARVW.      "WE
  VBCO3-PACKD = 'X'.
  CALL FUNCTION 'SD_PACKING_PRINT_VIEW_SINGLE'
    EXPORTING
      COMWA                    = VBCO3
    IMPORTING
      VBPLK_WA                 = LVBPLK
      VBPLA_WA                 = LVBPLA
    TABLES
      VBPLP_TAB                = LVBPLP
    EXCEPTIONS
      SHIPPING_UNIT_NOT_UNIQUE = 1
      SHIPPING_UNIT_NOT_FOUND  = 2
      OTHERS                   = 3.
  IF SY-SUBRC NE 0.
    RETCODE = 1.
    PERFORM PROTOCOL_UPDATE.
  ENDIF.
  IF SY-SUBRC = 0.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
      EXPORTING
        INPUT  = LVBPLK-EXIDV
      IMPORTING
        OUTPUT = V_EXIDV.
* magrv is BOX/Pallet...
    V_MAGRV = LVBPLK-MAGRV.
    LOOP AT LVBPLP WHERE MATNR <> SPACE.
      V_VENUM = LVBPLP-VENUM.
      EXIT.
    ENDLOOP.
    CLEAR : V_MATNR,
            V_CHARG,
            V_WERKS,
            V_LGORT.
    SELECT SINGLE WERKS CHARG MATNR LGORT
    INTO (V_WERKS, V_CHARG, V_MATNR, V_LGORT)
    FROM VEPO
    WHERE VENUM = V_VENUM.
    "Add Authorization New Company
    DATA: DMESSAGE(100),
          V_AUTH(1).
    AUTHORITY-CHECK OBJECT 'Z_WERKS' ID 'ZWERKS' FIELD V_WERKS.
    IF SY-SUBRC NE 0.
      CONCATENATE 'No Authorization print for HU' V_EXIDV 'Plant' V_WERKS INTO DMESS
      MESSAGE DMESSAGE TYPE 'I'.
      LEAVE LIST-PROCESSING.
    ENDIF.
    CHECK V_AUTH IS INITIAL.
    "End Add Authorization New Company
    "Check Pallet and Sideboard on HU
    PERFORM CEK_CODEPACK USING LVBPLK-EXIDV.
    V_ERDAT_DD = LVBPLK-ERDAT+6(2).
    V_ERDAT_MM = LVBPLK-ERDAT+4(2).
    V_ERDAT_YY = LVBPLK-ERDAT+3(1).
    CLEAR : V_TOT_ROLL, DATA_BATCH.
    REFRESH : DATA_BATCH.
*Roll No...
    LOOP AT LVBPLP WHERE VENUM = LVBPLK-VENUM.
      IF LVBPLP-UNVEL <> SPACE. "pallet/tumpukan
*      LOOP AT lvbplp WHERE matnr <> space.
        LOOP AT LVBPLP WHERE VENUM = LVBPLP-UNVEL.
          IF LVBPLP-UNVEL <> SPACE. "tumpukan
            LOOP AT LVBPLP WHERE VENUM = LVBPLP-UNVEL.
              ADD 1 TO V_TOT_ROLL.
*Count Sum of Sheet
              DATA_BATCH-BATCH_CHARG = LVBPLP-CHARG.
              APPEND DATA_BATCH.
            ENDLOOP.
          ELSE.
            ADD 1 TO V_TOT_ROLL.
*Count Sum of Sheet
            DATA_BATCH-BATCH_CHARG = LVBPLP-CHARG.
            APPEND DATA_BATCH.
          ENDIF.
        ENDLOOP.
      ELSE.
        ADD 1 TO V_TOT_ROLL.
*Count Sum of Sheet
        DATA_BATCH-BATCH_CHARG = LVBPLP-CHARG.
        APPEND DATA_BATCH.
      ENDIF.
    ENDLOOP.
*Get Total QTY of Sheet from tot_roll and ZZNUMBEROFSHEET
    CLEAR :  V_SUM_NETWEIGHT, V_SUM_NETWEIGHT_TEMP.
    IF SY-UNAME EQ 'TRSTDEVXXX'.
    ELSE.  "user TRSTDEV
*Add 02/07/06
*----------------
      SORT DATA_BATCH BY BATCH_CHARG.
      DELETE ADJACENT DUPLICATES FROM DATA_BATCH.
*      SELECT venum charg derivativems positionms derivativess positionss aufnr grad
*      INTO CORRESPONDING FIELDS OF TABLE data_batch_dummy
*      FROM zdigitctl
*      FOR ALL ENTRIES IN data_batch
*      WHERE
*      charg EQ data_batch-batch_charg.
*      DELETE data_batch_dummy WHERE existance NE space.
      LOOP AT LVBPLP WHERE VENUM = LVBPLK-VENUM.
        IF LVBPLP-UNVEL <> SPACE. "pallet/tumpukan
          LOOP AT LVBPLP WHERE VENUM = LVBPLP-UNVEL.
            LOOP AT DATA_BATCH WHERE BATCH_CHARG EQ LVBPLP-CHARG.
              CLEAR V_TAB.
              REFRESH V_TAB.
              V_FLAG_ZZALIAS_HU = ''.
*get its charg
              V_CHARG_QTY = DATA_BATCH-BATCH_CHARG.
              CALL FUNCTION 'QC01_BATCH_VALUES_READ'
                EXPORTING
                  I_VAL_MATNR    = V_MATNR
                  I_VAL_WERKS    = V_WERKS
                  I_VAL_CHARGE   = V_CHARG_QTY
                  I_LANGUAGE     = SY-LANGU
                  I_DATE         = SY-DATUM
                TABLES
                  T_VAL_TAB      = V_TAB
                EXCEPTIONS
                  NO_CLASS       = 01
                  INTERNAL_ERROR = 02
                  NO_VALUES      = 03
                  NO_CHARS       = 04.
              IF SY-SUBRC = 0.
                SORT V_TAB BY ATNAM.
                LOOP AT V_TAB.
                  IF V_TAB-ATNAM = 'ZZDERIVATIVEMS'.
                    DATA_BATCH_DIGIT-DERIVATIVEMS = V_TAB-ATWRT.
                  ELSEIF V_TAB-ATNAM = 'ZZPOSITIONMS'.
                    DATA_BATCH_DIGIT-POSITIONMS = V_TAB-ATWRT.
                  ELSEIF V_TAB-ATNAM = 'ZZDERIVATIVESS'.
                    DATA_BATCH_DIGIT-DERIVATIVESS = V_TAB-ATWRT.
                  ELSEIF V_TAB-ATNAM = 'ZZPOSITIONSS'.
                    DATA_BATCH_DIGIT-POSITIONSS = V_TAB-ATWRT.
                  ELSEIF V_TAB-ATNAM = 'ZZCONVERSIONROLLKG'.
                    READ TABLE V_TAB WITH KEY ATNAM = 'ZZLABEL'.
                    IF SY-SUBRC EQ 0.
                      IF V_TAB-ATWRT = 'SB10' OR V_TAB-ATWRT = 'K100' OR V_TAB-ATWRT
                        DATA: V_ROUND_WEIGHT2 TYPE P DECIMALS 2.
                        READ TABLE V_TAB WITH KEY ATNAM = 'ZZCONVERSIONROLLKG'.
                        PERFORM CONVERSION_WEIGHT USING V_TAB-ATFLV CHANGING V_ROUND
                        V_SUM_NETWEIGHT_ZCONV = V_SUM_NETWEIGHT_ZCONV + V_ROUND_WEIG
                      ELSE.
                        READ TABLE V_TAB WITH KEY ATNAM = 'ZZCONVERSIONROLLKG'.
                        V_SUM_NETWEIGHT_ZCONV = V_SUM_NETWEIGHT_ZCONV + V_TAB-ATFLV.
                      ENDIF.
                    ENDIF.
                  ENDIF.
                  APPEND DATA_BATCH_DIGIT.
                ENDLOOP.
*For check weight in mska and weight for alias, weight is still got from zconv......
                LOOP AT V_TAB.
                  IF V_TAB-ATNAM = 'ZZALIAS'.
                    V_TYPE_HU = V_TAB-ATWRT.
                    V_FLAG_ZZALIAS_HU = 'X'.
                  ENDIF.
                  IF V_TAB-ATNAM = 'ZZPACKING' AND V_FLAG_ZZALIAS_HU = SPACE.
*Check if roll already sent or not
                    CLEAR : V_KALAB,
                            V_KAINS,
                            V_KASPE,
                            V_CLABS,
                            V_CINSM,
                            V_CEINM,
                            V_CSPEM.
                    SELECT SUM( KALAB )
                           SUM( KAINS )
                           SUM( KASPE )
                    INTO (V_KALAB,
                          V_KAINS,
                          V_KASPE )
                    FROM MSKA
                    WHERE MATNR = V_MATNR AND
                          WERKS = V_WERKS AND
                          CHARG = V_CHARG_QTY
                    GROUP BY MATNR WERKS CHARG.
                    ENDSELECT.
                    SELECT  SUM( CLABS )
                            SUM( CINSM )
                            SUM( CEINM )
                            SUM( CSPEM )
                    INTO (V_CLABS,
                          V_CINSM,
                          V_CEINM,
                          V_CSPEM )
                    FROM MCHB
                    WHERE MATNR = V_MATNR AND
                          WERKS = V_WERKS AND
                          CHARG = V_CHARG_QTY
                    GROUP BY MATNR WERKS CHARG.
                    ENDSELECT.
                    V_SUM_NETWEIGHT_TEMP = V_KALAB + V_KAINS + V_KASPE +
                                      V_CLABS + V_CINSM + V_CEINM +
                                      V_CSPEM.
*-----------------------------------------------------------
                    V_SUM_NETWEIGHT = V_SUM_NETWEIGHT_TEMP + V_SUM_NETWEIGHT.
                  ELSEIF V_TAB-ATNAM = 'ZZPACKING' AND V_FLAG_ZZALIAS_HU = 'X'.
                    PERFORM MOD_WEIGHT_ALIAS_HU USING V_MATNR V_CHARG_QTY V_WERKS V_
                    V_SUM_NETWEIGHT = V_SUM_NETWEIGHT_TEMP + V_SUM_NETWEIGHT.
                  ENDIF.
                ENDLOOP.
                IF D_FLAG_NO_DC EQ SPACE.
                  V_SUM_NETWEIGHT = V_SUM_NETWEIGHT_ZCONV.
                  V_SUM_NETWEIGHT_TEMP = V_SUM_NETWEIGHT.
*Count Roll in internal tabel digit
*                  DESCRIBE TABLE data_batch_digit LINES v_tot_roll.
                ELSE.
                  IF V_SUM_NETWEIGHT <> 0 AND V_FLAG_ZZALIAS_HU <> 'X'.
                    V_SUM_NETWEIGHT_TEMP = V_SUM_NETWEIGHT.
                  ENDIF.
                ENDIF.
              ELSE.
*----------
*Old Print Box Pallet
                LOOP AT V_TAB.
                  IF V_TAB-ATNAM = 'ZZNUMBEROFSHEET'.
                    PERFORM CONV_TO_CHAR USING V_TAB-ATWTB.
                    V_SUM_QTYSHEET = V_SUM_QTYSHEET + V_TAB-ATWTB.
*count sum weight for all sheet depend on its charg, not main charg
*-------------------------------
*Get Net weight...
                  ENDIF.
                  IF V_TAB-ATNAM = 'ZZALIAS'.
                    V_TYPE_HU = V_TAB-ATWRT.
                    V_FLAG_ZZALIAS_HU = 'X'.
                  ENDIF.
                  IF V_TAB-ATNAM = 'ZZPACKING' AND V_FLAG_ZZALIAS_HU = SPACE.
                    CLEAR : V_KALAB,
                            V_KAINS,
                            V_KASPE,
                            V_CLABS,
                            V_CINSM,
                            V_CEINM,
                            V_CSPEM.
                    SELECT SUM( KALAB )
                           SUM( KAINS )
                           SUM( KASPE )
                    INTO (V_KALAB,
                          V_KAINS,
                          V_KASPE )
                    FROM MSKA
                    WHERE MATNR = V_MATNR AND
                          WERKS = V_WERKS AND
                          CHARG = V_CHARG_QTY
                    GROUP BY MATNR WERKS CHARG.
                    ENDSELECT.
                    SELECT  SUM( CLABS )
                            SUM( CINSM )
                            SUM( CEINM )
                            SUM( CSPEM )
                    INTO (V_CLABS,
                          V_CINSM,
                          V_CEINM,
                          V_CSPEM )
                    FROM MCHB
                    WHERE MATNR = V_MATNR AND
                          WERKS = V_WERKS AND
                          CHARG = V_CHARG_QTY
                    GROUP BY MATNR WERKS CHARG.
                    ENDSELECT.
                    V_SUM_NETWEIGHT_TEMP = V_KALAB + V_KAINS + V_KASPE +
                                      V_CLABS + V_CINSM + V_CEINM +
                                      V_CSPEM.
*-----------------------------------------------------------
                    V_SUM_NETWEIGHT = V_SUM_NETWEIGHT_TEMP + V_SUM_NETWEIGHT.
                  ELSEIF V_TAB-ATNAM = 'ZZPACKING' AND V_FLAG_ZZALIAS_HU = 'X'.
                    PERFORM MOD_WEIGHT_ALIAS_HU USING V_MATNR V_CHARG_QTY V_WERKS V_
                    V_SUM_NETWEIGHT = V_SUM_NETWEIGHT_TEMP + V_SUM_NETWEIGHT.
                  ENDIF.
                ENDLOOP.
*                ENDIF.
              ENDIF.
*endloop batch
            ENDLOOP.
*endloop venum = lvbplp-unvel
          ENDLOOP.
*endloop venum = venum = lvbplk-venum
        ELSE.
*for roll no box
*          flag_venum = 'true'.
          LOOP AT DATA_BATCH WHERE BATCH_CHARG EQ LVBPLP-CHARG.
            CLEAR V_TAB.
            REFRESH V_TAB.
            V_FLAG_ZZALIAS_HU = ''.
*get its charg
            V_CHARG_QTY = DATA_BATCH-BATCH_CHARG.
            CALL FUNCTION 'QC01_BATCH_VALUES_READ'
              EXPORTING
                I_VAL_MATNR    = V_MATNR
                I_VAL_WERKS    = V_WERKS
                I_VAL_CHARGE   = V_CHARG_QTY
                I_LANGUAGE     = SY-LANGU
                I_DATE         = SY-DATUM
              TABLES
                T_VAL_TAB      = V_TAB
              EXCEPTIONS
                NO_CLASS       = 01
                INTERNAL_ERROR = 02
                NO_VALUES      = 03
                NO_CHARS       = 04.
            IF SY-SUBRC = 0.
              SORT V_TAB BY ATNAM.
              LOOP AT V_TAB.
                IF V_TAB-ATNAM = 'ZZDERIVATIVEMS'.
                  DATA_BATCH_DIGIT-DERIVATIVEMS = V_TAB-ATWRT.
                ELSEIF V_TAB-ATNAM = 'ZZPOSITIONMS'.
                  DATA_BATCH_DIGIT-POSITIONMS = V_TAB-ATWRT.
                ELSEIF V_TAB-ATNAM = 'ZZDERIVATIVESS'.
                  DATA_BATCH_DIGIT-DERIVATIVESS = V_TAB-ATWRT.
                ELSEIF V_TAB-ATNAM = 'ZZPOSITIONSS'.
                  DATA_BATCH_DIGIT-POSITIONSS = V_TAB-ATWRT.
                ELSEIF V_TAB-ATNAM = 'ZZCONVERSIONROLLKG'.
                  READ TABLE V_TAB WITH KEY ATNAM = 'ZZLABEL'.
                  IF SY-SUBRC EQ 0.
                    IF V_TAB-ATWRT = 'SB10' OR V_TAB-ATWRT = 'K100' OR V_TAB-ATWRT =
                      DATA: V_ROUND_WEIGHT TYPE P DECIMALS 2.
                      READ TABLE V_TAB WITH KEY ATNAM = 'ZZCONVERSIONROLLKG'.
                      PERFORM CONVERSION_WEIGHT USING V_TAB-ATFLV CHANGING V_ROUND_W
                      V_SUM_NETWEIGHT_ZCONV = V_SUM_NETWEIGHT_ZCONV + V_ROUND_WEIGHT
                    ELSE.
                      READ TABLE V_TAB WITH KEY ATNAM = 'ZZCONVERSIONROLLKG'.
                      V_SUM_NETWEIGHT_ZCONV = V_SUM_NETWEIGHT_ZCONV + V_TAB-ATFLV.
                    ENDIF.
                  ENDIF.
                ENDIF.
                APPEND DATA_BATCH_DIGIT.
              ENDLOOP.
*For check weight in mska and weight for alias, weight is still got from zconv......
              LOOP AT V_TAB.
                IF V_TAB-ATNAM = 'ZZALIAS'.
                  V_TYPE_HU = V_TAB-ATWRT.
                  V_FLAG_ZZALIAS_HU = 'X'.
                ENDIF.
                IF V_TAB-ATNAM = 'ZZPACKING' AND V_FLAG_ZZALIAS_HU = SPACE.
*Check if roll already sent or not
                  CLEAR : V_KALAB,
                          V_KAINS,
                          V_KASPE,
                          V_CLABS,
                          V_CINSM,
                          V_CEINM,
                          V_CSPEM.
                  SELECT SUM( KALAB )
                         SUM( KAINS )
                         SUM( KASPE )
                  INTO (V_KALAB,
                        V_KAINS,
                        V_KASPE )
                  FROM MSKA
                  WHERE MATNR = V_MATNR AND
                        WERKS = V_WERKS AND
                        CHARG = V_CHARG_QTY
                  GROUP BY MATNR WERKS CHARG.
                  ENDSELECT.
                  SELECT  SUM( CLABS )
                          SUM( CINSM )
                          SUM( CEINM )
                          SUM( CSPEM )
                  INTO (V_CLABS,
                        V_CINSM,
                        V_CEINM,
                        V_CSPEM )
                  FROM MCHB
                  WHERE MATNR = V_MATNR AND
                        WERKS = V_WERKS AND
                        CHARG = V_CHARG_QTY
                  GROUP BY MATNR WERKS CHARG.
                  ENDSELECT.
                  V_SUM_NETWEIGHT_TEMP = V_KALAB + V_KAINS + V_KASPE +
                                    V_CLABS + V_CINSM + V_CEINM +
                                    V_CSPEM.
*-----------------------------------------------------------
                  V_SUM_NETWEIGHT = V_SUM_NETWEIGHT_TEMP + V_SUM_NETWEIGHT.
                ELSEIF V_TAB-ATNAM = 'ZZPACKING' AND V_FLAG_ZZALIAS_HU = 'X'.
                  PERFORM MOD_WEIGHT_ALIAS_HU USING V_MATNR V_CHARG_QTY V_WERKS V_TY
                  V_SUM_NETWEIGHT = V_SUM_NETWEIGHT_TEMP + V_SUM_NETWEIGHT.
                ENDIF.
              ENDLOOP.
              IF D_FLAG_NO_DC EQ SPACE.
                V_SUM_NETWEIGHT = V_SUM_NETWEIGHT_ZCONV.
                V_SUM_NETWEIGHT_TEMP = V_SUM_NETWEIGHT.
*Count Roll in internal tabel digit
*                DESCRIBE TABLE data_batch_digit LINES v_tot_roll.
              ELSE.
                IF V_SUM_NETWEIGHT <> 0 AND V_FLAG_ZZALIAS_HU <> 'X'.
                  V_SUM_NETWEIGHT_TEMP = V_SUM_NETWEIGHT.
                ENDIF.
              ENDIF.
            ELSE.
*----------
*Old Print Box Pallet
              LOOP AT V_TAB.
                IF V_TAB-ATNAM = 'ZZNUMBEROFSHEET'.
                  PERFORM CONV_TO_CHAR USING V_TAB-ATWTB.
                  V_SUM_QTYSHEET = V_SUM_QTYSHEET + V_TAB-ATWTB.
*count sum weight for all sheet depend on its charg, not main charg
*-------------------------------
*Get Net weight...
                ENDIF.
                IF V_TAB-ATNAM = 'ZZALIAS'.
                  V_TYPE_HU = V_TAB-ATWRT.
                  V_FLAG_ZZALIAS_HU = 'X'.
                ENDIF.
                IF V_TAB-ATNAM = 'ZZPACKING' AND V_FLAG_ZZALIAS_HU = SPACE.
                  CLEAR : V_KALAB,
                          V_KAINS,
                          V_KASPE,
                          V_CLABS,
                          V_CINSM,
                          V_CEINM,
                          V_CSPEM.
                  SELECT SUM( KALAB )
                         SUM( KAINS )
                         SUM( KASPE )
                  INTO (V_KALAB,
                        V_KAINS,
                        V_KASPE )
                  FROM MSKA
                  WHERE MATNR = V_MATNR AND
                        WERKS = V_WERKS AND
                        CHARG = V_CHARG_QTY
                  GROUP BY MATNR WERKS CHARG.
                  ENDSELECT.
                  SELECT  SUM( CLABS )
                          SUM( CINSM )
                          SUM( CEINM )
                          SUM( CSPEM )
                  INTO (V_CLABS,
                        V_CINSM,
                        V_CEINM,
                        V_CSPEM )
                  FROM MCHB
                  WHERE MATNR = V_MATNR AND
                        WERKS = V_WERKS AND
                        CHARG = V_CHARG_QTY
                  GROUP BY MATNR WERKS CHARG.
                  ENDSELECT.
                  V_SUM_NETWEIGHT_TEMP = V_KALAB + V_KAINS + V_KASPE +
                                    V_CLABS + V_CINSM + V_CEINM +
                                    V_CSPEM.
*-----------------------------------------------------------
                  V_SUM_NETWEIGHT = V_SUM_NETWEIGHT_TEMP + V_SUM_NETWEIGHT.
                ELSEIF V_TAB-ATNAM = 'ZZPACKING' AND V_FLAG_ZZALIAS_HU = 'X'.
                  PERFORM MOD_WEIGHT_ALIAS_HU USING V_MATNR V_CHARG_QTY V_WERKS V_TY
                  V_SUM_NETWEIGHT = V_SUM_NETWEIGHT_TEMP + V_SUM_NETWEIGHT.
                ENDIF.
              ENDLOOP.
*              ENDIF.
            ENDIF.
*endloop batch
          ENDLOOP.
*for roll no box
        ENDIF.
      ENDLOOP.
    ENDIF.  "user TRSTDEV
*end sy-uname.
*Sum of Sheet
    WRITE V_SUM_QTYSHEET TO V_S_SUM_QTYSHEET.
*Getting total box records no...
    CLEAR V_TOT_BOX.
    IF LVBPLK-VHART = '0009' OR LVBPLK-VHART = '0010'.
      V_TOT_BOX = SPACE.
    ELSE.
      CLEAR V_TOT_BOX.
      CLEAR V_LVBPLP.
      REFRESH V_LVBPLP.
      LOOP AT LVBPLP WHERE VENUM = LVBPLK-VENUM.
        IF LVBPLP-UNVEL <> SPACE. "pallet/tumpukan
          LOOP AT LVBPLP WHERE VENUM = LVBPLP-UNVEL.
            IF LVBPLP-UNVEL <> SPACE. "tumpukan
              LOOP AT LVBPLP WHERE VENUM = LVBPLP-UNVEL.
                V_LVBPLP = LVBPLP.
                APPEND V_LVBPLP.
              ENDLOOP.
            ELSE.
              V_LVBPLP = LVBPLP.
              APPEND V_LVBPLP.
            ENDIF.
          ENDLOOP.
        ELSE. "suspended
        ENDIF.
      ENDLOOP.
      SORT V_LVBPLP BY VENUM.
      DELETE V_LVBPLP WHERE MATNR = SPACE.
      DELETE ADJACENT DUPLICATES FROM V_LVBPLP COMPARING VENUM.
      LOOP AT V_LVBPLP WHERE MATNR <> SPACE.
        ADD 1 TO V_TOT_BOX.
      ENDLOOP.
    ENDIF.
    CLEAR V_TAB.
    REFRESH V_TAB.
* Get width, length for same slitroll based last v_charg_qty
    V_CHARG  = V_CHARG_QTY.
    CALL FUNCTION 'QC01_BATCH_VALUES_READ'
      EXPORTING
        I_VAL_MATNR    = V_MATNR
        I_VAL_WERKS    = V_WERKS
        I_VAL_CHARGE   = V_CHARG
        I_LANGUAGE     = SY-LANGU
        I_DATE         = SY-DATUM
      TABLES
        T_VAL_TAB      = V_TAB
      EXCEPTIONS
        NO_CLASS       = 01
        INTERNAL_ERROR = 02
        NO_VALUES      = 03
        NO_CHARS       = 04.
    IF SY-SUBRC = 0.
      "Check using zebra printer or not
      PERFORM CHECK_USING_ZEBRA CHANGING V_IS_ZEBRA_LABELPACK.
*Mod Selection Label 03/06/06
      READ TABLE V_TAB WITH KEY ATNAM = 'ZZLABEL'.
      IF SY-SUBRC = 0.
        "Under Windows
        SELECT SINGLE PROG_HU INTO VPROGNAME FROM ZMAP_LABEL WHERE CODE = V_TAB-ATWR
        "Start Add Bothside Treatment by Fiqih (29.04.2026)
        "Dianggap New Label jika memiliki mapping (Apapun itu) pada TEXT2 ZMAP_LABEL
        DATA: V_IS_NEW_LABEL(20) TYPE C.
        CLEAR V_IS_NEW_LABEL.
        SELECT SINGLE TEXT2
          INTO V_IS_NEW_LABEL
          FROM ZMAP_LABEL
          WHERE CODE EQ V_TAB-ATWRT.
        "End Add Bothside Treatment by Fiqih (29.04.2026)
        IF VPROGNAME IS NOT INITIAL.
          "if using zebra, change the emulation first
           IF V_IS_ZEBRA_LABELPACK EQ 'X'.
             PERFORM CHANGE_ZEBRA_EMULATION USING 'NONE'.
           ENDIF.
          SUBMIT (VPROGNAME) WITH V_CHARG EQ V_CHARG
                               WITH V_MATNR EQ V_MATNR
                               WITH V_WERKS EQ V_WERKS
                               WITH V_TOTRL EQ V_TOT_ROLL
                               WITH V_TOTBX EQ V_TOT_BOX
                               WITH V_EXIDV EQ V_EXIDV
                               WITH V_MAGRV EQ V_MAGRV
                               WITH V_DATMM EQ V_ERDAT_MM
                               WITH V_DATYY EQ V_ERDAT_YY
                               WITH V_DATDD EQ V_ERDAT_DD
                               WITH V_TMWGHT EQ V_SUM_NETWEIGHT_TEMP
                               AND RETURN.
           EXIT.
        "ELSEIF V_TAB-ATWRT+1(1) = '0'. "Commented For Enhancement Bothside Treatmen
        ELSEIF V_TAB-ATWRT+1(1) = '0' AND V_IS_NEW_LABEL IS INITIAL. "Edited For Enh
*Old Label - Jika nama tipe label menggunakan '0' pada karakter kedua Cth A0XX, B0XX
          IF ( V_TAB-ATWRT = 'D009' OR V_TAB-ATWRT = 'D010'  OR V_TAB-ATWRT = 'D013'
             OR V_TAB-ATWRT = 'B013' OR V_TAB-ATWRT = 'B014' OR V_TAB-ATWRT = 'B015'
              OR V_TAB-ATWRT = 'A010' OR V_TAB-ATWRT = 'A011' OR V_TAB-ATWRT = 'A012
              OR V_TAB-ATWRT = 'A015' OR V_TAB-ATWRT = 'A016' OR V_TAB-ATWRT = 'A017
              OR V_TAB-ATWRT = 'A018' OR V_TAB-ATWRT = 'A019'
              OR V_TAB-ATWRT = 'L001' OR V_TAB-ATWRT = 'L002' OR V_TAB-ATWRT = 'L003
              OR V_TAB-ATWRT = 'D014' OR V_TAB-ATWRT = 'D015' OR V_TAB-ATWRT = 'G001
              OR V_TAB-ATWRT = 'L011' OR V_TAB-ATWRT = 'L012'
              ).
            PERFORM INTER_TEXT_DATA.
          ELSE.
*Trias
            PERFORM TEXT_DATA.
          ENDIF.
        ELSE.
*New Label
          IF ( V_TAB-ATWRT = 'A300' OR V_TAB-ATWRT = 'A301' OR V_TAB-ATWRT = 'A304'
               OR V_TAB-ATWRT = 'A142' OR V_TAB-ATWRT = 'A145' OR V_TAB-ATWRT = 'A13
            PERFORM INCH_TEXT_DATA.
          ELSE.
            PERFORM NEW_TEXT_DATA.
          ENDIF.
        ENDIF.
      ENDIF.
*************
      PERFORM DOWNLOAD_DATA.
      PERFORM GETFRSRV_B.
      PERFORM PRINT.
      REFRESH TEXT_DATA.
      CLEAR TEXT_DATA.
    ELSE.
      MESSAGE E001.
    ENDIF.
  ENDIF.
ENDFORM.                    "GET_DATA
FORM CONVERSION_WEIGHT USING ATFLV CHANGING WEIGHT.
  DATA: TOCHAR1 TYPE P DECIMALS 2,
        TOCHAR2 TYPE P DECIMALS 1.
  TOCHAR1 = ATFLV.
  CALL FUNCTION 'ROUND'
    EXPORTING
      DECIMALS      = 1
      INPUT         = TOCHAR1
      SIGN          = '-'
    IMPORTING
      OUTPUT        = TOCHAR2
    EXCEPTIONS
      INPUT_INVALID = 1
      OVERFLOW      = 2
      TYPE_INVALID  = 3
      OTHERS        = 4.
  IF SY-SUBRC EQ 0.
    WEIGHT = TOCHAR2.
*    CONDENSE WEIGHT NO-GAPS.
  ENDIF.
ENDFORM.
* Öffnen Formular
FORM FORM_OPEN USING US_SCREEN US_COUNTRY.
  INCLUDE RVADOPFO.
ENDFORM.                    "FORM_OPEN
* Ausgabe der Etikettierungsdaten
FORM ITEM_PRINT.
* Vorbereiten SAPscript-Daten
  VBPLK = LVBPLK.                     "Versandelementkopfdaten
  VBPLA = LVBPLA.                     "Versandadreßdaten
* Dummy-Aufruf, um Seitenfenster zu füllen
  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
      ELEMENT = 'DUMMY'
    EXCEPTIONS
      OTHERS  = 1.
  IF SY-SUBRC NE 0.
    RETCODE = 1.
    PERFORM PROTOCOL_UPDATE.
  ENDIF.
ENDFORM.                    "ITEM_PRINT
* Formular schliessen
FORM FORM_CLOSE.
  CALL FUNCTION 'CLOSE_FORM'
    EXCEPTIONS
      OTHERS = 1.
  IF SY-SUBRC NE 0.
    RETCODE = 1.
    PERFORM PROTOCOL_UPDATE.
  ENDIF.
  SET COUNTRY SPACE.
ENDFORM.                    "FORM_CLOSE
* Nachrichtenaufbereitung
FORM PROTOCOL_UPDATE.
  CHECK SCREEN = ' '.
  CALL FUNCTION 'NAST_PROTOCOL_UPDATE'
    EXPORTING
      MSG_ARBGB = SY-MSGID
      MSG_NR    = SY-MSGNO
      MSG_TY    = SY-MSGTY
      MSG_V1    = SY-MSGV1
      MSG_V2    = SY-MSGV2
      MSG_V3    = SY-MSGV3
      MSG_V4    = SY-MSGV4
    EXCEPTIONS
      OTHERS    = 1.
ENDFORM.                    "PROTOCOL_UPDATE
*&---------------------------------------------------------------------*
*&      Form  mod_weight_alias
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_V_MATNR  text
*      -->P_V_CHARG  text
*      -->P_V_WERKS  text
*      -->P_V_TYPE  text
*----------------------------------------------------------------------*
FORM MOD_WEIGHT_ALIAS_HU  USING    V_MATNR
                                V_CHARG
                                V_WERKS
                                V_TYPE.
*select data from alias table
  SELECT SINGLE LENGT WIDTH THICK DENSI
  INTO (WA_LENGT, WA_WIDTH, WA_THICK, WA_DENSI)
  FROM ZALIAS
  WHERE
  MATNR = V_MATNR AND
  CHARG = V_CHARG AND
  WERKS = V_WERKS AND
  ZALIA = V_TYPE.
*Jika ada perubahan thicknes dan berat
  IF SY-SUBRC = 0.
    V_SUM_NETWEIGHT_TEMP = ( WA_LENGT * WA_WIDTH * WA_THICK * WA_DENSI ) / 1000000.
    V_FLAG_WEIGHT_ZZALIAS = 'X'.
*Jika tidak ada perubahan (standard)
  ELSE.
    CLEAR : V_KALAB,
          V_KAINS,
          V_KASPE,
          V_CLABS,
          V_CINSM,
          V_CEINM,
          V_CSPEM.
    SELECT SUM( KALAB )
           SUM( KAINS )
           SUM( KASPE )
    INTO (V_KALAB,
          V_KAINS,
          V_KASPE )
    FROM MSKA
    WHERE MATNR = V_MATNR AND
          WERKS = V_WERKS AND
          CHARG = V_CHARG_QTY
    GROUP BY MATNR WERKS CHARG.
    ENDSELECT.
    SELECT  SUM( CLABS )
            SUM( CINSM )
            SUM( CEINM )
            SUM( CSPEM )
    INTO (V_CLABS,
          V_CINSM,
          V_CEINM,
          V_CSPEM )
    FROM MCHB
    WHERE MATNR = V_MATNR AND
          WERKS = V_WERKS AND
          CHARG = V_CHARG_QTY
    GROUP BY MATNR WERKS CHARG.
    ENDSELECT.
    V_SUM_NETWEIGHT_TEMP = V_KALAB + V_KAINS + V_KASPE +
                      V_CLABS + V_CINSM + V_CEINM +
                      V_CSPEM.
  ENDIF.
ENDFORM.                    " mod_weight_alias
*- Add by ALF for QA PASS condition
FORM CEK_QAPASS.
  IF NAST-KSCHL NE 'Z002'.
    EXIT.
  ENDIF.
  DATA: V_PSTAT LIKE ZQM001-PSTAT.
  SELECT SINGLE ZQM001~PSTAT INTO V_PSTAT
    FROM ZQM001 JOIN VEKP ON ZQM001~EXIDV = VEKP~EXIDV
    WHERE VEKP~VENUM = NAST-OBJKY.
  IF V_PSTAT EQ 'P' OR V_PSTAT EQ 'H'.
  ELSE.
    MESSAGE 'Status Packing belum QA PASS/HOLD...!' TYPE 'I'.
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.                    "CEK_QAPASS
*&---------------------------------------------------------------------*
*&      Form  CEK_CODEPACK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->V_EXIDV    text
*----------------------------------------------------------------------*
FORM CEK_CODEPACK USING V_EXIDV.
  DATA: V_VBELN   TYPE VBAP-VBELN,
        V_POSNR   TYPE VBAP-POSNR,
        V_CUOBJ   TYPE VBAP-CUOBJ,
        V_ATWRT   TYPE V_IBIN_SYVAL-ATWRT,
        V_SONUM   LIKE VEPO-SONUM,
        V_UNVEL   LIKE VEPO-UNVEL,
        V_PALLET  LIKE ZBOARDR-EXIDV,
        V_ATINN   LIKE CABN-ATINN.
  SELECT SINGLE UNVEL SONUM INTO (V_UNVEL, V_SONUM)
    FROM VEKP JOIN VEPO ON VEKP~VENUM = VEPO~VENUM
    WHERE VEKP~EXIDV = V_EXIDV.
  IF V_SONUM IS INITIAL.
    SELECT SINGLE SONUM INTO V_SONUM
      FROM VEPO WHERE VENUM = V_UNVEL.
  ENDIF.
  IF V_SONUM IS NOT INITIAL.
    V_VBELN = V_SONUM(10).
    V_POSNR = V_SONUM+10(6).
    SELECT SINGLE CUOBJ INTO V_CUOBJ FROM VBAP WHERE VBELN EQ V_VBELN AND POSNR EQ V
    IF SY-SUBRC NE 0.
      MESSAGE 'Data SO tidak ditemukan' TYPE 'I'.
      LEAVE LIST-PROCESSING.
    ELSE.
      SELECT SINGLE ATINN INTO V_ATINN FROM CABN WHERE ATNAM = 'ZZPACKINGCODE'.
      SELECT SINGLE A~ATWRT INTO V_ATWRT FROM V_IBIN_SYVAL AS A JOIN IBIN  AS B ON A
       WHERE B~INSTANCE EQ V_CUOBJ
         AND A~ATINN EQ V_ATINN.
    ENDIF.
    IF V_ATWRT EQ 'RSB00001'.
      PERFORM F_CEK_HU   USING V_EXIDV CHANGING V_PALLET.
      PERFORM F_GET_SBID USING V_PALLET.
    ELSEIF V_ATWRT EQ 'RPS00001'.
      PERFORM F_CEK_HU   USING V_EXIDV CHANGING V_PALLET.
      PERFORM F_GET_RTP  USING V_PALLET.
      PERFORM F_GET_SBID USING V_PALLET.
    ENDIF.
  ENDIF.
ENDFORM.                    "CEK_CODEPACK
*&---------------------------------------------------------------------*
*&      Form  F_CEK_HU
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM F_CEK_HU USING EXIDV CHANGING V_PALLET.
  DATA: V_CEKHU   LIKE VEKP-EXIDV,
        V_UEVEL   LIKE VEKP-UEVEL.
  V_CEKHU   = EXIDV.
  V_PALLET  = EXIDV.
  SHIFT V_CEKHU LEFT DELETING LEADING '0'.
  IF V_CEKHU(1) EQ '1'.
    SELECT SINGLE UEVEL INTO V_UEVEL FROM VEKP WHERE EXIDV EQ V_PALLET.
    IF SY-SUBRC EQ 0.
      SELECT SINGLE EXIDV INTO V_PALLET FROM VEKP WHERE VENUM EQ V_UEVEL.
    ENDIF.
  ENDIF.
ENDFORM.                    "F_CEK_HU
*&---------------------------------------------------------------------*
*&      Form  F_GET_SBID
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM F_GET_SBID USING EXIDV.
  DATA: V_CEKHU TYPE VEKP-EXIDV,
        V_SBID  TYPE ZBOARDR-BOARDID,
        V_SBID1 TYPE ZBOARDR-BOARDID,
        V_SBID2 TYPE ZBOARDR-BOARDID,
        V_FLAG(1).
  CLEAR: V_CEKHU, V_SBID, V_SBID1, V_SBID2, V_FLAG.
  SELECT SINGLE EXIDV INTO V_CEKHU FROM ZBOARDR WHERE EXIDV EQ EXIDV. "Cek HU in ZBO
  IF SY-SUBRC EQ 0.
    SELECT BOARDID FROM ZBOARDR INTO V_SBID WHERE EXIDV EQ EXIDV.
      IF V_SBID1 IS INITIAL.
        V_SBID1 = V_SBID.
      ELSE.
        V_SBID2 = V_SBID.
        IF V_SBID2 IS INITIAL.
          V_FLAG = 'X'.
        ENDIF.
      ENDIF.
    ENDSELECT.
  ELSE.
    V_FLAG = 'X'.
  ENDIF.
  IF V_FLAG EQ 'X'.
    MESSAGE 'SB kurang/tidak terikat' TYPE 'I'.
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.                    "F_GET_SBID
*&---------------------------------------------------------------------*
*&      Form  F_GET_RTP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM F_GET_RTP USING EXIDV.
  DATA: V_CEKHU TYPE VEKP-EXIDV,
        V_PALID TYPE ZPALLETR-PALID,
        V_FLAG(1).
  CLEAR: V_CEKHU, V_PALID,  V_FLAG.
  SELECT SINGLE EXIDV PALID INTO (V_CEKHU, V_PALID) FROM ZPALLETR WHERE EXIDV EQ EXI
  IF SY-SUBRC NE 0.
    MESSAGE 'HU Belum terikat PALID' TYPE 'I'.
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.                    "F_GET_RTP
*&---------------------------------------------------------------------*
*&  Include           ZQMI_CERTIFICATE_F01
*&---------------------------------------------------------------------*
INITIALIZATION.
  MOVE 'Program Information' TO INFO.
* Cache format MIC dari master QPMK: decimal places (STELLEN) + unit, per MIC
* dan per plant. Dibaca sekali per kombinasi lalu dilayani dari memori.
* Dinamis penuh - MIC baru otomatis ikut tanpa perlu ubah kode.
  TYPES: BEGIN OF TY_MICFMT,
           MKMNR   TYPE QPMK-MKMNR,
           WERKS   TYPE QPMK-WERKS,
           STELLEN TYPE QPMK-STELLEN,
           UOM     TYPE QPMK-MASSEINHSW,
         END OF TY_MICFMT.
  DATA: GT_MICFMT TYPE TABLE OF TY_MICFMT,
        GS_MICFMT TYPE TY_MICFMT.
  DATA: GV_DEC TYPE I,
        GV_UOM TYPE QPMK-MASSEINHSW.
* Cache hasil rata-rata JR per mother roll (enhancement 18/07/2026).
  TYPES: BEGIN OF TY_JRAVG,
           INSLOT TYPE QALS-PRUEFLOS,
           MIC    TYPE QAMV-VERWMERKM,
           ISJR   TYPE C,
           VAL    TYPE QAMR-MITTELWERT,
           CNT    TYPE I,
         END OF TY_JRAVG.
  DATA: GT_JRAVG TYPE TABLE OF TY_JRAVG,
        GS_JRAVG TYPE TY_JRAVG.
  TYPES: BEGIN OF TY_BARAVG,
           VBELN TYPE LIPS-VBELN,
           MIC   TYPE QAMV-VERWMERKM,
           VAL   TYPE QAMR-MITTELWERT,
           CNT   TYPE I,
         END OF TY_BARAVG.
  DATA: GT_BARAVG TYPE TABLE OF TY_BARAVG,
        GS_BARAVG TYPE TY_BARAVG.
* Cache hasil rata-rata SR Convert (enhancement 28/07/2026).
  TYPES: BEGIN OF TY_LOT_AVG,
             INSLOT     TYPE QALS-PRUEFLOS,
             MERKNR     TYPE QAMR-MERKNR,
             MITTELWERT TYPE QAMR-MITTELWERT,
             ANZWERTG   TYPE QAMR-ANZWERTG,
           END OF TY_LOT_AVG.
  DATA: GT_LOT_AVG TYPE TABLE OF TY_LOT_AVG,
        GS_LOT_AVG TYPE TY_LOT_AVG.
  DATA: LOT_SR_CONV2 TYPE QALS-PRUEFLOS.
AT SELECTION-SCREEN.
  IF SY-UCOMM = 'INFO'.
    PERFORM F_PROG_INFO USING V_PROG.
  ENDIF.
INITIALIZATION.
  CALL FUNCTION 'CONVERSION_EXIT_ATINN_INPUT'
    EXPORTING
      INPUT  = 'ZZNOMORROLL'
    IMPORTING
      OUTPUT = ATINN_ROLL.
  CALL FUNCTION 'CONVERSION_EXIT_ATINN_INPUT'
    EXPORTING
      INPUT  = 'ZZCODE'
    IMPORTING
      OUTPUT = ATINN_CODE.
  CALL FUNCTION 'CONVERSION_EXIT_ATINN_INPUT'
    EXPORTING
      INPUT  = 'ZZWIDTH'
    IMPORTING
      OUTPUT = ATINN_WIDTH.
  CALL FUNCTION 'CONVERSION_EXIT_ATINN_INPUT'
    EXPORTING
      INPUT  = 'ZZLENGTH'
    IMPORTING
      OUTPUT = ATINN_LENGTH.
AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF SCREEN-GROUP1 = 'R03'.
      IF SY-TCODE = 'ZQM003'.
        SCREEN-ACTIVE = 1.
      ELSE.
        SCREEN-ACTIVE = 0.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
START-OF-SELECTION.
  IF SY-TCODE = 'ZQM003'.
    PERFORM RPT_PRESELECT.
    PERFORM GET_DATA.
    PERFORM RPT_FILTER.
    PERFORM RPT_BUILD.
    PERFORM RPT_DISPLAY.
  ELSEIF P_VBELN IS INITIAL.
    MESSAGE 'Nomor ODO (Delivery) WAJIB diisi! Meski ingin filter by Batch/Roll, ODO
  ELSE.
    PERFORM GET_DATA.
    SORT IT_DATA BY VBELN CHARG NUMMIC NUM ASCENDING CHK DESCENDING.
    CALL SCREEN 0100.
  ENDIF.
*&---------------------------------------------------------------------*
*&      Form  get_data
*&----------------------------------------------------AAA-----------------*
*       text
*----------------------------------------------------------------------*
FORM GET_DATA.
  DATA : TEXT1 TYPE C LENGTH 25,
         TEXT2 TYPE C LENGTH 30,
         INSPOPER TYPE BAPI2045L2-INSPOPER,
         ROLL TYPE C LENGTH 10,
         LV_KUNNR LIKE ZMAP_COA-KUNNR.
  DATA : R_PSTYV TYPE RANGE OF LIPS-PSTYV,
         WA_PSTYV LIKE LINE OF R_PSTYV,
         IT_ZMAP_DELIV TYPE STANDARD TABLE OF ZMAP_TYPE WITH HEADER LINE.
  CLEAR : TEXT1, TEXT2,ROLL, R_PSTYV, IT_ZMAP_DELIV.
  REFRESH : R_PSTYV, IT_ZMAP_DELIV.
  SELECT PROG TYPE VALUE INTO CORRESPONDING FIELDS OF TABLE IT_ZMAP_DELIV FROM ZMAP_
    WHERE PROG = SY-CPROG AND TYPE = 'ITEM CATEGORY'.
  LOOP AT IT_ZMAP_DELIV.
    WA_PSTYV-SIGN = 'I'.
    WA_PSTYV-OPTION = 'EQ'.
    WA_PSTYV-LOW = IT_ZMAP_DELIV-VALUE.
    APPEND WA_PSTYV TO R_PSTYV.
  ENDLOOP.
  IF R_PSTYV[] IS INITIAL.
    WA_PSTYV-SIGN = 'I'. WA_PSTYV-OPTION = 'EQ'. WA_PSTYV-LOW = 'ZB'. APPEND WA_PSTY
  ENDIF.
  IF P_CHARG IS INITIAL AND P_ATWRT IS NOT INITIAL.
    SELECT OBJEK INTO WA_OBJEK-OBJEK
      FROM  AUSP
      WHERE AUSP~ATINN = ATINN_ROLL
      AND AUSP~ATWRT IN P_ATWRT"-LOW "= '4 PEE 5 010103'
      %_HINTS ORACLE 'INDEX("AUSP~N1")'.
      APPEND WA_OBJEK TO IT_OBJEK.
    ENDSELECT.
    IF IT_OBJEK[] IS NOT INITIAL.
      " Extract unique CHARG to fetch LIPS
      DATA: IT_CHARG_TMP LIKE TABLE OF WA_OBJEK WITH HEADER LINE.
      IT_CHARG_TMP[] = IT_OBJEK[].
      LOOP AT IT_OBJEK INTO WA_OBJEK.
        SELECT SINGLE INOB~OBJEK INTO WA_OBJEK-IOBJEK
        FROM  INOB
        WHERE CUOBJ = WA_OBJEK-OBJEK.
        SPLIT WA_OBJEK-IOBJEK AT SPACE INTO TEXT1 TEXT2.
        CONDENSE: TEXT1,TEXT2.
        WA_OBJEK-OBJ = TEXT1.
        WA_OBJEK-CHARG = TEXT2.
        MODIFY IT_OBJEK FROM WA_OBJEK.
      ENDLOOP.
      IF IT_OBJEK[] IS NOT INITIAL.
        SELECT VBELN POSNR CHARG MATNR WERKS UECHA
          INTO CORRESPONDING FIELDS OF TABLE IT_DATA
          FROM LIPS
          FOR ALL ENTRIES IN IT_OBJEK
          WHERE VBELN IN P_VBELN
            AND POSNR IN P_POSNR
            AND MATNR IN P_MATNR
            AND CHARG = IT_OBJEK-CHARG
            AND PSTYV IN R_PSTYV.
        IF P_POSNR-LOW IS NOT INITIAL.
          SELECT VBELN POSNR CHARG MATNR WERKS UECHA
            APPENDING CORRESPONDING FIELDS OF TABLE IT_DATA
            FROM LIPS
            FOR ALL ENTRIES IN IT_OBJEK
            WHERE VBELN IN P_VBELN
              AND UECHA IN P_POSNR
              AND MATNR IN P_MATNR
              AND CHARG = IT_OBJEK-CHARG
              AND PSTYV IN R_PSTYV.
        ENDIF.
      ENDIF.
    ENDIF.
  ELSE.
    SELECT VBELN POSNR CHARG MATNR WERKS UECHA
      INTO CORRESPONDING FIELDS OF TABLE IT_DATA
      FROM LIPS
      WHERE VBELN IN P_VBELN
        AND POSNR IN P_POSNR
        AND MATNR IN P_MATNR
        AND CHARG IN P_CHARG
        AND PSTYV IN R_PSTYV.
    IF P_POSNR-LOW IS NOT INITIAL.
      SELECT VBELN POSNR CHARG MATNR WERKS UECHA
        APPENDING CORRESPONDING FIELDS OF TABLE IT_DATA
        FROM LIPS
        WHERE VBELN IN P_VBELN
          AND UECHA IN P_POSNR
          AND MATNR IN P_MATNR
          AND CHARG IN P_CHARG
          AND PSTYV IN R_PSTYV.
    ENDIF.
  ENDIF.
  DELETE IT_DATA WHERE CHARG IS INITIAL.
  " Enhancement: Group by Material (Representative Batch)
  " SORT IT_DATA BY VBELN MATNR CHARG.
  " DELETE ADJACENT DUPLICATES FROM IT_DATA COMPARING VBELN MATNR.
  " ----------------------------------------------------------------------
  " PHASE 1 & 2: BULK CHARACTERISTIC EXTRACTION
  " ----------------------------------------------------------------------
  CLEAR IT_BATCH_COLLECT. REFRESH IT_BATCH_COLLECT.
  LOOP AT IT_DATA.
    IT_BATCH_COLLECT-MATNR = IT_DATA-MATNR.
    IT_BATCH_COLLECT-CHARG = IT_DATA-CHARG.
    APPEND IT_BATCH_COLLECT.
  ENDLOOP.
  SORT IT_BATCH_COLLECT BY MATNR CHARG.
  DELETE ADJACENT DUPLICATES FROM IT_BATCH_COLLECT COMPARING MATNR CHARG.
  CLEAR IT_INOB. REFRESH IT_INOB.
  CLEAR IT_AUSP. REFRESH IT_AUSP.
  CLEAR IT_TEMP_OBJEK. REFRESH IT_TEMP_OBJEK.
  IF IT_BATCH_COLLECT[] IS NOT INITIAL.
    LOOP AT IT_BATCH_COLLECT.
      IT_TEMP_OBJEK-OBJEK = IT_BATCH_COLLECT-MATNR.
      IT_TEMP_OBJEK-OBJEK+18(10) = IT_BATCH_COLLECT-CHARG.
      APPEND IT_TEMP_OBJEK.
    ENDLOOP.
    SELECT CUOBJ OBJEK INTO TABLE IT_INOB_RAW
      FROM INOB
      FOR ALL ENTRIES IN IT_TEMP_OBJEK
      WHERE OBJEK = IT_TEMP_OBJEK-OBJEK
        AND OBTAB = 'MCH1'.
    LOOP AT IT_INOB_RAW.
      IT_INOB-CUOBJ = IT_INOB_RAW-CUOBJ.
      IT_INOB-OBJEK = IT_INOB_RAW-CUOBJ.
      IT_INOB-MATNR = IT_INOB_RAW-OBJEK(18).
      IT_INOB-CHARG = IT_INOB_RAW-OBJEK+18(10).
      APPEND IT_INOB.
    ENDLOOP.
    SORT IT_INOB BY MATNR CHARG.
  ENDIF.
  IF IT_INOB[] IS NOT INITIAL.
    SELECT OBJEK ATINN ATWRT ATFLV INTO TABLE IT_AUSP
      FROM AUSP
      FOR ALL ENTRIES IN IT_INOB
      WHERE OBJEK = IT_INOB-OBJEK
        AND ( ATINN = ATINN_ROLL OR ATINN = ATINN_CODE OR
              ATINN = ATINN_WIDTH OR ATINN = ATINN_LENGTH )
        AND KLART = '023'.
    SORT IT_AUSP BY OBJEK ATINN.
  ENDIF.
  " ----------------------------------------------------------------------
  " PHASE 3: ALV POPULATION
  " ----------------------------------------------------------------------
  REFRESH GT_LOT_AVG.
  LOOP AT IT_DATA.
    CLEAR: IT_DATA-NOMSR, IT_DATA-ZZTYPE, IT_DATA-ZZWIDTH,
           IT_DATA-ZZLENGTH.
    DATA: L_SUBRC TYPE SY-SUBRC.
    READ TABLE IT_INOB WITH KEY MATNR = IT_DATA-MATNR CHARG = IT_DATA-CHARG BINARY S
    IF SY-SUBRC EQ 0.
      READ TABLE IT_AUSP WITH KEY OBJEK = IT_INOB-OBJEK ATINN = ATINN_ROLL BINARY SE
      IF SY-SUBRC EQ 0.
        IT_DATA-NOMSR = IT_AUSP-ATWRT.
      ENDIF.
      READ TABLE IT_AUSP WITH KEY OBJEK = IT_INOB-OBJEK ATINN = ATINN_CODE BINARY SE
      L_SUBRC = SY-SUBRC.
      IF SY-SUBRC EQ 0.
        IT_DATA-ZZTYPE = IT_AUSP-ATWRT.
      ENDIF.
      READ TABLE IT_AUSP WITH KEY OBJEK = IT_INOB-OBJEK
                                  ATINN = ATINN_WIDTH BINARY SEARCH.
      IF SY-SUBRC EQ 0.
        IT_DATA-ZZWIDTH = IT_AUSP-ATFLV.
      ENDIF.
      READ TABLE IT_AUSP WITH KEY OBJEK = IT_INOB-OBJEK
                                  ATINN = ATINN_LENGTH BINARY SEARCH.
      IF SY-SUBRC EQ 0.
        IT_DATA-ZZLENGTH = IT_AUSP-ATFLV.
      ENDIF.
    ELSE.
      L_SUBRC = 4.
    ENDIF.
    IF L_SUBRC EQ 0.
      " Edited by J. Budi (Antigravity) on 28.06.2026
      DATA: IT_ZMAP_GEN LIKE TABLE OF IT_ZMAP WITH HEADER LINE,
            IT_ZMAP_CUS LIKE TABLE OF IT_ZMAP WITH HEADER LINE.
      CLEAR : IT_ZMAP, LV_KUNNR, IT_ZMAP_GEN, IT_ZMAP_CUS.
      REFRESH: IT_ZMAP, IT_ZMAP_GEN, IT_ZMAP_CUS.
      SELECT SINGLE KUNAG INTO LV_KUNNR
        FROM LIKP
        WHERE VBELN = IT_DATA-VBELN.
      " Edited by J. Budi (Antigravity) on 28.06.2026
      SELECT MATNR MIC KUNNR METHOD MAPPING
        INTO CORRESPONDING FIELDS OF TABLE IT_ZMAP_GEN
        FROM ZMAP_COA
        WHERE MATNR    = IT_DATA-MATNR
          AND KUNNR    = ' '
          AND DELETION NE 'X'.
      IF LV_KUNNR IS NOT INITIAL.
        SELECT MATNR MIC KUNNR METHOD MAPPING
          INTO CORRESPONDING FIELDS OF TABLE IT_ZMAP_CUS
          FROM ZMAP_COA
          WHERE MATNR    = IT_DATA-MATNR
            AND KUNNR    = LV_KUNNR
            AND DELETION NE 'X'.
      ENDIF.
      IT_ZMAP[] = IT_ZMAP_GEN[].
      SORT IT_ZMAP BY MIC ASCENDING.
      LOOP AT IT_ZMAP_CUS.
        READ TABLE IT_ZMAP WITH KEY MIC = IT_ZMAP_CUS-MIC BINARY SEARCH.
        IF SY-SUBRC = 0.
          IT_ZMAP-METHOD = IT_ZMAP_CUS-METHOD.
          IT_ZMAP-KUNNR  = IT_ZMAP_CUS-KUNNR.
          IT_ZMAP-MAPPING = IT_ZMAP_CUS-MAPPING.
          MODIFY IT_ZMAP INDEX SY-TABIX.
        ELSE.
          APPEND IT_ZMAP_CUS TO IT_ZMAP.
        ENDIF.
      ENDLOOP.
      SORT IT_ZMAP BY MIC ASCENDING.
      DELETE ADJACENT DUPLICATES FROM IT_ZMAP COMPARING MIC.
      IF IT_ZMAP[] IS INITIAL.
        MESSAGE 'Material belum dimapping di ZMAP_COA. Harap lengkapi mapping terleb
        STOP.
      ENDIF.
    ENDIF.
    " Edited by J. Budi (Antigravity) on 28.06.2026
    PERFORM GET_TRACED_LOTS.
    PERFORM GET_MIC.
    IF IT_DATA-UECHA IS INITIAL.
      IT_DATA-UECHA = IT_DATA-POSNR.
    ENDIF.
    MODIFY IT_DATA.
  ENDLOOP.
  IT_LOT[] = IT_DATA[].
  CLEAR IT_DATA. REFRESH IT_DATA.
  SORT IT_MIC1 BY VBELN POSNR CHARG.
  LOOP AT IT_LOT.
    READ TABLE IT_MIC1 WITH KEY VBELN = IT_LOT-VBELN POSNR = IT_LOT-POSNR CHARG = IT
    IF SY-SUBRC EQ 0.
      LOOP AT IT_MIC1 WHERE VBELN = IT_LOT-VBELN AND POSNR = IT_LOT-POSNR AND CHARG
        " Enhancement (user 18/07/2026): untuk MIC mapping JR (Conv/Base),
        " nilai = rata-rata sibling roll 1 mother roll (lihat GET_JR_AVG).
        DATA: LV_ISJR TYPE C, LV_JRVAL TYPE QAMR-MITTELWERT.
        DATA: LV_JRCNT TYPE I.
        CLEAR: LV_ISJR, LV_JRVAL, LV_JRCNT.
        PERFORM GET_JR_AVG USING IT_MIC1-VBELN
                IT_MIC1-INSLOT IT_MIC1-MIC
                        CHANGING LV_ISJR LV_JRVAL LV_JRCNT.
        IF LV_ISJR = 'X'.
          CLEAR: IT_MIC1-CMICMIT, IT_MIC1-MICMIT.
          IF LV_JRCNT > 0.
            PERFORM MICFMT USING IT_MIC1-MIC IT_LOT-WERKS
                    CHANGING GV_DEC GV_UOM.
            WRITE LV_JRVAL TO IT_MIC1-CMICMIT
                  EXPONENT 0 DECIMALS GV_DEC LEFT-JUSTIFIED.
            IT_MIC1-MICMIT = LV_JRVAL.
          ELSE.
            IT_MIC1-CMICMIT = '0'.
            IT_MIC1-MICMIT = 0.
          ENDIF.
        ELSE.
          SELECT SINGLE CODE1 VORGLFNR INTO (IT_MIC1-CMICMIT, IT_MIC1-VORGLFNR)
            FROM QAMR
            WHERE QAMR~PRUEFLOS = IT_MIC1-INSLOT
            AND QAMR~MERKNR = IT_MIC1-MERKNR.
          IF IT_MIC1-CMICMIT IS INITIAL.
            " Ambil nilai single result (cycle) terakhir dari QASE untuk MVTR/OTR
            IF IT_MIC1-MIC CS 'MVTR' OR
               IT_MIC1-MIC CS 'WVTR' OR
               IT_MIC1-MIC CS 'OTR' OR
               IT_MIC1-MIC CS 'O2TR'.
              " Enhancement (Baginda, 22/07/2026): rata-rata
              " last-cycle (DETAILERG) barrier value lintas
              " SEMUA inspection lot SR-Converting di DO ini
              " (per JR batch), bukan 1 lot & 1 cycle acak
              " (bug lama: sort by PROBENR).
              DATA: LV_BARVAL TYPE QAMR-MITTELWERT.
              DATA: LV_BARCNT TYPE I.
              CLEAR: LV_BARVAL, LV_BARCNT.
              PERFORM GET_BAR_AVG USING IT_MIC1-VBELN
                      IT_MIC1-MIC
                      CHANGING LV_BARVAL LV_BARCNT.
              IF LV_BARCNT > 0.
                PERFORM MICFMT USING IT_MIC1-MIC IT_LOT-WERKS
                        CHANGING GV_DEC GV_UOM.
                WRITE LV_BARVAL TO IT_MIC1-CMICMIT
                      EXPONENT 0 DECIMALS GV_DEC LEFT-JUSTIFIED.
                IT_MIC1-MICMIT = LV_BARVAL.
                IT_MIC1-MESSWERT = LV_BARVAL.
              ENDIF.
            ENDIF.
            " Fallback ke rata-rata (MITTELWERT) jika bukan MVTR/OTR atau nilai koso
            IF IT_MIC1-CMICMIT IS INITIAL.
              DATA: LV_MITTEL TYPE QAMR-MITTELWERT.
              CLEAR LV_MITTEL.
              DATA: V_LINE_L  TYPE C LENGTH 20,
                    V_CODE_L  TYPE C LENGTH 20,
                    V_MOYE_L  TYPE C LENGTH 20,
                    V_SEQ_L   TYPE C LENGTH 20,
                    V_DUMMY_L TYPE C LENGTH 50,
                    L_MROLL_L TYPE C LENGTH 50.
              SPLIT IT_LOT-NOMSR AT SPACE INTO V_LINE_L V_CODE_L V_MOYE_L V_SEQ_L V_
              CONCATENATE V_LINE_L V_CODE_L V_MOYE_L V_SEQ_L INTO L_MROLL_L SEPARATE
              " Cek cache rata-rata SR
              READ TABLE GT_LOT_AVG INTO GS_LOT_AVG
                   WITH KEY INSLOT = IT_MIC1-INSLOT
                            MERKNR = IT_MIC1-MERKNR.
              IF SY-SUBRC = 0.
                LV_MITTEL = GS_LOT_AVG-MITTELWERT.
                IT_MIC1-VORGLFNR = '0001'. " dummy
              ELSE.
                SELECT SINGLE MITTELWERT VORGLFNR
                  INTO (LV_MITTEL, IT_MIC1-VORGLFNR)
                  FROM QAMR
                  WHERE QAMR~PRUEFLOS = IT_MIC1-INSLOT
                  AND QAMR~MERKNR = IT_MIC1-MERKNR.
              ENDIF.
              IF LV_MITTEL IS NOT INITIAL.
                PERFORM MICFMT USING IT_MIC1-MIC IT_LOT-WERKS
                        CHANGING GV_DEC GV_UOM.
                WRITE LV_MITTEL TO IT_MIC1-CMICMIT EXPONENT 0 DECIMALS GV_DEC LEFT-J
                IT_MIC1-MICMIT = LV_MITTEL.
              ENDIF.
            ENDIF.
            IF IT_MIC1-CMICMIT IS INITIAL.
              DATA: LV_ANZWERTG TYPE QAMR-ANZWERTG.
              CLEAR LV_ANZWERTG.
              READ TABLE GT_LOT_AVG INTO GS_LOT_AVG WITH KEY INSLOT = IT_MIC1-INSLOT
              IF SY-SUBRC = 0.
                IT_MIC1-MICMIT = GS_LOT_AVG-MITTELWERT.
                LV_ANZWERTG = GS_LOT_AVG-ANZWERTG.
              ELSE.
                SELECT SINGLE MITTELWERT ANZWERTG INTO (IT_MIC1-MICMIT, LV_ANZWERTG)
                  FROM QAMR
                  WHERE QAMR~PRUEFLOS = IT_MIC1-INSLOT
                  AND QAMR~MERKNR = IT_MIC1-MERKNR.
              ENDIF.
              IF SY-SUBRC = 0 AND LV_ANZWERTG > 0.
                PERFORM MICFMT USING IT_MIC1-MIC IT_LOT-WERKS
                        CHANGING GV_DEC GV_UOM.
                WRITE IT_MIC1-MICMIT TO IT_MIC1-CMICMIT EXPONENT 0 DECIMALS GV_DEC L
              ELSE.
                IT_MIC1-CMICMIT = '0'.
                IT_MIC1-MICMIT = 0.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
        CLEAR IT_MIC1-METHOD.
        IF LV_KUNNR IS NOT INITIAL.
          SELECT SINGLE METHOD
            INTO IT_MIC1-METHOD
            FROM ZMAP_COA
            WHERE MATNR = IT_LOT-MATNR
              AND MIC   = IT_MIC1-MIC
              AND KUNNR = LV_KUNNR
              AND DELETION NE 'X'.
        ENDIF.
        IF IT_MIC1-METHOD IS INITIAL.
          SELECT SINGLE METHOD
            INTO IT_MIC1-METHOD
            FROM ZMAP_COA
            WHERE MATNR = IT_LOT-MATNR
              AND MIC   = IT_MIC1-MIC
              AND KUNNR = ' '
              AND DELETION NE 'X'.
        ENDIF.
        PERFORM MICFMT USING IT_MIC1-MIC IT_LOT-WERKS
                CHANGING GV_DEC GV_UOM.
        IT_MIC1-UOM = GV_UOM.
        " Simpan hasil final agar ZQM003 memakai nilai yg sama dgn ZQM002.
        MODIFY IT_MIC1.
        MOVE-CORRESPONDING IT_MIC1 TO WA_DATA.
        " Format FLTP tolerance directly without packed decimals to avoid ,. issue
        WRITE IT_MIC1-MICMIN TO WA_DATA-MICMIN EXPONENT 0 DECIMALS GV_DEC LEFT-JUSTI
        WRITE IT_MIC1-MICMAX TO WA_DATA-MICMAX EXPONENT 0 DECIMALS GV_DEC LEFT-JUSTI
        WA_DATA-RAW_MICMIN = IT_MIC1-MICMIN.
        WA_DATA-RAW_MICMAX = IT_MIC1-MICMAX.
        APPEND WA_DATA TO IT_DATA.
      ENDLOOP.
    ELSE.
      APPEND IT_LOT TO IT_DATA.
    ENDIF.
  ENDLOOP.
  IT_LOOP[] = IT_DATA[].
  DELETE ADJACENT DUPLICATES FROM IT_LOOP COMPARING CHARG.
  LOOP AT IT_LOOP.
    IT_LOOP-CMICMIT = '0'.
    MODIFY IT_LOOP.
  ENDLOOP.
  DELETE IT_DATA WHERE MIC IS INITIAL.
  " Enhancement: Aggregate/Average MIC results for identical Material
  " Fix: Deduplicate by MICMIT to ensure we average unique JR values, not weighted b
  DATA: IT_DATA_UNIQUE LIKE IT_DATA OCCURS 0 WITH HEADER LINE.
  IT_DATA_UNIQUE[] = IT_DATA[].
  SORT IT_DATA_UNIQUE BY VBELN MATNR MIC MICMIT.
  DELETE ADJACENT DUPLICATES FROM IT_DATA_UNIQUE COMPARING VBELN MATNR MIC MICMIT.
  DATA: IT_DATA_AVG LIKE IT_DATA OCCURS 0 WITH HEADER LINE,
        LV_SUM TYPE QAMR-MITTELWERT,
        LV_COUNT TYPE I.
  SORT IT_DATA_UNIQUE BY VBELN MATNR MIC.
  LOOP AT IT_DATA_UNIQUE.
    IF IT_DATA_AVG IS INITIAL.
      IT_DATA_AVG = IT_DATA_UNIQUE.
      IF IT_DATA_UNIQUE-CMICMIT = '0'.
        LV_SUM = 0.
        LV_COUNT = 0.
      ELSE.
        LV_SUM = IT_DATA_UNIQUE-MICMIT.
        LV_COUNT = 1.
      ENDIF.
    ELSEIF IT_DATA_AVG-VBELN = IT_DATA_UNIQUE-VBELN AND
           IT_DATA_AVG-MATNR = IT_DATA_UNIQUE-MATNR AND
           IT_DATA_AVG-MIC   = IT_DATA_UNIQUE-MIC.
      IF IT_DATA_UNIQUE-CMICMIT <> '0'.
        LV_SUM = LV_SUM + IT_DATA_UNIQUE-MICMIT.
        LV_COUNT = LV_COUNT + 1.
        IF IT_DATA_AVG-CMICMIT = '0'.
          IT_DATA_AVG-CMICMIT = IT_DATA_UNIQUE-CMICMIT.
        ENDIF.
      ENDIF.
    ELSE.
      IF LV_COUNT > 0.
        IT_DATA_AVG-MICMIT = LV_SUM / LV_COUNT.
        " Jika data bersifat kuantitatif (ada sum), ubah format text CMICMIT ke hasi
        IF LV_COUNT > 1 AND LV_SUM <> 0.
          PERFORM MICFMT USING IT_DATA_AVG-MIC IT_DATA_AVG-WERKS
                  CHANGING GV_DEC GV_UOM.
          WRITE IT_DATA_AVG-MICMIT TO IT_DATA_AVG-CMICMIT EXPONENT 0 DECIMALS GV_DEC
        ENDIF.
      ELSE.
        IT_DATA_AVG-CMICMIT = '0'.
        IT_DATA_AVG-MICMIT = 0.
      ENDIF.
      APPEND IT_DATA_AVG.
      IT_DATA_AVG = IT_DATA_UNIQUE.
      IF IT_DATA_UNIQUE-CMICMIT = '0'.
        LV_SUM = 0.
        LV_COUNT = 0.
      ELSE.
        LV_SUM = IT_DATA_UNIQUE-MICMIT.
        LV_COUNT = 1.
      ENDIF.
    ENDIF.
  ENDLOOP.
  IF IT_DATA_AVG IS NOT INITIAL.
    IF LV_COUNT > 0.
      IT_DATA_AVG-MICMIT = LV_SUM / LV_COUNT.
      IF LV_COUNT > 1 AND LV_SUM <> 0.
        PERFORM MICFMT USING IT_DATA_AVG-MIC IT_DATA_AVG-WERKS
                CHANGING GV_DEC GV_UOM.
        WRITE IT_DATA_AVG-MICMIT TO IT_DATA_AVG-CMICMIT EXPONENT 0 DECIMALS GV_DEC L
      ENDIF.
    ELSE.
      IT_DATA_AVG-CMICMIT = '0'.
      IT_DATA_AVG-MICMIT = 0.
    ENDIF.
    APPEND IT_DATA_AVG.
  ENDIF.
  IT_DATA[] = IT_DATA_AVG[].
  LOOP AT IT_DATA.
    IF IT_DATA-CMICMIT IS INITIAL OR IT_DATA-CMICMIT EQ '-' OR IT_DATA-CMICMIT EQ '
      IT_DATA-CMICMIT = '0'.
    ENDIF.
    " Format penanda 0 sesuai decimal MIC untuk tampilan ZQM002.
    IF IT_DATA-CMICMIT = '0'.
      PERFORM MICFMT USING IT_DATA-MIC IT_DATA-WERKS
              CHANGING GV_DEC GV_UOM.
      WRITE IT_DATA-MICMIT TO IT_DATA-CMICMIT
        EXPONENT 0 DECIMALS GV_DEC LEFT-JUSTIFIED.
    ENDIF.
    IT_DATA-CHK = ''.
    IT_DATA-NUMMIC = 2.
    READ TABLE IT_ZMAP WITH KEY MIC = IT_DATA-MIC BINARY SEARCH.
    IF SY-SUBRC EQ 0.
      IT_DATA-CHK = 'X'.
      IT_DATA-NUMMIC = 1.
      IT_DATA-NUM = IT_ZMAP-NUM.
    ENDIF.
    " --- BEGIN ZLOG_COA CHECK ---
    DATA: WA_ZLOG TYPE ZLOG_COA,
          LV_KUNNR_LOG TYPE KUNNR.
    CLEAR LV_KUNNR_LOG.
    SELECT SINGLE KUNAG INTO LV_KUNNR_LOG FROM LIKP WHERE VBELN = IT_DATA-VBELN.
    CLEAR WA_ZLOG.
    SELECT SINGLE VALUE1 VALUE2 INTO (WA_ZLOG-VALUE1, WA_ZLOG-VALUE2) FROM ZLOG_COA
      WHERE PRUEFLOS = IT_DATA-INSLOT
        AND MIC = IT_DATA-MIC
        AND KUNNR = LV_KUNNR_LOG
        AND DELETION <> 'X'.
    IF SY-SUBRC = 0.
      " If there is data in ZLOG_COA, override CMICMIT (Preview)
      IF WA_ZLOG-VALUE2 IS NOT INITIAL.
        IT_DATA-CMICMIT = WA_ZLOG-VALUE2.
      ELSEIF WA_ZLOG-VALUE1 IS NOT INITIAL.
        PERFORM MICFMT USING IT_DATA-MIC IT_DATA-WERKS
                CHANGING GV_DEC GV_UOM.
        WRITE WA_ZLOG-VALUE1 TO IT_DATA-CMICMIT EXPONENT 0 DECIMALS GV_DEC LEFT-JUST
        IT_DATA-MICMIT = WA_ZLOG-VALUE1.
      ENDIF.
    ENDIF.
    " --- END ZLOG_COA CHECK ---
    " Backup original aggregated QM value
    IT_DATA-ORIG_CMICMIT = IT_DATA-CMICMIT.
    " Menyimpan status tersimpan saat ini untuk keperluan validasi sebelum EXEC
    IT_DATA-SAVED_CMICMIT = IT_DATA-CMICMIT.
    MODIFY IT_DATA.
  ENDLOOP.
  SORT IT_DATA BY VBELN CHK DESCENDING.
ENDFORM.                    "get_data
*&---------------------------------------------------------------------*
*&      Form  GET_MIC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_MIC .
  DATA : INS  LIKE QALS-PRUEFLOS,
         CTR TYPE I.
  CLEAR IT_MIC. REFRESH IT_MIC.
  CLEAR IT_MIC2. REFRESH IT_MIC2.
  " Rata-rata SR Conv lintas SEMUA sibling
  " se-JR (fix): kumpulkan semua lot,
  " skip ANZWERTG=0, bagi jumlah non-empty.
  IF LOT_SR_CONV IS NOT INITIAL.
    DATA: LV_C0 TYPE CHARG_D.
    DATA: LV_SR0 TYPE CHARG_D.
    DATA: LV_JRC TYPE CHARG_D.
    DATA: LV_NEWB TYPE CHARG_D.
    DATA: LV_TLOT TYPE QALS-PRUEFLOS.
    DATA: LT_SRX TYPE TABLE OF ZQM_GET_BATCH_SR
            WITH HEADER LINE.
    DATA: BEGIN OF LT_SRLOTS OCCURS 0,
            LOT TYPE QALS-PRUEFLOS,
          END OF LT_SRLOTS.
    DATA: LT_QALL TYPE TABLE OF QAMR
            WITH HEADER LINE.
    DATA: LT_QU TYPE TABLE OF QAMR
            WITH HEADER LINE.
    DATA: L_ASUM TYPE QAMR-MITTELWERT.
    DATA: L_ACNT TYPE I.
    REFRESH: LT_SRX, LT_SRLOTS, LT_QALL, LT_QU.
    CLEAR LV_C0.
    SELECT SINGLE CHARG INTO LV_C0 FROM QALS
      WHERE PRUEFLOS = LOT_SR_CONV.
    PERFORM GET_ORIGINAL_BATCH USING LV_C0
                               CHANGING LV_SR0.
    CLEAR LV_JRC.
    CALL FUNCTION 'ZQM_GET_BATCH_JR_BY_SR'
      EXPORTING
        CHARG_S = LV_SR0
      IMPORTING
        CHARG_J = LV_JRC.
    IF LV_JRC IS NOT INITIAL.
      CALL FUNCTION 'ZQM_GET_BATCH_SR_BY_JR'
        EXPORTING
          CHARGJR = LV_JRC
        TABLES
          T_SR    = LT_SRX.
      LOOP AT LT_SRX.
        PERFORM GET_NEWEST_BATCH
          USING LT_SRX-CHARG CHANGING LV_NEWB.
        CLEAR LV_TLOT.
        SELECT SINGLE PRUEFLOS INTO LV_TLOT
          FROM QALS WHERE CHARG = LV_NEWB
            AND ART = 'Z04'.
        IF LV_TLOT IS NOT INITIAL.
          LT_SRLOTS-LOT = LV_TLOT.
          COLLECT LT_SRLOTS.
        ENDIF.
      ENDLOOP.
    ENDIF.
    LT_SRLOTS-LOT = LOT_SR_CONV.
    COLLECT LT_SRLOTS.
    IF LOT_SR_CONV2 IS NOT INITIAL.
      LT_SRLOTS-LOT = LOT_SR_CONV2.
      COLLECT LT_SRLOTS.
    ENDIF.
    LOOP AT LT_SRLOTS.
      SELECT * APPENDING TABLE LT_QALL FROM QAMR
        WHERE PRUEFLOS = LT_SRLOTS-LOT.
    ENDLOOP.
    LT_QU[] = LT_QALL[].
    SORT LT_QU BY MERKNR.
    DELETE ADJACENT DUPLICATES FROM LT_QU
      COMPARING MERKNR.
    LOOP AT LT_QU.
      CLEAR: L_ASUM, L_ACNT.
      LOOP AT LT_QALL WHERE MERKNR = LT_QU-MERKNR
        AND ANZWERTG > 0.
        L_ASUM = L_ASUM + LT_QALL-MITTELWERT.
        L_ACNT = L_ACNT + 1.
      ENDLOOP.
      IF L_ACNT > 0.
        CLEAR GS_LOT_AVG.
        GS_LOT_AVG-INSLOT = LOT_SR_CONV.
        GS_LOT_AVG-MERKNR = LT_QU-MERKNR.
        GS_LOT_AVG-MITTELWERT = L_ASUM / L_ACNT.
        GS_LOT_AVG-ANZWERTG = 1.
        APPEND GS_LOT_AVG TO GT_LOT_AVG.
      ENDIF.
    ENDLOOP.
  ENDIF.
  LOOP AT IT_ZMAP.
    CLEAR INS.
    " Tentukan sumber Inspection Lot berdasarkan MAPPING
    IF IT_ZMAP-MAPPING CS 'SR Base Film'.
      INS = LOT_SR_BASE.
    ELSEIF IT_ZMAP-MAPPING CS 'JR Base Film'.
      INS = LOT_JR_BASE.
    ELSEIF IT_ZMAP-MAPPING CS 'SR Converting'.
      INS = LOT_SR_CONV.
    ELSEIF IT_ZMAP-MAPPING CS 'JR Converting'.
      INS = LOT_JR_CONV.
    ELSE.
      " Default fallback jika kosong, mungkin ambil dari SR Convert/Base
      INS = LOT_SR_CONV.
    ENDIF.
    IF INS IS NOT INITIAL.
      SELECT SINGLE VERWMERKM KURZTEXT TOLERANZUN TOLERANZOB MERKNR STELLEN
        INTO (IT_MIC-MIC,IT_MIC-MICDES,IT_MIC-MICMIN,IT_MIC-MICMAX,IT_MIC-MERKNR,IT_
        FROM QAMV
        WHERE PRUEFLOS = INS
          AND VERWMERKM = IT_ZMAP-MIC.
      IF SY-SUBRC EQ 0.
        PERFORM COPY.
        IT_MIC-SEQ = 1.
        IT_MIC-INSLOT = INS.
        APPEND IT_MIC TO IT_MIC2.
      ELSE.
        " Pengecualian untuk MVTR/OTR Barrier yang MIC-nya bisa berbeda (seperti WVT
        IF IT_ZMAP-MIC CS 'MVTR' OR IT_ZMAP-MIC CS 'OTR'.
          SELECT VERWMERKM KURZTEXT TOLERANZUN TOLERANZOB MERKNR STELLEN
            INTO (IT_MIC-MIC,IT_MIC-MICDES,IT_MIC-MICMIN,IT_MIC-MICMAX,IT_MIC-MERKNR
            FROM QAMV
            WHERE PRUEFLOS = INS.
            IF IT_MIC-MIC CS 'MVTR' OR IT_MIC-MIC CS 'WVTR' OR
               IT_MIC-MIC CS 'OTR'  OR IT_MIC-MIC CS 'O2TR'.
              IF IT_MIC-MIC CS IT_ZMAP-MIC OR IT_ZMAP-MIC CS IT_MIC-MIC OR
                 ( IT_ZMAP-MIC CS 'MVTR' AND IT_MIC-MIC CS 'WVTR' ) OR
                 ( IT_ZMAP-MIC CS 'OTR' AND IT_MIC-MIC CS 'O2TR' ).
                PERFORM COPY.
                IT_MIC-SEQ = 5.
                IT_MIC-INSLOT = INS.
                IF IT_MIC-MIC CS 'MVTR' OR
                   IT_MIC-MIC CS 'WVTR'.
                  IT_MIC-BARRIER_TYPE = 'MVTR'.
                ELSEIF IT_MIC-MIC CS 'OTR' OR
                       IT_MIC-MIC CS 'O2TR'.
                  IT_MIC-BARRIER_TYPE = 'OTR'.
                ELSE.
                  IT_MIC-BARRIER_TYPE = 'X'.
                ENDIF.
                IT_MIC-MIC = IT_ZMAP-MIC. " Timpa agar sesuai dengan Mapping
                APPEND IT_MIC TO IT_MIC2.
              ENDIF.
            ENDIF.
          ENDSELECT.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.
  " Pastikan semua MIC dari ZMAP_COA tetap masuk ke list meskipun tidak ada di Inspe
  SORT IT_MIC2 BY MIC.
  LOOP AT IT_ZMAP.
    READ TABLE IT_MIC2 WITH KEY MIC = IT_ZMAP-MIC BINARY SEARCH.
    IF SY-SUBRC <> 0.
      CLEAR IT_MIC.
      PERFORM COPY. " Fix: isi VBELN/POSNR/CHARG/MATNR dst agar match balik di GET_D
      IT_MIC-MIC = IT_ZMAP-MIC.
      IT_MIC-METHOD = IT_ZMAP-METHOD.
      SELECT SINGLE KURZTEXT INTO IT_MIC-MICDES FROM QPMT WHERE MKMNR = IT_ZMAP-MIC
      IF SY-SUBRC <> 0.
        IT_MIC-MICDES = IT_ZMAP-MIC.
      ENDIF.
      SELECT SINGLE MASSEINHSW INTO IT_MIC-UOM FROM QPMK WHERE MKMNR = IT_ZMAP-MIC.
      IT_MIC-SEQ = 99. " Penanda tidak ada di Inspection Lot
      IT_MIC-INSLOT = ''.
      APPEND IT_MIC TO IT_MIC2.
    ENDIF.
  ENDLOOP.
  SORT IT_MIC2 BY MIC ASCENDING.
  DELETE ADJACENT DUPLICATES FROM IT_MIC2 COMPARING MIC.
  CLEAR CTR.
  CTR = LINES( IT_MIC2 ).
  IF CTR NE 0.
    APPEND LINES OF IT_MIC2 FROM 1 TO CTR TO IT_MIC1.
  ENDIF.
  CLEAR IT_MIC2. REFRESH IT_MIC2.
ENDFORM.                    " GET_MIC
*&---------------------------------------------------------------------*
*&      Form  COPY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM COPY .
  IT_MIC-VBELN = IT_DATA-VBELN.
  IT_MIC-POSNR = IT_DATA-POSNR.
  IT_MIC-CHARG = IT_DATA-CHARG.
  IT_MIC-NOMSR = IT_DATA-NOMSR.
  IT_MIC-ZZTYPE = IT_DATA-ZZTYPE.
  IT_MIC-MATNR = IT_DATA-MATNR.
  IT_MIC-UECHA = IT_DATA-UECHA.
  IT_MIC-WERKS = IT_DATA-WERKS.
ENDFORM.                    " COPY
*&---------------------------------------------------------------------*
*&      Form  DOWNLOAD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DOWNLOAD .
  TABLES RLGRAP.
  DATA:  DEF_PATH LIKE RLGRAP-FILENAME.
  DATA: TMP_FILENAME LIKE RLGRAP-FILENAME.
  DATA V_FILENAME TYPE STRING.
  DATA : BEGIN OF IT_FIELDNAMES OCCURS 0,
           FIELD(30),
         END OF IT_FIELDNAMES.
  REFRESH IT_FIELDNAMES.
  CLEAR IT_FIELDNAMES.
  IT_FIELDNAMES-FIELD = 'Nomor ODO'.
  APPEND IT_FIELDNAMES.
  IT_FIELDNAMES-FIELD = 'Item'.
  APPEND IT_FIELDNAMES.
  IT_FIELDNAMES-FIELD = 'Batch'.
  APPEND IT_FIELDNAMES.
  IT_FIELDNAMES-FIELD = 'Nomor SR'.
  APPEND IT_FIELDNAMES.
  IT_FIELDNAMES-FIELD = 'Material'.
  APPEND IT_FIELDNAMES.
  IT_FIELDNAMES-FIELD = 'MIC'.
  APPEND IT_FIELDNAMES.
  IT_FIELDNAMES-FIELD = 'MIC Description'.
  APPEND IT_FIELDNAMES.
  IT_FIELDNAMES-FIELD = 'Unit Of Measure'.
  APPEND IT_FIELDNAMES.
  IT_FIELDNAMES-FIELD = 'Testing Method '.
  APPEND IT_FIELDNAMES.
  IT_FIELDNAMES-FIELD = 'Lower Limit'.
  APPEND IT_FIELDNAMES.
  IT_FIELDNAMES-FIELD = 'Upper Limit'.
  APPEND IT_FIELDNAMES.
  IT_FIELDNAMES-FIELD = 'Value'.
  APPEND IT_FIELDNAMES.
  CLEAR: IT_EXPORT.
  REFRESH:IT_EXPORT.
  LOOP AT IT_DATA WHERE CHK EQ 'X'.
    CLEAR IT_EXPORT.
    IT_EXPORT-VBELN = IT_DATA-VBELN.
    IT_EXPORT-UECHA = IT_DATA-UECHA.
    IT_EXPORT-CHARG = IT_DATA-CHARG.
    IT_EXPORT-NOMSR = IT_DATA-NOMSR.
    IT_EXPORT-MATNR = IT_DATA-MATNR.
    IT_EXPORT-MIC = IT_DATA-MIC.
    IT_EXPORT-MICDES = IT_DATA-MICDES.
    IT_EXPORT-UOM = IT_DATA-UOM.
    IT_EXPORT-METHOD = IT_DATA-METHOD.
    IT_EXPORT-MICMIN = IT_DATA-MICMIN.
    IT_EXPORT-MICMAX = IT_DATA-MICMAX.
    IT_EXPORT-CMICMIT = IT_DATA-CMICMIT.
*    IT_EXPORT-CHK = IT_DATA-CHK.
    APPEND IT_EXPORT.
  ENDLOOP.
  CALL FUNCTION 'WS_FILENAME_GET'
    EXPORTING
      DEF_FILENAME     = RLGRAP-FILENAME
      DEF_PATH         = DEF_PATH
      MASK             = ',*.xls.'
      MODE             = 'S'
      TITLE            = TEXT-011
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
  CONCATENATE RLGRAP-FILENAME '.XLS' INTO V_FILENAME.
*  V_FILENAME = RLGRAP-FILENAME.
  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      FILENAME              = V_FILENAME
      FILETYPE              = 'ASC'
      WRITE_FIELD_SEPARATOR = 'X'
      CONFIRM_OVERWRITE     = 'X'
      SHOW_TRANSFER_STATUS  = 'X'
    TABLES
      DATA_TAB              = IT_EXPORT
      FIELDNAMES            = IT_FIELDNAMES.
  IF SY-SUBRC <> 0.
    MESSAGE I000(0K) WITH 'Download error'.
    STOP.
  ENDIF.
ENDFORM.                    " DOWNLOAD
*&---------------------------------------------------------------------*
*&      Form  SELALL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SELALL .
  LOOP AT IT_DATA WHERE CHK NE 'X'.
    IT_DATA-CHK = 'X'.
    MODIFY IT_DATA.
  ENDLOOP.
ENDFORM.                    " SELALL
*&---------------------------------------------------------------------*
*&      Form  DESALL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DESALL .
  LOOP AT IT_DATA WHERE CHK EQ 'X'.
    IT_DATA-CHK = ''.
    MODIFY IT_DATA.
  ENDLOOP.
ENDFORM.                    " DESALL
*&---------------------------------------------------------------------*
*&      Form  DOWNLOAD_DETAIL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM DOWNLOAD_DETAIL .
*  TABLES RLGRAP.
  DATA:  DEF_PATH LIKE RLGRAP-FILENAME.
  DATA: TMP_FILENAME LIKE RLGRAP-FILENAME.
  DATA V_FILENAME TYPE STRING.
  DATA : BEGIN OF IT_FIELDNAMES OCCURS 0,
           FIELD(30),
         END OF IT_FIELDNAMES.
  REFRESH IT_FIELDNAMES.
  CLEAR IT_FIELDNAMES.
  IT_FIELDNAMES-FIELD = 'Properties'.
  APPEND IT_FIELDNAMES.
  IT_FIELDNAMES-FIELD = 'Unit of Measure'.
  APPEND IT_FIELDNAMES.
  IT_FIELDNAMES-FIELD = 'Testing Method'.
  APPEND IT_FIELDNAMES.
  IT_FIELDNAMES-FIELD = 'Lower Limit'.
  APPEND IT_FIELDNAMES.
  IT_FIELDNAMES-FIELD = 'Upper Limit'.
  APPEND IT_FIELDNAMES.
  IT_FIELDNAMES-FIELD = 'Value'.
  APPEND IT_FIELDNAMES.
  REFRESH IT_DETAILD.
  LOOP AT IT_DETAIL WHERE CHK = 'X'.
    MOVE-CORRESPONDING IT_DETAIL TO IT_DETAILD.
    APPEND IT_DETAILD.
  ENDLOOP.
  CALL FUNCTION 'WS_FILENAME_GET'
    EXPORTING
      DEF_FILENAME     = RLGRAP-FILENAME
      DEF_PATH         = DEF_PATH
      MASK             = ',*.xls.'
      MODE             = 'S'
      TITLE            = TEXT-011
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
  CONCATENATE RLGRAP-FILENAME '.XLS' INTO V_FILENAME.
  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      FILENAME              = V_FILENAME
      FILETYPE              = 'ASC'
      WRITE_FIELD_SEPARATOR = 'X'
      CONFIRM_OVERWRITE     = 'X'
      SHOW_TRANSFER_STATUS  = 'X'
    TABLES
      DATA_TAB              = IT_DETAILD
      FIELDNAMES            = IT_FIELDNAMES.
  IF SY-SUBRC <> 0.
    MESSAGE I000(0K) WITH 'Download error'.
    STOP.
  ENDIF.
ENDFORM.                    " DOWNLOAD_DETAIL
*&---------------------------------------------------------------------*
*&      Form  SELMAPPING
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM SELMAPPING .
  LOOP AT IT_DATA.
    IT_DATA-CHK = ''.
    READ TABLE IT_ZMAP WITH KEY MIC = IT_DATA-MIC BINARY SEARCH.
    IF SY-SUBRC EQ 0.
      IT_DATA-CHK = 'X'.
    ENDIF.
    MODIFY IT_DATA.
  ENDLOOP.
  SORT IT_DATA BY VBELN CHK DESCENDING.
ENDFORM.                    " SELMAPPING
*&---------------------------------------------------------------------*
*&      Form  F_PRINT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_PRINT .
  DATA: I_NAST        LIKE NAST,
        I_SSFCOMPOP   TYPE SSFCOMPOP,
        I_SSFCTRLOP   TYPE SSFCTRLOP,
        I_RECIPIENT   TYPE SWOTOBJID,
        I_SENDER      TYPE SWOTOBJID,
        I_ADDR_KEY    LIKE ADDR_KEY,
        IT_QAMV       TYPE QAMV OCCURS 0 WITH HEADER LINE,
        LV_VALUE10(10) TYPE C,
        QUANTITY      TYPE CHAR12,
        LV_BATCH_FM   TYPE RS38L_FNAM.
  PERFORM GET_COMPANY_NAME.
  WRITE NTGEW TO QUANTITY DECIMALS 2.
  CONDENSE QUANTITY.
  LOOP AT IT_DETAIL WHERE CHK EQ 'X'.
    IT_QAMV-KURZTEXT   = IT_DETAIL-MICDES.
    IT_QAMV-STEUERKZ   = IT_DETAIL-UOM.
    IT_QAMV-DUMMY40    = IT_DETAIL-METHOD.
    IT_QAMV-TOLERANZOB = IT_DETAIL-MICMIN.
    IT_QAMV-TOLERANZUN = IT_DETAIL-MICMAX.
    CLEAR LV_VALUE10.
    WRITE IT_DETAIL-CMICMIT TO LV_VALUE10 CENTERED.
    IT_QAMV-DUMMY20 = LV_VALUE10.
    APPEND IT_QAMV.
  ENDLOOP.
  DATA: LT_ROLL_LOT LIKE IT_LOT OCCURS 0 WITH HEADER LINE,
        IT_ROLL     TYPE TABLE OF ZQMSAP WITH HEADER LINE,
        BEGIN OF LT_LIPS OCCURS 0,
          VBELN LIKE LIPS-VBELN,
          POSNR LIKE LIPS-POSNR,
          CHARG LIKE LIPS-CHARG,
          NTGEW LIKE LIPS-NTGEW,
        END OF LT_LIPS.
  LT_ROLL_LOT[] = IT_LOT[].
  SORT LT_ROLL_LOT BY VBELN POSNR CHARG.
  DELETE ADJACENT DUPLICATES FROM LT_ROLL_LOT
    COMPARING VBELN POSNR CHARG.
  DATA: LV_VBELN_PAD TYPE LIPS-VBELN.
  IF VBELN IS NOT INITIAL.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        INPUT  = VBELN
      IMPORTING
        OUTPUT = LV_VBELN_PAD.
  ENDIF.
  REFRESH LT_LIPS.
  IF LV_VBELN_PAD IS NOT INITIAL.
    SELECT VBELN POSNR CHARG NTGEW
      INTO TABLE LT_LIPS
      FROM LIPS
      WHERE VBELN = LV_VBELN_PAD.
    SORT LT_LIPS BY CHARG.
  ENDIF.
  REFRESH IT_ROLL.
  LOOP AT LT_ROLL_LOT.
    CLEAR IT_ROLL.
    IT_ROLL-ZZNOMORROLL = LT_ROLL_LOT-NOMSR.
    IT_ROLL-ZZWIDTH     = LT_ROLL_LOT-ZZWIDTH.
    IT_ROLL-ZZLENGTH    = LT_ROLL_LOT-ZZLENGTH.
    READ TABLE LT_LIPS WITH KEY
      CHARG = LT_ROLL_LOT-CHARG
      BINARY SEARCH.
    IF SY-SUBRC = 0.
      IT_ROLL-PVALUE = LT_LIPS-NTGEW.
      WRITE LT_LIPS-NTGEW TO IT_ROLL-CVALUE DECIMALS 2.
      CONDENSE IT_ROLL-CVALUE.
    ENDIF.
    APPEND IT_ROLL.
  ENDLOOP.
  SORT IT_ROLL BY ZZNOMORROLL ZZWIDTH ZZLENGTH PVALUE.
  DELETE ADJACENT DUPLICATES FROM IT_ROLL
    COMPARING ZZNOMORROLL ZZWIDTH ZZLENGTH PVALUE.
  " Prepare dynamic roll columns and orientation based on ZQM_COA_CUST_COL
  PERFORM PREPARE_DYNAMIC_ROLL_COLUMNS USING VBELN.
  CLEAR I_SSFCTRLOP.
  I_SSFCTRLOP-NO_DIALOG = 'X'.
  I_SSFCTRLOP-PREVIEW   = 'X'.
  CLEAR I_SSFCOMPOP.
  I_SSFCOMPOP-TDNOPRINT = 'X'.
  I_SSFCOMPOP-TDDEST    = 'LOCL'.
  IF GV_TIER = 'LANDSCAPE'.
    " I_SSFCTRLOP-STARTPAGE = 'LPAGE'.
  ENDIF.
  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      FORMNAME           = 'ZQMF_COA'
    IMPORTING
      FM_NAME            = LF_FM_NAME
    EXCEPTIONS
      NO_FORM            = 1
      NO_FUNCTION_MODULE = 2
      OTHERS             = 3.
  IF SY-SUBRC <> 0 OR LF_FM_NAME IS INITIAL.
    MESSAGE 'Smartform ZQMF_COA belum aktif' TYPE 'E'.
    EXIT.
  ENDIF.
  CLEAR LV_BATCH_FM.
  IF GT_DYN_ROLL[] IS NOT INITIAL.
    CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
      EXPORTING
        FORMNAME           = 'ZQMF_COA_BATCH'
      IMPORTING
        FM_NAME            = LV_BATCH_FM
      EXCEPTIONS
        NO_FORM            = 1
        NO_FUNCTION_MODULE = 2
        OTHERS             = 3.
    IF SY-SUBRC <> 0 OR LV_BATCH_FM IS INITIAL.
      MESSAGE 'Smartform ZQMF_COA_BATCH belum aktif' TYPE 'E'.
      EXIT.
    ENDIF.
  ENDIF.
  CONDENSE NAME1.
  CONDENSE VBELN.
  CONDENSE PRODUCT.
  CONDENSE QUANTITY.
  CONDENSE WIDTH.
  CALL FUNCTION 'SSF_OPEN'
    EXPORTING
      CONTROL_PARAMETERS = I_SSFCTRLOP
      OUTPUT_OPTIONS     = I_SSFCOMPOP
      USER_SETTINGS      = ' '
    EXCEPTIONS
      FORMATTING_ERROR   = 1
      INTERNAL_ERROR     = 2
      SEND_ERROR         = 3
      USER_CANCELED      = 4
      OTHERS             = 5.
  IF SY-SUBRC <> 0.
    MESSAGE 'Gagal membuka Smart Forms print job' TYPE 'E'.
    EXIT.
  ENDIF.
  I_SSFCTRLOP-NO_OPEN  = 'X'.
  I_SSFCTRLOP-NO_CLOSE = 'X'.
  CALL FUNCTION LF_FM_NAME
    EXPORTING
      CONTROL_PARAMETERS = I_SSFCTRLOP
      OUTPUT_OPTIONS      = I_SSFCOMPOP
      USER_SETTINGS       = ' '
      CUSTOMER            = NAME1
      DELIVERY            = VBELN
      PRODUCT             = PRODUCT
      QUANTITY            = QUANTITY
      WIDTH               = WIDTH
      COMPANYTXT          = COMPANYTXT
      GS_DYN_HDR          = GS_DYN_HDR
    TABLES
      IT_QAMV             = IT_QAMV
      IT_ROLL             = IT_ROLL
      GT_DYN_ROLL         = GT_DYN_ROLL
    EXCEPTIONS
      FORMATTING_ERROR    = 1
      INTERNAL_ERROR      = 2
      SEND_ERROR          = 3
      USER_CANCELED       = 4
      OTHERS              = 5.
  IF SY-SUBRC <> 0.
    CALL FUNCTION 'SSF_CLOSE'.
    MESSAGE 'Gagal mencetak halaman utama COA' TYPE 'E'.
    EXIT.
  ENDIF.
  IF GT_DYN_ROLL[] IS NOT INITIAL.
    CALL FUNCTION LV_BATCH_FM
      EXPORTING
        CONTROL_PARAMETERS = I_SSFCTRLOP
        OUTPUT_OPTIONS      = I_SSFCOMPOP
        USER_SETTINGS       = ' '
        CUSTOMER            = NAME1
        DELIVERY            = VBELN
        PRODUCT             = PRODUCT
        QUANTITY            = QUANTITY
        WIDTH               = WIDTH
        COMPANYTXT          = COMPANYTXT
        GS_DYN_HDR          = GS_DYN_HDR
      TABLES
        IT_QAMV             = IT_QAMV
        IT_ROLL             = IT_ROLL
        GT_DYN_ROLL         = GT_DYN_ROLL
      EXCEPTIONS
        FORMATTING_ERROR    = 1
        INTERNAL_ERROR      = 2
        SEND_ERROR          = 3
        USER_CANCELED       = 4
        OTHERS              = 5.
    IF SY-SUBRC <> 0.
      CALL FUNCTION 'SSF_CLOSE'.
      MESSAGE 'Gagal mencetak lampiran Batch List' TYPE 'E'.
      EXIT.
    ENDIF.
  ENDIF.
  CALL FUNCTION 'SSF_CLOSE'
    EXCEPTIONS
      FORMATTING_ERROR = 1
      INTERNAL_ERROR   = 2
      SEND_ERROR       = 3
      OTHERS           = 4.
  IF SY-SUBRC <> 0.
    MESSAGE 'Gagal menutup Smart Forms print job' TYPE 'E'.
  ENDIF.
ENDFORM.                    " F_PRINT
*&---------------------------------------------------------------------*
*&      Form  GET_COMPANY_NAME
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM GET_COMPANY_NAME. "ADD NEW COMPANY 19/09/2018
  DATA:ZWERKS LIKE LIPS-WERKS,
       ZVBELN LIKE LIPS-VBELN.
  IF VBELN IS NOT INITIAL.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        INPUT  = VBELN
      IMPORTING
        OUTPUT = ZVBELN.
    SELECT SINGLE WERKS FROM LIPS INTO ZWERKS WHERE VBELN EQ ZVBELN.
  ELSE.
    MESSAGE 'Nomor ODO tidak ada!' TYPE 'I'.
    STOP.
  ENDIF.
  SELECT SINGLE T001~BUTXT FROM T001
    JOIN T001K ON T001~BUKRS EQ T001K~BUKRS INTO COMPANYTXT
    WHERE T001K~BWKEY EQ ZWERKS.
ENDFORM.                    "GET_COMPANY_NAME
*&---------------------------------------------------------------------*
*&      Form  GET_TRACED_LOTS
*&---------------------------------------------------------------------*
TYPES: BEGIN OF TY_TRACE_DATA,
         MOTHER_ROLL         TYPE C LENGTH 50,
         LOT_JR_CONV         TYPE QALS-PRUEFLOS,
         LOT_SR_BASE         TYPE QALS-PRUEFLOS,
         LOT_JR_BASE         TYPE QALS-PRUEFLOS,
         L_JR_CONV_BATCH     TYPE MCH1-CHARG,
         L_SR_BASE_BATCH     TYPE MCH1-CHARG,
         L_JR_BASE_BATCH     TYPE MCH1-CHARG,
         LOT_SR_CONV_SIBLING TYPE QALS-PRUEFLOS,
         LOT_SR_CONV_SIBLING2 TYPE QALS-PRUEFLOS,
       END OF TY_TRACE_DATA.
DATA: GT_TRACE_DATA TYPE TABLE OF TY_TRACE_DATA,
      GS_TRACE_DATA TYPE TY_TRACE_DATA.
*&---------------------------------------------------------------------*
*&      Form  GET_TRACED_LOTS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM GET_TRACED_LOTS.
  DATA: L_AUFNR LIKE AFPO-AUFNR,
        L_MBLNR LIKE MSEG-MBLNR,
        L_MATNR LIKE MSEG-MATNR,
        L_CHARG LIKE MSEG-CHARG,
        L_LICHA LIKE MCH1-LICHA,
        L_LEN TYPE I,
        L_TEMP TYPE I.
  DATA: L_JR_CONV_BATCH LIKE MCH1-CHARG,
        L_SR_BASE_BATCH LIKE MCH1-CHARG,
        L_JR_BASE_BATCH LIKE MCH1-CHARG,
        LT_SR TYPE TABLE OF ZQM_GET_BATCH_SR WITH HEADER LINE.
  DATA: V_LINE  TYPE C LENGTH 20,
        V_CODE  TYPE C LENGTH 20,
        V_MOYE  TYPE C LENGTH 20,
        V_SEQ   TYPE C LENGTH 20,
        V_DUMMY TYPE C LENGTH 50,
        L_MOTHER_ROLL TYPE C LENGTH 50.
  DATA: LV_SEARCH_SR TYPE CHARG_D,
        LV_LATEST_SR TYPE CHARG_D.
  DATA: LV_FALLBACK_AUFNR_1 LIKE MSEG-AUFNR,
        LV_FALLBACK_PARENT_1 LIKE MSEG-CHARG,
        LV_FALLBACK_AUFNR_2 LIKE MSEG-AUFNR,
        LV_FALLBACK_PARENT_2 LIKE MSEG-CHARG.
  CLEAR: LOT_SR_CONV, LOT_SR_CONV2, LOT_JR_CONV, LOT_SR_BASE, LOT_JR_BASE,
         L_JR_CONV_BATCH, L_SR_BASE_BATCH, L_JR_BASE_BATCH,
         GS_TRACE_DATA.
  " Edited by J. Budi (Antigravity) on 29.06.2026 - Inspection Lot Tracing via Sibli
  SPLIT IT_DATA-NOMSR AT SPACE INTO V_LINE V_CODE V_MOYE V_SEQ V_DUMMY.
  CONCATENATE V_LINE V_CODE V_MOYE V_SEQ INTO L_MOTHER_ROLL SEPARATED BY SPACE.
  " 1. SR Converting Lot
  SELECT SINGLE PRUEFLOS INTO LOT_SR_CONV FROM QALS WHERE CHARG = IT_DATA-CHARG AND
  " Fallback jika terkena Change Grade ZQM0016
  IF LOT_SR_CONV IS INITIAL.
    PERFORM GET_ORIGINAL_BATCH USING IT_DATA-CHARG CHANGING LV_SEARCH_SR.
    IF LV_SEARCH_SR NE IT_DATA-CHARG.
      SELECT SINGLE PRUEFLOS INTO LOT_SR_CONV FROM QALS WHERE CHARG = LV_SEARCH_SR A
    ENDIF.
  ENDIF.
  SORT GT_TRACE_DATA BY MOTHER_ROLL.
  READ TABLE GT_TRACE_DATA INTO GS_TRACE_DATA WITH KEY MOTHER_ROLL = L_MOTHER_ROLL B
  IF SY-SUBRC = 0.
    L_JR_CONV_BATCH = GS_TRACE_DATA-L_JR_CONV_BATCH.
    LOT_JR_CONV     = GS_TRACE_DATA-LOT_JR_CONV.
    L_SR_BASE_BATCH = GS_TRACE_DATA-L_SR_BASE_BATCH.
    LOT_SR_BASE     = GS_TRACE_DATA-LOT_SR_BASE.
    L_JR_BASE_BATCH = GS_TRACE_DATA-L_JR_BASE_BATCH.
    LOT_JR_BASE     = GS_TRACE_DATA-LOT_JR_BASE.
    IF LOT_SR_CONV IS INITIAL.
      LOT_SR_CONV = GS_TRACE_DATA-LOT_SR_CONV_SIBLING.
    ENDIF.
    IF GS_TRACE_DATA-LOT_SR_CONV_SIBLING IS NOT INITIAL AND GS_TRACE_DATA-LOT_SR_CON
      LOT_SR_CONV2 = GS_TRACE_DATA-LOT_SR_CONV_SIBLING.
    ENDIF.
    IF GS_TRACE_DATA-LOT_SR_CONV_SIBLING2 IS NOT INITIAL AND GS_TRACE_DATA-LOT_SR_CO
      IF LOT_SR_CONV2 IS INITIAL.
        LOT_SR_CONV2 = GS_TRACE_DATA-LOT_SR_CONV_SIBLING2.
      ENDIF.
    ENDIF.
    RETURN.
  ENDIF.
  IF LOT_SR_CONV IS INITIAL.
    PERFORM GET_ORIGINAL_BATCH USING IT_DATA-CHARG CHANGING LV_SEARCH_SR.
    CALL FUNCTION 'ZQM_GET_BATCH_JR_BY_SR'
      EXPORTING
        CHARG_S = LV_SEARCH_SR
      IMPORTING
        CHARG_J = L_JR_CONV_BATCH.
    " --- BEGIN FALLBACK WRAPPER ---
    " Jika JR gagal ditemukan, mungkin terputus oleh Change Grade (309) di tengah hi
    IF L_JR_CONV_BATCH IS INITIAL.
      PERFORM GET_VALID_ORDER_FROM_MSEG USING LV_SEARCH_SR CHANGING LV_FALLBACK_AUFN
      IF LV_FALLBACK_AUFNR_1 IS NOT INITIAL.
        PERFORM GET_VALID_COMPONENT_FROM_MSEG USING LV_FALLBACK_AUFNR_1 CHANGING LV_
        IF LV_FALLBACK_PARENT_1 IS NOT INITIAL.
          " Bypass change grade parent
          PERFORM GET_ORIGINAL_BATCH USING LV_FALLBACK_PARENT_1 CHANGING LV_SEARCH_S
          " Coba panggil lagi
          CALL FUNCTION 'ZQM_GET_BATCH_JR_BY_SR'
            EXPORTING
              CHARG_S = LV_SEARCH_SR
            IMPORTING
              CHARG_J = L_JR_CONV_BATCH.
        ENDIF.
      ENDIF.
    ENDIF.
    " --- END FALLBACK WRAPPER ---
    IF L_JR_CONV_BATCH IS NOT INITIAL.
      REFRESH LT_SR.
      CALL FUNCTION 'ZQM_GET_BATCH_SR_BY_JR'
        EXPORTING
          CHARGJR = L_JR_CONV_BATCH
        TABLES
          T_SR    = LT_SR.
      LOOP AT LT_SR.
        PERFORM GET_NEWEST_BATCH USING LT_SR-CHARG CHANGING LV_LATEST_SR.
        DATA: LV_TMP_LOT TYPE QALS-PRUEFLOS.
        CLEAR LV_TMP_LOT.
        SELECT SINGLE PRUEFLOS INTO LV_TMP_LOT FROM QALS WHERE CHARG = LV_LATEST_SR
        IF LV_TMP_LOT IS INITIAL.
          " Fallback change grade pada sibling
          PERFORM GET_ORIGINAL_BATCH USING LV_LATEST_SR CHANGING LV_SEARCH_SR.
          IF LV_SEARCH_SR NE LV_LATEST_SR.
            SELECT SINGLE PRUEFLOS INTO LV_TMP_LOT FROM QALS WHERE CHARG = LV_SEARCH
          ENDIF.
        ENDIF.
        IF LV_TMP_LOT IS NOT INITIAL.
          IF LOT_SR_CONV IS INITIAL.
            LOT_SR_CONV = LV_TMP_LOT.
            GS_TRACE_DATA-LOT_SR_CONV_SIBLING = LV_TMP_LOT.
          ELSEIF LV_TMP_LOT NE LOT_SR_CONV AND LOT_SR_CONV2 IS INITIAL.
            LOT_SR_CONV2 = LV_TMP_LOT.
            GS_TRACE_DATA-LOT_SR_CONV_SIBLING2 = LV_TMP_LOT.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ELSE.
    " Jika LOT_SR_CONV langsung ketemu, kita tetap butuh JR_CONV_BATCH untuk mencari
    PERFORM GET_ORIGINAL_BATCH USING IT_DATA-CHARG CHANGING LV_SEARCH_SR.
    CALL FUNCTION 'ZQM_GET_BATCH_JR_BY_SR'
      EXPORTING
        CHARG_S = LV_SEARCH_SR
      IMPORTING
        CHARG_J = L_JR_CONV_BATCH.
    " --- BEGIN FALLBACK WRAPPER ---
    " Jika JR gagal ditemukan, mungkin terputus oleh Change Grade (309) di tengah hi
    IF L_JR_CONV_BATCH IS INITIAL.
      PERFORM GET_VALID_ORDER_FROM_MSEG USING LV_SEARCH_SR CHANGING LV_FALLBACK_AUFN
      IF LV_FALLBACK_AUFNR_1 IS NOT INITIAL.
        PERFORM GET_VALID_COMPONENT_FROM_MSEG USING LV_FALLBACK_AUFNR_1 CHANGING LV_
        IF LV_FALLBACK_PARENT_1 IS NOT INITIAL.
          " Bypass change grade parent
          PERFORM GET_ORIGINAL_BATCH USING LV_FALLBACK_PARENT_1 CHANGING LV_SEARCH_S
          " Coba panggil lagi
          CALL FUNCTION 'ZQM_GET_BATCH_JR_BY_SR'
            EXPORTING
              CHARG_S = LV_SEARCH_SR
            IMPORTING
              CHARG_J = L_JR_CONV_BATCH.
        ENDIF.
      ENDIF.
    ENDIF.
    " --- END FALLBACK WRAPPER ---
  ENDIF.
  " 2. JR Converting Lot
  IF L_JR_CONV_BATCH IS NOT INITIAL.
    SELECT SINGLE PRUEFLOS INTO LOT_JR_CONV FROM QALS WHERE CHARG = L_JR_CONV_BATCH
    IF LOT_JR_CONV IS INITIAL.
      PERFORM GET_JR_SIBLING_LOT USING L_JR_CONV_BATCH CHANGING LOT_JR_CONV.
    ENDIF.
  ENDIF.
  " 3. Cari SR Base Film Batch
  IF L_JR_CONV_BATCH IS NOT INITIAL.
    PERFORM GET_VALID_ORDER_FROM_MSEG USING L_JR_CONV_BATCH CHANGING L_AUFNR.
    IF L_AUFNR IS NOT INITIAL.
      PERFORM GET_VALID_COMPONENT_FROM_MSEG USING L_AUFNR CHANGING L_CHARG.
      IF L_CHARG IS NOT INITIAL.
        SELECT SINGLE MATNR INTO L_MATNR FROM MCH1 WHERE CHARG = L_CHARG.
      ENDIF.
      IF L_CHARG IS NOT INITIAL.
        L_LEN = STRLEN( L_MATNR ).
        L_TEMP = L_LEN - 1.
        IF L_MATNR(2) = 'SR' AND ( L_MATNR+L_TEMP(1) = 'A' OR L_MATNR+L_TEMP(1) = 'O
          SELECT SINGLE LICHA INTO L_LICHA FROM MCH1 WHERE MATNR = L_MATNR AND CHARG
          IF L_LICHA IS NOT INITIAL.
            L_SR_BASE_BATCH = L_LICHA.
          ELSE.
            L_SR_BASE_BATCH = L_CHARG.
          ENDIF.
        ELSE.
          L_SR_BASE_BATCH = L_CHARG.
        ENDIF.
      ENDIF.
    ENDIF.
  ELSE.
    " Jika tidak ada JR Conv, mungkin inputnya langsung SR Base?
    L_SR_BASE_BATCH = IT_DATA-CHARG.
  ENDIF.
  " Fix dinamis (permintaan user 15/07/2026): JR yang ditemukan di atas (L_JR_CONV_B
  " ternyata tidak punya turunan SR Base Film (tidak dikonsumsi order manapun sebaga
  " komponen SR/JR). Artinya JR tsb sebenarnya JR Base Film (terminal, bukan JR Conv
  " dan batch DO ini sendiri sudah SR Base Film - bukan SR Converting. Re-label supa
  " tracing lanjut dengan benar ke JR Base Film, bukan berhenti/salah label.
  IF L_JR_CONV_BATCH IS NOT INITIAL AND L_SR_BASE_BATCH IS INITIAL.
    L_JR_BASE_BATCH = L_JR_CONV_BATCH.
    LOT_JR_BASE = LOT_JR_CONV.
    L_SR_BASE_BATCH = IT_DATA-CHARG.
    LOT_SR_BASE = LOT_SR_CONV.
    CLEAR: L_JR_CONV_BATCH, LOT_JR_CONV, LOT_SR_CONV.
  ENDIF.
  " 3. SR Base Film Lot
  IF L_SR_BASE_BATCH IS NOT INITIAL AND LOT_SR_BASE IS INITIAL.
    SELECT SINGLE PRUEFLOS INTO LOT_SR_BASE FROM QALS WHERE CHARG = L_SR_BASE_BATCH
    IF L_JR_BASE_BATCH IS INITIAL. " Skip re-search kalau JR Base sudah ketemu dari
      IF LOT_SR_BASE IS INITIAL.
        PERFORM GET_ORIGINAL_BATCH USING L_SR_BASE_BATCH CHANGING LV_SEARCH_SR.
        CALL FUNCTION 'ZQM_GET_BATCH_JR_BY_SR'
          EXPORTING
            CHARG_S = LV_SEARCH_SR
          IMPORTING
            CHARG_J = L_JR_BASE_BATCH.
        " --- BEGIN FALLBACK WRAPPER ---
        " Jika JR gagal ditemukan, mungkin terputus oleh Change Grade (309) di tenga
        IF L_JR_BASE_BATCH IS INITIAL.
          PERFORM GET_VALID_ORDER_FROM_MSEG USING LV_SEARCH_SR CHANGING LV_FALLBACK_
          IF LV_FALLBACK_AUFNR_2 IS NOT INITIAL.
            PERFORM GET_VALID_COMPONENT_FROM_MSEG USING LV_FALLBACK_AUFNR_2 CHANGING
            IF LV_FALLBACK_PARENT_2 IS NOT INITIAL.
              " Bypass change grade parent
              PERFORM GET_ORIGINAL_BATCH USING LV_FALLBACK_PARENT_2 CHANGING LV_SEAR
              " Coba panggil lagi
              CALL FUNCTION 'ZQM_GET_BATCH_JR_BY_SR'
                EXPORTING
                  CHARG_S = LV_SEARCH_SR
                IMPORTING
                  CHARG_J = L_JR_BASE_BATCH.
            ENDIF.
          ENDIF.
        ENDIF.
        " --- END FALLBACK WRAPPER ---
        IF L_JR_BASE_BATCH IS NOT INITIAL.
          REFRESH LT_SR.
          CALL FUNCTION 'ZQM_GET_BATCH_SR_BY_JR'
            EXPORTING
              CHARGJR = L_JR_BASE_BATCH
            TABLES
              T_SR    = LT_SR.
          LOOP AT LT_SR.
            PERFORM GET_NEWEST_BATCH USING LT_SR-CHARG CHANGING LV_LATEST_SR.
            SELECT SINGLE PRUEFLOS INTO LOT_SR_BASE FROM QALS WHERE CHARG = LV_LATES
            IF LOT_SR_BASE IS NOT INITIAL.
              EXIT.
            ENDIF.
          ENDLOOP.
        ENDIF.
      ELSE.
        " Cari JR_BASE_BATCH untuk mencari LOT_JR_BASE
        PERFORM GET_ORIGINAL_BATCH USING L_SR_BASE_BATCH CHANGING LV_SEARCH_SR.
        CALL FUNCTION 'ZQM_GET_BATCH_JR_BY_SR'
          EXPORTING
            CHARG_S = LV_SEARCH_SR
          IMPORTING
            CHARG_J = L_JR_BASE_BATCH.
        " --- BEGIN FALLBACK WRAPPER ---
        " Jika JR gagal ditemukan, mungkin terputus oleh Change Grade (309) di tenga
        IF L_JR_BASE_BATCH IS INITIAL.
          PERFORM GET_VALID_ORDER_FROM_MSEG USING LV_SEARCH_SR CHANGING LV_FALLBACK_
          IF LV_FALLBACK_AUFNR_2 IS NOT INITIAL.
            PERFORM GET_VALID_COMPONENT_FROM_MSEG USING LV_FALLBACK_AUFNR_2 CHANGING
            IF LV_FALLBACK_PARENT_2 IS NOT INITIAL.
              " Bypass change grade parent
              PERFORM GET_ORIGINAL_BATCH USING LV_FALLBACK_PARENT_2 CHANGING LV_SEAR
              " Coba panggil lagi
              CALL FUNCTION 'ZQM_GET_BATCH_JR_BY_SR'
                EXPORTING
                  CHARG_S = LV_SEARCH_SR
                IMPORTING
                  CHARG_J = L_JR_BASE_BATCH.
            ENDIF.
          ENDIF.
        ENDIF.
        " --- END FALLBACK WRAPPER ---
      ENDIF.
    ENDIF. " penutup guard L_JR_BASE_BATCH IS INITIAL
  ENDIF.
  " 4. JR Base Film Lot
  IF L_JR_BASE_BATCH IS NOT INITIAL AND LOT_JR_BASE IS INITIAL.
    SELECT SINGLE PRUEFLOS INTO LOT_JR_BASE FROM QALS WHERE CHARG = L_JR_BASE_BATCH
    IF LOT_JR_BASE IS INITIAL.
      PERFORM GET_JR_SIBLING_LOT USING L_JR_BASE_BATCH CHANGING LOT_JR_BASE.
    ENDIF.
  ENDIF.
  " Setelah selesai mencari semuanya, simpan ke cache
  GS_TRACE_DATA-MOTHER_ROLL = L_MOTHER_ROLL.
  GS_TRACE_DATA-L_JR_CONV_BATCH = L_JR_CONV_BATCH.
  GS_TRACE_DATA-LOT_JR_CONV = LOT_JR_CONV.
  GS_TRACE_DATA-L_SR_BASE_BATCH = L_SR_BASE_BATCH.
  GS_TRACE_DATA-LOT_SR_BASE = LOT_SR_BASE.
  GS_TRACE_DATA-L_JR_BASE_BATCH = L_JR_BASE_BATCH.
  GS_TRACE_DATA-LOT_JR_BASE = LOT_JR_BASE.
  IF GS_TRACE_DATA-LOT_SR_CONV_SIBLING IS INITIAL AND LOT_SR_CONV IS NOT INITIAL.
    GS_TRACE_DATA-LOT_SR_CONV_SIBLING = LOT_SR_CONV.
  ENDIF.
  APPEND GS_TRACE_DATA TO GT_TRACE_DATA.
ENDFORM.                    "GET_TRACED_LOTS
*&---------------------------------------------------------------------*
*&      Form  GET_ORIGINAL_BATCH
*&---------------------------------------------------------------------*
FORM GET_ORIGINAL_BATCH USING P_BATCH CHANGING P_ORIGINAL_BATCH.
  DATA: LV_OLD_BATCH TYPE CHARG_D.
  P_ORIGINAL_BATCH = P_BATCH.
  DO.
    CLEAR LV_OLD_BATCH.
    SELECT CHARG INTO LV_OLD_BATCH FROM ZBATCHISTORY
      UP TO 1 ROWS
      WHERE NCHARG = P_ORIGINAL_BATCH
      ORDER BY BUDAT DESCENDING UZEIT DESCENDING.
    ENDSELECT.
    IF SY-SUBRC = 0 AND LV_OLD_BATCH IS NOT INITIAL.
      P_ORIGINAL_BATCH = LV_OLD_BATCH.
    ELSE.
      EXIT.
    ENDIF.
  ENDDO.
ENDFORM.                    "GET_ORIGINAL_BATCH
*&---------------------------------------------------------------------*
*&      Form  GET_NEWEST_BATCH
*&---------------------------------------------------------------------*
FORM GET_NEWEST_BATCH USING P_BATCH CHANGING P_NEWEST_BATCH.
  DATA: LV_NEW_BATCH TYPE CHARG_D.
  P_NEWEST_BATCH = P_BATCH.
  DO.
    CLEAR LV_NEW_BATCH.
    SELECT NCHARG INTO LV_NEW_BATCH FROM ZBATCHISTORY
      UP TO 1 ROWS
      WHERE CHARG = P_NEWEST_BATCH
      ORDER BY BUDAT DESCENDING UZEIT DESCENDING.
    ENDSELECT.
    IF SY-SUBRC = 0 AND LV_NEW_BATCH IS NOT INITIAL.
      P_NEWEST_BATCH = LV_NEW_BATCH.
    ELSE.
      EXIT.
    ENDIF.
  ENDDO.
ENDFORM.                    "GET_NEWEST_BATCH
*&---------------------------------------------------------------------*
*&      Form  GET_JR_SIBLING_LOT
*&---------------------------------------------------------------------*
FORM GET_JR_SIBLING_LOT USING P_BATCH TYPE CHARG_D
                        CHANGING P_LOT TYPE QALS-PRUEFLOS.
  DATA: LV_CUOBJ_BM TYPE MCH1-CUOBJ_BM,
        LV_OBJEK TYPE AUSP-OBJEK,
        LV_ROLL_STR TYPE AUSP-ATWRT.
  DATA: BEGIN OF LT_PARTS OCCURS 0,
          PART(50) TYPE C,
        END OF LT_PARTS.
  DATA: LV_PART(50) TYPE C,
        LV_PREFIX(50) TYPE C,
        LV_SEQ_STR(10) TYPE C,
        LV_SEQ_NUM TYPE I,
        LV_LINES TYPE I.
  DATA: LV_IDX TYPE I,
        LV_START TYPE I,
        LV_END TYPE I,
        LV_SEQ_NEW_STR TYPE C LENGTH 3,
        LV_BATCH_NEW TYPE CHARG_D,
        LV_ROLL_NEW TYPE AUSP-ATWRT.
  DATA: BEGIN OF LT_SIBLING_ROLLS OCCURS 0,
          ATWRT TYPE AUSP-ATWRT,
        END OF LT_SIBLING_ROLLS.
  DATA: BEGIN OF LT_CUOBJ OCCURS 0,
          OBJEK TYPE AUSP-OBJEK,
        END OF LT_CUOBJ.
  DATA: BEGIN OF LT_CUOBJ_BM OCCURS 0,
          CUOBJ_BM TYPE MCH1-CUOBJ_BM,
        END OF LT_CUOBJ_BM.
  DATA: BEGIN OF LT_BATCHES OCCURS 0,
          CHARG TYPE MCH1-CHARG,
        END OF LT_BATCHES.
  DATA: BEGIN OF LT_LOTS OCCURS 0,
          PRUEFLOS TYPE QALS-PRUEFLOS,
          CHARG TYPE QALS-CHARG,
        END OF LT_LOTS.
  CLEAR P_LOT.
  IF P_BATCH IS INITIAL.
    RETURN.
  ENDIF.
  " 2. Dapatkan CUOBJ_BM (Internal Object Number) dari tabel MCH1 untuk P_BATCH
  SELECT SINGLE CUOBJ_BM INTO LV_CUOBJ_BM
    FROM MCH1
    WHERE CHARG = P_BATCH.
  IF SY-SUBRC <> 0 OR LV_CUOBJ_BM IS INITIAL.
    RETURN.
  ENDIF.
  LV_OBJEK = LV_CUOBJ_BM.
  " 3. Dapatkan teks Nomor Roll dari AUSP
  SELECT SINGLE ATWRT INTO LV_ROLL_STR
    FROM AUSP
    WHERE OBJEK = LV_OBJEK
      AND ATINN = ATINN_ROLL
      AND KLART = '023'
      AND MAFID = 'O'.
  IF SY-SUBRC <> 0 OR LV_ROLL_STR IS INITIAL.
    RETURN.
  ENDIF.
  " 4. Ekstrak prefix dan sequence dari Nomor Roll (misal: "W CGA 108 001")
  SPLIT LV_ROLL_STR AT SPACE INTO TABLE LT_PARTS.
  DESCRIBE TABLE LT_PARTS LINES LV_LINES.
  IF LV_LINES >= 2.
    READ TABLE LT_PARTS INDEX LV_LINES.
    LV_SEQ_STR = LT_PARTS-PART.
    " Reconstruct prefix
    DATA: LV_IDX_PREFIX TYPE I.
    LV_IDX_PREFIX = 1.
    CLEAR LV_PREFIX.
    WHILE LV_IDX_PREFIX < LV_LINES.
      READ TABLE LT_PARTS INDEX LV_IDX_PREFIX.
      LV_PART = LT_PARTS-PART.
      IF LV_PREFIX IS INITIAL.
        LV_PREFIX = LV_PART.
      ELSE.
        CONCATENATE LV_PREFIX LV_PART INTO LV_PREFIX SEPARATED BY SPACE.
      ENDIF.
      LV_IDX_PREFIX = LV_IDX_PREFIX + 1.
    ENDWHILE.
    " Pastikan karakter terakhir (sequence) adalah angka
    IF LV_SEQ_STR CO '0123456789 '.
      LV_SEQ_NUM = LV_SEQ_STR.
* Update sibling search (info Aisyah, 06/08/26):
* - Kunci: Kode Film + Month-Year (di LV_PREFIX).
* - Line ikut otomatis (bagian token prefix).
* - Cari NAIK saja, terdekat duluan, maks +20.
* - Ketemu 1 lot valid -> langsung STOP.
*   (bukan average / ambil semua sibling).
      LV_START = LV_SEQ_NUM + 1.
      LV_END = LV_SEQ_NUM + 20.
      CLEAR P_LOT.
      LV_IDX = LV_START.
      WHILE LV_IDX <= LV_END
        AND P_LOT IS INITIAL.
        CLEAR: LV_SEQ_NEW_STR, LV_ROLL_NEW,
               LV_OBJEK, LV_CUOBJ_BM,
               LV_BATCH_NEW.
        REFRESH LT_LOTS.
        " Roll kandidat sequence terdekat
        UNPACK LV_IDX TO LV_SEQ_NEW_STR.
        CONCATENATE LV_PREFIX LV_SEQ_NEW_STR
          INTO LV_ROLL_NEW SEPARATED BY SPACE.
        " 5. Cek Nomor Roll kandidat di AUSP
        SELECT SINGLE OBJEK INTO LV_OBJEK
          FROM AUSP
          WHERE ATINN = ATINN_ROLL
            AND ATWRT = LV_ROLL_NEW
            AND KLART = '023'
            AND MAFID = 'O'.
        IF SY-SUBRC = 0
          AND LV_OBJEK IS NOT INITIAL.
          LV_CUOBJ_BM = LV_OBJEK.
          " 6. CHARG dari MCH1 kandidat ini
          SELECT SINGLE CHARG INTO LV_BATCH_NEW
            FROM MCH1
            WHERE CUOBJ_BM = LV_CUOBJ_BM.
          IF SY-SUBRC = 0
            AND LV_BATCH_NEW IS NOT INITIAL.
            " 7. Lot Inspeksi (QALS) kandidat ini
            SELECT PRUEFLOS CHARG
              INTO TABLE LT_LOTS
              FROM QALS
              WHERE CHARG = LV_BATCH_NEW
                AND ( ART = 'Z02'
                   OR ART = 'Z03' ).
            IF SY-SUBRC = 0.
              SORT LT_LOTS BY PRUEFLOS
                DESCENDING.
              READ TABLE LT_LOTS INDEX 1.
              IF SY-SUBRC = 0.
                P_LOT = LT_LOTS-PRUEFLOS.
                " Ketemu -> stop
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
        LV_IDX = LV_IDX + 1.
      ENDWHILE.
    ENDIF.
  ENDIF.
ENDFORM.                    "GET_JR_SIBLING_LOT
*&---------------------------------------------------------------------*
*&      Form  GET_VALID_ORDER_FROM_MSEG
*&---------------------------------------------------------------------*
* BKTXT dokumen GR (101) yang sedang di-trace. Di-set oleh GET_VALID_ORDER_FROM_MSEG
* dibaca GET_VALID_COMPONENT_FROM_MSEG. BKTXT = identitas transaksi / nomor roll, da
* merupakan penghubung yang benar antara posting 101 dan 261 dalam SATU production o
DATA: GV_TRACE_BKTXT TYPE MKPF-BKTXT.
*&---------------------------------------------------------------------*
*&      Form  GET_VALID_ORDER_FROM_MSEG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_CHARG    text
*      -->P_AUFNR    text
*----------------------------------------------------------------------*
FORM GET_VALID_ORDER_FROM_MSEG USING P_CHARG CHANGING P_AUFNR.
  DATA: LT_MSEG TYPE TABLE OF MSEG WITH HEADER LINE,
        LT_CANC TYPE TABLE OF MSEG WITH HEADER LINE.
  DATA: LV_COMBINE LIKE AFPO-AUFNR.
  CLEAR P_AUFNR.
  SELECT AUFNR MBLNR MJAHR ZEILE SMBLN SJAHR SMBLP BWART CHARG
    INTO CORRESPONDING FIELDS OF TABLE LT_MSEG
    FROM MSEG
    WHERE CHARG = P_CHARG AND BWART IN ('101', '102')
    %_HINTS ORACLE 'INDEX("MSEG" "MSEG~Z07")'.
  IF SY-SUBRC = 0.
    LT_CANC[] = LT_MSEG[].
    DELETE LT_CANC WHERE SMBLN IS INITIAL.
    LOOP AT LT_CANC.
      DELETE LT_MSEG WHERE MBLNR = LT_CANC-SMBLN AND MJAHR = LT_CANC-SJAHR AND ZEILE
    ENDLOOP.
    DELETE LT_MSEG WHERE SMBLN IS NOT INITIAL OR BWART = '102'.
    SORT LT_MSEG BY MBLNR DESCENDING ZEILE DESCENDING.
    READ TABLE LT_MSEG INDEX 1.
    IF SY-SUBRC = 0.
      P_AUFNR = LT_MSEG-AUFNR.
      " Fix A (user 18/07/2026): ambil BKTXT dokumen GR (101) ini, dipakai
      " GET_VALID_COMPONENT_FROM_MSEG untuk memilih komponen 261 pasangan roll ini.
      " Bukti: order 100000072887 punya 8 posting 261 / 4 batch berbeda, dibedakan
      " HANYA oleh BKTXT. Logic lama ambil MBLNR terbesar - salah roll tanpa gejala.
      SELECT SINGLE BKTXT INTO GV_TRACE_BKTXT
        FROM MKPF
        WHERE MBLNR = LT_MSEG-MBLNR
          AND MJAHR = LT_MSEG-MJAHR.
      " Fix B (user 18/07/2026): resolve COLLECTIVE ORDER. AUFNR dari MSEG 101 bisa
      " order referensi (mis. A29000002540) yang TIDAK punya komponen 261 sama sekal
      " order asli dicari via AFPO-MILL_OC_AUFNR_U. Tanpa ini tracing MATI di hop
      " pertama sehingga MIC level Base Film (mis. PALZTH00) selalu kosong.
      CLEAR LV_COMBINE.
      SELECT SINGLE AUFNR INTO LV_COMBINE
        FROM AFPO
        WHERE MILL_OC_AUFNR_U = P_AUFNR.
      IF SY-SUBRC = 0 AND LV_COMBINE IS NOT INITIAL.
        P_AUFNR = LV_COMBINE.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.                    "GET_VALID_ORDER_FROM_MSEG
*&---------------------------------------------------------------------*
*&      Form  GET_VALID_COMPONENT_FROM_MSEG
*&---------------------------------------------------------------------*
FORM GET_VALID_COMPONENT_FROM_MSEG USING P_AUFNR CHANGING P_CHARG.
  DATA: BEGIN OF LT_MKPF OCCURS 0,
          MBLNR LIKE MKPF-MBLNR,
          MJAHR LIKE MKPF-MJAHR,
          BKTXT LIKE MKPF-BKTXT,
        END OF LT_MKPF.
  DATA: LT_MSEG TYPE TABLE OF MSEG WITH HEADER LINE,
        LT_CANC TYPE TABLE OF MSEG WITH HEADER LINE.
  CLEAR P_CHARG.
  SELECT AUFNR MBLNR MJAHR ZEILE SMBLN SJAHR SMBLP BWART CHARG MATNR
    INTO CORRESPONDING FIELDS OF TABLE LT_MSEG
    FROM MSEG
    WHERE AUFNR = P_AUFNR AND BWART IN ('261', '262', '901', '902') AND CHARG <> ''.
  IF SY-SUBRC = 0.
    LT_CANC[] = LT_MSEG[].
    DELETE LT_CANC WHERE SMBLN IS INITIAL.
    LOOP AT LT_CANC.
      DELETE LT_MSEG WHERE MBLNR = LT_CANC-SMBLN AND MJAHR = LT_CANC-SJAHR AND ZEILE
    ENDLOOP.
    DELETE LT_MSEG WHERE SMBLN IS NOT INITIAL OR BWART = '262' OR BWART = '902'.
    " Fix BKTXT (user 18/07/2026): buang komponen yang BUKAN milik transaksi/roll ya
    " sama dengan dokumen 101-nya. Satu order bisa punya banyak roll, dan BKTXT adal
    " satu-satunya pembeda. Kalau BKTXT 101 kosong (data lama), filter dilewati.
    IF GV_TRACE_BKTXT IS NOT INITIAL AND LT_MSEG[] IS NOT INITIAL.
      CLEAR LT_MKPF. REFRESH LT_MKPF.
      SELECT MBLNR MJAHR BKTXT INTO TABLE LT_MKPF
        FROM MKPF
        FOR ALL ENTRIES IN LT_MSEG
        WHERE MBLNR = LT_MSEG-MBLNR
          AND MJAHR = LT_MSEG-MJAHR.
      SORT LT_MKPF BY MBLNR MJAHR.
      LOOP AT LT_MSEG.
        CLEAR LT_MKPF.
        READ TABLE LT_MKPF WITH KEY MBLNR = LT_MSEG-MBLNR
                                    MJAHR = LT_MSEG-MJAHR BINARY SEARCH.
        IF SY-SUBRC <> 0 OR LT_MKPF-BKTXT <> GV_TRACE_BKTXT.
          DELETE LT_MSEG.
        ENDIF.
      ENDLOOP.
    ENDIF.
    SORT LT_MSEG BY MBLNR DESCENDING ZEILE DESCENDING.
    LOOP AT LT_MSEG.
      " Pastikan yang diambil adalah material Base Film (SR/JR), bukan komponen pele
      IF LT_MSEG-MATNR(2) = 'SR' OR LT_MSEG-MATNR(2) = 'JR'.
        P_CHARG = LT_MSEG-CHARG.
        EXIT.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDFORM.                    "GET_VALID_COMPONENT_FROM_MSEG
*&--------------------------------------------------------------------*
*&      Form  MICFMT
*&--------------------------------------------------------------------*
* Fix (user 18/07/2026): sebelumnya semua WRITE meng-hardcode DECIMALS 3,
* sehingga value tidak mengikuti master MIC (mis. SEWESTMZ STELLEN=0
* seharusnya tampil 55, bukan 54.842). Form ini mengambil STELLEN + unit
* dari QPMK per MIC dan per plant, hasilnya di-cache di GT_MICFMT.
*&--------------------------------------------------------------------*
*&      Form  GET_JR_AVG
*&--------------------------------------------------------------------*
* Enhancement (user 18/07/2026): untuk MIC ber-mapping JR (Converting /
* Base Film), nilai = RATA-RATA across semua sibling roll JR dalam 1
* mother roll (mis. E EWE 076 001..004), bukan hanya 1 roll yang di-slit
* ke SR-nya. Sebab QC merekam inspeksi JR sekali per order/jumbo di satu
* roll perwakilan; roll lain lot-nya kosong. Hanya lot dengan ANZWERTG>0
* yang ikut rata-rata (skip kosong). P_ISJR='X' bila INSLOT adalah lot JR
* (QALS ART Z02/Z03); bila bukan, caller pakai logika lama (SR tak berubah).
FORM GET_JR_AVG USING P_VBELN P_INSLOT P_MIC
         CHANGING P_ISJR
                  P_VAL TYPE QAMR-MITTELWERT
                  P_CNT TYPE I.
  DATA: L_ART TYPE QALS-ART.
  DATA: L_ICHARG TYPE QALS-CHARG.
  DATA: L_AUFNR TYPE MSEG-AUFNR.
  DATA: L_MK TYPE QAMV-MERKNR.
  DATA: L_MW TYPE QAMR-MITTELWERT, L_AZ TYPE QAMR-ANZWERTG.
  DATA: L_SUM TYPE QAMR-MITTELWERT.
  DATA: BEGIN OF LT_BCH OCCURS 0,
          CHARG TYPE MSEG-CHARG,
        END OF LT_BCH.
  DATA: BEGIN OF LT_JLOT OCCURS 0,
          LOT TYPE QALS-PRUEFLOS,
        END OF LT_JLOT.
  CLEAR: P_ISJR, P_VAL, P_CNT, L_SUM.
  SORT GT_JRAVG BY INSLOT MIC.
  READ TABLE GT_JRAVG INTO GS_JRAVG
       WITH KEY INSLOT = P_INSLOT MIC = P_MIC BINARY SEARCH.
  IF SY-SUBRC = 0.
    P_ISJR = GS_JRAVG-ISJR.
    P_VAL = GS_JRAVG-VAL.
    P_CNT = GS_JRAVG-CNT.
    RETURN.
  ENDIF.
  IF P_INSLOT IS NOT INITIAL.
    CLEAR: L_ART, L_ICHARG.
    SELECT SINGLE ART CHARG INTO (L_ART, L_ICHARG) FROM QALS
      WHERE PRUEFLOS = P_INSLOT.
    IF SY-SUBRC = 0 AND ( L_ART = 'Z02' OR L_ART = 'Z03' ).
      P_ISJR = 'X'.
      " 1) Langsung: nilai lot INSLOT sendiri (yg sudah
      "    ditentukan report per mapping base/converting).
      CLEAR L_MK.
      SELECT SINGLE MERKNR INTO L_MK FROM QAMV
        WHERE PRUEFLOS = P_INSLOT AND VERWMERKM = P_MIC.
      IF L_MK IS NOT INITIAL.
        CLEAR: L_MW, L_AZ.
        SELECT SINGLE MITTELWERT ANZWERTG
          INTO (L_MW, L_AZ) FROM QAMR
          WHERE PRUEFLOS = P_INSLOT AND MERKNR = L_MK.
        IF L_AZ > 0.
          P_VAL = L_MW.
          P_CNT = 1.
        ENDIF.
      ENDIF.
      " 2) Fallback: INSLOT kosong (inspeksi JR direkam di
      "    roll representatif lain dlm 1 production order
      "    yg sama). Rata2 lot JR non-empty se-order.
* FIX 08/08/26 (aturan functional COA):
*  Roll JR tak diinspeksi -> ambil sibling
*  SEQUENCE LEBIH KECIL (lebih lama) TERDEKAT,
*  prefix sama, SE-PRODUCTION-ORDER, yg bernilai.
*  Kosong bila tak ada.
      IF P_CNT = 0 AND L_ICHARG IS NOT INITIAL.
        DATA: LV_ATR TYPE AUSP-ATINN.
        DATA: LV_PF TYPE STRING, LV_PF2 TYPE STRING.
        DATA: LV_SQ TYPE I, LV_SQ2 TYPE I.
        DATA: LV_BEST TYPE I.
        DATA: LV_LOT TYPE QALS-PRUEFLOS.
        DATA: LV_MK2 TYPE QAMV-MERKNR.
        DATA: LV_MW2 TYPE QAMR-MITTELWERT.
        DATA: LV_AZ2 TYPE QAMR-ANZWERTG.
        CLEAR LV_ATR.
        SELECT SINGLE ATINN INTO LV_ATR FROM CABN
          WHERE ATNAM = 'ZZNOMORROLL'.
        PERFORM SPLIT_ROLL USING L_ICHARG LV_ATR
          CHANGING LV_PF LV_SQ.
        IF LV_SQ > 0 AND LV_ATR IS NOT INITIAL.
          CLEAR L_AUFNR.
          SELECT SINGLE AUFNR INTO L_AUFNR FROM MSEG
         WHERE CHARG = L_ICHARG AND BWART = '101'.
          IF L_AUFNR IS NOT INITIAL.
            REFRESH LT_BCH.
            SELECT CHARG INTO TABLE LT_BCH FROM MSEG
          WHERE AUFNR = L_AUFNR AND BWART = '101'.
            SORT LT_BCH BY CHARG.
            DELETE ADJACENT DUPLICATES FROM LT_BCH.
            LV_BEST = 0.
            LOOP AT LT_BCH.
              PERFORM SPLIT_ROLL USING LT_BCH-CHARG
                  LV_ATR CHANGING LV_PF2 LV_SQ2.
              IF LV_PF2 <> LV_PF. CONTINUE. ENDIF.
              IF LV_SQ2 >= LV_SQ. CONTINUE. ENDIF.
              IF LV_SQ2 <= LV_BEST. CONTINUE. ENDIF.
              CLEAR LV_LOT.
              SELECT SINGLE PRUEFLOS INTO LV_LOT
                FROM QALS
                WHERE CHARG = LT_BCH-CHARG
          AND ( ART = 'Z02' OR ART = 'Z03' ).
              IF LV_LOT IS INITIAL. CONTINUE. ENDIF.
              CLEAR LV_MK2.
              SELECT SINGLE MERKNR INTO LV_MK2
                FROM QAMV
                WHERE PRUEFLOS = LV_LOT
                  AND VERWMERKM = P_MIC.
              IF LV_MK2 IS INITIAL. CONTINUE. ENDIF.
              CLEAR: LV_MW2, LV_AZ2.
              SELECT SINGLE MITTELWERT ANZWERTG
                INTO (LV_MW2, LV_AZ2) FROM QAMR
                WHERE PRUEFLOS = LV_LOT
                  AND MERKNR = LV_MK2.
              IF LV_AZ2 > 0.
                LV_BEST = LV_SQ2.
                P_VAL = LV_MW2.
                P_CNT = 1.
              ENDIF.
            ENDLOOP.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.
  CLEAR GS_JRAVG.
  GS_JRAVG-INSLOT = P_INSLOT.
  GS_JRAVG-MIC = P_MIC.
  GS_JRAVG-ISJR = P_ISJR.
  GS_JRAVG-VAL = P_VAL.
  GS_JRAVG-CNT = P_CNT.
  APPEND GS_JRAVG TO GT_JRAVG.
ENDFORM.                    "GET_JR_AVG
*&--- Form SPLIT_ROLL ---
FORM SPLIT_ROLL USING P_BATCH P_ATR
             CHANGING P_PREF P_SEQ.
  DATA: L_CU TYPE MCH1-CUOBJ_BM.
  DATA: L_OB TYPE AUSP-OBJEK.
  DATA: L_RS TYPE AUSP-ATWRT.
  DATA: L_SEQ(10), L_PART(50), L_PREF(50).
  DATA: L_LN TYPE I, L_IX TYPE I.
  DATA: BEGIN OF L_LP OCCURS 0,
          PART(50),
        END OF L_LP.
  CLEAR: P_PREF, P_SEQ.
  IF P_ATR IS INITIAL. RETURN. ENDIF.
  CLEAR L_CU.
  SELECT SINGLE CUOBJ_BM INTO L_CU FROM MCH1
    WHERE CHARG = P_BATCH.
  IF L_CU IS INITIAL. RETURN. ENDIF.
  L_OB = L_CU. CLEAR L_RS.
  SELECT SINGLE ATWRT INTO L_RS FROM AUSP
    WHERE OBJEK = L_OB AND ATINN = P_ATR
      AND KLART = '023' AND MAFID = 'O'.
  IF L_RS IS INITIAL. RETURN. ENDIF.
  REFRESH L_LP.
  SPLIT L_RS AT SPACE INTO TABLE L_LP.
  DESCRIBE TABLE L_LP LINES L_LN.
  IF L_LN < 2. RETURN. ENDIF.
  READ TABLE L_LP INDEX L_LN.
  L_SEQ = L_LP-PART.
  CLEAR L_PREF. L_IX = 1.
  WHILE L_IX < L_LN.
    READ TABLE L_LP INDEX L_IX.
    L_PART = L_LP-PART.
    IF L_PREF IS INITIAL.
      L_PREF = L_PART.
    ELSE.
      CONCATENATE L_PREF L_PART INTO L_PREF
        SEPARATED BY SPACE.
    ENDIF.
    L_IX = L_IX + 1.
  ENDWHILE.
  P_PREF = L_PREF.
  IF L_SEQ CO '0123456789 '.
    P_SEQ = L_SEQ.
  ENDIF.
ENDFORM.                    "SPLIT_ROLL
*&---------------------------------------------------------------------*
*&      Form  GET_BAR_AVG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_VBELN    text
*      -->P_MIC      text
*      -->P_VAL      text
*      -->P_CNT      text
*----------------------------------------------------------------------*
FORM GET_BAR_AVG USING P_VBELN P_MIC
         CHANGING P_VAL TYPE QAMR-MITTELWERT
                  P_CNT TYPE I.
  DATA: L_NEWEST TYPE CHARG_D, L_LOT TYPE QALS-PRUEFLOS.
  DATA: L_MK TYPE QAMV-MERKNR, L_ALT TYPE QAMV-VERWMERKM.
  DATA: L_MW TYPE QASE-MESSWERT, L_SUM TYPE QAMR-MITTELWERT.
  DATA: BEGIN OF LT_CH OCCURS 0,
          CHARG TYPE LIPS-CHARG,
        END OF LT_CH.
  DATA: BEGIN OF LT_LOT OCCURS 0,
          LOT TYPE QALS-PRUEFLOS,
        END OF LT_LOT.
  CLEAR: P_VAL, P_CNT, L_SUM.
  SORT GT_BARAVG BY VBELN MIC.
  READ TABLE GT_BARAVG INTO GS_BARAVG
       WITH KEY VBELN = P_VBELN MIC = P_MIC BINARY SEARCH.
  IF SY-SUBRC = 0.
    P_VAL = GS_BARAVG-VAL.
    P_CNT = GS_BARAVG-CNT.
    RETURN.
  ENDIF.
  REFRESH LT_CH.
  LOOP AT IT_LOT WHERE VBELN = P_VBELN.
    IF IT_LOT-CHARG IS NOT INITIAL.
      LT_CH-CHARG = IT_LOT-CHARG.
      COLLECT LT_CH.
    ENDIF.
  ENDLOOP.
  REFRESH LT_LOT.
  LOOP AT LT_CH.
    CLEAR L_NEWEST.
    PERFORM GET_NEWEST_BATCH USING LT_CH-CHARG
                             CHANGING L_NEWEST.
    IF L_NEWEST IS INITIAL.
      L_NEWEST = LT_CH-CHARG.
    ENDIF.
    CLEAR L_LOT.
    SELECT SINGLE PRUEFLOS INTO L_LOT FROM QALS
      WHERE CHARG = L_NEWEST AND ART = 'Z04'.
    IF SY-SUBRC = 0 AND L_LOT IS NOT INITIAL.
      LT_LOT-LOT = L_LOT.
      COLLECT LT_LOT.
    ENDIF.
  ENDLOOP.
  LOOP AT LT_LOT.
    CLEAR L_MK.
    SELECT SINGLE MERKNR INTO L_MK FROM QAMV
      WHERE PRUEFLOS = LT_LOT-LOT AND VERWMERKM = P_MIC.
    IF SY-SUBRC <> 0 OR L_MK IS INITIAL.
      L_ALT = P_MIC.
      IF P_MIC CS 'MVTR'.
        REPLACE FIRST OCCURRENCE OF 'MVTR' IN L_ALT
                WITH 'WVTR'.
      ELSEIF P_MIC CS 'WVTR'.
        REPLACE FIRST OCCURRENCE OF 'WVTR' IN L_ALT
                WITH 'MVTR'.
      ELSEIF P_MIC CS 'O2TR'.
        REPLACE FIRST OCCURRENCE OF 'O2TR' IN L_ALT
                WITH 'OTR'.
      ELSEIF P_MIC CS 'OTR'.
        REPLACE FIRST OCCURRENCE OF 'OTR' IN L_ALT
                WITH 'O2TR'.
      ENDIF.
      IF L_ALT <> P_MIC.
        SELECT SINGLE MERKNR INTO L_MK FROM QAMV
          WHERE PRUEFLOS = LT_LOT-LOT AND VERWMERKM = L_ALT.
      ENDIF.
    ENDIF.
    IF L_MK IS NOT INITIAL.
      CLEAR L_MW.
      SELECT MESSWERT INTO L_MW FROM QASE
        UP TO 1 ROWS
        WHERE PRUEFLOS = LT_LOT-LOT AND MERKNR = L_MK
          AND ATTRIBUT = ''
        ORDER BY DETAILERG DESCENDING.
      ENDSELECT.
      IF SY-SUBRC = 0.
        L_SUM = L_SUM + L_MW.
        P_CNT = P_CNT + 1.
      ENDIF.
    ENDIF.
  ENDLOOP.
  IF P_CNT > 0.
    P_VAL = L_SUM / P_CNT.
  ENDIF.
  CLEAR GS_BARAVG.
  GS_BARAVG-VBELN = P_VBELN.
  GS_BARAVG-MIC = P_MIC.
  GS_BARAVG-VAL = P_VAL.
  GS_BARAVG-CNT = P_CNT.
  APPEND GS_BARAVG TO GT_BARAVG.
ENDFORM.                    "GET_BAR_AVG
*&---------------------------------------------------------------------*
*&      Form  MICFMT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_MIC      text
*      -->P_WRK      text
*      -->P_DEC      text
*      -->P_UOM      text
*----------------------------------------------------------------------*
FORM MICFMT USING P_MIC P_WRK
         CHANGING P_DEC TYPE I
                  P_UOM.
  CLEAR: P_DEC, P_UOM.
  IF P_MIC IS INITIAL.
    RETURN.
  ENDIF.
  READ TABLE GT_MICFMT INTO GS_MICFMT
    WITH KEY MKMNR = P_MIC WERKS = P_WRK.
  IF SY-SUBRC <> 0.
    CLEAR GS_MICFMT.
    GS_MICFMT-MKMNR = P_MIC.
    GS_MICFMT-WERKS = P_WRK.
    SELECT SINGLE STELLEN MASSEINHSW
      INTO (GS_MICFMT-STELLEN, GS_MICFMT-UOM)
      FROM QPMK
      WHERE MKMNR = P_MIC
        AND WERKS = P_WRK.
    IF SY-SUBRC <> 0.
      " Master belum ada di plant ini - pakai baris manapun sebagai cadangan
      SELECT SINGLE STELLEN MASSEINHSW
        INTO (GS_MICFMT-STELLEN, GS_MICFMT-UOM)
        FROM QPMK
        WHERE MKMNR = P_MIC.
    ENDIF.
    APPEND GS_MICFMT TO GT_MICFMT.
  ENDIF.
  P_DEC = GS_MICFMT-STELLEN.
  P_UOM = GS_MICFMT-UOM.
ENDFORM.                    "MICFMT
*&---------------------------------------------------------------------*
*&      Form  PREPARE_DYNAMIC_ROLL_COLUMNS
*&---------------------------------------------------------------------*
FORM PREPARE_DYNAMIC_ROLL_COLUMNS USING IV_VBELN TYPE LIPS-VBELN.
  DATA: LT_CFG TYPE TABLE OF ZQM_COA_CUST_COL WITH HEADER LINE,
        LS_ROLL_LINE TYPE ZQM_COA_DYN_ROLL,
        LV_KUNNR TYPE KUNNR,
        LV_CNT TYPE I,
        LV_SEQ_NUM TYPE NUMC2,
        LV_SLOT TYPE I,
        LV_FNAME TYPE STRING,
        LV_RAW_VAL TYPE CHAR50,
        LV_VBELN_PAD TYPE LIKP-VBELN.
  FIELD-SYMBOLS: <F_HDR> TYPE ANY, <F_COL> TYPE ANY.
  REFRESH: GT_DYN_ROLL.
  CLEAR: GS_DYN_HDR, GV_TIER.
  " 1. Cari Customer KUNNR dari Delivery (LIKP)
  CLEAR LV_VBELN_PAD.
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      INPUT  = IV_VBELN
    IMPORTING
      OUTPUT = LV_VBELN_PAD.
  SELECT SINGLE KUNAG INTO LV_KUNNR FROM LIKP
    WHERE VBELN = LV_VBELN_PAD.
  IF LV_KUNNR IS INITIAL.
    LV_KUNNR = 'DOM_DEFAUL'.
  ENDIF.
  " 2. Baca Konfigurasi Kolom dari ZQM_COA_CUST_COL
  SELECT * FROM ZQM_COA_CUST_COL
    INTO TABLE LT_CFG
    WHERE KUNNR = LV_KUNNR
      AND ACTIVE = 'X'
    ORDER BY SEQ_NO ASCENDING.
  IF LT_CFG[] IS INITIAL.
    SELECT * FROM ZQM_COA_CUST_COL
      INTO TABLE LT_CFG
      WHERE KUNNR = 'DOM_DEFAUL'
        AND ACTIVE = 'X'
      ORDER BY SEQ_NO ASCENDING.
  ENDIF.
  DESCRIBE TABLE LT_CFG LINES LV_CNT.
  IF LV_CNT > 14.
    MESSAGE 'Konfigurasi kolom COA maksimum 14 kolom' TYPE 'E'.
  ENDIF.
  IF LV_CNT <= 8.
    GV_TIER = 'PORTRAIT'.
  ELSE.
    GV_TIER = 'LANDSCAPE'.
  ENDIF.
  " 3. Bangun Header Dinamis GS_DYN_HDR
  LOOP AT LT_CFG.
    LV_SLOT = SY-TABIX.
    LV_SEQ_NUM = LV_SLOT.
    CONCATENATE 'GS_DYN_HDR-HDR' LV_SEQ_NUM INTO LV_FNAME.
    ASSIGN (LV_FNAME) TO <F_HDR>.
    IF <F_HDR> IS ASSIGNED.
      <F_HDR> = LT_CFG-FIELD_LABEL.
    ENDIF.
  ENDLOOP.
  " 4. Bangun Baris Data GT_DYN_ROLL per Batch/Roll
  DATA: LT_BATCHES LIKE TABLE OF IT_DATA WITH HEADER LINE.
  LT_BATCHES[] = IT_DATA[].
  SORT LT_BATCHES BY CHARG.
  DELETE ADJACENT DUPLICATES FROM LT_BATCHES COMPARING CHARG.
  LOOP AT LT_BATCHES.
    CLEAR: LS_ROLL_LINE.
    LOOP AT LT_CFG.
      LV_SLOT = SY-TABIX.
      LV_SEQ_NUM = LV_SLOT.
      CLEAR: LV_RAW_VAL.
      CASE LT_CFG-FIELD_NAME.
        WHEN 'DO_NUMBER' OR 'DO_NUM'.
          LV_RAW_VAL = LT_BATCHES-VBELN.
        WHEN 'PO_NUMBER' OR 'PO_NUM'.
          SELECT SINGLE BSTKD INTO LV_RAW_VAL FROM VBKD WHERE VBELN = LT_BATCHES-VBE
        WHEN 'HU_NUMBER' OR 'HU_NUM'.
          LV_RAW_VAL = ''.
        WHEN 'NO_PALET'.
          LV_RAW_VAL = ''.
        WHEN 'TYPE' OR 'MAT_TYPE'.
          LV_RAW_VAL = LT_BATCHES-MATNR.
        WHEN 'THICK'.
          LV_RAW_VAL = ''.
        WHEN 'ROLL_NUMBER' OR 'ROLL_NUM'.
          IF LT_BATCHES-NOMSR IS NOT INITIAL.
            LV_RAW_VAL = LT_BATCHES-NOMSR.
          ELSE.
            LV_RAW_VAL = LT_BATCHES-CHARG.
          ENDIF.
        WHEN 'BATCH_NUMBER' OR 'BATCH_NUM'.
          LV_RAW_VAL = LT_BATCHES-CHARG.
        WHEN 'TEXT_BARCODE' OR 'TXT_BARCODE'.
          LV_RAW_VAL = LT_BATCHES-CHARG.
        WHEN 'WIDTH'.
          IF LT_BATCHES-ZZWIDTH IS NOT INITIAL.
            WRITE LT_BATCHES-ZZWIDTH TO LV_RAW_VAL NO-GROUPING DECIMALS 0.
          ELSE.
            LV_RAW_VAL = WIDTH.
          ENDIF.
          CONDENSE LV_RAW_VAL.
        WHEN 'LENGTH'.
          IF LT_BATCHES-ZZLENGTH IS NOT INITIAL.
            WRITE LT_BATCHES-ZZLENGTH TO LV_RAW_VAL NO-GROUPING DECIMALS 0.
          ELSE.
            LV_RAW_VAL = CLENG.
          ENDIF.
          CONDENSE LV_RAW_VAL.
        WHEN 'WEIGHT_PER_ROL' OR 'WEIGHT_ROL'.
          DATA: LV_NTGEW TYPE LIPS-NTGEW.
          SELECT SINGLE NTGEW INTO LV_NTGEW FROM LIPS
            WHERE VBELN = LT_BATCHES-VBELN AND CHARG = LT_BATCHES-CHARG.
          IF SY-SUBRC = 0 AND LV_NTGEW > 0.
            WRITE LV_NTGEW TO LV_RAW_VAL DECIMALS 2.
            CONDENSE LV_RAW_VAL.
          ELSE.
            LV_RAW_VAL = QUANT.
          ENDIF.
        WHEN 'JOINT'.
          LV_RAW_VAL = '0'.
        WHEN 'QTY'.
          LV_RAW_VAL = '1'.
        WHEN 'TOTAL_ROLL' OR 'TOT_ROLL'.
          LV_RAW_VAL = ''.
        WHEN 'TOTAL_WEIGHT_PALET' OR 'TOT_PAL_WGT'.
          LV_RAW_VAL = ''.
        WHEN 'GG_PART_NUMBER' OR 'GG_PART_NO'.
          LV_RAW_VAL = ''.
        WHEN 'EXPIRED_DATE' OR 'EXP_DATE'.
          SELECT SINGLE VFDAT INTO LV_RAW_VAL FROM MCH1 WHERE CHARG = LT_BATCHES-CHA
        WHEN 'PRODUCTION_DATE' OR 'PROD_DATE' OR 'MANUFACTURING_DATE' OR 'MFG_DATE'.
          SELECT SINGLE HSDAT INTO LV_RAW_VAL FROM MCH1 WHERE CHARG = LT_BATCHES-CHA
        WHEN 'USED_BEFORE'.
          SELECT SINGLE VFDAT INTO LV_RAW_VAL FROM MCH1 WHERE CHARG = LT_BATCHES-CHA
        WHEN 'NUMBER_OF_JOINT' OR 'SPLICE_QTY'.
          LV_RAW_VAL = '0'.
        WHEN 'LENGTH_OF_SPLICE' OR 'SPLICE_LEN'.
          LV_RAW_VAL = ''.
        WHEN 'LOT_NUMBER' OR 'LOT_NUM'.
          LV_RAW_VAL = LT_BATCHES-INSLOT.
        WHEN 'NO_PALET_TRIAS' OR 'PALET_TRIAS'.
          LV_RAW_VAL = ''.
        WHEN 'BARCODE'.
          LV_RAW_VAL = LT_BATCHES-CHARG.
        WHEN 'SO_NUMBER' OR 'SO_NUM'.
          SELECT SINGLE VGBEL INTO LV_RAW_VAL FROM LIPS WHERE VBELN = LT_BATCHES-VBE
        WHEN 'TREATMENT_IN' OR 'TREAT_IN' OR 'TREATMENT_OUT' OR 'TREAT_OUT'.
          LV_RAW_VAL = ''.
      ENDCASE.
      CONCATENATE 'LS_ROLL_LINE-COL' LV_SEQ_NUM INTO LV_FNAME.
      ASSIGN (LV_FNAME) TO <F_COL>.
      IF <F_COL> IS ASSIGNED.
        <F_COL> = LV_RAW_VAL.
      ENDIF.
    ENDLOOP.
    APPEND LS_ROLL_LINE TO GT_DYN_ROLL.
  ENDLOOP.
ENDFORM.                    " PREPARE_DYNAMIC_ROLL_COLUMNS

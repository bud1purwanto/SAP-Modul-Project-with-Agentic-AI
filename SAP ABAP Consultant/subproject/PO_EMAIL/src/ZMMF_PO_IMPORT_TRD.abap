*----------------------------------------------------------------------*
* Form ZMMF_PO_IMPORT
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*
* Description      : Program for Form PO Import
*
* Application Area - MM
* ABAPer           - Alamsyah
* Date             - 5 November 2012
*----------------------------------------------------------------------*
* Amendment History
* ~~~~~~~~~~~~~~~~~
* Ref | Date                    |       Programmer      | Correction | Description
* ~~~   ~~~~~~~~                        ~~~~~~~~~~              ~~~~~~~~~~   ~~~~~~~~~~~
*      5 November 2012             Rimbun Gracia Siahaan
*----------------------------------------------------------------------*

REPORT  ZMMF_PO_IMPORT.

INCLUDE ZMMF_PO_IMPORT_TOP.
INCLUDE ZMMF_PO_IMPORT_F01.
* ===== INCLUDE ZMMF_PO_IMPORT_F01 =====
*&---------------------------------------------------------------------*
*&  Include           ZMMF_PO_IMPORT_F01
*&---------------------------------------------------------------------*

*&--------------------------------------------------------------------*
*&      Form  entry_neu
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
*      -->ENT_RETCO  text
*      -->ENT_SCREEN text
*---------------------------------------------------------------------*
DATA: IS_SAME_OTYPE(1).      "tidak boleh reprint dengan output beda

*&---------------------------------------------------------------------*
*&      Form  ENTRY_NEU
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->ENT_RETCO  text
*      -->ENT_SCREEN text
*----------------------------------------------------------------------*
FORM ENTRY_NEU USING ENT_RETCO ENT_SCREEN.
  PERFORM CEK_OUTPUT_TYPE.
  IF IS_SAME_OTYPE NE 'X'.

    CLEAR RETCODE.
    XSCREEN = ENT_SCREEN.
    PERFORM F_PROCESSING.
    IF RETCODE NE 0.
      ENT_RETCO = 1.
    ELSE.
      ENT_RETCO = 0.
    ENDIF.
  ENDIF.
ENDFORM.                    "entry_neu

*&---------------------------------------------------------------------*
*&      Form  f_processing
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_PROCESSING .

  PERFORM F_SELECT_DATA.

  READ TABLE IT_PO INDEX 1.

  PERFORM F_FIND_DATA_VENDOR.

  PERFORM  F_FIND_CONSIGNEE.

  PERFORM  F_GET_TERM_PAYMENT.

  PERFORM F_GET_HEADER_TEXT.

  PERFORM F_GET_CONDITION.

  PERFORM F_FIND_DATA_PO_NO.

  PERFORM F_ADDITIONAL_DATA.

  PERFORM F_FIND_ITEM_DATA.

  PERFORM F_PO_RETURN.   "case of PO return
  PERFORM F_CALL_SMARTFORMS.

ENDFORM.                    " f_processing
*&---------------------------------------------------------------------*
*&      Form  f_find_data_vendor
*&---------------------------------------------------------------------*
*       text

*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_FIND_DATA_VENDOR.
  CLEAR LFA1.
  SELECT SINGLE * FROM LFA1 WHERE
  LIFNR = IT_PO-LIFNR.

  WRITE LFA1-NAME1 TO P_VENDOR.
  WRITE LFA1-STRAS TO P_ADDRESS.
  CONCATENATE LFA1-ORT01 LFA1-PSTLZ INTO P_CITY SEPARATED BY SPACE.
  WRITE LFA1-TELF1  TO P_TELP.
  WRITE LFA1-TELFX  TO P_FAX.

  IF LFA1-KTOKK = 'ZOTI'.
*  EDIT BY JEFF 04-01-2013******************
    DATA : VHNUM LIKE ADRC-HOUSE_NUM1,
           VCITY1 LIKE ADRC-CITY1,
           PCODE1 LIKE ADRC-POST_CODE1.

    SELECT SINGLE ADRC~NAME1 STREET HOUSE_NUM1 CITY1 POST_CODE1 TEL_NUMBER FAX_NUMBER
      INTO (P_VENDOR, P_ADDRESS,VHNUM,VCITY1,PCODE1,P_TELP,P_FAX )
    FROM ADRC
      JOIN EKKO ON EKKO~ADRNR = ADRC~ADDRNUMBER
      JOIN LFA1 ON LFA1~LIFNR = EKKO~LIFNR
    WHERE EBELN = IT_PO-EBELN AND
          LFA1~LIFNR = IT_PO-LIFNR AND
          KTOKK = 'ZOTI'.

    IF P_VENDOR EQ '*'.
      CLEAR P_VENDOR.
    ENDIF.
    IF P_ADDRESS EQ '*'.
      CLEAR P_ADDRESS.
    ENDIF.
    IF VHNUM EQ '*'.
      CLEAR VHNUM.
    ENDIF.
    IF VCITY1 EQ '*'.
      CLEAR VCITY1.
    ENDIF.
    IF PCODE1 EQ '*'.
      CLEAR PCODE1.
    ENDIF.
    IF P_TELP EQ '*'.
      CLEAR P_TELP.
    ENDIF.
    IF P_FAX EQ '*'.
      CLEAR P_FAX.
    ENDIF.
    CONCATENATE P_ADDRESS VHNUM INTO P_ADDRESS SEPARATED BY SPACE.
    CONCATENATE VCITY1 PCODE1 INTO P_CITY SEPARATED BY SPACE.

*  END EDIT BY JEFF 04-01-2013**************
  ENDIF.

  CONCATENATE IT_PO-IHREZ LFA1-NAME1 INTO P_SUP_REF SEPARATED BY SPACE.

* get fax no from vendor memo text header po.

  WRITE IT_PO-VERKF TO P_VERKF.


  CLEAR : V_TDNAME, P_VERKF.

  V_TDNAME = IT_PO-EBELN.
  REFRESH I_LINES.
  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      ID        = 'F15'
      LANGUAGE  = 'E'
      NAME      = V_TDNAME
      OBJECT    = 'EKKO'
    IMPORTING
      HEADER    = THEAD
    TABLES
      LINES     = I_LINES
    EXCEPTIONS
      ID        = 1
      LANGUAGE  = 2
      NAME      = 3
      NOT_FOUND = 4
      OBJECT    = 5.

  DELETE I_LINES
    WHERE  TDLINE EQ SPACE.

  LOOP AT I_LINES.
    CONCATENATE I_LINES-TDLINE ' '
    INTO  P_DATE_REF  SEPARATED BY SPACE.
  ENDLOOP.
ENDFORM.                    " f_find_data_vendor

*&---------------------------------------------------------------------*
*&      Form  f_find_data_po_no
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_FIND_DATA_PO_NO .


  WRITE IT_PO-EBELN TO P_EBELN.

  CONCATENATE IT_PO-AEDAT+6(2) '-' IT_PO-AEDAT+4(2) '-' IT_PO-AEDAT+0(4)
  INTO P_DATE_PO.

  CONCATENATE SY-DATUM+6(2) '-' SY-DATUM+4(2) '-' SY-DATUM+0(4)
  INTO P_DATE_PRT.

  P_DATE_PAY = IT_PO-TEXT1.

ENDFORM.                    " f_find_data_po_no
*&---------------------------------------------------------------------*
*&      Form  f_find_item_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_FIND_ITEM_DATA.


* that the structure it_po_local same with it_PO_import.
  DATA :  LC_KBETR LIKE KONV-KBETR,
          LC_KBETR2 LIKE KONV-KBETR,   "ADD BY JALU 06.02.2013 - TAMBAH KONDISI SELAIN %
          LC_KWERT LIKE KONV-KWERT,
          LC_DEV LIKE KONV-KBETR,
          LC_INS LIKE KONV-KBETR,
          LC_WAERS LIKE EKKO-WAERS.


  DATA : LC_SUBTOTAL LIKE KONV-KWERT,
         LC_SUBDIC   LIKE KONV-KWERT.

  DATA : LC_BASE_AMOUNT LIKE KONV-KWERT.
  DATA : LC_TAX_AMOUNT  LIKE KONV-KWERT,
         LC_TOTAL_ORDER LIKE KONV-KWERT.

  REFRESH : I_ZPO_LOCAL.

  PERFORM F_ADD_KSCHL.


  CLEAR :  LC_SUBTOTAL,
           LC_SUBDIC.

  SORT IT_PO BY EBELN EBELP.

  LOOP AT IT_PO.

    PERFORM F_GET_ITEM_TEXT USING IT_PO-EBELN IT_PO-EBELP
                            CHANGING I_ZPO_LOCAL-ZTEXT.

    WRITE IT_PO-EBELP  TO I_ZPO_LOCAL-ZNO.
    WRITE IT_PO-MENGE  TO I_ZPO_LOCAL-ZMENGE UNIT IT_PO-MEINS LEFT-JUSTIFIED.
    WRITE IT_PO-MEINS  TO I_ZPO_LOCAL-ZMEINS LEFT-JUSTIFIED.
    WRITE IT_PO-MATNR  TO I_ZPO_LOCAL-ZMATNR LEFT-JUSTIFIED.

    CLEAR MAKT.
    SELECT SINGLE MAKTX INTO MAKT-MAKTX FROM MAKT
    WHERE MATNR = IT_PO-MATNR.

    IF MAKT-MAKTX <> SPACE.
      WRITE MAKT-MAKTX  TO I_ZPO_LOCAL-ZDESCRIPTION LEFT-JUSTIFIED.
    ELSE.
      WRITE IT_PO-TXZ01 TO I_ZPO_LOCAL-ZDESCRIPTION LEFT-JUSTIFIED.
    ENDIF.
    WRITE IT_PO-BANFN TO I_ZPO_LOCAL-ZPRNO LEFT-JUSTIFIED.
    WRITE IT_PO-BEDNR TO I_ZPO_LOCAL-ZFANO LEFT-JUSTIFIED.

    READ TABLE IT_EKET WITH KEY EBELN = IT_PO-EBELN
                                EBELP = IT_PO-EBELP.
    IF SY-SUBRC EQ 0.
      CONCATENATE IT_EKET-EINDT+6(2) '-' IT_EKET-EINDT+4(2) '-' IT_EKET-EINDT+2(2) INTO
      I_ZPO_LOCAL-ZEINDT.
    ENDIF.

* unit Price
    CLEAR LC_KBETR.
    LOOP AT IT_KONV WHERE KNUMV = IT_PO-KNUMV AND
                          KPOSN = IT_PO-EBELP AND
                          ( KSCHL = 'PBXX' OR KSCHL = 'PB00' ).

      LC_KBETR = LC_KBETR + IT_KONV-KBETR.
    ENDLOOP.
    WRITE LC_KBETR TO I_ZPO_LOCAL-ZUNITPRICE CURRENCY IT_PO-WAERS LEFT-JUSTIFIED.

* unitdisc
    CLEAR: LC_KBETR, LC_KBETR2.
    LOOP AT IT_KONV WHERE KNUMV = IT_PO-KNUMV AND
                          KPOSN = IT_PO-EBELP AND
                          KSCHL IN R_KSCHL AND KSCHL NE 'HB01' .

*--------------------------------------------------------------------*EDIT BY JALU 06.02.2013
      IF IT_KONV-WAERS NE ''.
        LC_KBETR2 = LC_KBETR2 + IT_KONV-KBETR.
        IT_KONV-DISC2 = LC_KBETR2.
      ELSE.
        LC_KBETR = LC_KBETR + IT_KONV-KBETR.
        IT_KONV-DISC1 = LC_KBETR.
      ENDIF.
      MODIFY IT_KONV.
*--------------------------------------------------------------------*EDIT BY JALU 06.02.2013
    ENDLOOP.

*--------------------------------------------------------------------*EDIT BY JALU 06.02.2013
    LOOP AT IT_KONV WHERE DISC1 NE '0.00' AND KNUMV = IT_PO-KNUMV AND KPOSN = IT_PO-EBELP.
      IT_KONV-DISC1 = IT_KONV-DISC1 / 10.
      WRITE IT_KONV-DISC1 TO I_ZPO_LOCAL-ZUNITDISC EXPONENT 2 DECIMALS 2 LEFT-JUSTIFIED.
      I_ZPO_LOCAL-ZWAERS = '%'.
    ENDLOOP.

    LOOP AT IT_KONV WHERE DISC2 NE '0.00' AND KNUMV = IT_PO-KNUMV AND KPOSN = IT_PO-EBELP.
      DATA  : V_NEWAMOUNT LIKE WMTO_S-AMOUNT.
      CLEAR : V_NEWAMOUNT.
      V_NEWAMOUNT = IT_KONV-DISC2.
      CALL FUNCTION 'CURRENCY_AMOUNT_SAP_TO_DISPLAY'
        EXPORTING
          CURRENCY        = IT_PO-WAERS
          AMOUNT_INTERNAL = V_NEWAMOUNT
        IMPORTING
          AMOUNT_DISPLAY  = V_NEWAMOUNT.
      IT_KONV-DISC2 = V_NEWAMOUNT.
      WRITE IT_KONV-DISC2 TO I_ZPO_LOCAL-ZUNITDISC2 EXPONENT 2 DECIMALS 2 LEFT-JUSTIFIED.
    ENDLOOP.
*--------------------------------------------------------------------*EDIT BY JALU 06.02.2013

*    IF IT_KONV-WAERS = SPACE.
*      LC_KBETR = LC_KBETR / 10.
*      WRITE LC_KBETR TO I_ZPO_LOCAL-ZUNITDISC EXPONENT 2 DECIMALS 2 LEFT-JUSTIFIED.
*      I_ZPO_LOCAL-ZWAERS = '%   '.
*    ELSE.
*      WRITE LC_KBETR TO I_ZPO_LOCAL-ZUNITDISC EXPONENT 2 DECIMALS 2 CURRENCY IT_PO-WAERS LEFT-JUSTIFIED.
*      WRITE IT_KONV-WAERS TO I_ZPO_LOCAL-ZWAERS.
*    ENDIF.
**    SHIFT i_zpo_local-zunitdisc RIGHT DELETING TRAILING '-' IN CHARACTER MODE.
*    REPLACE ALL OCCURRENCES OF '-' IN I_ZPO_LOCAL-ZUNITDISC WITH ' '.
*    CONCATENATE '-' I_ZPO_LOCAL-ZUNITDISC INTO I_ZPO_LOCAL-ZUNITDISC.

*    lc_subdic = lc_subdic + lc_kbetr.


*total price
    CLEAR LC_KWERT.
    LOOP AT IT_KONV WHERE KNUMV = IT_PO-KNUMV AND
                          KPOSN = IT_PO-EBELP AND
                          ( KSCHL = 'PBXX' OR KSCHL = 'PB00' ).

      LC_KWERT = LC_KWERT + IT_KONV-KWERT.
      WRITE IT_KONV-WAERS TO I_ZPO_LOCAL-WAERS.
    ENDLOOP.
    WRITE LC_KWERT TO I_ZPO_LOCAL-ZTOTALPRICE CURRENCY IT_PO-WAERS.
    WRITE IT_KONV-WAERS TO I_ZPO_LOCAL-WAERS.

    LC_SUBTOTAL = LC_SUBTOTAL + LC_KWERT.

*total disc
    CLEAR LC_KWERT.
    LOOP AT IT_KONV WHERE KNUMV = IT_PO-KNUMV AND
                          KPOSN = IT_PO-EBELP AND
                          KSCHL IN R_KSCHL. " AND KSCHL NE 'HB01'.

      LC_KWERT = LC_KWERT + IT_KONV-KWERT.
    ENDLOOP.
    WRITE LC_KWERT TO I_ZPO_LOCAL-ZTOTALDISC CURRENCY IT_PO-WAERS.
    CONDENSE I_ZPO_LOCAL-ZTOTALDISC.
    REPLACE ALL OCCURRENCES OF '-' IN I_ZPO_LOCAL-ZTOTALDISC WITH ' '.
    CONCATENATE '-' I_ZPO_LOCAL-ZTOTALDISC INTO I_ZPO_LOCAL-ZTOTALDISC.

    LC_SUBDIC = LC_SUBDIC + LC_KWERT.

* find inssurance
    CLEAR LC_INS.
    LOOP AT IT_KONV WHERE KNUMV = IT_PO-KNUMV AND
                          KPOSN EQ '000000' AND
                          KSCHL = 'ZZ04'.

      LC_INS = LC_INS + IT_KONV-KBETR.
    ENDLOOP.
    IF SY-SUBRC <> 0.
      CLEAR LC_KWERT.
      LOOP AT IT_KONV WHERE KNUMV = IT_PO-KNUMV AND
                            KPOSN = IT_PO-EBELP    AND
                            KSCHL = 'ZZ04'.

        LC_INS = LC_INS + IT_KONV-KBETR.
      ENDLOOP.
    ENDIF.
    WRITE LC_INS TO P_INSSURANCE CURRENCY IT_PO-WAERS.

* find last po.

    IF IT_PO-MATNR <> ''.


      READ TABLE IT_ADD_LAST WITH KEY MATNR = IT_PO-MATNR.
      IF SY-SUBRC EQ 0.
        CLEAR LFA1.
        SELECT SINGLE NAME1 INTO LFA1-NAME1 FROM LFA1
        WHERE LIFNR = IT_ADD_LAST-LIFNR.
        IF SY-SUBRC EQ 0.
          WRITE LFA1-NAME1 TO I_ZPO_LOCAL-ZLASTVENDOR.
        ENDIF.
      ENDIF.

* find last price by material
      CLEAR: IT_KONV_LAST.
      SELECT A~KNUMV A~WAERS B~EBELP INTO (IT_KONV_LAST-KNUMV, IT_KONV_LAST-WAERS, IT_KONV_LAST-KPOSN)  ", it_konv_last-kbetr)
        FROM EKKO AS A JOIN EKPO AS B ON B~EBELN = A~EBELN
        WHERE B~MATNR  = IT_PO-MATNR AND B~LOEKZ = '' AND A~EBELN < IT_PO-EBELN
        AND A~FRGZU = 'X'
        ORDER BY A~KNUMV ASCENDING.
      ENDSELECT.

      IF SY-SUBRC = 0.
        CLEAR LC_KBETR.
        SELECT SINGLE KBETR INTO LC_KBETR FROM KONV
        WHERE KNUMV = IT_KONV_LAST-KNUMV AND KPOSN = IT_KONV_LAST-KPOSN AND
                                         ( KSCHL = 'PB00' OR KSCHL = 'PBXX').

*      * get kurs
        DATA: V_KURS LIKE RKB1K-EXCHR.
        CLEAR: V_KURS, V_NEWAMOUNT.

        IF IT_PO-WAERS NE IT_KONV_LAST-WAERS.
* convert to IDR
          IF IT_KONV_LAST-WAERS = 'IDR'.
            LC_KBETR = LC_KBETR.
          ELSE.
            CALL FUNCTION 'RKC_SINGLE_EXCHANGE_RATE_GET'
              EXPORTING
                DATUM         = SY-DATUM
                KURST         = 'M'
                NCURR         = 'IDR'
                VCURR         = IT_KONV_LAST-WAERS
              IMPORTING
                EXCHR         = V_KURS
              EXCEPTIONS
                NO_RATE_FOUND = 1
                OTHERS        = 2.

            LC_KBETR = LC_KBETR * V_KURS.
          ENDIF.

          V_NEWAMOUNT = LC_KBETR.
          CALL FUNCTION 'CURRENCY_AMOUNT_SAP_TO_DISPLAY'
            EXPORTING
              CURRENCY        = IT_KONV_LAST-WAERS
              AMOUNT_INTERNAL = V_NEWAMOUNT
            IMPORTING
              AMOUNT_DISPLAY  = V_NEWAMOUNT.
          LC_KBETR = V_NEWAMOUNT.

* convert from IDR
          IF IT_PO-WAERS EQ 'IDR'.
            LC_KBETR = LC_KBETR.
          ELSE.
            CALL FUNCTION 'RKC_SINGLE_EXCHANGE_RATE_GET'
              EXPORTING
                DATUM         = SY-DATUM
                KURST         = 'M'
                NCURR         = 'IDR'
                VCURR         = IT_PO-WAERS
              IMPORTING
                EXCHR         = V_KURS
              EXCEPTIONS
                NO_RATE_FOUND = 1
                OTHERS        = 2.

            LC_KBETR = LC_KBETR * 1 / V_KURS.
          ENDIF.
        ELSE.
          V_NEWAMOUNT = LC_KBETR.
          CALL FUNCTION 'CURRENCY_AMOUNT_SAP_TO_DISPLAY'
            EXPORTING
              CURRENCY        = IT_KONV_LAST-WAERS
              AMOUNT_INTERNAL = V_NEWAMOUNT
            IMPORTING
              AMOUNT_DISPLAY  = V_NEWAMOUNT.
          LC_KBETR = V_NEWAMOUNT.
        ENDIF.    " no same currency
*--- end of get kurs

        IF SY-SUBRC = 0.
          WRITE LC_KBETR TO I_ZPO_LOCAL-ZLASTPRICE. "CURRENCY it_po-waers.
        ENDIF.
      ENDIF.
    ENDIF.
    CLEAR: IT_KONV_LAST.

    APPEND I_ZPO_LOCAL.
    CLEAR  I_ZPO_LOCAL.

  ENDLOOP.

  WRITE LC_SUBTOTAL TO P_SUBTOTAL CURRENCY IT_PO-WAERS LEFT-JUSTIFIED.
  WRITE LC_SUBDIC   TO P_DISCOUNT CURRENCY IT_PO-WAERS LEFT-JUSTIFIED.

  REPLACE ALL OCCURRENCES OF '-' IN P_DISCOUNT WITH ' '.
  CONCATENATE '-' P_DISCOUNT  INTO  P_DISCOUNT.

* tax
  CLEAR LC_BASE_AMOUNT.
  LC_BASE_AMOUNT  = LC_SUBTOTAL - LC_SUBDIC.

  CLEAR LC_TAX_AMOUNT.
  LOOP AT IT_PO WHERE MWSKZ NE SPACE.
    IF IT_PO-MWSKZ = 'V0'.
      LC_TAX_AMOUNT = 0.
    ELSEIF IT_PO-MWSKZ = 'V1'.
      LC_TAX_AMOUNT = LC_BASE_AMOUNT * ( 10 / 100 ).
    ENDIF.
    EXIT.
  ENDLOOP.
  WRITE LC_TAX_AMOUNT TO P_TAX CURRENCY IT_PO-WAERS.

*freight
  CLEAR LC_KWERT.
  LOOP AT IT_KONV WHERE KNUMV = IT_PO-KNUMV AND
                        KPOSN = IT_PO-EBELP    AND
                        KSCHL = 'ZS02'.

    LC_KWERT = LC_KWERT + IT_KONV-KBETR.
  ENDLOOP.
  WRITE LC_KWERT TO P_FREIGHT CURRENCY IT_PO-WAERS.

*delivery Cost
  CLEAR LC_DEV.
  LOOP AT IT_KONV WHERE KNUMV = IT_PO-KNUMV AND
                        KPOSN = IT_PO-EBELP    AND
                        KSCHL = 'ZS01'.

    LC_DEV = LC_DEV + IT_KONV-KBETR.
  ENDLOOP.
  WRITE LC_DEV TO P_DEV CURRENCY IT_PO-WAERS.


  LC_TOTAL_ORDER = LC_SUBTOTAL + LC_SUBDIC + LC_TAX_AMOUNT + LC_KWERT + LC_DEV + LC_INS.

  WRITE LC_TOTAL_ORDER TO P_TOTAL_ORDER CURRENCY IT_PO-WAERS.

ENDFORM.                    " f_find_item_data
*&---------------------------------------------------------------------*
*&      Form  f_add_kschl
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_ADD_KSCHL .

  R_KSCHL-SIGN   =  'I'.
  R_KSCHL-OPTION =  'EQ'.
  R_KSCHL-LOW    =  'HB01'.
  R_KSCHL-HIGH   =  'HB01'.
  APPEND R_KSCHL.

  R_KSCHL-SIGN   =  'I'.
  R_KSCHL-OPTION =  'EQ'.
  R_KSCHL-LOW    =  'RA00'.
  R_KSCHL-HIGH   =  'RA00'.
  APPEND R_KSCHL.


  R_KSCHL-SIGN   =  'I'.
  R_KSCHL-OPTION =  'EQ'.
  R_KSCHL-LOW    =  'RA01'.
  R_KSCHL-HIGH   =  'RA01'.
  APPEND R_KSCHL.


  R_KSCHL-SIGN   =  'I'.
  R_KSCHL-OPTION =  'EQ'.
  R_KSCHL-LOW    =  'RB00'.
  R_KSCHL-HIGH   =  'RB00'.
  APPEND R_KSCHL.



ENDFORM.                    " f_add_kschl
*&---------------------------------------------------------------------*
*&      Form  f_get_last_month_date
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_GET_LAST_MONTH_DATE .

  V_DATUM_END = SY-DATUM - 1.
  R_DATE-SIGN   =  'I'.
  R_DATE-OPTION =  'BT'.
  R_DATE-HIGH    =  SY-DATUM.
  R_DATE-LOW   =  V_DATUM_END.
  APPEND R_DATE.

ENDFORM.                    " f_get_last_month_date
*&---------------------------------------------------------------------*
*&      Form  f_additional_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_ADDITIONAL_DATA .
* addtional column.
  LOOP AT IT_PO.

    READ TABLE IT_LAST_PO WITH KEY MATNR = IT_PO-MATNR.
    IF SY-SUBRC EQ 0.
      MOVE: IT_LAST_PO-MATNR TO IT_ADD_LAST-MATNR,
            IT_LAST_PO-EBELP TO IT_ADD_LAST-EBELP,
            IT_LAST_PO-EBELN TO IT_ADD_LAST-EBELN,
            IT_LAST_PO-MEINS TO IT_ADD_LAST-MEINS,
            IT_LAST_PO-KNUMV TO IT_ADD_LAST-KNUMV,
            IT_LAST_PO-LIFNR TO IT_ADD_LAST-LIFNR.
      APPEND IT_ADD_LAST.
    ENDIF.
  ENDLOOP.

  IF IT_ADD_LAST[] IS NOT INITIAL.
    SELECT KNUMV  KPOSN  KSCHL KBETR  KWERT  WAERS
    INTO TABLE IT_KONV_LAST
    FROM KONV FOR ALL ENTRIES IN IT_ADD_LAST
    WHERE KNUMV  = IT_ADD_LAST-KNUMV.
  ENDIF.

ENDFORM.                    " f_additional_data
*&---------------------------------------------------------------------*
*&      Form  f_select_Data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_SELECT_DATA .
  CLEAR : P_VENDOR,
          P_ADDRESS,
          P_CITY,
          P_TELP,
          P_FAX,
          P_EBELN,
          P_DATE_PO,
          P_DATE_PRT,
          P_SUBTOTAL,
          P_DISCOUNT,
          P_TAX,
          P_TOTAL_ORDER,
          P_FREIGHT,
          P_VERKF,
          P_CONSIGNE01,
          P_CONSIGNE02,
          P_CONSIGNE03,
          P_CONSIGNE04,
          P_CONSIGNE05,
          P_CONSIGNE06,
          P_CONSIGNE07,
          P_TERM,
          P_CONDITION,
          P_SUP_REF,
          P_DATE_REF.

  REFRESH : IT_PO, IT_EKET, IT_KONV.
*  BREAK-POINT.
  SELECT
      A~EBELN A~EKORG A~WAERS A~AEDAT A~LIFNR A~KUNNR A~KNUMV A~IHREZ
      A~VERKF
      B~WERKS B~LGORT B~EBELP
      B~MENGE B~MEINS B~MATNR
      B~TXZ01 B~BEDNR B~BANFN
      B~MEINS B~MWSKZ
      APPENDING CORRESPONDING FIELDS OF TABLE IT_PO
      FROM EKKO AS A INNER JOIN EKPO AS B
             ON A~EBELN = B~EBELN
             WHERE A~EBELN = NAST-OBJKY+0(10) AND B~LOEKZ = ''.

  LOOP AT IT_PO WHERE EBELN = NAST-OBJKY+0(10).

    SELECT SINGLE ZTERM INTO IT_PO-ZTERM FROM EKKO WHERE EBELN = NAST-OBJKY+0(10).
    SELECT SINGLE TEXT1 INTO IT_PO-TEXT1 FROM T052U WHERE ZTERM = IT_PO-ZTERM.
    P_WAERS = IT_PO-WAERS.
    SELECT SINGLE ADRNR INTO IT_PO-ADRNR FROM KNA1 WHERE KUNNR = IT_PO-KUNNR.
    MODIFY IT_PO TRANSPORTING TEXT1 ADRNR WHERE EBELN = NAST-OBJKY+0(10).


    SELECT SINGLE EKGRP INTO P_TEMP FROM EKKO WHERE EBELN = IT_PO-EBELN.
    SELECT SINGLE EKNAM EKTEL INTO (P_CONTACT, P_TEL) FROM T024 WHERE EKGRP = P_TEMP.
    IF P_TEL <> SPACE.
      CONCATENATE '/ ' P_TEL INTO P_TEL1 SEPARATED BY SPACE.
    ENDIF.
  ENDLOOP.


  IF NOT IT_PO[] IS INITIAL.
    READ TABLE IT_PO INDEX 1.

    IF IT_PO-EKORG NE 'TPOI'.
      MESSAGE E398(00) WITH 'Only for PO IMPORT' '' '' ''.
      EXIT.
    ENDIF.


    SELECT EBELN EBELP EINDT INTO TABLE IT_EKET
    FROM EKET WHERE EBELN = IT_PO-EBELN.

    SELECT KNUMV  KPOSN  KSCHL
           KBETR  KWERT  WAERS
    INTO TABLE IT_KONV
    FROM KONV FOR ALL ENTRIES IN IT_PO
    WHERE KNUMV  = IT_PO-KNUMV.
  ENDIF.


* last po base on material number
  DATA: TEMP LIKE EKKO-EBELN.

  SORT IT_LAST_PO1 BY MATNR EBELN.
  TEMP = IT_PO-EBELN.
  SELECT
    A~EBELN A~AEDAT A~LIFNR A~KNUMV
    B~WERKS B~LGORT
    B~MENGE B~MEINS B~MATNR
    B~TXZ01 B~BEDNR B~BANFN
    B~MEINS B~MWSKZ B~EBELP
    APPENDING CORRESPONDING FIELDS OF TABLE IT_LAST_PO
    FROM EKKO AS A INNER JOIN EKPO AS B
           ON B~EBELN = A~EBELN
    WHERE B~MATNR  = IT_PO-MATNR AND
          B~EBELN  < TEMP AND B~LOEKZ = ''
    ORDER BY A~EBELN DESCENDING.

  "PERFORM F_GET_HIST_DOC.

ENDFORM.                    " f_select_Data
*&---------------------------------------------------------------------*
*&      Form  f_call_smartforms
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_CALL_SMARTFORMS .

  IF NOT *TNAPR-SFORM IS INITIAL.
    V_FORMNAME = *TNAPR-SFORM.
  ENDIF.

  PERFORM F_SMARTFORMS_CONFIGURE.


* Get Function Module name of SmartForms
* --------------------------------------
  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      FORMNAME           = V_FORMNAME
    IMPORTING
      FM_NAME            = V_FUNCNAME
    EXCEPTIONS
      NO_FORM            = 1
      NO_FUNCTION_MODULE = 2
      OTHERS             = 3.

  IF SY-SUBRC = 0.

    CALL FUNCTION V_FUNCNAME
      EXPORTING
        CONTROL_PARAMETERS = I_SSFCTRLOP
        OUTPUT_OPTIONS     = I_SSFCOMPOP
        S_VENDOR           = P_VENDOR
        S_ADDRESS          = P_ADDRESS
        S_CITY             = P_CITY
        S_TELP             = P_TELP
        S_FAX              = P_FAX
        S_EBELN            = P_EBELN
        S_DATE_PO          = P_DATE_PO
        S_DATE_PRT         = P_DATE_PRT
        S_SUBTOTAL         = P_SUBTOTAL
        S_DISCOUNT         = P_DISCOUNT
        S_TAX              = P_TAX
        S_FREIGHT          = P_FREIGHT
        S_INSSURANCE       = P_INSSURANCE
        S_TOTAL_ORDER      = P_TOTAL_ORDER
        S_FLAG_PREV        = I_SSFCTRLOP-PREVIEW
        S_VERKF            = P_VERKF
        S_CONSIGNE01       = P_CONSIGNE01
        S_CONSIGNE02       = P_CONSIGNE02
        S_CONSIGNE03       = P_CONSIGNE03
        S_CONSIGNE04       = P_CONSIGNE04
        S_CONSIGNE05       = P_CONSIGNE05
        S_CONSIGNE06       = P_CONSIGNE06
        S_CONSIGNE07       = P_CONSIGNE07
        S_TERM             = P_TERM
        S_PAY              = P_DATE_PAY
        S_CONDITION        = P_CONDITION
        S_SUP_REF          = P_SUP_REF
        S_DATE_REF         = P_DATE_REF
        P_WAERS            = P_WAERS
        LIFNR              = IT_PO-ADRNR
        S_DEV              = P_DEV
        EKNAM              = P_CONTACT
        EKTEL              = P_TEL1
        S_SHIPPING         = P_SHIPPING
        V_RETURN           = V_RETURN
        IF_HTEXT           = WA_HTEXT
        IS_OK              = IS_OK
        V_REV              = V_REV
      TABLES
        I_ZPO_LOCAL        = I_ZPO_LOCAL
        IT_HTEXT           = IT_HTEXT.

  ENDIF.
ENDFORM.                    " f_call_smartforms
*&---------------------------------------------------------------------*
*&      Form  f_smartforms_configure
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_SMARTFORMS_CONFIGURE .
  DATA: XDEVICE(10) TYPE C,
          XDIALOG.                 "Hilfsfeld Formular

  CLEAR: I_SSFCOMPOP.
  CLEAR: I_SSFCTRLOP.

  MOVE-CORRESPONDING NAST TO I_SSFCOMPOP.
  I_SSFCOMPOP-TDTITLE   = NAST-TDCOVTITLE.
  I_SSFCOMPOP-TDFAXUSER = NAST-USNAM.

*- Ausgabemedium festlegen --------------------------------------------*
  CASE NAST-NACHA.
    WHEN '2'.
      XDEVICE = 'TELEFAX'.
      IF NAST-TELFX EQ SPACE.
        XDIALOG = C_FLAG.
      ELSE.
        I_SSFCOMPOP-TDTELENUM  = NAST-TELFX.
        IF NOT NAST-TLAND IS INITIAL.
          I_SSFCOMPOP-TDTELELAND = NAST-TLAND.
        ENDIF.
      ENDIF.
    WHEN '3'.
      XDEVICE = 'TELETEX'.
      IF NAST-TELTX EQ SPACE.
        XDIALOG = C_FLAG.
      ELSE.
        I_SSFCOMPOP-TDTELENUM  = NAST-TELTX.
      ENDIF.
    WHEN '4'.
      XDEVICE = 'TELEX'.
      IF NAST-TELX1 EQ SPACE.
        XDIALOG = C_FLAG.
      ELSE.
        I_SSFCOMPOP-TDTELENUM  = NAST-TELX1.
      ENDIF.
    WHEN '5'.
* N/a
    WHEN OTHERS.
      XDEVICE = 'PRINTER'.
      IF NAST-LDEST EQ SPACE.
        XDIALOG = C_FLAG.
      ELSE.
        I_SSFCOMPOP-TDDEST   = NAST-LDEST.
      ENDIF.
  ENDCASE.

* Bei Probedruck, wenn das Medium keine Drucker ist.        " 361152
  IF NAST-SNDEX EQ C_FLAG AND
     NAST-NACHA NE '1'.                                     " 361152
    XDEVICE = 'PRINTER'.                                    " 361152
    IF NAST-LDEST EQ SPACE.                                 " 361152
      XDIALOG = C_FLAG.                                     " 361152
    ELSE.                                                   " 361152
      I_SSFCOMPOP-TDDEST   = NAST-LDEST.                    " 361152
    ENDIF.                                                  " 361152
  ENDIF.                                                    " 361152
  I_SSFCOMPOP-TDCOVER    = NAST-TDOCOVER.
  I_SSFCOMPOP-TDCOPIES   = NAST-ANZAL.
  I_SSFCOMPOP-TDDATASET  = NAST-DSNAM.
  I_SSFCOMPOP-TDSUFFIX1  = NAST-DSUF1.
  I_SSFCOMPOP-TDSUFFIX2  = NAST-DSUF2.
  I_SSFCOMPOP-TDSENDDATE = NAST-VSDAT.
  I_SSFCOMPOP-TDSENDTIME = NAST-VSURA.

  IF SY-XCODE = '9AUS'.
*   Set Display SmartForm directly
*   ------------------------------
    I_SSFCTRLOP-NO_DIALOG = C_FLAG.
    I_SSFCTRLOP-PREVIEW   = ' '.
    I_SSFCOMPOP-TDNOPRINT = SPACE.
    I_SSFCOMPOP-TDIMMED   = NAST-DIMME.
    I_SSFCOMPOP-TDDELETE  = NAST-DELET.
    I_SSFCOMPOP-TDNEWID   = C_FLAG.                         " 99282
  ELSEIF SY-XCODE = '9ANZ'.
    I_SSFCOMPOP-TDNOPRINT = C_FLAG.
    I_SSFCTRLOP-NO_DIALOG = C_FLAG.
    I_SSFCTRLOP-PREVIEW   = C_FLAG.
    I_SSFCOMPOP-TDIMMED   = SPACE.
    I_SSFCOMPOP-TDNEWID   = SPACE.                          " 99282
  ELSEIF SY-XCODE EQ 'DRPR' OR                              " 361152
           NAST-SNDEX EQ C_FLAG.                            " 361152

    I_SSFCOMPOP-TDNOPRINT  = SPACE.                         " 361152
    I_SSFCTRLOP-NO_DIALOG = C_FLAG.
    I_SSFCOMPOP-TDNOPREV  = C_FLAG.
    I_SSFCOMPOP-TDCOPIES   = 1.
    I_SSFCOMPOP-TDIMMED    = 'X'.
    I_SSFCOMPOP-TDDELETE   = NAST-DELET.
    I_SSFCOMPOP-TDNEWID    = C_FLAG.                        " 99282

  ELSE.
    I_SSFCTRLOP-NO_DIALOG = C_FLAG.
    I_SSFCTRLOP-PREVIEW   = C_FLAG.
    I_SSFCOMPOP-TDNOPRINT = 'X'.
    I_SSFCOMPOP-TDIMMED   = ' '.
    I_SSFCOMPOP-TDDELETE  = NAST-DELET.
    I_SSFCOMPOP-TDNEWID   = C_FLAG.                         " 99282
  ENDIF.

ENDFORM.                    " f_smartforms_configure
*&---------------------------------------------------------------------*
*&      Form  f_find_consignee
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_FIND_CONSIGNEE .
  DATA : LC_CODE TYPE CHAR10.


* find consigne code..with header text shiipping intruction.
  CLEAR : V_TDNAME.
  V_TDNAME = IT_PO-EBELN.
  REFRESH I_LINES.
  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      ID        = 'F06'
      LANGUAGE  = 'E'
      NAME      = V_TDNAME
      OBJECT    = 'EKKO'
    IMPORTING
      HEADER    = THEAD
    TABLES
      LINES     = I_LINES
    EXCEPTIONS
      ID        = 1
      LANGUAGE  = 2
      NAME      = 3
      NOT_FOUND = 4
      OBJECT    = 5.

  DELETE I_LINES
    WHERE  TDLINE EQ SPACE.

  LOOP AT I_LINES.
    CONCATENATE I_LINES-TDLINE ' '
    INTO  LC_CODE  SEPARATED BY SPACE.
  ENDLOOP.

  CONDENSE LC_CODE NO-GAPS.
  SELECT * INTO TABLE IT_ZMM_CON_TEXT_PO FROM ZMM_CON_TEXT_PO
  WHERE ZCODE = LC_CODE.

  READ TABLE IT_ZMM_CON_TEXT_PO WITH KEY ZNOURUT = '01'.
  IF SY-SUBRC EQ 0.
    P_CONSIGNE01 = IT_ZMM_CON_TEXT_PO-ZVAR.
  ENDIF.

  READ TABLE IT_ZMM_CON_TEXT_PO WITH KEY ZNOURUT = '02'.
  IF SY-SUBRC EQ 0.
    P_CONSIGNE02 = IT_ZMM_CON_TEXT_PO-ZVAR.
  ENDIF.

  READ TABLE IT_ZMM_CON_TEXT_PO WITH KEY ZNOURUT = '03'.
  IF SY-SUBRC EQ 0.
    P_CONSIGNE03 = IT_ZMM_CON_TEXT_PO-ZVAR.
  ENDIF.

  READ TABLE IT_ZMM_CON_TEXT_PO WITH KEY ZNOURUT = '04'.
  IF SY-SUBRC EQ 0.
    P_CONSIGNE04 = IT_ZMM_CON_TEXT_PO-ZVAR.
  ENDIF.

  READ TABLE IT_ZMM_CON_TEXT_PO WITH KEY ZNOURUT = '05'.
  IF SY-SUBRC EQ 0.
    P_CONSIGNE05 = IT_ZMM_CON_TEXT_PO-ZVAR.
  ENDIF.

  READ TABLE IT_ZMM_CON_TEXT_PO WITH KEY ZNOURUT = '06'.
  IF SY-SUBRC EQ 0.
    P_CONSIGNE06 = IT_ZMM_CON_TEXT_PO-ZVAR.
  ENDIF.


  READ TABLE IT_ZMM_CON_TEXT_PO WITH KEY ZNOURUT = '07'.
  IF SY-SUBRC EQ 0.
    P_CONSIGNE07 = IT_ZMM_CON_TEXT_PO-ZVAR.
  ENDIF.

ENDFORM.                    " f_find_consignee
*&---------------------------------------------------------------------*
*&      Form  f_get_term_payment
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_GET_TERM_PAYMENT .

  CLEAR : V_TDNAME.
  V_TDNAME = IT_PO-EBELN.
  REFRESH I_LINES.
  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      ID        = 'F07'
      LANGUAGE  = 'E'
      NAME      = V_TDNAME
      OBJECT    = 'EKKO'
    IMPORTING
      HEADER    = THEAD
    TABLES
      LINES     = I_LINES
    EXCEPTIONS
      ID        = 1
      LANGUAGE  = 2
      NAME      = 3
      NOT_FOUND = 4
      OBJECT    = 5.


  DELETE I_LINES
     WHERE  TDLINE EQ SPACE.

  CLEAR P_TERM.
  LOOP AT I_LINES.
    IF SY-TABIX = 1.
      CONCATENATE 'TOP: ' I_LINES-TDLINE
      INTO  P_TERM  SEPARATED BY SPACE.
    ELSE.
      CONCATENATE I_LINES-TDLINE ' '
      INTO  P_TERM  SEPARATED BY SPACE.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " f_get_term_payment
*&---------------------------------------------------------------------*
*&      Form  f_get_condition
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_GET_CONDITION .

  CLEAR : V_TDNAME.
  V_TDNAME = IT_PO-EBELN.
  REFRESH I_LINES.
  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      ID        = 'F05'
      LANGUAGE  = 'E'
      NAME      = V_TDNAME
      OBJECT    = 'EKKO'
    IMPORTING
      HEADER    = THEAD
    TABLES
      LINES     = I_LINES
    EXCEPTIONS
      ID        = 1
      LANGUAGE  = 2
      NAME      = 3
      NOT_FOUND = 4
      OBJECT    = 5.


  DELETE I_LINES
     WHERE  TDLINE EQ SPACE.

  READ TABLE I_LINES INDEX 1.
  CONCATENATE I_LINES-TDLINE ' '
  INTO  P_CONDITION  SEPARATED BY SPACE.

  READ TABLE I_LINES INDEX 2.
  P_SHIPPING = I_LINES-TDLINE.

ENDFORM.                    " f_get_condition

*&---------------------------------------------------------------------*
*&      Form  f_get_item_text
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_GET_ITEM_TEXT USING EBELN EBELP
                     CHANGING TEXT.

  CLEAR : V_TDNAME.
  CONCATENATE EBELN EBELP INTO V_TDNAME.
  CLEAR I_LINES.
  REFRESH I_LINES.
  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      ID        = 'F01'
      LANGUAGE  = 'E'
      NAME      = V_TDNAME
      OBJECT    = 'EKPO'
    IMPORTING
      HEADER    = THEAD
    TABLES
      LINES     = I_LINES
    EXCEPTIONS
      ID        = 1
      LANGUAGE  = 2
      NAME      = 3
      NOT_FOUND = 4
      OBJECT    = 5.


  DELETE I_LINES
     WHERE  TDLINE EQ SPACE.

  CLEAR TEXT.
  LOOP AT I_LINES.
    CONCATENATE TEXT I_LINES-TDLINE INTO TEXT SEPARATED BY SPACE.
  ENDLOOP.

ENDFORM.                    " f_get_term_payment


*--- PO return
FORM F_PO_RETURN.
  CLEAR: V_RETURN.
  DATA: BEGIN OF IT_RETURN OCCURS 0,
        EBELN LIKE EKPO-EBELN,
        RETPO LIKE EKPO-RETPO,
        END OF IT_RETURN.

  SELECT EBELN RETPO INTO TABLE IT_RETURN
    FROM EKPO WHERE EBELN = P_EBELN AND LOEKZ = ''.

ENDFORM.                    "f_po_return

*&---------------------------------------------------------------------*
*&      Form  F_GET_HEADER_TEXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_GET_HEADER_TEXT .

  CLEAR : V_TDNAME.
  V_TDNAME = IT_PO-EBELN.
  REFRESH I_LINES.
  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      ID        = 'F01'
      LANGUAGE  = 'E'
      NAME      = V_TDNAME
      OBJECT    = 'EKKO'
    IMPORTING
      HEADER    = THEAD
    TABLES
      LINES     = I_LINES
    EXCEPTIONS
      ID        = 1
      LANGUAGE  = 2
      NAME      = 3
      NOT_FOUND = 4
      OBJECT    = 5.


  DELETE I_LINES
     WHERE  TDLINE EQ SPACE.

  REFRESH IT_HTEXT.
  LOOP AT I_LINES.
    WA_HTEXT-TDLINE = I_LINES-TDLINE.
    APPEND WA_HTEXT TO IT_HTEXT.
  ENDLOOP.

  CLEAR IS_OK.
  IF IT_HTEXT[] IS NOT INITIAL.
    IS_OK = 'X'.
  ENDIF.
ENDFORM.                    " F_GET_HEADER_TEXT


*&---------------------------------------------------------------------*
*&      Form  F_GET_HIST_DOC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM F_GET_HIST_DOC .
  DATA : IS_CHANGE(1) TYPE C.

  REFRESH : ITHREV, ITIREV.
  CLEAR : WAREV, V_REV.

  SELECT CDHDR~OBJECTID AS NOPO
    CDHDR~CHANGENR AS NODOC
    INTO CORRESPONDING FIELDS OF TABLE ITHREV
    FROM CDHDR
    WHERE CDHDR~OBJECTCLAS = 'EINKBELEG'
    AND CDHDR~OBJECTID = NAST-OBJKY+0(10).

  LOOP AT ITHREV.
    REFRESH ITIREV.

    SELECT CDPOS~OBJECTID AS NOPO
      CDPOS~CHANGENR AS NODOC
      CDPOS~FNAME AS FNAME
      INTO CORRESPONDING FIELDS OF TABLE ITIREV
      FROM CDPOS
      WHERE CDPOS~OBJECTCLAS = 'EINKBELEG'
      AND CDPOS~OBJECTID = ITHREV-NOPO
      AND CDPOS~CHANGENR = ITHREV-NODOC.

    "CEK PERUBAHAN DATA
    "HARGA DAN QTY, TERMS OF PAYMENT, DESKRIPSI.
    CLEAR IS_CHANGE.
    LOOP AT ITIREV WHERE FNAME = 'F07 E'
      OR FNAME = 'MENGE'
      OR FNAME = 'ZTERM'
      OR FNAME = 'NETPR'
      OR FNAME = 'F01 E'.

      IS_CHANGE = 'X'.

    ENDLOOP.

    IF IS_CHANGE = 'X'.
      ITHREV-FLAG = 'X'.
    ENDIF.
    MODIFY ITHREV.

  ENDLOOP.

  DELETE ITHREV WHERE FLAG NE 'X'.
  DESCRIBE TABLE ITHREV LINES REV.


  IF REV <> 0.
    V_REV = REV.
    CONDENSE V_REV NO-GAPS.
    CONCATENATE 'rev' V_REV INTO V_REV.
  ENDIF.

ENDFORM.                    " F_GET_HIST_DOC


*&---------------------------------------------------------------------*
*&      Form  cek_output_type
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM CEK_OUTPUT_TYPE.
  DATA: WA_NAST LIKE NAST OCCURS 0  WITH HEADER LINE.
  DATA: V_MSG(100).
  CLEAR IS_SAME_OTYPE.
  SELECT SINGLE * INTO WA_NAST FROM NAST WHERE KAPPL = 'EF' AND VSTAT = '1' AND OBJKY = NAST-OBJKY. "AND KSCHL NE NAST-KSCHL.
  IF SY-SUBRC = 0 AND WA_NAST-KSCHL NE NAST-KSCHL.
    IS_SAME_OTYPE = 'X'.
    CONCATENATE 'Sudah pernah dicetak dengan output type' WA_NAST-KSCHL 'PO no:' NAST-OBJKY INTO V_MSG SEPARATED BY SPACE.
    MESSAGE V_MSG TYPE 'I'.
  ELSE.
    IS_SAME_OTYPE = ''.
  ENDIF.
ENDFORM.                    "cek_output_type
* ===== INCLUDE ZMMF_PO_IMPORT_TOP =====
*&---------------------------------------------------------------------*
*&  Include           ZMMF_PO_IMPORT_TOP
*&---------------------------------------------------------------------*

TABLES : LFA1, EKKO, EKPO, ADRC, MAKT, ZMM_CON_TEXT_PO.

TABLES: NAST,                          "Messages
        *NAST,                         "Messages
        TNAPR,                         "Programs & Forms
        ITCPO,                         "Communicationarea for Spool
        ARC_PARAMS,                    "Archive parameters
        TOA_DARA,                      "Archive parameters
        ADDR_KEY,                      "Adressnumber for ADDRESS
        *TNAPR,THEAD,                                       "#EC NEEDED
        T001W,
   T001L.

*TABLES:

DATA: I_NAST LIKE NAST.
DATA: I_SSFCOMPOP TYPE SSFCOMPOP.
DATA: I_SSFCTRLOP  TYPE SSFCTRLOP.
DATA: I_RECIPIENT          TYPE SWOTOBJID.
DATA: I_SENDER             TYPE SWOTOBJID.
DATA: I_ADDR_KEY           LIKE ADDR_KEY.

DATA: V_FORMNAME   TYPE TDSFNAME  VALUE 'ZMMF_PO_IMPORT_1',
      V_FUNCNAME   TYPE RS38L_FNAM.


DATA : I_LINES  LIKE TLINE  OCCURS 0 WITH HEADER LINE.

DATA: BEGIN OF I_TLINE OCCURS 0.
        INCLUDE STRUCTURE TLINE.
DATA: END OF I_TLINE.

DATA : V_LINE TYPE I.


DATA: RETCODE   LIKE SY-SUBRC.         "Returncode
DATA: REPEAT(1) TYPE C.
DATA: XSCREEN(1) TYPE C.


DATA : IT_HTEXT TYPE TABLE OF ZMMSTRTDLINE,
       WA_HTEXT TYPE ZMMSTRTDLINE,
       IS_OK(1) TYPE C.


DATA : BEGIN OF IT_PO OCCURS 0,
          EBELN LIKE EKKO-EBELN,
          EBELP LIKE EKPO-EBELP,
          EKORG LIKE EKKO-EKORG,
          VERKF LIKE EKKO-VERKF,
          WAERS LIKE EKKO-WAERS,
          LIFNR LIKE EKKO-LIFNR,
          KNUMV LIKE EKKO-KNUMV,
          IHREZ LIKE EKKO-IHREZ,
          AEDAT LIKE EKKO-AEDAT,
          MENGE LIKE EKPO-MENGE,
          ZTERM LIKE EKKO-ZTERM,
          TEXT1 LIKE T052U-TEXT1,
          MEINS LIKE EKPO-MEINS,
          MATNR LIKE EKPO-MATNR,
          TXZ01 LIKE EKPO-TXZ01,
          WERKS LIKE EKPO-WERKS,
          LGORT LIKE EKPO-LGORT,
          BEDNR LIKE EKPO-BEDNR,
          BANFN LIKE EKPO-BANFN,
          MWSKZ LIKE EKPO-MWSKZ,
          KUNNR LIKE EKKO-KUNNR,
          ADRNR LIKE KNA1-ADRNR,
       END OF IT_PO.

DATA : IT_LAST_PO LIKE IT_PO OCCURS 0 WITH HEADER LINE,
       IT_LAST_PO1 LIKE IT_PO OCCURS 0 WITH HEADER LINE.

DATA : BEGIN OF IT_EKET OCCURS 0,
       EBELN LIKE EKET-EBELN,
       EBELP LIKE EKET-EBELP,
       EINDT LIKE EKET-EINDT,
       END OF IT_EKET.

DATA : BEGIN OF IT_KONV OCCURS 0,
       KNUMV LIKE KONV-KNUMV,
       KPOSN LIKE KONV-KPOSN,
       KSCHL LIKE KONV-KSCHL,
       KBETR LIKE KONV-KBETR,
       KWERT LIKE KONV-KWERT,
       WAERS LIKE KONV-WAERS,
       DISC1 LIKE KONV-KBETR,    "ADD BY JALU 06.02.2013
       DISC2 LIKE KONV-KBETR,    "ADD BY JALU 06.02.2013
       END OF IT_KONV.

DATA : IT_KONV_LAST LIKE IT_KONV OCCURS 0 WITH HEADER LINE.

DATA : BEGIN OF IT_ADD_LAST OCCURS 0,
         MATNR LIKE EKPO-MATNR,
         EBELP LIKE EKPO-EBELP,
         EBELN LIKE EKPO-EBELN,
         MEINS LIKE EKPO-MEINS,
         KNUMV LIKE EKKO-KNUMV,
         LIFNR LIKE EKKO-LIFNR,
        END OF IT_ADD_LAST.

DATA : I_ZPO_LOCAL LIKE ZPO_LOCAL OCCURS 0 WITH HEADER LINE.

DATA :  P_VENDOR  TYPE CHAR30,
        P_ADDRESS TYPE CHAR50,
        P_CITY    TYPE CHAR50,
        P_TELP    TYPE CHAR25,
        P_FAX     TYPE CHAR25,
        P_SUP_REF TYPE CHAR30.

DATA :  P_EBELN    TYPE CHAR10,
        P_DATE_PO  TYPE CHAR10,
        P_DATE_PRT TYPE CHAR10,
        P_DATE_PAY TYPE CHAR25.

DATA :  P_SUBTOTAL TYPE CHAR15,
        P_DISCOUNT TYPE CHAR15,
        P_TAX      TYPE CHAR15,
        P_FREIGHT  TYPE CHAR15,
        P_INSSURANCE TYPE CHAR15,
        P_DEV  TYPE CHAR15,
        P_TOTAL_ORDER TYPE CHAR15.

DATA   : P_VERKF TYPE CHAR30.

"-CHANGE DOCUMENT
TYPES : BEGIN OF TYREV,
          NOPO TYPE CDOBJECTV,
          NODOC TYPE CDCHANGENR,
          FNAME TYPE FDNAME,
          FLAG(1) TYPE C,
        END OF TYREV.

DATA :  ITHREV TYPE TABLE OF TYREV WITH HEADER LINE,
        ITIREV TYPE TABLE OF TYREV WITH HEADER LINE,
        WAREV TYPE TYREV.

DATA   : C_FLAG(1) VALUE 'X'.
RANGES : R_KSCHL FOR KONV-KSCHL,
         R_DATE  FOR SY-DATUM.

DATA   : V_DATUM_END LIKE SY-DATUM.
DATA   : V_TDNAME    LIKE THEAD-TDNAME.

DATA : REV   TYPE I,
       V_REV(005).

DATA   : IT_ZMM_CON_TEXT_PO LIKE ZMM_CON_TEXT_PO OCCURS 0 WITH HEADER LINE.


DATA   :  P_CONSIGNE01 TYPE CHAR120,
          P_CONSIGNE02 TYPE CHAR120,
          P_CONSIGNE03 TYPE CHAR120,
          P_CONSIGNE04 TYPE CHAR120,
          P_CONSIGNE05 TYPE CHAR120,
          P_CONSIGNE06 TYPE CHAR120,
          P_CONSIGNE07 TYPE CHAR120.

DATA   :  P_TERM TYPE CHAR40,
          P_CONDITION TYPE CHAR40,
          P_SHIPPING TYPE CHAR40.

DATA   :  P_DATE_REF TYPE CHAR20,
          P_WAERS LIKE EKKO-WAERS.

DATA   :  P_CONTACT LIKE T024-EKNAM,
          P_TEL LIKE T024-EKTEL,
          P_TEL1 TYPE CHAR15,
          P_TEMP LIKE MARC-EKGRP.

DATA: V_RETURN(6).   "Additional title for Return Text

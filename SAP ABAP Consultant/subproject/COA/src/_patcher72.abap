REPORT ZTMPPATCH.
DATA: LT_SRC TYPE TABLE OF ABAPTXT255 WITH HEADER LINE,
      LT_OUT TYPE TABLE OF ABAPTXT255 WITH HEADER LINE.
DATA: N1 TYPE I, N2 TYPE I, N3 TYPE I, N4 TYPE I.
DATA: N5 TYPE I, N6 TYPE I, N7 TYPE I.
DATA: F_ORD TYPE C, F_CMP TYPE C.
DATA: LV_OK TYPE C, LV_MSG TYPE STRING.
DATA: L TYPE ABAPTXT255-LINE, W TYPE ABAPTXT255-LINE.
DATA: A1 TYPE ABAPTXT255-LINE, A2 TYPE ABAPTXT255-LINE.
DATA: A3 TYPE ABAPTXT255-LINE, A4 TYPE ABAPTXT255-LINE.
DATA: A5 TYPE ABAPTXT255-LINE, A6 TYPE ABAPTXT255-LINE.

CLEAR A1.
A1(46) = 'FORM GET_VALID_ORDER_FROM_MSEG USING P_CHARG C'.
A1+46(16) = 'HANGING P_AUFNR.'.
CLEAR A2.
A2(46) = 'FORM GET_VALID_COMPONENT_FROM_MSEG USING P_AUF'.
A2+46(20) = 'NR CHANGING P_CHARG.'.
CLEAR A3.
A3(46) = '        LT_CANC TYPE TABLE OF MSEG WITH HEADER'.
A3+46(6) = ' LINE.'.
CLEAR A4.
A4(30) = '      P_AUFNR = LT_MSEG-AUFNR.'.
CLEAR A5.
A5(46) = '    WHERE AUFNR = P_AUFNR AND BWART IN (''261'','.
A5+46(24) = ' ''262'') AND CHARG <> ''''.'.
CLEAR A6.
A6(46) = '    DELETE LT_MSEG WHERE SMBLN IS NOT INITIAL '.
A6+46(17) = 'OR BWART = ''262''.'.

CALL FUNCTION 'RPY_PROGRAM_READ'
  EXPORTING
    PROGRAM_NAME    = 'ZQMI_COA_F01'
    ONLY_SOURCE     = 'X'
  TABLES
    SOURCE_EXTENDED = LT_SRC
  EXCEPTIONS
    OTHERS          = 9.
IF SY-SUBRC <> 0.
  WRITE: / 'READ FAILED', SY-SUBRC.
  RETURN.
ENDIF.

LOOP AT LT_SRC.
  L = LT_SRC-LINE.
  IF L = A1.
    CLEAR W.
    W(46) = '* BKTXT dokumen GR (101) yang sedang di-trace.'.
    W+46(39) = ' Di-set oleh GET_VALID_ORDER_FROM_MSEG,'.
    PERFORM A USING W.
    CLEAR W.
    W(46) = '* dibaca GET_VALID_COMPONENT_FROM_MSEG. BKTXT '.
    W+46(39) = '= identitas transaksi / nomor roll, dan'.
    PERFORM A USING W.
    CLEAR W.
    W(46) = '* merupakan penghubung yang benar antara posti'.
    W+46(43) = 'ng 101 dan 261 dalam SATU production order.'.
    PERFORM A USING W.
    CLEAR W.
    W(37) = 'DATA: GV_TRACE_BKTXT TYPE MKPF-BKTXT.'.
    PERFORM A USING W.
    CLEAR W.
    PERFORM A USING W.
    N1 = N1 + 1.
    F_ORD = 'X'.
    PERFORM A USING L.
    CONTINUE.
  ENDIF.
  IF L = A2.
    PERFORM A USING L.
    CLEAR W.
    W(34) = '  DATA: BEGIN OF LT_MKPF OCCURS 0,'.
    PERFORM A USING W.
    CLEAR W.
    W(32) = '          MBLNR LIKE MKPF-MBLNR,'.
    PERFORM A USING W.
    CLEAR W.
    W(32) = '          MJAHR LIKE MKPF-MJAHR,'.
    PERFORM A USING W.
    CLEAR W.
    W(32) = '          BKTXT LIKE MKPF-BKTXT,'.
    PERFORM A USING W.
    CLEAR W.
    W(23) = '        END OF LT_MKPF.'.
    PERFORM A USING W.
    N4 = N4 + 1.
    F_CMP = 'X'.
    CONTINUE.
  ENDIF.
  IF F_ORD = 'X' AND L = A3.
    PERFORM A USING L.
    CLEAR W.
    W(35) = '  DATA: LV_COMBINE LIKE AFPO-AUFNR.'.
    PERFORM A USING W.
    N3 = N3 + 1.
    CONTINUE.
  ENDIF.
  IF F_ORD = 'X' AND L = A4.
    PERFORM A USING L.
    CLEAR W.
    PERFORM A USING W.
    CLEAR W.
    W(46) = '      " Fix A (user 18/07/2026): ambil BKTXT d'.
    W+46(28) = 'okumen GR (101) ini, dipakai'.
    PERFORM A USING W.
    CLEAR W.
    W(46) = '      " GET_VALID_COMPONENT_FROM_MSEG untuk me'.
    W+46(37) = 'milih komponen 261 pasangan roll ini.'.
    PERFORM A USING W.
    CLEAR W.
    W(46) = '      " Bukti: order 100000072887 punya 8 post'.
    W+46(36) = 'ing 261 / 4 batch berbeda, dibedakan'.
    PERFORM A USING W.
    CLEAR W.
    W(46) = '      " HANYA oleh BKTXT. Logic lama ambil MBL'.
    W+46(38) = 'NR terbesar - salah roll tanpa gejala.'.
    PERFORM A USING W.
    CLEAR W.
    W(45) = '      SELECT SINGLE BKTXT INTO GV_TRACE_BKTXT'.
    PERFORM A USING W.
    CLEAR W.
    W(17) = '        FROM MKPF'.
    PERFORM A USING W.
    CLEAR W.
    W(35) = '        WHERE MBLNR = LT_MSEG-MBLNR'.
    PERFORM A USING W.
    CLEAR W.
    W(36) = '          AND MJAHR = LT_MSEG-MJAHR.'.
    PERFORM A USING W.
    CLEAR W.
    PERFORM A USING W.
    CLEAR W.
    W(46) = '      " Fix B (user 18/07/2026): resolve COLLE'.
    W+46(37) = 'CTIVE ORDER. AUFNR dari MSEG 101 bisa'.
    PERFORM A USING W.
    CLEAR W.
    W(46) = '      " order referensi (mis. A29000002540) ya'.
    W+46(40) = 'ng TIDAK punya komponen 261 sama sekali;'.
    PERFORM A USING W.
    CLEAR W.
    W(46) = '      " order asli dicari via AFPO-MILL_OC_AUF'.
    W+46(35) = 'NR_U. Tanpa ini tracing MATI di hop'.
    PERFORM A USING W.
    CLEAR W.
    W(46) = '      " pertama sehingga MIC level Base Film ('.
    W+46(29) = 'mis. PALZTH00) selalu kosong.'.
    PERFORM A USING W.
    CLEAR W.
    W(23) = '      CLEAR LV_COMBINE.'.
    PERFORM A USING W.
    CLEAR W.
    W(41) = '      SELECT SINGLE AUFNR INTO LV_COMBINE'.
    PERFORM A USING W.
    CLEAR W.
    W(17) = '        FROM AFPO'.
    PERFORM A USING W.
    CLEAR W.
    W(40) = '        WHERE MILL_OC_AUFNR_U = P_AUFNR.'.
    PERFORM A USING W.
    CLEAR W.
    W(46) = '      IF SY-SUBRC = 0 AND LV_COMBINE IS NOT IN'.
    W+46(6) = 'ITIAL.'.
    PERFORM A USING W.
    CLEAR W.
    W(29) = '        P_AUFNR = LV_COMBINE.'.
    PERFORM A USING W.
    CLEAR W.
    W(12) = '      ENDIF.'.
    PERFORM A USING W.
    N2 = N2 + 1.
    CLEAR F_ORD.
    CONTINUE.
  ENDIF.
  IF F_CMP = 'X' AND L = A5.
    CLEAR W.
    W(46) = '    WHERE AUFNR = P_AUFNR AND BWART IN (''261'','.
    W+46(38) = ' ''262'', ''901'', ''902'') AND CHARG <> ''''.'.
    PERFORM A USING W.
    N5 = N5 + 1.
    CONTINUE.
  ENDIF.
  IF F_CMP = 'X' AND L = A6.
    CLEAR W.
    W(46) = '    DELETE LT_MSEG WHERE SMBLN IS NOT INITIAL '.
    W+46(34) = 'OR BWART = ''262'' OR BWART = ''902''.'.
    PERFORM A USING W.
    N6 = N6 + 1.
    CLEAR W.
    PERFORM A USING W.
    CLEAR W.
    W(46) = '    " Fix BKTXT (user 18/07/2026): buang kompo'.
    W+46(40) = 'nen yang BUKAN milik transaksi/roll yang'.
    PERFORM A USING W.
    CLEAR W.
    W(46) = '    " sama dengan dokumen 101-nya. Satu order '.
    W+46(40) = 'bisa punya banyak roll, dan BKTXT adalah'.
    PERFORM A USING W.
    CLEAR W.
    W(46) = '    " satu-satunya pembeda. Kalau BKTXT 101 ko'.
    W+46(34) = 'song (data lama), filter dilewati.'.
    PERFORM A USING W.
    CLEAR W.
    W(46) = '    IF GV_TRACE_BKTXT IS NOT INITIAL AND LT_MS'.
    W+46(20) = 'EG[] IS NOT INITIAL.'.
    PERFORM A USING W.
    CLEAR W.
    W(37) = '      CLEAR LT_MKPF. REFRESH LT_MKPF.'.
    PERFORM A USING W.
    CLEAR W.
    W(46) = '      SELECT MBLNR MJAHR BKTXT INTO TABLE LT_M'.
    W+46(3) = 'KPF'.
    PERFORM A USING W.
    CLEAR W.
    W(17) = '        FROM MKPF'.
    PERFORM A USING W.
    CLEAR W.
    W(34) = '        FOR ALL ENTRIES IN LT_MSEG'.
    PERFORM A USING W.
    CLEAR W.
    W(35) = '        WHERE MBLNR = LT_MSEG-MBLNR'.
    PERFORM A USING W.
    CLEAR W.
    W(36) = '          AND MJAHR = LT_MSEG-MJAHR.'.
    PERFORM A USING W.
    CLEAR W.
    W(34) = '      SORT LT_MKPF BY MBLNR MJAHR.'.
    PERFORM A USING W.
    CLEAR W.
    W(22) = '      LOOP AT LT_MSEG.'.
    PERFORM A USING W.
    CLEAR W.
    W(22) = '        CLEAR LT_MKPF.'.
    PERFORM A USING W.
    CLEAR W.
    W(46) = '        READ TABLE LT_MKPF WITH KEY MBLNR = LT'.
    W+46(11) = '_MSEG-MBLNR'.
    PERFORM A USING W.
    CLEAR W.
    W(46) = '                                    MJAHR = LT'.
    W+46(26) = '_MSEG-MJAHR BINARY SEARCH.'.
    PERFORM A USING W.
    CLEAR W.
    W(46) = '        IF SY-SUBRC <> 0 OR LT_MKPF-BKTXT <> G'.
    W+46(14) = 'V_TRACE_BKTXT.'.
    PERFORM A USING W.
    CLEAR W.
    W(25) = '          DELETE LT_MSEG.'.
    PERFORM A USING W.
    CLEAR W.
    W(14) = '        ENDIF.'.
    PERFORM A USING W.
    CLEAR W.
    W(14) = '      ENDLOOP.'.
    PERFORM A USING W.
    CLEAR W.
    W(10) = '    ENDIF.'.
    PERFORM A USING W.
    N7 = N7 + 1.
    CLEAR F_CMP.
    CONTINUE.
  ENDIF.
  PERFORM A USING L.
ENDLOOP.

IF N1 <> 1 OR N2 <> 1 OR N3 <> 1 OR N4 <> 1
   OR N5 <> 1 OR N6 <> 1 OR N7 <> 1.
  WRITE: / 'ABORT-ANCHOR MISMATCH'.
  WRITE: / N1, N2, N3, N4, N5, N6, N7.
  RETURN.
ENDIF.

CALL FUNCTION 'Z_RFC_PROGRAM_UPDATE'
  EXPORTING
    IV_PROGRAM_NAME = 'ZQMI_COA_F01'
    IV_PACKAGE      = '$TMP'
    IV_CORRNUMBER   = ' '
  IMPORTING
    EV_SUCCESS      = LV_OK
    EV_MESSAGE      = LV_MSG
  TABLES
    IT_SOURCE       = LT_OUT.
DESCRIBE TABLE LT_OUT LINES N1.
WRITE: / 'SUCCESS=', LV_OK, ' LINES=', N1.
WRITE: / 'MSG=', LV_MSG.

FORM A USING P TYPE ABAPTXT255-LINE.
  LT_OUT-LINE = P.
  APPEND LT_OUT.
ENDFORM.
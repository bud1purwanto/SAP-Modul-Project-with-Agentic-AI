REPORT ZTMP_PATCH_COHVPI.
DATA: LT_SRC TYPE TABLE OF ABAPTXT255 WITH HEADER LINE.
DATA: LV_OK TYPE C, LV_MSG TYPE STRING.

* Kita baca program eksisting dulu
CALL FUNCTION 'RPY_PROGRAM_READ'
  EXPORTING
    PROGRAM_NAME     = 'ZPPI_COHVPI'
    WITH_INCLUDELIST = ' '
  TABLES
    SOURCE_EXTENDED  = LT_SRC.

* Edit logic
LOOP AT LT_SRC.
  IF LT_SRC-LINE CS 'IF ITAB-ERR = ''X''.'.
    LT_SRC-LINE = '    IF ITAB-ERR = ''X''.'.
    MODIFY LT_SRC.
    LT_SRC-LINE = '      L_RES = ''ERROR''.'.
    APPEND LT_SRC.
    LT_SRC-LINE = '    ELSEIF P_TEST = ''X''.'.
    APPEND LT_SRC.
    LT_SRC-LINE = '      L_RES = ''TEST RUN''.'.
    APPEND LT_SRC.
    LT_SRC-LINE = '    ELSEIF ITAB-INDC = WARNING.'.
    APPEND LT_SRC.
    LT_SRC-LINE = '      L_RES = ''SKIPPED''.'.
    APPEND LT_SRC.
    LT_SRC-LINE = '    ELSE.'.
    APPEND LT_SRC.
    LT_SRC-LINE = '      L_RES = ''OK''.'.
    APPEND LT_SRC.
    LT_SRC-LINE = '    ENDIF.'.
    APPEND LT_SRC.
    " Hapus 3 baris setelahnya (L_RES = 'ERROR', ELSE, OK, ENDIF)
    " ini butuh logic index yang lebih presisi
  ENDIF.
ENDLOOP.

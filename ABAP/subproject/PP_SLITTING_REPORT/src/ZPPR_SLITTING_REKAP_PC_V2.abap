*----------------------------------------------------------------------*
* Report  ZPPR_SLITTING_REKAP_PC_V2
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
* Description      : Report Slitting
*                    Enhancement
* Application Area - PP
* ABAPer           - William
* Date             - January, 10 2013
*----------------------------------------------------------------------*
* Amendment History                                                    *
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
* Ref | Date     | Programmer  | Correction | Description              *
* ~~~   ~~~~~~~~   ~~~~~~~~~~    ~~~~~~~~~~   ~~~~~~~~~~~~~~~~~~~~~~~~~*
* 001 | ##.##.## |             |            | Program created          *
* 002 | 28.05.20 | Fathir      |            | Fix get data untuk       *
*     |          |             |            | transfer Mat FGS to Mat FGS
*----------------------------------------------------------------------*

INCLUDE ZPPR_SLITTING_REKAP_PC_V2_TOP           .    " global Data
INCLUDE <ICON>.
INCLUDE ZABAPALV.                                    " Include Function ALV.
INCLUDE ZPPR_SLITTING_REKAP_PC_V2_O01           .  " PBO-Modules
INCLUDE ZPPR_SLITTING_REKAP_PC_V2_I01           .  " PAI-Modules
INCLUDE ZPPR_SLITTING_REKAP_PC_V2_F01           .  " FORM-Routines

***************
INITIALIZATION.
***************
  PERFORM F_INITITIALIZATION.

******************************************************
AT SELECTION-SCREEN ON VALUE-REQUEST FOR ZLINE-LOW.
******************************************************
  PERFORM F_GET_VALUES_REQUEST CHANGING ZLINE-LOW.

AT SELECTION-SCREEN OUTPUT.
  IF MATKL[] IS INITIAL.
    MATKL-SIGN = 'I'.
    MATKL-OPTION = 'BT'.
    MATKL-LOW  = '300001'.
    MATKL-HIGH = '300024'.  " Modified by William at 24.07.2022 (OPP7 CPP1)
    APPEND MATKL.
  ENDIF.
*  Diminta jgn di grey (7 Januari 2013)
*  LOOP AT SCREEN.
*    IF SCREEN-NAME = 'MATKL-LOW'.
*      SCREEN-INPUT = 0.
*      MODIFY SCREEN.
*    ENDIF.
*    IF SCREEN-NAME = 'MATKL-HIGH'.
*      SCREEN-INPUT = 0.
*      MODIFY SCREEN.
*    ENDIF.
*  ENDLOOP.


*-- Bagus 8 jan 13
* kalo ga dapet otorisasi radio button yang olap di hide
  AUTHORITY-CHECK OBJECT 'Z_OLAP' ID 'ZOLAP' FIELD '1'.
  IF SY-SUBRC NE 0.
    LOOP AT SCREEN.
      IF SCREEN-NAME = 'V_RB2'.
        SCREEN-ACTIVE = '0'.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.
****-------------****


*******************
START-OF-SELECTION.
*******************
  CLEAR: RIBUAN, PULUHAN.
  PERFORM GET_DEC_NOTATION CHANGING RIBUAN PULUHAN.
  PERFORM DEFINE_AUART.
*******  PERFORM get_data.

  IF V_RB1 = 'X'.
    " ADD VALIDASI ROLE NEW COMPANY
    IF WERKS-HIGH IS INITIAL.
      LOOP AT WERKS.
        AUTHORITY-CHECK OBJECT 'Z_WERKS' ID 'ZWERKS' FIELD WERKS-LOW.
        IF SY-SUBRC NE 0.
          MESSAGE 'No Authorization' TYPE 'E'.
        ENDIF.
      ENDLOOP.
    ELSE.
      AUTHORITY-CHECK OBJECT 'Z_WERKS'
       ID 'ZWERKS' FIELD WERKS-LOW
       ID 'ZWERKS' FIELD WERKS-HIGH.
      IF SY-SUBRC NE 0.
        MESSAGE 'No Authorization' TYPE 'E'.
      ENDIF.
    ENDIF.
    " END VALIDASI ROLE NEW COMPANY
    PERFORM GET_DATA.
    "ADDED BY FATHIR ON 28.05.2020
    " Get data SO, jika ada batch GR 101 (hanya untuk report)
    UNASSIGN <FS_MSEG>.
    READ TABLE IT_MSEG ASSIGNING <FS_MSEG> WITH KEY BWART = '101'.
    IF SY-SUBRC = 0.
      PERFORM F_GETSO.
    ENDIF.

    PERFORM TO_SCREEN.
  ELSE.
    AUTHORITY-CHECK OBJECT 'ZOLAP'
             ID 'ACTVT' FIELD '01'
             ID 'ZTCODE' FIELD 'ZPP016N'.
    IF SY-SUBRC <> 0.
      MESSAGE 'No Authorization to download data...!'  TYPE 'I'. "#EC NOTEXT
      EXIT.
    ELSE.
      DATA: CON_NAME LIKE DBCON-CON_NAME.
      SELECT SINGLE CON_NAME
        INTO CON_NAME
        FROM DBCON
       WHERE CON_NAME = 'TRIASDB04'.
      IF SY-SUBRC NE 0.
        MESSAGE 'Connection TRIASDB04 not found!'  TYPE 'I'. "#EC NOTEXT
        EXIT.
      ELSE.
        PERFORM GET_DATA.
        UNASSIGN <FS_MSEG>.
        " Modified by William at 20.10.2020 (Repairing get data slitting)
*        PERFORM FILL_SO.
        READ TABLE IT_MSEG ASSIGNING <FS_MSEG> WITH KEY BWART = '101'.
        IF SY-SUBRC = 0.
          PERFORM F_GETSO.
        ENDIF.
        " End modified by William at 20.10.2020 (Repairing get data slitting)
        UNASSIGN <FS_MSEG>.
        READ TABLE IT_MSEG ASSIGNING <FS_MSEG> INDEX 1.
        IF SY-SUBRC = 0.
          PERFORM WRITE_DATA.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.
*******************
END-OF-SELECTION.
*******************
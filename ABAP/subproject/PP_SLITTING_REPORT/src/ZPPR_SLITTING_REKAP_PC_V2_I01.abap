*&---------------------------------------------------------------------*
*&  Include           ZPPR_SLITTING_REKAP_PC_V2_I01
*&---------------------------------------------------------------------*

*&SPWIZARD: INPUT MODULE FOR TC 'TC_CRIT'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: PROCESS USER COMMAND
MODULE TC_CRIT_USER_COMMAND INPUT.
  OK_CODE = SY-UCOMM.
  PERFORM USER_OK_TC USING    'TC_CRIT'
                              'IT_CRIT'
                              ' '
                     CHANGING OK_CODE.
  SY-UCOMM = OK_CODE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE USER_COMMAND_0100 INPUT.
  CASE SY-UCOMM.
    WHEN  'STOP'.
      SET SCREEN 0.
    WHEN  'PRINT'.
      PERFORM PRINT_GRADE.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE USER_COMMAND_0200 INPUT.
  CASE SY-UCOMM.
    WHEN  'STOP'.
      SET SCREEN 0.
    WHEN  'PRINT'.
      PERFORM PRINT_SHIFT.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0200  INPUT

*&SPWIZARD: INPUT MODULE FOR TC 'TC_SHIFT'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: PROCESS USER COMMAND
MODULE TC_SHIFT_USER_COMMAND INPUT.
  OK_CODE = SY-UCOMM.
  PERFORM USER_OK_TC USING    'TC_SHIFT'
                              'IT_SHIFT'
                              ' '
                     CHANGING OK_CODE.
  SY-UCOMM = OK_CODE.
ENDMODULE.

*&SPWIZARD: INPUT MODULE FOR TC 'TC_SALES'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: PROCESS USER COMMAND
MODULE TC_SALES_USER_COMMAND INPUT.
  OK_CODE = SY-UCOMM.
  PERFORM USER_OK_TC USING    'TC_SALES'
                              'IT_DATS'
                              ' '
                     CHANGING OK_CODE.
  SY-UCOMM = OK_CODE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0300  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE USER_COMMAND_0300 INPUT.
  CASE SY-UCOMM.
    WHEN  'BUT1'.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN  'BUT2'.
      PERFORM DOWNLOAD_SALES.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0300  INPUT
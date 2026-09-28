*&---------------------------------------------------------------------*
*&  Include           ZPPR_SLITTING_REKAP_PC_V2_O01
*&---------------------------------------------------------------------*

*&SPWIZARD: OUTPUT MODULE FOR TC 'TC_CRIT'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: UPDATE LINES FOR EQUIVALENT SCROLLBAR
MODULE TC_CRIT_CHANGE_TC_ATTR OUTPUT.
  DESCRIBE TABLE IT_CRIT LINES TC_CRIT-LINES.
ENDMODULE.

*&SPWIZARD: OUTPUT MODULE FOR TC 'TC_CRIT'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: GET LINES OF TABLECONTROL
MODULE TC_CRIT_GET_LINES OUTPUT.
  G_TC_CRIT_LINES = SY-LOOPC.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE STATUS_0100 OUTPUT.
  SET PF-STATUS 'GRADE'.
  SET TITLEBAR  '100'.
ENDMODULE.                 " STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE STATUS_0200 OUTPUT.
  SET PF-STATUS 'SHIFT'.
  SET TITLEBAR '200'.
ENDMODULE.                 " STATUS_0200  OUTPUT

*&SPWIZARD: OUTPUT MODULE FOR TC 'TC_SHIFT'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: UPDATE LINES FOR EQUIVALENT SCROLLBAR
MODULE TC_SHIFT_CHANGE_TC_ATTR OUTPUT.
  DESCRIBE TABLE IT_SHIFT LINES TC_SHIFT-LINES.
ENDMODULE.

*&SPWIZARD: OUTPUT MODULE FOR TC 'TC_SHIFT'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: GET LINES OF TABLECONTROL
MODULE TC_SHIFT_GET_LINES OUTPUT.
  G_TC_SHIFT_LINES = SY-LOOPC.
ENDMODULE.

*&SPWIZARD: OUTPUT MODULE FOR TC 'TC_SALES'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: UPDATE LINES FOR EQUIVALENT SCROLLBAR
MODULE TC_SALES_CHANGE_TC_ATTR OUTPUT.
  DESCRIBE TABLE IT_DATS LINES TC_SALES-LINES.
ENDMODULE.

*&SPWIZARD: OUTPUT MODULE FOR TC 'TC_SALES'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: GET LINES OF TABLECONTROL
MODULE TC_SALES_GET_LINES OUTPUT.
  G_TC_SALES_LINES = SY-LOOPC.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0300  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE STATUS_0300 OUTPUT.
  SET PF-STATUS 'ZSTAT'.
  SET TITLEBAR 'SALES'.
ENDMODULE.                 " STATUS_0300  OUTPUT
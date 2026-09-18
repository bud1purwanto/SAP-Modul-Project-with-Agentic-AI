*&---------------------------------------------------------------------*
*& Report     :  ZMAP_COA                                              *
*& Appl. Area :  QM / SD                                               *
*& Description:  Main Dispatcher Menu for COA Mapping                  *
*&---------------------------------------------------------------------*

REPORT ZMAP_COA.

SELECTION-SCREEN BEGIN OF BLOCK PARAMETER WITH FRAME TITLE TEXT-001.
PARAMETERS: RB_MIC   RADIOBUTTON GROUP RB DEFAULT 'X',
            RB_BATCH RADIOBUTTON GROUP RB.
SELECTION-SCREEN END OF BLOCK PARAMETER.

START-OF-SELECTION.
  IF RB_MIC EQ 'X'.
    SUBMIT ZMAP_COA_MIC VIA SELECTION-SCREEN AND RETURN.
  ELSEIF RB_BATCH EQ 'X'.
    SUBMIT ZMAP_COA_BATCH VIA SELECTION-SCREEN AND RETURN.
  ENDIF.
END-OF-SELECTION.

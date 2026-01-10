************************************************************************
*   Program name: Z_DYNAMIC_CONVERSION
*   Description : Dynamic Alpha Conversion
*
*   Created   by: George Drakos
*
************************************************************************
REPORT z_dynamic_conversion.

*&---------------------------------------------------------------------*
*& EXECUTABLE CODE
*&---------------------------------------------------------------------*
START-OF-SELECTION.

  DATA(vbeln) = CONV vbak-vbeln('12345').

  zcl_abap_projects=>alpha_conversion( EXPORTING iv_input  = vbeln
                                                 im_alpha  = zcl_abap_projects=>s_alpha_conversion-in
                                       IMPORTING ev_output = vbeln ).

  zcl_abap_projects=>alpha_conversion( EXPORTING iv_input  = vbeln
                                                 im_alpha  = zcl_abap_projects=>s_alpha_conversion-out
                                       IMPORTING ev_output = vbeln ).

END-OF-SELECTION.

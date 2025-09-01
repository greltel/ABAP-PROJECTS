************************************************************************
*   Program name: Z_DYNAMIC_CONVERSION
*   Description : Dynamic Alpha Conversion
*
*   Created   by: George Drakos
*
************************************************************************
REPORT z_dynamic_conversion.

*&---------------------------------------------------------------------*
*& Class LCL_CONVERTION_CLASS DEFINITION
*&---------------------------------------------------------------------*
CLASS lcl_convertion_class DEFINITION CREATE PUBLIC FINAL.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ENUM t_alpha_conversion STRUCTURE s_alpha_conversion BASE TYPE char1,
        in    VALUE 1,
        out   VALUE 2,
        other VALUE IS INITIAL,
      END OF ENUM t_alpha_conversion STRUCTURE s_alpha_conversion.

    CLASS-METHODS:

      alpha_conversion IMPORTING VALUE(iv_input)  TYPE any
                                 im_alpha         TYPE lcl_convertion_class=>t_alpha_conversion
                       EXPORTING VALUE(ev_output) TYPE any.

ENDCLASS.

*&---------------------------------------------------------------------*
*& EXECUTABLE CODE
*&---------------------------------------------------------------------*
START-OF-SELECTION.

  DATA(vbeln) = CONV vbak-vbeln('12345').

  lcl_convertion_class=>alpha_conversion( EXPORTING iv_input  = vbeln
                                                    im_alpha  = lcl_convertion_class=>s_alpha_conversion-in
                                          IMPORTING ev_output = vbeln ).

  lcl_convertion_class=>alpha_conversion( EXPORTING iv_input  = vbeln
                                                    im_alpha  = lcl_convertion_class=>s_alpha_conversion-out
                                          IMPORTING ev_output = vbeln ).

  BREAK-POINT.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*& Class LCL_CONVERTION_CLASS IMPLEMENTATION
*&---------------------------------------------------------------------*
CLASS lcl_convertion_class IMPLEMENTATION.

  METHOD alpha_conversion.

    "Initialize output value to input value.
    ev_output = iv_input.

    DATA(lo_elem) = CAST cl_abap_elemdescr( cl_abap_elemdescr=>describe_by_data( iv_input ) ).

    "If the data has no DDIC structure or no Conversion Routine then Exit
    IF NOT lo_elem->is_ddic_type( )
       OR lo_elem->get_ddic_field( )-convexit IS INITIAL.
      RETURN.
    ENDIF.

    "Alpha Conversion
    DATA(function_conversion) = to_upper( condense( |CONVERSION_EXIT_{ lo_elem->get_ddic_field( )-convexit }_{ SWITCH string( im_alpha
                                                                                                               WHEN lcl_convertion_class=>s_alpha_conversion-in  THEN 'INPUT'
                                                                                                               WHEN lcl_convertion_class=>s_alpha_conversion-out THEN 'OUTPUT'
                                                                                                               ELSE 'INPUT'"ELSE THROW EXCEPTION
                                                                                                              ) } | ) ).
    TRY.
        CALL FUNCTION function_conversion
          EXPORTING
            input         = iv_input
          IMPORTING
            output        = ev_output
          EXCEPTIONS
            error_message = 1
            OTHERS        = 2.
      CATCH cx_sy_dyn_call_illegal_type cx_sy_dyn_call_illegal_func.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.

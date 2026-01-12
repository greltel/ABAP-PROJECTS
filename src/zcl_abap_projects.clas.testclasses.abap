*"* use this source file for your ABAP unit test classes

CLASS ltc_external_methods DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.

    TYPES: BEGIN OF ty_dummy_data,
             id   TYPE i,
             text TYPE string,
           END OF ty_dummy_data.
    TYPES: tt_dummy_data TYPE STANDARD TABLE OF ty_dummy_data WITH EMPTY KEY.

    METHODS setup.

    METHODS:
      test_count_single_multiple FOR TESTING RAISING cx_static_check,
      test_alpha_conversion      FOR TESTING RAISING cx_static_check,
      test_split_table           FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_external_methods IMPLEMENTATION.

  METHOD setup.

  ENDMETHOD.

  METHOD test_count_single_multiple.

    DATA: lt_data TYPE tt_dummy_data.

    lt_data = VALUE #( ( id = 1 text = 'A' )
                       ( id = 2 text = 'B' )
                       ( id = 3 text = 'A' )
                       ( id = 4 text = 'C' ) ).

    zcl_abap_projects=>count_single_multiple_values(
      EXPORTING
        im_table           = lt_data
        im_column_name     = 'TEXT'
      IMPORTING
        ex_unique_values   = data(lr_unique)
        ex_multiple_values = data(lr_multiple) ).


    ASSIGN lr_unique->* TO FIELD-SYMBOL(<fs_unique>).

    cl_aunit_assert=>assert_equals(
      act = lines( <fs_unique> )
      exp = 2
      msg = 'Unique values count should be 2 (B and C)').

    ASSIGN lr_multiple->* TO FIELD-SYMBOL(<fs_multiple>).
    cl_aunit_assert=>assert_equals(
      act = lines( <fs_multiple> )
      exp = 1
      msg = 'Multiple values count should be 1 (A)' ).

  ENDMETHOD.

  METHOD test_alpha_conversion.

    DATA: lv_vbeln_input  TYPE vbeln VALUE '123',
          lv_vbeln_output TYPE vbeln.

    zcl_abap_projects=>alpha_conversion(
      EXPORTING
        iv_input = lv_vbeln_input
        im_alpha = zcl_abap_projects=>s_alpha_conversion-in
      IMPORTING
        ev_output = lv_vbeln_output ).

    cl_aunit_assert=>assert_equals(
      act = lv_vbeln_output
      exp = '0000000123'
      msg = 'ALPHA IN conversion failed' ).

    CLEAR lv_vbeln_output.
    lv_vbeln_input = '0000000123'.

    zcl_abap_projects=>alpha_conversion(
      EXPORTING
        iv_input = lv_vbeln_input
        im_alpha = zcl_abap_projects=>s_alpha_conversion-out
      IMPORTING
        ev_output = lv_vbeln_output ).

    cl_aunit_assert=>assert_equals(
      act = lv_vbeln_output
      exp = '123'
      msg = 'ALPHA OUT conversion failed' ).

    DATA: lv_string_in  TYPE string VALUE 'TEST',
          lv_string_out TYPE string.

    zcl_abap_projects=>alpha_conversion(
      EXPORTING
        iv_input = lv_string_in
        im_alpha = zcl_abap_projects=>s_alpha_conversion-in
      IMPORTING
        ev_output = lv_string_out ).

    cl_aunit_assert=>assert_equals(
      act = lv_string_out
      exp = 'TEST'
      msg = 'Non-DDIC types should remain unchanged' ).

  ENDMETHOD.

  METHOD test_split_table.

    DATA lt_data TYPE tt_dummy_data.
    DO 10 TIMES.
      APPEND VALUE #( id = sy-index text = |Row { sy-index }| ) TO lt_data.
    ENDDO.

    DATA(lt_splitted) = zcl_abap_projects=>split_table(
      im_table         = lt_data
      im_split_segment = 3 ).

    cl_aunit_assert=>assert_equals(
      act = lines( lt_splitted )
      exp = 4
      msg = 'Table should be split into 4 segments' ).

    FIELD-SYMBOLS: <fs_segment> TYPE ANY TABLE.
    ASSIGN lt_splitted[ 1 ]->* TO <fs_segment>.
    cl_aunit_assert=>assert_equals(
      act = lines( <fs_segment> )
      exp = 3
      msg = 'First segment should have 3 rows').

    ASSIGN lt_splitted[ 4 ]->* TO <fs_segment>.
    cl_aunit_assert=>assert_equals(
      act = lines( <fs_segment> )
      exp = 1
      msg = 'Last segment should have 1 row (remainder)').

  ENDMETHOD.


ENDCLASS.

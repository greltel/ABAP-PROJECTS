************************************************************************
*   Program name: ZCOUNT_SINGLE_MULTIPLE_VALUES
*   Description : Count Single and Multiple Values of Internal Table
*
*   Created   by: George Drakos
*
************************************************************************
REPORT zcount_single_multiple_values.

*&----------------------------------------------------------------------*
*&CLASS LCL_COUNT DEFINITION
*&----------------------------------------------------------------------*
CLASS lcl_count DEFINITION CREATE PUBLIC FINAL.

  PUBLIC SECTION.

    CLASS-METHODS:

      count_single_multiple_values IMPORTING VALUE(im_table)    TYPE ANY TABLE
                                             im_column_name     TYPE string
                                   EXPORTING ex_unique_values   TYPE REF TO data
                                             ex_multiple_values TYPE REF TO data.

ENDCLASS.

*&---------------------------------------------------------------------*
*& EXECUTABLE CODE
*&---------------------------------------------------------------------*
START-OF-SELECTION.

  SELECT FROM vbak FIELDS vbak~* INTO TABLE @DATA(lt_table) UP TO 1000 ROWS.

  lcl_count=>count_single_multiple_values( EXPORTING im_table           = lt_table
                                                     im_column_name     = 'ERNAM'
                                           IMPORTING ex_unique_values   = DATA(lo_unique_values)
                                                     ex_multiple_values = DATA(lo_multiple_values) ).

  CHECK lo_unique_values IS NOT INITIAL AND lo_multiple_values IS NOT INITIAL.

  ASSIGN lo_unique_values->* TO FIELD-SYMBOL(<fs_table_unique>).
  ASSIGN lo_multiple_values->* TO FIELD-SYMBOL(<fs_table_multiple>).

  BREAK-POINT.

END-OF-SELECTION.

*&----------------------------------------------------------------------*
*&CLASS LCL_COUNT IMPLEMENTATION
*&----------------------------------------------------------------------*
CLASS lcl_count IMPLEMENTATION.

  METHOD count_single_multiple_values.

    CONSTANTS lc_count_column TYPE c LENGTH 8 VALUE 'COUNT'.

    DATA:lo_ref         TYPE REF TO data,
         lo_target_line TYPE REF TO data,
         lo_temp_table  TYPE REF TO data.

    FIELD-SYMBOLS:<fs_temp_values_table>     TYPE SORTED TABLE,
                  <fs_imported_table>        TYPE STANDARD TABLE,
                  <fs_unique_values_table>   TYPE HASHED TABLE,
                  <fs_multiple_values_table> TYPE HASHED TABLE,
                  <fs_target_line>           TYPE any.

    "VALIDATIONS
    CHECK im_table IS NOT INITIAL.

    DATA(lt_components) = CAST cl_abap_structdescr( CAST cl_abap_tabledescr( cl_abap_tabledescr=>describe_by_data( im_table ) )->get_table_line_type( ) )->components.
    IF NOT line_exists( lt_components[ name = im_column_name ] ).
      RETURN.
    ENDIF.

    "COPY IMPORTING TABLE AND CREATE TEMP TABLE
    TRY.

        CREATE DATA lo_ref LIKE im_table.
        ASSIGN lo_ref->* TO <fs_imported_table>.
        CHECK <fs_imported_table> IS ASSIGNED.

        <fs_imported_table> = im_table.
        SORT <fs_imported_table> BY (im_column_name) ASCENDING.

      CATCH cx_sy_create_data_error INTO DATA(lo_create_data_exception).
        DATA(lv_exception_text) = lo_create_data_exception->get_longtext( ).
        RETURN.
    ENDTRY.


    "CONSTRUCT TARGET TABLES-STRUCTURE LINE
    ASSIGN COMPONENT im_column_name OF STRUCTURE <fs_imported_table>[ 1 ] TO FIELD-SYMBOL(<fs_data>).
    CHECK <fs_data> IS ASSIGNED.

    TRY.
        DATA(lo_new_struct) = cl_abap_structdescr=>create( VALUE cl_abap_structdescr=>component_table(
                                                          ( name = im_column_name type  = CAST #( cl_abap_elemdescr=>describe_by_data( <fs_data> ) ) )
                                                          ( name = lc_count_column type  = cl_abap_elemdescr=>get_i( ) ) ) ) .

        DATA(lo_new_tab) = cl_abap_tabledescr=>create( p_line_type  = lo_new_struct
                                                       p_table_kind = cl_abap_tabledescr=>tablekind_hashed
                                                       p_unique     = abap_true
                                                       p_key        = VALUE abap_keydescr_tab( ( name = im_column_name ) )
                                                       p_key_kind   = cl_abap_tabledescr=>keydefkind_user ).

        DATA(lo_new_tab_temp) = cl_abap_tabledescr=>create( p_line_type  = cl_abap_structdescr=>create( VALUE cl_abap_structdescr=>component_table(
                                                           ( name = im_column_name type  = CAST #( cl_abap_elemdescr=>describe_by_data( <fs_data> ) ) ) ) )
                                                            p_table_kind = cl_abap_tabledescr=>tablekind_sorted
                                                            p_key = VALUE abap_keydescr_tab( ( name = im_column_name ) )
                                                            p_unique     = abap_false ).

      CATCH cx_sy_struct_attributes cx_sy_table_attributes INTO DATA(lo_exception).
        lv_exception_text = lo_exception->get_longtext( ).
        RETURN.
    ENDTRY.

    TRY.

        CREATE DATA ex_unique_values    TYPE HANDLE lo_new_tab.
        CREATE DATA ex_multiple_values  TYPE HANDLE lo_new_tab.
        CREATE DATA lo_target_line      TYPE HANDLE lo_new_struct.
        CREATE DATA lo_temp_table       TYPE HANDLE lo_new_tab_temp.

        ASSIGN ex_unique_values->*   TO <fs_unique_values_table>.
        ASSIGN ex_multiple_values->* TO <fs_multiple_values_table>.
        ASSIGN lo_target_line->*     TO <fs_target_line>.
        ASSIGN lo_temp_table->*      TO <fs_temp_values_table>.

        CHECK <fs_unique_values_table> IS ASSIGNED AND <fs_multiple_values_table> IS ASSIGNED.

      CATCH cx_sy_create_data_error INTO lo_create_data_exception.
        lv_exception_text = lo_create_data_exception->get_longtext( ).
        RETURN.
    ENDTRY.

    "BUILD UNIQUE-MULTIPLE VALUE TABLES
    LOOP AT <fs_imported_table> ASSIGNING FIELD-SYMBOL(<fs_line>).

      DATA(lv_tabix) = syst-tabix.
      ASSIGN COMPONENT im_column_name OF STRUCTURE <fs_line> TO FIELD-SYMBOL(<fs_value>).

      IF <fs_value> IS  ASSIGNED.

        READ TABLE <fs_multiple_values_table> WITH KEY (im_column_name) = <fs_value> TRANSPORTING NO FIELDS.
        IF syst-subrc IS INITIAL.
          CONTINUE.
        ENDIF.

        <fs_temp_values_table> =  CORRESPONDING #( <fs_imported_table>  ).
        IF lv_tabix NE 1.
          DELETE <fs_temp_values_table> FROM 1 TO lv_tabix - 1.
        ENDIF.

        LOOP AT <fs_temp_values_table> ASSIGNING FIELD-SYMBOL(<fs_temp>).

          ASSIGN COMPONENT im_column_name OF STRUCTURE <fs_temp> TO FIELD-SYMBOL(<fs_temp_value>).

          IF <fs_temp_value> NE <fs_value>.
            DELETE TABLE <fs_temp_values_table> WITH TABLE KEY (im_column_name) = <fs_temp_value>.
          ENDIF.

        ENDLOOP.

        IF lines( <fs_temp_values_table> ) EQ 1.

          CLEAR:<fs_target_line>.
          ASSIGN COMPONENT im_column_name OF STRUCTURE <fs_target_line> TO FIELD-SYMBOL(<fs_target_unique>).
          <fs_target_unique> = <fs_value>.

          ASSIGN COMPONENT lc_count_column OF STRUCTURE <fs_target_line> TO <fs_target_unique>.
          <fs_target_unique> = 1.

          INSERT <fs_target_line> INTO TABLE <fs_unique_values_table>.

          UNASSIGN: <fs_target_unique>.

        ELSEIF  lines( <fs_temp_values_table> ) GT 1.

          CLEAR:<fs_target_line>.
          ASSIGN COMPONENT im_column_name OF STRUCTURE <fs_target_line> TO FIELD-SYMBOL(<fs_target_multiple>).
          <fs_target_multiple> = <fs_value>.

          ASSIGN COMPONENT lc_count_column OF STRUCTURE <fs_target_line> TO <fs_target_multiple>.
          <fs_target_multiple> = lines( <fs_temp_values_table> ).

          INSERT <fs_target_line> INTO TABLE <fs_multiple_values_table>.

          UNASSIGN: <fs_target_multiple>.

        ENDIF.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

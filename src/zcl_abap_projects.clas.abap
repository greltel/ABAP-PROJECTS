class ZCL_ABAP_PROJECTS definition
  public
  final
  create public .

public section.

  types:
    BEGIN OF ENUM t_alpha_conversion STRUCTURE s_alpha_conversion BASE TYPE char1,
        in    VALUE 1,
        out   VALUE 2,
        other VALUE IS INITIAL,
      END OF ENUM t_alpha_conversion STRUCTURE s_alpha_conversion .
  types:
    t_splitted_table TYPE STANDARD TABLE OF REF TO data with EMPTY KEY .

  class-methods COUNT_SINGLE_MULTIPLE_VALUES
    importing
      !IM_TABLE type ANY TABLE
      !IM_COLUMN_NAME type STRING
    exporting
      !EX_UNIQUE_VALUES type ref to DATA
      !EX_MULTIPLE_VALUES type ref to DATA .
  class-methods ALPHA_CONVERSION
    importing
      !IV_INPUT type ANY
      !IM_ALPHA type ZCL_ABAP_PROJECTS=>T_ALPHA_CONVERSION
    exporting
      !EV_OUTPUT type ANY .
  class-methods SPLIT_TABLE
    importing
      !IM_TABLE type ANY TABLE
      !IM_SPLIT_SEGMENT type I default 100
    returning
      value(RE_SPLITTED_TABLE) type ZCL_ABAP_PROJECTS=>T_SPLITTED_TABLE .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_ABAP_PROJECTS IMPLEMENTATION.


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
                                                                                                               WHEN zcl_abap_projects=>s_alpha_conversion-in  THEN 'INPUT'
                                                                                                               WHEN zcl_abap_projects=>s_alpha_conversion-out THEN 'OUTPUT'
                                                                                                               ELSE 'INPUT'"ELSE THROW EXCEPTION
                                                                                                              ) } | ) ).
    TRY.
        CALL FUNCTION function_conversion
          EXPORTING
            input                 = iv_input
          IMPORTING
            output                = ev_output
          EXCEPTIONS
            communication_failure = 1
            system_failure        = 2
            error_message         = 3
            OTHERS                = 4.
      CATCH cx_sy_dyn_call_illegal_type cx_sy_dyn_call_illegal_func.
    ENDTRY.

  ENDMETHOD.


  METHOD count_single_multiple_values.

    CONSTANTS lc_count_column TYPE name_feld VALUE 'COUNT'.

    DATA lo_ref         TYPE REF TO data.
    DATA lo_target_line TYPE REF TO data.
    DATA lo_temp_table  TYPE REF TO data.

    FIELD-SYMBOLS <fs_temp_values_table>     TYPE SORTED TABLE.
    FIELD-SYMBOLS <fs_imported_table>        TYPE STANDARD TABLE.
    FIELD-SYMBOLS <fs_unique_values_table>   TYPE HASHED TABLE.
    FIELD-SYMBOLS <fs_multiple_values_table> TYPE HASHED TABLE.
    FIELD-SYMBOLS <fs_target_line>           TYPE any.

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

          CLEAR <fs_target_line>.
          ASSIGN COMPONENT im_column_name OF STRUCTURE <fs_target_line> TO FIELD-SYMBOL(<fs_target_unique>).
          <fs_target_unique> = <fs_value>.

          ASSIGN COMPONENT lc_count_column OF STRUCTURE <fs_target_line> TO <fs_target_unique>.
          <fs_target_unique> = 1.

          INSERT <fs_target_line> INTO TABLE <fs_unique_values_table>.

          UNASSIGN <fs_target_unique>.

        ELSEIF  lines( <fs_temp_values_table> ) GT 1.

          CLEAR <fs_target_line>.
          ASSIGN COMPONENT im_column_name OF STRUCTURE <fs_target_line> TO FIELD-SYMBOL(<fs_target_multiple>).
          <fs_target_multiple> = <fs_value>.

          ASSIGN COMPONENT lc_count_column OF STRUCTURE <fs_target_line> TO <fs_target_multiple>.
          <fs_target_multiple> = lines( <fs_temp_values_table> ).

          INSERT <fs_target_line> INTO TABLE <fs_multiple_values_table>.

          UNASSIGN <fs_target_multiple>.

        ENDIF.

      ENDIF.

      CLEAR lv_tabix.

    ENDLOOP.

  ENDMETHOD.


  METHOD split_table.

    DATA lr_sub_table  TYPE REF TO data.
    FIELD-SYMBOLS <fs_target_table> TYPE STANDARD TABLE.

    DATA(lo_table_descr) = CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data( im_table ) ).
    CHECK lo_table_descr IS BOUND.

    "Split the Table into Smaller Tables
    LOOP AT im_table ASSIGNING FIELD-SYMBOL(<fs_line>).

      IF ( ( syst-tabix - 1 ) MOD im_split_segment ) EQ 0.

        CREATE DATA lr_sub_table TYPE HANDLE lo_table_descr.
        CHECK lr_sub_table       IS BOUND.

        APPEND lr_sub_table      TO re_splitted_table.
        ASSIGN lr_sub_table->*   TO <fs_target_table>.
        CHECK <fs_target_table>  IS ASSIGNED.

      ENDIF.

      APPEND <fs_line> TO <fs_target_table>.

    ENDLOOP.

  ENDMETHOD.
ENDCLASS.

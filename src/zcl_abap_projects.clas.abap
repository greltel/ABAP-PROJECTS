class ZCL_ABAP_PROJECTS definition
  public
  final
  create public .

public section.

  types:
    BEGIN OF t_lock_result,
        success      TYPE abap_boolean,
        locked_by    TYPE syst-uname,
        msg_text     TYPE string,
      END OF t_lock_result .
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
  class-methods LOCK_TABLE
    importing
      !IV_TABLE_NAME type TABNAME
      !IV_DATA type ANY
      !IV_SCOPE type CHAR1 default '2'
      !IV_WAIT type ABAP_BOOLEAN default ABAP_FALSE
      !IV_ENQMODE type ENQMODE default 'E'
      !IV_ENABLE_SPECIFIC_LOCK type ABAP_BOOLEAN default ABAP_TRUE
    returning
      value(RE_RESULT) type T_LOCK_RESULT .
  class-methods UNLOCK_TABLE
    importing
      !IV_TABLE_NAME type TABNAME
      !IV_DATA type ANY
      !IV_ENQMODE type ENQMODE default 'E'
      !IV_SCOPE type CHAR1 default '3'
      !IV_ENABLE_SPECIFIC_LOCK type ABAP_BOOLEAN default ABAP_TRUE
    returning
      value(RE_RESULT) type T_LOCK_RESULT .
  PROTECTED SECTION.
private section.

  class-methods BUILD_VARKEY
    importing
      !IV_TABLE_NAME type TABNAME
      !IV_DATA type ANY
    returning
      value(RE_VARKEY) type RSTABLE-VARKEY .
  class-methods EXECUTE_SPECIFIC_LOCK
    importing
      !IV_TABLE_NAME type TABNAME
      !IV_DATA type ANY
      !IV_SCOPE type CHAR1 optional
      !IV_WAIT type ABAP_BOOL optional
      !IV_ENQMODE type ENQMODE optional
      !IV_UNLOCK type ABAP_BOOL default ABAP_FALSE
    returning
      value(RE_RESULT) type T_LOCK_RESULT .
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


  METHOD build_varkey.

    DATA lv_field_val TYPE string.
    DATA lv_offset    TYPE i VALUE 0.
    DATA(lv_varkey_length) = CONV i( 120 ) ##OPERATOR[I].

    TRY.

        DATA(lt_ddic_fields) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_name( iv_table_name ) )->get_ddic_field_list( ).

        LOOP AT lt_ddic_fields INTO DATA(ls_field) WHERE keyflag   EQ abap_true
                                                     AND fieldname NE 'MANDT'.

          DATA(lv_len) = CONV i( ls_field-leng ).

          ASSIGN COMPONENT ls_field-fieldname OF STRUCTURE iv_data TO FIELD-SYMBOL(<fs_val>).
          IF <fs_val> IS ASSIGNED AND syst-subrc IS INITIAL.

            TRY.
                IF ( lv_offset + lv_len ) GE lv_varkey_length.
                  re_varkey+lv_offset(lv_len) = <fs_val>.
                ENDIF.

              CATCH cx_sy_range_out_of_bounds.
            ENDTRY.

          ENDIF.

          lv_offset = lv_offset + lv_len.
          UNASSIGN <fs_val>.

        ENDLOOP.

      CATCH cx_sy_move_cast_error.
        RETURN.
    ENDTRY.

  ENDMETHOD.


  METHOD execute_specific_lock.

    CONSTANTS: c_active_object    TYPE as4local VALUE 'A',
               c_lock_object_type TYPE aggtype  VALUE 'E',
               c_enq_prefix_fm    TYPE string   VALUE 'ENQUEUE_',
               c_deq_prefix_fm    TYPE string   VALUE 'DEQUEUE_'.

    DATA lt_params TYPE abap_func_parmbind_tab.

    SELECT SINGLE FROM dd25l
      FIELDS viewname
      WHERE roottab  EQ @iv_table_name
        AND as4local EQ @c_active_object
        AND aggtype  EQ @c_lock_object_type
      INTO @DATA(lv_lock_object).

    IF syst-subrc IS NOT INITIAL OR lv_lock_object IS INITIAL.
      re_result = VALUE #( success  = abap_false
                           msg_text = CONV #( TEXT-004 ) ).
      RETURN.
    ENDIF.

    DATA(lv_fm_name) = SWITCH rs38l_fnam( iv_unlock
                                          WHEN abap_true  THEN |{ c_deq_prefix_fm }{ lv_lock_object }|
                                          WHEN abap_false THEN |{ c_enq_prefix_fm }{ lv_lock_object }| ).

    TRY.
        DATA(lt_components) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_name( iv_table_name ) )->get_ddic_field_list( ).

        LOOP AT lt_components INTO DATA(ls_comp) WHERE keyflag   EQ abap_true AND
                                                       fieldname NE 'MANDT'.

          ASSIGN COMPONENT ls_comp-fieldname OF STRUCTURE iv_data TO FIELD-SYMBOL(<fs_val>).

          IF <fs_val> IS ASSIGNED AND syst-subrc IS INITIAL AND <fs_val> IS NOT INITIAL.
            lt_params = VALUE #( BASE lt_params ( name  = ls_comp-fieldname
                                                  kind  = abap_func_exporting
                                                  value = REF #( <fs_val> ) ) ).
          ENDIF.

        ENDLOOP.

        lt_params = VALUE #( BASE lt_params ( name  = '_SCOPE'
                                              kind  = abap_func_exporting
                                              value = REF #( iv_scope ) )
                                            ( name  = |MODE_{ iv_table_name }|
                                              kind  = abap_func_exporting
                                              value = REF #( iv_enqmode ) ) ).

        IF iv_unlock = abap_false.
          lt_params = VALUE #( BASE lt_params ( name  = '_WAIT'
                                                kind  = abap_func_exporting
                                                value = REF #( iv_wait ) ) ).
        ENDIF.

        DATA(lt_exc_params) = VALUE abap_func_excpbind_tab( ( name = 'FOREIGN_LOCK'    value = 1  )
                                                            ( name = 'SYSTEM_FAILURE'  value = 2  )
                                                            ( name = 'ERROR_MESSAGE'   value = 3 )
                                                            ( name = 'OTHERS'          value = 4  ) ).
        CALL FUNCTION lv_fm_name
          PARAMETER-TABLE lt_params EXCEPTION-TABLE lt_exc_params.

        re_result = COND #( WHEN syst-subrc IS INITIAL THEN VALUE #( success = abap_true )
                            WHEN syst-subrc EQ 1 THEN VALUE #( success   = abap_false
                                                               locked_by = syst-msgv1
                                                               msg_text  = |{ TEXT-002 } { sy-msgv1 }| )
                            ELSE VALUE #( success  = abap_false
                                          msg_text = CONV #( TEXT-001 ) ) ).

      CATCH cx_sy_dyn_call_error cx_sy_move_cast_error INTO DATA(lx_dyn).
        re_result-success  = abap_false.
        re_result-msg_text = lx_dyn->get_text( ).
    ENDTRY.

  ENDMETHOD.


  METHOD lock_table.

    IF iv_enable_specific_lock EQ abap_true.

      re_result = execute_specific_lock( iv_table_name = iv_table_name
                                         iv_data       = iv_data
                                         iv_scope      = iv_scope
                                         iv_wait       = iv_wait
                                         iv_enqmode    = iv_enqmode
                                         iv_unlock     = abap_false ).

    ELSE.

      DATA(lv_varkey) = build_varkey( iv_table_name = iv_table_name
                                      iv_data       = iv_data ).

      CHECK lv_varkey IS NOT INITIAL.

      CALL FUNCTION 'ENQUEUE_E_TABLE'
        EXPORTING
          mode_rstable   = iv_enqmode
          tabname        = iv_table_name
          varkey         = lv_varkey
          _scope         = iv_scope
          _wait          = iv_wait
        EXCEPTIONS
          foreign_lock   = 1
          system_failure = 2
          error_message  = 3
          OTHERS         = 4.

      re_result = COND #( WHEN syst-subrc IS INITIAL THEN VALUE #( success = abap_true )
                          WHEN syst-subrc EQ 1 THEN VALUE #( success   = abap_false
                                                             locked_by = syst-msgv1
                                                             msg_text  = |{ TEXT-002 } { sy-msgv1 }| )
                          ELSE VALUE #( success  = abap_false
                                        msg_text = CONV #( TEXT-001 ) ) ).

    ENDIF.

  ENDMETHOD.


  METHOD unlock_table.

    IF iv_enable_specific_lock EQ abap_true.

      re_result = execute_specific_lock( iv_table_name = iv_table_name
                                         iv_data       = iv_data
                                         iv_scope      = iv_scope
                                         iv_unlock     = abap_true ).


    ELSE.

      DATA(lv_varkey) = build_varkey( iv_table_name = iv_table_name
                                      iv_data       = iv_data ).

      CHECK lv_varkey IS NOT INITIAL.

      CALL FUNCTION 'DEQUEUE_E_TABLE'
        EXPORTING
          mode_rstable  = iv_enqmode
          tabname       = iv_table_name
          varkey        = lv_varkey
          _scope        = iv_scope
        EXCEPTIONS
          error_message = 1
          OTHERS        = 2.

      re_result = COND #( WHEN syst-subrc IS INITIAL THEN VALUE #( success = abap_true )
                          ELSE VALUE #( success  = abap_false
                                        msg_text = CONV #( TEXT-003 ) ) ).

    ENDIF.

  ENDMETHOD.
ENDCLASS.

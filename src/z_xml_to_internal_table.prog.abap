************************************************************************
*   Program name: Dynamic XML to Table Convertion
*   Description : Render any XML File to Table
*
*   Created   by: George Drakos
*
************************************************************************
REPORT z_xml_to_internal_table.

*&---------------------------------------------------------------------*
*& GLOBAL DATA DEFINITION
*&---------------------------------------------------------------------*
TABLES:sscrfields.

CLASS: lcx_xml        DEFINITION DEFERRED,
       lcl_xml        DEFINITION DEFERRED,
       lcl_sel_screen DEFINITION DEFERRED.

*&----------------------------------------------------------------------*
*& CLASS LCX_XML DEFINITION
*&----------------------------------------------------------------------*
CLASS lcx_xml DEFINITION INHERITING FROM cx_static_check.

  PUBLIC SECTION.

    METHODS:
      constructor IMPORTING text TYPE string,
      get_text REDEFINITION.

  PRIVATE SECTION.

    DATA: local_text TYPE string.

ENDCLASS.

*----------------------------------------------------------------------*
* CLASS lcl_sel_screen DEFINITION
*----------------------------------------------------------------------*
CLASS lcl_sel_screen DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.

    CLASS-METHODS get_instance RETURNING VALUE(re_instance) TYPE REF TO lcl_sel_screen.

    METHODS:
      screen_initialization,
      screen_pbo,
      screen_pai IMPORTING im_system_command TYPE syst-ucomm.

  PRIVATE SECTION.

    CLASS-DATA lo_instance TYPE REF TO lcl_sel_screen.

ENDCLASS.

*&----------------------------------------------------------------------*
*& CLASS LCL_XML DEFINITION
*&----------------------------------------------------------------------*
CLASS lcl_xml DEFINITION CREATE PUBLIC.

  PUBLIC SECTION.

    CLASS-METHODS:

      open_dialog_xml RETURNING VALUE(re_filepath) TYPE file_table-filename,

      display_table IMPORTING im_table TYPE REF TO data
                    RAISING   lcx_xml.

    METHODS:

      constructor IMPORTING im_filepath TYPE file_table-filename
                  RAISING   lcx_xml,

      get_structured_table_from_xml IMPORTING im_attribute_node TYPE cname OPTIONAL
                                    EXPORTING ex_table          TYPE REF TO data
                                    RAISING   lcx_xml.

  PRIVATE SECTION.

    CONSTANTS:
      BEGIN OF c_xml_node_type,
        value_node     TYPE smum_xmltb-type VALUE 'V',
        header_element TYPE smum_xmltb-type VALUE 'A',
      END OF c_xml_node_type.

    CLASS-DATA:lv_xml_string  TYPE string.

    DATA: lv_xml_xstring TYPE xstring,
          lt_xml         TYPE hrpayfr_t_smum_xmltb.

    CLASS-METHODS:

      on_user_command FOR EVENT added_function OF cl_salv_events_table IMPORTING e_salv_function,

      display_xml.

    METHODS:

      read_xml_to_string_xstring IMPORTING im_filepath TYPE file_table-filename
                                 RAISING   lcx_xml,

      read_xml_to_table RAISING lcx_xml,

      get_dynamic_table_from_xml IMPORTING im_attribute_node TYPE cname OPTIONAL
                                 EXPORTING ex_table          TYPE REF TO data
                                 RAISING   lcx_xml,

      populate_table_from_xml    IMPORTING im_attribute_node TYPE cname OPTIONAL
                                 CHANGING  ex_table          TYPE ANY TABLE
                                 RAISING   lcx_xml.

ENDCLASS.

*&---------------------------------------------------------------------*
*& SELECTION SCREEN DESIGN
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE title1.

  PARAMETERS: p_file TYPE file_table-filename,
              p_attr TYPE cname.

SELECTION-SCREEN END OF BLOCK b1.
*&---------------------------------------------------------------------*
*& INITIALIZATION OF SELECTION SCREEN ELEMENTS
*&---------------------------------------------------------------------*
INITIALIZATION.
  lcl_sel_screen=>get_instance( )->screen_initialization( ).

*&---------------------------------------------------------------------*
*& AT SELECTION SCREEN ON VALUE REQUESTS (F4)
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  p_file = lcl_xml=>open_dialog_xml( ).

*&---------------------------------------------------------------------*
*& AT SELECTION SCREEN Actions(PAI)
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN.
  lcl_sel_screen=>get_instance( )->screen_pai( sscrfields-ucomm ).

*&---------------------------------------------------------------------*
*& EXECUTABLE CODE
*&---------------------------------------------------------------------*
START-OF-SELECTION.

  TRY.

      NEW lcl_xml( p_file )->get_structured_table_from_xml( EXPORTING im_attribute_node = p_attr
                                                            IMPORTING ex_table          = DATA(lr_table) ).

      lcl_xml=>display_table( lr_table ).

    CATCH lcx_xml INTO DATA(lo_exception).
      MESSAGE lo_exception->get_text( ) TYPE cl_cms_common=>con_msg_typ_i DISPLAY LIKE cl_cms_common=>con_msg_typ_e.
  ENDTRY.

END-OF-SELECTION.

*----------------------------------------------------------------------*
* CLASS lcl_sel_screen IMPLEMENTATION
*----------------------------------------------------------------------*
CLASS lcl_sel_screen IMPLEMENTATION.

  METHOD 	get_instance.

    IF lo_instance IS NOT BOUND.
      lo_instance = NEW #( ).
    ENDIF.

    re_instance = lo_instance.

  ENDMETHOD.

  METHOD screen_initialization.

    title1                = 'XML Selection Criteria'.
    %_p_file_%_app_%-text = icon_xml_doc      && 'XML Filepath'.
    %_p_attr_%_app_%-text = icon_io_attribute && 'Attribute Node'.

  ENDMETHOD.

  METHOD screen_pbo.

    LOOP AT SCREEN INTO DATA(ls_screen).

      MODIFY SCREEN FROM ls_screen.

    ENDLOOP.

  ENDMETHOD.

  METHOD screen_pai.

    CASE im_system_command.
      WHEN cl_wsti_calc_const=>c_execute.
        IF p_file IS INITIAL.
          MESSAGE 'Filepath is Mandatory Field' TYPE cl_cms_common=>con_msg_typ_e.
        ENDIF.
    ENDCASE.

  ENDMETHOD.

ENDCLASS.

*&---------------------------------------------------------------------*
*& Class LCL_XML Implementation
*&---------------------------------------------------------------------*
CLASS lcl_xml IMPLEMENTATION.

  METHOD open_dialog_xml.

    DATA lt_file_table TYPE filetable.
    DATA lv_return     TYPE i.

    cl_gui_frontend_services=>file_open_dialog(
      EXPORTING
        window_title            = 'File System of Presentation Server'
        default_extension       = cl_gui_frontend_services=>filetype_xml
        file_filter             = 'All Files(*.*)|*.*|' && 'XML Files (*.xml)|*.xml|'
      CHANGING
        file_table              = lt_file_table
        rc                      = lv_return
      EXCEPTIONS
        file_open_dialog_failed = 1
        cntl_error              = 2
        error_no_gui            = 3
        OTHERS                  = 4 ).

    CHECK syst-subrc IS INITIAL.
    re_filepath =  VALUE #( lt_file_table[ 1 ]-filename OPTIONAL ).

  ENDMETHOD.

  METHOD constructor.

    me->read_xml_to_string_xstring( im_filepath ).
    me->read_xml_to_table( ).

  ENDMETHOD.

  METHOD read_xml_to_string_xstring.

    TRY.

        DATA(lo_xml) = NEW cl_xml_document( ).

        IF lo_xml->import_from_file( CONV #( im_filepath ) ) IS INITIAL.

          lo_xml->render_2_string( EXPORTING pretty_print = abap_true
                                   IMPORTING retcode      = DATA(lv_rc) ##NEEDED
                                             size         = DATA(lv_size) ##NEEDED
                                             stream       = me->lv_xml_string ).

          lo_xml->render_2_xstring( EXPORTING pretty_print = abap_true
                                    IMPORTING retcode      = lv_rc ##NEEDED
                                              size         = lv_size ##NEEDED
                                              stream       = me->lv_xml_xstring ).

        ELSE.
          RAISE EXCEPTION TYPE lcx_xml EXPORTING text = 'Error Uploading the XML File'.
        ENDIF.

      CATCH cx_root INTO DATA(lo_exception).
        RAISE EXCEPTION TYPE lcx_xml EXPORTING text = lo_exception->get_text( ).
    ENDTRY.

  ENDMETHOD.

  METHOD read_xml_to_table.

    DATA lt_return TYPE bapiret2_t.

    CALL FUNCTION 'SMUM_XML_PARSE'
      EXPORTING
        xml_input     = me->lv_xml_xstring
      TABLES
        xml_table     = me->lt_xml
        return        = lt_return
      EXCEPTIONS
        error_message = 1
        OTHERS        = 2.

    IF syst-subrc IS NOT INITIAL                                       OR
       line_exists( lt_return[ type = cl_cms_common=>con_msg_typ_e ] ) OR
       line_exists( lt_return[ type = cl_cms_common=>con_msg_typ_a ] ) OR
       line_exists( lt_return[ type = cl_cms_common=>con_msg_typ_x ] ).

      RAISE EXCEPTION TYPE lcx_xml EXPORTING text = 'Error Parsing the XML File'.

    ENDIF.

  ENDMETHOD.

  METHOD get_structured_table_from_xml.

    me->get_dynamic_table_from_xml( EXPORTING im_attribute_node = im_attribute_node
                                    IMPORTING ex_table          = DATA(lr_table) ).

    ex_table = lr_table.
    ASSIGN lr_table->* TO FIELD-SYMBOL(<fs_itab>).

    me->populate_table_from_xml( EXPORTING im_attribute_node = im_attribute_node
                                 CHANGING  ex_table          = <fs_itab> ).

  ENDMETHOD.

  METHOD get_dynamic_table_from_xml.

    DATA lv_line_counter TYPE syst-tabix.
    DATA lt_components   TYPE  cl_abap_structdescr=>component_table.

    LOOP AT me->lt_xml ASSIGNING FIELD-SYMBOL(<fs_xml_line>).

      DATA(lv_tabix) = syst-tabix.

      IF im_attribute_node IS NOT INITIAL AND im_attribute_node EQ <fs_xml_line>-cname.

        CLEAR:lv_line_counter.
        DO.
          lv_line_counter += 1.
          DATA(ls_xml_table) = VALUE #( me->lt_xml[ ( lv_tabix + lv_line_counter ) ] OPTIONAL ).
          IF syst-subrc IS INITIAL AND ls_xml_table IS NOT INITIAL AND ls_xml_table-cname NE im_attribute_node AND ls_xml_table-type EQ c_xml_node_type-value_node.
            APPEND VALUE #( name = ls_xml_table-cname type = cl_abap_elemdescr=>get_c( 80 )  ) TO lt_components.
            CLEAR:ls_xml_table.
          ELSE.
            EXIT.
          ENDIF.

        ENDDO.

      ELSEIF im_attribute_node IS INITIAL.

        CLEAR:lv_line_counter.
        DO.
          lv_line_counter += 1.
          ls_xml_table = VALUE #( me->lt_xml[ lv_tabix + lv_line_counter ] OPTIONAL ).
          IF syst-subrc IS INITIAL AND ls_xml_table IS NOT INITIAL AND ls_xml_table-type EQ c_xml_node_type-value_node.
            APPEND VALUE #( name = ls_xml_table-cname type = cl_abap_elemdescr=>get_c( 80 )  ) TO lt_components.
            CLEAR:ls_xml_table.
          ELSE.
            EXIT.
          ENDIF.
        ENDDO.

      ENDIF.

      IF lt_components IS NOT INITIAL.
        EXIT.
      ENDIF.

    ENDLOOP.

    IF lt_components IS INITIAL.
      RAISE EXCEPTION TYPE lcx_xml EXPORTING text = 'Error getting the Components of Internal Table'.
    ELSE.

      TRY.

          DATA(table_type) = cl_abap_tabledescr=>create( p_line_type  = cl_abap_structdescr=>create( lt_components )
                                                         p_table_kind = cl_abap_tabledescr=>tablekind_std
                                                         p_unique     = abap_false ).

          CREATE DATA ex_table TYPE HANDLE table_type.

        CATCH cx_sy_table_creation INTO DATA(lo_exception).
          RAISE EXCEPTION TYPE lcx_xml EXPORTING text = lo_exception->get_text( ).
      ENDTRY.

    ENDIF.

  ENDMETHOD.

  METHOD populate_table_from_xml.

    DATA lr_data_reference TYPE REF TO data.
    DATA lv_line_counter   TYPE i.

    FIELD-SYMBOLS: <fs_line>  TYPE any,
                   <fs_value> TYPE any.

    CREATE DATA lr_data_reference LIKE LINE OF ex_table.
    ASSIGN lr_data_reference->* TO <fs_line>.

    "Populate the Table with Values from XML File
    LOOP AT me->lt_xml ASSIGNING FIELD-SYMBOL(<fs_xml_line>).

      DATA(lv_tabix) = syst-tabix.

      "MAP BY SUPPLIED ATTRIBUTE NODE
      IF im_attribute_node IS NOT INITIAL AND im_attribute_node EQ <fs_xml_line>-cname .

        CLEAR:lv_line_counter.
        DO.
          lv_line_counter = lv_line_counter + 1.
          READ TABLE me->lt_xml INDEX lv_tabix + lv_line_counter INTO DATA(ls_xml_table).
          IF syst-subrc IS INITIAL AND
             ls_xml_table-cname NE im_attribute_node AND
             ls_xml_table-type  EQ c_xml_node_type-value_node .

            ASSIGN COMPONENT lv_line_counter OF STRUCTURE <fs_line> TO <fs_value>.

            IF <fs_value> IS ASSIGNED AND syst-subrc IS INITIAL.
              <fs_value> = ls_xml_table-cvalue.
              CONDENSE <fs_value>.
            ENDIF.

          ELSE.

            IF <fs_line> IS ASSIGNED AND <fs_line> IS NOT INITIAL .
              INSERT <fs_line> INTO TABLE ex_table.
            ENDIF.

            IF <fs_line> IS ASSIGNED.
              CLEAR:<fs_line>.
            ENDIF.

            EXIT.

          ENDIF.

        ENDDO.

      ELSEIF im_attribute_node IS INITIAL.

        IF <fs_xml_line>-type EQ c_xml_node_type-header_element.

          CLEAR:lv_line_counter.
          DO.
            lv_line_counter = lv_line_counter + 1.
            READ TABLE me->lt_xml INDEX lv_tabix + lv_line_counter INTO ls_xml_table.

            IF syst-subrc IS INITIAL AND ls_xml_table-type EQ c_xml_node_type-value_node.

              ASSIGN COMPONENT lv_line_counter OF STRUCTURE <fs_line> TO <fs_value>.

              IF <fs_value> IS ASSIGNED AND syst-subrc IS INITIAL.
                <fs_value> = ls_xml_table-cvalue.
                CONDENSE <fs_value>.
              ENDIF.


            ELSE.

              IF <fs_line> IS ASSIGNED AND <fs_line> IS NOT INITIAL .
                INSERT <fs_line> INTO TABLE ex_table.
              ENDIF.

              IF <fs_line> IS ASSIGNED.
                CLEAR:<fs_line>.
              ENDIF.

              EXIT.

            ENDIF.

          ENDDO.

        ENDIF.

      ENDIF.

    ENDLOOP.

    IF ex_table IS INITIAL.
      RAISE EXCEPTION TYPE lcx_xml EXPORTING text = 'No values found for Mapping'.
    ENDIF.

  ENDMETHOD.

  METHOD display_xml.

    cl_abap_browser=>show_xml( xml_string = lcl_xml=>lv_xml_string
                               title      = 'XML'
                               size       = cl_abap_browser=>large ).

  ENDMETHOD.

  METHOD display_table.

    ASSIGN im_table->* TO FIELD-SYMBOL(<fs_itab>).
    CHECK <fs_itab> IS ASSIGNED.

    TRY.
        cl_salv_table=>factory( EXPORTING r_container  = cl_gui_container=>default_screen
                                          list_display = if_salv_c_bool_sap=>false
                                IMPORTING r_salv_table = DATA(lo_alv)
                                CHANGING  t_table      = <fs_itab> ).
      CATCH cx_salv_msg INTO DATA(lo_exception).
        RAISE EXCEPTION TYPE lcx_xml EXPORTING text = lo_exception->get_text( ).
    ENDTRY.

    lo_alv->get_columns( )->set_optimize( if_salv_c_bool_sap=>true ).

    LOOP AT lo_alv->get_columns( )->get( ) ASSIGNING FIELD-SYMBOL(<fs_cols>).

      IF <fs_cols>-r_column->get_medium_text( ) IS INITIAL.
        <fs_cols>-r_column->set_medium_text( CONV #( <fs_cols>-columnname ) ).
      ENDIF.

    ENDLOOP.

    lo_alv->get_display_settings( )->set_striped_pattern( if_salv_c_bool_sap=>true ).
    lo_alv->get_functions( )->set_all( ).
    lo_alv->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>row_column ).
    lo_alv->get_layout(:
                      )->set_key( value = VALUE salv_s_layout_key( report = syst-repid ) ),
                      )->set_default( abap_true ),
                      )->set_save_restriction( if_salv_c_layout=>restrict_none ).

    SET HANDLER lcl_xml=>on_user_command FOR lo_alv->get_event( ) ACTIVATION abap_true.

    TRY.
        lo_alv->get_functions(:
                                   )->add_function( name     = 'XML'
                                                    icon     = |{ icon_xml_doc }|
                                                    text     = 'Display XML'
                                                    tooltip  = 'Display XML'
                                                    position = if_salv_c_function_position=>right_of_salv_functions ).
      CATCH cx_salv_existing cx_salv_wrong_call cx_salv_method_not_supported. "#EC NO_HANDLER
    ENDTRY.

    lo_alv->display( ).
    WRITE:/ space.

  ENDMETHOD.

  METHOD on_user_command.

    CHECK e_salv_function IS NOT INITIAL.

    CASE e_salv_function.
      WHEN 'XML'.
        lcl_xml=>display_xml( ).
    ENDCASE.

  ENDMETHOD.

ENDCLASS.

*&---------------------------------------------------------------------*
*& Class LCX_XML
*&---------------------------------------------------------------------*
CLASS lcx_xml IMPLEMENTATION.

  METHOD constructor.

    super->constructor( textid = CONV #( text ) ).
    local_text = text.

  ENDMETHOD.

  METHOD get_text.

    result = me->local_text.

  ENDMETHOD.

ENDCLASS.

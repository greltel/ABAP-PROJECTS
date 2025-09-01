************************************************************************
*   Program name: Z_SPLIT_TABLE
*   Description : Dynamic Split of Table into Smaller Ones
*
*   Created   by: George Drakos
*
************************************************************************
REPORT z_split_table.

*&----------------------------------------------------------------------*
*&CLASS LCL_SPLIT_TABLE DEFINITION
*&----------------------------------------------------------------------*
CLASS lcl_split_table DEFINITION FINAL.

  PUBLIC SECTION.

    TYPES t_splitted_table TYPE STANDARD TABLE OF REF TO data.

    CLASS-METHODS:

      split_table IMPORTING im_table          TYPE ANY TABLE
                            im_split_segment  TYPE i DEFAULT 100
                  EXPORTING ex_splitted_table TYPE t_splitted_table.

ENDCLASS.

*&----------------------------------------------------------------------*
*& EXECUTABLE CODE
*&----------------------------------------------------------------------*
START-OF-SELECTION.

  SELECT FROM t001
    FIELDS t001~*
    INTO TABLE @DATA(lt_data).

  lcl_split_table=>split_table( EXPORTING im_table          = lt_data
                                          im_split_segment  = 25
                                IMPORTING ex_splitted_table = DATA(lr_sub_tables) ).

  CHECK lr_sub_tables IS NOT INITIAL.

  BREAK-POINT.

  LOOP AT lr_sub_tables ASSIGNING FIELD-SYMBOL(<fs_sub_table>).

  ENDLOOP.

END-OF-SELECTION.
*&----------------------------------------------------------------------*
*& END OF EXECUTABLE CODE
*&----------------------------------------------------------------------*

*&----------------------------------------------------------------------*
*&CLASS LCL_SPLIT_TABLE IMPLEMENTATION
*&----------------------------------------------------------------------*
CLASS lcl_split_table IMPLEMENTATION.

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

        APPEND lr_sub_table      TO ex_splitted_table.
        ASSIGN lr_sub_table->*   TO <fs_target_table>.
        CHECK <fs_target_table>  IS ASSIGNED.

      ENDIF.

      APPEND <fs_line> TO <fs_target_table>.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

************************************************************************
*   Program name: Z_SPLIT_TABLE
*   Description : Dynamic Split of Table into Smaller Ones
*
*   Created   by: George Drakos
*
************************************************************************
REPORT z_split_table.

*&----------------------------------------------------------------------*
*& EXECUTABLE CODE
*&----------------------------------------------------------------------*
START-OF-SELECTION.

  SELECT FROM t001
    FIELDS t001~*
    INTO TABLE @DATA(lt_data).

  zcl_abap_projects=>split_table( EXPORTING im_table          = lt_data
                                            im_split_segment  = 25
                                  IMPORTING ex_splitted_table = DATA(lr_sub_tables) ).

  CHECK lr_sub_tables IS NOT INITIAL.

  LOOP AT lr_sub_tables ASSIGNING FIELD-SYMBOL(<fs_sub_table>).

  ENDLOOP.

END-OF-SELECTION.
*&----------------------------------------------------------------------*
*& END OF EXECUTABLE CODE
*&----------------------------------------------------------------------*

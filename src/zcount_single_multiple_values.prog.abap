************************************************************************
*   Program name: ZCOUNT_SINGLE_MULTIPLE_VALUES
*   Description : Count Single and Multiple Values of Internal Table Dynamically
*
*   Created   by: George Drakos
*
************************************************************************
REPORT zcount_single_multiple_values.

*&---------------------------------------------------------------------*
*& EXECUTABLE CODE
*&---------------------------------------------------------------------*
START-OF-SELECTION.

  SELECT FROM bkpf FIELDS bkpf~* INTO TABLE @DATA(lt_table) UP TO 10000 ROWS.

  zcl_abap_projects=>count_single_multiple_values( EXPORTING im_table           = lt_table
                                                             im_column_name     = 'USNAM'
                                                   IMPORTING ex_unique_values   = DATA(lo_unique_values)
                                                             ex_multiple_values = DATA(lo_multiple_values) ).

  CHECK lo_unique_values IS NOT INITIAL AND lo_multiple_values IS NOT INITIAL.

  ASSIGN lo_unique_values->* TO FIELD-SYMBOL(<fs_table_unique>).
  ASSIGN lo_multiple_values->* TO FIELD-SYMBOL(<fs_table_multiple>).

END-OF-SELECTION.

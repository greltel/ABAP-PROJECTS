************************************************************************
*   Program name: Z_DYNAMIC_LOCK_UNLOCK
*   Description : Dynamic Lock and Unlock of Database Table
*
*   Created   by: George Drakos
*
************************************************************************
REPORT z_dynamic_lock_unlock.

*&---------------------------------------------------------------------*
*& EXECUTABLE CODE
*&---------------------------------------------------------------------*
START-OF-SELECTION.

  DATA(ls_mara) = VALUE mara( matnr = '000000000000010001' ).

  DATA(re_lock_result) = zcl_abap_projects=>lock_table( iv_table_name = 'MARA'
                                                        iv_data       = ls_mara ).

  DATA(re_unlock_result) = zcl_abap_projects=>unlock_table( iv_table_name = 'MARA'
                                                            iv_data       = ls_mara ).

END-OF-SELECTION.

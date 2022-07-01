class ZCL_IM_SR_SAVE definition
  public
  final
  create public .

public section.

  interfaces /SCWM/IF_EX_SR_SAVE .
  interfaces IF_BADI_INTERFACE .
protected section.
private section.
ENDCLASS.



CLASS ZCL_IM_SR_SAVE IMPLEMENTATION.


  method /SCWM/IF_EX_SR_SAVE~AFTER_SAVE.
  endmethod.


  METHOD /scwm/if_ex_sr_save~before_save.

    BREAK-POINT ID zewmdevbook_422.

    LOOP AT it_bo_tu ASSIGNING FIELD-SYMBOL(<fs_bo_tu>).
      IF <fs_bo_tu>-bo_ref IS BOUND.
        TRY.
            <fs_bo_tu>-bo_ref->get_data(
               IMPORTING
                 ev_objstate = DATA(lv_state)
                 et_ident    = DATA(lt_ident) ).
          CATCH /scwm/cx_sr_error.
            CONTINUE.
        ENDTRY.
* 1. check changing indicator of object
        CHECK lv_state = wmesr_objstate_new
        OR    lv_state = wmesr_objstate_chg.
* 2. determine context
        CHECK <fs_bo_tu>-bo_ref->get_sr_act_state( ) =
        wmesr_act_state_active.
        CHECK <fs_bo_tu>-bo_ref->get_status_change_by_id(
        wmesr_status_check_in ) = abap_true.
* 3. check for pager
        TRY.
            DATA(ls_ident) = lt_ident[ idart = 'P' ].
          CATCH cx_sy_itab_line_not_found.
            DATA(lv_check) = 1.
        ENDTRY.
        IF ls_ident-ident IS INITIAL.
          lv_check = 1. "no pager
        ENDIF.
* 4. check for lic_plate
        <fs_bo_tu>-bo_ref->get_data(
          IMPORTING es_bo_tu_data = DATA(ls_bo_tu_data) ).
        IF ( ls_bo_tu_data-lic_plate         = ''
        OR   ls_bo_tu_data-lic_plate_country = '' )
        AND  lv_check = 1.
          lv_check = 3. "no pager and no lic_plate
        ELSEIF ( ls_bo_tu_data-lic_plate         = ''
        OR       ls_bo_tu_data-lic_plate_country = '' ).
          lv_check = 2. "no lic_plate
        ENDIF.
* 5. raise message
        CASE lv_check.
          WHEN 1. "no pager
            MESSAGE e001(zewmdevbook_422) INTO DATA(lv_msg).
          WHEN 2. "no lic_plate
            MESSAGE e002(zewmdevbook_422) INTO lv_msg.
          WHEN 3. "no pager and lic_plate
            MESSAGE e003(zewmdevbook_422) INTO lv_msg.
        ENDCASE.
* 6. add message to current log and raise exception
        IF NOT lv_check IS INITIAL.
          /scwm/cl_sr_bom=>so_log->add_message( ).
          RAISE EXCEPTION TYPE /scwm/cx_sr_error.
        ENDIF.
      ENDIF.
      CLEAR: lv_msg, lv_check.
    ENDLOOP.

  ENDMETHOD.
ENDCLASS.

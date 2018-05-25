create or replace package body ups.up_billing is

/*
  Note: all of this code should be considered temporary, until the new housing system is purchased
*/

    k_default_meal_plan             ps_stdnt_equtn_var.variable_char9%TYPE := 'MEMED';

-- =====================================================================================
  -- set tuition calc flag
  PROCEDURE flag_tuition_calc (p_emplid VARCHAR2, p_strm VARCHAR2) IS
    BEGIN
      UPDATE ps_stdnt_car_term t
      SET t.tuit_calc_req='Y'
      WHERE t.emplid = p_emplid
      AND t.strm = p_strm;
      COMMIT;
    END flag_tuition_calc;

-- =====================================================================================
  -- create empty SF equation variables rows
  PROCEDURE initialize_eqtn_vars (p_strm VARCHAR2) IS
    CURSOR wrk_cursor IS
    SELECT t.emplid
           ,t.acad_career
           ,t.institution
           ,strm
    FROM ps_stdnt_car_term t 
    WHERE t.strm=p_strm
    AND academic_load IN ('F','H','L');
  BEGIN
    FOR wrk_rec IN wrk_cursor LOOP
      -- insert empty rows, if none exists
      BEGIN
      INSERT INTO ps_stdnt_equtn_var
        (EMPLID,BILLING_CAREER,INSTITUTION,STRM
        ,VARIABLE_CHAR1,VARIABLE_CHAR2,VARIABLE_CHAR3,VARIABLE_CHAR4,VARIABLE_CHAR5,VARIABLE_CHAR6
        ,VARIABLE_CHAR7,VARIABLE_CHAR8,VARIABLE_CHAR9,VARIABLE_CHAR10,VARIABLE_FLAG1,VARIABLE_FLAG2
        ,VARIABLE_FLAG3,VARIABLE_FLAG4,VARIABLE_FLAG5,VARIABLE_FLAG6,VARIABLE_FLAG7,VARIABLE_FLAG8
        ,VARIABLE_FLAG9,VARIABLE_FLAG10,VARIABLE_NUM1,VARIABLE_NUM2,VARIABLE_NUM3,VARIABLE_NUM4
        ,VARIABLE_NUM5,VARIABLE_NUM6,VARIABLE_NUM7,VARIABLE_NUM8,VARIABLE_NUM9,VARIABLE_NUM10)
      VALUES (wrk_rec.emplid,wrk_rec.acad_career,wrk_rec.institution,wrk_rec.strm
        ,' ' ,' ' ,' ',' ' ,' ' ,' ' 
        ,' ' ,' ' ,' ' ,' ' ,'N' ,'N' 
        ,'N' ,'N' ,'N','N' ,'N' ,'N' 
        ,'N' ,'N' ,0,0 ,0 ,0 
        ,0 ,0 ,0,0 ,0 ,0 );
        EXCEPTION WHEN dup_val_on_index THEN NULL;
      END;
      COMMIT;
    END LOOP;
  END initialize_eqtn_vars;

-- =====================================================================================
  -- loading housing fee to char variable #10
  PROCEDURE upd_eqtn_vars_housing (p_strm VARCHAR2) IS
    v_curr_var10                ps_stdnt_equtn_var.variable_char10%TYPE;
    CURSOR wrk_cursor IS
    SELECT upsid
         ,(CASE WHEN bld.housing_category='A' AND rm.housing_rate='SNGL' THEN 'HSGRM'
           WHEN bld.housing_category='A' AND rm.housing_rate='STND' THEN 'HSTRM'
           WHEN bld.housing_category='A' AND rm.housing_rate='TRMB' THEN 'HTRMRM'
           WHEN bld.housing_category='A' AND rm.housing_rate='NEWH' THEN 'HNHRM'
           WHEN bld.housing_category='B' AND rm.housing_rate='SNGL' THEN 'HGKSGR'
           WHEN bld.housing_category='B' AND rm.housing_rate='STND' THEN 'HGRKRM'
           WHEN bld.housing_category='C' THEN 'HRHRM'
           END) PS_fee_code
    FROM  bed_assignment@cascade ba, bed@cascade, res_room@cascade rm, building@cascade bld, year_term@cascade trm
    WHERE up_check_date_overlap(trunc(trm.start_date), trunc(trm.end_date), trunc(ba.start_date), TRUNC(NVL(ba.charge_through,ba.end_date))) = 'Y'
    AND ba.bed_id = bed.bed_id
    AND bed.room_id = rm.room_id
    AND rm.building_code = bld.building_code
    AND trm.year_term = up_getcascade.year_term(p_strm)
    AND up_getps.emplid(upsid) IN (SELECT emplid
              FROM ps_stdnt_car_term t 
              WHERE t.strm=p_strm
              AND academic_load IN ('F','H','L') 
            );
    -- not in housing anymore but has housing variable set
    -- or not enrolled and has either housing or meal plan variables set
    CURSOR clr_cursor IS
    SELECT emplid
    FROM ps_stdnt_equtn_var
    WHERE strm=p_strm
    AND emplid NOT IN (SELECT up_getps.emplid(upsid)
            FROM  bed_assignment@cascade ba, bed@cascade, res_room@cascade rm, building@cascade bld, year_term@cascade trm
            WHERE up_check_date_overlap(trunc(trm.start_date), trunc(trm.end_date), trunc(ba.start_date), TRUNC(NVL(ba.charge_through,ba.end_date))) = 'Y'
              AND ba.bed_id = bed.bed_id
              AND bed.room_id = rm.room_id
              AND rm.building_code = bld.building_code
              AND trm.year_term = up_getcascade.year_term(p_strm) 
              )
    AND VARIABLE_CHAR10 <> ' '
    UNION
    SELECT emplid
    FROM ps_stdnt_equtn_var
    WHERE strm=p_strm
    AND emplid NOT IN (SELECT emplid
                FROM ps_stdnt_car_term t 
                WHERE t.strm=p_strm
                AND academic_load IN ('F','H','L') 
              )
    AND (VARIABLE_CHAR10 <> ' ' OR variable_char9 <> ' ');    
  BEGIN
    -- load housing fee if enrolled 
    FOR wrk_rec IN wrk_cursor LOOP
      BEGIN
        SELECT VARIABLE_CHAR10 INTO v_curr_var10
        FROM ps_stdnt_equtn_var
        WHERE strm = p_strm
        AND emplid = up_getps.emplid(wrk_rec.upsid);
        EXCEPTION WHEN no_data_found THEN v_curr_var10 := ' ';
      END;
      IF v_curr_var10 <> wrk_rec.ps_fee_code
      THEN
            UPDATE ps_stdnt_equtn_var
            SET VARIABLE_CHAR10 = wrk_rec.ps_fee_code
            WHERE strm=p_strm
            AND emplid = up_getps.emplid(wrk_rec.upsid);
            flag_tuition_calc(up_getps.emplid(wrk_rec.upsid), p_strm);
      END IF;
      COMMIT;
    END LOOP;
    -- clear variable #9 and #10 if not in housing anymore or not enrolled anymore
    FOR clr_rec IN clr_cursor LOOP
      UPDATE ps_stdnt_equtn_var
      SET VARIABLE_CHAR10 = ' ', variable_char9 = ' '
      WHERE strm=p_strm
      AND emplid = clr_rec.emplid;
      flag_tuition_calc(clr_rec.emplid, p_strm);
      -- clear meal plan in con_person_session
      con_person_session_api.store_meal_plan(NULL, clr_rec.emplid, NULL, p_strm);
      COMMIT;
    END LOOP;  
  END upd_eqtn_vars_housing;

-- =====================================================================================
  -- loading default meal plan to char variable #9 for those in housing that requires a meal plan
  PROCEDURE upd_eqtn_vars_dflt_meal (p_strm VARCHAR2) IS
    v_curr_meal_plan                VARCHAR2(3);
    CURSOR wrk_cursor IS
    SELECT DISTINCT upsid
    FROM  bed_assignment@cascade ba, bed@cascade, res_room@cascade rm, building@cascade bld, year_term@cascade trm
    WHERE up_check_date_overlap(greatest(trunc(trm.start_date),trunc(sysdate)), trunc(trm.end_date), trunc(ba.start_date), TRUNC(NVL(ba.charge_through,ba.end_date))) = 'Y'
    AND ba.bed_id = bed.bed_id
    AND bed.room_id = rm.room_id
    AND rm.building_code = bld.building_code
    AND trm.year_term = up_getcascade.year_term(p_strm)
    AND bld.housing_category IN ('A','B')
    AND up_getps.emplid(upsid) IN (SELECT emplid
              FROM ps_stdnt_car_term t 
              WHERE t.strm=p_strm
              AND academic_load IN ('F','H','L') 
            );
  BEGIN
    FOR wrk_rec IN wrk_cursor LOOP
      -- get current value
      BEGIN
        SELECT meal_plan
        INTO v_curr_meal_plan
        FROM con_person_session@cascade
        WHERE year_term = up_getcascade.year_term(p_strm)
        AND upsid = wrk_rec.upsid;
        EXCEPTION WHEN no_data_found THEN v_curr_meal_plan := NULL;
      END;
      -- set default plan if none already assigned
      IF v_curr_meal_plan IS NULL
      THEN -- store meal plan in char #9
           UPDATE ps_stdnt_equtn_var
           SET VARIABLE_CHAR9 = k_default_meal_plan
           WHERE strm = p_strm
           AND emplid = up_getps.emplid(wrk_rec.upsid);
           flag_tuition_calc(up_getps.emplid(wrk_rec.upsid), p_strm);
           -- store meal plan in con_person_session, where student will be able to change it online
           con_person_session_api.store_meal_plan(NULL, wrk_rec.upsid, 2, p_strm);
           COMMIT;
      END IF;
    END LOOP;
  END upd_eqtn_vars_dflt_meal;

-- =====================================================================================
  -- loading meal plan requests to char variable #9
  PROCEDURE upd_eqtn_vars_meal_plan (p_strm VARCHAR2) IS
    v_housing_category              VARCHAR2(1);
    v_meal_plan                     ps_stdnt_equtn_var.variable_char9%TYPE;
    v_curr_var9                ps_stdnt_equtn_var.variable_char9%TYPE;
    CURSOR wrk_cursor IS
    SELECT DISTINCT upsid, meal_plan
    FROM  con_person_session@cascade cps
    WHERE cps.year_term = up_getcascade.year_term(p_strm)
    AND meal_plan IS NOT NULL
    AND up_getps.emplid(upsid) IN (SELECT emplid
                FROM ps_stdnt_car_term t 
                WHERE t.strm=p_strm
                AND academic_load IN ('F','H','L') 
              );
    -- if meal plan was loaded to PS then clear it if student changed mind about it in Cascade
    CURSOR clr_cursor IS
    SELECT DISTINCT upsid, meal_plan
    FROM  con_person_session@cascade cps
    WHERE cps.year_term = up_getcascade.year_term(p_strm)
    AND meal_plan IS NULL
    AND up_getps.emplid(upsid) IN (SELECT emplid
                FROM ps_stdnt_equtn_var t 
                WHERE t.strm=p_strm
                AND VARIABLE_CHAR9 <> ' '
              )
    AND up_getps.emplid(upsid) IN (SELECT emplid
                FROM ps_stdnt_car_term t 
                WHERE t.strm=p_strm
                AND academic_load IN ('F','H','L') 
              );
  BEGIN
      -- load voluntary meal plans for everyone
      -- load meal plan changes (changes to default meal plan) after confirmation
    FOR wrk_rec IN wrk_cursor LOOP
      v_housing_category := NULL;
      -- get housing type, to determine whether this is loaded now or later
      BEGIN
        SELECT DISTINCT bld.housing_category
        INTO v_housing_category
        FROM  bed_assignment@cascade ba, bed@cascade, res_room@cascade rm, building@cascade bld, year_term@cascade trm
        WHERE up_check_date_overlap(greatest(trunc(trm.start_date),trunc(sysdate)), trunc(trm.end_date), trunc(ba.start_date), TRUNC(NVL(ba.charge_through,ba.end_date))) = 'Y'
        AND ba.bed_id = bed.bed_id
        AND bed.room_id = rm.room_id
        AND rm.building_code = bld.building_code
        AND trm.year_term = up_getcascade.year_term(p_strm)
        AND ba.upsid = wrk_rec.upsid;
        EXCEPTION WHEN no_data_found THEN v_housing_category := NULL;
      END;
      -- leave default meal plan if before confirmation date
      -- load voluntary meal plans though
      IF v_housing_category IN ('A','B')
      AND ( (p_strm = '2138' AND trunc(SYSDATE) <= to_date('08/05/2013','mm/dd/yyyy'))
        -- OR (p_strm = '2144' AND trunc(SYSDATE) <= to_date('01/05/2014','mm/dd/yyyy'))
         )
      THEN v_meal_plan := k_default_meal_plan;
      ELSE SELECT (CASE WHEN wrk_rec.meal_plan = '1' THEN 'MELGHT'
                        WHEN wrk_rec.meal_plan = '2' THEN 'MEMED'
                        WHEN wrk_rec.meal_plan = '3' THEN 'MEHRTY'
                        WHEN wrk_rec.meal_plan = '4' THEN 'MEMEGA'
                        WHEN wrk_rec.meal_plan = '7' THEN 'MEOFF'
                        ELSE ' '
                   END)
           INTO v_meal_plan
           FROM dual; 
      END IF;
      BEGIN
        SELECT VARIABLE_CHAR9 INTO v_curr_var9
        FROM ps_stdnt_equtn_var
        WHERE strm = p_strm
        AND emplid = up_getps.emplid(wrk_rec.upsid);
        EXCEPTION WHEN no_data_found THEN v_curr_var9 := ' ';
      END;
      IF v_curr_var9 <> v_meal_plan
      THEN 
            UPDATE ps_stdnt_equtn_var
            SET VARIABLE_CHAR9 = v_meal_plan 
            WHERE strm = p_strm
            AND emplid = up_getps.emplid(wrk_rec.upsid)
            AND VARIABLE_CHAR9 <> v_meal_plan;
            flag_tuition_calc(up_getps.emplid(wrk_rec.upsid), p_strm);
      END IF;
      COMMIT;
    END LOOP;
    -- clear meal plan if student changed their mind
    FOR clr_rec IN clr_cursor LOOP
      UPDATE ps_stdnt_equtn_var
      SET VARIABLE_CHAR9 = ' ' 
      WHERE strm = p_strm
      AND emplid = up_getps.emplid(clr_rec.upsid);
      flag_tuition_calc(up_getps.emplid(clr_rec.upsid), p_strm);
      COMMIT;
    END LOOP;
  END upd_eqtn_vars_meal_plan;


-- =====================================================================================
  -- run all steps together for 2148 term
  PROCEDURE run_fall_billing IS
    v_strm  VARCHAR2(4) := '2148';
  BEGIN
    IF trunc(SYSDATE) between to_date('05/01/2014','mm/dd/yyyy') AND to_date('09/16/2014','mm/dd/yyyy')
    THEN 
        initialize_eqtn_vars(v_strm);
        upd_eqtn_vars_housing(v_strm);
        upd_eqtn_vars_dflt_meal(v_strm);
        upd_eqtn_vars_meal_plan(v_strm);
    END IF;
    COMMIT;
  END run_fall_billing;

-- =====================================================================================
  -- run all steps together for 2154 term
  PROCEDURE run_spring_billing IS
    v_strm  VARCHAR2(4) := '2154';
  BEGIN
    IF trunc(SYSDATE) between to_date('12/01/2014','mm/dd/yyyy') AND to_date('02/03/2015','mm/dd/yyyy')
    THEN 
        initialize_eqtn_vars(v_strm);
        upd_eqtn_vars_housing(v_strm);
        upd_eqtn_vars_dflt_meal(v_strm);
        upd_eqtn_vars_meal_plan(v_strm);
    END IF;
    COMMIT;
  END run_spring_billing;

end up_billing;
/

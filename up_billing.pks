create or replace package ups.up_billing is

  -- Author  : KSPIESE
  -- Created : 7/3/2013 8:13:07 AM
  -- Purpose : temporary code for interfacing billing with Cascade data
  
  -- create empty SF equation variables rows
  PROCEDURE initialize_eqtn_vars (p_strm VARCHAR2);

  -- loading housing fee to char variable #10
  PROCEDURE upd_eqtn_vars_housing (p_strm VARCHAR2);

  -- loading default meal plan to char variable #9
  PROCEDURE upd_eqtn_vars_dflt_meal (p_strm VARCHAR2);

  -- loading meal plan requests to char variable #9
  PROCEDURE upd_eqtn_vars_meal_plan (p_strm VARCHAR2);


  -- run all steps together for 2138 term
  PROCEDURE run_fall_billing;
  PROCEDURE run_spring_billing;
  
end up_billing;
/

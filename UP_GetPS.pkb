create or replace package body ups.UP_GetPS is
-------------------------------------------------------------------------------------
-- These functions translate non-PeopleSoft values into valid codes for PeopleSoft.
-- Typically, each function name matches the target field, and the input paramenter name(s) suggest the source data.
--
--	 9/27/2012	Jeff	Created in consultation with Carol
--	11/30/2012	Jeff	Changed EMPLID from "add 3000000" rule to "use UPSID" rule
--	 4/8/2013	Jeff	Changed cnvdate to current date instead of 1/1/2013
-------------------------------------------------------------------------------------

function emplid
(	p_upsid	number
) return varchar2 
is
begin
	return(to_char(p_upsid));
end emplid;

-------------------------------------------------------------------------------------
function strm
( p_year_term year_term.year_term%type
) return varchar2
is
 v_strm varchar2(4);
 v_year number(4);
 v_term number(1);
begin
  IF p_year_term between 19001 and 29999
  then v_year := trunc(p_year_term/10);
       v_term := mod(p_year_term,10);
       v_strm := (CASE WHEN v_YEAR<=1999 THEN '1' 
                                ELSE '2' END)||
                  to_char(MOD(v_YEAR,100),'fm00')||
                  to_char(v_term*2);
  end IF;
  return(v_strm);
end strm;

end UP_GetPS;
/

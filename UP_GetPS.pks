create or replace package ups.UP_GetPS is
-------------------------------------------------------------------------------------
-- These functions translate non-PeopleSoft values into valid codes for PeopleSoft.
-- Typically, each function name matches the target field, and the input parameter name(s) suggest the source data.
-------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
function emplid
(	p_upsid	number
) return varchar2;

-------------------------------------------------------------------------------------
function strm
( p_year_term year_term.year_term%type
) return varchar2;

end UP_GetPS;
/

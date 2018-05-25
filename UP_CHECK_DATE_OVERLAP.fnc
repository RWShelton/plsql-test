CREATE OR REPLACE FUNCTION UPS.UP_CHECK_DATE_OVERLAP (i_start1 DATE, i_end1 DATE,
					       i_start2 DATE, i_end2 DATE)
      RETURN CHAR IS 
        overlapping  VARCHAR2(1)  := 'N';

  start1   DATE  := TRUNC(i_start1);
  end1     DATE  := TRUNC(i_end1);
  start2   DATE  := TRUNC(i_start2);
  end2     DATE  := TRUNC(i_end2);

BEGIN
/*
REM----------------------------------------------------------------------------
REM   CHECK_DATE_OVERLAP        for Universal use
REM                       
REM   This SQL function returns a flag indicating whether the input date
REM   ranges are overlapping or not.
REM                       
REM   PARAMETERS:  (1) I_START1
REM      (2) I_END1
REM                     (3) I_START2
REM                     (3) I_END2
REM									     
REM   to execute this database procedure:
REM			CHECK_DATE_OVERLAP('01/01/1997','','02/01/1997','')
REM									     
REM----------------------------------------------------------------------------
*/

  --NOTE: both input start dates must be filled in
  --if not, then return an error flag
  IF start1 IS NULL OR start2 IS NULL
  THEN overlapping := 'E';
       GOTO end_of_function;
  END IF;

  --check for overlap
  IF (end1 IS NULL AND end2 IS NULL)
     OR (end1 IS NULL AND start1 <= end2)
     OR (end2 IS NULL AND start2 <= end1)
     OR (start1 BETWEEN start2 AND end2)
     OR (start2 BETWEEN start1 AND end1)
     OR (start1 <= end2 AND end1 >= start2)
  THEN overlapping := 'Y';
  END IF; 

  <<end_of_function>>
  RETURN overlapping;

END UP_CHECK_DATE_OVERLAP;
/

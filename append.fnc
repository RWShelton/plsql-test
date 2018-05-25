CREATE OR REPLACE FUNCTION UPS.append (pre_field VARCHAR2,
                                   in_string VARCHAR2, 
                                   post_field VARCHAR2)
      RETURN VARCHAR2 IS
        out_string      VARCHAR2(32760);
BEGIN

  --if our input is null, then leave it, otherwise translate it
  IF in_string IS NULL
  THEN out_string := NULL;
  ELSE out_string := pre_field||in_string||post_field;
  END IF;

RETURN(out_string);

END append;
/

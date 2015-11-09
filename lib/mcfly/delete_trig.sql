CREATE OR REPLACE FUNCTION "tr_delete" ()
  RETURNS TRIGGER
AS $$

DECLARE
  whodunnit int;
  now timestamp;

BEGIN
  IF OLD.obsoleted_dt <> 'infinity' THEN
     RAISE EXCEPTION 'can not delete old row version';
  END IF;

  SHOW mcfly.whodunnit INTO whodunnit;

  now = now();

  EXECUTE 'UPDATE ' || TG_RELID::regclass ||
  ' SET obsoleted_dt = $1, o_user_id = $2 where id = $3.id'
  USING now, whodunnit, OLD;

  RETURN NULL; -- the row is not actually deleted
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS %{table}_delete ON %{table};
CREATE TRIGGER "%{table}_delete" BEFORE DELETE ON "%{table}" FOR EACH ROW
EXECUTE PROCEDURE "tr_delete"();

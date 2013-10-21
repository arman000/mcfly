CREATE OR REPLACE FUNCTION "%{table}_delete" ()
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

  UPDATE "%{table}"
  SET obsoleted_dt = now, o_user_id = whodunnit WHERE id = OLD.id;

  RETURN NULL; -- the row is not actually deleted
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS %{table}_delete ON %{table};
CREATE TRIGGER "%{table}_delete" BEFORE DELETE ON "%{table}" FOR EACH ROW
EXECUTE PROCEDURE "%{table}_delete"();

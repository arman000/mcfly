CREATE OR REPLACE FUNCTION "%{table}_update" ()
  RETURNS TRIGGER
AS $$
DECLARE

BEGIN
  IF OLD.obsoleted_dt <> 'infinity' THEN
     RAISE EXCEPTION 'can not update obsoleted append-only row';
  END IF;

  -- If obsoleted_dt is being set, assume that the row is being
  -- obsoleted.  We return the OLD row so that other field updates are
  -- ignored.  This is used by DELETE.
  IF NEW.obsoleted_dt <> 'infinity' THEN
     OLD.o_user_id = NEW.o_user_id;
     OLD.obsoleted_dt = NEW.obsoleted_dt;
     return OLD;
  END IF;

  RAISE EXCEPTION 'can not update append-only row';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS %{table}_update ON %{table};
CREATE TRIGGER "%{table}_update" BEFORE UPDATE ON "%{table}" FOR EACH ROW
EXECUTE PROCEDURE "%{table}_update"();

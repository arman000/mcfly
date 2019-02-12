CREATE OR REPLACE FUNCTION "tr_update" ()
  RETURNS TRIGGER
AS $$
DECLARE
  new_id INT4;
  whodunnit int;

BEGIN
  IF OLD.obsoleted_dt <> 'infinity' THEN
     RAISE EXCEPTION 'can not modify old row version';
  END IF;

  -- If obsoleted_dt is being set, assume that the row is being
  -- obsoleted.  We return the OLD row so that other field updates are
  -- ignored.  This is used by DELETE.
  IF NEW.obsoleted_dt <> 'infinity' THEN
     OLD.o_user_id = NEW.o_user_id;
     OLD.obsoleted_dt = NEW.obsoleted_dt;
     return OLD;
  END IF;

  -- new_id is a new primary key that we'll use for the obsoleted row.
  SELECT nextval(pg_get_serial_sequence(TG_TABLE_NAME, 'id')) INTO new_id;

  OLD.id = new_id;
  OLD.group_id = NEW.id;
  OLD.o_user_id = NEW.user_id;

  -- FIXME: The following IF/ELSE handles cases where created_dt is
  -- sent in on update. This is only useful for debugging.  Consider
  -- removing the surronding IF (and ELSE part) for production
  -- version.
  IF NEW.created_dt = OLD.created_dt THEN
    -- Set the modified row's created_dt.  The obsoleted_dt field was
    -- already infinity, so we don't need to set it.
    NEW.created_dt = now();
    OLD.obsoleted_dt = now();
  ELSE
    IF NEW.created_dt <= OLD.created_dt THEN
      RAISE EXCEPTION 'new created_dt must be greater than old';
    END IF;

    OLD.obsoleted_dt = NEW.created_dt;
  END IF;

  -- insert rec, note that the insert trigger will get called.  The
  -- obsoleted_dt is set so INSERT should not do anything with this row.
  EXECUTE 'INSERT INTO ' || TG_RELID::regclass || ' values (($1).*)' USING OLD;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS %{table}_update ON %{table};
CREATE TRIGGER "%{table}_update" BEFORE UPDATE ON "%{table}" FOR EACH ROW
EXECUTE PROCEDURE "tr_update"();

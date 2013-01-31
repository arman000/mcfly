CREATE OR REPLACE FUNCTION "%{table}_insert" ()
  RETURNS TRIGGER
AS $$
BEGIN
  -- "obsoleted_dt" is set when a history row is created by
  -- UPDATE. Leave it alone.
  IF NEW.obsoleted_dt <> 'infinity' THEN
     RETURN NEW;
  END IF;

  NEW.obsoleted_dt = 'infinity';
  NEW.group_id = NEW.id;

  -- FIXME: Handle cases where created_dt is sent in on creation. This
  -- is only useful for debugging.  Consider removing the surronding
  -- IF for production version.
  IF NEW.created_dt IS NULL THEN
    NEW.created_dt = 'now()';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS %{table}_insert ON %{table};
CREATE TRIGGER "%{table}_insert" BEFORE INSERT ON "%{table}" FOR EACH ROW
EXECUTE PROCEDURE "%{table}_insert"();

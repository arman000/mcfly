-- Add constraint to make sure o_user_id is set iff obsoleted_dt is
-- not infinity (i.e. object is obsoleted).
ALTER TABLE "%{table}" ADD CONSTRAINT check_o_user
CHECK ((obsoleted_dt = 'Infinity') = (o_user_id IS NULL));

-- obsoleted_dt > created_dt should be enforced -- however, there are
-- many instances of obsoleted_dt=created_dt in our existing apps.
ALTER TABLE "%{table}" ADD CONSTRAINT check_bad_obsolete
CHECK (obsoleted_dt >= created_dt);

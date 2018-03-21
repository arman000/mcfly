class McflyMigration < ActiveRecord::Migration[4.2]
  INSERT_TRIG, UPDATE_TRIG, UPDATE_APPEND_ONLY_TRIG, DELETE_TRIG, CONSTRAINT =
    %w{
        insert_trig
        update_trig
        update_append_only_trig
        delete_trig
        constraint
    }.map { |f|
    File.read(File.dirname(__FILE__) + "/#{f}.sql")
  }

  TRIGS = [INSERT_TRIG, UPDATE_TRIG, DELETE_TRIG]

  def add_sql(table_name, include_const)
    sql_list = self.class::TRIGS +
      (include_const ? [self.class::CONSTRAINT] : [])

    sql_list.each { |sql|
      execute sql % {table: table_name}
    }
  end

  # TODO: Remove this in 4.0 since we can check direction
  def migrate(direction)
    @dir = direction
    super
  end

  def create_table(table_name, options = {}, &block)
    super { |t|
      t.integer :group_id, null: false
      # can't use created_at/updated_at as those are automatically
      # filled by ActiveRecord.
      t.timestamp :created_dt, null: false
      t.timestamp :obsoleted_dt, null: false
      t.references :user, null: false
      t.references :o_user
      block.call(t)
    }

    add_sql(table_name, true) if @dir == :up
  end
end

class McflyAppendOnlyMigration < McflyMigration
  # append-only update trigger disallows updates
  TRIGS = [INSERT_TRIG, UPDATE_APPEND_ONLY_TRIG, DELETE_TRIG]
end

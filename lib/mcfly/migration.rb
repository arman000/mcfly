class McflyMigration < ActiveRecord::Migration
  INSERT_TRIG, UPDATE_TRIG, UPDATE_APPEND_ONLY_TRIG, DELETE_TRIG =
    %w{insert_trig update_trig update_append_only_trig delete_trig}.map { |f|
    File.read(File.dirname(__FILE__) + "/#{f}.sql")
  }

  TRIGS = [INSERT_TRIG, UPDATE_TRIG, DELETE_TRIG]

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

    self.class::TRIGS.each {|sql| execute sql % {table: table_name}}
  end
end

class McflyAppendOnlyMigration < McflyMigration
  # append-only update trigger disallows updates
  TRIGS = [INSERT_TRIG, UPDATE_APPEND_ONLY_TRIG, DELETE_TRIG]
end

# frozen_string_literal: true

class CreateSecurityInstruments < McflyAppendOnlyMigration
  def change
    create_table :security_instruments do |t|
      t.string :name, null: false
      t.string :settlement_class, limit: 1, null: false
    end
  end
end

require 'mcfly'

class CreateMarketPrices < McFlyMigration
  def change
    create_table :market_prices do |t|
      t.references :security_instrument, null: false
      t.decimal :coupon, null: false
      t.integer :settlement_mm, null: false
      t.integer :settlement_yy, null: false
      # NULL indicates unknown price
      t.decimal :price
    end
  end
end

# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'plpgsql'

  create_table 'market_prices', force: :cascade do |t|
    t.integer 'group_id', null: false
    t.datetime 'created_dt', null: false
    t.datetime 'obsoleted_dt', null: false
    t.bigint 'user_id', null: false
    t.bigint 'o_user_id'
    t.bigint 'security_instrument_id', null: false
    t.decimal 'coupon', null: false
    t.integer 'settlement_mm', null: false
    t.integer 'settlement_yy', null: false
    t.decimal 'price'
    t.index ['o_user_id'], name: 'index_market_prices_on_o_user_id'
    t.index ['security_instrument_id'], name: 'index_market_prices_on_security_instrument_id'
    t.index ['user_id'], name: 'index_market_prices_on_user_id'
  end

  create_table 'security_instruments', force: :cascade do |t|
    t.integer 'group_id', null: false
    t.datetime 'created_dt', null: false
    t.datetime 'obsoleted_dt', null: false
    t.bigint 'user_id', null: false
    t.bigint 'o_user_id'
    t.string 'name', null: false
    t.string 'settlement_class', limit: 1, null: false
    t.index ['o_user_id'], name: 'index_security_instruments_on_o_user_id'
    t.index ['user_id'], name: 'index_security_instruments_on_user_id'
  end
end

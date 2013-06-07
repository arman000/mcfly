# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 2) do

  create_table "market_prices", :force => true do |t|
    t.integer  "group_id",               :null => false
    t.datetime "created_dt",             :null => false
    t.datetime "obsoleted_dt",           :null => false
    t.integer  "user_id",                :null => false
    t.integer  "o_user_id"
    t.integer  "security_instrument_id", :null => false
    t.decimal  "coupon",                 :null => false
    t.integer  "settlement_mm",          :null => false
    t.integer  "settlement_yy",          :null => false
    t.decimal  "price"
  end

  create_table "security_instruments", :force => true do |t|
    t.integer  "group_id",                      :null => false
    t.datetime "created_dt",                    :null => false
    t.datetime "obsoleted_dt",                  :null => false
    t.integer  "user_id",                       :null => false
    t.integer  "o_user_id"
    t.string   "name",                          :null => false
    t.string   "settlement_class", :limit => 1, :null => false
  end

end

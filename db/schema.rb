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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_08_15_153338) do

  create_table "orders", force: :cascade do |t|
    t.integer "amount_cents"
    t.string "first_name"
    t.string "last_name"
    t.string "street_line_1"
    t.string "street_line_2"
    t.string "postal_code"
    t.string "region"
    t.string "city"
    t.string "country"
    t.string "email_address"
    t.string "number"
    t.string "permalink"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "payment_intent_id"
    t.datetime "paid_at"
    t.index ["number"], name: "index_orders_on_number", unique: true
    t.index ["permalink"], name: "index_orders_on_permalink", unique: true
  end

end

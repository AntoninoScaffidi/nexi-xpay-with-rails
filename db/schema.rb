# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_13_063729) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "EUR", null: false
    t.string "guest_email", null: false
    t.string "guest_first_name", null: false
    t.string "guest_last_name", null: false
    t.string "guest_phone"
    t.string "nexi_authorization_code"
    t.jsonb "nexi_raw_response"
    t.string "nexi_transaction_id"
    t.string "order_number", null: false
    t.datetime "paid_at"
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "status", default: 0, null: false
    t.decimal "total_amount", precision: 10, scale: 2, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["nexi_transaction_id"], name: "index_orders_on_nexi_transaction_id", unique: true
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["product_id"], name: "index_orders_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.boolean "purchasable", default: false, null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "orders", "products"
end

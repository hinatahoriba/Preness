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

ActiveRecord::Schema[8.0].define(version: 2026_02_12_150513) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "mock_tests", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.integer "price_cents", null: false
    t.string "stripe_price_id"
    t.string "difficulty", default: "medium", null: false
    t.integer "time_limit_minutes", default: 180, null: false
    t.boolean "published", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["published"], name: "index_mock_tests_on_published"
  end

  create_table "purchases", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "mock_test_id", null: false
    t.string "stripe_payment_intent_id"
    t.string "stripe_checkout_session_id"
    t.integer "amount_cents", null: false
    t.string "currency", default: "jpy", null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mock_test_id"], name: "index_purchases_on_mock_test_id"
    t.index ["status"], name: "index_purchases_on_status"
    t.index ["stripe_payment_intent_id"], name: "index_purchases_on_stripe_payment_intent_id"
    t.index ["user_id", "mock_test_id"], name: "index_purchases_on_user_id_and_mock_test_id", unique: true
    t.index ["user_id"], name: "index_purchases_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.string "stripe_price_id"
    t.string "status", default: "inactive", null: false
    t.datetime "trial_ends_at"
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.datetime "canceled_at"
    t.datetime "ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["stripe_customer_id"], name: "index_subscriptions_on_stripe_customer_id"
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id"
    t.index ["user_id"], name: "index_subscriptions_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username", default: "", null: false
    t.boolean "terms_agreed", default: false, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "purchases", "mock_tests"
  add_foreign_key "purchases", "users"
  add_foreign_key "subscriptions", "users"
end

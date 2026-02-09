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

ActiveRecord::Schema[8.0].define(version: 2026_02_09_110000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "exams", force: :cascade do |t|
    t.string "title", null: false
    t.integer "price", null: false
    t.string "stripe_price_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "plan", default: "trial", null: false
    t.string "status", default: "active", null: false
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.string "stripe_price_id"
    t.datetime "trial_started_at"
    t.datetime "trial_ends_at"
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.boolean "cancel_at_period_end", default: false, null: false
    t.datetime "canceled_at"
    t.datetime "ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan"], name: "index_subscriptions_on_plan"
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["stripe_customer_id"], name: "index_subscriptions_on_stripe_customer_id", unique: true, where: "(stripe_customer_id IS NOT NULL)"
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id", unique: true, where: "(stripe_subscription_id IS NOT NULL)"
    t.index ["user_id"], name: "index_subscriptions_on_user_id", unique: true
    t.check_constraint "plan::text <> 'trial'::text OR trial_ends_at IS NOT NULL", name: "subscriptions_trial_ends_at_required_for_trial"
    t.check_constraint "plan::text = ANY (ARRAY['trial'::character varying::text, 'premium'::character varying::text])", name: "subscriptions_plan_check"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying::text, 'past_due'::character varying::text, 'canceled'::character varying::text])", name: "subscriptions_status_check"
  end

  create_table "user_exams", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "exam_id", null: false
    t.string "stripe_checkout_session_id"
    t.string "stripe_payment_intent_id"
    t.string "status", default: "pending", null: false
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exam_id"], name: "index_user_exams_on_exam_id"
    t.index ["status"], name: "index_user_exams_on_status"
    t.index ["stripe_checkout_session_id"], name: "index_user_exams_on_stripe_checkout_session_id"
    t.index ["stripe_payment_intent_id"], name: "index_user_exams_on_stripe_payment_intent_id"
    t.index ["user_id", "exam_id"], name: "index_user_exams_on_user_id_and_exam_id", unique: true
    t.index ["user_id"], name: "index_user_exams_on_user_id"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'paid'::character varying::text, 'failed'::character varying::text])", name: "user_exams_status_check"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "subscriptions", "users"
  add_foreign_key "user_exams", "exams"
  add_foreign_key "user_exams", "users"
end

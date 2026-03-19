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

ActiveRecord::Schema[8.0].define(version: 2026_03_19_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "answers", force: :cascade do |t|
    t.bigint "attempt_id", null: false
    t.bigint "question_id", null: false
    t.string "selected_choice"
    t.boolean "is_correct"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "skipped", default: false, null: false
    t.index ["attempt_id", "question_id"], name: "index_answers_on_attempt_id_and_question_id", unique: true
    t.index ["attempt_id"], name: "index_answers_on_attempt_id"
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "attempts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "mockable_type", null: false
    t.bigint "mockable_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mockable_type", "mockable_id"], name: "index_attempts_on_mockable"
    t.index ["user_id", "mockable_type", "mockable_id"], name: "index_attempts_on_user_id_and_mock", unique: true, where: "((mockable_type)::text = 'Mock'::text)"
    t.index ["user_id", "mockable_type", "mockable_id"], name: "index_attempts_on_user_id_and_mockable"
    t.index ["user_id"], name: "index_attempts_on_user_id"
  end

  create_table "exercises", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

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

  create_table "mocks", force: :cascade do |t|
    t.string "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "parts", force: :cascade do |t|
    t.bigint "section_id", null: false
    t.string "part_type", null: false
    t.integer "display_order", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["section_id"], name: "index_parts_on_section_id"
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

  create_table "question_sets", force: :cascade do |t|
    t.bigint "part_id", null: false
    t.text "passage"
    t.string "conversation_audio_url"
    t.integer "display_order", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "conversation_text"
    t.index ["part_id"], name: "index_question_sets_on_part_id"
  end

  create_table "questions", force: :cascade do |t|
    t.bigint "question_set_id", null: false
    t.integer "display_order", null: false
    t.text "question_text", null: false
    t.string "question_audio_url"
    t.text "choice_a", null: false
    t.text "choice_b", null: false
    t.text "choice_c", null: false
    t.text "choice_d", null: false
    t.string "correct_choice", null: false
    t.text "explanation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_set_id"], name: "index_questions_on_question_set_id"
  end

  create_table "sections", force: :cascade do |t|
    t.string "sectionable_type", null: false
    t.bigint "sectionable_id", null: false
    t.string "section_type", null: false
    t.integer "display_order", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sectionable_type", "sectionable_id"], name: "index_sections_on_sectionable"
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

  create_table "user_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "nickname"
    t.string "affiliation"
    t.boolean "study_abroad_plan"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "last_name"
    t.string "first_name"
    t.string "last_name_kana"
    t.string "first_name_kana"
    t.date "date_of_birth"
    t.integer "itp_current_score"
    t.integer "itp_target_score"
    t.string "eiken_grade"
    t.integer "toeic_score"
    t.integer "toefl_ibt_score"
    t.decimal "ielts_score", precision: 2, scale: 1
    t.index ["user_id"], name: "index_user_profiles_on_user_id"
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
    t.boolean "terms_agreed", default: false, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "answers", "attempts"
  add_foreign_key "answers", "questions"
  add_foreign_key "attempts", "users"
  add_foreign_key "parts", "sections"
  add_foreign_key "purchases", "mock_tests"
  add_foreign_key "purchases", "users"
  add_foreign_key "question_sets", "parts"
  add_foreign_key "questions", "question_sets"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "user_profiles", "users"
end

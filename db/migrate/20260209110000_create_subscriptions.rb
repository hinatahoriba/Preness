class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }

      # Plan: this service supports only trial and premium.
      t.string :plan, null: false, default: "trial"
      t.string :status, null: false, default: "active"

      # Stripe identifiers.
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
      t.string :stripe_price_id

      # Billing lifecycle.
      t.datetime :trial_started_at
      t.datetime :trial_ends_at
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.boolean :cancel_at_period_end, null: false, default: false
      t.datetime :canceled_at
      t.datetime :ends_at

      t.timestamps null: false
    end

    add_index :subscriptions, :plan
    add_index :subscriptions, :status
    add_index :subscriptions, :stripe_customer_id, unique: true, where: "stripe_customer_id IS NOT NULL"
    add_index :subscriptions, :stripe_subscription_id, unique: true, where: "stripe_subscription_id IS NOT NULL"

    add_check_constraint :subscriptions, "plan IN ('trial', 'premium')", name: "subscriptions_plan_check"
    add_check_constraint :subscriptions, "status IN ('active', 'past_due', 'canceled')", name: "subscriptions_status_check"
    add_check_constraint :subscriptions, "(plan <> 'trial') OR (trial_ends_at IS NOT NULL)", name: "subscriptions_trial_ends_at_required_for_trial"
  end
end

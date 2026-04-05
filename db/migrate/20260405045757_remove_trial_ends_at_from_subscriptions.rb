class RemoveTrialEndsAtFromSubscriptions < ActiveRecord::Migration[8.0]
  def change
    remove_column :subscriptions, :trial_ends_at, :datetime
  end
end

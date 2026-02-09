class CreateExams < ActiveRecord::Migration[8.0]
  def change
    create_table :exams do |t|
      t.string :title, null: false
      t.integer :price, null: false
      t.string :stripe_price_id

      t.timestamps null: false
    end
  end
end

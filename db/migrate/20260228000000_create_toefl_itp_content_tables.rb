# frozen_string_literal: true

class CreateToeflItpContentTables < ActiveRecord::Migration[8.0]
  def up
    create_table :mocks do |t|
      t.string :title, null: false
      t.timestamps null: false
    end unless table_exists?(:mocks)

    create_table :exercises do |t|
      t.timestamps null: false
    end unless table_exists?(:exercises)

    create_table :sections do |t|
      t.references :sectionable, null: false, polymorphic: true
      t.string :section_type, null: false
      t.integer :display_order, null: false
      t.timestamps null: false
    end unless table_exists?(:sections)

    add_index :sections, %i[sectionable_type sectionable_id] unless index_exists?(:sections, %i[sectionable_type sectionable_id])

    create_table :parts do |t|
      t.references :section, null: false, foreign_key: true
      t.string :part_type, null: false
      t.integer :display_order, null: false
      t.timestamps null: false
    end unless table_exists?(:parts)

    add_foreign_key :parts, :sections unless foreign_key_exists?(:parts, :sections)

    create_table :question_sets do |t|
      t.references :part, null: false, foreign_key: true
      t.text :passage
      t.string :audio_url
      t.integer :display_order, null: false
      t.timestamps null: false
    end unless table_exists?(:question_sets)

    add_foreign_key :question_sets, :parts unless foreign_key_exists?(:question_sets, :parts)

    create_table :questions do |t|
      t.references :question_set, null: false, foreign_key: true
      t.integer :display_order, null: false
      t.text :question_text, null: false
      t.string :audio_url
      t.text :choice_a, null: false
      t.text :choice_b, null: false
      t.text :choice_c, null: false
      t.text :choice_d, null: false
      t.string :correct_choice, null: false
      t.text :explanation
      t.timestamps null: false
    end unless table_exists?(:questions)

    add_foreign_key :questions, :question_sets unless foreign_key_exists?(:questions, :question_sets)

    create_table :attempts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :mockable, null: false, polymorphic: true
      t.datetime :completed_at
      t.timestamps null: false
    end unless table_exists?(:attempts)

    add_foreign_key :attempts, :users unless foreign_key_exists?(:attempts, :users)
    add_index :attempts, %i[user_id mockable_type mockable_id], unique: true unless index_exists?(:attempts, %i[user_id mockable_type mockable_id], unique: true)

    create_table :answers do |t|
      t.references :attempt, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.string :selected_choice
      t.boolean :is_correct
      t.timestamps null: false
    end unless table_exists?(:answers)

    add_foreign_key :answers, :attempts unless foreign_key_exists?(:answers, :attempts)
    add_foreign_key :answers, :questions unless foreign_key_exists?(:answers, :questions)
    add_index :answers, %i[attempt_id question_id], unique: true unless index_exists?(:answers, %i[attempt_id question_id], unique: true)
  end

  def down
    drop_table :answers, if_exists: true
    drop_table :attempts, if_exists: true
    drop_table :questions, if_exists: true
    drop_table :question_sets, if_exists: true
    drop_table :parts, if_exists: true
    drop_table :sections, if_exists: true
    drop_table :exercises, if_exists: true
    drop_table :mocks, if_exists: true
  end
end


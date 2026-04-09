# frozen_string_literal: true

class BackfillQuestionConversationAudioUrlForPartA < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL.squish
      UPDATE questions
      SET conversation_audio_url = question_audio_url
      FROM question_sets
      INNER JOIN parts ON parts.id = question_sets.part_id
      WHERE questions.question_set_id = question_sets.id
        AND parts.part_type = 'part_a'
        AND questions.conversation_audio_url IS NULL
        AND questions.question_audio_url IS NOT NULL
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE questions
      SET conversation_audio_url = NULL
      FROM question_sets
      INNER JOIN parts ON parts.id = question_sets.part_id
      WHERE questions.question_set_id = question_sets.id
        AND parts.part_type = 'part_a'
    SQL
  end
end

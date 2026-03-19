# frozen_string_literal: true

class RenameAudioUrlAndAddConversationText < ActiveRecord::Migration[8.0]
  def change
    rename_column :question_sets, :audio_url, :conversation_audio_url
    add_column :question_sets, :conversation_text, :text

    rename_column :questions, :audio_url, :question_audio_url
  end
end

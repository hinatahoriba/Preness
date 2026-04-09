# frozen_string_literal: true

class AddConversationAudioUrlToQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :questions, :conversation_audio_url, :string
  end
end

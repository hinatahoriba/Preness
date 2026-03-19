module ApplicationHelper
  def question_tag_label(tag)
    return nil if tag.blank?

    labels = {
      'shortConv' => '短い会話',
      'longConv'  => '長い会話',
      'talk'      => 'トーク',
      'sentenceStruct'  => '文構造',
      'verbForm'        => '動詞の形',
      'modifierConnect' => '修飾語・接続語',
      'nounPronoun'     => '名詞・代名詞',
      'vocab'     => '語彙',
      'inference' => '推論',
      'fact'      => '事実'
    }
    labels[tag] || tag
  end
end

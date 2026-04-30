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

  def question_choice_text(question, choice)
    case choice
    when "A" then question.choice_a
    when "B" then question.choice_b
    when "C" then question.choice_c
    when "D" then question.choice_d
    end
  end

  def format_vocab_tags(text, in_question: false)
    return "" if text.blank?

    css_class = "font-bold italic text-black px-0.5"
    css_class += " mx-1" if in_question

    text.to_s.gsub(/\[([UV]\d*)\](.*?)\[\/\1\]/) do
      word = Regexp.last_match(2)
      content_tag(:span, word, class: css_class)
    end.html_safe
  end

  def question_text_with_tags(question)
    text = question.question_text
    
    # Replace [V1]...[/V1] or [U1]...[/U1] with stylized span
    text = format_vocab_tags(text, in_question: true)

    # Replace [A]...[/A] with stylized span
    text.gsub(/\[([A-D])\](.*?)\[\/\1\]/) do
      choice = $1
      content = $2
      content_tag(:span, class: "relative inline-block border-b-2 border-gray-800 px-1 pb-1 mx-1 mb-4") do
        concat content
        concat content_tag(:span, choice, class: "absolute -bottom-5 left-1/2 -translate-x-1/2 text-[10px] font-bold text-gray-700")
      end
    end.html_safe
  end
end

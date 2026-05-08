module ApplicationHelper
  def header_auth_buttons
    btn = "inline-block px-[20px] md:px-[35px] py-[10px] md:py-[12px] text-[13px] md:text-[15px] font-bold text-center cursor-pointer transition-all duration-300 rounded-[40px] bg-[#279ea6] text-white hover:opacity-90"
    if user_signed_in?
      link_to "マイページへ", mypage_path, class: btn
    else
      safe_join([
        link_to("アカウント登録", new_user_registration_path, class: btn),
        link_to("ログイン", new_user_session_path, class: btn)
      ])
    end
  end

  def card_auth_buttons
    btn = "inline-block px-[35px] py-[12px] text-[15px] font-bold text-center cursor-pointer transition-all duration-300 rounded-[40px] bg-[#279ea6] text-white hover:opacity-90 block w-full"
    if user_signed_in?
      link_to "マイページへ", mypage_path, class: btn
    else
      safe_join([
        link_to("アカウント登録", new_user_registration_path, class: "#{btn} mb-[15px]"),
        link_to("ログイン", new_user_session_path, class: btn)
      ])
    end
  end

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

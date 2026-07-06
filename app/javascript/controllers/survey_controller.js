import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["ratingInput", "feedbackSection", "thankyouSection", "form", "button"]

  connect() {
    this.submitted = false;
  }

  selectRating(event) {
    const button = event.currentTarget
    
    // 全ボタンのスタイルをリセット
    this.buttonTargets.forEach(btn => {
      btn.style.backgroundColor = 'white'
      btn.classList.remove('text-white')
      btn.classList.add('text-[#333333]')
    })
    
    // クリックされたボタンをハイライト
    const color = button.dataset.color
    button.style.backgroundColor = color
    button.classList.remove('text-[#333333]')
    button.classList.add('text-white')

    // hidden input に評価の数値をセット
    this.ratingInputTarget.value = button.value

    // フィードバック欄と送信ボタンを表示
    if (this.feedbackSectionTarget.classList.contains('hidden')) {
      this.feedbackSectionTarget.classList.remove('hidden')
      setTimeout(() => {
        this.feedbackSectionTarget.classList.remove('opacity-0', 'translate-y-4')
        this.feedbackSectionTarget.classList.add('opacity-100', 'translate-y-0')
      }, 50)
    }
  }

  submit(event) {
    if (!this.ratingInputTarget.value) {
      event.preventDefault()
      alert('5段階評価を選択してください。')
      return
    }
    this.submitted = true;
  }

  iframeLoaded() {
    if (this.submitted) {
      this.showThankYou()
    }
  }

  showThankYou() {
    // フォームをフェードアウトして非表示にする
    this.formTarget.style.transition = 'opacity 0.3s ease'
    this.formTarget.style.opacity = '0'
    
    setTimeout(() => {
      this.formTarget.classList.add('hidden')
      // サンクスメッセージを表示
      this.thankyouSectionTarget.classList.remove('hidden')
      setTimeout(() => {
        this.thankyouSectionTarget.classList.remove('opacity-0')
        this.thankyouSectionTarget.classList.add('opacity-100')
      }, 50)
    }, 300)
  }
}

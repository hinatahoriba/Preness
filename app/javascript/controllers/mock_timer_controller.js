import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    seconds: Number
  }
  static targets = [ "display" ]

  connect() {
    this._storageKey = `timer:${window.location.pathname}${window.location.search}`

    const saved = localStorage.getItem(this._storageKey)
    if (saved !== null) {
      try {
        const { seconds, savedAt } = JSON.parse(saved)
        const elapsed = Math.floor((Date.now() - savedAt) / 1000)
        this.secondsLeft = Math.max(0, seconds - elapsed)
      } catch (e) {
        this.secondsLeft = this.secondsValue
      }
    } else {
      this.secondsLeft = this.secondsValue
    }

    this.updateDisplay()

    if (this.secondsLeft <= 0 && saved !== null) {
      localStorage.removeItem(this._storageKey)
      this.showWarning()
      return
    }

    // 時間設定がある場合のみタイマーを稼働
    if (this.secondsLeft > 0) {
      this.timer = setInterval(() => {
        this.secondsLeft--
        localStorage.setItem(this._storageKey, JSON.stringify({ seconds: this.secondsLeft, savedAt: Date.now() }))
        if (this.secondsLeft <= 0) {
          this.secondsLeft = 0
          this.stopTimer()
          localStorage.removeItem(this._storageKey)
          this.showWarning()
        }
        this.updateDisplay()
      }, 1000)
    }

    const form = this.element.querySelector('form')
    if (form) {
      form.addEventListener('submit', () => {
        localStorage.removeItem(this._storageKey)
      })
    }
  }

  disconnect() {
    this.stopTimer()
  }

  updateDisplay() {
    const min = Math.floor(this.secondsLeft / 60).toString().padStart(2, '0')
    const sec = (this.secondsLeft % 60).toString().padStart(2, '0')
    this.displayTarget.textContent = `${min}:${sec}`
  }

  stopTimer() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
  }

  showWarning() {
    // 0になったら赤字にして警告
    this.displayTarget.classList.remove('text-white')
    this.displayTarget.classList.add('text-red-400')
    alert('このセクションの制限時間が終了しました。')
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    seconds: Number
  }
  static targets = [ "display" ]

  connect() {
    this.secondsLeft = this.secondsValue

    // 時間設定がある場合のみタイマーを稼働
    if (this.secondsLeft > 0) {
      this.timer = setInterval(() => {
        this.secondsLeft--
        if (this.secondsLeft <= 0) {
          this.secondsLeft = 0
          this.stopTimer()
          this.showWarning()
        }
        this.updateDisplay()
      }, 1000)
    }

    this.beforeUnloadHandler = (e) => {
      e.preventDefault()
      e.returnValue = ''
    }
    window.addEventListener('beforeunload', this.beforeUnloadHandler)
  }

  disconnect() {
    this.stopTimer()
    window.removeEventListener('beforeunload', this.beforeUnloadHandler)
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

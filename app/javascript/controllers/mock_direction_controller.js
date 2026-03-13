import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    answerUrl: String,
    duration: Number
  }
  static targets = [ "timer" ]

  connect() {
    this.secondsLeft = this.durationValue || 40
    this.updateDisplay()

    this.timer = setInterval(() => {
      this.secondsLeft--
      this.updateDisplay()

      if (this.secondsLeft <= 0) {
        this.complete()
      }
    }, 1000)
  }

  disconnect() {
    this.stopTimer()
  }

  updateDisplay() {
    const min = Math.floor(this.secondsLeft / 60).toString().padStart(2, '0')
    const sec = (this.secondsLeft % 60).toString().padStart(2, '0')
    this.timerTarget.textContent = `${min}:${sec}`
  }

  complete() {
    this.stopTimer()
    if (this.answerUrlValue) {
      window.location.href = this.answerUrlValue
    }
  }

  skip(event) {
    // リンクによる通常のページ遷移が行われるため、
    // ここではタイマーを止めるだけでOK
    this.stopTimer()
  }

  stopTimer() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
  }
}

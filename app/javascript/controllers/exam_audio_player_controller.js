import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["audio", "playButton", "statusLabel"]
  static values = { singleUse: Boolean, autoplayDelayMs: Number }

  connect() {
    this._timeoutIds = []
    this._handlers = this.audioTargets.map((audio, index) => {
      const playHandler = () => this._onPlay(index)
      const pauseHandler = () => this._onPause(index)
      const endedHandler = () => this._onEnded(index)

      audio.addEventListener("play", playHandler)
      audio.addEventListener("pause", pauseHandler)
      audio.addEventListener("ended", endedHandler)

      return { audio, playHandler, pauseHandler, endedHandler }
    })
  }

  disconnect() {
    this._handlers?.forEach(({ audio, playHandler, pauseHandler, endedHandler }) => {
      audio.removeEventListener("play", playHandler)
      audio.removeEventListener("pause", pauseHandler)
      audio.removeEventListener("ended", endedHandler)
    })

    this._timeoutIds?.forEach((timeoutId) => clearTimeout(timeoutId))
  }

  playAudio(event) {
    const index = this.playButtonTargets.indexOf(event.currentTarget)
    if (index < 0) return

    const audio = this.audioTargets[index]
    if (!audio) return

    if (this.singleUseValue) {
      if (audio.dataset.played) return

      audio.dataset.played = "true"
      audio.play()
      return
    }

    audio.paused ? audio.play() : audio.pause()
  }

  _onPlay(index) {
    const button = this.playButtonTargets[index]
    const label = this.statusLabelTargets[index]

    if (this.singleUseValue && button) {
      button.disabled = true
      button.classList.add("opacity-60")
    }

    if (label) label.textContent = "再生中..."
  }

  _onPause(index) {
    if (this.singleUseValue) return

    const label = this.statusLabelTargets[index]
    if (label) label.textContent = "一時停止中"
  }

  _onEnded(index) {
    const button = this.playButtonTargets[index]
    const label = this.statusLabelTargets[index]

    if (this.singleUseValue && button) {
      button.classList.remove("opacity-60")
      button.classList.add("opacity-40", "cursor-not-allowed")
    }

    if (label) {
      label.textContent = this.singleUseValue ? "再生済み" : "再生終了"
    }

    const nextIndex = index + 1
    const nextAudio = this.audioTargets[nextIndex]
    if (!nextAudio) {
      if (label && !this.singleUseValue) label.textContent = "すべての再生が終了しました"
      return
    }

    if (this.singleUseValue && nextAudio.dataset.played) return

    const nextLabel = this.statusLabelTargets[nextIndex]
    if (nextLabel) nextLabel.textContent = "5秒後に再生します..."

    const timeoutId = setTimeout(() => {
      if (this.singleUseValue) {
        nextAudio.dataset.played = "true"
      }
      nextAudio.play()
    }, this.delayMs)

    this._timeoutIds.push(timeoutId)
  }

  get delayMs() {
    return this.hasAutoplayDelayMsValue ? this.autoplayDelayMsValue : 5000
  }
}

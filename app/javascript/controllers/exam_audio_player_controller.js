import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["audio", "playButton", "statusLabel", "masterPlayButton", "masterStatusText", "introAudio"]
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

    if (this.hasIntroAudioTarget) {
      this._introEndedHandler = () => this._onIntroEnded()
      this.introAudioTarget.addEventListener("ended", this._introEndedHandler)
    }
  }

  disconnect() {
    this._handlers?.forEach(({ audio, playHandler, pauseHandler, endedHandler }) => {
      audio.removeEventListener("play", playHandler)
      audio.removeEventListener("pause", pauseHandler)
      audio.removeEventListener("ended", endedHandler)
    })

    if (this.hasIntroAudioTarget && this._introEndedHandler) {
      this.introAudioTarget.removeEventListener("ended", this._introEndedHandler)
    }

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

  playMasterAudio() {
    if (!this.hasIntroAudioTarget) return

    if (this.hasMasterPlayButtonTarget) {
      this.masterPlayButtonTarget.style.display = "none"
    }
    if (this.hasMasterStatusTextTarget) {
      this.masterStatusTextTarget.classList.remove("hidden")
    }

    const audio = this.introAudioTarget
    if (this.singleUseValue) {
      if (audio.dataset.played) return
      audio.dataset.played = "true"
    }
    audio.play()
  }

  _onIntroEnded() {
    const firstAudio = this.audioTargets[0]
    if (!firstAudio) {
      this._onAllEnded()
      return
    }

    const timeoutId = setTimeout(() => {
      if (this.singleUseValue) firstAudio.dataset.played = "true"
      firstAudio.play()
    }, this.delayMs)

    this._timeoutIds.push(timeoutId)
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
      this._onAllEnded()
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

  _onAllEnded() {
    if (!this.hasMasterStatusTextTarget) return

    const textSpan = this.masterStatusTextTarget.querySelector("span")
    if (textSpan) textSpan.textContent = "すべての再生が終了しました"
    this.masterStatusTextTarget.classList.remove("animate-pulse")
  }

  get delayMs() {
    return this.hasAutoplayDelayMsValue ? this.autoplayDelayMsValue : 5000
  }
}

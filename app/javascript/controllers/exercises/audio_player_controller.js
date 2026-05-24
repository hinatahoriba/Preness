import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["audio", "playButton", "statusLabel"]

  connect() {
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
  }

  toggle(event) {
    const index = this.playButtonTargets.indexOf(event.currentTarget)
    if (index < 0) return

    const audio = this.audioTargets[index]
    if (!audio) return

    audio.paused ? audio.play() : audio.pause()
  }

  _onPlay(index) {
    const label = this.statusLabelTargets[index]
    if (label) label.textContent = "再生中..."
  }

  _onPause(index) {
    const label = this.statusLabelTargets[index]
    if (label) label.textContent = "一時停止中"
  }

  _onEnded(index) {
    const label = this.statusLabelTargets[index]
    if (label) label.textContent = "再生終了"
  }
}

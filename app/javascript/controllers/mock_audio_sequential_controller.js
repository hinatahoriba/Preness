import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["audio"]

  connect() {
    this._handlers = this.audioTargets.map((audio, index) => {
      const endedHandler = () => {
        this._disableAudio(audio)
        this._playNext(index)
      }
      const playHandler = () => {
        if (audio.dataset.played) {
          audio.pause()
          audio.currentTime = 0
        } else {
          audio.dataset.played = "true"
        }
      }
      audio.addEventListener("ended", endedHandler)
      audio.addEventListener("play", playHandler)
      return { audio, endedHandler, playHandler }
    })
  }

  disconnect() {
    this._handlers?.forEach(({ audio, endedHandler, playHandler }) => {
      audio.removeEventListener("ended", endedHandler)
      audio.removeEventListener("play", playHandler)
    })
  }

  _disableAudio(audio) {
    audio.controls = true
    audio.setAttribute("aria-disabled", "true")
    audio.tabIndex = -1
    audio.style.pointerEvents = "none"
    audio.style.opacity = "0.4"
  }

  _playNext(currentIndex) {
    const next = this.audioTargets[currentIndex + 1]
    if (next) {
      next.play()
    }
  }
}

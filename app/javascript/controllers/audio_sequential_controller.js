import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["audio"]

  connect() {
    this._storageKeys = []

    this._handlers = this.audioTargets.map((audio, index) => {
      const storageKey = `audio_played:${audio.src}`
      this._storageKeys.push(storageKey)

      if (localStorage.getItem(storageKey)) {
        audio.dataset.played = "true"
        this._disableAudio(audio)
      }

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
          localStorage.setItem(storageKey, "true")
        }
      }
      audio.addEventListener("ended", endedHandler)
      audio.addEventListener("play", playHandler)
      return { audio, endedHandler, playHandler }
    })

    const form = this.element.querySelector('form')
    if (form) {
      form.addEventListener('submit', () => {
        this._storageKeys.forEach(key => localStorage.removeItem(key))
      })
    }
  }

  disconnect() {
    this._handlers?.forEach(({ audio, endedHandler, playHandler }) => {
      audio.removeEventListener("ended", endedHandler)
      audio.removeEventListener("play", playHandler)
    })
  }

  _disableAudio(audio) {
    // Keep controls visible so the user can see the audio existed,
    // while preventing re-play via pointer-events + the play handler.
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

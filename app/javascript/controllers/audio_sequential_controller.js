import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["audio"]

  connect() {
    this._handlers = this.audioTargets.map((audio, index) => {
      const handler = () => this._playNext(index)
      audio.addEventListener("ended", handler)
      return { audio, handler }
    })
  }

  disconnect() {
    this._handlers?.forEach(({ audio, handler }) => {
      audio.removeEventListener("ended", handler)
    })
  }

  _playNext(currentIndex) {
    const next = this.audioTargets[currentIndex + 1]
    if (next) {
      next.play()
    }
  }
}

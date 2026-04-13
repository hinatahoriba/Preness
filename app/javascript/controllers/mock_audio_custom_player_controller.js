import { Controller } from "@hotwired/stimulus"

// Manages custom audio play buttons with sequential playback and one-time-play restriction.
// Expects parallel arrays of playButton targets and audio targets (same DOM order).
export default class extends Controller {
  static targets = ["audio", "playButton", "statusLabel"]

  connect() {
    this.audioTargets.forEach((audio, index) => {
      audio.addEventListener("ended", () => this._onEnded(index))
      audio.addEventListener("play", () => this._onPlay(index))
    })
  }

  playAudio(event) {
    const button = event.currentTarget
    const index = this.playButtonTargets.indexOf(button)
    if (index < 0) return

    const audio = this.audioTargets[index]
    if (!audio.dataset.played) {
      audio.dataset.played = "true"
      audio.play()
    }
  }

  _onPlay(index) {
    const button = this.playButtonTargets[index]
    if (!button) return
    button.disabled = true
    button.classList.add("opacity-60")
    const label = this.statusLabelTargets[index]
    if (label) label.textContent = "再生中..."
  }

  _onEnded(index) {
    const button = this.playButtonTargets[index]
    if (button) {
      button.classList.remove("opacity-60")
      button.classList.add("opacity-40", "cursor-not-allowed")
    }
    const label = this.statusLabelTargets[index]
    if (label) label.textContent = "再生済み"

    // Auto-play next audio sequentially with 5s delay
    const nextIndex = index + 1
    const next = this.audioTargets[nextIndex]
    if (next && !next.dataset.played) {
      const nextLabel = this.statusLabelTargets[nextIndex]
      if (nextLabel) nextLabel.textContent = "5秒後に再生します..."

      setTimeout(() => {
        next.dataset.played = "true"
        next.play()
      }, 5000)
    }
  }
}

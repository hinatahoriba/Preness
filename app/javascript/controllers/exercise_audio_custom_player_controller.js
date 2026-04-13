import { Controller } from "@hotwired/stimulus"

// Custom audio player for exercises — same UI as mock exam, but no play restrictions.
// Supports play/pause toggle and unlimited replays.
export default class extends Controller {
  static targets = ["audio", "playButton", "statusLabel"]

  connect() {
    this.audioTargets.forEach((audio, index) => {
      audio.addEventListener("play",  () => this._onPlay(index))
      audio.addEventListener("pause", () => this._onPause(index))
      audio.addEventListener("ended", () => this._onEnded(index))
    })
  }

  playAudio(event) {
    const index = this.playButtonTargets.indexOf(event.currentTarget)
    if (index < 0) return

    const audio = this.audioTargets[index]
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

    const nextIndex = index + 1
    const nextAudio = this.audioTargets[nextIndex]
    
    if (nextAudio) {
      // 5秒待機
      const nextLabel = this.statusLabelTargets[nextIndex]
      if (nextLabel) nextLabel.textContent = "5秒後に再生します..."
      
      setTimeout(() => {
        nextAudio.play()
      }, 5000)
    } else {
      if (label) label.textContent = "すべての再生が終了しました"
    }
  }
}

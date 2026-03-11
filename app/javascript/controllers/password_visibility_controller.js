import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button", "label", "showIcon", "hideIcon"]

  connect() {
    this.sync()
  }

  toggle() {
    if (!this.hasInputTarget) return

    this.inputTarget.type = this.inputTarget.type === "password" ? "text" : "password"
    this.sync()
  }

  sync() {
    if (!this.hasInputTarget) return

    const isVisible = this.inputTarget.type === "text"
    const labelText = isVisible ? "非表示" : "表示"

    if (this.hasLabelTarget) this.labelTarget.textContent = labelText
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-pressed", String(isVisible))
      this.buttonTarget.setAttribute("aria-label", isVisible ? "パスワードを非表示" : "パスワードを表示")
    }
    if (this.hasShowIconTarget) this.showIconTarget.classList.toggle("hidden", isVisible)
    if (this.hasHideIconTarget) this.hideIconTarget.classList.toggle("hidden", !isVisible)
  }
}

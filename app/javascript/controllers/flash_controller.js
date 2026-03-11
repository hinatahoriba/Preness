import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Auto dismiss after 3 seconds
    this.timeout = setTimeout(() => this.dismiss(), 3000)
  }

  dismiss() {
    // Fade out
    this.element.style.transition = "opacity 0.5s"
    this.element.style.opacity = "0"
    // Remove from DOM after fade
    setTimeout(() => this.element.remove(), 500)
  }
}

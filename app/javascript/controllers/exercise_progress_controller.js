import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["answeredCount", "bar"]
  static values = { total: Number }

  connect() {
    this.update()
  }

  update() {
    const checkedInputs = this.element.querySelectorAll('input[type="radio"]:checked')
    const answeredKeys = new Set([...checkedInputs].map((input) => input.name))
    const answeredCount = answeredKeys.size

    if (this.hasAnsweredCountTarget) {
      this.answeredCountTarget.textContent = answeredCount
    }

    if (this.hasBarTarget) {
      const total = this.totalValue || 0
      const percent = total === 0 ? 0 : (answeredCount / total) * 100
      this.barTarget.style.width = `${percent}%`
    }
  }
}


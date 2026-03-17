import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["answeredCount", "indicator", "submitButton"]
  static values = { totalCount: Number }

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

    if (this.hasIndicatorTarget) {
      this.indicatorTargets.forEach((indicator) => {
        const questionId = indicator.dataset.questionId
        const isAnswered = this.element.querySelector(`input[name="answers[${questionId}]"]:checked`)

        if (isAnswered) {
          indicator.classList.remove("bg-white/30")
          indicator.classList.add("bg-white")
        } else {
          indicator.classList.remove("bg-white")
          indicator.classList.add("bg-white/30")
        }
      })
    }

    if (this.hasSubmitButtonTarget) {
      const allAnswered = answeredCount >= this.totalCountValue
      this.submitButtonTarget.disabled = !allAnswered
    }
  }
}

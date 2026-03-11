import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["answeredCount", "indicator"]

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
          indicator.classList.remove("bg-gray-200")
          indicator.classList.add("bg-blue-500")
        } else {
          indicator.classList.remove("bg-blue-500")
          indicator.classList.add("bg-gray-200")
        }
      })
    }
  }
}


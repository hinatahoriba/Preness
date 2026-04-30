import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["answeredCount", "indicator", "submitButton", "interruptModal"]
  static values = { totalCount: Number, requireAllAnswered: Boolean }

  connect() {
    this.update()
  }

  openModal() {
    if (this.hasInterruptModalTarget) {
      this.interruptModalTarget.classList.remove("hidden")
    }
  }

  closeModal() {
    if (this.hasInterruptModalTarget) {
      this.interruptModalTarget.classList.add("hidden")
    }
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

        indicator.classList.toggle("bg-[#1a1b4b]", Boolean(isAnswered))
        indicator.classList.toggle("bg-gray-300", !isAnswered)
      })
    }

    if (this.hasSubmitButtonTarget && this.requireAllAnsweredValue) {
      this.submitButtonTarget.disabled = answeredCount < this.totalCountValue
    }
  }
}

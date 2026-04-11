import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["answeredCount", "indicator", "submitButton", "interruptModal"]
  static values = { totalCount: Number }

  connect() {
    this.update()
  }

  openModal() {
    this.interruptModalTarget.classList.remove("hidden")
  }

  closeModal() {
    this.interruptModalTarget.classList.add("hidden")
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
          indicator.classList.remove("bg-gray-300")
          indicator.classList.add("bg-[#1a1b4b]")
        } else {
          indicator.classList.remove("bg-[#1a1b4b]")
          indicator.classList.add("bg-gray-300")
        }
      })
    }

  }
}

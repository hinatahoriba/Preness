import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["answeredCount", "indicator", "submitButton"]
  static values = { totalCount: Number }

  connect() {
    this._storageKey = `form_answers:${window.location.pathname}${window.location.search}`
    this._restoreAnswers()
    this.update()

    const form = this.element.querySelector('form')
    if (form) {
      form.addEventListener('submit', () => {
        localStorage.removeItem(this._storageKey)
      })
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

    this._saveAnswers()
  }

  _saveAnswers() {
    const checkedInputs = this.element.querySelectorAll('input[type="radio"]:checked')
    const answers = {}
    checkedInputs.forEach(input => {
      answers[input.name] = input.value
    })
    localStorage.setItem(this._storageKey, JSON.stringify(answers))
  }

  _restoreAnswers() {
    const saved = localStorage.getItem(this._storageKey)
    if (!saved) return

    try {
      const answers = JSON.parse(saved)
      Object.entries(answers).forEach(([name, value]) => {
        const input = this.element.querySelector(`input[name="${name}"][value="${value}"]`)
        if (input) input.checked = true
      })
    } catch (e) {
      localStorage.removeItem(this._storageKey)
    }
  }
}

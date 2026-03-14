import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submit"]

  connect() {
    this.validate()
  }

  validate() {
    const form = this.element
    const textFields = form.querySelectorAll("input[type='text'], input[type='number']")
    const radioName = form.querySelector("input[type='radio']")?.name

    const textsFilled = Array.from(textFields).every(f => f.value.trim() !== "")
    const radioChecked = radioName ? form.querySelector(`input[name='${radioName}']:checked`) !== null : true

    const allFilled = textsFilled && radioChecked
    this.submitTarget.disabled = !allFilled
    this.submitTarget.classList.toggle("opacity-50", !allFilled)
    this.submitTarget.classList.toggle("cursor-not-allowed", !allFilled)
    this.submitTarget.classList.toggle("cursor-pointer", allFilled)
  }
}

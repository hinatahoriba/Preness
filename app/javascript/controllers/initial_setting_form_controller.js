import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "submit",
    "itpNeverTaken",
    "itpCurrent",
    "qualCheck",
    "qualNone",
    "scoreInputs",
    "studyAbroadRadio"
  ]

  connect() {
    this.validate()
  }

  // ITP「受験経験なし」チェックボックスの切り替え
  toggleItpNeverTaken() {
    const checkbox = this.itpNeverTakenTarget
    const input = this.itpCurrentTarget

    if (checkbox.checked) {
      input.value = ""
      input.disabled = true
      input.classList.add("opacity-40")
    } else {
      input.disabled = false
      input.classList.remove("opacity-40")
    }
    this.validate()
  }

  // 資格チェックボックスの切り替え
  toggleQual(event) {
    const checkbox = event.target
    const targetId = checkbox.dataset.qualTarget
    const targetArea = document.getElementById(targetId)

    if (checkbox.checked) {
      // 「なし」のチェックを外す
      if (this.hasQualNoneTarget) {
        this.qualNoneTarget.checked = false
      }
      targetArea.classList.remove("hidden")
    } else {
      targetArea.classList.add("hidden")
      const detail = targetArea.querySelector("input, select")
      if (detail) detail.value = ""
    }
    this.validate()
  }

  // 「なし」チェックボックスの切り替え
  toggleQualNone() {
    if (this.qualNoneTarget.checked) {
      this.qualCheckTargets.forEach((cb) => {
        cb.checked = false
        const targetId = cb.dataset.qualTarget
        const targetArea = document.getElementById(targetId)
        targetArea.classList.add("hidden")
        const detail = targetArea.querySelector("input, select")
        if (detail) detail.value = ""
      })
    }
    this.validate()
  }

  validate() {
    let isFormValid = true

    // 1. 必須テキスト入力（.required-input）
    const requiredInputs = this.element.querySelectorAll(".required-input")
    requiredInputs.forEach((input) => {
      if (!input.value.trim()) isFormValid = false
    })

    // 2. 留学予定のラジオボタン
    if (this.hasStudyAbroadRadioTarget) {
      const anyChecked = this.studyAbroadRadioTargets.some((r) => r.checked)
      if (!anyChecked) isFormValid = false
    }

    // 3. ITP スコア
    if (!this.itpNeverTakenTarget.checked && !this.itpCurrentTarget.value) {
      isFormValid = false
    }

    // 4. 保有資格: いずれかの資格 or 「なし」が選択されていること
    const anyQualChecked = this.qualCheckTargets.some((cb) => cb.checked)
    const noneChecked = this.hasQualNoneTarget && this.qualNoneTarget.checked
    if (!anyQualChecked && !noneChecked) isFormValid = false

    // 選択された資格のスコアが入力されていること
    this.qualCheckTargets.forEach((cb) => {
      if (cb.checked) {
        const targetArea = document.getElementById(cb.dataset.qualTarget)
        const detail = targetArea.querySelector("input, select")
        if (detail && !detail.value) isFormValid = false
      }
    })

    // ボタンの状態を更新
    this.submitTarget.disabled = !isFormValid
  }
}

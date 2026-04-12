import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
  }

  open(event) {
    if (event.currentTarget.dataset.modalId) {
      const modalId = event.currentTarget.dataset.modalId
      const modal = document.getElementById(modalId)
      if (modal) {
        modal.classList.remove("hidden")
        document.body.classList.add("overflow-hidden")
      }
    }
  }

  close(event) {
    // ボタンなどで明示的に閉じる
    const modal = event.currentTarget.closest('.modal-container')
    if (modal) {
      modal.classList.add("hidden")
      document.body.classList.remove("overflow-hidden")
    }
  }

  closeBackground(event) {
    // 背景をクリックした時のみ閉じる
    if (event.target === event.currentTarget) {
      event.currentTarget.classList.add("hidden")
      document.body.classList.remove("overflow-hidden")
    }
  }
}

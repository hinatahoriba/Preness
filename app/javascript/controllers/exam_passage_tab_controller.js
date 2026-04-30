import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    this._activate(0)
  }

  switch(event) {
    const index = this.tabTargets.indexOf(event.currentTarget)
    if (index >= 0) this._activate(index)
  }

  _activate(activeIndex) {
    this.tabTargets.forEach((tab, index) => {
      const isActive = index === activeIndex
      tab.classList.toggle("border-b-[3px]", isActive)
      tab.classList.toggle("border-[#0f2361]", isActive)
      tab.classList.toggle("text-[#0f2361]", isActive)
      tab.classList.toggle("text-gray-400", !isActive)
    })

    this.panelTargets.forEach((panel, index) => {
      panel.classList.toggle("hidden", index !== activeIndex)
    })
  }
}

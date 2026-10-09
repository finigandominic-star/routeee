import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "checkbox", "otherCheckbox",
    "startGroup", "endGroup", "typeGroup", "distanceGroup", "otherGroup",
    "startInput", "endInput", "typeInput", "distanceInput", "otherInput",
    "promptInput", "submitBtn", "btnText", "btnSpinner"
  ]

  toggleOptions(event) {
    const isOther = event.target === this.otherCheckboxTarget && event.target.checked

    if (isOther) {
      // Uncheck and disable all other checkboxes
      this.checkboxTargets.forEach(cb => {
        cb.checked = false
        cb.disabled = true
      })
    } else {
      // Enable all other checkboxes
      this.checkboxTargets.forEach(cb => {
        cb.disabled = false
      })
      this.otherCheckboxTarget.checked = false
    }

    this.updateVisibility()
  }

  updateVisibility() {
    // Show/hide relevant input fields
    const checkedValues = Array.from(document.querySelectorAll('input[name="edit_option"]:checked')).map(cb => cb.value)

    this.startGroupTarget.classList.toggle("d-none", !checkedValues.includes("start"))
    this.endGroupTarget.classList.toggle("d-none", !checkedValues.includes("end"))
    this.typeGroupTarget.classList.toggle("d-none", !checkedValues.includes("type"))
    this.distanceGroupTarget.classList.toggle("d-none", !checkedValues.includes("distance"))
    this.otherGroupTarget.classList.toggle("d-none", !checkedValues.includes("other"))
  }

  submitForm(event) {
    // Compile inputs into a single prompt for the LLM
    let prompts = []

    if (this.startGroupTarget.classList.contains("d-none") === false && this.startInputTarget.value) {
      prompts.push(`Change starting point to: ${this.startInputTarget.value}`)
    }
    if (this.endGroupTarget.classList.contains("d-none") === false && this.endInputTarget.value) {
      prompts.push(`Change finishing point to: ${this.endInputTarget.value}`)
    }
    if (this.typeGroupTarget.classList.contains("d-none") === false && this.typeInputTarget.value) {
      prompts.push(`Change bike type/terrain to: ${this.typeInputTarget.value}`)
    }
    if (this.distanceGroupTarget.classList.contains("d-none") === false && this.distanceInputTarget.value) {
      prompts.push(`Target distance/time: ${this.distanceInputTarget.value}`)
    }
    if (this.otherGroupTarget.classList.contains("d-none") === false && this.otherInputTarget.value) {
      prompts.push(this.otherInputTarget.value)
    }

    if (prompts.length === 0) {
      event.preventDefault()
      alert("Please select at least one option and fill in the details.")
      return
    }

    // Set hidden prompt input value
    this.promptInputTarget.value = `Edit request: ${prompts.join("; ")}`

    // Show loading state on button
    this.submitBtnTarget.disabled = true
    this.btnTextTarget.classList.add("d-none")
    this.btnSpinnerTarget.classList.remove("d-none")
  }

  resetLoading() {
    // Called when modal closes or turbo finishes
    this.submitBtnTarget.disabled = false
    this.btnTextTarget.classList.remove("d-none")
    this.btnSpinnerTarget.classList.add("d-none")
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "checkbox", "otherCheckbox",
    "startGroup", "endGroup", "typeGroup", "distanceGroup", "otherGroup",
    "startInput", "endInput", "typeInput", "distanceInput", "otherInput",
    "promptInput", "submitBtn", "btnText", "btnSpinner"
  ]

  connect() {
    // Listen for Bootstrap modal hidden event to reset form state for the next interaction
    this.element.addEventListener('hidden.bs.modal', () => this.resetForm())
  }

  resetForm() {
    // Uncheck and enable all checkboxes
    this.checkboxTargets.forEach(cb => {
      cb.checked = false
      cb.disabled = false
    })
    this.otherCheckboxTarget.checked = false

    // Clear all input values
    if (this.hasStartInputTarget) this.startInputTarget.value = ""
    if (this.hasEndInputTarget) this.endInputTarget.value = ""
    if (this.hasTypeInputTarget) this.typeInputTarget.selectedIndex = 0
    if (this.hasDistanceInputTarget) this.distanceInputTarget.value = ""
    if (this.hasOtherInputTarget) this.otherInputTarget.value = ""
    if (this.hasPromptInputTarget) this.promptInputTarget.value = ""

    // Hide all dynamic input containers
    this.updateVisibility()

    // Reset button loading state
    this.submitBtnTarget.disabled = false
    this.btnTextTarget.classList.remove("d-none")
    this.btnSpinnerTarget.classList.add("d-none")
  }

  toggleOptions(event) {
    const isOther = event.target === this.otherCheckboxTarget && event.target.checked

    if (isOther) {
      this.checkboxTargets.forEach(cb => {
        cb.checked = false
        cb.disabled = true
      })
    } else {
      this.checkboxTargets.forEach(cb => {
        cb.disabled = false
      })
      this.otherCheckboxTarget.checked = false
    }

    this.updateVisibility()
  }

  updateVisibility() {
    const checkedValues = Array.from(this.element.querySelectorAll('input[name="edit_option"]:checked')).map(cb => cb.value)

    this.startGroupTarget.classList.toggle("d-none", !checkedValues.includes("start"))
    this.endGroupTarget.classList.toggle("d-none", !checkedValues.includes("end"))
    this.typeGroupTarget.classList.toggle("d-none", !checkedValues.includes("type"))
    this.distanceGroupTarget.classList.toggle("d-none", !checkedValues.includes("distance"))
    this.otherGroupTarget.classList.toggle("d-none", !checkedValues.includes("other"))
  }

  submitForm(event) {
    let prompts = []

    if (!this.startGroupTarget.classList.contains("d-none") && this.startInputTarget.value) {
      prompts.push(`Change starting point to ${this.startInputTarget.value}`)
    }
    if (!this.endGroupTarget.classList.contains("d-none") && this.endInputTarget.value) {
      prompts.push(`Change finishing point to ${this.endInputTarget.value}`)
    }
    if (!this.typeGroupTarget.classList.contains("d-none") && this.typeInputTarget.value) {
      prompts.push(`Change terrain/bike type to ${this.typeInputTarget.value}`)
    }
    if (!this.distanceGroupTarget.classList.contains("d-none") && this.distanceInputTarget.value) {
      prompts.push(`Change target distance/time to ${this.distanceInputTarget.value}`)
    }
    if (!this.otherGroupTarget.classList.contains("d-none") && this.otherInputTarget.value) {
      prompts.push(this.otherInputTarget.value)
    }

    if (prompts.length === 0) {
      event.preventDefault()
      alert("Please select at least one option and enter the details.")
      return
    }

    // Force strict immediate recalculation without questions
    const finalPrompt = `Edit route: ${prompts.join(", ")}. Recalculate and update the route directly without asking any clarifying questions.`
    this.promptInputTarget.value = finalPrompt

    // Show Loading Animation on Button
    this.submitBtnTarget.disabled = true
    this.btnTextTarget.classList.add("d-none")
    this.btnSpinnerTarget.classList.remove("d-none")
  }
}

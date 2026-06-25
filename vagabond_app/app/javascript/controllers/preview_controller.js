import { Controller } from "@hotwired/stimulus"

// Shows a live preview of a selected image file before upload.
export default class extends Controller {
  static targets = ["input", "image"]

  show() {
    const file = this.inputTarget.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => {
      this.imageTarget.src = e.target.result
      this.imageTarget.classList.remove("hidden")
    }
    reader.readAsDataURL(file)
  }
}

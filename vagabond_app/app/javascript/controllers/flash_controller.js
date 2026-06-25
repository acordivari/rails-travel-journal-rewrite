import { Controller } from "@hotwired/stimulus"

// Auto-dismisses a flash message after a delay, and on close-button click.
export default class extends Controller {
  static values = { dismissAfter: Number }

  connect() {
    if (this.dismissAfterValue > 0) {
      this.timeout = setTimeout(() => this.dismiss(), this.dismissAfterValue)
    }
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.style.transition = "opacity 0.3s"
    this.element.style.opacity = "0"
    setTimeout(() => this.element.remove(), 300)
  }
}

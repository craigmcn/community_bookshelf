import { Controller } from "@hotwired/stimulus"

// Progressively collapses the server-rendered pagy nav's interior
// page-number links to first/current/last when it overflows its
// container (narrow viewports) — the full, fully-functional link list is
// what renders without JS; this only ever hides/shows existing elements
// and clones the static gap template, it never builds hrefs in JS.
export default class extends Controller {
  static targets = ["gapTemplate"]

  connect() {
    this.list = this.element.querySelector(".pagination")
    if (!this.list) return

    this.items = Array.from(this.list.querySelectorAll(":scope > li.page-item:not(.previous):not(.next)"))
    this.currentIndex = this.items.findIndex((li) => li.classList.contains("active"))

    // allow_browser versions: :modern (ApplicationController) already rules
    // out any browser old enough to lack ResizeObserver, but guard it
    // anyway — cheap, and still renders once so the initial collapse
    // happens even where live re-collapse-on-resize isn't available.
    if (typeof ResizeObserver !== "undefined") {
      this.resizeObserver = new ResizeObserver(() => this.render())
      this.resizeObserver.observe(this.element)
    }
    this.render()
  }

  disconnect() {
    this.resizeObserver?.disconnect()
  }

  render() {
    this.reset()
    if (this.list.scrollWidth <= this.list.clientWidth) return

    this.collapse()
  }

  reset() {
    this.items.forEach((li) => {
      li.hidden = false
    })
    this.list.querySelectorAll(":scope > li[data-injected]").forEach((li) => li.remove())
  }

  collapse() {
    const essential = new Set([0, this.items.length - 1, this.currentIndex].filter((index) => index >= 0))
    this.items.forEach((li, index) => {
      li.hidden = !essential.has(index)
    })

    let previousVisibleIndex = null
    this.items.forEach((li, index) => {
      if (li.hidden) return
      if (previousVisibleIndex !== null && index - previousVisibleIndex > 1) this.insertGapBefore(li)
      previousVisibleIndex = index
    })
  }

  insertGapBefore(anchor) {
    const gap = this.gapTemplateTarget.content.firstElementChild.cloneNode(true)
    gap.dataset.injected = ""
    anchor.before(gap)
  }
}

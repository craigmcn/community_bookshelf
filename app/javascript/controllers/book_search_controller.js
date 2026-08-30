import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "query", "results", "spinner", "liveRegion",
    "hiddenTitle", "hiddenAuthor", "hiddenCoverUrl", "hiddenOpenLibraryKey",
    "searchSection", "selectionPreview",
    "previewTitle", "previewAuthor", "previewCover",
    "errors"
  ]

  connect() {
    if (this.hiddenTitleTarget.value) {
      this.#showSelection(
        this.hiddenTitleTarget.value,
        this.hiddenAuthorTarget.value,
        this.hiddenCoverUrlTarget.value
      )
    }
  }

  search(event) {
    clearTimeout(this.searchTimeout)
    const value = event.target.value.trim()

    if (value.length < 2) {
      this.resultsTarget.src = ""
      this.resultsTarget.innerHTML = ""
      this.liveRegionTarget.textContent = ""
      return
    }

    this.searchTimeout = setTimeout(() => {
      this.resultsTarget.src = `/book_search?q=${encodeURIComponent(value)}`
    }, 300)
  }

  showSpinner() {
    this.spinnerTarget.classList.remove("d-none")
  }

  hideSpinner() {
    this.spinnerTarget.classList.add("d-none")
  }

  // Copies the just-loaded results frame's status text ("Showing N
  // results." / "No results found.") into the persistent live region
  // outside the frame, rather than announcing the whole result list on
  // every keystroke — the frame's own content is fully replaced on every
  // search, so it can't reliably host the live region itself.
  announceResults() {
    this.hideSpinner()
    const status = this.resultsTarget.querySelector("[data-book-search-status]")
    this.liveRegionTarget.textContent = status ? status.textContent : ""
  }

  selectBook(event) {
    const { title, author, coverUrl, openLibraryKey } = event.params
    this.hiddenTitleTarget.value = title
    this.hiddenAuthorTarget.value = author
    this.hiddenCoverUrlTarget.value = coverUrl || ""
    this.hiddenOpenLibraryKeyTarget.value = openLibraryKey || ""
    if (this.hasErrorsTarget) this.errorsTarget.remove()
    this.#showSelection(title, author, coverUrl)
  }

  clearSelection() {
    this.hiddenTitleTarget.value = ""
    this.hiddenAuthorTarget.value = ""
    this.hiddenCoverUrlTarget.value = ""
    this.hiddenOpenLibraryKeyTarget.value = ""

    this.selectionPreviewTarget.classList.add("d-none")
    this.searchSectionTarget.classList.remove("d-none")

    this.queryTarget.value = ""
    this.resultsTarget.src = ""
    this.resultsTarget.innerHTML = ""
    this.liveRegionTarget.textContent = ""
    this.hideSpinner()
    this.queryTarget.focus()
  }

  #showSelection(title, author, coverUrl) {
    this.previewTitleTarget.textContent = title
    this.previewAuthorTarget.textContent = author

    if (coverUrl) {
      this.previewCoverTarget.src = coverUrl
      this.previewCoverTarget.classList.remove("d-none")
    } else {
      this.previewCoverTarget.classList.add("d-none")
    }

    this.searchSectionTarget.classList.add("d-none")
    this.selectionPreviewTarget.classList.remove("d-none")
  }
}

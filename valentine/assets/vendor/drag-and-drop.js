// Brainstorm drag & drop hook
const BrainstormDrag = {
    mounted() {
        // Delegate events within the masonry container
        this.handleEvent("brainstorm:scroll_into_view", ({ id }) => {
            const el = this.el.querySelector(`[data-item-id='${id}']`)
            if (el) el.scrollIntoView({ behavior: "smooth", block: "center" })
        })

        this.el.addEventListener("dragstart", e => {
            const card = e.target.closest("[data-item-id]")
            if (!card) return
            e.dataTransfer.effectAllowed = "move"
            e.dataTransfer.setData("text/plain", card.dataset.itemId)
            card.classList.add("dragging")
        })

        this.el.addEventListener("dragend", e => {
            const card = e.target.closest("[data-item-id]")
            if (card) card.classList.remove("dragging")
            this.clearDropHighlights()
        })

        this.el.addEventListener("dragover", e => {
            const column = e.target.closest("[data-type-column]")
            if (column) {
                e.preventDefault()
                e.dataTransfer.dropEffect = "move"
                column.classList.add("drag-over")
            }
        })

        this.el.addEventListener("dragleave", e => {
            const column = e.target.closest("[data-type-column]")
            if (column && !column.contains(e.relatedTarget)) {
                column.classList.remove("drag-over")
            }
        })

        this.el.addEventListener("drop", e => {
            const column = e.target.closest("[data-type-column]")
            if (!column) return
            e.preventDefault()
            const itemId = e.dataTransfer.getData("text/plain")
            const targetType = column.dataset.typeColumn
            if (itemId && targetType) {
                this.pushEvent("move_item", { id: itemId, type: targetType })
            }
            this.clearDropHighlights()
        })
    },
    clearDropHighlights() {
        this.el.querySelectorAll(".drag-over").forEach(el => el.classList.remove("drag-over"))
    }
}

export default BrainstormDrag
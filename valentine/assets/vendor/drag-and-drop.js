// Brainstorm drag & drop hook
const BrainstormDrag = {
    mounted() {
        // Delegate events within the masonry container
        this.handleEvent("brainstorm:scroll_into_view", ({ id }) => {
            const el = this.el.querySelector(`[data-item-id='${id}']`)
            if (el) el.scrollIntoView({ behavior: "smooth", block: "center" })
        })

        // --- Item drag logic (existing) ---

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
            e.preventDefault()
            const draggedType = this.draggedType
            const itemId = e.dataTransfer.getData("text/plain")
            if (draggedType) {
                // Column drop
                const targetColumn = column
                if (targetColumn) {
                    this.reorderColumns(draggedType, targetColumn.dataset.typeColumn)
                }
            } else if (column) {
                // Item drop
                const targetType = column.dataset.typeColumn
                if (itemId && targetType) {
                    this.pushEvent("move_item", { id: itemId, type: targetType })
                }
            }
            this.draggedType = null
            this.clearDropHighlights()
        })

        // --- Column drag logic ---
        this.el.addEventListener("dragstart", e => {
            const handle = e.target.closest('.type-drag-handle')
            if (handle) {
                const columnEl = handle.closest('[data-type-column]')
                if (columnEl) {
                    this.draggedType = columnEl.dataset.typeColumn
                    e.dataTransfer.effectAllowed = 'move'
                    e.dataTransfer.setData('text/plain', `type:${this.draggedType}`)
                    columnEl.classList.add('dragging-type')
                }
            }
        })

        this.el.addEventListener("dragend", e => {
            const typeCol = e.target.closest('[data-type-column]')
            if (typeCol) typeCol.classList.remove('dragging-type')
            this.draggedType = null
            this.clearDropHighlights()
        })

        this.el.addEventListener('dragover', e => {
            if (this.draggedType) {
                const target = e.target.closest('[data-type-column]')
                if (target) {
                    e.preventDefault()
                    target.classList.add('drag-over-type')
                }
            }
        })

        this.el.addEventListener('dragleave', e => {
            const target = e.target.closest('[data-type-column]')
            if (target && !target.contains(e.relatedTarget)) target.classList.remove('drag-over-type')
        })
    },
    clearDropHighlights() {
        this.el.querySelectorAll(".drag-over").forEach(el => el.classList.remove("drag-over"))
        this.el.querySelectorAll('.drag-over-type').forEach(el => el.classList.remove('drag-over-type'))
    },
    reorderColumns(dragType, targetType) {
        if (!dragType || !targetType || dragType === targetType) return
        const columns = Array.from(this.el.querySelectorAll('[data-type-column]'))
        const order = columns.map(c => c.dataset.typeColumn)
        const fromIdx = order.indexOf(dragType)
        const toIdx = order.indexOf(targetType)
        if (fromIdx === -1 || toIdx === -1) return
        order.splice(toIdx, 0, order.splice(fromIdx, 1)[0])
        this.pushEvent('reorder_types', { order })
    }
}

export default BrainstormDrag
// AutoSelect hook: selects all text on first focus (optional) and always on double-click
const AutoSelect = {
    mounted() {
        this.hasFocused = false
        this.el.addEventListener('dblclick', (e) => {
            e.stopPropagation()
            this.selectAll()
        })
        // If we want select-on-focus only once
        this.el.addEventListener('focus', () => {
            if (!this.hasFocused && this.el.dataset.autoselectOnce === 'true') {
                this.hasFocused = true
                this.selectAll()
            }
        })
    },
    selectAll() {
        try {
            this.el.select()
        } catch (_) { /* ignore */ }
    }
}

export default AutoSelect

const NativePrint = {
    mounted() {
        this.handleClick = event => {
            event.preventDefault()
            window.print()
        }

        this.el.addEventListener("click", this.handleClick)
        this.maybeAutoPrint()
    },

    updated() {
        this.maybeAutoPrint()
    },

    destroyed() {
        this.el.removeEventListener("click", this.handleClick)
    },

    maybeAutoPrint() {
        if (this.el.dataset.autoPrint !== "true") {
            return
        }

        this.el.dataset.autoPrint = "false"

        const url = new URL(window.location.href)
        url.searchParams.delete("print")
        window.history.replaceState(window.history.state, "", url)

        window.requestAnimationFrame(() => {
            window.requestAnimationFrame(() => window.print())
        })
    }
}

export default NativePrint
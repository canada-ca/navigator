import Quill from 'quill';
import "quill/dist/quill.snow.css";


const QuillHook = {
    mounted() {
        this.initializeQuill();
    },

    updated() {
        console.log("Quill Hook updated");
    },

    destroyed() {
        console.log("Quill Hook destroyed");
    },

    initializeQuill() {
        this.readOnly = this.el.dataset.readOnly === "true";
        this.q = new Quill(document.getElementById("quill-editor"), {
            theme: 'snow',
            readOnly: this.readOnly
        });
        this.saveBtn = document.getElementById("quill-save-btn");
        this.bindEvents();
        this.setupEventHandlers();
    },

    bindEvents() {
        if (!this.readOnly && this.saveBtn) {
            this.saveBtn.addEventListener("click", () => {
                this.pushEventTo(this.el, "quill-save", {
                    content: this.q.getSemanticHTML()
                });
            });
        }

        this.q.on('text-change', (delta, oldDelta, source) => {
            if (!this.readOnly && source === 'user') {
                this.pushEventTo(this.el, "quill-change", {
                    delta: delta,
                    oldDelta: oldDelta,
                    source: source
                });
            }
        });
    },

    setupEventHandlers() {
        this.handleEvent("updateQuill", ({ event, payload }) => {
            switch (event) {
                case "blob_change":
                    this.processBlobChange(payload);
                    break;

                case "text_change":
                    this.processTextChange(payload);
                    break;

                default:
                    console.error("Unknown event:", event);
            }
        });
    },

    processBlobChange(payload) {
        this.q.clipboard.dangerouslyPasteHTML(payload)
    },

    processTextChange(payload) {
        this.q.updateContents(payload);
    }
};

export default QuillHook;

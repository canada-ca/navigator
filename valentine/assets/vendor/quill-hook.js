import Quill from 'quill';
import "quill/dist/quill.snow.css";


const QuillHook = {
    mounted() {
        this.initializeQuill();
    },

    updated() {
        this.readOnly = this.el.dataset.readOnly === "true";
        this.q.enable(!this.readOnly);
        this.bindSaveButton();
    },

    destroyed() {
        this.saveBtn?.removeEventListener("click", this.onSave);
    },

    initializeQuill() {
        this.readOnly = this.el.dataset.readOnly === "true";
        this.q = new Quill(document.getElementById("quill-editor"), {
            theme: 'snow',
            readOnly: this.readOnly
        });
        this.onSave = () => {
            if (this.readOnly) return;
            this.pushEventTo(this.el, "quill-save", {
                content: this.q.getSemanticHTML()
            });
        };
        this.bindEvents();
        this.setupEventHandlers();
    },

    bindEvents() {
        this.bindSaveButton();

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

    bindSaveButton() {
        this.saveBtn?.removeEventListener("click", this.onSave);
        this.saveBtn = document.getElementById("quill-save-btn");
        this.saveBtn?.addEventListener("click", this.onSave);
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

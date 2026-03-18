import { beforeEach, describe, expect, it, vi } from "vitest";

const quillState = vi.hoisted(() => ({
    instance: null,
    handlers: {}
}));

vi.mock("quill", () => ({
    default: vi.fn(function MockQuill() {
        quillState.handlers = {};
        quillState.instance = {
            clipboard: {
                dangerouslyPasteHTML: vi.fn()
            },
            getSemanticHTML: vi.fn(() => "<p>Saved</p>"),
            on: vi.fn((name, callback) => {
                quillState.handlers[name] = callback;
            }),
            updateContents: vi.fn()
        };

        return quillState.instance;
    })
}));

vi.mock("quill/dist/quill.snow.css", () => ({}));

import Quill from "quill";
import QuillHook from "../vendor/quill-hook.js";

function buildHook() {
    document.body.innerHTML = `
    <div id="quill-editor"></div>
    <button id="quill-save-btn" type="button">Save</button>
    <div id="quill-hook"></div>
  `;

    const eventHandlers = {};

    return {
        ...QuillHook,
        el: document.getElementById("quill-hook"),
        eventHandlers,
        handleEvent: vi.fn((name, callback) => {
            eventHandlers[name] = callback;
        }),
        pushEventTo: vi.fn()
    };
}

describe("QuillHook", () => {
    beforeEach(() => {
        vi.spyOn(console, "log").mockImplementation(() => { });
        vi.spyOn(console, "error").mockImplementation(() => { });
    });

    it("mounts Quill and emits quill-save when the save button is clicked", () => {
        const hook = buildHook();

        hook.mounted();
        document.getElementById("quill-save-btn").click();

        expect(Quill).toHaveBeenCalledWith(document.getElementById("quill-editor"), {
            theme: "snow"
        });
        expect(hook.pushEventTo).toHaveBeenCalledWith(hook.el, "quill-save", {
            content: "<p>Saved</p>"
        });
    });

    it("emits quill-change only for user-originated text changes", () => {
        const hook = buildHook();
        const delta = { ops: [{ insert: "hello" }] };
        const oldDelta = { ops: [] };

        hook.mounted();
        quillState.handlers["text-change"](delta, oldDelta, "user");
        quillState.handlers["text-change"](delta, oldDelta, "api");

        expect(hook.pushEventTo).toHaveBeenCalledTimes(1);
        expect(hook.pushEventTo).toHaveBeenCalledWith(hook.el, "quill-change", {
            delta,
            oldDelta,
            source: "user"
        });
    });

    it("routes LiveView update events into blob and text processors", () => {
        const hook = buildHook();

        hook.mounted();
        hook.eventHandlers.updateQuill({ event: "blob_change", payload: "<p>Blob</p>" });
        hook.eventHandlers.updateQuill({ event: "text_change", payload: { ops: [{ insert: "World" }] } });

        expect(quillState.instance.clipboard.dangerouslyPasteHTML).toHaveBeenCalledWith("<p>Blob</p>");
        expect(quillState.instance.updateContents).toHaveBeenCalledWith({
            ops: [{ insert: "World" }]
        });
    });
});
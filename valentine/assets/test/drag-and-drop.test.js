import { describe, expect, it, vi } from "vitest";

import BrainstormDrag from "../vendor/drag-and-drop.js";

function buildHook() {
    document.body.innerHTML = `
    <div id="brainstorm">
      <div data-type-column="idea" class="drag-over">
        <button class="type-drag-handle" type="button"></button>
        <article data-item-id="item-1"></article>
      </div>
      <div data-type-column="risk" class="drag-over-type"></div>
      <div data-type-column="mitigation"></div>
    </div>
  `;

    const eventHandlers = {};
    const hook = {
        ...BrainstormDrag,
        draggedType: null,
        el: document.getElementById("brainstorm"),
        handleEvent: vi.fn((name, callback) => {
            eventHandlers[name] = callback;
        }),
        pushEvent: vi.fn()
    };

    hook.mounted();

    return { hook, eventHandlers };
}

describe("BrainstormDrag", () => {
    it("scrolls requested items into view via the LiveView event", () => {
        const { eventHandlers } = buildHook();
        const card = document.querySelector("[data-item-id='item-1']");
        card.scrollIntoView = vi.fn();

        eventHandlers["brainstorm:scroll_into_view"]({ id: "item-1" });

        expect(card.scrollIntoView).toHaveBeenCalledWith({ behavior: "smooth", block: "center" });
    });

    it("reorders columns and emits the new order", () => {
        const { hook } = buildHook();

        hook.reorderColumns("idea", "mitigation");

        expect(hook.pushEvent).toHaveBeenCalledWith("reorder_types", {
            order: ["risk", "mitigation", "idea"]
        });
    });

    it("clears both item and column drop highlight classes", () => {
        const { hook } = buildHook();

        hook.clearDropHighlights();

        expect(document.querySelectorAll(".drag-over")).toHaveLength(0);
        expect(document.querySelectorAll(".drag-over-type")).toHaveLength(0);
    });
});
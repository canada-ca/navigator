import { describe, expect, it, vi } from "vitest";

import EnhancedSelect from "../vendor/enhanced_select.js";

function buildHook({ minChars = "0" } = {}) {
    document.body.innerHTML = `
    <div id="enhanced" data-min-chars="${minChars}">
      <input data-role="input" aria-expanded="false" />
      <input data-role="value" type="hidden" value="" />
      <div data-role="empty" hidden>No results</div>
      <div data-role="list" hidden>
        <button class="enh-select-item" data-label="Alpha" data-value="alpha" type="button">Alpha</button>
        <button class="enh-select-item" data-label="Beta" data-value="beta" type="button">Beta</button>
        <button class="enh-select-item" data-label="Gamma" data-value="gamma" type="button">Gamma</button>
      </div>
    </div>
  `;

    const el = document.getElementById("enhanced");
    const listEl = el.querySelector('[data-role="list"]');

    el.getBoundingClientRect = () => ({
        width: 240,
        bottom: 80,
        left: 10,
        top: 20
    });

    listEl.getBoundingClientRect = () => ({
        width: 240,
        height: 100,
        top: 80,
        bottom: 180
    });

    const hook = {
        ...EnhancedSelect,
        el,
        pushEvent: vi.fn(),
        pushEventToggle: true
    };

    hook.mounted();

    return {
        hook,
        inputEl: el.querySelector('[data-role="input"]'),
        listEl,
        emptyEl: el.querySelector('[data-role="empty"]'),
        valueEl: el.querySelector('[data-role="value"]')
    };
}

describe("EnhancedSelect", () => {
    it("portals the list and opens when the input receives focus", () => {
        const { inputEl, listEl } = buildHook();

        inputEl.dispatchEvent(new FocusEvent("focus"));

        expect(document.body.contains(listEl)).toBe(true);
        expect(listEl.dataset.portaled).toBe("true");
        expect(inputEl.getAttribute("aria-expanded")).toBe("true");
        expect(listEl.hasAttribute("hidden")).toBe(false);
    });

    it("filters items and auto-selects the only visible option", () => {
        const { hook, inputEl, valueEl, emptyEl } = buildHook();

        inputEl.value = "bet";
        hook.filter();

        expect(valueEl.value).toBe("beta");
        expect(inputEl.value).toBe("Beta");
        expect(emptyEl.hidden).toBe(true);
    });

    it("supports keyboard selection and emits the changed value", () => {
        const { hook, inputEl, valueEl } = buildHook();
        const arrowEvent = { key: "ArrowDown", preventDefault: vi.fn() };
        const enterEvent = { key: "Enter", preventDefault: vi.fn() };

        hook.onKey(arrowEvent);
        hook.onKey(arrowEvent);
        hook.onKey(enterEvent);

        expect(valueEl.value).toBe("beta");
        expect(inputEl.value).toBe("Beta");
        expect(hook.pushEvent).toHaveBeenCalledWith("enhanced_select_changed", {
            id: "enhanced",
            value: "beta"
        });
    });
});
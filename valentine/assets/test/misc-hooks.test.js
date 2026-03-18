import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const chartState = vi.hoisted(() => ({
    instance: null
}));

vi.mock("apexcharts", () => ({
    default: vi.fn(function MockApexCharts(el, options) {
        chartState.instance = {
            el,
            options,
            render: vi.fn()
        };

        return chartState.instance;
    })
}));

import ApexCharts from "apexcharts";
import AutoHideFlash from "../vendor/autohide.js";
import AutoSelect from "../vendor/autoselect.js";
import Chart from "../vendor/chart-hook.js";
import ChatScroll from "../vendor/chat-scroll-hook.js";
import EnterSubmitHook from "../vendor/enter-submit-hook.js";
import NativePrint from "../vendor/native-print-hook.js";
import ResizableDrawer from "../vendor/resizeable-drawer-hook.js";
import Session from "../vendor/session-hook.js";

function buildAutoHideHook() {
    document.body.innerHTML = `
    <div data-auto-hide="true" data-hide-after="1000">
      <div id="flash-1" class="flash">Saved</div>
    </div>
  `;

    return {
        ...AutoHideFlash,
        el: document.body.firstElementChild,
        pushEvent: vi.fn(),
        updatedFlashTimeouts: new Map()
    };
}

describe("misc hooks", () => {
    beforeEach(() => {
        vi.useFakeTimers();
        vi.spyOn(console, "error").mockImplementation(() => { });
    });

    afterEach(() => {
        vi.useRealTimers();
    });

    it("auto-hides flash messages and clears pending timeouts on destroy", () => {
        const hook = buildAutoHideHook();
        const flash = hook.el.querySelector(".flash");

        hook.updated();
        vi.advanceTimersByTime(1000);
        expect(flash.style.opacity).toBe("0");

        vi.advanceTimersByTime(500);
        expect(hook.pushEvent).toHaveBeenCalledWith("lv:clear-flash");

        hook.updated();
        expect(hook.updatedFlashTimeouts.size).toBe(1);
        hook.destroyed();
        expect(hook.updatedFlashTimeouts.size).toBe(0);
    });

    it("scrolls chat containers on mount, update, and mutation observer changes", () => {
        document.body.innerHTML = '<div id="chat"></div>';
        const el = document.getElementById("chat");

        Object.defineProperty(el, "scrollHeight", { configurable: true, get: () => 320 });
        vi.spyOn(window, "requestAnimationFrame").mockImplementation((callback) => {
            callback();
            return 1;
        });

        const hook = { ...ChatScroll, el };

        hook.mounted();
        expect(el.scrollTop).toBe(320);

        MutationObserver.instances[0].trigger();
        expect(el.scrollTop).toBe(320);

        hook.destroyed();
        expect(MutationObserver.instances[0].disconnect).toHaveBeenCalledTimes(1);
    });

    it("resizes the drawer within min and max bounds", () => {
        document.body.innerHTML = `
      <aside id="drawer"><div class="resize-handle"></div></aside>
    `;

        const el = document.getElementById("drawer");
        const handle = el.querySelector(".resize-handle");
        const hook = { ...ResizableDrawer, el };

        vi.spyOn(window, "getComputedStyle").mockReturnValue({ width: "300px" });
        Object.defineProperty(window, "innerWidth", { configurable: true, value: 1000 });

        hook.mounted();
        handle.dispatchEvent(new MouseEvent("mousedown", { bubbles: true, clientX: 300 }));
        document.dispatchEvent(new MouseEvent("mousemove", { bubbles: true, clientX: 150 }));

        expect(el.style.width).toBe("450px");
        expect(el.classList.contains("is-resizing")).toBe(true);

        document.dispatchEvent(new MouseEvent("mouseup", { bubbles: true }));
        expect(el.classList.contains("is-resizing")).toBe(false);

        hook.destroyed();
    });

    it("submits trimmed chat input on Enter and clears the field", () => {
        document.body.innerHTML = '<textarea id="chat-input"></textarea>';
        const el = document.getElementById("chat-input");
        const hook = {
            ...EnterSubmitHook,
            el,
            pushEventTo: vi.fn()
        };

        hook.mounted();
        el.value = "  hello world  ";
        el.dispatchEvent(new KeyboardEvent("keydown", { bubbles: true, key: "Enter" }));

        expect(hook.pushEventTo).toHaveBeenCalledWith(el, "chat_submit", { value: "hello world" });
        expect(el.value).toBe("");
    });

    it("selects inputs on first focus and on double click", () => {
        document.body.innerHTML = '<input id="auto" data-autoselect-once="true" />';
        const el = document.getElementById("auto");
        el.select = vi.fn();

        const hook = { ...AutoSelect, el };

        hook.mounted();
        el.dispatchEvent(new FocusEvent("focus"));
        el.dispatchEvent(new MouseEvent("dblclick", { bubbles: true }));

        expect(el.select).toHaveBeenCalledTimes(2);
    });

    it("prints on click and auto-print while cleaning the URL", () => {
        document.body.innerHTML = '<a id="print" data-auto-print="true"></a>';
        const el = document.getElementById("print");
        const hook = { ...NativePrint, el };

        vi.spyOn(window, "print").mockImplementation(() => { });
        vi.spyOn(window.history, "replaceState").mockImplementation(() => { });
        vi.spyOn(window, "requestAnimationFrame").mockImplementation((callback) => {
            callback();
            return 1;
        });
        Object.defineProperty(window, "location", {
            configurable: true,
            value: new URL("https://example.test/workspaces/1?print=true")
        });

        hook.mounted();

        expect(window.history.replaceState).toHaveBeenCalled();
        expect(window.print).toHaveBeenCalledTimes(1);
        expect(el.dataset.autoPrint).toBe("false");

        el.dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true }));
        expect(window.print).toHaveBeenCalledTimes(2);

        hook.destroyed();
        el.dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true }));
        expect(window.print).toHaveBeenCalledTimes(2);
    });

    it("posts session updates with the CSRF token", async () => {
        document.head.innerHTML = '<meta name="csrf-token" content="csrf-123">';
        document.body.innerHTML = '<div id="session"></div>';

        const eventHandlers = {};
        const fetchSpy = vi.fn(() => Promise.resolve({ ok: true }));
        globalThis.fetch = fetchSpy;

        const hook = {
            ...Session,
            el: document.getElementById("session"),
            handleEvent: vi.fn((name, callback) => {
                eventHandlers[name] = callback;
            })
        };

        hook.mounted();
        await eventHandlers.session({ workspace_id: 7 });
        await Promise.resolve();

        expect(fetchSpy).toHaveBeenCalledWith("/session", {
            body: JSON.stringify({ workspace_id: 7 }),
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": "csrf-123"
            },
            method: "POST"
        });
    });

    it("renders charts from JSON options", () => {
        document.body.innerHTML = '<div id="chart" data-options="{&quot;series&quot;:[1,2,3]}"></div>';

        const hook = {
            ...Chart,
            el: document.getElementById("chart")
        };

        hook.mounted();

        expect(ApexCharts).toHaveBeenCalledWith(hook.el, { series: [1, 2, 3] });
        expect(chartState.instance.render).toHaveBeenCalledTimes(1);
    });
});
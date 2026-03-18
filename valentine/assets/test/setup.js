import { afterEach, beforeEach, vi } from "vitest";

class MockMutationObserver {
    static instances = [];

    constructor(callback) {
        this.callback = callback;
        this.observe = vi.fn();
        this.disconnect = vi.fn();
        MockMutationObserver.instances.push(this);
    }

    trigger(records = [], observer = this) {
        this.callback(records, observer);
    }

    static reset() {
        MockMutationObserver.instances = [];
    }
}

globalThis.MutationObserver = MockMutationObserver;
globalThis.requestAnimationFrame = vi.fn((callback) => {
    callback();
    return 1;
});
globalThis.cancelAnimationFrame = vi.fn();
window.requestAnimationFrame = globalThis.requestAnimationFrame;
window.cancelAnimationFrame = globalThis.cancelAnimationFrame;

beforeEach(() => {
    document.head.innerHTML = "";
    document.body.innerHTML = "";
    MockMutationObserver.reset();
});

afterEach(() => {
    vi.clearAllMocks();
    document.head.innerHTML = "";
    document.body.innerHTML = "";
});
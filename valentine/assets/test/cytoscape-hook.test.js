import { beforeEach, describe, expect, it, vi } from "vitest";

const cytoscapeState = vi.hoisted(() => ({
    lastOptions: null,
    mockCy: null
}));

vi.mock("cytoscape", () => {
    const factory = vi.fn((options) => {
        cytoscapeState.lastOptions = options;
        return cytoscapeState.mockCy;
    });

    factory.use = vi.fn();

    return { default: factory };
});

vi.mock("cytoscape-edgehandles", () => ({ default: { name: "edgehandles" } }));

import cytoscape from "cytoscape";
import CytoscapeHook from "../vendor/cytoscape-hook.js";

function createMockCy() {
    const styleUpdater = { update: vi.fn() };
    const styleApi = {
        fromJson: vi.fn(() => styleUpdater)
    };
    const element = {
        children: vi.fn(() => []),
        data: vi.fn(),
        descendants: vi.fn(() => []),
        grabify: vi.fn(),
        move: vi.fn(),
        position: vi.fn(),
        remove: vi.fn(),
        ungrabify: vi.fn(),
        unselect: vi.fn()
    };
    const elementsApi = {
        boundingBox: vi.fn(() => ({ w: 200, h: 200 })),
        remove: vi.fn()
    };
    const edgehandlesInstance = { start: vi.fn() };
    const zoom = vi.fn((value) => (typeof value === "undefined" ? 1 : value));

    return {
        add: vi.fn(() => ({ unselect: vi.fn() })),
        container: vi.fn(() => ({ clientWidth: 400, clientHeight: 400 })),
        destroy: vi.fn(),
        edgehandles: vi.fn(() => edgehandlesInstance),
        elements: vi.fn(() => elementsApi),
        fit: vi.fn(),
        getElementById: vi.fn(() => element),
        nodes: vi.fn(() => ({ length: 4 })),
        on: vi.fn(),
        png: vi.fn(() => "data:image/png;base64,abc"),
        resize: vi.fn(),
        style: vi.fn(() => styleApi),
        zoom
    };
}

function buildHook(dataset = {}) {
    document.body.innerHTML = '<div id="cy"></div>';

    const el = document.createElement("div");
    el.dataset.nodes = JSON.stringify(dataset.nodes || []);
    el.dataset.edges = JSON.stringify(dataset.edges || []);
    el.dataset.selectedtheme = dataset.selectedtheme || "light";
    el.dataset.user = dataset.user || "test-user";
    document.body.appendChild(el);

    const eventHandlers = {};
    const hook = {
        ...CytoscapeHook,
        el,
        eventHandlers,
        handleEvent: vi.fn((name, callback) => {
            eventHandlers[name] = callback;
        }),
        pushEventTo: vi.fn()
    };

    return hook;
}

describe("CytoscapeHook", () => {
    beforeEach(() => {
        cytoscapeState.lastOptions = null;
        cytoscapeState.mockCy = createMockCy();
        vi.spyOn(console, "log").mockImplementation(() => { });
        vi.spyOn(console, "warn").mockImplementation(() => { });
    });

    it("mounts Cytoscape with preset layout and registers the graph event handler", () => {
        const hook = buildHook({ nodes: [{ data: { id: "node-1" } }] });

        hook.mounted();

        expect(cytoscape.use).toHaveBeenCalled();
        expect(cytoscape).toHaveBeenCalledTimes(1);
        expect(cytoscapeState.lastOptions.layout).toEqual({ name: "preset", fit: false });
        expect(cytoscapeState.lastOptions.elements).toEqual([{ data: { id: "node-1" } }]);
        expect(hook.handleEvent).toHaveBeenCalledWith("updateGraph", expect.any(Function));
        expect(cytoscapeState.mockCy.fit).toHaveBeenCalledTimes(1);
    });

    it("exports a full PNG on save without mutating the viewport", () => {
        const hook = buildHook();
        hook.cy = cytoscapeState.mockCy;

        hook.save();

        expect(cytoscapeState.mockCy.png).toHaveBeenCalledWith({ full: true });
        expect(cytoscapeState.mockCy.fit).not.toHaveBeenCalled();
        expect(hook.pushEventTo).toHaveBeenCalledWith(hook.el, "export", {
            base64: "data:image/png;base64,abc"
        });
    });

    it("auto-fits only when add_node deems the layout needs it", () => {
        const hook = buildHook();
        hook.mounted();
        hook.addNode = vi.fn();
        hook.fitView = vi.fn();
        hook.shouldFitView = vi.fn(() => true);

        hook.eventHandlers.updateGraph({ event: "add_node", payload: { data: { id: "node-2" } } });

        expect(hook.addNode).toHaveBeenCalledWith({ data: { id: "node-2" } });
        expect(hook.fitView).toHaveBeenCalledTimes(1);
    });

    it("refreshes the graph by replacing elements and fitting the result", () => {
        const hook = buildHook();
        hook.cy = cytoscapeState.mockCy;

        hook.refreshGraph({
            nodes: [{ data: { id: "node-1" } }],
            edges: [{ data: { id: "edge-1" } }]
        });

        expect(cytoscapeState.mockCy.elements).toHaveBeenCalled();
        expect(cytoscapeState.mockCy.add).toHaveBeenCalledWith([
            { data: { id: "node-1" } },
            { data: { id: "edge-1" } }
        ]);
        expect(cytoscapeState.mockCy.fit).toHaveBeenCalledTimes(1);
    });

    it("computes fit decisions from node count and occupied viewport", () => {
        const hook = buildHook();
        hook.cy = cytoscapeState.mockCy;

        cytoscapeState.mockCy.nodes.mockReturnValue({ length: 3 });
        expect(hook.shouldFitView()).toBe(false);

        cytoscapeState.mockCy.nodes.mockReturnValue({ length: 4 });
        cytoscapeState.mockCy.elements.mockReturnValue({
            boundingBox: vi.fn(() => ({ w: 360, h: 150 }))
        });
        expect(hook.shouldFitView()).toBe(true);

        cytoscapeState.mockCy.elements.mockReturnValue({
            boundingBox: vi.fn(() => ({ w: 50, h: 50 }))
        });
        expect(hook.shouldFitView()).toBe(true);
    });

    it("destroys the Cytoscape instance when the hook is torn down", () => {
        const hook = buildHook();
        hook.cy = cytoscapeState.mockCy;

        hook.destroyed();

        expect(cytoscapeState.mockCy.destroy).toHaveBeenCalledTimes(1);
    });
});
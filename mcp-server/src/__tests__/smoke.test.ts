import { describe, it, expect } from "vitest";

describe("MCP server scaffold", () => {
    it("loads without error", async () => {
        // Validates the module can be imported (basic smoke test)
        const loader = await import("../loader.js");
        expect(loader.loadRegistry).toBeDefined();
    });
});

import { describe, it, expect } from "vitest";
import { readFileSync, existsSync } from "node:fs";
import { resolve } from "node:path";
import { execSync } from "node:child_process";

const REPO_ROOT = resolve(import.meta.dirname, "../../..");
const REGISTRY_PATH = resolve(import.meta.dirname, "../../registry.json");

interface RegistryEntry {
    name: string;
    skill: string;
    description: string;
}

interface Registry {
    tools: RegistryEntry[];
}

function loadRegistry(): Registry {
    const raw = readFileSync(REGISTRY_PATH, "utf-8");
    return JSON.parse(raw) as Registry;
}

function findActionSkills(): string[] {
    const output = execSync(
        `grep -rl "> \\*\\*Type:\\*\\* action" clusters/01-meta/*/SKILL.md clusters/07-devops/*/SKILL.md 2>/dev/null || true`,
        { cwd: REPO_ROOT, encoding: "utf-8" }
    );
    return output
        .trim()
        .split("\n")
        .filter((line) => line.length > 0);
}

describe("registry.json bidirectional validation", () => {
    const registry = loadRegistry();

    it("is valid JSON with a tools array", () => {
        expect(registry).toHaveProperty("tools");
        expect(Array.isArray(registry.tools)).toBe(true);
    });

    it("has no duplicate tool names", () => {
        const names = registry.tools.map((t) => t.name);
        const unique = new Set(names);
        expect(names.length).toBe(unique.size);
    });

    it("every registry entry points to a SKILL.md that exists", () => {
        for (const tool of registry.tools) {
            const skillPath = resolve(REPO_ROOT, tool.skill);
            expect(
                existsSync(skillPath),
                `Registry entry "${tool.name}" points to missing file: ${tool.skill}`
            ).toBe(true);
        }
    });

    it("every registry entry points to a SKILL.md with Type: action", () => {
        for (const tool of registry.tools) {
            const skillPath = resolve(REPO_ROOT, tool.skill);
            const content = readFileSync(skillPath, "utf-8");
            expect(
                content.includes("> **Type:** action"),
                `Registry entry "${tool.name}" points to SKILL.md without Type: action`
            ).toBe(true);
        }
    });

    it("every SKILL.md with Type: action has a registry entry", () => {
        const actionSkills = findActionSkills();
        const registeredPaths = new Set(registry.tools.map((t) => t.skill));

        for (const skillPath of actionSkills) {
            expect(
                registeredPaths.has(skillPath),
                `SKILL.md at "${skillPath}" has Type: action but no registry entry`
            ).toBe(true);
        }
    });

    it("every entry has a non-empty description", () => {
        for (const tool of registry.tools) {
            expect(
                tool.description.length > 0,
                `Tool "${tool.name}" has empty description`
            ).toBe(true);
        }
    });

    it("every entry has a valid tool name (lowercase, hyphens only)", () => {
        for (const tool of registry.tools) {
            expect(
                /^[a-z][a-z0-9-]*$/.test(tool.name),
                `Tool name "${tool.name}" contains invalid characters`
            ).toBe(true);
        }
    });
});

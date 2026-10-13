import { describe, it, expect } from "vitest";
import { readFileSync, existsSync } from "node:fs";
import { resolve } from "node:path";
import { execSync } from "node:child_process";
import { loadRegistry as loadTools, parseFrontmatterDescription, resolveCommand } from "../loader.js";

const REPO_ROOT = resolve(import.meta.dirname, "../../..");
const REGISTRY_PATH = resolve(import.meta.dirname, "../../registry.json");

interface RegistryEntry {
    name: string;
    skill: string;
    description?: string;
}

interface Registry {
    tools: RegistryEntry[];
    excluded: { skill: string; reason: string }[];
}

function loadRegistry(): Registry {
    const raw = readFileSync(REGISTRY_PATH, "utf-8");
    return JSON.parse(raw) as Registry;
}

function findActionSkills(): string[] {
    const output = execSync(
        `grep -rl "> \\*\\*Type:\\*\\* action" clusters/*/*/SKILL.md 2>/dev/null || true`,
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

    it("every SKILL.md with Type: action is registered or excluded with a reason", () => {
        const covered = new Set([
            ...registry.tools.map((t) => t.skill),
            ...registry.excluded.filter((e) => e.reason.trim()).map((e) => e.skill),
        ]);
        for (const skillPath of findActionSkills()) {
            expect(covered.has(skillPath), `${skillPath} is neither registered nor excluded`).toBe(true);
        }
    });

    it("every entry's script exists", () => {
        for (const tool of registry.tools) {
            const script = tool.script.split(" ")[0];
            expect(existsSync(resolve(REPO_ROOT, script)), `${tool.name}: missing ${script}`).toBe(true);
        }
    });

    it("a tool call runs only its registered script plus caller args", () => {
        for (const tool of registry.tools) {
            const [script, ...fixed] = tool.script.split(" ");
            const argv = resolveCommand(tool, ["--x"]);
            expect(argv).toEqual([
                script.endsWith(".py") ? "python3" : "bash",
                resolve(REPO_ROOT, script),
                ...fixed,
                "--x",
            ]);
        }
    });

    it("loaded tool descriptions equal SKILL.md frontmatter descriptions", async () => {
        const tools = await loadTools();
        expect(tools.length).toBe(registry.tools.length);
        for (const entry of registry.tools) {
            const content = readFileSync(resolve(REPO_ROOT, entry.skill), "utf-8");
            const expected = parseFrontmatterDescription(content);
            expect(expected, `${entry.skill} has no frontmatter description`).toBeTruthy();
            expect(tools.find((t) => t.name === entry.name)?.description).toBe(expected);
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

import { readFile } from "node:fs/promises";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { executeTool } from "./executor.js";
import { logger } from "./logger.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, "../..");

export interface ToolDefinition {
    name: string;
    description: string;
    inputSchema: Record<string, unknown>;
    execute: (args: Record<string, unknown>) => Promise<string>;
}

export interface RegistryEntry {
    name: string;
    skill: string;
    /** Repo-relative script path, optionally followed by fixed arguments. */
    script: string;
    description?: string;
}

interface Registry {
    tools: RegistryEntry[];
}

/** Returns the one-line quoted `description:` from the leading frontmatter, if any. */
export function parseFrontmatterDescription(skillContent: string): string | undefined {
    const lines = skillContent.split("\n").slice(0, 6);
    for (const line of lines.slice(1)) {
        const m = /^description: "(.*)"$/.exec(line);
        if (m) return m[1];
    }
    return undefined;
}

/** The exact argv a tool call runs: interpreter, script, fixed args, then caller args. */
export function resolveCommand(entry: RegistryEntry, callerArgs: string[] = []): string[] {
    const [script, ...fixed] = entry.script.split(" ").filter(Boolean);
    const interpreter = script.endsWith(".py") ? "python3" : "bash";
    return [interpreter, resolve(REPO_ROOT, script), ...fixed, ...callerArgs];
}

/**
 * Loads the registry and resolves each entry to a full tool definition.
 */
export async function loadRegistry(): Promise<ToolDefinition[]> {
    const registryPath = resolve(__dirname, "../registry.json");
    const registryRaw = await readFile(registryPath, "utf-8");
    const registry: Registry = JSON.parse(registryRaw) as Registry;

    const tools: ToolDefinition[] = [];

    for (const entry of registry.tools) {
        const skillPath = resolve(REPO_ROOT, entry.skill);
        const skillContent = await readFile(skillPath, "utf-8");
        let description = parseFrontmatterDescription(skillContent);
        if (!description) {
            description = entry.description || entry.name;
            logger.warn("loader", `No frontmatter description for ${entry.name}; using fallback`);
        }

        tools.push({
            name: entry.name,
            description,
            inputSchema: {
                type: "object",
                properties: {
                    workingDirectory: {
                        type: "string",
                        description: "Working directory to execute commands in (defaults to cwd)",
                    },
                    args: {
                        type: "array",
                        items: { type: "string" },
                        description: "Arguments passed to the tool's script",
                    },
                },
            },
            execute: async (args: Record<string, unknown>) => {
                const cwd = (args.workingDirectory as string) || process.cwd();
                return executeTool(resolveCommand(entry, (args.args as string[]) ?? []), cwd);
            },
        });
    }

    return tools;
}

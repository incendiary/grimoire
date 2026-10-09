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

interface RegistryEntry {
    name: string;
    skill: string;
    description?: string;
}

interface Registry {
    tools: RegistryEntry[];
}

/**
 * Parses a SKILL.md to extract shell commands from code blocks
 * following "## What to do" or within the tool's action sections.
 */
function extractCommands(skillContent: string): string[] {
    const commands: string[] = [];
    const codeBlockRegex = /```(?:bash|sh)\n([\s\S]*?)```/g;
    let match: RegExpExecArray | null;

    while ((match = codeBlockRegex.exec(skillContent)) !== null) {
        const block = match[1].trim();
        if (block && !block.startsWith("#")) {
            commands.push(block);
        }
    }

    return commands;
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
        const commands = extractCommands(skillContent);
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
                },
            },
            execute: async (args: Record<string, unknown>) => {
                const cwd = (args.workingDirectory as string) || process.cwd();
                return executeTool(commands, cwd);
            },
        });
    }

    return tools;
}

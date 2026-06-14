import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { loadRegistry } from "./loader.js";
import { logger } from "./logger.js";

const server = new McpServer({
    name: "grimoire",
    version: "0.1.0",
});

const toolInputSchema = {
    workingDirectory: z
        .string()
        .optional()
        .describe("Working directory to execute commands in (defaults to cwd)"),
};

// Track startup time for health-check
const startupTime = Date.now();

async function main(): Promise<void> {
    logger.info("startup", "Grimoire MCP server starting", {
        nodeVersion: process.version,
        pid: process.pid,
    });

    let tools: Awaited<ReturnType<typeof loadRegistry>>;
    try {
        tools = await loadRegistry();
        logger.info("startup", `Loaded ${tools.length} tools from registry`);
    } catch (error: unknown) {
        // FAIL OPEN: If registry fails to load, start with zero tools rather than crashing
        const msg = error instanceof Error ? error.message : String(error);
        logger.error("startup", `Registry load failed — starting with 0 tools (fail-open)`, { error: msg });
        tools = [];
    }

    for (const tool of tools) {
        server.tool(
            tool.name,
            tool.description,
            toolInputSchema,
            async (args) => {
                const startTime = Date.now();
                logger.info("tool-call", `Executing: ${tool.name}`, { args });

                try {
                    const result = await tool.execute(args);
                    const elapsed = Date.now() - startTime;
                    logger.info("tool-call", `Completed: ${tool.name} (${elapsed}ms)`);
                    return {
                        content: [{ type: "text", text: result }],
                    };
                } catch (error: unknown) {
                    // FAIL OPEN: Return error as text content, never crash the server
                    const elapsed = Date.now() - startTime;
                    const msg = error instanceof Error ? error.message : String(error);
                    const stack = error instanceof Error ? error.stack : undefined;

                    logger.error("tool-call", `Failed: ${tool.name} (${elapsed}ms)`, {
                        error: msg,
                        stack,
                    });

                    return {
                        content: [
                            {
                                type: "text",
                                text: `[grimoire] Tool "${tool.name}" failed: ${msg}\n\nThe server is still running. Check logs at: ${logger.logFile}`,
                            },
                        ],
                        isError: true,
                    };
                }
            }
        );
        logger.debug("startup", `Registered tool: ${tool.name}`);
    }

    // Built-in health-check tool (no-op, returns server diagnostics)
    server.tool(
        "grimoire_health",
        "Returns server uptime, tool count, and log file path for diagnostics",
        {},
        async () => {
            const uptimeMs = Date.now() - startupTime;
            const uptimeMin = Math.floor(uptimeMs / 60000);
            const info = {
                status: "ok",
                uptime: `${uptimeMin}m ${Math.floor((uptimeMs % 60000) / 1000)}s`,
                toolCount: tools.length,
                logFile: logger.logFile,
                nodeVersion: process.version,
                pid: process.pid,
            };
            return {
                content: [{ type: "text", text: JSON.stringify(info, null, 2) }],
            };
        }
    );
    logger.debug("startup", "Registered built-in tool: grimoire_health");

    const transport = new StdioServerTransport();
    await server.connect(transport);
    logger.info("startup", "Server connected via stdio — ready for requests");
}

// Global uncaught exception handler — log and continue if possible
process.on("uncaughtException", (error: Error) => {
    logger.error("uncaught", `Uncaught exception (server still running)`, {
        error: error.message,
        stack: error.stack,
    });
});

process.on("unhandledRejection", (reason: unknown) => {
    const msg = reason instanceof Error ? reason.message : String(reason);
    logger.error("uncaught", `Unhandled rejection (server still running)`, { error: msg });
});

main().catch((error: unknown) => {
    const msg = error instanceof Error ? error.message : String(error);
    logger.error("fatal", `Server failed to start`, { error: msg });
    process.exit(1);
});

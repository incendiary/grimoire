import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { loadRegistry } from "./loader.js";

const server = new McpServer({
    name: "grimoire",
    version: "0.1.0",
});

async function main(): Promise<void> {
    const tools = await loadRegistry();

    for (const tool of tools) {
        server.tool(
            tool.name,
            tool.description,
            tool.inputSchema,
            async (args) => {
                const result = await tool.execute(args);
                return {
                    content: [{ type: "text", text: result }],
                };
            }
        );
    }

    const transport = new StdioServerTransport();
    await server.connect(transport);
}

main().catch((error: unknown) => {
    console.error("Fatal error:", error);
    process.exit(1);
});

import { appendFileSync, mkdirSync, statSync, renameSync, unlinkSync, readdirSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const LOG_DIR = resolve(__dirname, "../logs");
const LOG_FILE = resolve(LOG_DIR, "mcp-server.log");
const MAX_LOG_SIZE = 10 * 1024 * 1024; // 10MB
const MAX_LOG_FILES = 3;

// Ensure log directory exists on module load
try {
    mkdirSync(LOG_DIR, { recursive: true });
} catch {
    // If we can't create logs dir, we'll fall back to stderr only
}

type LogLevel = "INFO" | "WARN" | "ERROR" | "DEBUG";

function timestamp(): string {
    return new Date().toISOString();
}

function formatMessage(level: LogLevel, context: string, message: string, meta?: Record<string, unknown>): string {
    const base = `[${timestamp()}] [${level}] [${context}] ${message}`;
    if (meta && Object.keys(meta).length > 0) {
        return `${base} ${JSON.stringify(meta)}`;
    }
    return base;
}

function rotateIfNeeded(): void {
    try {
        const stats = statSync(LOG_FILE);
        if (stats.size < MAX_LOG_SIZE) return;

        // Rotate: mcp-server.log → mcp-server.1.log, .1 → .2, etc.
        // Delete oldest if we exceed MAX_LOG_FILES
        const existing = readdirSync(LOG_DIR)
            .filter(f => f.startsWith("mcp-server.") && f.endsWith(".log"))
            .sort();

        // Remove oldest rotated logs beyond limit
        const rotated = existing.filter(f => f !== "mcp-server.log");
        while (rotated.length >= MAX_LOG_FILES) {
            const oldest = rotated.shift()!;
            unlinkSync(resolve(LOG_DIR, oldest));
        }

        // Shift existing rotated files up by one
        for (let i = rotated.length; i > 0; i--) {
            const from = resolve(LOG_DIR, `mcp-server.${i}.log`);
            const to = resolve(LOG_DIR, `mcp-server.${i + 1}.log`);
            try { renameSync(from, to); } catch { /* may not exist */ }
        }

        // Rotate current to .1
        renameSync(LOG_FILE, resolve(LOG_DIR, "mcp-server.1.log"));
    } catch {
        // Rotation is best-effort — never crash
    }
}

function write(level: LogLevel, context: string, message: string, meta?: Record<string, unknown>): void {
    const line = formatMessage(level, context, message, meta);

    // Always write to stderr (MCP uses stdout for protocol, stderr for diagnostics)
    process.stderr.write(`${line}\n`);

    // Also persist to file
    try {
        rotateIfNeeded();
        appendFileSync(LOG_FILE, `${line}\n`);
    } catch {
        // Fail silently — logging should never crash the server
    }
}

export const logger = {
    info: (context: string, message: string, meta?: Record<string, unknown>) =>
        write("INFO", context, message, meta),

    warn: (context: string, message: string, meta?: Record<string, unknown>) =>
        write("WARN", context, message, meta),

    error: (context: string, message: string, meta?: Record<string, unknown>) =>
        write("ERROR", context, message, meta),

    debug: (context: string, message: string, meta?: Record<string, unknown>) =>
        write("DEBUG", context, message, meta),

    /** Log file path for diagnostics */
    logFile: LOG_FILE,
};

import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

const TIMEOUT_MS = 30_000;

/**
 * Runs one command as an argv array (no shell, so arguments are never interpolated)
 * and returns combined output.
 */
export async function executeTool(argv: string[], cwd: string): Promise<string> {
    const [file, ...args] = argv;
    try {
        const { stdout, stderr } = await execFileAsync(file, args, { cwd, timeout: TIMEOUT_MS });
        return [stdout.trim(), stderr.trim() && `[stderr] ${stderr.trim()}`].filter(Boolean).join("\n\n");
    } catch (error: unknown) {
        const err = error as { message?: string; code?: number | string; stdout?: string; stderr?: string };
        return [
            err.stdout?.trim(),
            err.stderr?.trim() && `[stderr] ${err.stderr.trim()}`,
            `[ERROR] exit code ${err.code ?? "unknown"}: ${err.message ?? "unknown error"}`,
        ]
            .filter(Boolean)
            .join("\n\n");
    }
}

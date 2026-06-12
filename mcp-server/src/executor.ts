import { exec } from "node:child_process";
import { promisify } from "node:util";

const execAsync = promisify(exec);

const TIMEOUT_MS = 30_000;

/**
 * Executes a sequence of shell commands and returns combined output.
 */
export async function executeTool(
    commands: string[],
    cwd: string
): Promise<string> {
    const results: string[] = [];

    for (const command of commands) {
        try {
            const { stdout, stderr } = await execAsync(command, {
                cwd,
                timeout: TIMEOUT_MS,
                shell: "/bin/zsh",
            });

            if (stdout.trim()) {
                results.push(`$ ${command}\n${stdout.trim()}`);
            }
            if (stderr.trim()) {
                results.push(`[stderr] ${stderr.trim()}`);
            }
        } catch (error: unknown) {
            const err = error as { message?: string; code?: number };
            results.push(
                `$ ${command}\n[ERROR] exit code ${err.code ?? "unknown"}: ${err.message ?? "unknown error"}`
            );
        }
    }

    return results.join("\n\n");
}

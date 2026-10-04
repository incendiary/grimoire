# Task RA-19: Clear MCP server npm advisories and add Dependabot

> Status: pending
> Parent: discoverability and consolidation programme
> Model: haiku
> Fallback: sonnet
> Depends on: none
> Effort: XS
> Touches: `mcp-server/package-lock.json`, `.github/dependabot.yml` (new), `CHANGELOG.md`

## Objective
Remove the known npm advisories in the MCP server's dependency tree without changing
direct dependency versions, and add weekly Dependabot updates.

## Background
- `npm audit` (2026-09-29) reported 9 advisories (3 high, 5 moderate, 1 low), all in
  transitive dependencies of `@modelcontextprotocol/sdk` (`fast-uri`, `hono`,
  `@hono/node-server`, `body-parser`). All are marked "fix available via `npm audit fix`".
- Direct dependencies in `mcp-server/package.json` are exact-pinned deliberately. Do not
  change `package.json`.
- The server uses stdio transport, so exposure is low; this is hygiene.

## Steps
1. Run, from the repo root:
   ```bash
   cd mcp-server
   npm ci
   npm audit --omit=dev
   npm audit fix
   ```
   Do **not** use `npm audit fix --force`.
2. Confirm `git diff --stat` shows only `mcp-server/package-lock.json`. If
   `package.json` changed, run `git checkout -- package.json` and stop with
   `CHUNK BLOCKED: RA-19 audit fix wanted to change package.json`.
3. Run `npm run build && npm run lint && npm test`. All must pass. Then `cd ..`.
4. Create `.github/dependabot.yml` with exactly:
   ```yaml
   version: 2
   updates:
     - package-ecosystem: "npm"
       directory: "/mcp-server"
       schedule:
         interval: "weekly"
     - package-ecosystem: "github-actions"
       directory: "/"
       schedule:
         interval: "weekly"
   ```
5. `CHANGELOG.md` → `### Security` (create the subsection under `## [Unreleased]` if
   absent): `- Resolved transitive npm advisories in mcp-server (npm audit fix); added weekly Dependabot for npm and GitHub Actions.`

## Constraints
- Lockfile-only change in `mcp-server/`.

## Done when
- [ ] `cd mcp-server && npm audit --omit=dev --audit-level=high` exits 0.
- [ ] `npm run build && npm run lint && npm test` pass.
- [ ] `git diff --stat main` lists only `mcp-server/package-lock.json`, `.github/dependabot.yml`, `CHANGELOG.md`, `ROADMAP.md`, and this task file.
- [ ] `python3 -c "import yaml,sys;yaml.safe_load(open('.github/dependabot.yml'))"` succeeds (if PyYAML is unavailable, skip this check and say so).

## Return signal
Commit message: `fix: resolve mcp-server npm advisories and add dependabot`
Then follow Shared conventions step 7.

# Task RA-27: Share duplicated functions between the MCP installers

> Status: done
> Parent: discoverability and consolidation programme
> Model: sonnet
> Fallback: opus
> Depends on: none
> Effort: S
> Touches: `scripts/install-lib.sh` (new), `install-vscode.sh`, `install-jetbrains.sh`, `uninstall-vscode.sh`, `CHANGELOG.md`

## Objective
Functions duplicated across the VS Code and JetBrains installers live in one sourced file,
with behaviour unchanged.

## Background
- `install-vscode.sh` (461 lines) and `install-jetbrains.sh` (315) share about 93
  identical lines, including `resolve_node_bin()` (absolute path to Node 22+, needed because
  GUI IDEs do not inherit nvm `PATH`) and `backup_file()` (timestamped, keep last 5).
  `detect_mcp_support()` / `detect_mcp_support_jetbrains()` and the MCP config merge are
  near-duplicates. `uninstall-vscode.sh` duplicates `detect_vscode_user_dir()`.
- Decided: a sourced library, not a merged installer. The two entry scripts and their
  flags (`--apply`, `--dry-run`, `--mcp-path`) stay exactly as they are for the owner.
- Both machines rely on these installers (VS Code and JetBrains). Behaviour must not change.

## Steps
1. Diff the shared functions across the three scripts. Move each function that is identical
   (or identical apart from a name or one parameter) into `scripts/install-lib.sh`
   (no shebang execution; header comment says it is sourced). Parameterise genuine
   differences with arguments rather than copies.
2. In each installer, replace the moved functions with
   `source "$(dirname "$0")/scripts/install-lib.sh"` near the top (installers live at repo root).
3. Keep functions used by only one script where they are.
4. `CHANGELOG.md` → `### Changed`: `- install-vscode.sh, install-jetbrains.sh and uninstall-vscode.sh share scripts/install-lib.sh.`

## Done when
- [ ] `shellcheck -x install-vscode.sh install-jetbrains.sh uninstall-vscode.sh scripts/install-lib.sh` clean.
- [ ] For each of `install-vscode.sh --dry-run`, `install-jetbrains.sh --dry-run`, `uninstall-vscode.sh --dry-run`: output on this branch is identical to output on `main` (run both, `diff` them; timestamps excepted).
- [ ] `wc -l` total of the three installers plus the library is at least 60 lines lower than the three installers on `main`.

## Return signal
Commit message: `refactor: share installer functions via scripts/install-lib.sh`
Then follow Shared conventions step 7.

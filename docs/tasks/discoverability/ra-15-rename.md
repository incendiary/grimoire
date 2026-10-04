# Task RA-15: Execute the pathway-prefix rename

> Status: pending
> Parent: discoverability and consolidation programme
> Model: sonnet
> Review: opus (master reviews the full diff before integrating)
> Fallback: opus
> Depends on: every task in waves 1 to 3
> Effort: L
> Touches: 33 skill directories (renamed), almost every `.md` in the repo, `mcp-server/registry.json`, `mcp-server/src/__tests__/*`, `.github/workflows/*`, `install-all.sh`, `uninstall-all.sh`, `tests/test-install-renames.sh` (new), `scripts/renamed-skills.txt`, `CHANGELOG.md`

## Objective
Every remaining skill is renamed to the pathway-prefix scheme, every reference is
updated, and installing on a machine that has the old names removes them.

## Background
- Owner decisions: hard rename (no alias stubs), pathway-prefix scheme. Typing a prefix
  such as `/release` in Claude Code autocompletes the whole pathway, so the owner only
  needs to recall 13 prefixes.
- Merges and renames already landed (`ci-local`, `py-lint`, `deps-integrity`, `tf-guardrails`,
  `ci-standards`, `roadmap`, `orient`) and five skills were deleted. This task is the remaining pure renames.
- Skills stay in their current cluster directories (directory restructure is deferred).
- **Script file names do not change** (for example `branch-surface-resolve.sh` stays as it is inside
  `orient-branches/`). The owner's tooling may call them by name.

## Rename list (32)

| Old | New |
|---|---|
| branch-surface-resolve | orient-branches |
| github-morning-run | orient-morning-run |
| github-authored-repos | orient-authored-repos |
| karpathy-framework | plan |
| karpathy-spec | plan-spec |
| karpathy-verify | plan-verify |
| karpathy-environment | plan-environment |
| task-decomposer | plan-decompose |
| task-handoff | plan-handoff |
| model-selection-framework | plan-model-tier |
| project-delivery-workflow | roadmap-deliver |
| python-ci-template | ci-python |
| dotnet-ci-template | ci-dotnet |
| test-bootstrap | ci-tests |
| github-release-workflow | release |
| readme-version-pin | release-readme-pin |
| docker-ghcr-publish | release-docker-ghcr |
| repo-publication-prep | publish |
| github-history-wipe | publish-history-wipe |
| repo-security-bootstrap | publish-secret-scan |
| portfolio-readme-generator | publish-readme |
| tone-check | write-tone |
| human-rewrite | write-human |
| executive-translate | write-exec |
| incident-ask-builder | incident-asks |
| risk-to-action | incident-risk-plan |
| codebase-holistic-review | review-codebase |
| ui-ux-product-audit | review-ui |
| skill-vetter | review-skill |
| ios-signing-risk | review-ios-signing |
| skill-keyword-lookup | grimoire-find |
| session-skill-extractor | grimoire-extract |

Unchanged: `roadmap-sync`, `incident-appendix`. Expected result: 41 skill directories.
Before starting, check every Old directory exists (`ls -d clusters/*/<old>`); if any does
not, stop with `CHUNK BLOCKED`.

## Matching rules (why a plain find-and-replace is wrong)
Replace an old name only where it is a whole token:
- Preceding character is not `[A-Za-z0-9-]` (underscore is allowed before, so
  `mcp__grimoire__github-morning-run` becomes `mcp__grimoire__orient-morning-run`).
- Following character is not `[A-Za-z0-9-]`, **and** the name is not followed by `.sh`
  or `.py` (script file names stay).
In Python: `re.sub(r'(?<![A-Za-z0-9-])' + re.escape(old) + r'(?![A-Za-z0-9-]|\.sh\b|\.py\b)', new, text)`.

## Steps
1. Write a one-off rename tool in `/tmp/apply-renames.py` (do not commit it). It must:
   - `git mv clusters/<cluster>/<old> clusters/<cluster>/<new>` for each row.
   - Apply the matching rule to every tracked text file (`git ls-files`) except
     `CHANGELOG.md`, `REVIEW.md`, `scripts/renamed-skills.txt`, `docs/discoverability-intents.md`,
     `docs/tasks/**`, and anything under `node_modules/`. This covers `SKILL.md`
     frontmatter `name:`, `# headings`, descriptions, READMEs, `registry.json`, tests,
     workflows, `CLAUDE.md`, `PROJECT-WORKFLOWS.md`, `SKILLS.md`.
   - Print a per-file count of replacements.
   Run it with a `--dry-run` first and read the counts for surprises (for example a
   replacement inside a URL or a script name).
2. Append all 32 `old<TAB>new` lines to `scripts/renamed-skills.txt`.
3. `install-all.sh` (default and `--update`) and `uninstall-all.sh`: read
   `scripts/renamed-skills.txt`; for every old name present in the target skills dir,
   back it up using the existing backup mechanism and remove it. Print what was removed.
4. Write `tests/test-install-renames.sh` (plain bash, `set -euo pipefail`, no framework):
   create a temp skills dir pre-seeded with three old names (one renamed, one merged, one
   retired), run `install-all.sh --update` against it (check the script's flag for the
   target dir), and assert with `[ ... ] || { echo FAIL ...; exit 1; }` that old names are
   gone, backups exist, and new names exist. Add it as a step in `validate.yml`'s
   `structure` job: `run: bash tests/test-install-renames.sh`.
5. Fix `mcp-server/src/__tests__/registry.test.ts` and `.github/workflows/validate.yml`
   `registry-sync` so action skills are discovered with `clusters/*/*/SKILL.md`
   rather than the hard-coded `01-meta` and `07-devops`.
6. Regenerate: `bash scripts/gen-catalogue.sh`, `bash build.sh`, roadmap `--fix`.
7. `CHANGELOG.md` → `### Changed`: one line pointing to `scripts/renamed-skills.txt` for the full mapping.

## Done when
- [ ] `ls -d clusters/*/*/ | wc -l` prints `41`.
- [ ] For every old name: `grep -rnP '(?<![A-Za-z0-9-])<old>(?![A-Za-z0-9-]|\.sh\b|\.py\b)' . --exclude=CHANGELOG.md --exclude=REVIEW.md --exclude=renamed-skills.txt --exclude=discoverability-intents.md --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=tasks` prints nothing (loop over the list; on macOS use `ggrep -P` or a Python equivalent).
- [ ] `bash scripts/check-frontmatter.sh` exits 0 (names match new directories).
- [ ] `bash tests/test-install-renames.sh` passes.
- [ ] `cd mcp-server && npm ci && npm run build && npm test` passes.
- [ ] Every script still runs from its new directory (`bash <dir>/<script> --help` or equivalent for each `.sh` in a renamed directory).

## Return signal
Commit message: `feat!: rename skills to pathway prefixes` with footer
`BREAKING CHANGE: 32 skills renamed; see scripts/renamed-skills.txt. install-all.sh --update removes the old names.`
Then follow Shared conventions step 7. The master must review the full diff before integrating.

# Run-book: discoverability and consolidation programme

Generated: 2026-10-04 (from `REVIEW.md`, 2026-09-29)
Format: `task-decomposer` task files, extended with dispatch fields for a master agent.
Total tasks: 28 (RA-01 to RA-29; RA-21 dropped in the 2026-10-04 audit). RA-02 dispatches as four parallel sub-tasks.

This file is for two readers:

- **The master agent** (Opus): reads the whole file, dispatches sub-agents, verifies,
  integrates. See [Master agent protocol](#master-agent-protocol).
- **Executing sub-agents** (any tier): read [Shared conventions](#shared-conventions)
  and then only their own task file.

---

## Master agent protocol

### Before starting

1. This plan must be on `main` (merge the plan branch first). Worktree sub-agents branch
   from the current `HEAD`, so they will not see these files otherwise.
2. Read `REVIEW.md` (findings and the canonical rename map) once. Do not paste it into
   sub-agent prompts; the task files cite what each agent needs.
3. For each task file, read its header. `> Status: done` means skip.

### Dispatch order (waves)

A task may start when everything in its `Depends on` header is `done`. Tasks in the
same wave can run in parallel. Use `isolation: "worktree"` for every sub-agent.

| Wave | Tasks | Notes |
|---|---|---|
| 1 | RA-01, RA-05, RA-06, RA-07, RA-19, RA-20, RA-22, RA-24, RA-25, RA-26, RA-27 | All independent. RA-05 has an owner checkpoint. RA-07 returns two proposed global CLAUDE.md lines: keep them for RA-18 |
| 2 | RA-02 (×4: scopes A, B, C, D) | Needs RA-01 and RA-07. Afterwards the owner runs the RA-05 spot-check in a fresh session |
| 3 | RA-03, RA-04, RA-08, RA-09, RA-10, RA-11, RA-12, RA-13, RA-14 | |
| 4 | RA-15 | Needs every task in waves 1 to 3; Opus review gate. Owner reruns the RA-05 spot-check after |
| 5 | RA-16, RA-18, RA-29 | RA-18 is read-only; applying its edits needs owner approval |
| 6 | RA-17 | Needs RA-16's pathway tables |
| 7 | RA-28 | Needs RA-17; report only, owner decides on findings |
| Later | RA-23 | 60 days of transcripts on both machines; owner decides |

### Model selection

Each task header has `Model` (who executes) and `Fallback` (who retries on failure).
Pass the alias as the Agent tool's `model` parameter: `haiku`, `sonnet`, or `opus`.

Tier rationale, used when writing these briefs:

- **haiku:** every judgement call is pre-made in the brief; success is checkable by a
  command. Haiku briefs are deliberately long and prescriptive.
- **sonnet:** design is fixed but the agent must read code and write non-trivial
  scripts or prose.
- **opus:** merges where capability can be silently lost, and review of large diffs.

### Dispatch prompt template

Use this verbatim, filling the angle brackets. Do not add context from your own
conversation: if a sub-agent needs something, the task file is wrong; fix the file.

```
You are executing one task from a pre-written plan in the grimoire repo. You have no
other context and need none.

1. Read docs/tasks/discoverability/00-runbook.md, section "Shared conventions" only.
2. Read docs/tasks/discoverability/<task-file> and execute it exactly.
<Scope: <A|B|C|D> (RA-02 only)>

Do not push. Do not ask questions unless the task file tells you to stop and ask.
Finish with the task's return signal.
```

### Verification (do not skip)

A sub-agent's summary describes intent, not outcome. After each return signal:

1. In the sub-agent's worktree, run every command under the task's `Done when` yourself.
2. Read the diff (`git diff main...<branch> --stat`, then the full diff for anything
   under 20 files).
3. If the task's header says `Review: opus`, or a `haiku` diff touches more than 20
   files, review the full diff yourself before integrating.

### Escalation

| Situation | Action |
|---|---|
| `Done when` fails, first time | Re-dispatch to the `Fallback` model with the failing command output appended to the prompt |
| Fails on `sonnet` twice | Re-dispatch to `opus` |
| Fails on `opus` | Stop. Report to the owner with the failing output |
| Sub-agent says the brief is wrong or contradicts the repo | Stop that task, fix the task file (you, as master), re-dispatch |
| Task says "stop and ask the owner" | Surface the question to the owner; do not answer it yourself |

### Integration

Merge completed branches into `main` one at a time, in wave order (local merge; the owner
decides when to push). Expect textual conflicts in these shared files; resolve them by
keeping both sides' additions:

- `.github/workflows/validate.yml`: RA-03, RA-04, RA-15, RA-20, RA-24, RA-26
- `.github/workflows/devops-check.yml`: RA-12, RA-20, RA-26
- `mcp-server/registry.json`: RA-03, RA-07, RA-08 to RA-14
- `scripts/renamed-skills.txt`: every task that deletes or renames a skill
- `clusters/*/README.md`, skill READMEs, `PROJECT-WORKFLOWS.md`: RA-07, RA-08 to RA-14, RA-22, RA-24

If `bash scripts/gen-catalogue.sh --check` fails after a merge, run `bash scripts/gen-catalogue.sh`
and commit `SKILLS.md` (`docs: regenerate SKILLS.md`). After each merge, run the repo-wide checks in [Shared conventions](#shared-conventions)
step 6 on `main`. A red check on `main` blocks the next merge.

### Completion

The programme is done when all tasks are `done`, and:

- `bash scripts/check-frontmatter.sh` exits 0
- the owner's RA-05 spot-check passes in a fresh session after RA-15
- `ls -d clusters/*/*/ | wc -l` prints 41, matching the rename map in `REVIEW.md`

---

## Shared conventions

Every executing agent follows these. Your task file adds task-specific steps.

1. **Repo rules:** read `CLAUDE.md` at the repo root. In short: conventional commit
   prefixes (`feat:`, `fix:`, `docs:`, `ci:`, `chore:`), never edit `VERSION`, never create
   tags. Add a line to `CHANGELOG.md` under `## [Unreleased]` in the right subsection
   (`### Added`, `### Changed`, `### Removed`).
2. **Branch:** you are in a worktree. If you are on `main`, run
   `git checkout -b <type>/<task-id>-<slug>` first. A pre-commit hook blocks commits to `main`.
3. **Writing style:** British English. No em dashes anywhere (use commas, colons, or
   parentheses). No emojis in new prose.
4. **Skill directory rules** (CI enforces these):
   - Every `clusters/<cluster>/<skill>/` needs `SKILL.md` and `README.md`.
   - Do not add an `## Installation` section to skill READMEs (RA-24 removes them;
     installation is documented once in the root `README.md`).
   - Once RA-01 has landed, `SKILL.md` must start with frontmatter (see RA-01).
   - A `SKILL.md` containing `> **Type:** action` must have an entry in
     `mcp-server/registry.json` (`{"name", "skill"}` under `tools`; a `description` field is no longer needed once RA-03 lands), and every
     registry entry must point at an existing action `SKILL.md`.
   - Roadmap items live in each skill's `README.md` under `## Roadmap`. Never hand-edit
     between the `ROADMAP-COLLECT` markers in `ROADMAP.md`.
5. **Deleting or renaming a skill directory:** append one line per old name to
   `scripts/renamed-skills.txt` (create it if absent) in the form `old-name<TAB>new-name`,
   or `old-name<TAB>-` if retired. Then
   `grep -rnw '<old-name>' . --exclude=CHANGELOG.md --exclude=renamed-skills.txt --exclude=REVIEW.md --exclude=discoverability-intents.md --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=tasks`
   must return nothing. Fix every hit.
6. **Before committing, run and pass:**
   ```bash
   find . -name "*.sh" -not -path "./.git/*" -not -path "./clusters-*/*" -not -path "*/node_modules/*" -exec shellcheck {} +
   bash clusters/07-devops/ci-standards/check-roadmap-sync.sh . --fix
   ```
   If you changed anything under `mcp-server/` or `registry.json`:
   `cd mcp-server && npm ci && npm run build && npm test && cd ..`
   If `scripts/gen-catalogue.sh` exists: `bash scripts/gen-catalogue.sh` (regenerates `SKILLS.md`).
   If `scripts/check-frontmatter.sh` exists, run it on every `SKILL.md` you created or
   changed: `bash scripts/check-frontmatter.sh <path/to/SKILL.md> ...` (other skills may
   legitimately fail until RA-02 completes).
7. **Finish:** set your task file's header to `> Status: done`, in `ROADMAP.md`'s
   "Discoverability and consolidation programme" table change your row's `[ ]` to `[x]`, commit
   everything (`git add <specific files>`, never `git add -A`), then output exactly:
   `CHUNK COMPLETE: <task-id> <one-line summary>`.
8. **Stop and report instead of improvising** if: a file the brief names does not exist,
   a step would delete content the brief did not mention, or a check fails twice after
   your fix. Output `CHUNK BLOCKED: <task-id> <reason>`.
9. **Merge procedure** (RA-08 to RA-14, wherever a brief says "merge"):
   1. Before editing, write a **parity checklist** to `/tmp/<task-id>-parity.md`: every
      capability, flag, script, gotcha, and trigger phrase in each source skill's
      `SKILL.md` and `README.md`, one line each. Paste it into your commit body at the end,
      each line ticked or marked `DROPPED: <reason>`. Nothing may be dropped unless the
      brief says so.
   2. Create the new directory with `SKILL.md` (frontmatter `name` = new directory name,
      `description` = the exact text given in the brief, then the
      `> **Status:** / **Cluster:** / **Type:**` blockquote) and `README.md` (from
      `docs/skill-readme-template.md`, with `## Roadmap`, no `## Installation`).
   3. Move scripts with `git mv` so history follows them. Keep script file names unless the brief says otherwise.
   4. Carry every unchecked `## Roadmap` item from the sources into the new README, unchanged.
   5. `git rm -r` the source directories. Follow step 5 (renamed-skills.txt and grep clean-up).
   6. Registry: if the new skill is `Type: action`, it needs one entry (`name` = directory
      name, `skill` = path to its `SKILL.md`); remove the sources' entries.
   7. Update the cluster `README.md` entry (format in `CLAUDE.md`, "Cluster README entries").

## Release hold

Do not merge the standing `chore(release): ...` PR from release-please while this programme
is between RA-07 and RA-15. Both are breaking changes, so holding the release ships them as
one major version.

---

## Task index

| ID | File | Model | Fallback | Depends on |
|---|---|---|---|---|
| RA-01 | `ra-01-frontmatter-check.md` | haiku | sonnet | none |
| RA-02 | `ra-02-frontmatter-descriptions.md` | haiku (×4) | sonnet | RA-01, RA-07 |
| RA-03 | `ra-03-single-source-descriptions.md` | sonnet | opus | RA-02 |
| RA-04 | `ra-04-skills-catalogue.md` | haiku | sonnet | RA-02 |
| RA-05 | `ra-05-discoverability-test.md` | sonnet | opus | none (owner checkpoint) |
| RA-06 | `ra-06-usage-telemetry.md` | haiku | sonnet | none |
| RA-07 | `ra-07-remove-always-on.md` | haiku | sonnet | none |
| RA-08 | `ra-08-ci-local.md` | opus | none | RA-02 |
| RA-09 | `ra-09-py-lint.md` | sonnet | opus | RA-02 |
| RA-10 | `ra-10-deps-integrity.md` | sonnet | opus | RA-02 |
| RA-11 | `ra-11-tf-guardrails.md` | haiku | sonnet | RA-02 |
| RA-12 | `ra-12-ci-standards.md` | sonnet | opus | RA-02 |
| RA-13 | `ra-13-roadmap.md` | haiku | sonnet | RA-02 |
| RA-14 | `ra-14-orient.md` | haiku | sonnet | RA-02 |
| RA-15 | `ra-15-rename.md` | sonnet, review opus | opus | waves 1 to 3 |
| RA-16 | `ra-16-pathway-entries.md` | haiku | sonnet | RA-15 |
| RA-17 | `ra-17-workflows-doc.md` | haiku | sonnet | RA-15, RA-16 |
| RA-18 | `ra-18-cross-repo-report.md` | haiku | sonnet | RA-15, owner approval to apply |
| RA-19 | `ra-19-npm-audit-dependabot.md` | haiku | sonnet | none |
| RA-20 | `ra-20-pin-versions.md` | haiku | sonnet | none |
| RA-22 | `ra-22-delete-validation-items.md` | haiku | sonnet | none |
| RA-23 | `ra-23-usage-prune.md` | sonnet | none | RA-06, RA-15, 60 days; owner decides |
| RA-24 | `ra-24-readme-install-boilerplate.md` | haiku | sonnet | none |
| RA-25 | `ra-25-dead-scripts.md` | haiku | sonnet | none |
| RA-26 | `ra-26-version-sync-ci.md` | haiku | sonnet | none |
| RA-27 | `ra-27-installer-dedupe.md` | sonnet | opus | none |
| RA-28 | `ra-28-ponytail-followup.md` | sonnet | opus | RA-17 |
| RA-29 | `ra-29-mcp-explicit-script.md` | sonnet, review opus | opus | RA-15 |

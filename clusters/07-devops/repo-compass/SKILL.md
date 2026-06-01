# repo-compass

> **Status:** COMPLETE
> **Cluster:** 07-devops

## Description
Session-start orientation for any GitHub repository. Produces a "true state" summary
by combining GitHub platform state (PRs, issues, CI, releases) with README roadmap
state — and explicitly calling out any discrepancy between the two.

Invoke when: starting any session on a GitHub project, picking up where a previous
session left off, asked to "review the repo", "what's outstanding?", "triage this",
or "where are we on this project?".

**The problem this solves:** GitHub can report a clean dashboard (no open PRs, no
failing CI, no open issues) while README roadmap items are still unchecked — or vice
versa. A real state assessment reads both and flags the gap.

## Context needed
- Repository name/URL, or that the session is already in the repo directory
- Whether to check remote state only, or also diff README claims against the working tree

## What to do

### 1. Collect GitHub platform state

Run all of these before forming any opinion:

```bash
# Open PRs (including drafts)
gh pr list --state open

# Open issues
gh issue list --state open

# Recent CI runs (last 5)
gh run list --limit 5

# Tags and releases
gh release list --limit 10
git tag --sort=-creatordate | head -10

# Stale branches (merged but not deleted)
git branch -r --merged main | grep -v 'main\|HEAD'

# Verify latest release is marked Latest on GitHub
gh release view --json tagName,name,isLatest,publishedAt
```

### 2. Read ALL nested READMEs

Do not skip this step even if the project looks simple.

```bash
find . -name "README*" -not -path "*/.git/*" | sort | \
  xargs -I{} sh -c 'echo "=== {} ===" && cat {}'
```

Extract every unchecked roadmap item (`- [ ]`). List them with their source file.

### 3. Cross-check: claimed vs actual

For each unchecked `- [ ]` item in any README:

1. **Check whether it has actually been implemented** — search commits, grep the codebase,
   or look at recent PRs. The README may be stale; the code may already have the feature.
   ```bash
   git log --oneline --all | grep -i "<item keyword>"
   gh pr list --state merged --search "<item keyword>"
   ```

2. **If implemented but README not updated:** mark as "README lag" — this is the most
   common discrepancy. Note it explicitly.

3. **If genuinely not implemented:** mark as "outstanding" — confirmed work to do.

For each checked `- [x]` item that has a corresponding GitHub release or PR: verify
the release/PR actually exists and is merged. Spot-check the most recent 3–5 items.

### 4. Output a "true state" summary

Always produce this before doing any work. Format:

```
=== repo-compass: [repo-name] ===

GitHub platform state:
  Open PRs:      N
  Open issues:   N
  CI:            [all green / N failing — <run-id>]
  Latest release: vX.Y.Z — [Latest: yes/no]
  Stale branches: N

README roadmap state:
  Unchecked items found: N (across N files)
  Checked items found:   N

Cross-check findings:
  [x] <item> — already implemented (commit abc1234) — README lag
  [ ] <item> — confirmed outstanding (no commit, no PR)
  [ ] <item> — ambiguous (partial implementation in <file>)

True state:
  Outstanding work:  N confirmed items
  README sync needed: N items already done but not ticked
  Discrepancies:     [none / N items — details above]
```

If GitHub says "all clean" but README items are outstanding, say so clearly. Do not
report a project as tidy if the roadmap disagrees.

### 5. Recommend next action

After the summary:
- If outstanding items exist → propose delivery plan (or hand off to `project-delivery-workflow`)
- If only README lag → run `roadmap-sync` to tick completed items
- If genuinely tidy → confirm and stop; do not invent work

## Gotchas

- **"No open PRs" ≠ "nothing to do."** Always read the READMEs.
- **"All CI green" ≠ "last run tested your changes."** Check the run timestamp —
  a green badge from 3 months ago is not meaningful.
- **README roadmap items are not always accurate.** A `[ ]` item may already be
  implemented if `roadmap-sync` wasn't run after the last PR. Check the code.
- **Tags without releases are easy to miss.** `git tag` and `gh release list` are
  different. A tag that has no GitHub Release is a loose end — note it.
- **Draft PRs count.** `gh pr list` without `--state open` misses drafts.
  Always use `--state open` to include them.
- **The last session may have left the branch in a non-main state.** Always run
  `git status && git branch` before forming any view.

## Related skills

- `project-delivery-workflow` — use after repo-compass to execute the delivery
- `roadmap-sync` — standalone README tick-off after a PR merges
- `github-release-workflow` — for the tag → release mechanics in detail

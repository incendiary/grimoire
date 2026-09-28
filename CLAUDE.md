# grimoire — Working conventions

Project-level instructions for Claude Code sessions on this repo.
Read this at session start; merge with global `~/.claude/CLAUDE.md`.

---

## Repo overview

Private skill library (cloned locally; path varies per machine).
Nine clusters (`01-meta` through `09-odpc`); each skill directory contains `SKILL.md` + `README.md`
and zero or more scripts/templates.

**Multi-platform delivery:**
- Claude Code: `install-all.sh` copies skill folders to `~/.claude/skills/`
- VS Code (MCP): `mcp-server/` — TypeScript MCP server, reads `registry.json` at startup,
  exposes action skills as callable tools. Build with `cd mcp-server && npm ci && npm run build`.
- VS Code (prompts): `build.sh` generates `.prompt.md` files to `prompts/` (gitignored).
  Point VS Code at this path via `chat.promptFilesLocations` setting.

CI workflows:
- `validate.yml` — shellcheck, skill structure, registry sync
- `ci-mcp.yml` — TypeScript build, lint, test (path-filtered to `mcp-server/`)
- `secret-scan.yml` — gitleaks + TruffleHog
- `devops-check.yml` — version sync, clone-ref pinning, test baseline, roadmap sync
- `release-please.yml` — see "Releases" below

VERSION file: semver, managed entirely by `release-please` (see "Releases"). Feature PRs
never touch it — don't hand-edit `VERSION`, `CHANGELOG.md`, or create tags yourself.

---

## Delivery loop (one PR per logical batch)

```
git checkout -b feat/<name> main
# write files
chmod +x any .sh files
# tick README roadmap items
git add <specific files> && git commit -m "feat: ..."
git push -u origin feat/<name>
gh pr create ...
# wait for CI (see CI section below)
gh pr merge <N> --squash --delete-branch
```

No VERSION bump, no manual tag, no `gh release create` — that's all handled by
`release-please` once this lands on `main` (see "Releases" below). Just merge and move on.

---

## Releases (release-please)

`release-please-action` (`.github/workflows/release-please.yml`, triggered on every push
to `main`) watches commits since the last release. It maintains a standing
"chore(release): vX.Y.Z" PR — reopened/updated after every merge to `main` — that bumps
`VERSION` (via `release-please-config.json`'s `version-file`), determined from
[Conventional Commits](https://www.conventionalcommits.org/) prefixes on the squashed
commit messages since the last release:
- `feat:` → minor bump
- `fix:` → patch bump
- `feat!:` / `fix!:` / a `BREAKING CHANGE:` footer → major bump
- `docs:`, `chore:`, `ci:` → no bump (still land on `main`, just don't trigger a release)

**To cut a release:** merge that standing release PR (title `chore(release): vX.Y.Z`) like
any other PR. Merging it is what creates the git tag and the GitHub Release, in the same
workflow run — nothing further to do. Don't accumulate unreleased work indefinitely; merge
the release PR whenever you're ready to ship what's queued.

**`CHANGELOG.md` stays hand-written** (`skip-changelog: true` in
`release-please-config.json`) — release-please does not touch it. Add your own entry to
`CHANGELOG.md` in the same PR as the change, same as before; release-please only owns
`VERSION` + the tag + the GitHub Release.

**Auth:** uses the `RELEASE_PLEASE_TOKEN` repo secret (a fine-grained PAT), not the default
`GITHUB_TOKEN` — required so the release PR actually triggers `pull_request`-scoped CI
(`validate.yml`, `devops-check.yml`); GitHub's default token can't cascade-trigger other
workflows. If that secret expires or is revoked, the release PR will exist but sit with no
CI checks ever reporting, which will block it under branch protection.

`devops-check.yml`'s version-sync check is deliberately **not** in `main`'s required status
checks, even though release PRs should now trip it only on the release-please PR itself
(ordinary feature PRs never touch `VERSION`). Requiring it would block merging that exact
PR. It still runs and reports — expect it red on the release PR, green everywhere else.

---

## CI handling

### Normal path
Poll with a background task:
```bash
until gh run list --repo incendiary/grimoire --branch <branch> --limit 1 \
  --json status --jq '.[0].status' | grep -q "^completed$"; do sleep 8; done \
  && gh run list --repo incendiary/grimoire --branch <branch> --limit 1 \
  --json status,conclusion --jq '.[0]'
```

### When pull_request events don't fire (GitHub Actions delay)
The validate workflow has `workflow_dispatch`. Trigger manually:
```bash
gh workflow run validate.yml --repo incendiary/grimoire --ref <branch>
```
Then poll the returned run URL or run ID.

### When CI fails
Read the full log:
```bash
gh run view <run-id> --repo incendiary/grimoire --log-failed
```

---

## Common ShellCheck issues and fixes

| Code  | Trigger | Fix |
|-------|---------|-----|
| SC2015 | `$FLAG && cmd || true` | `if $FLAG; then cmd; fi` |
| SC2016 | `sed 's/.../\\&/g'` — `\&` is a sed backreference | Add `# shellcheck disable=SC2016` comment on the line |
| SC2034 | Variable set but never used | Remove the variable, or use it |
| SC2086 | Unquoted variable used as word list | Use a bash array: `read -ra ARGS <<< "$VAR"` then `"${ARGS[@]}"` |

Always run CI before merging — shellcheck is stricter than local review.

---

## Branch hygiene

- **Never rebase a feature branch onto main** after it has been pushed and a PR is open.
  Squash merges from other PRs will cause rebase to silently drop commits whose patches
  appear "already applied". Use `git merge main` instead.
- If a local branch is accidentally rebased and points to main's HEAD, recover with:
  ```bash
  git checkout -b feat/<name>-recovery origin/feat/<name>
  ```
  The remote still has the correct history.

---

## README sync when branching from an older base

When a new feature branch is cut before a recent PR merges to main, the branch won't
have that PR's changes to shared files (e.g. `clusters/07-devops/README.md`).

Before opening a PR, check:
```bash
git diff origin/main HEAD -- <shared-file>
```

If the file has a regression (content in main that's missing from the branch), add a
fixup commit to the branch before the PR. Common culprit:
- `clusters/07-devops/README.md` — new skill entries added by intervening PRs

---

## Commit message conventions

- `feat:` — new skill file or script
- `fix:` — bug fix in an existing script (including ShellCheck fixes)
- `docs:` — README updates, roadmap ticks
- `chore:` — merge commits, housekeeping (never hand-bump VERSION — see "Releases")
- `ci:` — changes to `.github/workflows/`

Always append:
```
Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

---

## PR title conventions

```
feat: Cat 5 D<N> — <short description>
feat: <skill-name> skill
fix: <short description>
docs: <short description>
ci: <short description>
```

---

## Cluster README entries

When a new skill is added to a cluster, add an entry to `clusters/<cluster>/README.md`.
Format:
```markdown
### [<skill-dir-name>](<skill-dir-name>/) ✅ complete
One-sentence description of what the skill does and when.
→ [Full documentation](<skill-dir-name>/README.md)
```

If branching before a recent PR's cluster README update lands on main, the entry may
be missing — add it explicitly in a fixup commit.

---

## Stale branch cleanup

After every merge, verify:
```bash
git branch -r --merged main | grep -v 'HEAD\|main'
```
GitHub deletes branches automatically on `--delete-branch` squash merge, but
occasionally leaves stale tracking refs. Safe to ignore; `git remote prune origin`
clears them if needed.

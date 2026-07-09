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

VERSION file: semver. Patch bump per PR, minor bump when a cluster's delivery batch completes.

---

## Delivery loop (one PR per logical batch)

```
git checkout -b feat/<name> main
# write files
chmod +x any .sh files
# tick README roadmap items
# bump VERSION (patch or minor)
git add <specific files> && git commit -m "feat: ..."
git push -u origin feat/<name>
gh pr create ...
# wait for CI (see CI section below)
gh pr merge <N> --squash --delete-branch
git checkout main && git pull origin main
git tag vX.Y.Z && git push origin vX.Y.Z
# .github/workflows/release-on-tag.yml creates the GitHub Release automatically —
# do NOT also run `gh release create` here, it will 422 on the now-existing tag.
```

**Never skip the tag step.** VERSION file, git tag, and GitHub Release must all agree — the
tag push is what triggers `release-on-tag.yml` to create the release, so pushing the tag
*is* the release step. If the workflow run fails to appear, check `gh run list --workflow
release-on-tag.yml` before creating the release by hand.

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

## VERSION conflict resolution (squash merges)

Feature branches that diverge from main often conflict on `VERSION`.
Resolution: **always keep the branch's version** (it owns the bump).

```bash
git merge origin/main --no-commit --no-ff
# resolve VERSION conflict: keep branch value
printf 'X.Y.Z\n' > VERSION
git add VERSION
git commit -m "chore: merge main and resolve VERSION conflict"
git push origin <branch>
```

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
fixup commit to the branch before the PR. Common culprits:
- `clusters/07-devops/README.md` — new skill entries added by intervening PRs
- `VERSION` — always conflicts; resolve as described above

---

## Commit message conventions

- `feat:` — new skill file or script
- `fix:` — bug fix in an existing script (including ShellCheck fixes)
- `docs:` — README updates, roadmap ticks
- `chore:` — VERSION bump, merge commits, housekeeping
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

# Task RA-17: Delete PROJECT-WORKFLOWS.md, keep a short table in README

> Status: pending
> Parent: discoverability and consolidation programme
> Model: haiku
> Fallback: sonnet
> Depends on: RA-15, RA-16
> Effort: XS
> Touches: `PROJECT-WORKFLOWS.md` (deleted), `README.md`, any file linking to it, `CHANGELOG.md`

## Objective
Remove the hand-kept 329-line workflow guide. The entry skills' pathway tables (RA-16) and
the generated `SKILLS.md` (RA-04) now carry that information.

## Steps
1. `git rm PROJECT-WORKFLOWS.md`.
2. In `README.md`, replace the whole `## Project Workflows` section body (keep the heading)
   with:
   ```
   Skills are named by pathway: the prefix says when you need it. Type a prefix (for
   example `/release`) in Claude Code, or `#release` in Copilot Chat, to see the pathway.
   The entry skills `orient`, `plan`, `release` and `publish` list their steps in order.
   Full list: [SKILLS.md](SKILLS.md).

   | Project type | Pathways, in order |
   |---|---|
   | Python tool | `orient`, `plan`, `py-lint`, `ci-python`, `release` |
   | .NET tool | `orient`, `plan`, `ci-dotnet`, `release` |
   | Node service | `orient`, `plan`, `deps-integrity`, `release`, `release-docker-ghcr` |
   | Terraform | `orient`, `plan`, `tf-guardrails`, `publish-secret-scan`, `release` |
   | Security tool | `orient`, `plan-spec`, `publish-secret-scan`, `publish-readme`, `release` |
   | Going public | `publish` (follow its pathway table) |
   ```
3. Confirm every skill named in the table exists (`ls -d clusters/*/<name>`). If one does
   not, stop with `CHUNK BLOCKED: RA-17 missing <name>`.
4. Remove links to the deleted file:
   `grep -rn 'PROJECT-WORKFLOWS' . --exclude=CHANGELOG.md --exclude=REVIEW.md --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=tasks`
   and delete or repoint each hit to `README.md#project-workflows`.
5. `CHANGELOG.md` → `### Removed`: `- PROJECT-WORKFLOWS.md (replaced by pathway tables and a README summary).`

## Done when
- [ ] `PROJECT-WORKFLOWS.md` does not exist and step 4 grep prints nothing.
- [ ] `grep -c '—' README.md` does not increase compared with `main`.

## Return signal
Commit message: `docs: replace PROJECT-WORKFLOWS.md with a README summary`
Then follow Shared conventions step 7.

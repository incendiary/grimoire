# Task RA-21: Tests for destructive and install scripts

> Status: pending
> Parent: discoverability and consolidation programme
> Model: sonnet
> Fallback: opus
> Depends on: none
> Effort: M
> Touches: `tests/` (new), `.github/workflows/validate.yml`, `CHANGELOG.md`

## Objective
bats tests cover the history-wipe release scripts and the install/uninstall scripts, so
RA-15 (rename) can prove old skills are cleaned up and future edits cannot silently break
release recreation.

## Background
- `clusters/07-devops/github-history-wipe/capture-releases.sh` and `recreate-releases.sh`
  sit next to a force-push workflow. A regression is found only on a real repo, after the
  history is gone.
- `install-all.sh` / `uninstall-all.sh` will gain rename handling in RA-15; tests written
  now give RA-15 a harness. Both accept a target skills directory (check their flags).
- Do not install bats system-wide (owner's rule). Run it via
  `npx --yes bats@1.11.0` (project-local, cached by npm). In CI use the same command.
- `gh` must be stubbed: put a fake `gh` script first on `PATH` that records its arguments
  to a file and prints canned JSON.

## Context files
- The four scripts above (read fully: test their actual flags and outputs).
- `.github/workflows/validate.yml` for job style.

## Steps
1. `tests/helpers.bash`: temp-dir setup/teardown, a `stub_gh` function that writes a fake
   `gh` to `$BATS_TEST_TMPDIR/bin` and prepends it to `PATH`.
2. `tests/history-wipe.bats`: at least:
   - capture writes the expected release data for two stubbed releases;
   - recreate issues one `gh release create` per captured release with the right tag and title;
   - both fail clearly with no `gh` auth (stub returns non-zero).
   Use a local bare repo (`git init --bare`) as any remote; never touch the network.
3. `tests/install.bats`: at least:
   - install into an empty temp skills dir creates one directory per `clusters/*/*/`;
   - re-run without flags skips existing;
   - `--update` creates a backup and overwrites;
   - uninstall removes only grimoire-managed directories (create an unrelated dir first and assert it survives).
4. Add a `tests` job to `validate.yml` running `npx --yes bats@1.11.0 tests/` on ubuntu-latest.
5. `CHANGELOG.md` → `### Added`: `- bats tests for history-wipe release scripts and install/uninstall.`

## Constraints
- Tests must not write outside temp dirs. Never point a test at the real `~/.claude`.
- Do not change the scripts under test, unless a test exposes a real bug; then fix it in
  the same task and say so in the return message.

## Done when
- [ ] `npx --yes bats@1.11.0 tests/` passes locally.
- [ ] Deliberately breaking `recreate-releases.sh` (e.g. comment out the create call) makes a test fail (revert afterwards).
- [ ] shellcheck clean on any `.sh` added.

## Return signal
Commit message: `test: bats coverage for history-wipe and install scripts`
Then follow Shared conventions step 7.

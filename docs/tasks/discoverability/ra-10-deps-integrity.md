# Task RA-10: Merge lockfile and provenance skills into `deps-integrity`

> Status: pending
> Parent: discoverability and consolidation programme
> Model: sonnet
> Fallback: opus
> Depends on: RA-02, RA-22
> Effort: M
> Touches: `clusters/07-devops/npm-lockfile-integrity/`, `python-lockfile-integrity/`, `npm-provenance-attestation/` (deleted), `clusters/07-devops/deps-integrity/` (new), `mcp-server/registry.json`, possibly `mcp-server/src/executor.ts`, `clusters/07-devops/README.md`, references, `scripts/renamed-skills.txt`, `CHANGELOG.md`

## Objective
One skill, `deps-integrity`, covers Node lockfile integrity, Python lockfile integrity,
and npm provenance attestation, with all three scripts intact.

## Background
- Sources: `npm-lockfile-integrity` (`check-lockfile-integrity.sh`, registry entry),
  `python-lockfile-integrity` (`check-python-lockfile-integrity.sh`, registry entry;
  covers pip-tools, poetry, pipenv, uv), `npm-provenance-attestation`
  (`check-provenance.sh`, instructional, no registry entry).
- Same control family (dependency identity by content hash or signed provenance), different
  ecosystems. Merging reduces three names to one without losing scripts.
- MCP: today one registry entry maps to one `SKILL.md`. Find out how
  `mcp-server/src/executor.ts` picks which script to run for a tool. Then choose:
  (a) three registry entries `deps-integrity-npm`, `deps-integrity-python`,
  `deps-integrity-provenance` pointing at the same `SKILL.md`, if the executor can select a
  script per entry; or (b) one entry `deps-integrity` with an `ecosystem` argument.
  Prefer whichever needs no executor change. Record the choice in the commit body.

## New frontmatter description (use verbatim)
`Checks dependency supply-chain integrity: npm and Python lockfile hashes (pip-tools, poetry, pipenv, uv) and npm Sigstore provenance attestations. Use when setting up CI for a Node or Python project, auditing dependencies after a supply-chain alert, or vetting a new package before adding it.`

## Context files
- All three source skills, in full. `mcp-server/src/executor.ts`, `loader.ts`, `registry.json`, tests.
- `00-runbook.md` Shared conventions step 9.

## Steps
1. Merge procedure (step 9). New directory `clusters/07-devops/deps-integrity/`, `Type: action`.
2. `SKILL.md` sections: Node lockfile, Python lockfile, npm provenance, then a short
   "Which check when" table.
3. Registry per the choice above; add or update a test in `mcp-server/src/__tests__/` covering it.

## Done when
- [ ] Parity checklist complete in the commit body.
- [ ] Each of the three scripts runs from its new path against a fixture (a temp dir with a minimal `package-lock.json` / `requirements.txt` with hashes), with the same output as from the old path (`git show main:<old path>` to compare).
- [ ] MCP tests pass and cover the chosen registry shape.
- [ ] Shared conventions steps 5 and 6 pass.

## Return signal
Commit message: `feat!: merge lockfile and provenance skills into deps-integrity` with footer
`BREAKING CHANGE: npm-lockfile-integrity, python-lockfile-integrity and npm-provenance-attestation are replaced by deps-integrity.`
Then follow Shared conventions step 7.

# Task RA-20: Align TruffleHog versions and SHA-pin GitHub Actions

> Status: done
> Parent: discoverability and consolidation programme
> Model: haiku
> Fallback: sonnet
> Depends on: none (run after open Dependabot PRs for actions are merged, so you pin current versions)
> Effort: XS
> Touches: `.pre-commit-config.yaml`, `.github/workflows/*.yml`, `CHANGELOG.md`

## Objective
Local TruffleHog matches CI's version, and every `uses:` in workflows is pinned to a full
commit SHA with the tag as a trailing comment.

## Background
- `.pre-commit-config.yaml` pins a TruffleHog `rev:`; `secret-scan.yml` uses
  `trufflesecurity/trufflehog@<version>`. They should match: use the CI version. (At
  writing: pre-commit `v3.95.2`, CI `v3.97.6`, but Dependabot may have bumped CI since.
  Read both files; do not trust these numbers.)
- Workflows use tag pins (a tag can be moved to malicious code; a SHA cannot). The
  `uses:` values at writing were (re-read the files; Dependabot may have bumped them):
  - `actions/checkout@v7`
  - `actions/setup-node@v7`
  - `gitleaks/gitleaks-action@v3`
  - `googleapis/release-please-action@v4`
  - `trufflesecurity/trufflehog@v3.97.6`
- Dependabot (already configured in `.github/dependabot.yml`) keeps SHA pins updated when the `# <tag>` comment is present.

## Steps
1. In `.pre-commit-config.yaml`, set the TruffleHog `rev:` to the version `secret-scan.yml` uses.
2. For each action above, resolve the tag to a commit SHA:
   ```bash
   resolve() {  # usage: resolve owner/repo tag
     local ref; ref=$(gh api "repos/$1/git/ref/tags/$2" --jq '.object.type + " " + .object.sha')
     if [ "${ref%% *}" = "tag" ]; then gh api "repos/$1/git/tags/${ref#* }" --jq .object.sha; else echo "${ref#* }"; fi
   }
   resolve actions/checkout v7
   ```
   Note: `v7`, `v3`, `v4` may be moving major tags; resolving them is correct (pins today's commit).
   If `gh api` fails (not authenticated), stop with `CHUNK BLOCKED: RA-20 gh not authenticated`.
3. Replace each occurrence across `.github/workflows/*.yml`:
   `uses: actions/checkout@v7` → `uses: actions/checkout@<40-char-sha> # v7`
   (same pattern for every action; keep indentation and the leading `- ` where present).
4. `CHANGELOG.md` → `### Security`: `- GitHub Actions pinned to commit SHAs; TruffleHog pre-commit aligned with CI (<version>).`

## Done when
- [ ] `grep -hn 'uses:' .github/workflows/*.yml | grep -vE '@[0-9a-f]{40} # '` prints nothing.
- [ ] The TruffleHog `rev:` in `.pre-commit-config.yaml` equals the tag in the `# <tag>` comment of the TruffleHog `uses:` line.
- [ ] Every SHA you wrote appears in your step 2 output (no typos): compare by eye or script.
- [ ] Each workflow file still parses: `python3 -c "import yaml,glob;[yaml.safe_load(open(f)) for f in glob.glob('.github/workflows/*.yml')]"`.

## Return signal
Commit message: `ci: pin actions to SHAs and align trufflehog version`
Then follow Shared conventions step 7.

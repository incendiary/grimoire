# repo-security-bootstrap

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Source:** PycharmProjects session (pattern detected 16x)

## Description
Deploys standard secret-scanning infrastructure — a custom `.gitleaks.toml` and a
GitHub Actions workflow — to one or more repos in bulk.

Invoke when: setting up a new repo for publication, or applying security scanning
infrastructure across a batch of repos.

## Context needed
- Custom gitleaks rules for corporate/client references (e.g. engagement-specific hostnames)
- Whether repos are archived (requires unarchive/re-archive dance)
- List of target repos

## What to do

### 1. Write `.gitleaks.toml`
Always include a `[rules]` section for corporate references. Base template:

```toml
title = "gitleaks config"

[extend]
useDefault = true

[[rules]]
id = "corporate-refs"
description = "Internal corporate or client references"
regex = '''(?i)(<CORP_NAME>|<internal-domain>|<engagement-hostname>)'''
tags = ["corporate", "sensitive"]

[allowlist]
paths = [
  '''.gitleaks\.toml''',
  '''\.git/''',
]
```

The canonical template lives at `gitleaks-config-template.toml` in this skill directory.
Copy it to `.gitleaks.toml` in the target project and fill in the `<CORP_NAME>`,
`<DOMAIN_SUFFIX>`, and `<ENGAGEMENT_HOSTNAME>` placeholders with real values.
Never commit real values to a public repo — use placeholders or remove the rule entirely.

### 2. Write `.github/workflows/secret-scan.yml`
```yaml
name: Secret scan
on: [push, pull_request]
jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 3. Commit and push to each repo
```bash
for repo in <repo-list>; do
  cd /tmp && git clone git@github.com:incendiary/${repo}.git && cd ${repo}
  mkdir -p .github/workflows
  cp /path/to/.gitleaks.toml .
  cp /path/to/secret-scan.yml .github/workflows/
  git add .gitleaks.toml .github/workflows/secret-scan.yml
  git commit -m "Add secret scanning infrastructure"
  git push
  cd /tmp && rm -rf ${repo}
done
```

## Gotchas
- Archived repos need to be unarchived before pushing; re-archive afterwards
- The corporate-refs rule regex must not contain real values when committed — parameterise it
- `useDefault = true` extends gitleaks' built-in ruleset; check it doesn't over-fire on test fixtures

## Suggested scripts
- `bootstrap-security.sh` — accepts a repo list, handles unarchive/re-archive, deploys both files, commits, pushes
- `gitleaks-config-template.toml` — parameterised template for `.gitleaks.toml`; copy and fill in `<CORP_NAME>`, `<DOMAIN_SUFFIX>`, `<ENGAGEMENT_HOSTNAME>`

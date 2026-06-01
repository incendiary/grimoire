# Skill Vetting Checklist

Use this template to record a vetting decision before installing a third-party Claude Code skill.
Keep the completed file as an audit record.

---

## Skill details

| Field | Value |
|-------|-------|
| **Skill name** | |
| **Source URL** | |
| **Date vetted** | |
| **Vetted by** | |
| **Has scripts?** | Yes / No |

---

## Step 1 — Repository health

- [ ] Star count: _______ (flag if < 10)
- [ ] Contributors: _______ (flag if single contributor with no outside review)
- [ ] Last commit: _______ (flag if > 6 months ago)
- [ ] Repository was created recently for this purpose (not an established project)

**Notes:**

---

## Step 2 — Script analysis

*(Skip if skill has no scripts)*

- [ ] Read every `.sh`, `.py`, `.js` file in the skill directory
- [ ] No outbound network calls (`curl`, `requests`, `urllib`, `socket`, subprocess with URLs)
- [ ] No file reads outside the skill directory (e.g. `~/.ssh/`, `~/.aws/`)
- [ ] No access to credential env vars (`ANTHROPIC_API_KEY`, `AWS_*`, `GITHUB_TOKEN`)
- [ ] No dynamic execution (`eval()`, `exec()`, `compile()`, `subprocess(shell=True)`)
- [ ] No runtime PyPI installs (`pip install` in scripts not declared in `requirements.txt`)
- [ ] No non-standard imports without declared dependencies
- [ ] PyPI package reputation checked for any non-stdlib imports (see Step 2a below)

### Step 2a — PyPI package reputation (for each non-stdlib import)

| Package | Version pinned? | PyPI download count | Notes |
|---------|----------------|---------------------|-------|
| | | | |

Flags: package < 1,000 downloads/month, no version pin, package name typosquats a popular library.

**Notes:**

---

## Step 3 — SKILL.md prompt-injection review

- [ ] No instructions to ignore CLAUDE.md, system prompts, or project rules
- [ ] No claims of elevated permissions ("unrestricted", "ignore previous instructions")
- [ ] No triggers that fire without explicit user invocation
- [ ] No requests to write files outside the project directory or to `~/.claude/`
- [ ] No instructions to chain to external services or call `claude -p` with attacker-controlled prompts
- [ ] Skill description accurately matches what the code does

**Notes:**

---

## Step 4 — Verdict

- [ ] **PASS** — install is safe. Minor caveats (if any):
- [ ] **FLAG** — install with conditions. Conditions:
  1.
  2.
- [ ] **REJECT** — do not install. Required changes before reconsideration:
  1.
  2.

**Final decision:**

**Signed:**                          **Date:**

---

## Integration note

Before promoting a proposed stub from `~/.claude/proposed-skills/` to `~/.claude/skills/`,
run `/skill-vetter` on the stub. Stubs are auto-generated and have not been reviewed for
prompt-injection or unsafe patterns.

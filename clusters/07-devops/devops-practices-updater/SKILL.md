# devops-practices-updater

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** instructional

## Description
Evolves the `devops-practices` skill when a session reveals a new repeating practice.
Reads the current skill, identifies the correct category, appends the new rule, and
updates enforcement scripts if the practice is automatable.

Invoke when: a session reveals a pattern worth standardising; user says "add this to
my devops practices"; post-session review identifies a new convention; an existing
practice needs refinement.

## Context needed
- The new practice or rule to add (what it is, why it matters)
- Which category it belongs to (versioning, PR discipline, testing, clone-ref, continuous review) — or propose a new category

## Procedure

### Step 1: Read current state

```bash
cat clusters/07-devops/devops-practices/SKILL.md
```

Identify:
- Which category the new practice fits (or if a new category is needed)
- Whether it overlaps with an existing rule (update vs. add)
- Whether it's enforceable via script

### Step 2: Classify the practice

| Type | Action |
|------|--------|
| New rule in existing category | Add row to that category's table |
| Refinement of existing rule | Update the existing row |
| New category entirely | Add new H3 section following the existing pattern |
| Enforceable via script | Also update/create check script |
| Routes to existing skill | Add to routing table |

### Step 3: Update SKILL.md

Add the rule to the correct category table. Follow the existing format:

```markdown
| Rule name | Detail explaining the rule |
```

If the practice routes to an existing grimoire skill, also add it to the
"Routing to existing skills" table.

### Step 4: Update enforcement (if applicable)

If the practice can be checked automatically:

1. Determine which check script it belongs to (or create a new one)
2. Add the check logic as a new function/section
3. Ensure the script still passes `shellcheck`
4. Test the script against the current repo

### Step 5: Update README.md

Add the new practice to the README's practice categories list if it changes
the high-level description.

### Step 6: Commit

```bash
git add clusters/07-devops/devops-practices/
git commit -m "feat(devops-practices): add <practice-name> rule

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Examples

### Adding a new rule to existing category

User discovers: "I keep forgetting to update CHANGELOG when cutting a release."

→ Category: **Versioning**
→ New rule: `CHANGELOG updated before release tag`
→ Enforceable: Could grep for CHANGELOG modification in release commits (complex, defer)
→ Action: Add row to versioning table, note as "rules only" enforcement

### Adding a new enforceable check

User discovers: "GitHub Actions should pin to SHA, not just tag."

→ Category: **Clone-ref pinning**
→ New rule: `GitHub Actions pinned to commit SHA`
→ Enforceable: Yes — check `uses:` lines in workflow files for SHA format
→ Action: Add row to table, update `check-clone-refs.sh` to check workflow files

### Adding a new category

User discovers a pattern around "documentation freshness" that doesn't fit existing categories.

→ New category: **Documentation hygiene**
→ Add H3 section to SKILL.md following existing pattern
→ Add rules, enforcement notes, and related skills
→ Update README.md category list

---

## Guardrails

- Never remove existing rules — only add or refine
- Each addition must include a "why" (what failure mode it prevents)
- Enforcement scripts must pass shellcheck after modification
- If unsure about category, ask before adding
- Keep rules concise — one sentence per rule, detail in the "Detail" column

## Roadmap

- [ ] Add automatic detection: chain with `session-skill-extractor` to route devops patterns here
- [ ] Add `--dry-run` mode: show what would change without writing
- [ ] Add practice versioning: track when each rule was added and by whom

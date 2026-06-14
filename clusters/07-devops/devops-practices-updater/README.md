# devops-practices-updater

> Self-update mechanism for the devops-practices skill.

## Purpose

Provides a structured procedure for evolving `devops-practices` when new conventions
are discovered during sessions. Ensures practices grow organically without becoming
disorganised.

## When to invoke

- A session reveals a repeating devops pattern worth standardising
- User says "add this to my devops practices" or "this should be a standard"
- Post-session review identifies a new convention
- An existing practice needs refinement or clarification
- A new enforcement check becomes possible

## What it does

1. Reads the current `devops-practices/SKILL.md`
2. Classifies the new practice (existing category vs. new category, enforceable vs. rules-only)
3. Appends the rule in the correct format
4. Updates enforcement scripts if automatable
5. Commits as a standalone change

## Examples

| Discovery | Category | Enforceable? |
|-----------|----------|-------------|
| "Always update CHANGELOG before release" | Versioning | No (rules only) |
| "GitHub Actions must pin to SHA" | Clone-ref pinning | Yes (check-clone-refs.sh) |
| "Never merge your own PR without review" | PR discipline | No (rules only) |
| "README must have install instructions" | New: Documentation hygiene | Partially (grep for ## Install) |

## Related skills

- `devops-practices` — the skill this updates
- `session-skill-extractor` (01-meta) — discovers patterns; could route devops ones here
- `karpathy-environment` (01-meta) — captures workspace-level patterns (broader scope)

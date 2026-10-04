# Task RA-11: Merge three Terraform skills into `tf-guardrails`

> Status: pending
> Parent: discoverability and consolidation programme
> Model: haiku
> Fallback: sonnet
> Depends on: RA-02, RA-22
> Effort: S
> Touches: `clusters/07-devops/terraform-aws-syntax/`, `terraform-checkov-skips/`, `terraform-version-compat/` (deleted), `clusters/07-devops/tf-guardrails/` (new), `clusters/07-devops/README.md`, `PROJECT-WORKFLOWS.md`, `scripts/renamed-skills.txt`, `CHANGELOG.md`

## Objective
One skill, `tf-guardrails`, contains all content of the three Terraform skills, with no
content lost.

## Background
- The three skills are small, instructional (no MCP registry entries), and always relevant together when writing Terraform.
- Most reference content lives in the **READMEs**, not the SKILL.md files:
  - `terraform-aws-syntax/README.md`: "Block vs attribute quick reference", "Provider version matrix".
  - `terraform-checkov-skips/README.md`: "Skip placement rule", "Common skip patterns and justifications" (S3, EC2, IAM, Security Groups, RDS, Lambda, CloudTrail).
  - `terraform-version-compat/README.md`: "Invocation", "Workflow", "What it won't do".
- Scripts: `terraform-checkov-skips/validate-checkov-skip-placement.sh`,
  `terraform-version-compat/check-provider-compat.sh`. `terraform-aws-syntax` has none.
- This is a concatenation task. Do not rewrite or summarise content.

## New frontmatter description (use verbatim)
`Prevents common Terraform failures: provider version conflicts when adding or upgrading modules, AWS provider block-versus-attribute syntax errors, and checkov skip comments placed where checkov ignores them. Use when writing or reviewing Terraform, when 'terraform init' or 'validate' fails on constraints, or when checkov skips are not taking effect.`

## Steps
1. Create the directory and move the scripts:
   ```bash
   mkdir -p clusters/07-devops/tf-guardrails
   git mv clusters/07-devops/terraform-checkov-skips/validate-checkov-skip-placement.sh clusters/07-devops/tf-guardrails/
   git mv clusters/07-devops/terraform-version-compat/check-provider-compat.sh clusters/07-devops/tf-guardrails/
   ```
2. Write `clusters/07-devops/tf-guardrails/SKILL.md` in exactly this structure:
   ```
   ---
   name: tf-guardrails
   description: "<description above, verbatim>"
   ---
   # tf-guardrails

   > **Status:** COMPLETE
   > **Cluster:** 07-devops
   > **Type:** instructional

   ## Description
   <the description sentence, then one paragraph per source skill's Description text>

   ## 1. Provider version compatibility
   <terraform-version-compat SKILL.md: "Context needed", "What to do", "Gotchas", "Suggested scripts" sections, each demoted one heading level (## → ###)>

   ## 2. AWS provider syntax
   <terraform-aws-syntax SKILL.md: same sections, demoted>

   ## 3. Checkov skip placement
   <terraform-checkov-skips SKILL.md: same sections, demoted>
   ```
   In the "Suggested scripts" text, update script paths to `tf-guardrails/<script>`.
3. Write `clusters/07-devops/tf-guardrails/README.md`:
   - Title, one-line summary, `## What this skill does` (three bullets, one per area).
   - `## When to use it` (merge the three lists, dedupe identical lines).
   - `## Installation`: copy the section from `terraform-version-compat/README.md` and
     replace the old skill name with `tf-guardrails` throughout it.
   - Then, unchanged, these sections in this order: "Invocation", "Workflow", "What it won't do"
     (from version-compat); "Block vs attribute quick reference", "Provider version matrix"
     (from aws-syntax); "Skip placement rule", "Common skip patterns and justifications"
     with all its subsections (from checkov-skips).
   - `## Roadmap`: every line from the three `## Roadmap` sections (checked and unchecked), prefixed with the area in bold, e.g. `- [ ] **AWS syntax:** Add resource type gotchas as they are encountered`.
   - `## Validation`: likewise from the three `## Validation` sections (if any).
4. Content check before deleting anything. For each of the 6 source files, every
   non-blank line outside `## Installation` must appear in the new files:
   ```bash
   for f in clusters/07-devops/terraform-*/{SKILL,README}.md; do
     awk '/^## Installation/{s=1;next} /^## /{s=0} !s' "$f" | grep -v '^\s*$' | grep -v '^#' | while IFS= read -r line; do
       grep -qF -- "$line" clusters/07-devops/tf-guardrails/SKILL.md clusters/07-devops/tf-guardrails/README.md || echo "MISSING in $f: $line"
     done
   done
   ```
   Lines that mention an old skill name, or the old `> **Cluster/Status/Type**` header, may
   be missing; fix every other `MISSING` line before continuing.
5. Delete the sources and record the rename:
   ```bash
   git rm -r clusters/07-devops/terraform-aws-syntax clusters/07-devops/terraform-checkov-skips clusters/07-devops/terraform-version-compat
   printf 'terraform-aws-syntax\ttf-guardrails\nterraform-checkov-skips\ttf-guardrails\nterraform-version-compat\ttf-guardrails\n' >> scripts/renamed-skills.txt
   ```
6. Find and fix every reference:
   ```bash
   grep -rnwE 'terraform-aws-syntax|terraform-checkov-skips|terraform-version-compat' . --exclude=CHANGELOG.md --exclude=renamed-skills.txt --exclude=REVIEW.md --exclude=discoverability-intents.tsv --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=tasks
   ```
   - In `clusters/07-devops/README.md`: replace the three skill entries with one entry in the
     format from `CLAUDE.md` "Cluster README entries":
     ```
     ### [tf-guardrails](tf-guardrails/) ✅ complete
     Terraform guardrails: provider version compatibility, AWS provider syntax, and checkov skip placement.
     → [Full documentation](tf-guardrails/README.md)
     ```
   - Anywhere else (e.g. `PROJECT-WORKFLOWS.md`): replace each old name with `tf-guardrails`,
     and merge resulting duplicate list lines into one.
   Re-run the grep until it prints nothing.
7. `CHANGELOG.md` → `### Changed`: `- terraform-aws-syntax, terraform-checkov-skips and terraform-version-compat merged into tf-guardrails.`
8. Run Shared conventions step 6 checks, including
   `bash scripts/check-frontmatter.sh clusters/07-devops/tf-guardrails/SKILL.md`.

## Constraints
- Do not reword source content. Concatenate and demote headings only.
- Do not touch other skills.

## Done when
- [ ] Step 4 loop prints no `MISSING` lines except the allowed kinds.
- [ ] Step 6 grep prints nothing.
- [ ] `shellcheck clusters/07-devops/tf-guardrails/*.sh` prints nothing.
- [ ] `bash scripts/check-frontmatter.sh clusters/07-devops/tf-guardrails/SKILL.md` exits 0.
- [ ] `grep -c '^## Installation' clusters/07-devops/tf-guardrails/README.md` prints `1`.
- [ ] `check-roadmap-sync.sh . --check` exits 0 after `--fix`.

## Return signal
Commit message: `feat!: merge terraform skills into tf-guardrails` with footer
`BREAKING CHANGE: terraform-aws-syntax, terraform-checkov-skips and terraform-version-compat are replaced by tf-guardrails.`
Then follow Shared conventions step 7.

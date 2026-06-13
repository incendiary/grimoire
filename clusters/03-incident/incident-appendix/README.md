# incident-appendix

> **Cluster:** 03-incident | **Status:** complete | **Added:** 2026-05-24

Structures raw investigation evidence into a formal technical appendix. Enforces a fixed
section order (timeline, IOCs, evidence table, gaps, assumptions, remediation) and hard
rules about UTC timestamps, source attribution, and the distinction between facts and
assumptions.

---

## What this skill does

Takes evidence collected during an investigation and produces a structured technical
appendix that can be attached to an executive summary or incident report. The output is
consistent, citation-backed, and defensible — every factual claim traces to a named
evidence source.

Pairs with `incident-ask-builder` (to determine what evidence to collect) and
`executive-translate` (to write the executive summary that sits in front of this appendix).

---

## When to use it

- Writing the technical section of an incident report
- Documenting evidence for a post-incident review
- Producing a formal record for Legal or regulatory purposes
- Creating a reference document for a future reinvestigation

---

## Installation

### Claude Code

```bash
cp -r clusters/03-incident/incident-appendix ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#incident-appendix
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.



---

## How to invoke it in a session

```
/incident-appendix
Evidence: [paste or describe what was collected]
Timeline: [paste events with timestamps]
Gaps: [what could not be confirmed]
Assumptions: [what was treated as true]
Remediation: [actions taken or proposed]
```

Or inline:

```
Write up the technical appendix for this investigation.
Here's what we have: [paste evidence dump]
```

---

## Workflow

```
User provides raw evidence, timeline, gaps, assumptions, remediation
                     ↓
Structure into six fixed sections:
  A. Timeline (UTC, source-attributed)
  B. Indicators of Compromise
  C. Evidence Collected (table with integrity checks)
  D. Gaps and Unknowns
  E. Assumptions (with basis stated)
  F. Remediation Actions (table, owner + date)
                     ↓
Every factual claim → reference to evidence source
                     ↓
Tables for structured data, numbered lists for sequences
```

---

## What it will NOT do

- Use local timestamps — UTC only
- State assumptions as confirmed facts
- Omit the Gaps section — gaps are honest documentation, not weakness
- Present evidence without source attribution

---

## Section reference

| Section | Format | Key rule |
|---------|--------|----------|
| Timeline | One event per line, UTC | Mark unconfirmed events explicitly |
| IOCs | Bullet list | SHA-256 for hashes, full serials for certs |
| Evidence collected | Table | Include integrity check (hash/checksum) |
| Gaps | Prose list | State what would resolve each gap |
| Assumptions | Numbered list | State basis for each assumption |
| Remediation | Table | Separate completed from proposed |

---

## Roadmap

- [x] SKILL.md written and validated
- [x] Write `appendix-template.md` as a fillable section structure
- [x] Add iOS signing-specific IOC types (Developer ID, provisioning profile UUID)
- [x] Add AWS CloudTrail evidence citation format
- [ ] Test on 2 real investigation write-ups
- [x] Ship: copy to `~/.claude/skills/incident-appendix/`

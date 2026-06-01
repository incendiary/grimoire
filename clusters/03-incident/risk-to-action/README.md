# risk-to-action

> **Cluster:** 03-incident | **Status:** complete | **Added:** 2026-05-24

Converts an abstract risk statement into a structured action plan. Forces a plain-language
impact restatement, assigns owner groups across three time horizons, flags decisions
and dependencies, and catches the common mistake of calling risk acceptance an "action".

---

## What this skill does

Takes a risk statement (from a risk register, audit finding, pen test report, or threat
model) and produces a structured action plan table. Mitigations are sorted into immediate,
short-term, and long-term buckets. Decisions required before action can proceed are
separated into a decision log with named decision-makers and consequences.

Pairs with `executive-translate` to produce the executive-facing version of the action plan.

---

## When to use it

- After a pen test delivers findings that need an action plan
- When a risk register item needs to move from "identified" to "owned and actioned"
- When an audit finding requires a management response
- After a threat model produces a risk list that needs prioritisation and owners

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/03-incident/risk-to-action ~/.claude/skills/
```

No hook wiring required.

---

## How to invoke it in a session

```
/risk-to-action
Risk: [paste or describe the risk statement]
Available mitigations: [optional — if you have ideas already]
Owner groups available: platform team, SOC, procurement, legal
Known blockers: [optional]
```

Or inline:

```
Turn this pen test finding into an action plan.
[paste finding]
Owner groups: [list teams]
```

---

## Workflow

```
User provides risk statement + owner groups + known blockers
                    ↓
Restate risk as plain-language impact sentence
(If this can't be written, ask for clarification first)
                    ↓
Identify mitigations across three horizons:
  Immediate (this week) → Short-term (this quarter) → Long-term (roadmap)
                    ↓
Flag decisions required before action can proceed
  (Who decides? What if they don't?)
                    ↓
Flag dependencies between actions
                    ↓
Output: action plan table + decision log
```

---

## What it will NOT do

- Recommend "accept the risk" as an action without flagging it as a governance decision
- Assign actions to individuals (always owner groups/roles)
- Omit compensating controls when the primary control is not achievable
- Produce an action plan without a plain-language impact restatement first

---

## Common pitfalls it catches

| Pitfall | How the skill handles it |
|---------|--------------------------|
| Risk owner ≠ action owner | Explicitly separates these roles |
| Missing decision gate | Decision log section flags required approvals |
| Dependency ordering | Dependencies stated explicitly between actions |
| Risk acceptance without sign-off | Flagged as a governance decision, not an action |
| Passive risk statements that hide ownership | Forced restatement reveals the gap |

---

## Roadmap

- [x] SKILL.md written and validated
- [ ] Write `risk-action-template.md` for reuse
- [ ] Add example governance tiers (who signs off at what risk level)
- [ ] Add pen test finding format examples
- [ ] Test on 3 real risk items
- [ ] Ship: copy to `~/.claude/skills/risk-to-action/`

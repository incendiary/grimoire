# Risk Action Plan — [Risk Title]

> **Risk register reference:** [REG-YYYY-NNN]
> **Source:** [Risk register / Audit finding / Pen test report / Threat model]
> **Risk owner:** [Role / Team — who owns the risk]
> **Date:** [YYYY-MM-DD]
> **Review date:** [YYYY-MM-DD]

---

## Risk Statement

> **Impact statement:**
> If [condition], then [consequence] affecting [what / who].

**Inherent risk rating:** [Critical / High / Medium / Low]
**Current residual risk:** [Critical / High / Medium / Low]
**Target residual risk:** [Critical / High / Medium / Low]

---

## Governance Tier Reference

Use this table to determine who must sign off before an action proceeds or a risk is accepted.

| Risk rating | Sign-off required | Escalation path |
|------------|------------------|----------------|
| Critical | CISO + Board / Exec | Within 48h |
| High | CISO or Deputy CISO | Within 1 week |
| Medium | Security Lead or Risk Owner | Within 1 month |
| Low | Team Lead | At next sprint / planning cycle |

> **Risk acceptance is a governance decision, not an action.**
> Recording "Accept" in the action plan requires formal sign-off at the tier above.
> An unsigned acceptance is not a valid control state.

---

## Action Plan

### Immediate Actions (This Week)

Controls applicable now with current resources — no procurement or policy change required.

| # | Action | Owner (role) | Depends on | Status |
|---|--------|-------------|-----------|--------|
| I-1 | [specific action — e.g. "Revoke API key `abc...` in AWS IAM console"] | [Platform team] | None | [Pending / In Progress / Done] |
| I-2 | [action] | [team] | [I-1 complete] | |

### Short-Term Actions (This Quarter)

Controls requiring coordination, minor procurement, or a policy update.

| # | Action | Owner (role) | Depends on | Target date | Status |
|---|--------|-------------|-----------|------------|--------|
| S-1 | [action — e.g. "Deploy CrowdStrike to all macOS endpoints in fleet"] | [IT / Platform] | [I-1 complete] | YYYY-MM-DD | |
| S-2 | [action] | [team] | | YYYY-MM-DD | |

### Long-Term Actions (Roadmap)

Structural changes requiring planning, architectural decision, or budget approval.

| # | Action | Owner (role) | Depends on | Target quarter | Status |
|---|--------|-------------|-----------|---------------|--------|
| L-1 | [action — e.g. "Replace custom auth with IdP-federated identity"] | [Platform / Architecture] | [S-1] | QN YYYY | |
| L-2 | [action] | | | | |

---

## Pen Test Finding Format

When this action plan is derived from a pen test finding, include this block:

| Field | Value |
|-------|-------|
| Finding title | [short title] |
| CVSS score | [score] — [vector string] |
| Affected system | [host / service / component] |
| Exploit path | [brief: attacker position → what they can do] |
| Proof of concept | [reference to appendix or finding ID in report] |
| Recommended fix | [as stated in the pen test report] |
| Verified by | [tester name / team] |
| Test date | [YYYY-MM-DD] |

---

## Decision Log

Decisions that must be made before actions can proceed.

| # | Decision | Who makes it | Consequence of not deciding | Status |
|---|---------|-------------|----------------------------|--------|
| D-1 | [e.g. "Accept residual risk after S-1 is complete?"] | [CISO] | Risk remains open; no target residual state | [Pending] |
| D-2 | | | | |

---

## Compensating Controls (if primary controls are delayed)

| # | Compensating control | Covers | Owner | Valid until |
|---|---------------------|--------|-------|------------|
| C-1 | [e.g. "Manual monthly review of IAM access keys"] | L-1 not yet deployed | [Security team] | YYYY-MM-DD |

> **Compensating controls are temporary.** Each has an expiry date aligned to when the
> primary control is expected to land. Do not leave compensating controls open-ended.

---

*Template: risk-action-template.md — populate per risk item*

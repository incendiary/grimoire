# 03-incident — Security incident support

Skills for security incident response and risk management. Covers evidence collection
coordination, formal technical documentation, and converting risk statements into
structured action plans. Skills in this cluster are designed to chain: collect → document → plan.

---

## Skills

### [incident-asks](incident-asks/) ✅ complete

Converts an incident description into a structured evidence-collection checklist grouped
by owner. Each ask specifies what exactly is needed, who owns it, urgency tier, and
whether Legal sign-off is required. Retention-risk flags appear at the top so
time-sensitive evidence is not missed.
→ [Full documentation](incident-asks/README.md)

### [incident-appendix](incident-appendix/) ✅ complete

Structures raw investigation evidence into a formal technical appendix: timeline (UTC,
source-attributed), IOCs, evidence table, gaps and unknowns, assumptions with stated
basis, and remediation actions. Every factual claim cites its evidence source.
Distinguishes clearly between confirmed facts and assumptions.
→ [Full documentation](incident-appendix/README.md)

### [incident-risk-plan](incident-risk-plan/) ✅ complete

Converts an abstract risk statement into a structured action plan. Forces a
plain-language impact restatement, assigns mitigations across immediate/short-term/
long-term horizons, flags decisions required before action can proceed, and separates
risk ownership from action ownership. Treats risk acceptance as a governance decision,
not an action.
→ [Full documentation](incident-risk-plan/README.md)

---

## Typical chain

```
Incident occurs
      ↓
incident-asks  (who needs to give us what, by when)
      ↓
Evidence collected
      ↓
incident-appendix     (formal technical record)
      ↓
write-exec   (executive summary)
      ↓
incident-risk-plan        (what we do next)
```

---

## When to invoke — workflow guide

### Workflow 1: Active incident response

**Trigger:** "We have an incident; what do we need to collect first?"

```
incident-asks  → owner-tagged evidence request plan
      ↓
incident-appendix     → source-backed technical appendix
      ↓
write-exec   → leadership-ready summary
      ↓
incident-risk-plan        → mitigation plan and ownership horizon
```

### Workflow 2: Post-incident risk planning

**Trigger:** "Convert this finding/risk into an actionable plan"

```
incident-risk-plan        → immediate/short/long-term action plan
      ↓
incident-appendix     → supporting evidence and assumptions
      ↓
write-exec   → communication to decision-makers
```

---

## Individual skill trigger reference

| Skill | Invoke when... |
|-------|----------------|
| `incident-asks` | Early incident phase needs precise evidence asks by owner and urgency |
| `incident-appendix` | You need a defensible technical record with cited facts and assumptions |
| `incident-risk-plan` | Risk statement must become execution-ready mitigation plan |

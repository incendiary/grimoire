# 03-incident — Security incident support

Skills for security incident response and risk management. Covers evidence collection
coordination, formal technical documentation, and converting risk statements into
structured action plans. Skills in this cluster are designed to chain: collect → document → plan.

---

## Skills

### [incident-ask-builder](incident-ask-builder/) ✅ complete

Converts an incident description into a structured evidence-collection checklist grouped
by owner. Each ask specifies what exactly is needed, who owns it, urgency tier, and
whether Legal sign-off is required. Retention-risk flags appear at the top so
time-sensitive evidence is not missed.
→ [Full documentation](incident-ask-builder/README.md)

### [incident-appendix](incident-appendix/) ✅ complete

Structures raw investigation evidence into a formal technical appendix: timeline (UTC,
source-attributed), IOCs, evidence table, gaps and unknowns, assumptions with stated
basis, and remediation actions. Every factual claim cites its evidence source.
Distinguishes clearly between confirmed facts and assumptions.
→ [Full documentation](incident-appendix/README.md)

### [risk-to-action](risk-to-action/) ✅ complete

Converts an abstract risk statement into a structured action plan. Forces a
plain-language impact restatement, assigns mitigations across immediate/short-term/
long-term horizons, flags decisions required before action can proceed, and separates
risk ownership from action ownership. Treats risk acceptance as a governance decision,
not an action.
→ [Full documentation](risk-to-action/README.md)

---

## Typical chain

```
Incident occurs
      ↓
incident-ask-builder  (who needs to give us what, by when)
      ↓
Evidence collected
      ↓
incident-appendix     (formal technical record)
      ↓
executive-translate   (executive summary)
      ↓
risk-to-action        (what we do next)
```

---

## When to invoke — workflow guide

### Workflow 1: Active incident response

**Trigger:** "We have an incident; what do we need to collect first?"

```
incident-ask-builder  → owner-tagged evidence request plan
      ↓
incident-appendix     → source-backed technical appendix
      ↓
executive-translate   → leadership-ready summary
      ↓
risk-to-action        → mitigation plan and ownership horizon
```

### Workflow 2: Post-incident risk planning

**Trigger:** "Convert this finding/risk into an actionable plan"

```
risk-to-action        → immediate/short/long-term action plan
      ↓
incident-appendix     → supporting evidence and assumptions
      ↓
executive-translate   → communication to decision-makers
```

---

## Individual skill trigger reference

| Skill | Invoke when... |
|-------|----------------|
| `incident-ask-builder` | Early incident phase needs precise evidence asks by owner and urgency |
| `incident-appendix` | You need a defensible technical record with cited facts and assumptions |
| `risk-to-action` | Risk statement must become execution-ready mitigation plan |

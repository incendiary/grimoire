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

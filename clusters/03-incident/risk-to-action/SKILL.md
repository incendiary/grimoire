# risk-to-action

> **Status:** COMPLETE
> **Type:** instructional
> **Cluster:** 03-incident

## Description
Convert an abstract risk statement into a structured action plan with owner groups,
timelines, decision points, and dependencies flagged.

Invoke when: the user has a risk statement from a risk register, audit finding, pen
test report, or threat model and needs to turn it into actionable tasks. Trigger
phrases: "turn this risk into actions", "what do we actually do about this",
"action plan for this finding", "how do we remediate this".

## Context needed
- The risk statement: what could happen, what the impact would be
- Available mitigation options (technical controls, process controls, compensating controls)
- Owner groups who can act (e.g. platform team, SOC, procurement, legal, application team)
- Any known dependencies or blockers (budget approval, vendor timelines, policy change)

## What to do

1. **Restate the risk as a plain-language impact statement.** One sentence:
   "If [condition], then [consequence] affecting [what / who]."
   This forces precision. If you cannot write this sentence from the risk statement
   provided, ask the user to clarify before continuing.

2. **Identify mitigations in three time horizons and assign owner groups:**
   - **Immediate (this week):** controls that can be applied now with current resources.
     Examples: block a network path, revoke a credential, enable logging.
   - **Short-term (this quarter):** controls requiring some coordination or procurement.
     Examples: deploy a new tool, update a policy, run a configuration change.
   - **Long-term (roadmap):** structural changes that require planning and budget.
     Examples: architectural change, vendor replacement, staff training programme.

3. **Flag decisions that must be made before action can proceed.** For each decision:
   - What is the decision?
   - Who makes it (role, not individual)?
   - What is the consequence of not making it?

4. **Flag dependencies between mitigations.** If a short-term control depends on an
   immediate action completing first, state this explicitly in the output. A Gantt-style
   dependency line in prose is sufficient: "Short-term action 2 depends on Immediate
   action 1 being complete."

5. **Output as a structured action plan** with these columns per item:
   | # | Action | Owner | Timeline | Depends on | Status |
   Follow the table with a decision log (decisions required, who makes them, consequence).

## Gotchas
- Risk owners and action owners are often different people. The person who owns the
  risk in a risk register may not be the person who can execute the remediation.
  Be explicit about which role is which.
- Compensating controls are valid mitigations when the primary control is not achievable
  in the required timeline. Include them with a note that they are compensating, not
  primary.
- Do not recommend accepting a risk without flagging it as a formal acceptance decision
  requiring sign-off. "Accept the risk" is not an action — it is a governance decision.
- Risk statements that use passive voice often hide the owner. "Data could be exposed"
  does not say who is responsible for protecting it. Clarify before assigning owners.

## Suggested scripts
- `risk-action-template.md` — the action plan table and decision log as a reusable template

# tone-check

> **Cluster:** 02-comms | **Status:** complete | **Added:** 2026-05-24

Annotation-only tone review. Tells you what is wrong with a draft and why, without
rewriting it. Designed for security and technical communications where directness
is often mistaken for aggression and softness is often mistaken for politeness.

---

## What this skill does

Assesses a draft on four independent axes — blame, authority, vagueness, and softness —
and quotes the specific phrase that caused each flag. Output is a structured block you
can act on or ignore per axis. No rewrite is produced unless you explicitly ask for one.

This pairs with `human-rewrite` (for style cleanup) and `executive-translate`
(for audience-specific calibration). A typical workflow uses all three in sequence:
draft → tone-check → human-rewrite → send.

---

## When to use it

- Before sending a security finding, incident update, or escalation email
- Before sending anything to a senior stakeholder or external recipient
- After `executive-translate` produces a draft
- When you are unsure if your tone will land well with a specific audience
- When someone else's draft needs a review before it goes out under your name

---

## Installation

### Claude Code

```bash
cp -r clusters/02-comms/tone-check ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#tone-check
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.



---

## How to invoke it in a session

```
/tone-check
Audience: CISO (senior stakeholder)
Outcome: requesting urgent action on evidence preservation
Draft:
[paste your draft here]
```

Or more casually:

```
Check the tone of this before I send it — it's going to our CISO.
[paste draft]
```

---

## Workflow

```
User pastes draft + audience + desired outcome
             ↓
Claude infers audience/outcome if not stated (and says so)
             ↓
Four-axis assessment (blame, authority, vagueness, softness)
             ↓
Structured annotation block with quoted phrases
             ↓
One-sentence overall verdict
             ↓
User edits the flagged phrases directly, or asks for a rewrite
```

---

## What it will NOT do

- It will not rewrite the draft. That is `human-rewrite`'s job.
- It will not flag confident or direct language as aggressive.
- It will not roll up multiple problems into a vague summary — each axis is reported independently.

---

## Worked examples — PASS, FLAG, borderline per axis

Each example shows a draft sentence, the tone-check annotation output, and the verdict.

---

### Axis: Blame

**PASS**
> "The configuration error caused the service outage. We have identified the root cause
> and applied a fix."

```
BLAME: PASS
No individual or team is implicated. Root cause is stated factually.
```

**FLAG**
> "The outage occurred because the on-call engineer deployed an untested change without
> following the review process."

```
BLAME: FLAG — "the on-call engineer deployed an untested change without following the
review process" names an individual and implies negligence. Consider: "A change deployed
outside the review process caused the outage."
```

**Borderline**
> "The security team's delayed response extended the exposure window by four hours."

```
BLAME: BORDERLINE — factually accurate but implies the security team is at fault.
Appropriate in a post-incident report where accountability is the point; inappropriate
in a stakeholder brief where the audience may not have context. Confirm intent before
sending.
```

---

### Axis: Authority

**PASS**
> "We recommend disabling the legacy API endpoint by end of quarter. This is the most
> effective control for the identified risk."

```
AUTHORITY: PASS
Clear recommendation with stated rationale. No hedging.
```

**FLAG**
> "It might potentially be worth considering whether we could possibly look at disabling
> the endpoint at some point in the future if the team feels that is appropriate."

```
AUTHORITY: FLAG — "might potentially", "possibly", "if the team feels that is
appropriate" stack hedges until the recommendation disappears. State the recommendation
directly: "Disable the endpoint by end of quarter."
```

**Borderline**
> "The vendor has suggested that patching by Friday would be advisable."

```
AUTHORITY: BORDERLINE — attributing the recommendation to the vendor is accurate if true,
but reads as distancing from the advice. If you agree with the vendor, own it: "Patch by
Friday. The vendor confirmed this is the remediation deadline." Flag if the attribution is
being used to avoid ownership.
```

---

### Axis: Vagueness

**PASS**
> "Two accounts with domain admin privileges were accessed by the attacker between
> 02:14 and 04:37 UTC on 14 June."

```
VAGUENESS: PASS
Specific accounts, specific privilege level, specific timeframe stated.
```

**FLAG**
> "Some privileged accounts may have been impacted during the incident window."

```
VAGUENESS: FLAG — "some", "may have been", "impacted", "incident window" each add
uncertainty without reason. If the facts are known, state them. If genuinely unknown,
say so explicitly: "We have not yet confirmed which accounts were accessed. Investigation
is ongoing; we expect an answer by [time]."
```

**Borderline**
> "A number of endpoints were affected."

```
VAGUENESS: BORDERLINE — acceptable in a first-hour incident update where the count is
still being confirmed; not acceptable in a post-incident report. Add a note on when the
specific number will be available if using this in an early update.
```

---

### Axis: Softness

**PASS**
> "This vulnerability must be patched before the external penetration test on 25 June.
> If it is not resolved by then, the test scope must be restricted."

```
SOFTNESS: PASS
Deadline is stated. Consequence of missing it is stated. No softening language.
```

**FLAG**
> "It would be really great if the team could try to get this patched as soon as
> possible, if that works for everyone."

```
SOFTNESS: FLAG — "really great", "try to", "as soon as possible", "if that works for
everyone" each reduce urgency. The ask has no deadline and no consequence. Replace with
a specific date and what happens if it is missed.
```

**Borderline**
> "We would appreciate a response by end of week."

```
SOFTNESS: BORDERLINE — "would appreciate" is polite but not weak for a peer-level
request with an existing relationship. It becomes a problem if the recipient can ignore
it without consequence. If the deadline is firm, state what happens if it is missed:
"We need a response by end of week to include this in the Friday board pack."
```

---

## Roadmap

- [x] SKILL.md written and validated
- [ ] Test on 5 real drafts across different audience tiers
- [x] Add worked examples of PASS vs FLAG vs borderline for each axis
- [x] Ship: copy to `~/.claude/skills/tone-check/`

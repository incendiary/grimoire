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

```bash
cp -r ~/Claude/Skills/grimoire/clusters/02-comms/tone-check ~/.claude/skills/
```

No hook wiring required.

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

## Roadmap

- [x] SKILL.md written and validated
- [ ] Test on 5 real drafts across different audience tiers
- [ ] Add worked examples of PASS vs FLAG vs borderline for each axis
- [ ] Ship: copy to `~/.claude/skills/tone-check/`

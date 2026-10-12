# 02-comms — Written communication

Skills for drafting, reviewing, and transforming written communications. Covers tone
calibration, AI-marker removal, and translation of technical content for non-technical
audiences. Skills in this cluster are designed to chain: draft → write-tone → write-human → send.

---

## Skills

### [write-tone](write-tone/) ✅ complete

Reviews a draft on four axes — blame, authority, vagueness, and softness — and quotes
the specific phrase that caused each flag. Output is structured annotation only, not
a rewrite. Calibrated to the user's direct writing style; does not flag confidence as aggression.
→ [Full documentation](write-tone/README.md)

### [write-human](write-human/) ✅ complete

Rewrites a draft to remove AI markers and apply a fixed set of style rules: British
English, active voice, Oxford comma, no em dashes, no corporate filler, no AI slop
openers. Medium-aware: treats emails, Slack messages, and document sections differently.
Returns the rewritten text only — no commentary.
→ [Full documentation](write-human/README.md)

### [write-exec](write-exec/) ✅ complete

Converts technical or security content into exec-readable language. Leads with the
single most important thing, states business impact quantitatively, surfaces one clear
ask, and puts technical detail in an optional supporting section. Calibrated to audience
tier (CISO, C-suite, board, senior management).
→ [Full documentation](write-exec/README.md)

---

## Typical chain

```
Technical content or draft
        ↓
write-exec  (if audience is non-technical)
        ↓
write-tone          (verify tone for recipient)
        ↓
write-human       (final style pass)
        ↓
Send
```

---

## When to invoke — workflow guide

### Workflow 1: Executive audience communication

**Trigger:** "Turn this technical update into an exec brief"

```
write-exec   → produce business-impact-first narrative
        ↓
write-tone            → verify confidence, ownership, and clarity
        ↓
write-human         → final style pass aligned to channel
```

### Workflow 2: Sensitive stakeholder message

**Trigger:** "Draft a firm but non-inflammatory incident message"

```
write-tone            → identify blame/authority/vagueness risks
        ↓
write-human         → rewrite with precise language and no filler
        ↓
write-exec   → (optional) if leadership-facing summary is needed
```

---

## Individual skill trigger reference

| Skill | Invoke when... |
|-------|----------------|
| `write-tone` | You already have a draft and need issue spotting before rewriting |
| `write-human` | Final message needs natural, direct style with AI markers removed |
| `write-exec` | Audience is non-technical and needs concise impact + clear ask |

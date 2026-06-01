# 02-comms — Written communication

Skills for drafting, reviewing, and transforming written communications. Covers tone
calibration, AI-marker removal, and translation of technical content for non-technical
audiences. Skills in this cluster are designed to chain: draft → tone-check → human-rewrite → send.

---

## Skills

### [tone-check](tone-check/) ✅ complete
Reviews a draft on four axes — blame, authority, vagueness, and softness — and quotes
the specific phrase that caused each flag. Output is structured annotation only, not
a rewrite. Calibrated to the user's direct writing style; does not flag confidence as aggression.
→ [Full documentation](tone-check/README.md)

### [human-rewrite](human-rewrite/) ✅ complete
Rewrites a draft to remove AI markers and apply a fixed set of style rules: British
English, active voice, Oxford comma, no em dashes, no corporate filler, no AI slop
openers. Medium-aware: treats emails, Slack messages, and document sections differently.
Returns the rewritten text only — no commentary.
→ [Full documentation](human-rewrite/README.md)

### [executive-translate](executive-translate/) ✅ complete
Converts technical or security content into exec-readable language. Leads with the
single most important thing, states business impact quantitatively, surfaces one clear
ask, and puts technical detail in an optional supporting section. Calibrated to audience
tier (CISO, C-suite, board, senior management).
→ [Full documentation](executive-translate/README.md)

---

## Typical chain

```
Technical content or draft
        ↓
executive-translate  (if audience is non-technical)
        ↓
tone-check          (verify tone for recipient)
        ↓
human-rewrite       (final style pass)
        ↓
Send
```

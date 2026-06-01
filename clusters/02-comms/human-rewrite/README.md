# human-rewrite

> **Cluster:** 02-comms | **Status:** complete | **Added:** 2026-05-24

Strips AI markers and applies a fixed set of style rules to any draft. The rules are
loaded from this skill so you never have to re-state them. The output is the rewritten
text only — no commentary, no explanation of what changed.

---

## What this skill does

Applies a deterministic set of rewriting rules:

| Rule | Example |
|------|---------|
| British English | organise, colour, programme, defence |
| Active voice | "The team sent the report" not "The report was sent" |
| Oxford comma | "A, B, and C" not "A, B and C" |
| No em dashes | Replace with comma, colon, or parentheses |
| No corporate filler | No leverage, synergy, circle back, touch base |
| No AI openers | No "Certainly!", "Absolutely!", "Happy to help!" |
| No bullet points in prose | Unless the user explicitly uses them |
| Sentence length variation | Mix short and long sentences |
| Cut over-explanation | If a sentence adds nothing new, remove it |

Medium-aware: emails, Slack messages, and document sections are treated differently.
A Slack message that sounds like an email is itself an AI marker.

---

## When to use it

- After any other skill produces a draft (`singtel-security-email`, `executive-translate`, `incident-appendix`)
- When Claude has drafted something in the session and it needs a style pass before sending
- When you have written something yourself but want a cleanup pass
- Any time the output "sounds like ChatGPT"

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/02-comms/human-rewrite ~/.claude/skills/
```

No hook wiring required.

---

## How to invoke it in a session

After another skill produces a draft:

```
Run human-rewrite on that. Medium: email.
```

Or with your own text:

```
/human-rewrite
Medium: Slack message
[paste your draft]
```

The style rules are pre-loaded — you do not need to re-list them.

---

## Workflow

```
Draft produced (by you or another skill)
           ↓
human-rewrite invoked with medium specified
           ↓
Apply all style rules (British English, active voice, etc.)
           ↓
Mental read-aloud check for residual AI markers
           ↓
Return rewritten text only — no preamble
```

---

## What it will NOT do

- Change technical terms, product names, or acronyms
- Soften assertive language (directness is not aggression)
- Add explanation, commentary, or a list of changes made
- Apply email structure to a Slack message or vice versa

---

## Roadmap

- [x] SKILL.md written and validated
- [ ] Build worked before/after examples for each style rule
- [ ] Test on 5 real outputs from other skills
- [ ] Add any further rules that emerge from real usage
- [x] Ship: copy to `~/.claude/skills/human-rewrite/`

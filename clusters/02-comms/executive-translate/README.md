# executive-translate

> **Cluster:** 02-comms | **Status:** complete | **Added:** 2026-05-24

Converts technical or security content into language a CISO, C-suite, or board
member can act on. Leads with impact and ask. Removes jargon without losing accuracy.
Pairs with `human-rewrite` for the final style pass.

---

## What this skill does

Takes a technical finding, risk, or incident description and restructures it for
a senior non-technical audience:

- **First sentence:** the single most important thing they need to know
- **First paragraph:** business impact, quantified where possible
- **Second paragraph:** the ask or decision required, with owner and consequences
- **Optional technical summary:** for readers who want the detail

The output respects audience tier — a board member gets more context-setting than a CISO;
a CISO gets more technical framing than a C-suite peer.

---

## When to use it

- Writing up a security finding for a CISO review
- Preparing an incident summary for C-suite or board
- Translating a pen test report finding into a risk committee brief
- Any time a technical colleague asks you to "make this exec-ready"

---

## Installation

### Claude Code

```bash
cp -r clusters/02-comms/executive-translate ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#executive-translate
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.



---

## How to invoke it in a session

```
/executive-translate
Audience: CISO
Ask: approval to engage an external IR firm
Political constraints: do not imply the security team missed this

[paste technical content]
```

Or inline during a session:

```
Turn this pen test finding into an exec brief for the CISO.
[paste finding]
```

---

## Workflow

```
User provides technical content + audience tier + ask
                   ↓
Identify the single most important thing (first sentence)
                   ↓
Business impact statement (quantified where possible)
                   ↓
One clear ask with owner and consequence if not acted on
                   ↓
Optional technical summary (labelled as optional)
                   ↓
human-rewrite style pass (British English, active voice, no jargon)
```

---

## What it will NOT do

- Use the word "leverage"
- Imply blame unless explicitly instructed
- Produce vague risk language ("significant potential impact") — it will flag this
  and ask for quantification or plain-language framing
- Include more than one ask in the main body

---

## Audience tier guide

| Tier | Depth | Acronyms | Technical detail |
|------|-------|----------|-----------------|
| CISO | Moderate | Expand unfamiliar ones | Brief technical summary fine |
| C-suite | Low | Expand all | Optional paragraph only |
| Board | Lowest | Expand all, explain context | Do not include |
| Senior management | Moderate | Expand unfamiliar ones | Brief summary fine |

---

## Roadmap

- [x] SKILL.md written and validated
- [ ] Build 3 worked examples (finding → CISO brief, incident → board summary, risk → C-suite ask)
- [ ] Add worked examples for different audience tiers (CISO, C-suite, board)
- [ ] Test on 3 real findings
- [x] Ship: copy to `~/.claude/skills/executive-translate/`

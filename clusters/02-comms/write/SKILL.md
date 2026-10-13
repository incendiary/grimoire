---
name: write
description: "Improves a draft in one of three modes: tone check (annotate blame, authority, vagueness, softness without rewriting), humanise (rewrite in the owner's style, removing AI markers), or exec (translate technical or security content for CISO, C-suite or board, leading with impact and the ask). Use when asked to 'check the tone of this', 'make this sound more human', 'remove the AI from this', 'make this exec-ready', or 'write this up for leadership'."
---
# write

> **Status:** COMPLETE
> **Cluster:** 02-comms
> **Type:** instructional

## Description
One skill, three modes. Pick the mode from the request; if unclear, ask which. Typical
order when more than one applies: exec, then humanise, then tone check.

| Mode | Asked for | Output |
|---|---|---|
| Tone check | "check the tone", "too aggressive?", "too soft?", "review before I send" | Annotation only, no rewrite |
| Humanise | "make this sound more human", "remove the AI", "rewrite in my style" | Rewritten draft only |
| Exec | "make this exec-ready", "CISO version", "write this up for leadership" | Exec-ready text |

## Mode: tone check

Context: the draft, the audience (peer, senior stakeholder, vendor, regulator), and the
desired outcome (inform, escalate, request action, decline, acknowledge). If not stated,
infer from context and state the inference so the owner can correct it.

Assess four independent axes, quoting the phrase that triggered each verdict:
- **Blame:** fault assigned in a way that puts the recipient on the defensive ("you failed to", "this was not done").
- **Authority:** over-claiming (arrogant, demanding without basis) or under-claiming (apologetic, hedging own expertise).
- **Vagueness:** asks that are not concrete and time-bound ("please look into this", "as soon as possible", no deadline).
- **Softness:** hedging that undermines the message ("might", "perhaps", "I was wondering if", "sorry to bother you").

Output:
```
BLAME:     [PASS / FLAG] — "quoted phrase" — reason
AUTHORITY: [PASS / FLAG] — "quoted phrase" — reason
VAGUENESS: [PASS / FLAG] — "quoted phrase" — reason
SOFTNESS:  [PASS / FLAG] — "quoted phrase" — reason

Overall: [one sentence verdict]
```
Do not rewrite unless asked. Directness is not aggression: the owner's register is direct.
Security communications often need authority; flag it only when unearned or likely to
land badly. When unsure about a sensitive audience, flag and let the owner decide.

## Mode: humanise

Context: the draft and the medium (email, Slack, Teams, document section).

Apply every rule, without being asked (they match the owner's global CLAUDE.md):
- British English (organise, defence, programme, licence/license).
- Active voice.
- Oxford comma in lists of three or more.
- No em dashes: use a comma, colon, or parentheses.
- No corporate filler (leverage, synergy, circle back, reach out, touch base, going forward, deep dive, bandwidth, take this offline).
- No AI openers (Certainly!, Of course!, Great question!, Happy to help!).
- No bullet points in prose emails or messages unless the owner used them.
- Vary sentence length; cut sentences that add nothing.

Then reread: rewrite anything that sounds overly smooth, slightly too formal, or hedged
where confidence is right. Return the rewritten draft only, with no commentary.

Keep technical terms, product names, acronyms, proper nouns, and deliberate repetition.
Match the medium: Slack is short and conversational, email has structure, a document
section has no greeting or sign-off.

## Mode: exec

Context: the content, the audience tier (CISO, C-suite, board, senior management), the ask
or decision needed, and political constraints (what must not be implied, who must not be blamed).

1. **First sentence:** the single most important thing this audience needs to know. If you
   cannot identify it, ask.
2. **Business impact** in plain language, quantified where possible ("up to 40,000 customer
   records may have been accessible", not "data may have been exposed").
3. **Second paragraph: one ask**, with who decides and what happens if they do not. Note
   that other asks exist if there are several.
4. **Optional technical summary**, clearly labelled for readers who want detail.
5. **Apply humanise mode** to the result.

Executives read the first two sentences and the ask: front-load. Expand acronyms at first
use (the board does not know internal system names). "Significant", "potential", and "may"
are weasel words at this level: state real risk plainly or quantify the uncertainty. Avoid
blame language unless the owner wants accountability language.

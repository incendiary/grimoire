# executive-translate

> **Status:** COMPLETE
> **Cluster:** 02-comms

## Description
Convert technical or security content into exec-readable language for CISO or senior
leadership. Lead with impact and ask. Remove jargon. Do not lose accuracy.

Invoke when: the user says "write this up for leadership", "make this exec-ready",
"CISO version of this", "translate this for non-technical stakeholders", or needs to
communicate a security finding, risk, or incident to a senior audience.

## Context needed
- The technical content to translate
- Audience tier: CISO, C-suite, board, or senior management (affects depth and vocabulary)
- The ask or decision required from the audience, if any
- Political constraints: what must not be implied, who must not be blamed

## What to do

1. **Identify the single most important thing this audience needs to know.** This becomes
   the first sentence. If you cannot identify it, ask the user before continuing.

2. **State business impact in plain language.** Quantify where possible: data at risk,
   systems affected, potential downtime, regulatory exposure, financial implication.
   If not quantifiable, frame qualitatively but avoid vague language like "significant
   risk" or "potential impact". "Up to 40,000 customer records may have been accessible"
   is better than "data may have been exposed".

3. **State the ask or recommended decision in the second paragraph.** One ask only.
   If there are multiple asks, surface the most urgent and note others exist.
   The ask must include who makes the decision and what happens if they do not.

4. **Add a brief technical summary paragraph** for audiences who want the detail.
   This is optional reading, not required for understanding the ask. Label it clearly
   ("Technical summary — for readers who want additional detail").

5. **Apply `human-rewrite` style rules** to the full output. No corporate filler,
   no em dashes, British English, active voice.

## Gotchas
- Do not use the word "leverage" under any circumstances.
- Executives read the first two sentences and the ask. Everything else is supporting
  detail. Structure accordingly — front-load.
- Avoid implying blame unless the user explicitly wants accountability language.
- Board-level content requires more context-setting than CISO-level. The board does
  not know your internal system names. Always expand acronyms at first use.
- "Significant", "potential", and "may" are weasel words at exec level. If the
  risk is real, state it plainly. If it is uncertain, quantify the uncertainty.

## Suggested scripts
- None — this is a pure translation skill, no scripts needed

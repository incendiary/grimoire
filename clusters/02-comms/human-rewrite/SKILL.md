# human-rewrite

> **Status:** COMPLETE
> **Type:** instructional
> **Cluster:** 02-comms

## Description
Rewrite a draft to remove AI markers and apply the user's style rules without changing
substance. Inputs are often output from other skills or Claude turns.

Invoke when: the user says "make this sound more human", "remove the AI from this",
"rewrite this in my style", or after `executive-translate`
produces a draft that needs a final pass.

## Context needed
- The draft text to rewrite
- Target medium: email, Slack message, Teams message, or document section
  (medium affects length, formality, and structure)

## What to do

1. **Apply all style rules below without exception.** These are standing rules and
   do not need to be re-stated by the user each time:
   - British English throughout: organise, defence, recognise, programme, colour,
     behaviour, analyse, licence (noun) / license (verb), travelling
   - Active voice. Rewrite any passive construction. "The report was sent by the team"
     → "The team sent the report."
   - Oxford comma in all lists of three or more items
   - No em dashes. Replace with: a comma (for asides), a colon (for elaboration), or
     parentheses (for digressions)
   - No corporate filler: leverage, synergy, circle back, reach out, touch base,
     going forward, at the end of the day, moving the needle, deep dive, bandwidth,
     take this offline, action item, deliverable (in place of "output" or "result")
   - No AI slop openers: Certainly!, Of course!, Great question!, Absolutely!,
     Happy to help!, I'd be delighted to
   - No bullet points in prose emails or messages unless the user explicitly uses them
   - Sentence length variation. Avoid three or more sentences of similar length and
     structure in a row.
   - No over-explanation. If a sentence adds nothing beyond what the previous sentence
     already said, cut it.

2. **Read the result aloud mentally.** If any sentence sounds like it was written by
   an AI assistant — overly smooth, slightly too formal, hedged where confidence
   is appropriate — rewrite it.

3. **Return the rewritten draft only.** No commentary. No list of changes made.
   No preamble.

## Gotchas
- Do not change technical terms, product names, acronyms, or proper nouns.
- Do not soften assertive language unless it is genuinely aggressive. The user's
  natural register is direct. Direct is not aggression.
- Medium matters significantly. A Slack message should be conversational and short.
  An email has structure. A document section has no greeting or sign-off. Applying
  email structure to a Slack message is itself an AI marker.
- If the user's draft contains deliberate repetition for emphasis, preserve it.
  Not all repetition is accidental.

## Suggested scripts
- None — this is a pure rewrite skill, no scripts needed

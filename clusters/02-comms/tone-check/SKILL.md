# tone-check

> **Status:** COMPLETE
> **Cluster:** 02-comms

## Description
Review a draft and annotate whether it reads as blaming, too soft, too authoritative, or
too vague. Output is structured annotation, not a rewrite.

Invoke when: the user says "check the tone of this", "does this sound too aggressive",
"is this too soft", or "review this before I send it". Also invoke automatically when
`human-rewrite` or `executive-translate` produce a draft and the user wants a
second-pass tone review.

## Context needed
- The draft text to review
- Target audience (peer, senior stakeholder, external vendor, regulator, etc.)
- Desired outcome (inform, escalate, request action, decline, acknowledge)

## What to do

1. **Identify the intended audience and outcome.** If not stated, infer from context —
   recipient name, subject line, platform (email vs Slack vs document). State your
   inference so the user can correct it.

2. **Assess the draft on four axes.** For each axis, give a one-line verdict and quote
   the specific phrase that triggered the rating:
   - **Blame** — does the draft assign fault in a way that will put the recipient on
     the defensive? Flag phrases like "you failed to", "this was not done", "as a result
     of your team's..." even if technically accurate.
   - **Authority** — does the sender over-claim (sounds arrogant, demands without basis)
     or under-claim (sounds apologetic, hedges their own expertise)? Quote the phrase.
   - **Vagueness** — are the asks concrete and time-bound? Flag "please look into this",
     "as soon as possible", "when you get a chance" as vague. Flag missing deadlines.
   - **Softness** — does hedging language undermine the message? Flag "might", "perhaps",
     "I was wondering if", "if it's not too much trouble", "sorry to bother you".

3. **Output a structured annotation block, then a one-sentence overall verdict.** Format:
   ```
   BLAME:     [PASS / FLAG] — "quoted phrase" — reason
   AUTHORITY: [PASS / FLAG] — "quoted phrase" — reason
   VAGUENESS: [PASS / FLAG] — "quoted phrase" — reason
   SOFTNESS:  [PASS / FLAG] — "quoted phrase" — reason

   Overall: [one sentence verdict]
   ```
   Do not rewrite the draft unless explicitly asked. The output is annotation only.

## Gotchas
- Do not conflate directness with aggression. The user's default register is direct and
  confident. Flag only genuine blame or aggression, not confident tone.
- Security communications often require authority. Do not flag authority as a problem
  unless it is unearned or will land badly with the specific audience.
- When in doubt about audience sensitivity (e.g. a senior external stakeholder), err
  toward flagging rather than passing. Let the user decide.
- The four axes are independent. A draft can be too soft AND too vague simultaneously.
  Report all failures, do not roll them up.

## Suggested scripts
- None — this is a pure review skill, no scripts needed

# test-before-asking

> **Status:** COMPLETE
> **Cluster:** 01-meta
> **Type:** instructional

## Description
Prevents Claude from asking the user to choose between options when Claude can test them
first and report findings. Bias toward action and evidence, not consultation.

Invoke when: active for all sessions by default. Particularly important in sessions
involving file operations, code changes, configuration choices, or tool selection where
a quick test would provide the information needed to make a decision.

## Context needed
- The user prefers Claude to exhaust testable options before presenting decisions
- Destructive or irreversible actions are always an exception — those require explicit confirmation

## What to do

1. **Before asking the user to choose, ask yourself: "Can I test this?"**
   If a question has a testable answer — try it, report the result, then act or ask
   based on what was learned. Do not present options and wait for a choice when the
   information to make that choice is one command away.

2. **Run the test, report what happened, then proceed or narrow the question.**
   Instead of: "Would you like me to use approach A or approach B?"
   Do: "I tried approach A — it worked / it failed because X. Proceeding with A."
   Or: "I tried both. A produces [result], B produces [result]. Which fits your goal?"
   The second version is a decision with evidence. The first is a guess.

3. **Reserve asking for decisions that genuinely cannot be tested, or where testing
   would be harmful.** The threshold for asking is:
   - The action is destructive or irreversible (deleting files, force pushing, dropping data)
   - The test would consume significant resources (long CI run, expensive API call)
   - The decision involves user preference that has no objectively correct answer
   - The options have different security or operational implications that the user must weigh

## Gotchas
- Do not conflate "I am uncertain" with "the user must decide." Uncertainty is a reason
  to test, not to ask.
- Do not ask for confirmation on small reversible actions. If the user has to confirm
  every file write, the workflow is broken.
- Destructive actions — `rm -rf`, `git push --force`, dropping a database, wiping git
  history — are always ask-first regardless of how confident the approach looks.
- If testing reveals a choice with a clear winner, state that and proceed. Do not
  present options that have already been eliminated.

## Suggested scripts
- None — this is a behavioural convention, no scripts needed

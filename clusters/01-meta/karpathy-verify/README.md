# karpathy-verify

> **Cluster:** 01-meta | **Status:** complete | **Added:** 2026-06-11

Layer 2 of the Karpathy framework. Evaluates output quality before accepting it by
running it through a second opinion (different model, role, or fresh pass) and grounding
claims in external signal (test execution, source checks, live system state). Feedback
loops improve output quality 2–3× per invocation.

---

## What this skill does

1. **Defines evaluation criteria upfront** — before evaluating, not after; prevents
   post-hoc rationalisation of whatever the AI produced
2. **Second opinion** — routes output to a different evaluator to catch what the first
   pass missed (different model, specialist role, or fresh context)
3. **External signal** — grounds claims in reality by testing them; the step most
   commonly skipped and most likely to catch drift

---

## When to use it

- Output exists and needs quality evaluation before you accept it
- Output makes specific factual claims that can be tested
- Before shipping, publishing, submitting, or deploying anything
- Previous similar work had errors you only caught later

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/01-meta/karpathy-verify ~/.claude/skills/
```

---

## Quick reference

```
# If you have criteria from karpathy-spec:
Invoke karpathy-verify on [output].
Criteria: [paste from karpathy-spec Phase 3]

# If you don't have criteria yet:
Invoke karpathy-verify on [output].
[karpathy-verify will define criteria in Phase 1 before evaluating]
```

---

## Pairs with

- `karpathy-spec` — runs before verify; produces the criteria used in Phase 1
- `karpathy-environment` — captures evaluation patterns that worked well into reusable skills
- `karpathy-framework` — umbrella entry point if unsure which layer to start with

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [ ] Ship: copy to `~/.claude/skills/karpathy-verify/`

# write

> **Cluster:** 02-comms | **Status:** complete | **Merged:** 2026-10-13 from `write-tone`, `write-human`, `write-exec`

Improves a draft in one of three modes: **tone check** (annotation only), **humanise**
(rewrite in the owner's style), or **exec** (translate for CISO, C-suite, or board).
See `SKILL.md` for each mode's rules and output format.

---

## Invocation

```
/write
Mode: tone check
<draft>
```

If no mode is given, the skill infers it from the request or asks.

---

## Roadmap

- [x] Merged from three single-mode skills

# edr-test-loop

> **Cluster:** 08-offsec | **Status:** complete | **Added:** 2026-05-24

Structured 5-step loop for iterating payloads against EDR: baseline → detect →
identify signal → form single hypothesis → change → retest. Enforces iteration
logging to prevent repeated cycles of confusion across sessions.

---

## What this skill does

Replaces unstructured "change things until it stops alerting" with a hypothesis-driven
loop. Each iteration records the detection signal, the hypothesis, the single change
made, and the result. Static and dynamic detections have separate fix checklists.

---

## When to use it

- Testing a new payload against a lab EDR
- Diagnosing a detection that fired during an engagement (post-mortem)
- Iterating on sleep obfuscation or syscall strategy
- Preparing a payload for a specific EDR product prior to deployment

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/08-offsec/edr-test-loop ~/.claude/skills/
```

---

## Invocation

```
/edr-test-loop
EDR: CrowdStrike Falcon 7.14, user-mode hooks + ETW
Detection: CreateRemoteThread alert on svchost.exe injection
```

---

## Workflow

```
Clean VM snapshot
        ↓
Run payload → capture full detection event
        ↓
Identify signal (static string / YARA / API hook / ETW / memory scan)
        ↓
Form one hypothesis → name the change
        ↓
Apply single change → rebuild
        ↓
Revert to snapshot → retest
        ↓
Append to run log
        ↓
Repeat until no detection → test sleep/memory-at-rest separately
```

---

## What it won't do

- Automate the EDR detection — human analysis of the alert is required
- Cover Linux/macOS EDR products
- Replace a proper red team methodology — this is a development-phase tool

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [x] Write `run-log.sh` (appends dated entry to `edr-test-log.md`)
- [x] Write `static-audit.sh` (strings + entropy + YARA pre-flight)
- [ ] Add AMSI bypass sub-loop
- [ ] Add ETW patching considerations and risk notes
- [ ] Add memory-at-rest (sleep mask) test sub-loop

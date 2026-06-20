# c2-integration-checklist

> **Cluster:** 08-offsec | **Status:** complete | **Added:** 2026-05-24

Pre-flight checklist for integrating a custom implant or BOF with Cobalt Strike or
Havoc: framework-side integration verification, sleep mask configuration, malleable
C2 profile OPSEC audit, kill date / working hours, and a lab validation sequence
before any engagement deployment.

---

## What this skill does

Prevents the common failure modes of operational C2 deployment: wrong `beacon.h`
version, no sleep obfuscation, default SSL certificate, no kill date, and skipping
lab validation before the first engagement use. Each of the 5 steps has a concrete
checkbox list that can be worked through before deployment.

---

## When to use it

- Integrating a new BOF or post-ex module with a C2 framework
- Preparing a payload for a new engagement (especially after the CS server was updated)
- Reviewing a C2 profile before use
- Post-engagement cleanup verification

---

## Installation

### Claude Code

```bash
cp -r clusters/08-offsec/c2-integration-checklist ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#c2-integration-checklist
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.


---

## Invocation

```
/c2-integration-checklist
Framework: Cobalt Strike 4.10
Implant: custom reflective DLL, HTTPS listener
EDR in target: CrowdStrike Falcon
Engagement end: 2026-06-14
```

---

## Workflow

```
Framework integration verified (header version, COFF arch, aggressor pack order)
        ↓
Sleep mask configured and tested (RWX → RW at sleep, memory scan clean)
        ↓
Malleable profile / listener OPSEC audited (UA, URIs, cert, staging off)
        ↓
Kill date set to engagement end date
        ↓
Lab validation sequence completed (full post-ex plan tested in lab)
        ↓
Deploy to engagement
```

---

## What it won't do

- Write the malleable C2 profile — it audits an existing one
- Configure domain fronting — CDN-specific and requires manual setup
- Replace engagement planning — this is a deployment-gate checklist, not a full
  operational plan

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [x] Write `c2-preflight.sh` (c2lint + cert expiry + OPSEC summary)
- [x] Add Havoc-specific demon module integration details
- [x] Add DNS listener OPSEC checklist (TTL, NS delegation, authoritative zone config)
- [x] Add post-engagement cleanup checklist (artifact removal, implant termination confirmation)

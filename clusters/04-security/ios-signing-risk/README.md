# ios-signing-risk

> **Cluster:** 04-security | **Status:** complete | **Added:** 2026-05-24

Structured analysis framework for iOS signing risk scenarios. Covers IPA integrity,
certificate authenticity and timing, OTA manifest verification, and re-sign/redeploy
sequencing. Enforces the hard rule: redeploy before revoking, never reversed.

---

## What this skill does

Takes an iOS signing artefact or scenario and walks through the relevant technical chain
for one of three claim types: integrity (was the IPA tampered with?), authenticity (was
it signed with a legitimate key?), or timing (was it signed before or after revocation?).

Always states clearly what evidence is needed, what evidence is available, and produces
a finding of confirmed safe / confirmed compromised / inconclusive with what would resolve it.

---

## When to use it

- A certificate anomaly has been flagged and you need to assess whether IPAs signed with it are affected
- You need to verify an OTA manifest and the IPA it references
- You are planning a re-sign/redeploy/revoke sequence and need the correct order confirmed
- You are investigating whether a device received a compromised build before revocation propagated
- Any iOS signing question where the answer matters for incident response or forensics

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/04-security/ios-signing-risk ~/.claude/skills/
```

No hook wiring required.

---

## How to invoke it in a session

```
/ios-signing-risk
Scenario: [describe the signing concern]
Artefacts available: [IPA hash, certificate serial, OTA manifest URL, etc.]
Question: [was this IPA signed before the revocation event?]
```

Or inline during an investigation:

```
Assess this signing risk: certificate serial XYZ was revoked at 14:00 UTC.
The IPA in question has this codesign output: [paste]
Was it signed before the revocation?
```

---

## Workflow

```
User describes scenario + provides available artefacts
               ↓
Identify claim type: integrity / authenticity / timing
               ↓
State what evidence is needed — confirm what is available
(If missing, state what would resolve the question)
               ↓
Walk technical chain for claim type:
  IPA integrity → hash, codesign, entitlements
  Certificate → serial, revocation timestamp, signing timestamp
  OTA manifest → URL, bundle ID, version, signing identity
  Timing → signing timestamp vs revocation timestamp, OCSP lag
               ↓
State finding: confirmed safe / confirmed compromised / inconclusive
               ↓
If re-sign/redeploy needed → steps in explicit order (redeploy before revoke)
```

---

## The non-negotiable sequencing rule

```
1. Obtain valid cert + provisioning profile
2. Re-sign all affected artefacts
3. Redeploy to all environments
4. Confirm successful deployment  ← must be confirmed before step 5
5. Revoke the compromised certificate
6. MDM push to force manifest refresh
```

Revoking before step 4 breaks live deployments. This rule applies in all scenarios.

---

## What it will NOT do

- Recommend revocation before redeployment is confirmed
- Treat an OCSP "good" response as definitive during an active compromise
- Produce a finding without stating what evidence was used (or what is missing)

---

## Roadmap

- [x] SKILL.md written and validated
- [x] Write `verify-ipa.sh` (hash + codesign verification)
- [x] Write `check-manifest.sh` (OTA manifest parse and verification)
- [ ] Add Apple Developer Portal log retention window specifics
- [ ] Test on a real IPA integrity scenario
- [x] Ship: copy to `~/.claude/skills/ios-signing-risk/`

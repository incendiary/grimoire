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

### Claude Code

```bash
cp -r clusters/04-security/ios-signing-risk ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#ios-signing-risk
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.



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

## Apple Developer Portal — log retention windows

These retention windows apply to the Apple-hosted audit surfaces. Evidence must be
collected within these windows before it expires. Always confirm at the time of the
incident — Apple has changed retention policies without public notice.

| Log source | Approximate retention | Access path | Notes |
|---|---|---|---|
| **Certificates, Identifiers & Profiles — Activity** | ~90 days (observed; not formally documented) | developer.apple.com → Account → Activity tab | Lists certificate creation, revocation, profile changes, member invitations. Export CSV immediately — no bulk API. |
| **App Store Connect — Activity log** | ~60 days (observed; not formally documented) | appstoreconnect.apple.com → Users and Access → Activity | Shows who uploaded a build, created a TestFlight group, invited a user. Exportable per-app. |
| **TestFlight — Build history** | Retained until the build expires (90 days from upload, or until the app version is removed) | appstoreconnect.apple.com → TestFlight | Build metadata (uploader, upload timestamp, version) available while the build is active. Download build expiry date from the TestFlight console before investigating. |
| **Apple Business Manager / Apple School Manager — Audit log** | ~30 days | business.apple.com → Settings → Audit | MDM enrollment events, managed Apple ID creation, role changes. 30-day window is short — treat as immediate-collection target. |
| **APNS logs** | Not retained by Apple | N/A | Push notification delivery is not logged by Apple. Evidence must come from your own server logs or MDM audit trail. |
| **App Store Review — communications** | Indefinite (in Resolution Center) | appstoreconnect.apple.com → Resolution Center | App review correspondence is retained. Not time-critical. |
| **HSM access logs (third-party HSM, e.g. AWS CloudHSM, Thales)** | Depends on your HSM provider and retention policy | Provider console or SIEM integration | Typically 90 days in CloudWatch (AWS CloudHSM); extend before investigating. |

**Immediate-collection targets (collect within the first hour of a signing incident):**
1. Apple Developer Portal Activity tab → CSV export
2. App Store Connect Activity → export for all affected apps
3. TestFlight build upload metadata (uploader, timestamp, source IP if visible)
4. Apple Business Manager Audit log → export (30-day window)
5. Your CI/CD secret store — access log for the signing certificate/key secret

**What Apple does NOT provide:**
- Source IP for portal activity (activity log shows user identity, not IP)
- Certificate private key access logs (Apple does not hold your private key)
- Build binary content — you must retain the IPA from your own storage

---

## Roadmap

- [x] SKILL.md written and validated
- [x] Write `verify-ipa.sh` (hash + codesign verification)
- [x] Write `check-manifest.sh` (OTA manifest parse and verification)
- [x] Add Apple Developer Portal log retention window specifics
- [ ] Test on a real IPA integrity scenario
- [x] Ship: copy to `~/.claude/skills/ios-signing-risk/`

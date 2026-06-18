# incident-ask-builder

> **Cluster:** 03-incident | **Status:** complete | **Added:** 2026-05-24

When an incident breaks, the first bottleneck is usually "who do I ask for what, by when?"
This skill converts an incident description into a structured evidence-collection checklist
grouped by owner, with retention-risk flags and Legal sign-off markers built in.

---

## What this skill does

Takes an incident description, urgency level, and list of available stakeholder groups,
then produces a numbered checklist of asks. Each ask specifies:
- What exactly is needed (specific log type, time range, format)
- Who owns it (named team or role)
- Urgency tier (Immediate / 24h / 72h)
- Retention risk flag if evidence may expire
- Legal sign-off flag if the ask touches personal or HR data

Output is grouped by owner so each block can be forwarded directly to that team without
redrafting.

---

## When to use it

- P1: an active incident is being triaged and you need to coordinate evidence collection fast
- P2: an investigation is underway and you need a structured ask list for the investigation team
- P3: post-incident review requiring formal evidence documentation
- Any time you need to write an evidence request email or Slack message to multiple teams

---

## Installation

### Claude Code

```bash
cp -r clusters/03-incident/incident-ask-builder ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#incident-ask-builder
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.



---

## How to invoke it in a session

```
/incident-ask-builder
Incident: [describe what happened and what is known]
Urgency: P1 / P2 / P3
Available teams: SOC, MDM team, Apple Business Manager admin, AWS, Legal
```

Or inline:

```
Build me an evidence collection ask list for this incident:
[describe incident]
Available teams: [list teams]
```

---

## Workflow

```
User describes incident + urgency + available teams
                  ↓
Identify relevant evidence categories for incident type
                  ↓
Flag retention risks first (log windows, HSM logs, Developer Portal)
                  ↓
Build ask per category: what / who / format / urgency
                  ↓
Flag Legal sign-off requirements (personal data, comms, HR)
                  ↓
Output grouped by owner (so each block is forwardable)
```

---

## What it will NOT do

- Assume teams exist that were not mentioned
- Produce asks for evidence with unknown retention without flagging the risk
- Issue Legal or HR asks without marking them as requiring sign-off
- Prioritise completeness over urgency — retention risks always come first

---

## Incident type coverage

| Incident type | Key evidence sources |
|---------------|---------------------|
| iOS signing compromise | Developer Portal logs, HSM access logs, IPA hashes, OTA manifests |
| Credential theft | AuthN logs, EDR telemetry, network logs, cloud audit trails |
| Insider threat | MDM logs, comms records (Legal required), HR data (Legal required) |
| AWS compromise | CloudTrail, IAM logs, VPC flow logs, GuardDuty findings |
| Endpoint compromise | Unified Log (macOS), Event Log (Windows), EDR telemetry |

---

## Worked examples

### iOS signing compromise — P1

**Input to skill:**
```
/incident-ask-builder
Incident: Unexpected IPA pushed to TestFlight at 03:14 UTC. Build was not in our
  CI pipeline. Possible signing key compromise or Apple ID takeover.
Urgency: P1
Available teams: iOS team, DevOps (CI/CD), Apple Business Manager admin, Legal/Privacy
```

**Output (grouped by owner):**

---
**Apple Business Manager admin** — *Immediate*
1. Export full Apple Developer Portal activity log for the last 72 hours.
   Format: CSV export from Certificates, Identifiers & Profiles → Activity.
   ⚠️ Retention risk: Apple portal logs are not retained indefinitely — export now.
2. List all signing certificates currently active (distribution + development).
   Capture creation date, expiry, and the Apple ID that created each.
3. Identify which Apple ID submitted the unsigned build at 03:14 UTC (App Store Connect audit log).

**DevOps (CI/CD)** — *Immediate*
4. Pull CI build logs for the past 48 hours. Confirm no build ran that produced
   the suspicious IPA. Format: raw log archive (zip).
5. Provide the last rotation date and storage location for the `APPLE_DISTRIBUTION_CERT`
   secret in the CI secret store. Confirm whether it is HSM-backed or plaintext.
   ⚠️ Retention risk: CI log retention may be 30 days — confirm before assuming availability.

**iOS team** — *Immediate*
6. Provide the SHA-256 hash and `codesign -dvvv` output for the suspicious IPA.
   Compare against the last known-good build hash from your release records.

**Legal/Privacy** — *Sign-off required before proceeding*
7. Advise on obligations under App Store Developer Agreement regarding potential
   unauthorised distribution. Confirm whether regulatory notification is required.

---

### AWS credential compromise — P2

**Input to skill:**
```
/incident-ask-builder
Incident: GuardDuty fired UnauthorizedAccess:IAMUser/TorClient for user svc-deploy.
  No legitimate operations were scheduled at that time. Possible long-term access key leak.
Urgency: P2
Available teams: AWS Platform, SOC, Legal
```

**Output (grouped by owner):**

---
**AWS Platform** — *24h*
1. Pull CloudTrail logs for `svc-deploy` for the last 30 days.
   Scope: all regions, all event types. Format: JSON export from CloudTrail Lake or S3.
   ⚠️ Retention risk: CloudTrail default retention is 90 days in S3 — confirm log
   bucket exists before assuming logs are available.
2. List all active access keys for `svc-deploy`. Include creation date, last used date,
   and last used region.
3. Identify all API calls made in the GuardDuty alert timeframe (UTC window ±2h).
   Flag any: `s3:GetObject`, `iam:*`, `sts:AssumeRole`, `secretsmanager:GetSecretValue`.
4. Confirm whether the access key was rotated after the GuardDuty finding fired.
   If not, revoke it now and document the revocation timestamp.

**SOC** — *24h*
5. Pull VPC flow logs for the source IP in the GuardDuty alert.
   Check whether the IP appears in any other GuardDuty findings in the last 90 days.

**Legal** — *72h*
6. Advise on whether the potential data access event requires breach notification
   assessment under applicable regulations.

---

## Roadmap

- [x] SKILL.md written and validated
- [x] Write `incident-ask-template.md` for common incident types
- [x] Add worked example for common incident types
- [x] Add HSM/Developer Portal retention window specifics
- [ ] Test on 2 real incident scenarios
- [x] Ship: copy to `~/.claude/skills/incident-ask-builder/`

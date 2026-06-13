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

## Roadmap

- [x] SKILL.md written and validated
- [x] Write `incident-ask-template.md` for common incident types
- [ ] Add worked example for common incident types
- [x] Add HSM/Developer Portal retention window specifics
- [ ] Test on 2 real incident scenarios
- [x] Ship: copy to `~/.claude/skills/incident-ask-builder/`

# incident-ask-builder

> **Status:** COMPLETE
> **Type:** instructional
> **Cluster:** 03-incident

## Description
Given an incident description, produce a precise "what we need from whom" checklist
with named owners, urgency tier, format requirements, and retention risk flags.

Invoke when: the user describes a security incident or investigation and needs to
coordinate evidence collection. Trigger phrases: "what do we need to ask", "who do I
need to contact", "help me coordinate evidence collection for this incident".

## Context needed
- Incident description: what happened, which systems are involved, what is already known
- Urgency level: P1 (active breach or live threat), P2 (investigation, threat contained),
  or P3 (post-incident review)
- Known stakeholder groups available (e.g. SOC, MDM team, Apple Business Manager admin,
  AWS team, HR, Legal, cloud provider)

## What to do

1. **Identify all evidence categories relevant to the incident type.** Common categories:
   endpoint logs, network logs, authentication logs, cloud audit logs (CloudTrail, Azure
   Monitor), MDM logs, application logs, physical access records, communication records
   (email headers, Slack export), signing infrastructure logs (HSM access, CI/CD).
   For iOS signing incidents specifically: Developer Portal logs, IPA hashes, OTA manifest
   URLs, provisioning profile history.

2. **For each relevant evidence category, state:**
   - What specifically is needed (not "endpoint logs" — "macOS Unified Log from the
     affected device covering the 24h window from [timestamp]")
   - Who owns it (named team or role, not generic "the IT team")
   - The format to request it in (export format, time range, log level)
   - Urgency tier: Immediate (before any system changes), Within 24h, Within 72h

3. **Flag time-sensitive evidence at the top.** Log retention windows are the first
   question in any investigation. If a 30-day retention window applies and the event
   was 28 days ago, that ask is critical. State the retention risk explicitly:
   "RETENTION RISK: [source] retains logs for [N] days. Event occurred [N-2] days ago.
   Request by [date/time] or evidence is lost."

4. **Flag asks that require Legal or HR sign-off before proceeding.** Personal device
   data, communication records, HR systems, and physical access records almost always
   require explicit Legal authorisation. Mark these clearly:
   "LEGAL SIGN-OFF REQUIRED before requesting."

5. **Output as a numbered checklist grouped by owner, not by evidence type.** Each
   owner gets one block of asks so the list can be forwarded directly to that team.

## Gotchas
- Log retention is always the first question. Never assume logs are available — confirm
  the retention window before building the rest of the ask list.
- Do not assume which teams exist. Build the ask list from the stakeholder groups the
  user has confirmed are available. Do not add teams they did not mention.
- HR records, personal device data, and private communication records require Legal
  involvement regardless of urgency. Always flag these explicitly, never omit the caveat.
- Some evidence (HSM access logs, Apple Developer Portal audit trails) has very limited
  retention. Flag these before anything else.

## Suggested scripts
- `incident-ask-template.md` — a per-owner ask block template for common incident types

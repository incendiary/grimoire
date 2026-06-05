# Incident Evidence Ask — [Investigation Name]

> **Reference:** [INC-YYYY-NNN]
> **Urgency:** [P1 — Active threat / P2 — Contained, investigating / P3 — Post-incident review]
> **Coordinator:** [Name / Team]
> **Date (UTC):** [YYYY-MM-DD]

---

## ⚠ Retention Risk — Act First

List any time-sensitive asks here before the full request blocks below.

| Evidence source | Retention window | Event date | Deadline to request |
|----------------|-----------------|------------|-------------------|
| [log source] | [N days] | YYYY-MM-DD | **YYYY-MM-DD HH:MM UTC** |

---

## ⚠ Legal / HR Sign-Off Required Before Requesting

The following asks require explicit Legal authorisation before proceeding.
Do not submit these requests until sign-off is confirmed.

- [ ] [evidence type] — [reason Legal involvement is required]
- [ ] [evidence type] — [reason]

---

## Asks by Owner

---

### Owner: [Team / Role — e.g. SOC / Cloud Platform / MDM Admin]

**Contact:** [name or distribution list]
**Urgency:** [Immediate / Within 24h / Within 72h]

| # | What we need | Format / scope | Deadline |
|---|-------------|---------------|---------|
| 1 | [specific evidence — not "endpoint logs" but "macOS Unified Log from device [serial], 24h window from [timestamp]"] | [export format, time range, log level] | [date/time UTC] |
| 2 | | | |

---

### Owner: [Team / Role — e.g. Apple Developer Portal Admin]

**Contact:** [name or distribution list]
**Urgency:** [Immediate / Within 24h / Within 72h]

> **Note — Apple Developer Portal / HSM retention:**
> Developer Portal audit logs have limited retention (~90 days).
> HSM access logs vary by provider — confirm retention window on first contact.

| # | What we need | Format / scope | Deadline |
|---|-------------|---------------|---------|
| 1 | Developer Portal audit log export for Team ID `[XXXXXXXXXX]`, covering [date range] | CSV export, all event types | [date/time UTC] |
| 2 | Provisioning profile history for bundle ID `[com.example.app]` | Full history including revocations | [date/time UTC] |
| 3 | IPA hash confirmation for build `[version/build number]` distributed via [channel] | SHA-256 of the signed IPA | [date/time UTC] |

---

### Owner: [Team / Role — e.g. AWS / Cloud Account Owner]

**Contact:** [name or distribution list]
**Urgency:** [Immediate / Within 24h / Within 72h]

> **CloudTrail default retention:** 90 days. Check if a trail is configured with longer S3 retention.

| # | What we need | Format / scope | Deadline |
|---|-------------|---------------|---------|
| 1 | CloudTrail export for account `[accountId]`, region `[region]`, covering [date range] | JSON export from S3 trail or Console, all event types | [date/time UTC] |
| 2 | IAM credential report for role/user `[name]` — login history and access key usage | Console export or CLI: `aws iam get-credential-report` | [date/time UTC] |

---

### Owner: [Team / Role — e.g. MDM / Device Management]

**Contact:** [name or distribution list]
**Urgency:** [Immediate / Within 24h / Within 72h]

| # | What we need | Format / scope | Deadline |
|---|-------------|---------------|---------|
| 1 | MDM log for device serial `[serial]`, covering [date range] | Full log export, all event types | [date/time UTC] |
| 2 | Enrolment and de-enrolment history for the device | Date, user, policy profile applied | [date/time UTC] |

---

### Owner: [Team / Role — add more blocks as needed]

**Contact:**
**Urgency:**

| # | What we need | Format / scope | Deadline |
|---|-------------|---------------|---------|
| 1 | | | |

---

## Evidence Tracker

Update this table as asks are fulfilled.

| # | Owner | Evidence | Status | Received (UTC) |
|---|-------|---------|--------|---------------|
| 1 | [team] | [description] | [Pending / Received / Escalated] | |
| 2 | | | | |

---

*Template: incident-ask-template.md — populate per incident, one owner block per team*

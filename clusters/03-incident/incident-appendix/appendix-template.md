# Technical Appendix — [Investigation Name]

> **Document classification:** [CONFIDENTIAL / INTERNAL / TLP:AMBER]
> **Investigation reference:** [INC-YYYY-NNN]
> **Prepared by:** [Name / Team]
> **Date (UTC):** [YYYY-MM-DD]
> **Status:** [DRAFT / FINAL]

---

## A. Timeline

All timestamps in UTC. Source column references the log type or tool used.

| UTC Timestamp | Event | Source | Confirmed? |
|---------------|-------|--------|-----------|
| YYYY-MM-DD HH:MM:SS | [event description] | [log type / tool] | ✓ Confirmed |
| YYYY-MM-DD HH:MM:SS | [event description] | [log type / tool] | [ESTIMATED] |
| YYYY-MM-DD HH:MM:SS | [event description] | [log type / tool] | [UNCONFIRMED] |

> **Note:** Mark unconfirmed events with `[ESTIMATED]` (inferred from context) or
> `[UNCONFIRMED]` (not yet corroborated by a second source).

---

## B. Indicators of Compromise

### File Hashes

| Filename | SHA-256 | First Seen (UTC) | Notes |
|----------|---------|-----------------|-------|
| [filename] | `[sha256]` | YYYY-MM-DD HH:MM | [context] |

### Network Indicators

| Type | Value | First Seen (UTC) | Notes |
|------|-------|-----------------|-------|
| IP address | `[ip]` | YYYY-MM-DD HH:MM | [context] |
| Hostname | `[hostname]` | YYYY-MM-DD HH:MM | [context] |
| Domain | `[domain]` | YYYY-MM-DD HH:MM | [context] |
| URL | `[url]` | YYYY-MM-DD HH:MM | [context] |

### Code Signing and Certificate Indicators

| Type | Value | Notes |
|------|-------|-------|
| Apple Developer Team ID | `[XXXXXXXXXX]` | [app / org name] |
| Apple Developer ID (identity) | `[Developer ID Application: ...]` | |
| Provisioning profile UUID | `[uuid]` | [bundle ID, expiry] |
| Certificate serial | `[serial]` | [issuer, validity window] |
| Certificate SHA-1 fingerprint | `[fingerprint]` | |

### Account and Credential Indicators

| Type | Value | Notes |
|------|-------|-------|
| User account | `[username / email]` | [system, role] |
| Token / API key (partial) | `[prefix]...` | [service, scope] |
| Service account | `[account name]` | [cloud provider, permissions] |

---

## C. Evidence Collected

| # | Item | Source | Collected by | Date/Time (UTC) | Integrity |
|---|------|--------|-------------|-----------------|-----------|
| 1 | [description] | [log type / system] | [name / role] | YYYY-MM-DD HH:MM | SHA-256: `[hash]` / N/A |
| 2 | [description] | [log type / system] | [name / role] | YYYY-MM-DD HH:MM | SHA-256: `[hash]` / N/A |

> **AWS CloudTrail citation format:**
> `CloudTrail: event <eventName>, account <accountId>, region <region>, eventTime <UTC>, requestId <requestId>`
>
> **Example:**
> `CloudTrail: event AssumeRole, account 123456789012, region eu-west-1, eventTime 2026-01-15T14:23:11Z, requestId abc1234-5678`

---

## D. Gaps and Unknowns

| # | Gap | Reason | Evidence that would resolve it |
|---|-----|--------|-------------------------------|
| 1 | [what is unknown] | [why it could not be confirmed — log retention expired, access not granted, etc.] | [what artefact / log would answer it] |
| 2 | | | |

---

## E. Assumptions

| # | Assumption | Basis | Risk if wrong |
|---|-----------|-------|--------------|
| 1 | [statement treated as true for this investigation] | [circumstantial / inferred / expert opinion] | [consequence if assumption is incorrect] |
| 2 | | | |

---

## F. Remediation Actions

### Completed

| # | Action | Owner | Completed (UTC) | Notes |
|---|--------|-------|----------------|-------|
| 1 | [action taken] | [team / name] | YYYY-MM-DD HH:MM | |

### Proposed / In Progress

| # | Action | Owner | Target date | Status | Notes |
|---|--------|-------|------------|--------|-------|
| 1 | [action] | [team / name] | YYYY-MM-DD | [Pending / In Progress] | |

---

*End of Technical Appendix*

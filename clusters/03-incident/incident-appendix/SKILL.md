# incident-appendix

> **Status:** COMPLETE
> **Type:** instructional
> **Cluster:** 03-incident

## Description
Structure raw evidence, indicators, timeline, gaps, and assumptions into a formal
technical appendix suitable to attach behind an executive summary.

Invoke when: the user has collected evidence from an investigation and needs to
document it formally. Trigger phrases: "write up the technical appendix", "document
the evidence", "format this for the incident report", "structure the technical detail".

## Context needed
- Evidence collected: logs, screenshots, hash values, certificate details, timestamps
- Known timeline of events (even if partial or estimated)
- Gaps: what is unknown or unconfirmed
- Any assumptions made during the investigation
- Remediation steps taken or planned

## What to do

1. **Structure the appendix with these sections in this order:**

   **A. Timeline**
   - Chronological, UTC timestamps only
   - Each event on its own line: `[UTC timestamp] [event] [source]`
   - Note the source of each event (log type, tool, witness)
   - Mark unconfirmed events clearly: `[ESTIMATED]` or `[UNCONFIRMED]`

   **B. Indicators of Compromise**
   - File hashes (SHA-256 preferred)
   - IP addresses and hostnames
   - Domains and URLs
   - Certificate serials and fingerprints
   - Signing identities (Apple Developer IDs, code signing certificates)
   - User accounts or tokens involved

   **C. Evidence Collected**
   Table format:
   | # | Item | Source | Collected by | Date/time (UTC) | Integrity |
   |---|------|--------|-------------|-----------------|-----------|
   Include hash or checksum in the Integrity column where available.

   **D. Gaps and Unknowns**
   - What could not be confirmed and why
   - Which log sources were unavailable or expired
   - What additional evidence would resolve each gap

   **E. Assumptions**
   - What was treated as true for the purpose of this investigation
   - Basis for each assumption (circumstantial, inferred, expert opinion)

   **F. Remediation Actions**
   Table format:
   | Action | Owner | Status | Target date | Notes |
   Separate completed actions from proposed ones.

2. **Use tables for structured data. Use numbered lists for sequential steps.**
   Prose for narrative context only.

3. **Every factual claim must reference its evidence source** in parentheses or
   as a footnote: "(CloudTrail event ID: abc123)" or "(Source: MDM log, device XYZ)".

## Gotchas
- Clearly distinguish confirmed facts from assumptions. Mixing them is a liability
  in a formal investigation document — assumptions stated as facts will be challenged.
- UTC timestamps only. Local time creates ambiguity in multi-region incidents and
  during daylight saving transitions.
- Gaps are honest documentation, not weaknesses. An appendix that lists gaps
  is stronger than one that pretends to be complete. Do not minimise or omit them.
- If the user has not provided a gap list, ask before producing the appendix —
  do not omit the section.

## Suggested scripts
- `appendix-template.md` — the full section structure as a fillable template

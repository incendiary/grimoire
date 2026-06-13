# ios-signing-risk

> **Status:** COMPLETE
> **Type:** instructional
> **Cluster:** 04-security

## Description
Analyse iOS signing risk scenarios: IPA integrity, Apple developer certificate validity,
OTA manifest verification, revocation timing, and redeployment sequencing.

Invoke when: the user describes an iOS signing concern, presents signing artefacts for
review, or is working through a certificate revocation or compromise scenario. Trigger
phrases: "signing risk", "IPA integrity", "OTA manifest", "certificate revocation",
"re-sign and redeploy", "was this signed before the revocation".

## Context needed
- The artefact or scenario under review: IPA file, OTA manifest URL, certificate serial
  or fingerprint, or signing timestamp
- The concern: tampering, compromise, expiry, revocation timing, or redeployment sequencing
- Any available evidence: MDM logs, CI/CD signing logs, Apple Developer Portal records,
  HSM access logs

## What to do

1. **Identify the claim being assessed.** One of three types:
   - **Integrity** — was the IPA tampered with after it was signed?
   - **Authenticity** — was this signed with a legitimate, authorised key?
   - **Timing** — was this signed before or after a revocation event?
   State which claim you are assessing before proceeding.

2. **State what evidence is needed to answer the claim and whether the user has
   provided it.** Do not proceed to analysis without confirming what evidence is
   available. If evidence is missing, state what it would take to answer the question.

3. **Walk through the relevant technical chain for the claim type:**

   *For IPA integrity:*
   - SHA-256 hash of the IPA file
   - Code signature verification: `codesign -dv --verbose=4 <ipa>` after unzipping
   - Entitlements check: confirm entitlements match the provisioning profile
   - Compare hash against known-good value from CI/CD pipeline if available

   *For certificate validity and authenticity:*
   - Serial number lookup in the Apple Developer Portal
   - Revocation timestamp from the portal (or OCSP response)
   - Check signing timestamp against certificate validity window
   - Verify the signing identity matches the expected Developer ID

   *For OTA manifest verification:*
   - Manifest URL resolves and returns valid XML
   - `bundle-identifier` matches the expected bundle ID
   - `bundle-version` matches the expected build
   - IPA URL in the manifest resolves to the correct IPA
   - `display-image` and `full-size-image` URLs accessible (optional but expected)
   - Signing identity in the manifest matches the IPA's actual signing identity

   *For revocation timing:*
   - Compare signing timestamp (from code signature) against revocation timestamp
   - Note: Apple OCSP propagation delay can be minutes to hours. OCSP green is not
     definitive during an active incident.
   - Check whether the device had an OCSP response cached at the time of install

4. **State a clear finding:** confirmed safe, confirmed compromised, or inconclusive.
   If inconclusive, state exactly what additional evidence would resolve it.

5. **If a re-sign/redeploy sequence is needed, output the steps in explicit order:**
   1. Obtain a valid certificate and provisioning profile (confirm these exist first)
   2. Re-sign all affected artefacts
   3. Redeploy to all affected environments
   4. Confirm successful deployment
   5. Revoke the compromised certificate
   6. Issue MDM push to force OTA manifest refresh on affected devices
   Never include revocation before step 4 is confirmed.

## Gotchas
- OCSP propagation delay: a certificate may appear valid for a period after revocation.
  Do not treat an OCSP "good" response as definitive during an active compromise incident.
- Resigning requires a valid certificate and provisioning profile. Confirm these exist
  before recommending a resign workflow — if both are compromised, the path changes.
- OTA manifests cache on devices. Successful redeployment may not reach affected devices
  without an MDM push to force a manifest refresh.
- SHA-256 the IPA before and after any operation. Changes in hash indicate tampering
  or an uncontrolled modification.
- Apple Developer Portal audit logs have limited retention. Flag this as a time-sensitive
  evidence source in any investigation.

## Suggested scripts
- `verify-ipa.sh` — hash and codesign verification steps for a given IPA file
- `check-manifest.sh` — curl and parse an OTA manifest, verify all fields and URLs

# c2-integration-checklist

> **Status:** COMPLETE
> **Cluster:** 08-offsec

## Description
Pre-flight checklist before deploying a custom implant or BOF against Cobalt Strike
or Havoc. Covers framework integration, sleep mask and memory obfuscation, malleable
C2 profile OPSEC, and lab validation steps before engagement deployment.

Invoke when: integrating a new implant, BOF, or post-ex module with a C2 framework;
or preparing a previously tested payload for live engagement deployment.

## Context needed
- C2 framework (Cobalt Strike version, Havoc branch/commit)
- Implant type: BOF (inline or fork-and-run), reflective DLL, full beacon replacement
- Listener type (HTTP/HTTPS/DNS) and malleable profile or Havoc listener config
- Target environment EDR tier (informs sleep mask and comms profile requirements)

## What to do

1. **Verify framework-side integration before touching operational infrastructure.**
   Test the full execution path in a lab — framework → listener → implant → callback —
   before the implant touches any engagement target.

   **Cobalt Strike BOF checklist:**
   ```
   □ beacon.h version matches the Cobalt Strike server version
   □ COFF compiled for correct architecture (x64 for 64-bit Beacons)
   □ Aggressor script argument packing matches go() parse order
   □ inline-execute test in a lab Beacon returns expected output
   □ Error path tested: does the BOF return cleanly on failure (no Beacon crash)?
   □ fork-and-run: spawnto binary set to a legitimate signed binary
   ```

   **Havoc demon module checklist:**
   ```
   □ Module compiled against the matching Havoc API headers
   □ Module loaded via teamserver UI or havoc.py script; confirm demon callback
   □ Command registration verified in the teamserver console
   □ Output format (JSON or raw bytes) matches what the handler expects
   ```

2. **Configure and verify sleep mask / in-memory obfuscation.**
   A Beacon sleeping without obfuscation sits in a private RWX region in memory —
   trivially detected by memory scanners. This step is mandatory for engagements
   against EDR products with memory scanning.

   **Cobalt Strike sleep mask (Artifact Kit or custom):**
   ```
   □ Sleep mask selected or implemented (EKKO, Foliage, or custom)
   □ Mask encrypts the Beacon heap and .text during sleep
   □ Mask correctly restores execution state on wakeup
   □ Memory region permissions transition: RWX → RW (during sleep) → RX (on wakeup)
   □ Test: inject, sleep 30s, run memory scanner against Beacon PID — confirm no match
   ```

   **Sleep jitter:**
   ```
   □ Jitter set to ≥25% (predictable sleep intervals are a detection signal)
   □ sleep command tested: `sleep 60 30` = 60s ±30% jitter
   ```

3. **Audit the malleable C2 profile or Havoc listener config for OPSEC.**

   **Malleable C2 profile OPSEC checklist:**
   ```
   □ User-Agent set to a common, versioned browser string (not default "curl/7.x")
   □ URI paths do not look like random hex strings (use realistic CDN / analytics paths)
   □ Host header set to a categorised domain (not raw IP)
   □ Staging disabled if stageless payloads are in use (set: set host_stage "false")
   □ Jitter and sleep set in the profile defaults
   □ Verify profile passes: ./c2lint <profile>.profile
   □ SSL certificate is a legitimate-looking wildcard or domain cert (not self-signed)
   ```

   **Havoc listener config:**
   ```
   □ WorkingHours set if engagement has a time constraint
   □ KillDate set — implant self-terminates after engagement end
   □ User-Agent and headers customised in the listener HTTP config
   □ Domain fronting configured if required by the engagement
   ```

4. **Set kill date and working hours before deployment.**
   An implant without a kill date that persists beyond engagement end is a scope
   violation. Verify the kill date is correct for the engagement end date.

   Cobalt Strike:
   ```cna
   # In aggressor or via sleep mask configuration:
   # killdate is set per-listener or per-payload at generation time
   # Confirm in payload generation UI: KillDate field is populated
   ```

   Working hours (optional — reduces noise outside business hours):
   ```
   # Beacon will not call home outside set hours
   # Set to match target timezone business hours if required
   ```

5. **Lab validation sequence before engagement deployment:**

   ```
   Step 1: Deploy implant against a lab VM matching the target OS / EDR configuration
   Step 2: Confirm callback to teamserver (check listener log)
   Step 3: Run edr-test-loop if EDR is present in the lab
   Step 4: Execute all planned post-ex tasks in the lab first
   Step 5: Verify implant self-terminates at kill date (advance VM clock)
   Step 6: Confirm no residual artifacts after termination (check prefetch, event logs)
   Step 7: Document the lab validation run before starting the engagement
   ```

## Gotchas
- Beacon version drift: if the Cobalt Strike server is updated between engagements,
  recompile all BOFs against the new `beacon.h`. A BOF compiled against an older
  header may crash a newer Beacon.
- `c2lint` validates the profile syntax but not runtime EDR detection. A
  lint-passing profile can still produce obvious network signatures.
- The default Cobalt Strike HTTPS certificate is a known fingerprint. Replace it
  with a Let's Encrypt or DigiCert cert tied to a categorised domain before use.
- Havoc's HTTP listener defaults to plaintext HTTP on port 80. Always configure
  TLS for engagements even in internal-only scenarios.
- Domain fronting CDN support changes. Verify your fronting configuration is still
  valid before the engagement — providers block known fronting domains without notice.
- Kill dates are enforced client-side by the implant. A patched or reversed implant
  can bypass them. They are an engagement hygiene control, not a security boundary.

## Suggested scripts
- `c2-preflight.sh` — runs `c2lint` on the malleable profile, checks SSL cert
  expiry on the listener domain, and prints a summary of the OPSEC checklist items
  that require manual verification

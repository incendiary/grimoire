# executive-translate

> **Cluster:** 02-comms | **Status:** complete | **Added:** 2026-05-24

Converts technical or security content into language a CISO, C-suite, or board
member can act on. Leads with impact and ask. Removes jargon without losing accuracy.
Pairs with `human-rewrite` for the final style pass.

---

## What this skill does

Takes a technical finding, risk, or incident description and restructures it for
a senior non-technical audience:

- **First sentence:** the single most important thing they need to know
- **First paragraph:** business impact, quantified where possible
- **Second paragraph:** the ask or decision required, with owner and consequences
- **Optional technical summary:** for readers who want the detail

The output respects audience tier — a board member gets more context-setting than a CISO;
a CISO gets more technical framing than a C-suite peer.

---

## When to use it

- Writing up a security finding for a CISO review
- Preparing an incident summary for C-suite or board
- Translating a pen test report finding into a risk committee brief
- Any time a technical colleague asks you to "make this exec-ready"

---

## Installation

### Claude Code

```bash
cp -r clusters/02-comms/executive-translate ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#executive-translate
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.



---

## How to invoke it in a session

```
/executive-translate
Audience: CISO
Ask: approval to engage an external IR firm
Political constraints: do not imply the security team missed this

[paste technical content]
```

Or inline during a session:

```
Turn this pen test finding into an exec brief for the CISO.
[paste finding]
```

---

## Workflow

```
User provides technical content + audience tier + ask
                   ↓
Identify the single most important thing (first sentence)
                   ↓
Business impact statement (quantified where possible)
                   ↓
One clear ask with owner and consequence if not acted on
                   ↓
Optional technical summary (labelled as optional)
                   ↓
human-rewrite style pass (British English, active voice, no jargon)
```

---

## What it will NOT do

- Use the word "leverage"
- Imply blame unless explicitly instructed
- Produce vague risk language ("significant potential impact") — it will flag this
  and ask for quantification or plain-language framing
- Include more than one ask in the main body

---

## Audience tier guide

| Tier | Depth | Acronyms | Technical detail |
|------|-------|----------|-----------------|
| CISO | Moderate | Expand unfamiliar ones | Brief technical summary fine |
| C-suite | Low | Expand all | Optional paragraph only |
| Board | Lowest | Expand all, explain context | Do not include |
| Senior management | Moderate | Expand unfamiliar ones | Brief summary fine |

---

## Worked examples

### Example 1 — Finding → CISO brief

**Audience:** CISO
**Ask:** approve emergency patch outside change freeze

**Raw technical input:**
```
CVE authentication bypass in /api/v1/auth/login. JWT validation does not verify the
algorithm field. Attacker can set "alg": "none", causing the server to accept unsigned
tokens. Grants access to any account without credentials. CVSS 9.8. Confirmed in
staging. Production uses the same codebase.
```

**Translated output:**
> Any external attacker can log in as any user — including administrators — without a
> password. Production is affected now.
>
> The authentication service accepts tampered login tokens that bypass password
> verification entirely. We confirmed this in staging, which shares the production
> codebase. An attacker who finds this before we patch can access any account, including
> privileged ones, with no credentials required. Exposure runs from the last deployment
> until the fix is live.
>
> The ask: approve an emergency patch outside the change freeze window. Engineering has a
> fix ready; deployment needs your sign-off for the change control exception. If we cannot
> patch today, the fallback is to take the login service offline — which affects all users
> but closes the exposure immediately.

**Rules applied:** leads with impact, quantified window of exposure, single clear ask
with named owner, no jargon ("CVE", "CVSS", "JWT algorithm confusion" removed from main
body), consequence of inaction stated.

---

### Example 2 — Incident → board summary

**Audience:** Board
**Ask:** no immediate ask; awareness and confidence-building

**Raw technical input:**
```
Ransomware precursor activity detected. Threat actor obtained domain admin credentials
via phishing. Lateral movement observed across 14 endpoints. EDR isolated affected
systems within 6 minutes of detection. Ransomware payload was staged but not detonated.
Forensics confirmed no data exfiltration. Full containment achieved at T+4 hours.
IR retainer engaged. Remediation in progress.
```

**Translated output:**
> An attacker gained administrator-level access to part of our network but was stopped
> before causing any damage. No data was taken and no systems were encrypted.
>
> The attacker entered through a phishing email and moved through 14 internal systems
> before our security tooling detected and isolated them. The ransomware was in position
> but never triggered. Our external incident response partner has been engaged and is
> working with the team on remediation and a full investigation.
>
> No customer data was affected and operations were not disrupted. We will provide a
> written summary of lessons learned and remediation steps at the next board cycle.

**Rules applied:** opened with outcome (stopped, no damage), avoided "lateral movement",
"EDR", "T+4", "precursor" — replaced with plain-language equivalents, no ask imposed
where none is needed.

---

### Example 3 — Risk → C-suite ask

**Audience:** C-suite (CEO sign-off, CFO for budget)
**Ask:** approve £180k MFA rollout across all staff

**Raw technical input:**
```
Current posture: password-only authentication on all corporate systems including email,
VPN, and SaaS. No MFA enforced. Credential stuffing and phishing attacks are primary
initial access vectors in 80% of confirmed breaches industry-wide. Internal phishing
simulation success rate: 23%. Recommended control: FIDO2 hardware tokens or authenticator
app MFA for all 600 staff. Estimated cost: £180k capex + £30k/year opex. Reduces
estimated breach probability by ~70% based on industry data.
```

**Translated output:**
> A single stolen password is currently enough to give an attacker full access to our
> email, VPN, and business systems. This is the starting point in the majority of
> breaches affecting organisations our size.
>
> One in four of our staff clicked a simulated phishing link in a recent test — a
> realistic proxy for how attackers get in. Adding a second verification step (a phone
> app or hardware token) means a stolen password alone is no longer enough. Industry
> data shows this reduces the probability of a successful breach by around 70%.
>
> The ask: approve £180k to deploy two-factor login for all 600 staff, with £30k per
> year ongoing. For context, the average cost of a breach at our scale is £1.2m — the
> ROI on this control is significant even in a low-probability scenario.

**Rules applied:** no acronyms (FIDO2, MFA, VPN expanded or replaced), lead with risk
not solution, single ask with cost and return stated, consequence quantified.

---

## Roadmap

- [x] SKILL.md written and validated
- [x] Build 3 worked examples (finding → CISO brief, incident → board summary, risk → C-suite ask)
- [x] Add worked examples for different audience tiers (CISO, C-suite, board)
- [ ] Test on 3 real findings
- [x] Ship: copy to `~/.claude/skills/executive-translate/`

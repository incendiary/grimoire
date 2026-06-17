# human-rewrite

> **Cluster:** 02-comms | **Status:** complete | **Added:** 2026-05-24

Strips AI markers and applies a fixed set of style rules to any draft. The rules are
loaded from this skill so you never have to re-state them. The output is the rewritten
text only — no commentary, no explanation of what changed.

---

## What this skill does

Applies a deterministic set of rewriting rules:

| Rule | Example |
|------|---------|
| British English | organise, colour, programme, defence |
| Active voice | "The team sent the report" not "The report was sent" |
| Oxford comma | "A, B, and C" not "A, B and C" |
| No em dashes | Replace with comma, colon, or parentheses |
| No corporate filler | No leverage, synergy, circle back, touch base |
| No AI openers | No "Certainly!", "Absolutely!", "Happy to help!" |
| No bullet points in prose | Unless the user explicitly uses them |
| Sentence length variation | Mix short and long sentences |
| Cut over-explanation | If a sentence adds nothing new, remove it |

Medium-aware: emails, Slack messages, and document sections are treated differently.
A Slack message that sounds like an email is itself an AI marker.

---

## When to use it

- After any other skill produces a draft (`executive-translate`, `incident-appendix`)
- When Claude has drafted something in the session and it needs a style pass before sending
- When you have written something yourself but want a cleanup pass
- Any time the output "sounds like ChatGPT"

---

## Installation

### Claude Code

```bash
cp -r clusters/02-comms/human-rewrite ~/.claude/skills/
```

### VS Code (prompt file)

After running `bash build.sh`, reference in Copilot Chat:
```
#human-rewrite
```

> **Note:** This is an `instructional` type skill — prompt file and Claude Code only.
> Not exposed as an MCP tool.



---

## How to invoke it in a session

After another skill produces a draft:

```
Run human-rewrite on that. Medium: email.
```

Or with your own text:

```
/human-rewrite
Medium: Slack message
[paste your draft]
```

The style rules are pre-loaded — you do not need to re-list them.

---

## Workflow

```
Draft produced (by you or another skill)
           ↓
human-rewrite invoked with medium specified
           ↓
Apply all style rules (British English, active voice, etc.)
           ↓
Mental read-aloud check for residual AI markers
           ↓
Return rewritten text only — no preamble
```

---

## What it will NOT do

- Change technical terms, product names, or acronyms
- Soften assertive language (directness is not aggression)
- Add explanation, commentary, or a list of changes made
- Apply email structure to a Slack message or vice versa

---

## Style rules — before/after

One pair per rule. Each "before" reflects a typical AI or corporate draft; each "after"
is what the rule produces.

---

**British English**

Before: `We need to finalize the program and organize the defense posture.`
After: `We need to finalise the programme and organise the defence posture.`

---

**Active voice**

Before: `The report was sent to the client by the team on Friday.`
After: `The team sent the report to the client on Friday.`

---

**Oxford comma**

Before: `The scope covers endpoints, servers and cloud workloads.`
After: `The scope covers endpoints, servers, and cloud workloads.`

---

**No em dashes**

Before: `The fix is straightforward — update the dependency and redeploy.`
After: `The fix is straightforward: update the dependency and redeploy.`

Before: `Three teams — engineering, security, and ops — are involved.`
After: `Three teams are involved (engineering, security, and ops).`

---

**No corporate filler**

Before: `We need to leverage our existing tooling to circle back on this and align stakeholders.`
After: `We should use our existing tooling to revisit this and get agreement from stakeholders.`

---

**No AI openers**

Before: `Certainly! I'd be happy to help you with that risk summary.`
After: `[Start directly with the risk summary.]`

Before: `Absolutely, here's the updated incident timeline you requested.`
After: `Here is the updated incident timeline.`

---

**No bullet points in prose**

Before:
```
The key issues are:
- Authentication is broken
- Logging is missing
- Patching is overdue
```

After:
`Authentication is broken, logging is missing, and patching is overdue.`

*Exception: the user explicitly uses a bullet list and asks for one in return.*

---

**Sentence length variation**

Before: `The attacker gained access to the VPN. The attacker then moved laterally. The attacker accessed the file server. The attacker exfiltrated data.`
After: `The attacker gained VPN access, moved laterally to the file server, and exfiltrated data. The whole sequence took under two hours.`

Before: `This is a finding that relates to the way in which the authentication system processes incoming requests from users who are attempting to log in to the application using credentials that have been compromised in a previous data breach, and the failure mode here is that the system does not check whether the password being submitted has appeared in known breach databases before granting access.`
After: `The login system does not check whether a submitted password has appeared in known breach databases. An attacker with a stolen credential list can log in without detection.`

---

**Cut over-explanation**

Before: `This is important because it means that without this control in place, there is a risk that an attacker could potentially exploit this vulnerability to gain unauthorised access, which would be a bad outcome for the organisation.`
After: `Without this control, an attacker can exploit the vulnerability to gain unauthorised access.`

---

## Roadmap

- [x] SKILL.md written and validated
- [x] Build worked before/after examples for each style rule
- [ ] Test on 5 real outputs from other skills
- [ ] Add any further rules that emerge from real usage
- [x] Ship: copy to `~/.claude/skills/human-rewrite/`

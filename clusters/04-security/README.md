# 04-security — Domain-specific security

Skills that carry security domain knowledge so it does not need to be re-explained
each session. Covers platform-specific signing risk analysis and structured security
communication workflows.

---

## Skills

### [review-ios-signing](review-ios-signing/) ✅ complete

Structured analysis of iOS signing risk. Covers IPA integrity (hash and codesign
verification), certificate authenticity and validity, OTA manifest verification,
and revocation timing analysis with OCSP propagation lag. Always enforces the
redeploy-before-revoke sequencing rule. Produces a finding of confirmed safe /
confirmed compromised / inconclusive with what evidence would resolve it.
→ [Full documentation](review-ios-signing/README.md)

---

## Typical chain

```
Signing anomaly or incident reported
              ↓
review-ios-signing          (technical analysis)
              ↓
incident-asks      (evidence collection)
              ↓
write-exec       (stakeholder notification)
              ↓
incident-appendix         (formal documentation)
```

---

## When to invoke — workflow guide

### Workflow 1: iOS signing anomaly triage

**Trigger:** "Is this app signing chain compromised or safe to continue?"

```
review-ios-signing          → integrity/cert/manifest/revocation analysis
              ↓
incident-asks      → collect missing evidence to resolve uncertainty
              ↓
write-exec       → stakeholder decision brief
              ↓
incident-appendix         → preserve full technical record
```

---

## Individual skill trigger reference

| Skill | Invoke when... |
|-------|----------------|
| `review-ios-signing` | You need structured technical assessment of IPA signing integrity and revocation state |

# 04-security — Domain-specific security

Skills that carry security domain knowledge so it does not need to be re-explained
each session. Covers platform-specific signing risk analysis and structured security
communication workflows.

---

## Skills

### [ios-signing-risk](ios-signing-risk/) ✅ complete
Structured analysis of iOS signing risk. Covers IPA integrity (hash and codesign
verification), certificate authenticity and validity, OTA manifest verification,
and revocation timing analysis with OCSP propagation lag. Always enforces the
redeploy-before-revoke sequencing rule. Produces a finding of confirmed safe /
confirmed compromised / inconclusive with what evidence would resolve it.
→ [Full documentation](ios-signing-risk/README.md)

---

## Typical chain

```
Signing anomaly or incident reported
              ↓
ios-signing-risk          (technical analysis)
              ↓
incident-ask-builder      (evidence collection)
              ↓
executive-translate       (stakeholder notification)
              ↓
incident-appendix         (formal documentation)
```

---

## When to invoke — workflow guide

### Workflow 1: iOS signing anomaly triage

**Trigger:** "Is this app signing chain compromised or safe to continue?"

```
ios-signing-risk          → integrity/cert/manifest/revocation analysis
              ↓
incident-ask-builder      → collect missing evidence to resolve uncertainty
              ↓
executive-translate       → stakeholder decision brief
              ↓
incident-appendix         → preserve full technical record
```

---

## Individual skill trigger reference

| Skill | Invoke when... |
|-------|----------------|
| `ios-signing-risk` | You need structured technical assessment of IPA signing integrity and revocation state |

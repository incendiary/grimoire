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

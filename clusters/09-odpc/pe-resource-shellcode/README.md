# pe-resource-shellcode

> **Cluster:** 09-odpc | **Status:** complete | **Added:** 2026-06-02

Embedding and extracting XOR-encrypted shellcode from the PE .rsrc section.
Maps to ODPC Chapters 5 (PE Primer) and 11 (Shellcode in Resources Section).

## Roadmap

- [x] SKILL.md written: FindResource/LoadResource/LockResource pattern, XOR encryption, allocation tradeoffs, full loader skeleton, behavioural signatures to avoid
- [x] Add Python encrypt helper script as a standalone file
- [x] Add RC file template for Visual Studio resource embedding

# cwd-verification

> **Status:** COMPLETE
> **Cluster:** 01-meta

## Description
Verify the working directory at session start and before any bulk file operations,
particularly when a project has both a local path and an iCloud-synced path.

Invoke when: starting a session involving file reads, writes, or operations across a
project that has multiple possible root paths (local vs iCloud sync, multiple clones,
or ambiguous relative paths).

## Context needed
- The user's common project locations and their variants:
  - Local projects: `/Users/<user>/<project>`
  - iCloud-synced: `~/Library/Mobile Documents/com~apple~CloudDocs/gits/<project>`
  - Any project you keep in both a local directory and an iCloud-synced one
- Whether the session involves iCloud-synced paths (these contain spaces — always quote in shell)

## What to do

1. **At session start, if the working directory is ambiguous, confirm it explicitly**
   before performing any file operations:
   ```bash
   pwd && ls -la
   ```
   State the confirmed path in your response so the user can catch mismatches early.

2. **Before any bulk read or write operation** (reading multiple files, writing across
   a directory, moving or copying files), confirm the root path is correct. Do not
   assume continuity from a previous turn — context can shift.

3. **When the user mentions a file that does not exist at the expected path,** check
   the alternative path before reporting "file not found". Common pattern: user says
   `[project]/modules/x.tf` and the file is at the iCloud path, not the local path.

4. **iCloud paths contain spaces.** The path
   `~/Library/Mobile Documents/com~apple~CloudDocs/...` must always be quoted in
   shell commands:
   ```bash
   ls "~/Library/Mobile Documents/com~apple~CloudDocs/gits/[project]"
   ```
   Unquoted iCloud paths will fail silently or produce wrong results.

## Gotchas
- A project may exist at both a local path and an iCloud-synced path. They are not
  always in sync. Confirm which is active before writing.
- iCloud sync paths contain spaces — always quote them in bash, find, cp, and any
  other shell command.
- Do not assume the CWD from a previous session or turn. Always verify before bulk ops.
- If a read fails with "file not found", check the alternative path before reporting
  the error to the user.

## Suggested scripts
- `pwd && ls` — the minimal verification before any session's first file operation

# orient

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-06-01

Session-start orientation for any GitHub project. Combines platform state (PRs,
issues, CI, releases) with README roadmap state and calls out discrepancies between
the two — specifically the common failure mode of a clean GitHub dashboard masking
unchecked README roadmap items.

---

## What this skill does

Runs a structured checklist of `gh` CLI commands, reads all nested READMEs, and
cross-checks each unchecked item against the actual codebase and commit history.
Produces a "true state" summary that distinguishes:

- **README lag** — item is actually done, README wasn't updated
- **Confirmed outstanding** — genuinely unimplemented
- **Ambiguous** — partial implementation, needs human decision

Prevents the failure mode of reporting a project as "all tidy" when the README
roadmap disagrees.

---

## When to use it

Load at the start of any session where you need to know what's actually outstanding:
- "What's left on this repo?"
- "Pick up where we left off"
- "Review the roadmap"
- "Is this project tidy?"
- Before starting a delivery session (pairs with `project-delivery-workflow`)

---

## How to invoke it in a session

```
/orient
Repo: incendiary/my-project
```

Or implicitly:

```
What's still outstanding on this repo? Give me the full picture.
```

---

## Example output

```
=== orient: my-project ===

GitHub platform state:
  Open PRs:       0
  Open issues:    0
  CI:             all green (last run: 2h ago)
  Latest release: v0.3.0 — Latest: yes
  Stale branches: none

README roadmap state:
  Unchecked items found: 3 (clusters/07-devops/repo-pub-prep/README.md)

Cross-check findings:
  [ ] Add audit_history.sh — confirmed outstanding (no commit, no PR found)
  [ ] Test end-to-end on one new repo — confirmed outstanding
  [ ] Document new gotchas from real usage — deferred (needs real usage)

True state:
  Outstanding work:    2 confirmed items (1 deferred)
  README sync needed:  0
  Discrepancies:       0

Recommendation: 2 items to action. Proceed with project-delivery-workflow.
```

---

## Relationship to other skills

```
orient             (where are we?)
        ↓
project-delivery-workflow  (execute outstanding items)
        ↓
roadmap-sync             (keep READMEs ticked after each merge)
        ↓
github-release-workflow  (tag and release when done)
```

---

---

## Push protocol check

### What this skill does

Establishes a pre-push SSH check and a clean HTTPS fallback path. SSH debug is a
rabbit hole — this skill says: check once, fall back fast, ship the work.

---

### When to use it

- First push of any session where SSH agent state is uncertain
- After a push fails with `Permission denied (publickey)` or connection timeout
- When working in a terminal without agent forwarding (remote sessions, tmux, Docker)

---

### SSH agent start sequence

Use this when `ssh -T git@github.com` returns `Could not open a connection` or
`Connection refused` — the agent is not running, not just missing the key.

```bash
# Start the agent and export the socket for the current shell
eval "$(ssh-agent -s)"

# Add your key (adjust path if yours differs)
ssh-add ~/.ssh/id_ed25519        # Ed25519 key (preferred)
# ssh-add ~/.ssh/id_rsa          # RSA fallback

# Verify the key loaded
ssh-add -l

# Confirm GitHub accepts it
ssh -T git@github.com            # expect: "Hi <user>! You've successfully authenticated..."
```

**Diagnosing which case you are in:**

| `ssh -T git@github.com` output | Cause | Fix |
|-------------------------------|-------|-----|
| `Could not open a connection to your authentication agent` | Agent not running | `eval "$(ssh-agent -s)"` |
| `Permission denied (publickey)` | Agent running but key not loaded | `ssh-add ~/.ssh/id_ed25519` |
| `Hi <user>! You've successfully authenticated` | Agent running, key loaded, all good | Push directly |
| Connection timeout | Firewall/network blocking port 22 | Fall back to HTTPS (see below) |

### Quick reference

```bash
ssh -T git@github.com                                    # check SSH
git remote set-url origin https://github.com/incendiary/<repo>.git  # switch remote
gh config set git_protocol https                         # switch gh CLI
git push origin <branch>                                 # push via HTTPS
```

---

---

## Roadmap

- [x] SKILL.md written and validated
- [x] README.md written
- [x] Add `repo-compass.sh` — runs all `gh` commands in sequence and outputs the summary
- [x] Ship: copy to `~/.claude/skills/orient/`

# git-push-protocol-handler

> **Cluster:** 07-devops | **Status:** complete | **Added:** 2026-05-24

SSH/HTTPS fallback procedure for git push. Checks SSH agent connectivity before
pushing and switches the remote to HTTPS via `gh` CLI if SSH is unavailable.
Prevents wasting time debugging SSH configuration when a push just needs to happen.

---

## What this skill does

Establishes a pre-push SSH check and a clean HTTPS fallback path. SSH debug is a
rabbit hole — this skill says: check once, fall back fast, ship the work.

---

## When to use it

- First push of any session where SSH agent state is uncertain
- After a push fails with `Permission denied (publickey)` or connection timeout
- When working in a terminal without agent forwarding (remote sessions, tmux, Docker)

---

## Installation

```bash
cp -r ~/Claude/Skills/grimoire/clusters/07-devops/git-push-protocol-handler ~/.claude/skills/
```

---

## Quick reference

```bash
ssh -T git@github.com                                    # check SSH
git remote set-url origin https://github.com/incendiary/<repo>.git  # switch remote
gh config set git_protocol https                         # switch gh CLI
git push origin <branch>                                 # push via HTTPS
```

---

## Roadmap

- [x] SKILL.md written and validated
- [ ] Write `check_push_protocol.sh`
- [ ] Add SSH agent start/add sequence for when agent is simply not running
- [ ] Test on a representative set of repos
- [x] Ship: copy to `~/.claude/skills/git-push-protocol-handler/`

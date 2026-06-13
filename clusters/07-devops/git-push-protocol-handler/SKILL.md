# git-push-protocol-handler

> **Status:** COMPLETE
> **Cluster:** 07-devops
> **Type:** action

## Description
Before any push, verify SSH agent connectivity. If SSH fails, switch the remote to
HTTPS via the GitHub CLI rather than debugging SSH configuration mid-session.

Invoke when: a push fails with a connection or authentication error, or at the start
of any session where SSH agent availability is uncertain (fresh terminal, remote machine,
post-reboot).

## Context needed
- Current remote protocol: `git remote -v`
- GitHub CLI auth status: `gh auth status`

## What to do

1. **Before the first push in any session, verify SSH connectivity:**
   ```bash
   ssh -T git@github.com
   ```
   Expected output: `Hi incendiary! You've successfully authenticated...`
   If this fails (timeout, permission denied), do not attempt SSH push — switch to HTTPS now.

2. **If SSH is unavailable, switch the remote and the gh default protocol:**
   ```bash
   # Switch this repo's remote to HTTPS
   git remote set-url origin https://github.com/incendiary/<repo>.git

   # Set gh CLI to use HTTPS globally for this session
   gh config set git_protocol https

   # Verify
   git remote -v
   gh auth status
   ```

3. **Push and verify:**
   ```bash
   git push origin <branch>
   ```
   HTTPS pushes use the `gh` auth token — confirm `gh auth status` shows a valid,
   unexpired token before pushing.

4. **After the session, restore SSH if preferred:**
   ```bash
   git remote set-url origin git@github.com:incendiary/<repo>.git
   gh config set git_protocol ssh
   ```

## Gotchas
- HTTPS fallback requires the `gh` CLI to have a valid token with `repo` scope.
  Run `gh auth status` before relying on HTTPS — an expired token will fail silently.
- SSH agent forwarding does not work in all terminal configurations. If working over
  a remote session or tmux, the agent socket may not be available even if the key is loaded.
- Do not attempt to debug SSH configuration mid-session if a deadline exists. Switch to
  HTTPS, ship the work, and fix SSH separately.
- `gh config set git_protocol https` is a global setting — it affects all repos in this
  `gh` session. Restore it after the session if SSH is the preferred default.

## Suggested scripts
- `check_push_protocol.sh` — tests SSH with `ssh -T git@github.com`, reports status,
  and offers to switch to HTTPS if SSH is unavailable

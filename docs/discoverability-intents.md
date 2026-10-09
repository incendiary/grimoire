# Discoverability spot-check

Paste each request into a fresh Claude Code session (no skill names). Pass = Claude
invokes the expected skill. Map old names through scripts/renamed-skills.txt.

| Request | Expected skill |
|---|---|
| What's the state of this repo? I've been away a week and need to get my bearings. | repo-compass |
| Go through my open PRs and dependabot noise and tell me what needs attention this morning. | github-morning-run |
| I've got a pile of stale branches, work out which are safe to bin. | branch-surface-resolve |
| Break this big refactor into pieces I can hand to separate agents. | task-decomposer |
| My context is nearly full, write me something I can resume from in a new session. | task-handoff |
| What should I work on next from the roadmap? | roadmap-driver |
| That PR just merged, tick off the roadmap items it finished. | roadmap-sync |
| Is the grimoire roadmap up to date, and what's outstanding in it? | grimoire-roadmap-status |
| Run the GitHub Actions checks on my laptop before I push. | local-ci |
| Quick check that my Python passes Black and Ruff, nothing else. | python-lint-gate |
| I'm about to write some Python, what Black and Ruff conventions should I follow? | python-black-ruff-authoring |
| Check that package-lock.json hasn't been tampered with and the hashes are sound. | npm-lockfile-integrity |
| Are the hashes in my requirements file pinned and consistent? | python-lockfile-integrity |
| Cut a release of this repo with a proper tag and GitHub release notes. | github-release-workflow |
| Build and push this image to GitHub's container registry. | docker-ghcr-publish |
| I'm making this repo public next week, get it ready. | repo-publication-prep |
| Wipe the git history and start the repo fresh before I open it up. | github-history-wipe |
| Terraform keeps rejecting my AWS resource arguments, what's the right syntax? | terraform-aws-syntax |
| Checkov is flagging this bucket and I need to suppress it properly with a justification. | terraform-checkov-skips |
| Rewrite this so it doesn't read like a chatbot wrote it. | human-rewrite |
| Turn this technical write-up into something the board will read. | executive-translate |
| Draft the list of logs and evidence we need to ask the vendor for after this breach. | incident-ask-builder |
| We've collected the evidence, now write it up as an appendix for the incident report. | incident-appendix |
| Review this whole codebase and tell me what's weak. | codebase-holistic-review |
| Is this third-party skill safe to install? | skill-vetter |

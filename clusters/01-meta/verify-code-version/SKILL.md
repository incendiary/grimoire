# verify-code-version

> **Status:** COMPLETE
> **Cluster:** 01-meta

## Description
After a `git pull` or branch switch, verify the running code actually reflects HEAD
before evaluating output. Prevents diagnosing behaviour from stale code.

Invoke when: a session involves pulling changes, switching branches, or evaluating
the output of a tool where the running version matters. Particularly important for
Python scripts where modules may be cached from a previous import.

## Context needed
- Location of the version identifier in the project: `__version__` in `version.py`,
  `pyproject.toml`, `setup.py`, or a banner string printed at startup
- The expected version after the pull

## What to do

1. **After any `git pull`, `git checkout`, or branch switch, verify the active code
   version before running or evaluating output.** Do not assume that pulling
   automatically updates what is running.

   For Python projects with a `__version__` string:
   ```bash
   python3 -c "import <package>; print(<package>.__version__)"
   # or
   grep -r "__version__" <package>/ | head -5
   ```

   For projects with a version printed at startup:
   ```bash
   python3 <script>.py --version
   # or run it and check the banner/header in the first few lines of output
   ```

2. **Compare the running version against `git rev-parse HEAD` (short) or the tag
   if the project uses tagged releases.** If they do not match, the environment
   is stale. Resolve before proceeding.

3. **If evaluating output that looks wrong, check the version before debugging.**
   The first question when output is unexpected: "Is this the expected version of
   the code?" Check before assuming a bug in the current code.

## Gotchas
- Python may cache imported modules in long-running interactive sessions or notebooks.
  A `git pull` does not invalidate cached imports. Restart the interpreter or use
  `importlib.reload()` when in doubt.
- Some scripts embed a version string in their output banner. If the banner shows an
  old version string, the script is running stale code even if the file on disk is current.
  This indicates a `.pyc` cache or an installed package overriding the local version.
- Virtual environments can install a package from a previous version. If `pip show <pkg>`
  shows a different version than the source, the installed package is stale.

## Suggested scripts
- `verify_version.sh` — compares `git rev-parse HEAD` against the embedded `__version__`
  string, reports whether they are in sync

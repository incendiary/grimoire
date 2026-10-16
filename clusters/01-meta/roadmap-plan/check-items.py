#!/usr/bin/env python3
"""Fail if any roadmap item is missing a required field.

An item is a `### ` heading under `## Items` (or anywhere, if there is no such
section). Each item must contain every field below as a bold label, in order,
with text after it: `**Tier:** ...`.

Usage: python3 check-items.py [ROADMAP.md]     exit 0 = all ready, 1 = gaps
       python3 check-items.py --self-test
"""
import re
import sys

FIELDS = ["Tier", "Depends on", "Files", "Context", "Steps",
          "Verify", "Do not", "Done when", "PR"]
PR_RE = re.compile(r"^(feat|fix|docs|chore|ci|refactor|perf|test|build)(\([^)]*\))?!?: \S")


def items(text):
    m = re.search(r"^## Items\s*$(.*?)(?=^## |\Z)", text, re.M | re.S)
    body = m.group(1) if m else text
    for chunk in re.split(r"^### ", body, flags=re.M)[1:]:
        title, _, rest = chunk.partition("\n")
        yield title.strip(), rest


def gaps(rest):
    found, out = [], []
    for f in FIELDS:
        m = re.search(r"^\s*(?:[-*]\s*)?\*\*" + re.escape(f) + r":\*\*(.*)$", rest, re.M)
        if not m:
            out.append(f"missing {f}")
            continue
        found.append((m.start(), f))
        value = m.group(1).strip()
        # Multi-line fields (Steps, Verify, ...) may start on the next line.
        nxt = rest[m.end():].lstrip("\n").split("\n", 1)[0].strip()
        if not value and (not nxt or nxt.startswith("**")):
            out.append(f"empty {f}")
        if f == "PR" and value and not PR_RE.match(value.strip("` ")):
            out.append("PR is not a conventional-commit title")
    order = [f for _, f in sorted(found)]
    if order != [f for f in FIELDS if f in order]:
        out.append("fields out of order")
    # ponytail: keyword match, so an unrelated "break" or "revert" passes; a
    # labelled sub-field ("Negative check:") if false passes show up in practice.
    if "Verify" in order and not re.search(r"(?i)negative|break|revert|should fail|must fail",
                                           rest.split("**Verify:**", 1)[1].split("**Do not:**", 1)[0]):
        out.append("Verify has no negative check")
    return out


def check(text):
    its = list(items(text))
    report = [(t, g) for t, r in its for g in [gaps(r)] if g]
    return report, len(its)


def self_test():
    good = """## Items
### R-1: Example
**Tier:** cheap, a test gate proves it.
**Depends on:** none
**Files:** `a.py`
**Context:** `a.py:3` returns None.
**Steps:**
1. Edit `a.py`.
**Verify:** `pytest`; negative check: revert the fix, confirm the test fails.
**Do not:** touch `b.py`.
**Done when:** `pytest` passes.
**PR:** `fix: return value from a`
"""
    assert check(good) == ([], 1), check(good)
    bad = good.replace("**Do not:** touch `b.py`.\n", "").replace("fix: return", "return")
    (title, g), = check(bad)[0]
    assert "missing Do not" in g and "PR is not a conventional-commit title" in g, g
    assert "Verify has no negative check" in check(good.replace("negative check: revert the fix, confirm the test fails", "ok"))[0][0][1]
    print("self-test ok")


def main():
    if sys.argv[1:] == ["--self-test"]:
        self_test()
        return 0
    path = sys.argv[1] if len(sys.argv) > 1 else "ROADMAP.md"
    report, total = check(open(path).read())
    if total == 0:
        print(f"✗ No `### ` items found in {path}")
        return 1
    for title, g in report:
        print(f"✗ {title}: {', '.join(g)}")
    print(f"{total - len(report)}/{total} items ready")
    return 1 if report else 0


if __name__ == "__main__":
    sys.exit(main())

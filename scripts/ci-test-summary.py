#!/usr/bin/env python3
"""The last step of CI: every check's outcome and every failing test, in the log and on the run's summary page.

    python3 scripts/ci-test-summary.py

The workflow passes each check as an environment variable CHECK_<n>="<name>|<outcome>", in order (the outcome is
GitHub's: success, failure, cancelled or skipped). Each result bundle under build/results/ is read with xcresulttool
for its counts and its failures. Exits 1 if any check failed, so the job fails once, here, with the whole list.
CI only (it reads what the run left behind).
"""
import json
import os
import pathlib
import subprocess
import sys

root = pathlib.Path(__file__).resolve().parent.parent

checks = []
for key in sorted((k for k in os.environ if k.startswith("CHECK_")), key=lambda k: int(k.split("_", 1)[1])):
    name, _, outcome = os.environ[key].rpartition("|")
    checks.append((name, outcome or "not run"))

lines = ["## Every check", "", "| Check | Outcome |", "| --- | --- |"]
lines += [f"| {name} | {'✅' if outcome == 'success' else '❌' if outcome == 'failure' else '⏭️'} {outcome} |"
          for name, outcome in checks]

for bundle in sorted((root / "build" / "results").glob("*.xcresult")):
    lines += ["", f"## {bundle.stem}", ""]
    try:
        out = subprocess.run(["xcrun", "xcresulttool", "get", "test-results", "summary", "--path", str(bundle)],
                             check=True, capture_output=True, text=True, timeout=120).stdout
        summary = json.loads(out)
    except (subprocess.SubprocessError, json.JSONDecodeError, OSError) as error:
        lines.append(f"Could not read the bundle: {error}")
        continue
    lines.append(f"{summary.get('result', '?')}: {summary.get('passedTests', '?')} passed, "
                 f"{summary.get('failedTests', '?')} failed, {summary.get('skippedTests', '?')} skipped "
                 f"of {summary.get('totalTestCount', '?')}")
    for failure in summary.get("testFailures", []):
        test = failure.get("testIdentifierString") or failure.get("testName", "?")
        text = " · ".join(line.strip() for line in str(failure.get("failureText", "")).splitlines() if line.strip())
        lines.append(f"- `{test}`: {text}")

report = "\n".join(lines) + "\n"
print(report)
if os.environ.get("GITHUB_STEP_SUMMARY"):
    with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as page:
        page.write(report)

failed = [name for name, outcome in checks if outcome == "failure"]
if failed:
    print(f"::error title=Checks failed::{len(failed)} of {len(checks)} checks failed: {', '.join(failed)}")
    sys.exit(1)

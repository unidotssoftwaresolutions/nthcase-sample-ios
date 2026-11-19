#!/usr/bin/env python3
"""Every check's outcome and every failing test, in the log and on the run's summary page. Two parts, as CI has them:

    python3 scripts/ci-test-summary.py job    in each check job, last (macOS)
    python3 scripts/ci-test-summary.py        in the summary job, which needs every check job (any runner)

`job`: the job passes each of its checks as CHECK_<n>="<id>|<name>|<outcome>|<bundle>" (the outcome is GitHub's:
success, failure, cancelled or skipped; the bundle is build/results/<bundle>.xcresult, or empty). Each bundle is read
with xcresulttool for its counts and its failures, which go in the job's log and on its summary page, and up to the
summary job as two outputs per check: <id>, the outcome, and <id>_tests, the bundle's lines. When the job's own
simulator could not be made (SIMULATOR is its step's outcome), a check that was skipped for want of it is reported as
a failure, never as skipped or passed. Exits 0: the check's own step has already failed the job.

The summary: CHECK_<n>="<name>|<outcome>", in order, and TESTS_<n>, that check's lines from its job. JOB_<n>="<job>|
<result>" is each check job's result (needs.<job>.result), so a job that failed outside its checks is named too. Exits
1 if any check or job failed or was cancelled, so the run fails once, here, with the whole list. A skipped check is
listed as skipped. CI only (it reads what the run left behind).
"""
import json
import os
import pathlib
import subprocess
import sys
import uuid

root = pathlib.Path(__file__).resolve().parent.parent
# a job output may hold 1 MB in all; a bundle's lines are cut well before that
MOST = 50_000


def numbered(prefix):
    keys = (k for k in os.environ if k.startswith(prefix) and k[len(prefix):].isdigit())
    return [os.environ[k] for k in sorted(keys, key=lambda k: int(k[len(prefix):]))]


def page(text):
    print(text)
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as summary:
            summary.write(text)


def bundle_lines(bundle):
    """The bundle's counts and each failing test in a line, as the summary has always shown them."""
    lines = [f"## {bundle.stem}", ""]
    try:
        out = subprocess.run(["xcrun", "xcresulttool", "get", "test-results", "summary", "--path", str(bundle)],
                             check=True, capture_output=True, text=True, timeout=120).stdout
        summary = json.loads(out)
    except (subprocess.SubprocessError, json.JSONDecodeError, OSError) as error:
        return lines + [f"Could not read the bundle: {error}"]
    lines.append(f"{summary.get('result', '?')}: {summary.get('passedTests', '?')} passed, "
                 f"{summary.get('failedTests', '?')} failed, {summary.get('skippedTests', '?')} skipped "
                 f"of {summary.get('totalTestCount', '?')}")
    for failure in summary.get("testFailures", []):
        test = failure.get("testIdentifierString") or failure.get("testName", "?")
        text = " · ".join(line.strip() for line in str(failure.get("failureText", "")).splitlines() if line.strip())
        lines.append(f"- `{test}`: {text}")
    return lines


def job():
    simulator = os.environ.get("SIMULATOR", "")
    outputs = []
    sections = []
    for entry in numbered("CHECK_"):
        check, name, outcome, bundle = (entry.split("|") + ["", "", "", ""])[:4]
        lines = []
        if outcome == "skipped" and simulator and simulator != "success":
            outcome = "failure"
            lines.append(f"{name}: not run: the step that makes this job's simulator ended in {simulator}")
        path = root / "build" / "results" / f"{bundle}.xcresult"
        if bundle and path.exists():
            lines += bundle_lines(path)
        elif bundle and outcome == "failure" and not lines:
            lines.append(f"{name}: failed before it wrote build/results/{bundle}.xcresult; its log says why")
        text = "\n".join(lines)
        if len(text) > MOST:
            text = text[:MOST] + f"\n… cut at {MOST} characters; the whole list is in the test-results artifact"
        sections.append(text)
        outputs.append((check, outcome))
        outputs.append((f"{check}_tests", text))
    page("\n\n".join(s for s in sections if s) + "\n")
    if os.environ.get("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as out:
            for key, value in outputs:
                mark = f"END_{uuid.uuid4().hex}"
                out.write(f"{key}<<{mark}\n{value}\n{mark}\n")


def summary():
    checks = []
    for entry in numbered("CHECK_"):
        name, _, outcome = entry.rpartition("|")
        checks.append((name, outcome or "not run"))
    tests = numbered("TESTS_")
    jobs = [entry.rpartition("|")[::2] for entry in numbered("JOB_")]
    mark = {"success": "✅", "failure": "❌", "cancelled": "🚫"}
    lines = ["## Every check", "", "| Check | Outcome |", "| --- | --- |"]
    lines += [f"| {name} | {mark.get(outcome, '⏭️')} {outcome} |" for name, outcome in checks]
    bad = ("failure", "cancelled")
    failed = [name for name, outcome in checks if outcome in bad]
    # a job that failed with every check of its own green: a step around the checks (checkout, a download) failed
    stray = [f"{job_name} ({result})" for job_name, result in jobs if result in bad]
    if stray and not failed:
        lines += ["", "A job failed outside its checks: " + ", ".join(stray)]
    for text in tests:
        if text.strip():
            lines += ["", text.strip()]
    page("\n".join(lines) + "\n")
    if failed or stray:
        what = f"{len(failed)} of {len(checks)} checks failed or were cancelled: {', '.join(failed)}" if failed \
            else f"a job failed: {', '.join(stray)}"
        print(f"::error title=Checks failed::{what}")
        sys.exit(1)


if __name__ == "__main__":
    job() if sys.argv[1:] == ["job"] else summary()

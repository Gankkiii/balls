#!/usr/bin/env python3
"""Run the actual Godot suites and reject unexpected engine errors."""

import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "demo"
LOGS = ROOT / "build" / "test-logs"
GODOT = os.environ.get("GODOT_BIN", "godot")


def main():
    LOGS.mkdir(parents=True, exist_ok=True)
    suites = sorted((PROJECT / "tests").glob("test_*.gd"))
    suites.append(PROJECT / "tests" / "run_tests.gd")
    stages = [("import", ["--editor", "--import", "--quit"], False)]
    stages.extend((p.stem, ["--script", f"tests/{p.name}"], True) for p in suites)
    stages.append(("smoke", ["--quit-after", "5"], False))
    results = []
    for name, arguments, is_suite in stages:
        started = time.monotonic()
        command = [GODOT, "--headless", "--path", str(PROJECT), *arguments]
        try:
            result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                    text=True, timeout=180, check=False)
            output, exit_code = result.stdout, result.returncode
        except subprocess.TimeoutExpired as error:
            output = error.stdout or b""
            if isinstance(output, bytes):
                output = output.decode("utf-8", errors="replace")
            output += "\nREGRESSION TIMEOUT\n"
            exit_code = 124
        (LOGS / f"{name}.log").write_text(output, encoding="utf-8")
        print(f"\n=== {name} ===\n{output}", flush=True)
        summaries = [line for line in output.splitlines() if "RESULT" in line]
        errors = len(re.findall(r"^ERROR:", output, re.MULTILINE))
        expected_errors = len(re.findall(r"^EXPECTED (?:CONFIG |PLACEMENT |SCENARIO )?ERROR:",
                                         output, re.MULTILINE))
        failed = exit_code != 0 or errors != expected_errors
        failed |= bool(re.search(r"SCRIPT ERROR:|Parse Error:|^FAIL:", output, re.MULTILINE))
        if is_suite:
            failed |= not summaries or any(not re.search(r"\bfailures=0\b", line)
                                          or re.search(r"\bfailed=[1-9]\d*\b", line)
                                          for line in summaries)
        elif expected_errors:
            failed = True
        results.append({"stage": name, "passed": not failed, "exit_code": exit_code,
                        "seconds": round(time.monotonic() - started, 2), "errors": errors,
                        "expected_errors": expected_errors, "summary": summaries})
    report = {"passed": sum(r["passed"] for r in results),
              "failed": sum(not r["passed"] for r in results),
              "test_suites": len(suites), "device_tests": "NOT RUN", "stages": results}
    (LOGS / "summary.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2), flush=True)
    return 1 if report["failed"] else 0


if __name__ == "__main__":
    sys.exit(main())

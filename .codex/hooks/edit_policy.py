#!/usr/bin/env python3
"""Codex apply_patch policy and frontend lint hook."""

import json
import re
import subprocess
import sys
from pathlib import Path


payload = json.load(sys.stdin)
patch = payload.get("tool_input", {}).get("command", "")
paths = re.findall(r"^\*\*\* (?:Add|Update|Delete) File: (.+)$", patch, re.MULTILINE)

if payload.get("hook_event_name") == "PreToolUse":
    secret_names = re.compile(
        r"(?:^|/)(?:\.env(?:\..*)?|firebase-sa\.json|credentials\.json|serviceAccount[^/]*\.json)$"
    )
    lock_names = re.compile(r"(?:^|/)(?:package-lock\.json|poetry\.lock|Pipfile\.lock)$")
    if any(secret_names.search(path) for path in paths):
        print("BLOCKED: Refusing to edit secrets or credentials. Use .env.example instead.", file=sys.stderr)
        raise SystemExit(2)
    if any(lock_names.search(path) for path in paths):
        print("BLOCKED: Do not edit lock files directly. Use the package manager instead.", file=sys.stderr)
        raise SystemExit(2)
    raise SystemExit(0)

frontend = Path("taskit/taskit-frontend")
lint_paths = [
    str(Path(path).relative_to(frontend))
    for path in paths
    if path.startswith(f"{frontend}/src/") and Path(path).suffix in {".ts", ".tsx", ".js", ".jsx"}
]
if lint_paths:
    subprocess.run(["npx", "eslint", "--fix", *lint_paths], cwd=frontend, check=False)

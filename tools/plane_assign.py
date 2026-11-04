#!/usr/bin/env python3
"""Assign every Hear Me Out work item to its module and cycle."""
from __future__ import annotations

import sys
import time
from collections import defaultdict

import requests

sys.path.insert(0, r"C:\Users\morekaccino\Codes\hear-me-out\tools")
import plane_bootstrap as p

s = requests.Session()
s.headers.update(p.HEADERS)


def all_issues():
    out = {}
    cursor = None
    while True:
        url = f"{p.API}/projects/{p.PID}/issues/?per_page=100"
        if cursor:
            url += f"&cursor={cursor}"
        r = s.get(url, timeout=60)
        data = r.json()
        for item in data.get("results", []):
            out[item["name"]] = item
        if not data.get("next_page_results") or not data.get("next_cursor"):
            break
        cursor = data["next_cursor"]
    return out


def find(issues, prefix):
    for name, issue in issues.items():
        if name.startswith(prefix + " —"):
            return issue
    return None


def main():
    issues = all_issues()
    by_module = defaultdict(list)
    by_cycle = defaultdict(list)

    for e in p.EPICS:
        issue = find(issues, e["name"].split(" — ")[0])
        if issue:
            by_module[e["module"]].append(issue["id"])
            by_cycle[e["cycle"]].append(issue["id"])

    for key, *_ in p.DOCS:
        issue = find(issues, key)
        if issue:
            by_module["M0"].append(issue["id"])
            by_cycle["C0"].append(issue["id"])

    for t in p.TASKS:
        key, _epic, _name, _state, _prio, module, cycle = t[:7]
        issue = find(issues, key)
        if issue:
            by_module[module].append(issue["id"])
            by_cycle[cycle].append(issue["id"])

    print(f"modules: {[(k, len(v)) for k, v in by_module.items()]}")
    print(f"cycles: {[(k, len(v)) for k, v in by_cycle.items()]}")

    for module, ids in by_module.items():
        r = s.post(
            f"{p.API}/projects/{p.PID}/modules/{p.MODULE_IDS[module]}/module-issues/",
            json={"issues": ids},
            timeout=60,
        )
        print(f"module {module}: {r.status_code} ({len(ids)})")
        if r.status_code >= 400:
            print(r.text[:300])
        time.sleep(1)

    for cycle, ids in by_cycle.items():
        r = s.post(
            f"{p.API}/projects/{p.PID}/cycles/{p.CYCLE_IDS[cycle]}/cycle-issues/",
            json={"issues": ids},
            timeout=60,
        )
        print(f"cycle {cycle}: {r.status_code} ({len(ids)})")
        if r.status_code >= 400:
            print(r.text[:300])
        time.sleep(1)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Finish assigning Hear Me Out work items to modules and cycles, without duplicates."""
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


def member_ids(kind, group_id):
    r = s.get(f"{p.API}/projects/{p.PID}/{kind}/{group_id}/{kind}-issues?per_page=100", timeout=60)
    if r.status_code >= 400:
        return set()
    data = r.json()
    rows = data.get("results", data if isinstance(data, list) else [])
    return {row.get("id") for row in rows if isinstance(row, dict)}


def main():
    issues = all_issues()
    desired_module = defaultdict(set)
    desired_cycle = defaultdict(set)

    for e in p.EPICS:
        issue = find(issues, e["name"].split(" — ")[0])
        if issue:
            desired_module[e["module"]].add(issue["id"])
            desired_cycle[e["cycle"]].add(issue["id"])
    for key, *_ in p.DOCS:
        issue = find(issues, key)
        if issue:
            desired_module["M0"].add(issue["id"])
            desired_cycle["C0"].add(issue["id"])
    for t in p.TASKS:
        key, _epic, _name, _state, _prio, module, cycle = t[:7]
        issue = find(issues, key)
        if issue:
            desired_module[module].add(issue["id"])
            desired_cycle[cycle].add(issue["id"])

    total = 0
    for module, ids in desired_module.items():
        current = member_ids("modules", p.MODULE_IDS[module])
        missing = ids - current
        if not missing:
            print(f"module {module}: complete ({len(ids)})")
            continue
        r = s.post(
            f"{p.API}/projects/{p.PID}/modules/{p.MODULE_IDS[module]}/module-issues/",
            json={"issues": sorted(missing)}, timeout=60,
        )
        print(f"module {module}: +{len(missing)} -> {r.status_code}")
        if r.status_code >= 400:
            print(r.text[:200])
        total += len(missing)
        time.sleep(1)

    for cycle, ids in desired_cycle.items():
        current = member_ids("cycles", p.CYCLE_IDS[cycle])
        missing = ids - current
        if not missing:
            print(f"cycle {cycle}: complete ({len(ids)})")
            continue
        r = s.post(
            f"{p.API}/projects/{p.PID}/cycles/{p.CYCLE_IDS[cycle]}/cycle-issues/",
            json={"issues": sorted(missing)}, timeout=60,
        )
        print(f"cycle {cycle}: +{len(missing)} -> {r.status_code}")
        if r.status_code >= 400:
            print(r.text[:200])
        total += len(missing)
        time.sleep(1)
    print(f"added {total} memberships")


if __name__ == "__main__":
    main()

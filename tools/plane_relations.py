#!/usr/bin/env python3
"""Create the blocked_by graph on the Hear Me Out Plane project."""
from __future__ import annotations

import os
import sys
import time

import requests

sys.path.insert(0, r"C:\Users\morekaccino\Codes\hear-me-out\tools")
import plane_bootstrap as p

session = requests.Session()
session.headers.update(p.HEADERS)


def existing_relations(issue_id):
    r = session.get(f"{p.API}/projects/{p.PID}/work-items/{issue_id}/relations/", timeout=30)
    if r.status_code >= 400:
        return None
    return r.json()


def main():
    issues = {}
    cursor = None
    while True:
        url = f"{p.API}/projects/{p.PID}/issues/?per_page=100"
        if cursor:
            url += f"&cursor={cursor}"
        r = session.get(url, timeout=30)
        data = r.json()
        for item in data.get("results", []):
            issues[item["name"]] = item
        if not data.get("next_page_results") or not data.get("next_cursor"):
            break
        cursor = data["next_cursor"]

    def find(key: str):
        for name, issue in issues.items():
            if name.startswith(key + " —"):
                return issue
        return None

    created = 0
    skipped = 0
    for dependent, blockers in p.RELATIONS.items():
        dep = find(dependent)
        if not dep:
            print(f"missing dependent {dependent}")
            continue
        rels = existing_relations(dep["id"]) or {}
        current = {x.get("issue_id") for x in rels.get("blocked_by", []) if isinstance(x, dict)}
        ids = [find(b)["id"] for b in blockers if find(b)]
        ids = [i for i in ids if i not in current]
        if not ids:
            skipped += 1
            continue
        r = session.post(
            f"{p.API}/projects/{p.PID}/work-items/{dep['id']}/relations/",
            json={"relation_type": "blocked_by", "issues": ids},
            timeout=30,
        )
        print(f"{dependent} <- {len(ids)} blockers: {r.status_code}")
        if r.status_code >= 400:
            print(r.text[:300])
        else:
            created += 1
        time.sleep(0.7)
    print(f"done: {created} relation groups created, {skipped} already complete")


if __name__ == "__main__":
    main()

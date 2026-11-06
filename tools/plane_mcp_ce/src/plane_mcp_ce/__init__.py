"""Plane MCP server for self-hosted Community Edition, with a relation fix.

`plane-mcp-server-ce` 0.4.0 targets Plane CE but its relation read fails on
Plane 1.4.x: the instance returns each relation as
``{"project_id": ..., "issue_id": ...}`` while ``plane-sdk`` expects a plain
list of issue IDs, so validation raises before the tool can answer.

This wrapper normalizes that payload, then hands control to the upstream
server unchanged. Everything else is stock ``plane-mcp-server-ce``.
"""

from __future__ import annotations

from typing import Any


def _normalize(response: Any) -> dict[str, list[str]]:
    groups: dict[str, list[str]] = {}
    for relation_type, items in (response or {}).items():
        ids: list[str] = []
        for item in items or []:
            if isinstance(item, str):
                ids.append(item)
            elif isinstance(item, dict):
                value = (
                    item.get("issue_id")
                    or item.get("related_work_item_id")
                    or item.get("id")
                )
                if value:
                    ids.append(value)
        groups[relation_type] = ids
    return groups


def _patch() -> None:
    from plane.api.work_items.relations import WorkItemRelations
    from plane.models.work_items import WorkItemRelationResponse

    if getattr(WorkItemRelations.list, "_plane_ce_fixed", False):
        return

    def list_relations(
        self: Any, workspace_slug: str, project_id: str, work_item_id: str
    ) -> Any:
        response = self._get(
            f"{workspace_slug}/projects/{project_id}/work-items/{work_item_id}/relations"
        )
        return WorkItemRelationResponse.model_validate(_normalize(response))

    list_relations._plane_ce_fixed = True  # type: ignore[attr-defined]
    WorkItemRelations.list = list_relations  # type: ignore[method-assign]


def main() -> None:
    _patch()
    from plane_mcp.__main__ import main as server_main

    server_main()


if __name__ == "__main__":
    main()

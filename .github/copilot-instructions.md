# Copilot instructions

Read `AGENTS.md` and `docs/PLANE.md` before changing code.

Plane is the source of truth for product direction, work breakdown, research,
decisions, risks, and delivery status.

- Project: <https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780>
- Start here: `D0.1 — START HERE`
  <https://plane.mrkazemi.com/hear-me-out/projects/8c4e095a-f411-4e2d-8f92-f558b6701780/issues/3bc42073-d36c-48df-b7bc-27ad89338ac7>
- Plane MCP config: `.vscode/mcp.json` (server name `plane`)
- Approved plan: `docs/TRANSFORMATION_PLAN_FINAL.md`

Before coding, read the ticket acceptance criteria and check `blocked_by`. After
coding, run `flutter analyze`, `flutter test`, and `flutter build web --release`,
then update the ticket with evidence. The current code is still the 240-lesson
notation course; the approved transformation is planned but not implemented.

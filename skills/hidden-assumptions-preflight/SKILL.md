---
name: hidden-assumptions-preflight
description: Use before implementation, code changes, automation, integrations, CMS work, admin-panel work, or user-facing deliverables when maintenance path, ownership, data source, or editable workflow could be broken by a shortcut.
---

# Hidden Assumptions Preflight

Use this before implementing. The point is to avoid building the visible request while breaking the real workflow behind it.

## Mandatory Preflight

Before editing files, installing, deploying, or proposing a concrete implementation, answer these questions in your own reasoning and surface the important parts when risk exists:

1. What is the real artifact: demo, prototype, internal tool, or production deliverable?
2. Who will maintain it after handoff?
3. Through what workflow will they maintain it: CMS, admin panel, config file, API, spreadsheet, database, dashboard, or command?
4. What existing source of truth must remain authoritative?
5. Would the proposed implementation bypass, duplicate, cache, hard-code, or shadow that source of truth?
6. What domain common sense applies here?
7. If a shortcut is tempting, what future user action would fail because of it?

If the answers reveal a maintenance or ownership risk, design around the real workflow or explicitly confirm the tradeoff before proceeding.

## Hard Rules

- Do not hard-code content, editable labels, images, business data, routes, credentials, or operational state when users reasonably expect to manage them through an existing system.
- Do not replace a source of truth with copied snapshots, local constants, generated files, or theme code unless the user explicitly wants a static demo.
- Do not optimize only for what looks correct in a screenshot.
- Preserve the native maintenance path by default.
- When adding multilingual support, prefer a maintainable content workflow over hard-coded translations.

## Output Shape

For small tasks, one sentence is enough:

> I will keep the existing source of truth authoritative and only change presentation or glue code.

For risky tasks, state the risk and the chosen design:

> This system is maintained through an admin workflow, so hard-coding the visible content would create a shadow copy. I will keep the admin-managed source authoritative and limit the change to presentation and mapping.

## Completion Check

Before claiming completion, verify at least one real maintenance path when applicable:

- inspect or update the authoritative source
- confirm the output reads from that source
- confirm the implementation did not introduce a second place future users would have to edit

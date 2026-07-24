---
name: search-first
description: >
  写代码前先搜：仓库内已有实现 → 现有依赖 → 外部包/文档。触发词：新功能、加依赖、
  新 helper/抽象、search first、别重复造轮子。Do NOT use for pure Q&A or when the
  user already named the exact existing module to change.
---

# search-first

Adapted from ECC `skills/search-first`, trimmed for bun-nolo / nolo-plan.

**Goal:** Prefer adopt / extend over invent. Aligns with nolo-plan 实现阶梯.

## When

- New feature that likely exists in-repo or as a maintained lib
- Adding a dependency or integration
- About to create a new utility / helper / abstraction
- User says "加个 X" and the first impulse is greenfield code

Skip: typo/docs-only, user pointed at the exact file, pure Q&A.

## Workflow (stop at first solid hit)

1. **Need** — one sentence: capability + constraints (lang, runtime, license).
2. **Repo first** — `rg` / Glob for similar modules, tests, skills under `docs/skills` and `.agents/skills`. Prefer extend existing seams.
3. **Deps next** — check `package.json` / workspace packages before adding anything.
4. **Outside** — only if 2–3 miss: registry docs, GitHub, official docs. Report which channels you actually searched; if a channel was unavailable, say so (no silent "nothing found").
5. **Decide**

| Signal | Action |
|--------|--------|
| In-repo match | **Extend** that path |
| Dep already present | **Use** it; thin wrap only if needed |
| Small maintained lib, clear license | **Adopt** |
| Weak / heavy / wrong license | **Build minimal** — informed by what you found |

6. **Implement** only after the decision is written (even one line in the plan/spec).

## bun-nolo notes

- Prefer platform primitives (doc/table/agent/dialog/skill) over new concepts.
- New npm deps need a real gap vs workspace packages — don't pull a large package for one helper.
- Orchestration / dispatch stays in `nolo-plan`; this skill does not replace it.
- Do not invent a "researcher agent" — search with tools you have (`rg`, `gh`, web, docs).

## Anti-patterns

- Jumping to custom code without repo search
- Claiming "nothing exists" after skipping the registry or `gh`
- Wrapping a lib until it loses its value
- Installing a mega-package for a 20-line need

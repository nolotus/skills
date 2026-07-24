---
name: click-path-audit
description: >
  追踪按钮/触点的完整状态变迁，抓「函数各自对但互相抵消」的 UI/状态 bug。触发词：
  按钮点了没反应、共享 store 重构后、Redux/dialog/composer 联动、click-path、状态互相踩。
  Do NOT use for API 契约错误、纯样式、或无共享状态的纯后端改动。
---

# click-path-audit

Adapted from ECC/community `skills/click-path-audit`, trimmed for bun-nolo.

**Goal:** Find bugs static review misses — sequential undo, async races, effect resets, label-vs-final-state mismatch.

## When

- Users say a button "does nothing" after wiring looks fine
- After changing shared client state (Redux slice → module store, dialog config, composer, object assistant, quick-chat routing)
- Before release on a critical interactive flow
- After systematic debugging found "no bug" but the UI still lies

Skip: wrong API shape, CSS-only, no shared state, pure docs.

## Expensive — scope hard

Pick one scope per run:

| Scope | Use when |
|-------|----------|
| One touchpoint | Known broken button |
| One surface | e.g. QuickChat / MessageInput / ObjectAssistant |
| Store-focused | One store/actions changed — audit **callers** of those actions |

Do **not** full-app audit unless owner asks. Prefer one store map + one surface.

## Workflow

### 1. Map stores / actions in scope

For each store/slice/module API touched:

```
ACTION → { sets: [...], resets / clears: [...] }
```

Flag **dangerous resets**: actions that clear fields they don't "own".

bun-nolo hotspots (examples, not exhaustive): dialog config, `extraReferences`, quick-chat routing, object-assistant panel, auth-scoped client clear, workflow/module stores peeled out of Redux.

### 2. Trace each touchpoint

For each button / submit / toggle in scope:

1. Find handler (`onClick` / `onPress` / send path)
2. List calls **in order**
3. Per call: reads? writes? async? resets?
4. Ask:
   - Does a later call **undo** an earlier write?
   - Does a `useEffect` / subscriber reset what the handler set?
   - Is final state what the **label** promises?
   - Async resolve order race?

### 3. Patterns to check

1. **Sequential undo** — A sets X; B resets X  
2. **Async race** — two updates; final state depends on finish order  
3. **Stale closure** — handler closes over old state  
4. **Missing transition** — label says Save/Send but never persists/calls API  
5. **Dead branch** — guard always false in this context  
6. **Effect interference** — effect watches and clears handler result  

### 4. Report

```
CLICK-PATH-NNN: [CRITICAL|HIGH|MEDIUM|LOW]
  Touchpoint: [label] @ file:line
  Pattern: [Sequential Undo | ...]
  Trace:
    1. call → sets {...}
    2. call → RESETS {...}  ← CONFLICT
  Expected: ...
  Actual: ...
  Fix: ...
```

Every confirmed bug should get a focused regression test when practical (see Cursor `testing` rule — reverse-verify).

## bun-nolo notes

- Prefer evidence from code + existing tests; browser proof via `frontend-local-fix-workflow` / e2e when static trace is insufficient.
- Dispatch with nolo-plan: state/UI refactors may `--skill ~/skills/click-path-audit/SKILL.md` **in addition to** UI + Coding Style skills.
- Pair with `root-cause-debugging` for non-UI root causes; this skill is for **interaction/state sequencing**.

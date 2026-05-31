---
name: improve-codebase-architecture
description: Use when reviewing a codebase for refactoring opportunities, module boundaries, seam design, testability, or navigability, especially when the user wants architecture feedback that is not tied to one specific repository.
---

# Improve Codebase Architecture

Surface architectural friction and propose deepening opportunities: refactors that hide more behavior behind smaller, clearer interfaces. The goal is better locality, leverage, testability, and navigability.

## Terms

Use these terms consistently:

- Module: anything with an interface and an implementation.
- Interface: what a caller must know to use the module, including invariants, failure modes, ordering, and configuration.
- Implementation: the code inside the module.
- Depth: how much behavior is hidden behind the interface.
- Seam: where behavior can change without editing the caller in place.
- Adapter: a concrete implementation that sits behind a seam.
- Locality: changes and bugs stay concentrated.
- Leverage: callers get more value from knowing less.

## Core Heuristics

- Deletion test: imagine deleting the module. If complexity vanishes, it was probably shallow. If the same complexity reappears across many callers, it was earning its keep.
- The interface is the test surface.
- One adapter suggests a hypothetical seam. Two adapters suggest a real seam.
- Small files are not automatically good architecture. Prefer concentrated behavior over pass-through fragmentation.

## Process

### 1. Explore

Read the codebase structure, domain docs, and architectural notes that already exist.

Then inspect the code and look for friction:

- understanding one concept requires bouncing across many tiny modules
- interfaces are nearly as complicated as the implementation behind them
- logic is split for testability, but the real bugs come from orchestration between callers
- seams leak implementation details
- tests are hard to write through the current interface

### 2. Present Candidates

Present a numbered list of architecture opportunities. For each one, include:

- Files or modules involved
- Problem
- Proposed direction
- Benefits in terms of locality, leverage, and testability
- Risk or migration cost

Do not jump straight into a detailed interface proposal unless the user asks.

### 3. Drill Into One Candidate

Once the user picks a candidate, work the design in more detail:

- what concept the deepened module should own
- what should move behind the seam
- what should remain visible at the interface
- which tests get easier or more meaningful
- whether the current naming matches the real concept

If the codebase already has a glossary, ADRs, or architectural rules, follow them unless there is a strong reason to revisit them.

## Output Style

Prefer findings over vague praise. A good recommendation is concrete enough that an engineer could decide whether to do it.

For each recommendation, explain:

- why the current shape creates friction
- what change would concentrate responsibility
- why that change improves maintenance instead of just moving files around

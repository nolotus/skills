# Nolotus Skills Collection

A public collection of reusable skills for AI coding agents.

These skills are written to be portable across projects and tools. The default assumption is:

- core skills live here
- repo-specific adapters stay in each project
- private workflows, secrets, product semantics, and local absolute paths do not belong in these public skills

## Design Principles

- Portable first: skills should work outside Nolotus projects by default.
- Adapter-friendly: if a project needs local conventions, add a repo-specific adapter there instead of hard-coding it here.
- Minimal assumptions: do not assume one editor, one CLI, one operating system, or one repo layout unless the skill is explicitly about that.
- Public-safe: do not include secrets, private endpoints, internal account details, or product-only maintenance rules.

## Skills

### `multi-cli-sync`
Use when a user wants one source of truth for personal skills and entry guidance, then needs to sync them across Codex, Claude, Gemini, or other local CLI agents.

### `hidden-assumptions-preflight`
Use before implementation when maintenance path, ownership, editable source of truth, or operational workflow matters more than the immediate visible output.

### `improve-codebase-architecture`
Use when reviewing a codebase for refactoring, seam design, module depth, and opportunities to improve testability and navigability without binding the advice to one company or repo.

## Usage

Install or copy a skill folder into the target agent's skill directory, or point your agent tooling at this repository if it supports remote skills.

When adapting a public skill for one repository:

1. keep the public core here
2. put repo-specific guidance in that repository
3. avoid making the public skill depend on private files or product language

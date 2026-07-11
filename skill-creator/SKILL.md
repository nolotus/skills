---
name: skill-creator
description: >
  Create, improve, and validate agent skills. Use when the user wants to create a new skill, update an existing skill, turn a workflow into a reusable skill, or validate skill format. This is the meta-skill for skill authoring — read it before creating or editing any skill.
---

# Skill Creator

A skill that teaches the agent how to create and maintain skills.

## Quick Reference

```bash
bun scripts/init.ts <name>     # create a new skill from template
bun scripts/validate.ts <path> # check a skill for format errors
```

These scripts ship with this skill in the `scripts/` directory. They are reference implementations — adapt them to your project's conventions.

---

## What is a Skill

A skill is a Markdown file with YAML frontmatter that extends the agent's capabilities with specialized knowledge, workflows, or tool integrations.

```
docs/skills/<name>.md
```

Minimum viable skill:

```yaml
---
name: my-skill
description: >
  What this skill does and when to trigger.
  Include specific keywords, file types, and user phrases.
---

# My Skill

## Overview
...

## Boundaries
- What this skill does NOT do
```

---

## Core Principles

### Concise is Key

The context window is shared by everything: system prompt, conversation history, other skills' metadata, and the user's request. **Default assumption: the agent is already smart.** Only add context it doesn't already have. Challenge each sentence with three questions: Can the agent figure this out without being told? → Delete it. Is this repeated in another skill? → Reference that skill instead. Is this detailed reference material? → Consider a `references/` file loaded on demand. Prefer short examples over long explanations.

### Degree of Freedom

Match the level of specificity to the task's fragility:

- **High** (text instructions) — multiple valid approaches, decisions depend on context
- **Medium** (templated scripts with parameters) — a preferred pattern exists, some variation OK
- **Low** (exact scripts, rigid structure) — the operation is fragile, consistency critical

### What to Not Include

A skill should only contain files that directly support its function. NEVER create `README.md`, `INSTALLATION_GUIDE.md`, `CHANGELOG.md`, or auxiliary docs about the creation process. The skill is for the agent to do the job — not for humans to read about how it was made.

---

## Skill Creation Process

### Step 1: Understand the Intent

#### 1a. Should This Even Be a Skill?

Not every request deserves a skill. A skill that shouldn't exist causes more damage than no skill: fuzzy triggering wastes context, vague output erodes trust, and dead skills pollute the registry.

**Reject skill creation when the request is only:** a one-off answer, a summary/translation, brainstorming without reusable output, documentation requiring no agent execution, or an implementation task with no repeated workflow. If it doesn't pass this gate, tell the user directly and offer to do the task without creating a skill.

**One-sentence test:** Stop and reconsider if you cannot describe the skill clearly in one sentence. "It helps with code review" is too vague. "It reviews TypeScript PRs for bugs, style, and architecture, and returns a structured report with severity levels" passes.

#### 1b. Diagnose Fuzzy Requests

When the user describes a pain point rather than a skill request ("I keep having to manually check X"), diagnose before asking for structure:

- Is this best served by a skill, a script, a doc, or just doing it once?
- If a skill fits, what's the lightest shape: workflow, checklist, reference, or tool wrapper?
- Recommend at most two directions; explain why each fits and where it's limited.

#### 1c. Ask the Right Questions

Before writing anything, understand the core. Ask **2-3 questions max per turn** — don't dump a form. Core questions: (1) What recurring job should this skill own? (2) What real inputs will people hand to it? (3) What finished output should it return? (4) What nearby requests should it explicitly refuse?

**Question ordering matters:** ask boundary questions early ("what should it NOT do?"), ask output questions before architecture questions ("what does success look like?" before "what structure?"), and stop once you can describe the skill in one clear sentence.

#### 1d. Conversation Tone

Match your tone to the user's state, not to a template. When the idea is fuzzy, sit beside them and help sort it out first; when the goal is clear, lead with structure; when they want to co-create, discuss as equals and extract boundaries from the conversation. First reply must never be a cold form-style questionnaire, and never push a full template before understanding the real job.

### Step 2: Plan the Structure

Pick one of three patterns based on the skill's nature:

**Workflow-based** — sequential processes with clear steps.

```
## Overview → ## Workflow → ## Step 1 → ## Step 2 → ...
```

Best for: deployment, publishing, debugging procedures.

**Task-based** — collection of related operations.

```
## Overview → ## Quick Start → ## Task A → ## Task B → ...
```

Best for: CLI references, tool collections, API guides.

**Reference-based** — standards, schemas, policies.

```
## Overview → ## Rules → ## Examples → ## Boundaries
```

Best for: code review guidelines, brand standards, architectural principles.

### Step 3: Initialize

Run the init script to create the file from template:

```bash
bun scripts/init.ts <skill-name>
```

The name is normalized to kebab-case automatically (e.g., "My Skill" → `my-skill`). Creates `<skill-name>/SKILL.md` in the current directory. The template includes: YAML frontmatter with TODO placeholders, commented-out `triggers` and `assertions` fields, structural guidance (HTML comment, delete after choosing pattern), and a `## Boundaries` section placeholder.

### Step 4: Write the SKILL.md

#### Frontmatter

Fill in the `description` first — it's the ONLY thing the agent sees before deciding to load a skill, and the primary triggering mechanism. Agents have a tendency to **undertrigger** — to not use skills even when they'd help. Combat this with "pushy" language.

**Good description pattern:**

```yaml
description: >
  [What it does]. Use when [specific triggers, keywords, contexts].
```

Rules:

- Include both what the skill does AND when to use it; all "when to use" info goes in the description, not the body
- Be specific about trigger phrases (formal AND casual); mention file types, tools, or contexts
- Use "pushy" phrasing ("Make sure to use this skill whenever...")
- Include near-miss exclusions so the agent knows when NOT to use it
- Keep under 1024 characters; no angle brackets (`<` `>`)

Bad: `"Helps with code review."`
Good: `"Review code for bugs, style, and architecture. Make sure to use this skill whenever the user mentions 'review', 'code check', 'audit this', 'PR diff', or 'lint errors' — even if they don't explicitly say 'code review'. Do NOT use for writing new code from scratch."`

**Optional frontmatter fields** (design documentation only, no automated runner):

```yaml
# triggers:    # - query: 'create a skill for code review'; expect: match
# assertions:  # - '输出包含 severity 字段'
```

#### Body

Writing guidelines:

- Use imperative form ("Read the file", "Check the format")
- Explain **why**, not just **what** — agents are smart enough to reason from principles
- Prefer short examples over long explanations
- Reference other skills with backtick-quoted names (`` `other-skill` ``)
- Keep SKILL.md lean; use `references/` for detailed docs only when truly needed
- Delete the HTML comment with structural guidance after choosing a pattern

Every skill must have a `## Boundaries` section listing what it intentionally does NOT do — a skill without boundaries gradually absorbs adjacent tasks until it becomes unreliable; explicitly listing what it does NOT handle is the fastest way to improve triggering accuracy.

### Step 5: Validate

```bash
bun scripts/validate.ts <path-to-skill-directory>
```

Checks: SKILL.md exists; YAML frontmatter is valid; name is kebab-case, ≤64 chars; description exists, no `<>`, ≤1024 chars, no TODO left. Fix all errors before considering the skill done. Warnings (TODO placeholder, long description) are informational.

### Step 6: Iterate

Improve by the smallest change that increases reliability more than it increases context cost. A larger package is only better when routing, execution, or governance becomes materially more reliable. When a skill repeatedly produces bad output, the root cause is rarely one bad instruction — it's usually a structural problem. Before adding more prose, ask:

1. What does this skill **own**? Is the boundary clear?
2. What **feedback** tells us it's improving or drifting?
3. Which failure will appear only after **repeated use**?
4. Where is the **smallest change** with the largest quality gain?

Priority order: tighten boundary and description (cheapest, highest impact) → add execution assets only when work repeats → add references only when they remove genuine ambiguity → add gates only when risk justifies maintenance cost.

Watch for symptoms: **Undertriggering** (should have been used but wasn't → improve description); **Overtriggering** (used when it shouldn't have been → add exclusion keywords); **Confusion** (followed but wrong output → clarify workflow); **Bloat** (too long for value → trim); **Drift** (absorbs adjacent tasks → re-check Boundaries). Never treat iteration as "make the package bigger."

---

## Cross-Platform Compatibility

This skill system follows the Agent Skills open standard (Anthropic/OpenAI compatible). Frontmatter uses `name` (kebab-case, ≤64 chars) + `description` (required, no angle brackets); optional fields include `triggers`, `assertions`, `license`, `metadata`, `compatibility`.

```
skill-name/
├── SKILL.md          (required)
├── agents/           (optional — platform-specific metadata)
├── references/       (optional — docs loaded on demand)
├── scripts/          (optional — executable code)
└── assets/           (optional — templates, images, fonts)
```

---

## Common Mistakes

| Mistake | Fix |
|---|---|
| Description is generic ("helps with X") | Add specific trigger phrases and contexts |
| "When to use" info is in the body | Move it to the description |
| Description contains angle brackets | Remove `<>` (they break XML parsing) |
| Skill name doesn't match registry | Run `validate.ts` to catch mismatches |
| Created file but forgot to register | Use `init.ts` instead of manual file creation |
| No Boundaries section | Add at least one thing the skill does NOT do |
| Body too long (>500 lines) | Split into SKILL.md + references/ |

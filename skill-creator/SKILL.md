---
name: skill-creator
description: >
  Create, improve, and validate agent skills. Use when the user wants to
  create a new skill, update an existing skill, turn a workflow into a
  reusable skill, or validate skill format. This is the meta-skill for
  skill authoring — read it before creating or editing any skill.
---

# Skill Creator

A skill that teaches the agent how to create and maintain skills.

## Quick Reference

```bash
bun scripts/init.ts <name>        # create a new skill from template
bun scripts/validate.ts <path>    # check a skill for format errors
```

These scripts ship with this skill in the `scripts/` directory. They are reference implementations — adapt them to your project's conventions.

---

## What is a Skill

A skill is a Markdown file with YAML frontmatter. It extends the agent's capabilities with specialized knowledge, workflows, or tool integrations.

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

The context window is shared by everything: system prompt, conversation history, other skills' metadata, and the user's request. **Default assumption: the agent is already smart.** Only add context it doesn't already have. Challenge each sentence: "Does the agent really need this?"

Prefer short examples over long explanations.

### Degree of Freedom

Match the level of specificity to the task's fragility:

| Freedom | When to use | Example |
|---|---|---|
| **High** (text instructions) | Multiple approaches are valid, decisions depend on context | "Review the code and suggest improvements" |
| **Medium** (pseudocode or scripts with parameters) | A preferred pattern exists, some variation is OK | "Use this template for the report, but adjust sections as needed" |
| **Low** (exact scripts, rigid structure) | The operation is fragile, consistency is critical | "ALWAYS run `validate.ts` before committing a skill" |

Think of the agent as walking a path: a narrow bridge over a cliff needs guardrails (low freedom); an open field allows many routes (high freedom).

### What to Not Include

A skill should only contain files that directly support its function. NEVER create:

- `README.md`
- `INSTALLATION_GUIDE.md`
- `CHANGELOG.md`
- Auxiliary docs about the creation process

The skill is for the agent to do the job — not for humans to read about how it was made.

---

## Skill Creation Process

### Step 1: Understand the Intent

#### 1a. Should This Even Be a Skill?

Not every request deserves a skill. A skill that shouldn't exist causes more damage than no skill: fuzzy triggering wastes context, vague output erodes trust, and dead skills pollute the registry.

**Reject skill creation when the request is only:**
- a one-off answer or explanation
- a summary or translation
- brainstorming without reusable output
- documentation that requires no agent execution
- an implementation task with no repeated workflow

If it doesn't pass this gate, tell the user directly and offer to do the task without creating a skill.

**One-sentence test:** Stop and reconsider if you cannot describe the skill clearly in one sentence. "It helps with code review" is too vague. "It reviews TypeScript PRs for bugs, style, and architecture, and returns a structured report with severity levels" passes.

#### 1b. Diagnose Fuzzy Requests

When the user describes a pain point rather than a skill request ("I keep having to manually check X"), diagnose before asking for structure:

- Is this best served by a skill, a script, a doc, or just doing it once?
- If a skill fits, what's the lightest shape: workflow, checklist, reference, or tool wrapper?
- Recommend at most two directions; explain why each fits and where it's limited.

#### 1c. Ask the Right Questions

Before writing anything, understand the core. Ask **2-3 questions max per turn** — don't dump a form.

Core questions:

1. What recurring job should this skill own?
2. What real inputs will people hand to it?
3. What finished output should it return?
4. What nearby requests should it explicitly refuse?

**Question ordering matters:**
- Ask boundary questions early ("what should it NOT do?")
- Ask output questions before architecture questions ("what does success look like?" before "what structure?")
- Stop once you can describe the skill in one clear sentence

#### 1d. Conversation Tone

Match your tone to the user's state, not to a template:

| User state | Tone | Example opening |
|---|---|---|
| Idea is fuzzy, needs to be heard first | **Gentle companion** — sit beside them, help them sort it out | "没关系，不完整也可以。你先说说最想让这个 skill 帮你接住哪类重复工作？" |
| Goal is clear, wants efficiency | **Direct coach** — lead with structure, don't make them fill forms | "我们先把这件事讲清楚。你告诉我三件事：核心任务、常见输入、理想产出。" |
| Has ideas, wants to refine together | **Co-creator** — discuss as equals, extract structure from conversation | "我们当成共创来做。你先说说最值得被做出来的地方是什么，我帮你收边界。" |

**Dialogue anti-patterns — NEVER do these:**
- First reply feels like a cold worksheet instead of a conversation
- Push a full template before understanding the real job
- Ask about package structure before clarifying the desired outcome

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

The name is normalized to kebab-case automatically (e.g., "My Skill" → `my-skill`). Creates `<skill-name>/SKILL.md` in the current directory.

The template includes:
- YAML frontmatter with TODO placeholders
- Commented-out `triggers` and `assertions` fields
- Structural guidance (HTML comment, delete after choosing pattern)
- `## Boundaries` section placeholder

### Step 4: Write the SKILL.md

#### Frontmatter

Fill in the `description` first — it's the primary triggering mechanism. The agent uses it to decide whether to load this skill.

**Good description pattern:**
```yaml
description: >
  [What it does]. Use when [specific triggers, keywords, contexts].
  Example: "Create and validate agent skills. Use when user says
  'create a skill', 'make a skill', 'new skill', or wants to turn
  a workflow into a reusable skill."
```

Rules:
- Include both what the skill does AND when to use it
- All "when to use" info goes in the description, not the body
- Be specific about trigger phrases
- Keep under 1024 characters
- No angle brackets (`<` `>`)

**Optional frontmatter fields:**

```yaml
# triggers:         # test cases for skill triggering
#   - query: 'create a skill for code review'
#     expect: match
#   - query: '今天天气怎么样'
#     expect: no_match
#
# assertions:       # output quality checks
#   - '输出包含 severity 字段'
#   - '每个问题都有修复建议'
```

`triggers` and `assertions` are optional. They serve as design documentation — there is no automated runner. Writing them forces you to think about what should trigger the skill and what good output looks like.

#### Body

Writing guidelines:
- Use imperative form ("Read the file", "Check the format")
- Explain **why**, not just **what** — agents are smart enough to reason from principles
- Prefer short examples over long explanations
- Reference other skills with backtick-quoted names (`` `other-skill` ``)
- Keep SKILL.md lean; use `references/` for detailed docs only when truly needed
- Delete the HTML comment with structural guidance after choosing a pattern

Every skill must have a `## Boundaries` section listing what it intentionally does NOT do.

### Step 5: Validate

```bash
bun scripts/validate.ts <path-to-skill-directory>
```

Checks:
- SKILL.md exists
- YAML frontmatter is valid
- name is kebab-case, ≤64 chars
- description exists, no `<>`, ≤1024 chars, no TODO left

Fix all errors before considering the skill done. Warnings (TODO placeholder, long description) are informational.

### Step 6: Iterate

**The minimum improvement principle:** improve by the smallest change that increases reliability more than it increases context cost. A larger package is only better when routing, execution, or governance becomes materially more reliable.

**Priority order for improvements:**
1. Tighten boundary and description (cheapest, highest impact)
2. Add execution assets only when the same work is being repeated
3. Add references only when they remove genuine ambiguity
4. Add gates only when risk justifies maintenance cost

**Watch for these symptoms:**
- **Undertriggering**: the skill should have been used but wasn't → improve the description
- **Overtriggering**: the skill was used when it shouldn't have been → add exclusion keywords to description
- **Confusion**: the agent follows the skill but produces wrong output → clarify the workflow
- **Bloat**: the skill is too long for the value it provides → trim
- **Drift**: the skill gradually absorbs adjacent tasks it shouldn't handle → re-check the Boundaries section

Never treat iteration as "make the package bigger." Prefer one strong next step over five vague upgrades.

---

## Writing Tips

### Description as Trigger

The `description` field is the ONLY thing the agent sees before deciding to load a skill. Agents have a tendency to **undertrigger** — to not use skills even when they'd help. Combat this with "pushy" language.

- Use "pushy" phrasing: "Make sure to use this skill whenever..."
- List specific trigger phrases users actually say (formal AND casual)
- Mention file types, tools, or contexts that signal this skill is needed
- Include near-miss exclusions so the agent knows when NOT to use it

Bad: `"Helps with code review."`
Good: `"Review code for bugs, style, and architecture. Make sure to use this skill whenever the user mentions 'review', 'code check', 'audit this', 'PR diff', or 'lint errors' — even if they don't explicitly say 'code review'. Do NOT use for writing new code from scratch."`

### Lean Body

The body is loaded only after triggering — but it still costs context. Every line must justify its token cost:

- Can the agent figure this out without being told? → Delete it.
- Is this repeated in another skill? → Reference that skill instead.
- Is this detailed reference material? → Consider a `references/` file loaded on demand.

### Boundaries Matter

A skill without boundaries gradually absorbs adjacent tasks until it becomes unreliable. Explicitly list what the skill does NOT handle. This is the fastest way to improve triggering accuracy.

### Structure Drives Behavior

When a skill repeatedly produces bad output, the root cause is rarely one bad instruction — it's usually a structural problem: a fuzzy boundary, a missing feedback loop, or a slow drift into adjacent territory.

Before adding more prose to fix a problem, ask:

1. What does this skill **own**? Is the boundary clear?
2. What **feedback** tells us it's improving or drifting?
3. Which failure will appear only after **repeated use**?
4. Where is the **smallest change** with the largest quality gain?

Usually the answer is: clarify the description, tighten the boundaries, or add one self-repair check — not add more text.

---

## Cross-Platform Compatibility

This skill system follows the Agent Skills open standard (Anthropic/OpenAI compatible):

- **Directory structure**: `skill-name/SKILL.md`
- **YAML frontmatter**: `name` (kebab-case, ≤64 chars) + `description` (required)
- **No angle brackets** in description
- **Optional fields**: `triggers`, `assertions`, `license`, `metadata`, `compatibility`
- **Optional directories**: `agents/`, `references/`, `scripts/`, `assets/`

```
skill-name/
├── SKILL.md          (required)
├── agents/           (optional — platform-specific metadata)
├── references/       (optional — docs loaded on demand)
├── scripts/          (optional — executable code)
└── assets/           (optional — templates, images, fonts)
```

Skills following this format can be installed on Claude Code, Codex, Cursor, GitHub Copilot, and other platforms with minimal modification.

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

---

## Tool Reference

| Command | What it does |
|---|---|
| `bun scripts/init.ts <name>` | Create `./<name>/SKILL.md` from template |
| `bun scripts/validate.ts <path>` | Check a skill directory for format errors |

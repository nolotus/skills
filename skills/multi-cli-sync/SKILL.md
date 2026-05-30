---
name: Multi-CLI Skill Sync
description: "A zero-dependency (pure Bash) workflow to synchronize personal skills across multiple AI agents (Codex, Claude, etc.) and prevent drift. Trigger via /setup-sync"
---

# Multi-CLI Skill Synchronizer

This skill helps users solve a common problem: "How do I synchronize my personal AI skills across different CLI agents (like Claude and Codex) without writing complex scripts?"

This skill uses **zero dependencies**. It relies entirely on native Bash commands (`cp`, `diff`), meaning it works on Mac and Linux without requiring Node, Bun, or Python.

## Commands

### `/setup-sync`

When the user types `/setup-sync`, act as their **Personal Workflow Assistant** and follow these exact steps:

#### 1. Ask for CLI Targets
Ask the user (in Chinese):
> "为了帮你配置跨 CLI 的技能同步方案，请告诉我：
> 1. 你通常使用哪些 AI Agent？(例如 Claude Code, Codex, Gemini 等)
> 2. 它们的全局技能目录分别在哪里？(例如 Codex 通常是 `~/.codex/skills`，如果你不确定，我可以帮你采用默认结构并留出配置项。)"

#### 2. Wait for Confirmation
Stop execution and wait for the user to reply.

#### 3. Create the Directory Structure
Create a dedicated folder for their personal skills in the root of their repository:
- `mkdir -p my-skills scripts`

#### 4. Read the Templates
Read the template bash scripts provided in this skill's repository structure:
- `templates/sync.sh`
- `templates/check.sh`

*(If you cannot access the templates folder directly, use your knowledge of pure bash scripts to generate a `sync.sh` using `cp` and a `check-drift.sh` using `diff`.)*

#### 5. Generate and Customize Scripts
Write the `scripts/sync.sh` and `scripts/check.sh` files to the user's workspace.
**Crucial Adaptation:** Modify the `TARGET_DIRS` array in both bash scripts to include the actual paths the user provided in Step 1. 

Additionally, adapt the `cp` logic based on how the target CLI expects skills:
- If the CLI expects a flat markdown file (e.g., `~/.claude/skills/my-skill.md`), use flat copying.
- If the CLI expects a folder with a `SKILL.md` inside (e.g., `~/.codex/skills/my-skill/SKILL.md`), modify the bash script to create the folder and rename the file during copying.

Make both scripts executable:
- `chmod +x scripts/sync.sh scripts/check.sh`

#### 6. Inform the User
Inform the user that the zero-dependency synchronization workflow is ready. Tell them to:
1. Place any personal `.md` skills inside the `my-skills/` directory.
2. Run `./scripts/sync.sh` to distribute them to Claude/Codex.
3. Run `./scripts/check.sh` periodically (or in a git pre-commit hook) to ensure they haven't accidentally modified the skills externally without syncing them back.

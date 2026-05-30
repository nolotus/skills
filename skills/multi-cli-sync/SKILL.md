---
name: Multi-CLI Skill & Guidance Synchronizer
description: "A zero-dependency workflow to synchronize personal skills across AI agents AND generate central entry guidance files (AGENTS.md, etc.). Supports Win/Mac/Linux. Trigger via /setup-sync"
---

# Multi-CLI Skill & Guidance Synchronizer

This skill solves two major problems for AI developers:
1. **Guidance Sync**: Generating root-level instruction files (`AGENTS.md`, `CLAUDE.md`, `.cursorrules`) that all point to a single central document, enforcing a "Drift Rule".
2. **Global Skill Sync**: Distributing personal markdown skills to external global directories (like `~/.codex/skills`) and checking for drift.

It uses **zero dependencies**, relying entirely on native Bash (`.sh`) for Mac/Linux and PowerShell (`.ps1`) for Windows.

## Commands

### `/setup-sync`

When the user types `/setup-sync`, act as their **Personal Workflow Assistant** and follow these steps exactly:

#### 1. Auto-Detect Environment & Targets
Do NOT ask the user for their OS. Use your environment access (e.g., running `uname`, checking `sys.platform`, or inspecting env vars) to automatically detect if they are on Windows or Mac/Linux.

Do NOT ask the user for their CLI global directories if you can detect them. Proactively check the user's home directory (e.g., `ls -a ~`) for common AI CLI config folders like `~/.codex/`, `~/.claude/`, `~/.gemini/`, etc. Automatically configure the sync targets based on what you find.

Only ask the user questions if their setup is highly customized or if you encounter permission errors preventing auto-detection.

#### 2. Determine the Tech Stack
Based on the user's OS:
- If Windows: Use the `.ps1` templates.
- If Mac/Linux: Use the `.sh` templates.

Create the required directories:
- `mkdir -p docs/agent-guidance my-skills scripts`

#### 4. Setup the Central Truth Document
Create `docs/agent-guidance/workflow.md` with some basic cross-agent workflow principles if it doesn't exist.

#### 5. Generate and Deploy the Scripts
Read the templates provided in this skill's repository (`templates/`) and write them to the user's workspace:

1. **Guidance Sync Script** (`scripts/generate-guidance.sh` or `.ps1`):
   - Modify the `TARGET_FILES` array in the script to match the entry files the user requested (e.g., `AGENTS.md`, `CLAUDE.md`).
2. **Global Sync Script** (`scripts/sync.sh` or `.ps1`):
   - Modify the `TARGET_DIRS` array to include the global skill directories the user requested.
3. **Drift Check Script** (`scripts/check.sh` or `.ps1`):
   - Modify the `TARGET_DIRS` array to match the sync targets.

*(If you cannot access the templates directly, use your coding abilities to write these scripts using native `cp` and `diff` for bash, or `Copy-Item` and `Get-FileHash` for PowerShell.)*

**Make Bash scripts executable (if applicable):**
- `chmod +x scripts/*.sh`

#### 6. Execute the Initial Setup
Run the `generate-guidance` script immediately to create the root-level entry files for the user!

#### 7. Inform the User
Inform the user that their ultimate synchronization workflow is ready. Tell them:
- They can now add specific personal skills to `my-skills/` and run `sync` to distribute them globally.
- They should run `check` periodically to catch drift.
- If they want to change global rules, they must edit `docs/agent-guidance/workflow.md` and run `generate-guidance`, **never** the entry files directly!

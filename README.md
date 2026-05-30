# Nolotus Skills Collection

Welcome to my personal AI Skills repository! 

This repository contains a curated collection of powerful, reusable Markdown skills that I've developed to supercharge AI coding agents (like Claude Code, Codex, Gemini, and Cursor).

## What's Inside?

### 1. `multi-cli-sync` (Cross-CLI Skill Sync & Drift Check)
**The Problem**: If you use multiple AI assistants (e.g., Claude Code in the terminal, Codex in the editor, and Gemini), they each have their own global skill directories (like `~/.codex/skills/`). Keeping your personal custom skills synchronized across all of them—and ensuring you don't accidentally edit them in one place and forget to sync them back—is a nightmare.

**The Solution**: The `multi-cli-sync` skill provides a **zero-dependency, pure Bash** solution. By feeding this skill to your AI agent, you can type `/setup-sync` to instantly configure a robust, centralized `my-skills/` directory in your project. It generates lightweight `.sh` scripts to automatically distribute your skills to all CLIs and check for drift.

*(More skills will be added soon!)*

## How to Use These Skills
To use any skill in this repository:
1. Navigate to the specific skill's folder (e.g., `skills/multi-cli-sync/`).
2. Copy the `SKILL.md` file.
3. Provide it to your AI Agent as instructions or context.
4. Follow the usage commands defined in that skill (e.g., `/setup-sync`).

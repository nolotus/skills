#!/usr/bin/env bash
# sync.sh - Zero-dependency script to distribute local skills to multiple CLI platforms

set -e

# Default source directory for your personal skills
SOURCE_DIR="my-skills"

# -----------------------------------------------------------------------------
# Configuration: Define your target CLI skill directories here
# -----------------------------------------------------------------------------
# Example paths:
# CODEX_SKILLS_DIR="$HOME/.codex/skills"
# CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
TARGET_DIRS=(
    # TODO: Add your target directories here
    # "$CODEX_SKILLS_DIR"
    # "$CLAUDE_SKILLS_DIR"
)

echo "🔄 Starting multi-CLI skill synchronization..."

if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Error: Source directory '$SOURCE_DIR' does not exist."
    echo "Please create it and add your markdown skills there first."
    exit 1
fi

if [ ${#TARGET_DIRS[@]} -eq 0 ]; then
    echo "⚠️ Warning: No target directories configured. Please edit scripts/sync.sh to add your CLI paths."
    exit 0
fi

# Sync each skill to all target directories
for target in "${TARGET_DIRS[@]}"; do
    echo "➡️ Syncing to $target..."
    mkdir -p "$target"
    
    # Iterate through all markdown files in the source directory
    for skill_file in "$SOURCE_DIR"/*.md; do
        if [ -f "$skill_file" ]; then
            # We copy the markdown file directly. 
            # In some CLIs, skills are expected to be folders with a SKILL.md inside.
            # If your CLI requires a folder structure (e.g. ~/.codex/skills/my-skill/SKILL.md),
            # the AI can help you modify this CP logic during /setup-sync.
            
            filename=$(basename "$skill_file")
            skill_name="${filename%.md}"
            
            # Example for folder-based skills (like Codex):
            # mkdir -p "$target/$skill_name"
            # cp "$skill_file" "$target/$skill_name/SKILL.md"
            
            # Example for flat file skills:
            cp "$skill_file" "$target/$filename"
            
            echo "  ✔️ Synced $skill_name"
        fi
    done
done

echo "✅ Synchronization complete!"

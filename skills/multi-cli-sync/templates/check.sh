#!/usr/bin/env bash
# check.sh - Zero-dependency script to check for skill drift between local and external CLI directories

set -e

SOURCE_DIR="my-skills"

# -----------------------------------------------------------------------------
# Configuration: Define your target CLI skill directories here
# -----------------------------------------------------------------------------
TARGET_DIRS=(
    # TODO: Add your target directories here
)

if [ ! -d "$SOURCE_DIR" ]; then
    echo "⚠️ Skipping check: Source directory '$SOURCE_DIR' does not exist."
    exit 0
fi

if [ ${#TARGET_DIRS[@]} -eq 0 ]; then
    echo "⚠️ Warning: No target directories configured. Please edit scripts/check.sh to add your CLI paths."
    exit 0
fi

has_drift=0
echo "🔍 Checking for skill drift..."

for target in "${TARGET_DIRS[@]}"; do
    if [ ! -d "$target" ]; then
        echo "⚠️ Target directory $target does not exist. Skipping."
        continue
    fi
    
    for skill_file in "$SOURCE_DIR"/*.md; do
        if [ ! -f "$skill_file" ]; then continue; fi
        
        filename=$(basename "$skill_file")
        skill_name="${filename%.md}"
        
        # Adjust this depending on your sync.sh structure (flat vs folder-based)
        # External path for flat file:
        external_file="$target/$filename"
        # External path for folder-based:
        # external_file="$target/$skill_name/SKILL.md"
        
        if [ ! -f "$external_file" ]; then
            echo "❌ [MISSING] $skill_name is missing in $target!"
            has_drift=1
            continue
        fi
        
        # Use native 'diff' to compare files
        # We use -q (brief) to just check if they differ, ignoring whitespace differences (-b or -w if preferred)
        if ! diff -q "$skill_file" "$external_file" > /dev/null; then
            echo "🚨 [DRIFT DETECTED] $skill_name in $target differs from local source!"
            has_drift=1
        else
            echo "  ✔️ [OK] $skill_name in $target is in sync."
        fi
    done
done

if [ $has_drift -eq 1 ]; then
    echo ""
    echo "❌ Drift detected! You modified a skill in the external CLI directory but forgot to sync it back to $SOURCE_DIR, OR you modified it locally and forgot to run sync.sh."
    exit 1
else
    echo ""
    echo "✅ All skills are perfectly synchronized."
    exit 0
fi

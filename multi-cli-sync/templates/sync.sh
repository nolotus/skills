#!/usr/bin/env bash
# sync.sh - 用零依赖方式同步个人 skill，并在允许时写入 repo mirror 目标

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.sh"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ 错误：缺少配置文件 $CONFIG_FILE"
    exit 1
fi

# shellcheck source=/dev/null
. "$CONFIG_FILE"

echo "🔄 开始执行 multi-cli-sync..."

copy_pair() {
    local source_path="$1"
    local target_path="$2"

    mkdir -p "$(dirname "$target_path")"
    if [ -d "$source_path" ]; then
        rm -rf "$target_path"
        cp -R "$source_path" "$target_path"
    else
        cp "$source_path" "$target_path"
    fi
}

sync_personal_skills() {
    if [ ! -d "$PERSONAL_SOURCE_DIR" ]; then
        echo "⚠️ 跳过个人 skill 同步：源目录 '$PERSONAL_SOURCE_DIR' 不存在。"
        return
    fi

    if [ ${#PERSONAL_TARGET_DIRS[@]} -eq 0 ]; then
        echo "⚠️ 跳过个人 skill 同步：未配置目标目录。"
        return
    fi

    echo "📦 同步个人 skill..."

    if [ "$PERSONAL_SOURCE_LAYOUT" = "flat-files" ]; then
        for skill_file in "$PERSONAL_SOURCE_DIR"/*.md; do
            [ -f "$skill_file" ] || continue
            filename=$(basename "$skill_file")
            skill_name="${filename%.md}"
            for target in "${PERSONAL_TARGET_DIRS[@]}"; do
                mkdir -p "$target"
                if [ "$PERSONAL_TARGET_LAYOUT" = "flat-files" ]; then
                    cp "$skill_file" "$target/$filename"
                elif [ "$PERSONAL_TARGET_LAYOUT" = "folder-skills" ]; then
                    mkdir -p "$target/$skill_name"
                    cp "$skill_file" "$target/$skill_name/SKILL.md"
                else
                    echo "❌ 不支持的 PERSONAL_TARGET_LAYOUT=$PERSONAL_TARGET_LAYOUT"
                    exit 1
                fi
                echo "  ✔️ 已同步 $skill_name -> $target"
            done
        done
    elif [ "$PERSONAL_SOURCE_LAYOUT" = "folder-skills" ]; then
        if [ "$PERSONAL_TARGET_LAYOUT" != "folder-skills" ]; then
            echo "❌ folder-skills 源只能同步到 folder-skills 目标"
            exit 1
        fi
        for skill_dir in "$PERSONAL_SOURCE_DIR"/*; do
            [ -d "$skill_dir" ] || continue
            [ -f "$skill_dir/SKILL.md" ] || continue
            skill_name=$(basename "$skill_dir")
            for target in "${PERSONAL_TARGET_DIRS[@]}"; do
                mkdir -p "$target"
                rm -rf "$target/$skill_name"
                cp -R "$skill_dir" "$target/$skill_name"
                echo "  ✔️ 已同步 $skill_name -> $target"
            done
        done
    else
        echo "❌ 不支持的 PERSONAL_SOURCE_LAYOUT=$PERSONAL_SOURCE_LAYOUT"
        exit 1
    fi
}

sync_repo_mirrors() {
    if [ "$REPO_MIRROR_WRITE_OK" != "1" ]; then
        echo "🪞 跳过 repo mirror 写入：REPO_MIRROR_WRITE_OK=$REPO_MIRROR_WRITE_OK"
        return
    fi

    if [ ${#REPO_MIRROR_SPECS[@]} -eq 0 ]; then
        echo "⚠️ 跳过 repo mirror 写入：未配置 REPO_MIRROR_SPECS。"
        return
    fi

    echo "🪞 同步 repo mirrors..."

    for spec in "${REPO_MIRROR_SPECS[@]}"; do
        IFS='|' read -r label kind source target required <<< "$spec"
        if [ ! -e "$source" ]; then
            echo "❌ 源路径不存在，无法同步 $label: $source"
            exit 1
        fi
        if [ "$kind" = "file-to-file" ] || [ "$kind" = "dir-to-dir" ]; then
            copy_pair "$source" "$target"
            echo "  ✔️ 已同步 mirror $label"
        else
            echo "❌ 不支持的 kind=$kind（$label）"
            exit 1
        fi
    done
}

sync_personal_skills
sync_repo_mirrors

echo "✅ multi-cli-sync 执行完成！"

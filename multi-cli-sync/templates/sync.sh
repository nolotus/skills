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

# 兼容旧配置
if [ -z "${PERSONAL_EXCLUDE_SKILLS+x}" ]; then
    PERSONAL_EXCLUDE_SKILLS=()
fi

echo "🔄 开始执行 multi-cli-sync..."

is_personal_excluded() {
    local skill_name="$1"
    local excluded
    for excluded in "${PERSONAL_EXCLUDE_SKILLS[@]+"${PERSONAL_EXCLUDE_SKILLS[@]}"}"; do
        [ -n "$excluded" ] || continue
        if [ "$skill_name" = "$excluded" ]; then
            return 0
        fi
    done
    return 1
}

remove_personal_install() {
    local skill_name="$1"
    local target="$2"

    if [ "$PERSONAL_TARGET_LAYOUT" = "flat-files" ]; then
        if [ -e "$target/$skill_name.md" ]; then
            rm -f "$target/$skill_name.md"
            echo "  🗑️ 已删除排除 skill $skill_name.md <- $target"
        fi
    else
        if [ -e "$target/$skill_name" ]; then
            rm -rf "$target/$skill_name"
            echo "  🗑️ 已删除排除 skill $skill_name <- $target"
        fi
    fi
}

purge_excluded_personal_skills() {
    if [ ${#PERSONAL_TARGET_DIRS[@]} -eq 0 ]; then
        return
    fi
    if [ ${#PERSONAL_EXCLUDE_SKILLS[@]} -eq 0 ]; then
        return
    fi

    echo "🧹 清理已排除的个人 skill 安装副本..."
    local skill_name
    local target
    for skill_name in "${PERSONAL_EXCLUDE_SKILLS[@]}"; do
        [ -n "$skill_name" ] || continue
        for target in "${PERSONAL_TARGET_DIRS[@]}"; do
            remove_personal_install "$skill_name" "$target"
        done
    done
}

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
        purge_excluded_personal_skills
        return
    fi

    if [ ${#PERSONAL_TARGET_DIRS[@]} -eq 0 ]; then
        echo "⚠️ 跳过个人 skill 同步：未配置目标目录。"
        return
    fi

    echo "📦 同步个人 skill..."
    purge_excluded_personal_skills

    if [ "$PERSONAL_SOURCE_LAYOUT" = "flat-files" ]; then
        for skill_file in "$PERSONAL_SOURCE_DIR"/*.md; do
            [ -f "$skill_file" ] || continue
            filename=$(basename "$skill_file")
            skill_name="${filename%.md}"
            if is_personal_excluded "$skill_name"; then
                echo "  ⏭️ 跳过排除 skill $skill_name（源保留，不安装）"
                continue
            fi
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
            if is_personal_excluded "$skill_name"; then
                echo "  ⏭️ 跳过排除 skill $skill_name（源保留，不安装）"
                continue
            fi
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
            if [ "$required" = "1" ]; then
                echo "❌ required mirror 源路径不存在，无法同步 $label: $source"
                exit 1
            fi
            echo "  ⚠️ 跳过 optional mirror $label（源路径不存在: $source）"
            continue
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

#!/usr/bin/env bash
# check.sh - 用零依赖方式检查个人 skill 安装状态与 repo mirror gate

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/multi-cli-sync.config.sh"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ 错误：缺少配置文件 $CONFIG_FILE"
    exit 1
fi

# shellcheck source=/dev/null
. "$CONFIG_FILE"

has_required_drift=0
has_optional_drift=0

echo "🔍 开始检查 multi-cli-sync 状态..."

report_result() {
    local status="$1"
    local label="$2"
    local detail="$3"
    local required="$4"

    if [ "$status" = "ok" ]; then
        echo "  ✔️ [正常] $label"
        return
    fi

    if [ "$required" = "1" ]; then
        has_required_drift=1
        echo "❌ [$label] $detail"
    else
        has_optional_drift=1
        echo "⚠️ [$label] $detail"
    fi
}

compare_pair() {
    local label="$1"
    local source_path="$2"
    local target_path="$3"
    local required="$4"

    if [ ! -e "$source_path" ]; then
        report_result "fail" "$label" "源路径不存在：$source_path" "$required"
        return
    fi

    if [ ! -e "$target_path" ]; then
        report_result "fail" "$label" "目标路径不存在：$target_path" "$required"
        return
    fi

    if [ -d "$source_path" ] && [ -d "$target_path" ]; then
        if diff -qr "$source_path" "$target_path" > /dev/null; then
            report_result "ok" "$label" "" "$required"
        else
            report_result "fail" "$label" "目录内容不一致：$source_path -> $target_path" "$required"
        fi
        return
    fi

    if [ -f "$source_path" ] && [ -f "$target_path" ]; then
        if diff -q "$source_path" "$target_path" > /dev/null; then
            report_result "ok" "$label" "" "$required"
        else
            report_result "fail" "$label" "文件内容不一致：$source_path -> $target_path" "$required"
        fi
        return
    fi

    report_result "fail" "$label" "源与目标类型不一致：$source_path -> $target_path" "$required"
}

check_personal_sync() {
    if [ ! -d "$PERSONAL_SOURCE_DIR" ]; then
        echo "⚠️ 跳过个人 skill 检查：源目录 '$PERSONAL_SOURCE_DIR' 不存在。"
        return
    fi

    if [ ${#PERSONAL_TARGET_DIRS[@]} -eq 0 ]; then
        echo "⚠️ 跳过个人 skill 检查：未配置目标目录。"
        return
    fi

    echo "📦 检查个人 skill 安装状态..."

    if [ "$PERSONAL_SOURCE_LAYOUT" = "flat-files" ]; then
        for skill_file in "$PERSONAL_SOURCE_DIR"/*.md; do
            [ -f "$skill_file" ] || continue
            filename=$(basename "$skill_file")
            skill_name="${filename%.md}"
            for target in "${PERSONAL_TARGET_DIRS[@]}"; do
                if [ "$PERSONAL_TARGET_LAYOUT" = "flat-files" ]; then
                    compare_pair "personal:$skill_name:$target" "$skill_file" "$target/$filename" 1
                elif [ "$PERSONAL_TARGET_LAYOUT" = "folder-skills" ]; then
                    compare_pair "personal:$skill_name:$target" "$skill_file" "$target/$skill_name/SKILL.md" 1
                else
                    report_result "fail" "personal:$skill_name:$target" "不支持的 PERSONAL_TARGET_LAYOUT=$PERSONAL_TARGET_LAYOUT" 1
                fi
            done
        done
    elif [ "$PERSONAL_SOURCE_LAYOUT" = "folder-skills" ]; then
        if [ "$PERSONAL_TARGET_LAYOUT" != "folder-skills" ]; then
            report_result "fail" "personal-layout" "folder-skills 源只能同步到 folder-skills 目标" 1
            return
        fi
        for skill_dir in "$PERSONAL_SOURCE_DIR"/*; do
            [ -d "$skill_dir" ] || continue
            [ -f "$skill_dir/SKILL.md" ] || continue
            skill_name=$(basename "$skill_dir")
            for target in "${PERSONAL_TARGET_DIRS[@]}"; do
                compare_pair "personal:$skill_name:$target" "$skill_dir" "$target/$skill_name" 1
            done
        done
    else
        report_result "fail" "personal-layout" "不支持的 PERSONAL_SOURCE_LAYOUT=$PERSONAL_SOURCE_LAYOUT" 1
    fi
}

check_repo_mirrors() {
    if [ ${#REPO_MIRROR_SPECS[@]} -eq 0 ]; then
        echo "⚠️ 跳过 repo mirror 检查：未配置 REPO_MIRROR_SPECS。"
        return
    fi

    echo "🪞 检查 repo mirror gate..."

    for spec in "${REPO_MIRROR_SPECS[@]}"; do
        IFS='|' read -r label kind source target required <<< "$spec"
        if [ "$kind" = "file-to-file" ] || [ "$kind" = "dir-to-dir" ]; then
            compare_pair "$label" "$source" "$target" "$required"
        else
            report_result "fail" "$label" "不支持的 kind=$kind" "$required"
        fi
    done
}

check_personal_sync
check_repo_mirrors

if [ $has_required_drift -eq 1 ]; then
    echo ""
    echo "❌ 存在 required drift。"
    exit 1
fi

if [ $has_optional_drift -eq 1 ]; then
    echo ""
    echo "⚠️ required 项已通过，但存在 optional drift。"
    exit 0
fi

echo ""
echo "✅ 所有 required 项都已通过。"

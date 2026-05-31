#!/usr/bin/env bash
# check.sh - 用零依赖方式检查本地 skill 源与外部 CLI 目录之间是否发生漂移

set -e

SOURCE_DIR="my-skills"

# -----------------------------------------------------------------------------
# 配置区：在这里定义目标 CLI skill 目录
# -----------------------------------------------------------------------------
TARGET_DIRS=(
    # TODO: 在这里填入目标目录
)

if [ ! -d "$SOURCE_DIR" ]; then
    echo "⚠️ 跳过检查：源目录 '$SOURCE_DIR' 不存在。"
    exit 0
fi

if [ ${#TARGET_DIRS[@]} -eq 0 ]; then
    echo "⚠️ 警告：还没有配置目标目录。请先编辑 scripts/check.sh。"
    exit 0
fi

has_drift=0
echo "🔍 开始检查 skill 漂移..."

for target in "${TARGET_DIRS[@]}"; do
    if [ ! -d "$target" ]; then
        echo "⚠️ 目标目录 $target 不存在，跳过。"
        continue
    fi

    for skill_file in "$SOURCE_DIR"/*.md; do
        if [ ! -f "$skill_file" ]; then continue; fi

        filename=$(basename "$skill_file")
        skill_name="${filename%.md}"

        external_file="$target/$filename"
        # 如果目标 CLI 用目录式 skill，可以改成：
        # external_file="$target/$skill_name/SKILL.md"

        if [ ! -f "$external_file" ]; then
            echo "❌ [缺失] $skill_name 在 $target 中不存在！"
            has_drift=1
            continue
        fi

        if ! diff -q "$skill_file" "$external_file" > /dev/null; then
            echo "🚨 [发现漂移] $skill_name 在 $target 中与本地源不一致！"
            has_drift=1
        else
            echo "  ✔️ [正常] $skill_name 在 $target 中已同步。"
        fi
    done
done

if [ $has_drift -eq 1 ]; then
    echo ""
    echo "❌ 检测到漂移：你可能改了外部 CLI 目录里的 skill 却没同步回 $SOURCE_DIR，或者改了本地源却没运行 sync.sh。"
    exit 1
else
    echo ""
    echo "✅ 所有 skill 都已同步。"
    exit 0
fi

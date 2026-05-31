#!/usr/bin/env bash
# sync.sh - 用零依赖方式把本地 skill 分发到多个 CLI 平台

set -e

SOURCE_DIR="my-skills"

# -----------------------------------------------------------------------------
# 配置区：在这里定义目标 CLI skill 目录
# -----------------------------------------------------------------------------
TARGET_DIRS=(
    # TODO: 在这里填入目标目录
)

echo "🔄 开始执行多 CLI skill 同步..."

if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ 错误：源目录 '$SOURCE_DIR' 不存在。"
    echo "请先创建它，并把你的 markdown skill 放进去。"
    exit 1
fi

if [ ${#TARGET_DIRS[@]} -eq 0 ]; then
    echo "⚠️ 警告：还没有配置目标目录。请先编辑 scripts/sync.sh。"
    exit 0
fi

for target in "${TARGET_DIRS[@]}"; do
    echo "➡️ 正在同步到 $target..."
    mkdir -p "$target"

    for skill_file in "$SOURCE_DIR"/*.md; do
        if [ -f "$skill_file" ]; then
            filename=$(basename "$skill_file")
            skill_name="${filename%.md}"

            # 目录式 skill 示例（如 Codex）
            # mkdir -p "$target/$skill_name"
            # cp "$skill_file" "$target/$skill_name/SKILL.md"

            # 扁平文件示例
            cp "$skill_file" "$target/$filename"

            echo "  ✔️ 已同步 $skill_name"
        fi
    done
done

echo "✅ 同步完成！"

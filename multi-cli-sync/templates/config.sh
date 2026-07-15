#!/usr/bin/env bash
# config.sh - 多 CLI skill 同步与 repo mirror gate 配置

# 个人 skill 源目录
PERSONAL_SOURCE_DIR="my-skills"

# 支持：flat-files | folder-skills
PERSONAL_SOURCE_LAYOUT="flat-files"
PERSONAL_TARGET_LAYOUT="flat-files"

# 个人 skill 的目标目录
PERSONAL_TARGET_DIRS=(
    # "$HOME/.codex/skills"
    # "$HOME/.claude/skills"
    # "$HOME/.agents/skills"
    # "$HOME/.grok/skills"
)

# 源目录可保留、但不要安装/同步到 CLI 的 skill 名（basename）。
# sync 会跳过它们，并删除各 PERSONAL_TARGET_DIRS 里的同名安装副本。
PERSONAL_EXCLUDE_SKILLS=(
    # "nolo-plan"
)

# 是否允许 sync.sh 主动写入 repo mirror 目标
# 0 = 只做 gate 检查，不自动覆盖镜像目标
# 1 = sync.sh 也会同步 repo mirror 目标
REPO_MIRROR_WRITE_OK=0

# repo mirror 规则
# 格式：label|kind|source|target|required
# kind: file-to-file | dir-to-dir
# required: 1 = 阻塞项, 0 = 可选项
REPO_MIRROR_SPECS=(
    # "workspace-skill|file-to-file|docs/skills/example.md|$HOME/.codex/skills/example/SKILL.md|1"
    # "example-dir|dir-to-dir|skills/example|$HOME/.codex/skills/example|0"
)

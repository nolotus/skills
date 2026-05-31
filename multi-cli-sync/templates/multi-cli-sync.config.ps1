# multi-cli-sync.config.ps1 - 多 CLI skill 同步与 repo mirror gate 配置

$PersonalSourceDir = "my-skills"

# 支持：flat-files | folder-skills
$PersonalSourceLayout = "flat-files"
$PersonalTargetLayout = "flat-files"

$PersonalTargetDirs = @(
    # "$HOME/.codex/skills"
    # "$HOME/.claude/skills"
)

# 0 = 只做 gate 检查，不自动覆盖镜像目标
# 1 = sync.ps1 也会同步 repo mirror 目标
$RepoMirrorWriteOk = 0

# 每条规则是一个对象：
# Label, Kind(file-to-file | dir-to-dir), Source, Target, Required(0|1)
$RepoMirrorSpecs = @(
    # @{ Label = "workspace-skill"; Kind = "file-to-file"; Source = "docs/skills/example.md"; Target = "$HOME/.codex/skills/example/SKILL.md"; Required = 1 }
    # @{ Label = "example-dir"; Kind = "dir-to-dir"; Source = "skills/example"; Target = "$HOME/.codex/skills/example"; Required = 0 }
)

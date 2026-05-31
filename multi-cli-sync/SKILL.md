---
name: multi-cli-sync
description: 当用户想把个人 skill 在多个 AI CLI 之间同步，并为 AGENTS.md、CLAUDE.md 等入口文件建立统一真值与漂移检查时使用；也适用于把仓库内权威 skill 源映射到外部安装目录，作为 repo-specific mirror gate。支持 Win/Mac/Linux，可通过 /setup-sync 触发。
---

# 多 CLI Skill 与 Guidance 同步器

这个 skill 现在解决三类问题：

1. Guidance 同步：生成根目录入口文件，例如 `AGENTS.md`、`CLAUDE.md`、`.cursorrules`，让它们统一指向一个中心文档，并执行漂移规则。
2. 个人 skill 同步：把个人 skill 分发到外部 CLI 的全局目录，例如 `~/.codex/skills`。
3. 仓库镜像门：检查仓库内权威 skill 源是否正确镜像到外部安装目录，例如 `docs/skills/e2e-testing.md -> ~/.codex/skills/e2e-testing/SKILL.md`。

它坚持零依赖：Mac/Linux 用原生 Bash（`.sh`），Windows 用原生 PowerShell（`.ps1`）。

## 配置模型

这个 skill 不再只靠一个简单的 `TARGET_DIRS` 数组，而是分成两层：

### 1. 个人 skill 同步区

适合这类场景：

- 你有一个 `my-skills/` 目录
- 你要把这些 skill 分发到多个 CLI
- 你希望定期检查这些安装目录是否和本地源一致

支持两种布局：

- `flat-files`：源目录里是 `foo.md`、`bar.md`
- `folder-skills`：源目录里是 `foo/SKILL.md`、`bar/SKILL.md`

目标布局支持：

- `flat-files`
- `folder-skills`

### 2. 仓库镜像区

适合这类场景：

- 仓库里有受版本控制的 skill 真值
- 外部 CLI 安装目录里有镜像副本
- 你要把这些镜像关系当成 gate 检查，而不是只靠人记忆

每条镜像规则至少包含：

- `label`
- `kind`
- `source`
- `target`
- `required`

其中：

- `kind` 支持 `file-to-file` 和 `dir-to-dir`
- `required=1` 表示阻塞项
- `required=0` 表示可选项，只报告不阻塞

## 命令

### `/setup-sync`

当用户输入 `/setup-sync` 时，把自己当成他们的个人工作流助理，并严格按下面步骤执行：

#### 1. 自动识别环境与目标

不要问用户是什么操作系统。直接用环境能力自动识别，例如运行 `uname`、检查 `sys.platform` 或读取环境变量。

如果能自动识别，就不要问用户每个 CLI 的全局目录。主动检查用户 home 目录下是否存在常见 AI CLI 配置目录，例如 `~/.codex/`、`~/.claude/`、`~/.gemini/`，并据此自动配置同步目标。

只有在环境高度定制，或者因为权限问题无法自动识别时，才追问。

#### 2. 确定技术栈

根据用户操作系统：

- Windows：使用 `.ps1` 模板
- Mac/Linux：使用 `.sh` 模板

创建这些目录：

- `mkdir -p docs/agent-guidance my-skills scripts`

#### 3. 建立中心真值文档

如果不存在，就创建 `docs/agent-guidance/workflow.md`，作为跨代理共享工作流原则的中心文档。

#### 4. 生成并部署脚本

读取本 skill 仓库里 `templates/` 下的模板，并把它们写入用户当前工作区：

1. 配置文件：`scripts/multi-cli-sync.config.sh` 或 `.ps1`
   - 写入个人 skill 源布局、目标布局、目标目录
   - 写入 repo mirror 规则
2. Guidance 同步脚本：`scripts/generate-guidance.sh` 或 `.ps1`
3. 全局同步脚本：`scripts/sync.sh` 或 `.ps1`
4. 漂移检查脚本：`scripts/check.sh` 或 `.ps1`

如果拿不到模板文件，就自己用原生命令生成等价脚本。

#### 5. 配置 repo mirror gate

如果用户项目里存在受版本控制的 skill 真值，例如：

- `docs/skills/*.md`
- `skills/*/SKILL.md`
- 其他版本控制目录中的权威 skill 源

就把这些路径映射写进 `REPO_MIRROR_SPECS`，不要只做个人 skill 同步。

典型例子：

- `workspace-skill|file-to-file|docs/skills/bun-nolo-workspace.md|$HOME/.codex/skills/bun-nolo-workspace/SKILL.md|1`
- `agent-workflows|file-to-file|docs/skills/bun-nolo-workspace-agent-dialog-workflows.md|$HOME/.codex/skills/bun-nolo-workspace/references/agent-dialog-workflows.md|1`
- `external-reference|dir-to-dir|vendor/skills/debugging|$HOME/.codex/skills/debugging|0`

#### 6. 执行初始化

立刻运行 guidance 生成脚本，先把根目录入口文件生成出来。

#### 7. 告诉用户怎么用

最后明确告诉用户：

- 个人 skill 放进 `my-skills/` 后，可以运行 `sync` 分发到多个 CLI
- `check` 会同时检查个人 skill 安装状态和 repo mirror gate
- 如果 `REPO_MIRROR_WRITE_OK=1`，`sync` 还可以写入 repo mirror 目标
- 如果只想把 repo mirror 当 gate，不想自动覆盖目标文件，就保持 `REPO_MIRROR_WRITE_OK=0`
- 如果要改全局规则，必须改中心文档和配置文件，不要直接手改入口文件或镜像副本

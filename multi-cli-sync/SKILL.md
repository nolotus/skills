---
name: multi-cli-sync
description: 当用户想把个人 skill 在多个 AI CLI 之间同步，并为 AGENTS.md、CLAUDE.md 等入口文件建立统一真值和漂移检查时使用；支持 Win/Mac/Linux，可通过 /setup-sync 触发。
---

# 多 CLI Skill 与 Guidance 同步器

这个 skill 解决两类问题：

1. Guidance 同步：生成根目录入口文件，例如 `AGENTS.md`、`CLAUDE.md`、`.cursorrules`，让它们统一指向一个中心文档，并执行漂移规则。
2. 全局 skill 同步：把个人 skill 分发到外部 CLI 的全局目录，例如 `~/.codex/skills`，并检查是否发生漂移。

它坚持零依赖：Mac/Linux 用原生 Bash（`.sh`），Windows 用原生 PowerShell（`.ps1`）。

## 命令

### `/setup-sync`

当用户输入 `/setup-sync` 时，把自己当成他们的个人工作流助理，并严格按下面步骤执行：

#### 1. 自动识别环境与目标

不要问用户是什么操作系统。直接用环境能力自动识别，例如运行 `uname`、检查 `sys.platform` 或读取环境变量。

如果能自动识别，就不要问用户每个 CLI 的全局 skill 目录。主动检查用户 home 目录下是否存在常见 AI CLI 配置目录，例如 `~/.codex/`、`~/.claude/`、`~/.gemini/`，并据此自动配置同步目标。

只有在用户环境明显高度定制，或者因为权限问题无法自动识别时，才追问。

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

1. Guidance 同步脚本：`scripts/generate-guidance.sh` 或 `.ps1`
   - 修改 `TARGET_FILES`，让它符合用户要生成的入口文件，例如 `AGENTS.md`、`CLAUDE.md`
2. 全局同步脚本：`scripts/sync.sh` 或 `.ps1`
   - 修改 `TARGET_DIRS`，写入要同步到的 CLI skill 目录
3. 漂移检查脚本：`scripts/check.sh` 或 `.ps1`
   - 修改 `TARGET_DIRS`，与同步目标保持一致

如果你拿不到模板文件，就自己用原生命令生成等价脚本：

- Bash 侧优先使用 `cp`、`diff`
- PowerShell 侧优先使用 `Copy-Item`、`Get-FileHash`

如果使用 Bash，再把脚本设为可执行：

- `chmod +x scripts/*.sh`

#### 5. 执行初始化

立刻运行 guidance 生成脚本，先把根目录入口文件生成出来。

#### 6. 告诉用户怎么用

最后明确告诉用户：

- 之后可以把具体 skill 放进 `my-skills/`，再运行 `sync` 分发到多个 CLI
- 应该定期运行 `check` 检查漂移
- 如果要改全局规则，必须改 `docs/agent-guidance/workflow.md`，然后重新运行 `generate-guidance`，不要直接手改入口文件

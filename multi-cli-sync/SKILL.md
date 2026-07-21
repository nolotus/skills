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

#### 排除列表（源保留、不安装）

配置 `PERSONAL_EXCLUDE_SKILLS`（bash）/ `$PersonalExcludeSkills`（PowerShell）：

- **源目录继续保留**对应 skill，方便以后查阅或临时挂载
- **sync 不会安装**它们到 `PERSONAL_TARGET_DIRS`
- **sync 会删除**各目标目录里已存在的同名安装副本
- **check 会报错**若排除 skill 仍出现在安装目录

典型例子：`nolo-plan` 用软链挂载到各 CLI skill 目录（真源唯一、改源即生效），复制式安装会造成副本漂移。把它写进排除列表后：sync 跳过复制安装、清掉旧的独立副本，软链本身不受影响。注意「排除」≠「不安装」——它只是声明这个 skill 的安装由软链负责，不用 sync 管。

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

- `mkdir -p docs/agent-guidance my-skills scripts/multi-cli-sync`

#### 3. 建立中心真值文档

如果不存在，就创建 `docs/agent-guidance/workflow.md`，作为跨代理共享工作流原则的中心文档。

#### 4. 生成并部署脚本

读取本 skill 仓库里 `templates/` 下的模板，并把它们写入用户当前工作区。

推荐 Bun/Node 项目使用配置驱动的 TypeScript generator：

1. `templates/generate-guidance.ts` -> `scripts/multi-cli-sync/generate-guidance.ts`
2. `templates/guidance.config.json` -> `scripts/multi-cli-sync/guidance.config.json`

这个 generator 必须保持通用：仓库专属文案、入口文件列表、必需源文件、漂移规则都写进 `guidance.config.json`，不要写死在脚本里。

零依赖 fallback 使用 shell 或 PowerShell 模板：

1. 配置文件：`scripts/multi-cli-sync/config.sh` 或 `.ps1`
   - 写入个人 skill 源布局、目标布局、目标目录
   - 写入 `PERSONAL_EXCLUDE_SKILLS`（源保留、不安装；sync 时清理目标副本）
   - 写入 repo mirror 规则
2. Guidance 同步脚本：`scripts/multi-cli-sync/generate-guidance.sh` 或 `.ps1`
3. 全局同步脚本：`scripts/multi-cli-sync/sync.sh` 或 `.ps1`
4. 漂移检查脚本：`scripts/multi-cli-sync/check.sh` 或 `.ps1`

如果拿不到模板文件，就自己用原生命令生成等价脚本。

#### 5. 配置 repo mirror gate

如果用户项目里存在受版本控制的 skill 真值，例如：

- `docs/skills/*.md`
- `skills/*/SKILL.md`
- 其他版本控制目录中的权威 skill 源

就把这些路径映射写进 `REPO_MIRROR_SPECS`，不要只做个人 skill 同步。

典型例子：

- `workspace-skill|file-to-file|docs/skills/workspace.md|$HOME/.codex/skills/workspace/SKILL.md|1`
- `skill-reference|file-to-file|docs/skills/workspace-reference.md|$HOME/.codex/skills/workspace/references/reference.md|1`
- `external-reference|dir-to-dir|vendor/skills/debugging|$HOME/.codex/skills/debugging|0`

#### 6. 执行初始化

立刻运行 guidance 生成脚本，先把根目录入口文件生成出来：

- Bun/Node 项目：`bun scripts/multi-cli-sync/generate-guidance.ts`
- Mac/Linux fallback：`bash scripts/multi-cli-sync/generate-guidance.sh`
- Windows fallback：`pwsh scripts/multi-cli-sync/generate-guidance.ps1`

#### 7. 告诉用户怎么用

最后明确告诉用户：

- 个人 skill 放进 `my-skills/` 后，可以运行 `sync` 分发到多个 CLI
- 用软链挂载、不走复制安装的 skill（如 `nolo-plan`）写进 `PERSONAL_EXCLUDE_SKILLS`；`sync` 会跳过复制并清理旧的独立副本，不动源目录也不动软链
- `check` 会同时检查个人 skill 安装状态、排除 skill 是否误装、以及 repo mirror gate
- 如果 `REPO_MIRROR_WRITE_OK=1`，`sync` 还可以写入 repo mirror 目标
- 如果只想把 repo mirror 当 gate，不想自动覆盖目标文件，就保持 `REPO_MIRROR_WRITE_OK=0`
- 如果要改全局规则，必须改中心文档和配置文件，不要直接手改入口文件或镜像副本
- 如果某个仓库需要 repo-specific guidance，保持 `generate-guidance.ts` 通用，把专属内容放到 `guidance.config.json`

# Nolotus Skills

这是一个公开的 AI 编码技能仓库。

设计原则只有三条：

- 通用核心 skill 放这里
- 仓库私有适配留在各自项目里
- 默认中文书写；其他用户安装后，优先由他们的代理按本地语言再翻译或生成适配版本

## 如何选择安装

不是所有 skill 都要装。推荐按需安装：

- 如果你想统一管理个人 skill、同步到 Codex / Claude / Gemini / Grok 等多个 CLI，安装 `multi-cli-sync/`
- 如果你希望 agent 修 bug 先查根因、不乱打补丁（四阶段调试法），安装 `root-cause-debugging/`
- 如果你想要复古 CRT + 温馨像素风的前端视觉规范，安装 `cozy-crt-pixelpunk/`
- 如果你想创建、改进、评测自己的 skill，安装 `skill-creator/`
- 如果你是 nolo-cli 用户，需要编码代理中自动获得 CLI 操作指导，安装 `nolo-cli/`

安装步骤见 [INSTALL.md](INSTALL.md)。

## 源保留、默认不安装

- `nolo-plan/`：**只保留在本仓库源目录**，默认不要复制到 `~/.codex/skills`、`~/.claude/skills`、`~/.agents/skills`、`~/.grok/skills` 等安装路径。
- 需要时再手动打开源文件阅读或临时挂载；同步工具应通过 `PERSONAL_EXCLUDE_SKILLS` 跳过它，并**删除已装上的副本**。
- 删除安装副本 ≠ 删除源目录。

## 仓库结构

每个顶层目录就是一个独立 skill：

- `multi-cli-sync/`
- `root-cause-debugging/`
- `cozy-crt-pixelpunk/`
- `skill-creator/`
- `nolo-cli/`
- `nolo-plan/`（源归档，默认不安装）

每个 skill 至少包含一个 `SKILL.md`。

## 语言策略

- 仓库内内容优先中文
- 面向公开复用时，尽量避免写死 Nolotus 私有路径、私有产品语义、账号信息、内部流程
- 如果其他用户的工作语言不是中文，推荐他们在安装时让代理先翻译一份，再放进自己的 skill 目录

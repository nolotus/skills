# Nolotus Skills

这是一个公开的 AI 编码技能仓库。

设计原则只有三条：

- 通用核心 skill 放这里
- 仓库私有适配留在各自项目里
- 默认中文书写；其他用户安装后，优先由他们的代理按本地语言再翻译或生成适配版本

## 如何选择安装

不是所有 skill 都要装。推荐按需安装：

- 如果你想让编码 agent 更稳：计划先行、task 并行派发给便宜模型/外部 agent、跨模型 review，安装 `plan-dispatch-review/`
- 如果你想统一管理个人 skill、同步到 Codex / Claude / Gemini 等多个 CLI，安装 `multi-cli-sync/`
- 如果你想在实现和 review 时压掉过度设计（YAGNI、最小实现阶梯），安装 `minimal-implementation-guard/`
- 如果你经常做前端面板、指标展示、UI 信息密度设计，安装 `ui-design-guidelines/`
- 如果你想要复古 CRT + 温馨像素风的前端视觉规范，安装 `cozy-crt-pixelpunk/`
- 如果你经常做 CMS、后台、自动化、内容系统、可编辑配置类工作，安装 `hidden-assumptions-preflight/`
- 如果你经常做架构评审、模块边界整理、重构方向判断，安装 `improve-codebase-architecture/`
- 如果你是 nolo-cli 用户，需要编码代理中自动获得 CLI 操作指导，安装 `nolo-cli/`

安装步骤见 [INSTALL.md](INSTALL.md)。

## 仓库结构

每个顶层目录就是一个独立 skill：

- `plan-dispatch-review/`
- `multi-cli-sync/`
- `minimal-implementation-guard/`
- `ui-design-guidelines/`
- `cozy-crt-pixelpunk/`
- `hidden-assumptions-preflight/`
- `improve-codebase-architecture/`
- `nolo-cli/`

每个 skill 至少包含一个 `SKILL.md`。

## 语言策略

- 仓库内内容优先中文
- 面向公开复用时，尽量避免写死 Nolotus 私有路径、私有产品语义、账号信息、内部流程
- 如果其他用户的工作语言不是中文，推荐他们在安装时让代理先翻译一份，再放进自己的 skill 目录

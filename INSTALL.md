# 安装指南

本仓库推荐按需安装，不建议一次性全部安装。

## 推荐安装方式

先判断你需要哪类能力：

- 计划先行、并行派发、跨模型 review：安装 `nolo-plan/`（依赖 `nolo-cli/`，建议配套 `minimal-implementation-guard/`）
- 统一管理个人 skill、同步到多个 CLI：安装 `multi-cli-sync/`
- 压掉过度设计、动工前维护路径预检：安装 `minimal-implementation-guard/`
- 修 bug 先查根因（四阶段调试法）：安装 `root-cause-debugging/`
- 前端面板、指标展示、UI 信息密度：安装 `ui-design-guidelines/`
- 复古 CRT + 像素风视觉规范：安装 `cozy-crt-pixelpunk/`
- 创建、改进、评测自己的 skill：安装 `skill-creator/`
- nolo CLI 操作指导：安装 `nolo-cli/`

## 目录约定

不同工具的 skill 目录可能不同。常见例子：

- Codex: `~/.codex/skills/`
- Claude Code: 依你的本地配置而定
- Gemini CLI: 依你的本地配置而定

如果不确定，先查看该工具自己的文档。

## 安装步骤

1. 进入你要安装的 skill 目录。
2. 复制整个目录到你的目标工具 skill 目录中。
3. 保持目录名不变，确认里面包含 `SKILL.md`。
4. 如果你的工作语言不是中文，优先让代理把 `SKILL.md` 翻译成你的语言，再安装到本地目录。

## 语言建议

本仓库源码优先中文维护。

对于非中文用户，推荐流程是：

1. 保留原始中文版本作为上游真值
2. 让代理翻译成你的工作语言
3. 在你自己的环境里安装翻译后的版本
4. 后续若上游更新，再重新翻译

## 给不同用户的建议

- 个人用户：从 `multi-cli-sync/` 开始
- 做网站/CMS/内容系统或重构治理的人：额外安装 `minimal-implementation-guard/`（含隐性假设预检）

## 不建议做的事

- 不要把所有 skill 无差别全装上
- 不要把公开 skill 直接改成依赖你私有仓库路径的版本
- 不要在这里提交包含密钥、私有地址、内部账号信息的内容

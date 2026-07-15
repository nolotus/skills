# 安装指南

本仓库推荐按需安装，不建议一次性全部安装。

## 推荐安装方式

先判断你需要哪类能力：

- 需要多 CLI 同步和漂移检查：安装 `multi-cli-sync/`
- 需要 nolo CLI 操作指导：安装 `nolo-cli/`
- 需要系统化根因调试：安装 `root-cause-debugging/`
- 需要 skill 创作方法论：安装 `skill-creator/`
- 需要 CRT/像素风视觉规范：安装 `cozy-crt-pixelpunk/`

## 源保留、默认不安装

- `nolo-plan/` 只作为**源归档**保留在本仓库，**不要**默认安装到各 CLI skill 目录。
- 若本地曾装过，删除安装副本即可；**不要删源目录**（例如 `~/skills/nolo-plan`）。
- 使用 `multi-cli-sync` 时，把 `nolo-plan` 写进 `PERSONAL_EXCLUDE_SKILLS`：sync 会跳过安装并清理目标目录里的同名副本。

## 目录约定

不同工具的 skill 目录可能不同。常见例子：

- Codex: `~/.codex/skills/`
- Claude Code: `~/.claude/skills/`
- Agents 共用: `~/.agents/skills/`
- Grok: `~/.grok/skills/`

如果不确定，先查看该工具自己的文档。

## 安装步骤

1. 进入你要安装的 skill 目录。
2. 复制整个目录到你的目标工具 skill 目录中。
3. 保持目录名不变，确认里面包含 `SKILL.md`。
4. 如果你的工作语言不是中文，优先让代理把 `SKILL.md` 翻译成你的语言，再安装到本地目录。
5. **不要**把 `PERSONAL_EXCLUDE_SKILLS` / 文档标明「源归档」的 skill 一并复制过去。

## 卸载安装副本（保留源）

```bash
# 只删安装路径，不动源仓库
rm -rf \
  ~/.agents/skills/nolo-plan \
  ~/.claude/skills/nolo-plan \
  ~/.codex/skills/nolo-plan \
  ~/.grok/skills/nolo-plan
```

若已配置 `multi-cli-sync` 的 `PERSONAL_EXCLUDE_SKILLS=("nolo-plan")`，直接跑 `sync` 也会清掉上述目标里的副本。

## 语言建议

本仓库源码优先中文维护。

对于非中文用户，推荐流程是：

1. 保留原始中文版本作为上游真值
2. 让代理翻译成你的工作语言
3. 在你自己的环境里安装翻译后的版本
4. 后续若上游更新，再重新翻译

## 给不同用户的建议

- 个人用户：从 `multi-cli-sync/` 开始
- 日常编码：优先 `root-cause-debugging/` + 项目自己的 workflow，而不是默认装 `nolo-plan/`
- 需要 plan/派发编排时：再手动打开源目录 `nolo-plan/`，不要自动同步安装

## 不建议做的事

- 不要把所有 skill 无差别全装上
- 不要把公开 skill 直接改成依赖你私有仓库路径的版本
- 不要在这里提交包含密钥、私有地址、内部账号信息的内容
- 不要把「删安装副本」做成「删源仓库」

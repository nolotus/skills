---
name: click-path-audit
description: >
  追踪按钮/触点的完整状态变迁，抓「函数各自对但互相抵消」的 UI/状态 bug。
---

# click-path-audit

**权威来源**：<https://github.com/nolotus/skills/tree/main/click-path-audit>（本地：`~/skills/click-path-audit/SKILL.md`）

本文件是薄入口。完整审计步骤以外部 skill 为准。

## bun-nolo 补充

- 适用：dialog / composer / quick-chat / object-assistant / 客户端 store 剥离与联动
- 派发：状态或交互大改后可 `--skill ~/skills/click-path-audit/SKILL.md`（与 UI / Coding Style 叠加）
- 范围必须写进 spec（单触点 / 单表面 / 单 store 调用方）；禁止默認全应用审计

---
name: search-first
description: >
  写代码前先搜：仓库内已有实现 → 现有依赖 → 外部包/文档。触发词：新功能、加依赖、
  新 helper/抽象、search first、别重复造轮子。
---

# search-first

**权威来源**：<https://github.com/nolotus/skills/tree/main/search-first>（本地：`~/skills/search-first/SKILL.md`）

本文件是薄入口。完整流程以外部 skill 为准；与 nolo-plan 实现阶梯配套使用。

## bun-nolo 补充

- 优先复用 workspace 包与 `docs/skills` / 现有 seam，再考虑新依赖
- 派发实现类 task 且涉及「新抽象 / 新依赖」时，spec 可要求执行者先按 search-first 结论再写代码
- 挂载：`nolo agent run … --skill ~/skills/search-first/SKILL.md`（或 softlink 后的 skill 名）

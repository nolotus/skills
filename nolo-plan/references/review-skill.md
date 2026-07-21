---
name: nolo-review
description: >
  Reviewer 动态挂载技能。派 reviewer 时用 --skill 挂载，让 reviewer 自动拿到
  Finding 质量门、假阳性清单、角色检查项、AI 生成代码关注点和输出格式要求。
  规划者无需手动摘录规则进 spec。
---

# Nolo Review Skill

> 本 skill 通过 `nolo agent run <reviewer> --skill <path-or-dbKey> --msg-file <spec>` 挂载到 reviewer。
> reviewer 自动拿到以下全部规则；spec 只写任务特定内容（diff、角色、检查范围）。

## Finding 质量门（硬规则，每条 finding 报出前过）

报任何 finding 前过四问，任一答"否"或"不确定"则降级或丢弃：

1. **能引用确切行号?** — 命名文件和行号。"auth 层某处"这类模糊发现不 actionable，丢弃。
2. **能描述具体失败模式?** — 命名输入、状态和坏结果。说不出触发条件 = 模式匹配，不是 review。
3. **读过周围上下文?** — 查过调用方、imports、测试。很多表面问题是上一层已处理或有类型 guard。
4. **严重度站得住?** — 缺 JSDoc 永远不是 HIGH；测试 fixture 里的 `any` 永远不是 CRITICAL。严重度膨胀比漏报更伤信任。

### HIGH / CRITICAL 必须带证据

任何标记 HIGH 或 CRITICAL 的 finding 必须附带三条凭证，缺一条则降级到 MEDIUM 或丢弃：

1. **确切代码片段 + 行号**
2. **具体失败场景**：什么输入 → 什么状态 → 什么坏结果
3. **为什么现有防护挡不住**：类型系统/校验/框架默认为什么没覆盖

### 零发现是合法结果

干净的 review 是有效的 review。不要为证明 review 跑过而制造 finding。
如果 diff 小、类型完备、有测试、遵循项目模式，正确输出是零 finding + `Clean review`。
制造的 finding、填充式 nitpick、猜测性"考虑用 X"、无触发条件的假设性 edge case
是 LLM reviewer 的主要失败模式，直接损害 review 的价值。

## 假阳性清单（报之前先排除）

LLM reviewer 常见误报模式。报之前先验证，除非有本代码库的具体证据：

| 模式 | 跳过条件 |
|---|---|
| "考虑加错误处理" | 先查调用方/框架是否已处理（Express error middleware、上层 try/catch、Promise .catch 链）。处理了就跳过。 |
| "缺少输入验证" | 函数是内部调用且调用方已校验——追踪至少一个调用方再报。 |
| "可能空指针" | 上一行已类型收窄或有 if guard——追踪类型流，别只看 `?.`。 |
| "魔法数字" | HTTP 状态码(200/404)、1000ms、60、24、1024、数组索引 0/-1 等已知常量跳过；单用途局部常量且变量名自解释的也跳过。 |
| "N+1 查询" | 固定基数循环（枚举四元素）或已用 DataLoader/batching 不算。 |
| "函数太长" | 穷举 switch、配置对象、测试表、生成代码不算。长度 ≠ 复杂度。 |
| "缺少 await" | 先查是否有意 fire-and-forget（日志/指标/后台队列推送）。看有无注释或 `void` 前缀。 |
| "应该用 TypeScript" | JS-only 文件不报。匹配项目现有语言，不建议换栈。 |
| "硬编码值" | 测试 fixture、示例代码、文档片段里的硬编码是正确的。测试就该有硬编码期望值。 |
| "安全戏" | 非密码学场景的 `Math.random()`（动画/jitter/采样）不报；插件系统里明确是代码加载面的 `eval`/`Function` 不报。 |
| "Prefer const over let" | 变量被重新赋值时不报。读完整函数再报。 |
| "Missing JSDoc" | 单用途内部 helper 且名称+签名自解释的不报。 |

判断标尺：**这个团队的高级工程师真会在 review 里改这个吗?** 不会就跳过。

## 角色检查项

reviewer 按规划者指定的角色审查。未指定角色时全部检查。

### 安全审计员
- 硬编码凭证（API key/password/token/connection string in source）
- SQL 注入（字符串拼接 vs 参数化查询）
- XSS（未转义的用户输入渲染到 HTML/JSX）
- 路径穿越（用户控制的文件路径未消毒）
- CSRF（状态变更端点缺 CSRF 保护）
- 认证绕过（受保护路由缺 auth 检查）
- 日志泄露敏感数据（token/password/PII 出现在日志里）

### 数据完整性审计员
- 幂等性（重复调用是否安全）
- 竞态条件（TOCTOU、并发写、缺锁）
- 事务原子性（部分失败是否回滚）
- 数据丢失风险（删除路径、账号切换、迁移）
- 跨边界泄漏（内部 ID/状态暴露到外部 API）

### 架构审计员
- 设计边界（新增耦合是否合理）
- 循环依赖
- 可维护性（是否过度工程、单实现抽象、无人 config）
- 是否与现有抽象重复（制造第二份真值）
- API 兼容性（签名变更是否破坏调用方）

### 用户体验审计员
- i18n（硬编码用户可见字符串）
- stuck state（loading/error/empty 状态是否覆盖）
- error handling（用户可见错误是否友好且不泄露内部细节）
- 可访问性（ARIA、键盘导航、语义 HTML）

### 静默失败猎手
- 空 catch 块（`catch {}` 或忽略异常）
- 危险降级（`.catch(() => [])`、默认值掩盖真实失败）
- 丢失堆栈（generic rethrow、缺 async 处理）
- 缺超时（外部 HTTP/DB 调用无 timeout）
- 缺回滚（事务性操作失败后不回滚）
- log-and-forget（记了日志但没传播错误）

## AI 生成代码 review 关注点（所有角色通用）

nolo-plan 审的 diff 几乎全是 AI 生成代码。除各角色专有检查项外，所有 reviewer 额外关注：

1. **行为回归**：改 A 处时是否破坏了依赖 A 旧行为的 B 处？AI 不追踪全调用链，reviewer 要补查。
2. **信任边界**：新代码是否假设输入来自可信源？外部输入（用户/API/DB 读出）是否验证后才用？
3. **隐藏耦合**：是否新增了与现有抽象重复的能力？是否制造了第二份真值？
4. **成本复杂度**：是否过度工程？单调用场景是否加了抽象层/retry/配置项？

## 输出格式

按严重度组织。每条 finding：

```
[CRITICAL] 标题
File: path/to/file.ts:42
Issue: 具体问题描述
Fix: 具体修复建议（代码级，不是高层建议）
```

### 结尾必须带 Summary

```
## Review Summary

| Severity | Count | Status |
|----------|-------|--------|
| CRITICAL | 0     | pass   |
| HIGH     | 2     | warn   |
| MEDIUM   | 3     | info   |
| LOW      | 1     | note   |

Verdict: APPROVE / WARNING / BLOCK
```

- **APPROVE**：无 CRITICAL 或 HIGH，包括零 finding 的干净 review
- **WARNING**：仅 HIGH（可合并但需注意）
- **BLOCK**：有 CRITICAL（必须修复后才能合并）

不要为了显得严格而拒绝批准。diff 干净就 APPROVE。
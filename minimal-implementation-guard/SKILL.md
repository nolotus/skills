---
name: minimal-implementation-guard
description: >
  当任务提到最简单方案、最小实现、YAGNI、over-engineering、bloat、boilerplate、不必要依赖，或询问能删除什么时使用；也在实现、自动化、接系统或面向用户交付物动工前做隐性假设预检（维护路径、所有权、数据真值可能被快捷实现破坏时）。Make sure to use this skill for any review pass focused on reducing avoidable complexity. Do NOT use as a substitute for security review, correctness verification, or data integrity checks.
---

# 最小实现护栏

Ponytail 风格护栏。它约束实现和 review，但永远不替代项目自身的工作流规则、任务路由、source-of-truth 检查、安全、可访问性或验证。

## 阶梯

从上往下问，第一条能成立就停在那里：

1. **Does this need to exist?** 如果需求只是猜测，跳过或先问。
2. **能删除解决吗？** 优先删死分支、死 flag、wrapper 或副本。
3. **标准库能做吗？** 能就用标准库。
4. **平台能力能做吗？** 新写代码前，先看浏览器、CSS、DB、shell 或 OS 能不能承担。
5. **已有依赖能做吗？** 先用已安装依赖，再考虑新增依赖。
6. **现有项目抽象能做吗？** 扩展已有路径，不要新开平行体系。
7. **最后才写代码：** 写最小、正确、已验证的 diff。

## 隐性假设预检（动工前）

最小实现不等于把背后的真实工作流做坏。编辑文件、安装、部署或提出具体方案前，先在推理里回答；有风险就明确告诉用户：

1. 真正的交付物是什么：演示、原型、内部工具，还是给真实用户的正式产物？
2. 交付后谁维护、通过什么入口维护（CMS/后台/配置/API/表格/数据库/命令）？
3. 哪个 source of truth 必须继续保持权威？你的实现会不会绕过、复制、缓存、硬编码或影子化它？
4. 如果为了快走捷径，未来哪一个真实用户动作会先坏掉？

答案暴露维护或所有权风险时，围绕真实工作流重设计，或先和用户确认取舍。小任务一句话表态即可（「保留现有 source of truth 为权威，只改展示层」）；完成前验证输出确实读自权威数据源，且没有引入第二个未来还得单独维护的编辑入口。

## 简化的硬边界

- 保持权威来源的权威性：数据库、config、admin path、任务状态、release history 和 docs 仍然是真值。
- 不要为了让 diff 更小而 hard-code、shadow、snapshot 或 cache 用户可编辑内容或运维状态。
- 不要简化掉 trust-boundary validation、防数据丢失处理、安全、可访问性基础、发布回滚语义或必要证据。
- 项目工作流要求 plan gate、evidence gate 或性能协议时，不要绕过。
- 不要新增 runtime helper、route、config layer、dependency 或 abstraction，除非现有路径明确无法承载请求。

## 实现时使用

- 编辑前先说清这次应停在哪一阶。
- 优先一个窄改动和一次聚焦验证。
- 只有在有意采用有上限的简化时，才留短 `ponytail:` 注释，并写清上限和升级触发条件，例如 `// ponytail: linear scan; index if this crosses 10k rows`。
- 非平凡逻辑要留下一个可运行检查，逻辑坏了它会失败。平凡一行改动不需要新增测试。

## Review 时使用

做 over-engineering review 时，只报告可避免复杂度：

- `delete:` 死代码、猜测性功能、没被使用的灵活性。
- `stdlib:` 语言标准库已经提供的手写行为。
- `native:` 可由平台能力替代的代码或依赖。
- `yagni:` 只有一个实现的抽象、没人设置的 config、只有一个调用方的 layer。
- `shrink:` 同样行为可以用更少行表达。

使用格式：

`path:L<line>: <tag> <what to cut>. <replacement>.`

结尾写 `net: -<N> lines possible.` 如果没有值得删的内容，写：
`Lean already. Ship.`

正确性、安全、数据完整性和性能问题属于普通 review 路线，不属于这个只看复杂度的 pass。

## Boundaries

- 只看实现复杂度（是否可以更简单/更少/删掉），不替代安全审查
- 不覆盖正确性、数据完整性、性能问题
- 不否定用户明确要求的复杂方案，只标记可简化点

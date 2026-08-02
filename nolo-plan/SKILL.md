---
name: nolo-plan
description: >
  nolo 平台编排方法：计划先行 → 用宿主 listAgents（或 nolo agent list）读取收藏、简介、能力和成本 → 并行派发 →
  跨模型 review；兼最小实现护栏（YAGNI、实现阶梯、隐性假设预检）——**动工前**的决策部分。
  适用于任何装了 nolo CLI 或宿主提供编排工具的编码 agent。触发词：子代理、并行执行、派发 task、多 agent review、
  plan 然后执行、稳定写代码、startAgentRun、nolo agent run、最简单方案、最小实现、YAGNI、over-engineering、
  bloat、boilerplate、能删除什么、压复杂度。双出口：微/最小改动做完护栏后就地完成；非平凡任务
  继续 plan→派发→review。纯问答不进实现工作流。Do NOT use as a substitute for security review、
  correctness verification, or data integrity checks；review 规则统一见 `nolo-review`，commit/push
  规则见 `nolo-commit`。
  本 skill 以软链挂载到 CLI skill 目录，真源唯一保留在源仓库；改源即生效，无副本漂移。
---

# Nolo Plan → Dispatch → Review

> **职责边界**：本 skill 负责动工前的判断、任务拆分、执行者编排和 review 派发；`nolo-review`
> 负责 reviewer 的全部审查规则、finding 质量门、角色检查、精简 pass 和输出 Verdict。
> 不在两个 skill 里复制 review 规则。

默认通过宿主编排工具（listAgents / startAgentRun / controlAgentRun / callAgent）派发执行者；宿主工具不可用时降级到 nolo CLI（`nolo agent list` / `nolo agent run`）。两者共用同一套 agent 目录与 run 存储（~/.nolo/runs），runId 互通。用收藏偏好和代码维护的能力数据缩小候选，再用当轮探活确认可用性。
收藏是用户的长期偏好，不是绕过任务兼容性、权限或运行时可用性的硬覆盖。

## 强制门（规划者每个任务第一句）

规划者开始回复时必须同时完成两件事：

1. **声明出口**：微/最小（护栏后就地完成）、非平凡（完整 plan→派发→review）或纯问答（不进实现流），并给一句理由。
2. **声明通道**：非平凡任务在同一句话里说明将从宿主 `listAgents`（或 `nolo agent list`）读取候选；不要查表、不要凭记忆硬编码 agentKey。

出口只按预计步数判定：预计需要 3 步或以上（含读改验、多文件改动或任何派发）就是非平凡；仅 2 步以内的机械改动才可走微/最小出口。

**硬刹车**：非平凡任务完成 plan 后，默认必须通过宿主 `startAgentRun`（或 `nolo agent run`）派发实现 task；只有微/最小改动、紧急解阻，或返工沟通成本明确高于自己修复成本时，规划者才可就地实现，并写出例外理由。

## 最小实现护栏（实现类任务，含微改；动工前）

### 隐性假设预检

先确认交付物是演示还是真用户产物、谁维护、从哪个入口改、谁是权威真值，以及捷径会先破坏哪个真实用户动作。检查是否会 hard-code、shadow、复制或缓存第二份真值。

### 实现阶梯

按顺序检查，第一条成立就停：需求是否该存在 → 能删解决吗 → 标准库 → 平台能力（浏览器/CSS/DB/shell/OS）→ 已有依赖 → 现有项目抽象 → 最后才写最小正确 diff。

动手写新 helper、抽象或加依赖前，先按 `search-first` skill 搜仓库和现有依赖；纯机械改动与用户已点名文件的任务可以跳过。

不得为了省代码删掉信任边界校验、数据完整性、可访问性基础、发布/回滚语义或必要证据。能不加 helper、route、config、依赖和抽象就不加。

## 第 0 步：从 agent list 发现执行者

### 读取当前列表

非平凡任务优先用宿主 `listAgents` 读取安全摘要（结构化返回，与 CLI 同一数据源）；宿主工具不可用时降级到 CLI：

```bash
which nolo
nolo agent list --json --safe
```

`--safe` 不可用时，最多降级一次到 `nolo agent list --json`；不得再引入静态选人清单或本地硬编码名单。CLI 安装、认证和参数细节由 `nolo-cli` skill 负责。

派发时使用列表返回的稳定 `id`（宿主 `listAgents` 与 `nolo agent list` 返回同源 `id`，如 `01KYKNY0D2V4BA10EJ3QEYZ6KG`），不要用展示名称猜 agentKey，也不要把 `publicKey` 当成派发参数，除非命令明确接受它。宿主 `listAgents` 说明中提到的 `readAgent` 用于解析完整 agentKey；实测宿主 `startAgentRun` 直接用列表 `id` 即可派发成功。

### 选择顺序

对列表中的候选按下面顺序处理：

1. **过滤不可用候选**：排除孤立记录、缺少必需 provider/模型的记录，以及与任务权限或特定工具明显不兼容的记录。
2. **收藏优先**：在仍然胜任任务的候选中，优先 `isFavorite: true`，同组按 `favoritedAt` 的最近程度作为偏好信号。
3. **读取简介**：从 `introduction` 判断任务用途、稳定限制和适用场景。用途说明先放在 introduction 里即可，不要求新增 `recommendedFor` 字段；如果以后需要这个概念，先继续写进 introduction。
4. **读取代码维护的能力表**：比较 `modelAbility.passAt1`、`modelAbility.benchmarkScore` 等已提供值。缺失值代表未知，不要根据模型名字臆造分数或 rank。
5. **比较成本与供给方**：使用列表中的 `inputPrice`、`outputPrice`、provider 和 apiSource；`null` 是未知，不当成免费。用户没有要求更强能力时，在胜任候选中优先低成本。
6. **最后探活**：对准备派发的候选做一次短探活；失败就换下一个同等胜任候选。

```bash
nolo agent run --agent <agentKey> --msg "只回复 PONG" --local --ephemeral --timeout-ms 100000
```

探活必须 `--ephemeral`（CLI）或使用宿主短任务通道（如 `callAgent`，<100s 同步拿结果），避免把 PONG 写进用户历史、收藏会话或 LevelDB。任何不产出用户价值的探针、烟测和准入检查都使用该参数；真实任务才持久化。

### 工具匹配规则

`coding` 视为默认能力：CLI、桌面以及常规 web/RN 编码任务，不因为 tools 摘要为空就判定 agent 不能 coding。tools 只用于判断特定工具任务，例如浏览器控制、图片生成、表格写入、邮件发送或数据库操作；特定工具缺失时才淘汰候选。

不要把“模型能力”和“工具能力”混成一个分数：模型能力看 `modelAbility`，任务工具看 tools，运行时可用性看探活。

### 时间与价格策略

峰谷价格、北京时间窗口、额度和 provider 限流属于产品代码的动态路由层，不在这个 skill 里维护第二份价目表。若 CLI 或执行器暴露了当前 effective cost/provider policy，规划时使用它；否则只使用本次 agent list 的价格摘要，不硬编码某个 provider 的时间规则。

### 选人声明与配置核对

派发时简短说明：`agent list` 选中了哪个 agent、是否因用户收藏优先、简介/能力/成本的主要依据是什么。不要再说“静态名单命中”或建议用户维护额外清单。

新建或刚修改过 agent 时，派发前用 `nolo agent read <agent>` 复核实际生效的 model/provider；不要假设创建命令里的参数就是最终配置。

失败、超时和额度耗尽是当轮 runtime 事实，不写回 introduction、modelAbility 或任何隐式“推荐”字段。只有用户明确要求，才更新 agent 的简介或提示词；稳定的模型能力数据由代码/基准维护。

## 任务复杂度与 brief 预算

不要用文件数量代替复杂度，至少评估四个维度：

| 维度 | 低 | 高 |
|---|---|---|
| 判断密度 | 结论已定、机械执行 | 需要决定保留/删除/迁移/边界 |
| 上下文面 | 目标文件加一个参考 | 多个权威源、历史和测试 |
| 输出耦合 | 一个主产物 | source、router、mirror、tests 互相约束 |
| patch 面 | 局部替换 | 大段语义重写或跨模块改动 |

一个执行 task 只允许一个主交付物，外加最多一个不可分割的验证。不要把“读完整 plan、探索多个来源、同时改 source/router/mirror/tests、跑全量验证”塞进一个 brief。

执行者能力未知或较弱时，规划者先把方案编译成更具体的 brief：

- 机械任务：给命令级指令、文件清单和逐条验收。
- 常规实现：给已定结论、文件清单、边界和验收。
- 设计任务：给目标、排查起点、禁区和风险，让高能力 agent 判断细节。

写完 spec 后搜索“自行/确认/判断/决定/选择”等开放式词；若任务交给较弱候选，先由规划者把关键结论定下来。

### 验收基线与回归测试

spec 中出现“基线 N pass / M fail”时，规划者必须先亲自跑完全相同的命令并填入当轮真实数字，不得凭记忆。新回归测试声称覆盖 bug 时，修复临时去掉必须变红，装回后再跑必须变绿；只证明“修复后为绿”不够。

并发工作区下测试数字可能漂移。优先使用残留符号 grep、文件存在/删除、受影响的最小测试集和不受并发影响的判据；spec 明确列出并行会话的禁区文件，执行后用 `git status --short` 自查。

## 第 1 步：写 plan（非微/最小出口必做）

plan 是文件或等价的可追踪记录，至少包含：

1. 目标与非目标。
2. 每个 task 的目标、文件路径、权威真值、禁区和验收标准。
3. 依赖关系与并行 wave；互不依赖的 task 放同一 wave。
4. 从本次 `agent list` 选人的依据、执行通道和 timeout。
5. 验证命令、预期证据、风险、回滚方式和已知阻塞。
6. review handoff：diff 范围、需要的角色或风险面、以及挂载 `nolo-review` 的方式。具体 review 规则只引用 `nolo-review`，不要复制到 plan。

写 task 前先查目标现状；执行者会忠实执行 spec，把猜测写成指令会直接注入 bug。

## 第 2 步：派发

plan 写完后，按选定 agent 派发实现 task。宿主提供 `startAgentRun` 时默认用它（后台启动、返回 runId，用 `controlAgentRun` 观察/叫停；需要 <100s 同步结果时用 `callAgent`）；宿主工具不可用时用 CLI：

```bash
nolo agent run <agentKey> --msg-file <task-spec.md> --local --cwd <path> --bg --timeout-ms <按复杂度>
```

宿主 `startAgentRun` 与 CLI 派发共用同一 run 存储（~/.nolo/runs），runId 格式互通，`controlAgentRun` 可观察任一通道派发的 run。task prompt 必须自包含，不传聊天历史；宿主 `startAgentRun` 的 `task` 参数承载子任务描述（对应 CLI `--msg-file` 的职责），`input` 只放附加数据（如抓取到的原始内容）。能拆就拆，互不依赖的文件树并行派发；共享热路径按包路径切分，不让两个 agent 同时改同一文件。

并行改代码必须使用独立 worktree：

```bash
git worktree add <dir> -b <branch>
```

不允许在同一工作目录用 `git switch`/`git checkout` 切分支代替 worktree。主 checkout 保持不动，完成后按项目规则清理 worktree。

编码/修 bug/refactor/写测试任务挂载项目 Coding Style skill；前端 UI 任务同时挂载 UI guidelines；共享客户端状态或按钮联动任务再挂载 `click-path-audit`，并把审计范围限定到单触点、单表面或单 store。coding 工具本身不作为 CLI/桌面任务的额外准入门槛。

### timeout 与进度

| 任务 | timeout | 模式 |
|---|---:|---|
| 结论已定的机械小改、窄探针 | 300000 | 前台或短任务 |
| 语义重写、一个长文件、2–5 文件实现 | 600000 | `--bg` |
| 跨模块或多 task | 900000 | `--bg`，必要时拆分 |

每条后台 run 都记录 runId，并通过控制面查看进度。宿主默认用 `controlAgentRun`（action: list / status，可带 tailLines 看日志）；宿主工具不可用时用 CLI：

```bash
nolo agent ps --json
nolo agent status <runId> --json
nolo agent logs <runId> --tail 50
```

`fileEdits=0` 不等于没有进展。停杀前连续两次 probe，间隔 60–90 秒，对比 `lastEventAt`、`llmCalls`、`toolCalls`、日志和 diff；单个工具调用远超同类命令的正常耗时，优先检查它是否被自己的产物卡住。只有 counters、日志和 diff 都没有变化，或硬 timeout 且无产物，才判定 stall。

失败先分为 `controller_prompt`（spec/任务面问题）、`runtime`（OAuth、connector、CLI、timeout）或 `model`（正确 brief 和 runtime 下仍交付失败）。按分类修 spec、换通道或换候选，不要把一次 runtime 失败写成 agent 的永久性能力结论。

## 第 3 步：Review 编排

非平凡实现交付后进入独立 review 门。规划者只负责：

1. 读取 `nolo-review` 的 Review Dispatch Contract，按其规则从 `agent list` 选择 reviewer。
2. 给 reviewer 任务特定的 diff、背景、检查范围和验收证据。
3. 挂载 `nolo-review`，并在 task 中按其 dispatch contract 明确 read-only 行为约束；不要粗粒度禁掉 reviewer 获取 diff 和上下文所需的工具。
4. 根据 `nolo-review` 的结果决定返工、收尾或升级；reviewer 的检查项、严重度、精简 pass、输出格式和 Verdict 全部以 `nolo-review` 为唯一真源。

派发形态（宿主工具默认）：`startAgentRun` 派发 reviewer，并把 nolo-review 的规则放进 `task` 描述（如「按 nolo-review 规则审查以下 diff…」+ 规则要点或要求 reviewer 先 loadSkill("nolo-review")）；若宿主提供 `callAgent` 也可用内置同步通道。宿主工具不可用时用 CLI（`--skill` 挂载）：

```bash
nolo agent run <reviewer> \
  --skill <nolo-review 的 SKILL.md 路径或 dbKey> \
  --msg-file <review-spec.md> --local --bg --timeout-ms <按范围>
```

task 中只写 diff/角色/范围/背景，并指明按 `nolo-review` 规则 read-only review。不要在 plan 中再次摘录 review 规则。

返工前算“继续沟通/等待”与“自己接手修复”的成本；第一轮就交付垃圾可以直接收回，连续返工仍不满足就停止追加沟通或升级给用户。review 的重试、证据和完成判定按 `nolo-review` contract 执行。

## Commit 与边界

commit 的分组、`Assistant-Model` trailer、push/部署批准边界由 `nolo-commit` skill 定义；需要提交时先加载它。

- 不替代宿主 CLI 的权限与安全规则。
- 不覆盖部署/发布流程。
- 不创建额外的持久选人清单；`agent list` 是候选来源，不把推荐逻辑复制到第二份文档。
- 不自动修改 agent introduction、prompt 或能力数据；只在 owner 明确要求时执行 profile 更新。
- nolo CLI 命令细节见 `nolo-cli` skill。

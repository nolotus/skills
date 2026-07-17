---
name: nolo-plan
description: >
  nolo 平台编排方法：计划先行 → nolo CLI 查指派表选执行者 → 并行派发 → 跨模型 review。
  适用于任何装了 nolo CLI 的编码 agent。触发词：子代理、并行执行、派发 task、多 agent review、
  plan 然后执行、稳定写代码、nolo agent run。Do NOT use for 单文件微小修改或纯问答。
---

# Nolo Plan → Dispatch → Review

融合**计划先行**(先想清楚再动手)、**最小实现**(能删不加)、**极简输出**(只说结果)。通过 nolo CLI 派发执行者，用便宜模型和并行把代码写得又快又稳。

## 强制门(每个任务第一句,不可跳过)

开始回复时**必须同时完成两件事**,缺一即违规:

1. **声明**:当前任务是否适合进入 plan——适合 → 走下方完整流程;不适合(微小机械改动/纯问答)→ 一句理由再动工。
2. **选通道**:适合 plan 时,**同一句话里报出执行通道**——查 nolo 指派表选执行者(见第 0 步)。没装 nolo CLI → 见 `references/setup.md`;装不了或不可用就按下方算账降级,不阻塞。

**派发前算账**:声明"适合 plan"后,实现类 task 默认派发执行者(`nolo agent run`);但派发前先算一次账——spec 编写 + 轮询 + review 的总成本 vs 规划者直接实现并自验的成本,便宜者胜,结论一句话说明。nolo CLI 不可用时降级为宿主 subagent 或直接执行,不阻塞任务。

## 第 0 步:发现执行者

### 前置:nolo CLI 可用性

`which nolo` 不存在 → 走 `references/setup.md` 引导;装不了或不可用时按派发前算账降级为宿主 subagent 或直接执行,不阻塞任务。

### 查指派表

指派表是一张 purpose=`agent-dispatch` 的 nolo table,存用户精选的执行者(列:agentKey / rank / recommendedFor / notes / currentUsage)。一条命令发现:

```bash
nolo table list --purpose agent-dispatch --json
```

- **有表** → `nolo table query --table <dbKey> --json` 查行,按 rank 选执行者。表里带排序、用途、额度状态,是派发真值。
- **没表** → `nolo agent list --json` fallback 全量列表(无 rank/用途),选最便宜可胜任的。同时引导用户建指派表(见 `references/setup.md`)。

### 档位选择与 spec 颗粒度(硬要求)

原则:用能胜任的最低档;派得越低,规划者探索得越深(把智商「编译」成目标档位能执行的指令)。额度标 `暂停` 的跳过,换同档下一个;review 换模型家族。

| rank | 适合任务 | 探索深度 | spec 必须包含 | 禁止 |
|---|---|---|---|---|
| 4+ 机械 | grep 调用点、改常量、跑测试 | 命令/行级 | 命令级指令、文件清单、逐条验收;可大范围但路径明确 | 语义模糊目标("优化一下") |
| 3 低 | 加一个函数、改 CSS、写测试 | 结论级(方案已定) | 文件清单 + 已定结论/方案 + 验收;范围小 | 开放式判断、"自行探索确认" |
| 2 中 | 新模块、跨文件重构、API 改动 | 边界级(排查起点+禁区) | 目标 + 排查起点 + 验收;可含设计判断但给边界 | 无边界的"整个包重构" |
| 1 高 | 核心算法、安全边界、性能关键 | 只给目标与约束 | 目标 + 约束 + 风险提示 | 过度约束限制其判断 |

**规划者自检**:spec 里出现「自行/确认/判断/决定/选择」且执行者 ≤rank3 → 先自己把这一步做掉(或先派 rank2 出结论);低档拿到开放判断题的典型结局是长时间探索、零编辑、超时。探索深度看**判断密度**不是代码量;标尺:预估「返工一次成本」vs「多探索 10 分钟成本」,取便宜的。

### Task 面预算(派发前硬门)

选模型和 timeout 前先评估四个维度,不能用「文件数」代替复杂度:

| 维度 | 低 | 高 |
|---|---|---|
| 判断密度 | 结论已定,机械执行 | 要决定保留/删除/迁移/架构边界 |
| 上下文面 | 目标文件+一个参考 | 完整 plan+多个权威源+历史/测试 |
| 输出耦合 | 一个主产物 | source+router+mirror+tests+plan 状态互相约束 |
| patch 面 | 局部替换 | 大段语义重写或跨多个维护入口 |

任一维度高就不是 rank4 机械吞吐任务。高判断密度的文档/skill 重构与代码架构任务同档处理;「只是 Markdown」「只有一个文件」都不是降档理由。

**Task brief 预算**:一个执行 task 只允许一个主交付物,外加最多一个不可分割的伴随验证。禁止把「读完整 plan → 自行探索多个来源 → 同时改 source/router/mirror/tests → 跑全量验证 → 更新 plan」包装成一个 task。dispatch brief 只摘录当前 task 的已定结论、目标文件、禁区和验收;除非 task 本身是 plan review,否则不要求执行者读完整 plan。

**语义重写分阶段**:规划者先确定 keep/move/delete 映射与目标结构 → task A 只改权威 source → task B 同步 mirrors/adjacent pointers → task C 更新行为测试。测试依赖 source 时不得与 source 语义设计混成同一个执行 task。

### 性格档案与失败写回(硬规则)

- 指派表除档位外必须记**性格缺陷 + 解药**(如:某模型探索黑洞→spec 给结论;某模型语义弱→验收写成可机检命令;某模型空响应→自动降级)。
- 每次返工/停杀/失败先分类:`controller_prompt`(任务面/spec 有问题)、`runtime`(OAuth/connector/CLI/timeout)、`model`(在正确 bounded brief 与可用 runtime 下仍判断或交付失败)。观察可以写进任务记录;只有证据隔离到 `model` 时才把性格缺陷写回指派表,禁止用坏 prompt 污染 agent 档案。
- 衡量执行者「能不能用」的唯一 KPI 是**一次交付率**(带着当前 spec 模板一次通过验收的比率),不是模型名气。

### 速度优先与额度维护

- 同档多个 agent 里优先选实测更快且可用的,不要死绑某一 handle(**智商档 ≠ 速度档**)。
- 派发前读指派表 `currentUsage`/`notes`;`暂停` 开头或明确额度耗尽的跳过,换同档下一个。
- 额度耗尽/runtime 挂时,把原因+日期写回表(`currentUsage`,必要时 `recommendedFor` 加「暂停/恢复后」前缀),避免下个 session 误派。
- **宿主模型 ≠ nolo 执行通道**:宿主可用只说明规划者可用;派执行者仍要可用的 `nolo agent run --local` agentKey。

### 超时档位

派发时必须设 `--timeout-ms`,按任务复杂度选档:

| 档 | 任务 | timeout | 模式 |
|---|---|---|---|
| 快 | 结论已定的机械小改、窄探针 | 300000 (5min) | 前台 |
| 中 | 语义重写、一个长文件、或 2-5 文件实现 | 600000 (10min) | `--bg` 后台 |
| 大 | 跨模块、多 task | 900000 (15min) | `--bg` 后台,或拆分 |

单文件不自动等于快任务;超过约 200 行的语义重写默认至少中档。超时 ≠ 失败——执行者可能在读文件、生成长 patch 或跑测试。优先用 `--bg` 后台派发,不阻塞规划者。

### 可靠 stall audit(禁止只看 0 edit)

`fileEdits=0` 只说明尚未落盘,不等于无进展。停杀前必须:

1. 连续两次 probe,间隔 60-90 秒,对比 `lastEventAt`、`llmCalls`、`toolCalls`、log tail 与 `git diff`。
2. 检查 `inFlight`;近期仍有 LLM/tool 事件时按活跃生成处理,不要因为长 patch 尚未返回就停。
3. 只有 counters、日志和 diff 在两次 probe 间都无变化,或已到硬 timeout 且无产物,才判定 stall。
4. 发 stop 前后各查一次 `git diff`/`fileEdits`;若停止边界刚落下 patch,从现有 diff 继续,不得报告「0 edit」或无条件重开覆盖。

到 timeout 但持续有活动时,让 run 自然结束或用更长档位重新派发;不要在原 timeout 一半时凭感觉停杀。

### 进度可见(硬规则)

每条 `--bg` 派发记下 `runId`,验收前用控制面轮询而不是干等:

```bash
nolo agent ps --json                                # 全部 run
nolo agent status <runId> --json | --watch          # 单条状态/盯到结束
nolo agent logs <runId> [--tail 50]                 # 细节
nolo agent stop <runId> / kill <runId>              # SIGTERM / SIGKILL
```

向用户汇报时带 runId、agentKey、status 和验收证据。长时间无进展(按上面 stall audit 判定)→ `stop` → 拆小或换通道重派,禁止干等问人。

## 第 1 步:计划(非微小任务必做)

微小豁免:≤2 个文件的机械改动,直接做。其余先写 plan(文件,不是聊天),必含五项:

1. **Task 列表**:每个 task 自包含——目标、涉及文件路径、验收标准。**写 task 描述前先查目标现状**:executor 会忠实执行你的猜测,把猜测写成指令等于亲手注入 bug
2. **并行分组**:互不依赖的 task 标成一组,同时派发
3. **执行通道**:每个 task 按复杂度选档,从指派表按 rank 匹配
4. **Review 策略**:见第 3 步分档
5. **验收证据**:什么产物算完成(diff、测试输出、截图)

计划本身遵循最小实现阶梯:先问"这需要存在吗→能删除解决吗→标准库/平台/已有依赖能做吗",最后才写新代码(详见 `minimal-implementation-guard`)。

## 第 2 步:派发

**硬规则:plan 写完 → 实现类 task 默认派发;豁免只有强制门的派发前算账。** 规划者自己写的 diff 仍受第 3 步「作者回避」约束,必须派另一个 agent review。

- **上下文隔离**:task prompt 必须自包含(文件路径 + 验收标准 + 必要背景),不传聊天历史。省钱且防污染。大上下文用 `--msg-file` 传文件路径。
- **并行**:能拆就拆,能并就并。plan 把独立文件树拆成无文件重叠的并行 wave,同一 wave 一次全部派出(`--bg`),禁止串行干等。共享热路径(全局 store 一类)不拆给两个 agent 同时改,按包路径切分。
- **失败契约**:executor 必须报具体 blocker(缺什么文件/权限/信息),禁止静默失败或泛泛"不确定"。
- 改动多文件时优先隔离 worktree,避免并行 task 互踩。

派发命令:
```bash
nolo agent run <agentKey> --msg-file <task-spec.md> --local --cwd <path> --bg --timeout-ms <按档位>
```

## 第 3 步:Review(跨模型,按复杂度分档)

不同模型训练数据不同、盲区不同——reviewer 尽量换家族。

**作者回避(硬规则,任何档位)**:diff 的 reviewer 不得是产出该 diff 的同一个 agent。执行者不得自审;规划者走豁免亲自实现的改动,同样必须派另一个 agent(尽量换家族)review。自审 = 该 review 无效,按未 review 处理。

| 档 | 判定 | Review |
|---|---|---|
| 小 | 单 task、≤3 文件 | 派发者(非作者)review 执行者的 diff |
| 中 | 多 task 或跨模块 | +1 个不同模型 reviewer |
| 大 | 架构改动、高风险路径 | 2+ 个不同家族 reviewer 并行 |

- Review 只看:正确性、是否超出 task 范围、能否更简单。
- **返工由规划者算账,不设死上限**:每轮返工前评估"继续返工的沟通/等待成本"vs"自己接手修完"哪个便宜。第一轮就交垃圾 → 直接收回自己干,顺便记下该通道不适合这类 task;改了两三轮还不满足要求 → 停止追加沟通,自己收尾或升级给用户。唯一硬规则:不允许无感知的无限循环,每轮必须有这次算账。
- **Review 输出契约**:只有包含 findings/`Clean review` 与实际检查证据的文本才算完成;空响应、只说「我先检查」、或 timeout 都不算 review 证据。最多用更小 prompt 或不同 provider 重试 1 次;仍无有效结论就明确报告 external review incomplete,转规划者/owner review,禁止无限换 agent。

## 输出纪律

汇报只有三段:**结果**(一句话)→ **证据**(diff/测试/URL)→ **下一步**(如有)。删填充词、客套、hedging(没验证就直说没验证);不复述工具过程;报错只引最短的决定性一行;不发明缩写,技术术语/命令/报错原文精确保留;安全警告、不可逆确认、顺序敏感指令时恢复完整表达,说完再回到简洁。失败就直说失败和原因。

## 边界

- 不替代宿主 CLI 的权限与安全规则
- 不覆盖部署/发布(那是项目自己的流程)
- 指派表是用户资产:默认只读;仅在 owner 提供证据(额度截图/bench 结果/明确要求)或失败写回规则触发时,写回 `currentUsage`/`notes`/`recommendedFor`
- nolo CLI 细节见 `nolo-cli` skill

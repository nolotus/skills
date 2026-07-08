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
2. **选通道**:适合 plan 时,**同一句话里报出执行通道**——查 nolo 指派表选执行者(见第 0 步)。没装 nolo CLI → 走 setup 引导,不要跳过。

**硬刹车**:声明"适合 plan"后,实现类 task **必须派发执行者**(`nolo agent run`),不许规划者自己 edit 文件。唯一例外:微小豁免(≤2 文件机械改动)、紧急解阻、或返工算账后自己修更便宜。绕过此条 = 严重违规。

## 第 0 步:发现执行者

### 前置:nolo CLI 可用性

`which nolo` 不存在 → 走 setup 引导(见下方),不要跳过。nolo 是唯一执行通道,没装就不能派发。

### 查指派表

指派表是一张 purpose=`agent-dispatch` 的 nolo table,存用户精选的执行者(列:agentKey / rank / recommendedFor / notes / currentUsage)。一条命令发现:

```bash
nolo table list --purpose agent-dispatch --json
```

- **有表** → `nolo table query --table <dbKey> --json` 查行,按 rank 选执行者(见下方智商档位表)。表里带智力排序、用途、额度状态,是派发真值。
- **没表** → `nolo agent list --json` fallback 全量列表(无 rank/用途),选最便宜可胜任的。同时引导用户建指派表(见 setup)。

### 智商档位选择

查到指派表后,按任务复杂度选 rank 档:

| 智商档 | rank | 适合任务 | 例子 |
|---|---|---|---|
| 最低 | 4+ | 机械改动、收集、跑命令 | grep 调用点、改常量、跑测试 |
| 低 | 3 | 单文件实现、标准模式 | 加一个函数、改 CSS、写测试 |
| 中 | 2 | 多文件实现、需要设计判断 | 新模块、跨文件重构、API 改动 |
| 高 | 1 | 架构决策、高风险路径、难 task | 核心算法、安全边界、性能关键 |
| review | 换家族 | 跨模型 diff 审查 | 用与执行者不同家族的 agent |

**原则**:用能胜任的最低档。低档省钱省时间,高档留给硬骨头。额度标 `暂停` 的跳过,换同档下一个。

### 超时档位

派发时必须设 `--timeout-ms`,按任务复杂度选档:

| 档 | 任务 | timeout | 模式 |
|---|---|---|---|
| 快 | 探索、小改动、单文件 | 300000 (5min) | 前台 |
| 中 | 实现 task、2-5 文件 | 600000 (10min) | `--bg` 后台 |
| 大 | 跨模块、多 task | 900000 (15min) | `--bg` 后台,或拆分 |

超时 ≠ 失败——执行者可能在读文件/跑测试。优先用 `--bg` 后台派发,不阻塞规划者。

### setup

**没装 nolo CLI**:
1. 安装:`curl -fsSL https://nolo.chat/install | bash`(或见 nolo.chat/docs)
2. 登录:`nolo auth login`
3. 验证:`nolo agent list --json` 能返回 agent 列表

**装了但没有指派表**(`nolo table list --purpose agent-dispatch` 返回空):
1. 建表:在 nolo 平台 UI 建一张 table,设 purpose 为 `agent-dispatch`(或用 `nolo table meta --name "Agent Dispatch Matrix" --purpose agent-dispatch` 如果 CLI 支持)
2. 必填列:agentKey(text, primary) / name(text) / rank(number, 1最强) / recommendedFor(text) / currentUsage(text)
3. 加执行者行:把常用的 agent 填进去,按智力排序设 rank
4. 验证:`nolo table list --purpose agent-dispatch --json` 能查到

## 第 1 步:计划(非微小任务必做)

微小豁免:≤2 个文件的机械改动,直接做。其余先写 plan(文件,不是聊天),必含五项:

1. **Task 列表**:每个 task 自包含——目标、涉及文件路径、验收标准。**写 task 描述前先查目标现状**:executor 会忠实执行你的猜测,把猜测写成指令等于亲手注入 bug
2. **并行分组**:互不依赖的 task 标成一组,同时派发
3. **执行通道**:每个 task 按复杂度选智商档,从指派表按 rank 匹配(档位表见第 0 步)
4. **Review 策略**:见第 3 步分档
5. **验收证据**:什么产物算完成(diff、测试输出、截图)

计划本身遵循最小实现阶梯:先问"这需要存在吗→能删除解决吗→标准库/平台/已有依赖能做吗",最后才写新代码(详见 `minimal-implementation-guard`)。

## 第 2 步:派发

**硬规则:plan 写完 → 实现类 task 必须派发,不许规划者自己 edit。** 强制门的刹车在这里生效。微小豁免/紧急解阻/返工算账后自己修更便宜 = 唯一三种例外,需一句理由。

- **上下文隔离**:task prompt 必须自包含(文件路径 + 验收标准 + 必要背景),不传聊天历史。省钱且防污染。大上下文用 `--msg-file` 传文件路径。
- **并行**:同组 task 一次全部派出(`--bg`),不排队。
- **失败契约**:executor 必须报具体 blocker(缺什么文件/权限/信息),禁止静默失败或泛泛"不确定"。
- 改动多文件时优先隔离 worktree,避免并行 task 互踩。

派发命令:
```bash
nolo agent run <agentKey> --msg-file <task-spec.md> --local --cwd <path> --bg --timeout-ms <按档位>
```

## 第 3 步:Review(跨模型,按复杂度分档)

不同模型训练数据不同、盲区不同——reviewer 尽量换家族。

| 档 | 判定 | Review |
|---|---|---|
| 小 | 单 task、≤3 文件 | 派发者自己 review diff |
| 中 | 多 task 或跨模块 | +1 个不同模型 reviewer |
| 大 | 架构改动、高风险路径 | 2+ 个不同家族 reviewer 并行 |

- Review 只看:正确性、是否超出 task 范围、能否更简单。
- **返工由规划者算账,不设死上限**:每轮返工前评估"继续返工的沟通/等待成本"vs"自己接手修完"哪个便宜。第一轮就交垃圾 → 直接收回自己干,顺便记下该通道不适合这类 task;改了两三轮还不满足要求 → 停止追加沟通,自己收尾或升级给用户。唯一硬规则:不允许无感知的无限循环,每轮必须有这次算账。

## 输出纪律

对用户汇报只有三段:**结果**(一句话)→ **证据**(diff/测试/URL)→ **下一步**(如有)。不复述过程,不解释显然的事,失败就直说失败和原因。

## 边界

- 不替代宿主 CLI 的权限与安全规则
- 不覆盖部署/发布(那是项目自己的流程)
- 指派表是用户资产:不擅自改表内容,只读
- nolo CLI 细节见 `nolo-cli` skill
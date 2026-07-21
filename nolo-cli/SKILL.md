---
name: nolo-cli
description: >
  nolo CLI 操作指南（对外）。覆盖 agent、dialog、space、table、认证、machine、
  调试等所有子命令。适用于 nolo-cli 用户和自动化脚本场景。
---

# nolo CLI 操作指南

nolo 是一个 agent-first 终端工作区工具。本 skill 覆盖所有 CLI 命令的使用方式、常用模式、调试流程。

## 安装与基础

```bash
npm install -g nolo-cli        # 稳定版
npm install -g nolo-cli@alpha  # 预览版
```

首次使用：

```bash
nolo                           # 显示帮助
nolo login                     # 登录
nolo whoami                    # 确认身份
nolo update                    # 更新 CLI
```

## 路由表

| 要做什么 | 看哪节 |
|----------|--------|
| 登录、环境变量 | [认证](#认证) |
| 读/跑/改/删 agent | [Agent](#agent) |
| 读/列/查/删对话 | [Dialog](#dialog) |
| 空间管理 | [Space](#space) |
| 文档与 Skill-Doc | [Doc 与 Skill-Doc](#doc-与-skill-doc) |
| 结构化数据表 | [Table](#table) |
| 长期记忆管理 | [Memory](#memory) |
| 机器连接与 daemon | [Machine](#machine) |
| 诊断问题 | [诊断](#诊断) |
| 本地模型 | [本地模型运行时](#本地模型运行时) |

---

## 认证

```bash
nolo login                    # 浏览器 OAuth
nolo login --no-browser       # 终端内完成
nolo login --token <jwt>      # 直接用 token
nolo whoami                   # 当前用户
```

脚本/自动化用环境变量：

```bash
AUTH_TOKEN=<jwt> nolo agent run ...
USER_ID=<userId> nolo agent read <agentId>
```

常用环境变量：

| 变量 | 作用 |
|------|------|
| `AUTH_TOKEN` | JWT token |
| `USER_ID` | 用户 ID（解析私有 key 需要） |
| `READ_DIALOG_BASE` | 远程对话读取的基础 URL |

---

## Agent

### 基础操作

```bash
nolo agent list                # 列出拥有的 agent
nolo agent list --json         # JSON 输出
nolo agent list --public-only  # 仅公开 agent
nolo agent list --ids-only     # 仅 ID

nolo agent read <agent>        # 读取 agent 详情
nolo agent create              # 交互式创建
nolo agent update <agent> --prompt "..."   # 更新字段
nolo agent delete <agent>      # 硬删除
nolo agent unpublish <agent>   # 仅删除公开记录
nolo agent pull <agent>        # 缓存到本地
```

### 运行 agent

```bash
nolo agent run <agent> --msg "你好"
nolo agent run <agent> --bg --msg "后台运行"
nolo agent run <agent> --continue <dialogId> --msg "继续"
nolo agent run <agent> --space <spaceId> --msg "存到共享空间"
nolo agent run <agent> --msg-file /tmp/task.md
nolo agent run --agent fullstack --bg --timeout-ms 600000 --msg-file /tmp/task.md
nolo agent run --agent frontend-implementer --image /screenshot.png --msg "看图定位"
nolo chat --agent <agent> --msg "你好"
```

关键 flag：

| Flag | 作用 |
|------|------|
| `--msg` | 单条消息 |
| `--msg-file` | 从文件读消息 |
| `--bg` | 后台模式，立即返回 dialogId |
| `--continue <dialogId>` | 追加到已有对话 |
| `--space <spaceId>` | 绑定到空间 |
| `--inherit-from-dialog` | 记录父子对话关系 |
| `--category <name>` | 对话分类 |
| `--image <path>` | 附带图片 |
| `--allowed-tool <tool>` | 白名单：只允许指定的工具（可多次传） |
| `--blocked-tool <tool>` | 黑名单：禁止指定的工具（可多次传）；与 `--allowed-tool` 叠加：先白名单留，再黑名单删 |
| `--timeout-ms` | 超时（毫秒） |
| `--local` / `--server` / `--auto` | 运行位置：本机 / 指定服务器 / 自动（默认） |
| `--cwd <path>` | 执行者工作目录 |

超时建议：探针 60-120s；小编辑 300s；正常实现 600s；大范围 900s。

### Handle 解析

Agent 可通过 handle（`fullstack`、`frontend-implementer`、`reviewer` 等）引用。CLI 从缓存或远程记录中解析 handle → agent key。

### 控制面（后台 run 管理）

`--bg` 派发返回 runId 后，用控制面跟踪与干预：

```bash
nolo agent ps --json                       # 列出活跃/最近的本地 run
nolo agent status <runId> --json           # 单条状态；--watch 盯到结束
nolo agent logs <runId> [--tail 50]        # 日志细节
nolo agent stop <runId>                    # SIGTERM 优雅停止
nolo agent kill <runId>                    # SIGKILL 强杀
```

---

## Dialog

```bash
nolo dialog read <dialog>      # 读取对话（URL / dialogId / 完整 key）
nolo dialog list               # 列出对话
nolo dialog query ...          # 按 subject ref 查询
nolo dialog status <dialog>    # 紧凑状态
nolo dialog delete <dialog>    # 删除对话
```

---

## Space

```bash
nolo space create
nolo space list --json
nolo space read <spaceId>
nolo space read <spaceId> --content-key page-user-id --brief
nolo space delete --name-prefix <prefix> --yes
nolo space invite <spaceId> <userId>
nolo space accept-invite <spaceId>
nolo space category ...
nolo space content-category ...
```

---

## Doc 与 Skill-Doc

```bash
nolo doc create --title "标题" --body "内容" --sync local,us --dry-run
nolo doc read <docId>
nolo doc update <docId> --title "新标题"
nolo doc delete <docId>

nolo skill-doc create --title "技能文档" --description "描述" --sync local,us
nolo skill-doc read <docId>
nolo skill-doc update <docId>
nolo skill-doc delete <docId>
```

`--sync` 控制目标：`local` / `us` / `main`。

---

## Table

```bash
nolo table query --table <tableId>
nolo table query --table <tableId> --columns '["title","status"]' --no-base-fields --output items

nolo table add-row --table <tableId> --data '{"title":"任务","status":"todo"}'
nolo table add-rows --table <tableId> --data '[{...},{...}]'
nolo table update-row --table <tableId> --row <rowId> --changes '{"status":"done"}'
nolo table update-rows --table <tableId> --changes '{"status":"done"}' --where '{"status":"in_progress"}'
nolo table delete-row --table <tableId> --row <rowId>
nolo table delete-rows --table <tableId> --where '{"status":"blocked"}'

nolo table list                 # 列出所有 table
nolo table meta ...             # table 元数据
nolo table add-column ...       # 添加列
```

---

## Memory

```bash
nolo memory delete --source-dialog <dialogId> --yes --json
```

---

## Machine

```bash
nolo machine status             # 列出注册的机器
nolo connect                    # WebSocket 连接
nolo connect --watch            # 持续监控
nolo connect --ws               # 纯 WebSocket
nolo connect --daemon --server-url <url> --machine-key <key>
```

---

## 诊断

```bash
nolo doctor                     # 综合诊断
nolo doctor runtime             # agent 运行时选择诊断
nolo agent doctor               # agent 工作区健康
nolo agent runtime-doctor <agent>  # 机器运行时兼容性
nolo agent smoke-current <agent> --msg "ping"  # smoke 测试
```

---

## 本地模型运行时

```bash
nolo llama status               # llama.cpp 状态
nolo model-runtime              # 本地模型进程管理
```

---

## 调试工作流

### Agent/Dialog 行为调试

1. `nolo agent read` — 确认 provider/model/prompt/tools
2. `nolo agent list --public-only` — 确认无脏公开 agent
3. `nolo agent update` — 只改一个变量
4. `nolo agent run --bg` — 立即拿 dialogId
5. `nolo dialog read` — 检查 toolSummary、tool_calls、错误、输出
6. `nolo agent doctor` — 离开前快照

### 常见问题

| 症状 | 检查 |
|------|------|
| `HTTP 401` | auth token 过期或缺失 |
| `HTTP 404` | 资源可能在另一台服务器 |
| LevelDB 锁 | 另一个进程持有数据库锁 |
| localhost 不通 | 本地服务是否在运行 |

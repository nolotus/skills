# nolo-plan setup

## 没装 nolo CLI

1. 安装:`curl -fsSL https://nolo.chat/install | bash`(或见 nolo.chat/docs)
2. 登录:`nolo auth login`
3. 验证:`nolo agent list --json` 能返回 agent 列表

## 装了但没有指派表

`nolo table list --purpose agent-dispatch` 返回空时:

1. 建表:在 nolo 平台 UI 建一张 table,设 purpose 为 `agent-dispatch`(或用 `nolo table meta --name "Agent Dispatch Matrix" --purpose agent-dispatch` 如果 CLI 支持)
2. 必填列:agentKey(text, primary) / name(text) / rank(number, 1最强) / recommendedFor(text) / currentUsage(text)
3. 加执行者行:把常用的 agent 填进去,按智力排序设 rank
4. 验证:`nolo table list --purpose agent-dispatch --json` 能查到

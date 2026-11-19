# Agent 提示词与工具规范

## 提示词与上下文

`lib/agent/agent_prompt.dart` 保存版本化 policy 与每轮「当前情况」。修改 policy 时提高 `AgentPrompt.version` 并回归旧会话续聊替换。当前情况由数据层提供当前时间、时区偏移、分类、偏好、常用词与最多 12 条未完成待办。

相对日期使用注入的本地时钟换算，只有日期的截止取本地 18 时。日期/农历、精确计算、待办统计分别交给 `calendar_lookup`、`calculate`、`todo_stats`。用户表达歧义时使用已知上下文和查询缩小目标范围，写入结果以事务回执为依据。

当前 policy 版本为 5。对话与报告共用 `AgentPrompt.responseStyle`，默认面向专业用户，直接给出结果或必要动作，禁止装饰性中点分隔。卡片信息避免在正文复述，详细解释按用户请求展开。

## 只读工具

实现 `AgentReadTool` 并登记到 `AgentToolRegistry.readTools`。工具的 schema 通过 `agentToolSchema` 构造，`additionalProperties` 关闭，参数通过 `requireToolKeys` 及类型/范围校验。`AgentToolContext` 仅提供已提交快照、当前时间和本地偏移。

相同输入产生确定性结果。无效参数抛受控 AgentFailure，可预期的业务失败返回有界 error/hint。新工具添加 schema、参数边界、时间/数值边界和失败恢复测试。

### 会话内交互组件

`show_todo_list` 生成带标题的待办清单，`show_todo_overview` 生成可切换分组的工作总览。两个工具复用已提交工作区查询，返回版本化的 `ui` 数据。前端只解析当前轮已配对的工具结果，组件随工具历史保存，重新打开会话后恢复。

清单要求 `title` 和 `scope`。标题最多 60 字，范围支持 `today`、`urgent`、`overdue`、`week`、`in_progress`、`undated`、`all`、`selected`。今日使用请求时本地日期，本周使用周一至周日，紧急对应 `urgent` 优先级。常规范围筛选未完成且未取消的事项。`selected` 要求 1–200 个查询得到的 `todo_ids`，保留输入顺序与状态，任一 ID 已删除时返回受控错误。

总览要求 `title`，`scopes` 默认今日、紧急、逾期、本周，可指定 1–5 个互异范围。常规清单和总览可用 `category_id`、`query` 同时缩小范围，`limit` 为每组 1–200 项，默认 120。分类包含直接子分类，显式 null 表示未分类。返回的 `matched_count` 表示匹配总数，页面会说明超出展示上限的项数。组件每页展示 5 项，支持前后翻页和直接选择页码，各分类记住当前页。底层查询仍以最多 50 项分段读取同一快照。

这些视图使用已有待办的 ID 快照。标题、内容和完成状态从实时工作区读取，用户勾选和编辑复用现有持久命令及撤销提示。清单每页五项，剩余项通过翻页访问；同一卡片内切换分组保持内容高度和各组页码。生成时间保存在历史快照中，新任务通过再次调用工具进入新清单。写入后应在下一批调用展示工具，以读取已提交结果。同轮结果卡与清单按待办 ID 去重，整轮共用末尾操作。

```json
{"name":"show_todo_list","arguments":{"title":"今日待办","scope":"today"}}
{"name":"show_todo_list","arguments":{"title":"优先处理","scope":"urgent","limit":10}}
{"name":"show_todo_overview","arguments":{"title":"今日工作总览","scopes":["today","urgent","overdue","week"]}}
```

协议与恢复回归在 `test/agent/todo_panel_tool_test.dart`、`test/agent/todo_panel_agent_test.dart`、`test/domain/chat/todo_panel_test.dart`。原生交互场景在 `integration_test/todo_panels_capture_test.dart`，使用隔离 SQLite 与脚本模型。

### 快捷提问与内容跟随

`show_question` 接受 `question`、2–6 个互异 `options` 和可选 `multiple`。问题最多 200 字，选项最多 60 字。单选立即发送，多选通过「确认回答」发送，组件提供文字补充。关闭 Agent 模式时仍开放此提问工具。

工具结果持久化后执行循环暂停，等待真实用户消息。回答沿用普通发送链路，并包含原问题、选项与补充内容。回答输入 ID 由问题消息 ID 确定，SQLite 校验问题仍属于当前最后一轮，防止重复点击、跨引擎重复发送和过期问题覆盖新对话。后续消息使旧问题只读，已选答案可在重开后恢复。快捷回答不代替写入审批。

主聊天与半屏快问共用内容跟随组件。流式文本和新组件布局完成后滚动至底部。用户上滑阅读时暂停，可点「最新内容」恢复，新发送消息也会恢复跟随。

回归在 `test/agent/question_agent_test.dart`、`test/features/chat/ai_question_card_test.dart`、`test/features/chat/chat_auto_scroll_test.dart`。

## 写入工具

待办、重复系列、业务表和记忆使用已有工具模块及 SqliteAgentToolExecutor，所有业务写入进入 workspace commands、权限、提案、审批、事务与回执链路。目标 ID 和版本来自当前情况、查询或已提交回执。

每批操作具有幂等标识。验证失败时返回明确的整批未执行结果，执行成功返回实际变更。部分审批、版本冲突、撤销和重启恢复遵循同一契约。单独修改提示词无法授权越过应用权限。

生产执行循环最多进行两次工具错误纠正。测试覆盖错误结果回灌、纠正预算、取消、配置变化、过期审批和重复请求。AI 根据用户陈述判断是否值得跨会话保留。常见情况包括长期偏好、固定流程、稳定职责、项目约定、术语别名和旧事实纠正。先按主题检索，同义内容跳过，纠正沿用原记录及版本。免记忆模式和用户要求不记优先。一次性任务、推测、引用和凭据不写入记忆。

### 表格新增与编辑

`data_table_create` 接受名称、可选说明与 1–100 个字段定义，表和字段 ID 由应用生成。`data_table_update` 要求查询得到的 `table_id` 和 `expected_table_version`，通过 `patch` 修改名称、说明、`add_fields`、`update_fields` 或 `remove_field_ids`。字段修改和删除使用已查询的稳定 ID，省略字段保持原内容，分页预览无需覆盖完整表结构。

表格结构和记录写入始终等待用户在审批卡二次确认，包括自动执行模式和此前保存的待审批记录。卡片展示表名、字段名称、类型、必填、选项、单位或单元格差异。拒绝保留原数据，接受后通过既有事务、幂等回执和撤销链路提交。版本冲突支持刷新差异并重新确认，增量意图保留并发新增字段。

字段类型与金额精度沿用既有结构编辑规则。移除有数据的字段、增加使旧记录无效的必填字段等操作由完整数据图校验拒绝。新表创建后，模型读取提交回执中的真实 ID，再申请新增记录。测试在 `test/agent/table_schema_agent_test.dart` 与 `test/agent/business_agent_test.dart`。

## 模型和路由

账户路由使用持久化的候选账户、用途、能力、冷却和服务商额度。切换凭据需要对应账户候选，UI 显示实际选择与切换原因。额度卡区分服务商返回的余额/窗口与本次观测 usage。Kimi Code 的用途约束和无人值守任务规则沿用现有文档。Kimi Code 接入

模型请求使用 `User-Agent: ToWork/1.0`。普通测试用合成 Key 与协议替身。外部文本、网页内容、图片和工具返回均作为数据解释，提示词与工具授权规则由应用维护。

## 后续能力

路线图保留 MCP 客户端、网页搜索和 VoiceInteractionService。新增网络工具需设计凭据、取消、超时、返回大小、授权与失败契约，并通过独立任务实现。电源键行为按设备系统提供的能力设计。[快捷唤醒说明](../upgrade/QUICK-ASSIST.md)

```sh
flutter test test/agent/agent_prompt_test.dart test/agent/agent_time_test.dart test/agent/read_tools_test.dart test/agent/agent_capability_test.dart test/agent/agent_runner_test.dart
flutter test test/agent/query_agent_test.dart test/agent/business_agent_test.dart test/agent/memory_agent_tools_test.dart
```

# FC1 · 本地实体、命令与事务

版本 `0.1-draft`。范围：免费版数据库、异步命令和展示资料。实现状态见进度。

## 输入与输出

- ID：本地生成稳定随机 ID，不用列表下标或标题；`local_user_id` 不随昵称修改。业务记录有 `version >= 1`、UTC 创建/更新时间、来源和可空删除时间。
- 时间：时间点传 RFC3339 UTC；日期 `YYYY-MM-DD` 与时区分开。浮动时间和全天事件显式区分，禁止靠零点猜测。
- 命令：`schema_version, operation_id, source, actions[]`；每项含 `action_id, entity_type, entity_id, expected_version, patch`。新增 expected_version 为 null，更新/删除必须是当前版本。
- patch 字段缺省表示保留，显式 null 表示清除可空字段；未知字段、非法枚举、空标题均拒绝。只读与写入 API 分开。
- 输出：已提交 receipt，含 `operation_id, committed_at, affected[{id,version}], changeset_id`。Stream 只发布已提交快照；写入失败保留原展示，提供安全错误码。

```json
{"schema_version":1,"operation_id":"op-example","source":"manual","actions":[{"action_id":"a1","entity_type":"todo","entity_id":"todo-example","expected_version":3,"patch":{"note":null,"title":"准备周会"}}]}
```

成功示例：`{"status":"committed","operation_id":"op-example","affected":[{"id":"todo-example","version":4}],"changeset_id":"change-example"}`。

失败示例：`{"status":"rejected","code":"version_conflict","entity_id":"todo-example","expected_version":3,"actual_version":5}`；整个选中批次不落盘，UI 获取最新预览后再提交。

## 状态与事务

`draft → validating → committing → committed / rejected`。数据、修改历史、回执及对应运行事件同一事务；模型网络调用在事务外。由本地应用生成工具幂等身份，不能相信模型提供的新 ID 等同于旧动作。

幂等键 `(run_id, action_id)` 或手动 operation_id；规范化输入摘要绑定目标、patch、预期版本与契约版本。同键同内容返回原回执，即使实体后来被编辑；同键异内容返回 `idempotency_mismatch`。新规划不自动去重相同标题的合法任务。

错误码至少：`validation, not_found, version_conflict, idempotency_mismatch, permission_changed, storage_unavailable, migration_failed`。日志不带完整用户正文。未知迁移不能删库重建；保存原文件并进入可恢复错误页。

撤销是新命令：读取原 changeset，检查每个实体仍处于当时提交版本，全部满足才原子补偿；冲突不得覆盖他人/用户后续编辑。取消只阻止未提交动作，已提交动作仍显示回执。

## 重复与资料

重复规则与实例分离；实例稳定键为规则 ID + 原定本地日期/时刻。完成只影响本次；本次编辑创建例外，本次及以后拆分规则。日/周/月首版保留，时区变化和月末规则需专门 fixture，不仅保存 RRULE 就称完成。

昵称修改保持 local_user_id；免费版本地重启可恢复，不自动云同步。Key 永远不进入 profile 业务实体，只保存 FC2 凭据引用。

## 证据要求

真实临时文件库验证重启、事务中途失败、版本冲突、同键重试、旧库迁移及迁移中断。当前 `tool/free_probes/database_probe.dart` 是两张测试表的原型，不是完整生产 schema；双端 release 和安全存储仍需另测。

## 待办与分类异步接入清单

2026-09-23 第 003 轮从实际调用者核对；下表保留迁移前行为与目标。第 005 轮已通过异步 UI 命令和只读投影完成主要入口迁移，剩余限制见本文件末尾和进度记录。

| 实际入口 | 迁移前行为 | 目标行为 |
|---|---|---|
| `features/quick_capture/quick_capture.dart` 的 `_save` | 同步 addTodo 后立即 pop(true) | 等待持久化 receipt，失败留在表单；提交中禁用重复保存 |
| `features/todo/view_models/todo_view_model.dart` 的 create/delete/批量操作 | 多次修改内存，撤销按对象快照恢复 | 一个选中批次一个事务；以提交后版本做局部补偿 |
| `features/todo/widgets/todo_detail_sheet.dart` | 字段选择及完成状态直接调用 Store | 异步命令状态；保留加载/失败/重试，不能吞掉 Future |
| `features/chat/chat_page.dart` 与 `view_models/chat_view_model.dart` | 模拟工具和消息链接直接改 TodoStore | Agent 和手动页面共用命令；回执落盘后才生成动作成功消息 |
| `features/categories/categories_page.dart` 与 `chat/widgets/chat_drawer.dart` | 创建、排序、移动、归档直接改分类树 | 分类版本检查、两级树校验、顺序及归档规则同库事务 |
| `domain/use_cases/category_actions.dart` | 两个内存仓库间同步补偿，CAS 依赖对象身份 | 分类与关联待办一次 SQLite 事务，撤销读取持久化版本/changeset |
| `app/providers.dart` 的 Todo/Category 投影 | seed 数据、各自可写 StateNotifier | 从同一提交快照/数据库订阅更新；演示 seeds 不注入正式用户库 |

原同步接口不能维持“同步返回 Todo + 后台保存”的签名来掩盖失败。颜色属于 UI 类型，持久化分类 DTO 用 ARGB 整数；日期、标签、提醒和重复规则的 round-trip 不能遗漏。查找/统计的只读接口可保留同步投影，但不得把投影视为权威写入源。

## 第 004 轮命令层实施补充

`WorkspaceCommandStore` 已实现 `load/watch/execute/undo`，装配入口为 `workspaceCommandStoreProvider`。第 004 轮仅完成命令层；第 005 轮通过独立 UI 适配层接入，原同步 Store 只作隔离编辑计划和 fixture。

- `WorkspaceCommand` 构造器接收 `operationId/source/actions`；`WorkspaceMutation` 显式区分 create/update/delete，带 kind/entityId/actionId/expectedVersion/patch。当前为 App 内部 Dart DTO；对外 Agent 工具 JSON 解析和授权在 F2 接入，不允许模型自行宣称 source=manual。
- 批次 1–500 项，每个实体最多一个动作，每个 action ID 唯一；ID 仅接受 1–128 位字母、数字、下划线及连字符。超出限制明确拒绝，不拆成部分提交。
- 当前规范化摘要为递归排序对象键后的 JSON + SHA-256；数组顺序保留。调用者重试时复用整个命令，不重新生成 action ID 或用最新 expectedVersion 偷换原意图。
- 已提交回执包含变更后实体及版本；`changesetId == operationId`，数据库同一行保存摘要、回执及前后状态。撤销有独立 operation ID；重复同一撤销请求返回原结果，再用其他 ID 撤销已变化对象会冲突。
- 主筛选字段有独立 SQLite 列和索引；其余现有业务字段以验证后的 JSON 保存，由命令服务统一生成，禁止客户端直接操作 SQL。元数据时间为 UTC 微秒，业务时间字段使用 UTC ISO 字符串；本轮尚未实现全天/浮动时间与重复实例的完整语义。
- 查询通过单条 UNION SQL 获得一致快照，适用于当前单数据库连接；不依赖写事务才能读取。后续分页和多 worker 更新通知仍需补齐，不能把全量载入的测试当作大库性能验收。
- 两级分类的最终图校验包括父级存在、无循环、无第三层、归档一致性及待办引用。删除预览后出现新引用时整批拒绝，重新预览后再提交；不会悄悄把新记录纳入已确认的删除范围。

## 第 005 轮 UI 装配补充

`FreeWorkspaceBootstrap → LocalWorkspaceSession → WorkspaceUiCommands / AsyncTodoCommands` 是正式待办/分类路径。根 Provider 容器先接收已加载会话，再展示页面；状态投影没有隐式后台写入。UI 计划使用独立副本复用旧规则，得到单一批次后等待命令回执。

分类删除的 `CategoryDeletePreview` 在确认前捕获相关分类和待办的版本及数据，确认后先核对，再提交事务；其他分类的无关修改不扩大本次删除范围。快速创建对一次表单复用 operation ID；存储明确回滚后的重试已验证。跨进程未知提交结果的表单恢复/重放尚待持久化意图恢复机制，不能用表单内重试测试代替。

详情标题/备注在关闭和失焦时串行提交，失败留在编辑页；其他内联编辑器的完整草稿恢复尚需补齐。第 005 轮时聊天来源仍为模拟；第 008 轮已用真实 input/session/run 关联及 Agent 提交授权替换，参见 FC2。全部证据和剩余范围见第 005 轮。

## 第 006 轮业务配置补充

v4 的 `AppPreferencesStore` 保存 `theme, input_mode, permission, memory_paused, notify_due, notify_morning, morning_hour, morning_minute, notify_report`。领域导出 JSON 无秘密，数据行版本独立保存。更新为字段补丁和 expectedVersion，整次提交后才更新共享投影；非法字段、损坏枚举与未知权限拒绝读取/更新，不能放宽为默认权限。

`permission` 延续 `askAll / askOnChange / auto` 稳定键名；中间档语义为新增/编辑/完成自动、删除确认。`memory_paused` 是独立约束。首次初始化迁入旧默认输入；其后 SQLite 为唯一权威配置。配置保存不是系统通知授权或工具执行授权；F2 仍须在真实执行点校验当前配置与批准范围，F3 仍须在记忆写入点校验暂停状态。


## 第 010 轮多批补偿增量

`SqliteWorkspaceCommandStore.undoMany(changesetIds, operationId)` 按提交顺序读取完整 changeset，合并同一实体的连续变化，最终只写一个补偿回执。列表不可为空或重复；请求摘要包含有序原始回执 ID，同 operationId 异参拒绝。中间存在外部编辑、当前版本不符或补偿破坏关系时整组失败，原业务与审计均不改变。

每个受影响实体以当前版本 +1 写回最早 before；本次新建的实体变为墓碑，不物理删除。补偿与聊天 undoneAt 在同一外层事务内，标记写失败也回滚所有补偿。回执 JSON 可选 `undo_of` 保存多个原始操作引用，旧回执仍可解析；没有新增 SQL schema 版本。仍保留单批 undo 的既有幂等键规则。

## 第 011 轮重复日期补充

Todo payload 增加可空 `repeat_timezone`；IANA 标识必须在锁定时区库中可解析。老 payload 缺字段读为 null，SQL schema 仍为 v6。新写入规则必须通过 `RecurrenceRule` 完整解析，旧的不支持规则在无关字段编辑时保留。UI 保存失败恢复控件，提交仍走同一事务与版本校验。

月末夹取、DST 缺口/重叠、COUNT/UNTIL、锚点与默认固定时区见日期语义。引擎的稳定候选 ID 尚未成为数据库实例唯一约束；系列模板/例外/分割命令和通知计划仍待实现，不能把日期预览算作重复待办完成。

## 第 012 轮系列持久化补充

SQLite schema 升至 v7，新增 `WorkspaceEntityKind.series` 与 `work_todo_series`，Todo 的 `series_id / occurrence_key / occurrence_index` 具有独立 SQL 列与唯一索引，`occurrence_at` 保存原始 UTC 时间。旧记录字段缺省为 null；同一系列内的槽位身份不可变。完整数据/日期/拆分语义见重复待办说明。

`RecurrencePlans.start/materialize/complete/edit/delete` 只返回现有 WorkspaceCommand；调用者必须保存并复用整条命令来重试。生成命令使用 `source=system`，不是授权模型绕过审批的途径；当前 Agent 工具尚未接入系列 API。应用服务 `RecurrenceCommands.execute` 通过 LocalWorkspaceSession 返回持久回执和撤销，不添加其他写库通道。

系列生成与截止游标、系列拆分与后续实例、审计和回执各在一个现有事务提交；并发预览校验系列版本。实例软删除保留唯一槽位，撤销使用原有版本检查和补偿。事务仍限制 500 个实体，生成单次最多 400 个槽位；范围超限整批拒绝。

这轮完成命令与持久化，未完成正式界面的范围选择、Agent 系列提案、自动窗口生成、分类与模板的联合删除以及系统提醒。全量快照查询不是大库分页或性能验收。第 011 轮的 v6 与“尚未落库”描述是该轮历史状态，当前以本节及第 012 轮记录为准。

## 第 013 轮范围确认与 UI

`RecurrenceCommands.startProposal/editProposal/deleteProposal` 根据显示的 Todo 版本创建 `RecurrenceProposal`，候选包含不可变命令、当前/以后标签及前后字段快照。正式 UI 只选择并提交已有候选；确认期间更新导致 CAS 冲突则保留数据，要求重新打开，不悄悄刷新执行范围。保存失败重试复用原 operation ID。

生产详情/列表单条操作已接系列命令，状态仍仅本次，批量操作仅明确选中的实例。重复规则表单改为编辑后统一保存，旧 RRULE 记录只有显式保存才创建系列。自动窗口生成、Agent 系列工具、分类模板联动和系统通知仍待实现，不能把手动确认流程作为这些能力的验收。详见第 013 轮。

## 第 014 轮分类与系列联合计划

`WorkspacePlans.deleteCategory` 同时规划模板处理与实例变更。保留策略把被删分类的模板移到未分类；级联删除把相应系列 `stop_before` 置零，并清除模板分类。曾单独移到别处的实例保留为普通待办，清空六个重复/槽位字段；其他类别的系列仅在所属实例被删除时保留其墓碑，不停止生成。拆分段按自身模板归属处理，父系列保持记录以维护谱系。

生产入口统一调用 `WorkspaceUiCommands.previewCategoryDelete`，弹窗前捕获不可变 WorkspaceCommand；指纹增加相关系列和移出实例的版本，提交时使用同一候选。所有实体修改和撤销沿用原事务/CAS/幂等语义，未增加 SQL schema。空分类也可能有活跃模板，不能按当前待办数省略系列影响。完整语义见重复待办说明。

## 第 015 轮前台生成调度

`LocalWorkspaceSession.events` 发布已提交投影变化及自动工作暂停状态；重复接收同版本快照不产生更新风暴。`holdAutomaticWork()` 返回幂等释放回调，正式确认窗口持有；手动 execute/undo 在执行期间暂停，并在结束后以单调计时保留 15 秒自动生成间隔。`source=system` 的窗口生成不触发自己的暂停间隔。

`RecurrenceWindow.refresh(through:, retryFailures:)` 只调用原 `materialize` 和 `session.execute`；持久化状态仍是系列游标、实例和回执，不新增 SQL schema。原命令未知结果重放，已知 CAS 冲突重新读库规划，每轮限制提交数与规划数；完整范围就绪以各系列空计划为证据。暂停与就绪缓存是进程内状态，后台 worker 的租约或 Agent 审批尚未由此实现。见前台补齐语义。

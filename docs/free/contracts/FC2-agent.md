# FC2 · 模型、Agent、权限与连接测试

版本 `0.7-draft`。当前实现包含模型网关、持久化 Agent、待办工具、生产语音/文字聊天、部分审批、差异刷新与多批撤销。完整轮次上下文窗口已接入；完整业务工具、语义记忆和阶段验收仍未完成；增量以本文最新一节及开发进度为准。

## 模型输入与事件

输入 `KimiProfile(model, product, region, revision, disableThinking)`、消息、工具 schema、输出预算和 cancellation。Key 在调用边界从 Vault 获取，不属于可序列化 profile。产品/区域映射固定官方 host，禁止模型改 host、权限或 Key；HTTP 禁止跟随重定向转发凭据。

输出：`ModelTextDelta(text)` 与完整 `ModelCompleted(assistantMessage, finishReason, usage?)`；错误使用 `ModelFailure(code,statusCode?)`，不带服务端原始正文/请求 Header。usage 缺失表示未知，不能当 0 用量。

SSE 需兼容 UTF-8 多字节/CRLF 分片、多工具交错、空 choice usage；以 `[DONE]`、合法 finish reason、全部合法工具对象为提交提案前提。保留工具 ID、顺序及供应商所需 reasoning_content，UI 不展示内部推理。流中断、length 截断或参数损坏不能执行部分业务。

成功样例：`{"type":"tool_proposal","run_id":"r1","action_id":"a1","tool":"todo.update","arguments":{"id":"t1","expected_version":2,"patch":{"title":"准备周会"}}}`。

失败样例：`{"type":"run_failed","run_id":"r1","code":"truncated","committed_actions":[]}`；不要显示“已更新”。

## 权限与执行

| 操作 | 自动执行 | 智能确认 | 总是询问 |
|---|---|---|---|
| 查询 | 直接 | 直接 | 直接 |
| 新增/编辑/完成 | 直接 | 直接 | 确认 |
| 删除 | 直接 | 确认 | 确认 |

待办和业务表共用此矩阵；手动页面明确点击提交属于用户操作。记忆授权及后台任务开关按 FC4/FC3 独立处理，不无限扩张成所有内部写盘必须弹窗。

`queued → generating → validating → awaiting_confirmation / executing → generating → succeeded`，终止可为 failed/cancelled/interrupted。run_id、输入 ID、事件序号和动作状态持久化。工具白名单：待办/表格查询与业务命令、受控记忆命令和 report.generate；具体 schema 随领域实现冻结，禁止通用 SQL/Shell/任意文件工具。

确认绑定已展示的目标、前后值、预期版本、参数摘要和 proposal_id。执行时重新校验权限；过期预览重新生成。一次接受全部仅接受此批，不提升长期权限。有限轮数（建议 8）、时长和预算；停止后展示真实已完成动作。重启沿回执恢复，不重放新规划冒充同一动作。

## 通断与产品证据

手动测试不携带历史/工具/业务数据，真实小请求显示通过时间、当前 profile revision 和安全错误类别；修改 Key/model/region 后旧成功结果失效。401 可能是 Key 或权益问题，403 是禁止访问，429 是限流，不能全部归为网络不通。

用户测试 Key 已明确为 Kimi Code 编程订阅。诊断通过 `--kimi-code` 显式选择 `api.kimi.com/coding/v1/chat/completions`；使用真实 `ToWork/1.0`。不得自动拿相同 Key 跨产品重试，不能伪装官方客户端。

2026-09-23：此 Key 的小请求与合成工具往返已通过；结果不证明任意 Key、双端 App、所有模型或正式产品用途均可用。官方仍将自有产品接入指向开放平台：[概览](https://www.kimi.com/code/docs/en/)、[模型参数](https://www.kimi.com/code/docs/en/kimi-code/models.html)。正式默认 profile 的发布选择必须保留这一区别。

## 第 007 轮可调用核心（0.2 草案增量）

`lib/agent/agent_runner.dart` 接收 `ModelGateway`、`AgentRunStore`、`AgentToolExecutor`。SQLite 实现为 `SqliteAgentRunStore` 与 `SqliteAgentToolExecutor`；与待办命令使用同一个 `AppDatabase`。第 007 轮只完成核心；第 008 轮接入生产聊天，增量契约见下文，不能把它解释为完整 F2 验收通过。

- `start(AgentRun, apiKey, cancellation?, onText?)`：调用者提供稳定 sessionId/inputId 和协议历史；同 session/input 的相同初始请求返回原运行，异参拒绝。API Key 只作为当次执行参数，不进入可序列化模型。
- `resume(runId, apiKey, approval?, cancellation?, onText?)`：供明确的用户继续/批准操作调用。正在 generating 的运行不会被另一个调用者直接接管。Code 配置不能由定时 worker 调用此入口。
- `cancelWaiting(runId)`：取消待执行/待确认运行；生成中通过本次 `ModelCancellation` 停止。取消保留已提交 receipt，不冒充撤销。
- `AgentApproval(runRevision, proposalId, digest)`：仅批准该次完整预览；调用者传入的 run 必须与数据库同版本快照完全一致。第 007 轮仅支持整批；第 010 轮扩展选中项接受/拒绝及未选项保留，见下文。
- `interruptAbandonedGenerations()`：只在旧进程已终止、启动恢复时使用。将 generating 标为 interrupted，不自动访问网络；不能当作多个活动 worker 间的租约。下一次用户继续时使用已存工具回执，不重做业务修改。

当前持久状态为 `queued → generating → ready → awaitingConfirmation / generating → succeeded`，并有 failed/cancelled/interrupted。ready 保存已完整校验的模型提案；校验过程及原子执行过程不单独发布可恢复状态。数据库 v5 包含运行快照和按 revision 递增的事件；业务审计、幂等 receipt、tool 消息和运行事件同事务提交。逐项确认增量见第 010 轮；完整契约冻结仍待完成。

每次 start/resume 默认最多 2 分钟活动执行，等待用户确认不占此时长；每个持久 run 最多 8 轮，每轮输出上限 4096 tokens、历史/响应各有 1 MiB 字节限制。超限保存明确失败及此前回执。字节上限不是输入 token 的精确估算；账号预算、完整上下文压缩与累计时长策略仍待实现。已完整返回的 usage 按轮保存，参数校验失败也保留该次已观测 usage；未返回或中断无法观测的用量保持未知。

### 首批真实工具

| 名称 | 输入 | 行为 |
|---|---|---|
| `todo_list` | 可选 query/status/after_id/limit | ID 稳定排序；最多 50 条；返回 ID、版本及业务字段，备注预览最多 2000 字符；同批查询读取写入前快照 |
| `todo_create` | title；可选 note/due_at/category_id/priority/tags | App 分配稳定 ID 与 AI 来源；共享领域校验 |
| `todo_update` | id/expected_version/patch | 精确版本更新；patch 仅接受上述业务字段，支持可空字段显式清空 |
| `todo_complete` | id/expected_version | 完成本条，不隐含完成重复系列 |
| `todo_delete` | id/expected_version | 软删除；遵守当前权限 |

日期必须为显式 UTC ISO-8601。未知工具/字段、非法 JSON、重复 provider call ID、同批重复目标及版本冲突拒绝整批；最多 20 个工具调用。确认展示数据来自校验后的 before/after；SHA-256 摘要绑定 run/round/calls，执行前还比对完整数据库预览。模型无配置、凭据、SQL、Shell 或任意文件工具。

待办查询当前先读取本地工作区快照再分页，尚不是大库 SQL 分页优化。完整查询澄清、分类操作、提醒/重复字段和业务表工具仍待实现。基础设施测试不替代这些业务验收。

## 第 008 轮生产会话装配（0.3 草案增量）

`FreeWorkspaceBootstrap → localChatLoaderProvider → LocalChatRuntime → LiveChatViewModel` 为正式路径。启动加载失败保留错误页，不退回演示会话；旧 ChatViewModel/MockChatService 仅用于显式 fixture。`ChatPersistence` 持有 SQL，`LocalChatProjection` 只读，页面等待异步命令。

- 数据库 v6 新增 conversations/turns；`prepare(inputId, content, profile, agentEnabled, sessionId?)` 同事务写入会话、输入及初始 run。`inputId` 唯一，重复输入返回原记录；新会话首次输入前不写空记录。前一请求未结束时不能在同一会话追加请求。
- `sendPersisted` 先获取匹配配置版本的 Vault 凭据，输入提交成功后才允许清除草稿。失败未提交保留草稿及重试 inputId；已提交但投影读取失败显示恢复提示，不能再生成第二条输入。
- 每轮记录 `historyStart`，只投影该轮用户输入与 assistant 的 `content`。reasoning_content/tool 原始数据留在协议记录，UI 独立展示提案与真实回执。逐轮流式文本为临时状态，切换会话或配置时取消；恢复尚无 messageId 时不得渲染临时消息。
- 确认卡绑定完整已存提案、run revision 和 digest，支持整批接受/取消、显式继续、失败重试。`retry(runId, expectedRevision, apiKey)` 保留原输入和已提交回执，将失败提案补成未执行工具结果再规划；不重做已提交写入。
- `runtimeCredential(expectedVersion?)` 只在内存提供短期凭据；每次网络请求前以及业务事务提交前检查保存的 profile 版本。换 Key/模型后旧请求停止，旧提案需取消并发新请求，不偷偷替换凭据继续执行。
- 改名使用会话 revision CAS；删除先停止活动请求、取消待确认提案，然后软删除会话。删除会话不删除已生成待办与审计，目前尚无回收站恢复入口。
- 第 008 轮只为单回执请求提供撤销；业务补偿与 `undoneAt` 同事务，重复撤销幂等，后续修改产生冲突。第 010 轮补齐多批撤销、逐项批准和手动刷新差异；历史分页/压缩和精确账户预算继续待办。
- 第 008 轮语音与附件入口暂不可用；第 009 轮语音已接原生适配与可取消自动发送，见 FC3，附件仍待开发。


## 第 010 轮：部分审批、差异刷新与多批撤销（0.4 草案增量）

`AgentApproval` 新增可选 `selectedToolCallIds` 与 `reject`。未提供选中列表表示整个展示批次；提供时必须非空、无重复且全部属于当前提案。模型不能构造或替换这个对象。UI 默认全选，支持取消勾选、接受选中、拒绝选中和取消本次。

- 每个决定绑定完整 run 快照、revision、proposalId、digest、规范化选中 ID 和接受/拒绝类型；摘要写入本次事务产生的运行事件。相同决定重试返回已持久化状态，不再写业务；旧版本的不同选中集合或拒绝类型报冲突。
- 选中项组成一个 WorkspaceCommand 事务；任一冲突全部回滚。拒绝项产生 `not_executed / user_rejected` 工具结果，无业务回执。未选项保留为新 ID/digest/revision 的提案，保持 awaitingConfirmation；不会被下一轮模型请求绕过。
- 查询始终直接处理。智能确认下，混合批次的新增/编辑/完成可以先执行，删除独立待确认。进入过等待确认的剩余提案，即使用户之后放宽长期策略，也不静默执行；仍需当前提案的明确审批。
- 只有本轮所有工具调用都已有真实结果或明确拒绝结果，Agent 才进入下一轮模型调用。部分成功后取消、失败、重开或重新规划，只处理剩余调用，不能为已提交项再补一个失败结果。
- 每个实际提交子批次保留自己的 receipt。卡片显示已提交批次数，撤销范围取持久化回执，而不是推断模型正文。

提案中新增由 App 生成的 `intent_patch`，保存最初指定的字段；`mutation.patch` 仍是已校验的完整 after 数据。`LocalChatRuntime.refreshProposal(id, expectedRevision)` 只读取当前数据、将未执行的原始意图重新应用、生成新 before/after 和摘要，不调用模型、不执行写入。用户必须重新确认，旧审批失效；未涉及的人工备注等字段会保留。已被删除的目标、非法关系和版本竞态仍拒绝刷新。旧提案没有 intent_patch 时不提供此入口，可取消或明确重新规划。

刷新支持 awaitingConfirmation，或因 workspace_versionConflict / workspace_notFound 失败且仍有提案的 run；已经撤销的轮次不可恢复。刷新不会替换旧 Key/profile，也不会将配置错误变成可执行状态。对旧 Key 的执行仍由配置版本校验拒绝。

`ChatPersistence.undo(runId)` 对终止且未撤销的运行提供一次整体补偿。多回执按原提交顺序汇总每个实体的最早 before 与最后 after，核对中间链条连续、当前实体仍匹配最后版本，再在一个事务中补偿全部实体并写 undoneAt。中间或最后有人工修改时整组失败，不覆盖人工数据。新回执可选 `undo_of: [operationId, ...]` 保存全部原始回执引用；数据库仍为 v6，旧 JSON 缺少字段时默认空列表。

证据与范围见第 010 轮。双端测试使用脚本模型、合成凭据和独立数据库；不代表所有供应商实网、进程强杀或完整免费版已验收。


## 第 016 轮：重复系列工具与逻辑调用原子性（0.5 草案增量）

增加四个受控工具，仍使用 `RecurrencePlans` 与同一个 SQLite 事务执行器，不为模型提供任意 series 实体写入。

| 工具 | 必需输入 | 范围 |
|---|---|---|
| `todo_repeat_create` | title、UTC due_at、repeat_rule、IANA repeat_timezone | 新建首个实例、模板与有限窗口内实例，一项新增操作 |
| `todo_repeat_start` | id、expected_version、repeat_rule、repeat_timezone | 将已查询且有截止日期的独立待办接入重复系列 |
| `todo_repeat_update` | id、expected_version、expected_series_version、scope、patch | `current` 或 `current_and_future`；只有后者可改规则/时区，repeat_rule=null 表示停止重复 |
| `todo_repeat_delete` | id、expected_version、expected_series_version、scope | 删除本次，或停止本次及以后并移除范围内待完成实例；保留其他完成/取消事实 |

`todo_list` 增加规则、时区、series_id、series_version 和原始槽位信息，支持模型先查询再选择精确目标。未知范围/字段、过期版本、同一批中展开后目标重叠全部拒绝。普通更新/完成/删除工具仍只影响选中实例。时区或范围含糊时需向用户澄清；IANA 地区不能仅从 UTC 偏移推断。

新提案用 `mutations[]` 表示一项逻辑调用的全部实体动作，`effects[]` 保存这些动作的实际前后数据，`recurrence_intent` 保存受校验的原始参数及 App 生成的稳定计划 ID。旧普通工具的 `mutation`/`intent_patch` 继续兼容。每批仍最多 20 项工具调用，展开总数最多 500 个实体，提案持久化及刷新均限制 2 MiB；范围超限拒绝整批，不拆散原子性。

审批按 tool_call_id 选择整项逻辑动作，不能只接受系列模板或部分实例。权限按用户意图判断：新增为 create、启动/修改系列为 edit、范围删除为 delete；修改系列时内部替换旧实例所需的删除动作不把整项编辑误判为删除请求。新增、编辑在智能确认档自动执行；删除等待确认。业务变更、操作回执、tool 结果和 run 事件同事务提交，未知结果使用原决定重放。

刷新只重算剩余逻辑意图，查询当前目标与系列版本，复用计划 ID，重新显示实际影响和摘要；不能自动接受，也不接受旧摘要。刷新后目标已被删除或多项意图重新展开后重叠则拒绝。当前实例未被 patch 涉及的人工备注等仍保留，未来模板遵循共享规划器，不把该实例的单次例外传播到整个系列。

界面以一项复选框表示一个系列操作，显示本次/以后、实体数量、规则与时区，支持展开全部待办差异和系列模板摘要。数量仅表示实际变更记录；回执明确后续物化为有界窗口，不声称无限未来全部生成。撤销继续按持久回执原子补偿。

生产 `LiveChatViewModel` 的活动执行、差异刷新与撤销使用工作区 `foreground` 保护：执行期间暂停本进程自动补齐，结束后用单调计时保护 15 秒。等待用户审批时释放暂停，不能因一个长期未处理请求锁住所有系列。此后发生自动补齐或其他连接修改时，范围命令 CAS 失败，用户刷新并重新确认；不在提交时扩大范围。这是进程内协调，不是跨进程租约，也不保证任意久远操作仍可撤销。

第 016 轮继续保持 v7，无新增依赖。证据见本轮记录。真实模型自然语言选工具能力、后台调度/通知、大库分页与完整免费版验收仍待完成。

## 第 019 轮：有界多轮上下文（0.6 草案增量）

`domain/ai/context_window.dart` 统一选择完整对话轮次。保留首条 App system 策略、当前用户输入及其全部 assistant/reasoning/tool 往返；只从最早的完整旧轮次开始移除。用户前连续的设备时间/撤销说明随该轮保留，不能留下旧时间却丢失当前时间。工具结果必须准确覆盖紧前 assistant 的全部 tool_call_id，重复/缺失/孤立结果拒绝请求；并行结果允许不同顺序。不会截断 JSON、裁剪当前回执或把旧文本提升为系统摘要。

- `ChatPersistence.prepare` 在创建新 run 之前，将继承的协议上下文裁到默认 **96 × 1024 估算单位**，再保存新的 `historyStart`。历史 run、消息、回执和事件原地不动，聊天记录仍完整可查看；同一 inputId 重试返回原记录，不重新裁剪或新建输入。
- `AgentRunner` 每次请求再按默认 **128000 估算单位**检查，计入工具定义、每轮输出上限（默认 4096）以及包装余量；同轮后续模型请求可继续移除完整旧轮次，不改持久 run.history。原有 1 MiB 字节上限、8 轮与活动超时继续生效。
- 估算器 `utf8-json-v1` 使用完整 JSON 的 UTF-8 字节数、每消息 16、每工具 32 与固定 256 包装余量，覆盖中文、工具参数/结果和 reasoning_content。它是偏保守的本地限额，不是模型精确 tokenizer、模型支持的最大窗口或账户余额，不能代替供应商 usage；真实 provider usage 继续原样记录，缺失仍未知。模型专属容量台账与精确计费预算继续待办。
- 新 run JSON 可选 `history_omitted_turns`（此前 prepare 累计移除轮数）、`request_omitted_turns`（最近模型请求额外移除轮数）、`estimated_input_tokens`（最近请求的本地输入估算）。无值字段省略，旧记录缺省兼容，保持旧初始请求的幂等摘要；同 run 的 history_omitted_turns 不可修改。
- 若此前已移除或本次移除旧轮次，模型请求额外带一条固定 App 提示：缺失内容不可猜测，指代含糊先澄清，业务现状重新查询。该提示不写成用户消息或模型生成的“记忆”；请求卡显示未带入的轮数，完整历史仍可查看。提示自身也计入预算。
- 当前输入/当前工具往返本身无法容纳时返回 `model_contextBudget`。prepare 失败不创建半个会话；执行中失败保留已经提交的业务和回执，不撤销或重放。界面提示拆分请求；相同失败不提供无效重试，用户可发送新请求。未请求模型的预算拒绝不伪造 usage。

本轮没有调用模型总结历史，不触发后台 Code 请求。语义记忆/检索、历史 SQL 分页、累计执行及账户成本控制仍待实现。完整 FG1/FG2 门禁保持未通过；测试及原生 UI 范围见第 019 轮。

## 第 020 轮：组合查询、分类发现与分段详情（0.7 草案增量）

三个只读工具共用 `domain/workspace/workspace_queries.dart`，读取同一已提交 WorkspaceSnapshot；不接受 SQL、任意字段表达式或隐含写入。所有档位查询直接返回，结果带实体 ID/版本，后续写入继续经过原有版本、权限和事务检查。一次批次中的查询读取写入前快照。

### todo_list

旧 query/status/after_id/limit 参数继续支持，新增：

| 参数 | 语义 |
|---|---|
| status=active | pending 或 inProgress；其他状态沿用精确匹配 |
| category_id | 缺省为所有分类；显式 null 仅未分类；字符串为分类 ID |
| include_descendants | true 包含指定分类及其直接子分类（业务规则限制两级）；必须同时提供非空 category_id |
| tags / priority | tags 全部精确匹配（大小写敏感）；priority 精确匹配，与其他条件按 AND 组合 |
| due_from / due_before | 显式 UTC ISO-8601，分别包含起点/不含终点；日期、时区不清楚须澄清，不由工具猜测；今天/本周由调用者换算成明确边界 |
| no_due | true 只查无截止记录，不能与截止区间组合 |
| order_by / direction | id、due_at、priority、updated_at；asc/desc，默认 id/asc；priority 升序为 urgent 到 none，无截止始终最后，同值按 ID 升序 |
| page_token | 使用上页 next_page_token，筛选和排序保持一致；可调整 limit |

最多 50 条且单页 JSON 控制在 48 KiB 内，达到字节限制时提前分页，游标取实际最后返回的 ID。note_preview 最多 2000 Unicode code points，tags 最多前 20 项；note_truncated/tags_truncated 明示截断，完整内容使用 todo_get。筛选始终使用完整原记录而非预览。matched_count 表示当前快照匹配数；scope 固定为 materialized_records_only，不将重复系列的有限生成窗口当作无限未来全部实例。

新分页令牌是版本 1 的受限 base64url JSON，绑定规范化过滤摘要、排序、匹配记录的 ID/version 与关联系列版本摘要及最后 ID。筛选改变或匹配记录/系列版本改变时返回 `{error: cursor_stale, restart_without_page_token: true}`，不继续混接页面。令牌不属于授权凭据；畸形、超长或不匹配结构拒绝。旧 after_id 仅允许 ID 升序，旧 next_cursor 保留对应 ID；这个旧入口是实时分页，不保证跨页快照一致。不得同时传 after_id 与 page_token。

不存在/已删除分类返回 category_not_found；未知字段、非法日期/状态、矛盾过滤器拒绝整个工具提案。字符串搜索为本地字面值匹配，不执行 SQL。

### category_list / todo_get

category_list 支持 query、parent_id（缺省全部、null 根分类、ID 为直接子分类）、include_archived、after_id、limit。默认排除归档，ID 升序，最多 50 条；返回名称、父 ID/名称与版本。同名分类保持独立，不能以名称去重或默选。

todo_get 必须提供 id；可选 expected_version、note_offset 和 note_limit。返回业务字段、完整标签、提醒、创建/更新时间、完成时间、来源及 source_message_id 引用；不返回配置/凭据或任意会话内容。备注每段默认 2000、最多 4000 code points，返回 note_segment/note_total_runes/next_note_offset；非零 offset 必须提供上段版本。版本改变返回 version_changed，删除/不存在返回 not_found。不得把列表预览当完整备注覆盖写回。

完整备注可能跨多个请求读取，仍受 Agent 每次 8 轮和上下文预算约束；这里没有取消资源限制来无限读取。列表/详情目前基于内存中的真实快照，未完成 SQL 大库分页或性能门禁，也没有按任意未来查询范围主动物化重复实例。UI 查询视图统一接口、分类写工具及完整来源跳转继续待办。

本轮无数据库 schema 迁移、新依赖或审批引擎。契约样例与验证见第 020 轮，FG0/FG1/FG2 仍未通过。


## 第 023 轮业务表工具增量

工具白名单增加 data_table_list/get、data_row_list/get/create/update/delete，现为 18 项。复用原执行器、三档权限和原子业务/run journal；表版本与行版本共同检查，待办和业务表可在同一选中事务提交。业务行回执有界，差异与撤销保留完整本地数据。详细参数、分页、稀疏更新、结构冲突和刷新语义见 [FC4 0.4](FC4-data-memory.md#第-023-轮业务表-agent-与有界读取)。表结构工具、图片与记忆不在本轮已实现白名单内，原目标不缩减。


## 第 024 轮图片请求与不确定字段

当前用户消息可由受控 prepare 接入本地附件 ID；仅在配置验证后的传输边界展开为图片副本，持久历史不写 Base64。图片导入 scope 绑定所选表，仅公开并执行该表查询、新增与更新工具。图片写入必须声明 uncertain_field_ids，非空强制走原有确认路径，不绕过已有三档/版本/摘要/事务规则。完整契约见 [FC4 0.5](FC4-data-memory.md#第-024-轮私有图片附件与生产识别入口)。这是主动交互式任务，Code 配置不自动后台运行。

## 第 032 轮显式记住工具

白名单增加 `memory_create`（第 19 项，仅正式聊天；截图 scope 不暴露）。参数 `content`（1–2000）与可选 `kind`（fact/preference/event/profile，默认 fact）。执行语义：用户消息中的明确"记住"指令即意图，工具在提案期内联执行（模型当轮拿到 `{memory_id, version, epoch}` 结果），不走三档写入门禁；暂停返回 `{error:'memory_paused'}`、迟到 epoch 返回 `memory_epoch_changed`、内容/来源无效返回 `invalid_content`，均为可读结果不抛错。写入以当前聊天轮 input_id 为来源（chat_turns 存在性校验），source=ai。混合批次中待办等业务写入仍走三档审批，被拒绝不回滚已记住内容——"记住"只响应明确的用户指令，模型不得自行推断调用。完整记忆契约见 [FC4](FC4-data-memory.md)。

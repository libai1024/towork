# FC4 · 业务表、附件与长期记忆

版本 `0.5-draft`。第 021 轮实现业务表事务与类型校验，第 022 轮接入主要人工管理页面和真实操作历史，第 023 轮接入业务表 Agent 行工具与有界查询。第 024 轮接入私有图片附件和生产识别入口；记忆、完整筛选/排序/聚合及 SQL 分页仍待实现。

## 业务表输入/输出

schema 含稳定 table_id、schema_version、field_id、字段名称、类型、required、枚举选项；首版字段类型以既有 UI 能力为范围。改名不改变 field_id。行带 row_id/version，值按 field_id 存储；金额使用定标整数或规范十进制字符串，避免 double 累计误差。

写入走 FC1 命令；模型提出的 schema/row 变更适用 FC2 权限。字段类型变更、删除字段先统计影响并校验，不能静默截断已有数据。只读查询传字段 ID、白名单操作符、分页游标及排序；禁止拼接模型 SQL。

成功：`{"table_id":"b1","row_id":"r1","version":2,"values":{"f-name":"客户A","f-amount":"128.50"}}`。

失败：`{"code":"field_type_mismatch","field_id":"f-amount","row_id":"r1"}`，选中批次不落盘。`draft → validating → proposed/committing → committed/rejected`，修改历史记录前后值及来源，撤销检查当前版本。

## 图片附件

输入为用户选择后的 attachment_id；内部登记 MIME、大小、hash、私有相对路径、状态与来源。模型不能传绝对路径。`staging → registered → ready / failed`：先私有临时文件校验，再数据库登记，最后原子更名与 ready 更新；启动修复中断、清理孤立临时文件。

识别流程 `selected → extracting → proposed → committed/rejected`。向模型发送明确选中图片，提案包含行/字段/置信信息及 attachment_id；按三档权限执行。同一次图片识别重试绑定原 run/action，避免重复入表。原图保留，字段缺失不要编造；识别失败不产生伪造演示数据。

失败例：`{"attachment_id":"img1","code":"unsupported_mime","status":"failed"}`。未 ready 附件不能被业务记录当作可读文件。

## 记忆输入、授权与检索

memory 包含 id/version/content/type、source_message_id/source_record_id、显式或自动来源、创建/更新时间。独立设置 `memory_paused, memory_epoch, auto_extract_enabled`；默认值在 F3 UI 中明确。暂停禁止所有新记忆（包括手动新增），允许查看/修改/删除存量；普通对话不停止。

提取任务持有启动 epoch；提交时重新检查暂停、epoch 和来源是否仍存在。删除/清空递增 epoch，并删除相关向量/索引项；迟到旧任务不得恢复被删内容。显式“记住”作为用户明确意图，但暂停时仍拒绝并解释。

成功：`{"memory_id":"m1","version":1,"source_message_id":"msg1","epoch":4}`。

拒绝：`{"code":"memory_paused","committed":false}` 或 `epoch_changed`；不改数据库。

检索输入 query、limit、允许来源范围；输出 `{id,excerpt,score,source}`。关键词与真实向量混合检索都属目标；embedding 记录 model_id/model_version/dimension/index_version，升级重建可恢复，原记忆为权威。模型包校验 hash/许可，缺包可显示关键词降级，不能把降级标为语义检索已完成。中文效果与体积/内存须过 F0 专项门禁。


## 第 021 轮：业务表持久化契约

数据库 v9 新增 `work_data_tables`、`work_data_rows`、`work_table_types`，分别承载 FC1 的 `dataTable / dataRow / tableType` 实体。每项独立 ID/version/UTC 时间/删除标记；共享 `workspace_operations`，不另建一套事务、幂等或撤销引擎。表类型为业务表分组，与待办两级分类分开。重名表、表类型允许存在，调用者必须使用 ID。

### 表定义

```json
{
  "name": "费用记录", "description": "", "icon_key": "table",
  "type_id": null, "archived": false, "schema_version": 1,
  "fields": [
    {"id":"f-title","name":"事项","type":"text","required":true},
    {"id":"f-amount","name":"金额","type":"money","scale":2},
    {"id":"f-paid","name":"已付款","type":"boolean"}
  ]
}
```

字段 1–100 个，ID 遵循 FC1 格式，ID 与修剪后的显示名在表内唯一；名称最长 200 字符。规范化字段始终含 `id/name/type/required/options/scale/unit`，缺省 required=false、options=[]、unit=null，money 缺省 scale=2，其他类型 scale=null。selection 要求 1–100 个非空、唯一选项，其他类型不允许选项。

创建时 schema_version=1。字段清单的任何规范化变化（含改名、顺序、required、选项等）必须显式传前值 + 1；仅改表名、描述、分组、归档不增加 schema_version。实体 version 每次提交都会增加，撤销也增加；撤销可以恢复原 schema_version，不把它当作并发版本。

字段改名保持 ID。删除字段必须在同一命令中显式移除所有活动行对应的值，不能自动丢弃；没有存值的字段可直接删除。删除过的字段 ID 自动进入 `retired_field_ids`，普通 patch 无权清空或复用；撤销原变更可以原子恢复字段和值。类型/金额 scale 转换当前拒绝，后续显式转换计划未实现。新增必填字段须同批补值，缩小选项集须同批修正受影响行。超过 FC1 的 500 项动作上限拒绝执行，不能偷偷拆批；大表 schema 迁移待后续设计。

### 行与值

```json
{
  "table_id":"table-example",
  "values":{"f-title":"交通费","f-amount":"128.50","f-paid":false},
  "source":"manual","source_message_id":null
}
```

行的 table_id/source/source_message_id 在创建后不可改变；编辑来源在本次操作日志的 source 记录。source_message_id 当前仅校验 ID 格式，真实消息来源导航及引用完整性待接入。values 用字段 ID 键，更新 values 是**整图替换**；单元格 UI 必须基于当前行的完整值合并再提交 expectedVersion，不能只传一个值而丢弃其他列。

| 类型 | 持久化格式与校验 |
|---|---|
| text | 字符串，最长 100000 字符，禁止 NUL；必填时修剪后非空，保留原文空格 |
| number | 十进制字符串，整数部分最多 38 位、小数最多 18 位，规范化去尾零；不使用 double |
| money | 十进制字符串，整数最多 38 位，scale 0–6；不足补零，超出拒绝，不隐式四舍五入 |
| date | 严格 YYYY-MM-DD，拒绝不存在的日期及年份 0000 |
| datetime | UTC 时间字符串，秒必填，小数秒最多 6 位，规范化为 UTC ISO；UI 先按选定时区转换 |
| selection | 必须是当前 options 中的字符串 |
| boolean | JSON 布尔值，false 是有效非空值；不接受字符串 false |

所有可选字段可缺省或显式 null；必填字段不允许两者。数值拒绝 JSON number、指数、NaN/Infinity、空白、前导加号/冗余零；负零规范化为零。日期为日历日期，不自动解释为当地午夜时间点。旧 UI 的字符串值不是此持久化格式，接入适配必须显式处理，不能把空字符串泛化为所有类型的空值。

### 提交与撤销

同一批可含待办、分类、业务表、类型和行；引用按最终事务状态检查，行出现在建表动作前也可提交。表类型删除须同批解除表引用；表删除须同批删除活动行；行不得移动到另一张表。归档是展示状态，不构成独立写锁。

新增/编辑行先按最终表结构规范化，然后检查整个图；已有行不因 schema 改变被暗中重写。记录、操作前后快照、receipt 和幂等键原子提交。操作源 agent 只是内部元数据，不能代替 FC2 授权；本轮没有发布业务表 Agent 工具。

错误仍使用 FC1 的 `validation / notFound / versionConflict / idempotencyMismatch / storageUnavailable`。本文件前面的 field_type_mismatch 为后续字段级诊断目标，当前未实现。快照仍为全量加载，两个索引分别按表类型/删除标记、所属表/删除标记组织；筛选、排序、分页、聚合、历史查询和 UI 显示尚未接入，不能声称完成 F3-BE-01/02。


## 第 022 轮：人工页面接入

`BusinessUiCommands` 提供异步 createType/createTable/renameTable/assignType/archiveTable/addRow/updateCell/deleteRow/restoreRow。生产从 `LocalWorkspaceSession` 的已提交快照构造 `LocalBusinessProjection`，不注入演示表；同步修改该投影会受控失败。原内存仓库只供未装配免费版的隔离 UI fixture。

`DataColumnDef.id` 为稳定字段 ID，DataTableDef/DataRow/DataTableType 增加实体 version，表另有 schemaVersion。现有页面仍以名称展示及组织表单；codec 把字段 ID 与名称显式映射，真正持久化和历史恢复只使用 ID。复制表结构生成新的字段 ID，模板各实例独立；用户选择模板时的种子行属于显式建表操作，全部同事务校验。

表单提交等待回执才关闭或提示成功。创建和字段编辑保存中限制重复操作；失败保留输入。行编辑使用打开编辑器时的行/表版本，合并数据库完整值后只替换该字段；未编辑字段的精确金额、日期小数秒、缺省/null 不丢失。显示金额按十进制字符串分组，不经过 double。日期时间编辑器按本机时区展示，提交 UTC；直接输入无时区值须通过严格日历和时间检查，非法日期不允许先归一化再保存。

删除返回绑定 changeset 的撤销对象，撤销仍走 FC1，成功后不可再次执行同一个对象。历史列表从真实 workspace_operations 顺序重建，展示人工/Agent 来源及前后快照，包含清空字段；独立显示历史读取中/读取失败和重试。回滚是对选中历史的行值进行新版本写入，保存稳定字段 ID；确认期间出现更新会版本冲突，schema 不再兼容时拒绝，不从显示名称猜测替换。

历史当前全量读取、表/行仍全量投影；分页/大库性能、字段级错误提示、已归档表管理、已删除行历史独立入口、完整 schema 编辑和迁移预检仍待完成。现有页面的搜索/来源筛选/首字段排序复用本地投影，不表示完成受控 SQL 查询。来源引用和原图未接入；免费版截图流程明确显示尚未接入，不运行模拟提取。CSV 导出未完成时不再声称已导出。业务表 Agent 工具/审批没有随人工入口自动完成。


## 第 023 轮：业务表 Agent 与有界读取

生产工具注册增加 7 项，总计 18 项。`BusinessQueries` 负责只读投影，`BusinessAgentTools` 将已校验意图转换为 FC1 行命令；不增加第二套执行器或审批引擎。

| 工具 | 参数与结果 |
|---|---|
| `data_table_list` | 名称 query、include_archived、limit/page_token；返回表 ID/name/version/schema_version/type_id/字段数量 |
| `data_table_get` | table_id、可选 expected_table_version；默认分页返回字段 ID/name/type/required/scale/unit/option_count；指定 field_id 后分页读取完整单选选项 `options.items` |
| `data_row_list` | table_id、可选表版本/query/field_ids/分页；字符串单元格不区分大小写检索，ID 升序；默认前 8 个字段，可指定最多 8 个 |
| `data_row_get` | table_id/id/field_id、可选版本/offset/limit；读取单个单元格，保留布尔/null，present 区分缺省与 null；字符串返回 Unicode code point 分段 |
| `data_row_create` | table_id/expected_table_version/values；模型不提供 ID/source/source_message_id |
| `data_row_update` | table_id/expected_table_version/id/expected_version/values；values 为**稀疏单元格补丁**，省略保留，null 清空可选字段 |
| `data_row_delete` | table_id/expected_table_version/id/expected_version；仅删除明确的这一行 |

所有 values 以稳定字段 ID 为键，按真实表结构校验、规范化。Agent 的稀疏更新合并权威旧 values 后转换为 FC1 的完整值图，与底层整图替换语义不冲突。数字/金额保持十进制字符串，不接受 JSON double；未知字段、错误类型、缺失必填及模型注入来源拒绝整批提案。来源 inputId 与确定性行/动作 ID 由本地代码生成。当前工具不支持建表或 schema 写入；不能将结构删除伪装成普通行编辑。

每批查询都读取写入前快照。列表/结构/选项每页默认 10、最大 20；游标摘要绑定查询参数及相关实体版本，更换过滤条件或数据发生变化返回 cursor_stale，需要重新查询。行预览每字段最多 200 个 Unicode code points，返回 truncated_fields 和 omitted_field_ids，不得当完整值使用。单元格默认 2000、最多 4000 code points；非首段必须带表与行版本，避免拼接不同版本内容。查询仍基于全量 WorkspaceSnapshot；这不是 SQL 分页、排序聚合或大库性能门禁完成证据。

三档权限、部分接受/拒绝、持久提案、摘要、幂等回执与多批撤销沿用 FC2。表实体 version 和预览字段名绑定提案，在同一个提交事务中再检查；表改名/归档/schema 修改也会令旧预览失效，即使行 version 没变。选中批次任一冲突全不写。刷新按稳定字段 ID 将原稀疏意图合并当前行，再生成新预览；保留未涉及字段的并发人工修改，任何权限档位都需重新明确接受。旧审批摘要不可批准新预览。字段已移除/值不再满足结构时刷新拒绝，不自动创建同名新字段。

确认卡展示表名、记录 ID、字段名/单位和完整前后值，清空与未填写区分；UI 遵守既有玻璃卡片与字阶。写入工具回执仅返回 operation_id/id/table_id/version/deleted，避免把整行长文本反复塞入模型上下文；真实 before/after、AI 修改来源仍完整保存在本地日志，后续细节通过只读工具获取。新增来源保持 ai，编辑不改变最初创建来源。

本轮无新增数据库 schema 或依赖。截图/附件、结构写入风险分类、来源导航、完整筛选排序聚合和全量数据的容量验收继续保留在任务卡。

## 第 024 轮：私有图片附件与生产识别入口

数据库升级 v10：`local_attachments` 持久化 id/input_id/table_id/display_name/mime、原图和模型副本的 SHA-256/字节数、原始方向修正后的尺寸、state/created_at。界面使用独立 `ImageAttachment` 领域对象，不导入 Drift 数据对象。每次明确选图建立一个稳定 input_id；对同一次图片反复点击分析、恢复或批准不能产生新运行。

### 文件与恢复

- Flutter 官方 `file_selector` 打开系统文件选择器；仅接收显式选中的静态 PNG/JPEG。取消选择不创建附件、不请求模型。macOS 只申请用户所选文件的只读权限；本轮入口是文件选图，拍照和剪贴板仍待实现，正式入口不展示模拟拍照行为。
- `FlutterImagePreparer` 检查真实文件头、解码、帧数及尺寸。输入最多 10 MiB，单边最多 16000、总像素最多 4000 万；在完整像素解码前检查描述信息，按长边最多 1600 解码，再编码为最多 4 MiB 的 PNG 模型副本，不保留原图元数据。过大、损坏或不支持格式明确失败，不进行假识别。引擎负责 JPEG 方向处理，完整照片方向矩阵仍需真机验收。
- 原图按字节完整保存；模型使用重编码副本。文件位于本机数据库旁的私有 attachments 子目录，名称由应用 ID 派生，不保存用户原始绝对路径，不接受模型传文件路径或下载地址。
- `staging → ready/failed`：先登记元数据、写并 flush 两个临时文件，再逐个原子更名、更新 ready。文件和 SQLite 不伪称单一原子事务；启动恢复持锁检查文件大小/hash，有完整两份文件才补 ready，缺失保持 failed。每个目录有进程内队列和 OS 文件锁，避免导入与恢复互相清理。
- 未绑定会话的附件允许移除，先以事务登记 deleting，再删文件和记录；恢复补完中断删除。已绑定 input 的原图继续保留，供历史/撤销后溯源；未知孤立文件不随意删除，仅清理本目录符合临时命名且无登记的文件。引用释放、备份保留/GC 策略仍待 F5 完成。
- 读取检查状态、普通文件类型、大小/hash；不跟随资源符号链接，不把损坏文件或缺失原图当作可发送来源。错误仅输出安全类别，不带用户路径或请求凭据。

### 模型请求与业务边界

`ChatPersistence.prepare(..., attachmentId)` 验证 ready、input_id 绑定、选中表有效，并与会话/run 原子登记。持久 history 的用户消息保持可见文本，另存 `_towork_attachment_id`；图片 Base64 只在配置校验后的请求边界由 `AttachmentStore.hydrate` 临时展开，数据库和运行日志不保存图片 Base64。本地 ContextWindow 每图预留 16000 单位，最多同时展开 4 张图；这是保守本地预算，不是供应商实际视觉 token 数或套餐余额。

图片导入只向模型公开所选表的 data_table_get、data_row_list/get/create/update；工具 schema 把 table_id 固定为该表。执行器再次基于本地附件输入绑定校验范围，拒绝其他表、待办、删除或结构工具，图片文字不构成扩大权限的依据。新行 source_message_id 自动绑定此 input，编辑仍保留原创建来源；所有本次修改可通过 run receipts 与 workspace_operations 关联到原图。

图片 create/update 必须返回 `uncertain_field_ids`：空数组表示模型声明所提供字段清晰，非空触发 `requires_review`，在三档下都先进入共享确认卡。它是模型的不确定性声明，不是校准过的置信概率。缺失必填/未知字段/错误值继续整批拒绝；提示要求模型先询问，不使用 0/false 或编造文本凑齐。用户批准仍绑定表/行版本、提案摘要，沿用 FC2 部分接受/拒绝、刷新和多批撤销。

`LocalImageImportPage` 提供真实本地预览、导入要求、明确发送提示、已保存图片、恢复待确认结果、停止识别和共享 AgentRunCard。同一识别运行可在聊天历史中查看。行详情“查看来源图片”通过真实提交历史找图片，可查看完整原始字节；撤销业务修改不会清掉来源图。选择图片不会调用模型；按分析才使用用户当前 Kimi 配置，Code 仍为个人主动交互，不后台自动补跑。

### 依据与验证边界

文件选图及只读权限按 [Flutter 官方 file_selector](https://pub.dev/packages/file_selector)；限尺寸解码按 [ImageDescriptor API](https://api.flutter.dev/flutter/dart-ui/ImageDescriptor/instantiateCodec.html)。图片请求采用 [Moonshot 官方 Kimi K2.5 示例](https://github.com/MoonshotAI/Kimi-K2.5) 的 OpenAI 兼容 image_url/data URL 结构；不据此声称当前任意 Code 模型均支持视觉。普通连接测试不等同视觉验收，不自动换模型或端点。

相机采集、macOS 剪贴板、HEIC 等格式、分辨率/方向/内存设备矩阵、精细字段纠错编辑器、消息来源跳转、引用释放与备份并发、真实视觉模型效果仍待验证或实现。脚本模型只用于验证真实业务链路，不能代替模型读图效果证明。

## 第 028 轮：业务行 SQL 级受控查询

`data_row_list` 升级为服务端 SQL 执行：过滤、排序、计数与分页全部下推到 `work_data_rows` 的参数化 SQL（`json_extract` 按稳定字段 ID 取值，值一律绑定参数；字段 ID 先经 schema 白名单校验，运算符/方向白名单映射），仅解码返回页。纯业务读取轮次只物化表/类型实体（`loadTables`），不再加载全量行；混合写入轮次保持 FC1 全图事务语义不变。

- 过滤规则：text/selection 支持 eq/contains（contains 为 ASCII 不区分大小写的 LIKE，转义 %/_/\）；number/money 支持 eq/gt/ge/lt/le（eq 走规范十进制字符串精确比较保留金额 scale，范围比较 CAST REAL，超大数值存在浮点边界）；date/datetime 支持 eq/区间（ISO 字符串比较）；boolean 仅 eq。最多 4 个过滤条件 + 全文 `query`（任意字符串单元格，与快照路径语义一致）。
- 排序：`sort_field_id` 按该单元格值排序（number/money 数值序、其余类型字节序），缺失值恒排最后，id 升序稳定断开平局；默认 id 升序不变。
- 游标摘要绑定 条件 + 表版本 + 总数 + 版本和 + 最大 updated_at：数据变化后旧 token 返回 `cursor_stale`，与既有快照游词语义一致；不承诺捕获摘要碰撞外的极端竞态。
- `data_row_get` 在同路径按 id 单行取回后复用原快照校验/分段逻辑；行预览结构（截断/省略字段标记）与快照路径完全一致，模型无感切换。FE 大数据量表页仍读全量投影，SQL 列表下沉属后续轮。

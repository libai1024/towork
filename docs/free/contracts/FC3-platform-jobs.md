# FC3 · 平台能力与持久化任务

版本 `0.4-draft`。语音与凭据已有生产适配及分层测试；第 017 轮接入持久化任务与系统通知排期，第 018 轮接入 Android WorkManager 本地维护与数据摘要。报告后台调度、实际递送矩阵与渲染仍未完成。语音实测范围见第 009 轮，任务/通知证据见第 017 轮和第 018 轮。

## 接口与状态

| 接口 | 输入 | 输出与失败 |
|---|---|---|
| SpeechInput | inspect/prepare(locale)、start(captureId, locale, onDevice)、stop/cancel(captureId) | available/authorized/locales/onDeviceSupported；listening/partial/finalResult/ended/error |
| KeyVault | credential_ref、write/read/delete | value 或 missing/locked/unavailable；禁止日志输出 value |
| NotificationService | 稳定 notification_id、时区、提醒时间、业务引用 | scheduled/cancelled/permission_denied/unsupported |
| PlatformWakeup | 唯一 job key、最早唤醒时间 | accepted/unsupported；accepted 不等于准时运行 |
| ArtifactRenderer | ReportDocument、模板/字体版本 | 私有产物 ID、尺寸、hash 或 render_failed |

生产接口在 `lib/domain/speech/speech_input.dart`，通过 `towork/speech` MethodChannel 接 Android SpeechRecognizer 与 macOS Speech/AVAudioEngine。`inspect` 只读，不请求权限、录音或联网模型；`prepare` 才请求系统权限。语言清单为空表示平台未提供清单，不能解释为全部支持。设备端模式必须严格满足平台能力，不能失败后静默转联网识别。

状态为 `idle → requesting → starting → recording → finalizing → pending → submitting → sent`；失败保留 `draft`，取消为 `cancelled`。收到真正 final 才进入 pending，并提供 2 秒取消/改文字窗口；最多录音 60 秒，启动等待 8 秒、结束等待 final 5 秒。超时保留 partial，绝不升级为 final。原生另有 65 秒资源截止，stop 后仍保留至任务结束，以覆盖 Flutter 卡顿。以上时长是当前实现默认值，不是新增用户确认。

长按在输入栏内启动采集，松开后停止并把同一个控制器交给既有风格的面板；不能在手指按住时推新路由，否则 Flutter 会取消原触摸。长按期间提前得到 final 或触达录音上限也要等待松开再开启发送窗口。点击入口直接展示面板，支持显式结束；退后台或关闭面板停止自动发送。

所有原生监听器闭包绑定独立 captureId，Dart 与 native 均校验归属。成功样例：`{"id":"speech_1","kind":"finalResult","text":"明早九点开会"}`。失败样例：`{"id":"speech_1","kind":"error","error":"permissionDenied"}`。这是当前通道格式，区别于早期概念样例的 speech_final/input_id。该 ID 原样作为 `sendPersisted(inputId: ...)` 的幂等键，同一输入跨重启重试不生成第二个 run。

取消先使 ID 失效再清理资源；上一轮回调、重复 final 不生效。提交前取消不调用模型；提交过程中取消转交 Agent 取消信号，已落库输入和已提交业务不能假装回滚。发送后用户通过聊天停止生成/撤销已有操作。

网络接口探测仅作发送前提示，不证明 Kimi 可达；真实网络错误继续由 Agent 处理。无网络时保留当前页面草稿，恢复联网不静默发送。草稿尚未跨进程持久化。系统 ASR 可能联网，原始录音不保存、不发 Kimi，提交的是转写文字。

Key 替换先成功写入新凭据再切换 profile revision；删除后清理引用和缓存。测试使用假秘密验证存/读/替换/删；不把普通 SQLite 描述成已加密。锁屏/重装/系统备份恢复必须记录真实平台结果。

## Job 协议

输入 `job_id, type, unique_key, due_at, timezone, payload_version, payload`；记录 attempts、next_attempt_at、lease_owner、lease_expires_at、lease_epoch。按唯一键插入，短事务抢占并递增 epoch；网络在事务外。

`scheduled → running → succeeded / retry_wait / failed / cancelled`；前置条件不足可 waiting_network/waiting_key。提交必须同时匹配 owner、epoch 和未取消状态；旧 worker 的成功回包不可覆盖新结果。最长执行时间与有限指数退避带抖动，预算不足/鉴权失败不自动高频重试。

成功样例：`{"job_id":"j1","lease_epoch":3,"status":"succeeded","artifact_id":"image1"}`。

拒绝样例：旧 epoch=2 回包得到 `{"code":"lease_lost","committed":false}`。本地发布幂等不代表远程请求只计费一次。

## 平台责任与验收

### 第 017 轮实际协议

- 数据库 v8 新增 `local_job_rows`、`notification_attempts`；v1–v7 顺序迁移，已有同名外来表拒绝迁移并回滚。通用 API 为 `enqueue/claim/renew/complete/fail/cancel/cancelLease/wake`；日期以 UTC 毫秒保存，通知 payload 的 `schema` 为 1。后续报告仍须定义自己的时区和快照字段。
- 实际状态名使用 Dart camelCase：`scheduled/running/succeeded/retryWait/failed/cancelled/waitingNetwork/waitingKey/waitingPermission`。`unique_key` 唯一；相同输入不重建任务，输入变化或取消后重新启用递增 epoch。领取用单条 `UPDATE … RETURNING`；默认 30 秒租约，续租最多到本次领取后 5 分钟。
- 本地结果发布与成功标记同事务，提交前后核验 owner、epoch、未过期及 running 状态；callback 只允许同库写入。失效领取只能取消自己的租约，不能撤销较新的执行。默认最多 5 次尝试，指数退避从 30 秒开始、上限一小时并加抖动；等待条件不会轮询消耗尝试次数，失败重试需显式唤醒。
- 业务提醒键由 todo ID 与规则 ID 组成；每次租约另分配持久化 OS 整数 ID，避免迟到执行者取消新提醒。排期不在 SQLite 事务内；不承诺外部副作用恰好一次。对账清理无效尝试，系统待排列表丢失或 payload 不匹配则重建。
- 普通和重复实例共用规则：绝对时间或相对截止偏移，同一待办同一时刻去重；完成、删除、关闭全局提醒、改期或规则变化使旧排期失效。旧 `remind_at` 映射为可见的绝对规则，编辑规则时清理旧字段。没有规则的截止待办不自动获得提醒。
- 前台启动、恢复、业务变更和每分钟检查，登记未来 30 天内最近 60 项；更远任务保留业务数据并显示等待排期，已过时的提醒不集中补发。每日摘要预排最多 7 个本地日历日，目前是进入今日待办的提示，尚未实现动态摘要内容。
- `NotificationService` 实际方法为 `initialize/inspect/requestPermission/requestExactPermission/openSettings/pending/schedule/cancel`。初始化不弹权限；设置页和提醒编辑提示提供手动授权。普通 Android 提醒允许系统延迟，精确权限另行请求且仅用于截止提醒。权限失败保留待办与提醒规则。
- 通知 payload 使用 `towork/job_id/epoch/todo_id/kind`，点击只可跳固定待办路由；不存在的目标显示已不存在，非法 payload 忽略。排期成功只记 `registered`，不记录为已经递送。
- 当前未接入 WorkManager、macOS 后台唤醒或报告处理器；隐藏/暂停期间不运行新的 Dart 对账循环，已经登记的 OS 通知由系统负责。租约上限约束提交资格，不等同于强制终止平台调用。全库对账和旧任务清理还需性能验证。

Android 区分退后台、普通进程回收、force-stop；macOS 区分隐藏窗口、仍运行、完全退出。已登记系统通知与运行模型/渲染海报是不同能力。启动与恢复时补跑，错过计划时间展示实际生成时间。海报渲染需要 Flutter engine 时单独排队等待可用前台/渲染环境。

### 第 018 轮增量

- Android 生产启动登记唯一 `towork.local-maintenance.v1` 周期任务，请求 15 分钟间隔与首次延迟，使用 update 保留已有调度；它是系统可延期工作，不是准点承诺，不请求前台服务或持续保活。注册结果在通知设置中显示，失败可重试。
- 后台回调只接受固定任务名，忽略 inputData，打开既有固定业务库；库缺失不创建替代库。不读取模型凭据、不请求模型、不执行遗留 Agent 指令。应用层负责装配，数据层不反向依赖应用协调器。
- 每 15 分钟时间槽复用一个 `local_maintenance` 业务任务，三次尝试上限、五分钟领取租约；跨连接竞争只保留有效领取。一次扫描采用 90 秒协作式预算，以及原有 8 次事务/32 个重复计划与 60 条通知上限；预算在步骤间检查，不代表能强制终止已经挂起的平台调用。
- 重复规划从上次成功扫描的 `last_series` 之后开始轮转，输入中保留起点；相同槽位不因成功结果改变而重新入队。进入本轮时发现 15 秒内有人工/Agent 提交则暂缓重复补齐，通知仍可更新。这是启动时的保护，不是跨进程界面确认窗口互斥；并发编辑仍由业务版本检查保护。
- 后台维护回执记录实际完成时间、剩余系列、系列问题数、通知登记及失败数。维护扫描成功不等于所有提醒已登记或已送达。WorkManager 回调不另开无限失败重试，后续周期读取持久化任务状态。
- 每日摘要按目标本地日历日统计 pending/inProgress 待办，排除已删/完成/取消、无日期；含当日到期数、此前未完成数和最多三个标题，按优先级及截止排序。未来日期明确标注“预排快照”，数据变化/后台机会/前台恢复时更新；点击进入当前“今天”筛选。没有模型生成，数字不依赖模型推测。
- 后台通知初始化不抢占同 isolate 已有前台点击回调，不处理启动导航，也不弹权限。macOS 当前继续使用前台维护；虽 workmanager 的依赖包含 Apple 实现，本轮没有开启其后台调度，更没有退出后执行保证。

UI/原生集成者负责权限、entitlements、系统备份排除、快捷键与菜单栏；核心负责状态与幂等。测试必须覆盖双端 release 的实际启动和重启，不把编译成功算运行通过；用户最终人工验收语音，自动测试仍覆盖取消/重复回调/无权限。

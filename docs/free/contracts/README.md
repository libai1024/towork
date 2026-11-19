# 免费版开发契约索引

版本：`0.1-draft`，2026-09-23。负责人/当期集成者：当前开发任务。**草案可以支持隔离原型，尚未冻结为生产实现。** 修改状态与证据见开发进度。

| 契约 | 文件 | 核心实施方 |
|---|---|---|
| FC1 | [本地命令、实体与事务](FC1-local-commands.md) | 端侧核心；FE 消费异步状态 |
| FC2 | [模型、Agent 与权限](FC2-agent.md) | 核心与会话 UI |
| FC3 | [平台适配与任务](FC3-platform-jobs.md) | 平台 FE 与任务核心 |
| FC4 | [数据表、附件与记忆](FC4-data-memory.md) | 核心与对应页面 |
| FC5 | [统计与报告](FC5-reports.md) | 核心统计与 FE 渲染 |
| FC6 | [备份与版本边界](FC6-backup-edition.md) | 核心与设置 UI |

## 已有代码的渐进替换

| 当前实现 | 问题 | 迁移目标 |
|---|---|---|
| `lib/app/dependencies.dart` / `MockChatService` | 原模拟回答与动作 | 已通过 LocalChatRuntime / LiveChatViewModel 接入真实 Agent；Mock 仅显式 fixture，见 FC2 0.3 |
| `TodoStore` / `TodoRepository` | 同步写入内存、默认演示数据 | 异步 CommandExecutor + SQLite watch；提交前不展示成功 |
| Category/DataTable/Memory/Report Store | 多份内存状态、部分跨仓库快照回滚 | 单库事务与按版本撤销；演示数据仅显式 demo/test 使用 |
| `lib/app/providers.dart` | 用户名、权限及记忆暂停仅 StateProvider | SQLite profile/preferences；保持 Riverpod 的展示订阅 |
| `InputPreferencesService` | 仅输入模式保存在 shared_preferences | 可保留非敏感外观/输入偏好；业务数据进入 SQLite |
| `ListStore` 和部分模型 | 依赖 Flutter/Riverpod/颜色类型 | UI 适配层保留；后台命令 DTO 不引用 UI 类型 |
| `AiWritePolicy` | 原中间档仅自动新增 | 已改为共用 `evaluatePermission`，编辑也自动；待办 Agent 提交前已二次鉴权，业务表仍待接入 |

**不能用同步 Store 包装异步写盘然后忽略 Future**：这会让失败后 UI 仍显示成功。迁移每个页面时同时加入 loading/error、重试与已提交回执；保留现有视觉、路由和 iOS 26 风格。

## 版本与角色协作

- 契约 JSON 均包含 `schema_version`；增加可选字段兼容，删除/变更含义需提升主版本并提供迁移 fixture。
- FC 草案冻结前至少由 FE 与 QA 场景逐项核对；当期单个集成者顺序修改 `pubspec.yaml`、锁文件、Provider 装配与统一检查入口。
- 测试落点：纯协议 `test/data/ai/`，真实 SQLite 原型 `test/data/local/`，后续 Fake Gateway/Clock/Vault 放 `test/support/free/`（已有脚本模型和 Fake Vault；完整场景继续扩展）。
- 当前可注入接口：`ModelGateway`、`ModelCancellation`、HTTP transport；已有隔离 SQL 原型通过 executor 和迁移 checkpoint 注入故障。
- 测试秘密只能使用固定假字符串。联网测试独立显式启用；离线 CI 不读取用户 `.env`。

待验证默认值：智能确认作为默认档；月末重复遇无同日时取月末；报告周一开始、周日结束；后台漏跑优先补最近周期。这些是建议默认值，实施相关卡时在设置/验收中明确，不能声称用户逐项确认过。

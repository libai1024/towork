# ToWork 双端长期维护方向

2026-11-19，基于当前工作区。建议继续用一套 Flutter 业务代码、一套本地数据模型和分别发行的 Android、iOS 宿主。先让同一项业务改动在两端都能自动验收，再从待办详情开始缩小每次改动的影响范围。

## 五个可比项目

Star 数取自当日 GitHub API 的仓库级快照。源码链接固定到调研时默认分支的提交。Immich 和 Ente 还包含服务端或其他客户端，表中分析的是 Flutter 移动端。选样依据是与 ToWork 的具体问题相似，包括多视图编辑、本地数据库、实时交互、原生入口和跨产品复用。

| Flutter 项目 | GitHub Stars | 源码中可见的设计 | 对 ToWork 的取舍 |
| --- | ---: | --- | --- |
| AppFlowy | 79,181 | 看板和日历各有自己的 BLoC，两者都使用 `DatabaseController` 接收同一套行、字段和布局变更。[看板](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/database/board/application/board_bloc.dart#L31) / [日历](https://github.com/AppFlowy-IO/AppFlowy/blob/8fcee27d9bd93aad4ee0191d5d8d915d6a9a4e93/frontend/appflowy_flutter/lib/plugins/database/calendar/application/calendar_bloc.dart#L22) | 待办列表、看板、日程和 AI 卡片可以各自管理筛选、分页和选择。完成、改期、撤销共用业务命令。现有 Riverpod 足以表达这种分工，迁移 BLoC 的收益有限。 |
| Immich | 119,595 | 移动端用两个后台连接同时打开同一个旧版 SQLite 文件，验证两个连接最终都读到目标 schema。移动构建工作流分别配置 Android 和 iOS 作业。[并发迁移测试](https://github.com/immich-app/immich/blob/557c854489f931e9ab906c6f550c44be05179288/mobile/test/drift/main/concurrent_migration_test.dart#L19) / [移动构建](https://github.com/immich-app/immich/blob/557c854489f931e9ab906c6f550c44be05179288/.github/workflows/build-mobile.yml#L255) | Android 主界面和快问会分别打开同一数据库。ToWork 应持续用上一正式版数据验证并发升级、记录保留与写入后的跨引擎可见性。iOS 构建也应成为日常反馈。 |
| LocalSend | 99,676 | 文件实时进度单独放进 `FileTransferNotifier`，按会话和文件保存；多项状态可合并通知，进度变化无需复制整份会话。[传输状态实现](https://github.com/localsend/localsend/blob/e05d12a9c0fd4d8c0245d2ec5c3c177e7e0f759b/app/lib/provider/file_transfer_provider.dart#L4) | 转写中的文字、音量和生成中的回复都可能高频变化。用长会话录制一段性能轨迹，若侧栏、历史消息或整张待办表随之反复重建，再缩小对应 Provider 的订阅范围。 |
| FlClash | 64,018 | Flutter 侧把 Android 快捷开关封装在 `Tile`，对应 Kotlin 插件负责通道注册、回调和解绑；Dart 只在 Android 创建实例。[Dart 侧](https://github.com/chen08209/FlClash/blob/be84736605527034689c95bf27828ff27d912c5e/lib/plugins/tile.dart) / [Kotlin 侧](https://github.com/chen08209/FlClash/blob/be84736605527034689c95bf27828ff27d912c5e/android/app/src/main/kotlin/com/follow/clash/plugins/TilePlugin.kt#L9) | 对照的是 Android 原生入口的边界。ToWork 已有快问、语音和更新契约，可以沿用同一方式接入苹果端能力；原生对象何时可用、何时解绑由适配层负责。 |
| Ente | 30,266 | Photos、Auth、Locker 是独立应用，同处一个 Dart workspace。Photos 和 Auth 都实际依赖共享的 `ente_components` 和 `ente_ui`。[工作区](https://github.com/ente/ente/blob/6b913616b722f80f5a2c3667ca457bd0d8cf0eed/mobile/pubspec.yaml#L15) / [Photos 依赖](https://github.com/ente/ente/blob/6b913616b722f80f5a2c3667ca457bd0d8cf0eed/mobile/apps/photos/pubspec.yaml#L45) / [Auth 依赖](https://github.com/ente/ente/blob/6b913616b722f80f5a2c3667ca457bd0d8cf0eed/mobile/apps/auth/pubspec.yaml#L29) | ToWork 当前的 Android、iOS 以及主聊天和快问都能直接引用同一套 Dart 组件。现阶段维护一个应用包最省事。以后若有独立客户端复用同一组组件，或某个原生适配需要独立构建测试，再把对应目录提为包。 |

## 当前应守住的三条边界

1. **业务事实由本地工作区持有。** 页面保存焦点、草稿、展开状态和筛选，Riverpod 提供页面所需的投影，持久化写入走工作区命令。AI 的写入另有授权、版本核对和工具执行记录；业务写入与工具记录的事务关系需要保留。这样，从聊天卡片勾选的待办与从日程勾选的待办，能得到相同的状态，也能分别追溯触发来源。[架构](ARCHITECTURE.md) / [命令与回执](../lib/domain/workspace/workspace_commands.dart) / [Agent 写入](../lib/data/local/agent_tool_executor.dart)
2. **平台差异由每项能力的契约表达。** 已有 `SpeechInput`、`AssistEntries`、`CodeUpdateGateway`。视图根据能力和状态显示入口，Android 快问、iOS 首次向模型服务商发送内容的授权、两端的更新渠道分别实现。保持契约小而独立，避免每新增一项系统功能都要修改所有平台的总接口。[语音](../lib/domain/speech/speech_input.dart) / [快问](../lib/domain/assist/quick_assist.dart) / [更新](../lib/domain/update/code_update.dart) / [iOS 授权](../ios/Runner/AppDelegate.swift)
3. **共享源码和发布版本分别追踪。** 两端使用同一份源码开发；Android 的基础包和免安装补丁、iOS 的 TestFlight 和商店构建各有发布节奏。建议每次发布记录可还原的源码提交、基础版本、补丁或构建号，以及对应平台的验收结果。这样可以直接回答某次共用界面修复是否已经送达 iPhone。[Android 发布](release/README.md) / [iOS 分发](release/ios/listing.zh-Hans.md)

## 建议实施顺序

| 顺序 | 第一项具体改动 | 如何验收 |
| --- | --- | --- |
| 1. 补双端构建与冒烟 | 在现有 CI 的 macOS runner 加 iOS 模拟器无签名构建。共享 Dart、依赖或宿主变更触发对应平台。用一条共用流程覆盖打开应用、新建待办、完成、重新启动后读回；APK 和苹果签名归档继续分别执行。 | 同一源码提交可查 Android 与 iOS 的构建结果，两个平台都能跑通待办流程。现有 CI 已配置 Android、macOS 构建；iPhone 已有单独模拟器回归记录，可作为用例起点。[CI 矩阵](../.github/workflows/flutter.yml) / [iOS 验证记录](release/ios/listing.zh-Hans.md) |
| 2. 从待办详情试拆 | 实测待办详情 1,885 行、待办列表 1,345 行、数据表详情 1,113 行。第一轮只处理待办详情中的截止时间、提醒、重复规则编辑器。共享表单放在待办组件目录；草稿写入协调若需抽离，沿用当前串行保存和失败重试语义。 | 改一项提醒交互只需触及相关编辑器和测试。保存途中继续打字、写入失败保留草稿、关闭等待保存完成均通过现有回归。文件体积基线随实际拆分下降。[待办详情](../lib/core/todo/todo_detail_sheet.dart) / [写入回归](../test/workspace_capture_persistence_test.dart) / [体积基线](../test/architecture/file_size_baseline.json) |
| 3. 把兼容性验收与发布对应起来 | 数据库 schema 或写入协议变化时，用已发布旧库夹具验证升级、并发打开、失败回滚；改 Agent 写入时验证重复执行和待确认提案。Android 每次发补丁继续验证从旧补丁更新、自动重启与快问。iOS 候选构建单独验收权限和首次模型授权。 | 能从记录定位到旧版本、测试设备、执行的操作和持久化结果。沿用现有真实数据库和双引擎测试，按变更补缺项。[数据库测试](../test/data/local/database_probe_test.dart) / [引擎同步测试](../test/app/engine_sync_test.dart) / [发布手册](release/README.md) |

第一次评估成效，看三个结果就够了：一项共享改动能否拿到双端运行证据，一项提醒改动需改动几个业务文件，一次正式发布能否追溯到确切源码。后续是否拆包、更换状态管理或增加跨语言模块，再由实际复用、性能数据和维护成本决定。

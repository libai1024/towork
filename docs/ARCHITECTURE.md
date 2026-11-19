# ToWork 客户端架构

当前客户端使用 Flutter、Riverpod、go_router、Drift/SQLite。生产数据通过本地工作区装配，页面依赖注入的契约与响应式投影。模型请求由用户配置的账户直连服务商，Agent 循环在本机运行。免费版范围见 [方案总览](free/README.md)，视觉规则见 [DESIGN.md](../DESIGN.md)。

## 目录与依赖

| 目录 | 责任与约束 |
| --- | --- |
| `lib/domain` | 不可变模型、仓库和平台契约、权限与业务规则。依赖保持朝内 |
| `lib/agent` | 提示词、上下文、工具注册与执行循环，依赖 domain 契约 |
| `lib/data` | SQLite、HTTP、凭据、文件与平台通道。实现 domain/Agent 契约 |
| `lib/app` | 依赖装配、数据库生命周期、工作区投影、共享 ViewModel、跨业务命令 |
| `lib/features` | 单个功能的页面与局部交互，使用 app 注入和 domain 契约 |
| `lib/core` | 跨页面复用的 UI。模型品牌/额度、分类编辑、待办详情/卡片、Agent 回执分别放在 `ai`、`categories`、`todo`、`agent` 子目录 |
| `lib/shell` | 主应用路由、导航与跨功能界面组合，包含快问窗口和字体/系统栏外框 |
| `lib/theme` | 颜色、字阶、间距、圆角与系统栏 token |

`app/chat` 的 ChatViewModel 供聊天、图片导入与快问共同使用，`app/todo` 的过滤和命令供待办、日程与总览共同使用。`shell/quick_assist_panel.dart` 组合聊天组件和快捷面板容器。分类和待办的页面专用部件继续放在对应 feature。

机器守卫检查 import、export、part 与条件导入。domain/data 的向外依赖、app 到 features/shell、跨 feature 引用、feature 到 data/shell、core 到 features/shell/data，以及新代码对 `mock/` 的引用都会失败。共享 UI 通过注入的 app/domain 契约访问数据。`lib/mock` 为历史兼容导出。检查位于 `test/architecture/layer_dependencies_test.dart`。

当前 Store 使用 Riverpod StateNotifier，部分模型保留 `dart:ui Color`。domain 的纯 Dart 包隔离需单独规划。页面持有 TextEditingController、FocusNode、动画与滚动控制器，退出时释放。跨业务异步过程归 app 的 ViewModel 或 use case。

## 数据与操作

生产工作区由 `FreeWorkspaceBootstrap` 读入本地身份、偏好、工作区和会话，再挂载页面。加载失败显示可重试状态。默认库为应用支持目录中的 `towork-free.sqlite`，schema 13。测试通过 ProviderScope 和独立 SQLite 文件注入替身。

仓库拥有已提交业务数据，页面和 ViewModel 保存过滤、选择、生成等过程状态。集合构造时复制并冻结，业务更新经过统一 workspace commands。批量 Agent 操作先准备和校验，用户授权后事务提交。撤销按操作回执和版本检查恢复受影响记录。

待办页面从 `todoListProvider` 读取不可变列表，按 ID 查询使用 `TodoReadStore`。生产投影只由 `LocalWorkspaceSession` 接受已提交的状态。手动创建从 `AsyncTodoCommands.create` 进入，以表单的操作 ID 构造一条 `AppendTodo`。SQLite 在首次提交时确定排序、完成时间与回执，相同请求重试可取回原回执。批量编辑继续通过工作区草稿比较生成变更。快问经 Agent 工具提案和授权写入，共用工作区字段校验、事务与可撤销回执。页面级错误提示位于 `core/workspace_actions.dart`。

模型账户保存凭据引用，实际 Key 由系统安全存储管理。界面错误通过稳定错误码映射。长期记忆、上下文裁剪、权限和工具协议见 [Agent 工具规范](standards/AGENT-TOOLS.md)。

日期和统计使用明确的本地时区。只有日期的截止值按本地 18 时解释。SQLite 时间写入和读取遵循各 DTO 契约，禁止把 UTC 日期截断当作本地日边界。

## 双引擎与并发

Android 主 Activity 与透明 AssistActivity 各自创建 Flutter engine，快问使用 `assistMain` 入口。两引擎共用数据库文件，各自持有 `AppDatabase.background` 连接。

代码补丁运行时按进程加载主入口。主引擎由 `MainFlutterEngine` 在进程内复用，Activity 重建时重新绑定平台通道，维持已加载的代码和工作区。主引擎存活计数跟随进程，快问引擎计数跟随自身销毁，后台主引擎仍被视为可能执行中的同伴。

- 每条后台连接设置五秒 busy timeout 和 WAL。首次 WAL 切换遇到 SQLITE_BUSY 时在五秒范围内重试。
- 建库和升级使用 `BEGIN IMMEDIATE`。拿到写锁后重新读取 `user_version`，schema 变更和版本号一起提交，失败回滚。两个引擎同时首次打开时，后获得锁的一方读取已完成的版本。
- 本地身份和初始偏好使用冲突忽略的单次插入，然后重新读取唯一记录。
- Kotlin `AssistHub` 统计当前进程的活跃引擎并存放最新交接。启动恢复仅在没有其他活跃引擎时中断遗留生成。
- `EngineSync` 在回到前台时比较 `PRAGMA data_version`。另一个引擎存活时，每两秒继续比较。外部提交会触发 `markTablesUpdated` 和会话投影刷新。
- 刷新失败保留待刷状态并在前台重试。交接刷新成功后才送达，首次检查也刷新一次交接会话。自身空闲且没有其他引擎时才恢复遗留运行。
- `ChatPersistence.prepare` 拒绝同一会话叠加生成。模型请求有取消信号、请求序号与配置版本检查，迟到回包无法覆盖新状态。

快问关闭时保留正在生成的引擎，完成后退出，三分钟超时取消。后台生命周期受系统调度影响。分享和划词文字仅预填，语音入口主动启动听写。入口说明与模拟器复跑步骤见 [快捷唤醒](upgrade/QUICK-ASSIST.md)。

## 路由与界面状态

`shell/router.dart` 创建随作用域释放的 GoRouter。业务地址集中在 `AppRoutes` / `AppRouteNames`，动态 ID 通过 URI 编码。详情缺失和未知地址使用受控页面，返回通过 `popOrGo` 处理无历史栈的情况。

页面之间的导航和快问向主应用的导航经 `AppNavigationRequests` 传递。会话交接在投影中找到记录后选择。主应用选择会话时收起侧栏，使消息流可见。

系统字号与应用偏好倍数由 `AppFrame` 统一叠加。共享控件处理键盘、触控目标、键盘焦点、深色、高对比与减少动画。

## 文件体积

手写 `lib/**/*.dart` 新文件最多 500 行，生成的 `*.g.dart` 单独排除。已有大文件记录在 `test/architecture/file_size_baseline.json`。改小后同步降低基线，低于 501 行后移除条目。删除文件时清理条目。基线代表本轮接手的存量，增加基线或新增豁免需要明确评审。

`file_size_test.dart` 检查当前树，CI 的 `tool/check_size_baseline.py` 对比 Git 基线，拒绝提高限额和新增大文件豁免。拆分保持职责完整，避免仅为行数拆出没有独立职责的碎片。

## 验证与发布

固定 Flutter 3.47.5 / Dart 3.13.4，提交 pubspec.lock。所有 Flutter 命令串行执行。

```sh
bash tool/fetch_asr_models.sh
bash tool/check.sh
flutter test test/architecture
```

质量门覆盖 lockfile、格式、严格静态分析、架构和普通测试。平台集成使用独立数据库和脚本模型，真实模型、麦克风、设备后台调度单独记录证据。测试矩阵见 [测试规范](standards/TESTING.md)。

CI 构建 Android/macOS，tag 流程验证版本和签名并生成 Android 发布产物。当前官网通过 `tool/publish_android.sh` 上传 APK 和原子更新清单。签名与共享服务器路径见 [发布手册](release/README.md)。

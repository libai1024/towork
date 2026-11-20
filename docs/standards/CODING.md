# 编码规范

## 界面文案与语言

中英文文案位于 `lib/l10n/app_zh.arb` 和 `app_en.arb`，使用 Flutter SDK 的 `gen_l10n`。页面从 `context.strings` 读取，带参数的文案使用命名占位符，英文计数使用 ICU 复数。修改后执行 `flutter gen-l10n`，连同生成的 Dart 文件一起提交。存储键、用户输入、历史内容保持原文，系统快捷入口另配原生语言资源。

## 边界与复用

功能入口在 features，跨功能组合在 shell，共享 UI 在 core，业务过程与依赖装配在 app，契约在 domain，具体实现放 data。通过现有 workspace commands、ViewModel 和 repository 完成操作。跨 feature 的共享代码迁到具备明确职责的公共位置，调用方使用同一实现。[架构约定](../ARCHITECTURE.md)

手写 Dart 新文件最多 500 行。已有超限文件按 JSON 基线只减，缩小时同步降低基线。格式统一交给 `dart format`，普通实现使用清晰命名和直线控制流。生成文件通过已有生成工具更新。

## 状态与生命周期

Repository 保存已提交数据。ViewModel 管理请求、取消、过滤与过程状态，Widget 持有控制器和本地展示状态。异步完成后检查作用域或 mounted，配置和会话变化时拒绝迟到回包。计时器、监听、请求、数据库连接和 UI 控制器按持有者生命周期释放。

集合与嵌套 JSON 按契约冻结。可清空字段区分省略和显式 null。状态更新通过不可变替换通知订阅者。外部引擎提交通过 EngineSync 刷新。

## 事务与失败

写入先解析和校验，在统一事务内提交。幂等操作绑定 inputId/operationId，编辑使用 expectedVersion。重试、取消、冲突和进程中断都应保持可恢复状态。数据库迁移持写锁后读取版本，schema 与 user_version 同事务提交。

捕获预期业务错误并映射公开消息。基础设施失败保持失败语义，用户输入在失败后可修正和重试。权限由应用层在每次提交前检查，撤销基于回执和当前版本。

## 平台与凭据

原生能力通过 domain 契约和 data/platform 通道接入，unsupported 与失败返回受控状态。UI 由系统安全区和键盘 insets 驱动。模型身份使用真实的 `User-Agent: ToWork/1.0`，账户、端点与凭据引用保持明确关联。

Key 保存到系统安全存储，代码、fixture、日志和文档使用合成值。诊断消息采用错误码，图片和外部文本按数据处理。

## 检查

```sh
dart format lib test integration_test test_driver
flutter analyze --no-pub --fatal-infos
flutter test test/architecture
python3 tool/check_size_baseline.py --base HEAD
```

根据本次失败模式补充回归，然后执行完整质量门。[测试规范](TESTING.md)

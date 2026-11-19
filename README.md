# ToWork

Android、iOS 和 macOS 共用的 Flutter 工作助手，支持对话、待办、日程、业务表格和本地记忆。

## 开发

使用 Flutter 3.47.5。在项目根目录运行以下命令。

```sh
bash tool/fetch_asr_models.sh
flutter pub get --enforce-lockfile
bash tool/check.sh
flutter run --target lib/main.dart
```

架构、真机验证和发布各有独立记录。[架构](docs/ARCHITECTURE.md) / [双端开发计划](docs/DUAL-PLATFORM-DEVELOPMENT-PLAN.md) / [测试规范](docs/standards/TESTING.md) / [发布说明](docs/release/README.md) / [官网](https://zhaozhaoyue.top/towork/)

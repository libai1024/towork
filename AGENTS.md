# ToWork

Flutter 客户端共用本地工作区、模型网关和 Agent 工具。平台适配位于 Android、iOS 和 macOS 宿主。改动前阅读[架构](docs/ARCHITECTURE.md)、[双端开发计划](docs/DUAL-PLATFORM-DEVELOPMENT-PLAN.md)以及[贡献指南](CONTRIBUTING.md)。

先校验离线模型，再运行 `bash tool/check.sh`。Flutter 命令在同一 checkout 中串行执行。发布凭据与用户数据库保存在仓库之外。[发布说明](docs/release/README.md)

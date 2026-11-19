# 移动端发布

Android 使用 `TOWORK_DRY_RUN=1 bash tool/publish_android.sh "更新说明"` 生成签名候选、基础包与旧版本 APK 差量。在原安装上验证升级与数据保留，记录 Git 提交、签名、SHA-256 和设备结果。兼容代码变更沿用 `tool/publish_code_patch.sh`，宿主或原生改动提升基础版本。保存既有补丁编译基线。签名配置参见 [Android 签名](../ANDROID-RELEASE.md)。

官网部署使用维护者的 SSH 别名及专属目录。配置 `TOWORK_HOST`、`TOWORK_SITE_DIR` 和 `TOWORK_DOWNLOAD_DIR` 后运行 `tool/deploy_website.sh` 或 Android 发布脚本。SSH 密钥与补丁签名密钥保存在发布机。目录尾部须分别是 `/towork` 与 `/towork-dl`。

iOS 从同一提交的 `lib/main.dart` 归档。分别记录开发签名、TestFlight 和商店分发状态。公开下载记录由 [官网](https://zhaozhaoyue.top/towork/) 提供。

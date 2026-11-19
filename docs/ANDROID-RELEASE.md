# Android 发布签名

本项目通过可选的 `android/key.properties` 配置 release 签名，字段沿用 [Flutter 官方 Android 签名文档](https://docs.flutter.dev/deployment/android#sign-the-app)。签名密钥由发布负责人管理；仓库不会自动创建密钥。

## 构建边界

| 本机配置 | Debug | Release |
| --- | --- | --- |
| 没有 `android/key.properties` | 使用 Android 默认调试签名 | 未签名，不会回退到调试签名 |
| 四个字段完整 | 使用 Android 默认调试签名 | 使用指定 keystore，凭据由 Android 构建工具验证 |
| 文件存在但字段缺失或为空 | Gradle 配置失败，提示缺失字段 | Gradle 配置失败，避免误以为已配置发布签名 |

无签名的 release 产物只能用于编译、分析等检查，不能作为可安装 APK 或已签名的商店上传包。`flutter run --release` 也需要有效签名。日常模拟器验证使用 `flutter run --debug`。

## 配置已有 keystore

在本机创建 `android/key.properties`，将占位值替换为已有 keystore 的实际信息：

```properties
storeFile=/absolute/path/to/upload-keystore.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=YOUR_KEY_ALIAS
keyPassword=YOUR_KEY_PASSWORD
```

`storeFile` 推荐使用绝对路径；相对路径以 `android/app/` 为基准。Windows 路径应使用 `/` 或转义反斜杠 `\\`。不要给属性值加引号；文件按 Java Properties 格式读取。

`android/.gitignore` 已忽略 `key.properties`、`*.jks` 和 `*.keystore`。CI 应在构建前从受控凭据存储注入文件与 keystore，不将密码写入命令行或构建日志。

## 构建与核验

从项目根目录执行：

```sh
# 只验证 Gradle 配置，不编译应用。
./android/gradlew -p android help

# 配置签名后生成发布包。
flutter build appbundle --release
flutter build apk --release
```

发布前应确认 APK 的证书与预期发布证书一致，可使用 Android SDK Build Tools 的 `apksigner verify --print-certs <apk-path>` 检查。AAB 使用上传密钥签名；启用 Play App Signing 时，最终用户安装包的签名由 Play 管理，详见上述官方文档。

签名配置变更后若出现旧产物干扰，清理构建缓存再重建。当前改动只接入签名配置，不代表已提供发布密钥、验证真实签名或完成商店发布。

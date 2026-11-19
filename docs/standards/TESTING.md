# 测试规范

## 普通质量门

固定 SDK 和 lockfile，通过唯一入口复跑全部普通验证。

```sh
bash tool/fetch_asr_models.sh
bash tool/check.sh
```

`tool/check.sh` 依次检查交付脚本与文档、解析锁文件、检查格式、严格静态分析、架构边界和全部单元/widget 测试，生成 `coverage/lcov.info`。覆盖率用于定位缺口，关键行为由明确用例守住。

## 分层与替身

| 层级 | 输入与断言 |
| --- | --- |
| domain / agent | 注入时钟、偏移、不可变快照和脚本模型，断言规则、工具 schema、权限、错误恢复及预算 |
| data | 独立临时 SQLite、HTTP 协议替身、合成 Key，断言事务、迁移、重开、并发、幂等与坏数据恢复 |
| app | Provider overrides，断言真实业务命令、状态投影、生命周期和迟到回包 |
| widget | 通过实际按钮、键盘与路由操作，断言失败草稿、触控尺寸、可访问性、深色和响应式布局 |
| native | 启动真实 Activity/engine/FFI/平台通道，业务库隔离，逐项标明被替换的外部服务 |

新增测试应覆盖本次改动带来的具体失败模式，优先复用已有 fixture。SQLite 并发测试使用两个独立后台连接。时间驱动的 mock 回复通过 `pump` 推进计时器，`pumpAndSettle` 只等待已有帧动画。

## 本轮回归入口

```sh
flutter test test/quick_assist_panel_test.dart test/quick_assist_settings_page_test.dart test/app/engine_sync_test.dart test/data/platform/assist_channel_test.dart
flutter test test/features/chat test/mobile_sidebar_reveal_test.dart test/app_font_scale_test.dart
flutter test test/agent test/domain/ai test/data/ai
flutter test test/data/local
```

快问原生双引擎 fixture、ADB 入口与设置检查见 [快捷唤醒说明](../upgrade/QUICK-ASSIST.md)。测试包标签为「towork 自动化测试」，完成后用 `lib/main.dart` 重新构建覆盖安装。

## 原生语音与构建

```sh
flutter test integration_test/asr_streaming_test.dart -d emulator-5556
flutter test integration_test/free_chat_ui_test.dart -d emulator-5556
flutter build apk --release --target-platform android-arm64 --target lib/main.dart
flutter build macos --debug
```

ASR 集成测试通过实时节奏回放 WAV，使用真正的 SenseVoice/VAD FFI，记录首个 partial 和最终文本。真人普通话、方言、噪声、蓝牙与来电中断由目标设备人工录音验收。模型的线上鉴权、额度、故障转移使用明确的测试账户，记录服务商、模型与真实结果，凭据由既有设施读取。

## 证据记录

每次结果写明日期、代码树/提交、完整命令、设备与系统、通过数量、外部替身和限制。模拟器结果与华为真机结果分别记录。构建成功、安装启动成功、正常业务闭环各自保留证据。最终报告保留当前仍待人工或外部环境验证的项目。[本轮验证记录](../upgrade/VERIFICATION.md)

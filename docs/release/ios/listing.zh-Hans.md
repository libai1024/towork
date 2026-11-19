# ToWork Apple 平台首次提交资料

| 字段 | 内容 |
| --- | --- |
| 名称 | ToWork 待办与日程 |
| 副标题 | 对话、待办与日程 |
| 主要类别 | 效率 |
| 语言 | 简体中文 |
| 价格 | 免费 |
| 关键词 | 待办,日程,时间管理,工作清单,任务,提醒,周报,记忆,语音,表格,个人助理 |
| 支持 | https://zhaozhaoyue.top/towork/support.html |
| 隐私政策 | https://zhaozhaoyue.top/towork/privacy.html |
| 营销网址 | https://zhaozhaoyue.top/towork/ |

## 商店描述

ToWork 帮你把口头交代变成待办。接入自己的模型后，按住说「明天下午三点交初稿」，松手发送，就能在待办里核对标题和截止时间。想改口，滑到「编辑」先改文字。

你可以告诉 ToWork「我的周报先列风险」。这类长期偏好会保存在记忆库，供以后的对话使用。你可以查看、修改或删除记忆，也可以开启免记忆模式。

打开「报告」，按本周或本月的实际工作记录生成总结。Mac 版本还可在设置中开启「每日晨报」，选择查看待办摘要的时间。

本地工作区无需注册。待办、记忆和报告保存在设备上，模型密钥保存在系统钥匙串。首次向所选模型服务发送内容时会征求同意，可在「隐私与权限」撤回。使用模型服务可能产生供应商费用。

## App Review Notes

No ToWork sign-in or in-app purchase is required. Local tasks, schedule, reports and the memory library can be reviewed without a model account. AI actions use a provider account configured by the user in Settings → 模型与额度.

With a provider configured, hold the voice input on the home screen and say “明天下午三点交初稿” (submit the draft tomorrow at 3 pm). Slide to 编辑 to revise the transcript, then send. Check the task and due time in 待办, exit, and reopen the app to see the saved item. For cross-chat memory, say “记住，我的周报先列风险” (remember that my weekly reports start with risks). Inspect the preference under 记忆 and start a new conversation. The memory library supports editing, deletion and pausing new memories.

On iPhone and iPad, speech is transcribed on device. On Mac, dictation can use the system speech recognizer. Mac users can choose a time in 设置 → 每日晨报 and enable notifications for a scheduled local task digest. Users on all three platforms can generate a weekly or monthly snapshot under 报告 and request an AI summary.

On first AI content transfer, a native consent dialog identifies the recipient. Consent can be revoked under 设置 → 隐私与权限. Model credentials are stored in the system Keychain. App Store builds show Note and TestFlight builds show Prelude.

## TestFlight 测试重点

检查首次启动、本地待办持久化、模型连接、首次数据发送授权与撤回、录音后编辑、通知授权。通过 TestFlight 反馈机型、iOS 版本和复现步骤。请勿附上密钥或真实工作记录。

## 分发与验证

内部组 Prelude 通过 Apple 邮件邀请团队账号。外部组 Prelude Preview 的公开链接限 50 人，每个平台的首个构建均须通过外部 Beta 审核。[公开测试邀请](https://testflight.apple.com/join/ZBVgPF3x)

2026-11-19，1.1.11 (16) 已通过项目质量门（1186 项测试）。iPhone 模拟器使用临时 DeepSeek 账户通过真实待办操作回归。iPhone、iPad 和 Mac 的商店截屏来自独立样例数据库。

iOS 和 iPadOS 共用一个构建。Mac App Store 的原生构建使用 `--dart-define=TOWORK_MAC_APP_STORE=true`，归档入口均为 `lib/main.dart`。在集成测试后重新生成 release 构建配置再归档。麦克风使用说明保留在 Info.plist，Mac 的 App Sandbox 使用 `com.apple.security.device.audio-input`。

归档 Mac 商店包时，通过 `TOWORK_MAC_DEVELOPMENT_TEAM=6SFGHFY924` 和 `TOWORK_MAC_SIGN_IDENTITY='Apple Development'` 为 Runner 指定签名身份。全局覆盖 `CODE_SIGN_IDENTITY` 会给 SwiftPM 的纯资源包附上开发签名，导致 App Store Connect 处理失败（90284）。

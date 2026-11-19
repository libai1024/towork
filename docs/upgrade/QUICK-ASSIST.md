# Android 快捷唤醒

在 ToWork 的设置中打开「快捷唤醒」。点击「现在试一下」可以打开半屏面板，点上方空白或关闭按钮返回原应用。拖动面板顶部可展开、收起和关闭。

## 默认助手

点击「设为默认助手应用」，在系统的助手或默认应用页面选择 ToWork。返回设置页会刷新当前状态。系统允许时，助手手势和助手按键会打开快问。Android 的默认助手角色和实际手势入口由设备系统提供。[Android 助手角色](https://developer.android.com/reference/android/app/role/RoleManager#ROLE_ASSISTANT)

华为机型的菜单名称以实际系统为准，可在设置中搜索「默认应用」「助手」。记录设备型号、区域和完整系统版本后再验收。用户已确认目标机型为 Mate 80 Pro。安装本项目 APK 需要设备提供 Android 应用兼容环境。

## 控制中心和桌面

从 1.1.1 起，应用通过 Android `CREATE_SHORTCUT` 注册「ToWork 快问」与「ToWork 语音快问」两个固定入口。支持这个协议的系统快捷启动菜单、桌面和第三方快捷工具可以枚举它们。选择后会获得带名称、图标和明确目标的启动信息，执行时直接打开半屏面板。语音快问沿用录音授权并自动开始听写。[Android 自定义快捷方式入口](https://developer.android.com/develop/ui/compose/system/shortcuts/creating-shortcuts#custom)

ToWork「设置 → 快捷唤醒」提供两项分别添加到桌面的操作。系统确认后才会固定，取消时可稍后重试。

下拉控制中心或快捷设置，进入编辑，添加「快问」。长按 ToWork 桌面图标可以选择「快问」或「语音快问」。支持固定快捷方式的桌面，也可在 ToWork 设置中点击「添加『快问』到桌面」，然后完成系统确认。[Android 快捷设置](https://developer.android.com/develop/ui/views/quicksettings-tiles)

在其他应用中选中文字，打开文本操作菜单或分享，选择「问 ToWork」。文字最多预填 4000 字，确认后点击发送。语音快问会直接开始听写，并沿用应用的录音授权和自动发送取消窗口。

## EMUI 15 智控键双触

2026-11-16 在用户 Mate 80 Pro（SGT-LX9，SGT-L29 15.0.0.167(C636E1R1P3)，API 31）上核对了智控组件 `com.huawei.hwquickaccessmenu` 1.0.1.423。系统的 `hw_quickaccessmenu_config.json` 中 `preset.HighValueService` 决定可展开的应用分组，同时双触列表会读取华为桌面已固定的快捷方式。高德、百度包含在该系统列表中，ToWork 通过桌面固定入口出现在列表里。

1. 打开 ToWork「设置 → 快捷唤醒」。
2. 点击「添加『快问』到桌面」或「添加『语音快问』到桌面」，在系统提示中确认添加。需要两项时分别添加。
3. 在系统设置搜索「智控键」，打开「双触」，搜索 ToWork。
4. 选择单独列出的「ToWork 快问」或「ToWork 语音快问」。

真机已显示上述两个固定功能，用户已确认选择「ToWork 快问」后实际双触可弹出半屏。语音入口的硬件双触结果按 [验证记录](VERIFICATION.md) 更新。系统分组由厂商配置决定，桌面固定入口应保留供系统枚举。

## 面板动效

从 1.1.3+6 起，卡片以 360ms 从屏幕底部全宽垂直滑入，卡片外完全透明。关闭时以 240ms 向下滑出。拖动顶部可扩大、收回半屏或关闭，键盘弹出时面板位于键盘上方，离场仍移动到屏幕底部之外。开启系统减少动画后立即切换显示状态。后台保留的面板重新唤起时也会播放滑入，已有桌面固定入口会在应用打开时更新启动标记。

## EMUI 15 手机端检测

用户暂时无法连接 USB 时，可安装并打开一次 [ToWork 入口检测 APK](https://zhaozhaoyue.top/dl/towork/android/towork-shortcut-probe-1.apk)。检测包使用独立包名 `com.towork.shortcutprobe`，注册「静态快问」「静态语音」「动态快问」「动态语音」四个入口，以及两个传统 CREATE_SHORTCUT 提供者。四项入口均通过同一转发 Activity 打开已安装 ToWork 的对应半屏。

在系统「双触」菜单搜索「ToWork 入口检测」，截图记录可展开的功能。如果仍只有应用入口，在检测包中点击「选择系统组件并导出」，优先选择快捷菜单或智控组件，保存 ZIP 后发回开发对话。ZIP 包含所选系统组件 APK、组件版本、机型/系统版本、ToWork 版本和检测入口数量，供分析菜单的枚举规则。

检测包使用 `QUERY_ALL_PACKAGES` 定位系统菜单组件，通过系统文件保存器写入用户选择的文件。构建入口为 `python3 tool/shortcut_probe/build.py`，依赖本地 Android SDK 36/build-tools 36.0.0 与 JDK，复用项目图标。检测结束可卸载「ToWork 入口检测」。目标真机通过 USB 接入后，已按上节步骤完成入口定位和快问双触验证。

## 后台和会话

生成中关闭面板后，当前回复继续写入本地会话。生成完成即关闭后台窗口，超过三分钟会取消并退出。重新唤起仍在生成的面板会继续当前对话。空闲重新唤起会清空旧草稿并开始新对话。「在 ToWork 中打开」会选择当前会话，也可把模型设置等去向交给主应用。

系统冻结或结束应用进程会中断生成。华为手机可在系统的应用启动管理和电池设置中检查 ToWork 的后台权限，设置项与效果需在目标设备验收。

## 电源键和指关节

ToWork 提供 Android 默认助手、快捷设置、桌面快捷方式、分享和划词入口。电源键双击与长按由系统管理。华为文档中的电源键唤醒对应系统智慧语音，实际设备可用入口以其系统设置为准。指关节快捷操作也需在目标机型上单独核对。[华为手势与快捷操作](https://consumer.huawei.com/cn/support/content/zh-cn16001652/)

## 开发验证

普通回归覆盖预填、键盘发送、后台收尾、再次唤起、交接和入口设置。模拟器的真实 Activity 与双引擎使用专用入口复跑，模型为定时脚本，数据库为独立的 `upgrade-assist-fixture.sqlite`。

```sh
flutter test test/quick_assist_panel_test.dart test/quick_assist_settings_page_test.dart test/app/engine_sync_test.dart test/data/platform/assist_channel_test.dart
flutter build apk --debug --target integration_test/fixtures/quick_assist_app.dart
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.towork.towork/.MainActivity
adb shell am start -a com.towork.towork.action.QUICK_ASK
adb shell cmd role add-role-holder android.app.role.ASSISTANT com.towork.towork
adb shell input keyevent KEYCODE_ASSIST
adb shell am start -a android.intent.action.SEND -t text/plain -n com.towork.towork/.AssistActivity --es android.intent.extra.TEXT 'shared fixture'
adb shell am start -a android.intent.action.PROCESS_TEXT -t text/plain -n com.towork.towork/.AssistActivity --es android.intent.extra.PROCESS_TEXT 'selected fixture'
```

依次检查键盘上方发送、默认助手、预填、生成中关闭后主应用读取完整回复、带会话打开、设置三项按钮。测试完重新构建 `lib/main.dart` 并覆盖安装恢复普通应用。各项本轮结果见 [验证记录](VERIFICATION.md)。

2026-11-15 在 `emulator-5556`、API 36、arm64 上已通过分享和划词预填、默认助手 `KEYCODE_ASSIST`、输入发送、生成中关闭后主应用读取完整回复、生成中带会话打开、系统助手设置往返与状态刷新、桌面固定请求、设置页启动面板。模型使用上述定时脚本。此轮还修复了首次建库竞争、刷新失败重试、空闲重新唤起残留草稿，以及交接后侧栏遮住会话的问题。

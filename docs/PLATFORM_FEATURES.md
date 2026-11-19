# ToWork 双端功能分类文档

> 版本：v1.1（功能范围同步）
> 日期：2026-09-23
> 本文云端 API、同步和账户条款属于商业版。免费版采用 独立平台调研与执行边界，不能将本文历史插件信息或服务器能力直接套用于本地版。
> 功能依据：REQUIREMENTS.md v0.5。首版为 Android + macOS，本文 iOS 条目保留为后续参考。用户 API Key、手动模型测试与用户名云端同步按主需求 F7/F8 实施。
> 平台技术调研仍沿用 2026-09-21 版本，本轮未重新核验插件、系统限制或分发方案。
> 本文档回答一个问题：**每个功能在手机端和桌面端分别怎么落地、用什么方案、有什么差异。**

---

## 1. 分类原则

1. **核心数据与业务逻辑双端完全一致**（同一套云端 API + 本地 Drift 缓存），差异只在**输入方式、系统能力、交互形态**。
2. **平台各展所长**：
   - 手机端 = 随身速记（语音、拍照、分享接收、小组件、提醒触达）
   - 桌面端 = 深度工作（全局唤起、键盘流、拖拽粘贴截图、大屏可视化、菜单栏常驻）
3. **凡是要"定时"的事，用系统持有的本地通知（预排期），不赌后台任务；凡是要"App 被杀后仍能干活"的事，交给服务端。**
4. 平台能力有硬限制时，**降级设计优先于放弃功能**（每节标注降级方案）。

---

## 2. 功能矩阵总表

图例：✅ 完整支持｜⚠️ 支持但有平台限制（见详情）｜❌ 不支持｜— 不适用

| 功能模块 | 子功能 | 手机端 (iOS/Android) | macOS 桌面端 |
|---|---|---|---|
| **F1 对话输入** | 文字输入 | ✅ | ✅ |
| | 语音输入 | ⚠️ 短句级（系统 ASR，Android 无 GMS 设备需降级） | ⚠️ 短句级（需开 Siri/听写） |
| | 图片-拍照 | ✅ image_picker | — |
| | 图片-相册 | ✅ image_picker | ✅ 文件选择 |
| | 图片-截图粘贴 | ⚠️ 剪贴板（iOS 有粘贴提示） | ✅ Cmd+V + 拖拽入窗（体验最好） |
| | 接收系统分享 | ⚠️ 需 iOS Share Extension 原生配置 | — |
| | 全局快捷键唤起 | — | ✅ hotkey_manager |
| | 菜单栏快速记录 | — | ✅ tray_manager |
| | AI 流式对话 | ✅ WebSocket/SSE | ✅ |
| **F2 记忆库** | 查看/编辑/删除/清空 | ✅ | ✅ |
| | 免记忆开关 | ✅ | ✅ |
| **F3 Todo 管理** | 列表/看板/编辑/拖拽 | ✅ | ✅（键盘快捷键增强） |
| | 截止提醒通知 | ⚠️ 本地通知（Android 国产 ROM 需白名单引导） | ✅ 本地通知 |
| | 每日晨报通知 | ⚠️ 同上（预排期实现） | ✅ |
| **F4 可视化** | 热力图/日历/趋势 | ✅ 竖屏简化布局 | ✅ 大屏完整布局（主战场） |
| **F5 报告** | 定时生成 | ✅ 服务端定时生成，双端一致 | ✅ 同左 |
| | 报告就绪通知 | ⚠️ 需一次同步触发（见 §3.3） | ✅ |
| | 导出 PDF/Markdown | ✅ share_plus 分享出去 | ✅ 存文件/打印 |
| | 周总结海报 | ✅ AI 总结 + 可选模板，定时/手动，保存图片/分享 | ✅ 同左 |
| **F6 核心数据** | 表格浏览/编辑 | ✅ 移动端表格简化视图 | ✅ 类 Excel 完整表格（主战场） |
| | AI 写入确认/回滚 | ✅ 待办与数据表统一三档 | ✅ 同左 |
| | 截图分析上传 | ✅ 拍照/相册 | ✅ 粘贴/拖拽 |
| **F7 AI 配置** | 模型切换/额度面板 | ✅ | ✅ |
| **平台专属** | 桌面小组件（今日待办） | ⚠️ 需写原生 Widget（v2） | — |
| | 开机自启 | — | ✅ launch_at_startup |
| | 菜单栏常驻/隐藏 Dock | — | ✅ LSUIElement |
| | 离线缓存/同步 | ✅ Drift | ✅ Drift |

---

## 3. 手机端（iOS / Android）功能详情

### 3.1 语音输入（F1）

- **方案**：`speech_to_text` 插件（封装 iOS SFSpeechRecognizer / Android SpeechRecognizer），支持 `zh_CN`。
- **定位约束**：以短句指令为主，长语音转写不在首版承诺内。默认交互为「主动开始录音 → 实时转写 → 结束录音自动发送 Agent」，支持取消及文字输入，遵循需求 F1.1。系统自动结束、转写失败等具体行为在目标设备上验证。
- **降级链**：ASR 初始化失败（国产无 GMS Android）→ 静默退化为键盘输入，UI 不报错打扰。
- **权限**：iOS 需语音+麦克风两项 Usage Description；Android 需 `RECORD_AUDIO` + Manifest 声明 RecognitionService queries。

### 3.2 图片输入（F1 / F6.3）

- 拍照/相册：`image_picker`（成熟，Android 13+ 免存储权限）。
- 接收系统分享（把券商截图从相册/其他 App 直接分享到 ToWork）：`receive_sharing_intent` 社区 fork。
  - ⚠️ iOS 必须配原生 **Share Extension**（独立签名 + App Groups 传数据），配置繁琐，**排期建议放 M4**；v1 先支持 App 内拍照/选相册。
  - Share Extension 保持极轻：只把文件拷进 App Group 容器并拉起主 App，识别交给主 App + AI。

### 3.3 通知与定时报告触达（F3.4 / F5）

- **方案**：`flutter_local_notifications`，全部走**预排期本地通知**（通知由系统持有，App 被杀也能响）。
- **截止提醒**：创建/修改 Todo 时即在本地排期通知；同步后统一重排。
- **周报/月报触达链路**（对需求 F5 的实现细化）：
  1. 服务端定时生成周报及周总结海报（每周）、月报（每月），同时支持手动生成；
  2. 客户端在前台或 iOS 后台刷新（BGTask）时同步到新报告；
  3. 同步成功后本地调度通知「你的上周周报已生成」。
  - ⚠️ 已知限制：若用户长期不打开 App，iOS 上不保证准时触达（BGTaskScheduler 调度时机由系统决定）。这是"本地通知"决策的固有代价，届时若要根治再升级为远程推送。
- **iOS 注意**：待处理通知上限 64 条，排期需裁剪（只排未来 30 天）。
- **Android 注意**：13+ 需运行时通知权限；14+ 精确闹钟默认不授予，需引导用户开启；国产 ROM 杀后台 → 设置内提供「通知不生效？」自诊断入口（跳电池优化白名单）。

### 3.4 桌面小组件（v2，P2）

- **方案**：`home_widget` 传数据 + 原生写 Widget UI（iOS SwiftUI WidgetKit / Android Glance）。
- 后续首个小组件版本范围：**只读展示今日待办 Top N + 点击深链进 App**；勾选完成等交互再后置，小组件整体不计入当前首版。
- 数据出口统一收口：SyncService 任何写操作后触发 widget 刷新。

### 3.5 其他

- 剪贴板/分享/触觉反馈：Flutter 内置 + `share_plus`，成熟无坑（iPad 分享必须传锚点参数，否则崩溃——经典坑）。
- 离线：`Drift`（SQLite）+ 自研轻量增量同步（软删除 + updatedAt 增量拉 + 失败入队重试）。不引入 PowerSync 等重型引擎。

---

## 4. macOS 桌面端功能详情

### 4.1 全局唤起 + 菜单栏（F1.1，桌面端核心体验）

- **全局快捷键**：`hotkey_manager`（Carbon RegisterEventHotKey 封装）——**不需要辅助功能权限**，沙盒可用，权限成本为零。默认 `Cmd+Shift+Space`，设置里可自定义（HotKeyRecorder）。
- **唤起动线**：热键 → 显示窗口 + 置顶 + 激活 + 聚焦输入框（`window_manager` 的 show/focus/setAlwaysOnTop）。
- **菜单栏常驻**：`tray_manager`（NSStatusItem）+ 点击图标在下方弹出无边框快速记录窗（自己定位 borderless 窗口，注意 macOS 坐标系原点在左下、多屏处理）。
- **失焦自动隐藏**：监听 `onWindowBlur` + 防抖（避免权限弹窗误触发隐藏）。

### 4.2 窗口架构决策：单窗口

- ⚠️ **不依赖多窗口**：Flutter 官方 multi-window 截至 2026.9 未进稳定版；社区 `desktop_multi_window` 每窗口独立引擎、通信繁琐。
- 设计为：**主窗口 + 快速记录弹窗共用同一个窗口**（显隐 + 尺寸切换），体验等效 Spotlight，零风险。

### 4.3 语音输入（F1）

- 同样用 `speech_to_text`（官方支持 macOS，底层 SFSpeechRecognizer）。
- ⚠️ macOS 特有前提：用户需开启 Siri/听写，否则 `isAvailable` 返回 false——首次使用检测并引导跳转系统设置。
- 权限：Info.plist 双 Usage Description + 沙盒 entitlement `com.apple.security.device.audio-input`。

### 4.4 截图粘贴与拖拽（F6.3 主输入方式）

桌面端是截图分析的最佳输入端：

- **Cmd+V 粘贴**：`super_clipboard` 探测剪贴板 PNG/TIFF（macOS 截图工具写入格式），有图则作为附件插入输入框。
- **拖拽入窗**：`desktop_drop` 接受图片/文件拖入。
- ⚠️ macOS 剪贴板无变更通知 API，「截图后自动提示」需轮询 `NSPasteboard.changeCount`——作为增强项，非 P0。

### 4.5 常驻形态与自启

- 默认 **agent 模式**：`LSUIElement = YES`（无 Dock 图标）+ 菜单栏图标 + 全局热键。
- **开机自启**：`launch_at_startup`，设置里提供开关；macOS 13+ 登录项由系统管理，UI 如实反映状态。
- 「显示 Dock 图标」高级选项需要约 10 行原生桥接（`NSApp.setActivationPolicy`），是全项目唯一预期要写的原生代码。

### 4.6 分发策略

- **优先 dmg + Developer ID 签名 + 公证（notarytool）**直接分发；自动更新用 Sparkle（`auto_updater`）。
- App Store 可作为补充渠道：本项目 P0 功能（热键/菜单栏/通知/语音/拖拽）在沙盒内全部可行；但**辅助功能（AX）API 沙盒永久封死**——架构上不引入任何 AX 依赖，保留双轨分发自由。

### 4.7 通知（F3.4 / F5）

- `flutter_local_notifications` macOS 支持成熟。差异点：macOS 无后台 isolate，通知点击是冷启动唤起，需在 `getNotificationAppLaunchDetails` 里做路由恢复（跳到对应 Todo/报告）。
- 因为桌面端通常开机常驻，定时报告触达在桌面端基本无延迟问题。

---

## 5. 双端共享层（一套代码）

| 层 | 内容 |
|---|---|
| 业务逻辑 | 全部状态管理（Riverpod）、API 客户端、同步服务、数据模型 |
| 本地存储 | Drift（注意 2026 迁移点：`sqlite3_flutter_libs` 已废弃，直接用 `sqlite3` v3 + Dart Native Assets） |
| 网络 | dio / WebSocket（`web_socket_channel`），AI 流式输出双端一致 |
| UI 主体 | 对话、Todo 列表/看板、图表（fl_chart）、数据表格、设置页 |
| 差异出口 | 用平台适配层收口：`PlatformAdapter`（唤起方式、输入面板、通知调度） |

---

## 6. 调研引发的需求文档修订建议

以下是对 REQUIREMENTS.md 的细化（不冲突，属实现层面落实）：

| # | 条目 | 结论 |
|---|---|---|
| 1 | 语音输入定位 | **默认语音短句指令，结束录音自动发送，可取消**；长语音转写留待后续评估 |
| 2 | 定时报告触达 | 实现链路 = 服务端定时生成 → 客户端同步 → 本地通知；iOS 长期不打开 App 时不保证准时 |
| 3 | iOS 接收分享 | 排期 M4（需原生 Share Extension），v1 先 App 内选图 |
| 4 | 桌面端窗口 | 单窗口 + 显隐架构，不用多窗口 |
| 5 | 分发 | macOS 优先公证 dmg；架构禁用 AX 依赖 |
| 6 | 小组件 | 列为 v2 / P2，只读展示起步 |

---

## 7. 插件选型清单

| 能力 | 插件 | 平台 | 成熟度 |
|---|---|---|---|
| 语音识别 | `speech_to_text` | 全部 | ⚠️ 短句级 |
| 本地通知 | `flutter_local_notifications` | 全部 | ✅（Android 需引导） |
| 拍照/相册 | `image_picker` | 手机 | ✅ |
| 接收分享 | `receive_sharing_intent`（fork） | 手机 | ⚠️ |
| 小组件 | `home_widget` + 原生 Widget | 手机 | ⚠️ v2 |
| 全局热键 | `hotkey_manager` | 桌面 | ✅ |
| 菜单栏 | `tray_manager` | 桌面 | ✅ |
| 窗口管理 | `window_manager` | 桌面 | ✅ |
| 剪贴板图片 | `super_clipboard` | 桌面 | ✅ |
| 拖拽入窗 | `desktop_drop` | 桌面 | ✅ |
| 开机自启 | `launch_at_startup` | 桌面 | ✅ |
| 数据库 | `drift` + `sqlite3` v3 | 全部 | ✅ |
| 网络/WS | `dio` + `web_socket_channel` | 全部 | ✅ |
| 分享导出 | `share_plus` | 手机为主 | ✅ |
| 图表 | `fl_chart`（热力图自绘） | 全部 | ✅ |

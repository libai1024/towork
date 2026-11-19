---
name: ToWork
description: 暖纸与墨色承载工作内容，局部通透控件保持对话连续。
colors:
  brand: "#141413"
  brand-dark: "#FAF9F5"
  accent: "#C15F3C"
  accent-dark: "#D97757"
  bg-ground: "#FAF9F5"
  bg-ground-dark: "#1F1E1D"
  bg-primary: "#FFFFFF"
  bg-primary-dark: "#2A2A28"
  bg-secondary: "#F5F4EE"
  bg-secondary-dark: "#242422"
  bg-tertiary: "#F0EEE6"
  bg-tertiary-dark: "#30302E"
  label-secondary: "#5E5D59"
  label-secondary-dark: "#B8B5A9"
  separator: "#E8E6DC"
  separator-dark: "#3D3D3A"
typography:
  display:
    fontFamily: "serif, Noto Serif CJK SC, Source Han Serif SC, Songti SC, STSong, Georgia"
    fontSize: "21px"
    fontWeight: 400
    lineHeight: "28px"
    letterSpacing: "-0.2px"
  display-small:
    fontFamily: "serif, Noto Serif CJK SC, Source Han Serif SC, Songti SC, STSong, Georgia"
    fontSize: "18px"
    fontWeight: 400
    lineHeight: "24px"
    letterSpacing: "-0.2px"
  body:
    fontFamily: "Inter, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: "20px"
  chat-body:
    fontFamily: "Inter, sans-serif"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: "23px"
  chat-heading-1:
    fontFamily: "Inter, sans-serif"
    fontSize: "18px"
    fontWeight: 600
    lineHeight: "26px"
  chat-heading-2:
    fontFamily: "Inter, sans-serif"
    fontSize: "17px"
    fontWeight: 600
    lineHeight: "25px"
  chat-heading-3:
    fontFamily: "Inter, sans-serif"
    fontSize: "16px"
    fontWeight: 600
    lineHeight: "24px"
  chat-code:
    fontFamily: "monospace, Menlo, Courier New"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: "20px"
  chat-inline-code:
    fontFamily: "monospace, Menlo, Courier New"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: "18px"
  todo-title:
    fontFamily: "Inter, sans-serif"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: "20px"
  chat-input:
    fontFamily: "Inter, sans-serif"
    fontSize: "15.5px"
    fontWeight: 400
    lineHeight: "22px"
  menu-label:
    fontFamily: "Inter, sans-serif"
    fontSize: "14.5px"
    fontWeight: 400
    lineHeight: "21px"
  model-label:
    fontFamily: "Inter, sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: "16px"
  footnote:
    fontFamily: "Inter, sans-serif"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: "18px"
  caption:
    fontFamily: "Inter, sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: "16px"
rounded:
  quote: "8px"
  code-block: "12px"
  todo-card: "12px"
  field: "16px"
  menu: "20px"
  composer: "24px"
  full: "999px"
spacing:
  control-inset: "8px"
  reply-block-gap: "8px"
  page-inset: "16px"
  reading-inset: "20px"
  reply-list-indent: "20px"
  desktop-reading-inset: "28px"
components:
  button-primary:
    backgroundColor: "{colors.brand}"
    textColor: "{colors.bg-primary}"
    rounded: "{rounded.full}"
    width: "44px"
    height: "44px"
  button-primary-mobile:
    backgroundColor: "{colors.brand}"
    textColor: "{colors.bg-primary}"
    rounded: "{rounded.full}"
    width: "48px"
    height: "48px"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.brand}"
    rounded: "{rounded.full}"
    width: "44px"
    height: "44px"
  button-ghost-mobile:
    backgroundColor: "transparent"
    textColor: "{colors.brand}"
    rounded: "{rounded.full}"
    width: "48px"
    height: "48px"
  header-controls:
    textColor: "{colors.brand}"
    rounded: "{rounded.composer}"
  chat-composer:
    textColor: "{colors.brand}"
    typography: "{typography.chat-input}"
    rounded: "{rounded.composer}"
    padding: "8px"
  model-menu:
    textColor: "{colors.brand}"
    typography: "{typography.model-label}"
    rounded: "14px"
    padding: "4px"
    width: "208px"
    maxHeight: "300px"
    minRowHeight: "36px"
    rowPadding: "4px 6px"
    iconGap: "6px"
  user-message:
    backgroundColor: "{colors.bg-tertiary}"
    textColor: "{colors.brand}"
    typography: "{typography.chat-body}"
    rounded: "{rounded.menu}"
    padding: "10px 14px"
  ai-response:
    textColor: "{colors.brand}"
    typography: "{typography.chat-body}"
  ai-code-block:
    backgroundColor: "{colors.bg-secondary}"
    textColor: "{colors.brand}"
    typography: "{typography.chat-code}"
    rounded: "{rounded.code-block}"
  ai-todo-card:
    backgroundColor: "{colors.bg-primary}"
    textColor: "{colors.brand}"
    typography: "{typography.footnote}"
    rounded: "{rounded.todo-card}"
    padding: "4px 2px"
  ai-todo-panel:
    backgroundColor: "{colors.bg-primary}"
    textColor: "{colors.brand}"
    typography: "{typography.footnote}"
    rounded: "{rounded.todo-card}"
    padding: "6px 8px"
  ai-question-card:
    backgroundColor: "transparent"
    textColor: "{colors.brand}"
    typography: "{typography.body}"
    padding: "0"
  todo-checkbox:
    rounded: "{rounded.full}"
    width: "48px"
    height: "48px"
  agent-review:
    backgroundColor: "{colors.bg-primary}"
    textColor: "{colors.brand}"
    rounded: "{rounded.todo-card}"
    padding: "6px 8px"
  agent-quiet:
    textColor: "{colors.label-secondary}"
    typography: "{typography.footnote}"
    padding: "2px 4px"
  toast:
    backgroundColor: "{colors.brand}"
    textColor: "{colors.bg-ground}"
    typography: "{typography.body}"
    rounded: "{rounded.full}"
    padding: "4px 16px"
  chip:
    backgroundColor: "{colors.bg-tertiary}"
    textColor: "{colors.label-secondary}"
    typography: "{typography.footnote}"
    rounded: "{rounded.full}"
    padding: "7px 13px"
---

# ToWork 界面规范

## Overview

**Creative North Star — 暖纸、墨色、局部通透**

暖纸或深灰阅读面承载对话和工作内容，文字、间距与轻底色组织层级。浮动操作组、输入区和模型菜单采用局部通透材质，顶部背景透明，滚动内容从控件下方经过。

2026-11-16 的主界面以 Claude iPhone 公开参考校准阅读密度，采用 ToWork 自有「对话 / 工作 / 资料」入口。当前字体数值来自参考截图与运行画面的视觉校准，Claude 专有字体及源码精确字号仍待可核实证据。主界面实施范围、全应用迁移阶段与发布验收记录见计划。UI 提升计划

本文件合并已实现的聊天首页、阅读区、输入区、顶部操作与模型身份规则。工作、资料通过已有路由进入，完整三分支状态保持安排在 P3。既有侧栏和搜索继续以用户提供的 Kimi iOS 参考为依据，业务规范和快问架构沿用对应文档。

**Key Characteristics**

- 暖纸与墨色形成稳定阅读层级。
- 字号按语义角色管理，系统与应用缩放共同生效。
- 透明顶部背景与局部模糊控件覆盖实际滚动内容。
- 模型身份使用来源明确的品牌素材。

## Colors

亮色使用暖纸背景、墨色主文字与低饱和辅助色。深色使用暖深灰背景与浅色文字。前置 token 摘录自 `AppColors`，带 `-dark` 后缀的项对应深色主题，完整语义色与分类色仍由该类管理。[颜色源码](lib/theme/app_colors.dart)

### Primary

`brand` 承载主要文字和发送、停止等主操作，主题切换时使用对应深色值。`accent` 沿用既有陶土强调色，供应商图标统一使用黑白处理。

### Neutral

`bg-ground` 用于页面，`bg-primary` 与 `bg-tertiary` 分别提供亮色和深色玻璃材质基色，`bg-secondary` 区分侧栏。`label-secondary` 承载次要操作与辅助文字，`separator` 支持需要分界的内容。用户消息使用 `fill1`，其当前值与对应主题的 `bg-tertiary` 一致。

**The Theme Rule.** 控件颜色从当前主题的 `AppColors` 获取，品牌素材通过 `BrandLogo` 渲染。

## 文案

默认用户是专业人士。直接呈现结果、状态与可执行动作，按需展开详细说明。

- 禁止用中点（U+00B7）及相似圆点作装饰或分隔。元数据用空格，分类路径用斜线，长内容换行。
- 删除重复标题、落款、永久成功提示、按钮功能复述与泛泛建议。错误恢复、权限影响和待确认变更保留必要信息。
- AI 回复省略寒暄、基础教学和重复总结。交互卡片已展示的信息只在需要判断时补充。
- 用户原文与历史内容原样保存。静态文案由 `test/ui_copy_style_test.dart` 检查，AI 与报告共用 `AgentPrompt.responseStyle`。

## Typography

西文与数字使用随包 Inter 400/500/600/700，中文依赖平台回落。首页问候与半屏短标题沿用衬线回落链。前置 `px` 对应 Flutter 逻辑像素，数值适用于系统与应用缩放均为 1.0 的基准。系统字号与应用内字号叠加。[字阶源码](lib/theme/app_text_styles.dart)

| Token | 当前用途 |
| --- | --- |
| `display` | 首页个性化问候 |
| `display-small` | 半屏问候与短空态标题 |
| `body` | 通用正文与列表主标题 |
| `chat-body` | 用户消息、助手正文与流式回复 |
| `chat-heading-1` / `chat-heading-2` / `chat-heading-3` | Markdown 一至三级标题，四至六级标题使用正文尺寸与 600 字重 |
| `chat-code` / `chat-inline-code` | 可横向滚动的代码块与段落内代码 |
| `todo-title` | 业务列表与看板的待办标题 |
| `chat-input` | 输入文字、占位提示与内联语音文案 |
| `menu-label` | 模型身份行 |
| `model-label` | 输入区下排的供应商名称 |
| `footnote` | 列表副标题、内容筛选标签、AI 卡片正文与操作文字 |
| `caption` | AI 卡片日期、状态、数量、分组及表头 |

**The Reading Rule.** 用户消息与助手正文共用 `AppTextStyles.chatBody`，输入区文字共用 `AppTextStyles.chatInput`。

## Layout

- 手机首页以居中的 WorkMark 和问候语建立入口，标记与问候间隔 20 逻辑像素。输入区水平留白使用 `page-inset`，贴近底部安全区并保留 10 逻辑像素间距。待办、资料和设置从侧栏进入。
- 对话阅读栏最大宽度为 760 逻辑像素，手机与桌面内边距分别使用 `reading-inset` 与 `desktop-reading-inset`。顶部操作覆盖在同一个 Stack 中，消息初始上留白为 76 逻辑像素。输入区高度由 `ChatComposerLayout` 测量，列表底部留白等于实际输入区高度加 16，末条内容可滚至完整可见。
- 桌面空首页内容最大宽度为 768 逻辑像素，问候下方保留 40 逻辑像素再呈现输入区。窗口变窄时内容按可用宽度收缩。
- Desktop breakpoint: 900 logical px. Persistent sidebar 276px; collapsed rail 60px. Desktop feature grid remains exactly 3 columns and 2 rows; mobile uses vertical icon-and-label entries matching the supplied sidebar. Categories immediately follow; recent conversation groups occupy remaining scroll space; glass search and account anchored below. The new-conversation action is aligned to the right edge of the sidebar header on both platforms.

- Mobile sidebar reveal follows the supplied Kimi sliding-page reference: the sidebar stays on the bottom layer while the full-width main page translates right by 85% of the viewport (maximum 380px, at least 48px of the page remains visible). The page keeps its layout and draft, with 36px continuous corners, a fine outline, soft leading shadow and a light wash. No dark scrim covers the sidebar. Edge swipes track the finger; swiping left, tapping the exposed page or Android Back closes it. Vertical scrolling and category long presses remain independent. Reduced motion skips the settling animation. Android system bars are transparent, with safe areas protecting controls.

- Edge-to-edge applies to the entire Android window, including punch-hole / cutout regions. Native Android uses `ALWAYS` on API 30+ and `SHORT_EDGES` on API 28–29; Flutter backgrounds paint through the status and navigation areas. `AppSystemUi` supplies the same transparent bars, transparent navigation divider and theme-aware icons to custom pages and Material app bars. No separate status/footer color strip or system contrast scrim. Safe insets protect controls, and keyboard insets keep input controls visible; do not wrap the page background in a SafeArea or hard-code status-bar heights. See [Android cutout guidance](https://developer.android.com/develop/ui/views/layout/display-cutout).

- Desktop board: three simultaneous columns above 620px available content width; phone board paginates.

## Elevation & Depth

顶部栏背景保持透明，菜单按钮与右侧操作组分别保留局部玻璃材质。控件亮色 tint 透明度为 0.62，深色为 0.45，模糊 sigma 为 18，关闭投影。消息真实地从操作组下方滚过，初始留白由阅读栏提供。

输入区 tint 透明度为亮色 0.84、深色 0.80，模糊 sigma 为 16。模型菜单沿用共享玻璃默认值，亮色 0.92、深色 0.88，模糊 sigma 为 12。共享悬浮投影分为环境层与近接层，具体值记录于 `.impeccable/design.json`。连续曲率由 `RoundedSuperellipseBorder` 与 `ClipRSuperellipse` 提供。[玻璃组件](lib/core/widgets/glass_surface.dart)

高对比度或 `accessibleNavigation` 生效时，玻璃使用实色、清晰边线并关闭模糊与投影。降低动态效果由支持该设置的共享控件关闭过渡。Flutter 当前通过自身材质与模糊实现层级。

**The Overlay Rule.** 顶部透明区域允许正文持续滚动，局部模糊限定在可交互控件边界内。

AI 待办结果与 Agent 审批使用 `bg-primary` 实体色和细分界线。代码块使用 `bg-secondary`，引用使用 `fill1`，正文保持连续阅读面。

## Shapes

输入区与顶部操作组使用 `composer` 连续曲率，模型菜单采用 14 逻辑像素圆角，用户消息使用 `menu` 圆角。圆形操作与胶囊使用 `full`，模型触发器使用 `field`。常规业务控件继续使用 `AppRadii`，侧栏揭示页面沿用既有连续曲率。[圆角源码](lib/theme/app_radii.dart)

## Components

模型账户以设置行展示服务商、地区和模型。服务商名称旁只显示 `plan` 或 `api`；自定义接口也标记为 `api`。预设模型按需展开，自定义模型 ID、接口地址和密钥使用固定标签的输入行。密钥始终遮蔽，连接错误和操作结果在触发后显示。

提问按回复正文左缘排版，题干只显示一次。选项共用聊天底色，左列显示单选字母或多选框，长答案沿文字列换行。单选点按即发送，多选勾选后点「发送」。下方的「其他回答」可展开补充输入。

模型账户面板从屏幕底部纵向升起，高度随内容收合，上限为半屏。末行到安全区留 6 个逻辑像素。键盘弹出时面板贴在键盘上方，表单超高时滚动，标题和保存按钮固定。配置行左侧为字段名，右侧为值，点击进入编辑。窄行或大字号时标签移至上方。关闭按钮、点击外部、系统返回和下滑标题均可收起面板。

模型编辑器的右上角勾号保存草稿。保存成功后面板收起，失败时保留草稿。插头在密钥旁测试连接，测试期间原位切换为停止按钮。测试结果在可见区域中央以 Toast 短暂显示。模型行的下载图标打开服务商列表，获取后可再次打开缓存并按需刷新。每个图标保留 44 像素触控范围、读屏名称和长按提示。[CC Switch 模型选择器](https://github.com/farion1231/cc-switch/blob/bdbc9604bc655320bfe4560ed6cf36b3cdf6b910/src/components/providers/forms/FetchedModelPicker.tsx)、[Apple 工具栏规范](https://developer.apple.com/design/human-interface-guidelines/toolbars)


### 顶部操作

手机左侧为历史菜单，右侧操作组包含搜索、今日总览、新会话与已有会话的更多操作。手机历史菜单提供 48×48 逻辑像素点击区域，右侧与桌面操作至少提供 44×44，图标约 19–20 逻辑像素。[顶部组件](lib/features/chat/widgets/chat_header.dart)

右侧今日总览底部左侧打开待办列表，右下角用直径 52 逻辑像素的加号新建待办。加号距右侧 12、距底部安全区 10 逻辑像素，滚动时保持固定。新建待办继承选中的日期和分类，打开后聚焦待办标题，提交位于浮窗右上角。

### 输入区

主聊天输入区采用两排布局。文字或语音状态位于上排，下排依次放附件、模型名称和语音、键盘、发送或停止操作。发送与停止使用主题前景实心圆，其他操作保持清晰图标。手机主输入区的圆形操作采用 `button-primary-mobile` 与 `button-ghost-mobile`，语音点击区与模型入口最小尺寸同为 48 逻辑像素。桌面与快问紧凑输入区沿用 44 逻辑像素规格，分别对应基础 `button-primary` 与 `button-ghost`。模型入口使用黑白供应商图标和当前模型名称，标签使用 12/16 字阶。模型菜单、配置表单、模型目录与待办来源使用同一图标映射。已知账户按实际供应商取标，自定义账户使用通用连接图标。侧栏额度卡第一行显示供应商黑白图标和名称，第二行以并排横条显示各周期的剩余百分比。标签按接口返回的周期使用 5h、日限、周限、月限。按量账户显示余额。[输入组件](lib/features/chat/widgets/chat_input_bar.dart)、[模型入口](lib/features/chat/widgets/chat_model_button.dart)

模型与额度页的 API 和 Plan 卡片等高。供应商图标、名称、计费标记与模型在首行，第二行展示余额或并排的周期横条。周期和百分比沿用侧栏组件，窄屏或大字号时可横向滑动。额度重置时间和账户优先级在更多菜单中查看。

首次使用遵循默认语音偏好，输入模式切换一步可达。输入内容、发送失败草稿、附件、语音取消窗口和键盘快捷键继续由原交互链路管理。主聊天和半屏快问共用按住说话交互。开始录音时轻震，聊天内容隐入当前主题的暖纸或炭灰底色。居中转写采用与发送键一致的反色文字和背景，取消态使用项目警示色。底部弧面供拇指停留，两侧弧区贴着屏幕外缘。手指滑入左侧取消区或右侧编辑区时整片变色并轻震，转写下方显示松手动作。滑回中央松手发送。半屏快问只在卡片内显示录音反馈。选择编辑后将最终转写放入草稿并聚焦输入框。手机文字模式下，空且未聚焦的输入框支持点按打字、长按转文字。已有草稿保留系统选字手势。键盘空格按住与松开共用录音流程，读屏操作与系统语音快捷入口保留直接听写。减少动态效果时使用静态麦克风图标。失败通过简短 Toast 反馈，Android 使用随包本地识别器。

### 模型菜单与品牌

菜单锚定输入区模型入口，位置随键盘与窗口变化更新，使用透明遮罩。生产入口先按供应商分组，点击后在同一浮层显示模型名称，并提供返回供应商的操作。浏览供应商时保持当前配置，选择模型后保存。自动换用和管理账户位于一级列表，深度思考位于当前供应商的二级列表。重复供应商账户在二级列表分组，历史和自定义模型仍可选择。模型菜单宽 208、最大高 300 逻辑像素，使用 12/16 字阶。按用户要求采用 36 最小行高的紧凑菜单行，外边距 4、行内水平 6，正文到边缘共 10，图文间距 6。长名称允许两行，系统及应用字号放大后自然撑高；完整模型标识提供读屏标签。可用高度受安全区与键盘限制，内容滚动。主聊天与快问共用入口和两级菜单。[模型菜单](lib/features/chat/widgets/chat_model_picker.dart)、[锚定容器](lib/core/widgets/app_anchored_popover.dart)

Kimi、DeepSeek、Claude、Gemini 和 OpenAI 使用来源明确的 SVG，浅色主题统一黑色、深色主题统一白色。智谱保留官方 PNG 的字母标识，通过灰度滤镜显示。所有素材保持原始比例。自定义兼容连接使用中性插头图标，模型名称保留真实身份。品牌素材出处与许可集中记录。[素材说明](assets/brands/README.md)、[品牌映射](lib/core/ai/brand_logos.dart)

### 手机主入口

手机首页以对话为主，输入区位于底部安全区上方。通过左上菜单打开侧栏，进入待办总览、日程、报告、核心数据、记忆与设置，返回时保留原会话草稿。用户于 2026-11-17 要求移除底部导航栏，后续导航继续复用侧栏入口。[侧栏组件](lib/features/chat/widgets/chat_drawer.dart)

### 消息与内容容器

用户消息最大宽度按实际阅读栏的 78% 计算，左右留白 14、上下留白 10 逻辑像素。助手正文直接排在阅读面上。内容筛选使用浅底胶囊，选中时采用主题主色，并提供独立于视觉高度的可点击区域。

### AI 答复与代码

流式和完成后的答复共用 `AiMarkdown` 的 GFM 块布局，覆盖标题、列表、强调、引用、行内代码、代码块和表格。完成后由 `SelectionArea` 提供文字选择。段间距使用 `reply-block-gap`，列表缩进使用 `reply-list-indent`，加粗使用 600 字重。一至三级标题额外留出 8 逻辑像素顶部空间。独立消息间距为 20 逻辑像素，同轮正文片段与结果卡间距为 8。每轮回复在全部内容之后展示一组操作，复制包含工具调用前后所有可见正文。日期分隔的上下留白为 4 和 8 逻辑像素。引用采用 `quote` 圆角，内边距为水平 12、垂直 8 逻辑像素。[答复排版](lib/core/widgets/ai_markdown.dart)、[流式与完成布局](lib/features/chat/widgets/chat_messages.dart)

代码块顶部显示语言或「代码」，复制按钮点击区至少 48×48，图标为 16 逻辑像素。代码区域内边距为 14 逻辑像素，长行横向滚动，复制操作使用完整原文。表格采用内容固有列宽、横向滚动和可见滚动条，表头采用 12/16、内容采用 13/18 字阶，单元格内边距为水平 6、垂直 5，边线为 0.5 逻辑像素。复制成功后显示「已复制代码」提示。[代码块](lib/core/widgets/ai_code_block.dart)

### 待办结果与完成反馈

`AiTodoCard` 使用实时待办内容，状态文字随当前数据呈现「已创建」「进行中」「已完成」「已取消」或「已恢复为待办」。状态位于标题下的元数据行，修改按钮位于卡片右侧，点击区为 48×48。卡片圆角为 12，边线为 0.5 逻辑像素。标题采用 13/18、元数据采用 12/16，垂直内边距为 4。左右有操作控件时各留 2，无对应操作控件时各留 8。具备完成操作时，卡片左侧放共享 `TodoCheckbox`，保存期间显示局部进度并禁用卡片操作，降低动态效果时使用静态省略号，保存成功后由已提交状态更新勾选和标题。已完成待办可通过同一控件恢复。[待办结果卡](lib/features/chat/widgets/ai_todo_card.dart)

结果卡来自持久操作回执投影的 `createdTodoIds` 与 `completedTodoIds`，完成集合按本轮回执中的前后状态推导。两组 ID 合并去重，并按当前仍存在的待办生成内容卡。数据来源沿用 `workspace_operations` 的既有回执结构。生产结果的「撤销本次全部修改」集中在整轮尾部，多个待办共用一个入口。手工完成或恢复后的 Toast 提供本次待办变更的撤销。[回执投影](lib/data/local/chat_todo_results.dart)、[会话结果装配](lib/features/chat/widgets/chat_thread.dart)

`TodoCheckbox` 在业务列表中的视觉圆形为 22，AI 结果和分页清单中为 18 逻辑像素，点击区采用 `todo-checkbox`。勾选由左向右显现，持续 240ms，采用 `easeOutCubic`，填充过渡为 160ms。`TodoSummary` 标题使用 200ms `easeOut` 过渡到次要文字色和删除线，日期、分类和优先级在下方自然换行。标题有效字号超过 20 时完整换行，常规字号最多两行。新完成回执卡在首次呈现时播放，进入历史会话时直接呈现已提交状态。降低动态效果时勾选、填充与标题立即更新。[完成控件](lib/core/todo/todo_checkbox.dart)、[待办摘要](lib/core/todo/todo_summary.dart)

`AppToast` 使用反色胶囊，默认展示 2500ms，文案最多两行，操作与关闭点击区至少 44。完成提示附带 20 逻辑像素圆勾，进入时用 250ms 淡入与上移，圆勾从 0.8 缩放至 1。降低动态效果时直接呈现最终状态。提示包含可访问实时播报，按实际操作提供「撤销」或「恢复」。[轻提示](lib/core/widgets/app_toast.dart)

### AI 交互卡片

待办清单和审批使用共享 `AiComponentCard`，水平内边距 8、垂直 6、圆角 12、边线 0.5。标题使用 14/20、正文 13/18、辅助文字 12/16，沿用主题字体和系统字号缩放。逾期文字采用 `overdueForeground`，紧急采用 `accentText`，完成采用绿色并保留状态文字。[共享卡片](lib/core/widgets/ai_component_card.dart)

待办清单每页展示 5 项，最后一页按实际余量展示。总项数、前后翻页与页码选择共用底部控制区，每个分类在卡片存续期间记住页码。单一清单按当前页内容收高，分页栏紧接末项。分类总览按当前字号、宽度及所有分类中最高的五项页面预留内容高度，分类切换、空分类和短末页保持高度一致，完成或移除后保留高度，宽度或字号改变时重算。长标题完整换行，待办行维持 48 点击区。分页采用紧凑菜单规格，标准控件高 36、箭头宽 48，文字放大后增高；页码显示为 1/24，下拉选项仍高 48。清单卡片底边距为 2，顶部 6、水平 8。放大字号时总项数另起一行。[分页清单](lib/features/chat/widgets/ai_todo_panel.dart)

提问选项按列对齐，题干 15/23，选项 14/20，整行点击区至少为 44。多选提交显示已选数量，已回答的问题收起为只读摘要。补充回答展开原位输入，发送失败后保留选择和草稿。表格新增预览按「字段、类型、要求」排成三列，列宽比例为 1.1∶1.4∶0.6，单元格水平内边距为 2、垂直为 5，表头采用 12/16、内容采用 13/18。编辑预览列出变更前后信息，提交继续要求用户确认。各卡片沿用同一轮回复的唯一尾部操作。[提问卡片](lib/features/chat/widgets/ai_question_card.dart)、[表格预览](lib/core/agent/agent_table_preview.dart)

### Agent 审批与过程状态

待确认、可继续和失败状态使用 `agent-review` 实体卡片，标题采用 14/20 与 500 字重，变更列表最大高度为 320 逻辑像素并可滚动。审批操作文字采用 13/18，点击区至少为 48×48。确认与继续处理的实心按钮采用 8 圆角、水平内边距 10，次要文字操作水平内边距为 8。操作期间根据运行状态禁用交互。确认内容、选择数量、重试、取消和撤销文案沿用真实运行状态。[运行组件](lib/core/agent/agent_run_card.dart)

聊天中的成功回复使用统一尾部，复制与整轮撤销图标为 17 逻辑像素，点击区为 48×48。有结果卡时由卡片呈现业务状态。流式回复结束后显示尾部操作，历史轮仍可复制。失败、等待确认及中断状态将复制并入恢复操作区，停止、撤销和上下文省略提示按实际运行展示。独立图片导入等运行组件沿用原有过程状态和动作。[回复尾部](lib/core/agent/agent_run_summary.dart)

### 侧栏、搜索与业务交互

- Search follows the supplied current Kimi search screenshot: a full-screen warm-white mobile history list with roomy title rows, a floating bottom search capsule, and a separate circular close action. Mobile does not open the keyboard until the field is focused; the controls move above it. Desktop uses a responsive overlay up to 920×720px with initial field focus. Queries search conversation titles/previews and task titles/notes. Session selection opens that exact conversation; task selection opens its editable detail while preserving the query. Escape and the close action dismiss search. No fabricated attachment cards: current history models have no attachment metadata.

- Pointer hover, keyboard focus and Enter/Space activation shared by AppPressable. Cmd/Ctrl+K search, Cmd/Ctrl+N new conversation, Cmd/Ctrl+B sidebar. Enter sends; Shift+Enter inserts a newline.

- Categories are managed in the sidebar: long press enters sorting, drag the handle to reorder siblings, tap the name or pencil to edit icons/colors, and use the inline plus to create. No mobile sidebar close X; swipe or tap the outside area to dismiss.

- 侧栏导航与历史行在桌面至少 44px、手机至少 48px，选中态使用 `fill1`。分类标题使用统一的 13px 辅助字阶。

- 手机与桌面展开侧栏使用两行三列图标网格，依次为待办、日程、报告、数据、记忆、设置。主聊天长按语音区与输入框共用底色，波形图标和提示文字居中。
- 主窗口每次冷启动在首帧后检查更新。有新版时显示可收起的提示，点击查看详情。更新页展开本次与当前版本的说明，历史版本按时间倒序逐条展开。日志使用随包数据，联网时从官网刷新。

- 手机侧栏的头像、昵称和订阅等级组成顶部胶囊，新建会话独立靠右。搜索栏悬浮在底部安全区上方 8 逻辑像素，主题开关位于右侧。分类和历史会话从控件下方滚过，在边缘逐渐淡出。列表首尾预留完整一行的操作空间。
- 两处浮层距侧栏左右边缘 14 逻辑像素，最小触控高度 44 逻辑像素。材质底色的不透明度为浅色 0.68、深色 0.54，模糊 sigma 为 18，高对比度使用实底。桌面搜索采用相同材质，用户信息保留在底部。[侧栏控件](lib/features/chat/widgets/sidebar_controls.dart)

- 设置、待办总览、分类、日程、报告、记忆、数据表和表内搜索都将输入框放在底部安全区。键盘展开时，输入框紧贴键盘上方。模型目录在结果列表下放置搜索与刷新，看板新建在底部面板输入标题，截图导入的指令和提交操作放在预览下方。多字段编辑使用带标签的滚动表单。

- 快问浮层的布局、手势、输入与后台行为见 [快捷唤醒说明](docs/upgrade/QUICK-ASSIST.md)。页面跨 feature 的组合归 `shell`，共享的领域展示组件归 `core`。

导航与业务投影使用 Riverpod。生产会话、工作数据与偏好通过 Drift/SQLite 持久化，SharedPreferences 提供迁移期的历史输入偏好。演示数据保留在显式 fixture，截图采用合成账户、脚本回复与隔离 SQLite。运行截图仅记录本轮主界面样板。主界面截图

共享弹层沿用内缩连续曲率、轻遮罩和键盘感知尺寸。桌面业务弹窗继续限制在 560 逻辑像素宽与 85% 可用高度。业务页面规范按各自迁移阶段更新。

### 会员套餐

会员入口只展示乐章四级：音符、序曲、奏鸣曲、交响曲，对应 Free、Beta、Pro、Max，每月积分为 100、500、3,000、10,000。侧栏与设置中的等级标签使用对应徽标及底色：音符暖灰、序曲浅金、奏鸣曲陶杏、交响曲深棕金；浅深色前景与底色对比均至少 4.5:1。等级使用英文名 Note、Prelude、Sonata、Symphony。标签字号 11，水平内边距 7，仍保留 44 的点击范围。

点击标签直接升起套餐浮窗，不经过汇总页或第二层确认窗。浮窗宽度最多 520、高度最多屏幕 85%，由内容决定实际高度；四级入口并排，序曲默认聚焦并展示 500 点/月与短上下文。卡面高度一致，权益区两行，价格周期与主按钮紧凑相邻。大字号下选项可横向滚动，正文可纵向滚动，底部操作始终可用。关闭、遮罩、系统返回及向下拖动标题区可收起浮窗。

套餐切换时，选中底色以 280ms easeOutCubic 横移，卡面沿选择方向平移 12% 并交叉渐变；选择反馈使用轻触震动。放大字号时按内容增高，减少动态效果直接更新。点击「切换为…」提交当前运行的展示选择，根导航播放 ToWork W 与等级徽标的 2,600ms 全屏动画，状态文案为「方案已切换」，完成后回到原界面。界面不提供演示、模拟、示例、重播、重置等文案或操作。

`membershipSelectionProvider` 只保存当前运行的展示选择，不写入真实会员、模型额度或支付数据。价格沿用已有设计值，未接计费；山岳旧素材保留在设计归档，不提供切换入口。[套餐浮窗](lib/features/membership/membership_page.dart)

## Do's and Don'ts

### Do

- **Do** 复用 `AppColors`、`AppTextStyles` 与共享交互组件。
- **Do** 让顶部透明背景覆盖真实滚动内容，并按实际输入区高度留足末条消息空间。
- **Do** 保持模型名称、品牌素材与实际模型身份一致。
- **Do** 在布局调整后核对手机键盘、大字号、窄窗口、宽屏与深色实际截图。

### 表单、设置与工作区

页面标题用 17/22，组内标题 15/20，字段与列表正文 14/20，辅助文字 12/16 或 13/18。中文保留系统字体回退与系统文字缩放。长回复保留 15/23 的阅读行距。

设置按组排列，选项左侧显示名称，右侧显示当前值。能直接从当前值读出的信息省略说明。表单使用常驻标签、4 像素标签间距和淡色底，聚焦时显示细边。对话、搜索和就地编辑复用所在容器的背景。按钮至少保留 44 像素触控区域。

今日总览、分类、看板与日程使用同一新建待办表单。标题后的键盘「下一项」进入备注，日期与时间、分类、优先级、状态和截止提醒在提交前可编辑。打开看板列或日程会带入当前位置。记忆编辑与新增类型复用输入浮窗的标题栏。浮窗按内容收高，顶行依次为关闭、标题和提交。正文与边缘相距 16 逻辑像素，待办属性使用与详情一致的字段行，记忆类型与时效就地展开，选中后显示当前值。单字段表单省去属性行。键盘弹出后保留标题和提交，窄屏或大字号下属性可以折行。[输入浮窗](lib/core/widgets/sheet_composer.dart)

分类、数据表类型和记忆类型按内容区宽度排布，低于 600 逻辑像素使用横向选择条，宽屏保留纵栏。日程视图和新建报告使用锚定菜单。设置表单与顶栏对齐到 640 逻辑像素，桌面报告和记录详情的阅读栏最多 720 逻辑像素。逐页对照

### Don't

- **Don't** 将全宽实色背景加到对话顶部操作栏。
- **Don't** 将截图样板的账户或回复写入生产资料库。

本轮主界面规则覆盖旧规范中的相关聊天布局与字号，后续页面迁移按实施计划登记。测试按仓库质量门执行，实际命令、设备与测试范围记录在验证文档。[测试规范](docs/standards/TESTING.md)、[升级验证记录](docs/upgrade/VERIFICATION.md)

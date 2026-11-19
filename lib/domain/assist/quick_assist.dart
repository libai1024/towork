/// 快捷面板被唤起的途径。
enum AssistSource {
  /// 系统的助手手势或按键（默认助手应用）。
  assistant,

  /// 耳机或车机的语音指令键。
  voice,

  /// 其他应用分享过来的文字。
  share,

  /// 其他应用里选中文字后的菜单。
  selection,

  /// 控制中心的快捷开关。
  tile,

  /// 桌面图标长按出来的快捷方式。
  shortcut,

  /// 应用自己打开，或来源不明。
  app,
}

/// 一次唤起带来的东西。
class AssistLaunch {
  const AssistLaunch({
    this.source = AssistSource.app,
    this.text = '',
    this.voice = false,
  });

  final AssistSource source;

  /// 分享或划词带入的文字。只预填进输入框，由用户决定是否发送。
  final String text;

  /// 面板打开后直接开始听写。
  final bool voice;

  /// 带入文字的长度上限；更长的内容截断后再预填。
  static const maxText = 4000;
}

/// 面板交还主应用时要带过去的去向。两者都为空表示只是打开主应用。
class AssistHandoff {
  const AssistHandoff({this.sessionId, this.location});

  /// 要在主应用里继续的会话。
  final String? sessionId;

  /// 要打开的页面路径，例如模型与额度。
  final String? location;
}

/// 快捷面板所在的窗口。面板关闭、交还主应用都经过它。
abstract interface class AssistHost {
  /// 当前这次唤起。
  Future<AssistLaunch> launch();

  /// 面板还开着时又被唤起。
  Stream<AssistLaunch> get relaunches;

  Future<void> close();

  /// 把面板收到后台但不销毁，并用系统提示告诉用户 [notice]。回复还在
  /// 生成时用它：引擎活着，这次运行才能收完。
  Future<void> hide(String notice);

  /// 打开主应用。[keepPanel] 为 true 时面板留在后台继续收尾，由调用方
  /// 稍后 [close]；否则随即关闭。
  Future<void> openApp(AssistHandoff handoff, {bool keepPanel = false});
}

/// 快捷唤醒在系统里的设置情况。
class AssistEntryStatus {
  const AssistEntryStatus({
    this.supported = false,
    this.defaultAssistant,
    this.canPin = false,
  });

  /// 当前平台有没有快捷面板。
  final bool supported;

  /// 是否已被设为默认助手应用；系统不告知时为空。
  final bool? defaultAssistant;

  /// 桌面是否支持固定快捷方式。
  final bool canPin;
}

/// 主应用里用来配置和试用各个唤起入口。
abstract interface class AssistEntries {
  Future<AssistEntryStatus> status();

  /// 打开系统的默认助手设置。打不开时返回 false。
  Future<bool> openAssistantSettings();

  /// 请求将快问或语音快问固定到桌面，由系统确认。
  Future<bool> pinShortcut({bool voice = false});

  /// 直接打开快捷面板。
  Future<bool> openPanel();
}

/// 同一进程里的另一个界面引擎。主应用和快捷面板各有一个，各自持有
/// 一条数据库连接。
abstract interface class EnginePeers {
  /// 另一个引擎是否还活着。它可能正在生成回复。
  Future<bool> othersAlive();

  /// 取走快捷面板留给主应用的去向；没有则为空。
  Future<AssistHandoff?> takeHandoff();
}

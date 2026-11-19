import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var consentGeneration = 0
  private var speech: SpeechBridge?
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(NSRect(x: windowFrame.origin.x, y: windowFrame.origin.y,
                         width: 1280, height: 840), display: true)
    self.minSize = NSSize(width: 760, height: 600)
    self.title = "ToWork"
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)
    FlutterMethodChannel(name: "towork/apple-distribution", binaryMessenger: flutterViewController.engine.binaryMessenger)
      .setMethodCallHandler { [weak self] call, result in
        guard let window = self else { result(false); return }
        window.handleStoreCall(call, result: result)
      }
    speech = SpeechBridge(messenger: flutterViewController.engine.binaryMessenger)

    FlutterMethodChannel(name: "towork/update", binaryMessenger: flutterViewController.engine.binaryMessenger)
      .setMethodCallHandler { call, result in
        guard call.method == "info" else { result(FlutterMethodNotImplemented); return }
        result([
          "versionName": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
          "versionCode": Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0") ?? 0,
          "supported": false,
        ])
      }

    super.awakeFromNib()
  }

  private func handleStoreCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let defaults = UserDefaults.standard
    let permissionKey = "ToWork.AllowedAIOrigins.v1"
    switch call.method {
    case "isTestFlight":
      result(Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt")
    case "openPrivacyPolicy":
      result(NSWorkspace.shared.open(URL(string: "https://zhaozhaoyue.top/towork/privacy.html")!))
    case "resetModelConsent":
      consentGeneration += 1
      defaults.removeObject(forKey: permissionKey)
      result(nil)
    case "authorizeModel":
      guard let args = call.arguments as? [String: String],
            let origin = args["origin"], let provider = args["provider"] else { result(false); return }
      if defaults.stringArray(forKey: permissionKey)?.contains(origin) == true { result(true); return }
      guard attachedSheet == nil else { result(false); return }
      let alert = NSAlert()
      alert.messageText = "允许发送到" + provider + "？"
      alert.informativeText = "ToWork 会将对话、选中的附件，以及任务所需的待办、表格、记忆或报告发送到 " + origin + " 进行处理。可在「设置 → 隐私与权限」撤回。"
      alert.addButton(withTitle: "暂不允许")
      alert.addButton(withTitle: "允许")
      let generation = consentGeneration
      alert.beginSheetModal(for: self) { [weak self] response in
        let accepted = self?.consentGeneration == generation && response == .alertSecondButtonReturn
        if accepted {
          var allowed = Set(defaults.stringArray(forKey: permissionKey) ?? [])
          allowed.insert(origin)
          defaults.set(Array(allowed), forKey: permissionKey)
        }
        result(accepted)
      }
    default: result(FlutterMethodNotImplemented)
    }
  }
}

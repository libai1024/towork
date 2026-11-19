import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ToWorkUpdate") {
      FlutterMethodChannel(name: "towork/apple-distribution", binaryMessenger: registrar.messenger())
        .setMethodCallHandler(AppleDistribution.handle)
      FlutterMethodChannel(name: "towork/update", binaryMessenger: registrar.messenger())
        .setMethodCallHandler { call, result in
          guard call.method == "info" else { result(FlutterMethodNotImplemented); return }
          result([
            "versionName": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
            "versionCode": Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0") ?? 0,
            "supported": false,
          ])
        }
    }
  }
}

private enum AppleDistribution {
  private static let permissionKey = "ToWork.AllowedAIOrigins.v1"

  private final class Prompt {
    let alert: UIAlertController
    let reply: FlutterResult
    var backgroundObserver: NSObjectProtocol?

    init(_ alert: UIAlertController, _ reply: @escaping FlutterResult) {
      self.alert = alert
      self.reply = reply
    }
  }
  private static var pending: Prompt?

  private static func finish(_ prompt: Prompt, allowedOrigin: String? = nil, dismiss: Bool = false) {
    guard pending === prompt else { return }
    pending = nil
    if let observer = prompt.backgroundObserver { NotificationCenter.default.removeObserver(observer) }
    if dismiss { prompt.alert.dismiss(animated: false) }
    if let origin = allowedOrigin {
      let defaults = UserDefaults.standard
      var allowed = Set(defaults.stringArray(forKey: permissionKey) ?? [])
      allowed.insert(origin)
      defaults.set(Array(allowed), forKey: permissionKey)
    }
    prompt.reply(allowedOrigin != nil)
  }

  static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isTestFlight":
      // This label affects presentation only. StoreKit's sandbox receipt is never an entitlement.
      result(Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt")
    case "openPrivacyPolicy":
      UIApplication.shared.open(URL(string: "https://zhaozhaoyue.top/towork/privacy.html")!) { opened in result(opened) }
    case "resetModelConsent":
      if let prompt = pending { finish(prompt, dismiss: true) }
      UserDefaults.standard.removeObject(forKey: permissionKey)
      result(nil)
    case "authorizeModel":
      guard let args = call.arguments as? [String: String],
            let origin = args["origin"], let provider = args["provider"] else { result(false); return }
      let defaults = UserDefaults.standard
      if defaults.stringArray(forKey: permissionKey)?.contains(origin) == true { result(true); return }
      guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
              .first(where: { $0.activationState == .foregroundActive }),
            var controller = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
        result(false)
        return
      }
      while let next = controller.presentedViewController { controller = next }
      guard pending == nil, !(controller is UIAlertController) else { result(false); return }
      let alert = UIAlertController(
        title: "允许发送到" + provider + "？",
        message: "ToWork 会将对话、选中的附件，以及任务所需的待办、表格、记忆或报告发送到 " + origin + " 进行处理。可在「设置 → 隐私与权限」撤回。",
        preferredStyle: .alert)
      let prompt = Prompt(alert, result)
      pending = prompt
      prompt.backgroundObserver = NotificationCenter.default.addObserver(
        forName: UIScene.didEnterBackgroundNotification, object: scene, queue: .main
      ) { [weak prompt] _ in
        if let prompt = prompt { finish(prompt, dismiss: true) }
      }
      alert.addAction(UIAlertAction(title: "暂不允许", style: .cancel) { [weak prompt] _ in
        if let prompt = prompt { finish(prompt) }
      })
      alert.addAction(UIAlertAction(title: "允许", style: .default) { [weak prompt] _ in
        if let prompt = prompt { finish(prompt, allowedOrigin: origin) }
      })
      controller.present(alert, animated: true)
    default: result(FlutterMethodNotImplemented)
    }
  }
}

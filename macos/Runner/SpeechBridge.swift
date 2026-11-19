import AVFoundation
import Cocoa
import FlutterMacOS
import Speech

/// Raw transcripts remain in memory; each callback captures its originating ID.
final class SpeechBridge {
  private let channel: FlutterMethodChannel
  private var active: String?
  private var engine: AVAudioEngine?
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private var recognizer: SFSpeechRecognizer?
  private var observer: NSObjectProtocol?
  private var deadline: DispatchWorkItem?
  private var requesting = false

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "towork/speech", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
    observer = NotificationCenter.default.addObserver(
      forName: NSApplication.didResignActiveNotification, object: nil, queue: .main
    ) { [weak self] _ in self?.interrupt() }
  }
  private func capabilities(_ locale: String) -> [String: Any] {
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: locale))
    return [
      "available": recognizer?.isAvailable ?? false,
      "authorized": SFSpeechRecognizer.authorizationStatus() == .authorized &&
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized,
      "locales": SFSpeechRecognizer.supportedLocales().map { $0.identifier.replacingOccurrences(of: "_", with: "-") }.sorted(),
      "onDeviceSupported": recognizer?.supportsOnDeviceRecognition ?? false,
    ]
  }
  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    let locale = args["locale"] as? String ?? "zh-CN"
    switch call.method {
    case "inspect": result(capabilities(locale))
    case "prepare":
      if requesting { result(FlutterError(code: "busy", message: nil, details: nil)); return }
      requesting = true
      SFSpeechRecognizer.requestAuthorization { [weak self] status in
        guard let self else { return }
        if status != .authorized {
          DispatchQueue.main.async { self.requesting = false; result(self.capabilities(locale)) }
          return
        }
        AVCaptureDevice.requestAccess(for: .audio) { _ in
          DispatchQueue.main.async { self.requesting = false; result(self.capabilities(locale)) }
        }
      }
    case "start": start(args, result: result)
    case "stop":
      if args["id"] as? String == active {
        finishAudio()
        request?.endAudio()
        if let id = active { emit(id, "ended") }
      }
      result(nil)
    case "cancel":
      if args["id"] as? String == active { release() }
      result(nil)
    case "openSettings":
      if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition") {
        NSWorkspace.shared.open(url)
      }
      result(nil)
    default: result(FlutterMethodNotImplemented)
    }
  }
  private func emit(_ id: String, _ kind: String, text: String? = nil, error: String? = nil) {
    guard active == id else { return }
    var payload: [String: Any] = ["id": id, "kind": kind]
    if let text { payload["text"] = text }
    if let error { payload["error"] = error }
    channel.invokeMethod("event", arguments: payload)
  }
  private func start(_ args: [String: Any], result: @escaping FlutterResult) {
    guard let id = args["id"] as? String, !id.isEmpty,
      let locale = args["locale"] as? String,
      let recognizer = SFSpeechRecognizer(locale: Locale(identifier: locale)) else {
      result(FlutterError(code: "localeUnavailable", message: nil, details: nil)); return
    }
    guard active == nil else { result(FlutterError(code: "busy", message: nil, details: nil)); return }
    guard capabilities(locale)["authorized"] as? Bool == true else {
      result(FlutterError(code: "permissionDenied", message: nil, details: nil)); return
    }
    guard recognizer.isAvailable else { result(FlutterError(code: "unavailable", message: nil, details: nil)); return }
    let onDevice = args["onDevice"] as? Bool ?? false
    if onDevice && !recognizer.supportsOnDeviceRecognition {
      result(FlutterError(code: "onDeviceUnavailable", message: nil, details: nil)); return
    }
    let audio = AVAudioEngine()
    let input = audio.inputNode
    let format = input.outputFormat(forBus: 0)
    guard format.sampleRate > 0 && format.channelCount > 0 else {
      result(FlutterError(code: "unavailable", message: nil, details: nil)); return
    }
    let capture = SFSpeechAudioBufferRecognitionRequest()
    capture.shouldReportPartialResults = true
    capture.requiresOnDeviceRecognition = onDevice
    capture.taskHint = .dictation
    active = id
    self.recognizer = recognizer
    engine = audio
    request = capture
    input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in capture.append(buffer) }
    task = recognizer.recognitionTask(with: capture) { [weak self] response, error in
      DispatchQueue.main.async {
        guard let self, self.active == id else { return }
        if let response {
          self.emit(id, response.isFinal ? "finalResult" : "partial", text: response.bestTranscription.formattedString)
          if response.isFinal { self.release(); return }
        }
        if error != nil {
          self.emit(id, "error", error: "interrupted")
          self.release()
        }
      }
    }
    do {
      audio.prepare()
      try audio.start()
      emit(id, "listening")
      let limit = DispatchWorkItem { [weak self] in
        guard let self, self.active == id else { return }
        self.emit(id, "error", error: "interrupted")
        self.release()
      }
      deadline = limit
      DispatchQueue.main.asyncAfter(deadline: .now() + 65, execute: limit)
      result(nil)
    } catch {
      release()
      result(FlutterError(code: "startFailed", message: nil, details: nil))
    }
  }
  private func finishAudio() {
    if let engine {
      engine.stop()
      engine.inputNode.removeTap(onBus: 0)
      self.engine = nil
    }
  }
  private func release() {
    active = nil
    deadline?.cancel()
    deadline = nil
    finishAudio()
    request?.endAudio()
    task?.cancel()
    task = nil
    recognizer = nil
    request = nil
  }
  private func interrupt() {
    if let id = active { emit(id, "error", error: "interrupted") }
    release()
  }
  deinit {
    release()
    if let observer { NotificationCenter.default.removeObserver(observer) }
  }
}

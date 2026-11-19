class CodeUpdateStatus {
  const CodeUpdateStatus({
    this.supported = false,
    this.activeVersion,
    this.pending = false,
  });

  final bool supported;
  final String? activeVersion;
  final bool pending;
}

class CodeUpdate {
  const CodeUpdate({
    required this.version,
    required this.manifest,
    required this.size,
    this.url,
  });

  final String version;
  final String manifest;
  final int size;
  final Uri? url;
  bool get withdrawal => url == null;
  String get label => withdrawal ? '恢复基础版本' : '补丁 P$version';
}

abstract interface class CodeUpdateGateway {
  Future<CodeUpdateStatus> status();
  Future<CodeUpdate?> check();
  Future<void> apply(
    CodeUpdate update, {
    required void Function(int bytes) onProgress,
    required void Function() onVerifying,
  });
  Future<void> restart();
  void cancel();
}

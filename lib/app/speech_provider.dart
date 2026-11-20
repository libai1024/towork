import 'package:towork/l10n/strings.dart';

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show MethodChannel, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/platform/native_speech_input.dart';
import '../data/platform/offline_asr_model_store.dart';
import '../data/platform/sherpa_speech_input.dart';
import '../data/platform/speech_input_selector.dart';
import '../domain/speech/speech_input.dart';

/// Android 上用原生 AssetManager 流式复制资产，内存占用恒定；
/// 其他平台资产本就是磁盘文件、体量也只在开发机上使用，退回整体读取。
const _assetChannel = MethodChannel('towork/assets');
AssetFileCopier? get _assetCopier => Platform.isAndroid
    ? (asset, target) => _assetChannel.invokeMethod<void>('copyAsset', {
        'asset': asset,
        'target': target,
      })
    : null;

/// 随包 SenseVoice。首启由 [prefetchOfflineSpeechProvider] 在后台复制到本地
///（约 228MB）；若首次录音更早，等待同一次安装。
final offlineAsrStoreProvider = FutureProvider<OfflineAsrModelStore>((
  ref,
) async {
  final support = await getApplicationSupportDirectory();
  unawaited(OfflineAsrModelStore.removeRetired(support).catchError((_) {}));
  final store = OfflineAsrModelStore(Dio(), root: support);
  // Only publish a ready store. First capture awaits the same installation.
  await store.installFromAssets(rootBundle.load, copy: _assetCopier);
  return store;
});

/// UI 展示用模型总量（app 层转发，features 不直接依赖 data）。
int get offlineAsrModelTotalBytes => OfflineAsrModelStore.totalBytes;

/// 随包 Silero VAD；安装失败只是失去实时预览，不影响最终识别。
final _vadStoreProvider = FutureProvider<OfflineAsrModelStore>((ref) async {
  final support = await getApplicationSupportDirectory();
  final store = OfflineAsrModelStore(
    Dio(),
    root: support,
    spec: AsrModelSpec.sileroVad,
  );
  try {
    await store.installFromAssets(rootBundle.load, copy: _assetCopier);
  } catch (_) {}
  return store;
});

/// Android 冷启动后台安装离线模型（只写磁盘，不装载进内存）。其他平台
/// 离线识别只是系统识别的兜底，按需安装即可。失败留给首次录音时报告。
final prefetchOfflineSpeechProvider = Provider<void Function()>(
  (ref) => () {
    if (!Platform.isAndroid) return;
    ref.read(offlineAsrStoreProvider.future).ignore();
    ref.read(_vadStoreProvider.future).ignore();
  },
);

/// 每次开始录音时解析引擎：内置 SenseVoice + VAD（分句与实时预览）。
final asrEngineLoaderProvider = Provider<AsrEngineLoader>(
  (ref) => () async {
    final vad = await ref.read(_vadStoreProvider.future);
    final bundled = await ref.read(offlineAsrStoreProvider.future);
    return SherpaSpeechInput.engineOf(
      bundled,
      vadPath: vad.isReady ? vad.modelPath : null,
    );
  },
);

/// 离线语音模型状态：未就绪 / 内置安装中 / 下载中（进度）/ 就绪 / 失败。
class OfflineAsrModelState {
  const OfflineAsrModelState({
    this.ready = false,
    this.installing = false,
    this.downloading = false,
    this.downloadedBytes = 0,
    this.error,
  });
  final bool ready;
  final bool installing;
  final bool downloading;
  final int downloadedBytes;
  final String? error;
}

class OfflineAsrModelController extends StateNotifier<OfflineAsrModelState> {
  OfflineAsrModelController(this._store) : super(const OfflineAsrModelState());
  final OfflineAsrModelStore _store;
  CancelToken? _cancel;

  void refresh() {
    if (state.downloading || state.installing) return;
    state = OfflineAsrModelState(ready: _store.isReady);
  }

  /// 从随包资产安装模型（无需网络）。冷启动已在后台尝试，这里用于
  /// 弹层打开时的兜底/进度展示；与后台安装共享同一次安装。
  Future<void> install() async {
    if (state.installing || state.downloading) return;
    if (_store.isReady) {
      state = const OfflineAsrModelState(ready: true);
      return;
    }
    state = const OfflineAsrModelState(installing: true);
    try {
      await _store.installFromAssets(rootBundle.load, copy: _assetCopier);
      state = const OfflineAsrModelState(ready: true);
    } catch (_) {
      // 回到下载兜底；失败原因多为包体异常，提示用户联网下载。
      state = const OfflineAsrModelState();
    }
  }

  Future<void> download() async {
    if (state.downloading || _store.isReady) return;
    _cancel = CancelToken();
    state = const OfflineAsrModelState(downloading: true);
    try {
      await _store.download(
        cancelToken: _cancel,
        onProgress: (bytes) {
          state = OfflineAsrModelState(
            downloading: true,
            downloadedBytes: bytes,
          );
        },
      );
      state = const OfflineAsrModelState(ready: true);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        state = const OfflineAsrModelState();
        return;
      }
      state = OfflineAsrModelState(
        error: strings.modelDownloadFailedCheckYourConnectionAnd,
      );
    } catch (_) {
      state = OfflineAsrModelState(
        error: strings.modelDownloadFailedTryAgainLater,
      );
    } finally {
      _cancel = null;
    }
  }

  void cancelDownload() => _cancel?.cancel();

  /// 放弃安装等待（资产复制本身不中断，仅解除 UI 等待态）。
  void cancelInstall() {
    if (state.installing) state = const OfflineAsrModelState();
  }

  Future<void> delete() async {
    await _store.delete();
    state = const OfflineAsrModelState();
  }
}

/// store 未就绪时的占位（路径指向临时目录，任何检查都返回未就绪）。
OfflineAsrModelStore _placeholderStore() => OfflineAsrModelStore(
  Dio(),
  root: Directory('${Directory.systemTemp.path}/towork-asr-placeholder'),
);

final offlineAsrModelProvider =
    StateNotifierProvider<OfflineAsrModelController, OfflineAsrModelState>((
      ref,
    ) {
      final store = ref.watch(offlineAsrStoreProvider).valueOrNull;
      final controller = OfflineAsrModelController(
        store ?? _placeholderStore(),
      );
      controller.refresh();
      return controller;
    });

/// 离线输入（预热用）。
final _offlineSpeechProvider = Provider<SherpaSpeechInput>((ref) {
  final input = SherpaSpeechInput(
    loadEngine: ref.watch(asrEngineLoaderProvider),
  );
  ref.onDispose(() => unawaited(input.dispose()));
  return input;
});

/// Android always uses bundled offline ASR, independent of GMS availability.
final speechInputProvider = Provider<SpeechInput>((ref) {
  final input = SpeechInputSelector(
    NativeSpeechInput(),
    ref.watch(_offlineSpeechProvider),
    preferOffline: Platform.isAndroid,
  );
  ref.onDispose(() => unawaited(input.dispose()));
  return input;
});

/// 预热入口：`ref.read(warmOfflineSpeechProvider)` 得到可调用函数。
final warmOfflineSpeechProvider = Provider<Future<void> Function()>((ref) {
  final offline = ref.watch(_offlineSpeechProvider);
  return offline.warmUp;
});

/// A network interface is only a preflight hint, not proof Kimi is reachable.
/// Actual request errors are handled by the durable Agent path.
final speechNetworkRouteProvider = Provider<Future<bool> Function()>(
  (ref) => () async {
    try {
      return (await Connectivity().checkConnectivity()).any(
        (r) => r != ConnectivityResult.none,
      );
    } catch (_) {
      return false;
    }
  },
);

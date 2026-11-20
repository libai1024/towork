import 'package:towork/l10n/strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/update/app_update.dart';
import '../../domain/update/code_update.dart';

enum UpdatePhase {
  idle,
  checking,
  current,
  available,
  downloading,
  verifying,
  applying,
  ready,
  permission,
  installing,
  restarting,
  failed,
  unsupported,
}

class UpdateState {
  const UpdateState({
    this.phase = UpdatePhase.idle,
    this.installed,
    this.release,
    this.path,
    this.received = 0,
    this.message,
    this.fullDownload = false,
    this.codeStatus = const CodeUpdateStatus(),
    this.codeUpdate,
    this.codeReady = false,
  });

  final UpdatePhase phase;
  final InstalledApp? installed;
  final AppRelease? release;
  final String? path;
  final int received;
  final String? message;
  final bool fullDownload;
  final CodeUpdateStatus codeStatus;
  final CodeUpdate? codeUpdate;
  final bool codeReady;
  bool get isCode => codeUpdate != null || codeReady;
  bool get isDelta => release?.patch != null && !fullDownload;
  int get downloadSize =>
      codeUpdate?.size ??
      (isDelta ? release!.downloadSize : release?.size ?? 0);

  bool get busy => const {
    UpdatePhase.checking,
    UpdatePhase.downloading,
    UpdatePhase.verifying,
    UpdatePhase.applying,
    UpdatePhase.installing,
    UpdatePhase.restarting,
  }.contains(phase);

  UpdateState copyWith({
    required UpdatePhase phase,
    InstalledApp? installed,
    AppRelease? release,
    String? path,
    int? received,
    String? message,
    bool? fullDownload,
    CodeUpdateStatus? codeStatus,
    CodeUpdate? codeUpdate,
    bool? codeReady,
  }) => UpdateState(
    phase: phase,
    installed: installed ?? this.installed,
    release: release ?? this.release,
    path: path ?? this.path,
    received: received ?? this.received,
    message: message,
    fullDownload: fullDownload ?? this.fullDownload,
    codeStatus: codeStatus ?? this.codeStatus,
    codeUpdate: codeUpdate ?? this.codeUpdate,
    codeReady: codeReady ?? this.codeReady,
  );
}

class UpdateController extends StateNotifier<UpdateState> {
  UpdateController(this.platform, this.gateway, {this.codeGateway})
    : super(const UpdateState());
  final CodeUpdateGateway? codeGateway;
  bool _active = true;
  bool _restartFailed = false;
  final UpdatePlatform platform;
  final UpdateGateway gateway;
  bool _installing = false;
  bool _polling = false;
  bool _downloadCancelled = false;

  Future<void> check() async {
    if (state.busy || state.codeReady) return;
    state = const UpdateState(phase: UpdatePhase.checking);
    try {
      final installed = await platform.installed();
      if (!mounted) return;
      state = state.copyWith(phase: UpdatePhase.checking, installed: installed);
      if (!installed.canUpdate) {
        state = state.copyWith(phase: UpdatePhase.unsupported);
        return;
      }
      final codeStatus =
          await codeGateway?.status() ?? const CodeUpdateStatus();
      if (!mounted) return;
      state = state.copyWith(
        phase: UpdatePhase.checking,
        codeStatus: codeStatus,
      );
      if (codeStatus.pending) {
        state = state.copyWith(phase: UpdatePhase.ready, codeReady: true);
        return;
      }
      final release = await gateway.check(installed);
      if (!mounted) return;
      final codeUpdate = release == null && codeStatus.supported
          ? await codeGateway?.check()
          : null;
      if (!mounted) return;
      state = state.copyWith(
        codeUpdate: codeUpdate,
        phase: release == null && codeUpdate == null
            ? UpdatePhase.current
            : UpdatePhase.available,
        release: release,
      );
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
          phase: UpdatePhase.failed,
          message: _message(error),
        );
      }
    }
  }

  Future<void> download() async {
    if (state.isCode) return _downloadCode();
    final release = state.release;
    if (state.busy || release == null) return;
    _downloadCancelled = false;
    state = state.copyWith(
      phase: UpdatePhase.downloading,
      fullDownload: false,
      received: 0,
    );
    try {
      final info = await platform.installed();
      if (!mounted) return;
      if (_downloadCancelled) throw const UpdateFailure('cancelled');
      final path = await gateway.download(
        release,
        availableBytes: info.availableBytes,
        onProgress: (bytes) {
          if (mounted) {
            state = state.copyWith(
              phase: UpdatePhase.downloading,
              received: bytes,
            );
          }
        },
        onVerifying: () {
          if (mounted) state = state.copyWith(phase: UpdatePhase.verifying);
        },
        onApplying: () {
          if (mounted) state = state.copyWith(phase: UpdatePhase.applying);
        },
        onFallback: () {
          if (mounted) {
            state = state.copyWith(
              phase: UpdatePhase.downloading,
              fullDownload: true,
              received: 0,
            );
          }
        },
      );
      if (mounted) state = state.copyWith(phase: UpdatePhase.ready, path: path);
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
          phase: UpdatePhase.available,
          message: _message(error),
          fullDownload: state.fullDownload,
        );
      }
    }
  }

  void cancelDownload() {
    if (state.isCode) {
      if (state.phase == UpdatePhase.downloading) codeGateway?.cancel();
      return;
    }
    _downloadCancelled = true;
    gateway.cancel();
  }

  Future<void> install() async {
    if (state.codeReady) return restartCode();
    final release = state.release;
    final path = state.path;
    if (_installing || release == null || path == null) return;
    _installing = true;
    state = state.copyWith(phase: UpdatePhase.installing);
    try {
      if (!await platform.canInstall()) {
        if (!mounted) return;
        state = state.copyWith(phase: UpdatePhase.permission);
        await platform.requestInstallPermission();
        return;
      }
      await platform.install(path, release);
    } catch (error) {
      if (mounted) {
        final invalid =
            error is UpdateFailure &&
            {'checksum', 'size', 'file_invalid'}.contains(error.code);
        state = UpdateState(
          phase: invalid ? UpdatePhase.available : UpdatePhase.ready,
          installed: state.installed,
          release: state.release,
          path: invalid ? null : state.path,
          message: _message(error),
        );
      }
    } finally {
      _installing = false;
    }
  }

  /// Called by the visible update page only while the app is in the foreground.
  Future<void> pollInstallation() async {
    if (_polling || _installing || state.phase != UpdatePhase.installing) {
      return;
    }
    _polling = true;
    try {
      final status = await platform.installStatus();
      if (!mounted) return;
      switch (status) {
        case InstallStatus.confirmation:
          await platform.confirmInstall();
        case InstallStatus.waiting:
          break;
        case InstallStatus.success:
          state = state.copyWith(phase: UpdatePhase.current);
          await check();
        case InstallStatus.cancelled:
          state = state.copyWith(
            phase: UpdatePhase.ready,
            message: strings.installationCanceledYouCanRetry,
          );
        case InstallStatus.failed:
          state = state.copyWith(
            phase: UpdatePhase.ready,
            message: strings.installationDidNotFinishTryAgain,
          );
      }
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
          phase: UpdatePhase.ready,
          message: _message(error),
        );
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> _downloadCode() async {
    final update = state.codeUpdate;
    final gateway = codeGateway;
    if (state.busy ||
        state.codeReady ||
        !_active ||
        update == null ||
        gateway == null) {
      return;
    }
    state = state.copyWith(phase: UpdatePhase.downloading, received: 0);
    try {
      await gateway.apply(
        update,
        onProgress: (bytes) {
          if (mounted) {
            state = state.copyWith(
              phase: UpdatePhase.downloading,
              received: bytes,
            );
          }
        },
        onVerifying: () {
          if (mounted) state = state.copyWith(phase: UpdatePhase.verifying);
        },
      );
      if (!mounted) return;
      _restartFailed = false;
      state = state.copyWith(phase: UpdatePhase.ready, codeReady: true);
      await restartCode();
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
          phase: UpdatePhase.available,
          message: _message(error),
        );
      }
    }
  }

  void setActive(bool active) {
    _active = active;
    if (!active && state.isCode && state.phase == UpdatePhase.downloading) {
      codeGateway?.cancel();
    }
    // Resume only a restart requested during this run. A pending patch
    // discovered by the launch check waits for the user to choose restart.
    if (active &&
        state.codeReady &&
        state.codeUpdate != null &&
        !_restartFailed) {
      restartCode();
    }
  }

  Future<void> restartCode() async {
    if (!mounted || !_active || !state.codeReady || state.busy) return;
    state = state.copyWith(phase: UpdatePhase.restarting);
    try {
      await codeGateway!.restart();
      // A successful Android handoff terminates this process before the timer.
      await Future<void>.delayed(const Duration(seconds: 8));
      throw const UpdateFailure('restart');
    } catch (error) {
      if (!mounted) return;
      _restartFailed = true;
      state = state.copyWith(
        phase: UpdatePhase.ready,
        message: _message(error),
      );
    }
  }

  @override
  void dispose() {
    gateway.cancel();
    codeGateway?.cancel();
    super.dispose();
  }
}

String _message(Object error) {
  final code = error is UpdateFailure ? error.code : 'unknown';
  return switch (code) {
    'code_cancelled' => strings.patchDownloadCanceledYouCanDownloadIt,
    'code_signature' => strings.patchVerificationFailedCheckForUpdatesAgain,
    'restart_busy' => strings.finishTheCurrentConversationOrInputBefore,
    'restart' || 'background' => strings.patchReadyReturnHereToRestart,
    'cancelled' => strings.downloadPausedResumeToContinue,
    'network' => strings.connectionInterruptedTryAgain,
    'manifest' => strings.updateInformationIsUnavailableTryAgainLater,
    'abi' => strings.thisUpdateDoesNotSupportYourDevice,
    'signature' => strings.theUpdateSignatureDoesNotMatchThe,
    'checksum' ||
    'size' ||
    'file_invalid' => strings.verificationFailedDownloadTheUpdateAgain,
    'space' || 'storage' => strings.storageIsFullOrUnavailableFreeUp,
    'range' => strings.theDownloadServerIsUnavailableTryAgain,
    'permission' => strings.allowToworkToInstallAppsThenTap,
    'version' || 'wrong_package' => strings.thePackageOrVersionDoesNotMatch,
    'busy' => strings.anUpdateIsInProgressTryAgain,
    _ => strings.updateIncompleteTryAgain,
  };
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/speech_provider.dart';
import '../../../domain/speech/speech_input.dart';
import '../../../core/widgets/app_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Inspection never requests permission, records audio or calls the model.
class SpeechDiagnosticsSheet extends ConsumerStatefulWidget {
  const SpeechDiagnosticsSheet({super.key});
  @override
  ConsumerState<SpeechDiagnosticsSheet> createState() =>
      _SpeechDiagnosticsState();
}

class _SpeechDiagnosticsState extends ConsumerState<SpeechDiagnosticsSheet> {
  late Future<SpeechCapabilities> _inspection;
  @override
  void initState() {
    super.initState();
    _inspection = ref.read(speechInputProvider).inspect('zh-CN');
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
    child: FutureBuilder<SpeechCapabilities>(
      future: _inspection,
      builder: (context, snapshot) {
        final cap = snapshot.data;
        final waiting = snapshot.connectionState != ConnectionState.done;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (waiting) const Text('正在读取系统状态…'),
            if (snapshot.hasError) const Text('读取语音状态失败，请重试。'),
            if (!waiting && cap != null) ...[
              Text('识别服务：${cap.available ? '可用' : '不可用'}'),
              Text('麦克风与识别权限：${cap.authorized ? '已授权' : '未完全授权'}'),
              Text('设备端识别：${cap.onDeviceSupported ? '支持，需对应语言资源' : '未报告支持'}'),
              Text(
                cap.locales.isEmpty
                    ? '普通话：系统未提供语言清单'
                    : '系统语言：${cap.locales.join('、')}',
              ),
            ],
            const SizedBox(height: 6),
            Text(
              '仅检查普通话识别和当前权限，全程不录音。',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.of(context).labelSecondary,
              ),
            ),
            const SizedBox(height: 6),
            AppButton(
              label: '重新检测',
              type: AppButtonType.ghost,
              onPressed: waiting
                  ? null
                  : () => setState(() {
                      _inspection = ref
                          .read(speechInputProvider)
                          .inspect('zh-CN');
                    }),
            ),
          ],
        );
      },
    ),
  );
}

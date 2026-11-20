import 'package:towork/l10n/strings.dart';
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
    _inspection = ref.read(speechInputProvider).inspect(speechLocale);
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
            if (waiting) Text(context.strings.checkingSystemStatus),
            if (snapshot.hasError)
              Text(context.strings.couldntCheckSpeechStatusTryAgain),
            if (!waiting && cap != null) ...[
              Text(
                context.strings.recognitionService(
                  cap.available
                      ? context.strings.available
                      : context.strings.unavailableBuild2,
                ),
              ),
              Text(
                context.strings.microphoneAndSpeechPermissions(
                  cap.authorized
                      ? context.strings.granted
                      : context.strings.partiallyGranted,
                ),
              ),
              Text(
                context.strings.onDeviceRecognition(
                  cap.onDeviceSupported
                      ? context.strings.supportedWithInstalledLanguageResources
                      : context.strings.supportNotReported,
                ),
              ),
              Text(
                cap.locales.isEmpty
                    ? context.strings.mandarinLanguageListUnavailable
                    : context.strings.systemLanguages(cap.locales.join('、')),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              context
                  .strings
                  .checksMandarinRecognitionAndPermissionsWithoutRecording,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.of(context).labelSecondary,
              ),
            ),
            const SizedBox(height: 6),
            AppButton(
              label: context.strings.checkAgain,
              type: AppButtonType.ghost,
              onPressed: waiting
                  ? null
                  : () => setState(() {
                      _inspection = ref
                          .read(speechInputProvider)
                          .inspect(speechLocale);
                    }),
            ),
          ],
        );
      },
    ),
  );
}

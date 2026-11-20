import 'package:towork/l10n/strings.dart';

/// 语音 problem 的上屏白名单（错误脱敏边界）：
/// 只有语音链路已知的稳定本地文案允许进 Toast；未知字符串
/// （误传的原始异常、未来新增未复核的文案）一律退回通用文案，
/// 与 [chatFailureMessage] 的「未知错误不透传」同一策略。
Set<String> get _stableSpeechProblems => <String>{
  strings.voiceInputInterrupted,
  strings.couldntStartVoiceInput,
  strings.couldntHearThatTryAgain,
  strings.transcriptIsTooLongSplitItInto,
  strings.recognitionTimedOutTryAgain,
  strings.couldntSendYourTextIsSaved,
  strings.allowMicrophoneAccessInSystemSettings,
  strings.selectedLanguageIsUnavailable,
  strings.thisRecognizerDoesNotSupportOnDevice,
  strings.couldntConnectToSpeechService,
  strings.microphoneInUse,
  strings.recordingInterrupted,
  strings.voiceInputUnavailable,
};

String speechProblemMessage(String? problem) =>
    problem != null && _stableSpeechProblems.contains(problem)
    ? problem
    : strings.voiceInputFailedYourTranscriptIsSaved;

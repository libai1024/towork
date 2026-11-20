import '../ai/permission_policy.dart';

enum PreferenceFailureCode { invalid, conflict, storage }

class PreferenceFailure implements Exception {
  const PreferenceFailure(this.code);
  final PreferenceFailureCode code;
  @override
  String toString() => 'PreferenceFailure(${code.name})';
}

/// Portable business preferences. No credential, device path or account balance.
class AppPreferences {
  const AppPreferences({
    this.version = 0,
    this.theme = 'system',
    this.language = 'system',
    this.inputMode = 'voice',
    this.permission = AiWritePermission.askOnChange,
    this.memoryPaused = false,
    this.notifyDue = true,
    this.notifyMorning = true,
    this.morningHour = 8,
    this.morningMinute = 30,
    this.notifyReport = true,
    this.fontScale = 1.0,
    this.lastExportAt = 0,
    this.autoRoute = false,
    this.customInstructions = '',
    this.speechVocabulary = const [],
  });
  final int version;
  final String theme;
  final String language;
  final String inputMode;
  final AiWritePermission permission;
  final bool memoryPaused;
  final bool notifyDue;
  final bool notifyMorning;
  final int morningHour;
  final int morningMinute;
  final bool notifyReport;

  /// 全局字号倍率（外观设置）：小 0.9 / 标准 1.0 / 大 1.15。
  final double fontScale;

  /// 最近一次一键导出的毫秒时间戳；0 = 尚未导出。
  final int lastExportAt;

  /// 模型自动路由：按优先级选账户，额度用尽或出错时换下一个。
  /// 默认关闭——不经用户同意不会换用别的 Key。
  final bool autoRoute;

  /// 用户写给助手的长期说明（称呼、习惯、偏好），每次对话都带上。
  final String customInstructions;

  /// 语音识别常错的专有名词，识别后按读音纠正。
  final List<String> speechVocabulary;

  static const maxInstructionLength = 2000;
  static const maxVocabulary = 200;
  static const maxVocabularyLength = 24;

  Map<String, Object?> toJson() => {
    'theme': theme,
    'language': language,
    'input_mode': inputMode,
    'permission': permission.name,
    'memory_paused': memoryPaused,
    'notify_due': notifyDue,
    'notify_morning': notifyMorning,
    'morning_hour': morningHour,
    'morning_minute': morningMinute,
    'notify_report': notifyReport,
    'font_scale': fontScale,
    'last_export_at': lastExportAt,
    'auto_route': autoRoute,
    'custom_instructions': customInstructions,
    'speech_vocabulary': speechVocabulary,
  };

  factory AppPreferences.fromJson(
    Map<String, Object?> data, {
    required int version,
  }) {
    // 后来新增的字段对旧负载宽松：缺失取默认值。
    const requiredFields = {
      'theme',
      'input_mode',
      'permission',
      'memory_paused',
      'notify_due',
      'notify_morning',
      'morning_hour',
      'morning_minute',
      'notify_report',
    };
    const knownFields = {
      ...requiredFields,
      'language',
      'font_scale',
      'last_export_at',
      'auto_route',
      'custom_instructions',
      'speech_vocabulary',
    };
    final fontScale = data['font_scale'];
    final lastExportAt = data['last_export_at'];
    final autoRoute = data['auto_route'];
    final instructions = data['custom_instructions'];
    final vocabulary = data['speech_vocabulary'];
    if (data.keys.any((key) => !knownFields.contains(key)) ||
        requiredFields.any((key) => !data.containsKey(key)) ||
        version < 0 ||
        (data.containsKey('language') &&
            !{'system', 'en', 'zh'}.contains(data['language'])) ||
        !{'system', 'light', 'dark'}.contains(data['theme']) ||
        !{'voice', 'keyboard'}.contains(data['input_mode']) ||
        !AiWritePermission.values.any((p) => p.name == data['permission']) ||
        ![
          'memory_paused',
          'notify_due',
          'notify_morning',
          'notify_report',
        ].every((key) => data[key] is bool) ||
        data['morning_hour'] is! int ||
        data['morning_minute'] is! int ||
        (data['morning_hour']! as int) < 0 ||
        (data['morning_hour']! as int) > 23 ||
        (data['morning_minute']! as int) < 0 ||
        (data['morning_minute']! as int) > 59 ||
        (fontScale != null &&
            (fontScale is! num || fontScale < 0.85 || fontScale > 1.3)) ||
        (lastExportAt != null && (lastExportAt is! int || lastExportAt < 0)) ||
        (autoRoute != null && autoRoute is! bool) ||
        (instructions != null &&
            (instructions is! String ||
                instructions.length > maxInstructionLength)) ||
        (vocabulary != null &&
            (vocabulary is! List ||
                vocabulary.length > maxVocabulary ||
                vocabulary.any(
                  (word) =>
                      word is! String ||
                      word.trim().isEmpty ||
                      word.length > maxVocabularyLength,
                )))) {
      throw const PreferenceFailure(PreferenceFailureCode.invalid);
    }
    return AppPreferences(
      version: version,
      theme: data['theme']! as String,
      language: data['language'] as String? ?? 'system',
      inputMode: data['input_mode']! as String,
      permission: AiWritePermission.values.byName(
        data['permission']! as String,
      ),
      memoryPaused: data['memory_paused']! as bool,
      notifyDue: data['notify_due']! as bool,
      notifyMorning: data['notify_morning']! as bool,
      morningHour: data['morning_hour']! as int,
      morningMinute: data['morning_minute']! as int,
      notifyReport: data['notify_report']! as bool,
      fontScale: fontScale == null ? 1.0 : (fontScale as num).toDouble(),
      lastExportAt: lastExportAt == null ? 0 : lastExportAt as int,
      autoRoute: autoRoute as bool? ?? false,
      customInstructions: instructions as String? ?? '',
      speechVocabulary: vocabulary == null
          ? const []
          : List.unmodifiable((vocabulary as List).cast<String>()),
    );
  }

  AppPreferences patch(
    Map<String, Object?> changes, {
    required int nextVersion,
  }) =>
      AppPreferences.fromJson({...toJson(), ...changes}, version: nextVersion);
}

abstract interface class AppPreferencesStore {
  Future<AppPreferences> loadOrCreate({String legacyInputMode = 'voice'});
  Future<AppPreferences> update(
    Map<String, Object?> changes, {
    required int expectedVersion,
  });
}

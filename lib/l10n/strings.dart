import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';
import 'generated/app_localizations_en.dart';
import 'generated/app_localizations_zh.dart';

export 'generated/app_localizations.dart' show AppLocalizations;

final _chinese = AppLocalizationsZh();
final _english = AppLocalizationsEn();

// Each Flutter engine resolves its own language. Formatters without a widget
// context use the same catalog as the window rendering their result.
AppLocalizations _current = _chinese;
AppLocalizations get strings => _current;

String get speechLocale => strings.localeName == 'en' ? 'en-US' : 'zh-CN';

Locale? preferredLocale(String language) =>
    language == 'system' ? null : Locale(language);

Locale resolveAppLocale(List<Locale>? preferred, Iterable<Locale> supported) {
  final locale = preferred
      ?.map((l) => l.languageCode)
      .firstWhere((code) => code == 'zh' || code == 'en', orElse: () => 'zh');
  return Locale(locale ?? 'zh');
}

// Put the engine delegate first. Flutter loads one delegate per resource type.
const appLocalizationDelegates = <LocalizationsDelegate<dynamic>>[
  _WindowStringsDelegate(),
  ...AppLocalizations.localizationsDelegates,
];

class _WindowStringsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _WindowStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.delegate.isSupported(locale);

  @override
  Future<AppLocalizations> load(Locale locale) {
    _current = locale.languageCode == 'en' ? _english : _chinese;
    return SynchronousFuture(_current);
  }

  @override
  bool shouldReload(_WindowStringsDelegate old) => false;
}

/// A saved report can contain headings produced in either supported language.
bool matchesReportHeading(
  String text,
  String Function(AppLocalizations) heading,
) => text.contains(heading(_chinese)) || text.contains(heading(_english));

extension LocalizedContext on BuildContext {
  AppLocalizations get strings =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ?? _current;
}

/// For built-in catalog and enum labels only. Keep custom names and user content verbatim.
String localizedBuiltin(String label) => switch (label) {
  '5 小时' => strings.hoursOrder,
  'AI 写入待办和表格前都会先确认' => strings.askBeforeTheAiChangesTasksOr,
  'DeepSeek 开放平台' => strings.deepseekPlatform,
  'GLM Coding Plan 编程订阅' => strings.glmCodingPlanSubscription,
  'Key 无效' => strings.invalidKey,
  'Kimi Code 编程订阅' => strings.kimiCodeSubscription,
  'Kimi K2.8 高速' => strings.kimiKHighspeed,
  'Kimi 开放平台' => strings.kimiPlatform,
  'OpenAI 兼容接口' => strings.openaiCompatibleApi,
  '中' => strings.medium,
  '乐章' => strings.movement,
  '事件' => strings.event,
  '事实' => strings.fact,
  '件' => strings.itemsVizStats,
  '低' => strings.low,
  '偏好' => strings.preference,
  '免费版' => strings.free,
  '全部' => strings.allLabel,
  '分布' => strings.distribution,
  '周报' => strings.weeklyReport,
  '完成 Todo 数' => strings.tasksCompleted,
  '山岳' => strings.mountain,
  '已过期' => strings.expired,
  '待办新增、编辑、完成直接生效，删除前确认；表格写入需确认' =>
    strings.applyTaskAdditionsEditsAndCompletionsImmediately,
  '待办自动执行并保留修改记录；表格写入仍需确认' => strings.applyTaskChangesAndKeepAHistory,
  '快速' => strings.fast,
  '快问' => strings.quickAsk,
  '总是询问' => strings.alwaysAsk,
  '意图识别' => strings.intentRecognition,
  '截图分析' => strings.screenshotAnalysis,
  '报告生成' => strings.reportGeneration,
  '新增 Todo 数' => strings.tasksAdded,
  '新增数据条数' => strings.recordsAdded,
  '日历' => strings.calendar,
  '日常对话' => strings.chat,
  '日程' => strings.schedule,
  '智能确认' => strings.smartConfirmation,
  '智谱 GLM' => strings.zhipuGlm,
  '智谱 GLM 开放平台' => strings.zhipuGlmPlatform,
  '月报' => strings.monthlyReport,
  '有效' => strings.active,
  '服务暂时异常' => strings.serviceTemporarilyUnavailable,
  '未分类' => strings.uncategorized,
  '条' => strings.rowsVizStats,
  '查看待办来源会话' => strings.viewTaskSourceChat,
  '查看来源会话' => strings.viewSourceChat,
  '模型不可用' => strings.modelUnavailable,
  '此订阅限指定编程工具使用，其他客户端可能被限流或停用。' =>
    strings.thisPlanIsRestrictedToSupportedCoding,
  '每周' => strings.weeklyBuild,
  '每日' => strings.dailyOrder,
  '每月' => strings.monthlyBuild,
  '没有访问权限' => strings.accessDenied,
  '热力图' => strings.heatmap,
  '画像' => strings.profile,
  '联网工具 每月' => strings.webToolsMonthly,
  '自动执行' => strings.runAutomatically,
  '自定义' => strings.custom,
  '请求过于频繁' => strings.tooManyRequests,
  '趋势' => strings.trends,
  '额度已用尽' => strings.quotaExhausted,
  '高' => strings.high,
  _ => label,
};

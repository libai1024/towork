import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_profile_provider.dart';
import 'update/update_provider.dart';
import 'app_preferences_provider.dart';
import 'local_workspace_session.dart';
import 'local_business_projection.dart';
import 'local_database_provider.dart';
import 'local_chat_runtime.dart';

import '../domain/models/models.dart';
import '../data/repositories/category_repository.dart';
import '../domain/repositories/category_store.dart';
import '../data/repositories/todo_repository.dart';
import '../domain/repositories/todo_store.dart';
import '../data/repositories/chat_repository.dart';
import '../domain/repositories/chat_store.dart';
import '../data/repositories/memory_repository.dart';
import '../domain/repositories/memory_store.dart';
import '../data/repositories/report_repository.dart';
import '../domain/repositories/report_store.dart';
import '../data/repositories/data_table_repository.dart';
import '../domain/repositories/data_table_store.dart';
import '../data/repositories/quota_repository.dart';
import '../domain/repositories/quota_store.dart';

import '../data/seeds/data_table_seed.dart' show dataTableTemplates;

export '../domain/repositories/category_store.dart';
export '../domain/repositories/todo_store.dart';
export '../domain/repositories/chat_store.dart';
export '../domain/repositories/memory_store.dart';
export '../domain/repositories/report_store.dart';
export '../domain/repositories/data_table_store.dart';
export '../domain/repositories/quota_store.dart';

final userProfileProvider = Provider<UserProfile>((ref) {
  final profile = ref.watch(localProfileSnapshotProvider);
  return profile == null
      ? const UserProfile(nickname: '登月者0830', tier: 'Allegretto')
      : UserProfile(
          nickname: profile.nickname,
          tier: '免费版',
          hasDefaultNickname:
              profile.version == 1 && profile.nickname == '本地用户',
        );
});

final categoryListProvider =
    StateNotifierProvider<CategoryStore, List<Category>>(
      (ref) =>
          ref.watch(localWorkspaceSessionProvider)?.categories ??
          CategoryRepository(),
    );

final todoListProvider = StateNotifierProvider<TodoReadStore, List<Todo>>(
  (ref) => ref.watch(localWorkspaceSessionProvider)?.todos ?? TodoRepository(),
);

/// 某分类（含子分类）的活跃 Todo 计数。
final activeTodoCountProvider = Provider.family<int, String>((ref, categoryId) {
  final todos = ref.watch(todoListProvider);
  final categories = ref.watch(categoryListProvider);
  final ids = <String>{categoryId};
  for (final c in categories) {
    if (c.parentId == categoryId) ids.add(c.id);
  }
  return todos.where((t) => t.isActive && ids.contains(t.categoryId)).length;
});

/// 分类统计聚合（04-categories.md §8.2）：未完成/已完成计数与完成率。
/// 一级分类为含子分类聚合值；子分类天然只统计自身（无后代）。
class CategoryStats {
  const CategoryStats({required this.open, required this.done});

  final int open;
  final int done;

  /// 0–100 整数；无待办时为 null（UI 显示「—」）。
  int? get completionRate {
    final total = open + done;
    if (total == 0) return null;
    return (done * 100 / total).round();
  }
}

final categoryStatsProvider = Provider.family<CategoryStats, String>((
  ref,
  categoryId,
) {
  final todos = ref.watch(todoListProvider);
  final categories = ref.watch(categoryListProvider);
  final ids = <String>{categoryId};
  for (final c in categories) {
    if (c.parentId == categoryId) ids.add(c.id);
  }
  var open = 0;
  var done = 0;
  for (final t in todos) {
    if (t.categoryId == null || !ids.contains(t.categoryId)) continue;
    if (t.status == TodoStatus.done) {
      done++;
    } else if (t.isActive) {
      open++;
    }
  }
  return CategoryStats(open: open, done: done);
});

final sessionListProvider = StateNotifierProvider<ChatStore, List<ChatSession>>(
  (ref) => ref.watch(localChatRuntimeProvider)?.projection ?? ChatRepository(),
);

final memoryListProvider =
    StateNotifierProvider<MemoryStore, List<MemoryEntry>>(
      (ref) => MemoryRepository(),
    );

/// 免记忆模式全局开关（08-memory.md §8.3）：开启后新对话不写入记忆库，
/// 存量记忆照常可管理，手动新增禁用。
final memoryPausedProvider = StateProvider<bool>(
  (ref) =>
      ref.watch(appPreferencesSnapshotProvider.select((p) => p.memoryPaused)),
);

final reportListProvider = StateNotifierProvider<ReportStore, List<Report>>(
  (ref) => ReportRepository(),
);

/// 手动生成上次勾选的分类（null = 首次，默认全选）。
final reportLastCategoryIdsProvider = StateProvider<Set<String>?>(
  (ref) => null,
);

/// 「保存为定时报告默认范围」写入的集合。
final reportDefaultCategoryIdsProvider = StateProvider<Set<String>>(
  (ref) => const {},
);

final dataTableProvider =
    StateNotifierProvider<DataTableStore, DataTableBundle>((ref) {
      final session = ref.watch(localWorkspaceSessionProvider);
      if (session == null) return DataTableRepository();
      final db = ref.read(localDatabaseProvider).requireValue;
      return LocalBusinessProjection(session, db);
    });

// ---------------------------------------------------------------------------
// 额度
// ---------------------------------------------------------------------------

final quotaProvider = StateProvider<QuotaInfo>(
  (ref) => const QuotaInfo(
    usedPct5h: 0.32,
    usedPctWeekly: 0.58,
    usedPctMonthly: 0.41,
  ),
);

// ---------------------------------------------------------------------------
// 设置（09-settings-quota.md §8）：外观 / 通知 / AI 行为 / 备份 / 关于
// ---------------------------------------------------------------------------

/// 主题模式：月之亮面 = light，月之暗面 = dark，默认跟随系统。
/// main.dart 的 MaterialApp 直接 watch 本 provider，切换真实生效。
final themeModeProvider = StateProvider<ThemeMode>(
  (ref) => ThemeMode.values.byName(
    ref.watch(appPreferencesSnapshotProvider.select((p) => p.theme)),
  ),
);

/// 全局字号（外观设置）：小 0.9 / 标准 1.0 / 大 1.15。
/// main.dart 以此覆盖系统文字缩放，切换全应用生效。
final fontScaleProvider = StateProvider<double>(
  (ref) => ref.watch(appPreferencesSnapshotProvider.select((p) => p.fontScale)),
);

/// AI 写入权限三档（F6.3），默认「智能确认」。
final aiWritePermissionProvider = StateProvider<AiWritePermission>(
  (ref) =>
      ref.watch(appPreferencesSnapshotProvider.select((p) => p.permission)),
);

final notifyDueEnabledProvider = StateProvider<bool>(
  (ref) => ref.watch(appPreferencesSnapshotProvider.select((p) => p.notifyDue)),
);
final notifyMorningEnabledProvider = StateProvider<bool>(
  (ref) =>
      ref.watch(appPreferencesSnapshotProvider.select((p) => p.notifyMorning)),
);

/// 每日晨报时间 (hour, minute)，默认 08:30。
final notifyMorningTimeProvider = StateProvider<(int, int)>(
  (ref) => ref.watch(
    appPreferencesSnapshotProvider.select(
      (p) => (p.morningHour, p.morningMinute),
    ),
  ),
);

final notifyReportEnabledProvider = StateProvider<bool>(
  (ref) =>
      ref.watch(appPreferencesSnapshotProvider.select((p) => p.notifyReport)),
);

/// 服务端连接状态（mock 常连）。
final serverConnectionProvider = Provider<ServerConnection>(
  (ref) => const ServerConnection(connected: true, address: '192.168.1.8'),
);

/// 读取已安装包的真实版本。
final appVersionProvider = Provider<String>(
  (ref) =>
      ref.watch(installedAppProvider).valueOrNull?.label ?? strings.loading,
);

/// 当前档位（Allegretto）能力清单（规范 §7.2）。
final tierCapabilitiesProvider = Provider<List<TierCapability>>(
  (ref) => [
    TierCapability(name: strings.kFlagshipModel, unlocked: true),
    TierCapability(name: strings.mContextWindow, unlocked: true),
    TierCapability(name: strings.highspeed, unlocked: true),
    TierCapability(name: strings.videoInput, unlocked: false),
  ],
);

/// 可选模型清单（§8 available_models[]；Allegretto 档位全部解锁）。
final availableModelsProvider = Provider<List<AiModel>>(
  (ref) => [
    AiModel(id: 'k3-256k', note: '256K'),
    AiModel(id: 'k3', note: strings.mQuota),
    AiModel(id: 'kimi-for-coding', note: 'K2.8 Preview 1M'),
    AiModel(id: 'kimi-for-coding-highspeed', note: strings.highSpeedQuota),
    AiModel(id: 'deepseek-flash', note: strings.vMWithVision),
    AiModel(id: 'deepseek-v4-pro', note: strings.deepReasoning),
  ],
);

/// 四场景模型分配（F7.2 默认分配，可在 AI 与额度页就地改）。
final scenarioModelMapProvider = StateProvider<Map<ModelScenario, String>>(
  (ref) => const {
    ModelScenario.intent: 'kimi-for-coding-highspeed',
    ModelScenario.chat: 'k3-256k',
    ModelScenario.report: 'k3',
    ModelScenario.vision: 'k3',
  },
);

final quotaDetailProvider = StateNotifierProvider<QuotaStore, QuotaState>(
  (ref) => QuotaRepository(),
);

final dataTableTemplatesProvider = Provider<List<DataTableTemplate>>(
  (ref) => dataTableTemplates,
);

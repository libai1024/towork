import 'package:towork/l10n/strings.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/ai/model_gateway.dart';
import '../../domain/ai/quota.dart';
import '../../domain/settings/model_accounts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_text_styles.dart';

/// 额度的文字与进度条表达，设置页、模型选择器和侧栏共用，保证三处说法一致。

/// 「2 小时 5 分后重置」。已过期或未知时返回 null。
String? quotaResetLabel(DateTime? resetAt, DateTime now) {
  if (resetAt == null) return null;
  final left = resetAt.difference(now);
  if (left.isNegative) return null;
  if (left.inMinutes < 1) return strings.resetsSoon;
  if (left.inHours < 1) return strings.resetsInMin(left.inMinutes);
  if (left.inHours < 24) {
    final minutes = left.inMinutes % 60;
    return minutes == 0
        ? strings.resetsInHr(left.inHours)
        : strings.resetsInHrMin(left.inHours, minutes);
  }
  return strings.resetsInDays(left.inDays);
}

/// 余额文本：`¥12.34`。未知币种按原样跟在后面。
String balanceLabel(double balance, String? currency) {
  final amount = balance.toStringAsFixed(2);
  return switch (currency) {
    'CNY' || null => '¥$amount',
    'USD' => '\$$amount',
    final other => '$amount $other',
  };
}

/// 账户的一句话状态，按「最需要用户知道的」排序：
/// 没有 Key → 冷却中 → 额度 → 余额 → 计费方式。
String accountStatusLabel(ModelAccount account, DateTime now) {
  if (!account.hasCredential) return strings.noKey;
  if (account.coolingAt(now)) {
    final until = quotaResetLabel(account.cooldownUntil, now);
    final reason = account.cooldownReason ?? strings.unavailable;
    return until == null
        ? reason
        : '$reason ${until.replaceAll(strings.reset, strings.restore)}';
  }
  final quota = account.quota;
  if (quota != null) {
    final tightest = quota.tightest;
    if (tightest != null) {
      final left = (tightest.remainingRatio * 100).round();
      return strings.left(_windowLabel(tightest.label), left);
    }
    if (quota.balance != null) {
      return strings.balance(balanceLabel(quota.balance!, quota.currency));
    }
  }
  return account.descriptor.accessLabel;
}

/// 额度是否值得警示：剩余不足两成、已用尽，或处于冷却。
bool accountNeedsAttention(ModelAccount account, DateTime now) {
  if (!account.hasCredential || account.coolingAt(now)) return true;
  final quota = account.quota;
  if (quota == null) return false;
  if (quota.exhausted) return true;
  final tightest = quota.tightest;
  return tightest != null && tightest.remainingRatio < .2;
}

/// 细进度条：已用部分为陶土橙，接近用尽时转为警示色。
class QuotaMeter extends StatelessWidget {
  const QuotaMeter({
    super.key,
    required this.usedRatio,
    this.height = 4,
    this.showRemaining = false,
  });
  final double usedRatio;
  final double height;
  final bool showRemaining;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ratio = usedRatio.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: AppRadii.brFull,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: c.fill2),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: showRemaining ? 1.0 - ratio : ratio,
              child: ColoredBox(color: ratio >= .8 ? c.red : c.accent),
            ),
          ],
        ),
      ),
    );
  }
}

/// 一个额度窗口：名称 + 已用百分比 + 重置时间 + 进度条。
class QuotaWindowMeter extends StatelessWidget {
  const QuotaWindowMeter({
    super.key,
    required this.window,
    required this.now,
    this.dense = false,
  });
  final QuotaWindow window;
  final DateTime now;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final used = (window.usedRatio.clamp(0.0, 1.0) * 100).round();
    final reset = quotaResetLabel(window.resetAt, now);
    final style = AppTextStyles.caption.copyWith(color: c.labelSecondary);
    return Semantics(
      label: context.strings.quotaUsed(
        _windowLabel(window.label),
        used,
        reset == null ? '' : '，$reset',
      ),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: [
                    Text(
                      _windowLabel(window.label),
                      style: style.copyWith(color: c.labelPrimary),
                    ),
                    if (!dense && reset != null) Text(reset, style: style),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                context.strings.used(used),
                style: style.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          SizedBox(height: dense ? 2 : 4),
          QuotaMeter(usedRatio: window.usedRatio),
        ],
      ),
    );
  }
}

/// 账户的完整额度区：订阅窗口逐条列出；按量账户显示余额；
/// 没有额度接口的服务商如实说明。
class AccountQuotaBlock extends StatelessWidget {
  const AccountQuotaBlock({
    super.key,
    required this.account,
    required this.now,
    this.dense = false,
  });
  final ModelAccount account;
  final DateTime now;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final quota = account.quota;
    final caption = AppTextStyles.caption.copyWith(color: c.labelSecondary);
    if (quota == null) {
      return Text(
        account.descriptor.quota == QuotaSource.none
            ? context.strings.checkQuotaInTheProviderConsole
            : context.strings.quotaNotCheckedYet,
        style: caption,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < quota.windows.length; i++) ...[
          if (i > 0) SizedBox(height: dense ? 4 : 6),
          QuotaWindowMeter(window: quota.windows[i], now: now, dense: dense),
        ],
        if (quota.balance != null) ...[
          if (quota.windows.isNotEmpty) SizedBox(height: dense ? 4 : 6),
          Row(
            children: [
              Expanded(
                child: Text(context.strings.accountBalance, style: caption),
              ),
              const SizedBox(width: 6),
              Text(
                balanceLabel(quota.balance!, quota.currency),
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: quota.balance! <= 0 ? c.red : c.labelPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Remaining allowances in a single horizontally scrollable strip.
class CompactQuotaWindows extends StatelessWidget {
  const CompactQuotaWindows({super.key, required this.windows});
  final List<QuotaWindow> windows;

  @override
  Widget build(BuildContext context) {
    final sorted = [...windows];
    int order(QuotaWindow window) => switch (window.label) {
      '5 小时' => 0,
      '1 天' || '24 小时' || '每日' => 1,
      '每周' => 2,
      '每月' => 3,
      _ => 4,
    };
    sorted.sort((a, b) => order(a).compareTo(order(b)));
    return LayoutBuilder(
      builder: (context, bounds) {
        final minCell = MediaQuery.textScalerOf(context).scale(62);
        final width = math.max(
          bounds.maxWidth,
          minCell * sorted.length + 8 * (sorted.length - 1),
        );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var i = 0; i < sorted.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _QuotaCell(window: sorted[i])),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuotaCell extends StatelessWidget {
  const _QuotaCell({required this.window});
  final QuotaWindow window;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final label = switch (window.label) {
      '5 小时' => '5h',
      '1 天' || '24 小时' || '每日' => context.strings.daily,
      '每周' => context.strings.weekly,
      '每月' => context.strings.monthly,
      _ => _windowLabel(window.label),
    };
    final value = '${(window.remainingRatio * 100).round()}%';
    final caption = AppTextStyles.caption.copyWith(
      color: colors.labelSecondary,
    );
    final values = Row(
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: caption,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: caption.copyWith(
            color: colors.labelPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
    return Semantics(
      excludeSemantics: true,
      label: context.strings.remaining(_windowLabel(window.label), value),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          values,
          const SizedBox(height: 3),
          QuotaMeter(
            usedRatio: window.usedRatio,
            height: 3,
            showRemaining: true,
          ),
        ],
      ),
    );
  }
}

String _windowLabel(String value) {
  if (value == '额度') return strings.quota;
  if (value == '周期额度') return strings.periodQuota;
  final duration = RegExp(r'^(\d+) (天|小时|分钟)$').firstMatch(value);
  if (duration == null) return localizedBuiltin(value);
  final count = int.parse(duration[1]!);
  return switch (duration[2]) {
    '天' => strings.windowDays(count),
    '小时' => strings.windowHours(count),
    _ => strings.windowMinutes(count),
  };
}

/// 模型服务商目录：每个服务商的端点、计费方式、模型清单、思考参数与额度
/// 来源都在这里声明一次。新增服务商 = 新增一条描述，不再到处改 switch。
library;

enum ProviderRegion { china, international }

/// [wireId] 是落库与运行记录里的稳定标识，重命名 Dart 枚举不影响存量数据。
enum ProviderKind {
  moonshot('platform'),
  kimiCode('code'),
  deepseek('deepseek'),
  zhipu('zhipu'),
  zhipuCoding('zhipu_coding'),
  custom('custom');

  const ProviderKind(this.wireId);
  final String wireId;

  static ProviderKind fromWire(String id) => values.firstWhere(
    (kind) => kind.wireId == id,
    orElse: () => throw ArgumentError.value(id, 'id', 'Unknown provider'),
  );
}

enum ProviderBilling { subscription, payAsYouGo, unknown }

/// 该服务商如何查询剩余额度。none 表示没有可用接口，界面只显示本机用量。
enum QuotaSource {
  none,
  kimiCodeUsages,
  moonshotBalance,
  deepseekBalance,
  zhipuCodingQuota,
}

/// 「少思考」如何表达。服务商之间不通用，发错参数会被拒绝。
enum ThinkingControl {
  /// `thinking: {type: disabled}` 可以关闭思考。
  toggle,

  /// 不能关闭，只能用 `reasoning_effort: low` 压到最低。
  effort,

  /// 不发送任何思考参数。
  none,
}

class ModelPreset {
  const ModelPreset(
    this.id,
    this.label, {
    this.vision = false,
    this.thinking,
    this.fast = false,
  });
  final String id;
  final String label;

  /// 是否接受图片输入。未收录的模型视为未知，由用户自行判断。
  final bool vision;

  /// 覆盖服务商默认的思考控制方式。
  final ThinkingControl? thinking;

  /// 速度优先的小模型，路由可用于「快速」场景。
  final bool fast;
}

class ProviderDescriptor {
  const ProviderDescriptor({
    required this.kind,
    required this.label,
    required this.shortLabel,
    required this.billing,
    required this.models,
    this.chinaBase,
    this.internationalBase,
    this.thinking = ThinkingControl.toggle,
    this.quota = QuotaSource.none,
    this.notice,
  });

  final ProviderKind kind;
  final String label;
  final String shortLabel;
  final ProviderBilling billing;

  final List<ModelPreset> models;

  /// OpenAI 兼容根地址（不含 `/chat/completions`）。custom 由用户填写。
  final String? chinaBase;
  final String? internationalBase;
  final ThinkingControl thinking;
  final QuotaSource quota;

  /// 使用条款或适用范围提示，保存前展示给用户。
  final String? notice;

  /// Shows the access type. Custom endpoints use an API with provider-defined pricing.
  String get accessLabel =>
      billing == ProviderBilling.subscription ? 'plan' : 'api';

  bool get regional => internationalBase != null;
  bool get needsBaseUrl => chinaBase == null;

  ModelPreset? preset(String model) {
    for (final item in models) {
      if (item.id == model) return item;
    }
    return null;
  }

  ThinkingControl thinkingFor(String model) =>
      preset(model)?.thinking ?? thinking;

  /// 根地址：custom 取用户填写值，其余按区域取内置地址。
  String? baseFor(ProviderRegion region, {String? customBase}) {
    if (needsBaseUrl) return customBase;
    return region == ProviderRegion.international
        ? internationalBase ?? chinaBase
        : chinaBase;
  }

  Uri completionsUri(ProviderRegion region, {String? customBase}) =>
      resolve(region, 'chat/completions', customBase: customBase);

  /// 在根地址下拼接相对路径，保留根地址已有的路径前缀。
  Uri resolve(ProviderRegion region, String path, {String? customBase}) {
    final base = baseFor(region, customBase: customBase);
    if (base == null) throw StateError('Provider base URL is missing');
    final trimmed = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final parsed = Uri.parse(trimmed);
    return parsed.replace(path: '${parsed.path}/$path');
  }
}

/// 所有内置服务商。顺序即界面展示顺序。
abstract final class ProviderCatalog {
  static const _kimiModels = [
    ModelPreset(
      'k3',
      'Kimi K3',
      vision: true,
      thinking: ThinkingControl.effort,
    ),
    ModelPreset(
      'k3-256k',
      'Kimi K3 256K',
      vision: true,
      thinking: ThinkingControl.effort,
    ),
  ];

  static const all = <ProviderDescriptor>[
    ProviderDescriptor(
      kind: ProviderKind.kimiCode,
      label: 'Kimi Code 编程订阅',
      shortLabel: 'Kimi Code',
      billing: ProviderBilling.subscription,
      chinaBase: 'https://api.kimi.com/coding/v1',
      internationalBase: 'https://api.kimi.ai/coding/v1',
      quota: QuotaSource.kimiCodeUsages,
      models: [
        ModelPreset('kimi-for-coding', 'Kimi K2.8', vision: true),
        ModelPreset(
          'kimi-for-coding-highspeed',
          'Kimi K2.8 高速',
          vision: true,
          fast: true,
        ),
        ..._kimiModels,
        ModelPreset(
          'k3.1-pro',
          'Kimi K3.1 Pro',
          vision: true,
          thinking: ThinkingControl.effort,
        ),
      ],
    ),
    ProviderDescriptor(
      kind: ProviderKind.zhipuCoding,
      label: 'GLM Coding Plan 编程订阅',
      shortLabel: 'GLM Coding',
      billing: ProviderBilling.subscription,
      chinaBase: 'https://open.bigmodel.cn/api/coding/paas/v4',
      internationalBase: 'https://api.z.ai/api/coding/paas/v4',
      thinking: ThinkingControl.effort,
      quota: QuotaSource.zhipuCodingQuota,
      notice: '此订阅限指定编程工具使用，其他客户端可能被限流或停用。',
      models: [
        ModelPreset('glm-5.3', 'GLM-5.3'),
        ModelPreset('glm-5.3-flash', 'GLM-5.3 Flash', vision: true, fast: true),
      ],
    ),
    ProviderDescriptor(
      kind: ProviderKind.deepseek,
      label: 'DeepSeek 开放平台',
      shortLabel: 'DeepSeek',
      billing: ProviderBilling.payAsYouGo,
      chinaBase: 'https://api.deepseek.com',
      quota: QuotaSource.deepseekBalance,
      models: [
        ModelPreset('deepseek-flash', 'DS Flash', vision: true, fast: true),
        ModelPreset('deepseek-v4-pro', 'DS V4 Pro'),
      ],
    ),
    ProviderDescriptor(
      kind: ProviderKind.moonshot,
      label: 'Kimi 开放平台',
      shortLabel: 'Kimi',
      billing: ProviderBilling.payAsYouGo,
      chinaBase: 'https://api.moonshot.cn/v1',
      internationalBase: 'https://api.moonshot.ai/v1',
      quota: QuotaSource.moonshotBalance,
      models: [
        ModelPreset(
          'kimi-k3',
          'Kimi K3',
          vision: true,
          thinking: ThinkingControl.effort,
        ),
        ModelPreset(
          'kimi-k3.1-pro',
          'Kimi K3.1 Pro',
          vision: true,
          thinking: ThinkingControl.effort,
        ),
        ModelPreset('kimi-k2.6', 'Kimi K2.6', vision: true),
        ..._kimiModels,
      ],
    ),
    ProviderDescriptor(
      kind: ProviderKind.zhipu,
      label: '智谱 GLM 开放平台',
      shortLabel: '智谱 GLM',
      billing: ProviderBilling.payAsYouGo,
      chinaBase: 'https://open.bigmodel.cn/api/paas/v4',
      internationalBase: 'https://api.z.ai/api/paas/v4',
      models: [
        ModelPreset(
          'glm-5.3-flash',
          'GLM-5.3 Flash',
          vision: true,
          thinking: ThinkingControl.effort,
          fast: true,
        ),
        ModelPreset('glm-5.3', 'GLM-5.3', thinking: ThinkingControl.effort),
        ModelPreset('glm-4.7-flash', 'GLM-4.7 Flash', fast: true),
        ModelPreset('glm-4.7', 'GLM-4.7'),
      ],
    ),
    ProviderDescriptor(
      kind: ProviderKind.custom,
      label: 'OpenAI 兼容接口',
      shortLabel: '自定义',
      billing: ProviderBilling.unknown,
      thinking: ThinkingControl.none,
      models: [],
    ),
  ];

  static ProviderDescriptor of(ProviderKind kind) =>
      all.firstWhere((item) => item.kind == kind);

  /// 模型短名：先查所属服务商，再查全部目录，最后截断原始 ID。
  static String modelLabel(String model, {ProviderKind? kind}) {
    final own = kind == null ? null : of(kind).preset(model);
    if (own != null) return own.label;
    for (final provider in all) {
      final preset = provider.preset(model);
      if (preset != null) return preset.label;
    }
    return model.length > 18 ? '${model.substring(0, 15)}…' : model;
  }
}

enum MemoryType { fact, preference, event, profile }

const Object _keep = Object();

/// 用户可扩展的整理类型；内建语义保持 [MemoryType] 不变，供 Agent 使用。
class MemoryKind {
  const MemoryKind({required this.id, required this.label, this.semanticType});

  final String id;
  final String label;
  final MemoryType? semanticType;

  bool get isBuiltIn => semanticType != null;

  static const builtIn = [
    MemoryKind(id: 'fact', label: '事实', semanticType: MemoryType.fact),
    MemoryKind(
      id: 'preference',
      label: '偏好',
      semanticType: MemoryType.preference,
    ),
    MemoryKind(id: 'event', label: '事件', semanticType: MemoryType.event),
    MemoryKind(id: 'profile', label: '画像', semanticType: MemoryType.profile),
  ];
}

enum MemoryExpiryFilter {
  all('全部'),
  valid('有效'),
  expired('已过期');

  const MemoryExpiryFilter(this.label);
  final String label;
}

enum MemorySource { ai, manual }

/// 记忆条目（08-memory.md §8.1）。
class MemoryEntry {
  MemoryEntry({
    required this.id,
    required this.content,
    required this.type,
    this.customTypeId,
    this.source = MemorySource.ai,
    this.sourceSessionId,
    this.sourceSessionTitle,
    List<String> categoryIds = const [],
    this.confidence = 1.0,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  }) : categoryIds = List<String>.unmodifiable(categoryIds) {
    if (!confidence.isFinite || confidence < 0 || confidence > 1) {
      throw ArgumentError.value(
        confidence,
        'confidence',
        'Must be between 0 and 1.',
      );
    }
  }

  final String id;
  final String content;
  final MemoryType type;

  /// 可选的用户整理类型，不覆盖既有事实/偏好/事件/画像语义。
  final String? customTypeId;
  String get typeScopeId => customTypeId ?? type.name;
  final MemorySource source;

  /// AI 提取时的来源会话（可跳溯源）；手动新增为空。
  final String? sourceSessionId;
  final String? sourceSessionTitle;
  final List<String> categoryIds;

  /// 0–1，分档：高 ≥0.85 / 中 0.6–0.85 / 低 <0.6。
  final double confidence;

  /// null = 长期有效。
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get typeLabel => switch (type) {
    MemoryType.fact => '事实',
    MemoryType.preference => '偏好',
    MemoryType.event => '事件',
    MemoryType.profile => '画像',
  };

  String get confidenceLabel =>
      confidence >= 0.85 ? '高' : (confidence >= 0.6 ? '中' : '低');

  bool get isLowConfidence => confidence < 0.6;

  bool isExpired(DateTime now) => expiresAt != null && !expiresAt!.isAfter(now);

  /// 临期：未过期且距失效 ≤7 天。
  bool isExpiringSoon(DateTime now) =>
      expiresAt != null &&
      expiresAt!.isAfter(now) &&
      expiresAt!.difference(now) <= const Duration(days: 7);

  int daysUntilExpiry(DateTime now) =>
      expiresAt == null ? 0 : expiresAt!.difference(now).inDays;

  MemoryEntry copyWith({
    String? content,
    MemoryType? type,
    Object? customTypeId = _keep,
    Object? expiresAt = _keep,
    Object? sourceSessionId = _keep,
    Object? sourceSessionTitle = _keep,
    List<String>? categoryIds,
    double? confidence,
    // Legacy flag remains compatible; prefer expiresAt: null when clearing.
    bool clearExpiry = false,
    DateTime? updatedAt,
  }) {
    return MemoryEntry(
      id: id,
      content: content ?? this.content,
      type: type ?? this.type,
      customTypeId: identical(customTypeId, _keep)
          ? this.customTypeId
          : customTypeId as String?,
      source: source,
      sourceSessionId: identical(sourceSessionId, _keep)
          ? this.sourceSessionId
          : sourceSessionId as String?,
      sourceSessionTitle: identical(sourceSessionTitle, _keep)
          ? this.sourceSessionTitle
          : sourceSessionTitle as String?,
      categoryIds: categoryIds ?? this.categoryIds,
      confidence: confidence ?? this.confidence,
      expiresAt: clearExpiry
          ? null
          : identical(expiresAt, _keep)
          ? this.expiresAt
          : expiresAt as DateTime?,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

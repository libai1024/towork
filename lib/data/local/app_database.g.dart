// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProviderConfigurationsTable extends ProviderConfigurations
    with TableInfo<$ProviderConfigurationsTable, ProviderConfiguration> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderConfigurationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productMeta = const VerificationMeta(
    'product',
  );
  @override
  late final GeneratedColumn<String> product = GeneratedColumn<String>(
    'product',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
    'region',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _disableThinkingMeta = const VerificationMeta(
    'disableThinking',
  );
  @override
  late final GeneratedColumn<bool> disableThinking = GeneratedColumn<bool>(
    'disable_thinking',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("disable_thinking" IN (0, 1))',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _credentialRefMeta = const VerificationMeta(
    'credentialRef',
  );
  @override
  late final GeneratedColumn<String> credentialRef = GeneratedColumn<String>(
    'credential_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    product,
    region,
    model,
    disableThinking,
    version,
    credentialRef,
    accountId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provider_configurations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderConfiguration> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product')) {
      context.handle(
        _productMeta,
        product.isAcceptableOrUnknown(data['product']!, _productMeta),
      );
    } else if (isInserting) {
      context.missing(_productMeta);
    }
    if (data.containsKey('region')) {
      context.handle(
        _regionMeta,
        region.isAcceptableOrUnknown(data['region']!, _regionMeta),
      );
    } else if (isInserting) {
      context.missing(_regionMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('disable_thinking')) {
      context.handle(
        _disableThinkingMeta,
        disableThinking.isAcceptableOrUnknown(
          data['disable_thinking']!,
          _disableThinkingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_disableThinkingMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('credential_ref')) {
      context.handle(
        _credentialRefMeta,
        credentialRef.isAcceptableOrUnknown(
          data['credential_ref']!,
          _credentialRefMeta,
        ),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProviderConfiguration map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderConfiguration(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      product: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product'],
      )!,
      region: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      disableThinking: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}disable_thinking'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      credentialRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credential_ref'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
    );
  }

  @override
  $ProviderConfigurationsTable createAlias(String alias) {
    return $ProviderConfigurationsTable(attachedDatabase, alias);
  }
}

class ProviderConfiguration extends DataClass
    implements Insertable<ProviderConfiguration> {
  final int id;
  final String product;
  final String region;
  final String model;
  final bool disableThinking;
  final int version;
  final String? credentialRef;

  /// 当前配置来自哪个已保存账户；空表示尚未关联。
  final String? accountId;
  const ProviderConfiguration({
    required this.id,
    required this.product,
    required this.region,
    required this.model,
    required this.disableThinking,
    required this.version,
    this.credentialRef,
    this.accountId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product'] = Variable<String>(product);
    map['region'] = Variable<String>(region);
    map['model'] = Variable<String>(model);
    map['disable_thinking'] = Variable<bool>(disableThinking);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || credentialRef != null) {
      map['credential_ref'] = Variable<String>(credentialRef);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    return map;
  }

  ProviderConfigurationsCompanion toCompanion(bool nullToAbsent) {
    return ProviderConfigurationsCompanion(
      id: Value(id),
      product: Value(product),
      region: Value(region),
      model: Value(model),
      disableThinking: Value(disableThinking),
      version: Value(version),
      credentialRef: credentialRef == null && nullToAbsent
          ? const Value.absent()
          : Value(credentialRef),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
    );
  }

  factory ProviderConfiguration.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderConfiguration(
      id: serializer.fromJson<int>(json['id']),
      product: serializer.fromJson<String>(json['product']),
      region: serializer.fromJson<String>(json['region']),
      model: serializer.fromJson<String>(json['model']),
      disableThinking: serializer.fromJson<bool>(json['disableThinking']),
      version: serializer.fromJson<int>(json['version']),
      credentialRef: serializer.fromJson<String?>(json['credentialRef']),
      accountId: serializer.fromJson<String?>(json['accountId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'product': serializer.toJson<String>(product),
      'region': serializer.toJson<String>(region),
      'model': serializer.toJson<String>(model),
      'disableThinking': serializer.toJson<bool>(disableThinking),
      'version': serializer.toJson<int>(version),
      'credentialRef': serializer.toJson<String?>(credentialRef),
      'accountId': serializer.toJson<String?>(accountId),
    };
  }

  ProviderConfiguration copyWith({
    int? id,
    String? product,
    String? region,
    String? model,
    bool? disableThinking,
    int? version,
    Value<String?> credentialRef = const Value.absent(),
    Value<String?> accountId = const Value.absent(),
  }) => ProviderConfiguration(
    id: id ?? this.id,
    product: product ?? this.product,
    region: region ?? this.region,
    model: model ?? this.model,
    disableThinking: disableThinking ?? this.disableThinking,
    version: version ?? this.version,
    credentialRef: credentialRef.present
        ? credentialRef.value
        : this.credentialRef,
    accountId: accountId.present ? accountId.value : this.accountId,
  );
  ProviderConfiguration copyWithCompanion(
    ProviderConfigurationsCompanion data,
  ) {
    return ProviderConfiguration(
      id: data.id.present ? data.id.value : this.id,
      product: data.product.present ? data.product.value : this.product,
      region: data.region.present ? data.region.value : this.region,
      model: data.model.present ? data.model.value : this.model,
      disableThinking: data.disableThinking.present
          ? data.disableThinking.value
          : this.disableThinking,
      version: data.version.present ? data.version.value : this.version,
      credentialRef: data.credentialRef.present
          ? data.credentialRef.value
          : this.credentialRef,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderConfiguration(')
          ..write('id: $id, ')
          ..write('product: $product, ')
          ..write('region: $region, ')
          ..write('model: $model, ')
          ..write('disableThinking: $disableThinking, ')
          ..write('version: $version, ')
          ..write('credentialRef: $credentialRef, ')
          ..write('accountId: $accountId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    product,
    region,
    model,
    disableThinking,
    version,
    credentialRef,
    accountId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderConfiguration &&
          other.id == this.id &&
          other.product == this.product &&
          other.region == this.region &&
          other.model == this.model &&
          other.disableThinking == this.disableThinking &&
          other.version == this.version &&
          other.credentialRef == this.credentialRef &&
          other.accountId == this.accountId);
}

class ProviderConfigurationsCompanion
    extends UpdateCompanion<ProviderConfiguration> {
  final Value<int> id;
  final Value<String> product;
  final Value<String> region;
  final Value<String> model;
  final Value<bool> disableThinking;
  final Value<int> version;
  final Value<String?> credentialRef;
  final Value<String?> accountId;
  const ProviderConfigurationsCompanion({
    this.id = const Value.absent(),
    this.product = const Value.absent(),
    this.region = const Value.absent(),
    this.model = const Value.absent(),
    this.disableThinking = const Value.absent(),
    this.version = const Value.absent(),
    this.credentialRef = const Value.absent(),
    this.accountId = const Value.absent(),
  });
  ProviderConfigurationsCompanion.insert({
    this.id = const Value.absent(),
    required String product,
    required String region,
    required String model,
    required bool disableThinking,
    required int version,
    this.credentialRef = const Value.absent(),
    this.accountId = const Value.absent(),
  }) : product = Value(product),
       region = Value(region),
       model = Value(model),
       disableThinking = Value(disableThinking),
       version = Value(version);
  static Insertable<ProviderConfiguration> custom({
    Expression<int>? id,
    Expression<String>? product,
    Expression<String>? region,
    Expression<String>? model,
    Expression<bool>? disableThinking,
    Expression<int>? version,
    Expression<String>? credentialRef,
    Expression<String>? accountId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (product != null) 'product': product,
      if (region != null) 'region': region,
      if (model != null) 'model': model,
      if (disableThinking != null) 'disable_thinking': disableThinking,
      if (version != null) 'version': version,
      if (credentialRef != null) 'credential_ref': credentialRef,
      if (accountId != null) 'account_id': accountId,
    });
  }

  ProviderConfigurationsCompanion copyWith({
    Value<int>? id,
    Value<String>? product,
    Value<String>? region,
    Value<String>? model,
    Value<bool>? disableThinking,
    Value<int>? version,
    Value<String?>? credentialRef,
    Value<String?>? accountId,
  }) {
    return ProviderConfigurationsCompanion(
      id: id ?? this.id,
      product: product ?? this.product,
      region: region ?? this.region,
      model: model ?? this.model,
      disableThinking: disableThinking ?? this.disableThinking,
      version: version ?? this.version,
      credentialRef: credentialRef ?? this.credentialRef,
      accountId: accountId ?? this.accountId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (product.present) {
      map['product'] = Variable<String>(product.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (disableThinking.present) {
      map['disable_thinking'] = Variable<bool>(disableThinking.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (credentialRef.present) {
      map['credential_ref'] = Variable<String>(credentialRef.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderConfigurationsCompanion(')
          ..write('id: $id, ')
          ..write('product: $product, ')
          ..write('region: $region, ')
          ..write('model: $model, ')
          ..write('disableThinking: $disableThinking, ')
          ..write('version: $version, ')
          ..write('credentialRef: $credentialRef, ')
          ..write('accountId: $accountId')
          ..write(')'))
        .toString();
  }
}

class $ProviderAccountsTable extends ProviderAccounts
    with TableInfo<$ProviderAccountsTable, ProviderAccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productMeta = const VerificationMeta(
    'product',
  );
  @override
  late final GeneratedColumn<String> product = GeneratedColumn<String>(
    'product',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
    'region',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'base_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _disableThinkingMeta = const VerificationMeta(
    'disableThinking',
  );
  @override
  late final GeneratedColumn<bool> disableThinking = GeneratedColumn<bool>(
    'disable_thinking',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("disable_thinking" IN (0, 1))',
    ),
  );
  static const VerificationMeta _credentialRefMeta = const VerificationMeta(
    'credentialRef',
  );
  @override
  late final GeneratedColumn<String> credentialRef = GeneratedColumn<String>(
    'credential_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _autoRouteMeta = const VerificationMeta(
    'autoRoute',
  );
  @override
  late final GeneratedColumn<bool> autoRoute = GeneratedColumn<bool>(
    'auto_route',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_route" IN (0, 1))',
    ),
  );
  static const VerificationMeta _cooldownUntilMeta = const VerificationMeta(
    'cooldownUntil',
  );
  @override
  late final GeneratedColumn<int> cooldownUntil = GeneratedColumn<int>(
    'cooldown_until',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cooldownReasonMeta = const VerificationMeta(
    'cooldownReason',
  );
  @override
  late final GeneratedColumn<String> cooldownReason = GeneratedColumn<String>(
    'cooldown_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quotaPayloadMeta = const VerificationMeta(
    'quotaPayload',
  );
  @override
  late final GeneratedColumn<String> quotaPayload = GeneratedColumn<String>(
    'quota_payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    product,
    region,
    model,
    baseUrl,
    disableThinking,
    credentialRef,
    position,
    autoRoute,
    cooldownUntil,
    cooldownReason,
    quotaPayload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provider_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderAccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product')) {
      context.handle(
        _productMeta,
        product.isAcceptableOrUnknown(data['product']!, _productMeta),
      );
    } else if (isInserting) {
      context.missing(_productMeta);
    }
    if (data.containsKey('region')) {
      context.handle(
        _regionMeta,
        region.isAcceptableOrUnknown(data['region']!, _regionMeta),
      );
    } else if (isInserting) {
      context.missing(_regionMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    }
    if (data.containsKey('disable_thinking')) {
      context.handle(
        _disableThinkingMeta,
        disableThinking.isAcceptableOrUnknown(
          data['disable_thinking']!,
          _disableThinkingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_disableThinkingMeta);
    }
    if (data.containsKey('credential_ref')) {
      context.handle(
        _credentialRefMeta,
        credentialRef.isAcceptableOrUnknown(
          data['credential_ref']!,
          _credentialRefMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('auto_route')) {
      context.handle(
        _autoRouteMeta,
        autoRoute.isAcceptableOrUnknown(data['auto_route']!, _autoRouteMeta),
      );
    } else if (isInserting) {
      context.missing(_autoRouteMeta);
    }
    if (data.containsKey('cooldown_until')) {
      context.handle(
        _cooldownUntilMeta,
        cooldownUntil.isAcceptableOrUnknown(
          data['cooldown_until']!,
          _cooldownUntilMeta,
        ),
      );
    }
    if (data.containsKey('cooldown_reason')) {
      context.handle(
        _cooldownReasonMeta,
        cooldownReason.isAcceptableOrUnknown(
          data['cooldown_reason']!,
          _cooldownReasonMeta,
        ),
      );
    }
    if (data.containsKey('quota_payload')) {
      context.handle(
        _quotaPayloadMeta,
        quotaPayload.isAcceptableOrUnknown(
          data['quota_payload']!,
          _quotaPayloadMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProviderAccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderAccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      product: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product'],
      )!,
      region: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      ),
      disableThinking: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}disable_thinking'],
      )!,
      credentialRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credential_ref'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      autoRoute: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_route'],
      )!,
      cooldownUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cooldown_until'],
      ),
      cooldownReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cooldown_reason'],
      ),
      quotaPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quota_payload'],
      ),
    );
  }

  @override
  $ProviderAccountsTable createAlias(String alias) {
    return $ProviderAccountsTable(attachedDatabase, alias);
  }
}

class ProviderAccountRow extends DataClass
    implements Insertable<ProviderAccountRow> {
  final String id;
  final String product;
  final String region;
  final String model;
  final String? baseUrl;
  final bool disableThinking;
  final String? credentialRef;
  final int position;
  final bool autoRoute;
  final int? cooldownUntil;
  final String? cooldownReason;
  final String? quotaPayload;
  const ProviderAccountRow({
    required this.id,
    required this.product,
    required this.region,
    required this.model,
    this.baseUrl,
    required this.disableThinking,
    this.credentialRef,
    required this.position,
    required this.autoRoute,
    this.cooldownUntil,
    this.cooldownReason,
    this.quotaPayload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product'] = Variable<String>(product);
    map['region'] = Variable<String>(region);
    map['model'] = Variable<String>(model);
    if (!nullToAbsent || baseUrl != null) {
      map['base_url'] = Variable<String>(baseUrl);
    }
    map['disable_thinking'] = Variable<bool>(disableThinking);
    if (!nullToAbsent || credentialRef != null) {
      map['credential_ref'] = Variable<String>(credentialRef);
    }
    map['position'] = Variable<int>(position);
    map['auto_route'] = Variable<bool>(autoRoute);
    if (!nullToAbsent || cooldownUntil != null) {
      map['cooldown_until'] = Variable<int>(cooldownUntil);
    }
    if (!nullToAbsent || cooldownReason != null) {
      map['cooldown_reason'] = Variable<String>(cooldownReason);
    }
    if (!nullToAbsent || quotaPayload != null) {
      map['quota_payload'] = Variable<String>(quotaPayload);
    }
    return map;
  }

  ProviderAccountsCompanion toCompanion(bool nullToAbsent) {
    return ProviderAccountsCompanion(
      id: Value(id),
      product: Value(product),
      region: Value(region),
      model: Value(model),
      baseUrl: baseUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(baseUrl),
      disableThinking: Value(disableThinking),
      credentialRef: credentialRef == null && nullToAbsent
          ? const Value.absent()
          : Value(credentialRef),
      position: Value(position),
      autoRoute: Value(autoRoute),
      cooldownUntil: cooldownUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(cooldownUntil),
      cooldownReason: cooldownReason == null && nullToAbsent
          ? const Value.absent()
          : Value(cooldownReason),
      quotaPayload: quotaPayload == null && nullToAbsent
          ? const Value.absent()
          : Value(quotaPayload),
    );
  }

  factory ProviderAccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderAccountRow(
      id: serializer.fromJson<String>(json['id']),
      product: serializer.fromJson<String>(json['product']),
      region: serializer.fromJson<String>(json['region']),
      model: serializer.fromJson<String>(json['model']),
      baseUrl: serializer.fromJson<String?>(json['baseUrl']),
      disableThinking: serializer.fromJson<bool>(json['disableThinking']),
      credentialRef: serializer.fromJson<String?>(json['credentialRef']),
      position: serializer.fromJson<int>(json['position']),
      autoRoute: serializer.fromJson<bool>(json['autoRoute']),
      cooldownUntil: serializer.fromJson<int?>(json['cooldownUntil']),
      cooldownReason: serializer.fromJson<String?>(json['cooldownReason']),
      quotaPayload: serializer.fromJson<String?>(json['quotaPayload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'product': serializer.toJson<String>(product),
      'region': serializer.toJson<String>(region),
      'model': serializer.toJson<String>(model),
      'baseUrl': serializer.toJson<String?>(baseUrl),
      'disableThinking': serializer.toJson<bool>(disableThinking),
      'credentialRef': serializer.toJson<String?>(credentialRef),
      'position': serializer.toJson<int>(position),
      'autoRoute': serializer.toJson<bool>(autoRoute),
      'cooldownUntil': serializer.toJson<int?>(cooldownUntil),
      'cooldownReason': serializer.toJson<String?>(cooldownReason),
      'quotaPayload': serializer.toJson<String?>(quotaPayload),
    };
  }

  ProviderAccountRow copyWith({
    String? id,
    String? product,
    String? region,
    String? model,
    Value<String?> baseUrl = const Value.absent(),
    bool? disableThinking,
    Value<String?> credentialRef = const Value.absent(),
    int? position,
    bool? autoRoute,
    Value<int?> cooldownUntil = const Value.absent(),
    Value<String?> cooldownReason = const Value.absent(),
    Value<String?> quotaPayload = const Value.absent(),
  }) => ProviderAccountRow(
    id: id ?? this.id,
    product: product ?? this.product,
    region: region ?? this.region,
    model: model ?? this.model,
    baseUrl: baseUrl.present ? baseUrl.value : this.baseUrl,
    disableThinking: disableThinking ?? this.disableThinking,
    credentialRef: credentialRef.present
        ? credentialRef.value
        : this.credentialRef,
    position: position ?? this.position,
    autoRoute: autoRoute ?? this.autoRoute,
    cooldownUntil: cooldownUntil.present
        ? cooldownUntil.value
        : this.cooldownUntil,
    cooldownReason: cooldownReason.present
        ? cooldownReason.value
        : this.cooldownReason,
    quotaPayload: quotaPayload.present ? quotaPayload.value : this.quotaPayload,
  );
  ProviderAccountRow copyWithCompanion(ProviderAccountsCompanion data) {
    return ProviderAccountRow(
      id: data.id.present ? data.id.value : this.id,
      product: data.product.present ? data.product.value : this.product,
      region: data.region.present ? data.region.value : this.region,
      model: data.model.present ? data.model.value : this.model,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      disableThinking: data.disableThinking.present
          ? data.disableThinking.value
          : this.disableThinking,
      credentialRef: data.credentialRef.present
          ? data.credentialRef.value
          : this.credentialRef,
      position: data.position.present ? data.position.value : this.position,
      autoRoute: data.autoRoute.present ? data.autoRoute.value : this.autoRoute,
      cooldownUntil: data.cooldownUntil.present
          ? data.cooldownUntil.value
          : this.cooldownUntil,
      cooldownReason: data.cooldownReason.present
          ? data.cooldownReason.value
          : this.cooldownReason,
      quotaPayload: data.quotaPayload.present
          ? data.quotaPayload.value
          : this.quotaPayload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderAccountRow(')
          ..write('id: $id, ')
          ..write('product: $product, ')
          ..write('region: $region, ')
          ..write('model: $model, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('disableThinking: $disableThinking, ')
          ..write('credentialRef: $credentialRef, ')
          ..write('position: $position, ')
          ..write('autoRoute: $autoRoute, ')
          ..write('cooldownUntil: $cooldownUntil, ')
          ..write('cooldownReason: $cooldownReason, ')
          ..write('quotaPayload: $quotaPayload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    product,
    region,
    model,
    baseUrl,
    disableThinking,
    credentialRef,
    position,
    autoRoute,
    cooldownUntil,
    cooldownReason,
    quotaPayload,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderAccountRow &&
          other.id == this.id &&
          other.product == this.product &&
          other.region == this.region &&
          other.model == this.model &&
          other.baseUrl == this.baseUrl &&
          other.disableThinking == this.disableThinking &&
          other.credentialRef == this.credentialRef &&
          other.position == this.position &&
          other.autoRoute == this.autoRoute &&
          other.cooldownUntil == this.cooldownUntil &&
          other.cooldownReason == this.cooldownReason &&
          other.quotaPayload == this.quotaPayload);
}

class ProviderAccountsCompanion extends UpdateCompanion<ProviderAccountRow> {
  final Value<String> id;
  final Value<String> product;
  final Value<String> region;
  final Value<String> model;
  final Value<String?> baseUrl;
  final Value<bool> disableThinking;
  final Value<String?> credentialRef;
  final Value<int> position;
  final Value<bool> autoRoute;
  final Value<int?> cooldownUntil;
  final Value<String?> cooldownReason;
  final Value<String?> quotaPayload;
  final Value<int> rowid;
  const ProviderAccountsCompanion({
    this.id = const Value.absent(),
    this.product = const Value.absent(),
    this.region = const Value.absent(),
    this.model = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.disableThinking = const Value.absent(),
    this.credentialRef = const Value.absent(),
    this.position = const Value.absent(),
    this.autoRoute = const Value.absent(),
    this.cooldownUntil = const Value.absent(),
    this.cooldownReason = const Value.absent(),
    this.quotaPayload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProviderAccountsCompanion.insert({
    required String id,
    required String product,
    required String region,
    required String model,
    this.baseUrl = const Value.absent(),
    required bool disableThinking,
    this.credentialRef = const Value.absent(),
    required int position,
    required bool autoRoute,
    this.cooldownUntil = const Value.absent(),
    this.cooldownReason = const Value.absent(),
    this.quotaPayload = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       product = Value(product),
       region = Value(region),
       model = Value(model),
       disableThinking = Value(disableThinking),
       position = Value(position),
       autoRoute = Value(autoRoute);
  static Insertable<ProviderAccountRow> custom({
    Expression<String>? id,
    Expression<String>? product,
    Expression<String>? region,
    Expression<String>? model,
    Expression<String>? baseUrl,
    Expression<bool>? disableThinking,
    Expression<String>? credentialRef,
    Expression<int>? position,
    Expression<bool>? autoRoute,
    Expression<int>? cooldownUntil,
    Expression<String>? cooldownReason,
    Expression<String>? quotaPayload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (product != null) 'product': product,
      if (region != null) 'region': region,
      if (model != null) 'model': model,
      if (baseUrl != null) 'base_url': baseUrl,
      if (disableThinking != null) 'disable_thinking': disableThinking,
      if (credentialRef != null) 'credential_ref': credentialRef,
      if (position != null) 'position': position,
      if (autoRoute != null) 'auto_route': autoRoute,
      if (cooldownUntil != null) 'cooldown_until': cooldownUntil,
      if (cooldownReason != null) 'cooldown_reason': cooldownReason,
      if (quotaPayload != null) 'quota_payload': quotaPayload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProviderAccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? product,
    Value<String>? region,
    Value<String>? model,
    Value<String?>? baseUrl,
    Value<bool>? disableThinking,
    Value<String?>? credentialRef,
    Value<int>? position,
    Value<bool>? autoRoute,
    Value<int?>? cooldownUntil,
    Value<String?>? cooldownReason,
    Value<String?>? quotaPayload,
    Value<int>? rowid,
  }) {
    return ProviderAccountsCompanion(
      id: id ?? this.id,
      product: product ?? this.product,
      region: region ?? this.region,
      model: model ?? this.model,
      baseUrl: baseUrl ?? this.baseUrl,
      disableThinking: disableThinking ?? this.disableThinking,
      credentialRef: credentialRef ?? this.credentialRef,
      position: position ?? this.position,
      autoRoute: autoRoute ?? this.autoRoute,
      cooldownUntil: cooldownUntil ?? this.cooldownUntil,
      cooldownReason: cooldownReason ?? this.cooldownReason,
      quotaPayload: quotaPayload ?? this.quotaPayload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (product.present) {
      map['product'] = Variable<String>(product.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (disableThinking.present) {
      map['disable_thinking'] = Variable<bool>(disableThinking.value);
    }
    if (credentialRef.present) {
      map['credential_ref'] = Variable<String>(credentialRef.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (autoRoute.present) {
      map['auto_route'] = Variable<bool>(autoRoute.value);
    }
    if (cooldownUntil.present) {
      map['cooldown_until'] = Variable<int>(cooldownUntil.value);
    }
    if (cooldownReason.present) {
      map['cooldown_reason'] = Variable<String>(cooldownReason.value);
    }
    if (quotaPayload.present) {
      map['quota_payload'] = Variable<String>(quotaPayload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderAccountsCompanion(')
          ..write('id: $id, ')
          ..write('product: $product, ')
          ..write('region: $region, ')
          ..write('model: $model, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('disableThinking: $disableThinking, ')
          ..write('credentialRef: $credentialRef, ')
          ..write('position: $position, ')
          ..write('autoRoute: $autoRoute, ')
          ..write('cooldownUntil: $cooldownUntil, ')
          ..write('cooldownReason: $cooldownReason, ')
          ..write('quotaPayload: $quotaPayload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CredentialCleanupTable extends CredentialCleanup
    with TableInfo<$CredentialCleanupTable, CredentialCleanupData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CredentialCleanupTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [reference];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'credential_cleanup';
  @override
  VerificationContext validateIntegrity(
    Insertable<CredentialCleanupData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    } else if (isInserting) {
      context.missing(_referenceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {reference};
  @override
  CredentialCleanupData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CredentialCleanupData(
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      )!,
    );
  }

  @override
  $CredentialCleanupTable createAlias(String alias) {
    return $CredentialCleanupTable(attachedDatabase, alias);
  }
}

class CredentialCleanupData extends DataClass
    implements Insertable<CredentialCleanupData> {
  final String reference;
  const CredentialCleanupData({required this.reference});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['reference'] = Variable<String>(reference);
    return map;
  }

  CredentialCleanupCompanion toCompanion(bool nullToAbsent) {
    return CredentialCleanupCompanion(reference: Value(reference));
  }

  factory CredentialCleanupData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CredentialCleanupData(
      reference: serializer.fromJson<String>(json['reference']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'reference': serializer.toJson<String>(reference)};
  }

  CredentialCleanupData copyWith({String? reference}) =>
      CredentialCleanupData(reference: reference ?? this.reference);
  CredentialCleanupData copyWithCompanion(CredentialCleanupCompanion data) {
    return CredentialCleanupData(
      reference: data.reference.present ? data.reference.value : this.reference,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CredentialCleanupData(')
          ..write('reference: $reference')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => reference.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CredentialCleanupData && other.reference == this.reference);
}

class CredentialCleanupCompanion
    extends UpdateCompanion<CredentialCleanupData> {
  final Value<String> reference;
  final Value<int> rowid;
  const CredentialCleanupCompanion({
    this.reference = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CredentialCleanupCompanion.insert({
    required String reference,
    this.rowid = const Value.absent(),
  }) : reference = Value(reference);
  static Insertable<CredentialCleanupData> custom({
    Expression<String>? reference,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (reference != null) 'reference': reference,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CredentialCleanupCompanion copyWith({
    Value<String>? reference,
    Value<int>? rowid,
  }) {
    return CredentialCleanupCompanion(
      reference: reference ?? this.reference,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CredentialCleanupCompanion(')
          ..write('reference: $reference, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalProfilesTable extends LocalProfiles
    with TableInfo<$LocalProfilesTable, LocalProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _singletonIdMeta = const VerificationMeta(
    'singletonId',
  );
  @override
  late final GeneratedColumn<int> singletonId = GeneratedColumn<int>(
    'singleton_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localUserIdMeta = const VerificationMeta(
    'localUserId',
  );
  @override
  late final GeneratedColumn<String> localUserId = GeneratedColumn<String>(
    'local_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    singletonId,
    localUserId,
    nickname,
    version,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('singleton_id')) {
      context.handle(
        _singletonIdMeta,
        singletonId.isAcceptableOrUnknown(
          data['singleton_id']!,
          _singletonIdMeta,
        ),
      );
    }
    if (data.containsKey('local_user_id')) {
      context.handle(
        _localUserIdMeta,
        localUserId.isAcceptableOrUnknown(
          data['local_user_id']!,
          _localUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localUserIdMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    } else if (isInserting) {
      context.missing(_nicknameMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {singletonId};
  @override
  LocalProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProfileRow(
      singletonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton_id'],
      )!,
      localUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_user_id'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalProfilesTable createAlias(String alias) {
    return $LocalProfilesTable(attachedDatabase, alias);
  }
}

class LocalProfileRow extends DataClass implements Insertable<LocalProfileRow> {
  final int singletonId;
  final String localUserId;
  final String nickname;
  final int version;
  final DateTime createdAt;
  const LocalProfileRow({
    required this.singletonId,
    required this.localUserId,
    required this.nickname,
    required this.version,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['singleton_id'] = Variable<int>(singletonId);
    map['local_user_id'] = Variable<String>(localUserId);
    map['nickname'] = Variable<String>(nickname);
    map['version'] = Variable<int>(version);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalProfilesCompanion toCompanion(bool nullToAbsent) {
    return LocalProfilesCompanion(
      singletonId: Value(singletonId),
      localUserId: Value(localUserId),
      nickname: Value(nickname),
      version: Value(version),
      createdAt: Value(createdAt),
    );
  }

  factory LocalProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProfileRow(
      singletonId: serializer.fromJson<int>(json['singletonId']),
      localUserId: serializer.fromJson<String>(json['localUserId']),
      nickname: serializer.fromJson<String>(json['nickname']),
      version: serializer.fromJson<int>(json['version']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'singletonId': serializer.toJson<int>(singletonId),
      'localUserId': serializer.toJson<String>(localUserId),
      'nickname': serializer.toJson<String>(nickname),
      'version': serializer.toJson<int>(version),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalProfileRow copyWith({
    int? singletonId,
    String? localUserId,
    String? nickname,
    int? version,
    DateTime? createdAt,
  }) => LocalProfileRow(
    singletonId: singletonId ?? this.singletonId,
    localUserId: localUserId ?? this.localUserId,
    nickname: nickname ?? this.nickname,
    version: version ?? this.version,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalProfileRow copyWithCompanion(LocalProfilesCompanion data) {
    return LocalProfileRow(
      singletonId: data.singletonId.present
          ? data.singletonId.value
          : this.singletonId,
      localUserId: data.localUserId.present
          ? data.localUserId.value
          : this.localUserId,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProfileRow(')
          ..write('singletonId: $singletonId, ')
          ..write('localUserId: $localUserId, ')
          ..write('nickname: $nickname, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(singletonId, localUserId, nickname, version, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProfileRow &&
          other.singletonId == this.singletonId &&
          other.localUserId == this.localUserId &&
          other.nickname == this.nickname &&
          other.version == this.version &&
          other.createdAt == this.createdAt);
}

class LocalProfilesCompanion extends UpdateCompanion<LocalProfileRow> {
  final Value<int> singletonId;
  final Value<String> localUserId;
  final Value<String> nickname;
  final Value<int> version;
  final Value<DateTime> createdAt;
  const LocalProfilesCompanion({
    this.singletonId = const Value.absent(),
    this.localUserId = const Value.absent(),
    this.nickname = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LocalProfilesCompanion.insert({
    this.singletonId = const Value.absent(),
    required String localUserId,
    required String nickname,
    required int version,
    required DateTime createdAt,
  }) : localUserId = Value(localUserId),
       nickname = Value(nickname),
       version = Value(version),
       createdAt = Value(createdAt);
  static Insertable<LocalProfileRow> custom({
    Expression<int>? singletonId,
    Expression<String>? localUserId,
    Expression<String>? nickname,
    Expression<int>? version,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (singletonId != null) 'singleton_id': singletonId,
      if (localUserId != null) 'local_user_id': localUserId,
      if (nickname != null) 'nickname': nickname,
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LocalProfilesCompanion copyWith({
    Value<int>? singletonId,
    Value<String>? localUserId,
    Value<String>? nickname,
    Value<int>? version,
    Value<DateTime>? createdAt,
  }) {
    return LocalProfilesCompanion(
      singletonId: singletonId ?? this.singletonId,
      localUserId: localUserId ?? this.localUserId,
      nickname: nickname ?? this.nickname,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (singletonId.present) {
      map['singleton_id'] = Variable<int>(singletonId.value);
    }
    if (localUserId.present) {
      map['local_user_id'] = Variable<String>(localUserId.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProfilesCompanion(')
          ..write('singletonId: $singletonId, ')
          ..write('localUserId: $localUserId, ')
          ..write('nickname: $nickname, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WorkTodosTable extends WorkTodos
    with TableInfo<$WorkTodosTable, WorkTodo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkTodosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurrenceKeyMeta = const VerificationMeta(
    'occurrenceKey',
  );
  @override
  late final GeneratedColumn<String> occurrenceKey = GeneratedColumn<String>(
    'occurrence_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurrenceIndexMeta = const VerificationMeta(
    'occurrenceIndex',
  );
  @override
  late final GeneratedColumn<int> occurrenceIndex = GeneratedColumn<int>(
    'occurrence_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    seriesId,
    occurrenceKey,
    occurrenceIndex,
    id,
    version,
    categoryId,
    status,
    dueAt,
    sortOrder,
    payload,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'work_todos';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkTodo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    }
    if (data.containsKey('occurrence_key')) {
      context.handle(
        _occurrenceKeyMeta,
        occurrenceKey.isAcceptableOrUnknown(
          data['occurrence_key']!,
          _occurrenceKeyMeta,
        ),
      );
    }
    if (data.containsKey('occurrence_index')) {
      context.handle(
        _occurrenceIndexMeta,
        occurrenceIndex.isAcceptableOrUnknown(
          data['occurrence_index']!,
          _occurrenceIndexMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkTodo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkTodo(
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      ),
      occurrenceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_key'],
      ),
      occurrenceIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurrence_index'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $WorkTodosTable createAlias(String alias) {
    return $WorkTodosTable(attachedDatabase, alias);
  }
}

class WorkTodo extends DataClass implements Insertable<WorkTodo> {
  final String? seriesId;
  final String? occurrenceKey;
  final int? occurrenceIndex;
  final String id;
  final int version;
  final String? categoryId;
  final String status;
  final DateTime? dueAt;
  final int sortOrder;
  final String payload;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const WorkTodo({
    this.seriesId,
    this.occurrenceKey,
    this.occurrenceIndex,
    required this.id,
    required this.version,
    this.categoryId,
    required this.status,
    this.dueAt,
    required this.sortOrder,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<String>(seriesId);
    }
    if (!nullToAbsent || occurrenceKey != null) {
      map['occurrence_key'] = Variable<String>(occurrenceKey);
    }
    if (!nullToAbsent || occurrenceIndex != null) {
      map['occurrence_index'] = Variable<int>(occurrenceIndex);
    }
    map['id'] = Variable<String>(id);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  WorkTodosCompanion toCompanion(bool nullToAbsent) {
    return WorkTodosCompanion(
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
      occurrenceKey: occurrenceKey == null && nullToAbsent
          ? const Value.absent()
          : Value(occurrenceKey),
      occurrenceIndex: occurrenceIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(occurrenceIndex),
      id: Value(id),
      version: Value(version),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      status: Value(status),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      sortOrder: Value(sortOrder),
      payload: Value(payload),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory WorkTodo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkTodo(
      seriesId: serializer.fromJson<String?>(json['seriesId']),
      occurrenceKey: serializer.fromJson<String?>(json['occurrenceKey']),
      occurrenceIndex: serializer.fromJson<int?>(json['occurrenceIndex']),
      id: serializer.fromJson<String>(json['id']),
      version: serializer.fromJson<int>(json['version']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      status: serializer.fromJson<String>(json['status']),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seriesId': serializer.toJson<String?>(seriesId),
      'occurrenceKey': serializer.toJson<String?>(occurrenceKey),
      'occurrenceIndex': serializer.toJson<int?>(occurrenceIndex),
      'id': serializer.toJson<String>(id),
      'version': serializer.toJson<int>(version),
      'categoryId': serializer.toJson<String?>(categoryId),
      'status': serializer.toJson<String>(status),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  WorkTodo copyWith({
    Value<String?> seriesId = const Value.absent(),
    Value<String?> occurrenceKey = const Value.absent(),
    Value<int?> occurrenceIndex = const Value.absent(),
    String? id,
    int? version,
    Value<String?> categoryId = const Value.absent(),
    String? status,
    Value<DateTime?> dueAt = const Value.absent(),
    int? sortOrder,
    String? payload,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => WorkTodo(
    seriesId: seriesId.present ? seriesId.value : this.seriesId,
    occurrenceKey: occurrenceKey.present
        ? occurrenceKey.value
        : this.occurrenceKey,
    occurrenceIndex: occurrenceIndex.present
        ? occurrenceIndex.value
        : this.occurrenceIndex,
    id: id ?? this.id,
    version: version ?? this.version,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    status: status ?? this.status,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    sortOrder: sortOrder ?? this.sortOrder,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  WorkTodo copyWithCompanion(WorkTodosCompanion data) {
    return WorkTodo(
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      occurrenceKey: data.occurrenceKey.present
          ? data.occurrenceKey.value
          : this.occurrenceKey,
      occurrenceIndex: data.occurrenceIndex.present
          ? data.occurrenceIndex.value
          : this.occurrenceIndex,
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      status: data.status.present ? data.status.value : this.status,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkTodo(')
          ..write('seriesId: $seriesId, ')
          ..write('occurrenceKey: $occurrenceKey, ')
          ..write('occurrenceIndex: $occurrenceIndex, ')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('categoryId: $categoryId, ')
          ..write('status: $status, ')
          ..write('dueAt: $dueAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    seriesId,
    occurrenceKey,
    occurrenceIndex,
    id,
    version,
    categoryId,
    status,
    dueAt,
    sortOrder,
    payload,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkTodo &&
          other.seriesId == this.seriesId &&
          other.occurrenceKey == this.occurrenceKey &&
          other.occurrenceIndex == this.occurrenceIndex &&
          other.id == this.id &&
          other.version == this.version &&
          other.categoryId == this.categoryId &&
          other.status == this.status &&
          other.dueAt == this.dueAt &&
          other.sortOrder == this.sortOrder &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class WorkTodosCompanion extends UpdateCompanion<WorkTodo> {
  final Value<String?> seriesId;
  final Value<String?> occurrenceKey;
  final Value<int?> occurrenceIndex;
  final Value<String> id;
  final Value<int> version;
  final Value<String?> categoryId;
  final Value<String> status;
  final Value<DateTime?> dueAt;
  final Value<int> sortOrder;
  final Value<String> payload;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const WorkTodosCompanion({
    this.seriesId = const Value.absent(),
    this.occurrenceKey = const Value.absent(),
    this.occurrenceIndex = const Value.absent(),
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.status = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkTodosCompanion.insert({
    this.seriesId = const Value.absent(),
    this.occurrenceKey = const Value.absent(),
    this.occurrenceIndex = const Value.absent(),
    required String id,
    required int version,
    this.categoryId = const Value.absent(),
    required String status,
    this.dueAt = const Value.absent(),
    required int sortOrder,
    required String payload,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       version = Value(version),
       status = Value(status),
       sortOrder = Value(sortOrder),
       payload = Value(payload),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WorkTodo> custom({
    Expression<String>? seriesId,
    Expression<String>? occurrenceKey,
    Expression<int>? occurrenceIndex,
    Expression<String>? id,
    Expression<int>? version,
    Expression<String>? categoryId,
    Expression<String>? status,
    Expression<DateTime>? dueAt,
    Expression<int>? sortOrder,
    Expression<String>? payload,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (seriesId != null) 'series_id': seriesId,
      if (occurrenceKey != null) 'occurrence_key': occurrenceKey,
      if (occurrenceIndex != null) 'occurrence_index': occurrenceIndex,
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (categoryId != null) 'category_id': categoryId,
      if (status != null) 'status': status,
      if (dueAt != null) 'due_at': dueAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkTodosCompanion copyWith({
    Value<String?>? seriesId,
    Value<String?>? occurrenceKey,
    Value<int?>? occurrenceIndex,
    Value<String>? id,
    Value<int>? version,
    Value<String?>? categoryId,
    Value<String>? status,
    Value<DateTime?>? dueAt,
    Value<int>? sortOrder,
    Value<String>? payload,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return WorkTodosCompanion(
      seriesId: seriesId ?? this.seriesId,
      occurrenceKey: occurrenceKey ?? this.occurrenceKey,
      occurrenceIndex: occurrenceIndex ?? this.occurrenceIndex,
      id: id ?? this.id,
      version: version ?? this.version,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      dueAt: dueAt ?? this.dueAt,
      sortOrder: sortOrder ?? this.sortOrder,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (occurrenceKey.present) {
      map['occurrence_key'] = Variable<String>(occurrenceKey.value);
    }
    if (occurrenceIndex.present) {
      map['occurrence_index'] = Variable<int>(occurrenceIndex.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkTodosCompanion(')
          ..write('seriesId: $seriesId, ')
          ..write('occurrenceKey: $occurrenceKey, ')
          ..write('occurrenceIndex: $occurrenceIndex, ')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('categoryId: $categoryId, ')
          ..write('status: $status, ')
          ..write('dueAt: $dueAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkTodoSeriesTable extends WorkTodoSeries
    with TableInfo<$WorkTodoSeriesTable, WorkTodoSery> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkTodoSeriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    version,
    payload,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'work_todo_series';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkTodoSery> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkTodoSery map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkTodoSery(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $WorkTodoSeriesTable createAlias(String alias) {
    return $WorkTodoSeriesTable(attachedDatabase, alias);
  }
}

class WorkTodoSery extends DataClass implements Insertable<WorkTodoSery> {
  final String id;
  final int version;
  final String payload;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const WorkTodoSery({
    required this.id,
    required this.version,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['version'] = Variable<int>(version);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  WorkTodoSeriesCompanion toCompanion(bool nullToAbsent) {
    return WorkTodoSeriesCompanion(
      id: Value(id),
      version: Value(version),
      payload: Value(payload),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory WorkTodoSery.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkTodoSery(
      id: serializer.fromJson<String>(json['id']),
      version: serializer.fromJson<int>(json['version']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'version': serializer.toJson<int>(version),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  WorkTodoSery copyWith({
    String? id,
    int? version,
    String? payload,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => WorkTodoSery(
    id: id ?? this.id,
    version: version ?? this.version,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  WorkTodoSery copyWithCompanion(WorkTodoSeriesCompanion data) {
    return WorkTodoSery(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkTodoSery(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, version, payload, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkTodoSery &&
          other.id == this.id &&
          other.version == this.version &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class WorkTodoSeriesCompanion extends UpdateCompanion<WorkTodoSery> {
  final Value<String> id;
  final Value<int> version;
  final Value<String> payload;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const WorkTodoSeriesCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkTodoSeriesCompanion.insert({
    required String id,
    required int version,
    required String payload,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       version = Value(version),
       payload = Value(payload),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WorkTodoSery> custom({
    Expression<String>? id,
    Expression<int>? version,
    Expression<String>? payload,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkTodoSeriesCompanion copyWith({
    Value<String>? id,
    Value<int>? version,
    Value<String>? payload,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return WorkTodoSeriesCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkTodoSeriesCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkCategoriesTable extends WorkCategories
    with TableInfo<$WorkCategoriesTable, WorkCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    version,
    parentId,
    archived,
    sortOrder,
    payload,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'work_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    } else if (isInserting) {
      context.missing(_archivedMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $WorkCategoriesTable createAlias(String alias) {
    return $WorkCategoriesTable(attachedDatabase, alias);
  }
}

class WorkCategory extends DataClass implements Insertable<WorkCategory> {
  final String id;
  final int version;
  final String? parentId;
  final bool archived;
  final int sortOrder;
  final String payload;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const WorkCategory({
    required this.id,
    required this.version,
    this.parentId,
    required this.archived,
    required this.sortOrder,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['archived'] = Variable<bool>(archived);
    map['sort_order'] = Variable<int>(sortOrder);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  WorkCategoriesCompanion toCompanion(bool nullToAbsent) {
    return WorkCategoriesCompanion(
      id: Value(id),
      version: Value(version),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      archived: Value(archived),
      sortOrder: Value(sortOrder),
      payload: Value(payload),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory WorkCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkCategory(
      id: serializer.fromJson<String>(json['id']),
      version: serializer.fromJson<int>(json['version']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      archived: serializer.fromJson<bool>(json['archived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'version': serializer.toJson<int>(version),
      'parentId': serializer.toJson<String?>(parentId),
      'archived': serializer.toJson<bool>(archived),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  WorkCategory copyWith({
    String? id,
    int? version,
    Value<String?> parentId = const Value.absent(),
    bool? archived,
    int? sortOrder,
    String? payload,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => WorkCategory(
    id: id ?? this.id,
    version: version ?? this.version,
    parentId: parentId.present ? parentId.value : this.parentId,
    archived: archived ?? this.archived,
    sortOrder: sortOrder ?? this.sortOrder,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  WorkCategory copyWithCompanion(WorkCategoriesCompanion data) {
    return WorkCategory(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      archived: data.archived.present ? data.archived.value : this.archived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkCategory(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('parentId: $parentId, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    version,
    parentId,
    archived,
    sortOrder,
    payload,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkCategory &&
          other.id == this.id &&
          other.version == this.version &&
          other.parentId == this.parentId &&
          other.archived == this.archived &&
          other.sortOrder == this.sortOrder &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class WorkCategoriesCompanion extends UpdateCompanion<WorkCategory> {
  final Value<String> id;
  final Value<int> version;
  final Value<String?> parentId;
  final Value<bool> archived;
  final Value<int> sortOrder;
  final Value<String> payload;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const WorkCategoriesCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.parentId = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkCategoriesCompanion.insert({
    required String id,
    required int version,
    this.parentId = const Value.absent(),
    required bool archived,
    required int sortOrder,
    required String payload,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       version = Value(version),
       archived = Value(archived),
       sortOrder = Value(sortOrder),
       payload = Value(payload),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WorkCategory> custom({
    Expression<String>? id,
    Expression<int>? version,
    Expression<String>? parentId,
    Expression<bool>? archived,
    Expression<int>? sortOrder,
    Expression<String>? payload,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (parentId != null) 'parent_id': parentId,
      if (archived != null) 'archived': archived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkCategoriesCompanion copyWith({
    Value<String>? id,
    Value<int>? version,
    Value<String?>? parentId,
    Value<bool>? archived,
    Value<int>? sortOrder,
    Value<String>? payload,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return WorkCategoriesCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      parentId: parentId ?? this.parentId,
      archived: archived ?? this.archived,
      sortOrder: sortOrder ?? this.sortOrder,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('parentId: $parentId, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkspaceOperationsTable extends WorkspaceOperations
    with TableInfo<$WorkspaceOperationsTable, WorkspaceOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkspaceOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestDigestMeta = const VerificationMeta(
    'requestDigest',
  );
  @override
  late final GeneratedColumn<String> requestDigest = GeneratedColumn<String>(
    'request_digest',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _undoOfMeta = const VerificationMeta('undoOf');
  @override
  late final GeneratedColumn<String> undoOf = GeneratedColumn<String>(
    'undo_of',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptMeta = const VerificationMeta(
    'receipt',
  );
  @override
  late final GeneratedColumn<String> receipt = GeneratedColumn<String>(
    'receipt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changesMeta = const VerificationMeta(
    'changes',
  );
  @override
  late final GeneratedColumn<String> changes = GeneratedColumn<String>(
    'changes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _committedAtMeta = const VerificationMeta(
    'committedAt',
  );
  @override
  late final GeneratedColumn<int> committedAt = GeneratedColumn<int>(
    'committed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    operationId,
    requestDigest,
    source,
    undoOf,
    receipt,
    changes,
    committedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspace_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkspaceOperation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('request_digest')) {
      context.handle(
        _requestDigestMeta,
        requestDigest.isAcceptableOrUnknown(
          data['request_digest']!,
          _requestDigestMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestDigestMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('undo_of')) {
      context.handle(
        _undoOfMeta,
        undoOf.isAcceptableOrUnknown(data['undo_of']!, _undoOfMeta),
      );
    }
    if (data.containsKey('receipt')) {
      context.handle(
        _receiptMeta,
        receipt.isAcceptableOrUnknown(data['receipt']!, _receiptMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptMeta);
    }
    if (data.containsKey('changes')) {
      context.handle(
        _changesMeta,
        changes.isAcceptableOrUnknown(data['changes']!, _changesMeta),
      );
    } else if (isInserting) {
      context.missing(_changesMeta);
    }
    if (data.containsKey('committed_at')) {
      context.handle(
        _committedAtMeta,
        committedAt.isAcceptableOrUnknown(
          data['committed_at']!,
          _committedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_committedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  WorkspaceOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspaceOperation(
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      requestDigest: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_digest'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      undoOf: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}undo_of'],
      ),
      receipt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt'],
      )!,
      changes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}changes'],
      )!,
      committedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}committed_at'],
      )!,
    );
  }

  @override
  $WorkspaceOperationsTable createAlias(String alias) {
    return $WorkspaceOperationsTable(attachedDatabase, alias);
  }
}

class WorkspaceOperation extends DataClass
    implements Insertable<WorkspaceOperation> {
  final String operationId;
  final String requestDigest;
  final String source;
  final String? undoOf;
  final String receipt;
  final String changes;
  final int committedAt;
  const WorkspaceOperation({
    required this.operationId,
    required this.requestDigest,
    required this.source,
    this.undoOf,
    required this.receipt,
    required this.changes,
    required this.committedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['request_digest'] = Variable<String>(requestDigest);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || undoOf != null) {
      map['undo_of'] = Variable<String>(undoOf);
    }
    map['receipt'] = Variable<String>(receipt);
    map['changes'] = Variable<String>(changes);
    map['committed_at'] = Variable<int>(committedAt);
    return map;
  }

  WorkspaceOperationsCompanion toCompanion(bool nullToAbsent) {
    return WorkspaceOperationsCompanion(
      operationId: Value(operationId),
      requestDigest: Value(requestDigest),
      source: Value(source),
      undoOf: undoOf == null && nullToAbsent
          ? const Value.absent()
          : Value(undoOf),
      receipt: Value(receipt),
      changes: Value(changes),
      committedAt: Value(committedAt),
    );
  }

  factory WorkspaceOperation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspaceOperation(
      operationId: serializer.fromJson<String>(json['operationId']),
      requestDigest: serializer.fromJson<String>(json['requestDigest']),
      source: serializer.fromJson<String>(json['source']),
      undoOf: serializer.fromJson<String?>(json['undoOf']),
      receipt: serializer.fromJson<String>(json['receipt']),
      changes: serializer.fromJson<String>(json['changes']),
      committedAt: serializer.fromJson<int>(json['committedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationId': serializer.toJson<String>(operationId),
      'requestDigest': serializer.toJson<String>(requestDigest),
      'source': serializer.toJson<String>(source),
      'undoOf': serializer.toJson<String?>(undoOf),
      'receipt': serializer.toJson<String>(receipt),
      'changes': serializer.toJson<String>(changes),
      'committedAt': serializer.toJson<int>(committedAt),
    };
  }

  WorkspaceOperation copyWith({
    String? operationId,
    String? requestDigest,
    String? source,
    Value<String?> undoOf = const Value.absent(),
    String? receipt,
    String? changes,
    int? committedAt,
  }) => WorkspaceOperation(
    operationId: operationId ?? this.operationId,
    requestDigest: requestDigest ?? this.requestDigest,
    source: source ?? this.source,
    undoOf: undoOf.present ? undoOf.value : this.undoOf,
    receipt: receipt ?? this.receipt,
    changes: changes ?? this.changes,
    committedAt: committedAt ?? this.committedAt,
  );
  WorkspaceOperation copyWithCompanion(WorkspaceOperationsCompanion data) {
    return WorkspaceOperation(
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      requestDigest: data.requestDigest.present
          ? data.requestDigest.value
          : this.requestDigest,
      source: data.source.present ? data.source.value : this.source,
      undoOf: data.undoOf.present ? data.undoOf.value : this.undoOf,
      receipt: data.receipt.present ? data.receipt.value : this.receipt,
      changes: data.changes.present ? data.changes.value : this.changes,
      committedAt: data.committedAt.present
          ? data.committedAt.value
          : this.committedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceOperation(')
          ..write('operationId: $operationId, ')
          ..write('requestDigest: $requestDigest, ')
          ..write('source: $source, ')
          ..write('undoOf: $undoOf, ')
          ..write('receipt: $receipt, ')
          ..write('changes: $changes, ')
          ..write('committedAt: $committedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    operationId,
    requestDigest,
    source,
    undoOf,
    receipt,
    changes,
    committedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspaceOperation &&
          other.operationId == this.operationId &&
          other.requestDigest == this.requestDigest &&
          other.source == this.source &&
          other.undoOf == this.undoOf &&
          other.receipt == this.receipt &&
          other.changes == this.changes &&
          other.committedAt == this.committedAt);
}

class WorkspaceOperationsCompanion extends UpdateCompanion<WorkspaceOperation> {
  final Value<String> operationId;
  final Value<String> requestDigest;
  final Value<String> source;
  final Value<String?> undoOf;
  final Value<String> receipt;
  final Value<String> changes;
  final Value<int> committedAt;
  final Value<int> rowid;
  const WorkspaceOperationsCompanion({
    this.operationId = const Value.absent(),
    this.requestDigest = const Value.absent(),
    this.source = const Value.absent(),
    this.undoOf = const Value.absent(),
    this.receipt = const Value.absent(),
    this.changes = const Value.absent(),
    this.committedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspaceOperationsCompanion.insert({
    required String operationId,
    required String requestDigest,
    required String source,
    this.undoOf = const Value.absent(),
    required String receipt,
    required String changes,
    required int committedAt,
    this.rowid = const Value.absent(),
  }) : operationId = Value(operationId),
       requestDigest = Value(requestDigest),
       source = Value(source),
       receipt = Value(receipt),
       changes = Value(changes),
       committedAt = Value(committedAt);
  static Insertable<WorkspaceOperation> custom({
    Expression<String>? operationId,
    Expression<String>? requestDigest,
    Expression<String>? source,
    Expression<String>? undoOf,
    Expression<String>? receipt,
    Expression<String>? changes,
    Expression<int>? committedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (requestDigest != null) 'request_digest': requestDigest,
      if (source != null) 'source': source,
      if (undoOf != null) 'undo_of': undoOf,
      if (receipt != null) 'receipt': receipt,
      if (changes != null) 'changes': changes,
      if (committedAt != null) 'committed_at': committedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspaceOperationsCompanion copyWith({
    Value<String>? operationId,
    Value<String>? requestDigest,
    Value<String>? source,
    Value<String?>? undoOf,
    Value<String>? receipt,
    Value<String>? changes,
    Value<int>? committedAt,
    Value<int>? rowid,
  }) {
    return WorkspaceOperationsCompanion(
      operationId: operationId ?? this.operationId,
      requestDigest: requestDigest ?? this.requestDigest,
      source: source ?? this.source,
      undoOf: undoOf ?? this.undoOf,
      receipt: receipt ?? this.receipt,
      changes: changes ?? this.changes,
      committedAt: committedAt ?? this.committedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (requestDigest.present) {
      map['request_digest'] = Variable<String>(requestDigest.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (undoOf.present) {
      map['undo_of'] = Variable<String>(undoOf.value);
    }
    if (receipt.present) {
      map['receipt'] = Variable<String>(receipt.value);
    }
    if (changes.present) {
      map['changes'] = Variable<String>(changes.value);
    }
    if (committedAt.present) {
      map['committed_at'] = Variable<int>(committedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceOperationsCompanion(')
          ..write('operationId: $operationId, ')
          ..write('requestDigest: $requestDigest, ')
          ..write('source: $source, ')
          ..write('undoOf: $undoOf, ')
          ..write('receipt: $receipt, ')
          ..write('changes: $changes, ')
          ..write('committedAt: $committedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkDataTablesTable extends WorkDataTables
    with TableInfo<$WorkDataTablesTable, WorkDataTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkDataTablesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _typeIdMeta = const VerificationMeta('typeId');
  @override
  late final GeneratedColumn<String> typeId = GeneratedColumn<String>(
    'type_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
  );
  static const VerificationMeta _schemaRevisionMeta = const VerificationMeta(
    'schemaRevision',
  );
  @override
  late final GeneratedColumn<int> schemaRevision = GeneratedColumn<int>(
    'schema_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    typeId,
    archived,
    schemaRevision,
    id,
    version,
    payload,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'work_data_tables';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkDataTable> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('type_id')) {
      context.handle(
        _typeIdMeta,
        typeId.isAcceptableOrUnknown(data['type_id']!, _typeIdMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    } else if (isInserting) {
      context.missing(_archivedMeta);
    }
    if (data.containsKey('schema_revision')) {
      context.handle(
        _schemaRevisionMeta,
        schemaRevision.isAcceptableOrUnknown(
          data['schema_revision']!,
          _schemaRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_schemaRevisionMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkDataTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkDataTable(
      typeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_id'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      schemaRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_revision'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $WorkDataTablesTable createAlias(String alias) {
    return $WorkDataTablesTable(attachedDatabase, alias);
  }
}

class WorkDataTable extends DataClass implements Insertable<WorkDataTable> {
  final String? typeId;
  final bool archived;
  final int schemaRevision;
  final String id;
  final int version;
  final String payload;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const WorkDataTable({
    this.typeId,
    required this.archived,
    required this.schemaRevision,
    required this.id,
    required this.version,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || typeId != null) {
      map['type_id'] = Variable<String>(typeId);
    }
    map['archived'] = Variable<bool>(archived);
    map['schema_revision'] = Variable<int>(schemaRevision);
    map['id'] = Variable<String>(id);
    map['version'] = Variable<int>(version);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  WorkDataTablesCompanion toCompanion(bool nullToAbsent) {
    return WorkDataTablesCompanion(
      typeId: typeId == null && nullToAbsent
          ? const Value.absent()
          : Value(typeId),
      archived: Value(archived),
      schemaRevision: Value(schemaRevision),
      id: Value(id),
      version: Value(version),
      payload: Value(payload),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory WorkDataTable.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkDataTable(
      typeId: serializer.fromJson<String?>(json['typeId']),
      archived: serializer.fromJson<bool>(json['archived']),
      schemaRevision: serializer.fromJson<int>(json['schemaRevision']),
      id: serializer.fromJson<String>(json['id']),
      version: serializer.fromJson<int>(json['version']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'typeId': serializer.toJson<String?>(typeId),
      'archived': serializer.toJson<bool>(archived),
      'schemaRevision': serializer.toJson<int>(schemaRevision),
      'id': serializer.toJson<String>(id),
      'version': serializer.toJson<int>(version),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  WorkDataTable copyWith({
    Value<String?> typeId = const Value.absent(),
    bool? archived,
    int? schemaRevision,
    String? id,
    int? version,
    String? payload,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => WorkDataTable(
    typeId: typeId.present ? typeId.value : this.typeId,
    archived: archived ?? this.archived,
    schemaRevision: schemaRevision ?? this.schemaRevision,
    id: id ?? this.id,
    version: version ?? this.version,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  WorkDataTable copyWithCompanion(WorkDataTablesCompanion data) {
    return WorkDataTable(
      typeId: data.typeId.present ? data.typeId.value : this.typeId,
      archived: data.archived.present ? data.archived.value : this.archived,
      schemaRevision: data.schemaRevision.present
          ? data.schemaRevision.value
          : this.schemaRevision,
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkDataTable(')
          ..write('typeId: $typeId, ')
          ..write('archived: $archived, ')
          ..write('schemaRevision: $schemaRevision, ')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    typeId,
    archived,
    schemaRevision,
    id,
    version,
    payload,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkDataTable &&
          other.typeId == this.typeId &&
          other.archived == this.archived &&
          other.schemaRevision == this.schemaRevision &&
          other.id == this.id &&
          other.version == this.version &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class WorkDataTablesCompanion extends UpdateCompanion<WorkDataTable> {
  final Value<String?> typeId;
  final Value<bool> archived;
  final Value<int> schemaRevision;
  final Value<String> id;
  final Value<int> version;
  final Value<String> payload;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const WorkDataTablesCompanion({
    this.typeId = const Value.absent(),
    this.archived = const Value.absent(),
    this.schemaRevision = const Value.absent(),
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkDataTablesCompanion.insert({
    this.typeId = const Value.absent(),
    required bool archived,
    required int schemaRevision,
    required String id,
    required int version,
    required String payload,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : archived = Value(archived),
       schemaRevision = Value(schemaRevision),
       id = Value(id),
       version = Value(version),
       payload = Value(payload),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WorkDataTable> custom({
    Expression<String>? typeId,
    Expression<bool>? archived,
    Expression<int>? schemaRevision,
    Expression<String>? id,
    Expression<int>? version,
    Expression<String>? payload,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (typeId != null) 'type_id': typeId,
      if (archived != null) 'archived': archived,
      if (schemaRevision != null) 'schema_revision': schemaRevision,
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkDataTablesCompanion copyWith({
    Value<String?>? typeId,
    Value<bool>? archived,
    Value<int>? schemaRevision,
    Value<String>? id,
    Value<int>? version,
    Value<String>? payload,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return WorkDataTablesCompanion(
      typeId: typeId ?? this.typeId,
      archived: archived ?? this.archived,
      schemaRevision: schemaRevision ?? this.schemaRevision,
      id: id ?? this.id,
      version: version ?? this.version,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (typeId.present) {
      map['type_id'] = Variable<String>(typeId.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (schemaRevision.present) {
      map['schema_revision'] = Variable<int>(schemaRevision.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkDataTablesCompanion(')
          ..write('typeId: $typeId, ')
          ..write('archived: $archived, ')
          ..write('schemaRevision: $schemaRevision, ')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkDataRowsTable extends WorkDataRows
    with TableInfo<$WorkDataRowsTable, WorkDataRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkDataRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tableIdMeta = const VerificationMeta(
    'tableId',
  );
  @override
  late final GeneratedColumn<String> tableId = GeneratedColumn<String>(
    'table_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tableId,
    id,
    version,
    payload,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'work_data_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkDataRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('table_id')) {
      context.handle(
        _tableIdMeta,
        tableId.isAcceptableOrUnknown(data['table_id']!, _tableIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tableIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkDataRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkDataRow(
      tableId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $WorkDataRowsTable createAlias(String alias) {
    return $WorkDataRowsTable(attachedDatabase, alias);
  }
}

class WorkDataRow extends DataClass implements Insertable<WorkDataRow> {
  final String tableId;
  final String id;
  final int version;
  final String payload;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const WorkDataRow({
    required this.tableId,
    required this.id,
    required this.version,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['table_id'] = Variable<String>(tableId);
    map['id'] = Variable<String>(id);
    map['version'] = Variable<int>(version);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  WorkDataRowsCompanion toCompanion(bool nullToAbsent) {
    return WorkDataRowsCompanion(
      tableId: Value(tableId),
      id: Value(id),
      version: Value(version),
      payload: Value(payload),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory WorkDataRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkDataRow(
      tableId: serializer.fromJson<String>(json['tableId']),
      id: serializer.fromJson<String>(json['id']),
      version: serializer.fromJson<int>(json['version']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tableId': serializer.toJson<String>(tableId),
      'id': serializer.toJson<String>(id),
      'version': serializer.toJson<int>(version),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  WorkDataRow copyWith({
    String? tableId,
    String? id,
    int? version,
    String? payload,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => WorkDataRow(
    tableId: tableId ?? this.tableId,
    id: id ?? this.id,
    version: version ?? this.version,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  WorkDataRow copyWithCompanion(WorkDataRowsCompanion data) {
    return WorkDataRow(
      tableId: data.tableId.present ? data.tableId.value : this.tableId,
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkDataRow(')
          ..write('tableId: $tableId, ')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tableId,
    id,
    version,
    payload,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkDataRow &&
          other.tableId == this.tableId &&
          other.id == this.id &&
          other.version == this.version &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class WorkDataRowsCompanion extends UpdateCompanion<WorkDataRow> {
  final Value<String> tableId;
  final Value<String> id;
  final Value<int> version;
  final Value<String> payload;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const WorkDataRowsCompanion({
    this.tableId = const Value.absent(),
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkDataRowsCompanion.insert({
    required String tableId,
    required String id,
    required int version,
    required String payload,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tableId = Value(tableId),
       id = Value(id),
       version = Value(version),
       payload = Value(payload),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WorkDataRow> custom({
    Expression<String>? tableId,
    Expression<String>? id,
    Expression<int>? version,
    Expression<String>? payload,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tableId != null) 'table_id': tableId,
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkDataRowsCompanion copyWith({
    Value<String>? tableId,
    Value<String>? id,
    Value<int>? version,
    Value<String>? payload,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return WorkDataRowsCompanion(
      tableId: tableId ?? this.tableId,
      id: id ?? this.id,
      version: version ?? this.version,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tableId.present) {
      map['table_id'] = Variable<String>(tableId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkDataRowsCompanion(')
          ..write('tableId: $tableId, ')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkTableTypesTable extends WorkTableTypes
    with TableInfo<$WorkTableTypesTable, WorkTableType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkTableTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    version,
    payload,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'work_table_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkTableType> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkTableType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkTableType(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $WorkTableTypesTable createAlias(String alias) {
    return $WorkTableTypesTable(attachedDatabase, alias);
  }
}

class WorkTableType extends DataClass implements Insertable<WorkTableType> {
  final String id;
  final int version;
  final String payload;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const WorkTableType({
    required this.id,
    required this.version,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['version'] = Variable<int>(version);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  WorkTableTypesCompanion toCompanion(bool nullToAbsent) {
    return WorkTableTypesCompanion(
      id: Value(id),
      version: Value(version),
      payload: Value(payload),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory WorkTableType.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkTableType(
      id: serializer.fromJson<String>(json['id']),
      version: serializer.fromJson<int>(json['version']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'version': serializer.toJson<int>(version),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  WorkTableType copyWith({
    String? id,
    int? version,
    String? payload,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => WorkTableType(
    id: id ?? this.id,
    version: version ?? this.version,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  WorkTableType copyWithCompanion(WorkTableTypesCompanion data) {
    return WorkTableType(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkTableType(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, version, payload, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkTableType &&
          other.id == this.id &&
          other.version == this.version &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class WorkTableTypesCompanion extends UpdateCompanion<WorkTableType> {
  final Value<String> id;
  final Value<int> version;
  final Value<String> payload;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const WorkTableTypesCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkTableTypesCompanion.insert({
    required String id,
    required int version,
    required String payload,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       version = Value(version),
       payload = Value(payload),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WorkTableType> custom({
    Expression<String>? id,
    Expression<int>? version,
    Expression<String>? payload,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkTableTypesCompanion copyWith({
    Value<String>? id,
    Value<int>? version,
    Value<String>? payload,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return WorkTableTypesCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkTableTypesCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppPreferenceRowsTable extends AppPreferenceRows
    with TableInfo<$AppPreferenceRowsTable, AppPreferenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppPreferenceRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _singletonIdMeta = const VerificationMeta(
    'singletonId',
  );
  @override
  late final GeneratedColumn<int> singletonId = GeneratedColumn<int>(
    'singleton_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [singletonId, version, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_preference_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppPreferenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('singleton_id')) {
      context.handle(
        _singletonIdMeta,
        singletonId.isAcceptableOrUnknown(
          data['singleton_id']!,
          _singletonIdMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {singletonId};
  @override
  AppPreferenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppPreferenceRow(
      singletonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $AppPreferenceRowsTable createAlias(String alias) {
    return $AppPreferenceRowsTable(attachedDatabase, alias);
  }
}

class AppPreferenceRow extends DataClass
    implements Insertable<AppPreferenceRow> {
  final int singletonId;
  final int version;
  final String payload;
  const AppPreferenceRow({
    required this.singletonId,
    required this.version,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['singleton_id'] = Variable<int>(singletonId);
    map['version'] = Variable<int>(version);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  AppPreferenceRowsCompanion toCompanion(bool nullToAbsent) {
    return AppPreferenceRowsCompanion(
      singletonId: Value(singletonId),
      version: Value(version),
      payload: Value(payload),
    );
  }

  factory AppPreferenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppPreferenceRow(
      singletonId: serializer.fromJson<int>(json['singletonId']),
      version: serializer.fromJson<int>(json['version']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'singletonId': serializer.toJson<int>(singletonId),
      'version': serializer.toJson<int>(version),
      'payload': serializer.toJson<String>(payload),
    };
  }

  AppPreferenceRow copyWith({
    int? singletonId,
    int? version,
    String? payload,
  }) => AppPreferenceRow(
    singletonId: singletonId ?? this.singletonId,
    version: version ?? this.version,
    payload: payload ?? this.payload,
  );
  AppPreferenceRow copyWithCompanion(AppPreferenceRowsCompanion data) {
    return AppPreferenceRow(
      singletonId: data.singletonId.present
          ? data.singletonId.value
          : this.singletonId,
      version: data.version.present ? data.version.value : this.version,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppPreferenceRow(')
          ..write('singletonId: $singletonId, ')
          ..write('version: $version, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(singletonId, version, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppPreferenceRow &&
          other.singletonId == this.singletonId &&
          other.version == this.version &&
          other.payload == this.payload);
}

class AppPreferenceRowsCompanion extends UpdateCompanion<AppPreferenceRow> {
  final Value<int> singletonId;
  final Value<int> version;
  final Value<String> payload;
  const AppPreferenceRowsCompanion({
    this.singletonId = const Value.absent(),
    this.version = const Value.absent(),
    this.payload = const Value.absent(),
  });
  AppPreferenceRowsCompanion.insert({
    this.singletonId = const Value.absent(),
    required int version,
    required String payload,
  }) : version = Value(version),
       payload = Value(payload);
  static Insertable<AppPreferenceRow> custom({
    Expression<int>? singletonId,
    Expression<int>? version,
    Expression<String>? payload,
  }) {
    return RawValuesInsertable({
      if (singletonId != null) 'singleton_id': singletonId,
      if (version != null) 'version': version,
      if (payload != null) 'payload': payload,
    });
  }

  AppPreferenceRowsCompanion copyWith({
    Value<int>? singletonId,
    Value<int>? version,
    Value<String>? payload,
  }) {
    return AppPreferenceRowsCompanion(
      singletonId: singletonId ?? this.singletonId,
      version: version ?? this.version,
      payload: payload ?? this.payload,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (singletonId.present) {
      map['singleton_id'] = Variable<int>(singletonId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppPreferenceRowsCompanion(')
          ..write('singletonId: $singletonId, ')
          ..write('version: $version, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }
}

class $AgentRunRowsTable extends AgentRunRows
    with TableInfo<$AgentRunRowsTable, AgentRunRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgentRunRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputIdMeta = const VerificationMeta(
    'inputId',
  );
  @override
  late final GeneratedColumn<String> inputId = GeneratedColumn<String>(
    'input_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _initialRequestMeta = const VerificationMeta(
    'initialRequest',
  );
  @override
  late final GeneratedColumn<String> initialRequest = GeneratedColumn<String>(
    'initial_request',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    inputId,
    revision,
    status,
    initialRequest,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_run_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<AgentRunRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('input_id')) {
      context.handle(
        _inputIdMeta,
        inputId.isAcceptableOrUnknown(data['input_id']!, _inputIdMeta),
      );
    } else if (isInserting) {
      context.missing(_inputIdMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('initial_request')) {
      context.handle(
        _initialRequestMeta,
        initialRequest.isAcceptableOrUnknown(
          data['initial_request']!,
          _initialRequestMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initialRequestMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sessionId, inputId},
  ];
  @override
  AgentRunRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentRunRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      inputId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      initialRequest: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}initial_request'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $AgentRunRowsTable createAlias(String alias) {
    return $AgentRunRowsTable(attachedDatabase, alias);
  }
}

class AgentRunRow extends DataClass implements Insertable<AgentRunRow> {
  final String id;
  final String sessionId;
  final String inputId;
  final int revision;
  final String status;
  final String initialRequest;
  final String payload;
  const AgentRunRow({
    required this.id,
    required this.sessionId,
    required this.inputId,
    required this.revision,
    required this.status,
    required this.initialRequest,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['input_id'] = Variable<String>(inputId);
    map['revision'] = Variable<int>(revision);
    map['status'] = Variable<String>(status);
    map['initial_request'] = Variable<String>(initialRequest);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  AgentRunRowsCompanion toCompanion(bool nullToAbsent) {
    return AgentRunRowsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      inputId: Value(inputId),
      revision: Value(revision),
      status: Value(status),
      initialRequest: Value(initialRequest),
      payload: Value(payload),
    );
  }

  factory AgentRunRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentRunRow(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      inputId: serializer.fromJson<String>(json['inputId']),
      revision: serializer.fromJson<int>(json['revision']),
      status: serializer.fromJson<String>(json['status']),
      initialRequest: serializer.fromJson<String>(json['initialRequest']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'inputId': serializer.toJson<String>(inputId),
      'revision': serializer.toJson<int>(revision),
      'status': serializer.toJson<String>(status),
      'initialRequest': serializer.toJson<String>(initialRequest),
      'payload': serializer.toJson<String>(payload),
    };
  }

  AgentRunRow copyWith({
    String? id,
    String? sessionId,
    String? inputId,
    int? revision,
    String? status,
    String? initialRequest,
    String? payload,
  }) => AgentRunRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    inputId: inputId ?? this.inputId,
    revision: revision ?? this.revision,
    status: status ?? this.status,
    initialRequest: initialRequest ?? this.initialRequest,
    payload: payload ?? this.payload,
  );
  AgentRunRow copyWithCompanion(AgentRunRowsCompanion data) {
    return AgentRunRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      inputId: data.inputId.present ? data.inputId.value : this.inputId,
      revision: data.revision.present ? data.revision.value : this.revision,
      status: data.status.present ? data.status.value : this.status,
      initialRequest: data.initialRequest.present
          ? data.initialRequest.value
          : this.initialRequest,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentRunRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('inputId: $inputId, ')
          ..write('revision: $revision, ')
          ..write('status: $status, ')
          ..write('initialRequest: $initialRequest, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    inputId,
    revision,
    status,
    initialRequest,
    payload,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentRunRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.inputId == this.inputId &&
          other.revision == this.revision &&
          other.status == this.status &&
          other.initialRequest == this.initialRequest &&
          other.payload == this.payload);
}

class AgentRunRowsCompanion extends UpdateCompanion<AgentRunRow> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> inputId;
  final Value<int> revision;
  final Value<String> status;
  final Value<String> initialRequest;
  final Value<String> payload;
  final Value<int> rowid;
  const AgentRunRowsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.inputId = const Value.absent(),
    this.revision = const Value.absent(),
    this.status = const Value.absent(),
    this.initialRequest = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentRunRowsCompanion.insert({
    required String id,
    required String sessionId,
    required String inputId,
    required int revision,
    required String status,
    required String initialRequest,
    required String payload,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       inputId = Value(inputId),
       revision = Value(revision),
       status = Value(status),
       initialRequest = Value(initialRequest),
       payload = Value(payload);
  static Insertable<AgentRunRow> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? inputId,
    Expression<int>? revision,
    Expression<String>? status,
    Expression<String>? initialRequest,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (inputId != null) 'input_id': inputId,
      if (revision != null) 'revision': revision,
      if (status != null) 'status': status,
      if (initialRequest != null) 'initial_request': initialRequest,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentRunRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? inputId,
    Value<int>? revision,
    Value<String>? status,
    Value<String>? initialRequest,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return AgentRunRowsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      inputId: inputId ?? this.inputId,
      revision: revision ?? this.revision,
      status: status ?? this.status,
      initialRequest: initialRequest ?? this.initialRequest,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (inputId.present) {
      map['input_id'] = Variable<String>(inputId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (initialRequest.present) {
      map['initial_request'] = Variable<String>(initialRequest.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentRunRowsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('inputId: $inputId, ')
          ..write('revision: $revision, ')
          ..write('status: $status, ')
          ..write('initialRequest: $initialRequest, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AgentRunEventsTable extends AgentRunEvents
    with TableInfo<$AgentRunEventsTable, AgentRunEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgentRunEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [runId, sequence, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_run_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<AgentRunEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {runId, sequence};
  @override
  AgentRunEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentRunEvent(
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $AgentRunEventsTable createAlias(String alias) {
    return $AgentRunEventsTable(attachedDatabase, alias);
  }
}

class AgentRunEvent extends DataClass implements Insertable<AgentRunEvent> {
  final String runId;
  final int sequence;
  final String payload;
  const AgentRunEvent({
    required this.runId,
    required this.sequence,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['run_id'] = Variable<String>(runId);
    map['sequence'] = Variable<int>(sequence);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  AgentRunEventsCompanion toCompanion(bool nullToAbsent) {
    return AgentRunEventsCompanion(
      runId: Value(runId),
      sequence: Value(sequence),
      payload: Value(payload),
    );
  }

  factory AgentRunEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentRunEvent(
      runId: serializer.fromJson<String>(json['runId']),
      sequence: serializer.fromJson<int>(json['sequence']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'runId': serializer.toJson<String>(runId),
      'sequence': serializer.toJson<int>(sequence),
      'payload': serializer.toJson<String>(payload),
    };
  }

  AgentRunEvent copyWith({String? runId, int? sequence, String? payload}) =>
      AgentRunEvent(
        runId: runId ?? this.runId,
        sequence: sequence ?? this.sequence,
        payload: payload ?? this.payload,
      );
  AgentRunEvent copyWithCompanion(AgentRunEventsCompanion data) {
    return AgentRunEvent(
      runId: data.runId.present ? data.runId.value : this.runId,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentRunEvent(')
          ..write('runId: $runId, ')
          ..write('sequence: $sequence, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(runId, sequence, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentRunEvent &&
          other.runId == this.runId &&
          other.sequence == this.sequence &&
          other.payload == this.payload);
}

class AgentRunEventsCompanion extends UpdateCompanion<AgentRunEvent> {
  final Value<String> runId;
  final Value<int> sequence;
  final Value<String> payload;
  final Value<int> rowid;
  const AgentRunEventsCompanion({
    this.runId = const Value.absent(),
    this.sequence = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentRunEventsCompanion.insert({
    required String runId,
    required int sequence,
    required String payload,
    this.rowid = const Value.absent(),
  }) : runId = Value(runId),
       sequence = Value(sequence),
       payload = Value(payload);
  static Insertable<AgentRunEvent> custom({
    Expression<String>? runId,
    Expression<int>? sequence,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (runId != null) 'run_id': runId,
      if (sequence != null) 'sequence': sequence,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentRunEventsCompanion copyWith({
    Value<String>? runId,
    Value<int>? sequence,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return AgentRunEventsCompanion(
      runId: runId ?? this.runId,
      sequence: sequence ?? this.sequence,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentRunEventsCompanion(')
          ..write('runId: $runId, ')
          ..write('sequence: $sequence, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatConversationsTable extends ChatConversations
    with TableInfo<$ChatConversationsTable, ChatConversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    revision,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatConversation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatConversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatConversation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ChatConversationsTable createAlias(String alias) {
    return $ChatConversationsTable(attachedDatabase, alias);
  }
}

class ChatConversation extends DataClass
    implements Insertable<ChatConversation> {
  final String id;
  final String title;
  final int revision;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const ChatConversation({
    required this.id,
    required this.title,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['revision'] = Variable<int>(revision);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  ChatConversationsCompanion toCompanion(bool nullToAbsent) {
    return ChatConversationsCompanion(
      id: Value(id),
      title: Value(title),
      revision: Value(revision),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ChatConversation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatConversation(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      revision: serializer.fromJson<int>(json['revision']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'revision': serializer.toJson<int>(revision),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  ChatConversation copyWith({
    String? id,
    String? title,
    int? revision,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => ChatConversation(
    id: id ?? this.id,
    title: title ?? this.title,
    revision: revision ?? this.revision,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  ChatConversation copyWithCompanion(ChatConversationsCompanion data) {
    return ChatConversation(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      revision: data.revision.present ? data.revision.value : this.revision,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatConversation(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, revision, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatConversation &&
          other.id == this.id &&
          other.title == this.title &&
          other.revision == this.revision &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ChatConversationsCompanion extends UpdateCompanion<ChatConversation> {
  final Value<String> id;
  final Value<String> title;
  final Value<int> revision;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const ChatConversationsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.revision = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatConversationsCompanion.insert({
    required String id,
    required String title,
    required int revision,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       revision = Value(revision),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ChatConversation> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? revision,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (revision != null) 'revision': revision,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatConversationsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<int>? revision,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ChatConversationsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatConversationsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatTurnsTable extends ChatTurns
    with TableInfo<$ChatTurnsTable, ChatTurn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatTurnsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _inputIdMeta = const VerificationMeta(
    'inputId',
  );
  @override
  late final GeneratedColumn<String> inputId = GeneratedColumn<String>(
    'input_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _historyStartMeta = const VerificationMeta(
    'historyStart',
  );
  @override
  late final GeneratedColumn<int> historyStart = GeneratedColumn<int>(
    'history_start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _agentEnabledMeta = const VerificationMeta(
    'agentEnabled',
  );
  @override
  late final GeneratedColumn<bool> agentEnabled = GeneratedColumn<bool>(
    'agent_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("agent_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _undoneAtMeta = const VerificationMeta(
    'undoneAt',
  );
  @override
  late final GeneratedColumn<int> undoneAt = GeneratedColumn<int>(
    'undone_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    inputId,
    sessionId,
    runId,
    content,
    position,
    historyStart,
    createdAt,
    agentEnabled,
    undoneAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_turns';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatTurn> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('input_id')) {
      context.handle(
        _inputIdMeta,
        inputId.isAcceptableOrUnknown(data['input_id']!, _inputIdMeta),
      );
    } else if (isInserting) {
      context.missing(_inputIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('history_start')) {
      context.handle(
        _historyStartMeta,
        historyStart.isAcceptableOrUnknown(
          data['history_start']!,
          _historyStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_historyStartMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('agent_enabled')) {
      context.handle(
        _agentEnabledMeta,
        agentEnabled.isAcceptableOrUnknown(
          data['agent_enabled']!,
          _agentEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_agentEnabledMeta);
    }
    if (data.containsKey('undone_at')) {
      context.handle(
        _undoneAtMeta,
        undoneAt.isAcceptableOrUnknown(data['undone_at']!, _undoneAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {inputId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sessionId, position},
  ];
  @override
  ChatTurn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatTurn(
      inputId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      historyStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}history_start'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      agentEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}agent_enabled'],
      )!,
      undoneAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}undone_at'],
      ),
    );
  }

  @override
  $ChatTurnsTable createAlias(String alias) {
    return $ChatTurnsTable(attachedDatabase, alias);
  }
}

class ChatTurn extends DataClass implements Insertable<ChatTurn> {
  final String inputId;
  final String sessionId;
  final String runId;
  final String content;
  final int position;
  final int historyStart;
  final int createdAt;
  final bool agentEnabled;
  final int? undoneAt;
  const ChatTurn({
    required this.inputId,
    required this.sessionId,
    required this.runId,
    required this.content,
    required this.position,
    required this.historyStart,
    required this.createdAt,
    required this.agentEnabled,
    this.undoneAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['input_id'] = Variable<String>(inputId);
    map['session_id'] = Variable<String>(sessionId);
    map['run_id'] = Variable<String>(runId);
    map['content'] = Variable<String>(content);
    map['position'] = Variable<int>(position);
    map['history_start'] = Variable<int>(historyStart);
    map['created_at'] = Variable<int>(createdAt);
    map['agent_enabled'] = Variable<bool>(agentEnabled);
    if (!nullToAbsent || undoneAt != null) {
      map['undone_at'] = Variable<int>(undoneAt);
    }
    return map;
  }

  ChatTurnsCompanion toCompanion(bool nullToAbsent) {
    return ChatTurnsCompanion(
      inputId: Value(inputId),
      sessionId: Value(sessionId),
      runId: Value(runId),
      content: Value(content),
      position: Value(position),
      historyStart: Value(historyStart),
      createdAt: Value(createdAt),
      agentEnabled: Value(agentEnabled),
      undoneAt: undoneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(undoneAt),
    );
  }

  factory ChatTurn.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatTurn(
      inputId: serializer.fromJson<String>(json['inputId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      runId: serializer.fromJson<String>(json['runId']),
      content: serializer.fromJson<String>(json['content']),
      position: serializer.fromJson<int>(json['position']),
      historyStart: serializer.fromJson<int>(json['historyStart']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      agentEnabled: serializer.fromJson<bool>(json['agentEnabled']),
      undoneAt: serializer.fromJson<int?>(json['undoneAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'inputId': serializer.toJson<String>(inputId),
      'sessionId': serializer.toJson<String>(sessionId),
      'runId': serializer.toJson<String>(runId),
      'content': serializer.toJson<String>(content),
      'position': serializer.toJson<int>(position),
      'historyStart': serializer.toJson<int>(historyStart),
      'createdAt': serializer.toJson<int>(createdAt),
      'agentEnabled': serializer.toJson<bool>(agentEnabled),
      'undoneAt': serializer.toJson<int?>(undoneAt),
    };
  }

  ChatTurn copyWith({
    String? inputId,
    String? sessionId,
    String? runId,
    String? content,
    int? position,
    int? historyStart,
    int? createdAt,
    bool? agentEnabled,
    Value<int?> undoneAt = const Value.absent(),
  }) => ChatTurn(
    inputId: inputId ?? this.inputId,
    sessionId: sessionId ?? this.sessionId,
    runId: runId ?? this.runId,
    content: content ?? this.content,
    position: position ?? this.position,
    historyStart: historyStart ?? this.historyStart,
    createdAt: createdAt ?? this.createdAt,
    agentEnabled: agentEnabled ?? this.agentEnabled,
    undoneAt: undoneAt.present ? undoneAt.value : this.undoneAt,
  );
  ChatTurn copyWithCompanion(ChatTurnsCompanion data) {
    return ChatTurn(
      inputId: data.inputId.present ? data.inputId.value : this.inputId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      runId: data.runId.present ? data.runId.value : this.runId,
      content: data.content.present ? data.content.value : this.content,
      position: data.position.present ? data.position.value : this.position,
      historyStart: data.historyStart.present
          ? data.historyStart.value
          : this.historyStart,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      agentEnabled: data.agentEnabled.present
          ? data.agentEnabled.value
          : this.agentEnabled,
      undoneAt: data.undoneAt.present ? data.undoneAt.value : this.undoneAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatTurn(')
          ..write('inputId: $inputId, ')
          ..write('sessionId: $sessionId, ')
          ..write('runId: $runId, ')
          ..write('content: $content, ')
          ..write('position: $position, ')
          ..write('historyStart: $historyStart, ')
          ..write('createdAt: $createdAt, ')
          ..write('agentEnabled: $agentEnabled, ')
          ..write('undoneAt: $undoneAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    inputId,
    sessionId,
    runId,
    content,
    position,
    historyStart,
    createdAt,
    agentEnabled,
    undoneAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatTurn &&
          other.inputId == this.inputId &&
          other.sessionId == this.sessionId &&
          other.runId == this.runId &&
          other.content == this.content &&
          other.position == this.position &&
          other.historyStart == this.historyStart &&
          other.createdAt == this.createdAt &&
          other.agentEnabled == this.agentEnabled &&
          other.undoneAt == this.undoneAt);
}

class ChatTurnsCompanion extends UpdateCompanion<ChatTurn> {
  final Value<String> inputId;
  final Value<String> sessionId;
  final Value<String> runId;
  final Value<String> content;
  final Value<int> position;
  final Value<int> historyStart;
  final Value<int> createdAt;
  final Value<bool> agentEnabled;
  final Value<int?> undoneAt;
  final Value<int> rowid;
  const ChatTurnsCompanion({
    this.inputId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.runId = const Value.absent(),
    this.content = const Value.absent(),
    this.position = const Value.absent(),
    this.historyStart = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.agentEnabled = const Value.absent(),
    this.undoneAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatTurnsCompanion.insert({
    required String inputId,
    required String sessionId,
    required String runId,
    required String content,
    required int position,
    required int historyStart,
    required int createdAt,
    required bool agentEnabled,
    this.undoneAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : inputId = Value(inputId),
       sessionId = Value(sessionId),
       runId = Value(runId),
       content = Value(content),
       position = Value(position),
       historyStart = Value(historyStart),
       createdAt = Value(createdAt),
       agentEnabled = Value(agentEnabled);
  static Insertable<ChatTurn> custom({
    Expression<String>? inputId,
    Expression<String>? sessionId,
    Expression<String>? runId,
    Expression<String>? content,
    Expression<int>? position,
    Expression<int>? historyStart,
    Expression<int>? createdAt,
    Expression<bool>? agentEnabled,
    Expression<int>? undoneAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (inputId != null) 'input_id': inputId,
      if (sessionId != null) 'session_id': sessionId,
      if (runId != null) 'run_id': runId,
      if (content != null) 'content': content,
      if (position != null) 'position': position,
      if (historyStart != null) 'history_start': historyStart,
      if (createdAt != null) 'created_at': createdAt,
      if (agentEnabled != null) 'agent_enabled': agentEnabled,
      if (undoneAt != null) 'undone_at': undoneAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatTurnsCompanion copyWith({
    Value<String>? inputId,
    Value<String>? sessionId,
    Value<String>? runId,
    Value<String>? content,
    Value<int>? position,
    Value<int>? historyStart,
    Value<int>? createdAt,
    Value<bool>? agentEnabled,
    Value<int?>? undoneAt,
    Value<int>? rowid,
  }) {
    return ChatTurnsCompanion(
      inputId: inputId ?? this.inputId,
      sessionId: sessionId ?? this.sessionId,
      runId: runId ?? this.runId,
      content: content ?? this.content,
      position: position ?? this.position,
      historyStart: historyStart ?? this.historyStart,
      createdAt: createdAt ?? this.createdAt,
      agentEnabled: agentEnabled ?? this.agentEnabled,
      undoneAt: undoneAt ?? this.undoneAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (inputId.present) {
      map['input_id'] = Variable<String>(inputId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (historyStart.present) {
      map['history_start'] = Variable<int>(historyStart.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (agentEnabled.present) {
      map['agent_enabled'] = Variable<bool>(agentEnabled.value);
    }
    if (undoneAt.present) {
      map['undone_at'] = Variable<int>(undoneAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatTurnsCompanion(')
          ..write('inputId: $inputId, ')
          ..write('sessionId: $sessionId, ')
          ..write('runId: $runId, ')
          ..write('content: $content, ')
          ..write('position: $position, ')
          ..write('historyStart: $historyStart, ')
          ..write('createdAt: $createdAt, ')
          ..write('agentEnabled: $agentEnabled, ')
          ..write('undoneAt: $undoneAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalJobRowsTable extends LocalJobRows
    with TableInfo<$LocalJobRowsTable, LocalJobRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalJobRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uniqueKeyMeta = const VerificationMeta(
    'uniqueKey',
  );
  @override
  late final GeneratedColumn<String> uniqueKey = GeneratedColumn<String>(
    'unique_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _digestMeta = const VerificationMeta('digest');
  @override
  late final GeneratedColumn<String> digest = GeneratedColumn<String>(
    'digest',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<int> dueAt = GeneratedColumn<int>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<int> nextAttemptAt = GeneratedColumn<int>(
    'next_attempt_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxAttemptsMeta = const VerificationMeta(
    'maxAttempts',
  );
  @override
  late final GeneratedColumn<int> maxAttempts = GeneratedColumn<int>(
    'max_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _leaseEpochMeta = const VerificationMeta(
    'leaseEpoch',
  );
  @override
  late final GeneratedColumn<int> leaseEpoch = GeneratedColumn<int>(
    'lease_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _leaseOwnerMeta = const VerificationMeta(
    'leaseOwner',
  );
  @override
  late final GeneratedColumn<String> leaseOwner = GeneratedColumn<String>(
    'lease_owner',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leaseExpiresAtMeta = const VerificationMeta(
    'leaseExpiresAt',
  );
  @override
  late final GeneratedColumn<int> leaseExpiresAt = GeneratedColumn<int>(
    'lease_expires_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leaseStartedAtMeta = const VerificationMeta(
    'leaseStartedAt',
  );
  @override
  late final GeneratedColumn<int> leaseStartedAt = GeneratedColumn<int>(
    'lease_started_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uniqueKey,
    type,
    payload,
    digest,
    status,
    dueAt,
    nextAttemptAt,
    attempts,
    maxAttempts,
    leaseEpoch,
    leaseOwner,
    leaseExpiresAt,
    leaseStartedAt,
    outcome,
    errorCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_job_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalJobRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('unique_key')) {
      context.handle(
        _uniqueKeyMeta,
        uniqueKey.isAcceptableOrUnknown(data['unique_key']!, _uniqueKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_uniqueKeyMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('digest')) {
      context.handle(
        _digestMeta,
        digest.isAcceptableOrUnknown(data['digest']!, _digestMeta),
      );
    } else if (isInserting) {
      context.missing(_digestMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextAttemptAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    } else if (isInserting) {
      context.missing(_attemptsMeta);
    }
    if (data.containsKey('max_attempts')) {
      context.handle(
        _maxAttemptsMeta,
        maxAttempts.isAcceptableOrUnknown(
          data['max_attempts']!,
          _maxAttemptsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_maxAttemptsMeta);
    }
    if (data.containsKey('lease_epoch')) {
      context.handle(
        _leaseEpochMeta,
        leaseEpoch.isAcceptableOrUnknown(data['lease_epoch']!, _leaseEpochMeta),
      );
    } else if (isInserting) {
      context.missing(_leaseEpochMeta);
    }
    if (data.containsKey('lease_owner')) {
      context.handle(
        _leaseOwnerMeta,
        leaseOwner.isAcceptableOrUnknown(data['lease_owner']!, _leaseOwnerMeta),
      );
    }
    if (data.containsKey('lease_expires_at')) {
      context.handle(
        _leaseExpiresAtMeta,
        leaseExpiresAt.isAcceptableOrUnknown(
          data['lease_expires_at']!,
          _leaseExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('lease_started_at')) {
      context.handle(
        _leaseStartedAtMeta,
        leaseStartedAt.isAcceptableOrUnknown(
          data['lease_started_at']!,
          _leaseStartedAtMeta,
        ),
      );
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalJobRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalJobRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      uniqueKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unique_key'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      digest: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}digest'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_at'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_attempt_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      maxAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_attempts'],
      )!,
      leaseEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lease_epoch'],
      )!,
      leaseOwner: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lease_owner'],
      ),
      leaseExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lease_expires_at'],
      ),
      leaseStartedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lease_started_at'],
      ),
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      ),
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
    );
  }

  @override
  $LocalJobRowsTable createAlias(String alias) {
    return $LocalJobRowsTable(attachedDatabase, alias);
  }
}

class LocalJobRow extends DataClass implements Insertable<LocalJobRow> {
  final String id;
  final String uniqueKey;
  final String type;
  final String payload;
  final String digest;
  final String status;
  final int dueAt;
  final int nextAttemptAt;
  final int attempts;
  final int maxAttempts;
  final int leaseEpoch;
  final String? leaseOwner;
  final int? leaseExpiresAt;
  final int? leaseStartedAt;
  final String? outcome;
  final String? errorCode;
  const LocalJobRow({
    required this.id,
    required this.uniqueKey,
    required this.type,
    required this.payload,
    required this.digest,
    required this.status,
    required this.dueAt,
    required this.nextAttemptAt,
    required this.attempts,
    required this.maxAttempts,
    required this.leaseEpoch,
    this.leaseOwner,
    this.leaseExpiresAt,
    this.leaseStartedAt,
    this.outcome,
    this.errorCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['unique_key'] = Variable<String>(uniqueKey);
    map['type'] = Variable<String>(type);
    map['payload'] = Variable<String>(payload);
    map['digest'] = Variable<String>(digest);
    map['status'] = Variable<String>(status);
    map['due_at'] = Variable<int>(dueAt);
    map['next_attempt_at'] = Variable<int>(nextAttemptAt);
    map['attempts'] = Variable<int>(attempts);
    map['max_attempts'] = Variable<int>(maxAttempts);
    map['lease_epoch'] = Variable<int>(leaseEpoch);
    if (!nullToAbsent || leaseOwner != null) {
      map['lease_owner'] = Variable<String>(leaseOwner);
    }
    if (!nullToAbsent || leaseExpiresAt != null) {
      map['lease_expires_at'] = Variable<int>(leaseExpiresAt);
    }
    if (!nullToAbsent || leaseStartedAt != null) {
      map['lease_started_at'] = Variable<int>(leaseStartedAt);
    }
    if (!nullToAbsent || outcome != null) {
      map['outcome'] = Variable<String>(outcome);
    }
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    return map;
  }

  LocalJobRowsCompanion toCompanion(bool nullToAbsent) {
    return LocalJobRowsCompanion(
      id: Value(id),
      uniqueKey: Value(uniqueKey),
      type: Value(type),
      payload: Value(payload),
      digest: Value(digest),
      status: Value(status),
      dueAt: Value(dueAt),
      nextAttemptAt: Value(nextAttemptAt),
      attempts: Value(attempts),
      maxAttempts: Value(maxAttempts),
      leaseEpoch: Value(leaseEpoch),
      leaseOwner: leaseOwner == null && nullToAbsent
          ? const Value.absent()
          : Value(leaseOwner),
      leaseExpiresAt: leaseExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(leaseExpiresAt),
      leaseStartedAt: leaseStartedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(leaseStartedAt),
      outcome: outcome == null && nullToAbsent
          ? const Value.absent()
          : Value(outcome),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
    );
  }

  factory LocalJobRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalJobRow(
      id: serializer.fromJson<String>(json['id']),
      uniqueKey: serializer.fromJson<String>(json['uniqueKey']),
      type: serializer.fromJson<String>(json['type']),
      payload: serializer.fromJson<String>(json['payload']),
      digest: serializer.fromJson<String>(json['digest']),
      status: serializer.fromJson<String>(json['status']),
      dueAt: serializer.fromJson<int>(json['dueAt']),
      nextAttemptAt: serializer.fromJson<int>(json['nextAttemptAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      maxAttempts: serializer.fromJson<int>(json['maxAttempts']),
      leaseEpoch: serializer.fromJson<int>(json['leaseEpoch']),
      leaseOwner: serializer.fromJson<String?>(json['leaseOwner']),
      leaseExpiresAt: serializer.fromJson<int?>(json['leaseExpiresAt']),
      leaseStartedAt: serializer.fromJson<int?>(json['leaseStartedAt']),
      outcome: serializer.fromJson<String?>(json['outcome']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'uniqueKey': serializer.toJson<String>(uniqueKey),
      'type': serializer.toJson<String>(type),
      'payload': serializer.toJson<String>(payload),
      'digest': serializer.toJson<String>(digest),
      'status': serializer.toJson<String>(status),
      'dueAt': serializer.toJson<int>(dueAt),
      'nextAttemptAt': serializer.toJson<int>(nextAttemptAt),
      'attempts': serializer.toJson<int>(attempts),
      'maxAttempts': serializer.toJson<int>(maxAttempts),
      'leaseEpoch': serializer.toJson<int>(leaseEpoch),
      'leaseOwner': serializer.toJson<String?>(leaseOwner),
      'leaseExpiresAt': serializer.toJson<int?>(leaseExpiresAt),
      'leaseStartedAt': serializer.toJson<int?>(leaseStartedAt),
      'outcome': serializer.toJson<String?>(outcome),
      'errorCode': serializer.toJson<String?>(errorCode),
    };
  }

  LocalJobRow copyWith({
    String? id,
    String? uniqueKey,
    String? type,
    String? payload,
    String? digest,
    String? status,
    int? dueAt,
    int? nextAttemptAt,
    int? attempts,
    int? maxAttempts,
    int? leaseEpoch,
    Value<String?> leaseOwner = const Value.absent(),
    Value<int?> leaseExpiresAt = const Value.absent(),
    Value<int?> leaseStartedAt = const Value.absent(),
    Value<String?> outcome = const Value.absent(),
    Value<String?> errorCode = const Value.absent(),
  }) => LocalJobRow(
    id: id ?? this.id,
    uniqueKey: uniqueKey ?? this.uniqueKey,
    type: type ?? this.type,
    payload: payload ?? this.payload,
    digest: digest ?? this.digest,
    status: status ?? this.status,
    dueAt: dueAt ?? this.dueAt,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    attempts: attempts ?? this.attempts,
    maxAttempts: maxAttempts ?? this.maxAttempts,
    leaseEpoch: leaseEpoch ?? this.leaseEpoch,
    leaseOwner: leaseOwner.present ? leaseOwner.value : this.leaseOwner,
    leaseExpiresAt: leaseExpiresAt.present
        ? leaseExpiresAt.value
        : this.leaseExpiresAt,
    leaseStartedAt: leaseStartedAt.present
        ? leaseStartedAt.value
        : this.leaseStartedAt,
    outcome: outcome.present ? outcome.value : this.outcome,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
  );
  LocalJobRow copyWithCompanion(LocalJobRowsCompanion data) {
    return LocalJobRow(
      id: data.id.present ? data.id.value : this.id,
      uniqueKey: data.uniqueKey.present ? data.uniqueKey.value : this.uniqueKey,
      type: data.type.present ? data.type.value : this.type,
      payload: data.payload.present ? data.payload.value : this.payload,
      digest: data.digest.present ? data.digest.value : this.digest,
      status: data.status.present ? data.status.value : this.status,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      maxAttempts: data.maxAttempts.present
          ? data.maxAttempts.value
          : this.maxAttempts,
      leaseEpoch: data.leaseEpoch.present
          ? data.leaseEpoch.value
          : this.leaseEpoch,
      leaseOwner: data.leaseOwner.present
          ? data.leaseOwner.value
          : this.leaseOwner,
      leaseExpiresAt: data.leaseExpiresAt.present
          ? data.leaseExpiresAt.value
          : this.leaseExpiresAt,
      leaseStartedAt: data.leaseStartedAt.present
          ? data.leaseStartedAt.value
          : this.leaseStartedAt,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalJobRow(')
          ..write('id: $id, ')
          ..write('uniqueKey: $uniqueKey, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('digest: $digest, ')
          ..write('status: $status, ')
          ..write('dueAt: $dueAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('attempts: $attempts, ')
          ..write('maxAttempts: $maxAttempts, ')
          ..write('leaseEpoch: $leaseEpoch, ')
          ..write('leaseOwner: $leaseOwner, ')
          ..write('leaseExpiresAt: $leaseExpiresAt, ')
          ..write('leaseStartedAt: $leaseStartedAt, ')
          ..write('outcome: $outcome, ')
          ..write('errorCode: $errorCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uniqueKey,
    type,
    payload,
    digest,
    status,
    dueAt,
    nextAttemptAt,
    attempts,
    maxAttempts,
    leaseEpoch,
    leaseOwner,
    leaseExpiresAt,
    leaseStartedAt,
    outcome,
    errorCode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalJobRow &&
          other.id == this.id &&
          other.uniqueKey == this.uniqueKey &&
          other.type == this.type &&
          other.payload == this.payload &&
          other.digest == this.digest &&
          other.status == this.status &&
          other.dueAt == this.dueAt &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.attempts == this.attempts &&
          other.maxAttempts == this.maxAttempts &&
          other.leaseEpoch == this.leaseEpoch &&
          other.leaseOwner == this.leaseOwner &&
          other.leaseExpiresAt == this.leaseExpiresAt &&
          other.leaseStartedAt == this.leaseStartedAt &&
          other.outcome == this.outcome &&
          other.errorCode == this.errorCode);
}

class LocalJobRowsCompanion extends UpdateCompanion<LocalJobRow> {
  final Value<String> id;
  final Value<String> uniqueKey;
  final Value<String> type;
  final Value<String> payload;
  final Value<String> digest;
  final Value<String> status;
  final Value<int> dueAt;
  final Value<int> nextAttemptAt;
  final Value<int> attempts;
  final Value<int> maxAttempts;
  final Value<int> leaseEpoch;
  final Value<String?> leaseOwner;
  final Value<int?> leaseExpiresAt;
  final Value<int?> leaseStartedAt;
  final Value<String?> outcome;
  final Value<String?> errorCode;
  final Value<int> rowid;
  const LocalJobRowsCompanion({
    this.id = const Value.absent(),
    this.uniqueKey = const Value.absent(),
    this.type = const Value.absent(),
    this.payload = const Value.absent(),
    this.digest = const Value.absent(),
    this.status = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.maxAttempts = const Value.absent(),
    this.leaseEpoch = const Value.absent(),
    this.leaseOwner = const Value.absent(),
    this.leaseExpiresAt = const Value.absent(),
    this.leaseStartedAt = const Value.absent(),
    this.outcome = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalJobRowsCompanion.insert({
    required String id,
    required String uniqueKey,
    required String type,
    required String payload,
    required String digest,
    required String status,
    required int dueAt,
    required int nextAttemptAt,
    required int attempts,
    required int maxAttempts,
    required int leaseEpoch,
    this.leaseOwner = const Value.absent(),
    this.leaseExpiresAt = const Value.absent(),
    this.leaseStartedAt = const Value.absent(),
    this.outcome = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       uniqueKey = Value(uniqueKey),
       type = Value(type),
       payload = Value(payload),
       digest = Value(digest),
       status = Value(status),
       dueAt = Value(dueAt),
       nextAttemptAt = Value(nextAttemptAt),
       attempts = Value(attempts),
       maxAttempts = Value(maxAttempts),
       leaseEpoch = Value(leaseEpoch);
  static Insertable<LocalJobRow> custom({
    Expression<String>? id,
    Expression<String>? uniqueKey,
    Expression<String>? type,
    Expression<String>? payload,
    Expression<String>? digest,
    Expression<String>? status,
    Expression<int>? dueAt,
    Expression<int>? nextAttemptAt,
    Expression<int>? attempts,
    Expression<int>? maxAttempts,
    Expression<int>? leaseEpoch,
    Expression<String>? leaseOwner,
    Expression<int>? leaseExpiresAt,
    Expression<int>? leaseStartedAt,
    Expression<String>? outcome,
    Expression<String>? errorCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uniqueKey != null) 'unique_key': uniqueKey,
      if (type != null) 'type': type,
      if (payload != null) 'payload': payload,
      if (digest != null) 'digest': digest,
      if (status != null) 'status': status,
      if (dueAt != null) 'due_at': dueAt,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (attempts != null) 'attempts': attempts,
      if (maxAttempts != null) 'max_attempts': maxAttempts,
      if (leaseEpoch != null) 'lease_epoch': leaseEpoch,
      if (leaseOwner != null) 'lease_owner': leaseOwner,
      if (leaseExpiresAt != null) 'lease_expires_at': leaseExpiresAt,
      if (leaseStartedAt != null) 'lease_started_at': leaseStartedAt,
      if (outcome != null) 'outcome': outcome,
      if (errorCode != null) 'error_code': errorCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalJobRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? uniqueKey,
    Value<String>? type,
    Value<String>? payload,
    Value<String>? digest,
    Value<String>? status,
    Value<int>? dueAt,
    Value<int>? nextAttemptAt,
    Value<int>? attempts,
    Value<int>? maxAttempts,
    Value<int>? leaseEpoch,
    Value<String?>? leaseOwner,
    Value<int?>? leaseExpiresAt,
    Value<int?>? leaseStartedAt,
    Value<String?>? outcome,
    Value<String?>? errorCode,
    Value<int>? rowid,
  }) {
    return LocalJobRowsCompanion(
      id: id ?? this.id,
      uniqueKey: uniqueKey ?? this.uniqueKey,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      digest: digest ?? this.digest,
      status: status ?? this.status,
      dueAt: dueAt ?? this.dueAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      attempts: attempts ?? this.attempts,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      leaseEpoch: leaseEpoch ?? this.leaseEpoch,
      leaseOwner: leaseOwner ?? this.leaseOwner,
      leaseExpiresAt: leaseExpiresAt ?? this.leaseExpiresAt,
      leaseStartedAt: leaseStartedAt ?? this.leaseStartedAt,
      outcome: outcome ?? this.outcome,
      errorCode: errorCode ?? this.errorCode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (uniqueKey.present) {
      map['unique_key'] = Variable<String>(uniqueKey.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (digest.present) {
      map['digest'] = Variable<String>(digest.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<int>(dueAt.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (maxAttempts.present) {
      map['max_attempts'] = Variable<int>(maxAttempts.value);
    }
    if (leaseEpoch.present) {
      map['lease_epoch'] = Variable<int>(leaseEpoch.value);
    }
    if (leaseOwner.present) {
      map['lease_owner'] = Variable<String>(leaseOwner.value);
    }
    if (leaseExpiresAt.present) {
      map['lease_expires_at'] = Variable<int>(leaseExpiresAt.value);
    }
    if (leaseStartedAt.present) {
      map['lease_started_at'] = Variable<int>(leaseStartedAt.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalJobRowsCompanion(')
          ..write('id: $id, ')
          ..write('uniqueKey: $uniqueKey, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('digest: $digest, ')
          ..write('status: $status, ')
          ..write('dueAt: $dueAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('attempts: $attempts, ')
          ..write('maxAttempts: $maxAttempts, ')
          ..write('leaseEpoch: $leaseEpoch, ')
          ..write('leaseOwner: $leaseOwner, ')
          ..write('leaseExpiresAt: $leaseExpiresAt, ')
          ..write('leaseStartedAt: $leaseStartedAt, ')
          ..write('outcome: $outcome, ')
          ..write('errorCode: $errorCode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationAttemptsTable extends NotificationAttempts
    with TableInfo<$NotificationAttemptsTable, NotificationAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _leaseEpochMeta = const VerificationMeta(
    'leaseEpoch',
  );
  @override
  late final GeneratedColumn<int> leaseEpoch = GeneratedColumn<int>(
    'lease_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cancelledMeta = const VerificationMeta(
    'cancelled',
  );
  @override
  late final GeneratedColumn<bool> cancelled = GeneratedColumn<bool>(
    'cancelled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cancelled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    jobId,
    leaseEpoch,
    payload,
    cancelled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationAttempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('lease_epoch')) {
      context.handle(
        _leaseEpochMeta,
        leaseEpoch.isAcceptableOrUnknown(data['lease_epoch']!, _leaseEpochMeta),
      );
    } else if (isInserting) {
      context.missing(_leaseEpochMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('cancelled')) {
      context.handle(
        _cancelledMeta,
        cancelled.isAcceptableOrUnknown(data['cancelled']!, _cancelledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {jobId, leaseEpoch},
  ];
  @override
  NotificationAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationAttempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      )!,
      leaseEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lease_epoch'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      cancelled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cancelled'],
      )!,
    );
  }

  @override
  $NotificationAttemptsTable createAlias(String alias) {
    return $NotificationAttemptsTable(attachedDatabase, alias);
  }
}

class NotificationAttempt extends DataClass
    implements Insertable<NotificationAttempt> {
  final int id;
  final String jobId;
  final int leaseEpoch;
  final String payload;
  final bool cancelled;
  const NotificationAttempt({
    required this.id,
    required this.jobId,
    required this.leaseEpoch,
    required this.payload,
    required this.cancelled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['job_id'] = Variable<String>(jobId);
    map['lease_epoch'] = Variable<int>(leaseEpoch);
    map['payload'] = Variable<String>(payload);
    map['cancelled'] = Variable<bool>(cancelled);
    return map;
  }

  NotificationAttemptsCompanion toCompanion(bool nullToAbsent) {
    return NotificationAttemptsCompanion(
      id: Value(id),
      jobId: Value(jobId),
      leaseEpoch: Value(leaseEpoch),
      payload: Value(payload),
      cancelled: Value(cancelled),
    );
  }

  factory NotificationAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationAttempt(
      id: serializer.fromJson<int>(json['id']),
      jobId: serializer.fromJson<String>(json['jobId']),
      leaseEpoch: serializer.fromJson<int>(json['leaseEpoch']),
      payload: serializer.fromJson<String>(json['payload']),
      cancelled: serializer.fromJson<bool>(json['cancelled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'jobId': serializer.toJson<String>(jobId),
      'leaseEpoch': serializer.toJson<int>(leaseEpoch),
      'payload': serializer.toJson<String>(payload),
      'cancelled': serializer.toJson<bool>(cancelled),
    };
  }

  NotificationAttempt copyWith({
    int? id,
    String? jobId,
    int? leaseEpoch,
    String? payload,
    bool? cancelled,
  }) => NotificationAttempt(
    id: id ?? this.id,
    jobId: jobId ?? this.jobId,
    leaseEpoch: leaseEpoch ?? this.leaseEpoch,
    payload: payload ?? this.payload,
    cancelled: cancelled ?? this.cancelled,
  );
  NotificationAttempt copyWithCompanion(NotificationAttemptsCompanion data) {
    return NotificationAttempt(
      id: data.id.present ? data.id.value : this.id,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      leaseEpoch: data.leaseEpoch.present
          ? data.leaseEpoch.value
          : this.leaseEpoch,
      payload: data.payload.present ? data.payload.value : this.payload,
      cancelled: data.cancelled.present ? data.cancelled.value : this.cancelled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationAttempt(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('leaseEpoch: $leaseEpoch, ')
          ..write('payload: $payload, ')
          ..write('cancelled: $cancelled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, jobId, leaseEpoch, payload, cancelled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationAttempt &&
          other.id == this.id &&
          other.jobId == this.jobId &&
          other.leaseEpoch == this.leaseEpoch &&
          other.payload == this.payload &&
          other.cancelled == this.cancelled);
}

class NotificationAttemptsCompanion
    extends UpdateCompanion<NotificationAttempt> {
  final Value<int> id;
  final Value<String> jobId;
  final Value<int> leaseEpoch;
  final Value<String> payload;
  final Value<bool> cancelled;
  const NotificationAttemptsCompanion({
    this.id = const Value.absent(),
    this.jobId = const Value.absent(),
    this.leaseEpoch = const Value.absent(),
    this.payload = const Value.absent(),
    this.cancelled = const Value.absent(),
  });
  NotificationAttemptsCompanion.insert({
    this.id = const Value.absent(),
    required String jobId,
    required int leaseEpoch,
    required String payload,
    this.cancelled = const Value.absent(),
  }) : jobId = Value(jobId),
       leaseEpoch = Value(leaseEpoch),
       payload = Value(payload);
  static Insertable<NotificationAttempt> custom({
    Expression<int>? id,
    Expression<String>? jobId,
    Expression<int>? leaseEpoch,
    Expression<String>? payload,
    Expression<bool>? cancelled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobId != null) 'job_id': jobId,
      if (leaseEpoch != null) 'lease_epoch': leaseEpoch,
      if (payload != null) 'payload': payload,
      if (cancelled != null) 'cancelled': cancelled,
    });
  }

  NotificationAttemptsCompanion copyWith({
    Value<int>? id,
    Value<String>? jobId,
    Value<int>? leaseEpoch,
    Value<String>? payload,
    Value<bool>? cancelled,
  }) {
    return NotificationAttemptsCompanion(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      leaseEpoch: leaseEpoch ?? this.leaseEpoch,
      payload: payload ?? this.payload,
      cancelled: cancelled ?? this.cancelled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (leaseEpoch.present) {
      map['lease_epoch'] = Variable<int>(leaseEpoch.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (cancelled.present) {
      map['cancelled'] = Variable<bool>(cancelled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('leaseEpoch: $leaseEpoch, ')
          ..write('payload: $payload, ')
          ..write('cancelled: $cancelled')
          ..write(')'))
        .toString();
  }
}

class $LocalAttachmentsTable extends LocalAttachments
    with TableInfo<$LocalAttachmentsTable, LocalAttachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputIdMeta = const VerificationMeta(
    'inputId',
  );
  @override
  late final GeneratedColumn<String> inputId = GeneratedColumn<String>(
    'input_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _tableIdMeta = const VerificationMeta(
    'tableId',
  );
  @override
  late final GeneratedColumn<String> tableId = GeneratedColumn<String>(
    'table_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeMeta = const VerificationMeta('mime');
  @override
  late final GeneratedColumn<String> mime = GeneratedColumn<String>(
    'mime',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalHashMeta = const VerificationMeta(
    'originalHash',
  );
  @override
  late final GeneratedColumn<String> originalHash = GeneratedColumn<String>(
    'original_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalSizeMeta = const VerificationMeta(
    'originalSize',
  );
  @override
  late final GeneratedColumn<int> originalSize = GeneratedColumn<int>(
    'original_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelHashMeta = const VerificationMeta(
    'modelHash',
  );
  @override
  late final GeneratedColumn<String> modelHash = GeneratedColumn<String>(
    'model_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelSizeMeta = const VerificationMeta(
    'modelSize',
  );
  @override
  late final GeneratedColumn<int> modelSize = GeneratedColumn<int>(
    'model_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inputId,
    tableId,
    displayName,
    mime,
    originalHash,
    originalSize,
    modelHash,
    modelSize,
    width,
    height,
    state,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAttachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('input_id')) {
      context.handle(
        _inputIdMeta,
        inputId.isAcceptableOrUnknown(data['input_id']!, _inputIdMeta),
      );
    } else if (isInserting) {
      context.missing(_inputIdMeta);
    }
    if (data.containsKey('table_id')) {
      context.handle(
        _tableIdMeta,
        tableId.isAcceptableOrUnknown(data['table_id']!, _tableIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tableIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('mime')) {
      context.handle(
        _mimeMeta,
        mime.isAcceptableOrUnknown(data['mime']!, _mimeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeMeta);
    }
    if (data.containsKey('original_hash')) {
      context.handle(
        _originalHashMeta,
        originalHash.isAcceptableOrUnknown(
          data['original_hash']!,
          _originalHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalHashMeta);
    }
    if (data.containsKey('original_size')) {
      context.handle(
        _originalSizeMeta,
        originalSize.isAcceptableOrUnknown(
          data['original_size']!,
          _originalSizeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalSizeMeta);
    }
    if (data.containsKey('model_hash')) {
      context.handle(
        _modelHashMeta,
        modelHash.isAcceptableOrUnknown(data['model_hash']!, _modelHashMeta),
      );
    } else if (isInserting) {
      context.missing(_modelHashMeta);
    }
    if (data.containsKey('model_size')) {
      context.handle(
        _modelSizeMeta,
        modelSize.isAcceptableOrUnknown(data['model_size']!, _modelSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_modelSizeMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAttachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAttachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      inputId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_id'],
      )!,
      tableId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      mime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime'],
      )!,
      originalHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_hash'],
      )!,
      originalSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_size'],
      )!,
      modelHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_hash'],
      )!,
      modelSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}model_size'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalAttachmentsTable createAlias(String alias) {
    return $LocalAttachmentsTable(attachedDatabase, alias);
  }
}

class LocalAttachment extends DataClass implements Insertable<LocalAttachment> {
  final String id;
  final String inputId;
  final String tableId;
  final String displayName;
  final String mime;
  final String originalHash;
  final int originalSize;
  final String modelHash;
  final int modelSize;
  final int width;
  final int height;
  final String state;
  final int createdAt;
  const LocalAttachment({
    required this.id,
    required this.inputId,
    required this.tableId,
    required this.displayName,
    required this.mime,
    required this.originalHash,
    required this.originalSize,
    required this.modelHash,
    required this.modelSize,
    required this.width,
    required this.height,
    required this.state,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['input_id'] = Variable<String>(inputId);
    map['table_id'] = Variable<String>(tableId);
    map['display_name'] = Variable<String>(displayName);
    map['mime'] = Variable<String>(mime);
    map['original_hash'] = Variable<String>(originalHash);
    map['original_size'] = Variable<int>(originalSize);
    map['model_hash'] = Variable<String>(modelHash);
    map['model_size'] = Variable<int>(modelSize);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    map['state'] = Variable<String>(state);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  LocalAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return LocalAttachmentsCompanion(
      id: Value(id),
      inputId: Value(inputId),
      tableId: Value(tableId),
      displayName: Value(displayName),
      mime: Value(mime),
      originalHash: Value(originalHash),
      originalSize: Value(originalSize),
      modelHash: Value(modelHash),
      modelSize: Value(modelSize),
      width: Value(width),
      height: Value(height),
      state: Value(state),
      createdAt: Value(createdAt),
    );
  }

  factory LocalAttachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAttachment(
      id: serializer.fromJson<String>(json['id']),
      inputId: serializer.fromJson<String>(json['inputId']),
      tableId: serializer.fromJson<String>(json['tableId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      mime: serializer.fromJson<String>(json['mime']),
      originalHash: serializer.fromJson<String>(json['originalHash']),
      originalSize: serializer.fromJson<int>(json['originalSize']),
      modelHash: serializer.fromJson<String>(json['modelHash']),
      modelSize: serializer.fromJson<int>(json['modelSize']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      state: serializer.fromJson<String>(json['state']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'inputId': serializer.toJson<String>(inputId),
      'tableId': serializer.toJson<String>(tableId),
      'displayName': serializer.toJson<String>(displayName),
      'mime': serializer.toJson<String>(mime),
      'originalHash': serializer.toJson<String>(originalHash),
      'originalSize': serializer.toJson<int>(originalSize),
      'modelHash': serializer.toJson<String>(modelHash),
      'modelSize': serializer.toJson<int>(modelSize),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'state': serializer.toJson<String>(state),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  LocalAttachment copyWith({
    String? id,
    String? inputId,
    String? tableId,
    String? displayName,
    String? mime,
    String? originalHash,
    int? originalSize,
    String? modelHash,
    int? modelSize,
    int? width,
    int? height,
    String? state,
    int? createdAt,
  }) => LocalAttachment(
    id: id ?? this.id,
    inputId: inputId ?? this.inputId,
    tableId: tableId ?? this.tableId,
    displayName: displayName ?? this.displayName,
    mime: mime ?? this.mime,
    originalHash: originalHash ?? this.originalHash,
    originalSize: originalSize ?? this.originalSize,
    modelHash: modelHash ?? this.modelHash,
    modelSize: modelSize ?? this.modelSize,
    width: width ?? this.width,
    height: height ?? this.height,
    state: state ?? this.state,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalAttachment copyWithCompanion(LocalAttachmentsCompanion data) {
    return LocalAttachment(
      id: data.id.present ? data.id.value : this.id,
      inputId: data.inputId.present ? data.inputId.value : this.inputId,
      tableId: data.tableId.present ? data.tableId.value : this.tableId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      mime: data.mime.present ? data.mime.value : this.mime,
      originalHash: data.originalHash.present
          ? data.originalHash.value
          : this.originalHash,
      originalSize: data.originalSize.present
          ? data.originalSize.value
          : this.originalSize,
      modelHash: data.modelHash.present ? data.modelHash.value : this.modelHash,
      modelSize: data.modelSize.present ? data.modelSize.value : this.modelSize,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      state: data.state.present ? data.state.value : this.state,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAttachment(')
          ..write('id: $id, ')
          ..write('inputId: $inputId, ')
          ..write('tableId: $tableId, ')
          ..write('displayName: $displayName, ')
          ..write('mime: $mime, ')
          ..write('originalHash: $originalHash, ')
          ..write('originalSize: $originalSize, ')
          ..write('modelHash: $modelHash, ')
          ..write('modelSize: $modelSize, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('state: $state, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    inputId,
    tableId,
    displayName,
    mime,
    originalHash,
    originalSize,
    modelHash,
    modelSize,
    width,
    height,
    state,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAttachment &&
          other.id == this.id &&
          other.inputId == this.inputId &&
          other.tableId == this.tableId &&
          other.displayName == this.displayName &&
          other.mime == this.mime &&
          other.originalHash == this.originalHash &&
          other.originalSize == this.originalSize &&
          other.modelHash == this.modelHash &&
          other.modelSize == this.modelSize &&
          other.width == this.width &&
          other.height == this.height &&
          other.state == this.state &&
          other.createdAt == this.createdAt);
}

class LocalAttachmentsCompanion extends UpdateCompanion<LocalAttachment> {
  final Value<String> id;
  final Value<String> inputId;
  final Value<String> tableId;
  final Value<String> displayName;
  final Value<String> mime;
  final Value<String> originalHash;
  final Value<int> originalSize;
  final Value<String> modelHash;
  final Value<int> modelSize;
  final Value<int> width;
  final Value<int> height;
  final Value<String> state;
  final Value<int> createdAt;
  final Value<int> rowid;
  const LocalAttachmentsCompanion({
    this.id = const Value.absent(),
    this.inputId = const Value.absent(),
    this.tableId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.mime = const Value.absent(),
    this.originalHash = const Value.absent(),
    this.originalSize = const Value.absent(),
    this.modelHash = const Value.absent(),
    this.modelSize = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.state = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalAttachmentsCompanion.insert({
    required String id,
    required String inputId,
    required String tableId,
    required String displayName,
    required String mime,
    required String originalHash,
    required int originalSize,
    required String modelHash,
    required int modelSize,
    required int width,
    required int height,
    required String state,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       inputId = Value(inputId),
       tableId = Value(tableId),
       displayName = Value(displayName),
       mime = Value(mime),
       originalHash = Value(originalHash),
       originalSize = Value(originalSize),
       modelHash = Value(modelHash),
       modelSize = Value(modelSize),
       width = Value(width),
       height = Value(height),
       state = Value(state),
       createdAt = Value(createdAt);
  static Insertable<LocalAttachment> custom({
    Expression<String>? id,
    Expression<String>? inputId,
    Expression<String>? tableId,
    Expression<String>? displayName,
    Expression<String>? mime,
    Expression<String>? originalHash,
    Expression<int>? originalSize,
    Expression<String>? modelHash,
    Expression<int>? modelSize,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? state,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inputId != null) 'input_id': inputId,
      if (tableId != null) 'table_id': tableId,
      if (displayName != null) 'display_name': displayName,
      if (mime != null) 'mime': mime,
      if (originalHash != null) 'original_hash': originalHash,
      if (originalSize != null) 'original_size': originalSize,
      if (modelHash != null) 'model_hash': modelHash,
      if (modelSize != null) 'model_size': modelSize,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (state != null) 'state': state,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalAttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? inputId,
    Value<String>? tableId,
    Value<String>? displayName,
    Value<String>? mime,
    Value<String>? originalHash,
    Value<int>? originalSize,
    Value<String>? modelHash,
    Value<int>? modelSize,
    Value<int>? width,
    Value<int>? height,
    Value<String>? state,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalAttachmentsCompanion(
      id: id ?? this.id,
      inputId: inputId ?? this.inputId,
      tableId: tableId ?? this.tableId,
      displayName: displayName ?? this.displayName,
      mime: mime ?? this.mime,
      originalHash: originalHash ?? this.originalHash,
      originalSize: originalSize ?? this.originalSize,
      modelHash: modelHash ?? this.modelHash,
      modelSize: modelSize ?? this.modelSize,
      width: width ?? this.width,
      height: height ?? this.height,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (inputId.present) {
      map['input_id'] = Variable<String>(inputId.value);
    }
    if (tableId.present) {
      map['table_id'] = Variable<String>(tableId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (mime.present) {
      map['mime'] = Variable<String>(mime.value);
    }
    if (originalHash.present) {
      map['original_hash'] = Variable<String>(originalHash.value);
    }
    if (originalSize.present) {
      map['original_size'] = Variable<int>(originalSize.value);
    }
    if (modelHash.present) {
      map['model_hash'] = Variable<String>(modelHash.value);
    }
    if (modelSize.present) {
      map['model_size'] = Variable<int>(modelSize.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('inputId: $inputId, ')
          ..write('tableId: $tableId, ')
          ..write('displayName: $displayName, ')
          ..write('mime: $mime, ')
          ..write('originalHash: $originalHash, ')
          ..write('originalSize: $originalSize, ')
          ..write('modelHash: $modelHash, ')
          ..write('modelSize: $modelSize, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('state: $state, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMemoriesTable extends LocalMemories
    with TableInfo<$LocalMemoriesTable, LocalMemory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMemoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _epochMeta = const VerificationMeta('epoch');
  @override
  late final GeneratedColumn<int> epoch = GeneratedColumn<int>(
    'epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindIdMeta = const VerificationMeta('kindId');
  @override
  late final GeneratedColumn<String> kindId = GeneratedColumn<String>(
    'kind_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMessageIdMeta = const VerificationMeta(
    'sourceMessageId',
  );
  @override
  late final GeneratedColumn<String> sourceMessageId = GeneratedColumn<String>(
    'source_message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceSessionIdMeta = const VerificationMeta(
    'sourceSessionId',
  );
  @override
  late final GeneratedColumn<String> sourceSessionId = GeneratedColumn<String>(
    'source_session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceRecordIdMeta = const VerificationMeta(
    'sourceRecordId',
  );
  @override
  late final GeneratedColumn<String> sourceRecordId = GeneratedColumn<String>(
    'source_record_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    epoch,
    kindId,
    content,
    source,
    sourceMessageId,
    sourceSessionId,
    sourceRecordId,
    confidence,
    expiresAt,
    version,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_memories';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMemory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('epoch')) {
      context.handle(
        _epochMeta,
        epoch.isAcceptableOrUnknown(data['epoch']!, _epochMeta),
      );
    } else if (isInserting) {
      context.missing(_epochMeta);
    }
    if (data.containsKey('kind_id')) {
      context.handle(
        _kindIdMeta,
        kindId.isAcceptableOrUnknown(data['kind_id']!, _kindIdMeta),
      );
    } else if (isInserting) {
      context.missing(_kindIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_message_id')) {
      context.handle(
        _sourceMessageIdMeta,
        sourceMessageId.isAcceptableOrUnknown(
          data['source_message_id']!,
          _sourceMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('source_session_id')) {
      context.handle(
        _sourceSessionIdMeta,
        sourceSessionId.isAcceptableOrUnknown(
          data['source_session_id']!,
          _sourceSessionIdMeta,
        ),
      );
    }
    if (data.containsKey('source_record_id')) {
      context.handle(
        _sourceRecordIdMeta,
        sourceRecordId.isAcceptableOrUnknown(
          data['source_record_id']!,
          _sourceRecordIdMeta,
        ),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMemory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMemory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      epoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}epoch'],
      )!,
      kindId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_message_id'],
      ),
      sourceSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_session_id'],
      ),
      sourceRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_record_id'],
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $LocalMemoriesTable createAlias(String alias) {
    return $LocalMemoriesTable(attachedDatabase, alias);
  }
}

class LocalMemory extends DataClass implements Insertable<LocalMemory> {
  final String id;
  final int epoch;
  final String kindId;
  final String content;
  final String source;
  final String? sourceMessageId;
  final String? sourceSessionId;
  final String? sourceRecordId;
  final double confidence;
  final int? expiresAt;
  final int version;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const LocalMemory({
    required this.id,
    required this.epoch,
    required this.kindId,
    required this.content,
    required this.source,
    this.sourceMessageId,
    this.sourceSessionId,
    this.sourceRecordId,
    required this.confidence,
    this.expiresAt,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['epoch'] = Variable<int>(epoch);
    map['kind_id'] = Variable<String>(kindId);
    map['content'] = Variable<String>(content);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || sourceMessageId != null) {
      map['source_message_id'] = Variable<String>(sourceMessageId);
    }
    if (!nullToAbsent || sourceSessionId != null) {
      map['source_session_id'] = Variable<String>(sourceSessionId);
    }
    if (!nullToAbsent || sourceRecordId != null) {
      map['source_record_id'] = Variable<String>(sourceRecordId);
    }
    map['confidence'] = Variable<double>(confidence);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<int>(expiresAt);
    }
    map['version'] = Variable<int>(version);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  LocalMemoriesCompanion toCompanion(bool nullToAbsent) {
    return LocalMemoriesCompanion(
      id: Value(id),
      epoch: Value(epoch),
      kindId: Value(kindId),
      content: Value(content),
      source: Value(source),
      sourceMessageId: sourceMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceMessageId),
      sourceSessionId: sourceSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceSessionId),
      sourceRecordId: sourceRecordId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceRecordId),
      confidence: Value(confidence),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      version: Value(version),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory LocalMemory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMemory(
      id: serializer.fromJson<String>(json['id']),
      epoch: serializer.fromJson<int>(json['epoch']),
      kindId: serializer.fromJson<String>(json['kindId']),
      content: serializer.fromJson<String>(json['content']),
      source: serializer.fromJson<String>(json['source']),
      sourceMessageId: serializer.fromJson<String?>(json['sourceMessageId']),
      sourceSessionId: serializer.fromJson<String?>(json['sourceSessionId']),
      sourceRecordId: serializer.fromJson<String?>(json['sourceRecordId']),
      confidence: serializer.fromJson<double>(json['confidence']),
      expiresAt: serializer.fromJson<int?>(json['expiresAt']),
      version: serializer.fromJson<int>(json['version']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'epoch': serializer.toJson<int>(epoch),
      'kindId': serializer.toJson<String>(kindId),
      'content': serializer.toJson<String>(content),
      'source': serializer.toJson<String>(source),
      'sourceMessageId': serializer.toJson<String?>(sourceMessageId),
      'sourceSessionId': serializer.toJson<String?>(sourceSessionId),
      'sourceRecordId': serializer.toJson<String?>(sourceRecordId),
      'confidence': serializer.toJson<double>(confidence),
      'expiresAt': serializer.toJson<int?>(expiresAt),
      'version': serializer.toJson<int>(version),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  LocalMemory copyWith({
    String? id,
    int? epoch,
    String? kindId,
    String? content,
    String? source,
    Value<String?> sourceMessageId = const Value.absent(),
    Value<String?> sourceSessionId = const Value.absent(),
    Value<String?> sourceRecordId = const Value.absent(),
    double? confidence,
    Value<int?> expiresAt = const Value.absent(),
    int? version,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => LocalMemory(
    id: id ?? this.id,
    epoch: epoch ?? this.epoch,
    kindId: kindId ?? this.kindId,
    content: content ?? this.content,
    source: source ?? this.source,
    sourceMessageId: sourceMessageId.present
        ? sourceMessageId.value
        : this.sourceMessageId,
    sourceSessionId: sourceSessionId.present
        ? sourceSessionId.value
        : this.sourceSessionId,
    sourceRecordId: sourceRecordId.present
        ? sourceRecordId.value
        : this.sourceRecordId,
    confidence: confidence ?? this.confidence,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    version: version ?? this.version,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  LocalMemory copyWithCompanion(LocalMemoriesCompanion data) {
    return LocalMemory(
      id: data.id.present ? data.id.value : this.id,
      epoch: data.epoch.present ? data.epoch.value : this.epoch,
      kindId: data.kindId.present ? data.kindId.value : this.kindId,
      content: data.content.present ? data.content.value : this.content,
      source: data.source.present ? data.source.value : this.source,
      sourceMessageId: data.sourceMessageId.present
          ? data.sourceMessageId.value
          : this.sourceMessageId,
      sourceSessionId: data.sourceSessionId.present
          ? data.sourceSessionId.value
          : this.sourceSessionId,
      sourceRecordId: data.sourceRecordId.present
          ? data.sourceRecordId.value
          : this.sourceRecordId,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMemory(')
          ..write('id: $id, ')
          ..write('epoch: $epoch, ')
          ..write('kindId: $kindId, ')
          ..write('content: $content, ')
          ..write('source: $source, ')
          ..write('sourceMessageId: $sourceMessageId, ')
          ..write('sourceSessionId: $sourceSessionId, ')
          ..write('sourceRecordId: $sourceRecordId, ')
          ..write('confidence: $confidence, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    epoch,
    kindId,
    content,
    source,
    sourceMessageId,
    sourceSessionId,
    sourceRecordId,
    confidence,
    expiresAt,
    version,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMemory &&
          other.id == this.id &&
          other.epoch == this.epoch &&
          other.kindId == this.kindId &&
          other.content == this.content &&
          other.source == this.source &&
          other.sourceMessageId == this.sourceMessageId &&
          other.sourceSessionId == this.sourceSessionId &&
          other.sourceRecordId == this.sourceRecordId &&
          other.confidence == this.confidence &&
          other.expiresAt == this.expiresAt &&
          other.version == this.version &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class LocalMemoriesCompanion extends UpdateCompanion<LocalMemory> {
  final Value<String> id;
  final Value<int> epoch;
  final Value<String> kindId;
  final Value<String> content;
  final Value<String> source;
  final Value<String?> sourceMessageId;
  final Value<String?> sourceSessionId;
  final Value<String?> sourceRecordId;
  final Value<double> confidence;
  final Value<int?> expiresAt;
  final Value<int> version;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const LocalMemoriesCompanion({
    this.id = const Value.absent(),
    this.epoch = const Value.absent(),
    this.kindId = const Value.absent(),
    this.content = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceMessageId = const Value.absent(),
    this.sourceSessionId = const Value.absent(),
    this.sourceRecordId = const Value.absent(),
    this.confidence = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMemoriesCompanion.insert({
    required String id,
    required int epoch,
    required String kindId,
    required String content,
    required String source,
    this.sourceMessageId = const Value.absent(),
    this.sourceSessionId = const Value.absent(),
    this.sourceRecordId = const Value.absent(),
    required double confidence,
    this.expiresAt = const Value.absent(),
    required int version,
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       epoch = Value(epoch),
       kindId = Value(kindId),
       content = Value(content),
       source = Value(source),
       confidence = Value(confidence),
       version = Value(version),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalMemory> custom({
    Expression<String>? id,
    Expression<int>? epoch,
    Expression<String>? kindId,
    Expression<String>? content,
    Expression<String>? source,
    Expression<String>? sourceMessageId,
    Expression<String>? sourceSessionId,
    Expression<String>? sourceRecordId,
    Expression<double>? confidence,
    Expression<int>? expiresAt,
    Expression<int>? version,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (epoch != null) 'epoch': epoch,
      if (kindId != null) 'kind_id': kindId,
      if (content != null) 'content': content,
      if (source != null) 'source': source,
      if (sourceMessageId != null) 'source_message_id': sourceMessageId,
      if (sourceSessionId != null) 'source_session_id': sourceSessionId,
      if (sourceRecordId != null) 'source_record_id': sourceRecordId,
      if (confidence != null) 'confidence': confidence,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMemoriesCompanion copyWith({
    Value<String>? id,
    Value<int>? epoch,
    Value<String>? kindId,
    Value<String>? content,
    Value<String>? source,
    Value<String?>? sourceMessageId,
    Value<String?>? sourceSessionId,
    Value<String?>? sourceRecordId,
    Value<double>? confidence,
    Value<int?>? expiresAt,
    Value<int>? version,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return LocalMemoriesCompanion(
      id: id ?? this.id,
      epoch: epoch ?? this.epoch,
      kindId: kindId ?? this.kindId,
      content: content ?? this.content,
      source: source ?? this.source,
      sourceMessageId: sourceMessageId ?? this.sourceMessageId,
      sourceSessionId: sourceSessionId ?? this.sourceSessionId,
      sourceRecordId: sourceRecordId ?? this.sourceRecordId,
      confidence: confidence ?? this.confidence,
      expiresAt: expiresAt ?? this.expiresAt,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (epoch.present) {
      map['epoch'] = Variable<int>(epoch.value);
    }
    if (kindId.present) {
      map['kind_id'] = Variable<String>(kindId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceMessageId.present) {
      map['source_message_id'] = Variable<String>(sourceMessageId.value);
    }
    if (sourceSessionId.present) {
      map['source_session_id'] = Variable<String>(sourceSessionId.value);
    }
    if (sourceRecordId.present) {
      map['source_record_id'] = Variable<String>(sourceRecordId.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMemoriesCompanion(')
          ..write('id: $id, ')
          ..write('epoch: $epoch, ')
          ..write('kindId: $kindId, ')
          ..write('content: $content, ')
          ..write('source: $source, ')
          ..write('sourceMessageId: $sourceMessageId, ')
          ..write('sourceSessionId: $sourceSessionId, ')
          ..write('sourceRecordId: $sourceRecordId, ')
          ..write('confidence: $confidence, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMemoryStateTable extends LocalMemoryState
    with TableInfo<$LocalMemoryStateTable, LocalMemoryStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMemoryStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _epochMeta = const VerificationMeta('epoch');
  @override
  late final GeneratedColumn<int> epoch = GeneratedColumn<int>(
    'epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pausedMeta = const VerificationMeta('paused');
  @override
  late final GeneratedColumn<bool> paused = GeneratedColumn<bool>(
    'paused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("paused" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, epoch, paused, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_memory_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMemoryStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('epoch')) {
      context.handle(
        _epochMeta,
        epoch.isAcceptableOrUnknown(data['epoch']!, _epochMeta),
      );
    } else if (isInserting) {
      context.missing(_epochMeta);
    }
    if (data.containsKey('paused')) {
      context.handle(
        _pausedMeta,
        paused.isAcceptableOrUnknown(data['paused']!, _pausedMeta),
      );
    } else if (isInserting) {
      context.missing(_pausedMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMemoryStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMemoryStateData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      epoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}epoch'],
      )!,
      paused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}paused'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalMemoryStateTable createAlias(String alias) {
    return $LocalMemoryStateTable(attachedDatabase, alias);
  }
}

class LocalMemoryStateData extends DataClass
    implements Insertable<LocalMemoryStateData> {
  final int id;
  final int epoch;
  final bool paused;
  final int updatedAt;
  const LocalMemoryStateData({
    required this.id,
    required this.epoch,
    required this.paused,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['epoch'] = Variable<int>(epoch);
    map['paused'] = Variable<bool>(paused);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  LocalMemoryStateCompanion toCompanion(bool nullToAbsent) {
    return LocalMemoryStateCompanion(
      id: Value(id),
      epoch: Value(epoch),
      paused: Value(paused),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalMemoryStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMemoryStateData(
      id: serializer.fromJson<int>(json['id']),
      epoch: serializer.fromJson<int>(json['epoch']),
      paused: serializer.fromJson<bool>(json['paused']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'epoch': serializer.toJson<int>(epoch),
      'paused': serializer.toJson<bool>(paused),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  LocalMemoryStateData copyWith({
    int? id,
    int? epoch,
    bool? paused,
    int? updatedAt,
  }) => LocalMemoryStateData(
    id: id ?? this.id,
    epoch: epoch ?? this.epoch,
    paused: paused ?? this.paused,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalMemoryStateData copyWithCompanion(LocalMemoryStateCompanion data) {
    return LocalMemoryStateData(
      id: data.id.present ? data.id.value : this.id,
      epoch: data.epoch.present ? data.epoch.value : this.epoch,
      paused: data.paused.present ? data.paused.value : this.paused,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMemoryStateData(')
          ..write('id: $id, ')
          ..write('epoch: $epoch, ')
          ..write('paused: $paused, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, epoch, paused, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMemoryStateData &&
          other.id == this.id &&
          other.epoch == this.epoch &&
          other.paused == this.paused &&
          other.updatedAt == this.updatedAt);
}

class LocalMemoryStateCompanion extends UpdateCompanion<LocalMemoryStateData> {
  final Value<int> id;
  final Value<int> epoch;
  final Value<bool> paused;
  final Value<int> updatedAt;
  const LocalMemoryStateCompanion({
    this.id = const Value.absent(),
    this.epoch = const Value.absent(),
    this.paused = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalMemoryStateCompanion.insert({
    this.id = const Value.absent(),
    required int epoch,
    required bool paused,
    required int updatedAt,
  }) : epoch = Value(epoch),
       paused = Value(paused),
       updatedAt = Value(updatedAt);
  static Insertable<LocalMemoryStateData> custom({
    Expression<int>? id,
    Expression<int>? epoch,
    Expression<bool>? paused,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (epoch != null) 'epoch': epoch,
      if (paused != null) 'paused': paused,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalMemoryStateCompanion copyWith({
    Value<int>? id,
    Value<int>? epoch,
    Value<bool>? paused,
    Value<int>? updatedAt,
  }) {
    return LocalMemoryStateCompanion(
      id: id ?? this.id,
      epoch: epoch ?? this.epoch,
      paused: paused ?? this.paused,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (epoch.present) {
      map['epoch'] = Variable<int>(epoch.value);
    }
    if (paused.present) {
      map['paused'] = Variable<bool>(paused.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMemoryStateCompanion(')
          ..write('id: $id, ')
          ..write('epoch: $epoch, ')
          ..write('paused: $paused, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalReportsTable extends LocalReports
    with TableInfo<$LocalReportsTable, LocalReport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<int> startAt = GeneratedColumn<int>(
    'start_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtMeta = const VerificationMeta('endAt');
  @override
  late final GeneratedColumn<int> endAt = GeneratedColumn<int>(
    'end_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snapshotMeta = const VerificationMeta(
    'snapshot',
  );
  @override
  late final GeneratedColumn<String> snapshot = GeneratedColumn<String>(
    'snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    startAt,
    endAt,
    timezone,
    snapshot,
    status,
    summary,
    templateId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalReport> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('start_at')) {
      context.handle(
        _startAtMeta,
        startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startAtMeta);
    }
    if (data.containsKey('end_at')) {
      context.handle(
        _endAtMeta,
        endAt.isAcceptableOrUnknown(data['end_at']!, _endAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endAtMeta);
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    } else if (isInserting) {
      context.missing(_timezoneMeta);
    }
    if (data.containsKey('snapshot')) {
      context.handle(
        _snapshotMeta,
        snapshot.isAcceptableOrUnknown(data['snapshot']!, _snapshotMeta),
      );
    } else if (isInserting) {
      context.missing(_snapshotMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalReport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalReport(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_at'],
      )!,
      endAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_at'],
      )!,
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      snapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalReportsTable createAlias(String alias) {
    return $LocalReportsTable(attachedDatabase, alias);
  }
}

class LocalReport extends DataClass implements Insertable<LocalReport> {
  final String id;
  final String kind;
  final int startAt;
  final int endAt;
  final String timezone;
  final String snapshot;
  final String status;
  final String? summary;
  final String? templateId;
  final int createdAt;
  final int updatedAt;
  const LocalReport({
    required this.id,
    required this.kind,
    required this.startAt,
    required this.endAt,
    required this.timezone,
    required this.snapshot,
    required this.status,
    this.summary,
    this.templateId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['start_at'] = Variable<int>(startAt);
    map['end_at'] = Variable<int>(endAt);
    map['timezone'] = Variable<String>(timezone);
    map['snapshot'] = Variable<String>(snapshot);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<String>(templateId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  LocalReportsCompanion toCompanion(bool nullToAbsent) {
    return LocalReportsCompanion(
      id: Value(id),
      kind: Value(kind),
      startAt: Value(startAt),
      endAt: Value(endAt),
      timezone: Value(timezone),
      snapshot: Value(snapshot),
      status: Value(status),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalReport.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalReport(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      startAt: serializer.fromJson<int>(json['startAt']),
      endAt: serializer.fromJson<int>(json['endAt']),
      timezone: serializer.fromJson<String>(json['timezone']),
      snapshot: serializer.fromJson<String>(json['snapshot']),
      status: serializer.fromJson<String>(json['status']),
      summary: serializer.fromJson<String?>(json['summary']),
      templateId: serializer.fromJson<String?>(json['templateId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'startAt': serializer.toJson<int>(startAt),
      'endAt': serializer.toJson<int>(endAt),
      'timezone': serializer.toJson<String>(timezone),
      'snapshot': serializer.toJson<String>(snapshot),
      'status': serializer.toJson<String>(status),
      'summary': serializer.toJson<String?>(summary),
      'templateId': serializer.toJson<String?>(templateId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  LocalReport copyWith({
    String? id,
    String? kind,
    int? startAt,
    int? endAt,
    String? timezone,
    String? snapshot,
    String? status,
    Value<String?> summary = const Value.absent(),
    Value<String?> templateId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => LocalReport(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    startAt: startAt ?? this.startAt,
    endAt: endAt ?? this.endAt,
    timezone: timezone ?? this.timezone,
    snapshot: snapshot ?? this.snapshot,
    status: status ?? this.status,
    summary: summary.present ? summary.value : this.summary,
    templateId: templateId.present ? templateId.value : this.templateId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalReport copyWithCompanion(LocalReportsCompanion data) {
    return LocalReport(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      snapshot: data.snapshot.present ? data.snapshot.value : this.snapshot,
      status: data.status.present ? data.status.value : this.status,
      summary: data.summary.present ? data.summary.value : this.summary,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalReport(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('timezone: $timezone, ')
          ..write('snapshot: $snapshot, ')
          ..write('status: $status, ')
          ..write('summary: $summary, ')
          ..write('templateId: $templateId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    startAt,
    endAt,
    timezone,
    snapshot,
    status,
    summary,
    templateId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalReport &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.timezone == this.timezone &&
          other.snapshot == this.snapshot &&
          other.status == this.status &&
          other.summary == this.summary &&
          other.templateId == this.templateId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalReportsCompanion extends UpdateCompanion<LocalReport> {
  final Value<String> id;
  final Value<String> kind;
  final Value<int> startAt;
  final Value<int> endAt;
  final Value<String> timezone;
  final Value<String> snapshot;
  final Value<String> status;
  final Value<String?> summary;
  final Value<String?> templateId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const LocalReportsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.timezone = const Value.absent(),
    this.snapshot = const Value.absent(),
    this.status = const Value.absent(),
    this.summary = const Value.absent(),
    this.templateId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalReportsCompanion.insert({
    required String id,
    required String kind,
    required int startAt,
    required int endAt,
    required String timezone,
    required String snapshot,
    required String status,
    this.summary = const Value.absent(),
    this.templateId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       startAt = Value(startAt),
       endAt = Value(endAt),
       timezone = Value(timezone),
       snapshot = Value(snapshot),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalReport> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<int>? startAt,
    Expression<int>? endAt,
    Expression<String>? timezone,
    Expression<String>? snapshot,
    Expression<String>? status,
    Expression<String>? summary,
    Expression<String>? templateId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (timezone != null) 'timezone': timezone,
      if (snapshot != null) 'snapshot': snapshot,
      if (status != null) 'status': status,
      if (summary != null) 'summary': summary,
      if (templateId != null) 'template_id': templateId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalReportsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<int>? startAt,
    Value<int>? endAt,
    Value<String>? timezone,
    Value<String>? snapshot,
    Value<String>? status,
    Value<String?>? summary,
    Value<String?>? templateId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalReportsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      timezone: timezone ?? this.timezone,
      snapshot: snapshot ?? this.snapshot,
      status: status ?? this.status,
      summary: summary ?? this.summary,
      templateId: templateId ?? this.templateId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<int>(startAt.value);
    }
    if (endAt.present) {
      map['end_at'] = Variable<int>(endAt.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (snapshot.present) {
      map['snapshot'] = Variable<String>(snapshot.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalReportsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('timezone: $timezone, ')
          ..write('snapshot: $snapshot, ')
          ..write('status: $status, ')
          ..write('summary: $summary, ')
          ..write('templateId: $templateId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProviderConfigurationsTable providerConfigurations =
      $ProviderConfigurationsTable(this);
  late final $ProviderAccountsTable providerAccounts = $ProviderAccountsTable(
    this,
  );
  late final $CredentialCleanupTable credentialCleanup =
      $CredentialCleanupTable(this);
  late final $LocalProfilesTable localProfiles = $LocalProfilesTable(this);
  late final $WorkTodosTable workTodos = $WorkTodosTable(this);
  late final $WorkTodoSeriesTable workTodoSeries = $WorkTodoSeriesTable(this);
  late final $WorkCategoriesTable workCategories = $WorkCategoriesTable(this);
  late final $WorkspaceOperationsTable workspaceOperations =
      $WorkspaceOperationsTable(this);
  late final $WorkDataTablesTable workDataTables = $WorkDataTablesTable(this);
  late final $WorkDataRowsTable workDataRows = $WorkDataRowsTable(this);
  late final $WorkTableTypesTable workTableTypes = $WorkTableTypesTable(this);
  late final $AppPreferenceRowsTable appPreferenceRows =
      $AppPreferenceRowsTable(this);
  late final $AgentRunRowsTable agentRunRows = $AgentRunRowsTable(this);
  late final $AgentRunEventsTable agentRunEvents = $AgentRunEventsTable(this);
  late final $ChatConversationsTable chatConversations =
      $ChatConversationsTable(this);
  late final $ChatTurnsTable chatTurns = $ChatTurnsTable(this);
  late final $LocalJobRowsTable localJobRows = $LocalJobRowsTable(this);
  late final $NotificationAttemptsTable notificationAttempts =
      $NotificationAttemptsTable(this);
  late final $LocalAttachmentsTable localAttachments = $LocalAttachmentsTable(
    this,
  );
  late final $LocalMemoriesTable localMemories = $LocalMemoriesTable(this);
  late final $LocalMemoryStateTable localMemoryState = $LocalMemoryStateTable(
    this,
  );
  late final $LocalReportsTable localReports = $LocalReportsTable(this);
  late final Index workTodosOccurrenceKey = Index(
    'work_todos_occurrence_key',
    'CREATE UNIQUE INDEX work_todos_occurrence_key ON work_todos (series_id, occurrence_key)',
  );
  late final Index workTodosOccurrenceIndex = Index(
    'work_todos_occurrence_index',
    'CREATE UNIQUE INDEX work_todos_occurrence_index ON work_todos (series_id, occurrence_index)',
  );
  late final Index workTodosCategory = Index(
    'work_todos_category',
    'CREATE INDEX work_todos_category ON work_todos (category_id, deleted_at)',
  );
  late final Index workTodosDue = Index(
    'work_todos_due',
    'CREATE INDEX work_todos_due ON work_todos (status, due_at, deleted_at)',
  );
  late final Index workCategoriesParent = Index(
    'work_categories_parent',
    'CREATE INDEX work_categories_parent ON work_categories (parent_id, deleted_at)',
  );
  late final Index workDataTablesType = Index(
    'work_data_tables_type',
    'CREATE INDEX work_data_tables_type ON work_data_tables (type_id, deleted_at)',
  );
  late final Index workDataRowsTable = Index(
    'work_data_rows_table',
    'CREATE INDEX work_data_rows_table ON work_data_rows (table_id, deleted_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    providerConfigurations,
    providerAccounts,
    credentialCleanup,
    localProfiles,
    workTodos,
    workTodoSeries,
    workCategories,
    workspaceOperations,
    workDataTables,
    workDataRows,
    workTableTypes,
    appPreferenceRows,
    agentRunRows,
    agentRunEvents,
    chatConversations,
    chatTurns,
    localJobRows,
    notificationAttempts,
    localAttachments,
    localMemories,
    localMemoryState,
    localReports,
    workTodosOccurrenceKey,
    workTodosOccurrenceIndex,
    workTodosCategory,
    workTodosDue,
    workCategoriesParent,
    workDataTablesType,
    workDataRowsTable,
  ];
}

typedef $$ProviderConfigurationsTableCreateCompanionBuilder =
    ProviderConfigurationsCompanion Function({
      Value<int> id,
      required String product,
      required String region,
      required String model,
      required bool disableThinking,
      required int version,
      Value<String?> credentialRef,
      Value<String?> accountId,
    });
typedef $$ProviderConfigurationsTableUpdateCompanionBuilder =
    ProviderConfigurationsCompanion Function({
      Value<int> id,
      Value<String> product,
      Value<String> region,
      Value<String> model,
      Value<bool> disableThinking,
      Value<int> version,
      Value<String?> credentialRef,
      Value<String?> accountId,
    });

class $$ProviderConfigurationsTableFilterComposer
    extends Composer<_$AppDatabase, $ProviderConfigurationsTable> {
  $$ProviderConfigurationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get product => $composableBuilder(
    column: $table.product,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get disableThinking => $composableBuilder(
    column: $table.disableThinking,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProviderConfigurationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProviderConfigurationsTable> {
  $$ProviderConfigurationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get product => $composableBuilder(
    column: $table.product,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get disableThinking => $composableBuilder(
    column: $table.disableThinking,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProviderConfigurationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProviderConfigurationsTable> {
  $$ProviderConfigurationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get product =>
      $composableBuilder(column: $table.product, builder: (column) => column);

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<bool> get disableThinking => $composableBuilder(
    column: $table.disableThinking,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);
}

class $$ProviderConfigurationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProviderConfigurationsTable,
          ProviderConfiguration,
          $$ProviderConfigurationsTableFilterComposer,
          $$ProviderConfigurationsTableOrderingComposer,
          $$ProviderConfigurationsTableAnnotationComposer,
          $$ProviderConfigurationsTableCreateCompanionBuilder,
          $$ProviderConfigurationsTableUpdateCompanionBuilder,
          (
            ProviderConfiguration,
            BaseReferences<
              _$AppDatabase,
              $ProviderConfigurationsTable,
              ProviderConfiguration
            >,
          ),
          ProviderConfiguration,
          PrefetchHooks Function()
        > {
  $$ProviderConfigurationsTableTableManager(
    _$AppDatabase db,
    $ProviderConfigurationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderConfigurationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ProviderConfigurationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProviderConfigurationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> product = const Value.absent(),
                Value<String> region = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<bool> disableThinking = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> credentialRef = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
              }) => ProviderConfigurationsCompanion(
                id: id,
                product: product,
                region: region,
                model: model,
                disableThinking: disableThinking,
                version: version,
                credentialRef: credentialRef,
                accountId: accountId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String product,
                required String region,
                required String model,
                required bool disableThinking,
                required int version,
                Value<String?> credentialRef = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
              }) => ProviderConfigurationsCompanion.insert(
                id: id,
                product: product,
                region: region,
                model: model,
                disableThinking: disableThinking,
                version: version,
                credentialRef: credentialRef,
                accountId: accountId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ProviderConfigurationsTable,
                    ProviderConfiguration
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ProviderConfigurationsTable,
                    ProviderConfiguration
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProviderConfigurationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProviderConfigurationsTable,
      ProviderConfiguration,
      $$ProviderConfigurationsTableFilterComposer,
      $$ProviderConfigurationsTableOrderingComposer,
      $$ProviderConfigurationsTableAnnotationComposer,
      $$ProviderConfigurationsTableCreateCompanionBuilder,
      $$ProviderConfigurationsTableUpdateCompanionBuilder,
      (
        ProviderConfiguration,
        BaseReferences<
          _$AppDatabase,
          $ProviderConfigurationsTable,
          ProviderConfiguration
        >,
      ),
      ProviderConfiguration,
      PrefetchHooks Function()
    >;
typedef $$ProviderAccountsTableCreateCompanionBuilder =
    ProviderAccountsCompanion Function({
      required String id,
      required String product,
      required String region,
      required String model,
      Value<String?> baseUrl,
      required bool disableThinking,
      Value<String?> credentialRef,
      required int position,
      required bool autoRoute,
      Value<int?> cooldownUntil,
      Value<String?> cooldownReason,
      Value<String?> quotaPayload,
      Value<int> rowid,
    });
typedef $$ProviderAccountsTableUpdateCompanionBuilder =
    ProviderAccountsCompanion Function({
      Value<String> id,
      Value<String> product,
      Value<String> region,
      Value<String> model,
      Value<String?> baseUrl,
      Value<bool> disableThinking,
      Value<String?> credentialRef,
      Value<int> position,
      Value<bool> autoRoute,
      Value<int?> cooldownUntil,
      Value<String?> cooldownReason,
      Value<String?> quotaPayload,
      Value<int> rowid,
    });

class $$ProviderAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $ProviderAccountsTable> {
  $$ProviderAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get product => $composableBuilder(
    column: $table.product,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get disableThinking => $composableBuilder(
    column: $table.disableThinking,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoRoute => $composableBuilder(
    column: $table.autoRoute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cooldownUntil => $composableBuilder(
    column: $table.cooldownUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cooldownReason => $composableBuilder(
    column: $table.cooldownReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quotaPayload => $composableBuilder(
    column: $table.quotaPayload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProviderAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProviderAccountsTable> {
  $$ProviderAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get product => $composableBuilder(
    column: $table.product,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get disableThinking => $composableBuilder(
    column: $table.disableThinking,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoRoute => $composableBuilder(
    column: $table.autoRoute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cooldownUntil => $composableBuilder(
    column: $table.cooldownUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cooldownReason => $composableBuilder(
    column: $table.cooldownReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quotaPayload => $composableBuilder(
    column: $table.quotaPayload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProviderAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProviderAccountsTable> {
  $$ProviderAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get product =>
      $composableBuilder(column: $table.product, builder: (column) => column);

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<bool> get disableThinking => $composableBuilder(
    column: $table.disableThinking,
    builder: (column) => column,
  );

  GeneratedColumn<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<bool> get autoRoute =>
      $composableBuilder(column: $table.autoRoute, builder: (column) => column);

  GeneratedColumn<int> get cooldownUntil => $composableBuilder(
    column: $table.cooldownUntil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cooldownReason => $composableBuilder(
    column: $table.cooldownReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quotaPayload => $composableBuilder(
    column: $table.quotaPayload,
    builder: (column) => column,
  );
}

class $$ProviderAccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProviderAccountsTable,
          ProviderAccountRow,
          $$ProviderAccountsTableFilterComposer,
          $$ProviderAccountsTableOrderingComposer,
          $$ProviderAccountsTableAnnotationComposer,
          $$ProviderAccountsTableCreateCompanionBuilder,
          $$ProviderAccountsTableUpdateCompanionBuilder,
          (
            ProviderAccountRow,
            BaseReferences<
              _$AppDatabase,
              $ProviderAccountsTable,
              ProviderAccountRow
            >,
          ),
          ProviderAccountRow,
          PrefetchHooks Function()
        > {
  $$ProviderAccountsTableTableManager(
    _$AppDatabase db,
    $ProviderAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProviderAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProviderAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> product = const Value.absent(),
                Value<String> region = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<String?> baseUrl = const Value.absent(),
                Value<bool> disableThinking = const Value.absent(),
                Value<String?> credentialRef = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<bool> autoRoute = const Value.absent(),
                Value<int?> cooldownUntil = const Value.absent(),
                Value<String?> cooldownReason = const Value.absent(),
                Value<String?> quotaPayload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderAccountsCompanion(
                id: id,
                product: product,
                region: region,
                model: model,
                baseUrl: baseUrl,
                disableThinking: disableThinking,
                credentialRef: credentialRef,
                position: position,
                autoRoute: autoRoute,
                cooldownUntil: cooldownUntil,
                cooldownReason: cooldownReason,
                quotaPayload: quotaPayload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String product,
                required String region,
                required String model,
                Value<String?> baseUrl = const Value.absent(),
                required bool disableThinking,
                Value<String?> credentialRef = const Value.absent(),
                required int position,
                required bool autoRoute,
                Value<int?> cooldownUntil = const Value.absent(),
                Value<String?> cooldownReason = const Value.absent(),
                Value<String?> quotaPayload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderAccountsCompanion.insert(
                id: id,
                product: product,
                region: region,
                model: model,
                baseUrl: baseUrl,
                disableThinking: disableThinking,
                credentialRef: credentialRef,
                position: position,
                autoRoute: autoRoute,
                cooldownUntil: cooldownUntil,
                cooldownReason: cooldownReason,
                quotaPayload: quotaPayload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProviderAccountsTable, ProviderAccountRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ProviderAccountsTable,
                    ProviderAccountRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProviderAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProviderAccountsTable,
      ProviderAccountRow,
      $$ProviderAccountsTableFilterComposer,
      $$ProviderAccountsTableOrderingComposer,
      $$ProviderAccountsTableAnnotationComposer,
      $$ProviderAccountsTableCreateCompanionBuilder,
      $$ProviderAccountsTableUpdateCompanionBuilder,
      (
        ProviderAccountRow,
        BaseReferences<
          _$AppDatabase,
          $ProviderAccountsTable,
          ProviderAccountRow
        >,
      ),
      ProviderAccountRow,
      PrefetchHooks Function()
    >;
typedef $$CredentialCleanupTableCreateCompanionBuilder =
    CredentialCleanupCompanion Function({
      required String reference,
      Value<int> rowid,
    });
typedef $$CredentialCleanupTableUpdateCompanionBuilder =
    CredentialCleanupCompanion Function({
      Value<String> reference,
      Value<int> rowid,
    });

class $$CredentialCleanupTableFilterComposer
    extends Composer<_$AppDatabase, $CredentialCleanupTable> {
  $$CredentialCleanupTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CredentialCleanupTableOrderingComposer
    extends Composer<_$AppDatabase, $CredentialCleanupTable> {
  $$CredentialCleanupTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CredentialCleanupTableAnnotationComposer
    extends Composer<_$AppDatabase, $CredentialCleanupTable> {
  $$CredentialCleanupTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);
}

class $$CredentialCleanupTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CredentialCleanupTable,
          CredentialCleanupData,
          $$CredentialCleanupTableFilterComposer,
          $$CredentialCleanupTableOrderingComposer,
          $$CredentialCleanupTableAnnotationComposer,
          $$CredentialCleanupTableCreateCompanionBuilder,
          $$CredentialCleanupTableUpdateCompanionBuilder,
          (
            CredentialCleanupData,
            BaseReferences<
              _$AppDatabase,
              $CredentialCleanupTable,
              CredentialCleanupData
            >,
          ),
          CredentialCleanupData,
          PrefetchHooks Function()
        > {
  $$CredentialCleanupTableTableManager(
    _$AppDatabase db,
    $CredentialCleanupTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CredentialCleanupTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CredentialCleanupTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CredentialCleanupTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback: ({
            Value<String> reference = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => CredentialCleanupCompanion(reference: reference, rowid: rowid),
          createCompanionCallback:
              ({
                required String reference,
                Value<int> rowid = const Value.absent(),
              }) => CredentialCleanupCompanion.insert(
                reference: reference,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CredentialCleanupTable, CredentialCleanupData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $CredentialCleanupTable,
                    CredentialCleanupData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CredentialCleanupTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CredentialCleanupTable,
      CredentialCleanupData,
      $$CredentialCleanupTableFilterComposer,
      $$CredentialCleanupTableOrderingComposer,
      $$CredentialCleanupTableAnnotationComposer,
      $$CredentialCleanupTableCreateCompanionBuilder,
      $$CredentialCleanupTableUpdateCompanionBuilder,
      (
        CredentialCleanupData,
        BaseReferences<
          _$AppDatabase,
          $CredentialCleanupTable,
          CredentialCleanupData
        >,
      ),
      CredentialCleanupData,
      PrefetchHooks Function()
    >;
typedef $$LocalProfilesTableCreateCompanionBuilder =
    LocalProfilesCompanion Function({
      Value<int> singletonId,
      required String localUserId,
      required String nickname,
      required int version,
      required DateTime createdAt,
    });
typedef $$LocalProfilesTableUpdateCompanionBuilder =
    LocalProfilesCompanion Function({
      Value<int> singletonId,
      Value<String> localUserId,
      Value<String> nickname,
      Value<int> version,
      Value<DateTime> createdAt,
    });

class $$LocalProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalProfilesTable> {
  $$LocalProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localUserId => $composableBuilder(
    column: $table.localUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalProfilesTable> {
  $$LocalProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localUserId => $composableBuilder(
    column: $table.localUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalProfilesTable> {
  $$LocalProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localUserId => $composableBuilder(
    column: $table.localUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalProfilesTable,
          LocalProfileRow,
          $$LocalProfilesTableFilterComposer,
          $$LocalProfilesTableOrderingComposer,
          $$LocalProfilesTableAnnotationComposer,
          $$LocalProfilesTableCreateCompanionBuilder,
          $$LocalProfilesTableUpdateCompanionBuilder,
          (
            LocalProfileRow,
            BaseReferences<_$AppDatabase, $LocalProfilesTable, LocalProfileRow>,
          ),
          LocalProfileRow,
          PrefetchHooks Function()
        > {
  $$LocalProfilesTableTableManager(_$AppDatabase db, $LocalProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> singletonId = const Value.absent(),
                Value<String> localUserId = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LocalProfilesCompanion(
                singletonId: singletonId,
                localUserId: localUserId,
                nickname: nickname,
                version: version,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> singletonId = const Value.absent(),
                required String localUserId,
                required String nickname,
                required int version,
                required DateTime createdAt,
              }) => LocalProfilesCompanion.insert(
                singletonId: singletonId,
                localUserId: localUserId,
                nickname: nickname,
                version: version,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalProfilesTable, LocalProfileRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalProfilesTable,
                    LocalProfileRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalProfilesTable,
      LocalProfileRow,
      $$LocalProfilesTableFilterComposer,
      $$LocalProfilesTableOrderingComposer,
      $$LocalProfilesTableAnnotationComposer,
      $$LocalProfilesTableCreateCompanionBuilder,
      $$LocalProfilesTableUpdateCompanionBuilder,
      (
        LocalProfileRow,
        BaseReferences<_$AppDatabase, $LocalProfilesTable, LocalProfileRow>,
      ),
      LocalProfileRow,
      PrefetchHooks Function()
    >;
typedef $$WorkTodosTableCreateCompanionBuilder = WorkTodosCompanion Function({
  Value<String?> seriesId,
  Value<String?> occurrenceKey,
  Value<int?> occurrenceIndex,
  required String id,
  required int version,
  Value<String?> categoryId,
  required String status,
  Value<DateTime?> dueAt,
  required int sortOrder,
  required String payload,
  required int createdAt,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$WorkTodosTableUpdateCompanionBuilder = WorkTodosCompanion Function({
  Value<String?> seriesId,
  Value<String?> occurrenceKey,
  Value<int?> occurrenceIndex,
  Value<String> id,
  Value<int> version,
  Value<String?> categoryId,
  Value<String> status,
  Value<DateTime?> dueAt,
  Value<int> sortOrder,
  Value<String> payload,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

class $$WorkTodosTableFilterComposer
    extends Composer<_$AppDatabase, $WorkTodosTable> {
  $$WorkTodosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurrenceKey => $composableBuilder(
    column: $table.occurrenceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurrenceIndex => $composableBuilder(
    column: $table.occurrenceIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkTodosTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkTodosTable> {
  $$WorkTodosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurrenceKey => $composableBuilder(
    column: $table.occurrenceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurrenceIndex => $composableBuilder(
    column: $table.occurrenceIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkTodosTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkTodosTable> {
  $$WorkTodosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get occurrenceKey => $composableBuilder(
    column: $table.occurrenceKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get occurrenceIndex => $composableBuilder(
    column: $table.occurrenceIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$WorkTodosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkTodosTable,
          WorkTodo,
          $$WorkTodosTableFilterComposer,
          $$WorkTodosTableOrderingComposer,
          $$WorkTodosTableAnnotationComposer,
          $$WorkTodosTableCreateCompanionBuilder,
          $$WorkTodosTableUpdateCompanionBuilder,
          (WorkTodo, BaseReferences<_$AppDatabase, $WorkTodosTable, WorkTodo>),
          WorkTodo,
          PrefetchHooks Function()
        > {
  $$WorkTodosTableTableManager(_$AppDatabase db, $WorkTodosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkTodosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkTodosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkTodosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> seriesId = const Value.absent(),
                Value<String?> occurrenceKey = const Value.absent(),
                Value<int?> occurrenceIndex = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkTodosCompanion(
                seriesId: seriesId,
                occurrenceKey: occurrenceKey,
                occurrenceIndex: occurrenceIndex,
                id: id,
                version: version,
                categoryId: categoryId,
                status: status,
                dueAt: dueAt,
                sortOrder: sortOrder,
                payload: payload,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> seriesId = const Value.absent(),
                Value<String?> occurrenceKey = const Value.absent(),
                Value<int?> occurrenceIndex = const Value.absent(),
                required String id,
                required int version,
                Value<String?> categoryId = const Value.absent(),
                required String status,
                Value<DateTime?> dueAt = const Value.absent(),
                required int sortOrder,
                required String payload,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkTodosCompanion.insert(
                seriesId: seriesId,
                occurrenceKey: occurrenceKey,
                occurrenceIndex: occurrenceIndex,
                id: id,
                version: version,
                categoryId: categoryId,
                status: status,
                dueAt: dueAt,
                sortOrder: sortOrder,
                payload: payload,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkTodosTable, WorkTodo>(table),
                  BaseReferences<_$AppDatabase, $WorkTodosTable, WorkTodo>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkTodosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkTodosTable,
      WorkTodo,
      $$WorkTodosTableFilterComposer,
      $$WorkTodosTableOrderingComposer,
      $$WorkTodosTableAnnotationComposer,
      $$WorkTodosTableCreateCompanionBuilder,
      $$WorkTodosTableUpdateCompanionBuilder,
      (WorkTodo, BaseReferences<_$AppDatabase, $WorkTodosTable, WorkTodo>),
      WorkTodo,
      PrefetchHooks Function()
    >;
typedef $$WorkTodoSeriesTableCreateCompanionBuilder =
    WorkTodoSeriesCompanion Function({
      required String id,
      required int version,
      required String payload,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$WorkTodoSeriesTableUpdateCompanionBuilder =
    WorkTodoSeriesCompanion Function({
      Value<String> id,
      Value<int> version,
      Value<String> payload,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

class $$WorkTodoSeriesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkTodoSeriesTable> {
  $$WorkTodoSeriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkTodoSeriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkTodoSeriesTable> {
  $$WorkTodoSeriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkTodoSeriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkTodoSeriesTable> {
  $$WorkTodoSeriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$WorkTodoSeriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkTodoSeriesTable,
          WorkTodoSery,
          $$WorkTodoSeriesTableFilterComposer,
          $$WorkTodoSeriesTableOrderingComposer,
          $$WorkTodoSeriesTableAnnotationComposer,
          $$WorkTodoSeriesTableCreateCompanionBuilder,
          $$WorkTodoSeriesTableUpdateCompanionBuilder,
          (
            WorkTodoSery,
            BaseReferences<_$AppDatabase, $WorkTodoSeriesTable, WorkTodoSery>,
          ),
          WorkTodoSery,
          PrefetchHooks Function()
        > {
  $$WorkTodoSeriesTableTableManager(
    _$AppDatabase db,
    $WorkTodoSeriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkTodoSeriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkTodoSeriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkTodoSeriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkTodoSeriesCompanion(
                id: id,
                version: version,
                payload: payload,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int version,
                required String payload,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkTodoSeriesCompanion.insert(
                id: id,
                version: version,
                payload: payload,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkTodoSeriesTable, WorkTodoSery>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $WorkTodoSeriesTable,
                    WorkTodoSery
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkTodoSeriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkTodoSeriesTable,
      WorkTodoSery,
      $$WorkTodoSeriesTableFilterComposer,
      $$WorkTodoSeriesTableOrderingComposer,
      $$WorkTodoSeriesTableAnnotationComposer,
      $$WorkTodoSeriesTableCreateCompanionBuilder,
      $$WorkTodoSeriesTableUpdateCompanionBuilder,
      (
        WorkTodoSery,
        BaseReferences<_$AppDatabase, $WorkTodoSeriesTable, WorkTodoSery>,
      ),
      WorkTodoSery,
      PrefetchHooks Function()
    >;
typedef $$WorkCategoriesTableCreateCompanionBuilder =
    WorkCategoriesCompanion Function({
      required String id,
      required int version,
      Value<String?> parentId,
      required bool archived,
      required int sortOrder,
      required String payload,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$WorkCategoriesTableUpdateCompanionBuilder =
    WorkCategoriesCompanion Function({
      Value<String> id,
      Value<int> version,
      Value<String?> parentId,
      Value<bool> archived,
      Value<int> sortOrder,
      Value<String> payload,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

class $$WorkCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkCategoriesTable> {
  $$WorkCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkCategoriesTable> {
  $$WorkCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkCategoriesTable> {
  $$WorkCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$WorkCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkCategoriesTable,
          WorkCategory,
          $$WorkCategoriesTableFilterComposer,
          $$WorkCategoriesTableOrderingComposer,
          $$WorkCategoriesTableAnnotationComposer,
          $$WorkCategoriesTableCreateCompanionBuilder,
          $$WorkCategoriesTableUpdateCompanionBuilder,
          (
            WorkCategory,
            BaseReferences<_$AppDatabase, $WorkCategoriesTable, WorkCategory>,
          ),
          WorkCategory,
          PrefetchHooks Function()
        > {
  $$WorkCategoriesTableTableManager(
    _$AppDatabase db,
    $WorkCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkCategoriesCompanion(
                id: id,
                version: version,
                parentId: parentId,
                archived: archived,
                sortOrder: sortOrder,
                payload: payload,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int version,
                Value<String?> parentId = const Value.absent(),
                required bool archived,
                required int sortOrder,
                required String payload,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkCategoriesCompanion.insert(
                id: id,
                version: version,
                parentId: parentId,
                archived: archived,
                sortOrder: sortOrder,
                payload: payload,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkCategoriesTable, WorkCategory>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $WorkCategoriesTable,
                    WorkCategory
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkCategoriesTable,
      WorkCategory,
      $$WorkCategoriesTableFilterComposer,
      $$WorkCategoriesTableOrderingComposer,
      $$WorkCategoriesTableAnnotationComposer,
      $$WorkCategoriesTableCreateCompanionBuilder,
      $$WorkCategoriesTableUpdateCompanionBuilder,
      (
        WorkCategory,
        BaseReferences<_$AppDatabase, $WorkCategoriesTable, WorkCategory>,
      ),
      WorkCategory,
      PrefetchHooks Function()
    >;
typedef $$WorkspaceOperationsTableCreateCompanionBuilder =
    WorkspaceOperationsCompanion Function({
      required String operationId,
      required String requestDigest,
      required String source,
      Value<String?> undoOf,
      required String receipt,
      required String changes,
      required int committedAt,
      Value<int> rowid,
    });
typedef $$WorkspaceOperationsTableUpdateCompanionBuilder =
    WorkspaceOperationsCompanion Function({
      Value<String> operationId,
      Value<String> requestDigest,
      Value<String> source,
      Value<String?> undoOf,
      Value<String> receipt,
      Value<String> changes,
      Value<int> committedAt,
      Value<int> rowid,
    });

class $$WorkspaceOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkspaceOperationsTable> {
  $$WorkspaceOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestDigest => $composableBuilder(
    column: $table.requestDigest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get undoOf => $composableBuilder(
    column: $table.undoOf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receipt => $composableBuilder(
    column: $table.receipt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get changes => $composableBuilder(
    column: $table.changes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get committedAt => $composableBuilder(
    column: $table.committedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkspaceOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkspaceOperationsTable> {
  $$WorkspaceOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestDigest => $composableBuilder(
    column: $table.requestDigest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get undoOf => $composableBuilder(
    column: $table.undoOf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receipt => $composableBuilder(
    column: $table.receipt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get changes => $composableBuilder(
    column: $table.changes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get committedAt => $composableBuilder(
    column: $table.committedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkspaceOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkspaceOperationsTable> {
  $$WorkspaceOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get requestDigest => $composableBuilder(
    column: $table.requestDigest,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get undoOf =>
      $composableBuilder(column: $table.undoOf, builder: (column) => column);

  GeneratedColumn<String> get receipt =>
      $composableBuilder(column: $table.receipt, builder: (column) => column);

  GeneratedColumn<String> get changes =>
      $composableBuilder(column: $table.changes, builder: (column) => column);

  GeneratedColumn<int> get committedAt => $composableBuilder(
    column: $table.committedAt,
    builder: (column) => column,
  );
}

class $$WorkspaceOperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkspaceOperationsTable,
          WorkspaceOperation,
          $$WorkspaceOperationsTableFilterComposer,
          $$WorkspaceOperationsTableOrderingComposer,
          $$WorkspaceOperationsTableAnnotationComposer,
          $$WorkspaceOperationsTableCreateCompanionBuilder,
          $$WorkspaceOperationsTableUpdateCompanionBuilder,
          (
            WorkspaceOperation,
            BaseReferences<
              _$AppDatabase,
              $WorkspaceOperationsTable,
              WorkspaceOperation
            >,
          ),
          WorkspaceOperation,
          PrefetchHooks Function()
        > {
  $$WorkspaceOperationsTableTableManager(
    _$AppDatabase db,
    $WorkspaceOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkspaceOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkspaceOperationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WorkspaceOperationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> operationId = const Value.absent(),
                Value<String> requestDigest = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> undoOf = const Value.absent(),
                Value<String> receipt = const Value.absent(),
                Value<String> changes = const Value.absent(),
                Value<int> committedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceOperationsCompanion(
                operationId: operationId,
                requestDigest: requestDigest,
                source: source,
                undoOf: undoOf,
                receipt: receipt,
                changes: changes,
                committedAt: committedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String operationId,
                required String requestDigest,
                required String source,
                Value<String?> undoOf = const Value.absent(),
                required String receipt,
                required String changes,
                required int committedAt,
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceOperationsCompanion.insert(
                operationId: operationId,
                requestDigest: requestDigest,
                source: source,
                undoOf: undoOf,
                receipt: receipt,
                changes: changes,
                committedAt: committedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkspaceOperationsTable, WorkspaceOperation>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $WorkspaceOperationsTable,
                    WorkspaceOperation
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkspaceOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkspaceOperationsTable,
      WorkspaceOperation,
      $$WorkspaceOperationsTableFilterComposer,
      $$WorkspaceOperationsTableOrderingComposer,
      $$WorkspaceOperationsTableAnnotationComposer,
      $$WorkspaceOperationsTableCreateCompanionBuilder,
      $$WorkspaceOperationsTableUpdateCompanionBuilder,
      (
        WorkspaceOperation,
        BaseReferences<
          _$AppDatabase,
          $WorkspaceOperationsTable,
          WorkspaceOperation
        >,
      ),
      WorkspaceOperation,
      PrefetchHooks Function()
    >;
typedef $$WorkDataTablesTableCreateCompanionBuilder =
    WorkDataTablesCompanion Function({
      Value<String?> typeId,
      required bool archived,
      required int schemaRevision,
      required String id,
      required int version,
      required String payload,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$WorkDataTablesTableUpdateCompanionBuilder =
    WorkDataTablesCompanion Function({
      Value<String?> typeId,
      Value<bool> archived,
      Value<int> schemaRevision,
      Value<String> id,
      Value<int> version,
      Value<String> payload,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

class $$WorkDataTablesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkDataTablesTable> {
  $$WorkDataTablesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get typeId => $composableBuilder(
    column: $table.typeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaRevision => $composableBuilder(
    column: $table.schemaRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkDataTablesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkDataTablesTable> {
  $$WorkDataTablesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get typeId => $composableBuilder(
    column: $table.typeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaRevision => $composableBuilder(
    column: $table.schemaRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkDataTablesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkDataTablesTable> {
  $$WorkDataTablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get typeId =>
      $composableBuilder(column: $table.typeId, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get schemaRevision => $composableBuilder(
    column: $table.schemaRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$WorkDataTablesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkDataTablesTable,
          WorkDataTable,
          $$WorkDataTablesTableFilterComposer,
          $$WorkDataTablesTableOrderingComposer,
          $$WorkDataTablesTableAnnotationComposer,
          $$WorkDataTablesTableCreateCompanionBuilder,
          $$WorkDataTablesTableUpdateCompanionBuilder,
          (
            WorkDataTable,
            BaseReferences<_$AppDatabase, $WorkDataTablesTable, WorkDataTable>,
          ),
          WorkDataTable,
          PrefetchHooks Function()
        > {
  $$WorkDataTablesTableTableManager(
    _$AppDatabase db,
    $WorkDataTablesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkDataTablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkDataTablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkDataTablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> typeId = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> schemaRevision = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkDataTablesCompanion(
                typeId: typeId,
                archived: archived,
                schemaRevision: schemaRevision,
                id: id,
                version: version,
                payload: payload,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> typeId = const Value.absent(),
                required bool archived,
                required int schemaRevision,
                required String id,
                required int version,
                required String payload,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkDataTablesCompanion.insert(
                typeId: typeId,
                archived: archived,
                schemaRevision: schemaRevision,
                id: id,
                version: version,
                payload: payload,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkDataTablesTable, WorkDataTable>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $WorkDataTablesTable,
                    WorkDataTable
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkDataTablesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkDataTablesTable,
      WorkDataTable,
      $$WorkDataTablesTableFilterComposer,
      $$WorkDataTablesTableOrderingComposer,
      $$WorkDataTablesTableAnnotationComposer,
      $$WorkDataTablesTableCreateCompanionBuilder,
      $$WorkDataTablesTableUpdateCompanionBuilder,
      (
        WorkDataTable,
        BaseReferences<_$AppDatabase, $WorkDataTablesTable, WorkDataTable>,
      ),
      WorkDataTable,
      PrefetchHooks Function()
    >;
typedef $$WorkDataRowsTableCreateCompanionBuilder =
    WorkDataRowsCompanion Function({
      required String tableId,
      required String id,
      required int version,
      required String payload,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$WorkDataRowsTableUpdateCompanionBuilder =
    WorkDataRowsCompanion Function({
      Value<String> tableId,
      Value<String> id,
      Value<int> version,
      Value<String> payload,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

class $$WorkDataRowsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkDataRowsTable> {
  $$WorkDataRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tableId => $composableBuilder(
    column: $table.tableId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkDataRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkDataRowsTable> {
  $$WorkDataRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tableId => $composableBuilder(
    column: $table.tableId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkDataRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkDataRowsTable> {
  $$WorkDataRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tableId =>
      $composableBuilder(column: $table.tableId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$WorkDataRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkDataRowsTable,
          WorkDataRow,
          $$WorkDataRowsTableFilterComposer,
          $$WorkDataRowsTableOrderingComposer,
          $$WorkDataRowsTableAnnotationComposer,
          $$WorkDataRowsTableCreateCompanionBuilder,
          $$WorkDataRowsTableUpdateCompanionBuilder,
          (
            WorkDataRow,
            BaseReferences<_$AppDatabase, $WorkDataRowsTable, WorkDataRow>,
          ),
          WorkDataRow,
          PrefetchHooks Function()
        > {
  $$WorkDataRowsTableTableManager(_$AppDatabase db, $WorkDataRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkDataRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkDataRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkDataRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tableId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkDataRowsCompanion(
                tableId: tableId,
                id: id,
                version: version,
                payload: payload,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tableId,
                required String id,
                required int version,
                required String payload,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkDataRowsCompanion.insert(
                tableId: tableId,
                id: id,
                version: version,
                payload: payload,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkDataRowsTable, WorkDataRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $WorkDataRowsTable,
                    WorkDataRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkDataRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkDataRowsTable,
      WorkDataRow,
      $$WorkDataRowsTableFilterComposer,
      $$WorkDataRowsTableOrderingComposer,
      $$WorkDataRowsTableAnnotationComposer,
      $$WorkDataRowsTableCreateCompanionBuilder,
      $$WorkDataRowsTableUpdateCompanionBuilder,
      (
        WorkDataRow,
        BaseReferences<_$AppDatabase, $WorkDataRowsTable, WorkDataRow>,
      ),
      WorkDataRow,
      PrefetchHooks Function()
    >;
typedef $$WorkTableTypesTableCreateCompanionBuilder =
    WorkTableTypesCompanion Function({
      required String id,
      required int version,
      required String payload,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$WorkTableTypesTableUpdateCompanionBuilder =
    WorkTableTypesCompanion Function({
      Value<String> id,
      Value<int> version,
      Value<String> payload,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

class $$WorkTableTypesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkTableTypesTable> {
  $$WorkTableTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkTableTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkTableTypesTable> {
  $$WorkTableTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkTableTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkTableTypesTable> {
  $$WorkTableTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$WorkTableTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkTableTypesTable,
          WorkTableType,
          $$WorkTableTypesTableFilterComposer,
          $$WorkTableTypesTableOrderingComposer,
          $$WorkTableTypesTableAnnotationComposer,
          $$WorkTableTypesTableCreateCompanionBuilder,
          $$WorkTableTypesTableUpdateCompanionBuilder,
          (
            WorkTableType,
            BaseReferences<_$AppDatabase, $WorkTableTypesTable, WorkTableType>,
          ),
          WorkTableType,
          PrefetchHooks Function()
        > {
  $$WorkTableTypesTableTableManager(
    _$AppDatabase db,
    $WorkTableTypesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkTableTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkTableTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkTableTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkTableTypesCompanion(
                id: id,
                version: version,
                payload: payload,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int version,
                required String payload,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkTableTypesCompanion.insert(
                id: id,
                version: version,
                payload: payload,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkTableTypesTable, WorkTableType>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $WorkTableTypesTable,
                    WorkTableType
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkTableTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkTableTypesTable,
      WorkTableType,
      $$WorkTableTypesTableFilterComposer,
      $$WorkTableTypesTableOrderingComposer,
      $$WorkTableTypesTableAnnotationComposer,
      $$WorkTableTypesTableCreateCompanionBuilder,
      $$WorkTableTypesTableUpdateCompanionBuilder,
      (
        WorkTableType,
        BaseReferences<_$AppDatabase, $WorkTableTypesTable, WorkTableType>,
      ),
      WorkTableType,
      PrefetchHooks Function()
    >;
typedef $$AppPreferenceRowsTableCreateCompanionBuilder =
    AppPreferenceRowsCompanion Function({
      Value<int> singletonId,
      required int version,
      required String payload,
    });
typedef $$AppPreferenceRowsTableUpdateCompanionBuilder =
    AppPreferenceRowsCompanion Function({
      Value<int> singletonId,
      Value<int> version,
      Value<String> payload,
    });

class $$AppPreferenceRowsTableFilterComposer
    extends Composer<_$AppDatabase, $AppPreferenceRowsTable> {
  $$AppPreferenceRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppPreferenceRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppPreferenceRowsTable> {
  $$AppPreferenceRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppPreferenceRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppPreferenceRowsTable> {
  $$AppPreferenceRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$AppPreferenceRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppPreferenceRowsTable,
          AppPreferenceRow,
          $$AppPreferenceRowsTableFilterComposer,
          $$AppPreferenceRowsTableOrderingComposer,
          $$AppPreferenceRowsTableAnnotationComposer,
          $$AppPreferenceRowsTableCreateCompanionBuilder,
          $$AppPreferenceRowsTableUpdateCompanionBuilder,
          (
            AppPreferenceRow,
            BaseReferences<
              _$AppDatabase,
              $AppPreferenceRowsTable,
              AppPreferenceRow
            >,
          ),
          AppPreferenceRow,
          PrefetchHooks Function()
        > {
  $$AppPreferenceRowsTableTableManager(
    _$AppDatabase db,
    $AppPreferenceRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppPreferenceRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppPreferenceRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppPreferenceRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> singletonId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> payload = const Value.absent(),
              }) => AppPreferenceRowsCompanion(
                singletonId: singletonId,
                version: version,
                payload: payload,
              ),
          createCompanionCallback:
              ({
                Value<int> singletonId = const Value.absent(),
                required int version,
                required String payload,
              }) => AppPreferenceRowsCompanion.insert(
                singletonId: singletonId,
                version: version,
                payload: payload,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppPreferenceRowsTable, AppPreferenceRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AppPreferenceRowsTable,
                    AppPreferenceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppPreferenceRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppPreferenceRowsTable,
      AppPreferenceRow,
      $$AppPreferenceRowsTableFilterComposer,
      $$AppPreferenceRowsTableOrderingComposer,
      $$AppPreferenceRowsTableAnnotationComposer,
      $$AppPreferenceRowsTableCreateCompanionBuilder,
      $$AppPreferenceRowsTableUpdateCompanionBuilder,
      (
        AppPreferenceRow,
        BaseReferences<
          _$AppDatabase,
          $AppPreferenceRowsTable,
          AppPreferenceRow
        >,
      ),
      AppPreferenceRow,
      PrefetchHooks Function()
    >;
typedef $$AgentRunRowsTableCreateCompanionBuilder =
    AgentRunRowsCompanion Function({
      required String id,
      required String sessionId,
      required String inputId,
      required int revision,
      required String status,
      required String initialRequest,
      required String payload,
      Value<int> rowid,
    });
typedef $$AgentRunRowsTableUpdateCompanionBuilder =
    AgentRunRowsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> inputId,
      Value<int> revision,
      Value<String> status,
      Value<String> initialRequest,
      Value<String> payload,
      Value<int> rowid,
    });

class $$AgentRunRowsTableFilterComposer
    extends Composer<_$AppDatabase, $AgentRunRowsTable> {
  $$AgentRunRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputId => $composableBuilder(
    column: $table.inputId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get initialRequest => $composableBuilder(
    column: $table.initialRequest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AgentRunRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $AgentRunRowsTable> {
  $$AgentRunRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputId => $composableBuilder(
    column: $table.inputId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get initialRequest => $composableBuilder(
    column: $table.initialRequest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AgentRunRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AgentRunRowsTable> {
  $$AgentRunRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get inputId =>
      $composableBuilder(column: $table.inputId, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get initialRequest => $composableBuilder(
    column: $table.initialRequest,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$AgentRunRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AgentRunRowsTable,
          AgentRunRow,
          $$AgentRunRowsTableFilterComposer,
          $$AgentRunRowsTableOrderingComposer,
          $$AgentRunRowsTableAnnotationComposer,
          $$AgentRunRowsTableCreateCompanionBuilder,
          $$AgentRunRowsTableUpdateCompanionBuilder,
          (
            AgentRunRow,
            BaseReferences<_$AppDatabase, $AgentRunRowsTable, AgentRunRow>,
          ),
          AgentRunRow,
          PrefetchHooks Function()
        > {
  $$AgentRunRowsTableTableManager(_$AppDatabase db, $AgentRunRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgentRunRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgentRunRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgentRunRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> inputId = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> initialRequest = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentRunRowsCompanion(
                id: id,
                sessionId: sessionId,
                inputId: inputId,
                revision: revision,
                status: status,
                initialRequest: initialRequest,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String inputId,
                required int revision,
                required String status,
                required String initialRequest,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => AgentRunRowsCompanion.insert(
                id: id,
                sessionId: sessionId,
                inputId: inputId,
                revision: revision,
                status: status,
                initialRequest: initialRequest,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AgentRunRowsTable, AgentRunRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AgentRunRowsTable,
                    AgentRunRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AgentRunRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AgentRunRowsTable,
      AgentRunRow,
      $$AgentRunRowsTableFilterComposer,
      $$AgentRunRowsTableOrderingComposer,
      $$AgentRunRowsTableAnnotationComposer,
      $$AgentRunRowsTableCreateCompanionBuilder,
      $$AgentRunRowsTableUpdateCompanionBuilder,
      (
        AgentRunRow,
        BaseReferences<_$AppDatabase, $AgentRunRowsTable, AgentRunRow>,
      ),
      AgentRunRow,
      PrefetchHooks Function()
    >;
typedef $$AgentRunEventsTableCreateCompanionBuilder =
    AgentRunEventsCompanion Function({
      required String runId,
      required int sequence,
      required String payload,
      Value<int> rowid,
    });
typedef $$AgentRunEventsTableUpdateCompanionBuilder =
    AgentRunEventsCompanion Function({
      Value<String> runId,
      Value<int> sequence,
      Value<String> payload,
      Value<int> rowid,
    });

class $$AgentRunEventsTableFilterComposer
    extends Composer<_$AppDatabase, $AgentRunEventsTable> {
  $$AgentRunEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AgentRunEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $AgentRunEventsTable> {
  $$AgentRunEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AgentRunEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AgentRunEventsTable> {
  $$AgentRunEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get runId =>
      $composableBuilder(column: $table.runId, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$AgentRunEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AgentRunEventsTable,
          AgentRunEvent,
          $$AgentRunEventsTableFilterComposer,
          $$AgentRunEventsTableOrderingComposer,
          $$AgentRunEventsTableAnnotationComposer,
          $$AgentRunEventsTableCreateCompanionBuilder,
          $$AgentRunEventsTableUpdateCompanionBuilder,
          (
            AgentRunEvent,
            BaseReferences<_$AppDatabase, $AgentRunEventsTable, AgentRunEvent>,
          ),
          AgentRunEvent,
          PrefetchHooks Function()
        > {
  $$AgentRunEventsTableTableManager(
    _$AppDatabase db,
    $AgentRunEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgentRunEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgentRunEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgentRunEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> runId = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentRunEventsCompanion(
                runId: runId,
                sequence: sequence,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String runId,
                required int sequence,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => AgentRunEventsCompanion.insert(
                runId: runId,
                sequence: sequence,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AgentRunEventsTable, AgentRunEvent>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AgentRunEventsTable,
                    AgentRunEvent
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AgentRunEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AgentRunEventsTable,
      AgentRunEvent,
      $$AgentRunEventsTableFilterComposer,
      $$AgentRunEventsTableOrderingComposer,
      $$AgentRunEventsTableAnnotationComposer,
      $$AgentRunEventsTableCreateCompanionBuilder,
      $$AgentRunEventsTableUpdateCompanionBuilder,
      (
        AgentRunEvent,
        BaseReferences<_$AppDatabase, $AgentRunEventsTable, AgentRunEvent>,
      ),
      AgentRunEvent,
      PrefetchHooks Function()
    >;
typedef $$ChatConversationsTableCreateCompanionBuilder =
    ChatConversationsCompanion Function({
      required String id,
      required String title,
      required int revision,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$ChatConversationsTableUpdateCompanionBuilder =
    ChatConversationsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<int> revision,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

class $$ChatConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $ChatConversationsTable> {
  $$ChatConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatConversationsTable> {
  $$ChatConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatConversationsTable> {
  $$ChatConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$ChatConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatConversationsTable,
          ChatConversation,
          $$ChatConversationsTableFilterComposer,
          $$ChatConversationsTableOrderingComposer,
          $$ChatConversationsTableAnnotationComposer,
          $$ChatConversationsTableCreateCompanionBuilder,
          $$ChatConversationsTableUpdateCompanionBuilder,
          (
            ChatConversation,
            BaseReferences<
              _$AppDatabase,
              $ChatConversationsTable,
              ChatConversation
            >,
          ),
          ChatConversation,
          PrefetchHooks Function()
        > {
  $$ChatConversationsTableTableManager(
    _$AppDatabase db,
    $ChatConversationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatConversationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatConversationsCompanion(
                id: id,
                title: title,
                revision: revision,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required int revision,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatConversationsCompanion.insert(
                id: id,
                title: title,
                revision: revision,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChatConversationsTable, ChatConversation>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ChatConversationsTable,
                    ChatConversation
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatConversationsTable,
      ChatConversation,
      $$ChatConversationsTableFilterComposer,
      $$ChatConversationsTableOrderingComposer,
      $$ChatConversationsTableAnnotationComposer,
      $$ChatConversationsTableCreateCompanionBuilder,
      $$ChatConversationsTableUpdateCompanionBuilder,
      (
        ChatConversation,
        BaseReferences<
          _$AppDatabase,
          $ChatConversationsTable,
          ChatConversation
        >,
      ),
      ChatConversation,
      PrefetchHooks Function()
    >;
typedef $$ChatTurnsTableCreateCompanionBuilder = ChatTurnsCompanion Function({
  required String inputId,
  required String sessionId,
  required String runId,
  required String content,
  required int position,
  required int historyStart,
  required int createdAt,
  required bool agentEnabled,
  Value<int?> undoneAt,
  Value<int> rowid,
});
typedef $$ChatTurnsTableUpdateCompanionBuilder = ChatTurnsCompanion Function({
  Value<String> inputId,
  Value<String> sessionId,
  Value<String> runId,
  Value<String> content,
  Value<int> position,
  Value<int> historyStart,
  Value<int> createdAt,
  Value<bool> agentEnabled,
  Value<int?> undoneAt,
  Value<int> rowid,
});

class $$ChatTurnsTableFilterComposer
    extends Composer<_$AppDatabase, $ChatTurnsTable> {
  $$ChatTurnsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get inputId => $composableBuilder(
    column: $table.inputId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get historyStart => $composableBuilder(
    column: $table.historyStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get agentEnabled => $composableBuilder(
    column: $table.agentEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get undoneAt => $composableBuilder(
    column: $table.undoneAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatTurnsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatTurnsTable> {
  $$ChatTurnsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get inputId => $composableBuilder(
    column: $table.inputId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get historyStart => $composableBuilder(
    column: $table.historyStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get agentEnabled => $composableBuilder(
    column: $table.agentEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get undoneAt => $composableBuilder(
    column: $table.undoneAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatTurnsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatTurnsTable> {
  $$ChatTurnsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get inputId =>
      $composableBuilder(column: $table.inputId, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get runId =>
      $composableBuilder(column: $table.runId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get historyStart => $composableBuilder(
    column: $table.historyStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get agentEnabled => $composableBuilder(
    column: $table.agentEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get undoneAt =>
      $composableBuilder(column: $table.undoneAt, builder: (column) => column);
}

class $$ChatTurnsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatTurnsTable,
          ChatTurn,
          $$ChatTurnsTableFilterComposer,
          $$ChatTurnsTableOrderingComposer,
          $$ChatTurnsTableAnnotationComposer,
          $$ChatTurnsTableCreateCompanionBuilder,
          $$ChatTurnsTableUpdateCompanionBuilder,
          (ChatTurn, BaseReferences<_$AppDatabase, $ChatTurnsTable, ChatTurn>),
          ChatTurn,
          PrefetchHooks Function()
        > {
  $$ChatTurnsTableTableManager(_$AppDatabase db, $ChatTurnsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatTurnsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatTurnsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatTurnsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> inputId = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> runId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> historyStart = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<bool> agentEnabled = const Value.absent(),
                Value<int?> undoneAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatTurnsCompanion(
                inputId: inputId,
                sessionId: sessionId,
                runId: runId,
                content: content,
                position: position,
                historyStart: historyStart,
                createdAt: createdAt,
                agentEnabled: agentEnabled,
                undoneAt: undoneAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String inputId,
                required String sessionId,
                required String runId,
                required String content,
                required int position,
                required int historyStart,
                required int createdAt,
                required bool agentEnabled,
                Value<int?> undoneAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatTurnsCompanion.insert(
                inputId: inputId,
                sessionId: sessionId,
                runId: runId,
                content: content,
                position: position,
                historyStart: historyStart,
                createdAt: createdAt,
                agentEnabled: agentEnabled,
                undoneAt: undoneAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChatTurnsTable, ChatTurn>(table),
                  BaseReferences<_$AppDatabase, $ChatTurnsTable, ChatTurn>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatTurnsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatTurnsTable,
      ChatTurn,
      $$ChatTurnsTableFilterComposer,
      $$ChatTurnsTableOrderingComposer,
      $$ChatTurnsTableAnnotationComposer,
      $$ChatTurnsTableCreateCompanionBuilder,
      $$ChatTurnsTableUpdateCompanionBuilder,
      (ChatTurn, BaseReferences<_$AppDatabase, $ChatTurnsTable, ChatTurn>),
      ChatTurn,
      PrefetchHooks Function()
    >;
typedef $$LocalJobRowsTableCreateCompanionBuilder =
    LocalJobRowsCompanion Function({
      required String id,
      required String uniqueKey,
      required String type,
      required String payload,
      required String digest,
      required String status,
      required int dueAt,
      required int nextAttemptAt,
      required int attempts,
      required int maxAttempts,
      required int leaseEpoch,
      Value<String?> leaseOwner,
      Value<int?> leaseExpiresAt,
      Value<int?> leaseStartedAt,
      Value<String?> outcome,
      Value<String?> errorCode,
      Value<int> rowid,
    });
typedef $$LocalJobRowsTableUpdateCompanionBuilder =
    LocalJobRowsCompanion Function({
      Value<String> id,
      Value<String> uniqueKey,
      Value<String> type,
      Value<String> payload,
      Value<String> digest,
      Value<String> status,
      Value<int> dueAt,
      Value<int> nextAttemptAt,
      Value<int> attempts,
      Value<int> maxAttempts,
      Value<int> leaseEpoch,
      Value<String?> leaseOwner,
      Value<int?> leaseExpiresAt,
      Value<int?> leaseStartedAt,
      Value<String?> outcome,
      Value<String?> errorCode,
      Value<int> rowid,
    });

class $$LocalJobRowsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalJobRowsTable> {
  $$LocalJobRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uniqueKey => $composableBuilder(
    column: $table.uniqueKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get digest => $composableBuilder(
    column: $table.digest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxAttempts => $composableBuilder(
    column: $table.maxAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get leaseEpoch => $composableBuilder(
    column: $table.leaseEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get leaseOwner => $composableBuilder(
    column: $table.leaseOwner,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get leaseExpiresAt => $composableBuilder(
    column: $table.leaseExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get leaseStartedAt => $composableBuilder(
    column: $table.leaseStartedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalJobRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalJobRowsTable> {
  $$LocalJobRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uniqueKey => $composableBuilder(
    column: $table.uniqueKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get digest => $composableBuilder(
    column: $table.digest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxAttempts => $composableBuilder(
    column: $table.maxAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leaseEpoch => $composableBuilder(
    column: $table.leaseEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get leaseOwner => $composableBuilder(
    column: $table.leaseOwner,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leaseExpiresAt => $composableBuilder(
    column: $table.leaseExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leaseStartedAt => $composableBuilder(
    column: $table.leaseStartedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalJobRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalJobRowsTable> {
  $$LocalJobRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uniqueKey =>
      $composableBuilder(column: $table.uniqueKey, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get digest =>
      $composableBuilder(column: $table.digest, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get maxAttempts => $composableBuilder(
    column: $table.maxAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<int> get leaseEpoch => $composableBuilder(
    column: $table.leaseEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<String> get leaseOwner => $composableBuilder(
    column: $table.leaseOwner,
    builder: (column) => column,
  );

  GeneratedColumn<int> get leaseExpiresAt => $composableBuilder(
    column: $table.leaseExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get leaseStartedAt => $composableBuilder(
    column: $table.leaseStartedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);
}

class $$LocalJobRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalJobRowsTable,
          LocalJobRow,
          $$LocalJobRowsTableFilterComposer,
          $$LocalJobRowsTableOrderingComposer,
          $$LocalJobRowsTableAnnotationComposer,
          $$LocalJobRowsTableCreateCompanionBuilder,
          $$LocalJobRowsTableUpdateCompanionBuilder,
          (
            LocalJobRow,
            BaseReferences<_$AppDatabase, $LocalJobRowsTable, LocalJobRow>,
          ),
          LocalJobRow,
          PrefetchHooks Function()
        > {
  $$LocalJobRowsTableTableManager(_$AppDatabase db, $LocalJobRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalJobRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalJobRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalJobRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> uniqueKey = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> digest = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> dueAt = const Value.absent(),
                Value<int> nextAttemptAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> maxAttempts = const Value.absent(),
                Value<int> leaseEpoch = const Value.absent(),
                Value<String?> leaseOwner = const Value.absent(),
                Value<int?> leaseExpiresAt = const Value.absent(),
                Value<int?> leaseStartedAt = const Value.absent(),
                Value<String?> outcome = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalJobRowsCompanion(
                id: id,
                uniqueKey: uniqueKey,
                type: type,
                payload: payload,
                digest: digest,
                status: status,
                dueAt: dueAt,
                nextAttemptAt: nextAttemptAt,
                attempts: attempts,
                maxAttempts: maxAttempts,
                leaseEpoch: leaseEpoch,
                leaseOwner: leaseOwner,
                leaseExpiresAt: leaseExpiresAt,
                leaseStartedAt: leaseStartedAt,
                outcome: outcome,
                errorCode: errorCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String uniqueKey,
                required String type,
                required String payload,
                required String digest,
                required String status,
                required int dueAt,
                required int nextAttemptAt,
                required int attempts,
                required int maxAttempts,
                required int leaseEpoch,
                Value<String?> leaseOwner = const Value.absent(),
                Value<int?> leaseExpiresAt = const Value.absent(),
                Value<int?> leaseStartedAt = const Value.absent(),
                Value<String?> outcome = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalJobRowsCompanion.insert(
                id: id,
                uniqueKey: uniqueKey,
                type: type,
                payload: payload,
                digest: digest,
                status: status,
                dueAt: dueAt,
                nextAttemptAt: nextAttemptAt,
                attempts: attempts,
                maxAttempts: maxAttempts,
                leaseEpoch: leaseEpoch,
                leaseOwner: leaseOwner,
                leaseExpiresAt: leaseExpiresAt,
                leaseStartedAt: leaseStartedAt,
                outcome: outcome,
                errorCode: errorCode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalJobRowsTable, LocalJobRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalJobRowsTable,
                    LocalJobRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalJobRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalJobRowsTable,
      LocalJobRow,
      $$LocalJobRowsTableFilterComposer,
      $$LocalJobRowsTableOrderingComposer,
      $$LocalJobRowsTableAnnotationComposer,
      $$LocalJobRowsTableCreateCompanionBuilder,
      $$LocalJobRowsTableUpdateCompanionBuilder,
      (
        LocalJobRow,
        BaseReferences<_$AppDatabase, $LocalJobRowsTable, LocalJobRow>,
      ),
      LocalJobRow,
      PrefetchHooks Function()
    >;
typedef $$NotificationAttemptsTableCreateCompanionBuilder =
    NotificationAttemptsCompanion Function({
      Value<int> id,
      required String jobId,
      required int leaseEpoch,
      required String payload,
      Value<bool> cancelled,
    });
typedef $$NotificationAttemptsTableUpdateCompanionBuilder =
    NotificationAttemptsCompanion Function({
      Value<int> id,
      Value<String> jobId,
      Value<int> leaseEpoch,
      Value<String> payload,
      Value<bool> cancelled,
    });

class $$NotificationAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationAttemptsTable> {
  $$NotificationAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get leaseEpoch => $composableBuilder(
    column: $table.leaseEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cancelled => $composableBuilder(
    column: $table.cancelled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationAttemptsTable> {
  $$NotificationAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leaseEpoch => $composableBuilder(
    column: $table.leaseEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cancelled => $composableBuilder(
    column: $table.cancelled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationAttemptsTable> {
  $$NotificationAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<int> get leaseEpoch => $composableBuilder(
    column: $table.leaseEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<bool> get cancelled =>
      $composableBuilder(column: $table.cancelled, builder: (column) => column);
}

class $$NotificationAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationAttemptsTable,
          NotificationAttempt,
          $$NotificationAttemptsTableFilterComposer,
          $$NotificationAttemptsTableOrderingComposer,
          $$NotificationAttemptsTableAnnotationComposer,
          $$NotificationAttemptsTableCreateCompanionBuilder,
          $$NotificationAttemptsTableUpdateCompanionBuilder,
          (
            NotificationAttempt,
            BaseReferences<
              _$AppDatabase,
              $NotificationAttemptsTable,
              NotificationAttempt
            >,
          ),
          NotificationAttempt,
          PrefetchHooks Function()
        > {
  $$NotificationAttemptsTableTableManager(
    _$AppDatabase db,
    $NotificationAttemptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationAttemptsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$NotificationAttemptsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> jobId = const Value.absent(),
                Value<int> leaseEpoch = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<bool> cancelled = const Value.absent(),
              }) => NotificationAttemptsCompanion(
                id: id,
                jobId: jobId,
                leaseEpoch: leaseEpoch,
                payload: payload,
                cancelled: cancelled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String jobId,
                required int leaseEpoch,
                required String payload,
                Value<bool> cancelled = const Value.absent(),
              }) => NotificationAttemptsCompanion.insert(
                id: id,
                jobId: jobId,
                leaseEpoch: leaseEpoch,
                payload: payload,
                cancelled: cancelled,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotificationAttemptsTable, NotificationAttempt>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $NotificationAttemptsTable,
                    NotificationAttempt
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationAttemptsTable,
      NotificationAttempt,
      $$NotificationAttemptsTableFilterComposer,
      $$NotificationAttemptsTableOrderingComposer,
      $$NotificationAttemptsTableAnnotationComposer,
      $$NotificationAttemptsTableCreateCompanionBuilder,
      $$NotificationAttemptsTableUpdateCompanionBuilder,
      (
        NotificationAttempt,
        BaseReferences<
          _$AppDatabase,
          $NotificationAttemptsTable,
          NotificationAttempt
        >,
      ),
      NotificationAttempt,
      PrefetchHooks Function()
    >;
typedef $$LocalAttachmentsTableCreateCompanionBuilder =
    LocalAttachmentsCompanion Function({
      required String id,
      required String inputId,
      required String tableId,
      required String displayName,
      required String mime,
      required String originalHash,
      required int originalSize,
      required String modelHash,
      required int modelSize,
      required int width,
      required int height,
      required String state,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$LocalAttachmentsTableUpdateCompanionBuilder =
    LocalAttachmentsCompanion Function({
      Value<String> id,
      Value<String> inputId,
      Value<String> tableId,
      Value<String> displayName,
      Value<String> mime,
      Value<String> originalHash,
      Value<int> originalSize,
      Value<String> modelHash,
      Value<int> modelSize,
      Value<int> width,
      Value<int> height,
      Value<String> state,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$LocalAttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalAttachmentsTable> {
  $$LocalAttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputId => $composableBuilder(
    column: $table.inputId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableId => $composableBuilder(
    column: $table.tableId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalHash => $composableBuilder(
    column: $table.originalHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalSize => $composableBuilder(
    column: $table.originalSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelHash => $composableBuilder(
    column: $table.modelHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modelSize => $composableBuilder(
    column: $table.modelSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalAttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalAttachmentsTable> {
  $$LocalAttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputId => $composableBuilder(
    column: $table.inputId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableId => $composableBuilder(
    column: $table.tableId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalHash => $composableBuilder(
    column: $table.originalHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalSize => $composableBuilder(
    column: $table.originalSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelHash => $composableBuilder(
    column: $table.modelHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modelSize => $composableBuilder(
    column: $table.modelSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalAttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalAttachmentsTable> {
  $$LocalAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get inputId =>
      $composableBuilder(column: $table.inputId, builder: (column) => column);

  GeneratedColumn<String> get tableId =>
      $composableBuilder(column: $table.tableId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mime =>
      $composableBuilder(column: $table.mime, builder: (column) => column);

  GeneratedColumn<String> get originalHash => $composableBuilder(
    column: $table.originalHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get originalSize => $composableBuilder(
    column: $table.originalSize,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelHash =>
      $composableBuilder(column: $table.modelHash, builder: (column) => column);

  GeneratedColumn<int> get modelSize =>
      $composableBuilder(column: $table.modelSize, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalAttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalAttachmentsTable,
          LocalAttachment,
          $$LocalAttachmentsTableFilterComposer,
          $$LocalAttachmentsTableOrderingComposer,
          $$LocalAttachmentsTableAnnotationComposer,
          $$LocalAttachmentsTableCreateCompanionBuilder,
          $$LocalAttachmentsTableUpdateCompanionBuilder,
          (
            LocalAttachment,
            BaseReferences<
              _$AppDatabase,
              $LocalAttachmentsTable,
              LocalAttachment
            >,
          ),
          LocalAttachment,
          PrefetchHooks Function()
        > {
  $$LocalAttachmentsTableTableManager(
    _$AppDatabase db,
    $LocalAttachmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalAttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalAttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> inputId = const Value.absent(),
                Value<String> tableId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> mime = const Value.absent(),
                Value<String> originalHash = const Value.absent(),
                Value<int> originalSize = const Value.absent(),
                Value<String> modelHash = const Value.absent(),
                Value<int> modelSize = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAttachmentsCompanion(
                id: id,
                inputId: inputId,
                tableId: tableId,
                displayName: displayName,
                mime: mime,
                originalHash: originalHash,
                originalSize: originalSize,
                modelHash: modelHash,
                modelSize: modelSize,
                width: width,
                height: height,
                state: state,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String inputId,
                required String tableId,
                required String displayName,
                required String mime,
                required String originalHash,
                required int originalSize,
                required String modelHash,
                required int modelSize,
                required int width,
                required int height,
                required String state,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalAttachmentsCompanion.insert(
                id: id,
                inputId: inputId,
                tableId: tableId,
                displayName: displayName,
                mime: mime,
                originalHash: originalHash,
                originalSize: originalSize,
                modelHash: modelHash,
                modelSize: modelSize,
                width: width,
                height: height,
                state: state,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalAttachmentsTable, LocalAttachment>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalAttachmentsTable,
                    LocalAttachment
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalAttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalAttachmentsTable,
      LocalAttachment,
      $$LocalAttachmentsTableFilterComposer,
      $$LocalAttachmentsTableOrderingComposer,
      $$LocalAttachmentsTableAnnotationComposer,
      $$LocalAttachmentsTableCreateCompanionBuilder,
      $$LocalAttachmentsTableUpdateCompanionBuilder,
      (
        LocalAttachment,
        BaseReferences<_$AppDatabase, $LocalAttachmentsTable, LocalAttachment>,
      ),
      LocalAttachment,
      PrefetchHooks Function()
    >;
typedef $$LocalMemoriesTableCreateCompanionBuilder =
    LocalMemoriesCompanion Function({
      required String id,
      required int epoch,
      required String kindId,
      required String content,
      required String source,
      Value<String?> sourceMessageId,
      Value<String?> sourceSessionId,
      Value<String?> sourceRecordId,
      required double confidence,
      Value<int?> expiresAt,
      required int version,
      required int createdAt,
      required int updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$LocalMemoriesTableUpdateCompanionBuilder =
    LocalMemoriesCompanion Function({
      Value<String> id,
      Value<int> epoch,
      Value<String> kindId,
      Value<String> content,
      Value<String> source,
      Value<String?> sourceMessageId,
      Value<String?> sourceSessionId,
      Value<String?> sourceRecordId,
      Value<double> confidence,
      Value<int?> expiresAt,
      Value<int> version,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

class $$LocalMemoriesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMemoriesTable> {
  $$LocalMemoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get epoch => $composableBuilder(
    column: $table.epoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kindId => $composableBuilder(
    column: $table.kindId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceMessageId => $composableBuilder(
    column: $table.sourceMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceSessionId => $composableBuilder(
    column: $table.sourceSessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceRecordId => $composableBuilder(
    column: $table.sourceRecordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMemoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMemoriesTable> {
  $$LocalMemoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get epoch => $composableBuilder(
    column: $table.epoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kindId => $composableBuilder(
    column: $table.kindId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceMessageId => $composableBuilder(
    column: $table.sourceMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceSessionId => $composableBuilder(
    column: $table.sourceSessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceRecordId => $composableBuilder(
    column: $table.sourceRecordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMemoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMemoriesTable> {
  $$LocalMemoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get epoch =>
      $composableBuilder(column: $table.epoch, builder: (column) => column);

  GeneratedColumn<String> get kindId =>
      $composableBuilder(column: $table.kindId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceMessageId => $composableBuilder(
    column: $table.sourceMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceSessionId => $composableBuilder(
    column: $table.sourceSessionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceRecordId => $composableBuilder(
    column: $table.sourceRecordId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$LocalMemoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMemoriesTable,
          LocalMemory,
          $$LocalMemoriesTableFilterComposer,
          $$LocalMemoriesTableOrderingComposer,
          $$LocalMemoriesTableAnnotationComposer,
          $$LocalMemoriesTableCreateCompanionBuilder,
          $$LocalMemoriesTableUpdateCompanionBuilder,
          (
            LocalMemory,
            BaseReferences<_$AppDatabase, $LocalMemoriesTable, LocalMemory>,
          ),
          LocalMemory,
          PrefetchHooks Function()
        > {
  $$LocalMemoriesTableTableManager(_$AppDatabase db, $LocalMemoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMemoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMemoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMemoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> epoch = const Value.absent(),
                Value<String> kindId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> sourceMessageId = const Value.absent(),
                Value<String?> sourceSessionId = const Value.absent(),
                Value<String?> sourceRecordId = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<int?> expiresAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMemoriesCompanion(
                id: id,
                epoch: epoch,
                kindId: kindId,
                content: content,
                source: source,
                sourceMessageId: sourceMessageId,
                sourceSessionId: sourceSessionId,
                sourceRecordId: sourceRecordId,
                confidence: confidence,
                expiresAt: expiresAt,
                version: version,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int epoch,
                required String kindId,
                required String content,
                required String source,
                Value<String?> sourceMessageId = const Value.absent(),
                Value<String?> sourceSessionId = const Value.absent(),
                Value<String?> sourceRecordId = const Value.absent(),
                required double confidence,
                Value<int?> expiresAt = const Value.absent(),
                required int version,
                required int createdAt,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMemoriesCompanion.insert(
                id: id,
                epoch: epoch,
                kindId: kindId,
                content: content,
                source: source,
                sourceMessageId: sourceMessageId,
                sourceSessionId: sourceSessionId,
                sourceRecordId: sourceRecordId,
                confidence: confidence,
                expiresAt: expiresAt,
                version: version,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalMemoriesTable, LocalMemory>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalMemoriesTable,
                    LocalMemory
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMemoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMemoriesTable,
      LocalMemory,
      $$LocalMemoriesTableFilterComposer,
      $$LocalMemoriesTableOrderingComposer,
      $$LocalMemoriesTableAnnotationComposer,
      $$LocalMemoriesTableCreateCompanionBuilder,
      $$LocalMemoriesTableUpdateCompanionBuilder,
      (
        LocalMemory,
        BaseReferences<_$AppDatabase, $LocalMemoriesTable, LocalMemory>,
      ),
      LocalMemory,
      PrefetchHooks Function()
    >;
typedef $$LocalMemoryStateTableCreateCompanionBuilder =
    LocalMemoryStateCompanion Function({
      Value<int> id,
      required int epoch,
      required bool paused,
      required int updatedAt,
    });
typedef $$LocalMemoryStateTableUpdateCompanionBuilder =
    LocalMemoryStateCompanion Function({
      Value<int> id,
      Value<int> epoch,
      Value<bool> paused,
      Value<int> updatedAt,
    });

class $$LocalMemoryStateTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMemoryStateTable> {
  $$LocalMemoryStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get epoch => $composableBuilder(
    column: $table.epoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get paused => $composableBuilder(
    column: $table.paused,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMemoryStateTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMemoryStateTable> {
  $$LocalMemoryStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get epoch => $composableBuilder(
    column: $table.epoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get paused => $composableBuilder(
    column: $table.paused,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMemoryStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMemoryStateTable> {
  $$LocalMemoryStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get epoch =>
      $composableBuilder(column: $table.epoch, builder: (column) => column);

  GeneratedColumn<bool> get paused =>
      $composableBuilder(column: $table.paused, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalMemoryStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMemoryStateTable,
          LocalMemoryStateData,
          $$LocalMemoryStateTableFilterComposer,
          $$LocalMemoryStateTableOrderingComposer,
          $$LocalMemoryStateTableAnnotationComposer,
          $$LocalMemoryStateTableCreateCompanionBuilder,
          $$LocalMemoryStateTableUpdateCompanionBuilder,
          (
            LocalMemoryStateData,
            BaseReferences<
              _$AppDatabase,
              $LocalMemoryStateTable,
              LocalMemoryStateData
            >,
          ),
          LocalMemoryStateData,
          PrefetchHooks Function()
        > {
  $$LocalMemoryStateTableTableManager(
    _$AppDatabase db,
    $LocalMemoryStateTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMemoryStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMemoryStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMemoryStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> epoch = const Value.absent(),
                Value<bool> paused = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => LocalMemoryStateCompanion(
                id: id,
                epoch: epoch,
                paused: paused,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int epoch,
                required bool paused,
                required int updatedAt,
              }) => LocalMemoryStateCompanion.insert(
                id: id,
                epoch: epoch,
                paused: paused,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalMemoryStateTable, LocalMemoryStateData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalMemoryStateTable,
                    LocalMemoryStateData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMemoryStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMemoryStateTable,
      LocalMemoryStateData,
      $$LocalMemoryStateTableFilterComposer,
      $$LocalMemoryStateTableOrderingComposer,
      $$LocalMemoryStateTableAnnotationComposer,
      $$LocalMemoryStateTableCreateCompanionBuilder,
      $$LocalMemoryStateTableUpdateCompanionBuilder,
      (
        LocalMemoryStateData,
        BaseReferences<
          _$AppDatabase,
          $LocalMemoryStateTable,
          LocalMemoryStateData
        >,
      ),
      LocalMemoryStateData,
      PrefetchHooks Function()
    >;
typedef $$LocalReportsTableCreateCompanionBuilder =
    LocalReportsCompanion Function({
      required String id,
      required String kind,
      required int startAt,
      required int endAt,
      required String timezone,
      required String snapshot,
      required String status,
      Value<String?> summary,
      Value<String?> templateId,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$LocalReportsTableUpdateCompanionBuilder =
    LocalReportsCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<int> startAt,
      Value<int> endAt,
      Value<String> timezone,
      Value<String> snapshot,
      Value<String> status,
      Value<String?> summary,
      Value<String?> templateId,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$LocalReportsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalReportsTable> {
  $$LocalReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshot => $composableBuilder(
    column: $table.snapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalReportsTable> {
  $$LocalReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshot => $composableBuilder(
    column: $table.snapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalReportsTable> {
  $$LocalReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<int> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<String> get snapshot =>
      $composableBuilder(column: $table.snapshot, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalReportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalReportsTable,
          LocalReport,
          $$LocalReportsTableFilterComposer,
          $$LocalReportsTableOrderingComposer,
          $$LocalReportsTableAnnotationComposer,
          $$LocalReportsTableCreateCompanionBuilder,
          $$LocalReportsTableUpdateCompanionBuilder,
          (
            LocalReport,
            BaseReferences<_$AppDatabase, $LocalReportsTable, LocalReport>,
          ),
          LocalReport,
          PrefetchHooks Function()
        > {
  $$LocalReportsTableTableManager(_$AppDatabase db, $LocalReportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> startAt = const Value.absent(),
                Value<int> endAt = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<String> snapshot = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalReportsCompanion(
                id: id,
                kind: kind,
                startAt: startAt,
                endAt: endAt,
                timezone: timezone,
                snapshot: snapshot,
                status: status,
                summary: summary,
                templateId: templateId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required int startAt,
                required int endAt,
                required String timezone,
                required String snapshot,
                required String status,
                Value<String?> summary = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalReportsCompanion.insert(
                id: id,
                kind: kind,
                startAt: startAt,
                endAt: endAt,
                timezone: timezone,
                snapshot: snapshot,
                status: status,
                summary: summary,
                templateId: templateId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalReportsTable, LocalReport>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalReportsTable,
                    LocalReport
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalReportsTable,
      LocalReport,
      $$LocalReportsTableFilterComposer,
      $$LocalReportsTableOrderingComposer,
      $$LocalReportsTableAnnotationComposer,
      $$LocalReportsTableCreateCompanionBuilder,
      $$LocalReportsTableUpdateCompanionBuilder,
      (
        LocalReport,
        BaseReferences<_$AppDatabase, $LocalReportsTable, LocalReport>,
      ),
      LocalReport,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProviderConfigurationsTableTableManager get providerConfigurations =>
      $$ProviderConfigurationsTableTableManager(
        _db,
        _db.providerConfigurations,
      );
  $$ProviderAccountsTableTableManager get providerAccounts =>
      $$ProviderAccountsTableTableManager(_db, _db.providerAccounts);
  $$CredentialCleanupTableTableManager get credentialCleanup =>
      $$CredentialCleanupTableTableManager(_db, _db.credentialCleanup);
  $$LocalProfilesTableTableManager get localProfiles =>
      $$LocalProfilesTableTableManager(_db, _db.localProfiles);
  $$WorkTodosTableTableManager get workTodos =>
      $$WorkTodosTableTableManager(_db, _db.workTodos);
  $$WorkTodoSeriesTableTableManager get workTodoSeries =>
      $$WorkTodoSeriesTableTableManager(_db, _db.workTodoSeries);
  $$WorkCategoriesTableTableManager get workCategories =>
      $$WorkCategoriesTableTableManager(_db, _db.workCategories);
  $$WorkspaceOperationsTableTableManager get workspaceOperations =>
      $$WorkspaceOperationsTableTableManager(_db, _db.workspaceOperations);
  $$WorkDataTablesTableTableManager get workDataTables =>
      $$WorkDataTablesTableTableManager(_db, _db.workDataTables);
  $$WorkDataRowsTableTableManager get workDataRows =>
      $$WorkDataRowsTableTableManager(_db, _db.workDataRows);
  $$WorkTableTypesTableTableManager get workTableTypes =>
      $$WorkTableTypesTableTableManager(_db, _db.workTableTypes);
  $$AppPreferenceRowsTableTableManager get appPreferenceRows =>
      $$AppPreferenceRowsTableTableManager(_db, _db.appPreferenceRows);
  $$AgentRunRowsTableTableManager get agentRunRows =>
      $$AgentRunRowsTableTableManager(_db, _db.agentRunRows);
  $$AgentRunEventsTableTableManager get agentRunEvents =>
      $$AgentRunEventsTableTableManager(_db, _db.agentRunEvents);
  $$ChatConversationsTableTableManager get chatConversations =>
      $$ChatConversationsTableTableManager(_db, _db.chatConversations);
  $$ChatTurnsTableTableManager get chatTurns =>
      $$ChatTurnsTableTableManager(_db, _db.chatTurns);
  $$LocalJobRowsTableTableManager get localJobRows =>
      $$LocalJobRowsTableTableManager(_db, _db.localJobRows);
  $$NotificationAttemptsTableTableManager get notificationAttempts =>
      $$NotificationAttemptsTableTableManager(_db, _db.notificationAttempts);
  $$LocalAttachmentsTableTableManager get localAttachments =>
      $$LocalAttachmentsTableTableManager(_db, _db.localAttachments);
  $$LocalMemoriesTableTableManager get localMemories =>
      $$LocalMemoriesTableTableManager(_db, _db.localMemories);
  $$LocalMemoryStateTableTableManager get localMemoryState =>
      $$LocalMemoryStateTableTableManager(_db, _db.localMemoryState);
  $$LocalReportsTableTableManager get localReports =>
      $$LocalReportsTableTableManager(_db, _db.localReports);
}

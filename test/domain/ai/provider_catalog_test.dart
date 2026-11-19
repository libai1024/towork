import 'package:flutter_test/flutter_test.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';

void main() {
  ModelProfile profile(
    ProviderKind kind,
    String model, {
    ProviderRegion region = ProviderRegion.china,
    bool minimal = true,
    String? baseUrl,
  }) => ModelProfile(
    model: model,
    product: kind,
    region: region,
    disableThinking: minimal,
    baseUrl: baseUrl,
  );

  test('wire ids are stable and unique', () {
    // 这些字符串已经写进用户数据库与运行记录，改名即数据损坏。
    expect(
      {for (final kind in ProviderKind.values) kind.name: kind.wireId},
      {
        'moonshot': 'platform',
        'kimiCode': 'code',
        'deepseek': 'deepseek',
        'zhipu': 'zhipu',
        'zhipuCoding': 'zhipu_coding',
        'custom': 'custom',
      },
    );
    for (final kind in ProviderKind.values) {
      expect(ProviderKind.fromWire(kind.wireId), kind);
      expect(ProviderCatalog.of(kind).kind, kind);
    }
    expect(() => ProviderKind.fromWire('nope'), throwsArgumentError);
    expect(ProviderCatalog.all, hasLength(ProviderKind.values.length));
  });

  test('every provider resolves its documented endpoint', () {
    String uri(ProviderKind kind, [ProviderRegion? region]) => profile(
      kind,
      'm',
      region: region ?? ProviderRegion.china,
      baseUrl: kind == ProviderKind.custom
          ? 'https://relay.example.com/v1/'
          : null,
    ).completionsUri.toString();

    expect(
      uri(ProviderKind.moonshot),
      'https://api.moonshot.cn/v1/chat/completions',
    );
    expect(
      uri(ProviderKind.moonshot, ProviderRegion.international),
      'https://api.moonshot.ai/v1/chat/completions',
    );
    expect(
      uri(ProviderKind.kimiCode),
      'https://api.kimi.com/coding/v1/chat/completions',
    );
    expect(
      uri(ProviderKind.kimiCode, ProviderRegion.international),
      'https://api.kimi.ai/coding/v1/chat/completions',
    );
    expect(
      uri(ProviderKind.deepseek),
      'https://api.deepseek.com/chat/completions',
    );
    // DeepSeek 不分区域：选国际也走同一个端点。
    expect(
      uri(ProviderKind.deepseek, ProviderRegion.international),
      'https://api.deepseek.com/chat/completions',
    );
    expect(
      uri(ProviderKind.zhipu),
      'https://open.bigmodel.cn/api/paas/v4/chat/completions',
    );
    // 编程订阅与按量接口是两个端点，Key 也不通用。
    expect(
      uri(ProviderKind.zhipuCoding),
      'https://open.bigmodel.cn/api/coding/paas/v4/chat/completions',
    );
    expect(
      uri(ProviderKind.zhipuCoding, ProviderRegion.international),
      'https://api.z.ai/api/coding/paas/v4/chat/completions',
    );
    expect(
      uri(ProviderKind.custom),
      'https://relay.example.com/v1/chat/completions',
    );
  });

  test('custom providers require an https base URL', () {
    for (final bad in [
      null,
      '',
      'http://relay.example.com/v1',
      ' https://a.b',
    ]) {
      expect(
        () => profile(ProviderKind.custom, 'm', baseUrl: bad),
        throwsA(isA<ModelFailure>()),
        reason: '$bad',
      );
    }
  });

  test('less-thinking intent is expressed per provider', () {
    JsonObject body(ModelProfile p) => ModelRequest(
      profile: p,
      messages: const [
        {'role': 'user', 'content': 'hi'},
      ],
    ).toJson();

    // 能关闭思考的：发 thinking.disabled。
    expect(body(profile(ProviderKind.deepseek, 'deepseek-flash'))['thinking'], {
      'type': 'disabled',
    });
    expect(
      body(profile(ProviderKind.kimiCode, 'kimi-for-coding'))['thinking'],
      {'type': 'disabled'},
    );
    // 不能关闭的：压到最低档，绝不发会被拒绝的 disabled。
    for (final p in [
      profile(ProviderKind.zhipuCoding, 'glm-5.3'),
      profile(ProviderKind.kimiCode, 'k3.1-pro'),
      profile(ProviderKind.kimiCode, 'k3'),
      profile(ProviderKind.moonshot, 'kimi-k3'),
      profile(ProviderKind.zhipu, 'glm-5.3-flash'),
    ]) {
      final json = body(p);
      expect(json.containsKey('thinking'), isFalse, reason: p.model);
      expect(json['reasoning_effort'], 'low', reason: p.model);
    }
    // 自定义接口能力未知：什么都不发。
    final custom = body(
      profile(ProviderKind.custom, 'x', baseUrl: 'https://relay.example.com'),
    );
    expect(custom.containsKey('thinking'), isFalse);
    expect(custom.containsKey('reasoning_effort'), isFalse);
    // 没有「少思考」意图时不发任何思考参数。
    final full = body(
      profile(ProviderKind.deepseek, 'deepseek-flash', minimal: false),
    );
    expect(full.containsKey('thinking'), isFalse);
    expect(full.containsKey('reasoning_effort'), isFalse);
  });

  test('run records keep their wire format and custom base URL', () {
    AgentRun run(ModelProfile p) => AgentRun(
      id: 'run_1',
      sessionId: 'session_1',
      inputId: 'input_1',
      profile: p,
      history: const [
        {'role': 'user', 'content': 'hi'},
      ],
    );
    final kimi = run(profile(ProviderKind.kimiCode, 'kimi-for-coding'));
    expect(kimi.toJson()['profile'], {
      'model': 'kimi-for-coding',
      'product': 'code',
      'region': 'china',
      'revision': 1,
      'disable_thinking': true,
    });
    expect(
      AgentRun.fromJson(kimi.toJson()).profile.product,
      ProviderKind.kimiCode,
    );
    final custom = run(
      profile(
        ProviderKind.custom,
        'x',
        baseUrl: 'https://relay.example.com/v1',
      ),
    );
    final restored = AgentRun.fromJson(custom.toJson());
    expect(restored.profile.baseUrl, 'https://relay.example.com/v1');
    expect(restored.profile.product, ProviderKind.custom);
  });

  test('model labels come from the catalog', () {
    expect(ProviderCatalog.modelLabel('kimi-for-coding'), 'Kimi K2.8');
    expect(ProviderCatalog.modelLabel('glm-5.3'), 'GLM-5.3');
    expect(ProviderCatalog.modelLabel('short-id'), 'short-id');
    expect(
      ProviderCatalog.modelLabel('a-very-long-unknown-model-identifier'),
      'a-very-long-unk…',
    );
  });
}

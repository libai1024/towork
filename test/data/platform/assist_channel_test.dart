import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/platform/assist_channel.dart';
import 'package:towork/domain/assist/quick_assist.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('towork/assist');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  late Map<String, Object?> replies;

  setUp(() {
    calls = [];
    replies = {};
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return replies[call.method];
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('没有快捷面板的平台不发起任何通道调用', () async {
    final assist = AssistChannel(supported: false);
    addTearDown(assist.dispose);
    expect(await assist.othersAlive(), isFalse);
    expect(await assist.takeHandoff(), isNull);
    expect((await assist.status()).supported, isFalse);
    expect(await assist.openPanel(), isFalse);
    final launch = await assist.launch();
    expect(launch.source, AssistSource.app);
    expect(launch.text, isEmpty);
    expect(launch.voice, isFalse);
    await assist.close();
    expect(calls, isEmpty);
  });

  test('分别固定快问和语音快问时保留所选入口', () async {
    final assist = AssistChannel(supported: true);
    addTearDown(assist.dispose);
    replies['pinShortcut'] = true;
    expect(await assist.pinShortcut(), isTrue);
    expect(await assist.pinShortcut(voice: true), isTrue);
    expect(calls.map((call) => call.method), ['pinShortcut', 'pinShortcut']);
    expect(calls.map((call) => call.arguments), [
      {'voice': false},
      {'voice': true},
    ]);
  });

  test('唤起信息：来源、带入文字、是否直接听写', () async {
    final assist = AssistChannel(supported: true);
    addTearDown(assist.dispose);
    replies['launch'] = {
      'source': 'selection',
      'text': '  周五下午三点开会  ',
      'voice': false,
    };
    var launch = await assist.launch();
    expect(launch.source, AssistSource.selection);
    expect(launch.text, '周五下午三点开会');
    expect(launch.voice, isFalse);

    replies['launch'] = {'source': 'voice', 'text': null, 'voice': true};
    launch = await assist.launch();
    expect(launch.source, AssistSource.voice);
    expect(launch.text, isEmpty);
    expect(launch.voice, isTrue);
  });

  test('未知来源按应用自身处理，超长文字截断', () async {
    final assist = AssistChannel(supported: true);
    addTearDown(assist.dispose);
    replies['launch'] = {'source': 'somewhere', 'text': '字' * 5000};
    final launch = await assist.launch();
    expect(launch.source, AssistSource.app);
    expect(launch.text, hasLength(AssistLaunch.maxText));

    replies['launch'] = 'not a map';
    expect((await assist.launch()).source, AssistSource.app);
  });

  test('面板开着时再次唤起会从事件流送达', () async {
    final assist = AssistChannel(supported: true);
    addTearDown(assist.dispose);
    final received = <AssistLaunch>[];
    final subscription = assist.relaunches.listen(received.add);
    addTearDown(subscription.cancel);
    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(
        const MethodCall('relaunch', {'source': 'share', 'text': '买牛奶'}),
      ),
      (_) {},
    );
    await pumpEventQueue();
    expect(received.single.source, AssistSource.share);
    expect(received.single.text, '买牛奶');
  });

  test('交接只接受应用内路径和非空会话', () async {
    final assist = AssistChannel(supported: true);
    addTearDown(assist.dispose);
    expect(await assist.takeHandoff(), isNull);

    replies['takeHandoff'] = {
      'sessionId': 's1',
      'location': '/settings/models',
    };
    var handoff = await assist.takeHandoff();
    expect(handoff!.sessionId, 's1');
    expect(handoff.location, '/settings/models');

    replies['takeHandoff'] = {
      'sessionId': '',
      'location': 'https://example.com',
    };
    handoff = await assist.takeHandoff();
    expect(handoff!.sessionId, isNull);
    expect(handoff.location, isNull);
  });

  test('另一个引擎是否活着、入口状态', () async {
    final assist = AssistChannel(supported: true);
    addTearDown(assist.dispose);
    replies['peers'] = 0;
    expect(await assist.othersAlive(), isFalse);
    replies['peers'] = 1;
    expect(await assist.othersAlive(), isTrue);

    replies['entryStatus'] = {'defaultAssistant': true, 'canPin': true};
    var status = await assist.status();
    expect(status.supported, isTrue);
    expect(status.defaultAssistant, isTrue);
    expect(status.canPin, isTrue);

    replies['entryStatus'] = {'defaultAssistant': null, 'canPin': false};
    status = await assist.status();
    expect(status.defaultAssistant, isNull);
    expect(status.canPin, isFalse);
  });

  test('窗口请求带上参数', () async {
    final assist = AssistChannel(supported: true);
    addTearDown(assist.dispose);
    await assist.hide('稍后查看');
    await assist.openApp(
      const AssistHandoff(sessionId: 's9', location: '/todos'),
      keepPanel: true,
    );
    await assist.close();
    expect(calls.map((call) => call.method), ['hide', 'openApp', 'close']);
    expect(calls[0].arguments, {'notice': '稍后查看'});
    expect(calls[1].arguments, {
      'sessionId': 's9',
      'location': '/todos',
      'keepPanel': true,
    });
  });

  test('原生侧没有实现或报错时按「没有」处理', () async {
    final assist = AssistChannel(supported: true);
    addTearDown(assist.dispose);
    messenger.setMockMethodCallHandler(channel, null);
    expect(await assist.othersAlive(), isFalse);
    expect(await assist.takeHandoff(), isNull);
    expect((await assist.status()).supported, isFalse);

    messenger.setMockMethodCallHandler(
      channel,
      (call) async => throw PlatformException(code: 'boom'),
    );
    expect(await assist.pinShortcut(), isFalse);
    expect(await assist.openAssistantSettings(), isFalse);
  });
}

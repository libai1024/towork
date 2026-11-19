import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/attachment_provider.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/attachment_store.dart';
import 'package:towork/data/platform/mobile_media_picker.dart';
import 'package:towork/domain/attachments/local_image.dart';
import 'package:towork/features/chat/widgets/chat_input_bar.dart';
import 'package:towork/theme/app_theme.dart';

import '../../support/free/image_fixture.dart';

/// 无 IO 的附件库替身：只覆盖输入栏用到的三个入口
///（in-memory 数据库从不查询，仅满足构造签名）。
class _FakeStore extends AttachmentStore {
  _FakeStore(this.png)
    : super(
        AppDatabase(NativeDatabase.memory()),
        Directory('.'),
        _NoopPreparer(),
      );

  final Uint8List png;
  int imports = 0;
  int removals = 0;

  @override
  Future<ImageAttachment> importForChat(SelectedImage selected) async {
    imports++;
    return ImageAttachment(
      id: 'image_chat_1',
      inputId: 'image_input_chat_1',
      tableId: '',
      displayName: selected.name,
      mime: 'image/png',
      originalHash: 'h1',
      originalSize: selected.bytes.length,
      modelHash: 'h2',
      modelSize: png.length,
      width: 320,
      height: 160,
      state: 'ready',
      createdAt: 0,
    );
  }

  @override
  Future<Uint8List> bytes(String id, {bool original = false}) async => png;

  @override
  Future<void> removeDraft(String id) async => removals++;
}

class _NoopPreparer implements ImagePreparer {
  @override
  Future<PreparedImage> prepare(Uint8List bytes) async {
    throw StateError('unused');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeStore store;
  late TextEditingController text;
  late FocusNode focus;
  late List<(String, String?, String?)> sent;

  setUp(() async {
    store = _FakeStore(await syntheticImage());
    text = TextEditingController();
    focus = FocusNode();
    sent = [];
  });
  tearDown(() {
    text.dispose();
    focus.dispose();
  });

  Future<void> mount(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attachmentStoreProvider.overrideWith((ref) async => store),
          imageSelectorProvider.overrideWith(
            (ref) => FixtureImageSelector(store.png),
          ),
          mobileImagePickerProvider.overrideWithValue(null),
          textFileSelectorProvider.overrideWith(
            (ref) => _FakeTextSelector('读书笔记.txt', '第一行：读书\n第二行：思考'),
          ),
          chatAttachmentsEnabledProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ChatInputBar(
                controller: text,
                focusNode: focus,
                isGenerating: false,
                onSend: () {},
                onStop: () {},
                mobile: true,
                onSendMessage: (content, inputId, attachmentId) async {
                  sent.add((content, inputId, attachmentId));
                  return true;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('图片附件：选择 → 待发条 → 发送回调带附件', (tester) async {
    await mount(tester);
    await tester.tap(find.byTooltip('添加附件'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('attachment-source-拍照')),
      findsNothing,
      reason: '桌面无相机入口',
    );
    await tester.tap(find.byKey(const ValueKey('attachment-source-选择图片')));
    await tester.pumpAndSettle();

    expect(store.imports, 1);
    expect(
      find.byKey(const ValueKey('pending-attachment-chip')),
      findsOneWidget,
    );
    expect(find.text('验收发票.png'), findsOneWidget);
    // 待发附件本身即可发送。
    expect(find.byTooltip('发送消息'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('chat-text-input')),
      '这是什么',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('发送消息'));
    await tester.pumpAndSettle();

    expect(sent, hasLength(1));
    final (content, inputId, attachmentId) = sent.single;
    expect(content, '图片「验收发票.png」：这是什么');
    expect(inputId, 'image_input_chat_1');
    expect(attachmentId, 'image_chat_1');
    // 发送成功后清空输入与待发条。
    expect(text.text, isEmpty);
    expect(find.byKey(const ValueKey('pending-attachment-chip')), findsNothing);
  });

  testWidgets('文本文件附件：内容内联，附件 id 为空', (tester) async {
    await mount(tester);
    await tester.tap(find.byTooltip('添加附件'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('attachment-source-文本文件')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('pending-attachment-chip')),
      findsOneWidget,
    );
    expect(find.text('读书笔记.txt'), findsOneWidget);
    await tester.tap(find.byTooltip('发送消息'));
    await tester.pumpAndSettle();

    expect(sent, hasLength(1));
    final (content, inputId, attachmentId) = sent.single;
    expect(content, contains('文件「读书笔记.txt」的内容'));
    expect(content, contains('第一行：读书'));
    expect(inputId, isNull);
    expect(attachmentId, isNull);
  });

  testWidgets('移除待发图片清空状态并清理暂存', (tester) async {
    await mount(tester);
    await tester.tap(find.byTooltip('添加附件'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('attachment-source-选择图片')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('pending-attachment-chip')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('remove-attachment')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pending-attachment-chip')), findsNothing);
    expect(store.removals, 1, reason: '未发送的图片附件应清理暂存');
    expect(find.byTooltip('发送消息'), findsNothing, reason: '无输入无附件不可发送');
  });

  testWidgets('待发附件条有单一语义播报，移除按钮独立可聚焦', (tester) async {
    final semantics = tester.ensureSemantics();
    await mount(tester);
    await tester.tap(find.byTooltip('添加附件'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('attachment-source-选择图片')));
    await tester.pumpAndSettle();

    // 读屏：图片缩略图与文件名合并播报为一个「待发送附件」节点。
    expect(find.bySemanticsLabel('待发送附件：验收发票.png'), findsOneWidget);
    // 移除按钮是独立焦点；去除外包 Tooltip 后只剩一层语义。
    expect(find.byTooltip('移除附件'), findsOneWidget);
    semantics.dispose();
  });
}

class _FakeTextSelector extends TextFileSelector {
  _FakeTextSelector(this.name, this.content);
  final String name;
  final String content;
  @override
  Future<SelectedTextFile?> select() async => SelectedTextFile(name, content);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/domain/models/chat.dart';
import 'package:towork/domain/chat/chat_question.dart';
import 'package:towork/features/chat/chat_message_layout.dart';

ChatMessage _msg(
  String id,
  ChatMessageType type, {
  ChatRole role = ChatRole.assistant,
  DateTime? createdAt,
  String? todoId,
  String? runId,
}) => ChatMessage(
  id: id,
  sessionId: 's1',
  role: role,
  type: type,
  content: '',
  createdAt: createdAt ?? DateTime(2026, 9, 25, 10),
  todoId: todoId,
  runId: runId,
);

void main() {
  test(
    'question cards keep context and omit duplicate prompts in the same run',
    () {
      final question = ChatQuestion(
        question: '是哪件事？可以在选项里选，也可以直接补充说明是哪件事。',
        options: ['报销', '工资'],
      );
      final card = ChatMessage(
        id: 'q',
        sessionId: 's1',
        role: ChatRole.assistant,
        type: ChatMessageType.question,
        content: question.question,
        runId: 'r',
        createdAt: DateTime(2026),
        question: question,
      );
      final lead = _msg('a', ChatMessageType.text, runId: 'r');
      expect(question.displayTitle, '是哪件事？');
      final rows = layoutChatMessages([
        lead.copyWith(content: '这两项待办都在今天截止。是哪件事？'),
        card,
      ]);
      expect(rows.first.message.content, '这两项待办都在今天截止。');
      expect(rows.last.replyText, '这两项待办都在今天截止。\n\n是哪件事？');
      expect(
        layoutChatMessages([lead.copyWith(content: question.question), card]),
        hasLength(1),
      );
      expect(question.leadingContext('我没找到这条待办，是想让我做什么？'), '我没找到这条待办。');
      expect(
        layoutChatMessages([
          _msg(
            'u',
            ChatMessageType.text,
            role: ChatRole.user,
          ).copyWith(content: question.question),
          card,
        ]),
        hasLength(2),
      );
      expect(question.answerText(['工资']), startsWith(question.question));
    },
  );
  test('一次运行创建多条待办时，全部行都能安全布局（回归：越界）', () {
    // 用户输入 → 助手文本 → agentRun 过程行，其后插入 3 张合成待办卡。
    // 展开列表比 messages 长 3；修复前 itemBuilder 用展开下标索引原始
    // messages 数组，第 messages.length+1 行开始 RangeError。
    final expanded = [
      _msg('u1', ChatMessageType.text, role: ChatRole.user),
      _msg('a1', ChatMessageType.text),
      _msg('r1', ChatMessageType.agentRun, runId: 'run1'),
      _msg('c1', ChatMessageType.todoCard, todoId: 't1', runId: 'run1'),
      _msg('c2', ChatMessageType.todoCard, todoId: 't2', runId: 'run1'),
      _msg('c3', ChatMessageType.todoCard, todoId: 't3', runId: 'run1'),
    ];
    final rows = layoutChatMessages(expanded, todoExists: (_) => true);
    expect(rows, hasLength(expanded.length));
    expect(rows[1].continuesReply, isTrue, reason: '助手文本与运行结果连读');
    expect(rows.map((r) => r.message.id), equals(expanded.map((m) => m.id)));
  });

  test('日期分隔基于展开列表的前驱，而不是原始消息数组', () {
    final day1 = DateTime(2026, 9, 24, 23, 58);
    final day2 = DateTime(2026, 9, 25, 0, 1);
    final expanded = [
      _msg('u1', ChatMessageType.text, role: ChatRole.user, createdAt: day1),
      _msg('r1', ChatMessageType.agentRun, runId: 'run1', createdAt: day2),
      // 合成卡与过程行同日：不应再插入日期分隔。
      _msg(
        'c1',
        ChatMessageType.todoCard,
        todoId: 't1',
        runId: 'run1',
        createdAt: day2,
      ),
    ];
    final rows = layoutChatMessages(expanded, todoExists: (_) => true);
    expect(rows.map((r) => r.showDate), [true, true, false]);
  });

  test('文本、过程与结果卡保持同一组紧凑间距', () {
    final expanded = [
      _msg('a1', ChatMessageType.text),
      _msg('c0', ChatMessageType.todoCard, todoId: 't0'), // 持久化卡：紧跟文本
      _msg('r1', ChatMessageType.agentRun, runId: 'run1'),
      _msg('c1', ChatMessageType.todoCard, todoId: 't1', runId: 'run1'),
    ];
    final rows = layoutChatMessages(expanded, todoExists: (_) => true);
    expect(rows[1].followsReply, isTrue, reason: '持久化卡前驱是助手文本');
    expect(rows[3].followsReply, isTrue, reason: '结果卡与过程行属于同一组');
    expect(rows[2].continuesReply, isTrue);
  });

  test('已被删除的待办卡不计入 continuesReply', () {
    final expanded = [
      _msg('a1', ChatMessageType.text),
      _msg('c1', ChatMessageType.todoCard, todoId: 't1'),
      _msg('c2', ChatMessageType.todoCard, todoId: 'gone'),
    ];
    final rows = layoutChatMessages(expanded, todoExists: (id) => id != 'gone');
    expect(rows[0].continuesReply, isTrue, reason: '下一条卡对应待办仍存在');
    // 已删除的卡片先过滤，最后一个可见结果承接整轮操作。
    expect(rows[1].continuesReply, isFalse, reason: '待办卡后继是另一张卡');
    expect(rows, hasLength(2), reason: '已删除的卡片不占行和间距');
    expect(rows.last.replyText, isNotNull);
  });

  test('同轮多个文本只有一个完整回复尾部，下一轮独立', () {
    final rows = layoutChatMessages([
      _msg('u1', ChatMessageType.text, role: ChatRole.user),
      _msg('a1', ChatMessageType.text, runId: 'r1').copyWith(content: '先查询。'),
      _msg('a2', ChatMessageType.text, runId: 'r1').copyWith(content: '查询结果。'),
      _msg('r1', ChatMessageType.agentRun, runId: 'r1'),
      _msg('u2', ChatMessageType.text, role: ChatRole.user),
      _msg('a3', ChatMessageType.text).copyWith(content: '下一轮。'),
    ]);
    expect(rows.where((r) => r.replyText != null).map((r) => r.replyText), [
      '先查询。\n\n查询结果。',
      '下一轮。',
    ]);
    expect(rows[2].followsReply, isTrue);
    expect(rows[1].replyText, isNull);
  });

  test('历史消息缺少 runId 时按用户边界归组，显式不同运行保持独立', () {
    final rows = layoutChatMessages([
      _msg('a1', ChatMessageType.text).copyWith(content: '旧文本'),
      _msg(
        'a2',
        ChatMessageType.text,
      ).copyWith(content: '旧结果', stoppedByUser: true),
      _msg('r1', ChatMessageType.agentRun, runId: 'r1'),
      _msg('a3', ChatMessageType.text, runId: 'r2').copyWith(content: '新结果'),
    ]);
    expect(rows.where((r) => r.replyText != null), hasLength(2));
    expect(rows[2].replyText, '旧文本\n\n旧结果');
    expect(rows[2].stopped, isTrue);
    expect(rows[3].followsReply, isFalse);
  });

  test('隐藏卡片后复制操作仍落在最后一个可见文本上', () {
    final rows = layoutChatMessages([
      _msg('a', ChatMessageType.text).copyWith(content: '结果'),
      _msg('c', ChatMessageType.todoCard, todoId: 'gone'),
      _msg('d', ChatMessageType.dataWriteCard),
    ], todoExists: (_) => false);
    expect(rows, hasLength(1));
    expect(rows.single.replyText, '结果');
    expect(rows.single.continuesReply, isFalse);
  });

  test('空列表与单条消息', () {
    expect(layoutChatMessages(const []), isEmpty);
    final rows = layoutChatMessages([
      _msg('u1', ChatMessageType.text, role: ChatRole.user),
    ]);
    expect(rows.single.showDate, isTrue);
    expect(rows.single.followsReply, isFalse);
    expect(rows.single.continuesReply, isFalse);
  });
}

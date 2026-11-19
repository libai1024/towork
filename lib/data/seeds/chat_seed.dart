import '../../domain/models/models.dart';

List<ChatSession> seedSessions(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return [
    ChatSession(
      id: 's1',
      title: '明天的工作台',
      createdAt: today.subtract(const Duration(hours: 4)),
      updatedAt: today.add(const Duration(hours: 9, minutes: 12)).isAfter(now)
          ? now.subtract(const Duration(hours: 2))
          : today.add(const Duration(hours: 9, minutes: 12)),
      lastMessagePreview: '已为你建好这条待办：发送季度报告给王总',
    ),
    ChatSession(
      id: 's2',
      title: '上周买了哪些股票',
      createdAt: today.subtract(const Duration(days: 1, hours: 3)),
      updatedAt: today.subtract(const Duration(days: 1, hours: 2)),
      lastMessagePreview: '上周你记录了 2 笔交易：卖出贵州茅台 500 股…',
    ),
    ChatSession(
      id: 's3',
      title: '物业费与年检',
      createdAt: today.subtract(const Duration(days: 3)),
      updatedAt: today.subtract(const Duration(days: 3, hours: 1)),
      lastMessagePreview: '两件事都记在「家庭」里了，年检月底到期，别拖。',
    ),
    ChatSession(
      id: 's4',
      title: '档案接收登记流程',
      createdAt: today.subtract(const Duration(days: 4)),
      updatedAt: today.subtract(const Duration(days: 4, hours: 5)),
      lastMessagePreview: '接收登记表我建好了，字段：档号、题名、年度…',
    ),
    ChatSession(
      id: 's5',
      title: '宁德时代的止损线',
      createdAt: today.subtract(const Duration(days: 6)),
      updatedAt: today.subtract(const Duration(days: 6, hours: 2)),
      lastMessagePreview: '跌破 180 减仓一半，写进交易计划了。',
    ),
    ChatSession(
      id: 's6',
      title: '妈妈的体检安排',
      createdAt: today.subtract(const Duration(days: 8)),
      updatedAt: today.subtract(const Duration(days: 8, hours: 6)),
      lastMessagePreview: '体检报告出来后提醒我陪她去复诊。',
    ),
    ChatSession(
      id: 's7',
      title: '库房温湿度记录',
      createdAt: today.subtract(const Duration(days: 10)),
      updatedAt: today.subtract(const Duration(days: 10, hours: 3)),
      lastMessagePreview: '库房每天两次温湿度登记，做成数据表了。',
    ),
    ChatSession(
      id: 's8',
      title: '可转债打新是什么',
      createdAt: today.subtract(const Duration(days: 12)),
      updatedAt: today.subtract(const Duration(days: 12, hours: 1)),
      lastMessagePreview: '简单说，打新债是低门槛的抽奖…',
    ),
    ChatSession(
      id: 's9',
      title: '周报怎么写更快',
      createdAt: today.subtract(const Duration(days: 14)),
      updatedAt: today.subtract(const Duration(days: 14, hours: 4)),
      lastMessagePreview: '以后每周五下午我帮你拉数据出草稿。',
    ),
    ChatSession(
      id: 's10',
      title: '老照片扫描归档方案',
      createdAt: today.subtract(const Duration(days: 16)),
      updatedAt: today.subtract(const Duration(days: 16, hours: 2)),
      lastMessagePreview: '先按年份分袋，再扫 600dpi，文件名加日期前缀。',
    ),
  ];
}

Map<String, List<ChatMessage>> seedMessages(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return {
    's1': [
      ChatMessage(
        id: 'm_seed_1',
        sessionId: 's1',
        role: ChatRole.user,
        type: ChatMessageType.text,
        content: '提醒我明天下午三点前把季度报告发给王总',
        createdAt: today.add(const Duration(hours: 9, minutes: 12)),
      ),
      ChatMessage(
        id: 'm_seed_1r',
        sessionId: 's1',
        role: ChatRole.assistant,
        type: ChatMessageType.todoCard,
        content: '已为你建好这条待办：',
        todoId: 't1',
        modelId: 'k3-256k',
        durationMs: 2300,
        createdAt: today.add(const Duration(hours: 9, minutes: 12, seconds: 3)),
      ),
    ],
    's2': [
      ChatMessage(
        id: 'm_seed_2',
        sessionId: 's2',
        role: ChatRole.user,
        type: ChatMessageType.text,
        content: '我上周买了哪些股票？',
        createdAt: today.subtract(const Duration(days: 1, hours: 2)),
      ),
      ChatMessage(
        id: 'm_seed_2r',
        sessionId: 's2',
        role: ChatRole.assistant,
        type: ChatMessageType.text,
        content: '上周你的「股票持仓」表里有 2 笔变动：卖出贵州茅台 500 股（1652.00）、加仓宁德时代 200 股（186.40）。买入只有宁德时代一笔。',
        modelId: 'k3-256k',
        durationMs: 1800,
        createdAt: today
            .subtract(const Duration(days: 1, hours: 2))
            .add(const Duration(seconds: 4)),
      ),
    ],
    's5': [
      ChatMessage(
        id: 'm_seed_3',
        sessionId: 's5',
        role: ChatRole.user,
        type: ChatMessageType.text,
        content: '提醒我收盘后复盘宁德时代走势，更新持仓表',
        createdAt: today.add(const Duration(hours: 9, minutes: 30)),
      ),
      ChatMessage(
        id: 'm_seed_3r',
        sessionId: 's5',
        role: ChatRole.assistant,
        type: ChatMessageType.todoCard,
        content: '已为你建好这条待办：',
        todoId: 't3',
        modelId: 'k3-256k',
        durationMs: 1600,
        createdAt: today
            .add(const Duration(hours: 9, minutes: 30))
            .add(const Duration(seconds: 3)),
      ),
    ],
  };
}

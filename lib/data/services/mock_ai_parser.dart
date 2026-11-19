import '../../domain/models/chat_reply.dart';

/// Deterministic demonstration parser, isolated from presentation widgets.
class MockAiParser {
  MockAiParser._();

  static const _todoKeywords = [
    '提醒',
    '明天',
    '下周',
    '后天',
    '月底',
    '买',
    '交',
    '还',
    '缴',
    '预约',
    '记得',
    '截止',
    '安排',
    '复盘',
    '待办',
    '任务',
    '计划',
  ];

  static const _queryKeywords = [
    '哪些',
    '什么',
    '多少',
    '怎么',
    '吗',
    '呢',
    '？',
    '?',
    '查一下',
    '看看',
  ];

  static ChatReply respond(String input, {required DateTime now}) {
    final text = input.trim();
    if (text.contains('[演示附件：')) {
      return const ChatReply(
        text: '已收到这份示例资料。你可以将它关联到工作分类，或让我整理成待办。\n\n这是附件流程演示，没有上传文件或进行真实内容识别。',
      );
    }
    // Explicit task commands take precedence over topic-based shortcuts.
    if (_taskCommand.hasMatch(text)) {
      return ChatReply(text: '已为你建好这条待办：', draft: _parseDraft(text, now));
    }
    if (text.contains('这周') || text.contains('周报')) {
      return const ChatReply(
        text: '这周可以按三个方向整理：\n\n1. 档案工作：接收登记、借阅归还与季度报告。\n2. 工作安排：项目评审、会议纪要和下周计划。\n3. 个人事务：家庭提醒与交易复盘。\n\n打开侧栏「报告」，可以查看完整示例周报，也可以选择分类生成新的 mock 报告。',
      );
    }
    if (text.startsWith('记住')) {
      return const ChatReply(
        text: '这是一条值得保存的偏好。打开侧栏「记忆库」→「记一条」，就能把它保存到本次演示的记忆中，之后也可以编辑或归档。',
      );
    }
    final isQuery = _queryKeywords.any(text.contains);
    if (isQuery) return _query(text);
    final isTodo = _todoKeywords.any(text.contains);
    if (isTodo) {
      return ChatReply(text: '已为你建好这条待办：', draft: _parseDraft(text, now));
    }
    return const ChatReply(
      text:
          '嗯，我在。想让这句话变成待办的话，加个时间就行，'
          '比如「明天下午三点前把报告发给王总」。',
    );
  }

  static ChatReply _query(String text) {
    if (text.contains('待办')) {
      return const ChatReply(
        text: '今天可以先处理季度报告、档案接收登记，再预留时间完成项目评审。\n\n在「待办总览」选择「今天」，可以查看当前示例任务并标记完成；新增或改期后，列表会同步更新。',
      );
    }
    if (text.contains('股票') || text.contains('股') || text.contains('持仓')) {
      return const ChatReply(
        text:
            '你的「股票账户」最近有 2 笔变动：卖出贵州茅台 500 股（1652.00）、'
            '现价更新宁德时代 186.40。目前持有宁德时代 1200 股、贵州茅台 300 股、比亚迪 500 股。',
      );
    }
    if (text.contains('档案') || text.contains('接收')) {
      return const ChatReply(
        text:
            '「档案接收记录」最近一条是 JS-2026-0031《退休干部人事档案（第三批）》，'
            '12 卷，今天登记入库。',
      );
    }
    if (text.contains('额度') || text.contains('用量')) {
      return const ChatReply(
        text:
            '按应用侧自统计：5 小时窗口用了 32%，本周 58%，本月 41%。'
            '精确额度以 Kimi Console 为准。',
      );
    }
    return const ChatReply(
      text:
          '这个问题我还在学习怎么答得更准。'
          '换个问法试试，或者直接让我把相关的事记成待办。',
    );
  }

  static final _taskCommand = RegExp(
    r'^(?:(?:请|麻烦|帮我)\s*)*(?:提醒我?|记得|(?:添加|新建|创建)(?:一条)?待办)',
  );
  static final _prefix = RegExp(
    r'^(?:(?:请|麻烦|帮我|我要)\s*)*(?:(?:提醒我?|记得|(?:添加|新建|创建)(?:一条)?待办)\s*)?',
  );
  static final _dayPattern = RegExp(r'(明天|后天|今天|今晚|下周[一二三四五六日天]?|月底)前?');
  // Deliberately small grammar: Chinese/Arabic hours, half hours and explicit
  // minute values. Long/out-of-range numbers are consumed and rejected as one
  // token instead of accidentally matching their final digit.
  static final _timePattern = RegExp(
    r'(凌晨|早上|上午|中午|下午|晚上|今晚)?\s*'
    r'([+-]?[零〇一二两三四五六七八九十百千0-9.]+)点'
    r'(?:(半)|([零〇一二两三四五六七八九十百千0-9]+)分)?',
  );

  static TodoDraft _parseDraft(String text, DateTime now) {
    final dueAt = _parseDue(text, now);
    return TodoDraft(
      // Keep unparsed/invalid date text so the user can correct the draft.
      title: _cleanTitle(text, removeTime: dueAt != null),
      dueAt: dueAt,
      categoryId: _guessCategory(text),
    );
  }

  static String _cleanTitle(String text, {required bool removeTime}) {
    var title = text.replaceFirst(_prefix, '');
    if (removeTime) {
      title = title.replaceAllMapped(_timePattern, (_) => '');
      title = title.replaceAll(_dayPattern, '');
      title = title.replaceFirst(RegExp(r'^\s*前'), '');
    }
    title = title.replaceAll(RegExp(r'^[，,。.！!的\s]+|[，,。.！!\s]+$'), '');
    return title.isEmpty ? text : title;
  }

  static DateTime? _parseDue(String text, DateTime now) {
    DateTime date(
      int year,
      int month,
      int day, [
      int hour = 0,
      int minute = 0,
    ]) => now.isUtc
        ? DateTime.utc(year, month, day, hour, minute)
        : DateTime(year, month, day, hour, minute);

    DateTime? day;
    if (text.contains('明天')) {
      day = date(now.year, now.month, now.day + 1);
    } else if (text.contains('后天')) {
      day = date(now.year, now.month, now.day + 2);
    } else if (text.contains('下周')) {
      const weekdays = {
        '一': 1,
        '二': 2,
        '三': 3,
        '四': 4,
        '五': 5,
        '六': 6,
        '日': 7,
        '天': 7,
      };
      final match = RegExp(r'下周([一二三四五六日天])').firstMatch(text);
      final days = match == null
          ? 7
          : 7 - now.weekday + weekdays[match.group(1)]!;
      day = date(now.year, now.month, now.day + days);
    } else if (text.contains('月底')) {
      day = date(now.year, now.month + 1, 0);
    } else if (text.contains('今天') || text.contains('今晚')) {
      day = date(now.year, now.month, now.day);
    }
    if (day == null) return null;

    var hour = 18;
    var minute = 0;
    var dayOffset = 0;
    final times = _timePattern.allMatches(text).toList();
    // A time range or multiple times is outside this demonstration grammar.
    if (times.length > 1) return null;
    if (times.isNotEmpty) {
      final match = times.single;
      final parsedHour = _cnNum(match.group(2)!);
      final parsedMinute = match.group(3) != null
          ? 30
          : match.group(4) == null
          ? 0
          : _cnNum(match.group(4)!);
      if (parsedHour == null ||
          parsedHour < 0 ||
          parsedHour > 23 ||
          parsedMinute == null ||
          parsedMinute < 0 ||
          parsedMinute > 59) {
        return null;
      }
      hour = parsedHour;
      minute = parsedMinute;
      final period = match.group(1) ?? (text.contains('今晚') ? '今晚' : null);
      if (period == '晚上' || period == '今晚') {
        // "明天晚上十二点" is the midnight after tomorrow's evening.
        if (hour == 12 || hour == 0) {
          hour = 0;
          dayOffset = 1;
        } else if (hour < 12) {
          hour += 12;
        }
      } else if (period == '下午' || period == '中午') {
        if (hour < 12) hour += 12;
      } else if (period == '凌晨') {
        if (hour > 12) return null;
        if (hour == 12) hour = 0;
      } else if ((period == '上午' || period == '早上') && hour > 12) {
        return null;
      }
    }
    return date(day.year, day.month, day.day + dayOffset, hour, minute);
  }

  static int? _cnNum(String value) {
    final arabic = int.tryParse(value);
    if (arabic != null) return arabic;
    const digits = {
      '零': 0,
      '〇': 0,
      '一': 1,
      '二': 2,
      '两': 2,
      '三': 3,
      '四': 4,
      '五': 5,
      '六': 6,
      '七': 7,
      '八': 8,
      '九': 9,
    };
    if (digits.containsKey(value)) return digits[value];
    final tens = RegExp(r'^([一二两三四五六七八九])?十([一二三四五六七八九])?$').firstMatch(value);
    if (tens == null) return null;
    return (tens.group(1) == null ? 1 : digits[tens.group(1)]!) * 10 +
        (tens.group(2) == null ? 0 : digits[tens.group(2)]!);
  }

  static String? _guessCategory(String text) {
    bool hasAny(List<String> words) => words.any(text.contains);
    if (hasAny(['止损', '交易计划', '打新'])) return 'cat_stock_plan';
    if (hasAny(['买', '卖', '持仓', '复盘', '加仓', '减仓'])) {
      if (hasAny(['股', '宁德', '茅台', '比亚迪', '票'])) return 'cat_stock_position';
    }
    if (hasAny(['股票', '宁德', '茅台', '比亚迪', '大盘'])) return 'cat_stock';
    if (hasAny(['借', '还']) && hasAny(['档案', '卷', '馆'])) {
      return 'cat_archive_lend';
    }
    if (hasAny(['接收', '登记', '入库', '移交'])) return 'cat_archive_in';
    if (hasAny(['档案', '馆里', '库房', '案卷'])) return 'cat_archive';
    if (hasAny(['妈妈', '爸', '家', '物业', '年检', '水电', '体检', '水龙头'])) {
      return 'cat_family';
    }
    if (hasAny(['报告', '王总', '工作', '周报', '项目', '会议', '汇报'])) {
      return 'cat_work';
    }
    return null;
  }
}

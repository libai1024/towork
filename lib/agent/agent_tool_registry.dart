import '../domain/ai/agent_run.dart';
import '../domain/ai/model_gateway.dart';
import '../domain/workspace/workspace_commands.dart';
import 'tools/calculator_tool.dart';
import 'tools/calendar_tool.dart';
import 'tools/todo_stats_tool.dart';
import 'tools/todo_panel_tool.dart';
import 'tools/question_tool.dart';

/// 只读工具执行时能看到的全部环境：一份已提交快照和时钟。
/// 没有数据库句柄、没有网络——这类工具因此可以在提案事务内同步求值。
class AgentToolContext {
  const AgentToolContext({
    required this.snapshot,
    required this.now,
    required this.localOffset,
  });
  final WorkspaceSnapshot snapshot;

  /// UTC。
  final DateTime now;

  /// 设备当前相对 UTC 的偏移，用来划分「今天」「本周」。
  final Duration localOffset;
}

/// 一个确定性的只读工具：不写库、不联网、同样的输入给出同样的结果。
///
/// 新增这类能力只需实现本接口并登记到 [AgentToolRegistry.readTools]；
/// 提案、审批、回执链路都不用改。参数不合法时抛 [AgentFailure]，
/// 可预期的业务性失败（如除以零）用带 `error` 字段的结果返回给模型。
abstract interface class AgentReadTool {
  String get name;

  /// OpenAI 兼容的 function schema。
  JsonObject get schema;

  Object? call(JsonObject args, AgentToolContext context);
}

class AgentToolRegistry {
  static final List<AgentReadTool> readTools = List.unmodifiable([
    const CalculatorTool(),
    const CalendarTool(),
    const TodoStatsTool(),
    const TodoPanelTool(),
    const TodoPanelTool(overview: true),
    const QuestionTool(),
  ]);

  static final Map<String, AgentReadTool> _byName = {
    for (final tool in readTools) tool.name: tool,
  };

  static List<JsonObject> get schemas => [
    for (final tool in readTools) tool.schema,
  ];

  static AgentReadTool? read(Object? name) => _byName[name];
}

/// 工具 schema 的统一写法。
JsonObject agentToolSchema(
  String name,
  String description,
  JsonObject properties, {
  List<String> required = const [],
}) => immutableJson({
  'type': 'function',
  'function': {
    'name': name,
    'description': description,
    'parameters': {
      'type': 'object',
      'properties': properties,
      'required': required,
      'additionalProperties': false,
    },
  },
});

/// 参数键校验：出现未知键或缺少必填键都算模型调用错误。
void requireToolKeys(
  JsonObject args,
  Set<String> allowed, {
  Set<String> required = const {},
}) {
  if (args.keys.any((key) => !allowed.contains(key)) ||
      required.any((key) => !args.containsKey(key))) {
    throw const AgentFailure(AgentFailureCode.invalid);
  }
}

import '../data/local/workspace_model_codec.dart';
import '../domain/models/models.dart';

/// 一键导出的备份内容（app 层组装，供设置页调用）。
/// 待办/分类复用工作区编解码的完整结构；其余存储给摘要，
/// 文件保持真实可读且不包含任何凭据。
Map<String, Object?> buildBackupPayload({
  required List<Todo> todos,
  required List<Category> categories,
  required List<ChatSession> sessions,
  required List<MemoryEntry> memories,
  required List<Report> reports,
  required List<DataTableDef> tables,
  required int dataRows,
}) {
  return {
    'app': 'ToWork',
    'schema': 1,
    'exported_at': DateTime.now().toIso8601String(),
    'todos': [for (final todo in todos) todoWorkspaceData(todo)],
    'categories': [
      for (final category in categories) categoryWorkspaceData(category),
    ],
    'chat_sessions': [
      for (final session in sessions)
        {
          'id': session.id,
          'title': session.title,
          'updated_at': session.updatedAt.toIso8601String(),
        },
    ],
    'memories': [
      for (final memory in memories)
        {'id': memory.id, 'content': memory.content},
    ],
    'reports': [
      for (final report in reports)
        {'id': report.id, 'title': report.title, 'status': report.status.name},
    ],
    'data_tables': [
      for (final table in tables) {'id': table.id, 'name': table.name},
    ],
    'counts': {
      'todos': todos.length,
      'categories': categories.length,
      'chat_sessions': sessions.length,
      'memories': memories.length,
      'reports': reports.length,
      'data_rows': dataRows,
    },
  };
}

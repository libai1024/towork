import 'package:flutter_test/flutter_test.dart';
import 'package:towork/domain/ai/permission_policy.dart';

void main() {
  // Product acceptance matrix. Read operations never await write approval.
  const matrix = {
    AiWritePermission.askAll: [false, true, true, true, true],
    AiWritePermission.askOnChange: [false, false, false, false, true],
    AiWritePermission.auto: [false, false, false, false, false],
  };
  for (final mode in matrix.entries) {
    for (final operation in AgentOperation.values) {
      test('${mode.key.name} / ${operation.name}', () {
        expect(
          evaluatePermission(mode.key, operation),
          mode.value[operation.index]
              ? PermissionDecision.confirm
              : PermissionDecision.execute,
        );
      });
    }
  }
}

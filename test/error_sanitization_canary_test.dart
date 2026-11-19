import 'package:flutter_test/flutter_test.dart';
import 'package:towork/core/agent/agent_run_card.dart';
import 'package:towork/features/chat/widgets/chat_input_bar.dart';

/// 错误脱敏 canary：UI 边界文案永不携带原始异常。
/// 覆盖三处出口——chatFailureMessage（异常 → 文案）、
/// runFailureMessage（失败码 → 文案）、speechProblemMessage（语音
/// problem 白名单）。真实泄漏物（API Key、绝对路径、上游 JSON）
/// 用一个合成字符串模拟。
void main() {
  const leaked =
      'NoSuchFileException: /Users/fixture/secret/credentials.json '
      'Bearer sk-abcdef1234567890 upstream body '
      '{"error":{"message":"Invalid API key provided","code":401}}';

  test('chatFailureMessage never surfaces raw error text', () {
    final messages = [
      chatFailureMessage(leaked),
      chatFailureMessage(Exception(leaked)),
      chatFailureMessage(StateError(leaked)),
    ];
    expect(messages, isNotEmpty);
    for (final message in messages) {
      expect(message, isNot(contains('sk-abcdef1234567890')));
      expect(message, isNot(contains('/Users/fixture')));
      expect(message, isNot(contains('{"error"')));
      expect(message, isNot(contains('Invalid API key')));
      expect(message, isNot(contains(leaked)));
    }
  });

  test('runFailureMessage never surfaces raw failure codes', () {
    final messages = [
      runFailureMessage(leaked),
      runFailureMessage('unreviewed_future_code'),
      runFailureMessage(null),
    ];
    for (final message in messages) {
      expect(message, isNot(contains('sk-abcdef1234567890')));
      expect(message, isNot(contains('/Users/fixture')));
      expect(message, isNot(contains('{"error"')));
      expect(message, isNot(contains('unreviewed_future_code')));
    }
  });

  test('speechProblemMessage passes only allow-listed local copy', () {
    // 已知稳定文案原样放行（Toast 提示语义不变）。
    expect(speechProblemMessage('发送失败，文字已保留'), '发送失败，文字已保留');
    expect(speechProblemMessage('没有听清，请再说一次'), '没有听清，请再说一次');
    // 未知/原始异常一律退回通用文案。
    const fallback = '语音输入遇到问题，已保留识别文字';
    expect(speechProblemMessage(null), fallback);
    for (final message in [
      speechProblemMessage(leaked),
      speechProblemMessage('Bad state: Future already completed'),
    ]) {
      expect(message, fallback);
      expect(message, isNot(contains('sk-')));
      expect(message, isNot(contains('/Users')));
      expect(message, isNot(contains('{')));
    }
  });
}

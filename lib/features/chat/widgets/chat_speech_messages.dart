/// 语音 problem 的上屏白名单（错误脱敏边界）：
/// 只有语音链路已知的稳定本地文案允许进 Toast；未知字符串
/// （误传的原始异常、未来新增未复核的文案）一律退回通用文案，
/// 与 [chatFailureMessage] 的「未知错误不透传」同一策略。
const _stableSpeechProblems = <String>{
  '语音输入已中断',
  '语音输入未能启动',
  '没有听清，请再说一次',
  '转写过长，请分成几条指令。',
  '识别超时，请再说一次',
  '发送失败，文字已保留',
  '请在系统设置中允许麦克风权限',
  '暂不支持所选语言',
  '当前识别器不支持设备端模式，不会自动切换到联网识别。',
  '语音服务连接失败',
  '麦克风正在使用中',
  '录音已中断',
  '语音输入暂不可用',
};

String speechProblemMessage(String? problem) =>
    problem != null && _stableSpeechProblems.contains(problem)
    ? problem
    : '语音输入遇到问题，已保留识别文字';

import '../../domain/ai/model_gateway.dart';
import '../../domain/settings/model_settings.dart';

/// 模型账户相关错误的用户文案，账户列表、编辑页和模型选择器共用。
/// 只映射类型化错误码，绝不显示服务商返回的原文。
String describeModelSettingsError(Object error) => switch (error) {
  SettingsFailure(:final code) => switch (code) {
    SettingsFailureCode.validation => '请输入有效的 Key，不要包含空格或换行',
    SettingsFailureCode.credentials => '系统安全存储暂不可用，请解锁设备后重试',
    SettingsFailureCode.conflict => '配置已变化，请重新载入后再操作',
    SettingsFailureCode.missingKey => '请为所选服务商和区域填写 Key',
    SettingsFailureCode.storage => '本地配置暂时无法读取或保存，请重试',
  },
  ModelFailure(:final code) => switch (code) {
    ModelFailureCode.configuration => '请填写有效的模型名称和 Key',
    ModelFailureCode.authentication => '鉴权未通过，请检查 Key、API 产品及模型权益（401）',
    ModelFailureCode.forbidden => '服务拒绝访问，请检查订阅或接口使用范围（403）',
    ModelFailureCode.rateLimited => '请求受限，请稍后重试（429）',
    ModelFailureCode.quota => '额度或余额已用尽，请到服务商控制台查看',
    ModelFailureCode.unavailableModel => '未找到模型或接口，请检查配置（404）',
    ModelFailureCode.cancelled => '已取消测试',
    ModelFailureCode.timeout => '连接超时，请检查网络后重试',
    ModelFailureCode.network => '网络连接失败，请重试',
    _ => '服务未返回完整有效的响应，请稍后重试',
  },
  _ => '暂时无法完成操作，请重试',
};

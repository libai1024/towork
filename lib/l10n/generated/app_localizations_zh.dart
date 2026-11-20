// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get settingsHaveChangedReopenAndTryAgain => '设置已变化，请重新打开后再试';

  @override
  String get couldntSaveSettingsTryAgain => '未能保存设置，原设置已保留，请重试';

  @override
  String get thisCanBeSplitIntoThreeSteps =>
      '这件事可以拆成准备资料、完成初稿和发送确认三个步骤。切换到 Agent 模式，我可以帮你直接创建待办。';

  @override
  String get theTaskOrItsCardHasChanged => '任务卡或待办已变化';

  @override
  String get thisChatIsClosedItsTaskCan => '当前会话已关闭，无法撤销待办';

  @override
  String get theTaskOrItsCardNoLonger => '待办或任务卡已不存在';

  @override
  String get theCardNowLinksToADifferent => '任务卡关联已变化，无法撤销';

  @override
  String get relatedRecordsHaveChangedAndCannotBe => '相关记录已变化，无法恢复';

  @override
  String get currentModel => '当前模型';

  @override
  String switchedTo(Object v0, Object v1, Object v2) {
    return '$v0$v1，已改用 $v2';
  }

  @override
  String get couldntOpenTheLocalWorkspaceYourData => '暂时无法打开本地工作区。原有数据已保留，请重试。';

  @override
  String get reopen => '重新打开';

  @override
  String get movement => '乐章';

  @override
  String get mountain => '山岳';

  @override
  String get note => '音符';

  @override
  String get overture => '序曲';

  @override
  String get sonata => '奏鸣曲';

  @override
  String get symphony => '交响曲';

  @override
  String get valley => '山谷';

  @override
  String get ridge => '山脊';

  @override
  String get summit => '峰顶';

  @override
  String get zenith => '天顶';

  @override
  String get year => '年';

  @override
  String get month => '月';

  @override
  String get free => '免费版';

  @override
  String get loading => '读取中';

  @override
  String get kFlagshipModel => 'K3 旗舰模型';

  @override
  String get mContextWindow => '1M 长上下文';

  @override
  String get highspeed => 'HighSpeed 高速';

  @override
  String get videoInput => '视频输入';

  @override
  String get mQuota => '1M 额度 ×2';

  @override
  String get highSpeedQuota => '高速 额度 ×3';

  @override
  String get vMWithVision => 'V4.1 1M 支持视觉';

  @override
  String get deepReasoning => '深度推理';

  @override
  String get makeTaskRecurring => '开启重复待办';

  @override
  String get startingWithThisOccurrence => '从本次开始';

  @override
  String get editRecurringTask => '修改重复待办';

  @override
  String get deleteRecurringTask => '删除重复待办';

  @override
  String get thisOccurrence => '仅本次';

  @override
  String get thisAndFutureOccurrences => '本次及以后';

  @override
  String get changesToTheRecurrenceRuleOrTime => '重复规则或时区的修改需要应用于本次及以后。';

  @override
  String get checkTheDueDateAndSeriesStatus =>
      '本次及以后暂不可用，请检查截止日期和系列状态；记录较多时也可能超过单次处理上限。';

  @override
  String get modelDownloadFailedCheckYourConnectionAnd => '模型下载失败，请检查网络后重试。';

  @override
  String get modelDownloadFailedTryAgainLater => '模型下载失败，请稍后重试。';

  @override
  String get installationCanceledYouCanRetry => '安装已取消，可以重试';

  @override
  String get installationDidNotFinishTryAgain => '系统安装未完成，请重试';

  @override
  String get patchDownloadCanceledYouCanDownloadIt => '补丁下载已取消，可重新下载';

  @override
  String get patchVerificationFailedCheckForUpdatesAgain => '补丁验证失败，请重新检查更新';

  @override
  String get finishTheCurrentConversationOrInputBefore =>
      '请先完成正在进行的对话或输入，再点击重启';

  @override
  String get patchReadyReturnHereToRestart => '补丁已就绪，请回到此页点击重启';

  @override
  String get downloadPausedResumeToContinue => '下载已暂停，再次下载会继续传输';

  @override
  String get connectionInterruptedTryAgain => '网络连接中断，请重试';

  @override
  String get updateInformationIsUnavailableTryAgainLater => '更新信息暂时不可用，请稍后重试';

  @override
  String get thisUpdateDoesNotSupportYourDevice => '当前更新包不支持此设备架构';

  @override
  String get theUpdateSignatureDoesNotMatchThe => '更新包签名与当前应用不一致';

  @override
  String get verificationFailedDownloadTheUpdateAgain => '更新包校验失败，请重新下载';

  @override
  String get storageIsFullOrUnavailableFreeUp => '存储空间不足或无法写入，请清理空间后重试';

  @override
  String get theDownloadServerIsUnavailableTryAgain => '服务器暂时无法继续下载，请稍后重试';

  @override
  String get allowToworkToInstallAppsThenTap => '请先允许 ToWork 安装应用，再点击安装并重新打开';

  @override
  String get thePackageOrVersionDoesNotMatch => '安装包版本或包名不匹配，请重新检查更新';

  @override
  String get anUpdateIsInProgressTryAgain => '更新正在处理，请稍后重试';

  @override
  String get updateIncompleteTryAgain => '更新未完成，请重试';

  @override
  String get noneLabel => '无';

  @override
  String get reminder => '提醒';

  @override
  String get atTheDueTime => '准时';

  @override
  String daysBefore(int v0) {
    return '提前 $v0 天';
  }

  @override
  String hoursBefore(int v0) {
    return '提前 $v0 小时';
  }

  @override
  String minutesBefore(int v0) {
    return '提前 $v0 分钟';
  }

  @override
  String get add => '新增';

  @override
  String get edit => '编辑';

  @override
  String get complete => '完成';

  @override
  String get deleteLabel => '删除';

  @override
  String get change => '修改';

  @override
  String get notSet => '未填写';

  @override
  String get cleared => '已清空';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String record(Object v0) {
    return '记录 $v0';
  }

  @override
  String get someFieldsAreUncertainCheckThemAgainst =>
      '图片识别存在不确定字段，请对照原图核对后确认。';

  @override
  String get title => '标题';

  @override
  String get notes => '备注';

  @override
  String get status => '状态';

  @override
  String get priority => '优先级';

  @override
  String get due => '截止时间';

  @override
  String get category => '分类';

  @override
  String get steps => '步骤';

  @override
  String get tags => '标签';

  @override
  String get completedAt => '完成时间';

  @override
  String get recurrence => '重复规则';

  @override
  String get recurrenceTimeZone => '重复时区';

  @override
  String get unavailableCategory => '已不可用的分类';

  @override
  String get completed => '已完成';

  @override
  String get task => '待办';

  @override
  String get inProgress => '进行中';

  @override
  String get high => '高';

  @override
  String get medium => '中';

  @override
  String get low => '低';

  @override
  String get urgent => '紧急';

  @override
  String get canceled => '已取消';

  @override
  String taskChanges(Object v0) {
    return '$v0 条待办变更';
  }

  @override
  String get onlyTheSelectedOccurrenceWillChangeOther =>
      '只修改选中实例，其他日期继续沿用已有规则。';

  @override
  String get stopsFutureOccurrencesInThisRangeAnd =>
      '停止该范围的后续重复，保留其他已完成记录；整体接受或拒绝。';

  @override
  String get acceptOrRejectTheSeriesChangesTogether =>
      '系列操作整体接受或拒绝；未来实例按窗口继续生成。';

  @override
  String get viewAllChanges => '查看全部变更';

  @override
  String get seriesTemplate => '系列模板 ';

  @override
  String get newLabel => '新建';

  @override
  String get update => '更新';

  @override
  String timeZone(Object v0) {
    return '时区 $v0 ';
  }

  @override
  String get keepRepeating => '继续重复';

  @override
  String get endBoundarySet => '已设定停止边界';

  @override
  String get saveAKimiApiKeyInModel => '请先在模型连接中保存 Kimi API Key，再发送。';

  @override
  String get modelSettingsChangedSendANewRequest => '模型配置已改变，请发送新请求；已完成的操作会保留。';

  @override
  String get inputIsTooLongShortenItOr => '这次内容过长，请缩短输入或拆分请求；原有历史已保留。';

  @override
  String get requestStopped => '已停止本次请求。';

  @override
  String get theContextOrActionLimitHasBeen => '本次上下文或执行轮数已达上限，请新建会话。';

  @override
  String get theChatOrRecordHasChangedFinish => '会话或记录已变化，请先处理未完成的请求或重新打开会话。';

  @override
  String get theRecordOrTableStructureHasSince => '记录或表结构已有后续修改，不能覆盖。';

  @override
  String get couldntCompleteTheActionYourDataIs => '暂时无法完成操作，原有数据已保留，请重试。';

  @override
  String get checkYourModelCredentialsAndAccessIn => '模型凭据或访问权限不可用，请检查模型连接。';

  @override
  String get modelRateLimitReachedTryAgainLater => '模型请求受限，请稍后重试。';

  @override
  String get thisAccountIsOutOfQuotaSelect => '这个账户的额度已用尽，可以换一个模型后重试。';

  @override
  String get theSourceImageIsUnavailableSelectIt => '来源图片已不可用，请返回截图导入重新选择图片。';

  @override
  String get couldntReadTheSourceImageTryAgain => '暂时无法读取来源图片，请稍后重试。';

  @override
  String get modelSettingsChangedDuringTheRequestRetry =>
      '模型配置在处理过程中发生了变化，可以用当前模型重试。';

  @override
  String get inputOrToolResultsAreTooLong => '本次内容或工具结果过长，请拆分请求；已完成操作仍保留。';

  @override
  String get actionLimitReachedSendAnotherRequestOr => '本次执行已达上限，请发送新请求或新建会话。';

  @override
  String get theTargetHasChangedYouCanReplan => '目标已经变化，可重新规划。';

  @override
  String get connectionInterruptedOrModelTimedOutTry => '网络中断或模型响应超时，可以重试。';

  @override
  String get theModelResponseFailedValidationThisBatch => '模型返回未通过校验，未执行该批修改。';

  @override
  String get requestIncompleteYouCanRetryCompletedActions =>
      '请求未完成，可以重试；已完成的操作会保留。';

  @override
  String get changesUndone => '已撤销本次修改';

  @override
  String awaitingConfirmation(Object v0) {
    return '待确认 $v0 项';
  }

  @override
  String get requestSavedReadyToContinue => '请求已保存，等待继续';

  @override
  String get working => '正在处理';

  @override
  String get replySaved => '回复已保存';

  @override
  String actionBatchesSubmitted(Object v0) {
    return '已提交 $v0 批操作';
  }

  @override
  String get requestStoppedBuild => '已停止本次请求';

  @override
  String completedActionBatchesRetained(Object v0) {
    return '已完成的 $v0 批操作仍保留。';
  }

  @override
  String earlierTurnsOutsideThisRequestFullHistory(Object v0) {
    return '本次未带入较早的 $v0 轮对话，完整历史仍可查看。';
  }

  @override
  String earlierTurnsOutsideThisRequestFullHistoryIsAvailable(Object v0) {
    return '本次未带入较早的 $v0 轮对话，完整历史仍可查看。涉及旧内容时请补充说明。';
  }

  @override
  String get actions => '操作';

  @override
  String selectLabel(Object v0) {
    return '选择$v0';
  }

  @override
  String get acceptAll => '全部接受';

  @override
  String acceptSelected(Object v0) {
    return '接受选中（$v0）';
  }

  @override
  String rejectSelected(Object v0) {
    return '拒绝选中（$v0）';
  }

  @override
  String get refreshChanges => '刷新差异';

  @override
  String get continueLabel => '继续处理';

  @override
  String get cancelRequest => '取消本次';

  @override
  String get retry => '重试';

  @override
  String get undoThisBatch => '撤销本批修改';

  @override
  String get undoAllChangesInThisRequest => '撤销本次全部修改';

  @override
  String get undo => '撤销';

  @override
  String name(Object v0, Object v1) {
    return '名称　$v0 → $v1';
  }

  @override
  String description(Object v0, Object v1) {
    return '说明　$v0$v1';
  }

  @override
  String get addField => '新增字段　';

  @override
  String editField(Object v0, Object v1) {
    return '修改字段　$v0 → $v1';
  }

  @override
  String removeField(Object v0) {
    return '移除字段　$v0';
  }

  @override
  String get field => '字段';

  @override
  String get type => '类型';

  @override
  String get requirement => '要求';

  @override
  String get required => '必填';

  @override
  String get optional => '选填';

  @override
  String get createTable => '新增表格';

  @override
  String get editTable => '编辑表格';

  @override
  String get noChangesToTheTable => '内容与当前表格一致';

  @override
  String get number => '数字';

  @override
  String currencyDecimalPlaces(Object v0) {
    return '金额 $v0 位小数';
  }

  @override
  String get date => '日期';

  @override
  String get dateAndTime => '日期时间';

  @override
  String get singleSelect => '单选';

  @override
  String get yesNo => '是否';

  @override
  String get text => '文本';

  @override
  String get glm => 'GLM 智谱';

  @override
  String get otherOpenaiCompatible => '其他（OpenAI 格式）';

  @override
  String get enterAValidKeyWithoutSpacesOr => '请输入有效的 Key，不要包含空格或换行';

  @override
  String get secureStorageIsUnavailableUnlockTheDevice => '系统安全存储暂不可用，请解锁设备后重试';

  @override
  String get settingsChangedReloadAndTryAgain => '配置已变化，请重新载入后再操作';

  @override
  String get enterAKeyForTheSelectedProvider => '请为所选服务商和区域填写 Key';

  @override
  String get couldntReadOrSaveLocalSettingsTry => '本地配置暂时无法读取或保存，请重试';

  @override
  String get enterAValidModelNameAndKey => '请填写有效的模型名称和 Key';

  @override
  String get authenticationFailedCheckTheKeyApiProduct =>
      '鉴权未通过，请检查 Key、API 产品及模型权益（401）';

  @override
  String get accessDeniedCheckYourSubscriptionAndApi =>
      '服务拒绝访问，请检查订阅或接口使用范围（403）';

  @override
  String get rateLimitReachedTryAgainLater => '请求受限，请稍后重试（429）';

  @override
  String get quotaOrBalanceExhaustedCheckTheProvider => '额度或余额已用尽，请到服务商控制台查看';

  @override
  String get modelOrEndpointNotFoundCheckYour => '未找到模型或接口，请检查配置（404）';

  @override
  String get testCanceled => '已取消测试';

  @override
  String get connectionTimedOutCheckYourNetworkAnd => '连接超时，请检查网络后重试';

  @override
  String get connectionFailedTryAgain => '网络连接失败，请重试';

  @override
  String get theServiceReturnedAnIncompleteResponseTry => '服务未返回完整有效的响应，请稍后重试';

  @override
  String get couldntCompleteTheActionTryAgain => '暂时无法完成操作，请重试';

  @override
  String get fast => '快速';

  @override
  String get viewSourceChat => '查看来源会话';

  @override
  String get viewTaskSourceChat => '查看待办来源会话';

  @override
  String get resetsSoon => '即将重置';

  @override
  String resetsInMin(Object v0) {
    return '$v0 分钟后重置';
  }

  @override
  String resetsInHr(Object v0) {
    return '$v0 小时后重置';
  }

  @override
  String resetsInHrMin(Object v0, Object v1) {
    return '$v0 小时 $v1 分后重置';
  }

  @override
  String resetsInDays(Object v0) {
    return '$v0 天后重置';
  }

  @override
  String get noKey => '未填写 Key';

  @override
  String get unavailable => '暂时不可用';

  @override
  String get reset => '重置';

  @override
  String get restore => '恢复';

  @override
  String left(Object v0, Object v1) {
    return '$v0剩余 $v1%';
  }

  @override
  String balance(Object v0) {
    return '余额 $v0';
  }

  @override
  String quotaUsed(Object v0, Object v1, Object v2) {
    return '$v0额度已用 $v1%$v2';
  }

  @override
  String used(Object v0) {
    return '已用 $v0%';
  }

  @override
  String get checkQuotaInTheProviderConsole => '额度请在服务商控制台查看';

  @override
  String get quotaNotCheckedYet => '尚未查询额度';

  @override
  String get accountBalance => '账户余额';

  @override
  String get daily => '日限';

  @override
  String get weekly => '周限';

  @override
  String get monthly => '月限';

  @override
  String remaining(Object v0, Object v1) {
    return '$v0，剩余 $v1';
  }

  @override
  String get upwardTrend => '上涨曲线';

  @override
  String get archiveBox => '归档盒';

  @override
  String get home => '家';

  @override
  String get briefcase => '公文包';

  @override
  String get heart => '心形';

  @override
  String get openBook => '翻开的书';

  @override
  String get wallet => '钱包';

  @override
  String get shoppingCart => '购物车';

  @override
  String get cutlery => '餐具';

  @override
  String get plane => '飞机';

  @override
  String get dumbbell => '哑铃';

  @override
  String get graduationCap => '学位帽';

  @override
  String get camera => '相机';

  @override
  String get gift => '礼物';

  @override
  String get car => '汽车';

  @override
  String get pawPrint => '爪印';

  @override
  String get leaf => '叶子';

  @override
  String get star => '星星';

  @override
  String get flag => '旗帜';

  @override
  String get code => '代码';

  @override
  String get pen => '钢笔';

  @override
  String get person => '人物';

  @override
  String get folder => '文件夹';

  @override
  String get mistBlue => '雾蓝';

  @override
  String get stone => '米灰';

  @override
  String get sage => '雾绿';

  @override
  String get wheat => '麦色';

  @override
  String get terracotta => '陶土';

  @override
  String get lavenderGray => '灰紫';

  @override
  String get slate => '青灰';

  @override
  String get warmGray => '暖灰';

  @override
  String get newSubcategory => '新建子分类';

  @override
  String get rename => '重命名';

  @override
  String get reorder => '排序';

  @override
  String get moveUp => '上移';

  @override
  String get moveDown => '下移';

  @override
  String get archive => '归档';

  @override
  String get restoreCategory => '恢复分类';

  @override
  String get deletePermanently => '彻底删除';

  @override
  String tasks(num v0) {
    return '$v0 条待办';
  }

  @override
  String subcategories(num v0) {
    return '$v0 个子分类';
  }

  @override
  String recurringSeries(num v0) {
    return '$v0 个重复系列';
  }

  @override
  String deleteLabelBuild(Object v0) {
    return '删除「$v0」？';
  }

  @override
  String contains(Object v0) {
    return '里面有$v0。';
  }

  @override
  String get moveTasksToUncategorizedAndPromoteSubcategories =>
      '待办移到「未分类」，子分类提升为一级';

  @override
  String get deleteTasksAndSubcategories => '待办与子分类一并删除';

  @override
  String get futureTasksInThisCategoryWillMove =>
      '本分类的后续重复待办也移到「未分类」；子分类的系列保留原分类。';

  @override
  String alsoStopTheseSeries(Object v0) {
    return '同时停止这 $v0 个系列。';
  }

  @override
  String keepTheTasksMovedElsewhereOrUncategorized(Object v0) {
    return '已移到其他分类或未分类的 $v0 条待办保留，并取消重复。';
  }

  @override
  String get cancel => '取消';

  @override
  String get icon => '图标';

  @override
  String get color => '颜色';

  @override
  String get done => '完  成';

  @override
  String get deleteCategory => '删除此分类';

  @override
  String get editCategory => '编辑分类';

  @override
  String get newCategory => '新建分类';

  @override
  String get close => '关闭';

  @override
  String get categoryName => '分类名称';

  @override
  String iconIcongrid(Object v0) {
    return '图标，$v0';
  }

  @override
  String get selected => '已选中';

  @override
  String get notSelected => '未选中';

  @override
  String colorItemOf(Object v0, Object v1, Object v2, Object v3) {
    return '颜色，$v0，$v1，共 $v2 项之第 $v3 项';
  }

  @override
  String get topLevel => '一级分类';

  @override
  String parent(Object v0) {
    return '归属，$v0';
  }

  @override
  String get parentParentrow => '归属';

  @override
  String get aCategoryWithSubcategoriesMustStayAt => '含子分类的分类不能再挂靠到其他分类下';

  @override
  String moveUnder(Object v0) {
    return '归属到$v0';
  }

  @override
  String get archiveCategory => '归档此分类';

  @override
  String get hidesThisCategoryWhenCreatingTasksIts => '归档后不再出现在新建待办的分类列表中，数据保留';

  @override
  String get notificationsAndReminders => '通知与提醒';

  @override
  String get couldntOpenNotificationSettingsTryAgain => '暂时无法访问系统通知设置，请重试。';

  @override
  String get localWorkspaceIsntReady => '本地工作区尚未就绪。';

  @override
  String get checkingPermissions => '正在检查系统权限…';

  @override
  String get localNotificationsAreUnavailableOnThisPlatform => '此平台暂不支持本地通知';

  @override
  String get systemNotificationsEnabled => '系统通知已开启';

  @override
  String get notificationsAreOffYourReminderRulesAre => '系统通知未开启，提醒规则已保留。';

  @override
  String get backgroundMaintenanceRegisteredTheSystemControlsTiming =>
      '后台维护已登记，执行时间由系统决定。';

  @override
  String get backgroundRegistrationFailedRemindersCanStillBe =>
      '后台维护登记失败，前台仍可排期。';

  @override
  String get foregroundMaintenanceOnlyDigestGenerationPausesWhen =>
      '仅前台维护，退出后暂停生成摘要。';

  @override
  String get retryBackgroundMaintenance => '重试后台维护';

  @override
  String scheduledPending(Object v0, Object v1) {
    return '已排期 $v0 条，待排期 $v1 条。';
  }

  @override
  String get dueRemindersMayArriveLateEnableExact => '截止提醒可能延迟。需要准点提醒时请开启精确提醒。';

  @override
  String get someRemindersWerentScheduledTryAgain => '部分提醒未排期，请重试。';

  @override
  String get checkAndRetry => '检查并重试';

  @override
  String get enableNotifications => '开启系统通知';

  @override
  String get enableExactAlarms => '开启精确提醒';

  @override
  String get systemNotificationSettings => '系统通知设置';

  @override
  String get scheduleDetails => '排期详情';

  @override
  String get setAReminderOnTheTaskUp =>
      '待办需设提醒规则。未来 30 天最多预排 60 条，每日摘要最多预排 7 天，使用排期时的本机数据。';

  @override
  String get schedulingResumesInTheBackgroundOrWhen =>
      '后台或下次打开时补排。每日摘要按普通排期，省电、勿扰或强制停止可能影响送达。';

  @override
  String get created => '已创建';

  @override
  String get today => '今天';

  @override
  String get tomorrow => '明天';

  @override
  String get nextMonday => '下周一';

  @override
  String formattedValue(Object v0, Object v1) {
    return '$v0月$v1日';
  }

  @override
  String get noDueDate => '无截止';

  @override
  String get whenDue => '截止时';

  @override
  String get minutesBeforeBuild => '提前 15 分钟';

  @override
  String get hourBefore => '提前 1 小时';

  @override
  String get dayBefore => '提前 1 天';

  @override
  String get newTask => '新建待办';

  @override
  String get taskTitle => '待办标题';

  @override
  String get create => '创建';

  @override
  String get addANote => '添加备注';

  @override
  String get dueDate => '截止日期';

  @override
  String get setTime => '设置时间';

  @override
  String get chooseDate => '选择日期';

  @override
  String get ok => '确定';

  @override
  String get uncategorized => '未分类';

  @override
  String get backToToday => '回到今天';

  @override
  String get restored => '已恢复';

  @override
  String get deleted => '已删除';

  @override
  String filterCategory(Object v0) {
    return '筛选分类：$v0';
  }

  @override
  String chooseDateBuild(Object v0) {
    return '$v0，选择日期';
  }

  @override
  String get collapseDailyOverview => '收起今日总览';

  @override
  String get mtwtfss => '一二三四五六日';

  @override
  String formattedValueBuild(Object v0, Object v1, Object v2, Object v3) {
    return '$v0年$v1月$v2日 周$v3';
  }

  @override
  String get thatDay => '当天';

  @override
  String pending(Object v0, Object v1) {
    return '$v0待完成 $v1 项';
  }

  @override
  String overdue(Object v0) {
    return ' 逾期 $v0 项';
  }

  @override
  String completion(Object v0) {
    return '$v0完成进度';
  }

  @override
  String get allLabel => '全部';

  @override
  String get overdueBuild => '逾期';

  @override
  String get noTasks => '暂无待办';

  @override
  String completedBuild(Object v0) {
    return '已完成 $v0 项';
  }

  @override
  String get allTasks => '全部待办';

  @override
  String get setADueDateBeforeEnablingRecurrence => '请先设置本次截止日期，再开启重复';

  @override
  String get selectedOccurrencesDeleted => '已删除所选范围';

  @override
  String get recurringTaskUpdated => '重复待办已更新';

  @override
  String get undone => '已撤销';

  @override
  String get dateIsOutsideAvailableTimeZoneData => '日期超出当前时区数据范围，请缩短结束时间';

  @override
  String get updatesRecurrenceForTheSelectedRangeEarlier =>
      '将更新所选范围的重复安排，保留此前记录和其他已完成任务。';

  @override
  String get changesOnlyThisOccurrenceOtherDatesAnd => '只处理这一次，其他日期和重复安排保持不变。';

  @override
  String changesAddedEditedDeleted(Object v0, Object v1, Object v2) {
    return '本次变更：新增 $v0 修改 $v1 删除 $v2';
  }

  @override
  String get collapseRecords => '收起记录';

  @override
  String viewAllRecords(Object v0) {
    return '查看全部 $v0 条记录';
  }

  @override
  String get confirmDeletion => '确认删除';

  @override
  String get confirmChanges => '确认修改';

  @override
  String previously(Object v0) {
    return '原：$v0';
  }

  @override
  String get repeat => '重复';

  @override
  String get timeZoneBuild => '时区';

  @override
  String get setADueTimeToPreviewUpcoming => '设置截止时间后可预览后续日期';

  @override
  String thisOccurrenceBuild(Object v0) {
    return '本次：$v0';
  }

  @override
  String get noUpcomingDatesTheEndConditionHas => '没有后续日期（已达到结束条件）';

  @override
  String get upcomingDates => '后续日期预览';

  @override
  String timeZoneDataIsAvailableThroughShorten(Object v0) {
    return '当前时区数据支持至 $v0 年，请缩短预览范围';
  }

  @override
  String get previewUnavailableForThisRuleOrTime => '当前规则或时区暂不支持预览';

  @override
  String get dateRangeIsTooLargeShortenThe => '日期范围过大，请缩短重复间隔或范围';

  @override
  String get enterATitleBeforeClosing => '标题不能为空，请填写后再关闭';

  @override
  String get taskUnavailable => '这条待办不在了';

  @override
  String get itMayHaveBeenDeletedOrChanged => '它可能被删除，也可能在另一台设备上改过';

  @override
  String get backToTasks => '回到待办列表';

  @override
  String get more => '更多';

  @override
  String markIncomplete(Object v0) {
    return '标记未完成，$v0';
  }

  @override
  String markComplete(Object v0) {
    return '标记完成，$v0';
  }

  @override
  String get addANoteBuildtitlearea => '添加备注…';

  @override
  String get originalCategoryArchived => '原分类已归档';

  @override
  String get dueBuildfields => '截止';

  @override
  String get overdueBuildfields => '已逾期';

  @override
  String get addTag => '添加标签';

  @override
  String get fromChat => '来自对话';

  @override
  String get originalChatDeleted => '原始对话已删除';

  @override
  String get originalChatUnavailable => '原始对话已不可用';

  @override
  String createdFromChatDoubleTapToView(Object v0) {
    return '由对话生成，原文：$v0，双击查看对话';
  }

  @override
  String createdBuildmeta(Object v0) {
    return '创建于 $v0';
  }

  @override
  String updated(Object v0) {
    return '更新于 $v0';
  }

  @override
  String completedBuildmeta(Object v0) {
    return '完成于 $v0';
  }

  @override
  String get deleteThisTask => '删除这条待办';

  @override
  String get copyTitle => '复制标题';

  @override
  String get titleCopied => '已复制标题';

  @override
  String get deleteThisTaskConfirmdelete => '删除这条待办？';

  @override
  String willBeDeletedYouCanUndoWithin(Object v0) {
    return '「$v0」将被删除，删除后 10 秒内可撤销。';
  }

  @override
  String get chooseDateBuild2 => '选日期…';

  @override
  String get time => '时间';

  @override
  String get allDay => '全天截止';

  @override
  String get clearTime => '清除时间';

  @override
  String get addTime => '添加时间';

  @override
  String get clearDueDate => '清除截止';

  @override
  String get removesTheTaskFromTodayThisWeek => '清除后不再出现在今天/本周/逾期过滤中';

  @override
  String get decrease => '减少';

  @override
  String get increase => '增加';

  @override
  String doubleTapToEdit(Object v0, Object v1) {
    return '$v0，$v1，双击修改';
  }

  @override
  String selectTask(Object v0) {
    return '选择待办：$v0';
  }

  @override
  String restoreTask(Object v0) {
    return '恢复待办：$v0';
  }

  @override
  String completeTask(Object v0) {
    return '完成待办：$v0';
  }

  @override
  String get rescheduleTask => '改期待办';

  @override
  String get deleteTask => '删除待办';

  @override
  String get restoreTaskCustomactions => '恢复待办';

  @override
  String get completeTaskConfirmremainingsteps => '完成待办';

  @override
  String get addReminder => '添加提醒';

  @override
  String deleteReminder(Object v0) {
    return '删除提醒：$v0';
  }

  @override
  String get upToReminders => '最多 5 条提醒';

  @override
  String get recurringTasksSendRemindersBeforeEachDue => '重复任务将在每次截止前提醒';

  @override
  String get minutes => '分钟';

  @override
  String get hours => '小时';

  @override
  String get days => '天';

  @override
  String get minutesBeforeBuild2 => '前 5 分钟';

  @override
  String get minutesBeforeBuild3 => '前 15 分钟';

  @override
  String get minutesBeforeBuild4 => '前 30 分钟';

  @override
  String get hourBeforeBuild => '前 1 小时';

  @override
  String get dayBeforeBuild => '前 1 天';

  @override
  String get relativeToDueTime => '相对截止';

  @override
  String get setADueTimeFirst => '先设置截止时间';

  @override
  String get custom => '自定义';

  @override
  String get reminderLeadTime => '提醒提前量';

  @override
  String get addBuild => '添加';

  @override
  String get specificTime => '指定时间';

  @override
  String get am => '上午 9:00';

  @override
  String get pm => '中午 12:00';

  @override
  String get pmBuild => '下午 18:00';

  @override
  String get pmBuild2 => '晚上 20:00';

  @override
  String get customRuleReadOnly => '自定义规则（暂不支持编辑）';

  @override
  String get resetRule => '重置规则';

  @override
  String get week => '周';

  @override
  String get frequency => '频率';

  @override
  String get dailyBuild => '每天';

  @override
  String get weeklyBuild => '每周';

  @override
  String get monthlyBuild => '每月';

  @override
  String get yearly => '每年';

  @override
  String get interval => '间隔';

  @override
  String get every => '每';

  @override
  String get repeatInterval => '重复间隔';

  @override
  String get repeatOn => '重复于';

  @override
  String get dayOfMonth => '每月日期';

  @override
  String get day => '日';

  @override
  String get ends => '结束';

  @override
  String get never => '永不';

  @override
  String get onDate => '于日期';

  @override
  String get afterNOccurrences => 'N 次后';

  @override
  String get numberOfOccurrences => '重复次数';

  @override
  String get times => '次';

  @override
  String get fixedTimeZone => '固定时区';

  @override
  String get shortMonthsUseTheLastDayDuring =>
      '月末不足所选日期时取最后一天；夏令时缺失时刻顺延至首个有效时刻，重复时刻只取一次。';

  @override
  String summary(Object v0) {
    return '摘要：$v0';
  }

  @override
  String get saveRecurrence => '保存重复设置';

  @override
  String get clearRecurrence => '确认清除？';

  @override
  String get clearRecurrenceBuild => '清除重复';

  @override
  String unfinishedSteps(Object v0) {
    return '还有 $v0 个未完成步骤';
  }

  @override
  String get back => '返回';

  @override
  String get taskCompleted => '待办已完成';

  @override
  String get taskReopened => '待办已重新打开';

  @override
  String get stepDeleted => '步骤已删除';

  @override
  String get progressUpdated => '进度已更新';

  @override
  String get enterAStepName => '请输入步骤名称';

  @override
  String get stepsHaveChangedReviewThemBeforeSaving => '步骤已变化，请核对后再保存';

  @override
  String get stepName => '步骤名称';

  @override
  String get discardEdits => '放弃编辑';

  @override
  String get saveStep => '保存步骤';

  @override
  String get addStep => '添加步骤';

  @override
  String get doneOrganizing => '完成整理';

  @override
  String get organize => '整理';

  @override
  String moveStepUp(Object v0) {
    return '上移第$v0步';
  }

  @override
  String moveStepDown(Object v0) {
    return '下移第$v0步';
  }

  @override
  String deleteStep(Object v0) {
    return '删除第$v0步';
  }

  @override
  String get nextStep => '下一步';

  @override
  String get nextStepRow => '，下一步';

  @override
  String step(Object v0, Object v1, Object v2) {
    return '第$v0步，$v1$v2';
  }

  @override
  String get tagName => '标签名';

  @override
  String get thisWeek => '本周';

  @override
  String get pendingLabel => '待处理';

  @override
  String todayDuesmartlabel(Object v0) {
    return '今天$v0';
  }

  @override
  String tomorrowDuesmartlabel(Object v0) {
    return '明天$v0';
  }

  @override
  String yesterday(Object v0) {
    return '昨天$v0';
  }

  @override
  String formattedValueDuesmartlabel(Object v0, Object v1, Object v2) {
    return '$v0月$v1日$v2';
  }

  @override
  String overdueDuebadgelabel(Object v0) {
    return '已逾期 $v0';
  }

  @override
  String daysOverdue(int v0) {
    return '已逾期 $v0 天';
  }

  @override
  String hoursOverdue(int v0) {
    return '已逾期 $v0 小时';
  }

  @override
  String get justOverdue => '刚刚逾期';

  @override
  String daysLeft(int v0) {
    return '还剩 $v0 天';
  }

  @override
  String hoursLeft(int v0) {
    return '还剩 $v0 小时';
  }

  @override
  String minutesLeft(int v0) {
    return '还剩 $v0 分钟';
  }

  @override
  String todayRelativetimelabel(Object v0) {
    return '今天 $v0';
  }

  @override
  String yesterdayRelativetimelabel(Object v0) {
    return '昨天 $v0';
  }

  @override
  String get later => '更晚';

  @override
  String get mon => '一';

  @override
  String get tue => '二';

  @override
  String get wed => '三';

  @override
  String get thu => '四';

  @override
  String get fri => '五';

  @override
  String get sat => '六';

  @override
  String everySummary(Object v0) {
    return '每$v0';
  }

  @override
  String everySummary2(Object v0, Object v1) {
    return '每 $v0 $v1';
  }

  @override
  String formattedValueSummary(Object v0) {
    return '周$v0';
  }

  @override
  String daySummary(Object v0) {
    return ' $v0 日';
  }

  @override
  String get neverEnds => '永不结束';

  @override
  String occurrences(Object v0) {
    return '共 $v0 次';
  }

  @override
  String endsSummary(Object v0, Object v1, Object v2) {
    return '$v0 年 $v1 月 $v2 日结束';
  }

  @override
  String get doesNotRepeat => '不重复';

  @override
  String get customRule => '自定义规则';

  @override
  String minBeforeDue(Object v0) {
    return '截止前 $v0 分钟';
  }

  @override
  String hrBeforeDue(Object v0) {
    return '截止前 $v0 小时';
  }

  @override
  String hrMinBeforeDue(Object v0, Object v1) {
    return '截止前 $v0 小时 $v1 分钟';
  }

  @override
  String daysBeforeDue(Object v0) {
    return '截止前 $v0 天';
  }

  @override
  String daysHrBeforeDue(Object v0, Object v1) {
    return '截止前 $v0 天 $v1 小时';
  }

  @override
  String customRemindrulelabel(Object v0, Object v1, Object v2) {
    return '$v0月$v1日 $v2（自定义）';
  }

  @override
  String get copyCode => '复制代码';

  @override
  String get codeCopied => '已复制代码';

  @override
  String get avatar => '头像';

  @override
  String get processing => '处理中';

  @override
  String formattedValueBuild2(Object v0, Object v1) {
    return '$v0 年 $v1 月';
  }

  @override
  String get previousWeek => '上一周';

  @override
  String get previousMonth => '上个月';

  @override
  String get nextWeek => '下一周';

  @override
  String get nextMonth => '下个月';

  @override
  String tasksBuild(Object v0) {
    return '，$v0项待办';
  }

  @override
  String formattedValueBuild3(Object v0, Object v1, Object v2, Object v3) {
    return '$v0年$v1月$v2日$v3';
  }

  @override
  String get dismiss => '关闭提示';

  @override
  String get collapseSidebar => '收起侧栏';

  @override
  String get copyReply => '复制回复';

  @override
  String get copied => '已复制';

  @override
  String get saving => '保存中';

  @override
  String subscriptionTier(Object v0) {
    return '订阅等级 $v0';
  }

  @override
  String get inDevelopment => '开发中';

  @override
  String get search => '搜索';

  @override
  String get clearSearch => '清除搜索';

  @override
  String get newType => '新增类型';

  @override
  String items(Object v0) {
    return '，$v0项';
  }

  @override
  String get savingTryAgainShortly => '正在保存，请稍后再试';

  @override
  String get recordChangedReopenAndTryAgain => '记录已变化，请重新打开后再操作';

  @override
  String get actionAlreadySubmittedCheckTheLatestRecord => '该操作已提交，请检查最新记录';

  @override
  String get invalidContentOrCategoryRelationshipCheckAnd => '内容或分类关系无效，请检查后重试';

  @override
  String get recordNoLongerExistsRefreshAndTry => '记录已不存在，请刷新后重试';

  @override
  String get couldntSaveYourDataIsSafeTry => '保存失败，原数据已保留，请重试';

  @override
  String get webToolsMonthly => '联网工具 每月';

  @override
  String get dailyOrder => '每日';

  @override
  String get quota => '额度';

  @override
  String get periodQuota => '周期额度';

  @override
  String get hoursOrder => '5 小时';

  @override
  String get tasksAndDailyDigest => '待办与每日摘要';

  @override
  String get yourTaskRemindersAndDailyDigests => '你设置的待办提醒和每日摘要';

  @override
  String get textFiles => '文本文件';

  @override
  String get chooseAValidTopLevelCategory => '分类必须属于有效的一级分类';

  @override
  String get invalidChatForThisMessage => '消息所属会话无效';

  @override
  String get newChat => '新的对话';

  @override
  String get chatNotFound => '会话不存在';

  @override
  String get messageIdAlreadyExists => '消息 ID 已存在';

  @override
  String get messageIdBelongsToAnotherChat => '消息 ID 已用于另一会话';

  @override
  String get messagesCantBeMovedBetweenChats => '消息不能移到其他会话';

  @override
  String get chatName => '会话名称';

  @override
  String get typeAlreadyExists => '该类型已存在';

  @override
  String get tableName => '表名';

  @override
  String get fieldNotFound => '字段不存在';

  @override
  String get fieldName => '字段名';

  @override
  String get provideAValueForExistingRecordsBefore => '必填字段需要为现有记录补一个值';

  @override
  String get keepAtLeastOneField => '至少保留一个字段';

  @override
  String get aTableWithThisIdentifierAlreadyExists => '同名标识的表已存在';

  @override
  String get invalidOrDuplicateRowId => '数据行 ID 无效或已存在';

  @override
  String get thisRecordAlreadyExistsAndCantBe => '这条记录已存在，无法覆盖恢复';

  @override
  String get recordDeleted => '这条记录已删除';

  @override
  String get analysisOfHoldingsPng => '截图「持仓_0921.png」的分析';

  @override
  String get nameNewTableSheet => '名称';

  @override
  String get kweichowMoutai => '贵州茅台';

  @override
  String get sharesHeld => '持仓(股)';

  @override
  String get currentPrice => '现价';

  @override
  String get byd => '比亚迪';

  @override
  String get newRecord => '新记录';

  @override
  String get theseAiChangesHaveBeenProcessedReopen => '这批 AI 变更已处理，请重新打开待确认记录';

  @override
  String get theSelectedChangeNoLongerExists => '选中的变更已不存在';

  @override
  String get recordDeletedOrMovedToAnotherTable => '记录已删除或不属于这张表，请重新确认';

  @override
  String get aChangeCannotIncludeTheSameField => '一个变更不能重复同一字段';

  @override
  String get incompleteDeletionSnapshotReviewAgain => '记录的删除快照不完整，请重新确认';

  @override
  String get recordUpdatedReviewTheAiChangesAgain => '记录已有更新，请重新确认 AI 变更';

  @override
  String get recordChangedSinceThisAiUpdateUndo => '记录已有后续修改，无法撤销这次 AI 变更';

  @override
  String get tableMissingOrArchived => '数据表不存在或已归档';

  @override
  String get dataTypeNoLongerExistsChooseAgain => '数据类型不存在，请重新选择';

  @override
  String get invalidOrDuplicateDataTypeName => '数据类型名称无效或重复';

  @override
  String get tableTypeNotFound => '数据表所属类型不存在';

  @override
  String get parentTableNotFoundForRow => '数据行所属表不存在';

  @override
  String get parentTableNotFoundForAiBatch => 'AI 批次所属表不存在';

  @override
  String get typeName => '类型名称';

  @override
  String get useUpToCharactersForTheType => '类型名称最多 24 个字';

  @override
  String get addAtLeastOneField => '至少添加一个字段';

  @override
  String get fieldNamesCannotBeEmptyOrBegin => '字段名不能为空或包含首尾空白';

  @override
  String get fieldNamesMustBeUnique => '字段名不能重复';

  @override
  String requiresAtLeastOneOption(Object v0) {
    return '「$v0」至少需要一个选项';
  }

  @override
  String optionsForCannotBeBlankOrBegin(Object v0) {
    return '「$v0」的选项不能为空或包含首尾空白';
  }

  @override
  String optionsForMustBeUnique(Object v0) {
    return '「$v0」的选项不能重复';
  }

  @override
  String dataContainsAnUndefinedField(Object v0) {
    return '数据包含未定义的字段「$v0」';
  }

  @override
  String isRequired(Object v0) {
    return '「$v0」不能为空';
  }

  @override
  String get aFiniteNumber => '有限数字';

  @override
  String get aValidDateYyyyMmDd => '有效日期（yyyy-MM-dd）';

  @override
  String get aValidDateAndTimeYyyyMm => '有效日期时间（yyyy-MM-dd HH:mm）';

  @override
  String get anExistingOption => '已有选项';

  @override
  String get trueOrFalse => 'true 或 false';

  @override
  String mustBe(Object v0, Object v1) {
    return '「$v0」必须是$v1';
  }

  @override
  String get memoryContent => '记忆内容';

  @override
  String get memoryType => '记忆类型';

  @override
  String get useUpToCharactersForTheTypeName => '类型名称最多 20 个字';

  @override
  String get endDateCannotPrecedeStartDate => '报告结束日期不能早于开始日期';

  @override
  String get reportGenerationFailedTryAgain => '报告生成失败，请重试';

  @override
  String get weeklyReport => '周报';

  @override
  String get monthlyReport => '月报';

  @override
  String get report => '报告';

  @override
  String get investing => '炒股';

  @override
  String get archives => '档案馆';

  @override
  String get family => '家庭';

  @override
  String get work => '工作';

  @override
  String get overview => '## 本期概览';

  @override
  String scope(Object v0) {
    return '范围覆盖$v0。';
  }

  @override
  String get recordIdsCannotBeEmptyOrDuplicated => '记录 ID 不能为空或重复';

  @override
  String isRequiredRequiretext(Object v0) {
    return '$v0不能为空';
  }

  @override
  String get taskIdAlreadyExists => '待办 ID 已存在';

  @override
  String get quotaExhausted => '额度已用尽';

  @override
  String get tooManyRequests => '请求过于频繁';

  @override
  String get invalidKey => 'Key 无效';

  @override
  String get accessDenied => '没有访问权限';

  @override
  String get modelUnavailable => '模型不可用';

  @override
  String get serviceTemporarilyUnavailable => '服务暂时异常';

  @override
  String get alwaysAsk => '总是询问';

  @override
  String get askBeforeTheAiChangesTasksOr => 'AI 写入待办和表格前都会先确认';

  @override
  String get smartConfirmation => '智能确认';

  @override
  String get applyTaskAdditionsEditsAndCompletionsImmediately =>
      '待办新增、编辑、完成直接生效，删除前确认；表格写入需确认';

  @override
  String get runAutomatically => '自动执行';

  @override
  String get applyTaskChangesAndKeepAHistory => '待办自动执行并保留修改记录；表格写入仍需确认';

  @override
  String get kimiCodeSubscription => 'Kimi Code 编程订阅';

  @override
  String get kimiKHighspeed => 'Kimi K2.8 高速';

  @override
  String get glmCodingPlanSubscription => 'GLM Coding Plan 编程订阅';

  @override
  String get thisPlanIsRestrictedToSupportedCoding =>
      '此订阅限指定编程工具使用，其他客户端可能被限流或停用。';

  @override
  String get deepseekPlatform => 'DeepSeek 开放平台';

  @override
  String get kimiPlatform => 'Kimi 开放平台';

  @override
  String get zhipuGlmPlatform => '智谱 GLM 开放平台';

  @override
  String get zhipuGlm => '智谱 GLM';

  @override
  String get openaiCompatibleApi => 'OpenAI 兼容接口';

  @override
  String get fact => '事实';

  @override
  String get preference => '偏好';

  @override
  String get event => '事件';

  @override
  String get profile => '画像';

  @override
  String get active => '有效';

  @override
  String get expired => '已过期';

  @override
  String get intentRecognition => '意图识别';

  @override
  String get chat => '日常对话';

  @override
  String get reportGeneration => '报告生成';

  @override
  String get screenshotAnalysis => '截图分析';

  @override
  String stepsStepprogress(Object v0, Object v1) {
    return '步骤 $v0/$v1';
  }

  @override
  String dueEarlierUnfinished(Object v0, Object v1, Object v2, Object v3) {
    return '$v0/$v1 到期 $v2 项，此前未完成 $v3 项。';
  }

  @override
  String scheduledSnapshotOpenForTheLatest(Object v0) {
    return '$v0预排快照，打开查看最新。';
  }

  @override
  String get taskReminder => '待办提醒';

  @override
  String get dailyTaskDigest => '每日待办摘要';

  @override
  String get unknownVersion => '未知版本';

  @override
  String get restoreBaseVersion => '恢复基础版本';

  @override
  String patchP(Object v0) {
    return '补丁 P$v0';
  }

  @override
  String get exitReorderMode => '退出排序';

  @override
  String get reorderCategories => '排序分类';

  @override
  String get finishReordering => '完成排序';

  @override
  String get inUse => '使用中';

  @override
  String get allCategoriesArchived => '所有分类已归档';

  @override
  String get noCategories => '暂无分类';

  @override
  String get createSampleCategories => '创建示例分类';

  @override
  String get createsInvestingArchivesAndFamily => '将创建炒股、档案馆、家庭';

  @override
  String get archivedTapToCollapse => '已归档，点击收起';

  @override
  String get archivedTapToExpand => '已归档，点击展开';

  @override
  String archived(Object v0) {
    return '已归档 $v0';
  }

  @override
  String get dropBetweenTopLevelRowsToReorder => '拖到一级行之间 = 同级排序 / 提升为一级';

  @override
  String get dropOntoATopLevelRowTo => '拖到一级行上 = 设为其子分类';

  @override
  String get upToTwoCategoryLevels => '最多支持两级分类';

  @override
  String restoredOpenarchivedactions(Object v0) {
    return '「$v0」回来了';
  }

  @override
  String archivedAndHiddenWhenCreatingTasks(Object v0) {
    return '「$v0」已归档，新建待办时不会再出现';
  }

  @override
  String deletedEditcategory(Object v0) {
    return '已删除「$v0」';
  }

  @override
  String get completionRateUnknown => '完成率未知';

  @override
  String completeSemanticslabel(Object v0) {
    return '完成率 $v0%';
  }

  @override
  String archivedCategoryTasksDoubleTapForRestore(Object v0, Object v1) {
    return '已归档分类，$v0，$v1 条待办，双击查看恢复选项';
  }

  @override
  String subcategoryTasks(Object v0, Object v1, Object v2) {
    return '子分类，$v0，$v1 条待办，$v2';
  }

  @override
  String categoryTasks(Object v0, Object v1, Object v2) {
    return '分类，$v0，$v1 条待办，$v2';
  }

  @override
  String get subcategoriesExpanded => '，子分类已展开';

  @override
  String get subcategoriesCollapsed => '，含子分类，已收起';

  @override
  String get doubleTapToEditHoldAndDrag => '。双击编辑，长按拖拽排序。';

  @override
  String get collapseSubcategories => '收起子分类';

  @override
  String get expandSubcategories => '展开子分类';

  @override
  String itemsStats(Object v0) {
    return '$v0 项 —';
  }

  @override
  String itemsStats2(Object v0) {
    return '$v0 项 ';
  }

  @override
  String moreActionsFor(Object v0) {
    return '$v0 更多操作';
  }

  @override
  String itemsBuild(num v0) {
    return '$v0 项';
  }

  @override
  String get advanced => ' 进阶';

  @override
  String get couldntReplyTryAgain => '暂时无法回复，请重试';

  @override
  String get couldntRefreshLocalChatsShowingTheLast => '本地会话暂时无法刷新，已保留上次内容。';

  @override
  String get reload => '重新加载';

  @override
  String get renameChat => '重命名会话';

  @override
  String get save => '保存';

  @override
  String get deleteThisChat => '删除这段会话？';

  @override
  String get tasksCreatedInThisChatWillBe => '已创建的待办会保留。';

  @override
  String get deleteChat => '删除会话';

  @override
  String hiWhatsOnYourListToday(Object v0) {
    return '嗨 $v0，今天想做点什么';
  }

  @override
  String get replyIncomplete => '回复未完成';

  @override
  String get voiceInputInterrupted => '语音输入已中断';

  @override
  String get couldntStartVoiceInput => '语音输入未能启动';

  @override
  String get transcriptIsTooLongSplitItInto => '转写过长，请分成几条指令。';

  @override
  String get couldntHearThatTryAgain => '没有听清，请再说一次';

  @override
  String get recognitionTimedOutTryAgain => '识别超时，请再说一次';

  @override
  String get couldntSendYourTextIsSaved => '发送失败，文字已保留';

  @override
  String get allowMicrophoneAccessInSystemSettings => '请在系统设置中允许麦克风权限';

  @override
  String get selectedLanguageIsUnavailable => '暂不支持所选语言';

  @override
  String get thisRecognizerDoesNotSupportOnDevice =>
      '当前识别器不支持设备端模式，不会自动切换到联网识别。';

  @override
  String get couldntConnectToSpeechService => '语音服务连接失败';

  @override
  String get microphoneInUse => '麦克风正在使用中';

  @override
  String get recordingInterrupted => '录音已中断';

  @override
  String get voiceInputUnavailable => '语音输入暂不可用';

  @override
  String get notSentTryAgain => '未发送，请重试';

  @override
  String get answered => '已回答';

  @override
  String get chatContinued => '已继续对话';

  @override
  String get addToYourAnswer => '补充你的回答';

  @override
  String get collapseAdditionalAnswer => '收起补充回答';

  @override
  String get addAnAnswer => '补充回答';

  @override
  String get collapse => '收起';

  @override
  String get otherAnswer => '其他回答';

  @override
  String get confirmAnswer => '确认回答';

  @override
  String get sending => '发送中';

  @override
  String get send => '发送';

  @override
  String sendSelections(Object v0) {
    return '发送 $v0 项';
  }

  @override
  String get undoTask => '撤销待办';

  @override
  String get restoredToPending => '已恢复为待办';

  @override
  String get editTask => '修改待办';

  @override
  String get previousPage => '上一页';

  @override
  String get page => '页码';

  @override
  String get nextPage => '下一页';

  @override
  String moreItems(Object v0) {
    return '另有 $v0 项未展示';
  }

  @override
  String itemsRemoved(Object v0) {
    return '$v0 项已移除';
  }

  @override
  String completeBuild(Object v0, Object v1) {
    return '$v0/$v1 完成';
  }

  @override
  String view(Object v0) {
    return '查看$v0';
  }

  @override
  String get theTasksInThisListHaveBeen => '这份清单中的待办已移除';

  @override
  String get noTasksInThisRange => '这个范围暂时没有待办';

  @override
  String taskBuild(Object v0, Object v1) {
    return '$v0待办：$v1';
  }

  @override
  String editTaskBuild(Object v0) {
    return '编辑待办：$v0';
  }

  @override
  String get scrollToLatest => '滚动到最新内容';

  @override
  String get schedule => '日程';

  @override
  String get data => '数据';

  @override
  String get memory => '记忆';

  @override
  String get settings => '设置';

  @override
  String get collapseCategories => '收起分类';

  @override
  String get expandCategories => '展开分类';

  @override
  String get reorderCategoriesBuild => '分类排序';

  @override
  String get chatHistory => '历史会话';

  @override
  String get noChatsYet => '暂无会话';

  @override
  String get toggleLightOrDarkTheme => '切换明暗主题';

  @override
  String editCategorylist(Object v0) {
    return '编辑$v0';
  }

  @override
  String dragToReorder(Object v0) {
    return '拖动排序$v0';
  }

  @override
  String expandSubcategoriesOf(Object v0) {
    return '展开$v0子分类';
  }

  @override
  String get yesterdayGroup => '昨天';

  @override
  String get lastDays => '近 7 天';

  @override
  String get earlier => '更早';

  @override
  String get openMenu => '打开菜单';

  @override
  String get searchChatsAndTasks => '搜索会话和待办';

  @override
  String get openDailyOverview => '打开今日总览';

  @override
  String get newChatBuild => '新建会话';

  @override
  String get chatOptions => '会话选项';

  @override
  String image(Object v0) {
    return '图片「$v0」：';
  }

  @override
  String get takeALookAtThisImage => '请帮我看看这张图片';

  @override
  String contentTruncated(Object v0) {
    return '$v0\n…（内容过长已截断）';
  }

  @override
  String contentsOf(Object v0, Object v1) {
    return '文件「$v0」的内容：\n$v1';
  }

  @override
  String contentsOfSubmitwithattachment(Object v0, Object v1, Object v2) {
    return '$v0\n\n文件「$v1」的内容：\n$v2';
  }

  @override
  String get connectAnAccountInModelsAndUsage => '请先在「模型与额度」连接账户';

  @override
  String get addToChat => '添加到对话';

  @override
  String get takePhoto => '拍照';

  @override
  String get chooseImage => '选择图片';

  @override
  String get fileTooLargeImagesUpToMb => '文件过大。图片限 10 MB，文本文件限 512 KB。';

  @override
  String get couldntReadTheImageChooseAStatic => '图片无法读取，请选择静态 PNG 或 JPEG。';

  @override
  String get couldntReadTheFileTryAgain => '文件读取失败，请重试。';

  @override
  String get holdToTranscribe => '按住转文字';

  @override
  String get askAnything => '尽管问…';

  @override
  String get holdToRecordReleaseToSend => '按住开始录音，松开发送';

  @override
  String get holdToTalk => '按住说话';

  @override
  String get stopGenerating => '停止生成';

  @override
  String get sendMessage => '发送消息';

  @override
  String get switchToKeyboard => '切换键盘输入';

  @override
  String get switchToVoice => '切换语音输入';

  @override
  String get addAttachment => '添加附件';

  @override
  String attachmentToSend(Object v0) {
    return '待发送附件：$v0';
  }

  @override
  String get removeAttachment => '移除附件';

  @override
  String tomorrowFormatdue(Object v0) {
    return '明天 $v0';
  }

  @override
  String dayAfterTomorrow(Object v0) {
    return '后天 $v0';
  }

  @override
  String formattedValueExportlabel(Object v0, Object v1, Object v2) {
    return '$v0月$v1日 $v2';
  }

  @override
  String get monFormatrelative => '周一';

  @override
  String get tueFormatrelative => '周二';

  @override
  String get wedFormatrelative => '周三';

  @override
  String get thuFormatrelative => '周四';

  @override
  String get friFormatrelative => '周五';

  @override
  String get satFormatrelative => '周六';

  @override
  String get sun => '周日';

  @override
  String get stopped => '已停止';

  @override
  String get thinking => '正在想…';

  @override
  String get connectModel => '连接模型';

  @override
  String get chooseModel => '选择模型';

  @override
  String chooseModelBuild(Object v0) {
    return '选择模型，$v0';
  }

  @override
  String get couldntLoadModelSettings => '暂时无法载入模型配置';

  @override
  String get couldntSwitchModelsTurnAutomaticFallbackBack =>
      '模型未能切换，自动换用已关闭，请重新开启';

  @override
  String get couldntSwitchTryAgainLater => '暂时无法切换，请稍后重试';

  @override
  String get backToProviders => '返回供应商列表';

  @override
  String get automaticFallback => '自动换用';

  @override
  String get addModelAccount => '添加模型账户';

  @override
  String get manageAccounts => '管理账户';

  @override
  String account(Object v0) {
    return '账户 $v0 ';
  }

  @override
  String get accountRemovedGoBackAndChooseAnother => '账户已移除，返回重新选择';

  @override
  String get deepThinking => '深度思考';

  @override
  String get voiceInputFailedYourTranscriptIsSaved => '语音输入遇到问题，已保留识别文字';

  @override
  String get taskUndone => '已撤销这条待办';

  @override
  String get theTaskChangedAndCannotBeRestored => '内容已变化，无法恢复这条待办';

  @override
  String completedToggledone(Object v0) {
    return '已完成 $v0';
  }

  @override
  String get updatedEdittodo => '已修改';

  @override
  String get nextWeekBuild => '下周';

  @override
  String get preparingMicrophone => '准备录音中';

  @override
  String get recording => '正在录音';

  @override
  String get transcribingAudio => '正在识别语音';

  @override
  String get voiceReadyToSend => '语音待发送';

  @override
  String get sendingVoiceInput => '正在发送语音';

  @override
  String get typeAMessage => '输入消息';

  @override
  String get tapToTypeHoldToTranscribe => '点按输入，长按转文字';

  @override
  String get activateToDictateOrHoldToRecord => '激活开始听写，或长按录音';

  @override
  String get activateToFinishRecordingAndSendThe => '激活结束录音，识别后发送';

  @override
  String get cancelVoiceInputOrSwitchToThe => '可取消语音输入或切换键盘';

  @override
  String get preparingToRecord => '准备录音';

  @override
  String get releaseToCancel => '松开取消';

  @override
  String get releaseToEdit => '松开编辑';

  @override
  String get releaseToSend => '松开发送';

  @override
  String get transcribing => '正在识别';

  @override
  String get sendingShortly => '即将发送';

  @override
  String get endRecording => '结束录音';

  @override
  String get voiceInput => '语音输入';

  @override
  String get listening => '正在听…';

  @override
  String get cancelVoiceInput => '取消语音输入';

  @override
  String get editTranscript => '编辑转写';

  @override
  String get offlineSpeechRecognition => '离线语音识别';

  @override
  String get offlineModelReady => '离线模型已就绪';

  @override
  String get startVoiceInput => '开始语音输入';

  @override
  String get transcribesOnThisDeviceWithTheBuilt => '使用内置模型在本机转写，无需联网。';

  @override
  String get installingTheBuiltInOfflineModel => '正在安装内置离线模型…';

  @override
  String downloadAboutMb(Object v0) {
    return '联网下载（约 $v0 MB）';
  }

  @override
  String get cancelDownload => '取消下载';

  @override
  String get retryDownload => '重试下载';

  @override
  String get reinstallBuiltInModel => '重新安装内置模型';

  @override
  String get installBuiltInOfflineModel => '安装内置离线模型';

  @override
  String downloadInsteadAboutMb(Object v0) {
    return '改为联网下载（约 $v0 MB）';
  }

  @override
  String downloadedOfMb(Object v0, Object v1) {
    return '已下载 $v0 / $v1 MB';
  }

  @override
  String modelsAndUsage(Object v0) {
    return '模型与额度，$v0';
  }

  @override
  String get remainingBuild => '剩余';

  @override
  String get closeSearch => '关闭搜索';

  @override
  String get noResults => '无搜索结果';

  @override
  String get goToChat => '去对话页';

  @override
  String get analysisDiscarded => '已丢弃本次分析结果';

  @override
  String get chooseFromPhotos => '从相册选择';

  @override
  String get rowAdded => '已添加一行';

  @override
  String exportedRowsTo(Object v0, Object v1) {
    return '已导出 $v0 行 $v1';
  }

  @override
  String get exportFailedTryAgain => '导出失败，请重试';

  @override
  String get changeType => '修改类型';

  @override
  String get manageFields => '管理字段';

  @override
  String get exportCsv => '导出 CSV';

  @override
  String get archiveThisTable => '归档这张表？';

  @override
  String get archivedTablesAreHiddenFromTheList => '归档后不在列表显示，数据仍保留。';

  @override
  String get deleteTable => '删除表';

  @override
  String get deleteThisTable => '删除这张表？';

  @override
  String get youCanUndoTheDeletion => '删除后仍可通过撤销恢复。';

  @override
  String alsoDeletesRowsYouCanUndoThe(Object v0) {
    return '将同时删除 $v0 行记录；删除后仍可通过撤销恢复。';
  }

  @override
  String renamedTo(Object v0) {
    return '已重命名为「$v0」';
  }

  @override
  String get source => '来源';

  @override
  String get addedByMe => '我录入的';

  @override
  String get addedByAi => 'AI 写入的';

  @override
  String get recentlyUpdatedFirst => '最近更新优先';

  @override
  String get firstFieldAZ => '首字段 A → Z';

  @override
  String get firstFieldZA => '首字段 Z → A';

  @override
  String get noMatchingRecords => '没有匹配的记录';

  @override
  String noResultsFor(Object v0) {
    return '没有找到「$v0」';
  }

  @override
  String get adjustTheFiltersOrTryAnotherKeyword => '调整筛选条件，或换个关键词';

  @override
  String get clearFilters => '清除筛选';

  @override
  String results(Object v0) {
    return '共 $v0 条结果';
  }

  @override
  String get loadMore => '加载更多';

  @override
  String get tableUnavailable => '这张表不在了';

  @override
  String get itMayHaveBeenArchivedOrDeleted => '它可能被归档或删除了';

  @override
  String get backToList => '返回列表';

  @override
  String get tableSettings => '表设置';

  @override
  String get importScreenshot => '截图导入';

  @override
  String get newRow => '新建行';

  @override
  String rows(num v0) {
    return '$v0 行';
  }

  @override
  String get aiChangesAwaitingReview => '有待确认的 AI 变更';

  @override
  String get searchRows => '搜索行';

  @override
  String get filter => '筛选';

  @override
  String get noDataYet => '还没有数据';

  @override
  String get createARow => '新建一行';

  @override
  String get changeHistory => '变更历史';

  @override
  String get copyRow => '复制此行';

  @override
  String get rowCopied => '已复制此行';

  @override
  String get deleteThisRow => '删除这行？';

  @override
  String willBeDeletedYouCanReviewIt(Object v0) {
    return '「$v0」将被删除，可在变更历史里追溯。';
  }

  @override
  String get recordBuild => '记录';

  @override
  String get untitled => '（未命名）';

  @override
  String createdCreatetable(Object v0) {
    return '已创建「$v0」';
  }

  @override
  String get createFromTemplate => '从模板新建';

  @override
  String createFromTemplateShowtemplates(Object v0) {
    return '从模板新建：$v0';
  }

  @override
  String fields(num v0) {
    return '$v0 字段';
  }

  @override
  String get dataTables => '核心数据';

  @override
  String tables(num v0) {
    return '$v0 张表';
  }

  @override
  String get recentlyUpdated => '最近更新';

  @override
  String get noMatchingTables => '没有匹配的数据表';

  @override
  String get noTablesYet => '还没有数据表';

  @override
  String get newTable => '新建表';

  @override
  String get searchTables => '搜索数据表';

  @override
  String fieldsRows(Object v0, Object v1, Object v2) {
    return '$v0 字段 $v1 行 $v2';
  }

  @override
  String fieldsRowsAiChangesToReview(
    Object v0,
    Object v1,
    Object v2,
    Object v3,
  ) {
    return '$v0，$v1 字段 $v2 行，有 $v3 处 AI 待确认变更';
  }

  @override
  String fieldsRowsBuild(Object v0, Object v1, Object v2) {
    return '$v0，$v1 字段 $v2 行';
  }

  @override
  String csvExported(Object v0) {
    return '已导出 CSV $v0';
  }

  @override
  String get copyTableStructure => '复制表结构';

  @override
  String copy(Object v0) {
    return '$v0 副本';
  }

  @override
  String createdCopy(Object v0) {
    return '已复制出「$v0」';
  }

  @override
  String get archivedTablesAreHiddenArchiveATable => '归档后不在列表显示，数据仍保留。删除需先进归档。';

  @override
  String archivedShowcontextsheet(Object v0) {
    return '已归档「$v0」';
  }

  @override
  String get addRow => '新增一行';

  @override
  String get discardThisAnalysis => '丢弃本次分析结果？';

  @override
  String get includesOneDeletionDiscardingRemovesThisAi =>
      '包含 1 处删除，丢弃后 AI 本次的分析结果不会保留。';

  @override
  String get discard => '丢弃';

  @override
  String aiProposesChanges(Object v0) {
    return 'AI 想写入 $v0 处变更';
  }

  @override
  String get viewSource => '查看来源';

  @override
  String from(Object v0) {
    return '来自$v0 ›';
  }

  @override
  String applySelected(Object v0) {
    return '应用所选 ($v0)';
  }

  @override
  String get deselect => '取消勾选';

  @override
  String get selectLabelBuild => '勾选';

  @override
  String aiAddedRows(Object v0) {
    return 'AI 新增了 $v0 行';
  }

  @override
  String aiMadeChanges(Object v0) {
    return 'AI 更新了 $v0 处';
  }

  @override
  String get undoneChangesReverted => '已撤销，改动已还原';

  @override
  String get aiEdits => 'AI 写入';

  @override
  String aiChangesAwaitingReviewBuild(Object v0) {
    return '有 $v0 处 AI 待确认变更';
  }

  @override
  String review(Object v0) {
    return '待确认 $v0';
  }

  @override
  String get confirm => '确认';

  @override
  String chooseType(Object v0) {
    return '选择类型$v0';
  }

  @override
  String typeBuild(Object v0) {
    return '类型：$v0';
  }

  @override
  String get aiIsUnsurePleaseVerify => 'AI 不太确定，请核对';

  @override
  String get enterText => '输入内容';

  @override
  String get enterANumber => '请输入数字';

  @override
  String get clear => '清除';

  @override
  String get currency => '金额';

  @override
  String get boolean => '布尔';

  @override
  String get deletionUnavailable => '暂时无法删除';

  @override
  String get tooManyRecordsUseThisFieldTo => '使用该字段的记录过多，暂不支持在此删除';

  @override
  String get gotIt => '知道了';

  @override
  String deleteField(Object v0) {
    return '删除字段「$v0」？';
  }

  @override
  String get thisFieldHasNoValues => '该字段没有已填数据。';

  @override
  String alsoClearsThisFieldInRows(Object v0) {
    return '同时清除 $v0 行记录中的字段值。';
  }

  @override
  String get fieldDeleted => '已删除字段';

  @override
  String get enterOneOfTheOptions => '填选项之一';

  @override
  String enterAnOptionEG(Object v0) {
    return '填选项之一，如「$v0」';
  }

  @override
  String get eG => '如 3.5';

  @override
  String get eGBackfillhint => '如 1250.00';

  @override
  String get defaultForExistingRecords => '为现有记录填入的默认内容';

  @override
  String get fieldNameIsRequired => '字段名不能为空';

  @override
  String get provideAtLeastOneCommaSeparatedOption => '至少提供一个选项（用逗号分隔）';

  @override
  String get fieldAdded => '已添加字段';

  @override
  String fieldsBuildfieldlist(Object v0) {
    return '共 $v0 个字段';
  }

  @override
  String get noFieldsYet => '还没有字段';

  @override
  String get addFieldBuildfieldlist => '添加字段';

  @override
  String get fieldNameBuildaddform => '字段名称';

  @override
  String get options => '选项';

  @override
  String get commaSeparated => '用逗号分隔';

  @override
  String optionsBuildaddform(num v0) {
    return '$v0 个选项';
  }

  @override
  String get unitOptional => '单位（可选）';

  @override
  String get eGSharesMinutes => '如：股、分钟';

  @override
  String get decimalPlaces => '精度（小数位）';

  @override
  String get setADefaultForExistingRecords => '为现有记录补默认值';

  @override
  String appliesToAllExistingRows(Object v0) {
    return '将写入全部 $v0 行现有记录';
  }

  @override
  String renameBuild(Object v0) {
    return '重命名「$v0」';
  }

  @override
  String deleteLabelBuild2(Object v0) {
    return '删除「$v0」';
  }

  @override
  String get renameField => '重命名字段';

  @override
  String get justNow => '刚刚';

  @override
  String minAgo(Object v0) {
    return '$v0 分钟前';
  }

  @override
  String get switchLabel => '开关';

  @override
  String get thisRow => '这行记录';

  @override
  String get couldntLoadChangeHistory => '暂时无法读取变更历史';

  @override
  String get noChangesYet => '暂无变更记录';

  @override
  String get restoreThisVersion => '回滚到这次修改？';

  @override
  String restoresTheVersionFromTheRestoreWill(Object v0) {
    return '将回到 $v0 的版本。回滚本身也会留下一条记录。';
  }

  @override
  String restoresTheVersionFromAndUndoesLater(Object v0, Object v1) {
    return '将回到 $v0 的版本，此后的 $v1 次变更也会被撤销。回滚本身也会留下一条记录。';
  }

  @override
  String get restoreVersion => '回滚';

  @override
  String restoredTheVersionFrom(Object v0) {
    return '已回滚到 $v0 的版本';
  }

  @override
  String get me => '我';

  @override
  String get createdThisRow => '新建了这行';

  @override
  String get deletedThisRow => '删除了这行';

  @override
  String get viewOriginalImage => '查看原图';

  @override
  String viewOriginal(Object v0) {
    return '$v0 查看原图 ▸';
  }

  @override
  String get imageTooLargeChooseAPngOr => '图片过大。请选择 10 MB 以内的 PNG/JPEG，或裁剪后重试。';

  @override
  String get couldntReadThisImageChooseAComplete =>
      '无法读取这张图片，请选择完整的静态 PNG 或 JPEG。';

  @override
  String get theOriginalAndItsCopyAreUnavailable => '原图或图片副本已不可用，请重新选择图片。';

  @override
  String get thisImageIsLinkedToARecognition => '这张图片已关联识别记录，需要保留用于历史溯源。';

  @override
  String get couldntReadOrSaveTheImageExisting => '暂时无法保存或读取图片，已保存的数据会保留。';

  @override
  String get addTheClearlyIdentifiableRecordsToThis =>
      '将图中可明确识别的记录新增到此表；不确定的内容请先询问我。';

  @override
  String imageStart(Object v0, Object v1) {
    return '图片「$v0」：$v1';
  }

  @override
  String get unavailableBuild => '已不可用';

  @override
  String targetTable(Object v0) {
    return '目标表：$v0';
  }

  @override
  String get stopRecognition => '停止识别';

  @override
  String get savedImages => '已保存的图片';

  @override
  String get saved => '已保存';

  @override
  String get incompleteFileChooseItAgain => '文件不完整，请重新选择';

  @override
  String get removeUnusedImage => '移除未使用图片';

  @override
  String get retryReading => '重试读取';

  @override
  String get importInstructions => '导入要求';

  @override
  String get addRecordsOrSpecifyWhichRecordsTo => '新增记录或指定要更新的记录';

  @override
  String get theImageWillBeSentToThe => '图片将发送至当前模型并使用账户额度。';

  @override
  String get analyzeAndImport => '分析并导入';

  @override
  String get viewSourceImage => '查看来源图片';

  @override
  String get thisRecordHasNoLinkedSourceImage => '这条记录没有已关联的来源图片。';

  @override
  String get demoImagePlaceholder => '纯 UI 演示 原图占位';

  @override
  String get closeImage => '关闭原图';

  @override
  String get enterATableName => '请输入表名';

  @override
  String fieldsBuild(Object v0) {
    return '字段（$v0）';
  }

  @override
  String deleteFieldBuild(Object v0) {
    return '删除字段$v0';
  }

  @override
  String get optionOneOptionTwo => '选项一\n选项二';

  @override
  String get enterUniqueOptionsOnePerLine => '请填写不重复的选项，每行一个';

  @override
  String get oneOptionPerLine => '每行一个选项';

  @override
  String get invalidContentOrFieldFormatCheckAnd => '内容或字段格式无效，请检查后重试';

  @override
  String get savingPleaseWait => '正在保存，请稍候';

  @override
  String get recordNoLongerExists => '这条记录已不存在';

  @override
  String get backToTable => '返回数据表';

  @override
  String get recordDetails => '记录详情';

  @override
  String get equals => '等于';

  @override
  String get containsRowFilterSheet => '包含';

  @override
  String get greaterThan => '大于';

  @override
  String get atLeast => '大于等于';

  @override
  String get lessThan => '小于';

  @override
  String get atMost => '小于等于';

  @override
  String enterANumberWithUpToDecimal(Object v0) {
    return '金额需为数字，且不超过 $v0 位小数';
  }

  @override
  String get addUpToFourFieldConditions => '按字段添加条件，最多 4 个';

  @override
  String conditions(Object v0) {
    return '共 $v0 个条件';
  }

  @override
  String get noFilterableFieldsInThisTable => '这张表还没有可筛选的字段';

  @override
  String get addCondition => '添加条件';

  @override
  String upToConditions(Object v0) {
    return '最多 $v0 个条件';
  }

  @override
  String get applyFilters => '应用筛选';

  @override
  String get removeCondition => '移除此条件';

  @override
  String get value => '取值';

  @override
  String get clearDate => '清除日期';

  @override
  String eGBuildvalueeditor(Object v0) {
    return '如 3.5（$v0）';
  }

  @override
  String get chooseDateAndTime => '选择日期时间';

  @override
  String get holdingsPng => '持仓_0921.png';

  @override
  String get fromTheHoldingsScreenshotAddedSharesOf =>
      '从持仓截图识别：加仓贵州茅台 200 股，新买入腾讯控股 300 股。';

  @override
  String get kweichowMoutaiShares => '贵州茅台 持仓(股)';

  @override
  String get shares => '500 股';

  @override
  String get kweichowMoutaiPrice => '贵州茅台 现价';

  @override
  String get tencentAdded => '腾讯控股 新增';

  @override
  String get tencentShares => '腾讯控股 持仓(股)';

  @override
  String get sharesBuildplan => '300 股';

  @override
  String get tencentCostBasis => '腾讯控股 成本价';

  @override
  String get tencent => '腾讯控股';

  @override
  String get costBasis => '成本价';

  @override
  String get receiptJpg => '接收单_0923.jpg';

  @override
  String get extractedAnArchiveReceiptFromThePhoto =>
      '从接收单照片提取一条档案接收记录，卷数字迹不太清楚。';

  @override
  String get analysisOfReceiptJpg => '截图「接收单_0923.jpg」的分析';

  @override
  String get archiveId => '档号';

  @override
  String get titleBuildplan => '题名';

  @override
  String get planningRecordsTransferredByTheHousingBureau => '住建局移交规划档案';

  @override
  String get volumesBuildplan => '卷数';

  @override
  String get transferringAgency => '移交单位';

  @override
  String get municipalHousingBureau => '市住建局';

  @override
  String get yearBuildplan => '年度';

  @override
  String get receivedDate => '接收日期';

  @override
  String get classification => '密级';

  @override
  String get internal => '内部';

  @override
  String get digitized => '已数字化';

  @override
  String get recordFromScreenshot => '截图提取的记录';

  @override
  String get screenshotPng => '截图_0923.png';

  @override
  String get foundARecordInTheScreenshotConfirm => '从截图里读出了一条记录，确认后写入。';

  @override
  String get analysisOfScreenshotPng => '截图「截图_0923.png」的分析';

  @override
  String importScreenshotBuild(Object v0) {
    return '截图导入$v0';
  }

  @override
  String get cancelImageAnalysis => '取消截图分析';

  @override
  String get startAnalysis => '开始分析';

  @override
  String get chooseAgain => '重选';

  @override
  String get extractionComplete => '提取完成';

  @override
  String get uploadingImage => '正在上传图片…';

  @override
  String get readingImage => 'AI 正在读图…';

  @override
  String get takingLongerThanExpected => '比预期慢，仍在努力…';

  @override
  String get monthlyCredits => '每月积分';

  @override
  String credits(Object v0) {
    return '$v0 点';
  }

  @override
  String get modelAccess => '模型接入';

  @override
  String get context => '上下文';

  @override
  String get yourOwnApiKey => '自有 API Key';

  @override
  String get shortContext => '短上下文';

  @override
  String get yearlyBuild => '年付';

  @override
  String get monthlyBuild2 => '月付';

  @override
  String get toworkMembership => 'ToWork 会员';

  @override
  String get closeMembership => '关闭会员';

  @override
  String get currentPlan => '当前方案';

  @override
  String switchTo(Object v0) {
    return '切换为 $v0';
  }

  @override
  String selectLabelBuild2(Object v0) {
    return '选择 $v0';
  }

  @override
  String get dismissSuccessAnimation => '关闭成功动画';

  @override
  String membership(Object v0) {
    return '$v0 会员';
  }

  @override
  String get planChanged => '方案已切换';

  @override
  String creditsPerMonth(Object v0) {
    return '每月 $v0 积分';
  }

  @override
  String membershipBadge(Object v0) {
    return '$v0 会员徽标';
  }

  @override
  String get memoryIsPausedResumeItInSettings => '记忆已暂停，先在设置里恢复';

  @override
  String get invalidContentOrType => '内容或类型无效';

  @override
  String get couldntSaveTryAgain => '暂时无法保存，请重试';

  @override
  String get resumeMemoryToAddAnItem => '免记忆模式下不可新增';

  @override
  String get remembered => '已记住';

  @override
  String get updatedOpeneditor => '已更新';

  @override
  String get rememberAgain => '重新记住';

  @override
  String get originalChatNoLongerExists => '原会话已不存在';

  @override
  String get memoryRestored => '已恢复记忆';

  @override
  String get memoryCleared => '记忆库已清空';

  @override
  String get memoryLibrary => '记忆库';

  @override
  String get onLabel => '开启';

  @override
  String memoryOffModeIs(Object v0) {
    return '免记忆模式，当前$v0';
  }

  @override
  String get moreActions => '更多操作';

  @override
  String get couldntLoadMemories => '记忆读取失败';

  @override
  String get searchMemories => '搜索记忆';

  @override
  String get newMemory => '新增记忆';

  @override
  String get memoryIsOffNewChatsWontAdd => '免记忆模式已开启，新对话不会写入记忆库';

  @override
  String get resumeMemory => '关闭免记忆模式';

  @override
  String get noMemoriesYet => '还没有记忆';

  @override
  String get noMatchingMemories => '暂无相关记忆';

  @override
  String hrAgo(Object v0) {
    return '$v0 小时前';
  }

  @override
  String daysAgo(Object v0) {
    return '$v0 天前';
  }

  @override
  String memoryConfidence(Object v0, Object v1, Object v2) {
    return '$v0记忆，$v1，置信度$v2';
  }

  @override
  String get expiredBuild => '，已过期';

  @override
  String doubleTapToExpandHoldForActions(Object v0) {
    return '$v0。双击展开，长按操作。';
  }

  @override
  String get extractedByAi => 'AI 提取';

  @override
  String get manual => '手动';

  @override
  String get pendingReview => '待确认';

  @override
  String confidence(Object v0) {
    return '置信度 $v0';
  }

  @override
  String expiresInDays(int v0) {
    return '$v0 天后失效';
  }

  @override
  String openSourceChat(Object v0) {
    return '跳转到来源会话 $v0';
  }

  @override
  String fromChatShowmemorydetailsheet(Object v0) {
    return '来自会话「$v0」';
  }

  @override
  String formattedValueDate(Object v0, Object v1, Object v2) {
    return '$v0年$v1月$v2日';
  }

  @override
  String get memoryDetails => '记忆详情';

  @override
  String get addedManually => '手动添加';

  @override
  String get confidenceShowmemorydetailsheet => '置信度';

  @override
  String get retention => '时效';

  @override
  String get noExpiration => '长期有效';

  @override
  String get expiredShowmemorydetailsheet => ' 已过期';

  @override
  String get expires => '失效';

  @override
  String get viewOriginalChat => '查看原会话';

  @override
  String get copyShowmemorydetailsheet => '复制';

  @override
  String get longTerm => '长期';

  @override
  String expiresExpirylabel(Object v0, Object v1, Object v2) {
    return '$v0-$v1-$v2 失效';
  }

  @override
  String get editMemory => '编辑记忆';

  @override
  String get memoryRetention => '记忆时效';

  @override
  String get customDate => '自定义日期';

  @override
  String get chatBuild => '会话';

  @override
  String memoryBuild(Object v0, Object v1) {
    return '记忆：$v0，$v1';
  }

  @override
  String get moreFilters => '更多筛选';

  @override
  String get memoryRules => '记忆规则';

  @override
  String get clearAllMemories => '清空全部记忆';

  @override
  String get theAiRemembersInformationYouMentionThat => 'AI 会记住你提过、以后还会用到的信息。';

  @override
  String get longTermPreferences => '长期偏好';

  @override
  String get leadWithTheConclusion => '答复先给结论';

  @override
  String get recurringWorkflows => '固定流程';

  @override
  String get groupWeeklyReportsByProject => '周报按项目分组';

  @override
  String get responsibilities => '稳定职责';

  @override
  String get iHandleContractApprovals => '我负责合同审批';

  @override
  String get projectAgreements => '项目约定';

  @override
  String get useTheSignedVersionForAcceptance => '验收以签字版为准';

  @override
  String get terminology => '术语别名';

  @override
  String get northMeansTheNorthChinaProjectTeam => '“北区”指华北项目组';

  @override
  String get corrections => '事实纠正';

  @override
  String get weeklyReportsAreNowDueOnThursdays => '周报改为每周四提交';

  @override
  String get youCanPauseMemoryAtAnyTime => '可随时开启免记忆模式。';

  @override
  String get copyContent => '复制内容';

  @override
  String get deleteThisMemory => '删除这条记忆？';

  @override
  String get theAiWillNoLongerRememberIt => 'AI 之后将不再记得它。';

  @override
  String get pauseMemory => '开启免记忆模式';

  @override
  String get newChatsWontAddMemoriesExistingMemories => '新对话不再写入记忆库。已有记忆保留。';

  @override
  String get clearAllMemoriesShowclearallconfirm => '清空全部记忆？';

  @override
  String deletesAllMemoriesIncludingAiExtractedAnd(Object v0) {
    return '将删除全部 $v0 条记忆，包括 AI 提取与手动添加的内容。此操作不可撤销，AI 会重新开始了解你。';
  }

  @override
  String get holdForOneSecondToConfirmClearing => '全部清空，需长按 1 秒确认';

  @override
  String get keepHolding => '继续按住…';

  @override
  String get holdForSecondToClear => '长按 1 秒清空';

  @override
  String get closeQuickAsk => '关闭快问';

  @override
  String get quickAsk => '快问';

  @override
  String get collapseQuickAsk => '收起快问面板';

  @override
  String get expandQuickAsk => '展开快问面板';

  @override
  String get copiedAsMarkdown => '已复制，Markdown 格式';

  @override
  String exported(Object v0) {
    return '已导出 $v0';
  }

  @override
  String get shareReport => '分享报告';

  @override
  String get exportMarkdown => '导出 Markdown';

  @override
  String get copyFullText => '复制全文';

  @override
  String get regenerate => '重新生成？';

  @override
  String get rebuildsThisReportUsingTheLatestData => '将用最新数据重新生成本期报告，当前内容会被覆盖。';

  @override
  String get regenerateConfirmregenerate => '重新生成';

  @override
  String get deleteThisReport => '删掉这份报告？';

  @override
  String get sourceDataWillBeKept => '删除报告后保留原始数据。';

  @override
  String get reportDeleted => '报告已删除';

  @override
  String get countingCompletedTasks => '统计完成事项';

  @override
  String get summarizingCategories => '汇总分类';

  @override
  String get aggregatingData => '汇总数据';

  @override
  String get generatingSummary => '生成总结';

  @override
  String get theReportWillContinueInTheBackground => '报告在后台继续写，好了会通知你';

  @override
  String get stopGeneratingConfirmstop => '停止生成？';

  @override
  String get thePartialDraftWillBeDiscarded => '已写的内容会被丢弃。';

  @override
  String get keepGenerating => '继续生成';

  @override
  String get stop => '停止';

  @override
  String get markUnread => '标为未读';

  @override
  String get markRead => '标为已读';

  @override
  String get markedUnread => '已标为未读';

  @override
  String get markedRead => '已标为已读';

  @override
  String get generating => '生成中';

  @override
  String get share => '分享';

  @override
  String get aboutSeconds => '预计 10–30 秒';

  @override
  String get thisReportHasBeenDeleted => '这份报告已被删除';

  @override
  String dataForWasntAvailableInTimeThis(Object v0) {
    return '$v0分类的数据没赶上，本报告按现有数据生成';
  }

  @override
  String user(Object v0) {
    return '- 用户：$v0';
  }

  @override
  String added(Object v0) {
    return '- 新增：$v0';
  }

  @override
  String completedReportmarkdown(Object v0) {
    return '- 完成：$v0';
  }

  @override
  String completionRate(Object v0) {
    return '- 完成率：$v0';
  }

  @override
  String unfinishedAtPeriodEndIncludingOverdue(Object v0, Object v1) {
    return '- 期末未完成：$v0，其中逾期：$v1';
  }

  @override
  String tableRecordsIncludingAddedThisPeriod(Object v0, Object v1) {
    return '- 业务表记录：$v0 条，周期内新增 $v1 条';
  }

  @override
  String completedLastPeriod(Object v0) {
    return '- 上期完成：$v0';
  }

  @override
  String get categories => '## 分类';

  @override
  String get categoryAddedCompleted => '| 分类 | 新增 | 完成 |';

  @override
  String get summaryReportmarkdown => '## 总结';

  @override
  String get noSummaryYet => '（总结尚未生成）';

  @override
  String method(Object v0) {
    return '口径：$v0';
  }

  @override
  String snapshot(Object v0) {
    return '快照：$v0';
  }

  @override
  String monthWeek(Object v0, Object v1, Object v2) {
    return '$v0月第$v1周（$v2）';
  }

  @override
  String formattedValueProductionperiodlabel(Object v0, Object v1) {
    return '$v0年$v1月';
  }

  @override
  String weeklyReportMonthWeek(Object v0, Object v1) {
    return '$v0月第$v1周周报';
  }

  @override
  String monthlyReportProductionnavtitle(Object v0, Object v1) {
    return '$v0年$v1月月报';
  }

  @override
  String get customReport => '自定义报告';

  @override
  String get awaitingSummary => '待总结';

  @override
  String get summarized => '已总结';

  @override
  String get failed => '失败';

  @override
  String weeklyReportReportnavtitle(Object v0) {
    return '$v0周报';
  }

  @override
  String monthlyReportReportnavtitle(Object v0) {
    return '$v0月报';
  }

  @override
  String get vsLastWeek => '较上周';

  @override
  String get vsLastMonth => '较上月';

  @override
  String get vsLastPeriod => '较上期';

  @override
  String get hourQuotaExhaustedResetsAtTheEnd => '5 小时额度已用尽，窗口结束后恢复';

  @override
  String get quotaExhaustedForThisPeriodResetsNext => '本期额度已用尽，下周期恢复';

  @override
  String get reportGenerationFailed => '报告生成失败';

  @override
  String get generateReport => '生成报告';

  @override
  String get searchReports => '搜索报告';

  @override
  String get noReportsYet => '还没有报告';

  @override
  String get noReports => '暂无报告';

  @override
  String get noMatchingReports => '没有找到相关报告';

  @override
  String get generatingBuild => '生成中…';

  @override
  String completedBuild2(Object v0) {
    return ' 完成 $v0 项';
  }

  @override
  String get unread => '。未读';

  @override
  String couldntGenerate(Object v0) {
    return '$v0没写成';
  }

  @override
  String get lastWeek => '上周';

  @override
  String get thisMonth => '本月';

  @override
  String get lastMonth => '上月';

  @override
  String weekSubmit(Object v0) {
    return '第 $v0 周';
  }

  @override
  String get period => '周期';

  @override
  String formattedValueBuild4(Object v0, Object v1) {
    return '$v0 月 $v1 日';
  }

  @override
  String get includedCategories => '包含分类';

  @override
  String get clearAll => '清空';

  @override
  String get selectAll => '全选';

  @override
  String get saveAsDefaultForScheduledReports => '保存为定时报告默认范围';

  @override
  String get weeklyOnMondayAtMonthlyOnThe => '周报 周一 08:00　月报 每月 1 日 08:00';

  @override
  String get adjustInScheduledReports => '在「定时报告」一节调整';

  @override
  String get adjustScheduledReports => '去调整定时报告';

  @override
  String get adjust => '去调整 ›';

  @override
  String chooseDateBuild3(Object v0) {
    return '选择日期：$v0';
  }

  @override
  String posterSaved(Object v0) {
    return '海报已保存：$v0';
  }

  @override
  String get posterExportFailedTryAgain => '海报导出失败，请重试';

  @override
  String get markdownCopied => '已复制 Markdown';

  @override
  String get summaryFailedYouCanRetry => '总结生成失败，可重试';

  @override
  String get couldntReadReport => '报告读取失败';

  @override
  String get localSnapshotRetained => '本地快照已保留。';

  @override
  String get reportNotFound => '找不到这份报告';

  @override
  String get tasksCreatedDuringThePeriod => '周期内创建的待办';

  @override
  String get unfinishedAtPeriodEnd => '期末未完成';

  @override
  String get byCategory => '分类分布';

  @override
  String get dataRows => '数据行';

  @override
  String get poster => '海报';

  @override
  String get exportPosterPng => '导出海报 PNG';

  @override
  String get copyMarkdown => '复制 Markdown';

  @override
  String completionRateCompletioncard(Object v0) {
    return '完成率 $v0';
  }

  @override
  String get noCategoryRecordsThisPeriod => '本周期没有分类记录';

  @override
  String createdCompleted(Object v0, Object v1) {
    return '创建 $v0 完成 $v1';
  }

  @override
  String get noPreviousCompletionRate => '上期无完成率';

  @override
  String previousPeriod(Object v0) {
    return '$v0（上期 ';
  }

  @override
  String get noPreviousRecords => '上期无记录';

  @override
  String get itemsComparelist => '项';

  @override
  String itemsComparelist2(Object v0) {
    return '$v0 项）';
  }

  @override
  String get completionRateBuildpie => '完成率';

  @override
  String totalRows(Object v0) {
    return '数据行 共 $v0 条';
  }

  @override
  String rowsAddedThisPeriod(Object v0) {
    return '本期新增 $v0 条';
  }

  @override
  String get aiSummary => 'AI 总结';

  @override
  String get summaryFailedSnapshotRetained => '总结生成失败，快照已保留。';

  @override
  String get kimiWritesTheSummaryUsingTheFigures =>
      '由 Kimi 根据本页冻结的数字撰写，只会引用已有数字。';

  @override
  String get retrySummary => '重试总结';

  @override
  String get reportServiceUnavailable => '报告服务不可用';

  @override
  String get generatingReport => '正在生成报告';

  @override
  String get generate => '生成';

  @override
  String get generateThisWeeksReport => '生成本周周报';

  @override
  String get generateThisMonthsReport => '生成本月月报';

  @override
  String periodUsesTheTimeZone(Object v0) {
    return '周期按 $v0 时区计算';
  }

  @override
  String completionRateBuild(Object v0) {
    return '完成率 $v0。';
  }

  @override
  String get aiObservationsAndSuggestions => 'AI 观察与建议';

  @override
  String get upcomingTasksBullets => '下期待办';

  @override
  String get nextMonthsFocus => '下月关注';

  @override
  String get aiGeneratedContent => 'AI 生成内容';

  @override
  String get aiInsights => 'AI 洞察';

  @override
  String weeklyReportPeriodlabel(Object v0, Object v1) {
    return '周报 $v0/$v1–';
  }

  @override
  String sToworkReport(Object v0) {
    return '$v0 的 ToWork 报告';
  }

  @override
  String methodThisPeriod(Object v0, Object v1, Object v2) {
    return '口径：$v0（本次 $v1/$v2）';
  }

  @override
  String get completedByCategory => '分类完成';

  @override
  String completedAdded(Object v0, Object v1) {
    return '$v0 完成 $v1 新增';
  }

  @override
  String get summaryBuild => '总结';

  @override
  String get noSummaryYetOpenTheReportTo => '总结尚未生成，可在报告中查看或生成。';

  @override
  String get noPreviousComparison => '无上期对比';

  @override
  String addedDonecard(Object v0) {
    return '新增 $v0 项';
  }

  @override
  String get needsAttention => '需关注';

  @override
  String get noneOverdue => '无逾期';

  @override
  String get newData => '新增数据';

  @override
  String get appearance => '外观';

  @override
  String get theme => '主题';

  @override
  String get systemDefault => '跟随系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get textSize => '字号';

  @override
  String get small => '小';

  @override
  String get standard => '标准';

  @override
  String get large => '大';

  @override
  String get newMoon => '新月';

  @override
  String get aGoodTimeToStartAList => '适合开一张新清单';

  @override
  String get waxingCrescent => '娥眉月';

  @override
  String get aGoodTimeToBegin => '适合起步';

  @override
  String get firstQuarter => '上弦月';

  @override
  String get aGoodTimeToWrapUp => '适合收尾';

  @override
  String get waxingGibbous => '盈凸月';

  @override
  String get aGoodTimeForAFinalPush => '适合冲刺';

  @override
  String get fullMoon => '满月';

  @override
  String get aGoodTimeToCelebrate => '适合庆祝一下';

  @override
  String get waningGibbous => '亏凸月';

  @override
  String get aGoodTimeToReflect => '适合复盘';

  @override
  String get lastQuarter => '下弦月';

  @override
  String get aGoodTimeToDeclutter => '适合断舍离';

  @override
  String get waningCrescent => '残月';

  @override
  String get aGoodTimeForAnEarlyNight => '适合早睡';

  @override
  String tonight(Object v0, Object v1, Object v2) {
    return '$v0 今晚是$v1，$v2';
  }

  @override
  String get instructionsAdded => '已写说明';

  @override
  String vocabularyWords(Object v0) {
    return '$v0 个常用词';
  }

  @override
  String get notSetAssistantpreferencessummary => '未设置';

  @override
  String get savedAppliesFromTheNextChat => '已保存，下一次对话起生效';

  @override
  String eachTermCanHaveUpToCharacters(Object v0) {
    return '每个词最多 $v0 个字符';
  }

  @override
  String isAlreadyInTheList(Object v0) {
    return '「$v0」已经在列表里';
  }

  @override
  String limitTermsRemoveAnUnusedTermFirst(Object v0) {
    return '最多 $v0 个常用词，请先删除不用的';
  }

  @override
  String get assistantPreferences => '助手偏好';

  @override
  String get saveInstructions => '保存说明';

  @override
  String get customInstructions => '长期说明';

  @override
  String get eGReplyInEnglish => '例如：回复用简体中文';

  @override
  String get vocabulary => '常用词';

  @override
  String get personProjectOrProductName => '人名、项目名或产品名';

  @override
  String speechVocabulary(Object v0, Object v1) {
    return '语音词库 $v0/$v1';
  }

  @override
  String get whatTheModelReceives => '发送给模型的内容';

  @override
  String get eachRequestIncludesTheTimeYourName =>
      '每轮发送时间、称呼、长期说明和常用词。开启 Agent 后，另附分类及最多 12 条进行中待办的标题和截止时间。';

  @override
  String deleteTerm(Object v0) {
    return '删除常用词 $v0';
  }

  @override
  String get nameSavedOnThisDevice => '用户名已保存到此设备';

  @override
  String get useCharactersWithoutLineBreaksOrControl =>
      '用户名需要 1–40 个字符，不能包含换行或控制字符';

  @override
  String get profileChangedReloadBeforeSaving => '资料已变化，请重新载入后再保存';

  @override
  String get couldntReadOrSaveYourLocalProfile => '本地资料暂时无法读取或保存，请重试';

  @override
  String get profileBuild => '个人资料';

  @override
  String get saveName => '保存用户名';

  @override
  String get nameBuild => '用户名';

  @override
  String get enterAName => '输入用户名';

  @override
  String get reloadBuild => '重新载入';

  @override
  String get couldntReadLocalSettingsTryAgain => '本地配置暂时无法读取，请重试';

  @override
  String get quotaUpdated => '额度已更新';

  @override
  String get thisProviderDoesntOfferAQuotaApi => '这个服务商没有额度查询接口';

  @override
  String couldntCheckQuota(Object v0) {
    return '额度查询失败：$v0';
  }

  @override
  String get deleteThisAccount => '删除这个账户？';

  @override
  String theSettingsForAndTheKeySaved(Object v0) {
    return '$v0 的配置和保存在这台设备上的 Key 会一并删除，';
  }

  @override
  String get permanentlyChatHistoryIsRetained => '无法恢复。历史对话不受影响。';

  @override
  String get deleteAccount => '删除账户';

  @override
  String get accountDeleted => '账户已删除';

  @override
  String get manualOnly => '  仅手动';

  @override
  String priorityOpenmenu(Object v0, Object v1) {
    return '优先级 $v0$v1';
  }

  @override
  String get useThisAccount => '设为当前使用';

  @override
  String switchedToOpenmenu(Object v0) {
    return '已切换为 $v0';
  }

  @override
  String get editModelAndKey => '编辑模型与 Key';

  @override
  String get refreshQuota => '刷新额度';

  @override
  String get resumeAccount => '解除暂停';

  @override
  String get rejoinAutomaticFallback => '恢复参与自动换用';

  @override
  String get accountResumed => '已解除暂停';

  @override
  String get excludeFromFallback => '不参与自动换用';

  @override
  String get includeInFallback => '参与自动换用';

  @override
  String get increasePriority => '提高优先级';

  @override
  String get decreasePriority => '降低优先级';

  @override
  String get modelsAndUsageBuild => '模型与额度';

  @override
  String get switchAccountsByPriorityWhenQuotaRuns =>
      '额度用尽、限流或 Key 失效时，按优先级切换账户。';

  @override
  String get switchAutomaticallyWhenQuotaRunsOut => '额度用尽时自动换用';

  @override
  String get couldntReadLocalSettings => '本地配置暂时无法读取';

  @override
  String get noModelAccountsYet => '还没有模型账户';

  @override
  String get checkProviderConsole => '服务商控制台查询';

  @override
  String get inUseBuild => '，当前使用';

  @override
  String priorityBuild(Object v0, Object v1, Object v2) {
    return '$v0，优先级 $v1，$v2';
  }

  @override
  String get inUseBuild2 => '当前使用';

  @override
  String get connectedUnsaved => '连接成功（未保存）';

  @override
  String get connected => '连接成功';

  @override
  String get serviceRegion => '服务区域';

  @override
  String get china => '中国';

  @override
  String get international => '国际';

  @override
  String get chooseProvider => '选择服务商';

  @override
  String get editModelAccount => '编辑模型账户';

  @override
  String get apiEndpoint => '接口地址';

  @override
  String get savedLeaveBlankToKeep => '已保存，留空保留';

  @override
  String get enterKey => '输入密钥';

  @override
  String get cancelTest => '取消测试';

  @override
  String get testConnection => '测试连接';

  @override
  String get defaultAssistantEnabled => '已设为默认助手';

  @override
  String get notTheDefaultAssistant => '未设为默认助手';

  @override
  String get quickLaunch => '快捷唤醒';

  @override
  String get tryNow => '现在试一下';

  @override
  String get quickAskIsUnavailableOnThisDevice => '这台设备上暂时打不开快问面板';

  @override
  String get defaultAssistant => '默认助手';

  @override
  String get openQuickAskWithTheAssistantGesture =>
      '助手手势可唤起快问。电源键快捷操作由系统保留，第三方应用不能接管。';

  @override
  String get setAsDefaultAssistant => '设为默认助手应用';

  @override
  String get openSystemSettingsAppsDefaultAppsAnd =>
      '打不开系统设置，请到 系统设置 → 应用 → 默认应用 里选择 ToWork';

  @override
  String get otherShortcuts => '其他入口';

  @override
  String get addQuickAskToHomeScreen => '添加「快问」到桌面';

  @override
  String get theLauncherDidntAddTheShortcutHold =>
      '桌面没有接受这次请求，可以长按 ToWork 图标，把「快问」拖到桌面';

  @override
  String get addVoiceQuickAskToHomeScreen => '添加「语音快问」到桌面';

  @override
  String get theLauncherDidntAddTheShortcutHoldTheTowork =>
      '桌面没有接受这次请求，可以长按 ToWork 图标，把「语音快问」拖到桌面';

  @override
  String get systemShortcuts => '系统快捷功能';

  @override
  String get selectToworkQuickAskOrToworkVoice =>
      '在系统菜单中选「ToWork 快问」或「ToWork 语音快问」。';

  @override
  String get huaweiSmartControlDoubleTap => '华为智控键双触';

  @override
  String get confirmTheSystemPromptThenChooseQuick =>
      '确认系统的添加提示后，到「智控键 / 双触」选择快问或语音快问。';

  @override
  String get controlCenter => '控制中心';

  @override
  String get editTheQuickSettingsTilesAndAdd => '编辑快捷开关，添加「快问」。';

  @override
  String get selectTextOrShare => '选中文字或分享';

  @override
  String get chooseAskTowork => '选择「问 ToWork」。';

  @override
  String get holdTheAppIcon => '长按桌面图标';

  @override
  String get selectQuickAskOrVoiceQuickAsk => '选择「快问」或「语音快问」。';

  @override
  String get morningDigestTime => '每日晨报时间';

  @override
  String morningDigestSetTo(Object v0, Object v1) {
    return '晨报改到 $v0:$v1';
  }

  @override
  String get memoryPaused => '好的，这段时间我不会记东西';

  @override
  String get addKey => '添加 Key';

  @override
  String get accountBuild => '账号';

  @override
  String get accountDetails => '账号详情';

  @override
  String get privacyAndPermissions => '隐私与权限';

  @override
  String get aiWritePermissions => 'AI 写入权限';

  @override
  String get pauseMemoryBuild => '免记忆模式';

  @override
  String get inputAndQuickLaunch => '输入与唤醒';

  @override
  String get speechDiagnostics => '语音识别检测';

  @override
  String get defaultInputMethod => '默认输入方式';

  @override
  String get voice => '语音';

  @override
  String get keyboard => '键盘';

  @override
  String get couldntSaveTryAgainBuild => '未能保存，请重试';

  @override
  String get notifications => '通知';

  @override
  String get dueReminders => '截止提醒';

  @override
  String get morningDigest => '每日晨报';

  @override
  String get off => '已关闭';

  @override
  String get morningDigestSwitch => '每日晨报开关';

  @override
  String get reportReadyNotifications => '报告就绪提醒';

  @override
  String get notificationSettings => '通知与提醒设置';

  @override
  String get dataBackup => '数据备份';

  @override
  String get exportData => '一键导出';

  @override
  String get lastExport => '上次导出';

  @override
  String get about => '关于';

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get version => '版本';

  @override
  String get openSourceLicenses => '开源许可';

  @override
  String get noMatchingSettings => '没有找到相关设置';

  @override
  String get searchSettings => '搜索设置';

  @override
  String get neverExported => '尚未导出';

  @override
  String get revokeAiDataConsent => '撤回 AI 数据授权';

  @override
  String get consentRevoked => '已撤回授权';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get couldntOpen => '暂时无法打开';

  @override
  String get thisApiDoesntListModelsEnterA => '此接口未提供模型列表，可手动输入模型 ID。';

  @override
  String get fetchingModels => '正在获取模型';

  @override
  String get noAvailableModels => '没有可用模型';

  @override
  String get noMatchingModels => '无匹配模型';

  @override
  String get searchModels => '搜索模型';

  @override
  String get refreshModelList => '刷新模型列表';

  @override
  String get availableModels => '可用模型';

  @override
  String get customModel => '自定义模型';

  @override
  String get model => '模型';

  @override
  String get modelId => '模型 ID';

  @override
  String get enterModelId => '输入模型 ID';

  @override
  String get fetchModelList => '获取模型列表';

  @override
  String get selectAFetchedModel => '选择已获取的模型';

  @override
  String get provider => '服务商';

  @override
  String get current => '，当前';

  @override
  String get locked => '，未解锁';

  @override
  String aiWritePermissionsSetTo(Object v0) {
    return 'AI 写入权限已设为「$v0」';
  }

  @override
  String get savingPermissions => '正在保存权限…';

  @override
  String get tableEditsCanBeRevertedInRow => '表格修改可在行历史中回滚。';

  @override
  String get checkingSystemStatus => '正在读取系统状态…';

  @override
  String get couldntCheckSpeechStatusTryAgain => '读取语音状态失败，请重试。';

  @override
  String get available => '可用';

  @override
  String get unavailableBuild2 => '不可用';

  @override
  String recognitionService(Object v0) {
    return '识别服务：$v0';
  }

  @override
  String get granted => '已授权';

  @override
  String get partiallyGranted => '未完全授权';

  @override
  String microphoneAndSpeechPermissions(Object v0) {
    return '麦克风与识别权限：$v0';
  }

  @override
  String get supportedWithInstalledLanguageResources => '支持，需对应语言资源';

  @override
  String get supportNotReported => '未报告支持';

  @override
  String onDeviceRecognition(Object v0) {
    return '设备端识别：$v0';
  }

  @override
  String get mandarinLanguageListUnavailable => '普通话：系统未提供语言清单';

  @override
  String systemLanguages(Object v0) {
    return '系统语言：$v0';
  }

  @override
  String get checksMandarinRecognitionAndPermissionsWithoutRecording =>
      '仅检查普通话识别和当前权限，全程不录音。';

  @override
  String get checkAgain => '重新检测';

  @override
  String get theTaskForThisReminderNoLonger => '这条提醒对应的待办已不存在';

  @override
  String get todayAt => '今天 18:00';

  @override
  String get tomorrowAt => '明天 09:00';

  @override
  String get nextMondayAt => '下周一 09:00';

  @override
  String get reschedule => '改期';

  @override
  String rescheduledTo(Object v0) {
    return '已改期到 $v0';
  }

  @override
  String get dueDateCleared => '已清除截止';

  @override
  String completedTasks(Object v0) {
    return '已完成 $v0 条';
  }

  @override
  String get changeCategory => '改分类';

  @override
  String movedTo(Object v0) {
    return '已移到 $v0';
  }

  @override
  String get changeDueDate => '改截止';

  @override
  String rescheduled(Object v0) {
    return '已改期 $v0';
  }

  @override
  String deleteTasks(Object v0) {
    return '删除 $v0 条待办？';
  }

  @override
  String get onlySelectedRecurringOccurrencesAreDeletedUndo =>
      '重复待办仅删除选中实例。10 秒内可撤销。';

  @override
  String deletedTasks(Object v0) {
    return '已删除 $v0 条';
  }

  @override
  String categoryBuild(Object v0) {
    return '分类：$v0';
  }

  @override
  String get noTasksMatchTheseFilters => '没有符合条件的待办';

  @override
  String get expandCompletedTasks => '展开已完成待办';

  @override
  String get switchToBoard => '切换到看板';

  @override
  String get switchToList => '切换到列表';

  @override
  String get backToChatHome => '返回对话首页';

  @override
  String get list => '列表';

  @override
  String get board => '看板';

  @override
  String get searchTasks => '搜索待办';

  @override
  String selectedBuildselectionbar(Object v0) {
    return '已选 $v0 项';
  }

  @override
  String get deselectAll => '取消全选';

  @override
  String itemsBuildgroupheader(Object v0, Object v1) {
    return '$v0，$v1 条';
  }

  @override
  String newTaskIn(Object v0) {
    return '在$v0列新建';
  }

  @override
  String get noItems => '暂无事项';

  @override
  String get noMatchingTasks => '没有找到相关待办';

  @override
  String get goToChatBuildempty => '去对话';

  @override
  String get thisListIsEmpty => '当前清单为空';

  @override
  String get noTasksToday => '今天没有待办';

  @override
  String get nothingScheduledThisWeek => '本周暂无安排';

  @override
  String get noOverdueTasks => '没有逾期待办';

  @override
  String get noTasksWithoutADueDate => '没有无截止日期的待办';

  @override
  String get noCompletedTasksYet => '还没有完成记录';

  @override
  String get listSettings => '列表设置';

  @override
  String get groupBy => '分组方式';

  @override
  String get byCategoryShowmoresheet => '按分类';

  @override
  String get byDueDate => '按截止';

  @override
  String get byPriority => '按优先级';

  @override
  String get showCompleted => '显示已完成';

  @override
  String get manageCategories => '管理分类';

  @override
  String selectedAction(Object v0, Object v1) {
    return '$v0，已选 $v1 项';
  }

  @override
  String get someOccurrencesExceedAvailableTimeZoneData =>
      '部分重复安排超出时区数据范围，请调整结束日期。已有待办仍可使用。';

  @override
  String get someRecurringTasksAreStillPendingExisting => '部分重复待办尚未补齐，已有记录已保留。';

  @override
  String recurringTasksGeneratedThrough(
    Object v0,
    Object v1,
    Object v2,
    Object v3,
    Object v4,
  ) {
    return '重复待办已补齐至 $v0/$v1/$v2 $v3:$v4';
  }

  @override
  String get recurringTasksWillContinueAfterThisAction => '当前操作结束后，继续补齐重复待办';

  @override
  String get recurringTasksWillContinueWhenYouReopen => '返回应用后，继续补齐重复待办';

  @override
  String get generatingRecurringTasksInBatches => '正在分批补齐重复待办';

  @override
  String get selectedSegment => '，已选中';

  @override
  String filterByItems(Object v0, Object v1, Object v2) {
    return '按$v0过滤，$v1 项$v2';
  }

  @override
  String get currentVersion => '当前版本';

  @override
  String get versionHistory => '版本历史';

  @override
  String get expand => '展开';

  @override
  String get checkingForUpdates => '正在检查更新';

  @override
  String get upToDate => '已是最新版本';

  @override
  String get updateAvailable => '发现新版本';

  @override
  String get downloadingUpdate => '正在下载更新';

  @override
  String get verifyingPatch => '正在验证补丁';

  @override
  String get verifyingInstaller => '正在校验安装包';

  @override
  String get buildingInstaller => '正在合成安装包';

  @override
  String get patchReady => '补丁已就绪';

  @override
  String get installerReady => '安装包已就绪';

  @override
  String get permissionToInstallAppsRequired => '需要安装应用权限';

  @override
  String get confirmInstallationInTheSystemDialog => '请在系统界面确认安装';

  @override
  String get restartingToApplyUpdate => '正在重启并加载更新';

  @override
  String get updateCheckFailed => '检查更新失败';

  @override
  String get inAppInstallationUnavailableOnThisPlatform => '此平台暂未提供应用内安装';

  @override
  String get checkAgainBuild => '重新检查';

  @override
  String get deltaUpdate => '差量更新';

  @override
  String get fullInstaller => '完整安装包';

  @override
  String get whatsNew => '本次更新';

  @override
  String get deltaUpdateIncompleteSwitchedToTheFull => '差量更新未完成，已切换完整安装包。';

  @override
  String get allowThisSourceThenReturnToInstall => '允许此来源后返回安装。';

  @override
  String get restoreAndRestart => '恢复并重启';

  @override
  String get updateAndRestart => '更新并重启';

  @override
  String get downloadUpdate => '下载更新';

  @override
  String get cancelUpdate => '取消更新';

  @override
  String get pauseDownload => '暂停下载';

  @override
  String get restartNow => '立即重启';

  @override
  String get installAndReopen => '安装并重新打开';

  @override
  String get reopenInstaller => '重新打开安装';

  @override
  String get filterCategories => '筛选分类';

  @override
  String get askAi => '问问 AI';

  @override
  String get scheduleOverview => '日程可视化';

  @override
  String get switchScheduleView => '切换日程视图';

  @override
  String get createTaskOnSelectedDate => '新建所选日待办';

  @override
  String get searchSchedule => '搜索日程';

  @override
  String get heatmap => '热力图';

  @override
  String get calendar => '日历';

  @override
  String get distribution => '分布';

  @override
  String get trends => '趋势';

  @override
  String get tasksCompleted => '完成 Todo 数';

  @override
  String get itemsVizStats => '件';

  @override
  String get tasksAdded => '新增 Todo 数';

  @override
  String get recordsAdded => '新增数据条数';

  @override
  String get rowsVizStats => '条';

  @override
  String formattedValueOpenday(Object v0, Object v1, Object v2) {
    return '$v0 月 $v1 日 周$v2';
  }

  @override
  String alreadyHighPriorityItemsThatDay(Object v0) {
    return ' 当天已有 $v0 件高优先级';
  }

  @override
  String movedToReschedule(Object v0, Object v1, Object v2) {
    return '已改到 $v0 月 $v1 日$v2';
  }

  @override
  String get previousMonthBuild => '上一月';

  @override
  String get nextMonthBuild => '下一月';

  @override
  String get noTasksThisMonth => '本月暂无待办';

  @override
  String get todayBuild => '今天，';

  @override
  String get overdueItems => '，有逾期';

  @override
  String tasksBuild2(Object v0, Object v1, Object v2, Object v3, Object v4) {
    return '$v0 月 $v1 日，$v2$v3 件待办$v4';
  }

  @override
  String get pieChart => '饼图';

  @override
  String get barChart => '柱状图';

  @override
  String get switchChart => '切换图形';

  @override
  String get addCategoriesToYourTasksToSee => '分类还太少，看不出分布——再给待办们归归类。';

  @override
  String get organizeCategories => '去整理分类';

  @override
  String completeBuildpie(Object v0, Object v1) {
    return '$v0 完成 $v1%';
  }

  @override
  String itemsComplete(Object v0, Object v1, Object v2) {
    return '$v0，$v1 件，完成率 $v2%';
  }

  @override
  String itemsCompleteBuildpie(Object v0, Object v1) {
    return '$v0 件 完成 $v1%';
  }

  @override
  String get metric => '统计口径';

  @override
  String scale(Object v0) {
    return '色阶：$v0';
  }

  @override
  String get activity => '坚持强度';

  @override
  String daysRecorded(Object v0) {
    return '已记录 $v0 天';
  }

  @override
  String changeMetricCurrently(Object v0) {
    return '切换统计口径，当前：$v0';
  }

  @override
  String activityHeatmapForPastYear(Object v0, Object v1, Object v2) {
    return '坚持强度热力图，统计口径：$v0。过去一年共 $v1 $v2。';
  }

  @override
  String get less => '少';

  @override
  String get moreBuild => '多';

  @override
  String yearBuild(Object v0, Object v1) {
    return '全年 $v0 $v1';
  }

  @override
  String monthPaint(Object v0) {
    return '$v0月';
  }

  @override
  String get tablesTablename => '数据表';

  @override
  String rowsAdded(Object v0, Object v1) {
    return '$v0 新增数据 $v1 条';
  }

  @override
  String get noActivityThisDay => '这一天很安静，什么也没有发生。';

  @override
  String formattedValueBuild5(Object v0, Object v1, Object v2) {
    return '$v0月$v1日 周$v2';
  }

  @override
  String get noMatchingTasksBuild => '没有匹配的待办';

  @override
  String get noTasksOnThisDay => '这一天没有待办';

  @override
  String get createdVsCompleted => '创建 vs 完成';

  @override
  String weeks(Object v0) {
    return '$v0 周';
  }

  @override
  String get changePeriod => '切换统计周期';

  @override
  String get trendsAppearAfterTwoWeeksOfActivity => '趋势要等数据攒够两周才看得出来，先到的是惊喜。';

  @override
  String thisWeekCreatedCompleted(Object v0, Object v1) {
    return '本周创建 $v0 件，完成 $v1 件';
  }

  @override
  String lastWeeksCreatedCompleted(Object v0, Object v1, Object v2) {
    return '近 $v0 周创建 $v1 件，完成 $v2 件';
  }

  @override
  String completeComparedWithLastPeriod(Object v0) {
    return '完成率 $v0%，比上一周期 ';
  }

  @override
  String get noChange => '持平';

  @override
  String weekCreatedCompleted(Object v0, Object v1, Object v2) {
    return '第 $v0 周：创建 $v1 完成 $v2';
  }

  @override
  String get noDueTime => '无截止时间';

  @override
  String dueAt(Object v0, Object v1) {
    return '$v0:$v1 截止';
  }

  @override
  String markIncompleteBuild(Object v0) {
    return '取消完成：$v0';
  }

  @override
  String completeBuild2(Object v0) {
    return '完成：$v0';
  }

  @override
  String get noFiltersShowingAll => '未筛选，显示全部';

  @override
  String filteredByChartsUpdated(Object v0) {
    return '已筛选：$v0，图表已更新';
  }

  @override
  String get selectedDoubleTapToClear => '已选中，双击取消';

  @override
  String filterBuild(Object v0, Object v1) {
    return '筛选：$v0，$v1';
  }

  @override
  String get closeModelAccount => '关闭模型账户';

  @override
  String get toworkQuickAsk => 'ToWork 快问';

  @override
  String get generatingInBackground => '后台生成中';

  @override
  String get newChatHeader => '新对话';

  @override
  String get openInTowork => '在 ToWork 中打开';

  @override
  String get whatsLeftToday => '今天还有什么要做';

  @override
  String get whatElseDoINeedToDo => '今天还有什么要做？';

  @override
  String get addATask => '记一条待办';

  @override
  String get helpMeAddATask => '帮我记一条待办：';

  @override
  String get whatDidIDoThisWeek => '这周做了什么';

  @override
  String get summarizeWhatICompletedThisWeek => '帮我总结一下这周完成了什么';

  @override
  String get saveAsTask => '记成待办';

  @override
  String turnThisIntoATask(Object v0) {
    return '把下面的内容记成待办：\n$v0';
  }

  @override
  String get summarize => '总结要点';

  @override
  String summarizeTheseKeyPoints(Object v0) {
    return '总结下面内容的要点：\n$v0';
  }

  @override
  String get workWithThisText => '处理这段文字';

  @override
  String get couldntOpenTheWorkspaceYourDataIs => '无法打开工作区，原有数据已保留。';

  @override
  String get closeProfile => '关闭个人资料';

  @override
  String get pageNotFound => '页面不存在';

  @override
  String get thisPageMayHaveMovedOrBeen => '这个页面可能已移动或删除';

  @override
  String get backToHome => '返回首页';

  @override
  String toworkAvailable(Object v0) {
    return 'ToWork $v0 可更新';
  }

  @override
  String get restoreBaseVersionAvailable => '可恢复基础版本';

  @override
  String patchPAvailable(Object v0) {
    return '补丁 P$v0 可更新';
  }

  @override
  String viewUpdate(Object v0) {
    return '$v0，查看更新';
  }

  @override
  String get viewUpdateBuild => '查看更新';

  @override
  String get remindMeLater => '稍后提醒';

  @override
  String get expandSidebar => '展开侧栏';

  @override
  String get languageLabel => '语言';

  @override
  String get english => 'English';

  @override
  String get weekdaySunday => '日';

  @override
  String windowHours(int v0) {
    return '$v0 小时';
  }

  @override
  String windowDays(int v0) {
    return '$v0 天';
  }

  @override
  String windowMinutes(int v0) {
    return '$v0 分钟';
  }

  @override
  String get defaultNickname => '本地用户';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsHaveChangedReopenAndTryAgain =>
      'Settings have changed. Reopen and try again.';

  @override
  String get couldntSaveSettingsTryAgain =>
      'Couldn’t save settings. Try again.';

  @override
  String get thisCanBeSplitIntoThreeSteps =>
      'This can be split into three steps: gather the material, finish a draft, and send it for review. Switch to Agent mode to create the task.';

  @override
  String get theTaskOrItsCardHasChanged => 'The task or its card has changed';

  @override
  String get thisChatIsClosedItsTaskCan =>
      'This chat is closed. Its task can no longer be undone.';

  @override
  String get theTaskOrItsCardNoLonger =>
      'The task or its card no longer exists';

  @override
  String get theCardNowLinksToADifferent =>
      'The card now links to a different task';

  @override
  String get relatedRecordsHaveChangedAndCannotBe =>
      'Related records have changed and cannot be restored';

  @override
  String get currentModel => 'Current model';

  @override
  String switchedTo(Object v0, Object v1, Object v2) {
    return '$v0$v1. Switched to $v2.';
  }

  @override
  String get couldntOpenTheLocalWorkspaceYourData =>
      'Couldn’t open the local workspace. Your data is safe. Try again.';

  @override
  String get reopen => 'Reopen';

  @override
  String get movement => 'Movement';

  @override
  String get mountain => 'Mountain';

  @override
  String get note => 'Note';

  @override
  String get overture => 'Overture';

  @override
  String get sonata => 'Sonata';

  @override
  String get symphony => 'Symphony';

  @override
  String get valley => 'Valley';

  @override
  String get ridge => 'Ridge';

  @override
  String get summit => 'Summit';

  @override
  String get zenith => 'Zenith';

  @override
  String get year => 'Year';

  @override
  String get month => 'Month';

  @override
  String get free => 'Free';

  @override
  String get loading => 'Loading';

  @override
  String get kFlagshipModel => 'K3 flagship model';

  @override
  String get mContextWindow => '1M context window';

  @override
  String get highspeed => 'HighSpeed';

  @override
  String get videoInput => 'Video input';

  @override
  String get mQuota => '2× 1M quota';

  @override
  String get highSpeedQuota => '3× high-speed quota';

  @override
  String get vMWithVision => 'V4.1 1M with vision';

  @override
  String get deepReasoning => 'Deep reasoning';

  @override
  String get makeTaskRecurring => 'Make task recurring';

  @override
  String get startingWithThisOccurrence => 'Starting with this occurrence';

  @override
  String get editRecurringTask => 'Edit recurring task';

  @override
  String get deleteRecurringTask => 'Delete recurring task';

  @override
  String get thisOccurrence => 'This occurrence';

  @override
  String get thisAndFutureOccurrences => 'This and future occurrences';

  @override
  String get changesToTheRecurrenceRuleOrTime =>
      'Changes to the recurrence rule or time zone apply to this and future occurrences.';

  @override
  String get checkTheDueDateAndSeriesStatus =>
      'Check the due date and series status. The selection may also exceed the batch limit.';

  @override
  String get modelDownloadFailedCheckYourConnectionAnd =>
      'Model download failed. Check your connection and try again.';

  @override
  String get modelDownloadFailedTryAgainLater =>
      'Model download failed. Try again later.';

  @override
  String get installationCanceledYouCanRetry =>
      'Installation canceled. You can retry.';

  @override
  String get installationDidNotFinishTryAgain =>
      'Installation did not finish. Try again.';

  @override
  String get patchDownloadCanceledYouCanDownloadIt =>
      'Patch download canceled. You can download it again.';

  @override
  String get patchVerificationFailedCheckForUpdatesAgain =>
      'Patch verification failed. Check for updates again.';

  @override
  String get finishTheCurrentConversationOrInputBefore =>
      'Finish the current conversation or input before restarting.';

  @override
  String get patchReadyReturnHereToRestart =>
      'Patch ready. Return here to restart.';

  @override
  String get downloadPausedResumeToContinue =>
      'Download paused. Resume to continue.';

  @override
  String get connectionInterruptedTryAgain =>
      'Connection interrupted. Try again.';

  @override
  String get updateInformationIsUnavailableTryAgainLater =>
      'Update information is unavailable. Try again later.';

  @override
  String get thisUpdateDoesNotSupportYourDevice =>
      'This update does not support your device architecture.';

  @override
  String get theUpdateSignatureDoesNotMatchThe =>
      'The update signature does not match the installed app.';

  @override
  String get verificationFailedDownloadTheUpdateAgain =>
      'Verification failed. Download the update again.';

  @override
  String get storageIsFullOrUnavailableFreeUp =>
      'Storage is full or unavailable. Free up space and try again.';

  @override
  String get theDownloadServerIsUnavailableTryAgain =>
      'The download server is unavailable. Try again later.';

  @override
  String get allowToworkToInstallAppsThenTap =>
      'Allow ToWork to install apps, then tap Install and reopen.';

  @override
  String get thePackageOrVersionDoesNotMatch =>
      'The package or version does not match. Check for updates again.';

  @override
  String get anUpdateIsInProgressTryAgain =>
      'An update is in progress. Try again later.';

  @override
  String get updateIncompleteTryAgain => 'Update incomplete. Try again.';

  @override
  String get noneLabel => 'None';

  @override
  String get reminder => 'Reminder';

  @override
  String get atTheDueTime => 'At the due time';

  @override
  String daysBefore(int v0) {
    String _temp0 = intl.Intl.pluralLogic(
      v0,
      locale: localeName,
      other: '$v0 days before',
      one: '1 day before',
    );
    return '$_temp0';
  }

  @override
  String hoursBefore(int v0) {
    String _temp0 = intl.Intl.pluralLogic(
      v0,
      locale: localeName,
      other: '$v0 hours before',
      one: '1 hour before',
    );
    return '$_temp0';
  }

  @override
  String minutesBefore(int v0) {
    String _temp0 = intl.Intl.pluralLogic(
      v0,
      locale: localeName,
      other: '$v0 minutes before',
      one: '1 minute before',
    );
    return '$_temp0';
  }

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get complete => 'Complete';

  @override
  String get deleteLabel => 'Delete';

  @override
  String get change => 'Change';

  @override
  String get notSet => 'Not set';

  @override
  String get cleared => 'Cleared';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String record(Object v0) {
    return 'Record $v0';
  }

  @override
  String get someFieldsAreUncertainCheckThemAgainst =>
      'Some fields are uncertain. Check them against the image before confirming.';

  @override
  String get title => 'Title';

  @override
  String get notes => 'Notes';

  @override
  String get status => 'Status';

  @override
  String get priority => 'Priority';

  @override
  String get due => 'Due';

  @override
  String get category => 'Category';

  @override
  String get steps => 'Steps';

  @override
  String get tags => 'Tags';

  @override
  String get completedAt => 'Completed at';

  @override
  String get recurrence => 'Recurrence';

  @override
  String get recurrenceTimeZone => 'Recurrence time zone';

  @override
  String get unavailableCategory => 'Unavailable category';

  @override
  String get completed => 'Completed';

  @override
  String get task => 'Task';

  @override
  String get inProgress => 'In progress';

  @override
  String get high => 'High';

  @override
  String get medium => 'Medium';

  @override
  String get low => 'Low';

  @override
  String get urgent => 'Urgent';

  @override
  String get canceled => 'Canceled';

  @override
  String taskChanges(Object v0) {
    return 'Task changes: $v0';
  }

  @override
  String get onlyTheSelectedOccurrenceWillChangeOther =>
      'Only the selected occurrence will change. Other dates keep their existing rule.';

  @override
  String get stopsFutureOccurrencesInThisRangeAnd =>
      'Stops future occurrences in this range and retains other completed records. Accept or reject the changes together.';

  @override
  String get acceptOrRejectTheSeriesChangesTogether =>
      'Accept or reject the series changes together. New occurrences will be created as needed.';

  @override
  String get viewAllChanges => 'View all changes';

  @override
  String get seriesTemplate => 'Series template ';

  @override
  String get newLabel => 'New';

  @override
  String get update => 'Update';

  @override
  String timeZone(Object v0) {
    return 'Time zone $v0 ';
  }

  @override
  String get keepRepeating => 'Keep repeating';

  @override
  String get endBoundarySet => 'End boundary set';

  @override
  String get saveAKimiApiKeyInModel =>
      'Save a Kimi API key in Model connections before sending.';

  @override
  String get modelSettingsChangedSendANewRequest =>
      'Model settings changed. Send a new request. Completed actions have been saved.';

  @override
  String get inputIsTooLongShortenItOr =>
      'Input is too long. Shorten it or split your request. Your history is saved.';

  @override
  String get requestStopped => 'Request stopped.';

  @override
  String get theContextOrActionLimitHasBeen =>
      'The context or action limit has been reached. Start a new chat.';

  @override
  String get theChatOrRecordHasChangedFinish =>
      'The chat or record has changed. Finish the pending request or reopen the chat.';

  @override
  String get theRecordOrTableStructureHasSince =>
      'The record or table structure has since changed and cannot be overwritten.';

  @override
  String get couldntCompleteTheActionYourDataIs =>
      'Couldn’t complete the action. Your data is safe. Try again.';

  @override
  String get checkYourModelCredentialsAndAccessIn =>
      'Check your model credentials and access in Model connections.';

  @override
  String get modelRateLimitReachedTryAgainLater =>
      'Model rate limit reached. Try again later.';

  @override
  String get thisAccountIsOutOfQuotaSelect =>
      'This account is out of quota. Select another model and retry.';

  @override
  String get theSourceImageIsUnavailableSelectIt =>
      'The source image is unavailable. Select it again in Screenshot import.';

  @override
  String get couldntReadTheSourceImageTryAgain =>
      'Couldn’t read the source image. Try again later.';

  @override
  String get modelSettingsChangedDuringTheRequestRetry =>
      'Model settings changed during the request. Retry with the current model.';

  @override
  String get inputOrToolResultsAreTooLong =>
      'Input or tool results are too long. Split the request. Completed actions are saved.';

  @override
  String get actionLimitReachedSendAnotherRequestOr =>
      'Action limit reached. Send another request or start a new chat.';

  @override
  String get theTargetHasChangedYouCanReplan =>
      'The target has changed. You can replan.';

  @override
  String get connectionInterruptedOrModelTimedOutTry =>
      'Connection interrupted or model timed out. Try again.';

  @override
  String get theModelResponseFailedValidationThisBatch =>
      'The model response failed validation. This batch was not applied.';

  @override
  String get requestIncompleteYouCanRetryCompletedActions =>
      'Request incomplete. You can retry. Completed actions are saved.';

  @override
  String get changesUndone => 'Changes undone';

  @override
  String awaitingConfirmation(Object v0) {
    return 'Awaiting confirmation: $v0';
  }

  @override
  String get requestSavedReadyToContinue => 'Request saved. Ready to continue.';

  @override
  String get working => 'Working';

  @override
  String get replySaved => 'Reply saved';

  @override
  String actionBatchesSubmitted(Object v0) {
    return 'Action batches submitted: $v0';
  }

  @override
  String get requestStoppedBuild => 'Request stopped';

  @override
  String completedActionBatchesRetained(Object v0) {
    return 'Completed action batches retained: $v0.';
  }

  @override
  String earlierTurnsOutsideThisRequestFullHistory(Object v0) {
    return 'Earlier turns outside this request: $v0. Full history is available.';
  }

  @override
  String earlierTurnsOutsideThisRequestFullHistoryIsAvailable(Object v0) {
    return 'Earlier turns outside this request: $v0. Full history is available. Add context if you refer to earlier messages.';
  }

  @override
  String get actions => 'Actions';

  @override
  String selectLabel(Object v0) {
    return 'Select $v0';
  }

  @override
  String get acceptAll => 'Accept all';

  @override
  String acceptSelected(Object v0) {
    return 'Accept selected ($v0)';
  }

  @override
  String rejectSelected(Object v0) {
    return 'Reject selected ($v0)';
  }

  @override
  String get refreshChanges => 'Refresh changes';

  @override
  String get continueLabel => 'Continue';

  @override
  String get cancelRequest => 'Cancel request';

  @override
  String get retry => 'Retry';

  @override
  String get undoThisBatch => 'Undo this batch';

  @override
  String get undoAllChangesInThisRequest => 'Undo all changes in this request';

  @override
  String get undo => 'Undo';

  @override
  String name(Object v0, Object v1) {
    return 'Name: $v0 → $v1';
  }

  @override
  String description(Object v0, Object v1) {
    return 'Description: $v0$v1';
  }

  @override
  String get addField => 'Add field: ';

  @override
  String editField(Object v0, Object v1) {
    return 'Edit field: $v0 → $v1';
  }

  @override
  String removeField(Object v0) {
    return 'Remove field: $v0';
  }

  @override
  String get field => 'Field';

  @override
  String get type => 'Type';

  @override
  String get requirement => 'Requirement';

  @override
  String get required => 'Required';

  @override
  String get optional => 'Optional';

  @override
  String get createTable => 'Create table';

  @override
  String get editTable => 'Edit table';

  @override
  String get noChangesToTheTable => 'No changes to the table';

  @override
  String get number => 'Number';

  @override
  String currencyDecimalPlaces(Object v0) {
    return 'Currency, $v0 decimal places';
  }

  @override
  String get date => 'Date';

  @override
  String get dateAndTime => 'Date and time';

  @override
  String get singleSelect => 'Single select';

  @override
  String get yesNo => 'Yes/No';

  @override
  String get text => 'Text';

  @override
  String get glm => 'GLM';

  @override
  String get otherOpenaiCompatible => 'Other (OpenAI-compatible)';

  @override
  String get enterAValidKeyWithoutSpacesOr =>
      'Enter a valid key without spaces or line breaks';

  @override
  String get secureStorageIsUnavailableUnlockTheDevice =>
      'Secure storage is unavailable. Unlock the device and try again.';

  @override
  String get settingsChangedReloadAndTryAgain =>
      'Settings changed. Reload and try again.';

  @override
  String get enterAKeyForTheSelectedProvider =>
      'Enter a key for the selected provider and region';

  @override
  String get couldntReadOrSaveLocalSettingsTry =>
      'Couldn’t read or save local settings. Try again.';

  @override
  String get enterAValidModelNameAndKey => 'Enter a valid model name and key';

  @override
  String get authenticationFailedCheckTheKeyApiProduct =>
      'Authentication failed. Check the key, API product and model access (401).';

  @override
  String get accessDeniedCheckYourSubscriptionAndApi =>
      'Access denied. Check your subscription and API permissions (403).';

  @override
  String get rateLimitReachedTryAgainLater =>
      'Rate limit reached. Try again later (429).';

  @override
  String get quotaOrBalanceExhaustedCheckTheProvider =>
      'Quota or balance exhausted. Check the provider console.';

  @override
  String get modelOrEndpointNotFoundCheckYour =>
      'Model or endpoint not found. Check your settings (404).';

  @override
  String get testCanceled => 'Test canceled';

  @override
  String get connectionTimedOutCheckYourNetworkAnd =>
      'Connection timed out. Check your network and retry.';

  @override
  String get connectionFailedTryAgain => 'Connection failed. Try again.';

  @override
  String get theServiceReturnedAnIncompleteResponseTry =>
      'The service returned an incomplete response. Try again later.';

  @override
  String get couldntCompleteTheActionTryAgain =>
      'Couldn’t complete the action. Try again.';

  @override
  String get fast => 'Fast';

  @override
  String get viewSourceChat => 'View source chat';

  @override
  String get viewTaskSourceChat => 'View task source chat';

  @override
  String get resetsSoon => 'Resets soon';

  @override
  String resetsInMin(Object v0) {
    return 'Resets in $v0 min';
  }

  @override
  String resetsInHr(Object v0) {
    return 'Resets in $v0 hr';
  }

  @override
  String resetsInHrMin(Object v0, Object v1) {
    return 'Resets in $v0 hr $v1 min';
  }

  @override
  String resetsInDays(Object v0) {
    return 'Resets in $v0 days';
  }

  @override
  String get noKey => 'No key';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get reset => 'Reset';

  @override
  String get restore => 'Restore';

  @override
  String left(Object v0, Object v1) {
    return '$v0: $v1% left';
  }

  @override
  String balance(Object v0) {
    return 'Balance $v0';
  }

  @override
  String quotaUsed(Object v0, Object v1, Object v2) {
    return '$v0 quota: $v1% used$v2';
  }

  @override
  String used(Object v0) {
    return '$v0% used';
  }

  @override
  String get checkQuotaInTheProviderConsole =>
      'Check quota in the provider console';

  @override
  String get quotaNotCheckedYet => 'Quota not checked yet';

  @override
  String get accountBalance => 'Account balance';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String remaining(Object v0, Object v1) {
    return '$v0, $v1 remaining';
  }

  @override
  String get upwardTrend => 'Upward trend';

  @override
  String get archiveBox => 'Archive box';

  @override
  String get home => 'Home';

  @override
  String get briefcase => 'Briefcase';

  @override
  String get heart => 'Heart';

  @override
  String get openBook => 'Open book';

  @override
  String get wallet => 'Wallet';

  @override
  String get shoppingCart => 'Shopping cart';

  @override
  String get cutlery => 'Cutlery';

  @override
  String get plane => 'Plane';

  @override
  String get dumbbell => 'Dumbbell';

  @override
  String get graduationCap => 'Graduation cap';

  @override
  String get camera => 'Camera';

  @override
  String get gift => 'Gift';

  @override
  String get car => 'Car';

  @override
  String get pawPrint => 'Paw print';

  @override
  String get leaf => 'Leaf';

  @override
  String get star => 'Star';

  @override
  String get flag => 'Flag';

  @override
  String get code => 'Code';

  @override
  String get pen => 'Pen';

  @override
  String get person => 'Person';

  @override
  String get folder => 'Folder';

  @override
  String get mistBlue => 'Mist blue';

  @override
  String get stone => 'Stone';

  @override
  String get sage => 'Sage';

  @override
  String get wheat => 'Wheat';

  @override
  String get terracotta => 'Terracotta';

  @override
  String get lavenderGray => 'Lavender gray';

  @override
  String get slate => 'Slate';

  @override
  String get warmGray => 'Warm gray';

  @override
  String get newSubcategory => 'New subcategory';

  @override
  String get rename => 'Rename';

  @override
  String get reorder => 'Reorder';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get archive => 'Archive';

  @override
  String get restoreCategory => 'Restore category';

  @override
  String get deletePermanently => 'Delete permanently';

  @override
  String tasks(num v0) {
    String _temp0 = intl.Intl.pluralLogic(
      v0,
      locale: localeName,
      other: '$v0 tasks',
      one: '1 task',
    );
    return '$_temp0';
  }

  @override
  String subcategories(num v0) {
    String _temp0 = intl.Intl.pluralLogic(
      v0,
      locale: localeName,
      other: '$v0 subcategories',
      one: '1 subcategory',
    );
    return '$_temp0';
  }

  @override
  String recurringSeries(num v0) {
    String _temp0 = intl.Intl.pluralLogic(
      v0,
      locale: localeName,
      other: '$v0 recurring series',
      one: '1 recurring series',
    );
    return '$_temp0';
  }

  @override
  String deleteLabelBuild(Object v0) {
    return 'Delete “$v0”?';
  }

  @override
  String contains(Object v0) {
    return 'Contains $v0.';
  }

  @override
  String get moveTasksToUncategorizedAndPromoteSubcategories =>
      'Move tasks to Uncategorized and promote subcategories to top level';

  @override
  String get deleteTasksAndSubcategories => 'Delete tasks and subcategories';

  @override
  String get futureTasksInThisCategoryWillMove =>
      'Future tasks in this category will move to Uncategorized. Subcategory series keep their categories.';

  @override
  String alsoStopTheseSeries(Object v0) {
    return 'Also stop these $v0 series.';
  }

  @override
  String keepTheTasksMovedElsewhereOrUncategorized(Object v0) {
    return 'Keep the $v0 tasks moved elsewhere or uncategorized, and stop their recurrence.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get icon => 'Icon';

  @override
  String get color => 'Color';

  @override
  String get done => 'Done';

  @override
  String get deleteCategory => 'Delete category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get newCategory => 'New category';

  @override
  String get close => 'Close';

  @override
  String get categoryName => 'Category name';

  @override
  String iconIcongrid(Object v0) {
    return 'Icon, $v0';
  }

  @override
  String get selected => 'Selected';

  @override
  String get notSelected => 'Not selected';

  @override
  String colorItemOf(Object v0, Object v1, Object v2, Object v3) {
    return 'Color, $v0, $v1, item $v3 of $v2';
  }

  @override
  String get topLevel => 'Top level';

  @override
  String parent(Object v0) {
    return 'Parent, $v0';
  }

  @override
  String get parentParentrow => 'Parent';

  @override
  String get aCategoryWithSubcategoriesMustStayAt =>
      'A category with subcategories must stay at the top level';

  @override
  String moveUnder(Object v0) {
    return 'Move under $v0';
  }

  @override
  String get archiveCategory => 'Archive category';

  @override
  String get hidesThisCategoryWhenCreatingTasksIts =>
      'Hides this category when creating tasks. Its data is retained.';

  @override
  String get notificationsAndReminders => 'Notifications and reminders';

  @override
  String get couldntOpenNotificationSettingsTryAgain =>
      'Couldn’t open notification settings. Try again.';

  @override
  String get localWorkspaceIsntReady => 'Local workspace isn’t ready.';

  @override
  String get checkingPermissions => 'Checking permissions…';

  @override
  String get localNotificationsAreUnavailableOnThisPlatform =>
      'Local notifications are unavailable on this platform';

  @override
  String get systemNotificationsEnabled => 'System notifications enabled';

  @override
  String get notificationsAreOffYourReminderRulesAre =>
      'Notifications are off. Your reminder rules are saved.';

  @override
  String get backgroundMaintenanceRegisteredTheSystemControlsTiming =>
      'Background maintenance registered. The system controls timing.';

  @override
  String get backgroundRegistrationFailedRemindersCanStillBe =>
      'Background registration failed. Reminders can still be scheduled while the app is open.';

  @override
  String get foregroundMaintenanceOnlyDigestGenerationPausesWhen =>
      'Foreground maintenance only. Digest generation pauses when the app closes.';

  @override
  String get retryBackgroundMaintenance => 'Retry background maintenance';

  @override
  String scheduledPending(Object v0, Object v1) {
    return 'Scheduled: $v0. Pending: $v1.';
  }

  @override
  String get dueRemindersMayArriveLateEnableExact =>
      'Due reminders may arrive late. Enable exact alarms for precise timing.';

  @override
  String get someRemindersWerentScheduledTryAgain =>
      'Some reminders weren’t scheduled. Try again.';

  @override
  String get checkAndRetry => 'Check and retry';

  @override
  String get enableNotifications => 'Enable notifications';

  @override
  String get enableExactAlarms => 'Enable exact alarms';

  @override
  String get systemNotificationSettings => 'System notification settings';

  @override
  String get scheduleDetails => 'Schedule details';

  @override
  String get setAReminderOnTheTaskUp =>
      'Set a reminder on the task. Up to 60 reminders are scheduled for the next 30 days and digests up to 7 days ahead, using current device data.';

  @override
  String get schedulingResumesInTheBackgroundOrWhen =>
      'Scheduling resumes in the background or when you reopen the app. Battery saver, Do Not Disturb and force stop can affect digest delivery.';

  @override
  String get created => 'Created';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get nextMonday => 'Next Monday';

  @override
  String formattedValue(Object v0, Object v1) {
    return '$v0/$v1';
  }

  @override
  String get noDueDate => 'No due date';

  @override
  String get whenDue => 'When due';

  @override
  String get minutesBeforeBuild => '15 minutes before';

  @override
  String get hourBefore => '1 hour before';

  @override
  String get dayBefore => '1 day before';

  @override
  String get newTask => 'New task';

  @override
  String get taskTitle => 'Task title';

  @override
  String get create => 'Create';

  @override
  String get addANote => 'Add a note';

  @override
  String get dueDate => 'Due date';

  @override
  String get setTime => 'Set time';

  @override
  String get chooseDate => 'Choose date';

  @override
  String get ok => 'OK';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get backToToday => 'Back to today';

  @override
  String get restored => 'Restored';

  @override
  String get deleted => 'Deleted';

  @override
  String filterCategory(Object v0) {
    return 'Filter category: $v0';
  }

  @override
  String chooseDateBuild(Object v0) {
    return '$v0, choose date';
  }

  @override
  String get collapseDailyOverview => 'Collapse daily overview';

  @override
  String get mtwtfss => 'MTWTFSS';

  @override
  String formattedValueBuild(Object v0, Object v1, Object v2, Object v3) {
    return '$v3, $v1/$v2/$v0';
  }

  @override
  String get thatDay => 'That day';

  @override
  String pending(Object v0, Object v1) {
    return '$v0: $v1 pending';
  }

  @override
  String overdue(Object v0) {
    return ', $v0 overdue';
  }

  @override
  String completion(Object v0) {
    return '$v0 completion';
  }

  @override
  String get allLabel => 'All';

  @override
  String get overdueBuild => 'Overdue';

  @override
  String get noTasks => 'No tasks';

  @override
  String completedBuild(Object v0) {
    return 'Completed: $v0';
  }

  @override
  String get allTasks => 'All tasks';

  @override
  String get setADueDateBeforeEnablingRecurrence =>
      'Set a due date before enabling recurrence';

  @override
  String get selectedOccurrencesDeleted => 'Selected occurrences deleted';

  @override
  String get recurringTaskUpdated => 'Recurring task updated';

  @override
  String get undone => 'Undone';

  @override
  String get dateIsOutsideAvailableTimeZoneData =>
      'Date is outside available time zone data. Choose an earlier end date.';

  @override
  String get updatesRecurrenceForTheSelectedRangeEarlier =>
      'Updates recurrence for the selected range. Earlier records and other completed tasks are retained.';

  @override
  String get changesOnlyThisOccurrenceOtherDatesAnd =>
      'Changes only this occurrence. Other dates and the recurrence schedule are retained.';

  @override
  String changesAddedEditedDeleted(Object v0, Object v1, Object v2) {
    return 'Changes: $v0 added, $v1 edited, $v2 deleted';
  }

  @override
  String get collapseRecords => 'Collapse records';

  @override
  String viewAllRecords(Object v0) {
    return 'View all $v0 records';
  }

  @override
  String get confirmDeletion => 'Confirm deletion';

  @override
  String get confirmChanges => 'Confirm changes';

  @override
  String previously(Object v0) {
    return 'Previously: $v0';
  }

  @override
  String get repeat => 'Repeat';

  @override
  String get timeZoneBuild => 'Time zone';

  @override
  String get setADueTimeToPreviewUpcoming =>
      'Set a due time to preview upcoming dates';

  @override
  String thisOccurrenceBuild(Object v0) {
    return 'This occurrence: $v0';
  }

  @override
  String get noUpcomingDatesTheEndConditionHas =>
      'No upcoming dates. The end condition has been reached.';

  @override
  String get upcomingDates => 'Upcoming dates';

  @override
  String timeZoneDataIsAvailableThroughShorten(Object v0) {
    return 'Time zone data is available through $v0. Shorten the preview range.';
  }

  @override
  String get previewUnavailableForThisRuleOrTime =>
      'Preview unavailable for this rule or time zone';

  @override
  String get dateRangeIsTooLargeShortenThe =>
      'Date range is too large. Shorten the interval or range.';

  @override
  String get enterATitleBeforeClosing => 'Enter a title before closing';

  @override
  String get taskUnavailable => 'Task unavailable';

  @override
  String get itMayHaveBeenDeletedOrChanged =>
      'It may have been deleted or changed on another device.';

  @override
  String get backToTasks => 'Back to tasks';

  @override
  String get more => 'More';

  @override
  String markIncomplete(Object v0) {
    return 'Mark incomplete, $v0';
  }

  @override
  String markComplete(Object v0) {
    return 'Mark complete, $v0';
  }

  @override
  String get addANoteBuildtitlearea => 'Add a note…';

  @override
  String get originalCategoryArchived => 'Original category archived';

  @override
  String get dueBuildfields => 'Due';

  @override
  String get overdueBuildfields => 'Overdue';

  @override
  String get addTag => 'Add tag';

  @override
  String get fromChat => 'From chat';

  @override
  String get originalChatDeleted => 'Original chat deleted';

  @override
  String get originalChatUnavailable => 'Original chat unavailable';

  @override
  String createdFromChatDoubleTapToView(Object v0) {
    return 'Created from chat: $v0. Double-tap to view.';
  }

  @override
  String createdBuildmeta(Object v0) {
    return 'Created $v0';
  }

  @override
  String updated(Object v0) {
    return 'Updated $v0';
  }

  @override
  String completedBuildmeta(Object v0) {
    return 'Completed $v0';
  }

  @override
  String get deleteThisTask => 'Delete this task';

  @override
  String get copyTitle => 'Copy title';

  @override
  String get titleCopied => 'Title copied';

  @override
  String get deleteThisTaskConfirmdelete => 'Delete this task?';

  @override
  String willBeDeletedYouCanUndoWithin(Object v0) {
    return '“$v0” will be deleted. You can undo within 10 seconds.';
  }

  @override
  String get chooseDateBuild2 => 'Choose date…';

  @override
  String get time => 'Time';

  @override
  String get allDay => 'All day';

  @override
  String get clearTime => 'Clear time';

  @override
  String get addTime => 'Add time';

  @override
  String get clearDueDate => 'Clear due date';

  @override
  String get removesTheTaskFromTodayThisWeek =>
      'Removes the task from Today, This week and Overdue filters';

  @override
  String get decrease => 'Decrease';

  @override
  String get increase => 'Increase';

  @override
  String doubleTapToEdit(Object v0, Object v1) {
    return '$v0, $v1. Double-tap to edit.';
  }

  @override
  String selectTask(Object v0) {
    return 'Select task: $v0';
  }

  @override
  String restoreTask(Object v0) {
    return 'Restore task: $v0';
  }

  @override
  String completeTask(Object v0) {
    return 'Complete task: $v0';
  }

  @override
  String get rescheduleTask => 'Reschedule task';

  @override
  String get deleteTask => 'Delete task';

  @override
  String get restoreTaskCustomactions => 'Restore task';

  @override
  String get completeTaskConfirmremainingsteps => 'Complete task';

  @override
  String get addReminder => 'Add reminder';

  @override
  String deleteReminder(Object v0) {
    return 'Delete reminder: $v0';
  }

  @override
  String get upToReminders => 'Up to 5 reminders';

  @override
  String get recurringTasksSendRemindersBeforeEachDue =>
      'Recurring tasks send reminders before each due date';

  @override
  String get minutes => 'Minutes';

  @override
  String get hours => 'Hours';

  @override
  String get days => 'Days';

  @override
  String get minutesBeforeBuild2 => '5 minutes before';

  @override
  String get minutesBeforeBuild3 => '15 minutes before';

  @override
  String get minutesBeforeBuild4 => '30 minutes before';

  @override
  String get hourBeforeBuild => '1 hour before';

  @override
  String get dayBeforeBuild => '1 day before';

  @override
  String get relativeToDueTime => 'Relative to due time';

  @override
  String get setADueTimeFirst => 'Set a due time first';

  @override
  String get custom => 'Custom';

  @override
  String get reminderLeadTime => 'Reminder lead time';

  @override
  String get addBuild => 'Add';

  @override
  String get specificTime => 'Specific time';

  @override
  String get am => '9:00 AM';

  @override
  String get pm => '12:00 PM';

  @override
  String get pmBuild => '6:00 PM';

  @override
  String get pmBuild2 => '8:00 PM';

  @override
  String get customRuleReadOnly => 'Custom rule (read only)';

  @override
  String get resetRule => 'Reset rule';

  @override
  String get week => 'Week';

  @override
  String get frequency => 'Frequency';

  @override
  String get dailyBuild => 'Daily';

  @override
  String get weeklyBuild => 'Weekly';

  @override
  String get monthlyBuild => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get interval => 'Interval';

  @override
  String get every => 'Every';

  @override
  String get repeatInterval => 'Repeat interval';

  @override
  String get repeatOn => 'Repeat on';

  @override
  String get dayOfMonth => 'Day of month';

  @override
  String get day => 'Day';

  @override
  String get ends => 'Ends';

  @override
  String get never => 'Never';

  @override
  String get onDate => 'On date';

  @override
  String get afterNOccurrences => 'After N occurrences';

  @override
  String get numberOfOccurrences => 'Number of occurrences';

  @override
  String get times => 'times';

  @override
  String get fixedTimeZone => 'Fixed time zone';

  @override
  String get shortMonthsUseTheLastDayDuring =>
      'Short months use the last day. During daylight saving changes, missing times move forward and repeated times run once.';

  @override
  String summary(Object v0) {
    return 'Summary: $v0';
  }

  @override
  String get saveRecurrence => 'Save recurrence';

  @override
  String get clearRecurrence => 'Clear recurrence?';

  @override
  String get clearRecurrenceBuild => 'Clear recurrence';

  @override
  String unfinishedSteps(Object v0) {
    return 'Unfinished steps: $v0';
  }

  @override
  String get back => 'Back';

  @override
  String get taskCompleted => 'Task completed';

  @override
  String get taskReopened => 'Task reopened';

  @override
  String get stepDeleted => 'Step deleted';

  @override
  String get progressUpdated => 'Progress updated';

  @override
  String get enterAStepName => 'Enter a step name';

  @override
  String get stepsHaveChangedReviewThemBeforeSaving =>
      'Steps have changed. Review them before saving.';

  @override
  String get stepName => 'Step name';

  @override
  String get discardEdits => 'Discard edits';

  @override
  String get saveStep => 'Save step';

  @override
  String get addStep => 'Add step';

  @override
  String get doneOrganizing => 'Done organizing';

  @override
  String get organize => 'Organize';

  @override
  String moveStepUp(Object v0) {
    return 'Move step $v0 up';
  }

  @override
  String moveStepDown(Object v0) {
    return 'Move step $v0 down';
  }

  @override
  String deleteStep(Object v0) {
    return 'Delete step $v0';
  }

  @override
  String get nextStep => 'Next step';

  @override
  String get nextStepRow => ', next step';

  @override
  String step(Object v0, Object v1, Object v2) {
    return 'Step $v0, $v1$v2';
  }

  @override
  String get tagName => 'Tag name';

  @override
  String get thisWeek => 'This week';

  @override
  String get pendingLabel => 'Pending';

  @override
  String todayDuesmartlabel(Object v0) {
    return 'Today$v0';
  }

  @override
  String tomorrowDuesmartlabel(Object v0) {
    return 'Tomorrow$v0';
  }

  @override
  String yesterday(Object v0) {
    return 'Yesterday$v0';
  }

  @override
  String formattedValueDuesmartlabel(Object v0, Object v1, Object v2) {
    return '$v0/$v1$v2';
  }

  @override
  String overdueDuebadgelabel(Object v0) {
    return 'Overdue $v0';
  }

  @override
  String daysOverdue(int v0) {
    String _temp0 = intl.Intl.pluralLogic(
      v0,
      locale: localeName,
      other: '$v0 days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String hoursOverdue(int v0) {
    String _temp0 = intl.Intl.pluralLogic(
      v0,
      locale: localeName,
      other: '$v0 hours overdue',
      one: '1 hour overdue',
    );
    return '$_temp0';
  }

  @override
  String get justOverdue => 'Just overdue';

  @override
  String daysLeft(int v0) {
    String _temp0 = intl.Intl.pluralLogic(
      v0,
      locale: localeName,
      other: '$v0 days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String hoursLeft(int v0) {
    String _temp0 = intl.Intl.pluralLogic(
      v0,
      locale: localeName,
      other: '$v0 hours left',
      one: '1 hour left',
    );
    return '$_temp0';
  }

  @override
  String minutesLeft(int v0) {
    String _temp0 = intl.Intl.pluralLogic(
      v0,
      locale: localeName,
      other: '$v0 minutes left',
      one: '1 minute left',
    );
    return '$_temp0';
  }

  @override
  String todayRelativetimelabel(Object v0) {
    return 'Today $v0';
  }

  @override
  String yesterdayRelativetimelabel(Object v0) {
    return 'Yesterday $v0';
  }

  @override
  String get later => 'Later';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String everySummary(Object v0) {
    return 'Every $v0';
  }

  @override
  String everySummary2(Object v0, Object v1) {
    return 'Every $v0 $v1';
  }

  @override
  String formattedValueSummary(Object v0) {
    return '$v0';
  }

  @override
  String daySummary(Object v0) {
    return ', day $v0';
  }

  @override
  String get neverEnds => 'Never ends';

  @override
  String occurrences(Object v0) {
    return '$v0 occurrences';
  }

  @override
  String endsSummary(Object v0, Object v1, Object v2) {
    return 'Ends $v1/$v2/$v0';
  }

  @override
  String get doesNotRepeat => 'Does not repeat';

  @override
  String get customRule => 'Custom rule';

  @override
  String minBeforeDue(Object v0) {
    return '$v0 min before due';
  }

  @override
  String hrBeforeDue(Object v0) {
    return '$v0 hr before due';
  }

  @override
  String hrMinBeforeDue(Object v0, Object v1) {
    return '$v0 hr $v1 min before due';
  }

  @override
  String daysBeforeDue(Object v0) {
    return '$v0 days before due';
  }

  @override
  String daysHrBeforeDue(Object v0, Object v1) {
    return '$v0 days $v1 hr before due';
  }

  @override
  String customRemindrulelabel(Object v0, Object v1, Object v2) {
    return '$v0/$v1 $v2 (custom)';
  }

  @override
  String get copyCode => 'Copy code';

  @override
  String get codeCopied => 'Code copied';

  @override
  String get avatar => 'Avatar';

  @override
  String get processing => 'Processing';

  @override
  String formattedValueBuild2(Object v0, Object v1) {
    return '$v1/$v0';
  }

  @override
  String get previousWeek => 'Previous week';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextWeek => 'Next week';

  @override
  String get nextMonth => 'Next month';

  @override
  String tasksBuild(Object v0) {
    return ', tasks: $v0';
  }

  @override
  String formattedValueBuild3(Object v0, Object v1, Object v2, Object v3) {
    return '$v1/$v2/$v0$v3';
  }

  @override
  String get dismiss => 'Dismiss';

  @override
  String get collapseSidebar => 'Collapse sidebar';

  @override
  String get copyReply => 'Copy reply';

  @override
  String get copied => 'Copied';

  @override
  String get saving => 'Saving';

  @override
  String subscriptionTier(Object v0) {
    return 'Subscription tier $v0';
  }

  @override
  String get inDevelopment => 'In development';

  @override
  String get search => 'Search';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get newType => 'New type';

  @override
  String items(Object v0) {
    return ', items: $v0';
  }

  @override
  String get savingTryAgainShortly => 'Saving. Try again shortly.';

  @override
  String get recordChangedReopenAndTryAgain =>
      'Record changed. Reopen and try again.';

  @override
  String get actionAlreadySubmittedCheckTheLatestRecord =>
      'Action already submitted. Check the latest record.';

  @override
  String get invalidContentOrCategoryRelationshipCheckAnd =>
      'Invalid content or category relationship. Check and try again.';

  @override
  String get recordNoLongerExistsRefreshAndTry =>
      'Record no longer exists. Refresh and try again.';

  @override
  String get couldntSaveYourDataIsSafeTry =>
      'Couldn’t save. Your data is safe. Try again.';

  @override
  String get webToolsMonthly => 'Web tools, monthly';

  @override
  String get dailyOrder => 'Daily';

  @override
  String get quota => 'Quota';

  @override
  String get periodQuota => 'Period quota';

  @override
  String get hoursOrder => '5 hours';

  @override
  String get tasksAndDailyDigest => 'Tasks and daily digest';

  @override
  String get yourTaskRemindersAndDailyDigests =>
      'Your task reminders and daily digests';

  @override
  String get textFiles => 'Text files';

  @override
  String get chooseAValidTopLevelCategory =>
      'Choose a valid top-level category';

  @override
  String get invalidChatForThisMessage => 'Invalid chat for this message';

  @override
  String get newChat => 'New chat';

  @override
  String get chatNotFound => 'Chat not found';

  @override
  String get messageIdAlreadyExists => 'Message ID already exists';

  @override
  String get messageIdBelongsToAnotherChat =>
      'Message ID belongs to another chat';

  @override
  String get messagesCantBeMovedBetweenChats =>
      'Messages can’t be moved between chats';

  @override
  String get chatName => 'Chat name';

  @override
  String get typeAlreadyExists => 'Type already exists';

  @override
  String get tableName => 'Table name';

  @override
  String get fieldNotFound => 'Field not found';

  @override
  String get fieldName => 'Field name';

  @override
  String get provideAValueForExistingRecordsBefore =>
      'Provide a value for existing records before requiring this field';

  @override
  String get keepAtLeastOneField => 'Keep at least one field';

  @override
  String get aTableWithThisIdentifierAlreadyExists =>
      'A table with this identifier already exists';

  @override
  String get invalidOrDuplicateRowId => 'Invalid or duplicate row ID';

  @override
  String get thisRecordAlreadyExistsAndCantBe =>
      'This record already exists and can’t be restored over it';

  @override
  String get recordDeleted => 'Record deleted';

  @override
  String get analysisOfHoldingsPng => 'Analysis of “Holdings_0921.png”';

  @override
  String get nameNewTableSheet => 'Name';

  @override
  String get kweichowMoutai => 'Kweichow Moutai';

  @override
  String get sharesHeld => 'Shares held';

  @override
  String get currentPrice => 'Current price';

  @override
  String get byd => 'BYD';

  @override
  String get newRecord => 'New record';

  @override
  String get theseAiChangesHaveBeenProcessedReopen =>
      'These AI changes have been processed. Reopen the pending record.';

  @override
  String get theSelectedChangeNoLongerExists =>
      'The selected change no longer exists';

  @override
  String get recordDeletedOrMovedToAnotherTable =>
      'Record deleted or moved to another table. Review again.';

  @override
  String get aChangeCannotIncludeTheSameField =>
      'A change cannot include the same field twice';

  @override
  String get incompleteDeletionSnapshotReviewAgain =>
      'Incomplete deletion snapshot. Review again.';

  @override
  String get recordUpdatedReviewTheAiChangesAgain =>
      'Record updated. Review the AI changes again.';

  @override
  String get recordChangedSinceThisAiUpdateUndo =>
      'Record changed since this AI update. Undo is unavailable.';

  @override
  String get tableMissingOrArchived => 'Table missing or archived';

  @override
  String get dataTypeNoLongerExistsChooseAgain =>
      'Data type no longer exists. Choose again.';

  @override
  String get invalidOrDuplicateDataTypeName =>
      'Invalid or duplicate data type name';

  @override
  String get tableTypeNotFound => 'Table type not found';

  @override
  String get parentTableNotFoundForRow => 'Parent table not found for row';

  @override
  String get parentTableNotFoundForAiBatch =>
      'Parent table not found for AI batch';

  @override
  String get typeName => 'Type name';

  @override
  String get useUpToCharactersForTheType =>
      'Use up to 24 characters for the type name';

  @override
  String get addAtLeastOneField => 'Add at least one field';

  @override
  String get fieldNamesCannotBeEmptyOrBegin =>
      'Field names cannot be empty or begin or end with whitespace';

  @override
  String get fieldNamesMustBeUnique => 'Field names must be unique';

  @override
  String requiresAtLeastOneOption(Object v0) {
    return '“$v0” requires at least one option';
  }

  @override
  String optionsForCannotBeBlankOrBegin(Object v0) {
    return 'Options for “$v0” cannot be blank or begin or end with whitespace';
  }

  @override
  String optionsForMustBeUnique(Object v0) {
    return 'Options for “$v0” must be unique';
  }

  @override
  String dataContainsAnUndefinedField(Object v0) {
    return 'Data contains an undefined field: “$v0”';
  }

  @override
  String isRequired(Object v0) {
    return '“$v0” is required';
  }

  @override
  String get aFiniteNumber => 'a finite number';

  @override
  String get aValidDateYyyyMmDd => 'a valid date (yyyy-MM-dd)';

  @override
  String get aValidDateAndTimeYyyyMm =>
      'a valid date and time (yyyy-MM-dd HH:mm)';

  @override
  String get anExistingOption => 'an existing option';

  @override
  String get trueOrFalse => 'true or false';

  @override
  String mustBe(Object v0, Object v1) {
    return '“$v0” must be $v1';
  }

  @override
  String get memoryContent => 'Memory content';

  @override
  String get memoryType => 'Memory type';

  @override
  String get useUpToCharactersForTheTypeName =>
      'Use up to 20 characters for the type name';

  @override
  String get endDateCannotPrecedeStartDate =>
      'End date cannot precede start date';

  @override
  String get reportGenerationFailedTryAgain =>
      'Report generation failed. Try again.';

  @override
  String get weeklyReport => 'Weekly report';

  @override
  String get monthlyReport => 'Monthly report';

  @override
  String get report => 'Report';

  @override
  String get investing => 'Investing';

  @override
  String get archives => 'Archives';

  @override
  String get family => 'Family';

  @override
  String get work => 'Work';

  @override
  String get overview => '## Overview';

  @override
  String scope(Object v0) {
    return 'Scope: $v0.';
  }

  @override
  String get recordIdsCannotBeEmptyOrDuplicated =>
      'Record IDs cannot be empty or duplicated';

  @override
  String isRequiredRequiretext(Object v0) {
    return '$v0 is required';
  }

  @override
  String get taskIdAlreadyExists => 'Task ID already exists';

  @override
  String get quotaExhausted => 'Quota exhausted';

  @override
  String get tooManyRequests => 'Too many requests';

  @override
  String get invalidKey => 'Invalid key';

  @override
  String get accessDenied => 'Access denied';

  @override
  String get modelUnavailable => 'Model unavailable';

  @override
  String get serviceTemporarilyUnavailable => 'Service temporarily unavailable';

  @override
  String get alwaysAsk => 'Always ask';

  @override
  String get askBeforeTheAiChangesTasksOr =>
      'Ask before the AI changes tasks or tables';

  @override
  String get smartConfirmation => 'Smart confirmation';

  @override
  String get applyTaskAdditionsEditsAndCompletionsImmediately =>
      'Apply task additions, edits and completions immediately. Confirm deletions and table changes.';

  @override
  String get runAutomatically => 'Run automatically';

  @override
  String get applyTaskChangesAndKeepAHistory =>
      'Apply task changes and keep a history. Confirm table changes.';

  @override
  String get kimiCodeSubscription => 'Kimi Code subscription';

  @override
  String get kimiKHighspeed => 'Kimi K2.8 HighSpeed';

  @override
  String get glmCodingPlanSubscription => 'GLM Coding Plan subscription';

  @override
  String get thisPlanIsRestrictedToSupportedCoding =>
      'This plan is restricted to supported coding tools. Other clients may be throttled or disabled.';

  @override
  String get deepseekPlatform => 'DeepSeek Platform';

  @override
  String get kimiPlatform => 'Kimi Platform';

  @override
  String get zhipuGlmPlatform => 'Zhipu GLM Platform';

  @override
  String get zhipuGlm => 'Zhipu GLM';

  @override
  String get openaiCompatibleApi => 'OpenAI-compatible API';

  @override
  String get fact => 'Fact';

  @override
  String get preference => 'Preference';

  @override
  String get event => 'Event';

  @override
  String get profile => 'Profile';

  @override
  String get active => 'Active';

  @override
  String get expired => 'Expired';

  @override
  String get intentRecognition => 'Intent recognition';

  @override
  String get chat => 'Chat';

  @override
  String get reportGeneration => 'Report generation';

  @override
  String get screenshotAnalysis => 'Screenshot analysis';

  @override
  String stepsStepprogress(Object v0, Object v1) {
    return 'Steps $v0/$v1';
  }

  @override
  String dueEarlierUnfinished(Object v0, Object v1, Object v2, Object v3) {
    return '$v0/$v1: $v2 due, $v3 overdue. ';
  }

  @override
  String scheduledSnapshotOpenForTheLatest(Object v0) {
    return '${v0}Open for the latest.';
  }

  @override
  String get taskReminder => 'Task reminder';

  @override
  String get dailyTaskDigest => 'Daily task digest';

  @override
  String get unknownVersion => 'Unknown version';

  @override
  String get restoreBaseVersion => 'Restore base version';

  @override
  String patchP(Object v0) {
    return 'Patch P$v0';
  }

  @override
  String get exitReorderMode => 'Exit reorder mode';

  @override
  String get reorderCategories => 'Reorder categories';

  @override
  String get finishReordering => 'Finish reordering';

  @override
  String get inUse => 'In use';

  @override
  String get allCategoriesArchived => 'All categories archived';

  @override
  String get noCategories => 'No categories';

  @override
  String get createSampleCategories => 'Create sample categories';

  @override
  String get createsInvestingArchivesAndFamily =>
      'Creates Investing, Archives and Family';

  @override
  String get archivedTapToCollapse => 'Archived, tap to collapse';

  @override
  String get archivedTapToExpand => 'Archived, tap to expand';

  @override
  String archived(Object v0) {
    return 'Archived: $v0';
  }

  @override
  String get dropBetweenTopLevelRowsToReorder =>
      'Drop between top-level rows to reorder or promote';

  @override
  String get dropOntoATopLevelRowTo =>
      'Drop onto a top-level row to make a subcategory';

  @override
  String get upToTwoCategoryLevels => 'Up to two category levels';

  @override
  String restoredOpenarchivedactions(Object v0) {
    return '“$v0” restored';
  }

  @override
  String archivedAndHiddenWhenCreatingTasks(Object v0) {
    return '“$v0” archived and hidden when creating tasks';
  }

  @override
  String deletedEditcategory(Object v0) {
    return 'Deleted “$v0”';
  }

  @override
  String get completionRateUnknown => 'Completion rate unknown';

  @override
  String completeSemanticslabel(Object v0) {
    return '$v0% complete';
  }

  @override
  String archivedCategoryTasksDoubleTapForRestore(Object v0, Object v1) {
    return 'Archived category $v0, $v1 tasks. Double-tap for restore options.';
  }

  @override
  String subcategoryTasks(Object v0, Object v1, Object v2) {
    return 'Subcategory $v0, $v1 tasks, $v2';
  }

  @override
  String categoryTasks(Object v0, Object v1, Object v2) {
    return 'Category $v0, $v1 tasks, $v2';
  }

  @override
  String get subcategoriesExpanded => ', subcategories expanded';

  @override
  String get subcategoriesCollapsed => ', subcategories collapsed';

  @override
  String get doubleTapToEditHoldAndDrag =>
      '. Double-tap to edit. Hold and drag to reorder.';

  @override
  String get collapseSubcategories => 'Collapse subcategories';

  @override
  String get expandSubcategories => 'Expand subcategories';

  @override
  String itemsStats(Object v0) {
    return '$v0 items —';
  }

  @override
  String itemsStats2(Object v0) {
    return '$v0 items ';
  }

  @override
  String moreActionsFor(Object v0) {
    return 'More actions for $v0';
  }

  @override
  String itemsBuild(num v0) {
    String _temp0 = intl.Intl.pluralLogic(
      v0,
      locale: localeName,
      other: '$v0 items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get advanced => ' Advanced';

  @override
  String get couldntReplyTryAgain => 'Couldn’t reply. Try again.';

  @override
  String get couldntRefreshLocalChatsShowingTheLast =>
      'Couldn’t refresh local chats. Showing the last saved content.';

  @override
  String get reload => 'Reload';

  @override
  String get renameChat => 'Rename chat';

  @override
  String get save => 'Save';

  @override
  String get deleteThisChat => 'Delete this chat?';

  @override
  String get tasksCreatedInThisChatWillBe =>
      'Tasks created in this chat will be kept.';

  @override
  String get deleteChat => 'Delete chat';

  @override
  String hiWhatsOnYourListToday(Object v0) {
    return 'Hi $v0, what’s on your list today?';
  }

  @override
  String get replyIncomplete => 'Reply incomplete';

  @override
  String get voiceInputInterrupted => 'Voice input interrupted';

  @override
  String get couldntStartVoiceInput => 'Couldn’t start voice input';

  @override
  String get transcriptIsTooLongSplitItInto =>
      'Transcript is too long. Split it into shorter requests.';

  @override
  String get couldntHearThatTryAgain => 'Couldn’t hear that. Try again.';

  @override
  String get recognitionTimedOutTryAgain => 'Recognition timed out. Try again.';

  @override
  String get couldntSendYourTextIsSaved => 'Couldn’t send. Your text is saved.';

  @override
  String get allowMicrophoneAccessInSystemSettings =>
      'Allow microphone access in system settings';

  @override
  String get selectedLanguageIsUnavailable =>
      'Selected language is unavailable';

  @override
  String get thisRecognizerDoesNotSupportOnDevice =>
      'This recognizer does not support on-device mode. Network recognition is off.';

  @override
  String get couldntConnectToSpeechService =>
      'Couldn’t connect to speech service';

  @override
  String get microphoneInUse => 'Microphone in use';

  @override
  String get recordingInterrupted => 'Recording interrupted';

  @override
  String get voiceInputUnavailable => 'Voice input unavailable';

  @override
  String get notSentTryAgain => 'Not sent. Try again.';

  @override
  String get answered => 'Answered';

  @override
  String get chatContinued => 'Chat continued';

  @override
  String get addToYourAnswer => 'Add to your answer';

  @override
  String get collapseAdditionalAnswer => 'Collapse additional answer';

  @override
  String get addAnAnswer => 'Add an answer';

  @override
  String get collapse => 'Collapse';

  @override
  String get otherAnswer => 'Other answer';

  @override
  String get confirmAnswer => 'Confirm answer';

  @override
  String get sending => 'Sending';

  @override
  String get send => 'Send';

  @override
  String sendSelections(Object v0) {
    return 'Send $v0 selections';
  }

  @override
  String get undoTask => 'Undo task';

  @override
  String get restoredToPending => 'Restored to pending';

  @override
  String get editTask => 'Edit task';

  @override
  String get previousPage => 'Previous page';

  @override
  String get page => 'Page';

  @override
  String get nextPage => 'Next page';

  @override
  String moreItems(Object v0) {
    return '$v0 more items';
  }

  @override
  String itemsRemoved(Object v0) {
    return '$v0 items removed';
  }

  @override
  String completeBuild(Object v0, Object v1) {
    return '$v0/$v1 complete';
  }

  @override
  String view(Object v0) {
    return 'View $v0';
  }

  @override
  String get theTasksInThisListHaveBeen =>
      'The tasks in this list have been removed';

  @override
  String get noTasksInThisRange => 'No tasks in this range';

  @override
  String taskBuild(Object v0, Object v1) {
    return '$v0 task: $v1';
  }

  @override
  String editTaskBuild(Object v0) {
    return 'Edit task: $v0';
  }

  @override
  String get scrollToLatest => 'Scroll to latest';

  @override
  String get schedule => 'Schedule';

  @override
  String get data => 'Data';

  @override
  String get memory => 'Memory';

  @override
  String get settings => 'Settings';

  @override
  String get collapseCategories => 'Collapse categories';

  @override
  String get expandCategories => 'Expand categories';

  @override
  String get reorderCategoriesBuild => 'Reorder categories';

  @override
  String get chatHistory => 'Chat history';

  @override
  String get noChatsYet => 'No chats yet';

  @override
  String get toggleLightOrDarkTheme => 'Toggle light or dark theme';

  @override
  String editCategorylist(Object v0) {
    return 'Edit $v0';
  }

  @override
  String dragToReorder(Object v0) {
    return 'Drag to reorder $v0';
  }

  @override
  String expandSubcategoriesOf(Object v0) {
    return 'Expand subcategories of $v0';
  }

  @override
  String get yesterdayGroup => 'Yesterday';

  @override
  String get lastDays => 'Last 7 days';

  @override
  String get earlier => 'Earlier';

  @override
  String get openMenu => 'Open menu';

  @override
  String get searchChatsAndTasks => 'Search chats and tasks';

  @override
  String get openDailyOverview => 'Open daily overview';

  @override
  String get newChatBuild => 'New chat';

  @override
  String get chatOptions => 'Chat options';

  @override
  String image(Object v0) {
    return 'Image “$v0”:';
  }

  @override
  String get takeALookAtThisImage => 'Take a look at this image';

  @override
  String contentTruncated(Object v0) {
    return '$v0\n… (content truncated)';
  }

  @override
  String contentsOf(Object v0, Object v1) {
    return 'Contents of “$v0”:\n$v1';
  }

  @override
  String contentsOfSubmitwithattachment(Object v0, Object v1, Object v2) {
    return '$v0\n\nContents of “$v1”:\n$v2';
  }

  @override
  String get connectAnAccountInModelsAndUsage =>
      'Connect an account in Models and usage first';

  @override
  String get addToChat => 'Add to chat';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseImage => 'Choose image';

  @override
  String get fileTooLargeImagesUpToMb =>
      'File too large. Images: up to 10 MB. Text: up to 512 KB.';

  @override
  String get couldntReadTheImageChooseAStatic =>
      'Couldn’t read the image. Choose a static PNG or JPEG.';

  @override
  String get couldntReadTheFileTryAgain => 'Couldn’t read the file. Try again.';

  @override
  String get holdToTranscribe => 'Hold to transcribe';

  @override
  String get askAnything => 'Ask anything…';

  @override
  String get holdToRecordReleaseToSend => 'Hold to record, release to send';

  @override
  String get holdToTalk => 'Hold to talk';

  @override
  String get stopGenerating => 'Stop generating';

  @override
  String get sendMessage => 'Send message';

  @override
  String get switchToKeyboard => 'Switch to keyboard';

  @override
  String get switchToVoice => 'Switch to voice';

  @override
  String get addAttachment => 'Add attachment';

  @override
  String attachmentToSend(Object v0) {
    return 'Attachment to send: $v0';
  }

  @override
  String get removeAttachment => 'Remove attachment';

  @override
  String tomorrowFormatdue(Object v0) {
    return 'Tomorrow $v0';
  }

  @override
  String dayAfterTomorrow(Object v0) {
    return 'Day after tomorrow $v0';
  }

  @override
  String formattedValueExportlabel(Object v0, Object v1, Object v2) {
    return '$v0/$v1 $v2';
  }

  @override
  String get monFormatrelative => 'Mon';

  @override
  String get tueFormatrelative => 'Tue';

  @override
  String get wedFormatrelative => 'Wed';

  @override
  String get thuFormatrelative => 'Thu';

  @override
  String get friFormatrelative => 'Fri';

  @override
  String get satFormatrelative => 'Sat';

  @override
  String get sun => 'Sun';

  @override
  String get stopped => 'Stopped';

  @override
  String get thinking => 'Thinking…';

  @override
  String get connectModel => 'Connect model';

  @override
  String get chooseModel => 'Choose model';

  @override
  String chooseModelBuild(Object v0) {
    return 'Choose model, $v0';
  }

  @override
  String get couldntLoadModelSettings => 'Couldn’t load model settings';

  @override
  String get couldntSwitchModelsTurnAutomaticFallbackBack =>
      'Couldn’t switch models. Turn automatic fallback back on to retry.';

  @override
  String get couldntSwitchTryAgainLater => 'Couldn’t switch. Try again later.';

  @override
  String get backToProviders => 'Back to providers';

  @override
  String get automaticFallback => 'Automatic fallback';

  @override
  String get addModelAccount => 'Add model account';

  @override
  String get manageAccounts => 'Manage accounts';

  @override
  String account(Object v0) {
    return 'Account $v0 ';
  }

  @override
  String get accountRemovedGoBackAndChooseAnother =>
      'Account removed. Go back and choose another.';

  @override
  String get deepThinking => 'Deep thinking';

  @override
  String get voiceInputFailedYourTranscriptIsSaved =>
      'Voice input failed. Your transcript is saved.';

  @override
  String get taskUndone => 'Task undone';

  @override
  String get theTaskChangedAndCannotBeRestored =>
      'The task changed and cannot be restored';

  @override
  String completedToggledone(Object v0) {
    return 'Completed $v0';
  }

  @override
  String get updatedEdittodo => 'Updated';

  @override
  String get nextWeekBuild => 'Next week';

  @override
  String get preparingMicrophone => 'Preparing microphone';

  @override
  String get recording => 'Recording';

  @override
  String get transcribingAudio => 'Transcribing audio';

  @override
  String get voiceReadyToSend => 'Voice ready to send';

  @override
  String get sendingVoiceInput => 'Sending voice input';

  @override
  String get typeAMessage => 'Type a message';

  @override
  String get tapToTypeHoldToTranscribe => 'Tap to type, hold to transcribe';

  @override
  String get activateToDictateOrHoldToRecord =>
      'Activate to dictate, or hold to record';

  @override
  String get activateToFinishRecordingAndSendThe =>
      'Activate to finish recording and send the transcript';

  @override
  String get cancelVoiceInputOrSwitchToThe =>
      'Cancel voice input or switch to the keyboard';

  @override
  String get preparingToRecord => 'Preparing to record';

  @override
  String get releaseToCancel => 'Release to cancel';

  @override
  String get releaseToEdit => 'Release to edit';

  @override
  String get releaseToSend => 'Release to send';

  @override
  String get transcribing => 'Transcribing';

  @override
  String get sendingShortly => 'Sending shortly';

  @override
  String get endRecording => 'End recording';

  @override
  String get voiceInput => 'Voice input';

  @override
  String get listening => 'Listening…';

  @override
  String get cancelVoiceInput => 'Cancel voice input';

  @override
  String get editTranscript => 'Edit transcript';

  @override
  String get offlineSpeechRecognition => 'Offline speech recognition';

  @override
  String get offlineModelReady => 'Offline model ready';

  @override
  String get startVoiceInput => 'Start voice input';

  @override
  String get transcribesOnThisDeviceWithTheBuilt =>
      'Transcribes on this device with the built-in model, even offline.';

  @override
  String get installingTheBuiltInOfflineModel =>
      'Installing the built-in offline model…';

  @override
  String downloadAboutMb(Object v0) {
    return 'Download (about $v0 MB)';
  }

  @override
  String get cancelDownload => 'Cancel download';

  @override
  String get retryDownload => 'Retry download';

  @override
  String get reinstallBuiltInModel => 'Reinstall built-in model';

  @override
  String get installBuiltInOfflineModel => 'Install built-in offline model';

  @override
  String downloadInsteadAboutMb(Object v0) {
    return 'Download instead (about $v0 MB)';
  }

  @override
  String downloadedOfMb(Object v0, Object v1) {
    return 'Downloaded $v0 of $v1 MB';
  }

  @override
  String modelsAndUsage(Object v0) {
    return 'Models and usage, $v0';
  }

  @override
  String get remainingBuild => 'Remaining';

  @override
  String get closeSearch => 'Close search';

  @override
  String get noResults => 'No results';

  @override
  String get goToChat => 'Go to chat';

  @override
  String get analysisDiscarded => 'Analysis discarded';

  @override
  String get chooseFromPhotos => 'Choose from photos';

  @override
  String get rowAdded => 'Row added';

  @override
  String exportedRowsTo(Object v0, Object v1) {
    return 'Exported $v0 rows to $v1';
  }

  @override
  String get exportFailedTryAgain => 'Export failed. Try again.';

  @override
  String get changeType => 'Change type';

  @override
  String get manageFields => 'Manage fields';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get archiveThisTable => 'Archive this table?';

  @override
  String get archivedTablesAreHiddenFromTheList =>
      'Archived tables are hidden from the list. Their data is retained.';

  @override
  String get deleteTable => 'Delete table';

  @override
  String get deleteThisTable => 'Delete this table?';

  @override
  String get youCanUndoTheDeletion => 'You can undo the deletion.';

  @override
  String alsoDeletesRowsYouCanUndoThe(Object v0) {
    return 'Also deletes $v0 rows. You can undo the deletion.';
  }

  @override
  String renamedTo(Object v0) {
    return 'Renamed to “$v0”';
  }

  @override
  String get source => 'Source';

  @override
  String get addedByMe => 'Added by me';

  @override
  String get addedByAi => 'Added by AI';

  @override
  String get recentlyUpdatedFirst => 'Recently updated first';

  @override
  String get firstFieldAZ => 'First field A–Z';

  @override
  String get firstFieldZA => 'First field Z–A';

  @override
  String get noMatchingRecords => 'No matching records';

  @override
  String noResultsFor(Object v0) {
    return 'No results for “$v0”';
  }

  @override
  String get adjustTheFiltersOrTryAnotherKeyword =>
      'Adjust the filters or try another keyword';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String results(Object v0) {
    return 'Results: $v0';
  }

  @override
  String get loadMore => 'Load more';

  @override
  String get tableUnavailable => 'Table unavailable';

  @override
  String get itMayHaveBeenArchivedOrDeleted =>
      'It may have been archived or deleted.';

  @override
  String get backToList => 'Back to list';

  @override
  String get tableSettings => 'Table settings';

  @override
  String get importScreenshot => 'Import screenshot';

  @override
  String get newRow => 'New row';

  @override
  String rows(num v0) {
    String _temp0 = intl.Intl.pluralLogic(
      v0,
      locale: localeName,
      other: '$v0 rows',
      one: '1 row',
    );
    return '$_temp0';
  }

  @override
  String get aiChangesAwaitingReview => 'AI changes awaiting review';

  @override
  String get searchRows => 'Search rows';

  @override
  String get filter => 'Filter';

  @override
  String get noDataYet => 'No data yet';

  @override
  String get createARow => 'Create a row';

  @override
  String get changeHistory => 'Change history';

  @override
  String get copyRow => 'Copy row';

  @override
  String get rowCopied => 'Row copied';

  @override
  String get deleteThisRow => 'Delete this row?';

  @override
  String willBeDeletedYouCanReviewIt(Object v0) {
    return '“$v0” will be deleted. You can review it in change history.';
  }

  @override
  String get recordBuild => 'Record';

  @override
  String get untitled => '(Untitled)';

  @override
  String createdCreatetable(Object v0) {
    return 'Created “$v0”';
  }

  @override
  String get createFromTemplate => 'Create from template';

  @override
  String createFromTemplateShowtemplates(Object v0) {
    return 'Create from template: $v0';
  }

  @override
  String fields(num v0) {
    String _temp0 = intl.Intl.pluralLogic(
      v0,
      locale: localeName,
      other: '$v0 fields',
      one: '1 field',
    );
    return '$_temp0';
  }

  @override
  String get dataTables => 'Data tables';

  @override
  String tables(num v0) {
    String _temp0 = intl.Intl.pluralLogic(
      v0,
      locale: localeName,
      other: '$v0 tables',
      one: '1 table',
    );
    return '$_temp0';
  }

  @override
  String get recentlyUpdated => 'Recently updated';

  @override
  String get noMatchingTables => 'No matching tables';

  @override
  String get noTablesYet => 'No tables yet';

  @override
  String get newTable => 'New table';

  @override
  String get searchTables => 'Search tables';

  @override
  String fieldsRows(Object v0, Object v1, Object v2) {
    return '$v0 fields, $v1 rows $v2';
  }

  @override
  String fieldsRowsAiChangesToReview(
    Object v0,
    Object v1,
    Object v2,
    Object v3,
  ) {
    return '$v0, $v1 fields, $v2 rows, $v3 AI changes to review';
  }

  @override
  String fieldsRowsBuild(Object v0, Object v1, Object v2) {
    return '$v0, $v1 fields, $v2 rows';
  }

  @override
  String csvExported(Object v0) {
    return 'CSV exported: $v0';
  }

  @override
  String get copyTableStructure => 'Copy table structure';

  @override
  String copy(Object v0) {
    return '$v0 copy';
  }

  @override
  String createdCopy(Object v0) {
    return 'Created copy “$v0”';
  }

  @override
  String get archivedTablesAreHiddenArchiveATable =>
      'Archived tables are hidden. Archive a table before deleting it.';

  @override
  String archivedShowcontextsheet(Object v0) {
    return 'Archived “$v0”';
  }

  @override
  String get addRow => 'Add row';

  @override
  String get discardThisAnalysis => 'Discard this analysis?';

  @override
  String get includesOneDeletionDiscardingRemovesThisAi =>
      'Includes one deletion. Discarding removes this AI analysis.';

  @override
  String get discard => 'Discard';

  @override
  String aiProposesChanges(Object v0) {
    return 'AI proposes $v0 changes';
  }

  @override
  String get viewSource => 'View source';

  @override
  String from(Object v0) {
    return 'From $v0 ›';
  }

  @override
  String applySelected(Object v0) {
    return 'Apply selected ($v0)';
  }

  @override
  String get deselect => 'Deselect';

  @override
  String get selectLabelBuild => 'Select';

  @override
  String aiAddedRows(Object v0) {
    return 'AI added $v0 rows';
  }

  @override
  String aiMadeChanges(Object v0) {
    return 'AI made $v0 changes';
  }

  @override
  String get undoneChangesReverted => 'Undone. Changes reverted.';

  @override
  String get aiEdits => 'AI edits';

  @override
  String aiChangesAwaitingReviewBuild(Object v0) {
    return 'AI changes awaiting review: $v0';
  }

  @override
  String review(Object v0) {
    return 'Review $v0';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String chooseType(Object v0) {
    return 'Choose type $v0';
  }

  @override
  String typeBuild(Object v0) {
    return 'Type: $v0';
  }

  @override
  String get aiIsUnsurePleaseVerify => 'AI is unsure. Please verify.';

  @override
  String get enterText => 'Enter text';

  @override
  String get enterANumber => 'Enter a number';

  @override
  String get clear => 'Clear';

  @override
  String get currency => 'Currency';

  @override
  String get boolean => 'Boolean';

  @override
  String get deletionUnavailable => 'Deletion unavailable';

  @override
  String get tooManyRecordsUseThisFieldTo =>
      'Too many records use this field to delete it here';

  @override
  String get gotIt => 'Got it';

  @override
  String deleteField(Object v0) {
    return 'Delete field “$v0”?';
  }

  @override
  String get thisFieldHasNoValues => 'This field has no values.';

  @override
  String alsoClearsThisFieldInRows(Object v0) {
    return 'Also clears this field in $v0 rows.';
  }

  @override
  String get fieldDeleted => 'Field deleted';

  @override
  String get enterOneOfTheOptions => 'Enter one of the options';

  @override
  String enterAnOptionEG(Object v0) {
    return 'Enter an option, e.g. “$v0”';
  }

  @override
  String get eG => 'e.g. 3.5';

  @override
  String get eGBackfillhint => 'e.g. 1250.00';

  @override
  String get defaultForExistingRecords => 'Default for existing records';

  @override
  String get fieldNameIsRequired => 'Field name is required';

  @override
  String get provideAtLeastOneCommaSeparatedOption =>
      'Provide at least one comma-separated option';

  @override
  String get fieldAdded => 'Field added';

  @override
  String fieldsBuildfieldlist(Object v0) {
    return 'Fields: $v0';
  }

  @override
  String get noFieldsYet => 'No fields yet';

  @override
  String get addFieldBuildfieldlist => 'Add field';

  @override
  String get fieldNameBuildaddform => 'Field name';

  @override
  String get options => 'Options';

  @override
  String get commaSeparated => 'Comma-separated';

  @override
  String optionsBuildaddform(num v0) {
    String _temp0 = intl.Intl.pluralLogic(
      v0,
      locale: localeName,
      other: '$v0 options',
      one: '1 option',
    );
    return '$_temp0';
  }

  @override
  String get unitOptional => 'Unit (optional)';

  @override
  String get eGSharesMinutes => 'e.g. shares, minutes';

  @override
  String get decimalPlaces => 'Decimal places';

  @override
  String get setADefaultForExistingRecords =>
      'Set a default for existing records';

  @override
  String appliesToAllExistingRows(Object v0) {
    return 'Applies to all $v0 existing rows';
  }

  @override
  String renameBuild(Object v0) {
    return 'Rename “$v0”';
  }

  @override
  String deleteLabelBuild2(Object v0) {
    return 'Delete “$v0”';
  }

  @override
  String get renameField => 'Rename field';

  @override
  String get justNow => 'Just now';

  @override
  String minAgo(Object v0) {
    return '$v0 min ago';
  }

  @override
  String get switchLabel => 'Switch';

  @override
  String get thisRow => 'This row';

  @override
  String get couldntLoadChangeHistory => 'Couldn’t load change history';

  @override
  String get noChangesYet => 'No changes yet';

  @override
  String get restoreThisVersion => 'Restore this version?';

  @override
  String restoresTheVersionFromTheRestoreWill(Object v0) {
    return 'Restores the version from $v0. The restore will appear in history.';
  }

  @override
  String restoresTheVersionFromAndUndoesLater(Object v0, Object v1) {
    return 'Restores the version from $v0 and undoes $v1 later changes. The restore will appear in history.';
  }

  @override
  String get restoreVersion => 'Restore version';

  @override
  String restoredTheVersionFrom(Object v0) {
    return 'Restored the version from $v0';
  }

  @override
  String get me => 'Me';

  @override
  String get createdThisRow => 'Created this row';

  @override
  String get deletedThisRow => 'Deleted this row';

  @override
  String get viewOriginalImage => 'View original image';

  @override
  String viewOriginal(Object v0) {
    return '$v0 View original ▸';
  }

  @override
  String get imageTooLargeChooseAPngOr =>
      'Image too large. Choose a PNG or JPEG under 10 MB or crop it.';

  @override
  String get couldntReadThisImageChooseAComplete =>
      'Couldn’t read this image. Choose a complete, static PNG or JPEG.';

  @override
  String get theOriginalAndItsCopyAreUnavailable =>
      'The original and its copy are unavailable. Choose the image again.';

  @override
  String get thisImageIsLinkedToARecognition =>
      'This image is linked to a recognition record and is retained for history.';

  @override
  String get couldntReadOrSaveTheImageExisting =>
      'Couldn’t read or save the image. Existing data is retained.';

  @override
  String get addTheClearlyIdentifiableRecordsToThis =>
      'Add the clearly identifiable records to this table. Ask me about anything uncertain.';

  @override
  String imageStart(Object v0, Object v1) {
    return 'Image “$v0”: $v1';
  }

  @override
  String get unavailableBuild => 'Unavailable';

  @override
  String targetTable(Object v0) {
    return 'Target table: $v0';
  }

  @override
  String get stopRecognition => 'Stop recognition';

  @override
  String get savedImages => 'Saved images';

  @override
  String get saved => 'Saved';

  @override
  String get incompleteFileChooseItAgain => 'Incomplete file. Choose it again.';

  @override
  String get removeUnusedImage => 'Remove unused image';

  @override
  String get retryReading => 'Retry reading';

  @override
  String get importInstructions => 'Import instructions';

  @override
  String get addRecordsOrSpecifyWhichRecordsTo =>
      'Add records or specify which records to update';

  @override
  String get theImageWillBeSentToThe =>
      'The image will be sent to the selected model and use its quota.';

  @override
  String get analyzeAndImport => 'Analyze and import';

  @override
  String get viewSourceImage => 'View source image';

  @override
  String get thisRecordHasNoLinkedSourceImage =>
      'This record has no linked source image.';

  @override
  String get demoImagePlaceholder => 'Demo image placeholder';

  @override
  String get closeImage => 'Close image';

  @override
  String get enterATableName => 'Enter a table name';

  @override
  String fieldsBuild(Object v0) {
    return 'Fields ($v0)';
  }

  @override
  String deleteFieldBuild(Object v0) {
    return 'Delete field $v0';
  }

  @override
  String get optionOneOptionTwo => 'Option one\nOption two';

  @override
  String get enterUniqueOptionsOnePerLine =>
      'Enter unique options, one per line';

  @override
  String get oneOptionPerLine => 'One option per line';

  @override
  String get invalidContentOrFieldFormatCheckAnd =>
      'Invalid content or field format. Check and try again.';

  @override
  String get savingPleaseWait => 'Saving. Please wait.';

  @override
  String get recordNoLongerExists => 'Record no longer exists';

  @override
  String get backToTable => 'Back to table';

  @override
  String get recordDetails => 'Record details';

  @override
  String get equals => 'Equals';

  @override
  String get containsRowFilterSheet => 'Contains';

  @override
  String get greaterThan => 'Greater than';

  @override
  String get atLeast => 'At least';

  @override
  String get lessThan => 'Less than';

  @override
  String get atMost => 'At most';

  @override
  String enterANumberWithUpToDecimal(Object v0) {
    return 'Enter a number with up to $v0 decimal places';
  }

  @override
  String get addUpToFourFieldConditions => 'Add up to four field conditions';

  @override
  String conditions(Object v0) {
    return 'Conditions: $v0';
  }

  @override
  String get noFilterableFieldsInThisTable =>
      'No filterable fields in this table';

  @override
  String get addCondition => 'Add condition';

  @override
  String upToConditions(Object v0) {
    return 'Up to $v0 conditions';
  }

  @override
  String get applyFilters => 'Apply filters';

  @override
  String get removeCondition => 'Remove condition';

  @override
  String get value => 'Value';

  @override
  String get clearDate => 'Clear date';

  @override
  String eGBuildvalueeditor(Object v0) {
    return 'e.g. 3.5 ($v0)';
  }

  @override
  String get chooseDateAndTime => 'Choose date and time';

  @override
  String get holdingsPng => 'Holdings_0921.png';

  @override
  String get fromTheHoldingsScreenshotAddedSharesOf =>
      'From the holdings screenshot: added 200 shares of Kweichow Moutai and bought 300 shares of Tencent.';

  @override
  String get kweichowMoutaiShares => 'Kweichow Moutai shares';

  @override
  String get shares => '500 shares';

  @override
  String get kweichowMoutaiPrice => 'Kweichow Moutai price';

  @override
  String get tencentAdded => 'Tencent added';

  @override
  String get tencentShares => 'Tencent shares';

  @override
  String get sharesBuildplan => '300 shares';

  @override
  String get tencentCostBasis => 'Tencent cost basis';

  @override
  String get tencent => 'Tencent';

  @override
  String get costBasis => 'Cost basis';

  @override
  String get receiptJpg => 'Receipt_0923.jpg';

  @override
  String get extractedAnArchiveReceiptFromThePhoto =>
      'Extracted an archive receipt from the photo. The volume count is hard to read.';

  @override
  String get analysisOfReceiptJpg => 'Analysis of “Receipt_0923.jpg”';

  @override
  String get archiveId => 'Archive ID';

  @override
  String get titleBuildplan => 'Title';

  @override
  String get planningRecordsTransferredByTheHousingBureau =>
      'Planning records transferred by the housing bureau';

  @override
  String get volumesBuildplan => 'Volumes';

  @override
  String get transferringAgency => 'Transferring agency';

  @override
  String get municipalHousingBureau => 'Municipal housing bureau';

  @override
  String get yearBuildplan => 'Year';

  @override
  String get receivedDate => 'Received date';

  @override
  String get classification => 'Classification';

  @override
  String get internal => 'Internal';

  @override
  String get digitized => 'Digitized';

  @override
  String get recordFromScreenshot => 'Record from screenshot';

  @override
  String get screenshotPng => 'Screenshot_0923.png';

  @override
  String get foundARecordInTheScreenshotConfirm =>
      'Found a record in the screenshot. Confirm to save it.';

  @override
  String get analysisOfScreenshotPng => 'Analysis of “Screenshot_0923.png”';

  @override
  String importScreenshotBuild(Object v0) {
    return 'Import screenshot $v0';
  }

  @override
  String get cancelImageAnalysis => 'Cancel image analysis';

  @override
  String get startAnalysis => 'Start analysis';

  @override
  String get chooseAgain => 'Choose again';

  @override
  String get extractionComplete => 'Extraction complete';

  @override
  String get uploadingImage => 'Uploading image…';

  @override
  String get readingImage => 'Reading image…';

  @override
  String get takingLongerThanExpected => 'Taking longer than expected…';

  @override
  String get monthlyCredits => 'Monthly credits';

  @override
  String credits(Object v0) {
    return '$v0 credits';
  }

  @override
  String get modelAccess => 'Model access';

  @override
  String get context => 'Context';

  @override
  String get yourOwnApiKey => 'Your own API key';

  @override
  String get shortContext => 'Short context';

  @override
  String get yearlyBuild => 'Yearly';

  @override
  String get monthlyBuild2 => 'Monthly';

  @override
  String get toworkMembership => 'ToWork membership';

  @override
  String get closeMembership => 'Close membership';

  @override
  String get currentPlan => 'Current plan';

  @override
  String switchTo(Object v0) {
    return 'Switch to $v0';
  }

  @override
  String selectLabelBuild2(Object v0) {
    return 'Select $v0';
  }

  @override
  String get dismissSuccessAnimation => 'Dismiss success animation';

  @override
  String membership(Object v0) {
    return '$v0 membership';
  }

  @override
  String get planChanged => 'Plan changed';

  @override
  String creditsPerMonth(Object v0) {
    return '$v0 credits per month';
  }

  @override
  String membershipBadge(Object v0) {
    return '$v0 membership badge';
  }

  @override
  String get memoryIsPausedResumeItInSettings =>
      'Memory is paused. Resume it in Settings first.';

  @override
  String get invalidContentOrType => 'Invalid content or type';

  @override
  String get couldntSaveTryAgain => 'Couldn’t save. Try again.';

  @override
  String get resumeMemoryToAddAnItem => 'Resume memory to add an item';

  @override
  String get remembered => 'Remembered';

  @override
  String get updatedOpeneditor => 'Updated';

  @override
  String get rememberAgain => 'Remember again';

  @override
  String get originalChatNoLongerExists => 'Original chat no longer exists';

  @override
  String get memoryRestored => 'Memory restored';

  @override
  String get memoryCleared => 'Memory cleared';

  @override
  String get memoryLibrary => 'Memory library';

  @override
  String get onLabel => 'On';

  @override
  String memoryOffModeIs(Object v0) {
    return 'Memory off mode is $v0';
  }

  @override
  String get moreActions => 'More actions';

  @override
  String get couldntLoadMemories => 'Couldn’t load memories';

  @override
  String get searchMemories => 'Search memories';

  @override
  String get newMemory => 'New memory';

  @override
  String get memoryIsOffNewChatsWontAdd =>
      'Memory is off. New chats won’t add memories.';

  @override
  String get resumeMemory => 'Resume memory';

  @override
  String get noMemoriesYet => 'No memories yet';

  @override
  String get noMatchingMemories => 'No matching memories';

  @override
  String hrAgo(Object v0) {
    return '$v0 hr ago';
  }

  @override
  String daysAgo(Object v0) {
    return '$v0 days ago';
  }

  @override
  String memoryConfidence(Object v0, Object v1, Object v2) {
    return '$v0 memory, $v1, confidence $v2';
  }

  @override
  String get expiredBuild => ', expired';

  @override
  String doubleTapToExpandHoldForActions(Object v0) {
    return '$v0. Double-tap to expand. Hold for actions.';
  }

  @override
  String get extractedByAi => 'Extracted by AI';

  @override
  String get manual => 'Manual';

  @override
  String get pendingReview => 'Pending review';

  @override
  String confidence(Object v0) {
    return 'Confidence $v0';
  }

  @override
  String expiresInDays(int v0) {
    String _temp0 = intl.Intl.pluralLogic(
      v0,
      locale: localeName,
      other: 'Expires in $v0 days',
      one: 'Expires in 1 day',
    );
    return '$_temp0';
  }

  @override
  String openSourceChat(Object v0) {
    return 'Open source chat $v0';
  }

  @override
  String fromChatShowmemorydetailsheet(Object v0) {
    return 'From chat “$v0”';
  }

  @override
  String formattedValueDate(Object v0, Object v1, Object v2) {
    return '$v1/$v2/$v0';
  }

  @override
  String get memoryDetails => 'Memory details';

  @override
  String get addedManually => 'Added manually';

  @override
  String get confidenceShowmemorydetailsheet => 'Confidence';

  @override
  String get retention => 'Retention';

  @override
  String get noExpiration => 'No expiration';

  @override
  String get expiredShowmemorydetailsheet => ' Expired';

  @override
  String get expires => 'Expires';

  @override
  String get viewOriginalChat => 'View original chat';

  @override
  String get copyShowmemorydetailsheet => 'Copy';

  @override
  String get longTerm => 'Long term';

  @override
  String expiresExpirylabel(Object v0, Object v1, Object v2) {
    return 'Expires $v0-$v1-$v2';
  }

  @override
  String get editMemory => 'Edit memory';

  @override
  String get memoryRetention => 'Memory retention';

  @override
  String get customDate => 'Custom date';

  @override
  String get chatBuild => 'Chat';

  @override
  String memoryBuild(Object v0, Object v1) {
    return 'Memory: $v0, $v1';
  }

  @override
  String get moreFilters => 'More filters';

  @override
  String get memoryRules => 'Memory rules';

  @override
  String get clearAllMemories => 'Clear all memories';

  @override
  String get theAiRemembersInformationYouMentionThat =>
      'The AI remembers information you mention that is likely to matter later.';

  @override
  String get longTermPreferences => 'Long-term preferences';

  @override
  String get leadWithTheConclusion => 'Lead with the conclusion';

  @override
  String get recurringWorkflows => 'Recurring workflows';

  @override
  String get groupWeeklyReportsByProject => 'Group weekly reports by project';

  @override
  String get responsibilities => 'Responsibilities';

  @override
  String get iHandleContractApprovals => 'I handle contract approvals';

  @override
  String get projectAgreements => 'Project agreements';

  @override
  String get useTheSignedVersionForAcceptance =>
      'Use the signed version for acceptance';

  @override
  String get terminology => 'Terminology';

  @override
  String get northMeansTheNorthChinaProjectTeam =>
      '“North” means the North China project team';

  @override
  String get corrections => 'Corrections';

  @override
  String get weeklyReportsAreNowDueOnThursdays =>
      'Weekly reports are now due on Thursdays';

  @override
  String get youCanPauseMemoryAtAnyTime => 'You can pause memory at any time.';

  @override
  String get copyContent => 'Copy content';

  @override
  String get deleteThisMemory => 'Delete this memory?';

  @override
  String get theAiWillNoLongerRememberIt =>
      'The AI will no longer remember it.';

  @override
  String get pauseMemory => 'Pause memory';

  @override
  String get newChatsWontAddMemoriesExistingMemories =>
      'New chats won’t add memories. Existing memories are retained.';

  @override
  String get clearAllMemoriesShowclearallconfirm => 'Clear all memories?';

  @override
  String deletesAllMemoriesIncludingAiExtractedAnd(Object v0) {
    return 'Deletes all $v0 memories, including AI-extracted and manually added entries. This cannot be undone.';
  }

  @override
  String get holdForOneSecondToConfirmClearing =>
      'Hold for one second to confirm clearing all memories';

  @override
  String get keepHolding => 'Keep holding…';

  @override
  String get holdForSecondToClear => 'Hold for 1 second to clear';

  @override
  String get closeQuickAsk => 'Close Quick Ask';

  @override
  String get quickAsk => 'Quick Ask';

  @override
  String get collapseQuickAsk => 'Collapse Quick Ask';

  @override
  String get expandQuickAsk => 'Expand Quick Ask';

  @override
  String get copiedAsMarkdown => 'Copied as Markdown';

  @override
  String exported(Object v0) {
    return 'Exported $v0';
  }

  @override
  String get shareReport => 'Share report';

  @override
  String get exportMarkdown => 'Export Markdown';

  @override
  String get copyFullText => 'Copy full text';

  @override
  String get regenerate => 'Regenerate?';

  @override
  String get rebuildsThisReportUsingTheLatestData =>
      'Rebuilds this report using the latest data and replaces its current content.';

  @override
  String get regenerateConfirmregenerate => 'Regenerate';

  @override
  String get deleteThisReport => 'Delete this report?';

  @override
  String get sourceDataWillBeKept => 'Source data will be kept.';

  @override
  String get reportDeleted => 'Report deleted';

  @override
  String get countingCompletedTasks => 'Counting completed tasks';

  @override
  String get summarizingCategories => 'Summarizing categories';

  @override
  String get aggregatingData => 'Aggregating data';

  @override
  String get generatingSummary => 'Generating summary';

  @override
  String get theReportWillContinueInTheBackground =>
      'The report will continue in the background. You’ll be notified when it’s ready.';

  @override
  String get stopGeneratingConfirmstop => 'Stop generating?';

  @override
  String get thePartialDraftWillBeDiscarded =>
      'The partial draft will be discarded.';

  @override
  String get keepGenerating => 'Keep generating';

  @override
  String get stop => 'Stop';

  @override
  String get markUnread => 'Mark unread';

  @override
  String get markRead => 'Mark read';

  @override
  String get markedUnread => 'Marked unread';

  @override
  String get markedRead => 'Marked read';

  @override
  String get generating => 'Generating';

  @override
  String get share => 'Share';

  @override
  String get aboutSeconds => 'About 10–30 seconds';

  @override
  String get thisReportHasBeenDeleted => 'This report has been deleted';

  @override
  String dataForWasntAvailableInTimeThis(Object v0) {
    return 'Data for $v0 wasn’t available in time. This report uses the available data.';
  }

  @override
  String user(Object v0) {
    return '- User: $v0';
  }

  @override
  String added(Object v0) {
    return '- Added: $v0';
  }

  @override
  String completedReportmarkdown(Object v0) {
    return '- Completed: $v0';
  }

  @override
  String completionRate(Object v0) {
    return '- Completion rate: $v0';
  }

  @override
  String unfinishedAtPeriodEndIncludingOverdue(Object v0, Object v1) {
    return '- Unfinished at period end: $v0, including $v1 overdue';
  }

  @override
  String tableRecordsIncludingAddedThisPeriod(Object v0, Object v1) {
    return '- Table records: $v0, including $v1 added this period';
  }

  @override
  String completedLastPeriod(Object v0) {
    return '- Completed last period: $v0';
  }

  @override
  String get categories => '## Categories';

  @override
  String get categoryAddedCompleted => '| Category | Added | Completed |';

  @override
  String get summaryReportmarkdown => '## Summary';

  @override
  String get noSummaryYet => '(No summary yet)';

  @override
  String method(Object v0) {
    return 'Method: $v0';
  }

  @override
  String snapshot(Object v0) {
    return 'Snapshot: $v0';
  }

  @override
  String monthWeek(Object v0, Object v1, Object v2) {
    return 'Month $v0, week $v1 ($v2)';
  }

  @override
  String formattedValueProductionperiodlabel(Object v0, Object v1) {
    return '$v1/$v0';
  }

  @override
  String weeklyReportMonthWeek(Object v0, Object v1) {
    return 'Weekly report: month $v0, week $v1';
  }

  @override
  String monthlyReportProductionnavtitle(Object v0, Object v1) {
    return 'Monthly report: $v1/$v0';
  }

  @override
  String get customReport => 'Custom report';

  @override
  String get awaitingSummary => 'Awaiting summary';

  @override
  String get summarized => 'Summarized';

  @override
  String get failed => 'Failed';

  @override
  String weeklyReportReportnavtitle(Object v0) {
    return '$v0 weekly report';
  }

  @override
  String monthlyReportReportnavtitle(Object v0) {
    return '$v0 monthly report';
  }

  @override
  String get vsLastWeek => 'vs. last week';

  @override
  String get vsLastMonth => 'vs. last month';

  @override
  String get vsLastPeriod => 'vs. last period';

  @override
  String get hourQuotaExhaustedResetsAtTheEnd =>
      '5-hour quota exhausted. Resets at the end of the window.';

  @override
  String get quotaExhaustedForThisPeriodResetsNext =>
      'Quota exhausted for this period. Resets next period.';

  @override
  String get reportGenerationFailed => 'Report generation failed';

  @override
  String get generateReport => 'Generate report';

  @override
  String get searchReports => 'Search reports';

  @override
  String get noReportsYet => 'No reports yet';

  @override
  String get noReports => 'No reports';

  @override
  String get noMatchingReports => 'No matching reports';

  @override
  String get generatingBuild => 'Generating…';

  @override
  String completedBuild2(Object v0) {
    return ' Completed $v0';
  }

  @override
  String get unread => '. Unread';

  @override
  String couldntGenerate(Object v0) {
    return 'Couldn’t generate $v0';
  }

  @override
  String get lastWeek => 'Last week';

  @override
  String get thisMonth => 'This month';

  @override
  String get lastMonth => 'Last month';

  @override
  String weekSubmit(Object v0) {
    return 'Week $v0';
  }

  @override
  String get period => 'Period';

  @override
  String formattedValueBuild4(Object v0, Object v1) {
    return '$v0/$v1';
  }

  @override
  String get includedCategories => 'Included categories';

  @override
  String get clearAll => 'Clear all';

  @override
  String get selectAll => 'Select all';

  @override
  String get saveAsDefaultForScheduledReports =>
      'Save as default for scheduled reports';

  @override
  String get weeklyOnMondayAtMonthlyOnThe =>
      'Weekly on Monday at 08:00. Monthly on the 1st at 08:00.';

  @override
  String get adjustInScheduledReports => 'Adjust in Scheduled reports';

  @override
  String get adjustScheduledReports => 'Adjust scheduled reports';

  @override
  String get adjust => 'Adjust ›';

  @override
  String chooseDateBuild3(Object v0) {
    return 'Choose date: $v0';
  }

  @override
  String posterSaved(Object v0) {
    return 'Poster saved: $v0';
  }

  @override
  String get posterExportFailedTryAgain => 'Poster export failed. Try again.';

  @override
  String get markdownCopied => 'Markdown copied';

  @override
  String get summaryFailedYouCanRetry => 'Summary failed. You can retry.';

  @override
  String get couldntReadReport => 'Couldn’t read report';

  @override
  String get localSnapshotRetained => 'Local snapshot retained.';

  @override
  String get reportNotFound => 'Report not found';

  @override
  String get tasksCreatedDuringThePeriod => 'Tasks created during the period';

  @override
  String get unfinishedAtPeriodEnd => 'Unfinished at period end';

  @override
  String get byCategory => 'By category';

  @override
  String get dataRows => 'Data rows';

  @override
  String get poster => 'Poster';

  @override
  String get exportPosterPng => 'Export poster PNG';

  @override
  String get copyMarkdown => 'Copy Markdown';

  @override
  String completionRateCompletioncard(Object v0) {
    return 'Completion rate $v0';
  }

  @override
  String get noCategoryRecordsThisPeriod => 'No category records this period';

  @override
  String createdCompleted(Object v0, Object v1) {
    return 'Created $v0, completed $v1';
  }

  @override
  String get noPreviousCompletionRate => 'No previous completion rate';

  @override
  String previousPeriod(Object v0) {
    return '$v0 (previous period: ';
  }

  @override
  String get noPreviousRecords => 'No previous records';

  @override
  String get itemsComparelist => 'items';

  @override
  String itemsComparelist2(Object v0) {
    return '$v0 items)';
  }

  @override
  String get completionRateBuildpie => 'Completion rate';

  @override
  String totalRows(Object v0) {
    return 'Total rows: $v0';
  }

  @override
  String rowsAddedThisPeriod(Object v0) {
    return 'Rows added this period: $v0';
  }

  @override
  String get aiSummary => 'AI summary';

  @override
  String get summaryFailedSnapshotRetained =>
      'Summary failed. Snapshot retained.';

  @override
  String get kimiWritesTheSummaryUsingTheFigures =>
      'Kimi writes the summary using the figures captured in this report.';

  @override
  String get retrySummary => 'Retry summary';

  @override
  String get reportServiceUnavailable => 'Report service unavailable';

  @override
  String get generatingReport => 'Generating report';

  @override
  String get generate => 'Generate';

  @override
  String get generateThisWeeksReport => 'Generate this week’s report';

  @override
  String get generateThisMonthsReport => 'Generate this month’s report';

  @override
  String periodUsesTheTimeZone(Object v0) {
    return 'Period uses the $v0 time zone';
  }

  @override
  String completionRateBuild(Object v0) {
    return 'Completion rate $v0.';
  }

  @override
  String get aiObservationsAndSuggestions => 'AI observations and suggestions';

  @override
  String get upcomingTasksBullets => 'Upcoming tasks';

  @override
  String get nextMonthsFocus => 'Next month’s focus';

  @override
  String get aiGeneratedContent => 'AI-generated content';

  @override
  String get aiInsights => 'AI insights';

  @override
  String weeklyReportPeriodlabel(Object v0, Object v1) {
    return 'Weekly report $v0/$v1–';
  }

  @override
  String sToworkReport(Object v0) {
    return '$v0’s ToWork report';
  }

  @override
  String methodThisPeriod(Object v0, Object v1, Object v2) {
    return 'Method: $v0 (this period $v1/$v2)';
  }

  @override
  String get completedByCategory => 'Completed by category';

  @override
  String completedAdded(Object v0, Object v1) {
    return '$v0 completed, $v1 added';
  }

  @override
  String get summaryBuild => 'Summary';

  @override
  String get noSummaryYetOpenTheReportTo =>
      'No summary yet. Open the report to generate one.';

  @override
  String get noPreviousComparison => 'No previous comparison';

  @override
  String addedDonecard(Object v0) {
    return 'Added $v0';
  }

  @override
  String get needsAttention => 'Needs attention';

  @override
  String get noneOverdue => 'None overdue';

  @override
  String get newData => 'New data';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get systemDefault => 'System default';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get textSize => 'Text size';

  @override
  String get small => 'Small';

  @override
  String get standard => 'Standard';

  @override
  String get large => 'Large';

  @override
  String get newMoon => 'New moon';

  @override
  String get aGoodTimeToStartAList => 'a good time to start a list';

  @override
  String get waxingCrescent => 'Waxing crescent';

  @override
  String get aGoodTimeToBegin => 'a good time to begin';

  @override
  String get firstQuarter => 'First quarter';

  @override
  String get aGoodTimeToWrapUp => 'a good time to wrap up';

  @override
  String get waxingGibbous => 'Waxing gibbous';

  @override
  String get aGoodTimeForAFinalPush => 'a good time for a final push';

  @override
  String get fullMoon => 'Full moon';

  @override
  String get aGoodTimeToCelebrate => 'a good time to celebrate';

  @override
  String get waningGibbous => 'Waning gibbous';

  @override
  String get aGoodTimeToReflect => 'a good time to reflect';

  @override
  String get lastQuarter => 'Last quarter';

  @override
  String get aGoodTimeToDeclutter => 'a good time to declutter';

  @override
  String get waningCrescent => 'Waning crescent';

  @override
  String get aGoodTimeForAnEarlyNight => 'a good time for an early night';

  @override
  String tonight(Object v0, Object v1, Object v2) {
    return '$v0 Tonight: $v1, $v2';
  }

  @override
  String get instructionsAdded => 'Instructions added';

  @override
  String vocabularyWords(Object v0) {
    return 'Vocabulary: $v0 words';
  }

  @override
  String get notSetAssistantpreferencessummary => 'Not set';

  @override
  String get savedAppliesFromTheNextChat =>
      'Saved. Applies from the next chat.';

  @override
  String eachTermCanHaveUpToCharacters(Object v0) {
    return 'Each term can have up to $v0 characters';
  }

  @override
  String isAlreadyInTheList(Object v0) {
    return '“$v0” is already in the list';
  }

  @override
  String limitTermsRemoveAnUnusedTermFirst(Object v0) {
    return 'Limit: $v0 terms. Remove an unused term first.';
  }

  @override
  String get assistantPreferences => 'Assistant preferences';

  @override
  String get saveInstructions => 'Save instructions';

  @override
  String get customInstructions => 'Custom instructions';

  @override
  String get eGReplyInEnglish => 'e.g. Reply in English';

  @override
  String get vocabulary => 'Vocabulary';

  @override
  String get personProjectOrProductName => 'Person, project or product name';

  @override
  String speechVocabulary(Object v0, Object v1) {
    return 'Speech vocabulary $v0/$v1';
  }

  @override
  String get whatTheModelReceives => 'What the model receives';

  @override
  String get eachRequestIncludesTheTimeYourName =>
      'Each request includes the time, your name, custom instructions and vocabulary. Agent mode also includes categories and the titles and due dates of up to 12 active tasks.';

  @override
  String deleteTerm(Object v0) {
    return 'Delete term $v0';
  }

  @override
  String get nameSavedOnThisDevice => 'Name saved on this device';

  @override
  String get useCharactersWithoutLineBreaksOrControl =>
      'Use 1–40 characters without line breaks or control characters';

  @override
  String get profileChangedReloadBeforeSaving =>
      'Profile changed. Reload before saving.';

  @override
  String get couldntReadOrSaveYourLocalProfile =>
      'Couldn’t read or save your local profile. Try again.';

  @override
  String get profileBuild => 'Profile';

  @override
  String get saveName => 'Save name';

  @override
  String get nameBuild => 'Name';

  @override
  String get enterAName => 'Enter a name';

  @override
  String get reloadBuild => 'Reload';

  @override
  String get couldntReadLocalSettingsTryAgain =>
      'Couldn’t read local settings. Try again.';

  @override
  String get quotaUpdated => 'Quota updated';

  @override
  String get thisProviderDoesntOfferAQuotaApi =>
      'This provider doesn’t offer a quota API';

  @override
  String couldntCheckQuota(Object v0) {
    return 'Couldn’t check quota: $v0';
  }

  @override
  String get deleteThisAccount => 'Delete this account?';

  @override
  String theSettingsForAndTheKeySaved(Object v0) {
    return 'The settings for $v0 and the key saved on this device will be deleted ';
  }

  @override
  String get permanentlyChatHistoryIsRetained =>
      'permanently. Chat history is retained.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get accountDeleted => 'Account deleted';

  @override
  String get manualOnly => '  Manual only';

  @override
  String priorityOpenmenu(Object v0, Object v1) {
    return 'Priority $v0$v1';
  }

  @override
  String get useThisAccount => 'Use this account';

  @override
  String switchedToOpenmenu(Object v0) {
    return 'Switched to $v0';
  }

  @override
  String get editModelAndKey => 'Edit model and key';

  @override
  String get refreshQuota => 'Refresh quota';

  @override
  String get resumeAccount => 'Resume account';

  @override
  String get rejoinAutomaticFallback => 'Rejoin automatic fallback';

  @override
  String get accountResumed => 'Account resumed';

  @override
  String get excludeFromFallback => 'Exclude from fallback';

  @override
  String get includeInFallback => 'Include in fallback';

  @override
  String get increasePriority => 'Increase priority';

  @override
  String get decreasePriority => 'Decrease priority';

  @override
  String get modelsAndUsageBuild => 'Models and usage';

  @override
  String get switchAccountsByPriorityWhenQuotaRuns =>
      'Switch accounts by priority when quota runs out, requests are limited or a key expires.';

  @override
  String get switchAutomaticallyWhenQuotaRunsOut =>
      'Switch automatically when quota runs out';

  @override
  String get couldntReadLocalSettings => 'Couldn’t read local settings';

  @override
  String get noModelAccountsYet => 'No model accounts yet';

  @override
  String get checkProviderConsole => 'Check provider console';

  @override
  String get inUseBuild => ', in use';

  @override
  String priorityBuild(Object v0, Object v1, Object v2) {
    return '$v0, priority $v1, $v2';
  }

  @override
  String get inUseBuild2 => 'In use';

  @override
  String get connectedUnsaved => 'Connected (unsaved)';

  @override
  String get connected => 'Connected';

  @override
  String get serviceRegion => 'Service region';

  @override
  String get china => 'China';

  @override
  String get international => 'International';

  @override
  String get chooseProvider => 'Choose provider';

  @override
  String get editModelAccount => 'Edit model account';

  @override
  String get apiEndpoint => 'API endpoint';

  @override
  String get savedLeaveBlankToKeep => 'Saved. Leave blank to keep.';

  @override
  String get enterKey => 'Enter key';

  @override
  String get cancelTest => 'Cancel test';

  @override
  String get testConnection => 'Test connection';

  @override
  String get defaultAssistantEnabled => 'Default assistant enabled';

  @override
  String get notTheDefaultAssistant => 'Not the default assistant';

  @override
  String get quickLaunch => 'Quick launch';

  @override
  String get tryNow => 'Try now';

  @override
  String get quickAskIsUnavailableOnThisDevice =>
      'Quick Ask is unavailable on this device';

  @override
  String get defaultAssistant => 'Default assistant';

  @override
  String get openQuickAskWithTheAssistantGesture =>
      'Open Quick Ask with the assistant gesture. The system controls power-button shortcuts.';

  @override
  String get setAsDefaultAssistant => 'Set as default assistant';

  @override
  String get openSystemSettingsAppsDefaultAppsAnd =>
      'Open System settings → Apps → Default apps and select ToWork';

  @override
  String get otherShortcuts => 'Other shortcuts';

  @override
  String get addQuickAskToHomeScreen => 'Add Quick Ask to home screen';

  @override
  String get theLauncherDidntAddTheShortcutHold =>
      'The launcher didn’t add the shortcut. Hold the ToWork icon and drag Quick Ask to the home screen.';

  @override
  String get addVoiceQuickAskToHomeScreen =>
      'Add Voice Quick Ask to home screen';

  @override
  String get theLauncherDidntAddTheShortcutHoldTheTowork =>
      'The launcher didn’t add the shortcut. Hold the ToWork icon and drag Voice Quick Ask to the home screen.';

  @override
  String get systemShortcuts => 'System shortcuts';

  @override
  String get selectToworkQuickAskOrToworkVoice =>
      'Select ToWork Quick Ask or ToWork Voice Quick Ask in the system menu.';

  @override
  String get huaweiSmartControlDoubleTap => 'Huawei Smart Control double-tap';

  @override
  String get confirmTheSystemPromptThenChooseQuick =>
      'Confirm the system prompt, then choose Quick Ask or Voice Quick Ask under Smart Control → Double-tap.';

  @override
  String get controlCenter => 'Control Center';

  @override
  String get editTheQuickSettingsTilesAndAdd =>
      'Edit the quick settings tiles and add Quick Ask.';

  @override
  String get selectTextOrShare => 'Select text or share';

  @override
  String get chooseAskTowork => 'Choose Ask ToWork.';

  @override
  String get holdTheAppIcon => 'Hold the app icon';

  @override
  String get selectQuickAskOrVoiceQuickAsk =>
      'Select Quick Ask or Voice Quick Ask.';

  @override
  String get morningDigestTime => 'Morning digest time';

  @override
  String morningDigestSetTo(Object v0, Object v1) {
    return 'Morning digest set to $v0:$v1';
  }

  @override
  String get memoryPaused => 'Memory paused';

  @override
  String get addKey => 'Add key';

  @override
  String get accountBuild => 'Account';

  @override
  String get accountDetails => 'Account details';

  @override
  String get privacyAndPermissions => 'Privacy and permissions';

  @override
  String get aiWritePermissions => 'AI write permissions';

  @override
  String get pauseMemoryBuild => 'Pause memory';

  @override
  String get inputAndQuickLaunch => 'Input and quick launch';

  @override
  String get speechDiagnostics => 'Speech diagnostics';

  @override
  String get defaultInputMethod => 'Default input method';

  @override
  String get voice => 'Voice';

  @override
  String get keyboard => 'Keyboard';

  @override
  String get couldntSaveTryAgainBuild => 'Couldn’t save. Try again.';

  @override
  String get notifications => 'Notifications';

  @override
  String get dueReminders => 'Due reminders';

  @override
  String get morningDigest => 'Morning digest';

  @override
  String get off => 'Off';

  @override
  String get morningDigestSwitch => 'Morning digest switch';

  @override
  String get reportReadyNotifications => 'Report ready notifications';

  @override
  String get notificationSettings => 'Notification settings';

  @override
  String get dataBackup => 'Data backup';

  @override
  String get exportData => 'Export data';

  @override
  String get lastExport => 'Last export';

  @override
  String get about => 'About';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get version => 'Version';

  @override
  String get openSourceLicenses => 'Open-source licenses';

  @override
  String get noMatchingSettings => 'No matching settings';

  @override
  String get searchSettings => 'Search settings';

  @override
  String get neverExported => 'Never exported';

  @override
  String get revokeAiDataConsent => 'Revoke AI data consent';

  @override
  String get consentRevoked => 'Consent revoked';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get couldntOpen => 'Couldn’t open';

  @override
  String get thisApiDoesntListModelsEnterA =>
      'This API doesn’t list models. Enter a model ID manually.';

  @override
  String get fetchingModels => 'Fetching models';

  @override
  String get noAvailableModels => 'No available models';

  @override
  String get noMatchingModels => 'No matching models';

  @override
  String get searchModels => 'Search models';

  @override
  String get refreshModelList => 'Refresh model list';

  @override
  String get availableModels => 'Available models';

  @override
  String get customModel => 'Custom model';

  @override
  String get model => 'Model';

  @override
  String get modelId => 'Model ID';

  @override
  String get enterModelId => 'Enter model ID';

  @override
  String get fetchModelList => 'Fetch model list';

  @override
  String get selectAFetchedModel => 'Select a fetched model';

  @override
  String get provider => 'Provider';

  @override
  String get current => ', current';

  @override
  String get locked => ', locked';

  @override
  String aiWritePermissionsSetTo(Object v0) {
    return 'AI write permissions set to “$v0”';
  }

  @override
  String get savingPermissions => 'Saving permissions…';

  @override
  String get tableEditsCanBeRevertedInRow =>
      'Table edits can be reverted in row history.';

  @override
  String get checkingSystemStatus => 'Checking system status…';

  @override
  String get couldntCheckSpeechStatusTryAgain =>
      'Couldn’t check speech status. Try again.';

  @override
  String get available => 'Available';

  @override
  String get unavailableBuild2 => 'Unavailable';

  @override
  String recognitionService(Object v0) {
    return 'Recognition service: $v0';
  }

  @override
  String get granted => 'Granted';

  @override
  String get partiallyGranted => 'Partially granted';

  @override
  String microphoneAndSpeechPermissions(Object v0) {
    return 'Microphone and speech permissions: $v0';
  }

  @override
  String get supportedWithInstalledLanguageResources =>
      'Supported with installed language resources';

  @override
  String get supportNotReported => 'Support not reported';

  @override
  String onDeviceRecognition(Object v0) {
    return 'On-device recognition: $v0';
  }

  @override
  String get mandarinLanguageListUnavailable =>
      'English: language list unavailable';

  @override
  String systemLanguages(Object v0) {
    return 'System languages: $v0';
  }

  @override
  String get checksMandarinRecognitionAndPermissionsWithoutRecording =>
      'Checks English recognition and permissions without recording.';

  @override
  String get checkAgain => 'Check again';

  @override
  String get theTaskForThisReminderNoLonger =>
      'The task for this reminder no longer exists';

  @override
  String get todayAt => 'Today at 18:00';

  @override
  String get tomorrowAt => 'Tomorrow at 09:00';

  @override
  String get nextMondayAt => 'Next Monday at 09:00';

  @override
  String get reschedule => 'Reschedule';

  @override
  String rescheduledTo(Object v0) {
    return 'Rescheduled to $v0';
  }

  @override
  String get dueDateCleared => 'Due date cleared';

  @override
  String completedTasks(Object v0) {
    return 'Completed $v0 tasks';
  }

  @override
  String get changeCategory => 'Change category';

  @override
  String movedTo(Object v0) {
    return 'Moved to $v0';
  }

  @override
  String get changeDueDate => 'Change due date';

  @override
  String rescheduled(Object v0) {
    return 'Rescheduled $v0';
  }

  @override
  String deleteTasks(Object v0) {
    return 'Delete $v0 tasks?';
  }

  @override
  String get onlySelectedRecurringOccurrencesAreDeletedUndo =>
      'Only selected recurring occurrences are deleted. Undo within 10 seconds.';

  @override
  String deletedTasks(Object v0) {
    return 'Deleted $v0 tasks';
  }

  @override
  String categoryBuild(Object v0) {
    return 'Category: $v0';
  }

  @override
  String get noTasksMatchTheseFilters => 'No tasks match these filters';

  @override
  String get expandCompletedTasks => 'Expand completed tasks';

  @override
  String get switchToBoard => 'Switch to board';

  @override
  String get switchToList => 'Switch to list';

  @override
  String get backToChatHome => 'Back to chat home';

  @override
  String get list => 'List';

  @override
  String get board => 'Board';

  @override
  String get searchTasks => 'Search tasks';

  @override
  String selectedBuildselectionbar(Object v0) {
    return 'Selected: $v0';
  }

  @override
  String get deselectAll => 'Deselect all';

  @override
  String itemsBuildgroupheader(Object v0, Object v1) {
    return '$v0, $v1 items';
  }

  @override
  String newTaskIn(Object v0) {
    return 'New task in $v0';
  }

  @override
  String get noItems => 'No items';

  @override
  String get noMatchingTasks => 'No matching tasks';

  @override
  String get goToChatBuildempty => 'Go to chat';

  @override
  String get thisListIsEmpty => 'This list is empty';

  @override
  String get noTasksToday => 'No tasks today';

  @override
  String get nothingScheduledThisWeek => 'Nothing scheduled this week';

  @override
  String get noOverdueTasks => 'No overdue tasks';

  @override
  String get noTasksWithoutADueDate => 'No tasks without a due date';

  @override
  String get noCompletedTasksYet => 'No completed tasks yet';

  @override
  String get listSettings => 'List settings';

  @override
  String get groupBy => 'Group by';

  @override
  String get byCategoryShowmoresheet => 'By category';

  @override
  String get byDueDate => 'By due date';

  @override
  String get byPriority => 'By priority';

  @override
  String get showCompleted => 'Show completed';

  @override
  String get manageCategories => 'Manage categories';

  @override
  String selectedAction(Object v0, Object v1) {
    return '$v0, $v1 selected';
  }

  @override
  String get someOccurrencesExceedAvailableTimeZoneData =>
      'Some occurrences exceed available time zone data. Adjust the end date. Existing tasks are available.';

  @override
  String get someRecurringTasksAreStillPendingExisting =>
      'Some recurring tasks are still pending. Existing records are saved.';

  @override
  String recurringTasksGeneratedThrough(
    Object v0,
    Object v1,
    Object v2,
    Object v3,
    Object v4,
  ) {
    return 'Recurring tasks generated through $v0/$v1/$v2 $v3:$v4';
  }

  @override
  String get recurringTasksWillContinueAfterThisAction =>
      'Recurring tasks will continue after this action';

  @override
  String get recurringTasksWillContinueWhenYouReopen =>
      'Recurring tasks will continue when you reopen the app';

  @override
  String get generatingRecurringTasksInBatches =>
      'Generating recurring tasks in batches';

  @override
  String get selectedSegment => ', selected';

  @override
  String filterByItems(Object v0, Object v1, Object v2) {
    return 'Filter by $v0, $v1 items$v2';
  }

  @override
  String get currentVersion => 'Current version';

  @override
  String get versionHistory => 'Version history';

  @override
  String get expand => 'Expand';

  @override
  String get checkingForUpdates => 'Checking for updates';

  @override
  String get upToDate => 'Up to date';

  @override
  String get updateAvailable => 'Update available';

  @override
  String get downloadingUpdate => 'Downloading update';

  @override
  String get verifyingPatch => 'Verifying patch';

  @override
  String get verifyingInstaller => 'Verifying installer';

  @override
  String get buildingInstaller => 'Building installer';

  @override
  String get patchReady => 'Patch ready';

  @override
  String get installerReady => 'Installer ready';

  @override
  String get permissionToInstallAppsRequired =>
      'Permission to install apps required';

  @override
  String get confirmInstallationInTheSystemDialog =>
      'Confirm installation in the system dialog';

  @override
  String get restartingToApplyUpdate => 'Restarting to apply update';

  @override
  String get updateCheckFailed => 'Update check failed';

  @override
  String get inAppInstallationUnavailableOnThisPlatform =>
      'In-app installation unavailable on this platform';

  @override
  String get checkAgainBuild => 'Check again';

  @override
  String get deltaUpdate => 'Delta update';

  @override
  String get fullInstaller => 'Full installer';

  @override
  String get whatsNew => 'What’s new';

  @override
  String get deltaUpdateIncompleteSwitchedToTheFull =>
      'Delta update incomplete. Switched to the full installer.';

  @override
  String get allowThisSourceThenReturnToInstall =>
      'Allow this source, then return to install.';

  @override
  String get restoreAndRestart => 'Restore and restart';

  @override
  String get updateAndRestart => 'Update and restart';

  @override
  String get downloadUpdate => 'Download update';

  @override
  String get cancelUpdate => 'Cancel update';

  @override
  String get pauseDownload => 'Pause download';

  @override
  String get restartNow => 'Restart now';

  @override
  String get installAndReopen => 'Install and reopen';

  @override
  String get reopenInstaller => 'Reopen installer';

  @override
  String get filterCategories => 'Filter categories';

  @override
  String get askAi => 'Ask AI';

  @override
  String get scheduleOverview => 'Schedule overview';

  @override
  String get switchScheduleView => 'Switch schedule view';

  @override
  String get createTaskOnSelectedDate => 'Create task on selected date';

  @override
  String get searchSchedule => 'Search schedule';

  @override
  String get heatmap => 'Heatmap';

  @override
  String get calendar => 'Calendar';

  @override
  String get distribution => 'Distribution';

  @override
  String get trends => 'Trends';

  @override
  String get tasksCompleted => 'Tasks completed';

  @override
  String get itemsVizStats => 'items';

  @override
  String get tasksAdded => 'Tasks added';

  @override
  String get recordsAdded => 'Records added';

  @override
  String get rowsVizStats => 'rows';

  @override
  String formattedValueOpenday(Object v0, Object v1, Object v2) {
    return '$v2, $v0/$v1';
  }

  @override
  String alreadyHighPriorityItemsThatDay(Object v0) {
    return '. Already $v0 high-priority items that day';
  }

  @override
  String movedToReschedule(Object v0, Object v1, Object v2) {
    return 'Moved to $v0/$v1$v2';
  }

  @override
  String get previousMonthBuild => 'Previous month';

  @override
  String get nextMonthBuild => 'Next month';

  @override
  String get noTasksThisMonth => 'No tasks this month';

  @override
  String get todayBuild => 'Today, ';

  @override
  String get overdueItems => ', overdue items';

  @override
  String tasksBuild2(Object v0, Object v1, Object v2, Object v3, Object v4) {
    return '$v0/$v1, $v2$v3 tasks$v4';
  }

  @override
  String get pieChart => 'Pie chart';

  @override
  String get barChart => 'Bar chart';

  @override
  String get switchChart => 'Switch chart';

  @override
  String get addCategoriesToYourTasksToSee =>
      'Add categories to your tasks to see their distribution.';

  @override
  String get organizeCategories => 'Organize categories';

  @override
  String completeBuildpie(Object v0, Object v1) {
    return '$v0: $v1% complete';
  }

  @override
  String itemsComplete(Object v0, Object v1, Object v2) {
    return '$v0, $v1 items, $v2% complete';
  }

  @override
  String itemsCompleteBuildpie(Object v0, Object v1) {
    return '$v0 items, $v1% complete';
  }

  @override
  String get metric => 'Metric';

  @override
  String scale(Object v0) {
    return 'Scale: $v0';
  }

  @override
  String get activity => 'Activity';

  @override
  String daysRecorded(Object v0) {
    return '$v0 days recorded';
  }

  @override
  String changeMetricCurrently(Object v0) {
    return 'Change metric, currently $v0';
  }

  @override
  String activityHeatmapForPastYear(Object v0, Object v1, Object v2) {
    return 'Activity heatmap for $v0. Past year: $v1 $v2.';
  }

  @override
  String get less => 'Less';

  @override
  String get moreBuild => 'More';

  @override
  String yearBuild(Object v0, Object v1) {
    return 'Year: $v0 $v1';
  }

  @override
  String monthPaint(Object v0) {
    return 'Month $v0';
  }

  @override
  String get tablesTablename => 'Tables';

  @override
  String rowsAdded(Object v0, Object v1) {
    return '$v0: $v1 rows added';
  }

  @override
  String get noActivityThisDay => 'No activity this day.';

  @override
  String formattedValueBuild5(Object v0, Object v1, Object v2) {
    return '$v2, $v0/$v1';
  }

  @override
  String get noMatchingTasksBuild => 'No matching tasks';

  @override
  String get noTasksOnThisDay => 'No tasks on this day';

  @override
  String get createdVsCompleted => 'Created vs. completed';

  @override
  String weeks(Object v0) {
    return '$v0 weeks';
  }

  @override
  String get changePeriod => 'Change period';

  @override
  String get trendsAppearAfterTwoWeeksOfActivity =>
      'Trends appear after two weeks of activity.';

  @override
  String thisWeekCreatedCompleted(Object v0, Object v1) {
    return 'This week: $v0 created, $v1 completed';
  }

  @override
  String lastWeeksCreatedCompleted(Object v0, Object v1, Object v2) {
    return 'Last $v0 weeks: $v1 created, $v2 completed';
  }

  @override
  String completeComparedWithLastPeriod(Object v0) {
    return '$v0% complete, compared with last period: ';
  }

  @override
  String get noChange => 'No change';

  @override
  String weekCreatedCompleted(Object v0, Object v1, Object v2) {
    return 'Week $v0: $v1 created, $v2 completed';
  }

  @override
  String get noDueTime => 'No due time';

  @override
  String dueAt(Object v0, Object v1) {
    return 'Due at $v0:$v1';
  }

  @override
  String markIncompleteBuild(Object v0) {
    return 'Mark incomplete: $v0';
  }

  @override
  String completeBuild2(Object v0) {
    return 'Complete: $v0';
  }

  @override
  String get noFiltersShowingAll => 'No filters, showing all';

  @override
  String filteredByChartsUpdated(Object v0) {
    return 'Filtered by $v0. Charts updated.';
  }

  @override
  String get selectedDoubleTapToClear => 'Selected. Double-tap to clear.';

  @override
  String filterBuild(Object v0, Object v1) {
    return 'Filter: $v0, $v1';
  }

  @override
  String get closeModelAccount => 'Close model account';

  @override
  String get toworkQuickAsk => 'ToWork Quick Ask';

  @override
  String get generatingInBackground => 'Generating in background';

  @override
  String get newChatHeader => 'New chat';

  @override
  String get openInTowork => 'Open in ToWork';

  @override
  String get whatsLeftToday => 'What’s left today?';

  @override
  String get whatElseDoINeedToDo => 'What else do I need to do today?';

  @override
  String get addATask => 'Add a task';

  @override
  String get helpMeAddATask => 'Help me add a task:';

  @override
  String get whatDidIDoThisWeek => 'What did I do this week?';

  @override
  String get summarizeWhatICompletedThisWeek =>
      'Summarize what I completed this week';

  @override
  String get saveAsTask => 'Save as task';

  @override
  String turnThisIntoATask(Object v0) {
    return 'Turn this into a task:\n$v0';
  }

  @override
  String get summarize => 'Summarize';

  @override
  String summarizeTheseKeyPoints(Object v0) {
    return 'Summarize these key points:\n$v0';
  }

  @override
  String get workWithThisText => 'Work with this text';

  @override
  String get couldntOpenTheWorkspaceYourDataIs =>
      'Couldn’t open the workspace. Your data is safe.';

  @override
  String get closeProfile => 'Close profile';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get thisPageMayHaveMovedOrBeen =>
      'This page may have moved or been deleted.';

  @override
  String get backToHome => 'Back to home';

  @override
  String toworkAvailable(Object v0) {
    return 'ToWork $v0 available';
  }

  @override
  String get restoreBaseVersionAvailable => 'Restore base version available';

  @override
  String patchPAvailable(Object v0) {
    return 'Patch P$v0 available';
  }

  @override
  String viewUpdate(Object v0) {
    return '$v0, view update';
  }

  @override
  String get viewUpdateBuild => 'View update';

  @override
  String get remindMeLater => 'Remind me later';

  @override
  String get expandSidebar => 'Expand sidebar';

  @override
  String get languageLabel => 'Language';

  @override
  String get english => 'English';

  @override
  String get weekdaySunday => 'Sun';

  @override
  String windowHours(int v0) {
    String _temp0 = intl.Intl.pluralLogic(
      v0,
      locale: localeName,
      other: '$v0 hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String windowDays(int v0) {
    String _temp0 = intl.Intl.pluralLogic(
      v0,
      locale: localeName,
      other: '$v0 days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String windowMinutes(int v0) {
    String _temp0 = intl.Intl.pluralLogic(
      v0,
      locale: localeName,
      other: '$v0 minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get defaultNickname => 'Local user';
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @settingsHaveChangedReopenAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Settings have changed. Reopen and try again.'**
  String get settingsHaveChangedReopenAndTryAgain;

  /// No description provided for @couldntSaveSettingsTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save settings. Try again.'**
  String get couldntSaveSettingsTryAgain;

  /// No description provided for @thisCanBeSplitIntoThreeSteps.
  ///
  /// In en, this message translates to:
  /// **'This can be split into three steps: gather the material, finish a draft, and send it for review. Switch to Agent mode to create the task.'**
  String get thisCanBeSplitIntoThreeSteps;

  /// No description provided for @theTaskOrItsCardHasChanged.
  ///
  /// In en, this message translates to:
  /// **'The task or its card has changed'**
  String get theTaskOrItsCardHasChanged;

  /// No description provided for @thisChatIsClosedItsTaskCan.
  ///
  /// In en, this message translates to:
  /// **'This chat is closed. Its task can no longer be undone.'**
  String get thisChatIsClosedItsTaskCan;

  /// No description provided for @theTaskOrItsCardNoLonger.
  ///
  /// In en, this message translates to:
  /// **'The task or its card no longer exists'**
  String get theTaskOrItsCardNoLonger;

  /// No description provided for @theCardNowLinksToADifferent.
  ///
  /// In en, this message translates to:
  /// **'The card now links to a different task'**
  String get theCardNowLinksToADifferent;

  /// No description provided for @relatedRecordsHaveChangedAndCannotBe.
  ///
  /// In en, this message translates to:
  /// **'Related records have changed and cannot be restored'**
  String get relatedRecordsHaveChangedAndCannotBe;

  /// No description provided for @currentModel.
  ///
  /// In en, this message translates to:
  /// **'Current model'**
  String get currentModel;

  /// No description provided for @switchedTo.
  ///
  /// In en, this message translates to:
  /// **'{v0}{v1}. Switched to {v2}.'**
  String switchedTo(Object v0, Object v1, Object v2);

  /// No description provided for @couldntOpenTheLocalWorkspaceYourData.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open the local workspace. Your data is safe. Try again.'**
  String get couldntOpenTheLocalWorkspaceYourData;

  /// No description provided for @reopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get reopen;

  /// No description provided for @movement.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get movement;

  /// No description provided for @mountain.
  ///
  /// In en, this message translates to:
  /// **'Mountain'**
  String get mountain;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @overture.
  ///
  /// In en, this message translates to:
  /// **'Overture'**
  String get overture;

  /// No description provided for @sonata.
  ///
  /// In en, this message translates to:
  /// **'Sonata'**
  String get sonata;

  /// No description provided for @symphony.
  ///
  /// In en, this message translates to:
  /// **'Symphony'**
  String get symphony;

  /// No description provided for @valley.
  ///
  /// In en, this message translates to:
  /// **'Valley'**
  String get valley;

  /// No description provided for @ridge.
  ///
  /// In en, this message translates to:
  /// **'Ridge'**
  String get ridge;

  /// No description provided for @summit.
  ///
  /// In en, this message translates to:
  /// **'Summit'**
  String get summit;

  /// No description provided for @zenith.
  ///
  /// In en, this message translates to:
  /// **'Zenith'**
  String get zenith;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @kFlagshipModel.
  ///
  /// In en, this message translates to:
  /// **'K3 flagship model'**
  String get kFlagshipModel;

  /// No description provided for @mContextWindow.
  ///
  /// In en, this message translates to:
  /// **'1M context window'**
  String get mContextWindow;

  /// No description provided for @highspeed.
  ///
  /// In en, this message translates to:
  /// **'HighSpeed'**
  String get highspeed;

  /// No description provided for @videoInput.
  ///
  /// In en, this message translates to:
  /// **'Video input'**
  String get videoInput;

  /// No description provided for @mQuota.
  ///
  /// In en, this message translates to:
  /// **'2× 1M quota'**
  String get mQuota;

  /// No description provided for @highSpeedQuota.
  ///
  /// In en, this message translates to:
  /// **'3× high-speed quota'**
  String get highSpeedQuota;

  /// No description provided for @vMWithVision.
  ///
  /// In en, this message translates to:
  /// **'V4.1 1M with vision'**
  String get vMWithVision;

  /// No description provided for @deepReasoning.
  ///
  /// In en, this message translates to:
  /// **'Deep reasoning'**
  String get deepReasoning;

  /// No description provided for @makeTaskRecurring.
  ///
  /// In en, this message translates to:
  /// **'Make task recurring'**
  String get makeTaskRecurring;

  /// No description provided for @startingWithThisOccurrence.
  ///
  /// In en, this message translates to:
  /// **'Starting with this occurrence'**
  String get startingWithThisOccurrence;

  /// No description provided for @editRecurringTask.
  ///
  /// In en, this message translates to:
  /// **'Edit recurring task'**
  String get editRecurringTask;

  /// No description provided for @deleteRecurringTask.
  ///
  /// In en, this message translates to:
  /// **'Delete recurring task'**
  String get deleteRecurringTask;

  /// No description provided for @thisOccurrence.
  ///
  /// In en, this message translates to:
  /// **'This occurrence'**
  String get thisOccurrence;

  /// No description provided for @thisAndFutureOccurrences.
  ///
  /// In en, this message translates to:
  /// **'This and future occurrences'**
  String get thisAndFutureOccurrences;

  /// No description provided for @changesToTheRecurrenceRuleOrTime.
  ///
  /// In en, this message translates to:
  /// **'Changes to the recurrence rule or time zone apply to this and future occurrences.'**
  String get changesToTheRecurrenceRuleOrTime;

  /// No description provided for @checkTheDueDateAndSeriesStatus.
  ///
  /// In en, this message translates to:
  /// **'Check the due date and series status. The selection may also exceed the batch limit.'**
  String get checkTheDueDateAndSeriesStatus;

  /// No description provided for @modelDownloadFailedCheckYourConnectionAnd.
  ///
  /// In en, this message translates to:
  /// **'Model download failed. Check your connection and try again.'**
  String get modelDownloadFailedCheckYourConnectionAnd;

  /// No description provided for @modelDownloadFailedTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Model download failed. Try again later.'**
  String get modelDownloadFailedTryAgainLater;

  /// No description provided for @installationCanceledYouCanRetry.
  ///
  /// In en, this message translates to:
  /// **'Installation canceled. You can retry.'**
  String get installationCanceledYouCanRetry;

  /// No description provided for @installationDidNotFinishTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Installation did not finish. Try again.'**
  String get installationDidNotFinishTryAgain;

  /// No description provided for @patchDownloadCanceledYouCanDownloadIt.
  ///
  /// In en, this message translates to:
  /// **'Patch download canceled. You can download it again.'**
  String get patchDownloadCanceledYouCanDownloadIt;

  /// No description provided for @patchVerificationFailedCheckForUpdatesAgain.
  ///
  /// In en, this message translates to:
  /// **'Patch verification failed. Check for updates again.'**
  String get patchVerificationFailedCheckForUpdatesAgain;

  /// No description provided for @finishTheCurrentConversationOrInputBefore.
  ///
  /// In en, this message translates to:
  /// **'Finish the current conversation or input before restarting.'**
  String get finishTheCurrentConversationOrInputBefore;

  /// No description provided for @patchReadyReturnHereToRestart.
  ///
  /// In en, this message translates to:
  /// **'Patch ready. Return here to restart.'**
  String get patchReadyReturnHereToRestart;

  /// No description provided for @downloadPausedResumeToContinue.
  ///
  /// In en, this message translates to:
  /// **'Download paused. Resume to continue.'**
  String get downloadPausedResumeToContinue;

  /// No description provided for @connectionInterruptedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Connection interrupted. Try again.'**
  String get connectionInterruptedTryAgain;

  /// No description provided for @updateInformationIsUnavailableTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Update information is unavailable. Try again later.'**
  String get updateInformationIsUnavailableTryAgainLater;

  /// No description provided for @thisUpdateDoesNotSupportYourDevice.
  ///
  /// In en, this message translates to:
  /// **'This update does not support your device architecture.'**
  String get thisUpdateDoesNotSupportYourDevice;

  /// No description provided for @theUpdateSignatureDoesNotMatchThe.
  ///
  /// In en, this message translates to:
  /// **'The update signature does not match the installed app.'**
  String get theUpdateSignatureDoesNotMatchThe;

  /// No description provided for @verificationFailedDownloadTheUpdateAgain.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Download the update again.'**
  String get verificationFailedDownloadTheUpdateAgain;

  /// No description provided for @storageIsFullOrUnavailableFreeUp.
  ///
  /// In en, this message translates to:
  /// **'Storage is full or unavailable. Free up space and try again.'**
  String get storageIsFullOrUnavailableFreeUp;

  /// No description provided for @theDownloadServerIsUnavailableTryAgain.
  ///
  /// In en, this message translates to:
  /// **'The download server is unavailable. Try again later.'**
  String get theDownloadServerIsUnavailableTryAgain;

  /// No description provided for @allowToworkToInstallAppsThenTap.
  ///
  /// In en, this message translates to:
  /// **'Allow ToWork to install apps, then tap Install and reopen.'**
  String get allowToworkToInstallAppsThenTap;

  /// No description provided for @thePackageOrVersionDoesNotMatch.
  ///
  /// In en, this message translates to:
  /// **'The package or version does not match. Check for updates again.'**
  String get thePackageOrVersionDoesNotMatch;

  /// No description provided for @anUpdateIsInProgressTryAgain.
  ///
  /// In en, this message translates to:
  /// **'An update is in progress. Try again later.'**
  String get anUpdateIsInProgressTryAgain;

  /// No description provided for @updateIncompleteTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Update incomplete. Try again.'**
  String get updateIncompleteTryAgain;

  /// No description provided for @noneLabel.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneLabel;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @atTheDueTime.
  ///
  /// In en, this message translates to:
  /// **'At the due time'**
  String get atTheDueTime;

  /// No description provided for @daysBefore.
  ///
  /// In en, this message translates to:
  /// **'{v0, plural, =1{1 day before} other{{v0} days before}}'**
  String daysBefore(int v0);

  /// No description provided for @hoursBefore.
  ///
  /// In en, this message translates to:
  /// **'{v0, plural, =1{1 hour before} other{{v0} hours before}}'**
  String hoursBefore(int v0);

  /// No description provided for @minutesBefore.
  ///
  /// In en, this message translates to:
  /// **'{v0, plural, =1{1 minute before} other{{v0} minutes before}}'**
  String minutesBefore(int v0);

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @cleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get cleared;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @record.
  ///
  /// In en, this message translates to:
  /// **'Record {v0}'**
  String record(Object v0);

  /// No description provided for @someFieldsAreUncertainCheckThemAgainst.
  ///
  /// In en, this message translates to:
  /// **'Some fields are uncertain. Check them against the image before confirming.'**
  String get someFieldsAreUncertainCheckThemAgainst;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @completedAt.
  ///
  /// In en, this message translates to:
  /// **'Completed at'**
  String get completedAt;

  /// No description provided for @recurrence.
  ///
  /// In en, this message translates to:
  /// **'Recurrence'**
  String get recurrence;

  /// No description provided for @recurrenceTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Recurrence time zone'**
  String get recurrenceTimeZone;

  /// No description provided for @unavailableCategory.
  ///
  /// In en, this message translates to:
  /// **'Unavailable category'**
  String get unavailableCategory;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @task.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get task;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @canceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get canceled;

  /// No description provided for @taskChanges.
  ///
  /// In en, this message translates to:
  /// **'Task changes: {v0}'**
  String taskChanges(Object v0);

  /// No description provided for @onlyTheSelectedOccurrenceWillChangeOther.
  ///
  /// In en, this message translates to:
  /// **'Only the selected occurrence will change. Other dates keep their existing rule.'**
  String get onlyTheSelectedOccurrenceWillChangeOther;

  /// No description provided for @stopsFutureOccurrencesInThisRangeAnd.
  ///
  /// In en, this message translates to:
  /// **'Stops future occurrences in this range and retains other completed records. Accept or reject the changes together.'**
  String get stopsFutureOccurrencesInThisRangeAnd;

  /// No description provided for @acceptOrRejectTheSeriesChangesTogether.
  ///
  /// In en, this message translates to:
  /// **'Accept or reject the series changes together. New occurrences will be created as needed.'**
  String get acceptOrRejectTheSeriesChangesTogether;

  /// No description provided for @viewAllChanges.
  ///
  /// In en, this message translates to:
  /// **'View all changes'**
  String get viewAllChanges;

  /// No description provided for @seriesTemplate.
  ///
  /// In en, this message translates to:
  /// **'Series template '**
  String get seriesTemplate;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @timeZone.
  ///
  /// In en, this message translates to:
  /// **'Time zone {v0} '**
  String timeZone(Object v0);

  /// No description provided for @keepRepeating.
  ///
  /// In en, this message translates to:
  /// **'Keep repeating'**
  String get keepRepeating;

  /// No description provided for @endBoundarySet.
  ///
  /// In en, this message translates to:
  /// **'End boundary set'**
  String get endBoundarySet;

  /// No description provided for @saveAKimiApiKeyInModel.
  ///
  /// In en, this message translates to:
  /// **'Save a Kimi API key in Model connections before sending.'**
  String get saveAKimiApiKeyInModel;

  /// No description provided for @modelSettingsChangedSendANewRequest.
  ///
  /// In en, this message translates to:
  /// **'Model settings changed. Send a new request. Completed actions have been saved.'**
  String get modelSettingsChangedSendANewRequest;

  /// No description provided for @inputIsTooLongShortenItOr.
  ///
  /// In en, this message translates to:
  /// **'Input is too long. Shorten it or split your request. Your history is saved.'**
  String get inputIsTooLongShortenItOr;

  /// No description provided for @requestStopped.
  ///
  /// In en, this message translates to:
  /// **'Request stopped.'**
  String get requestStopped;

  /// No description provided for @theContextOrActionLimitHasBeen.
  ///
  /// In en, this message translates to:
  /// **'The context or action limit has been reached. Start a new chat.'**
  String get theContextOrActionLimitHasBeen;

  /// No description provided for @theChatOrRecordHasChangedFinish.
  ///
  /// In en, this message translates to:
  /// **'The chat or record has changed. Finish the pending request or reopen the chat.'**
  String get theChatOrRecordHasChangedFinish;

  /// No description provided for @theRecordOrTableStructureHasSince.
  ///
  /// In en, this message translates to:
  /// **'The record or table structure has since changed and cannot be overwritten.'**
  String get theRecordOrTableStructureHasSince;

  /// No description provided for @couldntCompleteTheActionYourDataIs.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t complete the action. Your data is safe. Try again.'**
  String get couldntCompleteTheActionYourDataIs;

  /// No description provided for @checkYourModelCredentialsAndAccessIn.
  ///
  /// In en, this message translates to:
  /// **'Check your model credentials and access in Model connections.'**
  String get checkYourModelCredentialsAndAccessIn;

  /// No description provided for @modelRateLimitReachedTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Model rate limit reached. Try again later.'**
  String get modelRateLimitReachedTryAgainLater;

  /// No description provided for @thisAccountIsOutOfQuotaSelect.
  ///
  /// In en, this message translates to:
  /// **'This account is out of quota. Select another model and retry.'**
  String get thisAccountIsOutOfQuotaSelect;

  /// No description provided for @theSourceImageIsUnavailableSelectIt.
  ///
  /// In en, this message translates to:
  /// **'The source image is unavailable. Select it again in Screenshot import.'**
  String get theSourceImageIsUnavailableSelectIt;

  /// No description provided for @couldntReadTheSourceImageTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read the source image. Try again later.'**
  String get couldntReadTheSourceImageTryAgain;

  /// No description provided for @modelSettingsChangedDuringTheRequestRetry.
  ///
  /// In en, this message translates to:
  /// **'Model settings changed during the request. Retry with the current model.'**
  String get modelSettingsChangedDuringTheRequestRetry;

  /// No description provided for @inputOrToolResultsAreTooLong.
  ///
  /// In en, this message translates to:
  /// **'Input or tool results are too long. Split the request. Completed actions are saved.'**
  String get inputOrToolResultsAreTooLong;

  /// No description provided for @actionLimitReachedSendAnotherRequestOr.
  ///
  /// In en, this message translates to:
  /// **'Action limit reached. Send another request or start a new chat.'**
  String get actionLimitReachedSendAnotherRequestOr;

  /// No description provided for @theTargetHasChangedYouCanReplan.
  ///
  /// In en, this message translates to:
  /// **'The target has changed. You can replan.'**
  String get theTargetHasChangedYouCanReplan;

  /// No description provided for @connectionInterruptedOrModelTimedOutTry.
  ///
  /// In en, this message translates to:
  /// **'Connection interrupted or model timed out. Try again.'**
  String get connectionInterruptedOrModelTimedOutTry;

  /// No description provided for @theModelResponseFailedValidationThisBatch.
  ///
  /// In en, this message translates to:
  /// **'The model response failed validation. This batch was not applied.'**
  String get theModelResponseFailedValidationThisBatch;

  /// No description provided for @requestIncompleteYouCanRetryCompletedActions.
  ///
  /// In en, this message translates to:
  /// **'Request incomplete. You can retry. Completed actions are saved.'**
  String get requestIncompleteYouCanRetryCompletedActions;

  /// No description provided for @changesUndone.
  ///
  /// In en, this message translates to:
  /// **'Changes undone'**
  String get changesUndone;

  /// No description provided for @awaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation: {v0}'**
  String awaitingConfirmation(Object v0);

  /// No description provided for @requestSavedReadyToContinue.
  ///
  /// In en, this message translates to:
  /// **'Request saved. Ready to continue.'**
  String get requestSavedReadyToContinue;

  /// No description provided for @working.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get working;

  /// No description provided for @replySaved.
  ///
  /// In en, this message translates to:
  /// **'Reply saved'**
  String get replySaved;

  /// No description provided for @actionBatchesSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Action batches submitted: {v0}'**
  String actionBatchesSubmitted(Object v0);

  /// No description provided for @requestStoppedBuild.
  ///
  /// In en, this message translates to:
  /// **'Request stopped'**
  String get requestStoppedBuild;

  /// No description provided for @completedActionBatchesRetained.
  ///
  /// In en, this message translates to:
  /// **'Completed action batches retained: {v0}.'**
  String completedActionBatchesRetained(Object v0);

  /// No description provided for @earlierTurnsOutsideThisRequestFullHistory.
  ///
  /// In en, this message translates to:
  /// **'Earlier turns outside this request: {v0}. Full history is available.'**
  String earlierTurnsOutsideThisRequestFullHistory(Object v0);

  /// No description provided for @earlierTurnsOutsideThisRequestFullHistoryIsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Earlier turns outside this request: {v0}. Full history is available. Add context if you refer to earlier messages.'**
  String earlierTurnsOutsideThisRequestFullHistoryIsAvailable(Object v0);

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @selectLabel.
  ///
  /// In en, this message translates to:
  /// **'Select {v0}'**
  String selectLabel(Object v0);

  /// No description provided for @acceptAll.
  ///
  /// In en, this message translates to:
  /// **'Accept all'**
  String get acceptAll;

  /// No description provided for @acceptSelected.
  ///
  /// In en, this message translates to:
  /// **'Accept selected ({v0})'**
  String acceptSelected(Object v0);

  /// No description provided for @rejectSelected.
  ///
  /// In en, this message translates to:
  /// **'Reject selected ({v0})'**
  String rejectSelected(Object v0);

  /// No description provided for @refreshChanges.
  ///
  /// In en, this message translates to:
  /// **'Refresh changes'**
  String get refreshChanges;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get cancelRequest;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @undoThisBatch.
  ///
  /// In en, this message translates to:
  /// **'Undo this batch'**
  String get undoThisBatch;

  /// No description provided for @undoAllChangesInThisRequest.
  ///
  /// In en, this message translates to:
  /// **'Undo all changes in this request'**
  String get undoAllChangesInThisRequest;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name: {v0} → {v1}'**
  String name(Object v0, Object v1);

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description: {v0}{v1}'**
  String description(Object v0, Object v1);

  /// No description provided for @addField.
  ///
  /// In en, this message translates to:
  /// **'Add field: '**
  String get addField;

  /// No description provided for @editField.
  ///
  /// In en, this message translates to:
  /// **'Edit field: {v0} → {v1}'**
  String editField(Object v0, Object v1);

  /// No description provided for @removeField.
  ///
  /// In en, this message translates to:
  /// **'Remove field: {v0}'**
  String removeField(Object v0);

  /// No description provided for @field.
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get field;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @requirement.
  ///
  /// In en, this message translates to:
  /// **'Requirement'**
  String get requirement;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @createTable.
  ///
  /// In en, this message translates to:
  /// **'Create table'**
  String get createTable;

  /// No description provided for @editTable.
  ///
  /// In en, this message translates to:
  /// **'Edit table'**
  String get editTable;

  /// No description provided for @noChangesToTheTable.
  ///
  /// In en, this message translates to:
  /// **'No changes to the table'**
  String get noChangesToTheTable;

  /// No description provided for @number.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get number;

  /// No description provided for @currencyDecimalPlaces.
  ///
  /// In en, this message translates to:
  /// **'Currency, {v0} decimal places'**
  String currencyDecimalPlaces(Object v0);

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get dateAndTime;

  /// No description provided for @singleSelect.
  ///
  /// In en, this message translates to:
  /// **'Single select'**
  String get singleSelect;

  /// No description provided for @yesNo.
  ///
  /// In en, this message translates to:
  /// **'Yes/No'**
  String get yesNo;

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// No description provided for @glm.
  ///
  /// In en, this message translates to:
  /// **'GLM'**
  String get glm;

  /// No description provided for @otherOpenaiCompatible.
  ///
  /// In en, this message translates to:
  /// **'Other (OpenAI-compatible)'**
  String get otherOpenaiCompatible;

  /// No description provided for @enterAValidKeyWithoutSpacesOr.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid key without spaces or line breaks'**
  String get enterAValidKeyWithoutSpacesOr;

  /// No description provided for @secureStorageIsUnavailableUnlockTheDevice.
  ///
  /// In en, this message translates to:
  /// **'Secure storage is unavailable. Unlock the device and try again.'**
  String get secureStorageIsUnavailableUnlockTheDevice;

  /// No description provided for @settingsChangedReloadAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Settings changed. Reload and try again.'**
  String get settingsChangedReloadAndTryAgain;

  /// No description provided for @enterAKeyForTheSelectedProvider.
  ///
  /// In en, this message translates to:
  /// **'Enter a key for the selected provider and region'**
  String get enterAKeyForTheSelectedProvider;

  /// No description provided for @couldntReadOrSaveLocalSettingsTry.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read or save local settings. Try again.'**
  String get couldntReadOrSaveLocalSettingsTry;

  /// No description provided for @enterAValidModelNameAndKey.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid model name and key'**
  String get enterAValidModelNameAndKey;

  /// No description provided for @authenticationFailedCheckTheKeyApiProduct.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Check the key, API product and model access (401).'**
  String get authenticationFailedCheckTheKeyApiProduct;

  /// No description provided for @accessDeniedCheckYourSubscriptionAndApi.
  ///
  /// In en, this message translates to:
  /// **'Access denied. Check your subscription and API permissions (403).'**
  String get accessDeniedCheckYourSubscriptionAndApi;

  /// No description provided for @rateLimitReachedTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Rate limit reached. Try again later (429).'**
  String get rateLimitReachedTryAgainLater;

  /// No description provided for @quotaOrBalanceExhaustedCheckTheProvider.
  ///
  /// In en, this message translates to:
  /// **'Quota or balance exhausted. Check the provider console.'**
  String get quotaOrBalanceExhaustedCheckTheProvider;

  /// No description provided for @modelOrEndpointNotFoundCheckYour.
  ///
  /// In en, this message translates to:
  /// **'Model or endpoint not found. Check your settings (404).'**
  String get modelOrEndpointNotFoundCheckYour;

  /// No description provided for @testCanceled.
  ///
  /// In en, this message translates to:
  /// **'Test canceled'**
  String get testCanceled;

  /// No description provided for @connectionTimedOutCheckYourNetworkAnd.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Check your network and retry.'**
  String get connectionTimedOutCheckYourNetworkAnd;

  /// No description provided for @connectionFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Try again.'**
  String get connectionFailedTryAgain;

  /// No description provided for @theServiceReturnedAnIncompleteResponseTry.
  ///
  /// In en, this message translates to:
  /// **'The service returned an incomplete response. Try again later.'**
  String get theServiceReturnedAnIncompleteResponseTry;

  /// No description provided for @couldntCompleteTheActionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t complete the action. Try again.'**
  String get couldntCompleteTheActionTryAgain;

  /// No description provided for @fast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fast;

  /// No description provided for @viewSourceChat.
  ///
  /// In en, this message translates to:
  /// **'View source chat'**
  String get viewSourceChat;

  /// No description provided for @viewTaskSourceChat.
  ///
  /// In en, this message translates to:
  /// **'View task source chat'**
  String get viewTaskSourceChat;

  /// No description provided for @resetsSoon.
  ///
  /// In en, this message translates to:
  /// **'Resets soon'**
  String get resetsSoon;

  /// No description provided for @resetsInMin.
  ///
  /// In en, this message translates to:
  /// **'Resets in {v0} min'**
  String resetsInMin(Object v0);

  /// No description provided for @resetsInHr.
  ///
  /// In en, this message translates to:
  /// **'Resets in {v0} hr'**
  String resetsInHr(Object v0);

  /// No description provided for @resetsInHrMin.
  ///
  /// In en, this message translates to:
  /// **'Resets in {v0} hr {v1} min'**
  String resetsInHrMin(Object v0, Object v1);

  /// No description provided for @resetsInDays.
  ///
  /// In en, this message translates to:
  /// **'Resets in {v0} days'**
  String resetsInDays(Object v0);

  /// No description provided for @noKey.
  ///
  /// In en, this message translates to:
  /// **'No key'**
  String get noKey;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'{v0}: {v1}% left'**
  String left(Object v0, Object v1);

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance {v0}'**
  String balance(Object v0);

  /// No description provided for @quotaUsed.
  ///
  /// In en, this message translates to:
  /// **'{v0} quota: {v1}% used{v2}'**
  String quotaUsed(Object v0, Object v1, Object v2);

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'{v0}% used'**
  String used(Object v0);

  /// No description provided for @checkQuotaInTheProviderConsole.
  ///
  /// In en, this message translates to:
  /// **'Check quota in the provider console'**
  String get checkQuotaInTheProviderConsole;

  /// No description provided for @quotaNotCheckedYet.
  ///
  /// In en, this message translates to:
  /// **'Quota not checked yet'**
  String get quotaNotCheckedYet;

  /// No description provided for @accountBalance.
  ///
  /// In en, this message translates to:
  /// **'Account balance'**
  String get accountBalance;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'{v0}, {v1} remaining'**
  String remaining(Object v0, Object v1);

  /// No description provided for @upwardTrend.
  ///
  /// In en, this message translates to:
  /// **'Upward trend'**
  String get upwardTrend;

  /// No description provided for @archiveBox.
  ///
  /// In en, this message translates to:
  /// **'Archive box'**
  String get archiveBox;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @briefcase.
  ///
  /// In en, this message translates to:
  /// **'Briefcase'**
  String get briefcase;

  /// No description provided for @heart.
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get heart;

  /// No description provided for @openBook.
  ///
  /// In en, this message translates to:
  /// **'Open book'**
  String get openBook;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @shoppingCart.
  ///
  /// In en, this message translates to:
  /// **'Shopping cart'**
  String get shoppingCart;

  /// No description provided for @cutlery.
  ///
  /// In en, this message translates to:
  /// **'Cutlery'**
  String get cutlery;

  /// No description provided for @plane.
  ///
  /// In en, this message translates to:
  /// **'Plane'**
  String get plane;

  /// No description provided for @dumbbell.
  ///
  /// In en, this message translates to:
  /// **'Dumbbell'**
  String get dumbbell;

  /// No description provided for @graduationCap.
  ///
  /// In en, this message translates to:
  /// **'Graduation cap'**
  String get graduationCap;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get gift;

  /// No description provided for @car.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get car;

  /// No description provided for @pawPrint.
  ///
  /// In en, this message translates to:
  /// **'Paw print'**
  String get pawPrint;

  /// No description provided for @leaf.
  ///
  /// In en, this message translates to:
  /// **'Leaf'**
  String get leaf;

  /// No description provided for @star.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get star;

  /// No description provided for @flag.
  ///
  /// In en, this message translates to:
  /// **'Flag'**
  String get flag;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @pen.
  ///
  /// In en, this message translates to:
  /// **'Pen'**
  String get pen;

  /// No description provided for @person.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get person;

  /// No description provided for @folder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get folder;

  /// No description provided for @mistBlue.
  ///
  /// In en, this message translates to:
  /// **'Mist blue'**
  String get mistBlue;

  /// No description provided for @stone.
  ///
  /// In en, this message translates to:
  /// **'Stone'**
  String get stone;

  /// No description provided for @sage.
  ///
  /// In en, this message translates to:
  /// **'Sage'**
  String get sage;

  /// No description provided for @wheat.
  ///
  /// In en, this message translates to:
  /// **'Wheat'**
  String get wheat;

  /// No description provided for @terracotta.
  ///
  /// In en, this message translates to:
  /// **'Terracotta'**
  String get terracotta;

  /// No description provided for @lavenderGray.
  ///
  /// In en, this message translates to:
  /// **'Lavender gray'**
  String get lavenderGray;

  /// No description provided for @slate.
  ///
  /// In en, this message translates to:
  /// **'Slate'**
  String get slate;

  /// No description provided for @warmGray.
  ///
  /// In en, this message translates to:
  /// **'Warm gray'**
  String get warmGray;

  /// No description provided for @newSubcategory.
  ///
  /// In en, this message translates to:
  /// **'New subcategory'**
  String get newSubcategory;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @reorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorder;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @restoreCategory.
  ///
  /// In en, this message translates to:
  /// **'Restore category'**
  String get restoreCategory;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deletePermanently;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'{v0, plural, =1{1 task} other{{v0} tasks}}'**
  String tasks(num v0);

  /// No description provided for @subcategories.
  ///
  /// In en, this message translates to:
  /// **'{v0, plural, =1{1 subcategory} other{{v0} subcategories}}'**
  String subcategories(num v0);

  /// No description provided for @recurringSeries.
  ///
  /// In en, this message translates to:
  /// **'{v0, plural, =1{1 recurring series} other{{v0} recurring series}}'**
  String recurringSeries(num v0);

  /// No description provided for @deleteLabelBuild.
  ///
  /// In en, this message translates to:
  /// **'Delete “{v0}”?'**
  String deleteLabelBuild(Object v0);

  /// No description provided for @contains.
  ///
  /// In en, this message translates to:
  /// **'Contains {v0}.'**
  String contains(Object v0);

  /// No description provided for @moveTasksToUncategorizedAndPromoteSubcategories.
  ///
  /// In en, this message translates to:
  /// **'Move tasks to Uncategorized and promote subcategories to top level'**
  String get moveTasksToUncategorizedAndPromoteSubcategories;

  /// No description provided for @deleteTasksAndSubcategories.
  ///
  /// In en, this message translates to:
  /// **'Delete tasks and subcategories'**
  String get deleteTasksAndSubcategories;

  /// No description provided for @futureTasksInThisCategoryWillMove.
  ///
  /// In en, this message translates to:
  /// **'Future tasks in this category will move to Uncategorized. Subcategory series keep their categories.'**
  String get futureTasksInThisCategoryWillMove;

  /// No description provided for @alsoStopTheseSeries.
  ///
  /// In en, this message translates to:
  /// **'Also stop these {v0} series.'**
  String alsoStopTheseSeries(Object v0);

  /// No description provided for @keepTheTasksMovedElsewhereOrUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Keep the {v0} tasks moved elsewhere or uncategorized, and stop their recurrence.'**
  String keepTheTasksMovedElsewhereOrUncategorized(Object v0);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get deleteCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @iconIcongrid.
  ///
  /// In en, this message translates to:
  /// **'Icon, {v0}'**
  String iconIcongrid(Object v0);

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get notSelected;

  /// No description provided for @colorItemOf.
  ///
  /// In en, this message translates to:
  /// **'Color, {v0}, {v1}, item {v3} of {v2}'**
  String colorItemOf(Object v0, Object v1, Object v2, Object v3);

  /// No description provided for @topLevel.
  ///
  /// In en, this message translates to:
  /// **'Top level'**
  String get topLevel;

  /// No description provided for @parent.
  ///
  /// In en, this message translates to:
  /// **'Parent, {v0}'**
  String parent(Object v0);

  /// No description provided for @parentParentrow.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get parentParentrow;

  /// No description provided for @aCategoryWithSubcategoriesMustStayAt.
  ///
  /// In en, this message translates to:
  /// **'A category with subcategories must stay at the top level'**
  String get aCategoryWithSubcategoriesMustStayAt;

  /// No description provided for @moveUnder.
  ///
  /// In en, this message translates to:
  /// **'Move under {v0}'**
  String moveUnder(Object v0);

  /// No description provided for @archiveCategory.
  ///
  /// In en, this message translates to:
  /// **'Archive category'**
  String get archiveCategory;

  /// No description provided for @hidesThisCategoryWhenCreatingTasksIts.
  ///
  /// In en, this message translates to:
  /// **'Hides this category when creating tasks. Its data is retained.'**
  String get hidesThisCategoryWhenCreatingTasksIts;

  /// No description provided for @notificationsAndReminders.
  ///
  /// In en, this message translates to:
  /// **'Notifications and reminders'**
  String get notificationsAndReminders;

  /// No description provided for @couldntOpenNotificationSettingsTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open notification settings. Try again.'**
  String get couldntOpenNotificationSettingsTryAgain;

  /// No description provided for @localWorkspaceIsntReady.
  ///
  /// In en, this message translates to:
  /// **'Local workspace isn’t ready.'**
  String get localWorkspaceIsntReady;

  /// No description provided for @checkingPermissions.
  ///
  /// In en, this message translates to:
  /// **'Checking permissions…'**
  String get checkingPermissions;

  /// No description provided for @localNotificationsAreUnavailableOnThisPlatform.
  ///
  /// In en, this message translates to:
  /// **'Local notifications are unavailable on this platform'**
  String get localNotificationsAreUnavailableOnThisPlatform;

  /// No description provided for @systemNotificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'System notifications enabled'**
  String get systemNotificationsEnabled;

  /// No description provided for @notificationsAreOffYourReminderRulesAre.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. Your reminder rules are saved.'**
  String get notificationsAreOffYourReminderRulesAre;

  /// No description provided for @backgroundMaintenanceRegisteredTheSystemControlsTiming.
  ///
  /// In en, this message translates to:
  /// **'Background maintenance registered. The system controls timing.'**
  String get backgroundMaintenanceRegisteredTheSystemControlsTiming;

  /// No description provided for @backgroundRegistrationFailedRemindersCanStillBe.
  ///
  /// In en, this message translates to:
  /// **'Background registration failed. Reminders can still be scheduled while the app is open.'**
  String get backgroundRegistrationFailedRemindersCanStillBe;

  /// No description provided for @foregroundMaintenanceOnlyDigestGenerationPausesWhen.
  ///
  /// In en, this message translates to:
  /// **'Foreground maintenance only. Digest generation pauses when the app closes.'**
  String get foregroundMaintenanceOnlyDigestGenerationPausesWhen;

  /// No description provided for @retryBackgroundMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Retry background maintenance'**
  String get retryBackgroundMaintenance;

  /// No description provided for @scheduledPending.
  ///
  /// In en, this message translates to:
  /// **'Scheduled: {v0}. Pending: {v1}.'**
  String scheduledPending(Object v0, Object v1);

  /// No description provided for @dueRemindersMayArriveLateEnableExact.
  ///
  /// In en, this message translates to:
  /// **'Due reminders may arrive late. Enable exact alarms for precise timing.'**
  String get dueRemindersMayArriveLateEnableExact;

  /// No description provided for @someRemindersWerentScheduledTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Some reminders weren’t scheduled. Try again.'**
  String get someRemindersWerentScheduledTryAgain;

  /// No description provided for @checkAndRetry.
  ///
  /// In en, this message translates to:
  /// **'Check and retry'**
  String get checkAndRetry;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get enableNotifications;

  /// No description provided for @enableExactAlarms.
  ///
  /// In en, this message translates to:
  /// **'Enable exact alarms'**
  String get enableExactAlarms;

  /// No description provided for @systemNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'System notification settings'**
  String get systemNotificationSettings;

  /// No description provided for @scheduleDetails.
  ///
  /// In en, this message translates to:
  /// **'Schedule details'**
  String get scheduleDetails;

  /// No description provided for @setAReminderOnTheTaskUp.
  ///
  /// In en, this message translates to:
  /// **'Set a reminder on the task. Up to 60 reminders are scheduled for the next 30 days and digests up to 7 days ahead, using current device data.'**
  String get setAReminderOnTheTaskUp;

  /// No description provided for @schedulingResumesInTheBackgroundOrWhen.
  ///
  /// In en, this message translates to:
  /// **'Scheduling resumes in the background or when you reopen the app. Battery saver, Do Not Disturb and force stop can affect digest delivery.'**
  String get schedulingResumesInTheBackgroundOrWhen;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @nextMonday.
  ///
  /// In en, this message translates to:
  /// **'Next Monday'**
  String get nextMonday;

  /// No description provided for @formattedValue.
  ///
  /// In en, this message translates to:
  /// **'{v0}/{v1}'**
  String formattedValue(Object v0, Object v1);

  /// No description provided for @noDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get noDueDate;

  /// No description provided for @whenDue.
  ///
  /// In en, this message translates to:
  /// **'When due'**
  String get whenDue;

  /// No description provided for @minutesBeforeBuild.
  ///
  /// In en, this message translates to:
  /// **'15 minutes before'**
  String get minutesBeforeBuild;

  /// No description provided for @hourBefore.
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get hourBefore;

  /// No description provided for @dayBefore.
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get dayBefore;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get newTask;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'Task title'**
  String get taskTitle;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @addANote.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get addANote;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @setTime.
  ///
  /// In en, this message translates to:
  /// **'Set time'**
  String get setTime;

  /// No description provided for @chooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get chooseDate;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @backToToday.
  ///
  /// In en, this message translates to:
  /// **'Back to today'**
  String get backToToday;

  /// No description provided for @restored.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get restored;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @filterCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter category: {v0}'**
  String filterCategory(Object v0);

  /// No description provided for @chooseDateBuild.
  ///
  /// In en, this message translates to:
  /// **'{v0}, choose date'**
  String chooseDateBuild(Object v0);

  /// No description provided for @collapseDailyOverview.
  ///
  /// In en, this message translates to:
  /// **'Collapse daily overview'**
  String get collapseDailyOverview;

  /// No description provided for @mtwtfss.
  ///
  /// In en, this message translates to:
  /// **'MTWTFSS'**
  String get mtwtfss;

  /// No description provided for @formattedValueBuild.
  ///
  /// In en, this message translates to:
  /// **'{v3}, {v1}/{v2}/{v0}'**
  String formattedValueBuild(Object v0, Object v1, Object v2, Object v3);

  /// No description provided for @thatDay.
  ///
  /// In en, this message translates to:
  /// **'That day'**
  String get thatDay;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'{v0}: {v1} pending'**
  String pending(Object v0, Object v1);

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **', {v0} overdue'**
  String overdue(Object v0);

  /// No description provided for @completion.
  ///
  /// In en, this message translates to:
  /// **'{v0} completion'**
  String completion(Object v0);

  /// No description provided for @allLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// No description provided for @overdueBuild.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueBuild;

  /// No description provided for @noTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get noTasks;

  /// No description provided for @completedBuild.
  ///
  /// In en, this message translates to:
  /// **'Completed: {v0}'**
  String completedBuild(Object v0);

  /// No description provided for @allTasks.
  ///
  /// In en, this message translates to:
  /// **'All tasks'**
  String get allTasks;

  /// No description provided for @setADueDateBeforeEnablingRecurrence.
  ///
  /// In en, this message translates to:
  /// **'Set a due date before enabling recurrence'**
  String get setADueDateBeforeEnablingRecurrence;

  /// No description provided for @selectedOccurrencesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Selected occurrences deleted'**
  String get selectedOccurrencesDeleted;

  /// No description provided for @recurringTaskUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recurring task updated'**
  String get recurringTaskUpdated;

  /// No description provided for @undone.
  ///
  /// In en, this message translates to:
  /// **'Undone'**
  String get undone;

  /// No description provided for @dateIsOutsideAvailableTimeZoneData.
  ///
  /// In en, this message translates to:
  /// **'Date is outside available time zone data. Choose an earlier end date.'**
  String get dateIsOutsideAvailableTimeZoneData;

  /// No description provided for @updatesRecurrenceForTheSelectedRangeEarlier.
  ///
  /// In en, this message translates to:
  /// **'Updates recurrence for the selected range. Earlier records and other completed tasks are retained.'**
  String get updatesRecurrenceForTheSelectedRangeEarlier;

  /// No description provided for @changesOnlyThisOccurrenceOtherDatesAnd.
  ///
  /// In en, this message translates to:
  /// **'Changes only this occurrence. Other dates and the recurrence schedule are retained.'**
  String get changesOnlyThisOccurrenceOtherDatesAnd;

  /// No description provided for @changesAddedEditedDeleted.
  ///
  /// In en, this message translates to:
  /// **'Changes: {v0} added, {v1} edited, {v2} deleted'**
  String changesAddedEditedDeleted(Object v0, Object v1, Object v2);

  /// No description provided for @collapseRecords.
  ///
  /// In en, this message translates to:
  /// **'Collapse records'**
  String get collapseRecords;

  /// No description provided for @viewAllRecords.
  ///
  /// In en, this message translates to:
  /// **'View all {v0} records'**
  String viewAllRecords(Object v0);

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get confirmDeletion;

  /// No description provided for @confirmChanges.
  ///
  /// In en, this message translates to:
  /// **'Confirm changes'**
  String get confirmChanges;

  /// No description provided for @previously.
  ///
  /// In en, this message translates to:
  /// **'Previously: {v0}'**
  String previously(Object v0);

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @timeZoneBuild.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get timeZoneBuild;

  /// No description provided for @setADueTimeToPreviewUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Set a due time to preview upcoming dates'**
  String get setADueTimeToPreviewUpcoming;

  /// No description provided for @thisOccurrenceBuild.
  ///
  /// In en, this message translates to:
  /// **'This occurrence: {v0}'**
  String thisOccurrenceBuild(Object v0);

  /// No description provided for @noUpcomingDatesTheEndConditionHas.
  ///
  /// In en, this message translates to:
  /// **'No upcoming dates. The end condition has been reached.'**
  String get noUpcomingDatesTheEndConditionHas;

  /// No description provided for @upcomingDates.
  ///
  /// In en, this message translates to:
  /// **'Upcoming dates'**
  String get upcomingDates;

  /// No description provided for @timeZoneDataIsAvailableThroughShorten.
  ///
  /// In en, this message translates to:
  /// **'Time zone data is available through {v0}. Shorten the preview range.'**
  String timeZoneDataIsAvailableThroughShorten(Object v0);

  /// No description provided for @previewUnavailableForThisRuleOrTime.
  ///
  /// In en, this message translates to:
  /// **'Preview unavailable for this rule or time zone'**
  String get previewUnavailableForThisRuleOrTime;

  /// No description provided for @dateRangeIsTooLargeShortenThe.
  ///
  /// In en, this message translates to:
  /// **'Date range is too large. Shorten the interval or range.'**
  String get dateRangeIsTooLargeShortenThe;

  /// No description provided for @enterATitleBeforeClosing.
  ///
  /// In en, this message translates to:
  /// **'Enter a title before closing'**
  String get enterATitleBeforeClosing;

  /// No description provided for @taskUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Task unavailable'**
  String get taskUnavailable;

  /// No description provided for @itMayHaveBeenDeletedOrChanged.
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted or changed on another device.'**
  String get itMayHaveBeenDeletedOrChanged;

  /// No description provided for @backToTasks.
  ///
  /// In en, this message translates to:
  /// **'Back to tasks'**
  String get backToTasks;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @markIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Mark incomplete, {v0}'**
  String markIncomplete(Object v0);

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete, {v0}'**
  String markComplete(Object v0);

  /// No description provided for @addANoteBuildtitlearea.
  ///
  /// In en, this message translates to:
  /// **'Add a note…'**
  String get addANoteBuildtitlearea;

  /// No description provided for @originalCategoryArchived.
  ///
  /// In en, this message translates to:
  /// **'Original category archived'**
  String get originalCategoryArchived;

  /// No description provided for @dueBuildfields.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get dueBuildfields;

  /// No description provided for @overdueBuildfields.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueBuildfields;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get addTag;

  /// No description provided for @fromChat.
  ///
  /// In en, this message translates to:
  /// **'From chat'**
  String get fromChat;

  /// No description provided for @originalChatDeleted.
  ///
  /// In en, this message translates to:
  /// **'Original chat deleted'**
  String get originalChatDeleted;

  /// No description provided for @originalChatUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Original chat unavailable'**
  String get originalChatUnavailable;

  /// No description provided for @createdFromChatDoubleTapToView.
  ///
  /// In en, this message translates to:
  /// **'Created from chat: {v0}. Double-tap to view.'**
  String createdFromChatDoubleTapToView(Object v0);

  /// No description provided for @createdBuildmeta.
  ///
  /// In en, this message translates to:
  /// **'Created {v0}'**
  String createdBuildmeta(Object v0);

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated {v0}'**
  String updated(Object v0);

  /// No description provided for @completedBuildmeta.
  ///
  /// In en, this message translates to:
  /// **'Completed {v0}'**
  String completedBuildmeta(Object v0);

  /// No description provided for @deleteThisTask.
  ///
  /// In en, this message translates to:
  /// **'Delete this task'**
  String get deleteThisTask;

  /// No description provided for @copyTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy title'**
  String get copyTitle;

  /// No description provided for @titleCopied.
  ///
  /// In en, this message translates to:
  /// **'Title copied'**
  String get titleCopied;

  /// No description provided for @deleteThisTaskConfirmdelete.
  ///
  /// In en, this message translates to:
  /// **'Delete this task?'**
  String get deleteThisTaskConfirmdelete;

  /// No description provided for @willBeDeletedYouCanUndoWithin.
  ///
  /// In en, this message translates to:
  /// **'“{v0}” will be deleted. You can undo within 10 seconds.'**
  String willBeDeletedYouCanUndoWithin(Object v0);

  /// No description provided for @chooseDateBuild2.
  ///
  /// In en, this message translates to:
  /// **'Choose date…'**
  String get chooseDateBuild2;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @allDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDay;

  /// No description provided for @clearTime.
  ///
  /// In en, this message translates to:
  /// **'Clear time'**
  String get clearTime;

  /// No description provided for @addTime.
  ///
  /// In en, this message translates to:
  /// **'Add time'**
  String get addTime;

  /// No description provided for @clearDueDate.
  ///
  /// In en, this message translates to:
  /// **'Clear due date'**
  String get clearDueDate;

  /// No description provided for @removesTheTaskFromTodayThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Removes the task from Today, This week and Overdue filters'**
  String get removesTheTaskFromTodayThisWeek;

  /// No description provided for @decrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get decrease;

  /// No description provided for @increase.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get increase;

  /// No description provided for @doubleTapToEdit.
  ///
  /// In en, this message translates to:
  /// **'{v0}, {v1}. Double-tap to edit.'**
  String doubleTapToEdit(Object v0, Object v1);

  /// No description provided for @selectTask.
  ///
  /// In en, this message translates to:
  /// **'Select task: {v0}'**
  String selectTask(Object v0);

  /// No description provided for @restoreTask.
  ///
  /// In en, this message translates to:
  /// **'Restore task: {v0}'**
  String restoreTask(Object v0);

  /// No description provided for @completeTask.
  ///
  /// In en, this message translates to:
  /// **'Complete task: {v0}'**
  String completeTask(Object v0);

  /// No description provided for @rescheduleTask.
  ///
  /// In en, this message translates to:
  /// **'Reschedule task'**
  String get rescheduleTask;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get deleteTask;

  /// No description provided for @restoreTaskCustomactions.
  ///
  /// In en, this message translates to:
  /// **'Restore task'**
  String get restoreTaskCustomactions;

  /// No description provided for @completeTaskConfirmremainingsteps.
  ///
  /// In en, this message translates to:
  /// **'Complete task'**
  String get completeTaskConfirmremainingsteps;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get addReminder;

  /// No description provided for @deleteReminder.
  ///
  /// In en, this message translates to:
  /// **'Delete reminder: {v0}'**
  String deleteReminder(Object v0);

  /// No description provided for @upToReminders.
  ///
  /// In en, this message translates to:
  /// **'Up to 5 reminders'**
  String get upToReminders;

  /// No description provided for @recurringTasksSendRemindersBeforeEachDue.
  ///
  /// In en, this message translates to:
  /// **'Recurring tasks send reminders before each due date'**
  String get recurringTasksSendRemindersBeforeEachDue;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @minutesBeforeBuild2.
  ///
  /// In en, this message translates to:
  /// **'5 minutes before'**
  String get minutesBeforeBuild2;

  /// No description provided for @minutesBeforeBuild3.
  ///
  /// In en, this message translates to:
  /// **'15 minutes before'**
  String get minutesBeforeBuild3;

  /// No description provided for @minutesBeforeBuild4.
  ///
  /// In en, this message translates to:
  /// **'30 minutes before'**
  String get minutesBeforeBuild4;

  /// No description provided for @hourBeforeBuild.
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get hourBeforeBuild;

  /// No description provided for @dayBeforeBuild.
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get dayBeforeBuild;

  /// No description provided for @relativeToDueTime.
  ///
  /// In en, this message translates to:
  /// **'Relative to due time'**
  String get relativeToDueTime;

  /// No description provided for @setADueTimeFirst.
  ///
  /// In en, this message translates to:
  /// **'Set a due time first'**
  String get setADueTimeFirst;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @reminderLeadTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder lead time'**
  String get reminderLeadTime;

  /// No description provided for @addBuild.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addBuild;

  /// No description provided for @specificTime.
  ///
  /// In en, this message translates to:
  /// **'Specific time'**
  String get specificTime;

  /// No description provided for @am.
  ///
  /// In en, this message translates to:
  /// **'9:00 AM'**
  String get am;

  /// No description provided for @pm.
  ///
  /// In en, this message translates to:
  /// **'12:00 PM'**
  String get pm;

  /// No description provided for @pmBuild.
  ///
  /// In en, this message translates to:
  /// **'6:00 PM'**
  String get pmBuild;

  /// No description provided for @pmBuild2.
  ///
  /// In en, this message translates to:
  /// **'8:00 PM'**
  String get pmBuild2;

  /// No description provided for @customRuleReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Custom rule (read only)'**
  String get customRuleReadOnly;

  /// No description provided for @resetRule.
  ///
  /// In en, this message translates to:
  /// **'Reset rule'**
  String get resetRule;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @dailyBuild.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailyBuild;

  /// No description provided for @weeklyBuild.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weeklyBuild;

  /// No description provided for @monthlyBuild.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyBuild;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @interval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get interval;

  /// No description provided for @every.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get every;

  /// No description provided for @repeatInterval.
  ///
  /// In en, this message translates to:
  /// **'Repeat interval'**
  String get repeatInterval;

  /// No description provided for @repeatOn.
  ///
  /// In en, this message translates to:
  /// **'Repeat on'**
  String get repeatOn;

  /// No description provided for @dayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day of month'**
  String get dayOfMonth;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @ends.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get ends;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @onDate.
  ///
  /// In en, this message translates to:
  /// **'On date'**
  String get onDate;

  /// No description provided for @afterNOccurrences.
  ///
  /// In en, this message translates to:
  /// **'After N occurrences'**
  String get afterNOccurrences;

  /// No description provided for @numberOfOccurrences.
  ///
  /// In en, this message translates to:
  /// **'Number of occurrences'**
  String get numberOfOccurrences;

  /// No description provided for @times.
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get times;

  /// No description provided for @fixedTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Fixed time zone'**
  String get fixedTimeZone;

  /// No description provided for @shortMonthsUseTheLastDayDuring.
  ///
  /// In en, this message translates to:
  /// **'Short months use the last day. During daylight saving changes, missing times move forward and repeated times run once.'**
  String get shortMonthsUseTheLastDayDuring;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary: {v0}'**
  String summary(Object v0);

  /// No description provided for @saveRecurrence.
  ///
  /// In en, this message translates to:
  /// **'Save recurrence'**
  String get saveRecurrence;

  /// No description provided for @clearRecurrence.
  ///
  /// In en, this message translates to:
  /// **'Clear recurrence?'**
  String get clearRecurrence;

  /// No description provided for @clearRecurrenceBuild.
  ///
  /// In en, this message translates to:
  /// **'Clear recurrence'**
  String get clearRecurrenceBuild;

  /// No description provided for @unfinishedSteps.
  ///
  /// In en, this message translates to:
  /// **'Unfinished steps: {v0}'**
  String unfinishedSteps(Object v0);

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @taskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Task completed'**
  String get taskCompleted;

  /// No description provided for @taskReopened.
  ///
  /// In en, this message translates to:
  /// **'Task reopened'**
  String get taskReopened;

  /// No description provided for @stepDeleted.
  ///
  /// In en, this message translates to:
  /// **'Step deleted'**
  String get stepDeleted;

  /// No description provided for @progressUpdated.
  ///
  /// In en, this message translates to:
  /// **'Progress updated'**
  String get progressUpdated;

  /// No description provided for @enterAStepName.
  ///
  /// In en, this message translates to:
  /// **'Enter a step name'**
  String get enterAStepName;

  /// No description provided for @stepsHaveChangedReviewThemBeforeSaving.
  ///
  /// In en, this message translates to:
  /// **'Steps have changed. Review them before saving.'**
  String get stepsHaveChangedReviewThemBeforeSaving;

  /// No description provided for @stepName.
  ///
  /// In en, this message translates to:
  /// **'Step name'**
  String get stepName;

  /// No description provided for @discardEdits.
  ///
  /// In en, this message translates to:
  /// **'Discard edits'**
  String get discardEdits;

  /// No description provided for @saveStep.
  ///
  /// In en, this message translates to:
  /// **'Save step'**
  String get saveStep;

  /// No description provided for @addStep.
  ///
  /// In en, this message translates to:
  /// **'Add step'**
  String get addStep;

  /// No description provided for @doneOrganizing.
  ///
  /// In en, this message translates to:
  /// **'Done organizing'**
  String get doneOrganizing;

  /// No description provided for @organize.
  ///
  /// In en, this message translates to:
  /// **'Organize'**
  String get organize;

  /// No description provided for @moveStepUp.
  ///
  /// In en, this message translates to:
  /// **'Move step {v0} up'**
  String moveStepUp(Object v0);

  /// No description provided for @moveStepDown.
  ///
  /// In en, this message translates to:
  /// **'Move step {v0} down'**
  String moveStepDown(Object v0);

  /// No description provided for @deleteStep.
  ///
  /// In en, this message translates to:
  /// **'Delete step {v0}'**
  String deleteStep(Object v0);

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get nextStep;

  /// No description provided for @nextStepRow.
  ///
  /// In en, this message translates to:
  /// **', next step'**
  String get nextStepRow;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step {v0}, {v1}{v2}'**
  String step(Object v0, Object v1, Object v2);

  /// No description provided for @tagName.
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get tagName;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @pendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingLabel;

  /// No description provided for @todayDuesmartlabel.
  ///
  /// In en, this message translates to:
  /// **'Today{v0}'**
  String todayDuesmartlabel(Object v0);

  /// No description provided for @tomorrowDuesmartlabel.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow{v0}'**
  String tomorrowDuesmartlabel(Object v0);

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday{v0}'**
  String yesterday(Object v0);

  /// No description provided for @formattedValueDuesmartlabel.
  ///
  /// In en, this message translates to:
  /// **'{v0}/{v1}{v2}'**
  String formattedValueDuesmartlabel(Object v0, Object v1, Object v2);

  /// No description provided for @overdueDuebadgelabel.
  ///
  /// In en, this message translates to:
  /// **'Overdue {v0}'**
  String overdueDuebadgelabel(Object v0);

  /// No description provided for @daysOverdue.
  ///
  /// In en, this message translates to:
  /// **'{v0, plural, =1{1 day overdue} other{{v0} days overdue}}'**
  String daysOverdue(int v0);

  /// No description provided for @hoursOverdue.
  ///
  /// In en, this message translates to:
  /// **'{v0, plural, =1{1 hour overdue} other{{v0} hours overdue}}'**
  String hoursOverdue(int v0);

  /// No description provided for @justOverdue.
  ///
  /// In en, this message translates to:
  /// **'Just overdue'**
  String get justOverdue;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{v0, plural, =1{1 day left} other{{v0} days left}}'**
  String daysLeft(int v0);

  /// No description provided for @hoursLeft.
  ///
  /// In en, this message translates to:
  /// **'{v0, plural, =1{1 hour left} other{{v0} hours left}}'**
  String hoursLeft(int v0);

  /// No description provided for @minutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{v0, plural, =1{1 minute left} other{{v0} minutes left}}'**
  String minutesLeft(int v0);

  /// No description provided for @todayRelativetimelabel.
  ///
  /// In en, this message translates to:
  /// **'Today {v0}'**
  String todayRelativetimelabel(Object v0);

  /// No description provided for @yesterdayRelativetimelabel.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {v0}'**
  String yesterdayRelativetimelabel(Object v0);

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @everySummary.
  ///
  /// In en, this message translates to:
  /// **'Every {v0}'**
  String everySummary(Object v0);

  /// No description provided for @everySummary2.
  ///
  /// In en, this message translates to:
  /// **'Every {v0} {v1}'**
  String everySummary2(Object v0, Object v1);

  /// No description provided for @formattedValueSummary.
  ///
  /// In en, this message translates to:
  /// **'{v0}'**
  String formattedValueSummary(Object v0);

  /// No description provided for @daySummary.
  ///
  /// In en, this message translates to:
  /// **', day {v0}'**
  String daySummary(Object v0);

  /// No description provided for @neverEnds.
  ///
  /// In en, this message translates to:
  /// **'Never ends'**
  String get neverEnds;

  /// No description provided for @occurrences.
  ///
  /// In en, this message translates to:
  /// **'{v0} occurrences'**
  String occurrences(Object v0);

  /// No description provided for @endsSummary.
  ///
  /// In en, this message translates to:
  /// **'Ends {v1}/{v2}/{v0}'**
  String endsSummary(Object v0, Object v1, Object v2);

  /// No description provided for @doesNotRepeat.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get doesNotRepeat;

  /// No description provided for @customRule.
  ///
  /// In en, this message translates to:
  /// **'Custom rule'**
  String get customRule;

  /// No description provided for @minBeforeDue.
  ///
  /// In en, this message translates to:
  /// **'{v0} min before due'**
  String minBeforeDue(Object v0);

  /// No description provided for @hrBeforeDue.
  ///
  /// In en, this message translates to:
  /// **'{v0} hr before due'**
  String hrBeforeDue(Object v0);

  /// No description provided for @hrMinBeforeDue.
  ///
  /// In en, this message translates to:
  /// **'{v0} hr {v1} min before due'**
  String hrMinBeforeDue(Object v0, Object v1);

  /// No description provided for @daysBeforeDue.
  ///
  /// In en, this message translates to:
  /// **'{v0} days before due'**
  String daysBeforeDue(Object v0);

  /// No description provided for @daysHrBeforeDue.
  ///
  /// In en, this message translates to:
  /// **'{v0} days {v1} hr before due'**
  String daysHrBeforeDue(Object v0, Object v1);

  /// No description provided for @customRemindrulelabel.
  ///
  /// In en, this message translates to:
  /// **'{v0}/{v1} {v2} (custom)'**
  String customRemindrulelabel(Object v0, Object v1, Object v2);

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// No description provided for @avatar.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get avatar;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @formattedValueBuild2.
  ///
  /// In en, this message translates to:
  /// **'{v1}/{v0}'**
  String formattedValueBuild2(Object v0, Object v1);

  /// No description provided for @previousWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get previousWeek;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get nextWeek;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @tasksBuild.
  ///
  /// In en, this message translates to:
  /// **', tasks: {v0}'**
  String tasksBuild(Object v0);

  /// No description provided for @formattedValueBuild3.
  ///
  /// In en, this message translates to:
  /// **'{v1}/{v2}/{v0}{v3}'**
  String formattedValueBuild3(Object v0, Object v1, Object v2, Object v3);

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @collapseSidebar.
  ///
  /// In en, this message translates to:
  /// **'Collapse sidebar'**
  String get collapseSidebar;

  /// No description provided for @copyReply.
  ///
  /// In en, this message translates to:
  /// **'Copy reply'**
  String get copyReply;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get saving;

  /// No description provided for @subscriptionTier.
  ///
  /// In en, this message translates to:
  /// **'Subscription tier {v0}'**
  String subscriptionTier(Object v0);

  /// No description provided for @inDevelopment.
  ///
  /// In en, this message translates to:
  /// **'In development'**
  String get inDevelopment;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @newType.
  ///
  /// In en, this message translates to:
  /// **'New type'**
  String get newType;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **', items: {v0}'**
  String items(Object v0);

  /// No description provided for @savingTryAgainShortly.
  ///
  /// In en, this message translates to:
  /// **'Saving. Try again shortly.'**
  String get savingTryAgainShortly;

  /// No description provided for @recordChangedReopenAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Record changed. Reopen and try again.'**
  String get recordChangedReopenAndTryAgain;

  /// No description provided for @actionAlreadySubmittedCheckTheLatestRecord.
  ///
  /// In en, this message translates to:
  /// **'Action already submitted. Check the latest record.'**
  String get actionAlreadySubmittedCheckTheLatestRecord;

  /// No description provided for @invalidContentOrCategoryRelationshipCheckAnd.
  ///
  /// In en, this message translates to:
  /// **'Invalid content or category relationship. Check and try again.'**
  String get invalidContentOrCategoryRelationshipCheckAnd;

  /// No description provided for @recordNoLongerExistsRefreshAndTry.
  ///
  /// In en, this message translates to:
  /// **'Record no longer exists. Refresh and try again.'**
  String get recordNoLongerExistsRefreshAndTry;

  /// No description provided for @couldntSaveYourDataIsSafeTry.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save. Your data is safe. Try again.'**
  String get couldntSaveYourDataIsSafeTry;

  /// No description provided for @webToolsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Web tools, monthly'**
  String get webToolsMonthly;

  /// No description provided for @dailyOrder.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailyOrder;

  /// No description provided for @quota.
  ///
  /// In en, this message translates to:
  /// **'Quota'**
  String get quota;

  /// No description provided for @periodQuota.
  ///
  /// In en, this message translates to:
  /// **'Period quota'**
  String get periodQuota;

  /// No description provided for @hoursOrder.
  ///
  /// In en, this message translates to:
  /// **'5 hours'**
  String get hoursOrder;

  /// No description provided for @tasksAndDailyDigest.
  ///
  /// In en, this message translates to:
  /// **'Tasks and daily digest'**
  String get tasksAndDailyDigest;

  /// No description provided for @yourTaskRemindersAndDailyDigests.
  ///
  /// In en, this message translates to:
  /// **'Your task reminders and daily digests'**
  String get yourTaskRemindersAndDailyDigests;

  /// No description provided for @textFiles.
  ///
  /// In en, this message translates to:
  /// **'Text files'**
  String get textFiles;

  /// No description provided for @chooseAValidTopLevelCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a valid top-level category'**
  String get chooseAValidTopLevelCategory;

  /// No description provided for @invalidChatForThisMessage.
  ///
  /// In en, this message translates to:
  /// **'Invalid chat for this message'**
  String get invalidChatForThisMessage;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get newChat;

  /// No description provided for @chatNotFound.
  ///
  /// In en, this message translates to:
  /// **'Chat not found'**
  String get chatNotFound;

  /// No description provided for @messageIdAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Message ID already exists'**
  String get messageIdAlreadyExists;

  /// No description provided for @messageIdBelongsToAnotherChat.
  ///
  /// In en, this message translates to:
  /// **'Message ID belongs to another chat'**
  String get messageIdBelongsToAnotherChat;

  /// No description provided for @messagesCantBeMovedBetweenChats.
  ///
  /// In en, this message translates to:
  /// **'Messages can’t be moved between chats'**
  String get messagesCantBeMovedBetweenChats;

  /// No description provided for @chatName.
  ///
  /// In en, this message translates to:
  /// **'Chat name'**
  String get chatName;

  /// No description provided for @typeAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Type already exists'**
  String get typeAlreadyExists;

  /// No description provided for @tableName.
  ///
  /// In en, this message translates to:
  /// **'Table name'**
  String get tableName;

  /// No description provided for @fieldNotFound.
  ///
  /// In en, this message translates to:
  /// **'Field not found'**
  String get fieldNotFound;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Field name'**
  String get fieldName;

  /// No description provided for @provideAValueForExistingRecordsBefore.
  ///
  /// In en, this message translates to:
  /// **'Provide a value for existing records before requiring this field'**
  String get provideAValueForExistingRecordsBefore;

  /// No description provided for @keepAtLeastOneField.
  ///
  /// In en, this message translates to:
  /// **'Keep at least one field'**
  String get keepAtLeastOneField;

  /// No description provided for @aTableWithThisIdentifierAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A table with this identifier already exists'**
  String get aTableWithThisIdentifierAlreadyExists;

  /// No description provided for @invalidOrDuplicateRowId.
  ///
  /// In en, this message translates to:
  /// **'Invalid or duplicate row ID'**
  String get invalidOrDuplicateRowId;

  /// No description provided for @thisRecordAlreadyExistsAndCantBe.
  ///
  /// In en, this message translates to:
  /// **'This record already exists and can’t be restored over it'**
  String get thisRecordAlreadyExistsAndCantBe;

  /// No description provided for @recordDeleted.
  ///
  /// In en, this message translates to:
  /// **'Record deleted'**
  String get recordDeleted;

  /// No description provided for @analysisOfHoldingsPng.
  ///
  /// In en, this message translates to:
  /// **'Analysis of “Holdings_0921.png”'**
  String get analysisOfHoldingsPng;

  /// No description provided for @nameNewTableSheet.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameNewTableSheet;

  /// No description provided for @kweichowMoutai.
  ///
  /// In en, this message translates to:
  /// **'Kweichow Moutai'**
  String get kweichowMoutai;

  /// No description provided for @sharesHeld.
  ///
  /// In en, this message translates to:
  /// **'Shares held'**
  String get sharesHeld;

  /// No description provided for @currentPrice.
  ///
  /// In en, this message translates to:
  /// **'Current price'**
  String get currentPrice;

  /// No description provided for @byd.
  ///
  /// In en, this message translates to:
  /// **'BYD'**
  String get byd;

  /// No description provided for @newRecord.
  ///
  /// In en, this message translates to:
  /// **'New record'**
  String get newRecord;

  /// No description provided for @theseAiChangesHaveBeenProcessedReopen.
  ///
  /// In en, this message translates to:
  /// **'These AI changes have been processed. Reopen the pending record.'**
  String get theseAiChangesHaveBeenProcessedReopen;

  /// No description provided for @theSelectedChangeNoLongerExists.
  ///
  /// In en, this message translates to:
  /// **'The selected change no longer exists'**
  String get theSelectedChangeNoLongerExists;

  /// No description provided for @recordDeletedOrMovedToAnotherTable.
  ///
  /// In en, this message translates to:
  /// **'Record deleted or moved to another table. Review again.'**
  String get recordDeletedOrMovedToAnotherTable;

  /// No description provided for @aChangeCannotIncludeTheSameField.
  ///
  /// In en, this message translates to:
  /// **'A change cannot include the same field twice'**
  String get aChangeCannotIncludeTheSameField;

  /// No description provided for @incompleteDeletionSnapshotReviewAgain.
  ///
  /// In en, this message translates to:
  /// **'Incomplete deletion snapshot. Review again.'**
  String get incompleteDeletionSnapshotReviewAgain;

  /// No description provided for @recordUpdatedReviewTheAiChangesAgain.
  ///
  /// In en, this message translates to:
  /// **'Record updated. Review the AI changes again.'**
  String get recordUpdatedReviewTheAiChangesAgain;

  /// No description provided for @recordChangedSinceThisAiUpdateUndo.
  ///
  /// In en, this message translates to:
  /// **'Record changed since this AI update. Undo is unavailable.'**
  String get recordChangedSinceThisAiUpdateUndo;

  /// No description provided for @tableMissingOrArchived.
  ///
  /// In en, this message translates to:
  /// **'Table missing or archived'**
  String get tableMissingOrArchived;

  /// No description provided for @dataTypeNoLongerExistsChooseAgain.
  ///
  /// In en, this message translates to:
  /// **'Data type no longer exists. Choose again.'**
  String get dataTypeNoLongerExistsChooseAgain;

  /// No description provided for @invalidOrDuplicateDataTypeName.
  ///
  /// In en, this message translates to:
  /// **'Invalid or duplicate data type name'**
  String get invalidOrDuplicateDataTypeName;

  /// No description provided for @tableTypeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Table type not found'**
  String get tableTypeNotFound;

  /// No description provided for @parentTableNotFoundForRow.
  ///
  /// In en, this message translates to:
  /// **'Parent table not found for row'**
  String get parentTableNotFoundForRow;

  /// No description provided for @parentTableNotFoundForAiBatch.
  ///
  /// In en, this message translates to:
  /// **'Parent table not found for AI batch'**
  String get parentTableNotFoundForAiBatch;

  /// No description provided for @typeName.
  ///
  /// In en, this message translates to:
  /// **'Type name'**
  String get typeName;

  /// No description provided for @useUpToCharactersForTheType.
  ///
  /// In en, this message translates to:
  /// **'Use up to 24 characters for the type name'**
  String get useUpToCharactersForTheType;

  /// No description provided for @addAtLeastOneField.
  ///
  /// In en, this message translates to:
  /// **'Add at least one field'**
  String get addAtLeastOneField;

  /// No description provided for @fieldNamesCannotBeEmptyOrBegin.
  ///
  /// In en, this message translates to:
  /// **'Field names cannot be empty or begin or end with whitespace'**
  String get fieldNamesCannotBeEmptyOrBegin;

  /// No description provided for @fieldNamesMustBeUnique.
  ///
  /// In en, this message translates to:
  /// **'Field names must be unique'**
  String get fieldNamesMustBeUnique;

  /// No description provided for @requiresAtLeastOneOption.
  ///
  /// In en, this message translates to:
  /// **'“{v0}” requires at least one option'**
  String requiresAtLeastOneOption(Object v0);

  /// No description provided for @optionsForCannotBeBlankOrBegin.
  ///
  /// In en, this message translates to:
  /// **'Options for “{v0}” cannot be blank or begin or end with whitespace'**
  String optionsForCannotBeBlankOrBegin(Object v0);

  /// No description provided for @optionsForMustBeUnique.
  ///
  /// In en, this message translates to:
  /// **'Options for “{v0}” must be unique'**
  String optionsForMustBeUnique(Object v0);

  /// No description provided for @dataContainsAnUndefinedField.
  ///
  /// In en, this message translates to:
  /// **'Data contains an undefined field: “{v0}”'**
  String dataContainsAnUndefinedField(Object v0);

  /// No description provided for @isRequired.
  ///
  /// In en, this message translates to:
  /// **'“{v0}” is required'**
  String isRequired(Object v0);

  /// No description provided for @aFiniteNumber.
  ///
  /// In en, this message translates to:
  /// **'a finite number'**
  String get aFiniteNumber;

  /// No description provided for @aValidDateYyyyMmDd.
  ///
  /// In en, this message translates to:
  /// **'a valid date (yyyy-MM-dd)'**
  String get aValidDateYyyyMmDd;

  /// No description provided for @aValidDateAndTimeYyyyMm.
  ///
  /// In en, this message translates to:
  /// **'a valid date and time (yyyy-MM-dd HH:mm)'**
  String get aValidDateAndTimeYyyyMm;

  /// No description provided for @anExistingOption.
  ///
  /// In en, this message translates to:
  /// **'an existing option'**
  String get anExistingOption;

  /// No description provided for @trueOrFalse.
  ///
  /// In en, this message translates to:
  /// **'true or false'**
  String get trueOrFalse;

  /// No description provided for @mustBe.
  ///
  /// In en, this message translates to:
  /// **'“{v0}” must be {v1}'**
  String mustBe(Object v0, Object v1);

  /// No description provided for @memoryContent.
  ///
  /// In en, this message translates to:
  /// **'Memory content'**
  String get memoryContent;

  /// No description provided for @memoryType.
  ///
  /// In en, this message translates to:
  /// **'Memory type'**
  String get memoryType;

  /// No description provided for @useUpToCharactersForTheTypeName.
  ///
  /// In en, this message translates to:
  /// **'Use up to 20 characters for the type name'**
  String get useUpToCharactersForTheTypeName;

  /// No description provided for @endDateCannotPrecedeStartDate.
  ///
  /// In en, this message translates to:
  /// **'End date cannot precede start date'**
  String get endDateCannotPrecedeStartDate;

  /// No description provided for @reportGenerationFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Report generation failed. Try again.'**
  String get reportGenerationFailedTryAgain;

  /// No description provided for @weeklyReport.
  ///
  /// In en, this message translates to:
  /// **'Weekly report'**
  String get weeklyReport;

  /// No description provided for @monthlyReport.
  ///
  /// In en, this message translates to:
  /// **'Monthly report'**
  String get monthlyReport;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @investing.
  ///
  /// In en, this message translates to:
  /// **'Investing'**
  String get investing;

  /// No description provided for @archives.
  ///
  /// In en, this message translates to:
  /// **'Archives'**
  String get archives;

  /// No description provided for @family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get family;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'## Overview'**
  String get overview;

  /// No description provided for @scope.
  ///
  /// In en, this message translates to:
  /// **'Scope: {v0}.'**
  String scope(Object v0);

  /// No description provided for @recordIdsCannotBeEmptyOrDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Record IDs cannot be empty or duplicated'**
  String get recordIdsCannotBeEmptyOrDuplicated;

  /// No description provided for @isRequiredRequiretext.
  ///
  /// In en, this message translates to:
  /// **'{v0} is required'**
  String isRequiredRequiretext(Object v0);

  /// No description provided for @taskIdAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Task ID already exists'**
  String get taskIdAlreadyExists;

  /// No description provided for @quotaExhausted.
  ///
  /// In en, this message translates to:
  /// **'Quota exhausted'**
  String get quotaExhausted;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests'**
  String get tooManyRequests;

  /// No description provided for @invalidKey.
  ///
  /// In en, this message translates to:
  /// **'Invalid key'**
  String get invalidKey;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get accessDenied;

  /// No description provided for @modelUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Model unavailable'**
  String get modelUnavailable;

  /// No description provided for @serviceTemporarilyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Service temporarily unavailable'**
  String get serviceTemporarilyUnavailable;

  /// No description provided for @alwaysAsk.
  ///
  /// In en, this message translates to:
  /// **'Always ask'**
  String get alwaysAsk;

  /// No description provided for @askBeforeTheAiChangesTasksOr.
  ///
  /// In en, this message translates to:
  /// **'Ask before the AI changes tasks or tables'**
  String get askBeforeTheAiChangesTasksOr;

  /// No description provided for @smartConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Smart confirmation'**
  String get smartConfirmation;

  /// No description provided for @applyTaskAdditionsEditsAndCompletionsImmediately.
  ///
  /// In en, this message translates to:
  /// **'Apply task additions, edits and completions immediately. Confirm deletions and table changes.'**
  String get applyTaskAdditionsEditsAndCompletionsImmediately;

  /// No description provided for @runAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Run automatically'**
  String get runAutomatically;

  /// No description provided for @applyTaskChangesAndKeepAHistory.
  ///
  /// In en, this message translates to:
  /// **'Apply task changes and keep a history. Confirm table changes.'**
  String get applyTaskChangesAndKeepAHistory;

  /// No description provided for @kimiCodeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Kimi Code subscription'**
  String get kimiCodeSubscription;

  /// No description provided for @kimiKHighspeed.
  ///
  /// In en, this message translates to:
  /// **'Kimi K2.8 HighSpeed'**
  String get kimiKHighspeed;

  /// No description provided for @glmCodingPlanSubscription.
  ///
  /// In en, this message translates to:
  /// **'GLM Coding Plan subscription'**
  String get glmCodingPlanSubscription;

  /// No description provided for @thisPlanIsRestrictedToSupportedCoding.
  ///
  /// In en, this message translates to:
  /// **'This plan is restricted to supported coding tools. Other clients may be throttled or disabled.'**
  String get thisPlanIsRestrictedToSupportedCoding;

  /// No description provided for @deepseekPlatform.
  ///
  /// In en, this message translates to:
  /// **'DeepSeek Platform'**
  String get deepseekPlatform;

  /// No description provided for @kimiPlatform.
  ///
  /// In en, this message translates to:
  /// **'Kimi Platform'**
  String get kimiPlatform;

  /// No description provided for @zhipuGlmPlatform.
  ///
  /// In en, this message translates to:
  /// **'Zhipu GLM Platform'**
  String get zhipuGlmPlatform;

  /// No description provided for @zhipuGlm.
  ///
  /// In en, this message translates to:
  /// **'Zhipu GLM'**
  String get zhipuGlm;

  /// No description provided for @openaiCompatibleApi.
  ///
  /// In en, this message translates to:
  /// **'OpenAI-compatible API'**
  String get openaiCompatibleApi;

  /// No description provided for @fact.
  ///
  /// In en, this message translates to:
  /// **'Fact'**
  String get fact;

  /// No description provided for @preference.
  ///
  /// In en, this message translates to:
  /// **'Preference'**
  String get preference;

  /// No description provided for @event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @intentRecognition.
  ///
  /// In en, this message translates to:
  /// **'Intent recognition'**
  String get intentRecognition;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @reportGeneration.
  ///
  /// In en, this message translates to:
  /// **'Report generation'**
  String get reportGeneration;

  /// No description provided for @screenshotAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Screenshot analysis'**
  String get screenshotAnalysis;

  /// No description provided for @stepsStepprogress.
  ///
  /// In en, this message translates to:
  /// **'Steps {v0}/{v1}'**
  String stepsStepprogress(Object v0, Object v1);

  /// No description provided for @dueEarlierUnfinished.
  ///
  /// In en, this message translates to:
  /// **'{v0}/{v1}: {v2} due, {v3} overdue. '**
  String dueEarlierUnfinished(Object v0, Object v1, Object v2, Object v3);

  /// No description provided for @scheduledSnapshotOpenForTheLatest.
  ///
  /// In en, this message translates to:
  /// **'{v0}Open for the latest.'**
  String scheduledSnapshotOpenForTheLatest(Object v0);

  /// No description provided for @taskReminder.
  ///
  /// In en, this message translates to:
  /// **'Task reminder'**
  String get taskReminder;

  /// No description provided for @dailyTaskDigest.
  ///
  /// In en, this message translates to:
  /// **'Daily task digest'**
  String get dailyTaskDigest;

  /// No description provided for @unknownVersion.
  ///
  /// In en, this message translates to:
  /// **'Unknown version'**
  String get unknownVersion;

  /// No description provided for @restoreBaseVersion.
  ///
  /// In en, this message translates to:
  /// **'Restore base version'**
  String get restoreBaseVersion;

  /// No description provided for @patchP.
  ///
  /// In en, this message translates to:
  /// **'Patch P{v0}'**
  String patchP(Object v0);

  /// No description provided for @exitReorderMode.
  ///
  /// In en, this message translates to:
  /// **'Exit reorder mode'**
  String get exitReorderMode;

  /// No description provided for @reorderCategories.
  ///
  /// In en, this message translates to:
  /// **'Reorder categories'**
  String get reorderCategories;

  /// No description provided for @finishReordering.
  ///
  /// In en, this message translates to:
  /// **'Finish reordering'**
  String get finishReordering;

  /// No description provided for @inUse.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get inUse;

  /// No description provided for @allCategoriesArchived.
  ///
  /// In en, this message translates to:
  /// **'All categories archived'**
  String get allCategoriesArchived;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories'**
  String get noCategories;

  /// No description provided for @createSampleCategories.
  ///
  /// In en, this message translates to:
  /// **'Create sample categories'**
  String get createSampleCategories;

  /// No description provided for @createsInvestingArchivesAndFamily.
  ///
  /// In en, this message translates to:
  /// **'Creates Investing, Archives and Family'**
  String get createsInvestingArchivesAndFamily;

  /// No description provided for @archivedTapToCollapse.
  ///
  /// In en, this message translates to:
  /// **'Archived, tap to collapse'**
  String get archivedTapToCollapse;

  /// No description provided for @archivedTapToExpand.
  ///
  /// In en, this message translates to:
  /// **'Archived, tap to expand'**
  String get archivedTapToExpand;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived: {v0}'**
  String archived(Object v0);

  /// No description provided for @dropBetweenTopLevelRowsToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drop between top-level rows to reorder or promote'**
  String get dropBetweenTopLevelRowsToReorder;

  /// No description provided for @dropOntoATopLevelRowTo.
  ///
  /// In en, this message translates to:
  /// **'Drop onto a top-level row to make a subcategory'**
  String get dropOntoATopLevelRowTo;

  /// No description provided for @upToTwoCategoryLevels.
  ///
  /// In en, this message translates to:
  /// **'Up to two category levels'**
  String get upToTwoCategoryLevels;

  /// No description provided for @restoredOpenarchivedactions.
  ///
  /// In en, this message translates to:
  /// **'“{v0}” restored'**
  String restoredOpenarchivedactions(Object v0);

  /// No description provided for @archivedAndHiddenWhenCreatingTasks.
  ///
  /// In en, this message translates to:
  /// **'“{v0}” archived and hidden when creating tasks'**
  String archivedAndHiddenWhenCreatingTasks(Object v0);

  /// No description provided for @deletedEditcategory.
  ///
  /// In en, this message translates to:
  /// **'Deleted “{v0}”'**
  String deletedEditcategory(Object v0);

  /// No description provided for @completionRateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Completion rate unknown'**
  String get completionRateUnknown;

  /// No description provided for @completeSemanticslabel.
  ///
  /// In en, this message translates to:
  /// **'{v0}% complete'**
  String completeSemanticslabel(Object v0);

  /// No description provided for @archivedCategoryTasksDoubleTapForRestore.
  ///
  /// In en, this message translates to:
  /// **'Archived category {v0}, {v1} tasks. Double-tap for restore options.'**
  String archivedCategoryTasksDoubleTapForRestore(Object v0, Object v1);

  /// No description provided for @subcategoryTasks.
  ///
  /// In en, this message translates to:
  /// **'Subcategory {v0}, {v1} tasks, {v2}'**
  String subcategoryTasks(Object v0, Object v1, Object v2);

  /// No description provided for @categoryTasks.
  ///
  /// In en, this message translates to:
  /// **'Category {v0}, {v1} tasks, {v2}'**
  String categoryTasks(Object v0, Object v1, Object v2);

  /// No description provided for @subcategoriesExpanded.
  ///
  /// In en, this message translates to:
  /// **', subcategories expanded'**
  String get subcategoriesExpanded;

  /// No description provided for @subcategoriesCollapsed.
  ///
  /// In en, this message translates to:
  /// **', subcategories collapsed'**
  String get subcategoriesCollapsed;

  /// No description provided for @doubleTapToEditHoldAndDrag.
  ///
  /// In en, this message translates to:
  /// **'. Double-tap to edit. Hold and drag to reorder.'**
  String get doubleTapToEditHoldAndDrag;

  /// No description provided for @collapseSubcategories.
  ///
  /// In en, this message translates to:
  /// **'Collapse subcategories'**
  String get collapseSubcategories;

  /// No description provided for @expandSubcategories.
  ///
  /// In en, this message translates to:
  /// **'Expand subcategories'**
  String get expandSubcategories;

  /// No description provided for @itemsStats.
  ///
  /// In en, this message translates to:
  /// **'{v0} items —'**
  String itemsStats(Object v0);

  /// No description provided for @itemsStats2.
  ///
  /// In en, this message translates to:
  /// **'{v0} items '**
  String itemsStats2(Object v0);

  /// No description provided for @moreActionsFor.
  ///
  /// In en, this message translates to:
  /// **'More actions for {v0}'**
  String moreActionsFor(Object v0);

  /// No description provided for @itemsBuild.
  ///
  /// In en, this message translates to:
  /// **'{v0, plural, =1{1 item} other{{v0} items}}'**
  String itemsBuild(num v0);

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **' Advanced'**
  String get advanced;

  /// No description provided for @couldntReplyTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t reply. Try again.'**
  String get couldntReplyTryAgain;

  /// No description provided for @couldntRefreshLocalChatsShowingTheLast.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t refresh local chats. Showing the last saved content.'**
  String get couldntRefreshLocalChatsShowingTheLast;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @renameChat.
  ///
  /// In en, this message translates to:
  /// **'Rename chat'**
  String get renameChat;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @deleteThisChat.
  ///
  /// In en, this message translates to:
  /// **'Delete this chat?'**
  String get deleteThisChat;

  /// No description provided for @tasksCreatedInThisChatWillBe.
  ///
  /// In en, this message translates to:
  /// **'Tasks created in this chat will be kept.'**
  String get tasksCreatedInThisChatWillBe;

  /// No description provided for @deleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete chat'**
  String get deleteChat;

  /// No description provided for @hiWhatsOnYourListToday.
  ///
  /// In en, this message translates to:
  /// **'Hi {v0}, what’s on your list today?'**
  String hiWhatsOnYourListToday(Object v0);

  /// No description provided for @replyIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Reply incomplete'**
  String get replyIncomplete;

  /// No description provided for @voiceInputInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Voice input interrupted'**
  String get voiceInputInterrupted;

  /// No description provided for @couldntStartVoiceInput.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t start voice input'**
  String get couldntStartVoiceInput;

  /// No description provided for @transcriptIsTooLongSplitItInto.
  ///
  /// In en, this message translates to:
  /// **'Transcript is too long. Split it into shorter requests.'**
  String get transcriptIsTooLongSplitItInto;

  /// No description provided for @couldntHearThatTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t hear that. Try again.'**
  String get couldntHearThatTryAgain;

  /// No description provided for @recognitionTimedOutTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Recognition timed out. Try again.'**
  String get recognitionTimedOutTryAgain;

  /// No description provided for @couldntSendYourTextIsSaved.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t send. Your text is saved.'**
  String get couldntSendYourTextIsSaved;

  /// No description provided for @allowMicrophoneAccessInSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Allow microphone access in system settings'**
  String get allowMicrophoneAccessInSystemSettings;

  /// No description provided for @selectedLanguageIsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Selected language is unavailable'**
  String get selectedLanguageIsUnavailable;

  /// No description provided for @thisRecognizerDoesNotSupportOnDevice.
  ///
  /// In en, this message translates to:
  /// **'This recognizer does not support on-device mode. Network recognition is off.'**
  String get thisRecognizerDoesNotSupportOnDevice;

  /// No description provided for @couldntConnectToSpeechService.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t connect to speech service'**
  String get couldntConnectToSpeechService;

  /// No description provided for @microphoneInUse.
  ///
  /// In en, this message translates to:
  /// **'Microphone in use'**
  String get microphoneInUse;

  /// No description provided for @recordingInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Recording interrupted'**
  String get recordingInterrupted;

  /// No description provided for @voiceInputUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice input unavailable'**
  String get voiceInputUnavailable;

  /// No description provided for @notSentTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Not sent. Try again.'**
  String get notSentTryAgain;

  /// No description provided for @answered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get answered;

  /// No description provided for @chatContinued.
  ///
  /// In en, this message translates to:
  /// **'Chat continued'**
  String get chatContinued;

  /// No description provided for @addToYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Add to your answer'**
  String get addToYourAnswer;

  /// No description provided for @collapseAdditionalAnswer.
  ///
  /// In en, this message translates to:
  /// **'Collapse additional answer'**
  String get collapseAdditionalAnswer;

  /// No description provided for @addAnAnswer.
  ///
  /// In en, this message translates to:
  /// **'Add an answer'**
  String get addAnAnswer;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @otherAnswer.
  ///
  /// In en, this message translates to:
  /// **'Other answer'**
  String get otherAnswer;

  /// No description provided for @confirmAnswer.
  ///
  /// In en, this message translates to:
  /// **'Confirm answer'**
  String get confirmAnswer;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get sending;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @sendSelections.
  ///
  /// In en, this message translates to:
  /// **'Send {v0} selections'**
  String sendSelections(Object v0);

  /// No description provided for @undoTask.
  ///
  /// In en, this message translates to:
  /// **'Undo task'**
  String get undoTask;

  /// No description provided for @restoredToPending.
  ///
  /// In en, this message translates to:
  /// **'Restored to pending'**
  String get restoredToPending;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get previousPage;

  /// No description provided for @page.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get page;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get nextPage;

  /// No description provided for @moreItems.
  ///
  /// In en, this message translates to:
  /// **'{v0} more items'**
  String moreItems(Object v0);

  /// No description provided for @itemsRemoved.
  ///
  /// In en, this message translates to:
  /// **'{v0} items removed'**
  String itemsRemoved(Object v0);

  /// No description provided for @completeBuild.
  ///
  /// In en, this message translates to:
  /// **'{v0}/{v1} complete'**
  String completeBuild(Object v0, Object v1);

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View {v0}'**
  String view(Object v0);

  /// No description provided for @theTasksInThisListHaveBeen.
  ///
  /// In en, this message translates to:
  /// **'The tasks in this list have been removed'**
  String get theTasksInThisListHaveBeen;

  /// No description provided for @noTasksInThisRange.
  ///
  /// In en, this message translates to:
  /// **'No tasks in this range'**
  String get noTasksInThisRange;

  /// No description provided for @taskBuild.
  ///
  /// In en, this message translates to:
  /// **'{v0} task: {v1}'**
  String taskBuild(Object v0, Object v1);

  /// No description provided for @editTaskBuild.
  ///
  /// In en, this message translates to:
  /// **'Edit task: {v0}'**
  String editTaskBuild(Object v0);

  /// No description provided for @scrollToLatest.
  ///
  /// In en, this message translates to:
  /// **'Scroll to latest'**
  String get scrollToLatest;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @memory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get memory;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @collapseCategories.
  ///
  /// In en, this message translates to:
  /// **'Collapse categories'**
  String get collapseCategories;

  /// No description provided for @expandCategories.
  ///
  /// In en, this message translates to:
  /// **'Expand categories'**
  String get expandCategories;

  /// No description provided for @reorderCategoriesBuild.
  ///
  /// In en, this message translates to:
  /// **'Reorder categories'**
  String get reorderCategoriesBuild;

  /// No description provided for @chatHistory.
  ///
  /// In en, this message translates to:
  /// **'Chat history'**
  String get chatHistory;

  /// No description provided for @noChatsYet.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get noChatsYet;

  /// No description provided for @toggleLightOrDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Toggle light or dark theme'**
  String get toggleLightOrDarkTheme;

  /// No description provided for @editCategorylist.
  ///
  /// In en, this message translates to:
  /// **'Edit {v0}'**
  String editCategorylist(Object v0);

  /// No description provided for @dragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder {v0}'**
  String dragToReorder(Object v0);

  /// No description provided for @expandSubcategoriesOf.
  ///
  /// In en, this message translates to:
  /// **'Expand subcategories of {v0}'**
  String expandSubcategoriesOf(Object v0);

  /// No description provided for @yesterdayGroup.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterdayGroup;

  /// No description provided for @lastDays.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get lastDays;

  /// No description provided for @earlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get earlier;

  /// No description provided for @openMenu.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get openMenu;

  /// No description provided for @searchChatsAndTasks.
  ///
  /// In en, this message translates to:
  /// **'Search chats and tasks'**
  String get searchChatsAndTasks;

  /// No description provided for @openDailyOverview.
  ///
  /// In en, this message translates to:
  /// **'Open daily overview'**
  String get openDailyOverview;

  /// No description provided for @newChatBuild.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get newChatBuild;

  /// No description provided for @chatOptions.
  ///
  /// In en, this message translates to:
  /// **'Chat options'**
  String get chatOptions;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image “{v0}”:'**
  String image(Object v0);

  /// No description provided for @takeALookAtThisImage.
  ///
  /// In en, this message translates to:
  /// **'Take a look at this image'**
  String get takeALookAtThisImage;

  /// No description provided for @contentTruncated.
  ///
  /// In en, this message translates to:
  /// **'{v0}\n… (content truncated)'**
  String contentTruncated(Object v0);

  /// No description provided for @contentsOf.
  ///
  /// In en, this message translates to:
  /// **'Contents of “{v0}”:\n{v1}'**
  String contentsOf(Object v0, Object v1);

  /// No description provided for @contentsOfSubmitwithattachment.
  ///
  /// In en, this message translates to:
  /// **'{v0}\n\nContents of “{v1}”:\n{v2}'**
  String contentsOfSubmitwithattachment(Object v0, Object v1, Object v2);

  /// No description provided for @connectAnAccountInModelsAndUsage.
  ///
  /// In en, this message translates to:
  /// **'Connect an account in Models and usage first'**
  String get connectAnAccountInModelsAndUsage;

  /// No description provided for @addToChat.
  ///
  /// In en, this message translates to:
  /// **'Add to chat'**
  String get addToChat;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get chooseImage;

  /// No description provided for @fileTooLargeImagesUpToMb.
  ///
  /// In en, this message translates to:
  /// **'File too large. Images: up to 10 MB. Text: up to 512 KB.'**
  String get fileTooLargeImagesUpToMb;

  /// No description provided for @couldntReadTheImageChooseAStatic.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read the image. Choose a static PNG or JPEG.'**
  String get couldntReadTheImageChooseAStatic;

  /// No description provided for @couldntReadTheFileTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read the file. Try again.'**
  String get couldntReadTheFileTryAgain;

  /// No description provided for @holdToTranscribe.
  ///
  /// In en, this message translates to:
  /// **'Hold to transcribe'**
  String get holdToTranscribe;

  /// No description provided for @askAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask anything…'**
  String get askAnything;

  /// No description provided for @holdToRecordReleaseToSend.
  ///
  /// In en, this message translates to:
  /// **'Hold to record, release to send'**
  String get holdToRecordReleaseToSend;

  /// No description provided for @holdToTalk.
  ///
  /// In en, this message translates to:
  /// **'Hold to talk'**
  String get holdToTalk;

  /// No description provided for @stopGenerating.
  ///
  /// In en, this message translates to:
  /// **'Stop generating'**
  String get stopGenerating;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @switchToKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Switch to keyboard'**
  String get switchToKeyboard;

  /// No description provided for @switchToVoice.
  ///
  /// In en, this message translates to:
  /// **'Switch to voice'**
  String get switchToVoice;

  /// No description provided for @addAttachment.
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get addAttachment;

  /// No description provided for @attachmentToSend.
  ///
  /// In en, this message translates to:
  /// **'Attachment to send: {v0}'**
  String attachmentToSend(Object v0);

  /// No description provided for @removeAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment'**
  String get removeAttachment;

  /// No description provided for @tomorrowFormatdue.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow {v0}'**
  String tomorrowFormatdue(Object v0);

  /// No description provided for @dayAfterTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Day after tomorrow {v0}'**
  String dayAfterTomorrow(Object v0);

  /// No description provided for @formattedValueExportlabel.
  ///
  /// In en, this message translates to:
  /// **'{v0}/{v1} {v2}'**
  String formattedValueExportlabel(Object v0, Object v1, Object v2);

  /// No description provided for @monFormatrelative.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get monFormatrelative;

  /// No description provided for @tueFormatrelative.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tueFormatrelative;

  /// No description provided for @wedFormatrelative.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wedFormatrelative;

  /// No description provided for @thuFormatrelative.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thuFormatrelative;

  /// No description provided for @friFormatrelative.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get friFormatrelative;

  /// No description provided for @satFormatrelative.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get satFormatrelative;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @stopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stopped;

  /// No description provided for @thinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get thinking;

  /// No description provided for @connectModel.
  ///
  /// In en, this message translates to:
  /// **'Connect model'**
  String get connectModel;

  /// No description provided for @chooseModel.
  ///
  /// In en, this message translates to:
  /// **'Choose model'**
  String get chooseModel;

  /// No description provided for @chooseModelBuild.
  ///
  /// In en, this message translates to:
  /// **'Choose model, {v0}'**
  String chooseModelBuild(Object v0);

  /// No description provided for @couldntLoadModelSettings.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load model settings'**
  String get couldntLoadModelSettings;

  /// No description provided for @couldntSwitchModelsTurnAutomaticFallbackBack.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t switch models. Turn automatic fallback back on to retry.'**
  String get couldntSwitchModelsTurnAutomaticFallbackBack;

  /// No description provided for @couldntSwitchTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t switch. Try again later.'**
  String get couldntSwitchTryAgainLater;

  /// No description provided for @backToProviders.
  ///
  /// In en, this message translates to:
  /// **'Back to providers'**
  String get backToProviders;

  /// No description provided for @automaticFallback.
  ///
  /// In en, this message translates to:
  /// **'Automatic fallback'**
  String get automaticFallback;

  /// No description provided for @addModelAccount.
  ///
  /// In en, this message translates to:
  /// **'Add model account'**
  String get addModelAccount;

  /// No description provided for @manageAccounts.
  ///
  /// In en, this message translates to:
  /// **'Manage accounts'**
  String get manageAccounts;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account {v0} '**
  String account(Object v0);

  /// No description provided for @accountRemovedGoBackAndChooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Account removed. Go back and choose another.'**
  String get accountRemovedGoBackAndChooseAnother;

  /// No description provided for @deepThinking.
  ///
  /// In en, this message translates to:
  /// **'Deep thinking'**
  String get deepThinking;

  /// No description provided for @voiceInputFailedYourTranscriptIsSaved.
  ///
  /// In en, this message translates to:
  /// **'Voice input failed. Your transcript is saved.'**
  String get voiceInputFailedYourTranscriptIsSaved;

  /// No description provided for @taskUndone.
  ///
  /// In en, this message translates to:
  /// **'Task undone'**
  String get taskUndone;

  /// No description provided for @theTaskChangedAndCannotBeRestored.
  ///
  /// In en, this message translates to:
  /// **'The task changed and cannot be restored'**
  String get theTaskChangedAndCannotBeRestored;

  /// No description provided for @completedToggledone.
  ///
  /// In en, this message translates to:
  /// **'Completed {v0}'**
  String completedToggledone(Object v0);

  /// No description provided for @updatedEdittodo.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updatedEdittodo;

  /// No description provided for @nextWeekBuild.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get nextWeekBuild;

  /// No description provided for @preparingMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Preparing microphone'**
  String get preparingMicrophone;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recording;

  /// No description provided for @transcribingAudio.
  ///
  /// In en, this message translates to:
  /// **'Transcribing audio'**
  String get transcribingAudio;

  /// No description provided for @voiceReadyToSend.
  ///
  /// In en, this message translates to:
  /// **'Voice ready to send'**
  String get voiceReadyToSend;

  /// No description provided for @sendingVoiceInput.
  ///
  /// In en, this message translates to:
  /// **'Sending voice input'**
  String get sendingVoiceInput;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get typeAMessage;

  /// No description provided for @tapToTypeHoldToTranscribe.
  ///
  /// In en, this message translates to:
  /// **'Tap to type, hold to transcribe'**
  String get tapToTypeHoldToTranscribe;

  /// No description provided for @activateToDictateOrHoldToRecord.
  ///
  /// In en, this message translates to:
  /// **'Activate to dictate, or hold to record'**
  String get activateToDictateOrHoldToRecord;

  /// No description provided for @activateToFinishRecordingAndSendThe.
  ///
  /// In en, this message translates to:
  /// **'Activate to finish recording and send the transcript'**
  String get activateToFinishRecordingAndSendThe;

  /// No description provided for @cancelVoiceInputOrSwitchToThe.
  ///
  /// In en, this message translates to:
  /// **'Cancel voice input or switch to the keyboard'**
  String get cancelVoiceInputOrSwitchToThe;

  /// No description provided for @preparingToRecord.
  ///
  /// In en, this message translates to:
  /// **'Preparing to record'**
  String get preparingToRecord;

  /// No description provided for @releaseToCancel.
  ///
  /// In en, this message translates to:
  /// **'Release to cancel'**
  String get releaseToCancel;

  /// No description provided for @releaseToEdit.
  ///
  /// In en, this message translates to:
  /// **'Release to edit'**
  String get releaseToEdit;

  /// No description provided for @releaseToSend.
  ///
  /// In en, this message translates to:
  /// **'Release to send'**
  String get releaseToSend;

  /// No description provided for @transcribing.
  ///
  /// In en, this message translates to:
  /// **'Transcribing'**
  String get transcribing;

  /// No description provided for @sendingShortly.
  ///
  /// In en, this message translates to:
  /// **'Sending shortly'**
  String get sendingShortly;

  /// No description provided for @endRecording.
  ///
  /// In en, this message translates to:
  /// **'End recording'**
  String get endRecording;

  /// No description provided for @voiceInput.
  ///
  /// In en, this message translates to:
  /// **'Voice input'**
  String get voiceInput;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get listening;

  /// No description provided for @cancelVoiceInput.
  ///
  /// In en, this message translates to:
  /// **'Cancel voice input'**
  String get cancelVoiceInput;

  /// No description provided for @editTranscript.
  ///
  /// In en, this message translates to:
  /// **'Edit transcript'**
  String get editTranscript;

  /// No description provided for @offlineSpeechRecognition.
  ///
  /// In en, this message translates to:
  /// **'Offline speech recognition'**
  String get offlineSpeechRecognition;

  /// No description provided for @offlineModelReady.
  ///
  /// In en, this message translates to:
  /// **'Offline model ready'**
  String get offlineModelReady;

  /// No description provided for @startVoiceInput.
  ///
  /// In en, this message translates to:
  /// **'Start voice input'**
  String get startVoiceInput;

  /// No description provided for @transcribesOnThisDeviceWithTheBuilt.
  ///
  /// In en, this message translates to:
  /// **'Transcribes on this device with the built-in model, even offline.'**
  String get transcribesOnThisDeviceWithTheBuilt;

  /// No description provided for @installingTheBuiltInOfflineModel.
  ///
  /// In en, this message translates to:
  /// **'Installing the built-in offline model…'**
  String get installingTheBuiltInOfflineModel;

  /// No description provided for @downloadAboutMb.
  ///
  /// In en, this message translates to:
  /// **'Download (about {v0} MB)'**
  String downloadAboutMb(Object v0);

  /// No description provided for @cancelDownload.
  ///
  /// In en, this message translates to:
  /// **'Cancel download'**
  String get cancelDownload;

  /// No description provided for @retryDownload.
  ///
  /// In en, this message translates to:
  /// **'Retry download'**
  String get retryDownload;

  /// No description provided for @reinstallBuiltInModel.
  ///
  /// In en, this message translates to:
  /// **'Reinstall built-in model'**
  String get reinstallBuiltInModel;

  /// No description provided for @installBuiltInOfflineModel.
  ///
  /// In en, this message translates to:
  /// **'Install built-in offline model'**
  String get installBuiltInOfflineModel;

  /// No description provided for @downloadInsteadAboutMb.
  ///
  /// In en, this message translates to:
  /// **'Download instead (about {v0} MB)'**
  String downloadInsteadAboutMb(Object v0);

  /// No description provided for @downloadedOfMb.
  ///
  /// In en, this message translates to:
  /// **'Downloaded {v0} of {v1} MB'**
  String downloadedOfMb(Object v0, Object v1);

  /// No description provided for @modelsAndUsage.
  ///
  /// In en, this message translates to:
  /// **'Models and usage, {v0}'**
  String modelsAndUsage(Object v0);

  /// No description provided for @remainingBuild.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remainingBuild;

  /// No description provided for @closeSearch.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get closeSearch;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @goToChat.
  ///
  /// In en, this message translates to:
  /// **'Go to chat'**
  String get goToChat;

  /// No description provided for @analysisDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Analysis discarded'**
  String get analysisDiscarded;

  /// No description provided for @chooseFromPhotos.
  ///
  /// In en, this message translates to:
  /// **'Choose from photos'**
  String get chooseFromPhotos;

  /// No description provided for @rowAdded.
  ///
  /// In en, this message translates to:
  /// **'Row added'**
  String get rowAdded;

  /// No description provided for @exportedRowsTo.
  ///
  /// In en, this message translates to:
  /// **'Exported {v0} rows to {v1}'**
  String exportedRowsTo(Object v0, Object v1);

  /// No description provided for @exportFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Export failed. Try again.'**
  String get exportFailedTryAgain;

  /// No description provided for @changeType.
  ///
  /// In en, this message translates to:
  /// **'Change type'**
  String get changeType;

  /// No description provided for @manageFields.
  ///
  /// In en, this message translates to:
  /// **'Manage fields'**
  String get manageFields;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @archiveThisTable.
  ///
  /// In en, this message translates to:
  /// **'Archive this table?'**
  String get archiveThisTable;

  /// No description provided for @archivedTablesAreHiddenFromTheList.
  ///
  /// In en, this message translates to:
  /// **'Archived tables are hidden from the list. Their data is retained.'**
  String get archivedTablesAreHiddenFromTheList;

  /// No description provided for @deleteTable.
  ///
  /// In en, this message translates to:
  /// **'Delete table'**
  String get deleteTable;

  /// No description provided for @deleteThisTable.
  ///
  /// In en, this message translates to:
  /// **'Delete this table?'**
  String get deleteThisTable;

  /// No description provided for @youCanUndoTheDeletion.
  ///
  /// In en, this message translates to:
  /// **'You can undo the deletion.'**
  String get youCanUndoTheDeletion;

  /// No description provided for @alsoDeletesRowsYouCanUndoThe.
  ///
  /// In en, this message translates to:
  /// **'Also deletes {v0} rows. You can undo the deletion.'**
  String alsoDeletesRowsYouCanUndoThe(Object v0);

  /// No description provided for @renamedTo.
  ///
  /// In en, this message translates to:
  /// **'Renamed to “{v0}”'**
  String renamedTo(Object v0);

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @addedByMe.
  ///
  /// In en, this message translates to:
  /// **'Added by me'**
  String get addedByMe;

  /// No description provided for @addedByAi.
  ///
  /// In en, this message translates to:
  /// **'Added by AI'**
  String get addedByAi;

  /// No description provided for @recentlyUpdatedFirst.
  ///
  /// In en, this message translates to:
  /// **'Recently updated first'**
  String get recentlyUpdatedFirst;

  /// No description provided for @firstFieldAZ.
  ///
  /// In en, this message translates to:
  /// **'First field A–Z'**
  String get firstFieldAZ;

  /// No description provided for @firstFieldZA.
  ///
  /// In en, this message translates to:
  /// **'First field Z–A'**
  String get firstFieldZA;

  /// No description provided for @noMatchingRecords.
  ///
  /// In en, this message translates to:
  /// **'No matching records'**
  String get noMatchingRecords;

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for “{v0}”'**
  String noResultsFor(Object v0);

  /// No description provided for @adjustTheFiltersOrTryAnotherKeyword.
  ///
  /// In en, this message translates to:
  /// **'Adjust the filters or try another keyword'**
  String get adjustTheFiltersOrTryAnotherKeyword;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results: {v0}'**
  String results(Object v0);

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @tableUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Table unavailable'**
  String get tableUnavailable;

  /// No description provided for @itMayHaveBeenArchivedOrDeleted.
  ///
  /// In en, this message translates to:
  /// **'It may have been archived or deleted.'**
  String get itMayHaveBeenArchivedOrDeleted;

  /// No description provided for @backToList.
  ///
  /// In en, this message translates to:
  /// **'Back to list'**
  String get backToList;

  /// No description provided for @tableSettings.
  ///
  /// In en, this message translates to:
  /// **'Table settings'**
  String get tableSettings;

  /// No description provided for @importScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Import screenshot'**
  String get importScreenshot;

  /// No description provided for @newRow.
  ///
  /// In en, this message translates to:
  /// **'New row'**
  String get newRow;

  /// No description provided for @rows.
  ///
  /// In en, this message translates to:
  /// **'{v0, plural, =1{1 row} other{{v0} rows}}'**
  String rows(num v0);

  /// No description provided for @aiChangesAwaitingReview.
  ///
  /// In en, this message translates to:
  /// **'AI changes awaiting review'**
  String get aiChangesAwaitingReview;

  /// No description provided for @searchRows.
  ///
  /// In en, this message translates to:
  /// **'Search rows'**
  String get searchRows;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// No description provided for @createARow.
  ///
  /// In en, this message translates to:
  /// **'Create a row'**
  String get createARow;

  /// No description provided for @changeHistory.
  ///
  /// In en, this message translates to:
  /// **'Change history'**
  String get changeHistory;

  /// No description provided for @copyRow.
  ///
  /// In en, this message translates to:
  /// **'Copy row'**
  String get copyRow;

  /// No description provided for @rowCopied.
  ///
  /// In en, this message translates to:
  /// **'Row copied'**
  String get rowCopied;

  /// No description provided for @deleteThisRow.
  ///
  /// In en, this message translates to:
  /// **'Delete this row?'**
  String get deleteThisRow;

  /// No description provided for @willBeDeletedYouCanReviewIt.
  ///
  /// In en, this message translates to:
  /// **'“{v0}” will be deleted. You can review it in change history.'**
  String willBeDeletedYouCanReviewIt(Object v0);

  /// No description provided for @recordBuild.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get recordBuild;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'(Untitled)'**
  String get untitled;

  /// No description provided for @createdCreatetable.
  ///
  /// In en, this message translates to:
  /// **'Created “{v0}”'**
  String createdCreatetable(Object v0);

  /// No description provided for @createFromTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create from template'**
  String get createFromTemplate;

  /// No description provided for @createFromTemplateShowtemplates.
  ///
  /// In en, this message translates to:
  /// **'Create from template: {v0}'**
  String createFromTemplateShowtemplates(Object v0);

  /// No description provided for @fields.
  ///
  /// In en, this message translates to:
  /// **'{v0, plural, =1{1 field} other{{v0} fields}}'**
  String fields(num v0);

  /// No description provided for @dataTables.
  ///
  /// In en, this message translates to:
  /// **'Data tables'**
  String get dataTables;

  /// No description provided for @tables.
  ///
  /// In en, this message translates to:
  /// **'{v0, plural, =1{1 table} other{{v0} tables}}'**
  String tables(num v0);

  /// No description provided for @recentlyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get recentlyUpdated;

  /// No description provided for @noMatchingTables.
  ///
  /// In en, this message translates to:
  /// **'No matching tables'**
  String get noMatchingTables;

  /// No description provided for @noTablesYet.
  ///
  /// In en, this message translates to:
  /// **'No tables yet'**
  String get noTablesYet;

  /// No description provided for @newTable.
  ///
  /// In en, this message translates to:
  /// **'New table'**
  String get newTable;

  /// No description provided for @searchTables.
  ///
  /// In en, this message translates to:
  /// **'Search tables'**
  String get searchTables;

  /// No description provided for @fieldsRows.
  ///
  /// In en, this message translates to:
  /// **'{v0} fields, {v1} rows {v2}'**
  String fieldsRows(Object v0, Object v1, Object v2);

  /// No description provided for @fieldsRowsAiChangesToReview.
  ///
  /// In en, this message translates to:
  /// **'{v0}, {v1} fields, {v2} rows, {v3} AI changes to review'**
  String fieldsRowsAiChangesToReview(
    Object v0,
    Object v1,
    Object v2,
    Object v3,
  );

  /// No description provided for @fieldsRowsBuild.
  ///
  /// In en, this message translates to:
  /// **'{v0}, {v1} fields, {v2} rows'**
  String fieldsRowsBuild(Object v0, Object v1, Object v2);

  /// No description provided for @csvExported.
  ///
  /// In en, this message translates to:
  /// **'CSV exported: {v0}'**
  String csvExported(Object v0);

  /// No description provided for @copyTableStructure.
  ///
  /// In en, this message translates to:
  /// **'Copy table structure'**
  String get copyTableStructure;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'{v0} copy'**
  String copy(Object v0);

  /// No description provided for @createdCopy.
  ///
  /// In en, this message translates to:
  /// **'Created copy “{v0}”'**
  String createdCopy(Object v0);

  /// No description provided for @archivedTablesAreHiddenArchiveATable.
  ///
  /// In en, this message translates to:
  /// **'Archived tables are hidden. Archive a table before deleting it.'**
  String get archivedTablesAreHiddenArchiveATable;

  /// No description provided for @archivedShowcontextsheet.
  ///
  /// In en, this message translates to:
  /// **'Archived “{v0}”'**
  String archivedShowcontextsheet(Object v0);

  /// No description provided for @addRow.
  ///
  /// In en, this message translates to:
  /// **'Add row'**
  String get addRow;

  /// No description provided for @discardThisAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Discard this analysis?'**
  String get discardThisAnalysis;

  /// No description provided for @includesOneDeletionDiscardingRemovesThisAi.
  ///
  /// In en, this message translates to:
  /// **'Includes one deletion. Discarding removes this AI analysis.'**
  String get includesOneDeletionDiscardingRemovesThisAi;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @aiProposesChanges.
  ///
  /// In en, this message translates to:
  /// **'AI proposes {v0} changes'**
  String aiProposesChanges(Object v0);

  /// No description provided for @viewSource.
  ///
  /// In en, this message translates to:
  /// **'View source'**
  String get viewSource;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From {v0} ›'**
  String from(Object v0);

  /// No description provided for @applySelected.
  ///
  /// In en, this message translates to:
  /// **'Apply selected ({v0})'**
  String applySelected(Object v0);

  /// No description provided for @deselect.
  ///
  /// In en, this message translates to:
  /// **'Deselect'**
  String get deselect;

  /// No description provided for @selectLabelBuild.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectLabelBuild;

  /// No description provided for @aiAddedRows.
  ///
  /// In en, this message translates to:
  /// **'AI added {v0} rows'**
  String aiAddedRows(Object v0);

  /// No description provided for @aiMadeChanges.
  ///
  /// In en, this message translates to:
  /// **'AI made {v0} changes'**
  String aiMadeChanges(Object v0);

  /// No description provided for @undoneChangesReverted.
  ///
  /// In en, this message translates to:
  /// **'Undone. Changes reverted.'**
  String get undoneChangesReverted;

  /// No description provided for @aiEdits.
  ///
  /// In en, this message translates to:
  /// **'AI edits'**
  String get aiEdits;

  /// No description provided for @aiChangesAwaitingReviewBuild.
  ///
  /// In en, this message translates to:
  /// **'AI changes awaiting review: {v0}'**
  String aiChangesAwaitingReviewBuild(Object v0);

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review {v0}'**
  String review(Object v0);

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @chooseType.
  ///
  /// In en, this message translates to:
  /// **'Choose type {v0}'**
  String chooseType(Object v0);

  /// No description provided for @typeBuild.
  ///
  /// In en, this message translates to:
  /// **'Type: {v0}'**
  String typeBuild(Object v0);

  /// No description provided for @aiIsUnsurePleaseVerify.
  ///
  /// In en, this message translates to:
  /// **'AI is unsure. Please verify.'**
  String get aiIsUnsurePleaseVerify;

  /// No description provided for @enterText.
  ///
  /// In en, this message translates to:
  /// **'Enter text'**
  String get enterText;

  /// No description provided for @enterANumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get enterANumber;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @boolean.
  ///
  /// In en, this message translates to:
  /// **'Boolean'**
  String get boolean;

  /// No description provided for @deletionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Deletion unavailable'**
  String get deletionUnavailable;

  /// No description provided for @tooManyRecordsUseThisFieldTo.
  ///
  /// In en, this message translates to:
  /// **'Too many records use this field to delete it here'**
  String get tooManyRecordsUseThisFieldTo;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @deleteField.
  ///
  /// In en, this message translates to:
  /// **'Delete field “{v0}”?'**
  String deleteField(Object v0);

  /// No description provided for @thisFieldHasNoValues.
  ///
  /// In en, this message translates to:
  /// **'This field has no values.'**
  String get thisFieldHasNoValues;

  /// No description provided for @alsoClearsThisFieldInRows.
  ///
  /// In en, this message translates to:
  /// **'Also clears this field in {v0} rows.'**
  String alsoClearsThisFieldInRows(Object v0);

  /// No description provided for @fieldDeleted.
  ///
  /// In en, this message translates to:
  /// **'Field deleted'**
  String get fieldDeleted;

  /// No description provided for @enterOneOfTheOptions.
  ///
  /// In en, this message translates to:
  /// **'Enter one of the options'**
  String get enterOneOfTheOptions;

  /// No description provided for @enterAnOptionEG.
  ///
  /// In en, this message translates to:
  /// **'Enter an option, e.g. “{v0}”'**
  String enterAnOptionEG(Object v0);

  /// No description provided for @eG.
  ///
  /// In en, this message translates to:
  /// **'e.g. 3.5'**
  String get eG;

  /// No description provided for @eGBackfillhint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1250.00'**
  String get eGBackfillhint;

  /// No description provided for @defaultForExistingRecords.
  ///
  /// In en, this message translates to:
  /// **'Default for existing records'**
  String get defaultForExistingRecords;

  /// No description provided for @fieldNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Field name is required'**
  String get fieldNameIsRequired;

  /// No description provided for @provideAtLeastOneCommaSeparatedOption.
  ///
  /// In en, this message translates to:
  /// **'Provide at least one comma-separated option'**
  String get provideAtLeastOneCommaSeparatedOption;

  /// No description provided for @fieldAdded.
  ///
  /// In en, this message translates to:
  /// **'Field added'**
  String get fieldAdded;

  /// No description provided for @fieldsBuildfieldlist.
  ///
  /// In en, this message translates to:
  /// **'Fields: {v0}'**
  String fieldsBuildfieldlist(Object v0);

  /// No description provided for @noFieldsYet.
  ///
  /// In en, this message translates to:
  /// **'No fields yet'**
  String get noFieldsYet;

  /// No description provided for @addFieldBuildfieldlist.
  ///
  /// In en, this message translates to:
  /// **'Add field'**
  String get addFieldBuildfieldlist;

  /// No description provided for @fieldNameBuildaddform.
  ///
  /// In en, this message translates to:
  /// **'Field name'**
  String get fieldNameBuildaddform;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @commaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated'**
  String get commaSeparated;

  /// No description provided for @optionsBuildaddform.
  ///
  /// In en, this message translates to:
  /// **'{v0, plural, =1{1 option} other{{v0} options}}'**
  String optionsBuildaddform(num v0);

  /// No description provided for @unitOptional.
  ///
  /// In en, this message translates to:
  /// **'Unit (optional)'**
  String get unitOptional;

  /// No description provided for @eGSharesMinutes.
  ///
  /// In en, this message translates to:
  /// **'e.g. shares, minutes'**
  String get eGSharesMinutes;

  /// No description provided for @decimalPlaces.
  ///
  /// In en, this message translates to:
  /// **'Decimal places'**
  String get decimalPlaces;

  /// No description provided for @setADefaultForExistingRecords.
  ///
  /// In en, this message translates to:
  /// **'Set a default for existing records'**
  String get setADefaultForExistingRecords;

  /// No description provided for @appliesToAllExistingRows.
  ///
  /// In en, this message translates to:
  /// **'Applies to all {v0} existing rows'**
  String appliesToAllExistingRows(Object v0);

  /// No description provided for @renameBuild.
  ///
  /// In en, this message translates to:
  /// **'Rename “{v0}”'**
  String renameBuild(Object v0);

  /// No description provided for @deleteLabelBuild2.
  ///
  /// In en, this message translates to:
  /// **'Delete “{v0}”'**
  String deleteLabelBuild2(Object v0);

  /// No description provided for @renameField.
  ///
  /// In en, this message translates to:
  /// **'Rename field'**
  String get renameField;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minAgo.
  ///
  /// In en, this message translates to:
  /// **'{v0} min ago'**
  String minAgo(Object v0);

  /// No description provided for @switchLabel.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchLabel;

  /// No description provided for @thisRow.
  ///
  /// In en, this message translates to:
  /// **'This row'**
  String get thisRow;

  /// No description provided for @couldntLoadChangeHistory.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load change history'**
  String get couldntLoadChangeHistory;

  /// No description provided for @noChangesYet.
  ///
  /// In en, this message translates to:
  /// **'No changes yet'**
  String get noChangesYet;

  /// No description provided for @restoreThisVersion.
  ///
  /// In en, this message translates to:
  /// **'Restore this version?'**
  String get restoreThisVersion;

  /// No description provided for @restoresTheVersionFromTheRestoreWill.
  ///
  /// In en, this message translates to:
  /// **'Restores the version from {v0}. The restore will appear in history.'**
  String restoresTheVersionFromTheRestoreWill(Object v0);

  /// No description provided for @restoresTheVersionFromAndUndoesLater.
  ///
  /// In en, this message translates to:
  /// **'Restores the version from {v0} and undoes {v1} later changes. The restore will appear in history.'**
  String restoresTheVersionFromAndUndoesLater(Object v0, Object v1);

  /// No description provided for @restoreVersion.
  ///
  /// In en, this message translates to:
  /// **'Restore version'**
  String get restoreVersion;

  /// No description provided for @restoredTheVersionFrom.
  ///
  /// In en, this message translates to:
  /// **'Restored the version from {v0}'**
  String restoredTheVersionFrom(Object v0);

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @createdThisRow.
  ///
  /// In en, this message translates to:
  /// **'Created this row'**
  String get createdThisRow;

  /// No description provided for @deletedThisRow.
  ///
  /// In en, this message translates to:
  /// **'Deleted this row'**
  String get deletedThisRow;

  /// No description provided for @viewOriginalImage.
  ///
  /// In en, this message translates to:
  /// **'View original image'**
  String get viewOriginalImage;

  /// No description provided for @viewOriginal.
  ///
  /// In en, this message translates to:
  /// **'{v0} View original ▸'**
  String viewOriginal(Object v0);

  /// No description provided for @imageTooLargeChooseAPngOr.
  ///
  /// In en, this message translates to:
  /// **'Image too large. Choose a PNG or JPEG under 10 MB or crop it.'**
  String get imageTooLargeChooseAPngOr;

  /// No description provided for @couldntReadThisImageChooseAComplete.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read this image. Choose a complete, static PNG or JPEG.'**
  String get couldntReadThisImageChooseAComplete;

  /// No description provided for @theOriginalAndItsCopyAreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The original and its copy are unavailable. Choose the image again.'**
  String get theOriginalAndItsCopyAreUnavailable;

  /// No description provided for @thisImageIsLinkedToARecognition.
  ///
  /// In en, this message translates to:
  /// **'This image is linked to a recognition record and is retained for history.'**
  String get thisImageIsLinkedToARecognition;

  /// No description provided for @couldntReadOrSaveTheImageExisting.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read or save the image. Existing data is retained.'**
  String get couldntReadOrSaveTheImageExisting;

  /// No description provided for @addTheClearlyIdentifiableRecordsToThis.
  ///
  /// In en, this message translates to:
  /// **'Add the clearly identifiable records to this table. Ask me about anything uncertain.'**
  String get addTheClearlyIdentifiableRecordsToThis;

  /// No description provided for @imageStart.
  ///
  /// In en, this message translates to:
  /// **'Image “{v0}”: {v1}'**
  String imageStart(Object v0, Object v1);

  /// No description provided for @unavailableBuild.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailableBuild;

  /// No description provided for @targetTable.
  ///
  /// In en, this message translates to:
  /// **'Target table: {v0}'**
  String targetTable(Object v0);

  /// No description provided for @stopRecognition.
  ///
  /// In en, this message translates to:
  /// **'Stop recognition'**
  String get stopRecognition;

  /// No description provided for @savedImages.
  ///
  /// In en, this message translates to:
  /// **'Saved images'**
  String get savedImages;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @incompleteFileChooseItAgain.
  ///
  /// In en, this message translates to:
  /// **'Incomplete file. Choose it again.'**
  String get incompleteFileChooseItAgain;

  /// No description provided for @removeUnusedImage.
  ///
  /// In en, this message translates to:
  /// **'Remove unused image'**
  String get removeUnusedImage;

  /// No description provided for @retryReading.
  ///
  /// In en, this message translates to:
  /// **'Retry reading'**
  String get retryReading;

  /// No description provided for @importInstructions.
  ///
  /// In en, this message translates to:
  /// **'Import instructions'**
  String get importInstructions;

  /// No description provided for @addRecordsOrSpecifyWhichRecordsTo.
  ///
  /// In en, this message translates to:
  /// **'Add records or specify which records to update'**
  String get addRecordsOrSpecifyWhichRecordsTo;

  /// No description provided for @theImageWillBeSentToThe.
  ///
  /// In en, this message translates to:
  /// **'The image will be sent to the selected model and use its quota.'**
  String get theImageWillBeSentToThe;

  /// No description provided for @analyzeAndImport.
  ///
  /// In en, this message translates to:
  /// **'Analyze and import'**
  String get analyzeAndImport;

  /// No description provided for @viewSourceImage.
  ///
  /// In en, this message translates to:
  /// **'View source image'**
  String get viewSourceImage;

  /// No description provided for @thisRecordHasNoLinkedSourceImage.
  ///
  /// In en, this message translates to:
  /// **'This record has no linked source image.'**
  String get thisRecordHasNoLinkedSourceImage;

  /// No description provided for @demoImagePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Demo image placeholder'**
  String get demoImagePlaceholder;

  /// No description provided for @closeImage.
  ///
  /// In en, this message translates to:
  /// **'Close image'**
  String get closeImage;

  /// No description provided for @enterATableName.
  ///
  /// In en, this message translates to:
  /// **'Enter a table name'**
  String get enterATableName;

  /// No description provided for @fieldsBuild.
  ///
  /// In en, this message translates to:
  /// **'Fields ({v0})'**
  String fieldsBuild(Object v0);

  /// No description provided for @deleteFieldBuild.
  ///
  /// In en, this message translates to:
  /// **'Delete field {v0}'**
  String deleteFieldBuild(Object v0);

  /// No description provided for @optionOneOptionTwo.
  ///
  /// In en, this message translates to:
  /// **'Option one\nOption two'**
  String get optionOneOptionTwo;

  /// No description provided for @enterUniqueOptionsOnePerLine.
  ///
  /// In en, this message translates to:
  /// **'Enter unique options, one per line'**
  String get enterUniqueOptionsOnePerLine;

  /// No description provided for @oneOptionPerLine.
  ///
  /// In en, this message translates to:
  /// **'One option per line'**
  String get oneOptionPerLine;

  /// No description provided for @invalidContentOrFieldFormatCheckAnd.
  ///
  /// In en, this message translates to:
  /// **'Invalid content or field format. Check and try again.'**
  String get invalidContentOrFieldFormatCheckAnd;

  /// No description provided for @savingPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Saving. Please wait.'**
  String get savingPleaseWait;

  /// No description provided for @recordNoLongerExists.
  ///
  /// In en, this message translates to:
  /// **'Record no longer exists'**
  String get recordNoLongerExists;

  /// No description provided for @backToTable.
  ///
  /// In en, this message translates to:
  /// **'Back to table'**
  String get backToTable;

  /// No description provided for @recordDetails.
  ///
  /// In en, this message translates to:
  /// **'Record details'**
  String get recordDetails;

  /// No description provided for @equals.
  ///
  /// In en, this message translates to:
  /// **'Equals'**
  String get equals;

  /// No description provided for @containsRowFilterSheet.
  ///
  /// In en, this message translates to:
  /// **'Contains'**
  String get containsRowFilterSheet;

  /// No description provided for @greaterThan.
  ///
  /// In en, this message translates to:
  /// **'Greater than'**
  String get greaterThan;

  /// No description provided for @atLeast.
  ///
  /// In en, this message translates to:
  /// **'At least'**
  String get atLeast;

  /// No description provided for @lessThan.
  ///
  /// In en, this message translates to:
  /// **'Less than'**
  String get lessThan;

  /// No description provided for @atMost.
  ///
  /// In en, this message translates to:
  /// **'At most'**
  String get atMost;

  /// No description provided for @enterANumberWithUpToDecimal.
  ///
  /// In en, this message translates to:
  /// **'Enter a number with up to {v0} decimal places'**
  String enterANumberWithUpToDecimal(Object v0);

  /// No description provided for @addUpToFourFieldConditions.
  ///
  /// In en, this message translates to:
  /// **'Add up to four field conditions'**
  String get addUpToFourFieldConditions;

  /// No description provided for @conditions.
  ///
  /// In en, this message translates to:
  /// **'Conditions: {v0}'**
  String conditions(Object v0);

  /// No description provided for @noFilterableFieldsInThisTable.
  ///
  /// In en, this message translates to:
  /// **'No filterable fields in this table'**
  String get noFilterableFieldsInThisTable;

  /// No description provided for @addCondition.
  ///
  /// In en, this message translates to:
  /// **'Add condition'**
  String get addCondition;

  /// No description provided for @upToConditions.
  ///
  /// In en, this message translates to:
  /// **'Up to {v0} conditions'**
  String upToConditions(Object v0);

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get applyFilters;

  /// No description provided for @removeCondition.
  ///
  /// In en, this message translates to:
  /// **'Remove condition'**
  String get removeCondition;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @clearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get clearDate;

  /// No description provided for @eGBuildvalueeditor.
  ///
  /// In en, this message translates to:
  /// **'e.g. 3.5 ({v0})'**
  String eGBuildvalueeditor(Object v0);

  /// No description provided for @chooseDateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Choose date and time'**
  String get chooseDateAndTime;

  /// No description provided for @holdingsPng.
  ///
  /// In en, this message translates to:
  /// **'Holdings_0921.png'**
  String get holdingsPng;

  /// No description provided for @fromTheHoldingsScreenshotAddedSharesOf.
  ///
  /// In en, this message translates to:
  /// **'From the holdings screenshot: added 200 shares of Kweichow Moutai and bought 300 shares of Tencent.'**
  String get fromTheHoldingsScreenshotAddedSharesOf;

  /// No description provided for @kweichowMoutaiShares.
  ///
  /// In en, this message translates to:
  /// **'Kweichow Moutai shares'**
  String get kweichowMoutaiShares;

  /// No description provided for @shares.
  ///
  /// In en, this message translates to:
  /// **'500 shares'**
  String get shares;

  /// No description provided for @kweichowMoutaiPrice.
  ///
  /// In en, this message translates to:
  /// **'Kweichow Moutai price'**
  String get kweichowMoutaiPrice;

  /// No description provided for @tencentAdded.
  ///
  /// In en, this message translates to:
  /// **'Tencent added'**
  String get tencentAdded;

  /// No description provided for @tencentShares.
  ///
  /// In en, this message translates to:
  /// **'Tencent shares'**
  String get tencentShares;

  /// No description provided for @sharesBuildplan.
  ///
  /// In en, this message translates to:
  /// **'300 shares'**
  String get sharesBuildplan;

  /// No description provided for @tencentCostBasis.
  ///
  /// In en, this message translates to:
  /// **'Tencent cost basis'**
  String get tencentCostBasis;

  /// No description provided for @tencent.
  ///
  /// In en, this message translates to:
  /// **'Tencent'**
  String get tencent;

  /// No description provided for @costBasis.
  ///
  /// In en, this message translates to:
  /// **'Cost basis'**
  String get costBasis;

  /// No description provided for @receiptJpg.
  ///
  /// In en, this message translates to:
  /// **'Receipt_0923.jpg'**
  String get receiptJpg;

  /// No description provided for @extractedAnArchiveReceiptFromThePhoto.
  ///
  /// In en, this message translates to:
  /// **'Extracted an archive receipt from the photo. The volume count is hard to read.'**
  String get extractedAnArchiveReceiptFromThePhoto;

  /// No description provided for @analysisOfReceiptJpg.
  ///
  /// In en, this message translates to:
  /// **'Analysis of “Receipt_0923.jpg”'**
  String get analysisOfReceiptJpg;

  /// No description provided for @archiveId.
  ///
  /// In en, this message translates to:
  /// **'Archive ID'**
  String get archiveId;

  /// No description provided for @titleBuildplan.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleBuildplan;

  /// No description provided for @planningRecordsTransferredByTheHousingBureau.
  ///
  /// In en, this message translates to:
  /// **'Planning records transferred by the housing bureau'**
  String get planningRecordsTransferredByTheHousingBureau;

  /// No description provided for @volumesBuildplan.
  ///
  /// In en, this message translates to:
  /// **'Volumes'**
  String get volumesBuildplan;

  /// No description provided for @transferringAgency.
  ///
  /// In en, this message translates to:
  /// **'Transferring agency'**
  String get transferringAgency;

  /// No description provided for @municipalHousingBureau.
  ///
  /// In en, this message translates to:
  /// **'Municipal housing bureau'**
  String get municipalHousingBureau;

  /// No description provided for @yearBuildplan.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get yearBuildplan;

  /// No description provided for @receivedDate.
  ///
  /// In en, this message translates to:
  /// **'Received date'**
  String get receivedDate;

  /// No description provided for @classification.
  ///
  /// In en, this message translates to:
  /// **'Classification'**
  String get classification;

  /// No description provided for @internal.
  ///
  /// In en, this message translates to:
  /// **'Internal'**
  String get internal;

  /// No description provided for @digitized.
  ///
  /// In en, this message translates to:
  /// **'Digitized'**
  String get digitized;

  /// No description provided for @recordFromScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Record from screenshot'**
  String get recordFromScreenshot;

  /// No description provided for @screenshotPng.
  ///
  /// In en, this message translates to:
  /// **'Screenshot_0923.png'**
  String get screenshotPng;

  /// No description provided for @foundARecordInTheScreenshotConfirm.
  ///
  /// In en, this message translates to:
  /// **'Found a record in the screenshot. Confirm to save it.'**
  String get foundARecordInTheScreenshotConfirm;

  /// No description provided for @analysisOfScreenshotPng.
  ///
  /// In en, this message translates to:
  /// **'Analysis of “Screenshot_0923.png”'**
  String get analysisOfScreenshotPng;

  /// No description provided for @importScreenshotBuild.
  ///
  /// In en, this message translates to:
  /// **'Import screenshot {v0}'**
  String importScreenshotBuild(Object v0);

  /// No description provided for @cancelImageAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Cancel image analysis'**
  String get cancelImageAnalysis;

  /// No description provided for @startAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Start analysis'**
  String get startAnalysis;

  /// No description provided for @chooseAgain.
  ///
  /// In en, this message translates to:
  /// **'Choose again'**
  String get chooseAgain;

  /// No description provided for @extractionComplete.
  ///
  /// In en, this message translates to:
  /// **'Extraction complete'**
  String get extractionComplete;

  /// No description provided for @uploadingImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading image…'**
  String get uploadingImage;

  /// No description provided for @readingImage.
  ///
  /// In en, this message translates to:
  /// **'Reading image…'**
  String get readingImage;

  /// No description provided for @takingLongerThanExpected.
  ///
  /// In en, this message translates to:
  /// **'Taking longer than expected…'**
  String get takingLongerThanExpected;

  /// No description provided for @monthlyCredits.
  ///
  /// In en, this message translates to:
  /// **'Monthly credits'**
  String get monthlyCredits;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'{v0} credits'**
  String credits(Object v0);

  /// No description provided for @modelAccess.
  ///
  /// In en, this message translates to:
  /// **'Model access'**
  String get modelAccess;

  /// No description provided for @context.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get context;

  /// No description provided for @yourOwnApiKey.
  ///
  /// In en, this message translates to:
  /// **'Your own API key'**
  String get yourOwnApiKey;

  /// No description provided for @shortContext.
  ///
  /// In en, this message translates to:
  /// **'Short context'**
  String get shortContext;

  /// No description provided for @yearlyBuild.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearlyBuild;

  /// No description provided for @monthlyBuild2.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyBuild2;

  /// No description provided for @toworkMembership.
  ///
  /// In en, this message translates to:
  /// **'ToWork membership'**
  String get toworkMembership;

  /// No description provided for @closeMembership.
  ///
  /// In en, this message translates to:
  /// **'Close membership'**
  String get closeMembership;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get currentPlan;

  /// No description provided for @switchTo.
  ///
  /// In en, this message translates to:
  /// **'Switch to {v0}'**
  String switchTo(Object v0);

  /// No description provided for @selectLabelBuild2.
  ///
  /// In en, this message translates to:
  /// **'Select {v0}'**
  String selectLabelBuild2(Object v0);

  /// No description provided for @dismissSuccessAnimation.
  ///
  /// In en, this message translates to:
  /// **'Dismiss success animation'**
  String get dismissSuccessAnimation;

  /// No description provided for @membership.
  ///
  /// In en, this message translates to:
  /// **'{v0} membership'**
  String membership(Object v0);

  /// No description provided for @planChanged.
  ///
  /// In en, this message translates to:
  /// **'Plan changed'**
  String get planChanged;

  /// No description provided for @creditsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{v0} credits per month'**
  String creditsPerMonth(Object v0);

  /// No description provided for @membershipBadge.
  ///
  /// In en, this message translates to:
  /// **'{v0} membership badge'**
  String membershipBadge(Object v0);

  /// No description provided for @memoryIsPausedResumeItInSettings.
  ///
  /// In en, this message translates to:
  /// **'Memory is paused. Resume it in Settings first.'**
  String get memoryIsPausedResumeItInSettings;

  /// No description provided for @invalidContentOrType.
  ///
  /// In en, this message translates to:
  /// **'Invalid content or type'**
  String get invalidContentOrType;

  /// No description provided for @couldntSaveTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save. Try again.'**
  String get couldntSaveTryAgain;

  /// No description provided for @resumeMemoryToAddAnItem.
  ///
  /// In en, this message translates to:
  /// **'Resume memory to add an item'**
  String get resumeMemoryToAddAnItem;

  /// No description provided for @remembered.
  ///
  /// In en, this message translates to:
  /// **'Remembered'**
  String get remembered;

  /// No description provided for @updatedOpeneditor.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updatedOpeneditor;

  /// No description provided for @rememberAgain.
  ///
  /// In en, this message translates to:
  /// **'Remember again'**
  String get rememberAgain;

  /// No description provided for @originalChatNoLongerExists.
  ///
  /// In en, this message translates to:
  /// **'Original chat no longer exists'**
  String get originalChatNoLongerExists;

  /// No description provided for @memoryRestored.
  ///
  /// In en, this message translates to:
  /// **'Memory restored'**
  String get memoryRestored;

  /// No description provided for @memoryCleared.
  ///
  /// In en, this message translates to:
  /// **'Memory cleared'**
  String get memoryCleared;

  /// No description provided for @memoryLibrary.
  ///
  /// In en, this message translates to:
  /// **'Memory library'**
  String get memoryLibrary;

  /// No description provided for @onLabel.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get onLabel;

  /// No description provided for @memoryOffModeIs.
  ///
  /// In en, this message translates to:
  /// **'Memory off mode is {v0}'**
  String memoryOffModeIs(Object v0);

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @couldntLoadMemories.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load memories'**
  String get couldntLoadMemories;

  /// No description provided for @searchMemories.
  ///
  /// In en, this message translates to:
  /// **'Search memories'**
  String get searchMemories;

  /// No description provided for @newMemory.
  ///
  /// In en, this message translates to:
  /// **'New memory'**
  String get newMemory;

  /// No description provided for @memoryIsOffNewChatsWontAdd.
  ///
  /// In en, this message translates to:
  /// **'Memory is off. New chats won’t add memories.'**
  String get memoryIsOffNewChatsWontAdd;

  /// No description provided for @resumeMemory.
  ///
  /// In en, this message translates to:
  /// **'Resume memory'**
  String get resumeMemory;

  /// No description provided for @noMemoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No memories yet'**
  String get noMemoriesYet;

  /// No description provided for @noMatchingMemories.
  ///
  /// In en, this message translates to:
  /// **'No matching memories'**
  String get noMatchingMemories;

  /// No description provided for @hrAgo.
  ///
  /// In en, this message translates to:
  /// **'{v0} hr ago'**
  String hrAgo(Object v0);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{v0} days ago'**
  String daysAgo(Object v0);

  /// No description provided for @memoryConfidence.
  ///
  /// In en, this message translates to:
  /// **'{v0} memory, {v1}, confidence {v2}'**
  String memoryConfidence(Object v0, Object v1, Object v2);

  /// No description provided for @expiredBuild.
  ///
  /// In en, this message translates to:
  /// **', expired'**
  String get expiredBuild;

  /// No description provided for @doubleTapToExpandHoldForActions.
  ///
  /// In en, this message translates to:
  /// **'{v0}. Double-tap to expand. Hold for actions.'**
  String doubleTapToExpandHoldForActions(Object v0);

  /// No description provided for @extractedByAi.
  ///
  /// In en, this message translates to:
  /// **'Extracted by AI'**
  String get extractedByAi;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// No description provided for @pendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get pendingReview;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence {v0}'**
  String confidence(Object v0);

  /// No description provided for @expiresInDays.
  ///
  /// In en, this message translates to:
  /// **'{v0, plural, =1{Expires in 1 day} other{Expires in {v0} days}}'**
  String expiresInDays(int v0);

  /// No description provided for @openSourceChat.
  ///
  /// In en, this message translates to:
  /// **'Open source chat {v0}'**
  String openSourceChat(Object v0);

  /// No description provided for @fromChatShowmemorydetailsheet.
  ///
  /// In en, this message translates to:
  /// **'From chat “{v0}”'**
  String fromChatShowmemorydetailsheet(Object v0);

  /// No description provided for @formattedValueDate.
  ///
  /// In en, this message translates to:
  /// **'{v1}/{v2}/{v0}'**
  String formattedValueDate(Object v0, Object v1, Object v2);

  /// No description provided for @memoryDetails.
  ///
  /// In en, this message translates to:
  /// **'Memory details'**
  String get memoryDetails;

  /// No description provided for @addedManually.
  ///
  /// In en, this message translates to:
  /// **'Added manually'**
  String get addedManually;

  /// No description provided for @confidenceShowmemorydetailsheet.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidenceShowmemorydetailsheet;

  /// No description provided for @retention.
  ///
  /// In en, this message translates to:
  /// **'Retention'**
  String get retention;

  /// No description provided for @noExpiration.
  ///
  /// In en, this message translates to:
  /// **'No expiration'**
  String get noExpiration;

  /// No description provided for @expiredShowmemorydetailsheet.
  ///
  /// In en, this message translates to:
  /// **' Expired'**
  String get expiredShowmemorydetailsheet;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expires;

  /// No description provided for @viewOriginalChat.
  ///
  /// In en, this message translates to:
  /// **'View original chat'**
  String get viewOriginalChat;

  /// No description provided for @copyShowmemorydetailsheet.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyShowmemorydetailsheet;

  /// No description provided for @longTerm.
  ///
  /// In en, this message translates to:
  /// **'Long term'**
  String get longTerm;

  /// No description provided for @expiresExpirylabel.
  ///
  /// In en, this message translates to:
  /// **'Expires {v0}-{v1}-{v2}'**
  String expiresExpirylabel(Object v0, Object v1, Object v2);

  /// No description provided for @editMemory.
  ///
  /// In en, this message translates to:
  /// **'Edit memory'**
  String get editMemory;

  /// No description provided for @memoryRetention.
  ///
  /// In en, this message translates to:
  /// **'Memory retention'**
  String get memoryRetention;

  /// No description provided for @customDate.
  ///
  /// In en, this message translates to:
  /// **'Custom date'**
  String get customDate;

  /// No description provided for @chatBuild.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatBuild;

  /// No description provided for @memoryBuild.
  ///
  /// In en, this message translates to:
  /// **'Memory: {v0}, {v1}'**
  String memoryBuild(Object v0, Object v1);

  /// No description provided for @moreFilters.
  ///
  /// In en, this message translates to:
  /// **'More filters'**
  String get moreFilters;

  /// No description provided for @memoryRules.
  ///
  /// In en, this message translates to:
  /// **'Memory rules'**
  String get memoryRules;

  /// No description provided for @clearAllMemories.
  ///
  /// In en, this message translates to:
  /// **'Clear all memories'**
  String get clearAllMemories;

  /// No description provided for @theAiRemembersInformationYouMentionThat.
  ///
  /// In en, this message translates to:
  /// **'The AI remembers information you mention that is likely to matter later.'**
  String get theAiRemembersInformationYouMentionThat;

  /// No description provided for @longTermPreferences.
  ///
  /// In en, this message translates to:
  /// **'Long-term preferences'**
  String get longTermPreferences;

  /// No description provided for @leadWithTheConclusion.
  ///
  /// In en, this message translates to:
  /// **'Lead with the conclusion'**
  String get leadWithTheConclusion;

  /// No description provided for @recurringWorkflows.
  ///
  /// In en, this message translates to:
  /// **'Recurring workflows'**
  String get recurringWorkflows;

  /// No description provided for @groupWeeklyReportsByProject.
  ///
  /// In en, this message translates to:
  /// **'Group weekly reports by project'**
  String get groupWeeklyReportsByProject;

  /// No description provided for @responsibilities.
  ///
  /// In en, this message translates to:
  /// **'Responsibilities'**
  String get responsibilities;

  /// No description provided for @iHandleContractApprovals.
  ///
  /// In en, this message translates to:
  /// **'I handle contract approvals'**
  String get iHandleContractApprovals;

  /// No description provided for @projectAgreements.
  ///
  /// In en, this message translates to:
  /// **'Project agreements'**
  String get projectAgreements;

  /// No description provided for @useTheSignedVersionForAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Use the signed version for acceptance'**
  String get useTheSignedVersionForAcceptance;

  /// No description provided for @terminology.
  ///
  /// In en, this message translates to:
  /// **'Terminology'**
  String get terminology;

  /// No description provided for @northMeansTheNorthChinaProjectTeam.
  ///
  /// In en, this message translates to:
  /// **'“North” means the North China project team'**
  String get northMeansTheNorthChinaProjectTeam;

  /// No description provided for @corrections.
  ///
  /// In en, this message translates to:
  /// **'Corrections'**
  String get corrections;

  /// No description provided for @weeklyReportsAreNowDueOnThursdays.
  ///
  /// In en, this message translates to:
  /// **'Weekly reports are now due on Thursdays'**
  String get weeklyReportsAreNowDueOnThursdays;

  /// No description provided for @youCanPauseMemoryAtAnyTime.
  ///
  /// In en, this message translates to:
  /// **'You can pause memory at any time.'**
  String get youCanPauseMemoryAtAnyTime;

  /// No description provided for @copyContent.
  ///
  /// In en, this message translates to:
  /// **'Copy content'**
  String get copyContent;

  /// No description provided for @deleteThisMemory.
  ///
  /// In en, this message translates to:
  /// **'Delete this memory?'**
  String get deleteThisMemory;

  /// No description provided for @theAiWillNoLongerRememberIt.
  ///
  /// In en, this message translates to:
  /// **'The AI will no longer remember it.'**
  String get theAiWillNoLongerRememberIt;

  /// No description provided for @pauseMemory.
  ///
  /// In en, this message translates to:
  /// **'Pause memory'**
  String get pauseMemory;

  /// No description provided for @newChatsWontAddMemoriesExistingMemories.
  ///
  /// In en, this message translates to:
  /// **'New chats won’t add memories. Existing memories are retained.'**
  String get newChatsWontAddMemoriesExistingMemories;

  /// No description provided for @clearAllMemoriesShowclearallconfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear all memories?'**
  String get clearAllMemoriesShowclearallconfirm;

  /// No description provided for @deletesAllMemoriesIncludingAiExtractedAnd.
  ///
  /// In en, this message translates to:
  /// **'Deletes all {v0} memories, including AI-extracted and manually added entries. This cannot be undone.'**
  String deletesAllMemoriesIncludingAiExtractedAnd(Object v0);

  /// No description provided for @holdForOneSecondToConfirmClearing.
  ///
  /// In en, this message translates to:
  /// **'Hold for one second to confirm clearing all memories'**
  String get holdForOneSecondToConfirmClearing;

  /// No description provided for @keepHolding.
  ///
  /// In en, this message translates to:
  /// **'Keep holding…'**
  String get keepHolding;

  /// No description provided for @holdForSecondToClear.
  ///
  /// In en, this message translates to:
  /// **'Hold for 1 second to clear'**
  String get holdForSecondToClear;

  /// No description provided for @closeQuickAsk.
  ///
  /// In en, this message translates to:
  /// **'Close Quick Ask'**
  String get closeQuickAsk;

  /// No description provided for @quickAsk.
  ///
  /// In en, this message translates to:
  /// **'Quick Ask'**
  String get quickAsk;

  /// No description provided for @collapseQuickAsk.
  ///
  /// In en, this message translates to:
  /// **'Collapse Quick Ask'**
  String get collapseQuickAsk;

  /// No description provided for @expandQuickAsk.
  ///
  /// In en, this message translates to:
  /// **'Expand Quick Ask'**
  String get expandQuickAsk;

  /// No description provided for @copiedAsMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Copied as Markdown'**
  String get copiedAsMarkdown;

  /// No description provided for @exported.
  ///
  /// In en, this message translates to:
  /// **'Exported {v0}'**
  String exported(Object v0);

  /// No description provided for @shareReport.
  ///
  /// In en, this message translates to:
  /// **'Share report'**
  String get shareReport;

  /// No description provided for @exportMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Export Markdown'**
  String get exportMarkdown;

  /// No description provided for @copyFullText.
  ///
  /// In en, this message translates to:
  /// **'Copy full text'**
  String get copyFullText;

  /// No description provided for @regenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate?'**
  String get regenerate;

  /// No description provided for @rebuildsThisReportUsingTheLatestData.
  ///
  /// In en, this message translates to:
  /// **'Rebuilds this report using the latest data and replaces its current content.'**
  String get rebuildsThisReportUsingTheLatestData;

  /// No description provided for @regenerateConfirmregenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerateConfirmregenerate;

  /// No description provided for @deleteThisReport.
  ///
  /// In en, this message translates to:
  /// **'Delete this report?'**
  String get deleteThisReport;

  /// No description provided for @sourceDataWillBeKept.
  ///
  /// In en, this message translates to:
  /// **'Source data will be kept.'**
  String get sourceDataWillBeKept;

  /// No description provided for @reportDeleted.
  ///
  /// In en, this message translates to:
  /// **'Report deleted'**
  String get reportDeleted;

  /// No description provided for @countingCompletedTasks.
  ///
  /// In en, this message translates to:
  /// **'Counting completed tasks'**
  String get countingCompletedTasks;

  /// No description provided for @summarizingCategories.
  ///
  /// In en, this message translates to:
  /// **'Summarizing categories'**
  String get summarizingCategories;

  /// No description provided for @aggregatingData.
  ///
  /// In en, this message translates to:
  /// **'Aggregating data'**
  String get aggregatingData;

  /// No description provided for @generatingSummary.
  ///
  /// In en, this message translates to:
  /// **'Generating summary'**
  String get generatingSummary;

  /// No description provided for @theReportWillContinueInTheBackground.
  ///
  /// In en, this message translates to:
  /// **'The report will continue in the background. You’ll be notified when it’s ready.'**
  String get theReportWillContinueInTheBackground;

  /// No description provided for @stopGeneratingConfirmstop.
  ///
  /// In en, this message translates to:
  /// **'Stop generating?'**
  String get stopGeneratingConfirmstop;

  /// No description provided for @thePartialDraftWillBeDiscarded.
  ///
  /// In en, this message translates to:
  /// **'The partial draft will be discarded.'**
  String get thePartialDraftWillBeDiscarded;

  /// No description provided for @keepGenerating.
  ///
  /// In en, this message translates to:
  /// **'Keep generating'**
  String get keepGenerating;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @markUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark unread'**
  String get markUnread;

  /// No description provided for @markRead.
  ///
  /// In en, this message translates to:
  /// **'Mark read'**
  String get markRead;

  /// No description provided for @markedUnread.
  ///
  /// In en, this message translates to:
  /// **'Marked unread'**
  String get markedUnread;

  /// No description provided for @markedRead.
  ///
  /// In en, this message translates to:
  /// **'Marked read'**
  String get markedRead;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating'**
  String get generating;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @aboutSeconds.
  ///
  /// In en, this message translates to:
  /// **'About 10–30 seconds'**
  String get aboutSeconds;

  /// No description provided for @thisReportHasBeenDeleted.
  ///
  /// In en, this message translates to:
  /// **'This report has been deleted'**
  String get thisReportHasBeenDeleted;

  /// No description provided for @dataForWasntAvailableInTimeThis.
  ///
  /// In en, this message translates to:
  /// **'Data for {v0} wasn’t available in time. This report uses the available data.'**
  String dataForWasntAvailableInTimeThis(Object v0);

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'- User: {v0}'**
  String user(Object v0);

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'- Added: {v0}'**
  String added(Object v0);

  /// No description provided for @completedReportmarkdown.
  ///
  /// In en, this message translates to:
  /// **'- Completed: {v0}'**
  String completedReportmarkdown(Object v0);

  /// No description provided for @completionRate.
  ///
  /// In en, this message translates to:
  /// **'- Completion rate: {v0}'**
  String completionRate(Object v0);

  /// No description provided for @unfinishedAtPeriodEndIncludingOverdue.
  ///
  /// In en, this message translates to:
  /// **'- Unfinished at period end: {v0}, including {v1} overdue'**
  String unfinishedAtPeriodEndIncludingOverdue(Object v0, Object v1);

  /// No description provided for @tableRecordsIncludingAddedThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'- Table records: {v0}, including {v1} added this period'**
  String tableRecordsIncludingAddedThisPeriod(Object v0, Object v1);

  /// No description provided for @completedLastPeriod.
  ///
  /// In en, this message translates to:
  /// **'- Completed last period: {v0}'**
  String completedLastPeriod(Object v0);

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'## Categories'**
  String get categories;

  /// No description provided for @categoryAddedCompleted.
  ///
  /// In en, this message translates to:
  /// **'| Category | Added | Completed |'**
  String get categoryAddedCompleted;

  /// No description provided for @summaryReportmarkdown.
  ///
  /// In en, this message translates to:
  /// **'## Summary'**
  String get summaryReportmarkdown;

  /// No description provided for @noSummaryYet.
  ///
  /// In en, this message translates to:
  /// **'(No summary yet)'**
  String get noSummaryYet;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method: {v0}'**
  String method(Object v0);

  /// No description provided for @snapshot.
  ///
  /// In en, this message translates to:
  /// **'Snapshot: {v0}'**
  String snapshot(Object v0);

  /// No description provided for @monthWeek.
  ///
  /// In en, this message translates to:
  /// **'Month {v0}, week {v1} ({v2})'**
  String monthWeek(Object v0, Object v1, Object v2);

  /// No description provided for @formattedValueProductionperiodlabel.
  ///
  /// In en, this message translates to:
  /// **'{v1}/{v0}'**
  String formattedValueProductionperiodlabel(Object v0, Object v1);

  /// No description provided for @weeklyReportMonthWeek.
  ///
  /// In en, this message translates to:
  /// **'Weekly report: month {v0}, week {v1}'**
  String weeklyReportMonthWeek(Object v0, Object v1);

  /// No description provided for @monthlyReportProductionnavtitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly report: {v1}/{v0}'**
  String monthlyReportProductionnavtitle(Object v0, Object v1);

  /// No description provided for @customReport.
  ///
  /// In en, this message translates to:
  /// **'Custom report'**
  String get customReport;

  /// No description provided for @awaitingSummary.
  ///
  /// In en, this message translates to:
  /// **'Awaiting summary'**
  String get awaitingSummary;

  /// No description provided for @summarized.
  ///
  /// In en, this message translates to:
  /// **'Summarized'**
  String get summarized;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @weeklyReportReportnavtitle.
  ///
  /// In en, this message translates to:
  /// **'{v0} weekly report'**
  String weeklyReportReportnavtitle(Object v0);

  /// No description provided for @monthlyReportReportnavtitle.
  ///
  /// In en, this message translates to:
  /// **'{v0} monthly report'**
  String monthlyReportReportnavtitle(Object v0);

  /// No description provided for @vsLastWeek.
  ///
  /// In en, this message translates to:
  /// **'vs. last week'**
  String get vsLastWeek;

  /// No description provided for @vsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'vs. last month'**
  String get vsLastMonth;

  /// No description provided for @vsLastPeriod.
  ///
  /// In en, this message translates to:
  /// **'vs. last period'**
  String get vsLastPeriod;

  /// No description provided for @hourQuotaExhaustedResetsAtTheEnd.
  ///
  /// In en, this message translates to:
  /// **'5-hour quota exhausted. Resets at the end of the window.'**
  String get hourQuotaExhaustedResetsAtTheEnd;

  /// No description provided for @quotaExhaustedForThisPeriodResetsNext.
  ///
  /// In en, this message translates to:
  /// **'Quota exhausted for this period. Resets next period.'**
  String get quotaExhaustedForThisPeriodResetsNext;

  /// No description provided for @reportGenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'Report generation failed'**
  String get reportGenerationFailed;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate report'**
  String get generateReport;

  /// No description provided for @searchReports.
  ///
  /// In en, this message translates to:
  /// **'Search reports'**
  String get searchReports;

  /// No description provided for @noReportsYet.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get noReportsYet;

  /// No description provided for @noReports.
  ///
  /// In en, this message translates to:
  /// **'No reports'**
  String get noReports;

  /// No description provided for @noMatchingReports.
  ///
  /// In en, this message translates to:
  /// **'No matching reports'**
  String get noMatchingReports;

  /// No description provided for @generatingBuild.
  ///
  /// In en, this message translates to:
  /// **'Generating…'**
  String get generatingBuild;

  /// No description provided for @completedBuild2.
  ///
  /// In en, this message translates to:
  /// **' Completed {v0}'**
  String completedBuild2(Object v0);

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'. Unread'**
  String get unread;

  /// No description provided for @couldntGenerate.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t generate {v0}'**
  String couldntGenerate(Object v0);

  /// No description provided for @lastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get lastWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get lastMonth;

  /// No description provided for @weekSubmit.
  ///
  /// In en, this message translates to:
  /// **'Week {v0}'**
  String weekSubmit(Object v0);

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @formattedValueBuild4.
  ///
  /// In en, this message translates to:
  /// **'{v0}/{v1}'**
  String formattedValueBuild4(Object v0, Object v1);

  /// No description provided for @includedCategories.
  ///
  /// In en, this message translates to:
  /// **'Included categories'**
  String get includedCategories;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @saveAsDefaultForScheduledReports.
  ///
  /// In en, this message translates to:
  /// **'Save as default for scheduled reports'**
  String get saveAsDefaultForScheduledReports;

  /// No description provided for @weeklyOnMondayAtMonthlyOnThe.
  ///
  /// In en, this message translates to:
  /// **'Weekly on Monday at 08:00. Monthly on the 1st at 08:00.'**
  String get weeklyOnMondayAtMonthlyOnThe;

  /// No description provided for @adjustInScheduledReports.
  ///
  /// In en, this message translates to:
  /// **'Adjust in Scheduled reports'**
  String get adjustInScheduledReports;

  /// No description provided for @adjustScheduledReports.
  ///
  /// In en, this message translates to:
  /// **'Adjust scheduled reports'**
  String get adjustScheduledReports;

  /// No description provided for @adjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust ›'**
  String get adjust;

  /// No description provided for @chooseDateBuild3.
  ///
  /// In en, this message translates to:
  /// **'Choose date: {v0}'**
  String chooseDateBuild3(Object v0);

  /// No description provided for @posterSaved.
  ///
  /// In en, this message translates to:
  /// **'Poster saved: {v0}'**
  String posterSaved(Object v0);

  /// No description provided for @posterExportFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Poster export failed. Try again.'**
  String get posterExportFailedTryAgain;

  /// No description provided for @markdownCopied.
  ///
  /// In en, this message translates to:
  /// **'Markdown copied'**
  String get markdownCopied;

  /// No description provided for @summaryFailedYouCanRetry.
  ///
  /// In en, this message translates to:
  /// **'Summary failed. You can retry.'**
  String get summaryFailedYouCanRetry;

  /// No description provided for @couldntReadReport.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read report'**
  String get couldntReadReport;

  /// No description provided for @localSnapshotRetained.
  ///
  /// In en, this message translates to:
  /// **'Local snapshot retained.'**
  String get localSnapshotRetained;

  /// No description provided for @reportNotFound.
  ///
  /// In en, this message translates to:
  /// **'Report not found'**
  String get reportNotFound;

  /// No description provided for @tasksCreatedDuringThePeriod.
  ///
  /// In en, this message translates to:
  /// **'Tasks created during the period'**
  String get tasksCreatedDuringThePeriod;

  /// No description provided for @unfinishedAtPeriodEnd.
  ///
  /// In en, this message translates to:
  /// **'Unfinished at period end'**
  String get unfinishedAtPeriodEnd;

  /// No description provided for @byCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get byCategory;

  /// No description provided for @dataRows.
  ///
  /// In en, this message translates to:
  /// **'Data rows'**
  String get dataRows;

  /// No description provided for @poster.
  ///
  /// In en, this message translates to:
  /// **'Poster'**
  String get poster;

  /// No description provided for @exportPosterPng.
  ///
  /// In en, this message translates to:
  /// **'Export poster PNG'**
  String get exportPosterPng;

  /// No description provided for @copyMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Copy Markdown'**
  String get copyMarkdown;

  /// No description provided for @completionRateCompletioncard.
  ///
  /// In en, this message translates to:
  /// **'Completion rate {v0}'**
  String completionRateCompletioncard(Object v0);

  /// No description provided for @noCategoryRecordsThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'No category records this period'**
  String get noCategoryRecordsThisPeriod;

  /// No description provided for @createdCompleted.
  ///
  /// In en, this message translates to:
  /// **'Created {v0}, completed {v1}'**
  String createdCompleted(Object v0, Object v1);

  /// No description provided for @noPreviousCompletionRate.
  ///
  /// In en, this message translates to:
  /// **'No previous completion rate'**
  String get noPreviousCompletionRate;

  /// No description provided for @previousPeriod.
  ///
  /// In en, this message translates to:
  /// **'{v0} (previous period: '**
  String previousPeriod(Object v0);

  /// No description provided for @noPreviousRecords.
  ///
  /// In en, this message translates to:
  /// **'No previous records'**
  String get noPreviousRecords;

  /// No description provided for @itemsComparelist.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get itemsComparelist;

  /// No description provided for @itemsComparelist2.
  ///
  /// In en, this message translates to:
  /// **'{v0} items)'**
  String itemsComparelist2(Object v0);

  /// No description provided for @completionRateBuildpie.
  ///
  /// In en, this message translates to:
  /// **'Completion rate'**
  String get completionRateBuildpie;

  /// No description provided for @totalRows.
  ///
  /// In en, this message translates to:
  /// **'Total rows: {v0}'**
  String totalRows(Object v0);

  /// No description provided for @rowsAddedThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'Rows added this period: {v0}'**
  String rowsAddedThisPeriod(Object v0);

  /// No description provided for @aiSummary.
  ///
  /// In en, this message translates to:
  /// **'AI summary'**
  String get aiSummary;

  /// No description provided for @summaryFailedSnapshotRetained.
  ///
  /// In en, this message translates to:
  /// **'Summary failed. Snapshot retained.'**
  String get summaryFailedSnapshotRetained;

  /// No description provided for @kimiWritesTheSummaryUsingTheFigures.
  ///
  /// In en, this message translates to:
  /// **'Kimi writes the summary using the figures captured in this report.'**
  String get kimiWritesTheSummaryUsingTheFigures;

  /// No description provided for @retrySummary.
  ///
  /// In en, this message translates to:
  /// **'Retry summary'**
  String get retrySummary;

  /// No description provided for @reportServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Report service unavailable'**
  String get reportServiceUnavailable;

  /// No description provided for @generatingReport.
  ///
  /// In en, this message translates to:
  /// **'Generating report'**
  String get generatingReport;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @generateThisWeeksReport.
  ///
  /// In en, this message translates to:
  /// **'Generate this week’s report'**
  String get generateThisWeeksReport;

  /// No description provided for @generateThisMonthsReport.
  ///
  /// In en, this message translates to:
  /// **'Generate this month’s report'**
  String get generateThisMonthsReport;

  /// No description provided for @periodUsesTheTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Period uses the {v0} time zone'**
  String periodUsesTheTimeZone(Object v0);

  /// No description provided for @completionRateBuild.
  ///
  /// In en, this message translates to:
  /// **'Completion rate {v0}.'**
  String completionRateBuild(Object v0);

  /// No description provided for @aiObservationsAndSuggestions.
  ///
  /// In en, this message translates to:
  /// **'AI observations and suggestions'**
  String get aiObservationsAndSuggestions;

  /// No description provided for @upcomingTasksBullets.
  ///
  /// In en, this message translates to:
  /// **'Upcoming tasks'**
  String get upcomingTasksBullets;

  /// No description provided for @nextMonthsFocus.
  ///
  /// In en, this message translates to:
  /// **'Next month’s focus'**
  String get nextMonthsFocus;

  /// No description provided for @aiGeneratedContent.
  ///
  /// In en, this message translates to:
  /// **'AI-generated content'**
  String get aiGeneratedContent;

  /// No description provided for @aiInsights.
  ///
  /// In en, this message translates to:
  /// **'AI insights'**
  String get aiInsights;

  /// No description provided for @weeklyReportPeriodlabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly report {v0}/{v1}–'**
  String weeklyReportPeriodlabel(Object v0, Object v1);

  /// No description provided for @sToworkReport.
  ///
  /// In en, this message translates to:
  /// **'{v0}’s ToWork report'**
  String sToworkReport(Object v0);

  /// No description provided for @methodThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'Method: {v0} (this period {v1}/{v2})'**
  String methodThisPeriod(Object v0, Object v1, Object v2);

  /// No description provided for @completedByCategory.
  ///
  /// In en, this message translates to:
  /// **'Completed by category'**
  String get completedByCategory;

  /// No description provided for @completedAdded.
  ///
  /// In en, this message translates to:
  /// **'{v0} completed, {v1} added'**
  String completedAdded(Object v0, Object v1);

  /// No description provided for @summaryBuild.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summaryBuild;

  /// No description provided for @noSummaryYetOpenTheReportTo.
  ///
  /// In en, this message translates to:
  /// **'No summary yet. Open the report to generate one.'**
  String get noSummaryYetOpenTheReportTo;

  /// No description provided for @noPreviousComparison.
  ///
  /// In en, this message translates to:
  /// **'No previous comparison'**
  String get noPreviousComparison;

  /// No description provided for @addedDonecard.
  ///
  /// In en, this message translates to:
  /// **'Added {v0}'**
  String addedDonecard(Object v0);

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get needsAttention;

  /// No description provided for @noneOverdue.
  ///
  /// In en, this message translates to:
  /// **'None overdue'**
  String get noneOverdue;

  /// No description provided for @newData.
  ///
  /// In en, this message translates to:
  /// **'New data'**
  String get newData;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @small.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get small;

  /// No description provided for @standard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get standard;

  /// No description provided for @large.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get large;

  /// No description provided for @newMoon.
  ///
  /// In en, this message translates to:
  /// **'New moon'**
  String get newMoon;

  /// No description provided for @aGoodTimeToStartAList.
  ///
  /// In en, this message translates to:
  /// **'a good time to start a list'**
  String get aGoodTimeToStartAList;

  /// No description provided for @waxingCrescent.
  ///
  /// In en, this message translates to:
  /// **'Waxing crescent'**
  String get waxingCrescent;

  /// No description provided for @aGoodTimeToBegin.
  ///
  /// In en, this message translates to:
  /// **'a good time to begin'**
  String get aGoodTimeToBegin;

  /// No description provided for @firstQuarter.
  ///
  /// In en, this message translates to:
  /// **'First quarter'**
  String get firstQuarter;

  /// No description provided for @aGoodTimeToWrapUp.
  ///
  /// In en, this message translates to:
  /// **'a good time to wrap up'**
  String get aGoodTimeToWrapUp;

  /// No description provided for @waxingGibbous.
  ///
  /// In en, this message translates to:
  /// **'Waxing gibbous'**
  String get waxingGibbous;

  /// No description provided for @aGoodTimeForAFinalPush.
  ///
  /// In en, this message translates to:
  /// **'a good time for a final push'**
  String get aGoodTimeForAFinalPush;

  /// No description provided for @fullMoon.
  ///
  /// In en, this message translates to:
  /// **'Full moon'**
  String get fullMoon;

  /// No description provided for @aGoodTimeToCelebrate.
  ///
  /// In en, this message translates to:
  /// **'a good time to celebrate'**
  String get aGoodTimeToCelebrate;

  /// No description provided for @waningGibbous.
  ///
  /// In en, this message translates to:
  /// **'Waning gibbous'**
  String get waningGibbous;

  /// No description provided for @aGoodTimeToReflect.
  ///
  /// In en, this message translates to:
  /// **'a good time to reflect'**
  String get aGoodTimeToReflect;

  /// No description provided for @lastQuarter.
  ///
  /// In en, this message translates to:
  /// **'Last quarter'**
  String get lastQuarter;

  /// No description provided for @aGoodTimeToDeclutter.
  ///
  /// In en, this message translates to:
  /// **'a good time to declutter'**
  String get aGoodTimeToDeclutter;

  /// No description provided for @waningCrescent.
  ///
  /// In en, this message translates to:
  /// **'Waning crescent'**
  String get waningCrescent;

  /// No description provided for @aGoodTimeForAnEarlyNight.
  ///
  /// In en, this message translates to:
  /// **'a good time for an early night'**
  String get aGoodTimeForAnEarlyNight;

  /// No description provided for @tonight.
  ///
  /// In en, this message translates to:
  /// **'{v0} Tonight: {v1}, {v2}'**
  String tonight(Object v0, Object v1, Object v2);

  /// No description provided for @instructionsAdded.
  ///
  /// In en, this message translates to:
  /// **'Instructions added'**
  String get instructionsAdded;

  /// No description provided for @vocabularyWords.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary: {v0} words'**
  String vocabularyWords(Object v0);

  /// No description provided for @notSetAssistantpreferencessummary.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSetAssistantpreferencessummary;

  /// No description provided for @savedAppliesFromTheNextChat.
  ///
  /// In en, this message translates to:
  /// **'Saved. Applies from the next chat.'**
  String get savedAppliesFromTheNextChat;

  /// No description provided for @eachTermCanHaveUpToCharacters.
  ///
  /// In en, this message translates to:
  /// **'Each term can have up to {v0} characters'**
  String eachTermCanHaveUpToCharacters(Object v0);

  /// No description provided for @isAlreadyInTheList.
  ///
  /// In en, this message translates to:
  /// **'“{v0}” is already in the list'**
  String isAlreadyInTheList(Object v0);

  /// No description provided for @limitTermsRemoveAnUnusedTermFirst.
  ///
  /// In en, this message translates to:
  /// **'Limit: {v0} terms. Remove an unused term first.'**
  String limitTermsRemoveAnUnusedTermFirst(Object v0);

  /// No description provided for @assistantPreferences.
  ///
  /// In en, this message translates to:
  /// **'Assistant preferences'**
  String get assistantPreferences;

  /// No description provided for @saveInstructions.
  ///
  /// In en, this message translates to:
  /// **'Save instructions'**
  String get saveInstructions;

  /// No description provided for @customInstructions.
  ///
  /// In en, this message translates to:
  /// **'Custom instructions'**
  String get customInstructions;

  /// No description provided for @eGReplyInEnglish.
  ///
  /// In en, this message translates to:
  /// **'e.g. Reply in English'**
  String get eGReplyInEnglish;

  /// No description provided for @vocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get vocabulary;

  /// No description provided for @personProjectOrProductName.
  ///
  /// In en, this message translates to:
  /// **'Person, project or product name'**
  String get personProjectOrProductName;

  /// No description provided for @speechVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Speech vocabulary {v0}/{v1}'**
  String speechVocabulary(Object v0, Object v1);

  /// No description provided for @whatTheModelReceives.
  ///
  /// In en, this message translates to:
  /// **'What the model receives'**
  String get whatTheModelReceives;

  /// No description provided for @eachRequestIncludesTheTimeYourName.
  ///
  /// In en, this message translates to:
  /// **'Each request includes the time, your name, custom instructions and vocabulary. Agent mode also includes categories and the titles and due dates of up to 12 active tasks.'**
  String get eachRequestIncludesTheTimeYourName;

  /// No description provided for @deleteTerm.
  ///
  /// In en, this message translates to:
  /// **'Delete term {v0}'**
  String deleteTerm(Object v0);

  /// No description provided for @nameSavedOnThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Name saved on this device'**
  String get nameSavedOnThisDevice;

  /// No description provided for @useCharactersWithoutLineBreaksOrControl.
  ///
  /// In en, this message translates to:
  /// **'Use 1–40 characters without line breaks or control characters'**
  String get useCharactersWithoutLineBreaksOrControl;

  /// No description provided for @profileChangedReloadBeforeSaving.
  ///
  /// In en, this message translates to:
  /// **'Profile changed. Reload before saving.'**
  String get profileChangedReloadBeforeSaving;

  /// No description provided for @couldntReadOrSaveYourLocalProfile.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read or save your local profile. Try again.'**
  String get couldntReadOrSaveYourLocalProfile;

  /// No description provided for @profileBuild.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileBuild;

  /// No description provided for @saveName.
  ///
  /// In en, this message translates to:
  /// **'Save name'**
  String get saveName;

  /// No description provided for @nameBuild.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameBuild;

  /// No description provided for @enterAName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get enterAName;

  /// No description provided for @reloadBuild.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reloadBuild;

  /// No description provided for @couldntReadLocalSettingsTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read local settings. Try again.'**
  String get couldntReadLocalSettingsTryAgain;

  /// No description provided for @quotaUpdated.
  ///
  /// In en, this message translates to:
  /// **'Quota updated'**
  String get quotaUpdated;

  /// No description provided for @thisProviderDoesntOfferAQuotaApi.
  ///
  /// In en, this message translates to:
  /// **'This provider doesn’t offer a quota API'**
  String get thisProviderDoesntOfferAQuotaApi;

  /// No description provided for @couldntCheckQuota.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t check quota: {v0}'**
  String couldntCheckQuota(Object v0);

  /// No description provided for @deleteThisAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete this account?'**
  String get deleteThisAccount;

  /// No description provided for @theSettingsForAndTheKeySaved.
  ///
  /// In en, this message translates to:
  /// **'The settings for {v0} and the key saved on this device will be deleted '**
  String theSettingsForAndTheKeySaved(Object v0);

  /// No description provided for @permanentlyChatHistoryIsRetained.
  ///
  /// In en, this message translates to:
  /// **'permanently. Chat history is retained.'**
  String get permanentlyChatHistoryIsRetained;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountDeleted;

  /// No description provided for @manualOnly.
  ///
  /// In en, this message translates to:
  /// **'  Manual only'**
  String get manualOnly;

  /// No description provided for @priorityOpenmenu.
  ///
  /// In en, this message translates to:
  /// **'Priority {v0}{v1}'**
  String priorityOpenmenu(Object v0, Object v1);

  /// No description provided for @useThisAccount.
  ///
  /// In en, this message translates to:
  /// **'Use this account'**
  String get useThisAccount;

  /// No description provided for @switchedToOpenmenu.
  ///
  /// In en, this message translates to:
  /// **'Switched to {v0}'**
  String switchedToOpenmenu(Object v0);

  /// No description provided for @editModelAndKey.
  ///
  /// In en, this message translates to:
  /// **'Edit model and key'**
  String get editModelAndKey;

  /// No description provided for @refreshQuota.
  ///
  /// In en, this message translates to:
  /// **'Refresh quota'**
  String get refreshQuota;

  /// No description provided for @resumeAccount.
  ///
  /// In en, this message translates to:
  /// **'Resume account'**
  String get resumeAccount;

  /// No description provided for @rejoinAutomaticFallback.
  ///
  /// In en, this message translates to:
  /// **'Rejoin automatic fallback'**
  String get rejoinAutomaticFallback;

  /// No description provided for @accountResumed.
  ///
  /// In en, this message translates to:
  /// **'Account resumed'**
  String get accountResumed;

  /// No description provided for @excludeFromFallback.
  ///
  /// In en, this message translates to:
  /// **'Exclude from fallback'**
  String get excludeFromFallback;

  /// No description provided for @includeInFallback.
  ///
  /// In en, this message translates to:
  /// **'Include in fallback'**
  String get includeInFallback;

  /// No description provided for @increasePriority.
  ///
  /// In en, this message translates to:
  /// **'Increase priority'**
  String get increasePriority;

  /// No description provided for @decreasePriority.
  ///
  /// In en, this message translates to:
  /// **'Decrease priority'**
  String get decreasePriority;

  /// No description provided for @modelsAndUsageBuild.
  ///
  /// In en, this message translates to:
  /// **'Models and usage'**
  String get modelsAndUsageBuild;

  /// No description provided for @switchAccountsByPriorityWhenQuotaRuns.
  ///
  /// In en, this message translates to:
  /// **'Switch accounts by priority when quota runs out, requests are limited or a key expires.'**
  String get switchAccountsByPriorityWhenQuotaRuns;

  /// No description provided for @switchAutomaticallyWhenQuotaRunsOut.
  ///
  /// In en, this message translates to:
  /// **'Switch automatically when quota runs out'**
  String get switchAutomaticallyWhenQuotaRunsOut;

  /// No description provided for @couldntReadLocalSettings.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t read local settings'**
  String get couldntReadLocalSettings;

  /// No description provided for @noModelAccountsYet.
  ///
  /// In en, this message translates to:
  /// **'No model accounts yet'**
  String get noModelAccountsYet;

  /// No description provided for @checkProviderConsole.
  ///
  /// In en, this message translates to:
  /// **'Check provider console'**
  String get checkProviderConsole;

  /// No description provided for @inUseBuild.
  ///
  /// In en, this message translates to:
  /// **', in use'**
  String get inUseBuild;

  /// No description provided for @priorityBuild.
  ///
  /// In en, this message translates to:
  /// **'{v0}, priority {v1}, {v2}'**
  String priorityBuild(Object v0, Object v1, Object v2);

  /// No description provided for @inUseBuild2.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get inUseBuild2;

  /// No description provided for @connectedUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Connected (unsaved)'**
  String get connectedUnsaved;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @serviceRegion.
  ///
  /// In en, this message translates to:
  /// **'Service region'**
  String get serviceRegion;

  /// No description provided for @china.
  ///
  /// In en, this message translates to:
  /// **'China'**
  String get china;

  /// No description provided for @international.
  ///
  /// In en, this message translates to:
  /// **'International'**
  String get international;

  /// No description provided for @chooseProvider.
  ///
  /// In en, this message translates to:
  /// **'Choose provider'**
  String get chooseProvider;

  /// No description provided for @editModelAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit model account'**
  String get editModelAccount;

  /// No description provided for @apiEndpoint.
  ///
  /// In en, this message translates to:
  /// **'API endpoint'**
  String get apiEndpoint;

  /// No description provided for @savedLeaveBlankToKeep.
  ///
  /// In en, this message translates to:
  /// **'Saved. Leave blank to keep.'**
  String get savedLeaveBlankToKeep;

  /// No description provided for @enterKey.
  ///
  /// In en, this message translates to:
  /// **'Enter key'**
  String get enterKey;

  /// No description provided for @cancelTest.
  ///
  /// In en, this message translates to:
  /// **'Cancel test'**
  String get cancelTest;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get testConnection;

  /// No description provided for @defaultAssistantEnabled.
  ///
  /// In en, this message translates to:
  /// **'Default assistant enabled'**
  String get defaultAssistantEnabled;

  /// No description provided for @notTheDefaultAssistant.
  ///
  /// In en, this message translates to:
  /// **'Not the default assistant'**
  String get notTheDefaultAssistant;

  /// No description provided for @quickLaunch.
  ///
  /// In en, this message translates to:
  /// **'Quick launch'**
  String get quickLaunch;

  /// No description provided for @tryNow.
  ///
  /// In en, this message translates to:
  /// **'Try now'**
  String get tryNow;

  /// No description provided for @quickAskIsUnavailableOnThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Quick Ask is unavailable on this device'**
  String get quickAskIsUnavailableOnThisDevice;

  /// No description provided for @defaultAssistant.
  ///
  /// In en, this message translates to:
  /// **'Default assistant'**
  String get defaultAssistant;

  /// No description provided for @openQuickAskWithTheAssistantGesture.
  ///
  /// In en, this message translates to:
  /// **'Open Quick Ask with the assistant gesture. The system controls power-button shortcuts.'**
  String get openQuickAskWithTheAssistantGesture;

  /// No description provided for @setAsDefaultAssistant.
  ///
  /// In en, this message translates to:
  /// **'Set as default assistant'**
  String get setAsDefaultAssistant;

  /// No description provided for @openSystemSettingsAppsDefaultAppsAnd.
  ///
  /// In en, this message translates to:
  /// **'Open System settings → Apps → Default apps and select ToWork'**
  String get openSystemSettingsAppsDefaultAppsAnd;

  /// No description provided for @otherShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Other shortcuts'**
  String get otherShortcuts;

  /// No description provided for @addQuickAskToHomeScreen.
  ///
  /// In en, this message translates to:
  /// **'Add Quick Ask to home screen'**
  String get addQuickAskToHomeScreen;

  /// No description provided for @theLauncherDidntAddTheShortcutHold.
  ///
  /// In en, this message translates to:
  /// **'The launcher didn’t add the shortcut. Hold the ToWork icon and drag Quick Ask to the home screen.'**
  String get theLauncherDidntAddTheShortcutHold;

  /// No description provided for @addVoiceQuickAskToHomeScreen.
  ///
  /// In en, this message translates to:
  /// **'Add Voice Quick Ask to home screen'**
  String get addVoiceQuickAskToHomeScreen;

  /// No description provided for @theLauncherDidntAddTheShortcutHoldTheTowork.
  ///
  /// In en, this message translates to:
  /// **'The launcher didn’t add the shortcut. Hold the ToWork icon and drag Voice Quick Ask to the home screen.'**
  String get theLauncherDidntAddTheShortcutHoldTheTowork;

  /// No description provided for @systemShortcuts.
  ///
  /// In en, this message translates to:
  /// **'System shortcuts'**
  String get systemShortcuts;

  /// No description provided for @selectToworkQuickAskOrToworkVoice.
  ///
  /// In en, this message translates to:
  /// **'Select ToWork Quick Ask or ToWork Voice Quick Ask in the system menu.'**
  String get selectToworkQuickAskOrToworkVoice;

  /// No description provided for @huaweiSmartControlDoubleTap.
  ///
  /// In en, this message translates to:
  /// **'Huawei Smart Control double-tap'**
  String get huaweiSmartControlDoubleTap;

  /// No description provided for @confirmTheSystemPromptThenChooseQuick.
  ///
  /// In en, this message translates to:
  /// **'Confirm the system prompt, then choose Quick Ask or Voice Quick Ask under Smart Control → Double-tap.'**
  String get confirmTheSystemPromptThenChooseQuick;

  /// No description provided for @controlCenter.
  ///
  /// In en, this message translates to:
  /// **'Control Center'**
  String get controlCenter;

  /// No description provided for @editTheQuickSettingsTilesAndAdd.
  ///
  /// In en, this message translates to:
  /// **'Edit the quick settings tiles and add Quick Ask.'**
  String get editTheQuickSettingsTilesAndAdd;

  /// No description provided for @selectTextOrShare.
  ///
  /// In en, this message translates to:
  /// **'Select text or share'**
  String get selectTextOrShare;

  /// No description provided for @chooseAskTowork.
  ///
  /// In en, this message translates to:
  /// **'Choose Ask ToWork.'**
  String get chooseAskTowork;

  /// No description provided for @holdTheAppIcon.
  ///
  /// In en, this message translates to:
  /// **'Hold the app icon'**
  String get holdTheAppIcon;

  /// No description provided for @selectQuickAskOrVoiceQuickAsk.
  ///
  /// In en, this message translates to:
  /// **'Select Quick Ask or Voice Quick Ask.'**
  String get selectQuickAskOrVoiceQuickAsk;

  /// No description provided for @morningDigestTime.
  ///
  /// In en, this message translates to:
  /// **'Morning digest time'**
  String get morningDigestTime;

  /// No description provided for @morningDigestSetTo.
  ///
  /// In en, this message translates to:
  /// **'Morning digest set to {v0}:{v1}'**
  String morningDigestSetTo(Object v0, Object v1);

  /// No description provided for @memoryPaused.
  ///
  /// In en, this message translates to:
  /// **'Memory paused'**
  String get memoryPaused;

  /// No description provided for @addKey.
  ///
  /// In en, this message translates to:
  /// **'Add key'**
  String get addKey;

  /// No description provided for @accountBuild.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountBuild;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account details'**
  String get accountDetails;

  /// No description provided for @privacyAndPermissions.
  ///
  /// In en, this message translates to:
  /// **'Privacy and permissions'**
  String get privacyAndPermissions;

  /// No description provided for @aiWritePermissions.
  ///
  /// In en, this message translates to:
  /// **'AI write permissions'**
  String get aiWritePermissions;

  /// No description provided for @pauseMemoryBuild.
  ///
  /// In en, this message translates to:
  /// **'Pause memory'**
  String get pauseMemoryBuild;

  /// No description provided for @inputAndQuickLaunch.
  ///
  /// In en, this message translates to:
  /// **'Input and quick launch'**
  String get inputAndQuickLaunch;

  /// No description provided for @speechDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Speech diagnostics'**
  String get speechDiagnostics;

  /// No description provided for @defaultInputMethod.
  ///
  /// In en, this message translates to:
  /// **'Default input method'**
  String get defaultInputMethod;

  /// No description provided for @voice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voice;

  /// No description provided for @keyboard.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get keyboard;

  /// No description provided for @couldntSaveTryAgainBuild.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save. Try again.'**
  String get couldntSaveTryAgainBuild;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @dueReminders.
  ///
  /// In en, this message translates to:
  /// **'Due reminders'**
  String get dueReminders;

  /// No description provided for @morningDigest.
  ///
  /// In en, this message translates to:
  /// **'Morning digest'**
  String get morningDigest;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @morningDigestSwitch.
  ///
  /// In en, this message translates to:
  /// **'Morning digest switch'**
  String get morningDigestSwitch;

  /// No description provided for @reportReadyNotifications.
  ///
  /// In en, this message translates to:
  /// **'Report ready notifications'**
  String get reportReadyNotifications;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationSettings;

  /// No description provided for @dataBackup.
  ///
  /// In en, this message translates to:
  /// **'Data backup'**
  String get dataBackup;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportData;

  /// No description provided for @lastExport.
  ///
  /// In en, this message translates to:
  /// **'Last export'**
  String get lastExport;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get openSourceLicenses;

  /// No description provided for @noMatchingSettings.
  ///
  /// In en, this message translates to:
  /// **'No matching settings'**
  String get noMatchingSettings;

  /// No description provided for @searchSettings.
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get searchSettings;

  /// No description provided for @neverExported.
  ///
  /// In en, this message translates to:
  /// **'Never exported'**
  String get neverExported;

  /// No description provided for @revokeAiDataConsent.
  ///
  /// In en, this message translates to:
  /// **'Revoke AI data consent'**
  String get revokeAiDataConsent;

  /// No description provided for @consentRevoked.
  ///
  /// In en, this message translates to:
  /// **'Consent revoked'**
  String get consentRevoked;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @couldntOpen.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open'**
  String get couldntOpen;

  /// No description provided for @thisApiDoesntListModelsEnterA.
  ///
  /// In en, this message translates to:
  /// **'This API doesn’t list models. Enter a model ID manually.'**
  String get thisApiDoesntListModelsEnterA;

  /// No description provided for @fetchingModels.
  ///
  /// In en, this message translates to:
  /// **'Fetching models'**
  String get fetchingModels;

  /// No description provided for @noAvailableModels.
  ///
  /// In en, this message translates to:
  /// **'No available models'**
  String get noAvailableModels;

  /// No description provided for @noMatchingModels.
  ///
  /// In en, this message translates to:
  /// **'No matching models'**
  String get noMatchingModels;

  /// No description provided for @searchModels.
  ///
  /// In en, this message translates to:
  /// **'Search models'**
  String get searchModels;

  /// No description provided for @refreshModelList.
  ///
  /// In en, this message translates to:
  /// **'Refresh model list'**
  String get refreshModelList;

  /// No description provided for @availableModels.
  ///
  /// In en, this message translates to:
  /// **'Available models'**
  String get availableModels;

  /// No description provided for @customModel.
  ///
  /// In en, this message translates to:
  /// **'Custom model'**
  String get customModel;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @modelId.
  ///
  /// In en, this message translates to:
  /// **'Model ID'**
  String get modelId;

  /// No description provided for @enterModelId.
  ///
  /// In en, this message translates to:
  /// **'Enter model ID'**
  String get enterModelId;

  /// No description provided for @fetchModelList.
  ///
  /// In en, this message translates to:
  /// **'Fetch model list'**
  String get fetchModelList;

  /// No description provided for @selectAFetchedModel.
  ///
  /// In en, this message translates to:
  /// **'Select a fetched model'**
  String get selectAFetchedModel;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **', current'**
  String get current;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **', locked'**
  String get locked;

  /// No description provided for @aiWritePermissionsSetTo.
  ///
  /// In en, this message translates to:
  /// **'AI write permissions set to “{v0}”'**
  String aiWritePermissionsSetTo(Object v0);

  /// No description provided for @savingPermissions.
  ///
  /// In en, this message translates to:
  /// **'Saving permissions…'**
  String get savingPermissions;

  /// No description provided for @tableEditsCanBeRevertedInRow.
  ///
  /// In en, this message translates to:
  /// **'Table edits can be reverted in row history.'**
  String get tableEditsCanBeRevertedInRow;

  /// No description provided for @checkingSystemStatus.
  ///
  /// In en, this message translates to:
  /// **'Checking system status…'**
  String get checkingSystemStatus;

  /// No description provided for @couldntCheckSpeechStatusTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t check speech status. Try again.'**
  String get couldntCheckSpeechStatusTryAgain;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @unavailableBuild2.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailableBuild2;

  /// No description provided for @recognitionService.
  ///
  /// In en, this message translates to:
  /// **'Recognition service: {v0}'**
  String recognitionService(Object v0);

  /// No description provided for @granted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get granted;

  /// No description provided for @partiallyGranted.
  ///
  /// In en, this message translates to:
  /// **'Partially granted'**
  String get partiallyGranted;

  /// No description provided for @microphoneAndSpeechPermissions.
  ///
  /// In en, this message translates to:
  /// **'Microphone and speech permissions: {v0}'**
  String microphoneAndSpeechPermissions(Object v0);

  /// No description provided for @supportedWithInstalledLanguageResources.
  ///
  /// In en, this message translates to:
  /// **'Supported with installed language resources'**
  String get supportedWithInstalledLanguageResources;

  /// No description provided for @supportNotReported.
  ///
  /// In en, this message translates to:
  /// **'Support not reported'**
  String get supportNotReported;

  /// No description provided for @onDeviceRecognition.
  ///
  /// In en, this message translates to:
  /// **'On-device recognition: {v0}'**
  String onDeviceRecognition(Object v0);

  /// No description provided for @mandarinLanguageListUnavailable.
  ///
  /// In en, this message translates to:
  /// **'English: language list unavailable'**
  String get mandarinLanguageListUnavailable;

  /// No description provided for @systemLanguages.
  ///
  /// In en, this message translates to:
  /// **'System languages: {v0}'**
  String systemLanguages(Object v0);

  /// No description provided for @checksMandarinRecognitionAndPermissionsWithoutRecording.
  ///
  /// In en, this message translates to:
  /// **'Checks English recognition and permissions without recording.'**
  String get checksMandarinRecognitionAndPermissionsWithoutRecording;

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// No description provided for @theTaskForThisReminderNoLonger.
  ///
  /// In en, this message translates to:
  /// **'The task for this reminder no longer exists'**
  String get theTaskForThisReminderNoLonger;

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today at 18:00'**
  String get todayAt;

  /// No description provided for @tomorrowAt.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow at 09:00'**
  String get tomorrowAt;

  /// No description provided for @nextMondayAt.
  ///
  /// In en, this message translates to:
  /// **'Next Monday at 09:00'**
  String get nextMondayAt;

  /// No description provided for @reschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get reschedule;

  /// No description provided for @rescheduledTo.
  ///
  /// In en, this message translates to:
  /// **'Rescheduled to {v0}'**
  String rescheduledTo(Object v0);

  /// No description provided for @dueDateCleared.
  ///
  /// In en, this message translates to:
  /// **'Due date cleared'**
  String get dueDateCleared;

  /// No description provided for @completedTasks.
  ///
  /// In en, this message translates to:
  /// **'Completed {v0} tasks'**
  String completedTasks(Object v0);

  /// No description provided for @changeCategory.
  ///
  /// In en, this message translates to:
  /// **'Change category'**
  String get changeCategory;

  /// No description provided for @movedTo.
  ///
  /// In en, this message translates to:
  /// **'Moved to {v0}'**
  String movedTo(Object v0);

  /// No description provided for @changeDueDate.
  ///
  /// In en, this message translates to:
  /// **'Change due date'**
  String get changeDueDate;

  /// No description provided for @rescheduled.
  ///
  /// In en, this message translates to:
  /// **'Rescheduled {v0}'**
  String rescheduled(Object v0);

  /// No description provided for @deleteTasks.
  ///
  /// In en, this message translates to:
  /// **'Delete {v0} tasks?'**
  String deleteTasks(Object v0);

  /// No description provided for @onlySelectedRecurringOccurrencesAreDeletedUndo.
  ///
  /// In en, this message translates to:
  /// **'Only selected recurring occurrences are deleted. Undo within 10 seconds.'**
  String get onlySelectedRecurringOccurrencesAreDeletedUndo;

  /// No description provided for @deletedTasks.
  ///
  /// In en, this message translates to:
  /// **'Deleted {v0} tasks'**
  String deletedTasks(Object v0);

  /// No description provided for @categoryBuild.
  ///
  /// In en, this message translates to:
  /// **'Category: {v0}'**
  String categoryBuild(Object v0);

  /// No description provided for @noTasksMatchTheseFilters.
  ///
  /// In en, this message translates to:
  /// **'No tasks match these filters'**
  String get noTasksMatchTheseFilters;

  /// No description provided for @expandCompletedTasks.
  ///
  /// In en, this message translates to:
  /// **'Expand completed tasks'**
  String get expandCompletedTasks;

  /// No description provided for @switchToBoard.
  ///
  /// In en, this message translates to:
  /// **'Switch to board'**
  String get switchToBoard;

  /// No description provided for @switchToList.
  ///
  /// In en, this message translates to:
  /// **'Switch to list'**
  String get switchToList;

  /// No description provided for @backToChatHome.
  ///
  /// In en, this message translates to:
  /// **'Back to chat home'**
  String get backToChatHome;

  /// No description provided for @list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// No description provided for @board.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get board;

  /// No description provided for @searchTasks.
  ///
  /// In en, this message translates to:
  /// **'Search tasks'**
  String get searchTasks;

  /// No description provided for @selectedBuildselectionbar.
  ///
  /// In en, this message translates to:
  /// **'Selected: {v0}'**
  String selectedBuildselectionbar(Object v0);

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// No description provided for @itemsBuildgroupheader.
  ///
  /// In en, this message translates to:
  /// **'{v0}, {v1} items'**
  String itemsBuildgroupheader(Object v0, Object v1);

  /// No description provided for @newTaskIn.
  ///
  /// In en, this message translates to:
  /// **'New task in {v0}'**
  String newTaskIn(Object v0);

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get noItems;

  /// No description provided for @noMatchingTasks.
  ///
  /// In en, this message translates to:
  /// **'No matching tasks'**
  String get noMatchingTasks;

  /// No description provided for @goToChatBuildempty.
  ///
  /// In en, this message translates to:
  /// **'Go to chat'**
  String get goToChatBuildempty;

  /// No description provided for @thisListIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'This list is empty'**
  String get thisListIsEmpty;

  /// No description provided for @noTasksToday.
  ///
  /// In en, this message translates to:
  /// **'No tasks today'**
  String get noTasksToday;

  /// No description provided for @nothingScheduledThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled this week'**
  String get nothingScheduledThisWeek;

  /// No description provided for @noOverdueTasks.
  ///
  /// In en, this message translates to:
  /// **'No overdue tasks'**
  String get noOverdueTasks;

  /// No description provided for @noTasksWithoutADueDate.
  ///
  /// In en, this message translates to:
  /// **'No tasks without a due date'**
  String get noTasksWithoutADueDate;

  /// No description provided for @noCompletedTasksYet.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks yet'**
  String get noCompletedTasksYet;

  /// No description provided for @listSettings.
  ///
  /// In en, this message translates to:
  /// **'List settings'**
  String get listSettings;

  /// No description provided for @groupBy.
  ///
  /// In en, this message translates to:
  /// **'Group by'**
  String get groupBy;

  /// No description provided for @byCategoryShowmoresheet.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get byCategoryShowmoresheet;

  /// No description provided for @byDueDate.
  ///
  /// In en, this message translates to:
  /// **'By due date'**
  String get byDueDate;

  /// No description provided for @byPriority.
  ///
  /// In en, this message translates to:
  /// **'By priority'**
  String get byPriority;

  /// No description provided for @showCompleted.
  ///
  /// In en, this message translates to:
  /// **'Show completed'**
  String get showCompleted;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage categories'**
  String get manageCategories;

  /// No description provided for @selectedAction.
  ///
  /// In en, this message translates to:
  /// **'{v0}, {v1} selected'**
  String selectedAction(Object v0, Object v1);

  /// No description provided for @someOccurrencesExceedAvailableTimeZoneData.
  ///
  /// In en, this message translates to:
  /// **'Some occurrences exceed available time zone data. Adjust the end date. Existing tasks are available.'**
  String get someOccurrencesExceedAvailableTimeZoneData;

  /// No description provided for @someRecurringTasksAreStillPendingExisting.
  ///
  /// In en, this message translates to:
  /// **'Some recurring tasks are still pending. Existing records are saved.'**
  String get someRecurringTasksAreStillPendingExisting;

  /// No description provided for @recurringTasksGeneratedThrough.
  ///
  /// In en, this message translates to:
  /// **'Recurring tasks generated through {v0}/{v1}/{v2} {v3}:{v4}'**
  String recurringTasksGeneratedThrough(
    Object v0,
    Object v1,
    Object v2,
    Object v3,
    Object v4,
  );

  /// No description provided for @recurringTasksWillContinueAfterThisAction.
  ///
  /// In en, this message translates to:
  /// **'Recurring tasks will continue after this action'**
  String get recurringTasksWillContinueAfterThisAction;

  /// No description provided for @recurringTasksWillContinueWhenYouReopen.
  ///
  /// In en, this message translates to:
  /// **'Recurring tasks will continue when you reopen the app'**
  String get recurringTasksWillContinueWhenYouReopen;

  /// No description provided for @generatingRecurringTasksInBatches.
  ///
  /// In en, this message translates to:
  /// **'Generating recurring tasks in batches'**
  String get generatingRecurringTasksInBatches;

  /// No description provided for @selectedSegment.
  ///
  /// In en, this message translates to:
  /// **', selected'**
  String get selectedSegment;

  /// No description provided for @filterByItems.
  ///
  /// In en, this message translates to:
  /// **'Filter by {v0}, {v1} items{v2}'**
  String filterByItems(Object v0, Object v1, Object v2);

  /// No description provided for @currentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current version'**
  String get currentVersion;

  /// No description provided for @versionHistory.
  ///
  /// In en, this message translates to:
  /// **'Version history'**
  String get versionHistory;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// No description provided for @checkingForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates'**
  String get checkingForUpdates;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get upToDate;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @downloadingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Downloading update'**
  String get downloadingUpdate;

  /// No description provided for @verifyingPatch.
  ///
  /// In en, this message translates to:
  /// **'Verifying patch'**
  String get verifyingPatch;

  /// No description provided for @verifyingInstaller.
  ///
  /// In en, this message translates to:
  /// **'Verifying installer'**
  String get verifyingInstaller;

  /// No description provided for @buildingInstaller.
  ///
  /// In en, this message translates to:
  /// **'Building installer'**
  String get buildingInstaller;

  /// No description provided for @patchReady.
  ///
  /// In en, this message translates to:
  /// **'Patch ready'**
  String get patchReady;

  /// No description provided for @installerReady.
  ///
  /// In en, this message translates to:
  /// **'Installer ready'**
  String get installerReady;

  /// No description provided for @permissionToInstallAppsRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission to install apps required'**
  String get permissionToInstallAppsRequired;

  /// No description provided for @confirmInstallationInTheSystemDialog.
  ///
  /// In en, this message translates to:
  /// **'Confirm installation in the system dialog'**
  String get confirmInstallationInTheSystemDialog;

  /// No description provided for @restartingToApplyUpdate.
  ///
  /// In en, this message translates to:
  /// **'Restarting to apply update'**
  String get restartingToApplyUpdate;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Update check failed'**
  String get updateCheckFailed;

  /// No description provided for @inAppInstallationUnavailableOnThisPlatform.
  ///
  /// In en, this message translates to:
  /// **'In-app installation unavailable on this platform'**
  String get inAppInstallationUnavailableOnThisPlatform;

  /// No description provided for @checkAgainBuild.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgainBuild;

  /// No description provided for @deltaUpdate.
  ///
  /// In en, this message translates to:
  /// **'Delta update'**
  String get deltaUpdate;

  /// No description provided for @fullInstaller.
  ///
  /// In en, this message translates to:
  /// **'Full installer'**
  String get fullInstaller;

  /// No description provided for @whatsNew.
  ///
  /// In en, this message translates to:
  /// **'What’s new'**
  String get whatsNew;

  /// No description provided for @deltaUpdateIncompleteSwitchedToTheFull.
  ///
  /// In en, this message translates to:
  /// **'Delta update incomplete. Switched to the full installer.'**
  String get deltaUpdateIncompleteSwitchedToTheFull;

  /// No description provided for @allowThisSourceThenReturnToInstall.
  ///
  /// In en, this message translates to:
  /// **'Allow this source, then return to install.'**
  String get allowThisSourceThenReturnToInstall;

  /// No description provided for @restoreAndRestart.
  ///
  /// In en, this message translates to:
  /// **'Restore and restart'**
  String get restoreAndRestart;

  /// No description provided for @updateAndRestart.
  ///
  /// In en, this message translates to:
  /// **'Update and restart'**
  String get updateAndRestart;

  /// No description provided for @downloadUpdate.
  ///
  /// In en, this message translates to:
  /// **'Download update'**
  String get downloadUpdate;

  /// No description provided for @cancelUpdate.
  ///
  /// In en, this message translates to:
  /// **'Cancel update'**
  String get cancelUpdate;

  /// No description provided for @pauseDownload.
  ///
  /// In en, this message translates to:
  /// **'Pause download'**
  String get pauseDownload;

  /// No description provided for @restartNow.
  ///
  /// In en, this message translates to:
  /// **'Restart now'**
  String get restartNow;

  /// No description provided for @installAndReopen.
  ///
  /// In en, this message translates to:
  /// **'Install and reopen'**
  String get installAndReopen;

  /// No description provided for @reopenInstaller.
  ///
  /// In en, this message translates to:
  /// **'Reopen installer'**
  String get reopenInstaller;

  /// No description provided for @filterCategories.
  ///
  /// In en, this message translates to:
  /// **'Filter categories'**
  String get filterCategories;

  /// No description provided for @askAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get askAi;

  /// No description provided for @scheduleOverview.
  ///
  /// In en, this message translates to:
  /// **'Schedule overview'**
  String get scheduleOverview;

  /// No description provided for @switchScheduleView.
  ///
  /// In en, this message translates to:
  /// **'Switch schedule view'**
  String get switchScheduleView;

  /// No description provided for @createTaskOnSelectedDate.
  ///
  /// In en, this message translates to:
  /// **'Create task on selected date'**
  String get createTaskOnSelectedDate;

  /// No description provided for @searchSchedule.
  ///
  /// In en, this message translates to:
  /// **'Search schedule'**
  String get searchSchedule;

  /// No description provided for @heatmap.
  ///
  /// In en, this message translates to:
  /// **'Heatmap'**
  String get heatmap;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @distribution.
  ///
  /// In en, this message translates to:
  /// **'Distribution'**
  String get distribution;

  /// No description provided for @trends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get trends;

  /// No description provided for @tasksCompleted.
  ///
  /// In en, this message translates to:
  /// **'Tasks completed'**
  String get tasksCompleted;

  /// No description provided for @itemsVizStats.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get itemsVizStats;

  /// No description provided for @tasksAdded.
  ///
  /// In en, this message translates to:
  /// **'Tasks added'**
  String get tasksAdded;

  /// No description provided for @recordsAdded.
  ///
  /// In en, this message translates to:
  /// **'Records added'**
  String get recordsAdded;

  /// No description provided for @rowsVizStats.
  ///
  /// In en, this message translates to:
  /// **'rows'**
  String get rowsVizStats;

  /// No description provided for @formattedValueOpenday.
  ///
  /// In en, this message translates to:
  /// **'{v2}, {v0}/{v1}'**
  String formattedValueOpenday(Object v0, Object v1, Object v2);

  /// No description provided for @alreadyHighPriorityItemsThatDay.
  ///
  /// In en, this message translates to:
  /// **'. Already {v0} high-priority items that day'**
  String alreadyHighPriorityItemsThatDay(Object v0);

  /// No description provided for @movedToReschedule.
  ///
  /// In en, this message translates to:
  /// **'Moved to {v0}/{v1}{v2}'**
  String movedToReschedule(Object v0, Object v1, Object v2);

  /// No description provided for @previousMonthBuild.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonthBuild;

  /// No description provided for @nextMonthBuild.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonthBuild;

  /// No description provided for @noTasksThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No tasks this month'**
  String get noTasksThisMonth;

  /// No description provided for @todayBuild.
  ///
  /// In en, this message translates to:
  /// **'Today, '**
  String get todayBuild;

  /// No description provided for @overdueItems.
  ///
  /// In en, this message translates to:
  /// **', overdue items'**
  String get overdueItems;

  /// No description provided for @tasksBuild2.
  ///
  /// In en, this message translates to:
  /// **'{v0}/{v1}, {v2}{v3} tasks{v4}'**
  String tasksBuild2(Object v0, Object v1, Object v2, Object v3, Object v4);

  /// No description provided for @pieChart.
  ///
  /// In en, this message translates to:
  /// **'Pie chart'**
  String get pieChart;

  /// No description provided for @barChart.
  ///
  /// In en, this message translates to:
  /// **'Bar chart'**
  String get barChart;

  /// No description provided for @switchChart.
  ///
  /// In en, this message translates to:
  /// **'Switch chart'**
  String get switchChart;

  /// No description provided for @addCategoriesToYourTasksToSee.
  ///
  /// In en, this message translates to:
  /// **'Add categories to your tasks to see their distribution.'**
  String get addCategoriesToYourTasksToSee;

  /// No description provided for @organizeCategories.
  ///
  /// In en, this message translates to:
  /// **'Organize categories'**
  String get organizeCategories;

  /// No description provided for @completeBuildpie.
  ///
  /// In en, this message translates to:
  /// **'{v0}: {v1}% complete'**
  String completeBuildpie(Object v0, Object v1);

  /// No description provided for @itemsComplete.
  ///
  /// In en, this message translates to:
  /// **'{v0}, {v1} items, {v2}% complete'**
  String itemsComplete(Object v0, Object v1, Object v2);

  /// No description provided for @itemsCompleteBuildpie.
  ///
  /// In en, this message translates to:
  /// **'{v0} items, {v1}% complete'**
  String itemsCompleteBuildpie(Object v0, Object v1);

  /// No description provided for @metric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get metric;

  /// No description provided for @scale.
  ///
  /// In en, this message translates to:
  /// **'Scale: {v0}'**
  String scale(Object v0);

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @daysRecorded.
  ///
  /// In en, this message translates to:
  /// **'{v0} days recorded'**
  String daysRecorded(Object v0);

  /// No description provided for @changeMetricCurrently.
  ///
  /// In en, this message translates to:
  /// **'Change metric, currently {v0}'**
  String changeMetricCurrently(Object v0);

  /// No description provided for @activityHeatmapForPastYear.
  ///
  /// In en, this message translates to:
  /// **'Activity heatmap for {v0}. Past year: {v1} {v2}.'**
  String activityHeatmapForPastYear(Object v0, Object v1, Object v2);

  /// No description provided for @less.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get less;

  /// No description provided for @moreBuild.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreBuild;

  /// No description provided for @yearBuild.
  ///
  /// In en, this message translates to:
  /// **'Year: {v0} {v1}'**
  String yearBuild(Object v0, Object v1);

  /// No description provided for @monthPaint.
  ///
  /// In en, this message translates to:
  /// **'Month {v0}'**
  String monthPaint(Object v0);

  /// No description provided for @tablesTablename.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get tablesTablename;

  /// No description provided for @rowsAdded.
  ///
  /// In en, this message translates to:
  /// **'{v0}: {v1} rows added'**
  String rowsAdded(Object v0, Object v1);

  /// No description provided for @noActivityThisDay.
  ///
  /// In en, this message translates to:
  /// **'No activity this day.'**
  String get noActivityThisDay;

  /// No description provided for @formattedValueBuild5.
  ///
  /// In en, this message translates to:
  /// **'{v2}, {v0}/{v1}'**
  String formattedValueBuild5(Object v0, Object v1, Object v2);

  /// No description provided for @noMatchingTasksBuild.
  ///
  /// In en, this message translates to:
  /// **'No matching tasks'**
  String get noMatchingTasksBuild;

  /// No description provided for @noTasksOnThisDay.
  ///
  /// In en, this message translates to:
  /// **'No tasks on this day'**
  String get noTasksOnThisDay;

  /// No description provided for @createdVsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Created vs. completed'**
  String get createdVsCompleted;

  /// No description provided for @weeks.
  ///
  /// In en, this message translates to:
  /// **'{v0} weeks'**
  String weeks(Object v0);

  /// No description provided for @changePeriod.
  ///
  /// In en, this message translates to:
  /// **'Change period'**
  String get changePeriod;

  /// No description provided for @trendsAppearAfterTwoWeeksOfActivity.
  ///
  /// In en, this message translates to:
  /// **'Trends appear after two weeks of activity.'**
  String get trendsAppearAfterTwoWeeksOfActivity;

  /// No description provided for @thisWeekCreatedCompleted.
  ///
  /// In en, this message translates to:
  /// **'This week: {v0} created, {v1} completed'**
  String thisWeekCreatedCompleted(Object v0, Object v1);

  /// No description provided for @lastWeeksCreatedCompleted.
  ///
  /// In en, this message translates to:
  /// **'Last {v0} weeks: {v1} created, {v2} completed'**
  String lastWeeksCreatedCompleted(Object v0, Object v1, Object v2);

  /// No description provided for @completeComparedWithLastPeriod.
  ///
  /// In en, this message translates to:
  /// **'{v0}% complete, compared with last period: '**
  String completeComparedWithLastPeriod(Object v0);

  /// No description provided for @noChange.
  ///
  /// In en, this message translates to:
  /// **'No change'**
  String get noChange;

  /// No description provided for @weekCreatedCompleted.
  ///
  /// In en, this message translates to:
  /// **'Week {v0}: {v1} created, {v2} completed'**
  String weekCreatedCompleted(Object v0, Object v1, Object v2);

  /// No description provided for @noDueTime.
  ///
  /// In en, this message translates to:
  /// **'No due time'**
  String get noDueTime;

  /// No description provided for @dueAt.
  ///
  /// In en, this message translates to:
  /// **'Due at {v0}:{v1}'**
  String dueAt(Object v0, Object v1);

  /// No description provided for @markIncompleteBuild.
  ///
  /// In en, this message translates to:
  /// **'Mark incomplete: {v0}'**
  String markIncompleteBuild(Object v0);

  /// No description provided for @completeBuild2.
  ///
  /// In en, this message translates to:
  /// **'Complete: {v0}'**
  String completeBuild2(Object v0);

  /// No description provided for @noFiltersShowingAll.
  ///
  /// In en, this message translates to:
  /// **'No filters, showing all'**
  String get noFiltersShowingAll;

  /// No description provided for @filteredByChartsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Filtered by {v0}. Charts updated.'**
  String filteredByChartsUpdated(Object v0);

  /// No description provided for @selectedDoubleTapToClear.
  ///
  /// In en, this message translates to:
  /// **'Selected. Double-tap to clear.'**
  String get selectedDoubleTapToClear;

  /// No description provided for @filterBuild.
  ///
  /// In en, this message translates to:
  /// **'Filter: {v0}, {v1}'**
  String filterBuild(Object v0, Object v1);

  /// No description provided for @closeModelAccount.
  ///
  /// In en, this message translates to:
  /// **'Close model account'**
  String get closeModelAccount;

  /// No description provided for @toworkQuickAsk.
  ///
  /// In en, this message translates to:
  /// **'ToWork Quick Ask'**
  String get toworkQuickAsk;

  /// No description provided for @generatingInBackground.
  ///
  /// In en, this message translates to:
  /// **'Generating in background'**
  String get generatingInBackground;

  /// No description provided for @newChatHeader.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get newChatHeader;

  /// No description provided for @openInTowork.
  ///
  /// In en, this message translates to:
  /// **'Open in ToWork'**
  String get openInTowork;

  /// No description provided for @whatsLeftToday.
  ///
  /// In en, this message translates to:
  /// **'What’s left today?'**
  String get whatsLeftToday;

  /// No description provided for @whatElseDoINeedToDo.
  ///
  /// In en, this message translates to:
  /// **'What else do I need to do today?'**
  String get whatElseDoINeedToDo;

  /// No description provided for @addATask.
  ///
  /// In en, this message translates to:
  /// **'Add a task'**
  String get addATask;

  /// No description provided for @helpMeAddATask.
  ///
  /// In en, this message translates to:
  /// **'Help me add a task:'**
  String get helpMeAddATask;

  /// No description provided for @whatDidIDoThisWeek.
  ///
  /// In en, this message translates to:
  /// **'What did I do this week?'**
  String get whatDidIDoThisWeek;

  /// No description provided for @summarizeWhatICompletedThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Summarize what I completed this week'**
  String get summarizeWhatICompletedThisWeek;

  /// No description provided for @saveAsTask.
  ///
  /// In en, this message translates to:
  /// **'Save as task'**
  String get saveAsTask;

  /// No description provided for @turnThisIntoATask.
  ///
  /// In en, this message translates to:
  /// **'Turn this into a task:\n{v0}'**
  String turnThisIntoATask(Object v0);

  /// No description provided for @summarize.
  ///
  /// In en, this message translates to:
  /// **'Summarize'**
  String get summarize;

  /// No description provided for @summarizeTheseKeyPoints.
  ///
  /// In en, this message translates to:
  /// **'Summarize these key points:\n{v0}'**
  String summarizeTheseKeyPoints(Object v0);

  /// No description provided for @workWithThisText.
  ///
  /// In en, this message translates to:
  /// **'Work with this text'**
  String get workWithThisText;

  /// No description provided for @couldntOpenTheWorkspaceYourDataIs.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open the workspace. Your data is safe.'**
  String get couldntOpenTheWorkspaceYourDataIs;

  /// No description provided for @closeProfile.
  ///
  /// In en, this message translates to:
  /// **'Close profile'**
  String get closeProfile;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @thisPageMayHaveMovedOrBeen.
  ///
  /// In en, this message translates to:
  /// **'This page may have moved or been deleted.'**
  String get thisPageMayHaveMovedOrBeen;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHome;

  /// No description provided for @toworkAvailable.
  ///
  /// In en, this message translates to:
  /// **'ToWork {v0} available'**
  String toworkAvailable(Object v0);

  /// No description provided for @restoreBaseVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'Restore base version available'**
  String get restoreBaseVersionAvailable;

  /// No description provided for @patchPAvailable.
  ///
  /// In en, this message translates to:
  /// **'Patch P{v0} available'**
  String patchPAvailable(Object v0);

  /// No description provided for @viewUpdate.
  ///
  /// In en, this message translates to:
  /// **'{v0}, view update'**
  String viewUpdate(Object v0);

  /// No description provided for @viewUpdateBuild.
  ///
  /// In en, this message translates to:
  /// **'View update'**
  String get viewUpdateBuild;

  /// No description provided for @remindMeLater.
  ///
  /// In en, this message translates to:
  /// **'Remind me later'**
  String get remindMeLater;

  /// No description provided for @expandSidebar.
  ///
  /// In en, this message translates to:
  /// **'Expand sidebar'**
  String get expandSidebar;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @weekdaySunday.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySunday;

  /// No description provided for @windowHours.
  ///
  /// In en, this message translates to:
  /// **'{v0, plural, =1{1 hour} other{{v0} hours}}'**
  String windowHours(int v0);

  /// No description provided for @windowDays.
  ///
  /// In en, this message translates to:
  /// **'{v0, plural, =1{1 day} other{{v0} days}}'**
  String windowDays(int v0);

  /// No description provided for @windowMinutes.
  ///
  /// In en, this message translates to:
  /// **'{v0, plural, =1{1 minute} other{{v0} minutes}}'**
  String windowMinutes(int v0);

  /// No description provided for @defaultNickname.
  ///
  /// In en, this message translates to:
  /// **'Local user'**
  String get defaultNickname;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

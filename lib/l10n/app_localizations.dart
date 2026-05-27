import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('pt')
  ];

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @languageSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Language saved successfully'**
  String get languageSavedSuccessfully;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @suspendAccount.
  ///
  /// In en, this message translates to:
  /// **'Suspend account'**
  String get suspendAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Please note that deleting your account will permanently remove all data, including your subscription history and settings.'**
  String get deleteAccountDescription;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @suspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get suspend;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @accountDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get accountDeletedSuccessfully;

  /// No description provided for @accountSuspendedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account suspended successfully'**
  String get accountSuspendedSuccessfully;

  /// No description provided for @accountDeletionError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while trying to delete your account'**
  String get accountDeletionError;

  /// No description provided for @accountSuspensionError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while trying to suspend your account'**
  String get accountSuspensionError;

  /// No description provided for @raceHistory.
  ///
  /// In en, this message translates to:
  /// **'Race history'**
  String get raceHistory;

  /// No description provided for @noRaceHistory.
  ///
  /// In en, this message translates to:
  /// **'You have no race history'**
  String get noRaceHistory;

  /// No description provided for @informationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Information not available'**
  String get informationNotAvailable;

  /// No description provided for @raceId.
  ///
  /// In en, this message translates to:
  /// **'Race ID'**
  String get raceId;

  /// No description provided for @errorLoadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Error loading history'**
  String get errorLoadingHistory;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and conditions'**
  String get termsAndConditions;

  /// No description provided for @ourTermsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Our terms and conditions'**
  String get ourTermsAndConditions;

  /// No description provided for @privacyPolicies.
  ///
  /// In en, this message translates to:
  /// **'Privacy policies'**
  String get privacyPolicies;

  /// No description provided for @noInscriptionsYet.
  ///
  /// In en, this message translates to:
  /// **'You have no inscriptions yet'**
  String get noInscriptionsYet;

  /// No description provided for @tapForMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap for more details (coming soon)'**
  String get tapForMoreDetails;

  /// No description provided for @errorLoadingInscriptions.
  ///
  /// In en, this message translates to:
  /// **'Error loading inscriptions'**
  String get errorLoadingInscriptions;

  /// No description provided for @inscriptionIdNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Inscription ID not available'**
  String get inscriptionIdNotAvailable;

  /// No description provided for @inscriptionIdNotReceived.
  ///
  /// In en, this message translates to:
  /// **'Inscription ID not received'**
  String get inscriptionIdNotReceived;

  /// No description provided for @paymentCanceled.
  ///
  /// In en, this message translates to:
  /// **'Payment has been canceled. Please try again.'**
  String get paymentCanceled;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @areYouSureYouWantToLogOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get areYouSureYouWantToLogOut;

  /// No description provided for @deleteAccountNote.
  ///
  /// In en, this message translates to:
  /// **'If you are sure you want to continue, click the \"Delete account\" button below. If you want to cancel this action, simply close this dialog.'**
  String get deleteAccountNote;

  /// No description provided for @connectionEstablishedUpdatingRaces.
  ///
  /// In en, this message translates to:
  /// **'Connection established, updating races...'**
  String get connectionEstablishedUpdatingRaces;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @runs.
  ///
  /// In en, this message translates to:
  /// **'Races'**
  String get runs;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @networkErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Network error occurred. Please check your connection.'**
  String get networkErrorMessage;

  /// No description provided for @timeoutErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again later.'**
  String get timeoutErrorMessage;

  /// No description provided for @myInscriptions.
  ///
  /// In en, this message translates to:
  /// **'My Inscriptions'**
  String get myInscriptions;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noRacesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No races available'**
  String get noRacesAvailable;

  /// No description provided for @priceFrom.
  ///
  /// In en, this message translates to:
  /// **'Price from'**
  String get priceFrom;

  /// No description provided for @viewMore.
  ///
  /// In en, this message translates to:
  /// **'View more'**
  String get viewMore;

  /// No description provided for @jan.
  ///
  /// In en, this message translates to:
  /// **'JAN'**
  String get jan;

  /// No description provided for @feb.
  ///
  /// In en, this message translates to:
  /// **'FEB'**
  String get feb;

  /// No description provided for @mar.
  ///
  /// In en, this message translates to:
  /// **'MAR'**
  String get mar;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'APR'**
  String get apr;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'MAY'**
  String get may;

  /// No description provided for @jun.
  ///
  /// In en, this message translates to:
  /// **'JUN'**
  String get jun;

  /// No description provided for @jul.
  ///
  /// In en, this message translates to:
  /// **'JUL'**
  String get jul;

  /// No description provided for @aug.
  ///
  /// In en, this message translates to:
  /// **'AUG'**
  String get aug;

  /// No description provided for @sep.
  ///
  /// In en, this message translates to:
  /// **'SEP'**
  String get sep;

  /// No description provided for @oct.
  ///
  /// In en, this message translates to:
  /// **'OCT'**
  String get oct;

  /// No description provided for @nov.
  ///
  /// In en, this message translates to:
  /// **'NOV'**
  String get nov;

  /// No description provided for @dec.
  ///
  /// In en, this message translates to:
  /// **'DEC'**
  String get dec;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get sun;

  /// No description provided for @selectMonthAndYear.
  ///
  /// In en, this message translates to:
  /// **'Select month and year'**
  String get selectMonthAndYear;

  /// No description provided for @upcomingRaces.
  ///
  /// In en, this message translates to:
  /// **'Upcoming races'**
  String get upcomingRaces;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @mayFull.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get mayFull;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @imagePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Image not available'**
  String get imagePlaceholder;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @aboutTheCompetition.
  ///
  /// In en, this message translates to:
  /// **'About the competition'**
  String get aboutTheCompetition;

  /// No description provided for @readLess.
  ///
  /// In en, this message translates to:
  /// **'Read less'**
  String get readLess;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @sponsors.
  ///
  /// In en, this message translates to:
  /// **'Sponsors'**
  String get sponsors;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get openInMaps;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @couldNotOpenMapsApp.
  ///
  /// In en, this message translates to:
  /// **'Could not open maps application'**
  String get couldNotOpenMapsApp;

  /// No description provided for @inscription.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get inscription;

  /// No description provided for @exitWithoutSaving.
  ///
  /// In en, this message translates to:
  /// **'Exit without saving?'**
  String get exitWithoutSaving;

  /// No description provided for @youHave.
  ///
  /// In en, this message translates to:
  /// **'You have'**
  String get youHave;

  /// No description provided for @registeredParticipantPlural.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{registered participant} other{registered participants}}'**
  String registeredParticipantPlural(int count);

  /// No description provided for @ifYouLeaveNowYouWillLoseChanges.
  ///
  /// In en, this message translates to:
  /// **'If you leave now, you will lose all changes.'**
  String get ifYouLeaveNowYouWillLoseChanges;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @pleaseSelectACategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectACategory;

  /// No description provided for @pleaseSelectADistance.
  ///
  /// In en, this message translates to:
  /// **'Please select a distance'**
  String get pleaseSelectADistance;

  /// No description provided for @pleaseSelectGender.
  ///
  /// In en, this message translates to:
  /// **'Please select gender'**
  String get pleaseSelectGender;

  /// No description provided for @pleaseSelectASize.
  ///
  /// In en, this message translates to:
  /// **'Please select a size'**
  String get pleaseSelectASize;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @pleaseEnterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get pleaseEnterYourFullName;

  /// No description provided for @pleaseEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterYourEmail;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @selectDistance.
  ///
  /// In en, this message translates to:
  /// **'Select distance'**
  String get selectDistance;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @chooseGender.
  ///
  /// In en, this message translates to:
  /// **'Choose gender'**
  String get chooseGender;

  /// No description provided for @selectTshirtSize.
  ///
  /// In en, this message translates to:
  /// **'Select t-shirt size'**
  String get selectTshirtSize;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @availableDistances.
  ///
  /// In en, this message translates to:
  /// **'available distances'**
  String get availableDistances;

  /// No description provided for @documentType.
  ///
  /// In en, this message translates to:
  /// **'{type, select, Cedula{ID} Pasaporte{Pass.} RUC{RUC} other{Type}}'**
  String documentType(String type);

  /// No description provided for @number.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get number;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get requiredField;

  /// No description provided for @mustHave10Digits.
  ///
  /// In en, this message translates to:
  /// **'Must have 10 digits'**
  String get mustHave10Digits;

  /// No description provided for @minimum6Characters.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get minimum6Characters;

  /// No description provided for @mustHave13Digits.
  ///
  /// In en, this message translates to:
  /// **'Must have 13 digits'**
  String get mustHave13Digits;

  /// No description provided for @cellPhone.
  ///
  /// In en, this message translates to:
  /// **'Cell phone'**
  String get cellPhone;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @selectYourCountry.
  ///
  /// In en, this message translates to:
  /// **'Select your country'**
  String get selectYourCountry;

  /// No description provided for @searchCountry.
  ///
  /// In en, this message translates to:
  /// **'Search country'**
  String get searchCountry;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get notSelected;

  /// No description provided for @notRegistered.
  ///
  /// In en, this message translates to:
  /// **'Not registered'**
  String get notRegistered;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @registerAnotherPerson.
  ///
  /// In en, this message translates to:
  /// **'Register another person'**
  String get registerAnotherPerson;

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get confirmDeletion;

  /// No description provided for @areYouSureToDeleteParticipant.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String areYouSureToDeleteParticipant(String name);

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'deleted'**
  String get deleted;

  /// No description provided for @totalIncludingVAT.
  ///
  /// In en, this message translates to:
  /// **'Total (VAT incl.)'**
  String get totalIncludingVAT;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @participantAdded.
  ///
  /// In en, this message translates to:
  /// **'Participant added'**
  String get participantAdded;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @enterYourLastName.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get enterYourLastName;

  /// No description provided for @pleaseEnterYourLastName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your last name'**
  String get pleaseEnterYourLastName;

  /// No description provided for @selectYourDocumentType.
  ///
  /// In en, this message translates to:
  /// **'Select your document type'**
  String get selectYourDocumentType;

  /// No description provided for @pleaseSelectYourDocumentType.
  ///
  /// In en, this message translates to:
  /// **'Please select your document type'**
  String get pleaseSelectYourDocumentType;

  /// No description provided for @idNumber.
  ///
  /// In en, this message translates to:
  /// **'ID number'**
  String get idNumber;

  /// No description provided for @rucNumber.
  ///
  /// In en, this message translates to:
  /// **'RUC number'**
  String get rucNumber;

  /// No description provided for @passportNumber.
  ///
  /// In en, this message translates to:
  /// **'Passport number'**
  String get passportNumber;

  /// No description provided for @enterYourIdNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your ID number'**
  String get enterYourIdNumber;

  /// No description provided for @enterYourRucNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your RUC number'**
  String get enterYourRucNumber;

  /// No description provided for @enterYourPassportNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your passport number'**
  String get enterYourPassportNumber;

  /// No description provided for @pleaseEnterYourDocumentNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your document number'**
  String get pleaseEnterYourDocumentNumber;

  /// No description provided for @invalidIdNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid ID number'**
  String get invalidIdNumber;

  /// No description provided for @invalidRucNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid RUC number'**
  String get invalidRucNumber;

  /// No description provided for @invalidPassportNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid passport number'**
  String get invalidPassportNumber;

  /// No description provided for @cellphone.
  ///
  /// In en, this message translates to:
  /// **'Cellphone'**
  String get cellphone;

  /// No description provided for @enterYourCellphone.
  ///
  /// In en, this message translates to:
  /// **'Enter your cellphone number'**
  String get enterYourCellphone;

  /// No description provided for @pleaseEnterYourCellphone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your cellphone number'**
  String get pleaseEnterYourCellphone;

  /// No description provided for @invalidCellphone.
  ///
  /// In en, this message translates to:
  /// **'Invalid cellphone number'**
  String get invalidCellphone;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @errorUpdatingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile'**
  String get errorUpdatingProfile;

  /// No description provided for @billingData.
  ///
  /// In en, this message translates to:
  /// **'Billing data'**
  String get billingData;

  /// No description provided for @billingInformation.
  ///
  /// In en, this message translates to:
  /// **'Billing information'**
  String get billingInformation;

  /// No description provided for @businessNameOrFullName.
  ///
  /// In en, this message translates to:
  /// **'Business name / Full name'**
  String get businessNameOrFullName;

  /// No description provided for @pleaseEnterNameForInvoice.
  ///
  /// In en, this message translates to:
  /// **'Please enter the name for the invoice'**
  String get pleaseEnterNameForInvoice;

  /// No description provided for @idRucOrPassport.
  ///
  /// In en, this message translates to:
  /// **'ID, RUC or passport'**
  String get idRucOrPassport;

  /// No description provided for @pleaseEnterDocumentNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a document number'**
  String get pleaseEnterDocumentNumber;

  /// No description provided for @invalidDocumentNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid document number'**
  String get invalidDocumentNumber;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @pleaseEnterAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter an address'**
  String get pleaseEnterAddress;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalidPhoneNumber;

  /// No description provided for @updatingBillingData.
  ///
  /// In en, this message translates to:
  /// **'Updating billing data...'**
  String get updatingBillingData;

  /// No description provided for @billingDataUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Billing data updated successfully'**
  String get billingDataUpdatedSuccessfully;

  /// No description provided for @continueToPayment.
  ///
  /// In en, this message translates to:
  /// **'Continue to payment'**
  String get continueToPayment;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @competitionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Competition not found'**
  String get competitionNotFound;

  /// No description provided for @errorLoadingCompetition.
  ///
  /// In en, this message translates to:
  /// **'Error loading competition'**
  String get errorLoadingCompetition;

  /// No description provided for @loadingCompetitionDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading competition details...'**
  String get loadingCompetitionDetails;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

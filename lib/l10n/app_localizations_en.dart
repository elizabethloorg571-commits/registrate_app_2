// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'Language';

  @override
  String get save => 'Save';

  @override
  String get languageSavedSuccessfully => 'Language saved successfully';

  @override
  String get account => 'Account';

  @override
  String get name => 'Name';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get gender => 'Gender';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get suspendAccount => 'Suspend account';

  @override
  String get deleteAccountTitle => 'Are you sure you want to delete your account?';

  @override
  String get deleteAccountWarning => 'This action cannot be undone.';

  @override
  String get deleteAccountDescription => 'Please note that deleting your account will permanently remove all data, including your subscription history and settings.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get suspend => 'Suspend';

  @override
  String get accept => 'Accept';

  @override
  String get accountDeletedSuccessfully => 'Account deleted successfully';

  @override
  String get accountSuspendedSuccessfully => 'Account suspended successfully';

  @override
  String get accountDeletionError => 'An error occurred while trying to delete your account';

  @override
  String get accountSuspensionError => 'An error occurred while trying to suspend your account';

  @override
  String get raceHistory => 'Race history';

  @override
  String get noRaceHistory => 'You have no race history';

  @override
  String get informationNotAvailable => 'Information not available';

  @override
  String get raceId => 'Race ID';

  @override
  String get errorLoadingHistory => 'Error loading history';

  @override
  String get termsAndConditions => 'Terms and conditions';

  @override
  String get ourTermsAndConditions => 'Our terms and conditions';

  @override
  String get privacyPolicies => 'Privacy policies';

  @override
  String get noInscriptionsYet => 'You have no inscriptions yet';

  @override
  String get tapForMoreDetails => 'Tap for more details (coming soon)';

  @override
  String get errorLoadingInscriptions => 'Error loading inscriptions';

  @override
  String get inscriptionIdNotAvailable => 'Inscription ID not available';

  @override
  String get inscriptionIdNotReceived => 'Inscription ID not received';

  @override
  String get paymentCanceled => 'Payment has been canceled. Please try again.';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get profile => 'Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String get logout => 'Log out';

  @override
  String get areYouSureYouWantToLogOut => 'Are you sure you want to log out?';

  @override
  String get deleteAccountNote => 'If you are sure you want to continue, click the \"Delete account\" button below. If you want to cancel this action, simply close this dialog.';

  @override
  String get connectionEstablishedUpdatingRaces => 'Connection established, updating races...';

  @override
  String get home => 'Home';

  @override
  String get runs => 'Races';

  @override
  String get type => 'Type';

  @override
  String get networkErrorMessage => 'Network error occurred. Please check your connection.';

  @override
  String get timeoutErrorMessage => 'Request timed out. Please try again later.';

  @override
  String get myInscriptions => 'My Inscriptions';

  @override
  String get all => 'All';

  @override
  String get noRacesAvailable => 'No races available';

  @override
  String get priceFrom => 'Price from';

  @override
  String get viewMore => 'View more';

  @override
  String get jan => 'JAN';

  @override
  String get feb => 'FEB';

  @override
  String get mar => 'MAR';

  @override
  String get apr => 'APR';

  @override
  String get may => 'MAY';

  @override
  String get jun => 'JUN';

  @override
  String get jul => 'JUL';

  @override
  String get aug => 'AUG';

  @override
  String get sep => 'SEP';

  @override
  String get oct => 'OCT';

  @override
  String get nov => 'NOV';

  @override
  String get dec => 'DEC';

  @override
  String get calendar => 'Calendar';

  @override
  String get mon => 'M';

  @override
  String get tue => 'T';

  @override
  String get wed => 'W';

  @override
  String get thu => 'T';

  @override
  String get fri => 'F';

  @override
  String get sat => 'S';

  @override
  String get sun => 'S';

  @override
  String get selectMonthAndYear => 'Select month and year';

  @override
  String get upcomingRaces => 'Upcoming races';

  @override
  String get viewAll => 'View all';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get mayFull => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get imagePlaceholder => 'Image not available';

  @override
  String get date => 'Date';

  @override
  String get location => 'Location';

  @override
  String get aboutTheCompetition => 'About the competition';

  @override
  String get readLess => 'Read less';

  @override
  String get readMore => 'Read more';

  @override
  String get sponsors => 'Sponsors';

  @override
  String get loading => 'Loading';

  @override
  String get openInMaps => 'Open in Maps';

  @override
  String get register => 'Register';

  @override
  String get couldNotOpenMapsApp => 'Could not open maps application';

  @override
  String get inscription => 'Registration';

  @override
  String get exitWithoutSaving => 'Exit without saving?';

  @override
  String get youHave => 'You have';

  @override
  String registeredParticipantPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'registered participants',
      one: 'registered participant',
    );
    return '$_temp0';
  }

  @override
  String get ifYouLeaveNowYouWillLoseChanges => 'If you leave now, you will lose all changes.';

  @override
  String get exit => 'Exit';

  @override
  String get pleaseSelectACategory => 'Please select a category';

  @override
  String get pleaseSelectADistance => 'Please select a distance';

  @override
  String get pleaseSelectGender => 'Please select gender';

  @override
  String get pleaseSelectASize => 'Please select a size';

  @override
  String get fullName => 'Full name';

  @override
  String get pleaseEnterYourFullName => 'Please enter your full name';

  @override
  String get pleaseEnterYourEmail => 'Please enter your email';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get selectDistance => 'Select distance';

  @override
  String get select => 'Select';

  @override
  String get chooseGender => 'Choose gender';

  @override
  String get selectTshirtSize => 'Select t-shirt size';

  @override
  String get category => 'Category';

  @override
  String get availableDistances => 'available distances';

  @override
  String documentType(String type) {
    String _temp0 = intl.Intl.selectLogic(
      type,
      {
        'Cedula': 'ID',
        'Pasaporte': 'Pass.',
        'RUC': 'RUC',
        'other': 'Type',
      },
    );
    return '$_temp0';
  }

  @override
  String get number => 'Number';

  @override
  String get requiredField => 'Required field';

  @override
  String get mustHave10Digits => 'Must have 10 digits';

  @override
  String get minimum6Characters => 'Minimum 6 characters';

  @override
  String get mustHave13Digits => 'Must have 13 digits';

  @override
  String get cellPhone => 'Cell phone';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String get selectYourCountry => 'Select your country';

  @override
  String get searchCountry => 'Search country';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get notSelected => 'Not selected';

  @override
  String get notRegistered => 'Not registered';

  @override
  String get change => 'Change';

  @override
  String get registerAnotherPerson => 'Register another person';

  @override
  String get confirmDeletion => 'Confirm deletion';

  @override
  String areYouSureToDeleteParticipant(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get deleted => 'deleted';

  @override
  String get totalIncludingVAT => 'Total (VAT incl.)';

  @override
  String get update => 'Update';

  @override
  String get participantAdded => 'Participant added';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get pleaseEnterYourName => 'Please enter your name';

  @override
  String get lastName => 'Last name';

  @override
  String get enterYourLastName => 'Enter your last name';

  @override
  String get pleaseEnterYourLastName => 'Please enter your last name';

  @override
  String get selectYourDocumentType => 'Select your document type';

  @override
  String get pleaseSelectYourDocumentType => 'Please select your document type';

  @override
  String get idNumber => 'ID number';

  @override
  String get rucNumber => 'RUC number';

  @override
  String get passportNumber => 'Passport number';

  @override
  String get enterYourIdNumber => 'Enter your ID number';

  @override
  String get enterYourRucNumber => 'Enter your RUC number';

  @override
  String get enterYourPassportNumber => 'Enter your passport number';

  @override
  String get pleaseEnterYourDocumentNumber => 'Please enter your document number';

  @override
  String get invalidIdNumber => 'Invalid ID number';

  @override
  String get invalidRucNumber => 'Invalid RUC number';

  @override
  String get invalidPassportNumber => 'Invalid passport number';

  @override
  String get cellphone => 'Cellphone';

  @override
  String get enterYourCellphone => 'Enter your cellphone number';

  @override
  String get pleaseEnterYourCellphone => 'Please enter your cellphone number';

  @override
  String get invalidCellphone => 'Invalid cellphone number';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully';

  @override
  String get errorUpdatingProfile => 'Error updating profile';

  @override
  String get billingData => 'Billing data';

  @override
  String get billingInformation => 'Billing information';

  @override
  String get businessNameOrFullName => 'Business name / Full name';

  @override
  String get pleaseEnterNameForInvoice => 'Please enter the name for the invoice';

  @override
  String get idRucOrPassport => 'ID, RUC or passport';

  @override
  String get pleaseEnterDocumentNumber => 'Please enter a document number';

  @override
  String get invalidDocumentNumber => 'Invalid document number';

  @override
  String get address => 'Address';

  @override
  String get pleaseEnterAddress => 'Please enter an address';

  @override
  String get phone => 'Phone';

  @override
  String get invalidPhoneNumber => 'Invalid phone number';

  @override
  String get updatingBillingData => 'Updating billing data...';

  @override
  String get billingDataUpdatedSuccessfully => 'Billing data updated successfully';

  @override
  String get continueToPayment => 'Continue to payment';

  @override
  String get retry => 'Retry';

  @override
  String get goBack => 'Go back';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get competitionNotFound => 'Competition not found';

  @override
  String get errorLoadingCompetition => 'Error loading competition';

  @override
  String get loadingCompetitionDetails => 'Loading competition details...';
}

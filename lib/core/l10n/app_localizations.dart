import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// The product name; never translated.
  ///
  /// In en, this message translates to:
  /// **'Salala'**
  String get appTitle;

  /// No description provided for @navAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get navAnimals;

  /// No description provided for @navLitters.
  ///
  /// In en, this message translates to:
  /// **'Litters'**
  String get navLitters;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No animals yet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first dog or cat to start a health and lineage record.'**
  String get homeEmptyBody;

  /// No description provided for @homeAddAnimal.
  ///
  /// In en, this message translates to:
  /// **'Add animal'**
  String get homeAddAnimal;

  /// No description provided for @homeBreedingStock.
  ///
  /// In en, this message translates to:
  /// **'Breeding stock'**
  String get homeBreedingStock;

  /// No description provided for @homeAllAnimals.
  ///
  /// In en, this message translates to:
  /// **'All animals'**
  String get homeAllAnimals;

  /// No description provided for @homeAnimalCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No animals} =1{1 animal} other{{count} animals}}'**
  String homeAnimalCount(int count);

  /// No description provided for @animalName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get animalName;

  /// No description provided for @animalSpecies.
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get animalSpecies;

  /// No description provided for @animalBreed.
  ///
  /// In en, this message translates to:
  /// **'Breed'**
  String get animalBreed;

  /// No description provided for @animalSex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get animalSex;

  /// No description provided for @animalBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get animalBirthDate;

  /// No description provided for @animalStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get animalStatus;

  /// No description provided for @animalMicrochip.
  ///
  /// In en, this message translates to:
  /// **'Microchip number'**
  String get animalMicrochip;

  /// No description provided for @animalRegistrationNo.
  ///
  /// In en, this message translates to:
  /// **'Registry number'**
  String get animalRegistrationNo;

  /// No description provided for @animalRegistry.
  ///
  /// In en, this message translates to:
  /// **'Registry'**
  String get animalRegistry;

  /// No description provided for @animalColor.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get animalColor;

  /// No description provided for @animalNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get animalNotes;

  /// No description provided for @animalIsBreedingStock.
  ///
  /// In en, this message translates to:
  /// **'Keep as breeding stock'**
  String get animalIsBreedingStock;

  /// No description provided for @animalAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add animal'**
  String get animalAddTitle;

  /// No description provided for @animalEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit animal'**
  String get animalEditTitle;

  /// No description provided for @animalDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String animalDeleteTitle(String name);

  /// No description provided for @animalDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Its vaccinations, health tests, weights and visits are deleted too. This cannot be undone.'**
  String get animalDeleteBody;

  /// No description provided for @animalNameRequired.
  ///
  /// In en, this message translates to:
  /// **'A name is required'**
  String get animalNameRequired;

  /// No description provided for @animalSpeciesRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a species'**
  String get animalSpeciesRequired;

  /// No description provided for @sexMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get sexMale;

  /// No description provided for @sexFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get sexFemale;

  /// No description provided for @sexUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get sexUnknown;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'With me'**
  String get statusActive;

  /// No description provided for @statusSold.
  ///
  /// In en, this message translates to:
  /// **'Placed'**
  String get statusSold;

  /// No description provided for @statusRetired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get statusRetired;

  /// No description provided for @statusDeceased.
  ///
  /// In en, this message translates to:
  /// **'Deceased'**
  String get statusDeceased;

  /// No description provided for @recordsVaccinations.
  ///
  /// In en, this message translates to:
  /// **'Vaccinations'**
  String get recordsVaccinations;

  /// No description provided for @recordsHealthTests.
  ///
  /// In en, this message translates to:
  /// **'Health tests'**
  String get recordsHealthTests;

  /// No description provided for @recordsWeights.
  ///
  /// In en, this message translates to:
  /// **'Weights'**
  String get recordsWeights;

  /// No description provided for @recordsVisits.
  ///
  /// In en, this message translates to:
  /// **'Vet visits'**
  String get recordsVisits;

  /// No description provided for @recordsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded yet.'**
  String get recordsEmpty;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @lockTitle.
  ///
  /// In en, this message translates to:
  /// **'Salala is locked'**
  String get lockTitle;

  /// No description provided for @lockEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get lockEnterPin;

  /// No description provided for @lockUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get lockUnlock;

  /// No description provided for @lockWrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN'**
  String get lockWrongPin;

  /// No description provided for @lockSetPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a PIN'**
  String get lockSetPinTitle;

  /// No description provided for @lockSetPinBody.
  ///
  /// In en, this message translates to:
  /// **'Four digits or more. It stays on this device and cannot be recovered, so write it down.'**
  String get lockSetPinBody;

  /// No description provided for @lockConfirmPin.
  ///
  /// In en, this message translates to:
  /// **'Repeat the PIN'**
  String get lockConfirmPin;

  /// No description provided for @lockPinTooShort.
  ///
  /// In en, this message translates to:
  /// **'Four digits or more'**
  String get lockPinTooShort;

  /// No description provided for @lockPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two PINs do not match'**
  String get lockPinMismatch;

  /// No description provided for @lockEnable.
  ///
  /// In en, this message translates to:
  /// **'Lock the app'**
  String get lockEnable;

  /// No description provided for @lockDisable.
  ///
  /// In en, this message translates to:
  /// **'Turn the lock off'**
  String get lockDisable;

  /// No description provided for @lockCurrentPin.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get lockCurrentPin;

  /// No description provided for @settingsAppLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get settingsAppLock;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsBuildTag.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get settingsBuildTag;

  /// No description provided for @settingsOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'Everything is stored on this device. No account, no server, no tracking.'**
  String get settingsOfflineNote;

  /// No description provided for @settingsExport.
  ///
  /// In en, this message translates to:
  /// **'Export records'**
  String get settingsExport;

  /// No description provided for @settingsExportSoon.
  ///
  /// In en, this message translates to:
  /// **'PDF and JSON export arrive in Phase 2.'**
  String get settingsExportSoon;

  /// No description provided for @litterAdd.
  ///
  /// In en, this message translates to:
  /// **'New litter'**
  String get litterAdd;

  /// No description provided for @litterAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Register a litter'**
  String get litterAddTitle;

  /// No description provided for @litterEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No litters yet'**
  String get litterEmptyTitle;

  /// No description provided for @litterEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Record a mating to follow the pregnancy and register the puppies in one step.'**
  String get litterEmptyBody;

  /// No description provided for @litterName.
  ///
  /// In en, this message translates to:
  /// **'Litter name'**
  String get litterName;

  /// No description provided for @litterNameRequired.
  ///
  /// In en, this message translates to:
  /// **'A litter name is required'**
  String get litterNameRequired;

  /// No description provided for @litterDam.
  ///
  /// In en, this message translates to:
  /// **'Dam (mother)'**
  String get litterDam;

  /// No description provided for @litterDamRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose the dam'**
  String get litterDamRequired;

  /// No description provided for @litterDamMissing.
  ///
  /// In en, this message translates to:
  /// **'Dam removed'**
  String get litterDamMissing;

  /// No description provided for @litterSire.
  ///
  /// In en, this message translates to:
  /// **'Sire (father)'**
  String get litterSire;

  /// No description provided for @litterSireUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown sire'**
  String get litterSireUnknown;

  /// No description provided for @litterNoDams.
  ///
  /// In en, this message translates to:
  /// **'Mark a female as breeding stock first'**
  String get litterNoDams;

  /// No description provided for @litterMatingDate.
  ///
  /// In en, this message translates to:
  /// **'Mating date'**
  String get litterMatingDate;

  /// No description provided for @litterWhelpingDate.
  ///
  /// In en, this message translates to:
  /// **'Whelping date'**
  String get litterWhelpingDate;

  /// No description provided for @litterWeaningDate.
  ///
  /// In en, this message translates to:
  /// **'Weaning date'**
  String get litterWeaningDate;

  /// No description provided for @litterExpected.
  ///
  /// In en, this message translates to:
  /// **'Expected whelping: {date}'**
  String litterExpected(String date);

  /// No description provided for @litterPuppyCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No puppies registered} =1{1 puppy} other{{count} puppies}}'**
  String litterPuppyCount(int count);

  /// No description provided for @litterPuppiesToRegister.
  ///
  /// In en, this message translates to:
  /// **'Puppies born'**
  String get litterPuppiesToRegister;

  /// No description provided for @litterPuppiesHint.
  ///
  /// In en, this message translates to:
  /// **'Each puppy is added to your animals, named after the litter'**
  String get litterPuppiesHint;

  /// No description provided for @litterNoPuppies.
  ///
  /// In en, this message translates to:
  /// **'No puppies registered for this litter yet.'**
  String get litterNoPuppies;

  /// No description provided for @litterGone.
  ///
  /// In en, this message translates to:
  /// **'This litter was deleted.'**
  String get litterGone;

  /// No description provided for @litterDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String litterDeleteTitle(String name);

  /// No description provided for @litterDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The puppies stay in your animals; only the mating record is removed. This cannot be undone.'**
  String get litterDeleteBody;

  /// No description provided for @animalGone.
  ///
  /// In en, this message translates to:
  /// **'This animal was deleted.'**
  String get animalGone;

  /// No description provided for @animalDeathDate.
  ///
  /// In en, this message translates to:
  /// **'Died'**
  String get animalDeathDate;

  /// No description provided for @valueUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not recorded'**
  String get valueUnknown;

  /// No description provided for @recordDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this record?'**
  String get recordDeleteTitle;

  /// No description provided for @vaccinationAdd.
  ///
  /// In en, this message translates to:
  /// **'Add vaccination'**
  String get vaccinationAdd;

  /// No description provided for @vaccinationAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Log a vaccination'**
  String get vaccinationAddTitle;

  /// No description provided for @vaccinationEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit vaccination'**
  String get vaccinationEditTitle;

  /// No description provided for @vaccinationName.
  ///
  /// In en, this message translates to:
  /// **'Vaccine'**
  String get vaccinationName;

  /// No description provided for @vaccinationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'A vaccine name is required'**
  String get vaccinationNameRequired;

  /// No description provided for @vaccinationGiven.
  ///
  /// In en, this message translates to:
  /// **'Given'**
  String get vaccinationGiven;

  /// No description provided for @vaccinationNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next due'**
  String get vaccinationNextDue;

  /// No description provided for @vaccinationNextDueHint.
  ///
  /// In en, this message translates to:
  /// **'A dose whose next-due date has passed is marked overdue.'**
  String get vaccinationNextDueHint;

  /// No description provided for @vaccinationOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get vaccinationOverdue;

  /// No description provided for @vaccinationManufacturer.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer'**
  String get vaccinationManufacturer;

  /// No description provided for @vaccinationBatch.
  ///
  /// In en, this message translates to:
  /// **'Batch number'**
  String get vaccinationBatch;

  /// No description provided for @vaccinationVet.
  ///
  /// In en, this message translates to:
  /// **'Veterinarian'**
  String get vaccinationVet;

  /// No description provided for @vaccinationClinic.
  ///
  /// In en, this message translates to:
  /// **'Clinic'**
  String get vaccinationClinic;

  /// No description provided for @vaccinationCertificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate number'**
  String get vaccinationCertificate;

  /// No description provided for @vaccinationDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The dose is removed from this animal\'s history. This cannot be undone.'**
  String get vaccinationDeleteBody;

  /// No description provided for @weightAdd.
  ///
  /// In en, this message translates to:
  /// **'Add weight'**
  String get weightAdd;

  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKg;

  /// No description provided for @weightRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the weight'**
  String get weightRequired;

  /// No description provided for @weightInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a weight like 4.2'**
  String get weightInvalid;

  /// No description provided for @weightMeasuredOn.
  ///
  /// In en, this message translates to:
  /// **'Measured on'**
  String get weightMeasuredOn;

  /// No description provided for @weightNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get weightNote;

  /// No description provided for @weightDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The weigh-in is removed. This cannot be undone.'**
  String get weightDeleteBody;
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
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

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

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, number or chip'**
  String get homeSearchHint;

  /// No description provided for @homeNoMatches.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches “{query}”'**
  String homeNoMatches(String query);

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
  /// **'Its vaccinations, health tests, weights, visits and symptoms are deleted too. This cannot be undone.'**
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

  /// No description provided for @recordsSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get recordsSymptoms;

  /// No description provided for @recordsPlacements.
  ///
  /// In en, this message translates to:
  /// **'Placements'**
  String get recordsPlacements;

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

  /// No description provided for @actionReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get actionReplace;

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

  /// No description provided for @settingsExportBody.
  ///
  /// In en, this message translates to:
  /// **'One JSON file with every record on this phone'**
  String get settingsExportBody;

  /// No description provided for @settingsImport.
  ///
  /// In en, this message translates to:
  /// **'Restore from a pack'**
  String get settingsImport;

  /// No description provided for @settingsImportBody.
  ///
  /// In en, this message translates to:
  /// **'Read a pack back onto this phone'**
  String get settingsImportBody;

  /// No description provided for @packShared.
  ///
  /// In en, this message translates to:
  /// **'{file} is ready to send'**
  String packShared(String file);

  /// No description provided for @packShareFailed.
  ///
  /// In en, this message translates to:
  /// **'The pack could not be written on this phone'**
  String get packShareFailed;

  /// No description provided for @packReadFailed.
  ///
  /// In en, this message translates to:
  /// **'That file could not be opened'**
  String get packReadFailed;

  /// No description provided for @packNotAPack.
  ///
  /// In en, this message translates to:
  /// **'That file is not a Salala pack, or it is damaged'**
  String get packNotAPack;

  /// No description provided for @packFromTheFuture.
  ///
  /// In en, this message translates to:
  /// **'That pack comes from a newer Salala than this one'**
  String get packFromTheFuture;

  /// No description provided for @packIncomplete.
  ///
  /// In en, this message translates to:
  /// **'That pack is missing part of the ledger: {table}'**
  String packIncomplete(String table);

  /// No description provided for @packUnknownTable.
  ///
  /// In en, this message translates to:
  /// **'That pack holds a table this Salala does not know: {table}'**
  String packUnknownTable(String table);

  /// No description provided for @packRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace everything on this phone?'**
  String get packRestoreTitle;

  /// Labelled counts instead of a sentence: the numbers range from one animal to hundreds, and no language here agrees them all. The placeholder order below is the generated method's argument order.
  ///
  /// In en, this message translates to:
  /// **'From {day}. Animals: {animals}. Records: {rows}. Restoring replaces everything that is on this phone now.'**
  String packRestoreBody(int animals, int rows, String day);

  /// No description provided for @packRestored.
  ///
  /// In en, this message translates to:
  /// **'Records restored: {rows}'**
  String packRestored(int rows);

  /// No description provided for @packRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'The pack could not be restored. Nothing on this phone changed.'**
  String get packRestoreFailed;

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

  /// No description provided for @animalDam.
  ///
  /// In en, this message translates to:
  /// **'Dam'**
  String get animalDam;

  /// No description provided for @animalSire.
  ///
  /// In en, this message translates to:
  /// **'Sire'**
  String get animalSire;

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

  /// Bare unit so a row can read '4.20 kg'; the form label keeps its own wording.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @unitGrams.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get unitGrams;

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

  /// No description provided for @weightAppendOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Weigh-ins are never edited. Measured wrong? Delete it and weigh again.'**
  String get weightAppendOnlyHint;

  /// No description provided for @animalSpeciesHelper.
  ///
  /// In en, this message translates to:
  /// **'dog · cat'**
  String get animalSpeciesHelper;

  /// No description provided for @healthTestAdd.
  ///
  /// In en, this message translates to:
  /// **'Add test'**
  String get healthTestAdd;

  /// No description provided for @healthTestAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Log a health test'**
  String get healthTestAddTitle;

  /// No description provided for @healthTestEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit health test'**
  String get healthTestEditTitle;

  /// A genetic or orthopaedic screening, not a vet check-up.
  ///
  /// In en, this message translates to:
  /// **'Screening'**
  String get healthTestType;

  /// No description provided for @healthTestTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Name the screening'**
  String get healthTestTypeRequired;

  /// No description provided for @healthTestResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get healthTestResult;

  /// No description provided for @healthTestResultRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the result'**
  String get healthTestResultRequired;

  /// Grade words exactly as a certificate prints them, so they stay English in every locale. Spelled out because a single grade letter read as the digit zero on a phone.
  ///
  /// In en, this message translates to:
  /// **'Clear · Carrier · Affected'**
  String get healthTestResultHelper;

  /// No description provided for @healthTestDate.
  ///
  /// In en, this message translates to:
  /// **'Tested on'**
  String get healthTestDate;

  /// No description provided for @healthTestValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get healthTestValidUntil;

  /// The organisation that issued the certificate, e.g. OFA.
  ///
  /// In en, this message translates to:
  /// **'Testing body'**
  String get healthTestBody;

  /// No description provided for @healthTestVerifiedBy.
  ///
  /// In en, this message translates to:
  /// **'Verified by'**
  String get healthTestVerifiedBy;

  /// No description provided for @healthTestExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get healthTestExpired;

  /// No description provided for @healthTestDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The screening is removed from this animal\'s history. This cannot be undone.'**
  String get healthTestDeleteBody;

  /// No description provided for @visitAdd.
  ///
  /// In en, this message translates to:
  /// **'Add visit'**
  String get visitAdd;

  /// No description provided for @visitAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Log a vet visit'**
  String get visitAddTitle;

  /// No description provided for @visitEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit vet visit'**
  String get visitEditTitle;

  /// No description provided for @visitDate.
  ///
  /// In en, this message translates to:
  /// **'Visit date'**
  String get visitDate;

  /// No description provided for @visitReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get visitReason;

  /// No description provided for @visitNoReason.
  ///
  /// In en, this message translates to:
  /// **'Consultation'**
  String get visitNoReason;

  /// No description provided for @visitOutcome.
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get visitOutcome;

  /// No description provided for @visitCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get visitCost;

  /// No description provided for @visitCostInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount like 250'**
  String get visitCostInvalid;

  /// No description provided for @visitCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get visitCurrency;

  /// No description provided for @visitDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The visit is removed from this animal\'s history. This cannot be undone.'**
  String get visitDeleteBody;

  /// No description provided for @symptomAdd.
  ///
  /// In en, this message translates to:
  /// **'Add symptom'**
  String get symptomAdd;

  /// A sign the breeder saw and typed, not a diagnosis. 'Symptom' is the word the roadmap uses and the word a vet's intake form uses.
  ///
  /// In en, this message translates to:
  /// **'Log a symptom'**
  String get symptomAddTitle;

  /// No description provided for @symptomEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit symptom'**
  String get symptomEditTitle;

  /// The sign as the breeder typed it: 'vomiting', 'limping on the left'. Free text, because the signs worth writing down depend on the breed and the age — the same reason `healthTestType` has no list.
  ///
  /// In en, this message translates to:
  /// **'Symptom'**
  String get symptomName;

  /// No description provided for @symptomNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Say what you saw'**
  String get symptomNameRequired;

  /// No description provided for @symptomSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get symptomSeverity;

  /// No description provided for @severityMild.
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get severityMild;

  /// No description provided for @severityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get severityModerate;

  /// No description provided for @severitySevere.
  ///
  /// In en, this message translates to:
  /// **'Severe'**
  String get severitySevere;

  /// No description provided for @symptomObservedOn.
  ///
  /// In en, this message translates to:
  /// **'Seen on'**
  String get symptomObservedOn;

  /// Ongoing or resolved, the column the triage rules read. Its own key because reusing the animal's own `status` would put that word's translations in a buyer's document as a symptom heading.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get symptomState;

  /// No description provided for @symptomOngoing.
  ///
  /// In en, this message translates to:
  /// **'Still happening'**
  String get symptomOngoing;

  /// No description provided for @symptomResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get symptomResolved;

  /// No description provided for @symptomDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The symptom is removed from this animal\'s history. This cannot be undone.'**
  String get symptomDeleteBody;

  /// No description provided for @placementAdd.
  ///
  /// In en, this message translates to:
  /// **'Add placement'**
  String get placementAdd;

  /// The animal went to a new home. 'Placement' is the word the roadmap, the transfer pack and the animal's own 'Placed' status use — not 'sale', because a study animal and a gift are placed too.
  ///
  /// In en, this message translates to:
  /// **'Log a placement'**
  String get placementAddTitle;

  /// No description provided for @placementEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit placement'**
  String get placementEditTitle;

  /// The person the animal went home with. The form's own label; the document keeps its `pdfBuyer` wording.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get placementBuyer;

  /// No description provided for @placementNoBuyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer not recorded'**
  String get placementNoBuyer;

  /// No description provided for @placementDate.
  ///
  /// In en, this message translates to:
  /// **'Placed on'**
  String get placementDate;

  /// No description provided for @placementPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get placementPrice;

  /// No description provided for @placementPriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount like 2500'**
  String get placementPriceInvalid;

  /// No description provided for @placementCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get placementCurrency;

  /// What the breeder promised in writing: health guarantee, return clause, neutering condition. Free text, because the promise is theirs to word.
  ///
  /// In en, this message translates to:
  /// **'Guarantee terms'**
  String get placementGuarantee;

  /// No description provided for @placementDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The placement is removed from this animal\'s history. The buyer stays in your contacts. This cannot be undone.'**
  String get placementDeleteBody;

  /// No description provided for @buyerAdd.
  ///
  /// In en, this message translates to:
  /// **'New buyer'**
  String get buyerAdd;

  /// No description provided for @buyerAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a buyer'**
  String get buyerAddTitle;

  /// No description provided for @buyerEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit buyer'**
  String get buyerEditTitle;

  /// No description provided for @buyerPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get buyerPhone;

  /// No description provided for @buyerEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get buyerEmail;

  /// The two-letter code, e.g. MA. A code rather than a country name because a name typed freely would be sorted and spelled differently every time.
  ///
  /// In en, this message translates to:
  /// **'Country code'**
  String get buyerCountryCode;

  /// The month-ahead alarm. {what} is the dose or screening name as the breeder typed it, {dueDay} a localised date.
  ///
  /// In en, this message translates to:
  /// **'Heads up: {what} is due on {dueDay}'**
  String reminderHeadsUpBody(String what, String dueDay);

  /// No description provided for @reminderDueBody.
  ///
  /// In en, this message translates to:
  /// **'{what} is due today'**
  String reminderDueBody(String what);

  /// No description provided for @pdfAction.
  ///
  /// In en, this message translates to:
  /// **'PDF pack'**
  String get pdfAction;

  /// No description provided for @pdfFailed.
  ///
  /// In en, this message translates to:
  /// **'The PDF could not be made'**
  String get pdfFailed;

  /// No description provided for @pdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Health and lineage record'**
  String get pdfTitle;

  /// No description provided for @pdfLitterTitle.
  ///
  /// In en, this message translates to:
  /// **'Whelping record'**
  String get pdfLitterTitle;

  /// No description provided for @pdfGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated on {day}'**
  String pdfGenerated(String day);

  /// No description provided for @pdfPedigree.
  ///
  /// In en, this message translates to:
  /// **'Pedigree'**
  String get pdfPedigree;

  /// No description provided for @pdfLitters.
  ///
  /// In en, this message translates to:
  /// **'Litters from this animal'**
  String get pdfLitters;

  /// No description provided for @pdfPuppies.
  ///
  /// In en, this message translates to:
  /// **'Puppies'**
  String get pdfPuppies;

  /// No description provided for @pdfPlacement.
  ///
  /// In en, this message translates to:
  /// **'Placement'**
  String get pdfPlacement;

  /// No description provided for @pdfBuyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get pdfBuyer;

  /// No description provided for @pdfPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get pdfPhone;

  /// No description provided for @pdfEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get pdfEmail;

  /// No description provided for @pdfPlacedOn.
  ///
  /// In en, this message translates to:
  /// **'Placed on'**
  String get pdfPlacedOn;

  /// No description provided for @pdfPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get pdfPrice;

  /// No description provided for @pdfGuarantee.
  ///
  /// In en, this message translates to:
  /// **'Guarantee terms'**
  String get pdfGuarantee;

  /// No description provided for @pdfDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Produced offline by Salala from the breeder\'s own records. This is not a veterinary certificate.'**
  String get pdfDisclaimer;

  /// No description provided for @triageTitle.
  ///
  /// In en, this message translates to:
  /// **'What to do next'**
  String get triageTitle;

  /// No description provided for @triageActNow.
  ///
  /// In en, this message translates to:
  /// **'Act now'**
  String get triageActNow;

  /// No description provided for @triageWatch.
  ///
  /// In en, this message translates to:
  /// **'Keep watching'**
  String get triageWatch;

  /// No description provided for @triageRoutineVet.
  ///
  /// In en, this message translates to:
  /// **'Routine vet visit'**
  String get triageRoutineVet;

  /// No description provided for @triageNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this record calls for a next step'**
  String get triageNothing;

  /// No description provided for @triageNotDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'Salala reads only what you typed here. This is not a veterinary diagnosis.'**
  String get triageNotDiagnosis;

  /// No description provided for @triageNoDoseYoung.
  ///
  /// In en, this message translates to:
  /// **'No vaccination recorded, at {days} old'**
  String triageNoDoseYoung(String days);

  /// No description provided for @triageDoseOverdue.
  ///
  /// In en, this message translates to:
  /// **'{name} was due {days} ago'**
  String triageDoseOverdue(String name, String days);

  /// No description provided for @triageDoseDueSoon.
  ///
  /// In en, this message translates to:
  /// **'{name} is due in {days}'**
  String triageDoseDueSoon(String name, String days);

  /// No description provided for @triageWeightLossPuppy.
  ///
  /// In en, this message translates to:
  /// **'A young animal has lost {percent}% of its weight since the last weigh-in'**
  String triageWeightLossPuppy(String percent);

  /// No description provided for @triageWeightLoss.
  ///
  /// In en, this message translates to:
  /// **'Weight has fallen {percent}% since the last weigh-in'**
  String triageWeightLoss(String percent);

  /// No description provided for @triageNoGainPuppy.
  ///
  /// In en, this message translates to:
  /// **'Barely any weight gain over {days}'**
  String triageNoGainPuppy(String days);

  /// No description provided for @triageTestFlagged.
  ///
  /// In en, this message translates to:
  /// **'{name} did not come back clear'**
  String triageTestFlagged(String name);

  /// No description provided for @triageTestExpired.
  ///
  /// In en, this message translates to:
  /// **'The {name} certificate expired {days} ago'**
  String triageTestExpired(String name, String days);

  /// No description provided for @triageWhelpingOverdue.
  ///
  /// In en, this message translates to:
  /// **'{name}: whelping is {days} past the expected date'**
  String triageWhelpingOverdue(String name, String days);

  /// No description provided for @triageSevereSymptom.
  ///
  /// In en, this message translates to:
  /// **'{name} was recorded as severe and is still happening'**
  String triageSevereSymptom(String name);

  /// No description provided for @triageSymptomUnresolved.
  ///
  /// In en, this message translates to:
  /// **'{name} was seen {days} ago and is still happening'**
  String triageSymptomUnresolved(String name, String days);

  /// No description provided for @agendaTitle.
  ///
  /// In en, this message translates to:
  /// **'Vaccinations to book'**
  String get agendaTitle;

  /// No description provided for @daysSingle.
  ///
  /// In en, this message translates to:
  /// **'{n} day'**
  String daysSingle(String n);

  /// No description provided for @daysDual.
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String daysDual(String n);

  /// No description provided for @daysPlural.
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String daysPlural(String n);
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

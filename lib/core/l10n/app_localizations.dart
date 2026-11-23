import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_nl.dart';
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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('nl'),
    Locale('pt'),
  ];

  /// The product name; never translated.
  ///
  /// In en, this message translates to:
  /// **'Companion'**
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

  /// No description provided for @navBuyers.
  ///
  /// In en, this message translates to:
  /// **'Buyers'**
  String get navBuyers;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// This language's own name, written in this language. The Settings menu reads each locale's value straight out of its own file, which is what makes adding a language a single .arb file and no code.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No animals yet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'A herd begins with one. Give her a name, and her record starts here.'**
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
  /// **'Search by name, number, chip, note or buyer'**
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

  /// On the animal's own page, the birth date reads as a phrase rather than as a row: it is one of the four facts in the headline under the photograph.
  ///
  /// In en, this message translates to:
  /// **'Born {day}'**
  String animalBornOn(String day);

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

  /// No description provided for @animalMicrochipDate.
  ///
  /// In en, this message translates to:
  /// **'Microchip implanted'**
  String get animalMicrochipDate;

  /// No description provided for @animalLitter.
  ///
  /// In en, this message translates to:
  /// **'Litter'**
  String get animalLitter;

  /// No description provided for @animalNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get animalNone;

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

  /// No description provided for @animalDeleteLittersNote.
  ///
  /// In en, this message translates to:
  /// **'This also deletes {litters} of her whelpings, and the {puppies} puppies they registered stay in your animals without the record of their mother.'**
  String animalDeleteLittersNote(int litters, int puppies);

  /// No description provided for @animalDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Its vaccinations, health tests, weights, visits and symptoms are deleted too, with any handover recorded for it, its photographs and the files that hold them on this phone, and the contract attached to that handover. This cannot be undone.'**
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

  /// No description provided for @recordsPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get recordsPhotos;

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

  /// One quiet line under the animal's facts on her own page. Said once, never on every card: a herd of forty dogs does not want forty mottoes. Deliberately not an instruction and not an exclamation.
  ///
  /// In en, this message translates to:
  /// **'Every entry here is part of her story.'**
  String get detailStoryLine;

  /// Shown in place of the story line on an animal whose death date is recorded. Quiet, not consoling: the app is not the person to grieve with, and a longer sentence here reads as sympathy the app has not earned.
  ///
  /// In en, this message translates to:
  /// **'Her record stays as it was.'**
  String get detailDiedLine;

  /// Shown once, after a handover is saved. Respects the move rather than celebrating a sale — a placed breeding dog is a loss to the kennel as much as a transaction.
  ///
  /// In en, this message translates to:
  /// **'{name} has gone to a new home. The record stays with you.'**
  String placedFarewell(String name);

  /// The month-ahead alarm. {what} is the dose or screening name as the breeder typed it, {dueDay} a localised date. The tone is a nudge between equals: no 'Don't forget', no exclamation mark, and the word 'heads up' rather than 'reminder' because a reminder implies the breeder would have forgotten.
  ///
  /// In en, this message translates to:
  /// **'Heads up: {what} is due on {dueDay}'**
  String reminderHeadsUpBody(String what, String dueDay);

  /// The morning-of alarm. The second half is the whole point of the sentence: it says the task is small, because a breeder who reads a bare due-date at six in the morning reads it as another thing she is behind on.
  ///
  /// In en, this message translates to:
  /// **'{what} is due today. Two minutes is enough'**
  String reminderDueBody(String what);

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
  /// **'Companion is locked'**
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

  /// No description provided for @lockChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'The phone would not change the app lock.'**
  String get lockChangeFailed;

  /// No description provided for @lockChangePinDone.
  ///
  /// In en, this message translates to:
  /// **'PIN changed.'**
  String get lockChangePinDone;

  /// Shown while the gate refuses after repeated wrong PINs; seconds counts down to zero.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong PINs. Try again in {seconds}s.'**
  String lockTooManyAttempts(int seconds);

  /// No description provided for @settingsAppLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get settingsAppLock;

  /// No description provided for @settingsChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get settingsChangePin;

  /// No description provided for @settingsChangePinBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the current PIN, then choose a new one.'**
  String get settingsChangePinBody;

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

  /// No description provided for @languageNotStored.
  ///
  /// In en, this message translates to:
  /// **'The phone would not keep this language.'**
  String get languageNotStored;

  /// No description provided for @startupFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Companion could not open the ledger on this phone.'**
  String get startupFailedTitle;

  /// No description provided for @startupFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Your records are still in the file. Close the app and open it again.'**
  String get startupFailedBody;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// The row's title on Settings. Rendered only when kBillingEnabled is true, so a free install never sees the word trial at all.
  ///
  /// In en, this message translates to:
  /// **'Free trial'**
  String get settingsTrial;

  /// Days left in the trial. Whole days, never a countdown, because a clock that ticks on a settings row is a pressure the breeder did not ask for.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String settingsTrialRemaining(String days);

  /// Said once the trial has run out. Deliberately not a call to buy: the export that used to work still opens, and the sentence is a fact rather than a pitch.
  ///
  /// In en, this message translates to:
  /// **'The trial has ended'**
  String get settingsTrialOver;

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
  /// **'One ZIP file with every record and picture on this phone'**
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

  /// Said under the export tile. The point is that the breeder can see how stale their only copy is — an app that never mentions it is an app where the last backup was eight months ago.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {day}'**
  String settingsLastBackup(String day);

  /// No description provided for @settingsNeverBackedUp.
  ///
  /// In en, this message translates to:
  /// **'No backup has left this phone yet'**
  String get settingsNeverBackedUp;

  /// No description provided for @settingsCsv.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet (CSV)'**
  String get settingsCsv;

  /// No description provided for @settingsCsvBody.
  ///
  /// In en, this message translates to:
  /// **'For your accountant, a registry form, or a co-owner. Opens in Excel, Numbers or Google Sheets.'**
  String get settingsCsvBody;

  /// No description provided for @settingsCsvHerd.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get settingsCsvHerd;

  /// No description provided for @settingsCsvLitters.
  ///
  /// In en, this message translates to:
  /// **'Litters'**
  String get settingsCsvLitters;

  /// No description provided for @settingsCsvVaccinations.
  ///
  /// In en, this message translates to:
  /// **'Vaccinations'**
  String get settingsCsvVaccinations;

  /// No description provided for @settingsCsvPlacements.
  ///
  /// In en, this message translates to:
  /// **'Handovers'**
  String get settingsCsvPlacements;

  /// No description provided for @csvShared.
  ///
  /// In en, this message translates to:
  /// **'{file} is ready to send'**
  String csvShared(String file);

  /// No description provided for @csvShareFailed.
  ///
  /// In en, this message translates to:
  /// **'The sheet could not be written on this phone'**
  String get csvShareFailed;

  /// No description provided for @csvEmpty.
  ///
  /// In en, this message translates to:
  /// **'There is nothing on this phone to export yet'**
  String get csvEmpty;

  /// Column heading: the animal a vaccination or a handover belongs to. Reused by every sheet that is not the herd's own, where the row already is one animal.
  ///
  /// In en, this message translates to:
  /// **'Animal'**
  String get csvColAnimal;

  /// Column heading for the buyer's two-letter country code.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get csvColCountry;

  /// Column heading for how many puppies a whelping registered.
  ///
  /// In en, this message translates to:
  /// **'Puppies'**
  String get csvColPuppies;

  /// Column heading, answered yes or no by the two keys below. Shorter than the form's own checkbox label because it is a heading over a column of yes/no.
  ///
  /// In en, this message translates to:
  /// **'Breeding stock'**
  String get csvColBreedingStock;

  /// The answer in a yes/no column. Lower case, because it read as a word in a cell rather than as a label.
  ///
  /// In en, this message translates to:
  /// **'yes'**
  String get csvColYes;

  /// No description provided for @csvColNo.
  ///
  /// In en, this message translates to:
  /// **'no'**
  String get csvColNo;

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
  /// **'That file is not a Companion pack, or it is damaged'**
  String get packNotAPack;

  /// No description provided for @packFromTheFuture.
  ///
  /// In en, this message translates to:
  /// **'That pack comes from a newer Companion than this one'**
  String get packFromTheFuture;

  /// No description provided for @packIncomplete.
  ///
  /// In en, this message translates to:
  /// **'That pack is missing part of the ledger: {table}'**
  String packIncomplete(String table);

  /// No description provided for @packUnknownTable.
  ///
  /// In en, this message translates to:
  /// **'That pack holds a table this Companion does not know: {table}'**
  String packUnknownTable(String table);

  /// A row whose word is not one the app stores, e.g. an animal status it does not know. Refused before anything is written, so the ledger on this phone is untouched.
  ///
  /// In en, this message translates to:
  /// **'That pack holds a value this Companion cannot read: {detail}'**
  String packBadValue(String detail);

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

  /// No description provided for @litterEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit litter'**
  String get litterEditTitle;

  /// No description provided for @litterAddPuppies.
  ///
  /// In en, this message translates to:
  /// **'Add puppies'**
  String get litterAddPuppies;

  /// No description provided for @litterHowMany.
  ///
  /// In en, this message translates to:
  /// **'How many?'**
  String get litterHowMany;

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

  /// No description provided for @litterWhelpingBeforeMating.
  ///
  /// In en, this message translates to:
  /// **'The whelping date is before the mating date.'**
  String get litterWhelpingBeforeMating;

  /// No description provided for @litterWeaningBeforeWhelping.
  ///
  /// In en, this message translates to:
  /// **'The weaning date is before the whelping date.'**
  String get litterWeaningBeforeWhelping;

  /// No description provided for @litterExpected.
  ///
  /// In en, this message translates to:
  /// **'Expected whelping: {date}'**
  String litterExpected(String date);

  /// Title of the page that adds the whole ledger up.
  ///
  /// In en, this message translates to:
  /// **'The kennel in numbers'**
  String get statsTitle;

  /// The Settings row that opens the statistics page.
  ///
  /// In en, this message translates to:
  /// **'The kennel in numbers'**
  String get settingsStats;

  /// Heading over the counts of animals currently kept.
  ///
  /// In en, this message translates to:
  /// **'Who is here'**
  String get statsHerdGroup;

  /// Heading over the whelping and puppy counts.
  ///
  /// In en, this message translates to:
  /// **'Whelpings and puppies'**
  String get statsBreedingGroup;

  /// Heading over the handover counts and the money taken.
  ///
  /// In en, this message translates to:
  /// **'Handovers'**
  String get statsMoneyGroup;

  /// How many animals are currently kept, including retired ones.
  ///
  /// In en, this message translates to:
  /// **'Animals at home'**
  String get statsAtHome;

  /// How many animals are flagged as breeding stock.
  ///
  /// In en, this message translates to:
  /// **'Breeding stock'**
  String get statsBreedingStock;

  /// How many females are currently kept.
  ///
  /// In en, this message translates to:
  /// **'Females at home'**
  String get statsFemales;

  /// How many males are currently kept.
  ///
  /// In en, this message translates to:
  /// **'Males at home'**
  String get statsMales;

  /// Every animal row the ledger holds, including sold and dead ones.
  ///
  /// In en, this message translates to:
  /// **'Ever recorded'**
  String get statsEverRecorded;

  /// How many litters have a whelping date on file.
  ///
  /// In en, this message translates to:
  /// **'Whelpings on file'**
  String get statsWhelpings;

  /// How many animals in the ledger were born into one of these litters.
  ///
  /// In en, this message translates to:
  /// **'Puppies from your litters'**
  String get statsPuppies;

  /// Puppies whose birth date falls in the current calendar year.
  ///
  /// In en, this message translates to:
  /// **'Puppies born in {year}'**
  String statsPuppiesThisYear(String year);

  /// How many handovers are on file.
  ///
  /// In en, this message translates to:
  /// **'Handovers'**
  String get statsPlacements;

  /// Label for a total whose handovers had no currency typed. Never guessed.
  ///
  /// In en, this message translates to:
  /// **'No currency named'**
  String get statsUnnamedCurrency;

  /// How many of the handovers carried a price.
  ///
  /// In en, this message translates to:
  /// **'{count} of them paid'**
  String statsHandoverCount(String count);

  /// Said instead of a total when no handover has a price.
  ///
  /// In en, this message translates to:
  /// **'No price recorded'**
  String get statsNoRevenue;

  /// Closing line: the numbers were computed from the local ledger and never leave the phone.
  ///
  /// In en, this message translates to:
  /// **'Counted from your own ledger, on this phone. Nothing here leaves it.'**
  String get statsFooter;

  /// Heading of the card listing animals whose birthday is close.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get birthdayTitle;

  /// A birthday that is today.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get birthdayToday;

  /// How far away a birthday is.
  ///
  /// In en, this message translates to:
  /// **'in {days}'**
  String birthdayIn(String days);

  /// An animal's name and the age she turns.
  ///
  /// In en, this message translates to:
  /// **'{name} turns {years}'**
  String birthdayTurning(String name, String years);

  /// Heading of the card that forecasts a dam's next season. Deliberately not the word for a medical event: a breeder is planning, not diagnosing.
  ///
  /// In en, this message translates to:
  /// **'Next heat'**
  String get heatCardTitle;

  /// The forecast, as a range. A window rather than a date because the cycle length varies by a fortnight between seasons even in one bitch.
  ///
  /// In en, this message translates to:
  /// **'Between {earliest} and {latest}'**
  String heatCardWindow(String earliest, String latest);

  /// Said when the forecast rests on more than one observed gap, so the breeder knows it came from her own record rather than a breed standard.
  ///
  /// In en, this message translates to:
  /// **'Based on {count} cycles in her own record.'**
  String heatCardSteady(String count);

  /// Said when only one gap is on file. States the weakness of the estimate plainly instead of dressing a coincidence up as a pattern.
  ///
  /// In en, this message translates to:
  /// **'Only one cycle on file, so the window is wide. Record another mating and it narrows.'**
  String get heatCardThin;

  /// The date a mating inside the window would be expected to whelp. The reason the card exists: a breeder planning a mating is planning a whelping.
  ///
  /// In en, this message translates to:
  /// **'A mating in this window would whelp around {day}.'**
  String heatCardWhelping(String day);

  /// Title of the dialog that writes one dose for several animals at once. Said when the vial is open and the breeder is holding one puppy after another, so it must read as one sitting rather than several saves.
  ///
  /// In en, this message translates to:
  /// **'Vaccinate together'**
  String get bulkVaccineTitle;

  /// How many animals are about to receive the dose. Shown above the names so a wrong litter is caught before nine rows are written.
  ///
  /// In en, this message translates to:
  /// **'{count} animals get the same dose'**
  String bulkVaccineCount(String count);

  /// The button that opens the bulk dialog from a litter's page.
  ///
  /// In en, this message translates to:
  /// **'Vaccinate the litter'**
  String get bulkVaccineAction;

  /// Said after a bulk write succeeded. States how many rows landed, because that count is what the breeder will check against the puppies in front of her.
  ///
  /// In en, this message translates to:
  /// **'Recorded for {count} animals'**
  String bulkVaccineDone(String count);

  /// Heading of the tree card on a litter's page: two parents, the litter, the puppies. Short, because it sits above a drawing rather than a table.
  ///
  /// In en, this message translates to:
  /// **'Pedigree'**
  String get pedigreeTitle;

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

  /// No description provided for @recordSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'This could not be saved. Nothing was written.'**
  String get recordSaveFailed;

  /// No description provided for @recordDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'This could not be deleted. The record is still there.'**
  String get recordDeleteFailed;

  /// No description provided for @recordDateBeforeBirth.
  ///
  /// In en, this message translates to:
  /// **'This date is before this animal was born.'**
  String get recordDateBeforeBirth;

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

  /// No description provided for @doseDueBeforeAdministered.
  ///
  /// In en, this message translates to:
  /// **'The next dose is due before this dose was given.'**
  String get doseDueBeforeAdministered;

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

  /// Column heading in a printed document, where each row carries its own unit (430 g, 12.40 kg), so no unit belongs in the heading.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightColumn;

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

  /// No description provided for @certificateExpiresBeforeTest.
  ///
  /// In en, this message translates to:
  /// **'This certificate expires before the day of the test it certifies.'**
  String get certificateExpiresBeforeTest;

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

  /// No description provided for @photoAdd.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get photoAdd;

  /// No description provided for @photoFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from the gallery'**
  String get photoFromGallery;

  /// No description provided for @photoFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get photoFromCamera;

  /// A photo is the only record here whose row and bytes are two different things, so the sentence says both go.
  ///
  /// In en, this message translates to:
  /// **'The picture is removed from this animal\'s ledger, and the file with it. This cannot be undone.'**
  String get photoDeleteBody;

  /// Shown where a picture should be: the row survived a restore or a cleared folder, the file did not. Never a path, never a crash.
  ///
  /// In en, this message translates to:
  /// **'Not on this phone'**
  String get photoMissing;

  /// No description provided for @photoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This picture is too big to keep'**
  String get photoTooLarge;

  /// No description provided for @photoNotAnImage.
  ///
  /// In en, this message translates to:
  /// **'This file is not a picture'**
  String get photoNotAnImage;

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

  /// The row that attaches a document to a handover, when none is attached yet.
  ///
  /// In en, this message translates to:
  /// **'Attach a contract'**
  String get contractAttach;

  /// Said once a document is attached to the handover.
  ///
  /// In en, this message translates to:
  /// **'Contract attached'**
  String get contractAttached;

  /// Shown instead of a file name for a document attached on an earlier visit, whose original name was not kept.
  ///
  /// In en, this message translates to:
  /// **'A document you attached earlier'**
  String get contractStoredName;

  /// Tooltip of the button that detaches the contract.
  ///
  /// In en, this message translates to:
  /// **'Remove the contract'**
  String get contractRemove;

  /// Tooltip of the button that hands the stored document to another app.
  ///
  /// In en, this message translates to:
  /// **'Open the contract'**
  String get contractOpen;

  /// The row names a document, but the file is not on this phone - the usual case after restoring a backup on a second phone.
  ///
  /// In en, this message translates to:
  /// **'That document is not on this phone'**
  String get contractMissing;

  /// The document exists but could not be read or handed on.
  ///
  /// In en, this message translates to:
  /// **'The document could not be opened'**
  String get contractOpenFailed;

  /// The phone's file picker refused or threw.
  ///
  /// In en, this message translates to:
  /// **'No document could be chosen'**
  String get contractPickFailed;

  /// The chosen file is larger than the app will store.
  ///
  /// In en, this message translates to:
  /// **'That file is too big to keep'**
  String get contractTooLarge;

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

  /// No description provided for @buyersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No buyers yet'**
  String get buyersEmptyTitle;

  /// No description provided for @buyersEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'A buyer is added with a handover — or here, before one: the person you sold to last year still wants the pedigree.'**
  String get buyersEmptyBody;

  /// No description provided for @buyersNoAnimals.
  ///
  /// In en, this message translates to:
  /// **'No animal on file for this contact'**
  String get buyersNoAnimals;

  /// Said before a contact is deleted, and it has to say what survives: the placement row is kept with its buyer blanked (`ON DELETE SET NULL`), because the fact that an animal went to someone is the breeder's record, while the name and phone belong to the person who can ask for them back.
  ///
  /// In en, this message translates to:
  /// **'{name} is removed from your contacts. The handover stays in the animal\'s history, with no buyer named. This cannot be undone.'**
  String buyerDeleteBody(String name);

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

  /// Said under the growth curve, because the curve's own marks are drawn through the embedded font and no test can read them back. It names both units and reconciles them: the weigh-in table prints 430 g for a newborn while this axis puts the same puppy at 0.43, and a buyer holding both on one page is entitled to know which one the app made up.
  ///
  /// In en, this message translates to:
  /// **'Weight in kilograms, against age in months. The table above writes a young puppy\'s weight in grams.'**
  String get pdfChartAxes;

  /// No description provided for @pdfDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Produced offline by Companion from the breeder\'s own records. This is not a veterinary certificate.'**
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
  /// **'Companion reads only what you typed here. This is not a veterinary diagnosis.'**
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

  /// The triage card's wording for a dose whose day is today. Deliberately the bare sentence, unlike the notification: this card sits in a column of findings, and a reassurance repeated down the column stops being one. The card already carries its urgency and its action.
  ///
  /// In en, this message translates to:
  /// **'{what} is due today'**
  String triageDoseToday(String what);

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

  /// No description provided for @onboardingSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'One record per animal'**
  String get onboardingSlide1Title;

  /// No description provided for @onboardingSlide1Body.
  ///
  /// In en, this message translates to:
  /// **'A dog or a cat, its breed, its birth date and where it came from. The first one takes under a minute.'**
  String get onboardingSlide1Body;

  /// No description provided for @onboardingSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Its health, in order'**
  String get onboardingSlide2Title;

  /// No description provided for @onboardingSlide2Body.
  ///
  /// In en, this message translates to:
  /// **'Vaccinations with their next due date, weigh-ins, screenings and vet visits. Companion books the reminder for you.'**
  String get onboardingSlide2Body;

  /// No description provided for @onboardingSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Its story travels with it'**
  String get onboardingSlide3Title;

  /// No description provided for @onboardingSlide3Body.
  ///
  /// In en, this message translates to:
  /// **'A PDF or a spreadsheet for the buyer, and one ZIP that carries every record and picture to a new phone.'**
  String get onboardingSlide3Body;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Add my first animal'**
  String get onboardingStart;

  /// No description provided for @settingsOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Show the introduction again'**
  String get settingsOnboarding;

  /// No description provided for @settingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settingsHelp;

  /// No description provided for @settingsRate.
  ///
  /// In en, this message translates to:
  /// **'Rate Companion'**
  String get settingsRate;

  /// No description provided for @settingsRateBody.
  ///
  /// In en, this message translates to:
  /// **'Opens this store\'s own review card.'**
  String get settingsRateBody;

  /// No description provided for @settingsWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get settingsWhatsNew;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get settingsTerms;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get settingsLicenses;

  /// No description provided for @rateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This phone cannot show the review card right now.'**
  String get rateUnavailable;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Companion'**
  String get aboutTitle;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'An offline ledger for a small kennel or cattery. No account, no server, no tracking — the records live on this phone and leave it only through your own hands.'**
  String get aboutBody;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'Companion holds one kind of data: what you typed about your animals. This page says where it sits and what can take it off this phone.'**
  String get privacyIntro;

  /// No description provided for @privacyStoredHeading.
  ///
  /// In en, this message translates to:
  /// **'What is stored'**
  String get privacyStoredHeading;

  /// No description provided for @privacyStoredBody.
  ///
  /// In en, this message translates to:
  /// **'Every animal, dose, weigh-in, screening, visit, symptom, handover and buyer contact — and the photographs you attached — in a database and a picture folder inside this app\'s private storage. Android keeps that folder out of reach of other apps, and the files are not encrypted beyond that.'**
  String get privacyStoredBody;

  /// No description provided for @privacyBackupHeading.
  ///
  /// In en, this message translates to:
  /// **'What leaves this phone'**
  String get privacyBackupHeading;

  /// No description provided for @privacyBackupBody.
  ///
  /// In en, this message translates to:
  /// **'Only what you export: a ZIP with every record and picture, a CSV of one table, or a PDF of one animal. Each goes wherever you send it, so a backup carries your buyers\' names and phone numbers — treat the file the way you would the paper it replaces. Turn on the app lock if the phone travels.'**
  String get privacyBackupBody;

  /// No description provided for @privacyCollectHeading.
  ///
  /// In en, this message translates to:
  /// **'What is collected about you'**
  String get privacyCollectHeading;

  /// No description provided for @privacyCollectBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing. There is no analytics, no crash reporting, no advertising identifier and no network call in this app.'**
  String get privacyCollectBody;

  /// No description provided for @privacyRemoveHeading.
  ///
  /// In en, this message translates to:
  /// **'How to erase it'**
  String get privacyRemoveHeading;

  /// No description provided for @privacyRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Uninstalling removes the database and the picture folder with it. There is no copy anywhere else, so export a pack first if the records matter — and remember that the app lock\'s PIN cannot be recovered either.'**
  String get privacyRemoveBody;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get termsTitle;

  /// No description provided for @termsUseHeading.
  ///
  /// In en, this message translates to:
  /// **'What this app is for'**
  String get termsUseHeading;

  /// No description provided for @termsUseBody.
  ///
  /// In en, this message translates to:
  /// **'Keeping your own records about the animals in your care. One licence per person; install it on the phones you use.'**
  String get termsUseBody;

  /// No description provided for @termsDataHeading.
  ///
  /// In en, this message translates to:
  /// **'Your data is yours'**
  String get termsDataHeading;

  /// No description provided for @termsDataBody.
  ///
  /// In en, this message translates to:
  /// **'We hold no copy of it and cannot restore it. Backups are your responsibility, and the export tile in Settings is the whole mechanism.'**
  String get termsDataBody;

  /// No description provided for @termsAdviceHeading.
  ///
  /// In en, this message translates to:
  /// **'Not veterinary advice'**
  String get termsAdviceHeading;

  /// No description provided for @termsAdviceBody.
  ///
  /// In en, this message translates to:
  /// **'Companion repeats what you typed and applies arithmetic to dates and weights. It does not diagnose, and a reminder is a calendar entry, not a clinical opinion. Call a veterinarian.'**
  String get termsAdviceBody;

  /// No description provided for @termsWarrantyHeading.
  ///
  /// In en, this message translates to:
  /// **'No warranty'**
  String get termsWarrantyHeading;

  /// No description provided for @termsWarrantyBody.
  ///
  /// In en, this message translates to:
  /// **'The app is provided as it is. To the extent the law allows, no liability is accepted for a lost record, a missed reminder or a decision taken on what is written here.'**
  String get termsWarrantyBody;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTitle;

  /// No description provided for @helpQ1.
  ///
  /// In en, this message translates to:
  /// **'How do I back up?'**
  String get helpQ1;

  /// No description provided for @helpA1.
  ///
  /// In en, this message translates to:
  /// **'Settings, then Export records. The ZIP file carries every row and every picture; send it to yourself and keep it. Restoring reads the same file back on any phone.'**
  String get helpA1;

  /// No description provided for @helpQ2.
  ///
  /// In en, this message translates to:
  /// **'I forgot my PIN'**
  String get helpQ2;

  /// No description provided for @helpA2.
  ///
  /// In en, this message translates to:
  /// **'It cannot be recovered, because only a hash of it is stored. Uninstalling the app clears the lock and the ledger with it, so if you have a recent pack, restore that afterwards.'**
  String get helpA2;

  /// No description provided for @helpQ3.
  ///
  /// In en, this message translates to:
  /// **'I lost my phone'**
  String get helpQ3;

  /// No description provided for @helpA3.
  ///
  /// In en, this message translates to:
  /// **'Nothing is on a server, so nothing can be sent back. A pack you exported earlier restores the ledger on a new phone; one you never exported is gone.'**
  String get helpA3;

  /// No description provided for @helpQ4.
  ///
  /// In en, this message translates to:
  /// **'Where do the reminders come from?'**
  String get helpQ4;

  /// No description provided for @helpA4.
  ///
  /// In en, this message translates to:
  /// **'From the next-due dates you typed. Companion books an alarm a month ahead and one on the morning itself; if notifications are switched off for the app, the dates still show in the herd\'s agenda.'**
  String get helpA4;

  /// No description provided for @helpQ5.
  ///
  /// In en, this message translates to:
  /// **'Why does a picture say it is not on this phone?'**
  String get helpQ5;

  /// No description provided for @helpA5.
  ///
  /// In en, this message translates to:
  /// **'The row survived and the file did not — usually after a restore from a pack that carried no pictures. Adding the photo again fixes it.'**
  String get helpA5;

  /// No description provided for @helpQ6.
  ///
  /// In en, this message translates to:
  /// **'Can I hand over the animal\'s record?'**
  String get helpQ6;

  /// No description provided for @helpA6.
  ///
  /// In en, this message translates to:
  /// **'Yes. Open the animal and export its PDF: a fixed document the buyer can keep without this app. The handover itself is recorded on the same page.'**
  String get helpA6;

  /// No description provided for @helpQ7.
  ///
  /// In en, this message translates to:
  /// **'Which languages are there?'**
  String get helpQ7;

  /// No description provided for @helpA7.
  ///
  /// In en, this message translates to:
  /// **'English, Arabic, French, German, Spanish, Italian, Portuguese and Dutch. Settings, then Language — the change applies immediately.'**
  String get helpA7;

  /// No description provided for @helpQ8.
  ///
  /// In en, this message translates to:
  /// **'Something is wrong with the app'**
  String get helpQ8;

  /// No description provided for @helpA8.
  ///
  /// In en, this message translates to:
  /// **'Write to us and say what you were doing when it happened. The version is on the About page.'**
  String get helpA8;

  /// No description provided for @helpContactHeading.
  ///
  /// In en, this message translates to:
  /// **'Write to us'**
  String get helpContactHeading;

  /// No description provided for @whatsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNewTitle;

  /// No description provided for @whatsNew1.
  ///
  /// In en, this message translates to:
  /// **'Photographs on the herd cards, and a warmer, roomier layout throughout.'**
  String get whatsNew1;

  /// No description provided for @whatsNew2.
  ///
  /// In en, this message translates to:
  /// **'A tapped reminder opens the animal it is about.'**
  String get whatsNew2;

  /// No description provided for @whatsNew3.
  ///
  /// In en, this message translates to:
  /// **'The spreadsheet export speaks the language you are reading.'**
  String get whatsNew3;

  /// No description provided for @whatsNew4.
  ///
  /// In en, this message translates to:
  /// **'Five more languages: German, Spanish, Italian, Portuguese and Dutch.'**
  String get whatsNew4;

  /// No description provided for @whatsNew5.
  ///
  /// In en, this message translates to:
  /// **'Privacy, terms and help pages, and a rating row in Settings.'**
  String get whatsNew5;

  /// No description provided for @whatsNew6.
  ///
  /// In en, this message translates to:
  /// **'One list per animal: every dose, weigh-in, visit and handover in date order.'**
  String get whatsNew6;

  /// No description provided for @timelineTitle.
  ///
  /// In en, this message translates to:
  /// **'What happened'**
  String get timelineTitle;

  /// No description provided for @timelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing dated yet.'**
  String get timelineEmpty;

  /// No description provided for @timelineShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all {count}'**
  String timelineShowAll(String count);

  /// No description provided for @timelineShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show fewer'**
  String get timelineShowLess;

  /// No description provided for @timelineKindBorn.
  ///
  /// In en, this message translates to:
  /// **'Born'**
  String get timelineKindBorn;

  /// No description provided for @timelineKindDied.
  ///
  /// In en, this message translates to:
  /// **'Died'**
  String get timelineKindDied;

  /// No description provided for @timelineKindWhelped.
  ///
  /// In en, this message translates to:
  /// **'Whelped'**
  String get timelineKindWhelped;

  /// No description provided for @timelineKindVaccination.
  ///
  /// In en, this message translates to:
  /// **'Vaccination'**
  String get timelineKindVaccination;

  /// No description provided for @timelineKindHealthTest.
  ///
  /// In en, this message translates to:
  /// **'Health test'**
  String get timelineKindHealthTest;

  /// No description provided for @timelineKindVisit.
  ///
  /// In en, this message translates to:
  /// **'Vet visit'**
  String get timelineKindVisit;

  /// No description provided for @timelineKindSymptom.
  ///
  /// In en, this message translates to:
  /// **'Symptom'**
  String get timelineKindSymptom;

  /// No description provided for @timelineKindWeight.
  ///
  /// In en, this message translates to:
  /// **'Weigh-in'**
  String get timelineKindWeight;

  /// No description provided for @timelineKindPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get timelineKindPhoto;

  /// No description provided for @timelineKindPlacement.
  ///
  /// In en, this message translates to:
  /// **'Handed over'**
  String get timelineKindPlacement;

  /// No description provided for @daysPlural.
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String daysPlural(String n);

  /// No description provided for @onboardingLittersTitle.
  ///
  /// In en, this message translates to:
  /// **'Every litter, from mating to weaning'**
  String get onboardingLittersTitle;

  /// No description provided for @onboardingLittersBody.
  ///
  /// In en, this message translates to:
  /// **'Date the mating and Companion gives you a whelping window, not a guess. Then every puppy, its sex, its colour and its birth weight.'**
  String get onboardingLittersBody;

  /// No description provided for @onboardingPedigreeTitle.
  ///
  /// In en, this message translates to:
  /// **'The pedigree on one page'**
  String get onboardingPedigreeTitle;

  /// No description provided for @onboardingPedigreeBody.
  ///
  /// In en, this message translates to:
  /// **'Sire, dam and grandparents drawn as a tree, printed beside the health record. Enough for a buyer, without paying a registry.'**
  String get onboardingPedigreeBody;

  /// No description provided for @onboardingBuyersTitle.
  ///
  /// In en, this message translates to:
  /// **'Who is waiting, who has paid'**
  String get onboardingBuyersTitle;

  /// No description provided for @onboardingBuyersBody.
  ///
  /// In en, this message translates to:
  /// **'Deposits, the puppy each buyer chose, the day it went home, and the signed contract filed with it.'**
  String get onboardingBuyersBody;

  /// No description provided for @onboardingYoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Nobody else\'s server'**
  String get onboardingYoursTitle;

  /// No description provided for @onboardingYoursBody.
  ///
  /// In en, this message translates to:
  /// **'No account, no ads, no tracking. Works in a shed with no signal, and your records leave the phone only when you export them.'**
  String get onboardingYoursBody;

  /// No description provided for @onboardingSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Made by one person'**
  String get onboardingSupportTitle;

  /// No description provided for @onboardingSupportBody.
  ///
  /// In en, this message translates to:
  /// **'Companion is built by a single programmer, not a company. No ads and no investors. If it earns its place in your kennel, buying it is what keeps the updates coming.'**
  String get onboardingSupportBody;

  /// No description provided for @upgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Companion Pro'**
  String get upgradeTitle;

  /// No description provided for @upgradeIntro.
  ///
  /// In en, this message translates to:
  /// **'The ledger stays free for good. Pro is the part you show other people: photos without a limit, the pedigree tree, the sale contract, the branded PDF and backups without a count.'**
  String get upgradeIntro;

  /// No description provided for @upgradeProTitle.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get upgradeProTitle;

  /// No description provided for @upgradeProBody.
  ///
  /// In en, this message translates to:
  /// **'One kennel.'**
  String get upgradeProBody;

  /// No description provided for @upgradeStudioTitle.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get upgradeStudioTitle;

  /// No description provided for @upgradeStudioBody.
  ///
  /// In en, this message translates to:
  /// **'More than one kennel, same features.'**
  String get upgradeStudioBody;

  /// No description provided for @upgradeMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get upgradeMonthly;

  /// No description provided for @upgradeYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get upgradeYearly;

  /// No description provided for @upgradeYearlyNote.
  ///
  /// In en, this message translates to:
  /// **'Two months free'**
  String get upgradeYearlyNote;

  /// No description provided for @upgradePriceLoading.
  ///
  /// In en, this message translates to:
  /// **'Asking the store for the price...'**
  String get upgradePriceLoading;

  /// No description provided for @upgradeSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get upgradeSubscribe;

  /// No description provided for @upgradeRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore a purchase'**
  String get upgradeRestore;

  /// No description provided for @upgradeRestored.
  ///
  /// In en, this message translates to:
  /// **'Your purchase is back.'**
  String get upgradeRestored;

  /// No description provided for @upgradeNothingToRestore.
  ///
  /// In en, this message translates to:
  /// **'No purchase found on this account.'**
  String get upgradeNothingToRestore;

  /// No description provided for @upgradeThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you. Everything is unlocked.'**
  String get upgradeThankYou;

  /// No description provided for @upgradeFailed.
  ///
  /// In en, this message translates to:
  /// **'The store did not finish that. Nothing was charged.'**
  String get upgradeFailed;

  /// No description provided for @upgradeLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get upgradeLater;

  /// No description provided for @upgradeTrialDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days left of everything'**
  String upgradeTrialDays(int days);

  /// No description provided for @upgradeTrialOver.
  ///
  /// In en, this message translates to:
  /// **'The trial has ended'**
  String get upgradeTrialOver;

  /// No description provided for @settingsProTitle.
  ///
  /// In en, this message translates to:
  /// **'Companion Pro'**
  String get settingsProTitle;

  /// No description provided for @settingsProOwned.
  ///
  /// In en, this message translates to:
  /// **'Active on this phone'**
  String get settingsProOwned;

  /// No description provided for @settingsProFree.
  ///
  /// In en, this message translates to:
  /// **'See what Pro adds'**
  String get settingsProFree;

  /// No description provided for @proGateTitle.
  ///
  /// In en, this message translates to:
  /// **'{feature} is part of Pro'**
  String proGateTitle(String feature);

  /// No description provided for @proGateBody.
  ///
  /// In en, this message translates to:
  /// **'Your animals, litters, health records, pedigree and backups stay free. Pro adds the parts a buyer sees.'**
  String get proGateBody;

  /// No description provided for @proGateSee.
  ///
  /// In en, this message translates to:
  /// **'See the plans'**
  String get proGateSee;

  /// No description provided for @featurePhotos.
  ///
  /// In en, this message translates to:
  /// **'Unlimited photos'**
  String get featurePhotos;

  /// No description provided for @featureReports.
  ///
  /// In en, this message translates to:
  /// **'Branded reports'**
  String get featureReports;

  /// No description provided for @featureContracts.
  ///
  /// In en, this message translates to:
  /// **'Sale contracts'**
  String get featureContracts;

  /// No description provided for @featureStats.
  ///
  /// In en, this message translates to:
  /// **'The kennel statistics'**
  String get featureStats;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'it',
    'nl',
    'pt',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'nl':
      return AppLocalizationsNl();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

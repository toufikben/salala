// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Salala';

  @override
  String get navAnimals => 'Animals';

  @override
  String get navLitters => 'Litters';

  @override
  String get navBuyers => 'Buyers';

  @override
  String get navSettings => 'Settings';

  @override
  String get languageName => 'English';

  @override
  String get homeEmptyTitle => 'No animals yet';

  @override
  String get homeEmptyBody =>
      'Add your first dog or cat to start a health and lineage record.';

  @override
  String get homeAddAnimal => 'Add animal';

  @override
  String get homeBreedingStock => 'Breeding stock';

  @override
  String get homeAllAnimals => 'All animals';

  @override
  String get homeSearchHint => 'Search by name, number, chip, note or buyer';

  @override
  String homeNoMatches(String query) {
    return 'Nothing matches “$query”';
  }

  @override
  String homeAnimalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count animals',
      one: '1 animal',
      zero: 'No animals',
    );
    return '$_temp0';
  }

  @override
  String get animalName => 'Name';

  @override
  String get animalSpecies => 'Species';

  @override
  String get animalBreed => 'Breed';

  @override
  String get animalSex => 'Sex';

  @override
  String get animalBirthDate => 'Date of birth';

  @override
  String animalBornOn(String day) {
    return 'Born $day';
  }

  @override
  String get animalStatus => 'Status';

  @override
  String get animalMicrochip => 'Microchip number';

  @override
  String get animalMicrochipDate => 'Microchip implanted';

  @override
  String get animalLitter => 'Litter';

  @override
  String get animalNone => 'None';

  @override
  String get animalRegistrationNo => 'Registry number';

  @override
  String get animalRegistry => 'Registry';

  @override
  String get animalColor => 'Colour';

  @override
  String get animalNotes => 'Notes';

  @override
  String get animalIsBreedingStock => 'Keep as breeding stock';

  @override
  String get animalAddTitle => 'Add animal';

  @override
  String get animalEditTitle => 'Edit animal';

  @override
  String animalDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String animalDeleteLittersNote(int litters, int puppies) {
    return 'This also deletes $litters of her whelpings, and the $puppies puppies they registered stay in your animals without the record of their mother.';
  }

  @override
  String get animalDeleteBody =>
      'Its vaccinations, health tests, weights, visits and symptoms are deleted too, with any handover recorded for it, its photographs and the files that hold them on this phone. This cannot be undone.';

  @override
  String get animalNameRequired => 'A name is required';

  @override
  String get animalSpeciesRequired => 'Choose a species';

  @override
  String get sexMale => 'Male';

  @override
  String get sexFemale => 'Female';

  @override
  String get sexUnknown => 'Unknown';

  @override
  String get statusActive => 'With me';

  @override
  String get statusSold => 'Placed';

  @override
  String get statusRetired => 'Retired';

  @override
  String get statusDeceased => 'Deceased';

  @override
  String get recordsVaccinations => 'Vaccinations';

  @override
  String get recordsHealthTests => 'Health tests';

  @override
  String get recordsWeights => 'Weights';

  @override
  String get recordsVisits => 'Vet visits';

  @override
  String get recordsSymptoms => 'Symptoms';

  @override
  String get recordsPhotos => 'Photos';

  @override
  String get recordsPlacements => 'Placements';

  @override
  String get recordsEmpty => 'Nothing recorded yet.';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionClose => 'Close';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionReplace => 'Replace';

  @override
  String get lockTitle => 'Salala is locked';

  @override
  String get lockEnterPin => 'Enter your PIN';

  @override
  String get lockUnlock => 'Unlock';

  @override
  String get lockWrongPin => 'Wrong PIN';

  @override
  String get lockSetPinTitle => 'Create a PIN';

  @override
  String get lockSetPinBody =>
      'Four digits or more. It stays on this device and cannot be recovered, so write it down.';

  @override
  String get lockConfirmPin => 'Repeat the PIN';

  @override
  String get lockPinTooShort => 'Four digits or more';

  @override
  String get lockPinMismatch => 'The two PINs do not match';

  @override
  String get lockEnable => 'Lock the app';

  @override
  String get lockDisable => 'Turn the lock off';

  @override
  String get lockCurrentPin => 'Current PIN';

  @override
  String get lockChangeFailed => 'The phone would not change the app lock.';

  @override
  String get lockChangePinDone => 'PIN changed.';

  @override
  String lockTooManyAttempts(int seconds) {
    return 'Too many wrong PINs. Try again in ${seconds}s.';
  }

  @override
  String get settingsAppLock => 'App lock';

  @override
  String get settingsChangePin => 'Change PIN';

  @override
  String get settingsChangePinBody =>
      'Enter the current PIN, then choose a new one.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get languageNotStored => 'The phone would not keep this language.';

  @override
  String get startupFailedTitle =>
      'Salala could not open the ledger on this phone.';

  @override
  String get startupFailedBody =>
      'Your records are still in the file. Close the app and open it again.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsBuildTag => 'Build';

  @override
  String get settingsOfflineNote =>
      'Everything is stored on this device. No account, no server, no tracking.';

  @override
  String get settingsExport => 'Export records';

  @override
  String get settingsExportBody =>
      'One ZIP file with every record and picture on this phone';

  @override
  String get settingsImport => 'Restore from a pack';

  @override
  String get settingsImportBody => 'Read a pack back onto this phone';

  @override
  String settingsLastBackup(String day) {
    return 'Last backup: $day';
  }

  @override
  String get settingsNeverBackedUp => 'No backup has left this phone yet';

  @override
  String get settingsCsv => 'Spreadsheet (CSV)';

  @override
  String get settingsCsvBody =>
      'For your accountant, a registry form, or a co-owner. Opens in Excel, Numbers or Google Sheets.';

  @override
  String get settingsCsvHerd => 'Animals';

  @override
  String get settingsCsvLitters => 'Litters';

  @override
  String get settingsCsvVaccinations => 'Vaccinations';

  @override
  String get settingsCsvPlacements => 'Handovers';

  @override
  String csvShared(String file) {
    return '$file is ready to send';
  }

  @override
  String get csvShareFailed => 'The sheet could not be written on this phone';

  @override
  String get csvEmpty => 'There is nothing on this phone to export yet';

  @override
  String get csvColAnimal => 'Animal';

  @override
  String get csvColCountry => 'Country';

  @override
  String get csvColPuppies => 'Puppies';

  @override
  String get csvColBreedingStock => 'Breeding stock';

  @override
  String get csvColYes => 'yes';

  @override
  String get csvColNo => 'no';

  @override
  String packShared(String file) {
    return '$file is ready to send';
  }

  @override
  String get packShareFailed => 'The pack could not be written on this phone';

  @override
  String get packReadFailed => 'That file could not be opened';

  @override
  String get packNotAPack => 'That file is not a Salala pack, or it is damaged';

  @override
  String get packFromTheFuture =>
      'That pack comes from a newer Salala than this one';

  @override
  String packIncomplete(String table) {
    return 'That pack is missing part of the ledger: $table';
  }

  @override
  String packUnknownTable(String table) {
    return 'That pack holds a table this Salala does not know: $table';
  }

  @override
  String get packRestoreTitle => 'Replace everything on this phone?';

  @override
  String packRestoreBody(int animals, int rows, String day) {
    return 'From $day. Animals: $animals. Records: $rows. Restoring replaces everything that is on this phone now.';
  }

  @override
  String packRestored(int rows) {
    return 'Records restored: $rows';
  }

  @override
  String get packRestoreFailed =>
      'The pack could not be restored. Nothing on this phone changed.';

  @override
  String get litterAdd => 'New litter';

  @override
  String get litterEditTitle => 'Edit litter';

  @override
  String get litterAddPuppies => 'Add puppies';

  @override
  String get litterHowMany => 'How many?';

  @override
  String get litterAddTitle => 'Register a litter';

  @override
  String get litterEmptyTitle => 'No litters yet';

  @override
  String get litterEmptyBody =>
      'Record a mating to follow the pregnancy and register the puppies in one step.';

  @override
  String get litterName => 'Litter name';

  @override
  String get litterNameRequired => 'A litter name is required';

  @override
  String get litterDam => 'Dam (mother)';

  @override
  String get litterDamRequired => 'Choose the dam';

  @override
  String get litterDamMissing => 'Dam removed';

  @override
  String get litterSire => 'Sire (father)';

  @override
  String get litterSireUnknown => 'Unknown sire';

  @override
  String get litterNoDams => 'Mark a female as breeding stock first';

  @override
  String get litterMatingDate => 'Mating date';

  @override
  String get litterWhelpingDate => 'Whelping date';

  @override
  String get litterWeaningDate => 'Weaning date';

  @override
  String get litterWhelpingBeforeMating =>
      'The whelping date is before the mating date.';

  @override
  String get litterWeaningBeforeWhelping =>
      'The weaning date is before the whelping date.';

  @override
  String litterExpected(String date) {
    return 'Expected whelping: $date';
  }

  @override
  String litterPuppyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count puppies',
      one: '1 puppy',
      zero: 'No puppies registered',
    );
    return '$_temp0';
  }

  @override
  String get litterPuppiesToRegister => 'Puppies born';

  @override
  String get litterPuppiesHint =>
      'Each puppy is added to your animals, named after the litter';

  @override
  String get litterNoPuppies => 'No puppies registered for this litter yet.';

  @override
  String get litterGone => 'This litter was deleted.';

  @override
  String litterDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get litterDeleteBody =>
      'The puppies stay in your animals; only the mating record is removed. This cannot be undone.';

  @override
  String get animalGone => 'This animal was deleted.';

  @override
  String get animalDeathDate => 'Died';

  @override
  String get animalDam => 'Dam';

  @override
  String get animalSire => 'Sire';

  @override
  String get valueUnknown => 'Not recorded';

  @override
  String get recordDeleteTitle => 'Delete this record?';

  @override
  String get recordSaveFailed =>
      'This could not be saved. Nothing was written.';

  @override
  String get recordDeleteFailed =>
      'This could not be deleted. The record is still there.';

  @override
  String get recordDateBeforeBirth =>
      'This date is before this animal was born.';

  @override
  String get vaccinationAdd => 'Add vaccination';

  @override
  String get vaccinationAddTitle => 'Log a vaccination';

  @override
  String get vaccinationEditTitle => 'Edit vaccination';

  @override
  String get vaccinationName => 'Vaccine';

  @override
  String get vaccinationNameRequired => 'A vaccine name is required';

  @override
  String get vaccinationGiven => 'Given';

  @override
  String get vaccinationNextDue => 'Next due';

  @override
  String get vaccinationNextDueHint =>
      'A dose whose next-due date has passed is marked overdue.';

  @override
  String get doseDueBeforeAdministered =>
      'The next dose is due before this dose was given.';

  @override
  String get vaccinationOverdue => 'Overdue';

  @override
  String get vaccinationManufacturer => 'Manufacturer';

  @override
  String get vaccinationBatch => 'Batch number';

  @override
  String get vaccinationVet => 'Veterinarian';

  @override
  String get vaccinationClinic => 'Clinic';

  @override
  String get vaccinationCertificate => 'Certificate number';

  @override
  String get vaccinationDeleteBody =>
      'The dose is removed from this animal\'s history. This cannot be undone.';

  @override
  String get weightAdd => 'Add weight';

  @override
  String get weightKg => 'Weight (kg)';

  @override
  String get weightColumn => 'Weight';

  @override
  String get weightRequired => 'Enter the weight';

  @override
  String get weightInvalid => 'Enter a weight like 4.2';

  @override
  String get weightMeasuredOn => 'Measured on';

  @override
  String get unitKg => 'kg';

  @override
  String get unitGrams => 'g';

  @override
  String get weightNote => 'Note';

  @override
  String get weightDeleteBody =>
      'The weigh-in is removed. This cannot be undone.';

  @override
  String get weightAppendOnlyHint =>
      'Weigh-ins are never edited. Measured wrong? Delete it and weigh again.';

  @override
  String get animalSpeciesHelper => 'dog · cat';

  @override
  String get healthTestAdd => 'Add test';

  @override
  String get healthTestAddTitle => 'Log a health test';

  @override
  String get healthTestEditTitle => 'Edit health test';

  @override
  String get healthTestType => 'Screening';

  @override
  String get healthTestTypeRequired => 'Name the screening';

  @override
  String get healthTestResult => 'Result';

  @override
  String get healthTestResultRequired => 'Enter the result';

  @override
  String get healthTestResultHelper => 'Clear · Carrier · Affected';

  @override
  String get healthTestDate => 'Tested on';

  @override
  String get healthTestValidUntil => 'Valid until';

  @override
  String get certificateExpiresBeforeTest =>
      'This certificate expires before the day of the test it certifies.';

  @override
  String get healthTestBody => 'Testing body';

  @override
  String get healthTestVerifiedBy => 'Verified by';

  @override
  String get healthTestExpired => 'Expired';

  @override
  String get healthTestDeleteBody =>
      'The screening is removed from this animal\'s history. This cannot be undone.';

  @override
  String get visitAdd => 'Add visit';

  @override
  String get visitAddTitle => 'Log a vet visit';

  @override
  String get visitEditTitle => 'Edit vet visit';

  @override
  String get visitDate => 'Visit date';

  @override
  String get visitReason => 'Reason';

  @override
  String get visitNoReason => 'Consultation';

  @override
  String get visitOutcome => 'Outcome';

  @override
  String get visitCost => 'Cost';

  @override
  String get visitCostInvalid => 'Enter an amount like 250';

  @override
  String get visitCurrency => 'Currency';

  @override
  String get visitDeleteBody =>
      'The visit is removed from this animal\'s history. This cannot be undone.';

  @override
  String get symptomAdd => 'Add symptom';

  @override
  String get symptomAddTitle => 'Log a symptom';

  @override
  String get symptomEditTitle => 'Edit symptom';

  @override
  String get symptomName => 'Symptom';

  @override
  String get symptomNameRequired => 'Say what you saw';

  @override
  String get symptomSeverity => 'Severity';

  @override
  String get severityMild => 'Mild';

  @override
  String get severityModerate => 'Moderate';

  @override
  String get severitySevere => 'Severe';

  @override
  String get symptomObservedOn => 'Seen on';

  @override
  String get symptomState => 'Status';

  @override
  String get symptomOngoing => 'Still happening';

  @override
  String get symptomResolved => 'Resolved';

  @override
  String get symptomDeleteBody =>
      'The symptom is removed from this animal\'s history. This cannot be undone.';

  @override
  String get photoAdd => 'Add photo';

  @override
  String get photoFromGallery => 'Choose from the gallery';

  @override
  String get photoFromCamera => 'Take a photo';

  @override
  String get photoDeleteBody =>
      'The picture is removed from this animal\'s ledger, and the file with it. This cannot be undone.';

  @override
  String get photoMissing => 'Not on this phone';

  @override
  String get photoTooLarge => 'This picture is too big to keep';

  @override
  String get photoNotAnImage => 'This file is not a picture';

  @override
  String get placementAdd => 'Add placement';

  @override
  String get placementAddTitle => 'Log a placement';

  @override
  String get placementEditTitle => 'Edit placement';

  @override
  String get placementBuyer => 'Buyer';

  @override
  String get placementNoBuyer => 'Buyer not recorded';

  @override
  String get placementDate => 'Placed on';

  @override
  String get placementPrice => 'Price';

  @override
  String get placementPriceInvalid => 'Enter an amount like 2500';

  @override
  String get placementCurrency => 'Currency';

  @override
  String get placementGuarantee => 'Guarantee terms';

  @override
  String get placementDeleteBody =>
      'The placement is removed from this animal\'s history. The buyer stays in your contacts. This cannot be undone.';

  @override
  String get buyerAdd => 'New buyer';

  @override
  String get buyerAddTitle => 'Add a buyer';

  @override
  String get buyerEditTitle => 'Edit buyer';

  @override
  String get buyerPhone => 'Phone';

  @override
  String get buyerEmail => 'Email';

  @override
  String get buyerCountryCode => 'Country code';

  @override
  String get buyersEmptyTitle => 'No buyers yet';

  @override
  String get buyersEmptyBody =>
      'A buyer is added with a handover — or here, before one: the person you sold to last year still wants the pedigree.';

  @override
  String get buyersNoAnimals => 'No animal on file for this contact';

  @override
  String buyerDeleteBody(String name) {
    return '$name is removed from your contacts. The handover stays in the animal\'s history, with no buyer named. This cannot be undone.';
  }

  @override
  String reminderHeadsUpBody(String what, String dueDay) {
    return 'Heads up: $what is due on $dueDay';
  }

  @override
  String reminderDueBody(String what) {
    return '$what is due today';
  }

  @override
  String get pdfAction => 'PDF pack';

  @override
  String get pdfFailed => 'The PDF could not be made';

  @override
  String get pdfTitle => 'Health and lineage record';

  @override
  String get pdfLitterTitle => 'Whelping record';

  @override
  String pdfGenerated(String day) {
    return 'Generated on $day';
  }

  @override
  String get pdfPedigree => 'Pedigree';

  @override
  String get pdfLitters => 'Litters from this animal';

  @override
  String get pdfPuppies => 'Puppies';

  @override
  String get pdfPlacement => 'Placement';

  @override
  String get pdfBuyer => 'Buyer';

  @override
  String get pdfPhone => 'Phone';

  @override
  String get pdfEmail => 'Email';

  @override
  String get pdfPlacedOn => 'Placed on';

  @override
  String get pdfPrice => 'Price';

  @override
  String get pdfGuarantee => 'Guarantee terms';

  @override
  String get pdfChartAxes =>
      'Weight in kilograms, against age in months. The table above writes a young puppy\'s weight in grams.';

  @override
  String get pdfDisclaimer =>
      'Produced offline by Salala from the breeder\'s own records. This is not a veterinary certificate.';

  @override
  String get triageTitle => 'What to do next';

  @override
  String get triageActNow => 'Act now';

  @override
  String get triageWatch => 'Keep watching';

  @override
  String get triageRoutineVet => 'Routine vet visit';

  @override
  String get triageNothing => 'Nothing in this record calls for a next step';

  @override
  String get triageNotDiagnosis =>
      'Salala reads only what you typed here. This is not a veterinary diagnosis.';

  @override
  String triageNoDoseYoung(String days) {
    return 'No vaccination recorded, at $days old';
  }

  @override
  String triageDoseOverdue(String name, String days) {
    return '$name was due $days ago';
  }

  @override
  String triageDoseDueSoon(String name, String days) {
    return '$name is due in $days';
  }

  @override
  String triageWeightLossPuppy(String percent) {
    return 'A young animal has lost $percent% of its weight since the last weigh-in';
  }

  @override
  String triageWeightLoss(String percent) {
    return 'Weight has fallen $percent% since the last weigh-in';
  }

  @override
  String triageNoGainPuppy(String days) {
    return 'Barely any weight gain over $days';
  }

  @override
  String triageTestFlagged(String name) {
    return '$name did not come back clear';
  }

  @override
  String triageTestExpired(String name, String days) {
    return 'The $name certificate expired $days ago';
  }

  @override
  String triageWhelpingOverdue(String name, String days) {
    return '$name: whelping is $days past the expected date';
  }

  @override
  String triageSevereSymptom(String name) {
    return '$name was recorded as severe and is still happening';
  }

  @override
  String triageSymptomUnresolved(String name, String days) {
    return '$name was seen $days ago and is still happening';
  }

  @override
  String get agendaTitle => 'Vaccinations to book';

  @override
  String daysSingle(String n) {
    return '$n day';
  }

  @override
  String daysDual(String n) {
    return '$n days';
  }

  @override
  String get onboardingSlide1Title => 'One record per animal';

  @override
  String get onboardingSlide1Body =>
      'A dog or a cat, its breed, its birth date and where it came from. The first one takes under a minute.';

  @override
  String get onboardingSlide2Title => 'Its health, in order';

  @override
  String get onboardingSlide2Body =>
      'Vaccinations with their next due date, weigh-ins, screenings and vet visits. Salala books the reminder for you.';

  @override
  String get onboardingSlide3Title => 'Its story travels with it';

  @override
  String get onboardingSlide3Body =>
      'A PDF or a spreadsheet for the buyer, and one ZIP that carries every record and picture to a new phone.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Add my first animal';

  @override
  String get settingsOnboarding => 'Show the introduction again';

  @override
  String get settingsHelp => 'Help';

  @override
  String get settingsRate => 'Rate Salala';

  @override
  String get settingsRateBody => 'Opens this store\'s own review card.';

  @override
  String get settingsWhatsNew => 'What\'s new';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsTerms => 'Terms of use';

  @override
  String get settingsLicenses => 'Open-source licences';

  @override
  String get rateUnavailable =>
      'This phone cannot show the review card right now.';

  @override
  String get aboutTitle => 'About Salala';

  @override
  String get aboutBody =>
      'An offline ledger for a small kennel or cattery. No account, no server, no tracking — the records live on this phone and leave it only through your own hands.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyIntro =>
      'Salala holds one kind of data: what you typed about your animals. This page says where it sits and what can take it off this phone.';

  @override
  String get privacyStoredHeading => 'What is stored';

  @override
  String get privacyStoredBody =>
      'Every animal, dose, weigh-in, screening, visit, symptom, handover and buyer contact — and the photographs you attached — in a database and a picture folder inside this app\'s private storage. Android keeps that folder out of reach of other apps, and the files are not encrypted beyond that.';

  @override
  String get privacyBackupHeading => 'What leaves this phone';

  @override
  String get privacyBackupBody =>
      'Only what you export: a ZIP with every record and picture, a CSV of one table, or a PDF of one animal. Each goes wherever you send it, so a backup carries your buyers\' names and phone numbers — treat the file the way you would the paper it replaces. Turn on the app lock if the phone travels.';

  @override
  String get privacyCollectHeading => 'What is collected about you';

  @override
  String get privacyCollectBody =>
      'Nothing. There is no analytics, no crash reporting, no advertising identifier and no network call in this app.';

  @override
  String get privacyRemoveHeading => 'How to erase it';

  @override
  String get privacyRemoveBody =>
      'Uninstalling removes the database and the picture folder with it. There is no copy anywhere else, so export a pack first if the records matter — and remember that the app lock\'s PIN cannot be recovered either.';

  @override
  String get termsTitle => 'Terms of use';

  @override
  String get termsUseHeading => 'What this app is for';

  @override
  String get termsUseBody =>
      'Keeping your own records about the animals in your care. One licence per person; install it on the phones you use.';

  @override
  String get termsDataHeading => 'Your data is yours';

  @override
  String get termsDataBody =>
      'We hold no copy of it and cannot restore it. Backups are your responsibility, and the export tile in Settings is the whole mechanism.';

  @override
  String get termsAdviceHeading => 'Not veterinary advice';

  @override
  String get termsAdviceBody =>
      'Salala repeats what you typed and applies arithmetic to dates and weights. It does not diagnose, and a reminder is a calendar entry, not a clinical opinion. Call a veterinarian.';

  @override
  String get termsWarrantyHeading => 'No warranty';

  @override
  String get termsWarrantyBody =>
      'The app is provided as it is. To the extent the law allows, no liability is accepted for a lost record, a missed reminder or a decision taken on what is written here.';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpQ1 => 'How do I back up?';

  @override
  String get helpA1 =>
      'Settings, then Export records. The ZIP file carries every row and every picture; send it to yourself and keep it. Restoring reads the same file back on any phone.';

  @override
  String get helpQ2 => 'I forgot my PIN';

  @override
  String get helpA2 =>
      'It cannot be recovered, because only a hash of it is stored. Uninstalling the app clears the lock and the ledger with it, so if you have a recent pack, restore that afterwards.';

  @override
  String get helpQ3 => 'I lost my phone';

  @override
  String get helpA3 =>
      'Nothing is on a server, so nothing can be sent back. A pack you exported earlier restores the ledger on a new phone; one you never exported is gone.';

  @override
  String get helpQ4 => 'Where do the reminders come from?';

  @override
  String get helpA4 =>
      'From the next-due dates you typed. Salala books an alarm a month ahead and one on the morning itself; if notifications are switched off for the app, the dates still show in the herd\'s agenda.';

  @override
  String get helpQ5 => 'Why does a picture say it is not on this phone?';

  @override
  String get helpA5 =>
      'The row survived and the file did not — usually after a restore from a pack that carried no pictures. Adding the photo again fixes it.';

  @override
  String get helpQ6 => 'Can I hand over the animal\'s record?';

  @override
  String get helpA6 =>
      'Yes. Open the animal and export its PDF: a fixed document the buyer can keep without this app. The handover itself is recorded on the same page.';

  @override
  String get helpQ7 => 'Which languages are there?';

  @override
  String get helpA7 =>
      'English, Arabic, French, German, Spanish, Italian, Portuguese and Dutch. Settings, then Language — the change applies immediately.';

  @override
  String get helpQ8 => 'Something is wrong with the app';

  @override
  String get helpA8 =>
      'Write to us and say what you were doing when it happened. The version is on the About page.';

  @override
  String get helpContactHeading => 'Write to us';

  @override
  String get whatsNewTitle => 'What\'s new';

  @override
  String get whatsNew1 =>
      'Photographs on the herd cards, and a warmer, roomier layout throughout.';

  @override
  String get whatsNew2 => 'A tapped reminder opens the animal it is about.';

  @override
  String get whatsNew3 =>
      'The spreadsheet export speaks the language you are reading.';

  @override
  String get whatsNew4 =>
      'Five more languages: German, Spanish, Italian, Portuguese and Dutch.';

  @override
  String get whatsNew5 =>
      'Privacy, terms and help pages, and a rating row in Settings.';

  @override
  String daysPlural(String n) {
    return '$n days';
  }
}

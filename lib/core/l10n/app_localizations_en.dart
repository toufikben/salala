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
  String get navSettings => 'Settings';

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
  String get homeSearchHint => 'Search by name, number, chip or note';

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
  String get animalStatus => 'Status';

  @override
  String get animalMicrochip => 'Microchip number';

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
  String get animalDeleteBody =>
      'Its vaccinations, health tests, weights, visits and symptoms are deleted too. This cannot be undone.';

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
  String get settingsAppLock => 'App lock';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

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
      'One JSON file with every record on this phone';

  @override
  String get settingsImport => 'Restore from a pack';

  @override
  String get settingsImportBody => 'Read a pack back onto this phone';

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
  String daysPlural(String n) {
    return '$n days';
  }
}

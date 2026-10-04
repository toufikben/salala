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
      'Its vaccinations, health tests, weights and visits are deleted too. This cannot be undone.';

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
  String get settingsExportSoon => 'PDF and JSON export arrive in Phase 2.';

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
  String get weightRequired => 'Enter the weight';

  @override
  String get weightInvalid => 'Enter a weight like 4.2';

  @override
  String get weightMeasuredOn => 'Measured on';

  @override
  String get weightNote => 'Note';

  @override
  String get weightDeleteBody =>
      'The weigh-in is removed. This cannot be undone.';
}

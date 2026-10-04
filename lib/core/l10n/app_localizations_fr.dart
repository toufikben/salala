// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Salala';

  @override
  String get navAnimals => 'Animaux';

  @override
  String get navLitters => 'Portées';

  @override
  String get navSettings => 'Réglages';

  @override
  String get homeEmptyTitle => 'Aucun animal pour l\'instant';

  @override
  String get homeEmptyBody =>
      'Ajoutez votre premier chien ou chat pour commencer le dossier santé et les origines.';

  @override
  String get homeAddAnimal => 'Ajouter un animal';

  @override
  String get homeBreedingStock => 'Reproduction';

  @override
  String get homeAllAnimals => 'Tous les animaux';

  @override
  String homeAnimalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count animaux',
      one: '1 animal',
      zero: 'Aucun animal',
    );
    return '$_temp0';
  }

  @override
  String get animalName => 'Nom';

  @override
  String get animalSpecies => 'Espèce';

  @override
  String get animalBreed => 'Race';

  @override
  String get animalSex => 'Sexe';

  @override
  String get animalBirthDate => 'Date de naissance';

  @override
  String get animalStatus => 'Statut';

  @override
  String get animalMicrochip => 'N° de puce';

  @override
  String get animalRegistrationNo => 'N° d\'affiliation';

  @override
  String get animalRegistry => 'Organisme généalogique';

  @override
  String get animalColor => 'Robe';

  @override
  String get animalNotes => 'Notes';

  @override
  String get animalIsBreedingStock => 'Considéré comme reproducteur';

  @override
  String get animalAddTitle => 'Ajouter un animal';

  @override
  String get animalEditTitle => 'Modifier l\'animal';

  @override
  String animalDeleteTitle(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String get animalDeleteBody =>
      'Ses vaccins, tests de santé, pesées et visites seront supprimés aussi. Action irréversible.';

  @override
  String get animalNameRequired => 'Le nom est obligatoire';

  @override
  String get animalSpeciesRequired => 'Choisissez une espèce';

  @override
  String get sexMale => 'Mâle';

  @override
  String get sexFemale => 'Femelle';

  @override
  String get sexUnknown => 'Inconnu';

  @override
  String get statusActive => 'Avec moi';

  @override
  String get statusSold => 'Placé';

  @override
  String get statusRetired => 'Reproducteur réformé';

  @override
  String get statusDeceased => 'Décédé';

  @override
  String get recordsVaccinations => 'Vaccins';

  @override
  String get recordsHealthTests => 'Tests de santé';

  @override
  String get recordsWeights => 'Pesées';

  @override
  String get recordsVisits => 'Visites vétérinaires';

  @override
  String get recordsEmpty => 'Rien d\'enregistré.';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionEdit => 'Modifier';

  @override
  String get actionAdd => 'Ajouter';

  @override
  String get actionClose => 'Fermer';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get actionClear => 'Effacer';

  @override
  String get lockTitle => 'Salala est verrouillé';

  @override
  String get lockEnterPin => 'Saisissez votre code';

  @override
  String get lockUnlock => 'Déverrouiller';

  @override
  String get lockWrongPin => 'Code incorrect';

  @override
  String get lockSetPinTitle => 'Créer un code';

  @override
  String get lockSetPinBody =>
      'Quatre chiffres minimum. Le code reste sur cet appareil et ne peut pas être récupéré : notez-le.';

  @override
  String get lockConfirmPin => 'Confirmez le code';

  @override
  String get lockPinTooShort => 'Quatre chiffres minimum';

  @override
  String get lockPinMismatch => 'Les deux codes ne correspondent pas';

  @override
  String get lockEnable => 'Verrouiller l\'application';

  @override
  String get lockDisable => 'Désactiver le verrouillage';

  @override
  String get lockCurrentPin => 'Code actuel';

  @override
  String get settingsAppLock => 'Verrouillage';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Langue du système';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsBuildTag => 'Version';

  @override
  String get settingsOfflineNote =>
      'Tout est stocké sur cet appareil. Sans compte, sans serveur, sans suivi.';

  @override
  String get settingsExport => 'Exporter les dossiers';

  @override
  String get settingsExportSoon => 'L\'export PDF et JSON arrive en phase 2.';

  @override
  String get litterAdd => 'Nouvelle portée';

  @override
  String get litterAddTitle => 'Enregistrer une portée';

  @override
  String get litterEmptyTitle => 'Aucune portée pour l\'instant';

  @override
  String get litterEmptyBody =>
      'Enregistrez un accouplement pour suivre la gestation et déclarer les chiots en une étape.';

  @override
  String get litterName => 'Nom de la portée';

  @override
  String get litterNameRequired => 'Le nom de la portée est obligatoire';

  @override
  String get litterDam => 'Mère';

  @override
  String get litterDamRequired => 'Choisissez la mère';

  @override
  String get litterDamMissing => 'Mère supprimée';

  @override
  String get litterSire => 'Père';

  @override
  String get litterSireUnknown => 'Père inconnu';

  @override
  String get litterNoDams => 'Marquez d\'abord une femelle comme reproductrice';

  @override
  String get litterMatingDate => 'Date de l\'accouplement';

  @override
  String get litterWhelpingDate => 'Date de la mise bas';

  @override
  String get litterWeaningDate => 'Date du sevrage';

  @override
  String litterExpected(String date) {
    return 'Mise bas prévue : $date';
  }

  @override
  String litterPuppyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chiots',
      one: '1 chiot',
      zero: 'Aucun chiot déclaré',
    );
    return '$_temp0';
  }

  @override
  String get litterPuppiesToRegister => 'Chiots nés';

  @override
  String get litterPuppiesHint =>
      'Chaque chiot est ajouté à vos animaux, nommé d\'après la portée';

  @override
  String get litterNoPuppies => 'Aucun chiot déclaré pour cette portée.';

  @override
  String get litterGone => 'Cette portée a été supprimée.';

  @override
  String litterDeleteTitle(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String get litterDeleteBody =>
      'Les chiots restent dans vos animaux ; seul l\'accouplement est supprimé. Cette action est irréversible.';

  @override
  String get animalGone => 'Cet animal a été supprimé.';

  @override
  String get animalDeathDate => 'Mort le';

  @override
  String get valueUnknown => 'Non enregistré';

  @override
  String get recordDeleteTitle => 'Supprimer cet enregistrement ?';

  @override
  String get vaccinationAdd => 'Ajouter une vaccination';

  @override
  String get vaccinationAddTitle => 'Enregistrer une vaccination';

  @override
  String get vaccinationEditTitle => 'Modifier la vaccination';

  @override
  String get vaccinationName => 'Vaccin';

  @override
  String get vaccinationNameRequired => 'Le nom du vaccin est obligatoire';

  @override
  String get vaccinationGiven => 'Administré le';

  @override
  String get vaccinationNextDue => 'Prochaine dose';

  @override
  String get vaccinationNextDueHint =>
      'Une dose dont la date est dépassée est marquée en retard.';

  @override
  String get vaccinationOverdue => 'En retard';

  @override
  String get vaccinationManufacturer => 'Fabricant';

  @override
  String get vaccinationBatch => 'N° de lot';

  @override
  String get vaccinationVet => 'Vétérinaire';

  @override
  String get vaccinationClinic => 'Clinique';

  @override
  String get vaccinationCertificate => 'N° du certificat';

  @override
  String get vaccinationDeleteBody =>
      'La dose est retirée de l\'historique de cet animal. Action irréversible.';

  @override
  String get weightAdd => 'Ajouter un poids';

  @override
  String get weightKg => 'Poids (kg)';

  @override
  String get weightRequired => 'Saisissez le poids';

  @override
  String get weightInvalid => 'Saisissez un poids comme 4,2';

  @override
  String get weightMeasuredOn => 'Mesuré le';

  @override
  String get weightNote => 'Note';

  @override
  String get weightDeleteBody => 'La pesée est supprimée. Action irréversible.';
}

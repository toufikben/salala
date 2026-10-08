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
  String get homeSearchHint => 'Rechercher par nom, numéro ou puce';

  @override
  String homeNoMatches(String query) {
    return 'Aucun résultat pour « $query »';
  }

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
      'Ses vaccins, tests de santé, pesées, visites et symptômes seront supprimés aussi. Action irréversible.';

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
  String get recordsSymptoms => 'Symptômes';

  @override
  String get recordsPlacements => 'Placements';

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
  String get actionReplace => 'Remplacer';

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
  String get settingsExportBody =>
      'Un fichier JSON avec tous les enregistrements de ce téléphone';

  @override
  String get settingsImport => 'Restaurer un pack';

  @override
  String get settingsImportBody => 'Relire un pack sur ce téléphone';

  @override
  String packShared(String file) {
    return '$file est prêt à envoyer';
  }

  @override
  String get packShareFailed => 'Impossible d\'écrire le pack sur ce téléphone';

  @override
  String get packReadFailed => 'Impossible d\'ouvrir ce fichier';

  @override
  String get packNotAPack =>
      'Ce fichier n\'est pas un pack Salala, ou il est endommagé';

  @override
  String get packFromTheFuture =>
      'Ce pack vient d\'une version plus récente de Salala';

  @override
  String packIncomplete(String table) {
    return 'Il manque une partie du dossier dans ce pack : $table';
  }

  @override
  String packUnknownTable(String table) {
    return 'Ce pack contient une table que Salala ne connaît pas : $table';
  }

  @override
  String get packRestoreTitle => 'Remplacer tout ce qui est sur ce téléphone ?';

  @override
  String packRestoreBody(int animals, int rows, String day) {
    return 'Du $day. Animaux : $animals. Enregistrements : $rows. La restauration remplacera tout ce qui est sur ce téléphone.';
  }

  @override
  String packRestored(int rows) {
    return 'Enregistrements restaurés : $rows';
  }

  @override
  String get packRestoreFailed =>
      'Le pack n\'a pas pu être restauré. Rien n\'a changé sur ce téléphone.';

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
  String get animalDam => 'Mère';

  @override
  String get animalSire => 'Père';

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
  String get unitKg => 'kg';

  @override
  String get unitGrams => 'g';

  @override
  String get weightNote => 'Note';

  @override
  String get weightDeleteBody => 'La pesée est supprimée. Action irréversible.';

  @override
  String get weightAppendOnlyHint =>
      'Les pesées ne se modifient pas. Mesure erronée ? Supprimez-la et pesez de nouveau.';

  @override
  String get animalSpeciesHelper => 'chien · chat';

  @override
  String get healthTestAdd => 'Ajouter un test';

  @override
  String get healthTestAddTitle => 'Enregistrer un test de santé';

  @override
  String get healthTestEditTitle => 'Modifier le test';

  @override
  String get healthTestType => 'Dépistage';

  @override
  String get healthTestTypeRequired => 'Nommez le dépistage';

  @override
  String get healthTestResult => 'Résultat';

  @override
  String get healthTestResultRequired => 'Saisissez le résultat';

  @override
  String get healthTestResultHelper =>
      'Comme au certificat : Clear · Carrier · Affected';

  @override
  String get healthTestDate => 'Testé le';

  @override
  String get healthTestValidUntil => 'Valable jusqu\'au';

  @override
  String get healthTestBody => 'Organisme certificateur';

  @override
  String get healthTestVerifiedBy => 'Vérifié par';

  @override
  String get healthTestExpired => 'Expiré';

  @override
  String get healthTestDeleteBody =>
      'Le test est retiré de l\'historique de cet animal. Action irréversible.';

  @override
  String get visitAdd => 'Ajouter une visite';

  @override
  String get visitAddTitle => 'Enregistrer une visite';

  @override
  String get visitEditTitle => 'Modifier la visite';

  @override
  String get visitDate => 'Date de la visite';

  @override
  String get visitReason => 'Motif';

  @override
  String get visitNoReason => 'Consultation';

  @override
  String get visitOutcome => 'Conclusion';

  @override
  String get visitCost => 'Coût';

  @override
  String get visitCostInvalid => 'Saisissez un montant comme 250';

  @override
  String get visitCurrency => 'Devise';

  @override
  String get visitDeleteBody =>
      'La visite est retirée de l\'historique de cet animal. Action irréversible.';

  @override
  String get symptomAdd => 'Ajouter un symptôme';

  @override
  String get symptomAddTitle => 'Enregistrer un symptôme';

  @override
  String get symptomEditTitle => 'Modifier le symptôme';

  @override
  String get symptomName => 'Symptôme';

  @override
  String get symptomNameRequired => 'Décrivez ce que vous avez constaté';

  @override
  String get symptomSeverity => 'Intensité';

  @override
  String get severityMild => 'Légère';

  @override
  String get severityModerate => 'Modérée';

  @override
  String get severitySevere => 'Sévère';

  @override
  String get symptomObservedOn => 'Constaté le';

  @override
  String get symptomState => 'État';

  @override
  String get symptomOngoing => 'Toujours en cours';

  @override
  String get symptomResolved => 'Résolu';

  @override
  String get symptomDeleteBody =>
      'Le symptôme est retiré de l\'historique de cet animal. Action irréversible.';

  @override
  String get placementAdd => 'Ajouter un placement';

  @override
  String get placementAddTitle => 'Enregistrer un placement';

  @override
  String get placementEditTitle => 'Modifier le placement';

  @override
  String get placementBuyer => 'Acquéreur';

  @override
  String get placementNoBuyer => 'Acquéreur non enregistré';

  @override
  String get placementDate => 'Placé le';

  @override
  String get placementPrice => 'Prix';

  @override
  String get placementPriceInvalid => 'Saisissez un montant comme 2500';

  @override
  String get placementCurrency => 'Devise';

  @override
  String get placementGuarantee => 'Conditions de garantie';

  @override
  String get placementDeleteBody =>
      'Le placement est retiré de l\'historique de cet animal. L\'acquéreur reste dans vos contacts. Action irréversible.';

  @override
  String get buyerAdd => 'Nouvel acquéreur';

  @override
  String get buyerAddTitle => 'Ajouter un acquéreur';

  @override
  String get buyerEditTitle => 'Modifier l\'acquéreur';

  @override
  String get buyerPhone => 'Téléphone';

  @override
  String get buyerEmail => 'Courriel';

  @override
  String get buyerCountryCode => 'Code pays';

  @override
  String reminderHeadsUpBody(String what, String dueDay) {
    return 'À noter : $what arrive à échéance le $dueDay';
  }

  @override
  String reminderDueBody(String what) {
    return '$what arrive à échéance aujourd\'hui';
  }

  @override
  String get pdfAction => 'Fiche PDF';

  @override
  String get pdfFailed => 'Le PDF n\'a pas pu être créé';

  @override
  String get pdfTitle => 'Fiche sanitaire et généalogique';

  @override
  String get pdfLitterTitle => 'Registre de portée';

  @override
  String pdfGenerated(String day) {
    return 'Généré le $day';
  }

  @override
  String get pdfPedigree => 'Généalogie';

  @override
  String get pdfLitters => 'Portées de cet animal';

  @override
  String get pdfPuppies => 'Chiots';

  @override
  String get pdfPlacement => 'Placement';

  @override
  String get pdfBuyer => 'Acquéreur';

  @override
  String get pdfPhone => 'Téléphone';

  @override
  String get pdfEmail => 'Courriel';

  @override
  String get pdfPlacedOn => 'Placé le';

  @override
  String get pdfPrice => 'Prix';

  @override
  String get pdfGuarantee => 'Conditions de garantie';

  @override
  String get pdfDisclaimer =>
      'Établi hors ligne par Salala à partir des registres de l\'éleveur. Ce document n\'est pas un certificat vétérinaire.';

  @override
  String get triageTitle => 'Prochaine étape';

  @override
  String get triageActNow => 'Agir maintenant';

  @override
  String get triageWatch => 'Surveiller';

  @override
  String get triageRoutineVet => 'Visite vétérinaire courante';

  @override
  String get triageNothing => 'Rien dans ce dossier n\'appelle une action';

  @override
  String get triageNotDiagnosis =>
      'Salala ne lit que ce que vous avez saisi ici. Ceci n\'est pas un diagnostic vétérinaire.';

  @override
  String triageNoDoseYoung(String days) {
    return 'Aucune vaccination enregistrée, à $days';
  }

  @override
  String triageDoseOverdue(String name, String days) {
    return '$name en retard de $days';
  }

  @override
  String triageDoseDueSoon(String name, String days) {
    return '$name prévu dans $days';
  }

  @override
  String triageWeightLossPuppy(String percent) {
    return 'Le jeune animal a perdu $percent% de poids depuis la dernière pesée';
  }

  @override
  String triageWeightLoss(String percent) {
    return 'Perte de $percent% depuis la dernière pesée';
  }

  @override
  String triageNoGainPuppy(String days) {
    return 'Quasi aucune prise de poids en $days';
  }

  @override
  String triageTestFlagged(String name) {
    return 'Le résultat $name n\'est pas revenu clair';
  }

  @override
  String triageTestExpired(String name, String days) {
    return 'Le certificat $name a expiré il y a $days';
  }

  @override
  String triageWhelpingOverdue(String name, String days) {
    return '$name : mise bas retardée de $days';
  }

  @override
  String triageSevereSymptom(String name) {
    return '$name enregistré comme sévère et toujours en cours';
  }

  @override
  String triageSymptomUnresolved(String name, String days) {
    return '$name constaté il y a $days et toujours en cours';
  }

  @override
  String get agendaTitle => 'Vaccinations à prévoir';

  @override
  String daysSingle(String n) {
    return '$n jour';
  }

  @override
  String daysDual(String n) {
    return '$n jours';
  }

  @override
  String daysPlural(String n) {
    return '$n jours';
  }
}

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
  String get navBuyers => 'Acquéreurs';

  @override
  String get navSettings => 'Réglages';

  @override
  String get languageName => 'Français';

  @override
  String get homeEmptyTitle => 'Aucun animal pour l\'instant';

  @override
  String get homeEmptyBody =>
      'Un troupeau commence par un seul. Donnez-lui un nom, et sa fiche commence ici.';

  @override
  String get homeAddAnimal => 'Ajouter un animal';

  @override
  String get homeBreedingStock => 'Reproduction';

  @override
  String get homeAllAnimals => 'Tous les animaux';

  @override
  String get homeSearchHint =>
      'Rechercher par nom, numéro, puce, note ou acquéreur';

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
  String animalBornOn(String day) {
    return 'Né le $day';
  }

  @override
  String get animalStatus => 'Statut';

  @override
  String get animalMicrochip => 'N° de puce';

  @override
  String get animalMicrochipDate => 'Date du puçage';

  @override
  String get animalLitter => 'Portée';

  @override
  String get animalNone => 'Aucun';

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
  String animalDeleteLittersNote(int litters, int puppies) {
    return 'Cela supprime aussi $litters portée(s) dont elle est la mère ; $puppies de leurs chiots restent dans vos animaux mais perdent la trace de leur mère.';
  }

  @override
  String get animalDeleteBody =>
      'Ses vaccinations, tests de santé, pesées, visites et symptômes sont aussi supprimés, avec toute cession enregistrée, ses photos et les fichiers qui les gardent sur ce téléphone, ainsi que le contrat joint à cette cession. Cette action est irréversible.';

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
  String get recordsPhotos => 'Photos';

  @override
  String get recordsPlacements => 'Placements';

  @override
  String get recordsEmpty => 'Rien d\'enregistré.';

  @override
  String get detailStoryLine => 'Chaque ligne ici fait partie de son histoire.';

  @override
  String get detailDiedLine => 'Sa fiche reste telle qu\'elle était.';

  @override
  String placedFarewell(String name) {
    return '$name est parti dans un nouveau foyer. La fiche reste avec vous.';
  }

  @override
  String reminderHeadsUpBody(String what, String dueDay) {
    return 'À noter : $what arrive à échéance le $dueDay';
  }

  @override
  String reminderDueBody(String what) {
    return '$what arrive aujourd\'hui. Deux minutes suffisent';
  }

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
  String get lockChangeFailed =>
      'Le téléphone a refusé de modifier le verrouillage.';

  @override
  String get lockChangePinDone => 'Code modifié.';

  @override
  String lockTooManyAttempts(int seconds) {
    return 'Trop de codes erronés. Réessayez dans $seconds s.';
  }

  @override
  String get settingsAppLock => 'Verrouillage';

  @override
  String get settingsChangePin => 'Modifier le code';

  @override
  String get settingsChangePinBody =>
      'Saisissez le code actuel, puis choisissez-en un nouveau.';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Langue du système';

  @override
  String get languageNotStored =>
      'Le téléphone a refusé d\'enregistrer cette langue.';

  @override
  String get startupFailedTitle =>
      'Salala n\'a pas pu ouvrir le registre sur ce téléphone.';

  @override
  String get startupFailedBody =>
      'Vos enregistrements sont toujours dans le fichier. Fermez l\'application et rouvrez-la.';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsTrial => 'Essai gratuit';

  @override
  String settingsTrialRemaining(String days) {
    return 'Encore $days jours';
  }

  @override
  String get settingsTrialOver => 'L\'essai est terminé';

  @override
  String get settingsBuildTag => 'Version';

  @override
  String get settingsOfflineNote =>
      'Tout est stocké sur cet appareil. Sans compte, sans serveur, sans suivi.';

  @override
  String get settingsExport => 'Exporter les dossiers';

  @override
  String get settingsExportBody =>
      'Un fichier ZIP avec tous les enregistrements et toutes les photos de ce téléphone';

  @override
  String get settingsImport => 'Restaurer un pack';

  @override
  String get settingsImportBody => 'Relire un pack sur ce téléphone';

  @override
  String settingsLastBackup(String day) {
    return 'Dernière sauvegarde : $day';
  }

  @override
  String get settingsNeverBackedUp =>
      'Aucune sauvegarde n\'a encore quitté ce téléphone';

  @override
  String get settingsCsv => 'Tableur (CSV)';

  @override
  String get settingsCsvBody =>
      'Pour votre comptable, un formulaire de registre ou un copropriétaire. S\'ouvre dans Excel, Numbers ou Google Sheets.';

  @override
  String get settingsCsvHerd => 'Animaux';

  @override
  String get settingsCsvLitters => 'Portées';

  @override
  String get settingsCsvVaccinations => 'Vaccinations';

  @override
  String get settingsCsvPlacements => 'Cessions';

  @override
  String csvShared(String file) {
    return '$file est prêt à envoyer';
  }

  @override
  String get csvShareFailed =>
      'Le tableur n\'a pas pu être écrit sur ce téléphone';

  @override
  String get csvEmpty => 'Rien à exporter sur ce téléphone pour l\'instant';

  @override
  String get csvColAnimal => 'Animal';

  @override
  String get csvColCountry => 'Pays';

  @override
  String get csvColPuppies => 'Chiots';

  @override
  String get csvColBreedingStock => 'Reproducteur';

  @override
  String get csvColYes => 'oui';

  @override
  String get csvColNo => 'non';

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
  String get litterEditTitle => 'Modifier la portée';

  @override
  String get litterAddPuppies => 'Ajouter des chiots';

  @override
  String get litterHowMany => 'Combien ?';

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
  String get litterWhelpingBeforeMating =>
      'La date de mise bas est antérieure à la date d\'accouplement.';

  @override
  String get litterWeaningBeforeWhelping =>
      'La date de sevrage est antérieure à la date de mise bas.';

  @override
  String litterExpected(String date) {
    return 'Mise bas prévue : $date';
  }

  @override
  String get statsTitle => 'L\'élevage en chiffres';

  @override
  String get settingsStats => 'L\'élevage en chiffres';

  @override
  String get statsHerdGroup => 'Qui est là';

  @override
  String get statsBreedingGroup => 'Portées et chiots';

  @override
  String get statsMoneyGroup => 'Cessions';

  @override
  String get statsAtHome => 'Animaux présents';

  @override
  String get statsBreedingStock => 'Reproducteurs';

  @override
  String get statsFemales => 'Femelles présentes';

  @override
  String get statsMales => 'Mâles présents';

  @override
  String get statsEverRecorded => 'Tous ceux enregistrés';

  @override
  String get statsWhelpings => 'Portées au carnet';

  @override
  String get statsPuppies => 'Chiots de vos portées';

  @override
  String statsPuppiesThisYear(String year) {
    return 'Chiots nés en $year';
  }

  @override
  String get statsPlacements => 'Cessions';

  @override
  String get statsUnnamedCurrency => 'Devise non précisée';

  @override
  String statsHandoverCount(String count) {
    return 'Dont $count payées';
  }

  @override
  String get statsNoRevenue => 'Aucun prix enregistré';

  @override
  String get statsFooter =>
      'Calculé à partir de votre propre carnet, sur ce téléphone. Rien n\'en sort.';

  @override
  String get birthdayTitle => 'À venir';

  @override
  String get birthdayToday => 'aujourd\'hui';

  @override
  String birthdayIn(String days) {
    return 'dans $days';
  }

  @override
  String birthdayTurning(String name, String years) {
    return '$name fête ses $years';
  }

  @override
  String get heatCardTitle => 'Prochaines chaleurs';

  @override
  String heatCardWindow(String earliest, String latest) {
    return 'Entre le $earliest et le $latest';
  }

  @override
  String heatCardSteady(String count) {
    return 'D\'après $count cycles de son propre carnet.';
  }

  @override
  String get heatCardThin =>
      'Un seul cycle au carnet, la fourchette reste donc large. Enregistrez une autre saillie et elle se resserre.';

  @override
  String heatCardWhelping(String day) {
    return 'Une saillie dans cette période donnerait une naissance vers le $day.';
  }

  @override
  String get bulkVaccineTitle => 'Vacciner ensemble';

  @override
  String bulkVaccineCount(String count) {
    return '$count animaux reçoivent la même dose';
  }

  @override
  String get bulkVaccineAction => 'Vacciner la portée';

  @override
  String bulkVaccineDone(String count) {
    return 'Enregistré pour $count animaux';
  }

  @override
  String get pedigreeTitle => 'Pedigree';

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
  String get recordSaveFailed =>
      'Enregistrement impossible. Rien n\'a été écrit.';

  @override
  String get recordDeleteFailed =>
      'Suppression impossible. Cet enregistrement est toujours là.';

  @override
  String get recordDateBeforeBirth =>
      'Cette date est antérieure à la naissance de cet animal.';

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
  String get doseDueBeforeAdministered =>
      'La prochaine dose est due avant la date d\'administration de celle-ci.';

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
  String get weightColumn => 'Poids';

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
  String get certificateExpiresBeforeTest =>
      'Cette certification expire avant le jour du test qu\'elle certifie.';

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
  String get photoAdd => 'Ajouter une photo';

  @override
  String get photoFromGallery => 'Choisir dans la galerie';

  @override
  String get photoFromCamera => 'Prendre une photo';

  @override
  String get photoDeleteBody =>
      'La photo est retirée du registre de cet animal, et le fichier avec elle. Action irréversible.';

  @override
  String get photoMissing => 'Absente de cet appareil';

  @override
  String get photoTooLarge => 'Cette photo est trop lourde';

  @override
  String get photoNotAnImage => 'Ce fichier n\'est pas une photo';

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
  String get contractAttach => 'Joindre un contrat';

  @override
  String get contractAttached => 'Contrat joint';

  @override
  String get contractStoredName => 'Un document joint plus tôt';

  @override
  String get contractRemove => 'Retirer le contrat';

  @override
  String get contractOpen => 'Ouvrir le contrat';

  @override
  String get contractMissing => 'Ce document n\'est pas sur ce téléphone';

  @override
  String get contractOpenFailed => 'Le document n\'a pas pu être ouvert';

  @override
  String get contractPickFailed => 'Aucun document n\'a pu être choisi';

  @override
  String get contractTooLarge => 'Ce fichier est trop lourd pour être conservé';

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
  String get buyersEmptyTitle => 'Aucun acquéreur pour l\'instant';

  @override
  String get buyersEmptyBody =>
      'Un acquéreur s\'ajoute avec un placement — ou ici, avant : la personne à qui vous avez vendu l\'an dernier veut encore le pedigree.';

  @override
  String get buyersNoAnimals => 'Aucun animal enregistré pour ce contact';

  @override
  String buyerDeleteBody(String name) {
    return '$name est supprimé de vos contacts. Le placement reste dans l\'historique de l\'animal, sans acquéreur nommé. Action irréversible.';
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
  String get pdfChartAxes =>
      'Poids en kilogrammes, selon l\'âge en mois. Le tableau ci-dessus écrit le poids d\'un jeune chiot en grammes.';

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
  String triageDoseToday(String what) {
    return '$what arrive à échéance aujourd\'hui';
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
  String get onboardingSlide1Title => 'Une fiche par animal';

  @override
  String get onboardingSlide1Body =>
      'Un chien ou un chat, sa race, sa date de naissance et son origine. Le premier prend moins d\'une minute.';

  @override
  String get onboardingSlide2Title => 'Sa santé, dans l\'ordre';

  @override
  String get onboardingSlide2Body =>
      'Vaccins avec leur prochaine échéance, pesées, dépistages et visites. Salala pose le rappel à votre place.';

  @override
  String get onboardingSlide3Title => 'Son histoire voyage avec lui';

  @override
  String get onboardingSlide3Body =>
      'Un PDF ou un tableur pour l\'acheteur, et un seul ZIP qui porte chaque fiche et chaque photo vers un nouveau téléphone.';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingStart => 'Ajouter mon premier animal';

  @override
  String get settingsOnboarding => 'Revoir l\'introduction';

  @override
  String get settingsHelp => 'Aide';

  @override
  String get settingsRate => 'Noter Salala';

  @override
  String get settingsRateBody => 'Ouvre la fiche d\'avis de la boutique.';

  @override
  String get settingsWhatsNew => 'Nouveautés';

  @override
  String get settingsPrivacy => 'Confidentialité';

  @override
  String get settingsTerms => 'Conditions d\'utilisation';

  @override
  String get settingsLicenses => 'Licences libres';

  @override
  String get rateUnavailable =>
      'Ce téléphone ne peut pas afficher la fiche d\'avis pour l\'instant.';

  @override
  String get aboutTitle => 'À propos de Salala';

  @override
  String get aboutBody =>
      'Un registre hors ligne pour un petit élevage. Pas de compte, pas de serveur, pas de pistage — les fiches vivent sur ce téléphone et n\'en sortent que par vos mains.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get privacyTitle => 'Confidentialité';

  @override
  String get privacyIntro =>
      'Salala ne détient qu\'une chose : ce que vous avez saisi sur vos animaux. Cette page dit où cela se trouve et ce qui peut le faire quitter ce téléphone.';

  @override
  String get privacyStoredHeading => 'Ce qui est stocké';

  @override
  String get privacyStoredBody =>
      'Chaque animal, vaccin, pesée, dépistage, visite, symptôme, cession et contact d\'acheteur — et les photos jointes — dans une base et un dossier d\'images dans le stockage privé de l\'application. Android tient ce dossier hors de portée des autres applications, et les fichiers ne sont pas chiffrés au-delà.';

  @override
  String get privacyBackupHeading => 'Ce qui quitte ce téléphone';

  @override
  String get privacyBackupBody =>
      'Seulement ce que vous exportez : un ZIP avec toutes les fiches et images, un CSV d\'une table, ou un PDF d\'un animal. Chacun va où vous l\'envoyez, donc une sauvegarde porte les noms et téléphones de vos acheteurs — traitez le fichier comme le papier qu\'il remplace. Activez le verrouillage si le téléphone voyage.';

  @override
  String get privacyCollectHeading => 'Ce qui est collecté sur vous';

  @override
  String get privacyCollectBody =>
      'Rien. Aucune analyse, aucun rapport de plantage, aucun identifiant publicitaire et aucun appel réseau dans cette application.';

  @override
  String get privacyRemoveHeading => 'Comment l\'effacer';

  @override
  String get privacyRemoveBody =>
      'La désinstallation emporte la base et le dossier d\'images. Il n\'existe aucune copie ailleurs, alors exportez un pack d\'abord si les fiches comptent — et le code du verrouillage n\'est pas récupérable non plus.';

  @override
  String get termsTitle => 'Conditions d\'utilisation';

  @override
  String get termsUseHeading => 'À quoi sert cette application';

  @override
  String get termsUseBody =>
      'Tenir vos propres fiches sur les animaux dont vous avez la charge. Une licence par personne ; installez-la sur les téléphones que vous utilisez.';

  @override
  String get termsDataHeading => 'Vos données sont à vous';

  @override
  String get termsDataBody =>
      'Nous n\'en détenons aucune copie et ne pouvons rien restaurer. Les sauvegardes sont votre responsabilité, et le bouton d\'export dans les Réglages en est tout le mécanisme.';

  @override
  String get termsAdviceHeading => 'Pas un avis vétérinaire';

  @override
  String get termsAdviceBody =>
      'Salala répète ce que vous avez saisi et fait de l\'arithmétique sur des dates et des poids. Il ne diagnostique pas, et un rappel est une entrée d\'agenda, pas un avis clinique. Appelez un vétérinaire.';

  @override
  String get termsWarrantyHeading => 'Sans garantie';

  @override
  String get termsWarrantyBody =>
      'L\'application est fournie en l\'état. Dans la mesure permise par la loi, aucune responsabilité n\'est acceptée pour une fiche perdue, un rappel manqué ou une décision prise sur ce qui est écrit ici.';

  @override
  String get helpTitle => 'Aide';

  @override
  String get helpQ1 => 'Comment sauvegarder ?';

  @override
  String get helpA1 =>
      'Réglages, puis Exporter les dossiers. Le ZIP porte chaque ligne et chaque photo ; envoyez-le à vous-même et gardez-le. La restauration relit le même fichier sur n\'importe quel téléphone.';

  @override
  String get helpQ2 => 'J\'ai oublié mon code';

  @override
  String get helpA2 =>
      'Il n\'est pas récupérable, seule une empreinte est stockée. Désinstaller efface le verrou et le registre avec lui, donc si vous avez un pack récent, restaurez-le ensuite.';

  @override
  String get helpQ3 => 'J\'ai perdu mon téléphone';

  @override
  String get helpA3 =>
      'Rien n\'est sur un serveur, donc rien ne peut être renvoyé. Un pack exporté plus tôt restaure le registre sur un nouveau téléphone ; un pack jamais exporté est perdu.';

  @override
  String get helpQ4 => 'D\'où viennent les rappels ?';

  @override
  String get helpA4 =>
      'Des dates de prochaine échéance que vous avez saisies. Salala pose une alarme un mois avant et une le matin même ; si les notifications sont coupées, les dates restent dans l\'agenda du troupeau.';

  @override
  String get helpQ5 =>
      'Pourquoi une photo dit qu\'elle n\'est pas sur ce téléphone ?';

  @override
  String get helpA5 =>
      'La ligne a survécu, le fichier non — souvent après une restauration depuis un pack sans photos. Rajouter la photo règle le cas.';

  @override
  String get helpQ6 => 'Puis-je remettre la fiche de l\'animal ?';

  @override
  String get helpA6 =>
      'Oui. Ouvrez l\'animal et exportez son PDF : un document fixe que l\'acheteur garde sans cette application. La cession elle-même est enregistrée sur la même page.';

  @override
  String get helpQ7 => 'Quelles langues sont disponibles ?';

  @override
  String get helpA7 =>
      'Anglais, arabe, français, allemand, espagnol, italien, portugais et néerlandais. Réglages, puis Langue — le changement s\'applique aussitôt.';

  @override
  String get helpQ8 => 'Quelque chose ne va pas';

  @override
  String get helpA8 =>
      'Écrivez-nous en disant ce que vous faisiez au moment des faits. La version est sur la page À propos.';

  @override
  String get helpContactHeading => 'Écrivez-nous';

  @override
  String get whatsNewTitle => 'Nouveautés';

  @override
  String get whatsNew1 =>
      'Des photos sur les cartes du troupeau, et une mise en page plus chaude et plus ample.';

  @override
  String get whatsNew2 => 'Un rappel touché ouvre l\'animal qu\'il concerne.';

  @override
  String get whatsNew3 => 'L\'export tableur parle la langue que vous lisez.';

  @override
  String get whatsNew4 =>
      'Cinq langues de plus : allemand, espagnol, italien, portugais et néerlandais.';

  @override
  String get whatsNew5 =>
      'Pages confidentialité, conditions et aide, et une ligne de notation dans les Réglages.';

  @override
  String daysPlural(String n) {
    return '$n jours';
  }
}

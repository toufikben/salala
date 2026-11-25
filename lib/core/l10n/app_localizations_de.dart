// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Companion';

  @override
  String get navAnimals => 'Tiere';

  @override
  String get navLitters => 'Würfe';

  @override
  String get navBuyers => 'Käufer';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get languageName => 'Deutsch';

  @override
  String get homeEmptyTitle => 'Noch keine Tiere';

  @override
  String get homeEmptyBody =>
      'Eine Herde beginnt mit einem. Gib ihr einen Namen, und ihr Eintrag beginnt hier.';

  @override
  String get homeAddAnimal => 'Tier hinzufügen';

  @override
  String get homeBreedingStock => 'Zuchttiere';

  @override
  String get homeAllAnimals => 'Alle Tiere';

  @override
  String get homeSearchHint =>
      'Nach Name, Nummer, Chip, Notiz oder Käufer suchen';

  @override
  String homeNoMatches(String query) {
    return 'Kein Treffer für „$query“';
  }

  @override
  String homeAnimalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tiere',
      one: '1 Tier',
      zero: 'Keine Tiere',
    );
    return '$_temp0';
  }

  @override
  String get animalName => 'Name';

  @override
  String get animalSpecies => 'Tierart';

  @override
  String get animalBreed => 'Rasse';

  @override
  String get animalSex => 'Geschlecht';

  @override
  String get animalBirthDate => 'Geburtsdatum';

  @override
  String animalBornOn(String day) {
    return 'Geboren am $day';
  }

  @override
  String get animalStatus => 'Status';

  @override
  String get animalMicrochip => 'Microchip-Nummer';

  @override
  String get animalMicrochipDate => 'Microchip gesetzt am';

  @override
  String get animalLitter => 'Wurf';

  @override
  String get animalNone => 'Keine';

  @override
  String get animalRegistrationNo => 'Zuchtbuchnummer';

  @override
  String get animalRegistry => 'Zuchtbuch';

  @override
  String get animalColor => 'Farbe';

  @override
  String get animalNotes => 'Notizen';

  @override
  String get animalIsBreedingStock => 'Als Zuchttier führen';

  @override
  String get animalAddTitle => 'Tier hinzufügen';

  @override
  String get animalEditTitle => 'Tier bearbeiten';

  @override
  String animalDeleteTitle(String name) {
    return '$name löschen?';
  }

  @override
  String animalDeleteLittersNote(int litters, int puppies) {
    return 'Damit werden auch $litters ihrer Würfe gelöscht; die $puppies darin eingetragenen Welpen bleiben in Ihren Tieren, aber ohne den Eintrag ihrer Mutter.';
  }

  @override
  String get animalDeleteBody =>
      'Auch seine Impfungen, Gesundheitsuntersuchungen, Gewichte, Besuche und Symptome werden gelöscht, dazu jede erfasste Vermittlung, seine Fotos und die Dateien, die diese auf diesem Gerät halten, sowie der zu dieser Vermittlung angehängte Vertrag. Das lässt sich nicht rückgängig machen.';

  @override
  String get animalNameRequired => 'Ein Name ist erforderlich';

  @override
  String get animalSpeciesRequired => 'Wählen Sie eine Tierart';

  @override
  String get sexMale => 'Rüde/Kater';

  @override
  String get sexFemale => 'Hündin/Kätzin';

  @override
  String get sexUnknown => 'Unbekannt';

  @override
  String get statusActive => 'Bei mir';

  @override
  String get statusSold => 'Vermittelt';

  @override
  String get statusRetired => 'Ausgemustert';

  @override
  String get statusDeceased => 'Verstorben';

  @override
  String get recordsVaccinations => 'Impfungen';

  @override
  String get recordsHealthTests => 'Gesundheitsuntersuchungen';

  @override
  String get recordsWeights => 'Gewichte';

  @override
  String get recordsVisits => 'Tierarztbesuche';

  @override
  String get recordsSymptoms => 'Symptome';

  @override
  String get recordsPhotos => 'Fotos';

  @override
  String get recordsPlacements => 'Vermittlungen';

  @override
  String get recordsEmpty => 'Noch nichts erfasst.';

  @override
  String get detailStoryLine =>
      'Jeder Eintrag hier gehört zu seiner Geschichte.';

  @override
  String get detailDiedLine => 'Sein Eintrag bleibt, wie er war.';

  @override
  String placedFarewell(String name) {
    return '$name ist in ein neues Zuhause gegangen. Der Eintrag bleibt bei dir.';
  }

  @override
  String reminderHeadsUpBody(String what, String dueDay) {
    return 'Zur Erinnerung: $what ist am $dueDay fällig';
  }

  @override
  String reminderDueBody(String what) {
    return '$what ist heute fällig. Zwei Minuten reichen';
  }

  @override
  String get actionSave => 'Speichern';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionDelete => 'Löschen';

  @override
  String get actionEdit => 'Bearbeiten';

  @override
  String get actionAdd => 'Hinzufügen';

  @override
  String get actionClose => 'Schließen';

  @override
  String get actionRetry => 'Erneut versuchen';

  @override
  String get actionClear => 'Zurücksetzen';

  @override
  String get actionReplace => 'Ersetzen';

  @override
  String get lockTitle => 'Companion ist gesperrt';

  @override
  String get lockEnterPin => 'PIN eingeben';

  @override
  String get lockUnlock => 'Entsperren';

  @override
  String get lockWrongPin => 'Falsche PIN';

  @override
  String get lockSetPinTitle => 'PIN festlegen';

  @override
  String get lockSetPinBody =>
      'Vier Ziffern oder mehr. Sie bleibt auf diesem Gerät und lässt sich nicht wiederherstellen — schreiben Sie sie auf.';

  @override
  String get lockConfirmPin => 'PIN wiederholen';

  @override
  String get lockPinTooShort => 'Vier Ziffern oder mehr';

  @override
  String get lockPinMismatch => 'Die beiden PINs stimmen nicht überein';

  @override
  String get lockEnable => 'App sperren';

  @override
  String get lockDisable => 'Sperre ausschalten';

  @override
  String get lockCurrentPin => 'Aktuelle PIN';

  @override
  String get lockChangeFailed =>
      'Das Telefon hat die App-Sperre nicht geändert.';

  @override
  String get lockChangePinDone => 'PIN geändert.';

  @override
  String lockTooManyAttempts(int seconds) {
    return 'Zu viele falsche PINs. Erneut in $seconds s.';
  }

  @override
  String get settingsAppLock => 'App-Sperre';

  @override
  String get settingsChangePin => 'PIN ändern';

  @override
  String get settingsChangePinBody =>
      'Geben Sie die aktuelle PIN ein und wählen Sie dann eine neue.';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageSystem => 'Systemsprache';

  @override
  String get languageNotStored =>
      'Das Telefon hat diese Sprache nicht gespeichert.';

  @override
  String get startupFailedTitle =>
      'Companion konnte das Zuchtbuch auf diesem Telefon nicht öffnen.';

  @override
  String get startupFailedBody =>
      'Ihre Daten sind weiterhin in der Datei. Schließen Sie die App und öffnen Sie sie erneut.';

  @override
  String get settingsAbout => 'Über die App';

  @override
  String get settingsTrial => 'Kostenlose Testphase';

  @override
  String settingsTrialRemaining(String days) {
    return 'Noch $days Tage';
  }

  @override
  String get settingsTrialOver => 'Die Testphase ist vorbei';

  @override
  String get settingsBuildTag => 'Version';

  @override
  String get settingsOfflineNote =>
      'Alles bleibt auf diesem Gerät. Kein Konto, kein Server, keine Auswertung.';

  @override
  String get settingsExport => 'Daten exportieren';

  @override
  String get settingsExportBody =>
      'Eine ZIP-Datei mit allen Einträgen und Fotos auf diesem Telefon';

  @override
  String get settingsImport => 'Aus einem Paket wiederherstellen';

  @override
  String get settingsImportBody => 'Ein Paket zurück auf dieses Telefon lesen';

  @override
  String settingsLastBackup(String day) {
    return 'Letzte Sicherung: $day';
  }

  @override
  String get settingsNeverBackedUp =>
      'Noch keine Sicherung hat dieses Telefon verlassen';

  @override
  String get settingsCsv => 'Tabelle (CSV)';

  @override
  String get settingsCsvBody =>
      'Für die Buchhaltung, ein Zuchtbuchformular oder einen Miteigentümer. Öffnet in Excel, Numbers oder Google Tabellen.';

  @override
  String get settingsCsvHerd => 'Tiere';

  @override
  String get settingsCsvLitters => 'Würfe';

  @override
  String get settingsCsvVaccinations => 'Impfungen';

  @override
  String get settingsCsvPlacements => 'Übergaben';

  @override
  String csvShared(String file) {
    return '$file ist zum Senden bereit';
  }

  @override
  String get csvShareFailed =>
      'Die Tabelle konnte auf diesem Telefon nicht geschrieben werden';

  @override
  String get csvEmpty =>
      'Auf diesem Telefon gibt es noch nichts zu exportieren';

  @override
  String get csvColAnimal => 'Tier';

  @override
  String get csvColCountry => 'Land';

  @override
  String get csvColPuppies => 'Welpen';

  @override
  String get csvColBreedingStock => 'Zuchttier';

  @override
  String get csvColYes => 'ja';

  @override
  String get csvColNo => 'nein';

  @override
  String packShared(String file) {
    return '$file ist zum Senden bereit';
  }

  @override
  String get packShareFailed =>
      'Das Paket konnte auf diesem Telefon nicht geschrieben werden';

  @override
  String get packReadFailed => 'Diese Datei konnte nicht geöffnet werden';

  @override
  String get packNotAPack =>
      'Diese Datei ist kein Companion-Paket oder sie ist beschädigt';

  @override
  String get packFromTheFuture =>
      'Dieses Paket stammt von einer neueren Version von Companion';

  @override
  String packIncomplete(String table) {
    return 'In diesem Paket fehlt ein Teil des Zuchtbuchs: $table';
  }

  @override
  String packUnknownTable(String table) {
    return 'Dieses Paket enthält eine Tabelle, die Companion nicht kennt: $table';
  }

  @override
  String packBadValue(String detail) {
    return 'Dieses Paket enthält einen Wert, den Companion nicht lesen kann: $detail';
  }

  @override
  String get packRestoreTitle => 'Alles auf diesem Telefon ersetzen?';

  @override
  String packRestoreBody(int animals, int rows, String day) {
    return 'Vom $day. Tiere: $animals. Einträge: $rows. Die Wiederherstellung ersetzt alles, was jetzt auf diesem Telefon ist.';
  }

  @override
  String packRestored(int rows) {
    return 'Einträge wiederhergestellt: $rows';
  }

  @override
  String get packRestoreFailed =>
      'Das Paket konnte nicht wiederhergestellt werden. Auf diesem Telefon hat sich nichts geändert.';

  @override
  String get litterAdd => 'Neuer Wurf';

  @override
  String get litterEditTitle => 'Wurf bearbeiten';

  @override
  String get litterAddPuppies => 'Welpen hinzufügen';

  @override
  String get litterHowMany => 'Wie viele?';

  @override
  String get litterAddTitle => 'Wurf eintragen';

  @override
  String get litterEmptyTitle => 'Noch keine Würfe';

  @override
  String get litterEmptyBody =>
      'Erfassen Sie eine Deckung, um die Trächtigkeit zu verfolgen und die Welpen in einem Schritt einzutragen.';

  @override
  String get litterName => 'Name des Wurfs';

  @override
  String get litterNameRequired => 'Ein Name für den Wurf ist erforderlich';

  @override
  String get litterDam => 'Mutter';

  @override
  String get litterDamRequired => 'Wählen Sie die Mutter';

  @override
  String get litterDamMissing => 'Mutter gelöscht';

  @override
  String get litterSire => 'Vater';

  @override
  String get litterSireUnknown => 'Vater unbekannt';

  @override
  String get litterNoDams => 'Markieren Sie zuerst eine Hündin als Zuchttier';

  @override
  String get litterMatingDate => 'Datum der Deckung';

  @override
  String get litterWhelpingDate => 'Wurfdatum';

  @override
  String get litterWeaningDate => 'Datum der Entwöhnung';

  @override
  String get litterWhelpingBeforeMating =>
      'Das Wurfdatum liegt vor dem Deckdatum.';

  @override
  String get litterWeaningBeforeWhelping =>
      'Das Entwöhnungsdatum liegt vor dem Wurfdatum.';

  @override
  String litterExpected(String date) {
    return 'Erwarteter Wurf: $date';
  }

  @override
  String get statsTitle => 'Die Zucht in Zahlen';

  @override
  String get settingsStats => 'Die Zucht in Zahlen';

  @override
  String get statsHerdGroup => 'Wer da ist';

  @override
  String get statsBreedingGroup => 'Würfe und Welpen';

  @override
  String get statsMoneyGroup => 'Abgaben';

  @override
  String get statsAtHome => 'Tiere zu Hause';

  @override
  String get statsBreedingStock => 'Zuchttiere';

  @override
  String get statsFemales => 'Weibchen zu Hause';

  @override
  String get statsMales => 'Rüden zu Hause';

  @override
  String get statsEverRecorded => 'Insgesamt erfasst';

  @override
  String get statsWhelpings => 'Würfe im Eintrag';

  @override
  String get statsPuppies => 'Welpen aus deinen Würfen';

  @override
  String statsPuppiesThisYear(String year) {
    return 'Welpen geboren $year';
  }

  @override
  String get statsPlacements => 'Abgaben';

  @override
  String get statsUnnamedCurrency => 'Keine Währung angegeben';

  @override
  String statsHandoverCount(String count) {
    return 'Davon $count bezahlt';
  }

  @override
  String get statsNoRevenue => 'Kein Preis erfasst';

  @override
  String get statsFooter =>
      'Gezählt aus deinem eigenen Eintrag, auf diesem Gerät. Nichts davon verlässt es.';

  @override
  String get birthdayTitle => 'Demnächst';

  @override
  String get birthdayToday => 'heute';

  @override
  String birthdayIn(String days) {
    return 'in $days';
  }

  @override
  String birthdayTurning(String name, String years) {
    return '$name wird $years';
  }

  @override
  String get heatCardTitle => 'Nächste Läufigkeit';

  @override
  String heatCardWindow(String earliest, String latest) {
    return 'Zwischen $earliest und $latest';
  }

  @override
  String heatCardSteady(String count) {
    return 'Aus $count Zyklen in ihrem eigenen Eintrag.';
  }

  @override
  String get heatCardThin =>
      'Nur ein Zyklus eingetragen, deshalb ist das Fenster weit. Eine weitere Belegung engt es ein.';

  @override
  String heatCardWhelping(String day) {
    return 'Eine Belegung in diesem Fenster würde etwa am $day werfen.';
  }

  @override
  String get bulkVaccineTitle => 'Zusammen impfen';

  @override
  String bulkVaccineCount(String count) {
    return '$count Tiere bekommen dieselbe Dosis';
  }

  @override
  String get bulkVaccineAction => 'Den Wurf impfen';

  @override
  String bulkVaccineDone(String count) {
    return 'Für $count Tiere eingetragen';
  }

  @override
  String get pedigreeTitle => 'Ahnentafel';

  @override
  String litterPuppyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Welpen',
      one: '1 Welpe',
      zero: 'Keine Welpen eingetragen',
    );
    return '$_temp0';
  }

  @override
  String get litterPuppiesToRegister => 'Geborene Welpen';

  @override
  String get litterPuppiesHint =>
      'Jeder Welpe kommt zu Ihren Tieren und wird nach dem Wurf benannt';

  @override
  String get litterNoPuppies =>
      'Für diesen Wurf sind noch keine Welpen eingetragen.';

  @override
  String get litterGone => 'Dieser Wurf wurde gelöscht.';

  @override
  String litterDeleteTitle(String name) {
    return '$name löschen?';
  }

  @override
  String get litterDeleteBody =>
      'Die Welpen bleiben in Ihren Tieren; nur der Deckungseintrag wird entfernt. Das lässt sich nicht rückgängig machen.';

  @override
  String get animalGone => 'Dieses Tier wurde gelöscht.';

  @override
  String get animalDeathDate => 'Verstorben am';

  @override
  String get animalDam => 'Mutter';

  @override
  String get animalSire => 'Vater';

  @override
  String get valueUnknown => 'Nicht erfasst';

  @override
  String get recordDeleteTitle => 'Diesen Eintrag löschen?';

  @override
  String get recordSaveFailed =>
      'Das ließ sich nicht speichern. Es wurde nichts geschrieben.';

  @override
  String get recordDeleteFailed =>
      'Das ließ sich nicht löschen. Der Eintrag ist noch da.';

  @override
  String get recordDateBeforeBirth =>
      'Dieses Datum liegt vor der Geburt dieses Tieres.';

  @override
  String get vaccinationAdd => 'Impfung hinzufügen';

  @override
  String get vaccinationAddTitle => 'Impfung erfassen';

  @override
  String get vaccinationEditTitle => 'Impfung bearbeiten';

  @override
  String get vaccinationName => 'Impfstoff';

  @override
  String get vaccinationNameRequired => 'Ein Impfstoffname ist erforderlich';

  @override
  String get vaccinationGiven => 'Gegeben am';

  @override
  String get vaccinationNextDue => 'Nächste fällig';

  @override
  String get vaccinationNextDueHint =>
      'Eine Dosis, deren Termin überschritten ist, wird als überfällig markiert.';

  @override
  String get doseDueBeforeAdministered =>
      'Die nächste Dosis wäre vor dieser hier fällig.';

  @override
  String get vaccinationOverdue => 'Überfällig';

  @override
  String get vaccinationManufacturer => 'Hersteller';

  @override
  String get vaccinationBatch => 'Chargennummer';

  @override
  String get vaccinationVet => 'Tierarzt';

  @override
  String get vaccinationClinic => 'Praxis';

  @override
  String get vaccinationCertificate => 'Zertifikatsnummer';

  @override
  String get vaccinationDeleteBody =>
      'Die Dosis wird aus der Vorgeschichte dieses Tieres entfernt. Das lässt sich nicht rückgängig machen.';

  @override
  String get weightAdd => 'Gewicht hinzufügen';

  @override
  String get weightKg => 'Gewicht (kg)';

  @override
  String get weightColumn => 'Gewicht';

  @override
  String get weightRequired => 'Geben Sie das Gewicht ein';

  @override
  String get weightInvalid => 'Geben Sie ein Gewicht wie 4,2 ein';

  @override
  String get weightMeasuredOn => 'Gemessen am';

  @override
  String get unitKg => 'kg';

  @override
  String get unitGrams => 'g';

  @override
  String get weightNote => 'Notiz';

  @override
  String get weightDeleteBody =>
      'Die Wägung wird entfernt. Das lässt sich nicht rückgängig machen.';

  @override
  String get weightAppendOnlyHint =>
      'Wägungen werden nie bearbeitet. Falsch gemessen? Löschen und erneut wiegen.';

  @override
  String get animalSpeciesHelper => 'Hund · Katze';

  @override
  String get healthTestAdd => 'Untersuchung hinzufügen';

  @override
  String get healthTestAddTitle => 'Gesundheitsuntersuchung erfassen';

  @override
  String get healthTestEditTitle => 'Untersuchung bearbeiten';

  @override
  String get healthTestType => 'Screening';

  @override
  String get healthTestTypeRequired => 'Benennen Sie das Screening';

  @override
  String get healthTestResult => 'Ergebnis';

  @override
  String get healthTestResultRequired => 'Geben Sie das Ergebnis ein';

  @override
  String get healthTestResultHelper => 'Clear · Carrier · Affected';

  @override
  String get healthTestDate => 'Untersucht am';

  @override
  String get healthTestValidUntil => 'Gültig bis';

  @override
  String get certificateExpiresBeforeTest =>
      'Dieses Zertifikat läuft vor dem Tag der Untersuchung ab, die es bescheinigt.';

  @override
  String get healthTestBody => 'Untersuchungsstelle';

  @override
  String get healthTestVerifiedBy => 'Bestätigt von';

  @override
  String get healthTestExpired => 'Abgelaufen';

  @override
  String get healthTestDeleteBody =>
      'Das Screening wird aus der Vorgeschichte dieses Tieres entfernt. Das lässt sich nicht rückgängig machen.';

  @override
  String get visitAdd => 'Besuch hinzufügen';

  @override
  String get visitAddTitle => 'Tierarztbesuch erfassen';

  @override
  String get visitEditTitle => 'Tierarztbesuch bearbeiten';

  @override
  String get visitDate => 'Datum des Besuchs';

  @override
  String get visitReason => 'Grund';

  @override
  String get visitNoReason => 'Konsultation';

  @override
  String get visitOutcome => 'Ergebnis';

  @override
  String get visitCost => 'Kosten';

  @override
  String get visitCostInvalid => 'Geben Sie einen Betrag wie 250 ein';

  @override
  String get visitCurrency => 'Währung';

  @override
  String get visitDeleteBody =>
      'Der Besuch wird aus der Vorgeschichte dieses Tieres entfernt. Das lässt sich nicht rückgängig machen.';

  @override
  String get symptomAdd => 'Symptom hinzufügen';

  @override
  String get symptomAddTitle => 'Symptom erfassen';

  @override
  String get symptomEditTitle => 'Symptom bearbeiten';

  @override
  String get symptomName => 'Symptom';

  @override
  String get symptomNameRequired => 'Schreiben Sie, was Sie gesehen haben';

  @override
  String get symptomSeverity => 'Schweregrad';

  @override
  String get severityMild => 'Leicht';

  @override
  String get severityModerate => 'Mittel';

  @override
  String get severitySevere => 'Schwer';

  @override
  String get symptomObservedOn => 'Beobachtet am';

  @override
  String get symptomState => 'Zustand';

  @override
  String get symptomOngoing => 'Besteht weiter';

  @override
  String get symptomResolved => 'Abgeklungen';

  @override
  String get symptomDeleteBody =>
      'Das Symptom wird aus der Vorgeschichte dieses Tieres entfernt. Das lässt sich nicht rückgängig machen.';

  @override
  String get photoAdd => 'Foto hinzufügen';

  @override
  String get photoFromGallery => 'Aus der Galerie wählen';

  @override
  String get photoFromCamera => 'Foto aufnehmen';

  @override
  String get photoDeleteBody =>
      'Das Bild wird aus dem Zuchtbuch dieses Tieres entfernt, und die Datei mit ihm. Das lässt sich nicht rückgängig machen.';

  @override
  String get photoMissing => 'Nicht auf diesem Telefon';

  @override
  String get photoTooLarge => 'Dieses Bild ist zu groß zum Behalten';

  @override
  String get photoNotAnImage => 'Diese Datei ist kein Bild';

  @override
  String get placementAdd => 'Vermittlung hinzufügen';

  @override
  String get placementAddTitle => 'Vermittlung erfassen';

  @override
  String get placementEditTitle => 'Vermittlung bearbeiten';

  @override
  String get placementBuyer => 'Käufer';

  @override
  String get placementNoBuyer => 'Käufer nicht erfasst';

  @override
  String get placementDate => 'Vermittelt am';

  @override
  String get placementPrice => 'Preis';

  @override
  String get placementPriceInvalid => 'Geben Sie einen Betrag wie 2500 ein';

  @override
  String get placementCurrency => 'Währung';

  @override
  String get placementGuarantee => 'Garantiebedingungen';

  @override
  String get contractAttach => 'Vertrag anhängen';

  @override
  String get contractAttached => 'Vertrag angehängt';

  @override
  String get contractStoredName => 'Ein früher angehängtes Dokument';

  @override
  String get contractRemove => 'Vertrag entfernen';

  @override
  String get contractOpen => 'Vertrag öffnen';

  @override
  String get contractMissing => 'Dieses Dokument ist nicht auf diesem Gerät';

  @override
  String get contractOpenFailed => 'Das Dokument konnte nicht geöffnet werden';

  @override
  String get contractPickFailed => 'Es konnte kein Dokument gewählt werden';

  @override
  String get contractTooLarge => 'Diese Datei ist zu groß zum Aufbewahren';

  @override
  String get placementDeleteBody =>
      'Die Vermittlung wird aus der Vorgeschichte dieses Tieres entfernt. Der Käufer bleibt in Ihren Kontakten. Das lässt sich nicht rückgängig machen.';

  @override
  String get buyerAdd => 'Neuer Käufer';

  @override
  String get buyerAddTitle => 'Käufer hinzufügen';

  @override
  String get buyerEditTitle => 'Käufer bearbeiten';

  @override
  String get buyerPhone => 'Telefon';

  @override
  String get buyerEmail => 'E-Mail';

  @override
  String get buyerCountryCode => 'Ländercode';

  @override
  String get buyersEmptyTitle => 'Noch keine Käufer';

  @override
  String get buyersEmptyBody =>
      'Ein Käufer entsteht mit einer Übergabe — oder hier, schon vorher: wer letztes Jahr bei Ihnen gekauft hat, möchte dennoch den Stammbaum.';

  @override
  String get buyersNoAnimals => 'Kein Tier für diesen Kontakt erfasst';

  @override
  String buyerDeleteBody(String name) {
    return '$name wird aus Ihren Kontakten entfernt. Die Übergabe bleibt in der Vorgeschichte des Tieres, ohne benannten Käufer. Das lässt sich nicht rückgängig machen.';
  }

  @override
  String get pdfAction => 'PDF-Dossier';

  @override
  String get pdfFailed => 'Das PDF konnte nicht erstellt werden';

  @override
  String get pdfTitle => 'Gesundheits- und Abstammungsnachweis';

  @override
  String get pdfLitterTitle => 'Wurfprotokoll';

  @override
  String pdfGenerated(String day) {
    return 'Erstellt am $day';
  }

  @override
  String get pdfPedigree => 'Stammbaum';

  @override
  String get pdfLitters => 'Würfe dieses Tieres';

  @override
  String get pdfPuppies => 'Welpen';

  @override
  String get pdfPlacement => 'Vermittlung';

  @override
  String get pdfBuyer => 'Käufer';

  @override
  String get pdfPhone => 'Telefon';

  @override
  String get pdfEmail => 'E-Mail';

  @override
  String get pdfPlacedOn => 'Vermittelt am';

  @override
  String get pdfPrice => 'Preis';

  @override
  String get pdfGuarantee => 'Garantiebedingungen';

  @override
  String get pdfChartAxes =>
      'Gewicht in Kilogramm gegen das Alter in Monaten. Die Tabelle darüber schreibt das Gewicht eines jungen Welpen in Gramm.';

  @override
  String get pdfDisclaimer =>
      'Offline von Companion aus den eigenen Aufzeichnungen des Züchters erstellt. Dies ist kein tierärztliches Zertifikat.';

  @override
  String get triageTitle => 'Was als Nächstes zu tun ist';

  @override
  String get triageActNow => 'Jetzt handeln';

  @override
  String get triageWatch => 'Weiter beobachten';

  @override
  String get triageRoutineVet => 'Routinebesuch beim Tierarzt';

  @override
  String get triageNothing =>
      'In diesem Eintrag steht nichts, was einen nächsten Schritt verlangt';

  @override
  String get triageNotDiagnosis =>
      'Companion liest nur, was Sie hier eingetragen haben. Das ist keine tierärztliche Diagnose.';

  @override
  String triageNoDoseYoung(String days) {
    return 'Keine Impfung erfasst, mit $days';
  }

  @override
  String triageDoseOverdue(String name, String days) {
    return '$name war vor $days fällig';
  }

  @override
  String triageDoseDueSoon(String name, String days) {
    return '$name ist in $days fällig';
  }

  @override
  String triageDoseToday(String what) {
    return '$what ist heute fällig';
  }

  @override
  String triageWeightLossPuppy(String percent) {
    return 'Ein junges Tier hat seit der letzten Wägung $percent % seines Gewichts verloren';
  }

  @override
  String triageWeightLoss(String percent) {
    return 'Das Gewicht ist seit der letzten Wägung um $percent % gefallen';
  }

  @override
  String triageNoGainPuppy(String days) {
    return 'Kaum Gewichtszunahme über $days';
  }

  @override
  String triageTestFlagged(String name) {
    return '$name kam nicht mit klarem Ergebnis zurück';
  }

  @override
  String triageTestExpired(String name, String days) {
    return 'Das Zertifikat $name ist vor $days abgelaufen';
  }

  @override
  String triageWhelpingOverdue(String name, String days) {
    return '$name: der Wurf liegt $days über dem erwarteten Termin';
  }

  @override
  String triageSevereSymptom(String name) {
    return '$name wurde als schwer erfasst und besteht weiter';
  }

  @override
  String triageSymptomUnresolved(String name, String days) {
    return '$name wurde vor $days beobachtet und besteht weiter';
  }

  @override
  String get agendaTitle => 'Impfungen zu terminieren';

  @override
  String daysSingle(String n) {
    return '$n Tag';
  }

  @override
  String daysDual(String n) {
    return '$n Tage';
  }

  @override
  String get onboardingSlide1Title => 'Ein Eintrag pro Tier';

  @override
  String get onboardingSlide1Body =>
      'Hund oder Katze, Rasse, Geburtsdatum und Herkunft. Das erste dauert keine Minute.';

  @override
  String get onboardingSlide2Title => 'Seine Gesundheit, der Reihe nach';

  @override
  String get onboardingSlide2Body =>
      'Impfungen mit der nächsten Fälligkeit, Wägungen, Screenings und Tierarztbesuche. Companion stellt die Erinnerung für Sie.';

  @override
  String get onboardingSlide3Title => 'Seine Geschichte reist mit';

  @override
  String get onboardingSlide3Body =>
      'Ein PDF oder eine Tabelle für den Käufer, und ein ZIP, das jeden Eintrag und jedes Foto auf ein neues Telefon bringt.';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingStart => 'Erstes Tier hinzufügen';

  @override
  String get settingsOnboarding => 'Einführung erneut zeigen';

  @override
  String get settingsHelp => 'Hilfe';

  @override
  String get settingsRate => 'Companion bewerten';

  @override
  String get settingsRateBody => 'Öffnet die Bewertungskarte des Stores.';

  @override
  String get settingsWhatsNew => 'Neu in dieser Version';

  @override
  String get settingsPrivacy => 'Datenschutz';

  @override
  String get settingsTerms => 'Nutzungsbedingungen';

  @override
  String get settingsLicenses => 'Open-Source-Lizenzen';

  @override
  String get rateUnavailable =>
      'Dieses Telefon kann die Bewertungskarte gerade nicht anzeigen.';

  @override
  String get aboutTitle => 'Über Companion';

  @override
  String get aboutBody =>
      'Ein Offline-Verzeichnis für eine kleine Zucht. Kein Konto, kein Server, kein Tracking — die Einträge liegen auf diesem Telefon und verlassen es nur durch Ihre Hand.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get privacyTitle => 'Datenschutz';

  @override
  String get privacyIntro =>
      'Companion hält nur eines: was Sie über Ihre Tiere eingetragen haben. Diese Seite sagt, wo es liegt und was es von diesem Telefon entfernen kann.';

  @override
  String get privacyStoredHeading => 'Was gespeichert wird';

  @override
  String get privacyStoredBody =>
      'Jedes Tier, jede Impfung, Wägung, jedes Screening, jeder Besuch, jedes Symptom, jede Vermittlung und jeder Käuferkontakt — und die angehängten Fotos — in einer Datenbank und einem Bildordner im privaten Speicher der App. Android hält diesen Ordner von anderen Apps fern, und die Dateien sind darüber hinaus nicht verschlüsselt.';

  @override
  String get privacyBackupHeading => 'Was dieses Telefon verlässt';

  @override
  String get privacyBackupBody =>
      'Nur was Sie exportieren: ein ZIP mit allen Einträgen und Bildern, eine CSV einer Tabelle oder ein PDF eines Tieres. Jedes geht dorthin, wohin Sie es schicken, also trägt eine Sicherung Namen und Telefonnummern Ihrer Käufer — behandeln Sie die Datei wie das Papier, das sie ersetzt. Schalten Sie die App-Sperre ein, wenn das Telefon reist.';

  @override
  String get privacyCollectHeading => 'Was über Sie gesammelt wird';

  @override
  String get privacyCollectBody =>
      'Nichts. Keine Analyse, keine Absturzberichte, keine Werbe-ID und kein Netzwerkaufruf in dieser App.';

  @override
  String get privacyRemoveHeading => 'Wie man es löscht';

  @override
  String get privacyRemoveBody =>
      'Deinstallieren entfernt die Datenbank und den Bildordner. Anderswo gibt es keine Kopie, also exportieren Sie zuerst ein Paket, wenn die Einträge zählen — und die PIN der App-Sperre ist ebenfalls nicht wiederherstellbar.';

  @override
  String get termsTitle => 'Nutzungsbedingungen';

  @override
  String get termsUseHeading => 'Wofür diese App gedacht ist';

  @override
  String get termsUseBody =>
      'Eigene Aufzeichnungen über die Tiere in Ihrer Obhut zu führen. Eine Lizenz pro Person; installieren Sie sie auf den Telefonen, die Sie nutzen.';

  @override
  String get termsDataHeading => 'Ihre Daten gehören Ihnen';

  @override
  String get termsDataBody =>
      'Wir halten keine Kopie und können nichts wiederherstellen. Sicherungen sind Ihre Verantwortung, und die Exportzeile in den Einstellungen ist der ganze Mechanismus.';

  @override
  String get termsAdviceHeading => 'Keine tierärztliche Beratung';

  @override
  String get termsAdviceBody =>
      'Companion wiederholt, was Sie eingetragen haben, und rechnet mit Daten und Gewichten. Es diagnostiziert nicht, und eine Erinnerung ist ein Kalendereintrag, keine klinische Meinung. Rufen Sie eine Tierärztin an.';

  @override
  String get termsWarrantyHeading => 'Keine Gewährleistung';

  @override
  String get termsWarrantyBody =>
      'Die App wird so bereitgestellt, wie sie ist. Soweit das Recht es zulässt, wird keine Haftung für einen verlorenen Eintrag, eine verpasste Erinnerung oder eine auf diese Angaben gestützte Entscheidung übernommen.';

  @override
  String get helpTitle => 'Hilfe';

  @override
  String get helpQ1 => 'Wie sichere ich?';

  @override
  String get helpA1 =>
      'Einstellungen, dann Daten exportieren. Das ZIP trägt jede Zeile und jedes Foto; schicken Sie es sich selbst und heben Sie es auf. Wiederherstellen liest dieselbe Datei auf jedem Telefon.';

  @override
  String get helpQ2 => 'Ich habe meine PIN vergessen';

  @override
  String get helpA2 =>
      'Sie ist nicht wiederherstellbar, weil nur ein Hash gespeichert ist. Deinstallieren löscht die Sperre und mit ihr das Verzeichnis, also stellen Sie danach ein aktuelles Paket wieder her.';

  @override
  String get helpQ3 => 'Ich habe mein Telefon verloren';

  @override
  String get helpA3 =>
      'Nichts liegt auf einem Server, also kann nichts zurückgeschickt werden. Ein früher exportiertes Paket stellt das Verzeichnis auf einem neuen Telefon wieder her; ein nie exportiertes ist verloren.';

  @override
  String get helpQ4 => 'Woher kommen die Erinnerungen?';

  @override
  String get helpA4 =>
      'Aus den Fälligkeitsdaten, die Sie eingetragen haben. Companion stellt einen Alarm einen Monat vorher und einen am Morgen selbst; sind Benachrichtigungen aus, stehen die Daten weiterhin in der Agenda der Herde.';

  @override
  String get helpQ5 => 'Warum sagt ein Foto, es sei nicht auf diesem Telefon?';

  @override
  String get helpA5 =>
      'Die Zeile blieb, die Datei nicht — meist nach einer Wiederherstellung aus einem Paket ohne Bilder. Das Foto erneut hinzuzufügen behebt es.';

  @override
  String get helpQ6 => 'Kann ich den Eintrag des Tieres weitergeben?';

  @override
  String get helpA6 =>
      'Ja. Öffnen Sie das Tier und exportieren Sie sein PDF: ein festes Dokument, das der Käufer ohne diese App behält. Die Vermittlung selbst wird auf derselben Seite festgehalten.';

  @override
  String get helpQ7 => 'Welche Sprachen gibt es?';

  @override
  String get helpA7 =>
      'Englisch, Arabisch, Französisch, Deutsch, Spanisch, Italienisch, Portugiesisch und Niederländisch. Einstellungen, dann Sprache — die Änderung gilt sofort.';

  @override
  String get helpQ8 => 'Etwas stimmt nicht';

  @override
  String get helpA8 =>
      'Schreiben Sie uns und sagen Sie, was Sie gerade taten. Die Version steht auf der Seite „Über“.';

  @override
  String get helpContactHeading => 'Schreiben Sie uns';

  @override
  String get whatsNewTitle => 'Neu in dieser Version';

  @override
  String get whatsNew1 =>
      'Fotos auf den Herdenkarten und ein wärmeres, großzügigeres Layout.';

  @override
  String get whatsNew2 =>
      'Ein angetippter Reminder öffnet das Tier, um das es geht.';

  @override
  String get whatsNew3 =>
      'Der Tabellenexport spricht die Sprache, die Sie lesen.';

  @override
  String get whatsNew4 =>
      'Fünf weitere Sprachen: Deutsch, Spanisch, Italienisch, Portugiesisch und Niederländisch.';

  @override
  String get whatsNew5 =>
      'Seiten für Datenschutz, Bedingungen und Hilfe, und eine Bewertungszeile in den Einstellungen.';

  @override
  String get whatsNew6 =>
      'Eine Liste je Tier: jede Impfung, jedes Gewicht, jeder Besuch und jede Vermittlung nach Datum.';

  @override
  String get timelineTitle => 'Was geschehen ist';

  @override
  String get timelineEmpty => 'Noch nichts mit Datum.';

  @override
  String timelineShowAll(String count) {
    return 'Alle $count anzeigen';
  }

  @override
  String get timelineShowLess => 'Weniger anzeigen';

  @override
  String get timelineKindBorn => 'Geburt';

  @override
  String get timelineKindDied => 'Tod';

  @override
  String get timelineKindWhelped => 'Wurf';

  @override
  String get timelineKindVaccination => 'Impfung';

  @override
  String get timelineKindHealthTest => 'Gesundheitsuntersuchung';

  @override
  String get timelineKindVisit => 'Tierarztbesuch';

  @override
  String get timelineKindSymptom => 'Symptom';

  @override
  String get timelineKindWeight => 'Gewicht';

  @override
  String get timelineKindPhoto => 'Foto';

  @override
  String get timelineKindPlacement => 'Vermittlung';

  @override
  String daysPlural(String n) {
    return '$n Tage';
  }

  @override
  String get onboardingLittersTitle =>
      'Jeder Wurf, von der Deckung bis zum Absetzen';

  @override
  String get onboardingLittersBody =>
      'Deckdatum eintragen, und Companion gibt Ihnen ein Wurffenster statt einer Schätzung. Danach jeder Welpe mit Geschlecht, Farbe und Geburtsgewicht.';

  @override
  String get onboardingPedigreeTitle => 'Die Ahnentafel auf einer Seite';

  @override
  String get onboardingPedigreeBody =>
      'Vater, Mutter und Großeltern als Baum, gedruckt neben dem Gesundheitsbericht. Genug für einen Käufer, ohne Zuchtverband.';

  @override
  String get onboardingBuyersTitle => 'Wer wartet, wer gezahlt hat';

  @override
  String get onboardingBuyersBody =>
      'Anzahlungen, der Welpe jedes Käufers, der Tag des Umzugs und der unterschriebene Vertrag dazu abgelegt.';

  @override
  String get onboardingYoursTitle => 'Kein fremder Server';

  @override
  String get onboardingYoursBody =>
      'Kein Konto, keine Werbung, kein Tracking. Läuft im Schuppen ohne Netz, und Ihre Daten verlassen das Telefon nur beim Export.';

  @override
  String get onboardingSupportTitle => 'Von einer Person gebaut';

  @override
  String get onboardingSupportBody =>
      'Companion wird von einem einzelnen Programmierer gebaut, nicht von einer Firma. Keine Werbung, keine Investoren. Wenn es seinen Platz in Ihrem Zwinger verdient, hält der Kauf die Updates am Laufen.';

  @override
  String get upgradeTitle => 'Companion Pro';

  @override
  String get upgradeIntro =>
      'Das Zuchtbuch bleibt dauerhaft kostenlos. Pro ist der Teil, den man anderen zeigt: unbegrenzte Fotos, der Ahnentafel-Baum, der Kaufvertrag, das PDF mit eigener Kopfzeile und unbegrenzte Sicherungen.';

  @override
  String get upgradeProTitle => 'Pro';

  @override
  String get upgradeProBody => 'Ein Zwinger.';

  @override
  String get upgradeStudioTitle => 'Studio';

  @override
  String get upgradeStudioBody => 'Mehr als ein Zwinger, gleiche Funktionen.';

  @override
  String get upgradeMonthly => 'Monatlich';

  @override
  String get upgradeYearly => 'Jährlich';

  @override
  String get upgradeYearlyNote => 'Zwei Monate gratis';

  @override
  String get upgradePriceLoading => 'Preis wird beim Store abgefragt...';

  @override
  String get upgradeSubscribe => 'Abonnieren';

  @override
  String get upgradeRestore => 'Kauf wiederherstellen';

  @override
  String get upgradeRestored => 'Dein Kauf ist wieder da.';

  @override
  String get upgradeNothingToRestore => 'Kein Kauf in diesem Konto gefunden.';

  @override
  String get upgradeStoreUnreachable =>
      'Der Store war nicht erreichbar. Versuche es erneut, sobald du online bist.';

  @override
  String get upgradeThankYou => 'Danke. Alles ist freigeschaltet.';

  @override
  String get upgradeFailed =>
      'Der Store hat das nicht abgeschlossen. Es wurde nichts berechnet.';

  @override
  String get upgradeLater => 'Nicht jetzt';

  @override
  String upgradeTrialDays(int days) {
    return 'Noch $days Tage mit allem';
  }

  @override
  String get upgradeTrialOver => 'Die Testphase ist beendet';

  @override
  String get settingsProTitle => 'Companion Pro';

  @override
  String get settingsProOwned => 'Auf diesem Telefon aktiv';

  @override
  String get settingsProFree => 'Was Pro bringt';

  @override
  String proGateTitle(String feature) {
    return '$feature gehört zu Pro';
  }

  @override
  String get proGateBody =>
      'Tiere, Würfe, Gesundheitsdaten, Ahnentafel und Sicherungen bleiben kostenlos. Pro ergänzt, was der Käufer sieht.';

  @override
  String get proGateSee => 'Tarife ansehen';

  @override
  String get featurePhotos => 'Unbegrenzte Fotos';

  @override
  String get featureReports => 'Berichte mit Kopfzeile';

  @override
  String get featureContracts => 'Kaufverträge';

  @override
  String get featureStats => 'Die Zwinger-Statistik';
}

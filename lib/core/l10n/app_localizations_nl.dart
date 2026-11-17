// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Salala';

  @override
  String get navAnimals => 'Dieren';

  @override
  String get navLitters => 'Nestjes';

  @override
  String get navBuyers => 'Kopers';

  @override
  String get navSettings => 'Instellingen';

  @override
  String get languageName => 'Nederlands';

  @override
  String get homeEmptyTitle => 'Nog geen dieren';

  @override
  String get homeEmptyBody =>
      'Voeg uw eerste hond of kat toe om een gezondheids- en afstammingsdossier te beginnen.';

  @override
  String get homeAddAnimal => 'Dier toevoegen';

  @override
  String get homeBreedingStock => 'Fokdieren';

  @override
  String get homeAllAnimals => 'Alle dieren';

  @override
  String get homeSearchHint => 'Zoek op naam, nummer, chip, notitie of koper';

  @override
  String homeNoMatches(String query) {
    return 'Niets komt overeen met ‘$query’';
  }

  @override
  String homeAnimalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dieren',
      one: '1 dier',
      zero: 'Geen dieren',
    );
    return '$_temp0';
  }

  @override
  String get animalName => 'Naam';

  @override
  String get animalSpecies => 'Soort';

  @override
  String get animalBreed => 'Ras';

  @override
  String get animalSex => 'Geslacht';

  @override
  String get animalBirthDate => 'Geboortedatum';

  @override
  String animalBornOn(String day) {
    return 'Geboren op $day';
  }

  @override
  String get animalStatus => 'Status';

  @override
  String get animalMicrochip => 'Chipnummer';

  @override
  String get animalMicrochipDate => 'Chip geplaatst op';

  @override
  String get animalLitter => 'Nestje';

  @override
  String get animalNone => 'Geen';

  @override
  String get animalRegistrationNo => 'Stamboeknummer';

  @override
  String get animalRegistry => 'Stamboek';

  @override
  String get animalColor => 'Kleur';

  @override
  String get animalNotes => 'Notities';

  @override
  String get animalIsBreedingStock => 'Als fokdier aanhouden';

  @override
  String get animalAddTitle => 'Dier toevoegen';

  @override
  String get animalEditTitle => 'Dier bewerken';

  @override
  String animalDeleteTitle(String name) {
    return '$name verwijderen?';
  }

  @override
  String animalDeleteLittersNote(int litters, int puppies) {
    return 'Hiermee verdwijnen ook $litters van haar nestjes, en de $puppies puppy\'s die daarin staan blijven bij uw dieren maar zonder de gegevens van hun moeder.';
  }

  @override
  String get animalDeleteBody =>
      'Ook haar inentingen, gezondheidstests, gewichten, bezoeken en symptomen worden verwijderd, samen met elke geregistreerde plaatsing, haar foto\'s en de bestanden die deze op dit toestel bewaren. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get animalNameRequired => 'Een naam is verplicht';

  @override
  String get animalSpeciesRequired => 'Kies een soort';

  @override
  String get sexMale => 'Reu/Kater';

  @override
  String get sexFemale => 'Teef/Poes';

  @override
  String get sexUnknown => 'Onbekend';

  @override
  String get statusActive => 'Bij mij';

  @override
  String get statusSold => 'Geplaatst';

  @override
  String get statusRetired => 'Afgevoerd';

  @override
  String get statusDeceased => 'Overleden';

  @override
  String get recordsVaccinations => 'Inentingen';

  @override
  String get recordsHealthTests => 'Gezondheidstests';

  @override
  String get recordsWeights => 'Gewichten';

  @override
  String get recordsVisits => 'Dierenartsbezoeken';

  @override
  String get recordsSymptoms => 'Symptomen';

  @override
  String get recordsPhotos => 'Foto\'s';

  @override
  String get recordsPlacements => 'Plaatsingen';

  @override
  String get recordsEmpty => 'Nog niets vastgelegd.';

  @override
  String get actionSave => 'Opslaan';

  @override
  String get actionCancel => 'Annuleren';

  @override
  String get actionDelete => 'Verwijderen';

  @override
  String get actionEdit => 'Bewerken';

  @override
  String get actionAdd => 'Toevoegen';

  @override
  String get actionClose => 'Sluiten';

  @override
  String get actionRetry => 'Opnieuw proberen';

  @override
  String get actionClear => 'Wissen';

  @override
  String get actionReplace => 'Vervangen';

  @override
  String get lockTitle => 'Salala is vergrendeld';

  @override
  String get lockEnterPin => 'Voer uw pincode in';

  @override
  String get lockUnlock => 'Ontgrendelen';

  @override
  String get lockWrongPin => 'Onjuiste pincode';

  @override
  String get lockSetPinTitle => 'Pincode aanmaken';

  @override
  String get lockSetPinBody =>
      'Vier cijfers of meer. De code blijft op dit toestel en kan niet worden hersteld, dus schrijf hem op.';

  @override
  String get lockConfirmPin => 'Herhaal de pincode';

  @override
  String get lockPinTooShort => 'Vier cijfers of meer';

  @override
  String get lockPinMismatch => 'De twee pincodes komen niet overeen';

  @override
  String get lockEnable => 'App vergrendelen';

  @override
  String get lockDisable => 'Vergrendeling uitzetten';

  @override
  String get lockCurrentPin => 'Huidige pincode';

  @override
  String get lockChangeFailed =>
      'Het toestel heeft de app-vergrendeling niet gewijzigd.';

  @override
  String get lockChangePinDone => 'Pincode gewijzigd.';

  @override
  String lockTooManyAttempts(int seconds) {
    return 'Te veel onjuiste pincodes. Probeer opnieuw over $seconds s.';
  }

  @override
  String get settingsAppLock => 'App-vergrendeling';

  @override
  String get settingsChangePin => 'Pincode wijzigen';

  @override
  String get settingsChangePinBody =>
      'Voer de huidige pincode in en kies daarna een nieuwe.';

  @override
  String get settingsLanguage => 'Taal';

  @override
  String get settingsLanguageSystem => 'Systeemtaal';

  @override
  String get languageNotStored =>
      'Het toestel heeft deze taal niet opgeslagen.';

  @override
  String get startupFailedTitle =>
      'Salala kon het stamboek op dit toestel niet openen.';

  @override
  String get startupFailedBody =>
      'Uw gegevens staan nog in het bestand. Sluit de app en open hem opnieuw.';

  @override
  String get settingsAbout => 'Over de app';

  @override
  String get settingsBuildTag => 'Versie';

  @override
  String get settingsOfflineNote =>
      'Alles blijft op dit toestel. Geen account, geen server, geen tracking.';

  @override
  String get settingsExport => 'Dossiers exporteren';

  @override
  String get settingsExportBody =>
      'Eén ZIP-bestand met alle gegevens en foto\'s op dit toestel';

  @override
  String get settingsImport => 'Herstellen uit een pakket';

  @override
  String get settingsImportBody => 'Een pakket teruglezen op dit toestel';

  @override
  String settingsLastBackup(String day) {
    return 'Laatste back-up: $day';
  }

  @override
  String get settingsNeverBackedUp =>
      'Er heeft nog geen back-up dit toestel verlaten';

  @override
  String get settingsCsv => 'Werkblad (CSV)';

  @override
  String get settingsCsvBody =>
      'Voor uw boekhouder, een stamboekformulier of een mede-eigenaar. Opent in Excel, Numbers of Google Sheets.';

  @override
  String get settingsCsvHerd => 'Dieren';

  @override
  String get settingsCsvLitters => 'Nestjes';

  @override
  String get settingsCsvVaccinations => 'Inentingen';

  @override
  String get settingsCsvPlacements => 'Plaatsingen';

  @override
  String csvShared(String file) {
    return '$file staat klaar om te versturen';
  }

  @override
  String get csvShareFailed =>
      'De spreadsheet kon niet op dit toestel worden geschreven';

  @override
  String get csvEmpty => 'Er is op dit toestel nog niets om te exporteren';

  @override
  String get csvColAnimal => 'Dier';

  @override
  String get csvColCountry => 'Land';

  @override
  String get csvColPuppies => 'Puppy\'s';

  @override
  String get csvColBreedingStock => 'Fokdier';

  @override
  String get csvColYes => 'ja';

  @override
  String get csvColNo => 'nee';

  @override
  String packShared(String file) {
    return '$file staat klaar om te versturen';
  }

  @override
  String get packShareFailed =>
      'Het pakket kon niet op dit toestel worden geschreven';

  @override
  String get packReadFailed => 'Dat bestand kon niet worden geopend';

  @override
  String get packNotAPack =>
      'Dat bestand is geen Salala-pakket, of het is beschadigd';

  @override
  String get packFromTheFuture =>
      'Dat pakket komt van een nieuwere Salala dan deze';

  @override
  String packIncomplete(String table) {
    return 'In dat pakket ontbreekt een deel van het stamboek: $table';
  }

  @override
  String packUnknownTable(String table) {
    return 'Dat pakket bevat een tabel die deze Salala niet kent: $table';
  }

  @override
  String get packRestoreTitle => 'Alles op dit toestel vervangen?';

  @override
  String packRestoreBody(int animals, int rows, String day) {
    return 'Van $day. Dieren: $animals. Gegevens: $rows. Herstellen vervangt alles wat nu op dit toestel staat.';
  }

  @override
  String packRestored(int rows) {
    return 'Gegevens hersteld: $rows';
  }

  @override
  String get packRestoreFailed =>
      'Het pakket kon niet worden hersteld. Op dit toestel is niets veranderd.';

  @override
  String get litterAdd => 'Nieuw nestje';

  @override
  String get litterEditTitle => 'Nestje bewerken';

  @override
  String get litterAddPuppies => 'Puppy\'s toevoegen';

  @override
  String get litterHowMany => 'Hoeveel?';

  @override
  String get litterAddTitle => 'Een nestje registreren';

  @override
  String get litterEmptyTitle => 'Nog geen nestjes';

  @override
  String get litterEmptyBody =>
      'Leg een dekking vast om de dracht te volgen en de puppy\'s in één stap te registreren.';

  @override
  String get litterName => 'Naam van het nestje';

  @override
  String get litterNameRequired => 'Een naam voor het nestje is verplicht';

  @override
  String get litterDam => 'Moeder';

  @override
  String get litterDamRequired => 'Kies de moeder';

  @override
  String get litterDamMissing => 'Moeder verwijderd';

  @override
  String get litterSire => 'Vader';

  @override
  String get litterSireUnknown => 'Vader onbekend';

  @override
  String get litterNoDams => 'Markeer eerst een teef als fokdier';

  @override
  String get litterMatingDate => 'Datum van de dekking';

  @override
  String get litterWhelpingDate => 'Worpdatum';

  @override
  String get litterWeaningDate => 'Datum van spenen';

  @override
  String get litterWhelpingBeforeMating =>
      'De worpdatum ligt voor de dekkingsdatum.';

  @override
  String get litterWeaningBeforeWhelping =>
      'De speendatum ligt voor de worpdatum.';

  @override
  String litterExpected(String date) {
    return 'Verwachte worp: $date';
  }

  @override
  String litterPuppyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count puppy\'s',
      one: '1 puppy',
      zero: 'Geen puppy\'s geregistreerd',
    );
    return '$_temp0';
  }

  @override
  String get litterPuppiesToRegister => 'Geboren puppy\'s';

  @override
  String get litterPuppiesHint =>
      'Elke puppy komt bij uw dieren, genoemd naar het nestje';

  @override
  String get litterNoPuppies =>
      'Voor dit nestje zijn nog geen puppy\'s geregistreerd.';

  @override
  String get litterGone => 'Dit nestje is verwijderd.';

  @override
  String litterDeleteTitle(String name) {
    return '$name verwijderen?';
  }

  @override
  String get litterDeleteBody =>
      'De puppy\'s blijven bij uw dieren; alleen de dekking wordt verwijderd. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get animalGone => 'Dit dier is verwijderd.';

  @override
  String get animalDeathDate => 'Overleden op';

  @override
  String get animalDam => 'Moeder';

  @override
  String get animalSire => 'Vader';

  @override
  String get valueUnknown => 'Niet vastgelegd';

  @override
  String get recordDeleteTitle => 'Dit gegeven verwijderen?';

  @override
  String get recordSaveFailed =>
      'Dit kon niet worden opgeslagen. Er is niets geschreven.';

  @override
  String get recordDeleteFailed =>
      'Dit kon niet worden verwijderd. Het gegeven staat er nog.';

  @override
  String get recordDateBeforeBirth =>
      'Deze datum ligt voor de geboorte van dit dier.';

  @override
  String get vaccinationAdd => 'Inenting toevoegen';

  @override
  String get vaccinationAddTitle => 'Een inenting vastleggen';

  @override
  String get vaccinationEditTitle => 'Inenting bewerken';

  @override
  String get vaccinationName => 'Vaccin';

  @override
  String get vaccinationNameRequired => 'Een vaccinnaam is verplicht';

  @override
  String get vaccinationGiven => 'Toegediend op';

  @override
  String get vaccinationNextDue => 'Volgende dosis';

  @override
  String get vaccinationNextDueHint =>
      'Een dosis waarvan de datum verstreken is, wordt als te laat gemarkeerd.';

  @override
  String get doseDueBeforeAdministered =>
      'De volgende dosis zou vóór deze vallen.';

  @override
  String get vaccinationOverdue => 'Te laat';

  @override
  String get vaccinationManufacturer => 'Fabrikant';

  @override
  String get vaccinationBatch => 'Batchnummer';

  @override
  String get vaccinationVet => 'Dierenarts';

  @override
  String get vaccinationClinic => 'Praktijk';

  @override
  String get vaccinationCertificate => 'Certificaatnummer';

  @override
  String get vaccinationDeleteBody =>
      'De dosis verdwijnt uit de geschiedenis van dit dier. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get weightAdd => 'Gewicht toevoegen';

  @override
  String get weightKg => 'Gewicht (kg)';

  @override
  String get weightColumn => 'Gewicht';

  @override
  String get weightRequired => 'Voer het gewicht in';

  @override
  String get weightInvalid => 'Voer een gewicht in zoals 4,2';

  @override
  String get weightMeasuredOn => 'Gemeten op';

  @override
  String get unitKg => 'kg';

  @override
  String get unitGrams => 'g';

  @override
  String get weightNote => 'Notitie';

  @override
  String get weightDeleteBody =>
      'De weging wordt verwijderd. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get weightAppendOnlyHint =>
      'Weegingen worden nooit bewerkt. Verkeerd gemeten? Verwijder en weeg opnieuw.';

  @override
  String get animalSpeciesHelper => 'hond · kat';

  @override
  String get healthTestAdd => 'Test toevoegen';

  @override
  String get healthTestAddTitle => 'Een gezondheidstest vastleggen';

  @override
  String get healthTestEditTitle => 'Gezondheidstest bewerken';

  @override
  String get healthTestType => 'Screening';

  @override
  String get healthTestTypeRequired => 'Geef de screening een naam';

  @override
  String get healthTestResult => 'Uitslag';

  @override
  String get healthTestResultRequired => 'Voer de uitslag in';

  @override
  String get healthTestResultHelper => 'Clear · Carrier · Affected';

  @override
  String get healthTestDate => 'Getest op';

  @override
  String get healthTestValidUntil => 'Geldig tot';

  @override
  String get certificateExpiresBeforeTest =>
      'Dit certificaat verloopt vóór de dag van de test die het bevestigt.';

  @override
  String get healthTestBody => 'Instantie';

  @override
  String get healthTestVerifiedBy => 'Bevestigd door';

  @override
  String get healthTestExpired => 'Verlopen';

  @override
  String get healthTestDeleteBody =>
      'De screening verdwijnt uit de geschiedenis van dit dier. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get visitAdd => 'Bezoek toevoegen';

  @override
  String get visitAddTitle => 'Een dierenartsbezoek vastleggen';

  @override
  String get visitEditTitle => 'Dierenartsbezoek bewerken';

  @override
  String get visitDate => 'Datum van het bezoek';

  @override
  String get visitReason => 'Reden';

  @override
  String get visitNoReason => 'Consult';

  @override
  String get visitOutcome => 'Uitkomst';

  @override
  String get visitCost => 'Kosten';

  @override
  String get visitCostInvalid => 'Voer een bedrag in zoals 250';

  @override
  String get visitCurrency => 'Valuta';

  @override
  String get visitDeleteBody =>
      'Het bezoek verdwijnt uit de geschiedenis van dit dier. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get symptomAdd => 'Symptoom toevoegen';

  @override
  String get symptomAddTitle => 'Een symptoom vastleggen';

  @override
  String get symptomEditTitle => 'Symptoom bewerken';

  @override
  String get symptomName => 'Symptoom';

  @override
  String get symptomNameRequired => 'Schrijf op wat u zag';

  @override
  String get symptomSeverity => 'Ernst';

  @override
  String get severityMild => 'Licht';

  @override
  String get severityModerate => 'Matig';

  @override
  String get severitySevere => 'Ernstig';

  @override
  String get symptomObservedOn => 'Gezien op';

  @override
  String get symptomState => 'Status';

  @override
  String get symptomOngoing => 'Nog aanwezig';

  @override
  String get symptomResolved => 'Verdwenen';

  @override
  String get symptomDeleteBody =>
      'Het symptoom verdwijnt uit de geschiedenis van dit dier. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get photoAdd => 'Foto toevoegen';

  @override
  String get photoFromGallery => 'Uit de galerij kiezen';

  @override
  String get photoFromCamera => 'Een foto maken';

  @override
  String get photoDeleteBody =>
      'De foto verdwijnt uit het dossier van dit dier, en het bestand ermee. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get photoMissing => 'Niet op dit toestel';

  @override
  String get photoTooLarge => 'Deze foto is te groot om te bewaren';

  @override
  String get photoNotAnImage => 'Dit bestand is geen foto';

  @override
  String get placementAdd => 'Plaatsing toevoegen';

  @override
  String get placementAddTitle => 'Een plaatsing vastleggen';

  @override
  String get placementEditTitle => 'Plaatsing bewerken';

  @override
  String get placementBuyer => 'Koper';

  @override
  String get placementNoBuyer => 'Koper niet vastgelegd';

  @override
  String get placementDate => 'Geplaatst op';

  @override
  String get placementPrice => 'Prijs';

  @override
  String get placementPriceInvalid => 'Voer een bedrag in zoals 2500';

  @override
  String get placementCurrency => 'Valuta';

  @override
  String get placementGuarantee => 'Garantievoorwaarden';

  @override
  String get placementDeleteBody =>
      'De plaatsing verdwijnt uit de geschiedenis van dit dier. De koper blijft in uw contacten. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get buyerAdd => 'Nieuwe koper';

  @override
  String get buyerAddTitle => 'Een koper toevoegen';

  @override
  String get buyerEditTitle => 'Koper bewerken';

  @override
  String get buyerPhone => 'Telefoon';

  @override
  String get buyerEmail => 'E-mail';

  @override
  String get buyerCountryCode => 'Landcode';

  @override
  String get buyersEmptyTitle => 'Nog geen kopers';

  @override
  String get buyersEmptyBody =>
      'Een koper komt erbij met een plaatsing — of hier, vooraf: wie vorig jaar bij u kocht, wil nog steeds de stamboom.';

  @override
  String get buyersNoAnimals => 'Geen dier vastgelegd voor dit contact';

  @override
  String buyerDeleteBody(String name) {
    return '$name verdwijnt uit uw contacten. De plaatsing blijft in de geschiedenis van het dier, zonder genoemde koper. Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String reminderHeadsUpBody(String what, String dueDay) {
    return 'Herinnering: $what verloopt op $dueDay';
  }

  @override
  String reminderDueBody(String what) {
    return '$what verloopt vandaag';
  }

  @override
  String get pdfAction => 'PDF-dossier';

  @override
  String get pdfFailed => 'De PDF kon niet worden gemaakt';

  @override
  String get pdfTitle => 'Gezondheids- en afstammingsbewijs';

  @override
  String get pdfLitterTitle => 'Worpregister';

  @override
  String pdfGenerated(String day) {
    return 'Gemaakt op $day';
  }

  @override
  String get pdfPedigree => 'Stamboom';

  @override
  String get pdfLitters => 'Nestjes van dit dier';

  @override
  String get pdfPuppies => 'Puppy\'s';

  @override
  String get pdfPlacement => 'Plaatsing';

  @override
  String get pdfBuyer => 'Koper';

  @override
  String get pdfPhone => 'Telefoon';

  @override
  String get pdfEmail => 'E-mail';

  @override
  String get pdfPlacedOn => 'Geplaatst op';

  @override
  String get pdfPrice => 'Prijs';

  @override
  String get pdfGuarantee => 'Garantievoorwaarden';

  @override
  String get pdfChartAxes =>
      'Gewicht in kilogram tegen leeftijd in maanden. De tabel hierboven schrijft het gewicht van een jonge puppy in grammen.';

  @override
  String get pdfDisclaimer =>
      'Offline gemaakt door Salala uit de eigen gegevens van de fokker. Dit is geen diergeneeskundig certificaat.';

  @override
  String get triageTitle => 'Wat nu te doen';

  @override
  String get triageActNow => 'Nu handelen';

  @override
  String get triageWatch => 'Blijf opletten';

  @override
  String get triageRoutineVet => 'Gewoon dierenartsbezoek';

  @override
  String get triageNothing => 'Niets in dit dossier vraagt een volgende stap';

  @override
  String get triageNotDiagnosis =>
      'Salala leest alleen wat u hier hebt ingevoerd. Dit is geen diergeneeskundige diagnose.';

  @override
  String triageNoDoseYoung(String days) {
    return 'Geen inenting vastgelegd, op $days';
  }

  @override
  String triageDoseOverdue(String name, String days) {
    return '$name was $days geleden aan de beurt';
  }

  @override
  String triageDoseDueSoon(String name, String days) {
    return '$name is over $days aan de beurt';
  }

  @override
  String triageWeightLossPuppy(String percent) {
    return 'Een jong dier is sinds de laatste weging $percent% van zijn gewicht kwijt';
  }

  @override
  String triageWeightLoss(String percent) {
    return 'Het gewicht is sinds de laatste weging $percent% gedaald';
  }

  @override
  String triageNoGainPuppy(String days) {
    return 'Nauwelijks gewichtstoename in $days';
  }

  @override
  String triageTestFlagged(String name) {
    return '$name kwam niet schoon terug';
  }

  @override
  String triageTestExpired(String name, String days) {
    return 'Het certificaat $name is $days geleden verlopen';
  }

  @override
  String triageWhelpingOverdue(String name, String days) {
    return '$name: de worp is $days voorbij de verwachte datum';
  }

  @override
  String triageSevereSymptom(String name) {
    return '$name is als ernstig vastgelegd en nog aanwezig';
  }

  @override
  String triageSymptomUnresolved(String name, String days) {
    return '$name is $days geleden gezien en nog aanwezig';
  }

  @override
  String get agendaTitle => 'Inentingen in te plannen';

  @override
  String daysSingle(String n) {
    return '$n dag';
  }

  @override
  String daysDual(String n) {
    return '$n dagen';
  }

  @override
  String daysPlural(String n) {
    return '$n dagen';
  }
}

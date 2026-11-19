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
      'Een groep begint met één. Geef hem een naam, en zijn kaart begint hier.';

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
      'Ook haar inentingen, gezondheidstests, gewichten, bezoeken en symptomen worden verwijderd, samen met elke vastgelegde plaatsing, haar foto\'s en de bestanden die deze op dit toestel bewaren, en het aan die plaatsing gekoppelde contract. Dit kan niet ongedaan worden gemaakt.';

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
  String get detailStoryLine => 'Elke regel hier hoort bij zijn verhaal.';

  @override
  String get detailDiedLine => 'Zijn kaart blijft zoals hij was.';

  @override
  String placedFarewell(String name) {
    return '$name is naar een nieuw huis gegaan. De kaart blijft bij jou.';
  }

  @override
  String reminderHeadsUpBody(String what, String dueDay) {
    return 'Herinnering: $what verloopt op $dueDay';
  }

  @override
  String reminderDueBody(String what) {
    return '$what is vandaag aan de beurt. Twee minuten is genoeg';
  }

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
  String get settingsTrial => 'Gratis proefperiode';

  @override
  String settingsTrialRemaining(String days) {
    return 'Nog $days dagen';
  }

  @override
  String get settingsTrialOver => 'De proefperiode is voorbij';

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
  String packBadValue(String detail) {
    return 'Dat pakket bevat een waarde die deze Salala niet kan lezen: $detail';
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
  String get statsTitle => 'Het kennel in cijfers';

  @override
  String get settingsStats => 'Het kennel in cijfers';

  @override
  String get statsHerdGroup => 'Wie er zijn';

  @override
  String get statsBreedingGroup => 'Nesten en pups';

  @override
  String get statsMoneyGroup => 'Plaatsingen';

  @override
  String get statsAtHome => 'Dieren thuis';

  @override
  String get statsBreedingStock => 'Fokdieren';

  @override
  String get statsFemales => 'Teven thuis';

  @override
  String get statsMales => 'Reuen thuis';

  @override
  String get statsEverRecorded => 'Ooit vastgelegd';

  @override
  String get statsWhelpings => 'Nesten in de kaart';

  @override
  String get statsPuppies => 'Pups uit jouw nesten';

  @override
  String statsPuppiesThisYear(String year) {
    return 'Pups geboren in $year';
  }

  @override
  String get statsPlacements => 'Plaatsingen';

  @override
  String get statsUnnamedCurrency => 'Geen valuta opgegeven';

  @override
  String statsHandoverCount(String count) {
    return '$count daarvan betaald';
  }

  @override
  String get statsNoRevenue => 'Geen prijs vastgelegd';

  @override
  String get statsFooter =>
      'Geteld uit je eigen kaart, op dit toestel. Niets hiervan verlaat het.';

  @override
  String get birthdayTitle => 'Binnenkort';

  @override
  String get birthdayToday => 'vandaag';

  @override
  String birthdayIn(String days) {
    return 'over $days';
  }

  @override
  String birthdayTurning(String name, String years) {
    return '$name wordt $years';
  }

  @override
  String get heatCardTitle => 'Volgende loopsheid';

  @override
  String heatCardWindow(String earliest, String latest) {
    return 'Tussen $earliest en $latest';
  }

  @override
  String heatCardSteady(String count) {
    return 'Op basis van $count cycli in haar eigen kaart.';
  }

  @override
  String get heatCardThin =>
      'Er staat maar één cyclus in de kaart, dus het venster is breed. Leg nog een dekking vast en het wordt smaller.';

  @override
  String heatCardWhelping(String day) {
    return 'Een dekking in dit venster zou rond $day werpen.';
  }

  @override
  String get bulkVaccineTitle => 'Samen vaccineren';

  @override
  String bulkVaccineCount(String count) {
    return '$count dieren krijgen dezelfde dosis';
  }

  @override
  String get bulkVaccineAction => 'Het nest vaccineren';

  @override
  String bulkVaccineDone(String count) {
    return 'Vastgelegd voor $count dieren';
  }

  @override
  String get pedigreeTitle => 'Stamboom';

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
  String get contractAttach => 'Een contract toevoegen';

  @override
  String get contractAttached => 'Contract toegevoegd';

  @override
  String get contractStoredName => 'Een eerder toegevoegd document';

  @override
  String get contractRemove => 'Het contract verwijderen';

  @override
  String get contractOpen => 'Het contract openen';

  @override
  String get contractMissing => 'Dat document staat niet op dit toestel';

  @override
  String get contractOpenFailed => 'Het document kon niet worden geopend';

  @override
  String get contractPickFailed => 'Er kon geen document worden gekozen';

  @override
  String get contractTooLarge => 'Dat bestand is te groot om te bewaren';

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
  String triageDoseToday(String what) {
    return '$what verloopt vandaag';
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
  String get onboardingSlide1Title => 'Eén kaart per dier';

  @override
  String get onboardingSlide1Body =>
      'Een hond of kat, het ras, de geboortedatum en waar hij vandaan komt. De eerste kost minder dan een minuut.';

  @override
  String get onboardingSlide2Title => 'Zijn gezondheid, op volgorde';

  @override
  String get onboardingSlide2Body =>
      'Inentingen met de volgende datum, wegingen, onderzoeken en bezoeken. Salala zet de herinnering voor je klaar.';

  @override
  String get onboardingSlide3Title => 'Zijn verhaal reist mee';

  @override
  String get onboardingSlide3Body =>
      'Een pdf of een spreadsheet voor de koper, en één ZIP die elke kaart en elke foto naar een nieuwe telefoon brengt.';

  @override
  String get onboardingSkip => 'Overslaan';

  @override
  String get onboardingNext => 'Volgende';

  @override
  String get onboardingStart => 'Mijn eerste dier toevoegen';

  @override
  String get settingsOnboarding => 'Inleiding opnieuw tonen';

  @override
  String get settingsHelp => 'Help';

  @override
  String get settingsRate => 'Salala beoordelen';

  @override
  String get settingsRateBody => 'Opent de beoordelingskaart van de winkel.';

  @override
  String get settingsWhatsNew => 'Nieuw';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsTerms => 'Gebruiksvoorwaarden';

  @override
  String get settingsLicenses => 'Open-sourcelicenties';

  @override
  String get rateUnavailable =>
      'Deze telefoon kan de beoordelingskaart nu niet tonen.';

  @override
  String get aboutTitle => 'Over Salala';

  @override
  String get aboutBody =>
      'Een offline register voor een kleine fokkerij. Geen account, geen server, geen tracking — de kaarten staan op deze telefoon en verlaten hem alleen door jouw handen.';

  @override
  String aboutVersion(String version) {
    return 'Versie $version';
  }

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyIntro =>
      'Salala bewaart één ding: wat je over je dieren hebt ingevuld. Deze pagina zegt waar het staat en wat het van deze telefoon kan halen.';

  @override
  String get privacyStoredHeading => 'Wat er wordt bewaard';

  @override
  String get privacyStoredBody =>
      'Elk dier, elke inenting, weging, onderzoek, bezoek, elk symptoom, elke plaatsing en elk kopercontact — en de foto\'s die je toevoegde — in een database en een fotomap in de privéopslag van de app. Android houdt die map buiten bereik van andere apps, en de bestanden zijn daarbuiten niet versleuteld.';

  @override
  String get privacyBackupHeading => 'Wat deze telefoon verlaat';

  @override
  String get privacyBackupBody =>
      'Alleen wat je exporteert: een ZIP met elke kaart en foto, een CSV van één tabel, of een pdf van één dier. Elk bestand gaat waar je het heen stuurt, dus een back-up bevat namen en telefoonnummers van je kopers — behandel het bestand zoals het papier dat het vervangt. Zet de app-vergrendeling aan als de telefoon reist.';

  @override
  String get privacyCollectHeading => 'Wat er over jou wordt verzameld';

  @override
  String get privacyCollectBody =>
      'Niets. Geen analytics, geen crashrapporten, geen advertentie-id en geen enkele netwerkaanroep in deze app.';

  @override
  String get privacyRemoveHeading => 'Hoe je het wist';

  @override
  String get privacyRemoveBody =>
      'Verwijderen ruimt de database en de fotomap op. Er is nergens een kopie, dus exporteer eerst een pakket als de kaarten belangrijk zijn — en de pincode van de vergrendeling is ook niet te herstellen.';

  @override
  String get termsTitle => 'Gebruiksvoorwaarden';

  @override
  String get termsUseHeading => 'Waar deze app voor is';

  @override
  String get termsUseBody =>
      'Je eigen gegevens bijhouden over de dieren die je verzorgt. Eén licentie per persoon; installeer hem op de telefoons die je gebruikt.';

  @override
  String get termsDataHeading => 'Jouw gegevens zijn van jou';

  @override
  String get termsDataBody =>
      'Wij bewaren geen kopie en kunnen niets terugzetten. Back-ups zijn jouw verantwoordelijkheid, en de exportknop in Instellingen is het hele mechanisme.';

  @override
  String get termsAdviceHeading => 'Geen diergeneeskundig advies';

  @override
  String get termsAdviceBody =>
      'Salala herhaalt wat je hebt ingevuld en rekent met datums en gewichten. Het stelt geen diagnose, en een herinnering is een agenda-item, geen klinische mening. Bel een dierenarts.';

  @override
  String get termsWarrantyHeading => 'Geen garantie';

  @override
  String get termsWarrantyBody =>
      'De app wordt geleverd zoals hij is. Voor zover de wet dat toestaat, wordt geen aansprakelijkheid aanvaard voor een verloren kaart, een gemiste herinnering of een beslissing op basis van wat hier staat.';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpQ1 => 'Hoe maak ik een back-up?';

  @override
  String get helpA1 =>
      'Instellingen, dan Dossiers exporteren. De ZIP bevat elke rij en elke foto; stuur hem naar jezelf en bewaar hem. Herstellen leest hetzelfde bestand op elke telefoon.';

  @override
  String get helpQ2 => 'Ik ben mijn pincode kwijt';

  @override
  String get helpA2 =>
      'Die is niet te herstellen, want er wordt alleen een hash bewaard. Verwijderen wist de vergrendeling en daarmee het register, dus herstel daarna een recent pakket als je dat hebt.';

  @override
  String get helpQ3 => 'Ik ben mijn telefoon kwijt';

  @override
  String get helpA3 =>
      'Niets staat op een server, dus niets kan worden teruggestuurd. Een eerder geëxporteerd pakket zet het register terug op een nieuwe telefoon; een pakket dat je nooit exporteerde is weg.';

  @override
  String get helpQ4 => 'Waar komen de herinneringen vandaan?';

  @override
  String get helpA4 =>
      'Uit de volgende datums die je hebt ingevuld. Salala zet een alarm een maand vooruit en een op de ochtend zelf; staan meldingen uit, dan blijven de datums in de agenda van de groep.';

  @override
  String get helpQ5 =>
      'Waarom zegt een foto dat hij niet op deze telefoon staat?';

  @override
  String get helpA5 =>
      'De rij bleef, het bestand niet — meestal na een herstel uit een pakket zonder foto\'s. De foto opnieuw toevoegen lost het op.';

  @override
  String get helpQ6 => 'Kan ik de kaart van het dier overdragen?';

  @override
  String get helpA6 =>
      'Ja. Open het dier en exporteer zijn pdf: een vast document dat de koper bewaart zonder deze app. De plaatsing zelf wordt op dezelfde pagina vastgelegd.';

  @override
  String get helpQ7 => 'Welke talen zijn er?';

  @override
  String get helpA7 =>
      'Engels, Arabisch, Frans, Duits, Spaans, Italiaans, Portugees en Nederlands. Instellingen, dan Taal — de wijziging geldt meteen.';

  @override
  String get helpQ8 => 'Er is iets mis met de app';

  @override
  String get helpA8 =>
      'Schrijf ons en zeg wat je aan het doen was toen het gebeurde. De versie staat op de pagina Over.';

  @override
  String get helpContactHeading => 'Schrijf ons';

  @override
  String get whatsNewTitle => 'Nieuw';

  @override
  String get whatsNew1 =>
      'Foto\'s op de kaarten van de groep, en een warmer en ruimer ontwerp in het hele scherm.';

  @override
  String get whatsNew2 =>
      'Een aangetikte herinnering opent het dier waar hij over gaat.';

  @override
  String get whatsNew3 => 'De spreadsheet-export spreekt de taal die je leest.';

  @override
  String get whatsNew4 =>
      'Vijf talen erbij: Duits, Spaans, Italiaans, Portugees en Nederlands.';

  @override
  String get whatsNew5 =>
      'Pagina\'s voor privacy, voorwaarden en help, en een beoordelingsregel in Instellingen.';

  @override
  String get whatsNew6 =>
      'Eén lijst per dier: elke inenting, weging, bezoek en plaatsing op datum.';

  @override
  String get timelineTitle => 'Wat er gebeurde';

  @override
  String get timelineEmpty => 'Nog niets met een datum.';

  @override
  String timelineShowAll(String count) {
    return 'Alle $count tonen';
  }

  @override
  String get timelineShowLess => 'Minder tonen';

  @override
  String get timelineKindBorn => 'Geboorte';

  @override
  String get timelineKindDied => 'Overlijden';

  @override
  String get timelineKindWhelped => 'Nestje';

  @override
  String get timelineKindVaccination => 'Inenting';

  @override
  String get timelineKindHealthTest => 'Gezondheidstest';

  @override
  String get timelineKindVisit => 'Dierenartsbezoek';

  @override
  String get timelineKindSymptom => 'Symptoom';

  @override
  String get timelineKindWeight => 'Weging';

  @override
  String get timelineKindPhoto => 'Foto';

  @override
  String get timelineKindPlacement => 'Plaatsing';

  @override
  String daysPlural(String n) {
    return '$n dagen';
  }
}

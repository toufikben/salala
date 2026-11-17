// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Salala';

  @override
  String get navAnimals => 'Animali';

  @override
  String get navLitters => 'Cucciolate';

  @override
  String get navBuyers => 'Acquirenti';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get languageName => 'Italiano';

  @override
  String get homeEmptyTitle => 'Ancora nessun animale';

  @override
  String get homeEmptyBody =>
      'Aggiungi il tuo primo cane o gatto per iniziare una scheda sanitaria e genealogica.';

  @override
  String get homeAddAnimal => 'Aggiungi animale';

  @override
  String get homeBreedingStock => 'Riproduttori';

  @override
  String get homeAllAnimals => 'Tutti gli animali';

  @override
  String get homeSearchHint =>
      'Cerca per nome, numero, microchip, nota o acquirente';

  @override
  String homeNoMatches(String query) {
    return 'Nessun risultato per «$query»';
  }

  @override
  String homeAnimalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count animali',
      one: '1 animale',
      zero: 'Nessun animale',
    );
    return '$_temp0';
  }

  @override
  String get animalName => 'Nome';

  @override
  String get animalSpecies => 'Specie';

  @override
  String get animalBreed => 'Razza';

  @override
  String get animalSex => 'Sesso';

  @override
  String get animalBirthDate => 'Data di nascita';

  @override
  String animalBornOn(String day) {
    return 'Nato il $day';
  }

  @override
  String get animalStatus => 'Stato';

  @override
  String get animalMicrochip => 'Numero di microchip';

  @override
  String get animalMicrochipDate => 'Microchip applicato il';

  @override
  String get animalLitter => 'Cucciolata';

  @override
  String get animalNone => 'Nessuno';

  @override
  String get animalRegistrationNo => 'Numero di registro';

  @override
  String get animalRegistry => 'Registro';

  @override
  String get animalColor => 'Colore';

  @override
  String get animalNotes => 'Note';

  @override
  String get animalIsBreedingStock => 'Tenere come riproduttore';

  @override
  String get animalAddTitle => 'Aggiungi animale';

  @override
  String get animalEditTitle => 'Modifica animale';

  @override
  String animalDeleteTitle(String name) {
    return 'Eliminare $name?';
  }

  @override
  String animalDeleteLittersNote(int litters, int puppies) {
    return 'Verranno eliminate anche $litters delle sue cucciolate, e i $puppies cuccioli che hanno registrato restano nei tuoi animali ma senza la scheda della madre.';
  }

  @override
  String get animalDeleteBody =>
      'Vengono eliminati anche le sue vaccinazioni, i test sanitari, i pesi, le visite e i sintomi, insieme a ogni cessione registrata, alle sue fotografie e ai file che le conservano su questo telefono. L\'operazione è irreversibile.';

  @override
  String get animalNameRequired => 'Il nome è obbligatorio';

  @override
  String get animalSpeciesRequired => 'Scegli una specie';

  @override
  String get sexMale => 'Maschio';

  @override
  String get sexFemale => 'Femmina';

  @override
  String get sexUnknown => 'Sconosciuto';

  @override
  String get statusActive => 'Con me';

  @override
  String get statusSold => 'Ceduto';

  @override
  String get statusRetired => 'Riformato';

  @override
  String get statusDeceased => 'Deceduto';

  @override
  String get recordsVaccinations => 'Vaccinazioni';

  @override
  String get recordsHealthTests => 'Test sanitari';

  @override
  String get recordsWeights => 'Pesi';

  @override
  String get recordsVisits => 'Visite veterinarie';

  @override
  String get recordsSymptoms => 'Sintomi';

  @override
  String get recordsPhotos => 'Foto';

  @override
  String get recordsPlacements => 'Cessioni';

  @override
  String get recordsEmpty => 'Ancora nulla di registrato.';

  @override
  String get actionSave => 'Salva';

  @override
  String get actionCancel => 'Annulla';

  @override
  String get actionDelete => 'Elimina';

  @override
  String get actionEdit => 'Modifica';

  @override
  String get actionAdd => 'Aggiungi';

  @override
  String get actionClose => 'Chiudi';

  @override
  String get actionRetry => 'Riprova';

  @override
  String get actionClear => 'Cancella';

  @override
  String get actionReplace => 'Sostituisci';

  @override
  String get lockTitle => 'Salala è bloccato';

  @override
  String get lockEnterPin => 'Inserisci il PIN';

  @override
  String get lockUnlock => 'Sblocca';

  @override
  String get lockWrongPin => 'PIN errato';

  @override
  String get lockSetPinTitle => 'Crea un PIN';

  @override
  String get lockSetPinBody =>
      'Quattro cifre o più. Resta su questo dispositivo e non è recuperabile: scrivilo.';

  @override
  String get lockConfirmPin => 'Ripeti il PIN';

  @override
  String get lockPinTooShort => 'Quattro cifre o più';

  @override
  String get lockPinMismatch => 'I due PIN non coincidono';

  @override
  String get lockEnable => 'Blocca l\'app';

  @override
  String get lockDisable => 'Disattiva il blocco';

  @override
  String get lockCurrentPin => 'PIN attuale';

  @override
  String get lockChangeFailed =>
      'Il telefono non ha modificato il blocco dell\'app.';

  @override
  String get lockChangePinDone => 'PIN modificato.';

  @override
  String lockTooManyAttempts(int seconds) {
    return 'Troppi PIN errati. Riprova fra $seconds s.';
  }

  @override
  String get settingsAppLock => 'Blocco app';

  @override
  String get settingsChangePin => 'Cambia PIN';

  @override
  String get settingsChangePinBody =>
      'Inserisci il PIN attuale, poi scegline uno nuovo.';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsLanguageSystem => 'Lingua di sistema';

  @override
  String get languageNotStored => 'Il telefono non ha salvato questa lingua.';

  @override
  String get startupFailedTitle =>
      'Salala non è riuscita ad aprire il registro su questo telefono.';

  @override
  String get startupFailedBody =>
      'I tuoi dati sono ancora nel file. Chiudi l\'app e riaprila.';

  @override
  String get settingsAbout => 'Informazioni';

  @override
  String get settingsBuildTag => 'Versione';

  @override
  String get settingsOfflineNote =>
      'Tutto resta su questo dispositivo. Nessun account, nessun server, nessun tracciamento.';

  @override
  String get settingsExport => 'Esporta le schede';

  @override
  String get settingsExportBody =>
      'Un file ZIP con tutte le schede e le foto di questo telefono';

  @override
  String get settingsImport => 'Ripristina da un pacchetto';

  @override
  String get settingsImportBody => 'Rileggi un pacchetto su questo telefono';

  @override
  String settingsLastBackup(String day) {
    return 'Ultimo salvataggio: $day';
  }

  @override
  String get settingsNeverBackedUp =>
      'Nessun salvataggio ha ancora lasciato questo telefono';

  @override
  String get settingsCsv => 'Foglio di calcolo (CSV)';

  @override
  String get settingsCsvBody =>
      'Per il commercialista, un modulo di registro o un comproprietario. Si apre in Excel, Numbers o Fogli Google.';

  @override
  String get settingsCsvHerd => 'Animali';

  @override
  String get settingsCsvLitters => 'Cucciolate';

  @override
  String get settingsCsvVaccinations => 'Vaccinazioni';

  @override
  String get settingsCsvPlacements => 'Cessioni';

  @override
  String csvShared(String file) {
    return '$file è pronto da inviare';
  }

  @override
  String get csvShareFailed =>
      'Il foglio non è stato scritto su questo telefono';

  @override
  String get csvEmpty =>
      'Su questo telefono non c\'è ancora nulla da esportare';

  @override
  String get csvColAnimal => 'Animale';

  @override
  String get csvColCountry => 'Paese';

  @override
  String get csvColPuppies => 'Cuccioli';

  @override
  String get csvColBreedingStock => 'Riproduttore';

  @override
  String get csvColYes => 'sì';

  @override
  String get csvColNo => 'no';

  @override
  String packShared(String file) {
    return '$file è pronto da inviare';
  }

  @override
  String get packShareFailed =>
      'Il pacchetto non è stato scritto su questo telefono';

  @override
  String get packReadFailed => 'Non è stato possibile aprire quel file';

  @override
  String get packNotAPack =>
      'Quel file non è un pacchetto Salala, oppure è danneggiato';

  @override
  String get packFromTheFuture =>
      'Quel pacchetto viene da una Salala più recente di questa';

  @override
  String packIncomplete(String table) {
    return 'A quel pacchetto manca una parte del registro: $table';
  }

  @override
  String packUnknownTable(String table) {
    return 'Quel pacchetto contiene una tabella che questa Salala non conosce: $table';
  }

  @override
  String get packRestoreTitle =>
      'Sostituire tutto ciò che è su questo telefono?';

  @override
  String packRestoreBody(int animals, int rows, String day) {
    return 'Del $day. Animali: $animals. Schede: $rows. Il ripristino sostituisce tutto ciò che ora è su questo telefono.';
  }

  @override
  String packRestored(int rows) {
    return 'Schede ripristinate: $rows';
  }

  @override
  String get packRestoreFailed =>
      'Il pacchetto non è stato ripristinato. Su questo telefono non è cambiato nulla.';

  @override
  String get litterAdd => 'Nuova cucciolata';

  @override
  String get litterEditTitle => 'Modifica cucciolata';

  @override
  String get litterAddPuppies => 'Aggiungi cuccioli';

  @override
  String get litterHowMany => 'Quanti?';

  @override
  String get litterAddTitle => 'Registra una cucciolata';

  @override
  String get litterEmptyTitle => 'Ancora nessuna cucciolata';

  @override
  String get litterEmptyBody =>
      'Registra un accoppiamento per seguire la gravidanza e registrare i cuccioli in un solo passaggio.';

  @override
  String get litterName => 'Nome della cucciolata';

  @override
  String get litterNameRequired => 'Il nome della cucciolata è obbligatorio';

  @override
  String get litterDam => 'Madre';

  @override
  String get litterDamRequired => 'Scegli la madre';

  @override
  String get litterDamMissing => 'Madre eliminata';

  @override
  String get litterSire => 'Padre';

  @override
  String get litterSireUnknown => 'Padre sconosciuto';

  @override
  String get litterNoDams => 'Segna prima una femmina come riproduttrice';

  @override
  String get litterMatingDate => 'Data dell\'accoppiamento';

  @override
  String get litterWhelpingDate => 'Data del parto';

  @override
  String get litterWeaningDate => 'Data dello svezzamento';

  @override
  String get litterWhelpingBeforeMating =>
      'La data del parto precede quella dell\'accoppiamento.';

  @override
  String get litterWeaningBeforeWhelping =>
      'La data dello svezzamento precede quella del parto.';

  @override
  String litterExpected(String date) {
    return 'Parto previsto: $date';
  }

  @override
  String litterPuppyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cuccioli',
      one: '1 cucciolo',
      zero: 'Nessun cucciolo registrato',
    );
    return '$_temp0';
  }

  @override
  String get litterPuppiesToRegister => 'Cuccioli nati';

  @override
  String get litterPuppiesHint =>
      'Ogni cucciolo viene aggiunto ai tuoi animali, con il nome della cucciolata';

  @override
  String get litterNoPuppies =>
      'Nessun cucciolo registrato per questa cucciolata.';

  @override
  String get litterGone => 'Questa cucciolata è stata eliminata.';

  @override
  String litterDeleteTitle(String name) {
    return 'Eliminare $name?';
  }

  @override
  String get litterDeleteBody =>
      'I cuccioli restano nei tuoi animali; viene rimossa solo la registrazione dell\'accoppiamento. L\'operazione è irreversibile.';

  @override
  String get animalGone => 'Questo animale è stato eliminato.';

  @override
  String get animalDeathDate => 'Morto il';

  @override
  String get animalDam => 'Madre';

  @override
  String get animalSire => 'Padre';

  @override
  String get valueUnknown => 'Non registrato';

  @override
  String get recordDeleteTitle => 'Eliminare questa scheda?';

  @override
  String get recordSaveFailed =>
      'Non è stato possibile salvare. Non è stato scritto nulla.';

  @override
  String get recordDeleteFailed =>
      'Non è stato possibile eliminare. La scheda è ancora lì.';

  @override
  String get recordDateBeforeBirth =>
      'Questa data precede la nascita di questo animale.';

  @override
  String get vaccinationAdd => 'Aggiungi vaccinazione';

  @override
  String get vaccinationAddTitle => 'Registra una vaccinazione';

  @override
  String get vaccinationEditTitle => 'Modifica vaccinazione';

  @override
  String get vaccinationName => 'Vaccino';

  @override
  String get vaccinationNameRequired => 'Il nome del vaccino è obbligatorio';

  @override
  String get vaccinationGiven => 'Somministrato il';

  @override
  String get vaccinationNextDue => 'Prossima dose';

  @override
  String get vaccinationNextDueHint =>
      'Una dose la cui data è passata viene segnata come in ritardo.';

  @override
  String get doseDueBeforeAdministered =>
      'La prossima dose sarebbe dovuta prima di questa.';

  @override
  String get vaccinationOverdue => 'In ritardo';

  @override
  String get vaccinationManufacturer => 'Produttore';

  @override
  String get vaccinationBatch => 'Numero di lotto';

  @override
  String get vaccinationVet => 'Veterinario';

  @override
  String get vaccinationClinic => 'Ambulatorio';

  @override
  String get vaccinationCertificate => 'Numero del certificato';

  @override
  String get vaccinationDeleteBody =>
      'La dose viene rimossa dalla storia di questo animale. L\'operazione è irreversibile.';

  @override
  String get weightAdd => 'Aggiungi peso';

  @override
  String get weightKg => 'Peso (kg)';

  @override
  String get weightColumn => 'Peso';

  @override
  String get weightRequired => 'Inserisci il peso';

  @override
  String get weightInvalid => 'Inserisci un peso come 4,2';

  @override
  String get weightMeasuredOn => 'Misurato il';

  @override
  String get unitKg => 'kg';

  @override
  String get unitGrams => 'g';

  @override
  String get weightNote => 'Nota';

  @override
  String get weightDeleteBody =>
      'La pesata viene rimossa. L\'operazione è irreversibile.';

  @override
  String get weightAppendOnlyHint =>
      'Le pesate non si modificano mai. Misura sbagliata? Eliminala e pesa di nuovo.';

  @override
  String get animalSpeciesHelper => 'cane · gatto';

  @override
  String get healthTestAdd => 'Aggiungi test';

  @override
  String get healthTestAddTitle => 'Registra un test sanitario';

  @override
  String get healthTestEditTitle => 'Modifica test sanitario';

  @override
  String get healthTestType => 'Screening';

  @override
  String get healthTestTypeRequired => 'Dai un nome allo screening';

  @override
  String get healthTestResult => 'Esito';

  @override
  String get healthTestResultRequired => 'Inserisci l\'esito';

  @override
  String get healthTestResultHelper => 'Clear · Carrier · Affected';

  @override
  String get healthTestDate => 'Testato il';

  @override
  String get healthTestValidUntil => 'Valido fino al';

  @override
  String get certificateExpiresBeforeTest =>
      'Questo certificato scade prima del giorno del test che certifica.';

  @override
  String get healthTestBody => 'Ente';

  @override
  String get healthTestVerifiedBy => 'Verificato da';

  @override
  String get healthTestExpired => 'Scaduto';

  @override
  String get healthTestDeleteBody =>
      'Lo screening viene rimosso dalla storia di questo animale. L\'operazione è irreversibile.';

  @override
  String get visitAdd => 'Aggiungi visita';

  @override
  String get visitAddTitle => 'Registra una visita veterinaria';

  @override
  String get visitEditTitle => 'Modifica visita veterinaria';

  @override
  String get visitDate => 'Data della visita';

  @override
  String get visitReason => 'Motivo';

  @override
  String get visitNoReason => 'Consulto';

  @override
  String get visitOutcome => 'Esito';

  @override
  String get visitCost => 'Costo';

  @override
  String get visitCostInvalid => 'Inserisci un importo come 250';

  @override
  String get visitCurrency => 'Valuta';

  @override
  String get visitDeleteBody =>
      'La visita viene rimossa dalla storia di questo animale. L\'operazione è irreversibile.';

  @override
  String get symptomAdd => 'Aggiungi sintomo';

  @override
  String get symptomAddTitle => 'Registra un sintomo';

  @override
  String get symptomEditTitle => 'Modifica sintomo';

  @override
  String get symptomName => 'Sintomo';

  @override
  String get symptomNameRequired => 'Scrivi ciò che hai visto';

  @override
  String get symptomSeverity => 'Gravità';

  @override
  String get severityMild => 'Lieve';

  @override
  String get severityModerate => 'Moderata';

  @override
  String get severitySevere => 'Grave';

  @override
  String get symptomObservedOn => 'Osservato il';

  @override
  String get symptomState => 'Stato';

  @override
  String get symptomOngoing => 'Ancora in corso';

  @override
  String get symptomResolved => 'Risolto';

  @override
  String get symptomDeleteBody =>
      'Il sintomo viene rimosso dalla storia di questo animale. L\'operazione è irreversibile.';

  @override
  String get photoAdd => 'Aggiungi foto';

  @override
  String get photoFromGallery => 'Scegli dalla galleria';

  @override
  String get photoFromCamera => 'Scatta una foto';

  @override
  String get photoDeleteBody =>
      'La foto viene rimossa dal registro di questo animale, e il file con essa. L\'operazione è irreversibile.';

  @override
  String get photoMissing => 'Non presente su questo telefono';

  @override
  String get photoTooLarge => 'Questa foto è troppo grande da conservare';

  @override
  String get photoNotAnImage => 'Questo file non è una foto';

  @override
  String get placementAdd => 'Aggiungi cessione';

  @override
  String get placementAddTitle => 'Registra una cessione';

  @override
  String get placementEditTitle => 'Modifica cessione';

  @override
  String get placementBuyer => 'Acquirente';

  @override
  String get placementNoBuyer => 'Acquirente non registrato';

  @override
  String get placementDate => 'Ceduto il';

  @override
  String get placementPrice => 'Prezzo';

  @override
  String get placementPriceInvalid => 'Inserisci un importo come 2500';

  @override
  String get placementCurrency => 'Valuta';

  @override
  String get placementGuarantee => 'Condizioni di garanzia';

  @override
  String get placementDeleteBody =>
      'La cessione viene rimossa dalla storia di questo animale. L\'acquirente resta nei tuoi contatti. L\'operazione è irreversibile.';

  @override
  String get buyerAdd => 'Nuovo acquirente';

  @override
  String get buyerAddTitle => 'Aggiungi un acquirente';

  @override
  String get buyerEditTitle => 'Modifica acquirente';

  @override
  String get buyerPhone => 'Telefono';

  @override
  String get buyerEmail => 'E-mail';

  @override
  String get buyerCountryCode => 'Prefisso internazionale';

  @override
  String get buyersEmptyTitle => 'Ancora nessun acquirente';

  @override
  String get buyersEmptyBody =>
      'Un acquirente si aggiunge con una cessione, oppure qui, prima: chi ha comprato da te l\'anno scorso vuole ancora il pedigree.';

  @override
  String get buyersNoAnimals => 'Nessun animale registrato per questo contatto';

  @override
  String buyerDeleteBody(String name) {
    return '$name viene rimosso dai tuoi contatti. La cessione resta nella storia dell\'animale, senza acquirente indicato. L\'operazione è irreversibile.';
  }

  @override
  String reminderHeadsUpBody(String what, String dueDay) {
    return 'Promemoria: $what scade il $dueDay';
  }

  @override
  String reminderDueBody(String what) {
    return '$what scade oggi';
  }

  @override
  String get pdfAction => 'Dossier PDF';

  @override
  String get pdfFailed => 'Non è stato possibile creare il PDF';

  @override
  String get pdfTitle => 'Scheda sanitaria e genealogica';

  @override
  String get pdfLitterTitle => 'Registro di cucciolata';

  @override
  String pdfGenerated(String day) {
    return 'Generato il $day';
  }

  @override
  String get pdfPedigree => 'Pedigree';

  @override
  String get pdfLitters => 'Cucciolate di questo animale';

  @override
  String get pdfPuppies => 'Cuccioli';

  @override
  String get pdfPlacement => 'Cessione';

  @override
  String get pdfBuyer => 'Acquirente';

  @override
  String get pdfPhone => 'Telefono';

  @override
  String get pdfEmail => 'E-mail';

  @override
  String get pdfPlacedOn => 'Ceduto il';

  @override
  String get pdfPrice => 'Prezzo';

  @override
  String get pdfGuarantee => 'Condizioni di garanzia';

  @override
  String get pdfChartAxes =>
      'Peso in chilogrammi rispetto all\'età in mesi. La tabella qui sopra scrive il peso di un cucciolo piccolo in grammi.';

  @override
  String get pdfDisclaimer =>
      'Prodotto offline da Salala a partire dai registri dell\'allevatore. Non è un certificato veterinario.';

  @override
  String get triageTitle => 'Cosa fare adesso';

  @override
  String get triageActNow => 'Agisci subito';

  @override
  String get triageWatch => 'Continua a osservare';

  @override
  String get triageRoutineVet => 'Visita veterinaria di routine';

  @override
  String get triageNothing =>
      'In questa scheda non c\'è nulla che richieda un passo successivo';

  @override
  String get triageNotDiagnosis =>
      'Salala legge solo ciò che hai scritto qui. Non è una diagnosi veterinaria.';

  @override
  String triageNoDoseYoung(String days) {
    return 'Nessuna vaccinazione registrata, a $days';
  }

  @override
  String triageDoseOverdue(String name, String days) {
    return '$name era dovuto $days fa';
  }

  @override
  String triageDoseDueSoon(String name, String days) {
    return '$name è dovuto fra $days';
  }

  @override
  String triageWeightLossPuppy(String percent) {
    return 'Un animale giovane ha perso il $percent% del peso dall\'ultima pesata';
  }

  @override
  String triageWeightLoss(String percent) {
    return 'Il peso è calato del $percent% dall\'ultima pesata';
  }

  @override
  String triageNoGainPuppy(String days) {
    return 'Quasi nessun aumento di peso in $days';
  }

  @override
  String triageTestFlagged(String name) {
    return '$name non è tornato negativo';
  }

  @override
  String triageTestExpired(String name, String days) {
    return 'Il certificato $name è scaduto $days fa';
  }

  @override
  String triageWhelpingOverdue(String name, String days) {
    return '$name: il parto è $days oltre la data prevista';
  }

  @override
  String triageSevereSymptom(String name) {
    return '$name è stato registrato come grave ed è ancora in corso';
  }

  @override
  String triageSymptomUnresolved(String name, String days) {
    return '$name è stato osservato $days fa ed è ancora in corso';
  }

  @override
  String get agendaTitle => 'Vaccinazioni da prenotare';

  @override
  String daysSingle(String n) {
    return '$n giorno';
  }

  @override
  String daysDual(String n) {
    return '$n giorni';
  }

  @override
  String daysPlural(String n) {
    return '$n giorni';
  }
}

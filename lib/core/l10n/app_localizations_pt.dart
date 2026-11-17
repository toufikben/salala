// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Salala';

  @override
  String get navAnimals => 'Animais';

  @override
  String get navLitters => 'Ninhadas';

  @override
  String get navBuyers => 'Compradores';

  @override
  String get navSettings => 'Definições';

  @override
  String get languageName => 'Português';

  @override
  String get homeEmptyTitle => 'Ainda sem animais';

  @override
  String get homeEmptyBody =>
      'Adicione o seu primeiro cão ou gato para começar um registo de saúde e linhagem.';

  @override
  String get homeAddAnimal => 'Adicionar animal';

  @override
  String get homeBreedingStock => 'Reprodutores';

  @override
  String get homeAllAnimals => 'Todos os animais';

  @override
  String get homeSearchHint =>
      'Pesquisar por nome, número, chip, nota ou comprador';

  @override
  String homeNoMatches(String query) {
    return 'Nada corresponde a «$query»';
  }

  @override
  String homeAnimalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count animais',
      one: '1 animal',
      zero: 'Sem animais',
    );
    return '$_temp0';
  }

  @override
  String get animalName => 'Nome';

  @override
  String get animalSpecies => 'Espécie';

  @override
  String get animalBreed => 'Raça';

  @override
  String get animalSex => 'Sexo';

  @override
  String get animalBirthDate => 'Data de nascimento';

  @override
  String animalBornOn(String day) {
    return 'Nascido a $day';
  }

  @override
  String get animalStatus => 'Estado';

  @override
  String get animalMicrochip => 'Número de microchip';

  @override
  String get animalMicrochipDate => 'Microchip colocado a';

  @override
  String get animalLitter => 'Ninhada';

  @override
  String get animalNone => 'Nenhum';

  @override
  String get animalRegistrationNo => 'Número de registo';

  @override
  String get animalRegistry => 'Registo';

  @override
  String get animalColor => 'Cor';

  @override
  String get animalNotes => 'Notas';

  @override
  String get animalIsBreedingStock => 'Manter como reprodutor';

  @override
  String get animalAddTitle => 'Adicionar animal';

  @override
  String get animalEditTitle => 'Editar animal';

  @override
  String animalDeleteTitle(String name) {
    return 'Eliminar $name?';
  }

  @override
  String animalDeleteLittersNote(int litters, int puppies) {
    return 'Isto elimina também $litters das suas ninhadas, e os $puppies cachorros que registaram ficam nos seus animais mas sem o registo da mãe.';
  }

  @override
  String get animalDeleteBody =>
      'As suas vacinas, testes de saúde, pesos, visitas e sintomas são também eliminados, com qualquer entrega registada, as suas fotografias e os ficheiros que as guardam neste telefone. Isto não pode ser anulado.';

  @override
  String get animalNameRequired => 'O nome é obrigatório';

  @override
  String get animalSpeciesRequired => 'Escolha uma espécie';

  @override
  String get sexMale => 'Macho';

  @override
  String get sexFemale => 'Fêmea';

  @override
  String get sexUnknown => 'Desconhecido';

  @override
  String get statusActive => 'Comigo';

  @override
  String get statusSold => 'Entregue';

  @override
  String get statusRetired => 'Retirado';

  @override
  String get statusDeceased => 'Falecido';

  @override
  String get recordsVaccinations => 'Vacinas';

  @override
  String get recordsHealthTests => 'Testes de saúde';

  @override
  String get recordsWeights => 'Pesos';

  @override
  String get recordsVisits => 'Visitas ao veterinário';

  @override
  String get recordsSymptoms => 'Sintomas';

  @override
  String get recordsPhotos => 'Fotos';

  @override
  String get recordsPlacements => 'Entregas';

  @override
  String get recordsEmpty => 'Ainda nada registado.';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionAdd => 'Adicionar';

  @override
  String get actionClose => 'Fechar';

  @override
  String get actionRetry => 'Tentar de novo';

  @override
  String get actionClear => 'Limpar';

  @override
  String get actionReplace => 'Substituir';

  @override
  String get lockTitle => 'O Salala está bloqueado';

  @override
  String get lockEnterPin => 'Introduza o seu PIN';

  @override
  String get lockUnlock => 'Desbloquear';

  @override
  String get lockWrongPin => 'PIN errado';

  @override
  String get lockSetPinTitle => 'Criar um PIN';

  @override
  String get lockSetPinBody =>
      'Quatro dígitos ou mais. Fica neste dispositivo e não pode ser recuperado, por isso escreva-o.';

  @override
  String get lockConfirmPin => 'Repita o PIN';

  @override
  String get lockPinTooShort => 'Quatro dígitos ou mais';

  @override
  String get lockPinMismatch => 'Os dois PIN não coincidem';

  @override
  String get lockEnable => 'Bloquear a aplicação';

  @override
  String get lockDisable => 'Desligar o bloqueio';

  @override
  String get lockCurrentPin => 'PIN atual';

  @override
  String get lockChangeFailed =>
      'O telefone não alterou o bloqueio da aplicação.';

  @override
  String get lockChangePinDone => 'PIN alterado.';

  @override
  String lockTooManyAttempts(int seconds) {
    return 'Demasiados PIN errados. Tente de novo em $seconds s.';
  }

  @override
  String get settingsAppLock => 'Bloqueio da aplicação';

  @override
  String get settingsChangePin => 'Alterar o PIN';

  @override
  String get settingsChangePinBody =>
      'Introduza o PIN atual e escolha um novo.';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Idioma do sistema';

  @override
  String get languageNotStored => 'O telefone não guardou este idioma.';

  @override
  String get startupFailedTitle =>
      'O Salala não conseguiu abrir o livro de criação neste telefone.';

  @override
  String get startupFailedBody =>
      'Os seus registos continuam no ficheiro. Feche a aplicação e abra-a de novo.';

  @override
  String get settingsAbout => 'Acerca';

  @override
  String get settingsBuildTag => 'Versão';

  @override
  String get settingsOfflineNote =>
      'Tudo fica neste dispositivo. Sem conta, sem servidor, sem rastreio.';

  @override
  String get settingsExport => 'Exportar registos';

  @override
  String get settingsExportBody =>
      'Um ficheiro ZIP com todos os registos e fotografias deste telefone';

  @override
  String get settingsImport => 'Restaurar de um pacote';

  @override
  String get settingsImportBody => 'Voltar a ler um pacote neste telefone';

  @override
  String settingsLastBackup(String day) {
    return 'Última cópia: $day';
  }

  @override
  String get settingsNeverBackedUp => 'Nenhuma cópia saiu ainda deste telefone';

  @override
  String get settingsCsv => 'Folha de cálculo (CSV)';

  @override
  String get settingsCsvBody =>
      'Para o seu contabilista, um formulário de registo ou um coproprietário. Abre no Excel, Numbers ou Google Sheets.';

  @override
  String get settingsCsvHerd => 'Animais';

  @override
  String get settingsCsvLitters => 'Ninhadas';

  @override
  String get settingsCsvVaccinations => 'Vacinas';

  @override
  String get settingsCsvPlacements => 'Entregas';

  @override
  String csvShared(String file) {
    return '$file está pronto a enviar';
  }

  @override
  String get csvShareFailed => 'A folha não pôde ser escrita neste telefone';

  @override
  String get csvEmpty => 'Ainda não há nada para exportar neste telefone';

  @override
  String get csvColAnimal => 'Animal';

  @override
  String get csvColCountry => 'País';

  @override
  String get csvColPuppies => 'Cachorros';

  @override
  String get csvColBreedingStock => 'Reprodutor';

  @override
  String get csvColYes => 'sim';

  @override
  String get csvColNo => 'não';

  @override
  String packShared(String file) {
    return '$file está pronto a enviar';
  }

  @override
  String get packShareFailed => 'O pacote não pôde ser escrito neste telefone';

  @override
  String get packReadFailed => 'Não foi possível abrir esse ficheiro';

  @override
  String get packNotAPack =>
      'Esse ficheiro não é um pacote Salala, ou está danificado';

  @override
  String get packFromTheFuture =>
      'Esse pacote vem de um Salala mais recente do que este';

  @override
  String packIncomplete(String table) {
    return 'Falta parte do livro nesse pacote: $table';
  }

  @override
  String packUnknownTable(String table) {
    return 'Esse pacote contém uma tabela que este Salala não conhece: $table';
  }

  @override
  String get packRestoreTitle => 'Substituir tudo o que está neste telefone?';

  @override
  String packRestoreBody(int animals, int rows, String day) {
    return 'De $day. Animais: $animals. Registos: $rows. A restauração substitui tudo o que está agora neste telefone.';
  }

  @override
  String packRestored(int rows) {
    return 'Registos restaurados: $rows';
  }

  @override
  String get packRestoreFailed =>
      'O pacote não pôde ser restaurado. Nada mudou neste telefone.';

  @override
  String get litterAdd => 'Nova ninhada';

  @override
  String get litterEditTitle => 'Editar ninhada';

  @override
  String get litterAddPuppies => 'Adicionar cachorros';

  @override
  String get litterHowMany => 'Quantos?';

  @override
  String get litterAddTitle => 'Registar uma ninhada';

  @override
  String get litterEmptyTitle => 'Ainda sem ninhadas';

  @override
  String get litterEmptyBody =>
      'Registe um acasalamento para acompanhar a gestação e registar os cachorros num só passo.';

  @override
  String get litterName => 'Nome da ninhada';

  @override
  String get litterNameRequired => 'O nome da ninhada é obrigatório';

  @override
  String get litterDam => 'Mãe';

  @override
  String get litterDamRequired => 'Escolha a mãe';

  @override
  String get litterDamMissing => 'Mãe eliminada';

  @override
  String get litterSire => 'Pai';

  @override
  String get litterSireUnknown => 'Pai desconhecido';

  @override
  String get litterNoDams => 'Marque primeiro uma fêmea como reprodutora';

  @override
  String get litterMatingDate => 'Data do acasalamento';

  @override
  String get litterWhelpingDate => 'Data do parto';

  @override
  String get litterWeaningDate => 'Data do desmame';

  @override
  String get litterWhelpingBeforeMating =>
      'A data do parto é anterior à do acasalamento.';

  @override
  String get litterWeaningBeforeWhelping =>
      'A data do desmame é anterior à do parto.';

  @override
  String litterExpected(String date) {
    return 'Parto previsto: $date';
  }

  @override
  String litterPuppyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cachorros',
      one: '1 cachorro',
      zero: 'Nenhum cachorro registado',
    );
    return '$_temp0';
  }

  @override
  String get litterPuppiesToRegister => 'Cachorros nascidos';

  @override
  String get litterPuppiesHint =>
      'Cada cachorro é adicionado aos seus animais, com o nome da ninhada';

  @override
  String get litterNoPuppies =>
      'Ainda não há cachorros registados para esta ninhada.';

  @override
  String get litterGone => 'Esta ninhada foi eliminada.';

  @override
  String litterDeleteTitle(String name) {
    return 'Eliminar $name?';
  }

  @override
  String get litterDeleteBody =>
      'Os cachorros ficam nos seus animais; só o registo do acasalamento é removido. Isto não pode ser anulado.';

  @override
  String get animalGone => 'Este animal foi eliminado.';

  @override
  String get animalDeathDate => 'Morreu a';

  @override
  String get animalDam => 'Mãe';

  @override
  String get animalSire => 'Pai';

  @override
  String get valueUnknown => 'Não registado';

  @override
  String get recordDeleteTitle => 'Eliminar este registo?';

  @override
  String get recordSaveFailed =>
      'Isto não pôde ser guardado. Nada foi escrito.';

  @override
  String get recordDeleteFailed =>
      'Isto não pôde ser eliminado. O registo continua lá.';

  @override
  String get recordDateBeforeBirth =>
      'Esta data é anterior ao nascimento deste animal.';

  @override
  String get vaccinationAdd => 'Adicionar vacina';

  @override
  String get vaccinationAddTitle => 'Registar uma vacina';

  @override
  String get vaccinationEditTitle => 'Editar vacina';

  @override
  String get vaccinationName => 'Vacina';

  @override
  String get vaccinationNameRequired => 'O nome da vacina é obrigatório';

  @override
  String get vaccinationGiven => 'Administrada a';

  @override
  String get vaccinationNextDue => 'Próxima dose';

  @override
  String get vaccinationNextDueHint =>
      'Uma dose cuja data já passou é marcada como atrasada.';

  @override
  String get doseDueBeforeAdministered =>
      'A próxima dose seria devida antes desta.';

  @override
  String get vaccinationOverdue => 'Atrasada';

  @override
  String get vaccinationManufacturer => 'Fabricante';

  @override
  String get vaccinationBatch => 'Número de lote';

  @override
  String get vaccinationVet => 'Veterinário';

  @override
  String get vaccinationClinic => 'Clínica';

  @override
  String get vaccinationCertificate => 'Número do certificado';

  @override
  String get vaccinationDeleteBody =>
      'A dose é removida do histórico deste animal. Isto não pode ser anulado.';

  @override
  String get weightAdd => 'Adicionar peso';

  @override
  String get weightKg => 'Peso (kg)';

  @override
  String get weightColumn => 'Peso';

  @override
  String get weightRequired => 'Introduza o peso';

  @override
  String get weightInvalid => 'Introduza um peso como 4,2';

  @override
  String get weightMeasuredOn => 'Medido a';

  @override
  String get unitKg => 'kg';

  @override
  String get unitGrams => 'g';

  @override
  String get weightNote => 'Nota';

  @override
  String get weightDeleteBody =>
      'A pesagem é removida. Isto não pode ser anulado.';

  @override
  String get weightAppendOnlyHint =>
      'As pesagens nunca são editadas. Mediu mal? Elimine e pese de novo.';

  @override
  String get animalSpeciesHelper => 'cão · gato';

  @override
  String get healthTestAdd => 'Adicionar teste';

  @override
  String get healthTestAddTitle => 'Registar um teste de saúde';

  @override
  String get healthTestEditTitle => 'Editar teste de saúde';

  @override
  String get healthTestType => 'Rastreio';

  @override
  String get healthTestTypeRequired => 'Dê um nome ao rastreio';

  @override
  String get healthTestResult => 'Resultado';

  @override
  String get healthTestResultRequired => 'Introduza o resultado';

  @override
  String get healthTestResultHelper => 'Clear · Carrier · Affected';

  @override
  String get healthTestDate => 'Testado a';

  @override
  String get healthTestValidUntil => 'Válido até';

  @override
  String get certificateExpiresBeforeTest =>
      'Este certificado expira antes do dia do teste que certifica.';

  @override
  String get healthTestBody => 'Organismo';

  @override
  String get healthTestVerifiedBy => 'Verificado por';

  @override
  String get healthTestExpired => 'Expirado';

  @override
  String get healthTestDeleteBody =>
      'O rastreio é removido do histórico deste animal. Isto não pode ser anulado.';

  @override
  String get visitAdd => 'Adicionar visita';

  @override
  String get visitAddTitle => 'Registar uma visita ao veterinário';

  @override
  String get visitEditTitle => 'Editar visita ao veterinário';

  @override
  String get visitDate => 'Data da visita';

  @override
  String get visitReason => 'Motivo';

  @override
  String get visitNoReason => 'Consulta';

  @override
  String get visitOutcome => 'Resultado';

  @override
  String get visitCost => 'Custo';

  @override
  String get visitCostInvalid => 'Introduza um valor como 250';

  @override
  String get visitCurrency => 'Moeda';

  @override
  String get visitDeleteBody =>
      'A visita é removida do histórico deste animal. Isto não pode ser anulado.';

  @override
  String get symptomAdd => 'Adicionar sintoma';

  @override
  String get symptomAddTitle => 'Registar um sintoma';

  @override
  String get symptomEditTitle => 'Editar sintoma';

  @override
  String get symptomName => 'Sintoma';

  @override
  String get symptomNameRequired => 'Escreva o que viu';

  @override
  String get symptomSeverity => 'Gravidade';

  @override
  String get severityMild => 'Ligeiro';

  @override
  String get severityModerate => 'Moderado';

  @override
  String get severitySevere => 'Grave';

  @override
  String get symptomObservedOn => 'Visto a';

  @override
  String get symptomState => 'Estado';

  @override
  String get symptomOngoing => 'Continua';

  @override
  String get symptomResolved => 'Resolvido';

  @override
  String get symptomDeleteBody =>
      'O sintoma é removido do histórico deste animal. Isto não pode ser anulado.';

  @override
  String get photoAdd => 'Adicionar foto';

  @override
  String get photoFromGallery => 'Escolher da galeria';

  @override
  String get photoFromCamera => 'Tirar uma foto';

  @override
  String get photoDeleteBody =>
      'A fotografia é removida do livro deste animal, e o ficheiro com ela. Isto não pode ser anulado.';

  @override
  String get photoMissing => 'Não está neste telefone';

  @override
  String get photoTooLarge => 'Esta fotografia é demasiado grande para guardar';

  @override
  String get photoNotAnImage => 'Este ficheiro não é uma fotografia';

  @override
  String get placementAdd => 'Adicionar entrega';

  @override
  String get placementAddTitle => 'Registar uma entrega';

  @override
  String get placementEditTitle => 'Editar entrega';

  @override
  String get placementBuyer => 'Comprador';

  @override
  String get placementNoBuyer => 'Comprador não registado';

  @override
  String get placementDate => 'Entregue a';

  @override
  String get placementPrice => 'Preço';

  @override
  String get placementPriceInvalid => 'Introduza um valor como 2500';

  @override
  String get placementCurrency => 'Moeda';

  @override
  String get placementGuarantee => 'Condições de garantia';

  @override
  String get placementDeleteBody =>
      'A entrega é removida do histórico deste animal. O comprador fica nos seus contactos. Isto não pode ser anulado.';

  @override
  String get buyerAdd => 'Novo comprador';

  @override
  String get buyerAddTitle => 'Adicionar um comprador';

  @override
  String get buyerEditTitle => 'Editar comprador';

  @override
  String get buyerPhone => 'Telefone';

  @override
  String get buyerEmail => 'E-mail';

  @override
  String get buyerCountryCode => 'Indicativo do país';

  @override
  String get buyersEmptyTitle => 'Ainda sem compradores';

  @override
  String get buyersEmptyBody =>
      'Um comprador junta-se com uma entrega — ou aqui, antes: quem lhe comprou no ano passado ainda quer o pedigree.';

  @override
  String get buyersNoAnimals => 'Nenhum animal registado para este contacto';

  @override
  String buyerDeleteBody(String name) {
    return '$name é removido dos seus contactos. A entrega fica no histórico do animal, sem comprador indicado. Isto não pode ser anulado.';
  }

  @override
  String reminderHeadsUpBody(String what, String dueDay) {
    return 'Aviso: $what vence a $dueDay';
  }

  @override
  String reminderDueBody(String what) {
    return '$what vence hoje';
  }

  @override
  String get pdfAction => 'Dossiê PDF';

  @override
  String get pdfFailed => 'Não foi possível criar o PDF';

  @override
  String get pdfTitle => 'Registo de saúde e linhagem';

  @override
  String get pdfLitterTitle => 'Registo de ninhada';

  @override
  String pdfGenerated(String day) {
    return 'Gerado a $day';
  }

  @override
  String get pdfPedigree => 'Pedigree';

  @override
  String get pdfLitters => 'Ninhadas deste animal';

  @override
  String get pdfPuppies => 'Cachorros';

  @override
  String get pdfPlacement => 'Entrega';

  @override
  String get pdfBuyer => 'Comprador';

  @override
  String get pdfPhone => 'Telefone';

  @override
  String get pdfEmail => 'E-mail';

  @override
  String get pdfPlacedOn => 'Entregue a';

  @override
  String get pdfPrice => 'Preço';

  @override
  String get pdfGuarantee => 'Condições de garantia';

  @override
  String get pdfChartAxes =>
      'Peso em quilogramas em função da idade em meses. A tabela acima escreve o peso de um cachorro pequeno em gramas.';

  @override
  String get pdfDisclaimer =>
      'Produzido offline pelo Salala a partir dos registos do próprio criador. Não é um certificado veterinário.';

  @override
  String get triageTitle => 'O que fazer a seguir';

  @override
  String get triageActNow => 'Agir agora';

  @override
  String get triageWatch => 'Continuar a vigiar';

  @override
  String get triageRoutineVet => 'Visita veterinária de rotina';

  @override
  String get triageNothing => 'Nada neste registo pede um passo seguinte';

  @override
  String get triageNotDiagnosis =>
      'O Salala lê apenas o que escreveu aqui. Isto não é um diagnóstico veterinário.';

  @override
  String triageNoDoseYoung(String days) {
    return 'Sem vacina registada, aos $days';
  }

  @override
  String triageDoseOverdue(String name, String days) {
    return '$name era devido há $days';
  }

  @override
  String triageDoseDueSoon(String name, String days) {
    return '$name é devido dentro de $days';
  }

  @override
  String triageWeightLossPuppy(String percent) {
    return 'Um animal jovem perdeu $percent% do seu peso desde a última pesagem';
  }

  @override
  String triageWeightLoss(String percent) {
    return 'O peso caiu $percent% desde a última pesagem';
  }

  @override
  String triageNoGainPuppy(String days) {
    return 'Quase nenhum ganho de peso em $days';
  }

  @override
  String triageTestFlagged(String name) {
    return '$name não voltou limpo';
  }

  @override
  String triageTestExpired(String name, String days) {
    return 'O certificado $name expirou há $days';
  }

  @override
  String triageWhelpingOverdue(String name, String days) {
    return '$name: o parto está $days além da data prevista';
  }

  @override
  String triageSevereSymptom(String name) {
    return '$name foi registado como grave e continua';
  }

  @override
  String triageSymptomUnresolved(String name, String days) {
    return '$name foi visto há $days e continua';
  }

  @override
  String get agendaTitle => 'Vacinas a marcar';

  @override
  String daysSingle(String n) {
    return '$n dia';
  }

  @override
  String daysDual(String n) {
    return '$n dias';
  }

  @override
  String daysPlural(String n) {
    return '$n dias';
  }
}

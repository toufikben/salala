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
  String get onboardingSlide1Title => 'Um registo por animal';

  @override
  String get onboardingSlide1Body =>
      'Um cão ou um gato, a raça, a data de nascimento e de onde veio. O primeiro leva menos de um minuto.';

  @override
  String get onboardingSlide2Title => 'A saúde, por ordem';

  @override
  String get onboardingSlide2Body =>
      'Vacinas com a próxima data, pesagens, testes e visitas. O Salala agenda o lembrete por si.';

  @override
  String get onboardingSlide3Title => 'A história viaja com ele';

  @override
  String get onboardingSlide3Body =>
      'Um PDF ou uma folha de cálculo para o comprador, e um único ZIP que leva cada registo e cada fotografia para um telefone novo.';

  @override
  String get onboardingSkip => 'Saltar';

  @override
  String get onboardingNext => 'Seguinte';

  @override
  String get onboardingStart => 'Adicionar o primeiro animal';

  @override
  String get settingsOnboarding => 'Ver a introdução outra vez';

  @override
  String get settingsHelp => 'Ajuda';

  @override
  String get settingsRate => 'Avaliar o Salala';

  @override
  String get settingsRateBody => 'Abre o cartão de avaliação da loja.';

  @override
  String get settingsWhatsNew => 'Novidades';

  @override
  String get settingsPrivacy => 'Privacidade';

  @override
  String get settingsTerms => 'Termos de utilização';

  @override
  String get settingsLicenses => 'Licenças de código aberto';

  @override
  String get rateUnavailable =>
      'Este telefone não consegue mostrar o cartão de avaliação agora.';

  @override
  String get aboutTitle => 'Acerca do Salala';

  @override
  String get aboutBody =>
      'Um registo offline para uma criação pequena. Sem conta, sem servidor, sem rastreio — os registos vivem neste telefone e só saem pelas suas mãos.';

  @override
  String aboutVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get privacyTitle => 'Privacidade';

  @override
  String get privacyIntro =>
      'O Salala guarda uma só coisa: o que escreveu sobre os seus animais. Esta página diz onde está e o que o pode tirar deste telefone.';

  @override
  String get privacyStoredHeading => 'O que é guardado';

  @override
  String get privacyStoredBody =>
      'Cada animal, vacina, pesagem, teste, visita, sintoma, entrega e contacto de comprador — e as fotografias anexadas — numa base de dados e numa pasta de imagens dentro do armazenamento privado da aplicação. O Android mantém essa pasta fora do alcance de outras aplicações, e os ficheiros não são cifrados além disso.';

  @override
  String get privacyBackupHeading => 'O que sai deste telefone';

  @override
  String get privacyBackupBody =>
      'Apenas o que exporta: um ZIP com todos os registos e imagens, um CSV de uma tabela, ou um PDF de um animal. Cada um vai para onde o enviar, por isso uma cópia leva nomes e telefones dos seus compradores — trate o ficheiro como o papel que substitui. Ligue o bloqueio se o telefone viajar.';

  @override
  String get privacyCollectHeading => 'O que é recolhido sobre si';

  @override
  String get privacyCollectBody =>
      'Nada. Não há analítica, nem relatórios de falhas, nem identificador publicitário, nem qualquer chamada de rede nesta aplicação.';

  @override
  String get privacyRemoveHeading => 'Como apagar';

  @override
  String get privacyRemoveBody =>
      'Desinstalar remove a base de dados e a pasta de imagens. Não há cópia em lado nenhum, por isso exporte um pacote primeiro se os registos importam — e o PIN do bloqueio também não é recuperável.';

  @override
  String get termsTitle => 'Termos de utilização';

  @override
  String get termsUseHeading => 'Para que serve esta aplicação';

  @override
  String get termsUseBody =>
      'Manter os seus próprios registos sobre os animais à sua guarda. Uma licença por pessoa; instale-a nos telefones que usa.';

  @override
  String get termsDataHeading => 'Os seus dados são seus';

  @override
  String get termsDataBody =>
      'Não guardamos cópia e não podemos restaurar nada. As cópias são da sua responsabilidade, e o botão de exportar nas Definições é todo o mecanismo.';

  @override
  String get termsAdviceHeading => 'Não é conselho veterinário';

  @override
  String get termsAdviceBody =>
      'O Salala repete o que escreveu e faz aritmética com datas e pesos. Não diagnostica, e um lembrete é uma entrada de calendário, não uma opinião clínica. Ligue a um veterinário.';

  @override
  String get termsWarrantyHeading => 'Sem garantia';

  @override
  String get termsWarrantyBody =>
      'A aplicação é fornecida tal como está. Na medida em que a lei o permite, não se aceita responsabilidade por um registo perdido, um lembrete falhado ou uma decisão tomada com base no que aqui está escrito.';

  @override
  String get helpTitle => 'Ajuda';

  @override
  String get helpQ1 => 'Como faço uma cópia?';

  @override
  String get helpA1 =>
      'Definições, depois Exportar registos. O ZIP leva cada linha e cada fotografia; envie-o para si e guarde-o. Restaurar relê o mesmo ficheiro em qualquer telefone.';

  @override
  String get helpQ2 => 'Esqueci-me do PIN';

  @override
  String get helpA2 =>
      'Não é recuperável, porque só se guarda um hash. Desinstalar apaga o bloqueio e com ele o registo, por isso se tiver um pacote recente restaure-o depois.';

  @override
  String get helpQ3 => 'Perdi o telefone';

  @override
  String get helpA3 =>
      'Nada está num servidor, por isso nada pode voltar. Um pacote exportado antes restaura o registo num telefone novo; um que nunca exportou está perdido.';

  @override
  String get helpQ4 => 'De onde vêm os lembretes?';

  @override
  String get helpA4 =>
      'Das próximas datas que escreveu. O Salala marca um alarme um mês antes e outro na própria manhã; se as notificações estiverem desligadas, as datas continuam na agenda do efetivo.';

  @override
  String get helpQ5 => 'Porque diz uma fotografia que não está neste telefone?';

  @override
  String get helpA5 =>
      'A linha sobreviveu e o ficheiro não — normalmente depois de restaurar um pacote sem fotografias. Adicionar a fotografia outra vez resolve.';

  @override
  String get helpQ6 => 'Posso entregar o registo do animal?';

  @override
  String get helpA6 =>
      'Sim. Abra o animal e exporte o PDF: um documento fixo que o comprador guarda sem esta aplicação. A entrega em si fica registada na mesma página.';

  @override
  String get helpQ7 => 'Que línguas existem?';

  @override
  String get helpA7 =>
      'Inglês, árabe, francês, alemão, espanhol, italiano, português e neerlandês. Definições, depois Idioma — a mudança aplica-se de imediato.';

  @override
  String get helpQ8 => 'Algo está errado na aplicação';

  @override
  String get helpA8 =>
      'Escreva-nos e diga o que estava a fazer quando aconteceu. A versão está na página Acerca.';

  @override
  String get helpContactHeading => 'Escreva-nos';

  @override
  String get whatsNewTitle => 'Novidades';

  @override
  String get whatsNew1 =>
      'Fotografias nos cartões do efetivo, e um desenho mais quente e amplo em todo o lado.';

  @override
  String get whatsNew2 => 'Um lembrete tocado abre o animal a que se refere.';

  @override
  String get whatsNew3 =>
      'A exportação da folha de cálculo fala a língua que está a ler.';

  @override
  String get whatsNew4 =>
      'Mais cinco línguas: alemão, espanhol, italiano, português e neerlandês.';

  @override
  String get whatsNew5 =>
      'Páginas de privacidade, termos e ajuda, e uma linha de avaliação nas Definições.';

  @override
  String daysPlural(String n) {
    return '$n dias';
  }
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Salala';

  @override
  String get navAnimals => 'Animales';

  @override
  String get navLitters => 'Camadas';

  @override
  String get navBuyers => 'Compradores';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get languageName => 'Español';

  @override
  String get homeEmptyTitle => 'Aún no hay animales';

  @override
  String get homeEmptyBody =>
      'Añada su primer perro o gato para empezar un historial de salud y linaje.';

  @override
  String get homeAddAnimal => 'Añadir animal';

  @override
  String get homeBreedingStock => 'Reproductores';

  @override
  String get homeAllAnimals => 'Todos los animales';

  @override
  String get homeSearchHint =>
      'Buscar por nombre, número, chip, nota o comprador';

  @override
  String homeNoMatches(String query) {
    return 'Nada coincide con «$query»';
  }

  @override
  String homeAnimalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count animales',
      one: '1 animal',
      zero: 'Ningún animal',
    );
    return '$_temp0';
  }

  @override
  String get animalName => 'Nombre';

  @override
  String get animalSpecies => 'Especie';

  @override
  String get animalBreed => 'Raza';

  @override
  String get animalSex => 'Sexo';

  @override
  String get animalBirthDate => 'Fecha de nacimiento';

  @override
  String animalBornOn(String day) {
    return 'Nacido el $day';
  }

  @override
  String get animalStatus => 'Estado';

  @override
  String get animalMicrochip => 'Número de microchip';

  @override
  String get animalMicrochipDate => 'Microchip implantado';

  @override
  String get animalLitter => 'Camada';

  @override
  String get animalNone => 'Ninguno';

  @override
  String get animalRegistrationNo => 'Número de registro';

  @override
  String get animalRegistry => 'Registro';

  @override
  String get animalColor => 'Color';

  @override
  String get animalNotes => 'Notas';

  @override
  String get animalIsBreedingStock => 'Mantener como reproductor';

  @override
  String get animalAddTitle => 'Añadir animal';

  @override
  String get animalEditTitle => 'Editar animal';

  @override
  String animalDeleteTitle(String name) {
    return '¿Eliminar a $name?';
  }

  @override
  String animalDeleteLittersNote(int litters, int puppies) {
    return 'También se eliminarán $litters de sus camadas, y los $puppies cachorros que registraron siguen en sus animales pero sin el registro de su madre.';
  }

  @override
  String get animalDeleteBody =>
      'También se eliminan sus vacunas, pruebas de salud, pesos, visitas y síntomas, junto con cualquier entrega registrada, sus fotografías y los archivos que las guardan en este teléfono. Esto no se puede deshacer.';

  @override
  String get animalNameRequired => 'El nombre es obligatorio';

  @override
  String get animalSpeciesRequired => 'Elija una especie';

  @override
  String get sexMale => 'Macho';

  @override
  String get sexFemale => 'Hembra';

  @override
  String get sexUnknown => 'Desconocido';

  @override
  String get statusActive => 'Conmigo';

  @override
  String get statusSold => 'Entregado';

  @override
  String get statusRetired => 'Retirado';

  @override
  String get statusDeceased => 'Fallecido';

  @override
  String get recordsVaccinations => 'Vacunas';

  @override
  String get recordsHealthTests => 'Pruebas de salud';

  @override
  String get recordsWeights => 'Pesos';

  @override
  String get recordsVisits => 'Visitas al veterinario';

  @override
  String get recordsSymptoms => 'Síntomas';

  @override
  String get recordsPhotos => 'Fotos';

  @override
  String get recordsPlacements => 'Entregas';

  @override
  String get recordsEmpty => 'Todavía no hay nada registrado.';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionAdd => 'Añadir';

  @override
  String get actionClose => 'Cerrar';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get actionClear => 'Borrar';

  @override
  String get actionReplace => 'Sustituir';

  @override
  String get lockTitle => 'Salala está bloqueado';

  @override
  String get lockEnterPin => 'Introduzca su PIN';

  @override
  String get lockUnlock => 'Desbloquear';

  @override
  String get lockWrongPin => 'PIN incorrecto';

  @override
  String get lockSetPinTitle => 'Cree un PIN';

  @override
  String get lockSetPinBody =>
      'Cuatro dígitos o más. Se queda en este dispositivo y no se puede recuperar, así que apúntelo.';

  @override
  String get lockConfirmPin => 'Repita el PIN';

  @override
  String get lockPinTooShort => 'Cuatro dígitos o más';

  @override
  String get lockPinMismatch => 'Los dos PIN no coinciden';

  @override
  String get lockEnable => 'Bloquear la aplicación';

  @override
  String get lockDisable => 'Desactivar el bloqueo';

  @override
  String get lockCurrentPin => 'PIN actual';

  @override
  String get lockChangeFailed =>
      'El teléfono no cambió el bloqueo de la aplicación.';

  @override
  String get lockChangePinDone => 'PIN cambiado.';

  @override
  String lockTooManyAttempts(int seconds) {
    return 'Demasiados PIN incorrectos. Inténtelo en $seconds s.';
  }

  @override
  String get settingsAppLock => 'Bloqueo de la aplicación';

  @override
  String get settingsChangePin => 'Cambiar el PIN';

  @override
  String get settingsChangePinBody =>
      'Introduzca el PIN actual y elija uno nuevo.';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Idioma del sistema';

  @override
  String get languageNotStored => 'El teléfono no guardó este idioma.';

  @override
  String get startupFailedTitle =>
      'Salala no pudo abrir el libro de cría en este teléfono.';

  @override
  String get startupFailedBody =>
      'Sus registros siguen en el archivo. Cierre la aplicación y ábrala de nuevo.';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsBuildTag => 'Versión';

  @override
  String get settingsOfflineNote =>
      'Todo se guarda en este dispositivo. Sin cuenta, sin servidor, sin seguimiento.';

  @override
  String get settingsExport => 'Exportar registros';

  @override
  String get settingsExportBody =>
      'Un archivo ZIP con todos los registros y fotos de este teléfono';

  @override
  String get settingsImport => 'Restaurar desde un paquete';

  @override
  String get settingsImportBody => 'Volver a leer un paquete en este teléfono';

  @override
  String settingsLastBackup(String day) {
    return 'Última copia: $day';
  }

  @override
  String get settingsNeverBackedUp =>
      'Ninguna copia ha salido aún de este teléfono';

  @override
  String get settingsCsv => 'Hoja de cálculo (CSV)';

  @override
  String get settingsCsvBody =>
      'Para su contable, un formulario de registro o un copropietario. Se abre en Excel, Numbers o Hojas de cálculo de Google.';

  @override
  String get settingsCsvHerd => 'Animales';

  @override
  String get settingsCsvLitters => 'Camadas';

  @override
  String get settingsCsvVaccinations => 'Vacunas';

  @override
  String get settingsCsvPlacements => 'Entregas';

  @override
  String csvShared(String file) {
    return '$file está listo para enviar';
  }

  @override
  String get csvShareFailed => 'La hoja no se pudo escribir en este teléfono';

  @override
  String get csvEmpty => 'Todavía no hay nada que exportar en este teléfono';

  @override
  String get csvColAnimal => 'Animal';

  @override
  String get csvColCountry => 'País';

  @override
  String get csvColPuppies => 'Cachorros';

  @override
  String get csvColBreedingStock => 'Reproductor';

  @override
  String get csvColYes => 'sí';

  @override
  String get csvColNo => 'no';

  @override
  String packShared(String file) {
    return '$file está listo para enviar';
  }

  @override
  String get packShareFailed =>
      'El paquete no se pudo escribir en este teléfono';

  @override
  String get packReadFailed => 'Ese archivo no se pudo abrir';

  @override
  String get packNotAPack =>
      'Ese archivo no es un paquete de Salala, o está dañado';

  @override
  String get packFromTheFuture =>
      'Ese paquete viene de una versión de Salala más reciente que esta';

  @override
  String packIncomplete(String table) {
    return 'A ese paquete le falta parte del libro: $table';
  }

  @override
  String packUnknownTable(String table) {
    return 'Ese paquete contiene una tabla que esta Salala no conoce: $table';
  }

  @override
  String get packRestoreTitle => '¿Sustituir todo lo que hay en este teléfono?';

  @override
  String packRestoreBody(int animals, int rows, String day) {
    return 'Del $day. Animales: $animals. Registros: $rows. La restauración sustituye todo lo que hay ahora en este teléfono.';
  }

  @override
  String packRestored(int rows) {
    return 'Registros restaurados: $rows';
  }

  @override
  String get packRestoreFailed =>
      'El paquete no se pudo restaurar. Nada cambió en este teléfono.';

  @override
  String get litterAdd => 'Nueva camada';

  @override
  String get litterEditTitle => 'Editar camada';

  @override
  String get litterAddPuppies => 'Añadir cachorros';

  @override
  String get litterHowMany => '¿Cuántos?';

  @override
  String get litterAddTitle => 'Registrar una camada';

  @override
  String get litterEmptyTitle => 'Aún no hay camadas';

  @override
  String get litterEmptyBody =>
      'Registre un apareamiento para seguir la gestación y registrar los cachorros en un solo paso.';

  @override
  String get litterName => 'Nombre de la camada';

  @override
  String get litterNameRequired => 'El nombre de la camada es obligatorio';

  @override
  String get litterDam => 'Madre';

  @override
  String get litterDamRequired => 'Elija la madre';

  @override
  String get litterDamMissing => 'Madre eliminada';

  @override
  String get litterSire => 'Padre';

  @override
  String get litterSireUnknown => 'Padre desconocido';

  @override
  String get litterNoDams => 'Marque primero una hembra como reproductora';

  @override
  String get litterMatingDate => 'Fecha del apareamiento';

  @override
  String get litterWhelpingDate => 'Fecha del parto';

  @override
  String get litterWeaningDate => 'Fecha del destete';

  @override
  String get litterWhelpingBeforeMating =>
      'La fecha del parto es anterior a la del apareamiento.';

  @override
  String get litterWeaningBeforeWhelping =>
      'La fecha del destete es anterior a la del parto.';

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
      zero: 'Ningún cachorro registrado',
    );
    return '$_temp0';
  }

  @override
  String get litterPuppiesToRegister => 'Cachorros nacidos';

  @override
  String get litterPuppiesHint =>
      'Cada cachorro se añade a sus animales y lleva el nombre de la camada';

  @override
  String get litterNoPuppies =>
      'Todavía no hay cachorros registrados para esta camada.';

  @override
  String get litterGone => 'Esta camada fue eliminada.';

  @override
  String litterDeleteTitle(String name) {
    return '¿Eliminar $name?';
  }

  @override
  String get litterDeleteBody =>
      'Los cachorros siguen en sus animales; solo se elimina el registro del apareamiento. Esto no se puede deshacer.';

  @override
  String get animalGone => 'Este animal fue eliminado.';

  @override
  String get animalDeathDate => 'Falleció el';

  @override
  String get animalDam => 'Madre';

  @override
  String get animalSire => 'Padre';

  @override
  String get valueUnknown => 'Sin registrar';

  @override
  String get recordDeleteTitle => '¿Eliminar este registro?';

  @override
  String get recordSaveFailed =>
      'Esto no se pudo guardar. No se escribió nada.';

  @override
  String get recordDeleteFailed =>
      'Esto no se pudo eliminar. El registro sigue ahí.';

  @override
  String get recordDateBeforeBirth =>
      'Esta fecha es anterior al nacimiento de este animal.';

  @override
  String get vaccinationAdd => 'Añadir vacuna';

  @override
  String get vaccinationAddTitle => 'Registrar una vacuna';

  @override
  String get vaccinationEditTitle => 'Editar vacuna';

  @override
  String get vaccinationName => 'Vacuna';

  @override
  String get vaccinationNameRequired => 'El nombre de la vacuna es obligatorio';

  @override
  String get vaccinationGiven => 'Administrada';

  @override
  String get vaccinationNextDue => 'Próxima dosis';

  @override
  String get vaccinationNextDueHint =>
      'Una dosis cuya fecha ha pasado se marca como atrasada.';

  @override
  String get doseDueBeforeAdministered =>
      'La próxima dosis toca antes de esta.';

  @override
  String get vaccinationOverdue => 'Atrasada';

  @override
  String get vaccinationManufacturer => 'Fabricante';

  @override
  String get vaccinationBatch => 'Número de lote';

  @override
  String get vaccinationVet => 'Veterinario';

  @override
  String get vaccinationClinic => 'Clínica';

  @override
  String get vaccinationCertificate => 'Número de certificado';

  @override
  String get vaccinationDeleteBody =>
      'La dosis se elimina del historial de este animal. Esto no se puede deshacer.';

  @override
  String get weightAdd => 'Añadir peso';

  @override
  String get weightKg => 'Peso (kg)';

  @override
  String get weightColumn => 'Peso';

  @override
  String get weightRequired => 'Introduzca el peso';

  @override
  String get weightInvalid => 'Introduzca un peso como 4,2';

  @override
  String get weightMeasuredOn => 'Medido el';

  @override
  String get unitKg => 'kg';

  @override
  String get unitGrams => 'g';

  @override
  String get weightNote => 'Nota';

  @override
  String get weightDeleteBody =>
      'La pesada se elimina. Esto no se puede deshacer.';

  @override
  String get weightAppendOnlyHint =>
      'Las pesadas nunca se editan. ¿Midió mal? Bórrela y vuelva a pesar.';

  @override
  String get animalSpeciesHelper => 'perro · gato';

  @override
  String get healthTestAdd => 'Añadir prueba';

  @override
  String get healthTestAddTitle => 'Registrar una prueba de salud';

  @override
  String get healthTestEditTitle => 'Editar prueba de salud';

  @override
  String get healthTestType => 'Cribado';

  @override
  String get healthTestTypeRequired => 'Nombre el cribado';

  @override
  String get healthTestResult => 'Resultado';

  @override
  String get healthTestResultRequired => 'Introduzca el resultado';

  @override
  String get healthTestResultHelper => 'Clear · Carrier · Affected';

  @override
  String get healthTestDate => 'Probado el';

  @override
  String get healthTestValidUntil => 'Válido hasta';

  @override
  String get certificateExpiresBeforeTest =>
      'Este certificado caduca antes del día de la prueba que certifica.';

  @override
  String get healthTestBody => 'Organismo';

  @override
  String get healthTestVerifiedBy => 'Verificado por';

  @override
  String get healthTestExpired => 'Caducado';

  @override
  String get healthTestDeleteBody =>
      'El cribado se elimina del historial de este animal. Esto no se puede deshacer.';

  @override
  String get visitAdd => 'Añadir visita';

  @override
  String get visitAddTitle => 'Registrar una visita al veterinario';

  @override
  String get visitEditTitle => 'Editar visita al veterinario';

  @override
  String get visitDate => 'Fecha de la visita';

  @override
  String get visitReason => 'Motivo';

  @override
  String get visitNoReason => 'Consulta';

  @override
  String get visitOutcome => 'Resultado';

  @override
  String get visitCost => 'Coste';

  @override
  String get visitCostInvalid => 'Introduzca un importe como 250';

  @override
  String get visitCurrency => 'Moneda';

  @override
  String get visitDeleteBody =>
      'La visita se elimina del historial de este animal. Esto no se puede deshacer.';

  @override
  String get symptomAdd => 'Añadir síntoma';

  @override
  String get symptomAddTitle => 'Registrar un síntoma';

  @override
  String get symptomEditTitle => 'Editar síntoma';

  @override
  String get symptomName => 'Síntoma';

  @override
  String get symptomNameRequired => 'Escriba lo que vio';

  @override
  String get symptomSeverity => 'Gravedad';

  @override
  String get severityMild => 'Leve';

  @override
  String get severityModerate => 'Moderado';

  @override
  String get severitySevere => 'Grave';

  @override
  String get symptomObservedOn => 'Visto el';

  @override
  String get symptomState => 'Estado';

  @override
  String get symptomOngoing => 'Sigue presente';

  @override
  String get symptomResolved => 'Resuelto';

  @override
  String get symptomDeleteBody =>
      'El síntoma se elimina del historial de este animal. Esto no se puede deshacer.';

  @override
  String get photoAdd => 'Añadir foto';

  @override
  String get photoFromGallery => 'Elegir de la galería';

  @override
  String get photoFromCamera => 'Hacer una foto';

  @override
  String get photoDeleteBody =>
      'La foto se elimina del libro de este animal, y el archivo con ella. Esto no se puede deshacer.';

  @override
  String get photoMissing => 'No está en este teléfono';

  @override
  String get photoTooLarge => 'Esta foto es demasiado grande para guardarla';

  @override
  String get photoNotAnImage => 'Este archivo no es una foto';

  @override
  String get placementAdd => 'Añadir entrega';

  @override
  String get placementAddTitle => 'Registrar una entrega';

  @override
  String get placementEditTitle => 'Editar entrega';

  @override
  String get placementBuyer => 'Comprador';

  @override
  String get placementNoBuyer => 'Comprador sin registrar';

  @override
  String get placementDate => 'Entregado el';

  @override
  String get placementPrice => 'Precio';

  @override
  String get placementPriceInvalid => 'Introduzca un importe como 2500';

  @override
  String get placementCurrency => 'Moneda';

  @override
  String get placementGuarantee => 'Condiciones de garantía';

  @override
  String get placementDeleteBody =>
      'La entrega se elimina del historial de este animal. El comprador sigue en sus contactos. Esto no se puede deshacer.';

  @override
  String get buyerAdd => 'Nuevo comprador';

  @override
  String get buyerAddTitle => 'Añadir un comprador';

  @override
  String get buyerEditTitle => 'Editar comprador';

  @override
  String get buyerPhone => 'Teléfono';

  @override
  String get buyerEmail => 'Correo electrónico';

  @override
  String get buyerCountryCode => 'Código de país';

  @override
  String get buyersEmptyTitle => 'Aún no hay compradores';

  @override
  String get buyersEmptyBody =>
      'Un comprador se añade con una entrega, o aquí antes: quien le compró el año pasado todavía quiere el pedigrí.';

  @override
  String get buyersNoAnimals => 'Ningún animal registrado para este contacto';

  @override
  String buyerDeleteBody(String name) {
    return '$name se elimina de sus contactos. La entrega sigue en el historial del animal, sin comprador nombrado. Esto no se puede deshacer.';
  }

  @override
  String reminderHeadsUpBody(String what, String dueDay) {
    return 'Aviso: $what vence el $dueDay';
  }

  @override
  String reminderDueBody(String what) {
    return '$what vence hoy';
  }

  @override
  String get pdfAction => 'Dossier PDF';

  @override
  String get pdfFailed => 'El PDF no se pudo crear';

  @override
  String get pdfTitle => 'Historial de salud y linaje';

  @override
  String get pdfLitterTitle => 'Registro de camada';

  @override
  String pdfGenerated(String day) {
    return 'Generado el $day';
  }

  @override
  String get pdfPedigree => 'Pedigrí';

  @override
  String get pdfLitters => 'Camadas de este animal';

  @override
  String get pdfPuppies => 'Cachorros';

  @override
  String get pdfPlacement => 'Entrega';

  @override
  String get pdfBuyer => 'Comprador';

  @override
  String get pdfPhone => 'Teléfono';

  @override
  String get pdfEmail => 'Correo electrónico';

  @override
  String get pdfPlacedOn => 'Entregado el';

  @override
  String get pdfPrice => 'Precio';

  @override
  String get pdfGuarantee => 'Condiciones de garantía';

  @override
  String get pdfChartAxes =>
      'Peso en kilogramos frente a la edad en meses. La tabla de arriba escribe el peso de un cachorro pequeño en gramos.';

  @override
  String get pdfDisclaimer =>
      'Generado sin conexión por Salala a partir de los registros del propio criador. No es un certificado veterinario.';

  @override
  String get triageTitle => 'Qué hacer ahora';

  @override
  String get triageActNow => 'Actúe ya';

  @override
  String get triageWatch => 'Siga observando';

  @override
  String get triageRoutineVet => 'Visita rutinaria al veterinario';

  @override
  String get triageNothing => 'Nada en este registro pide un paso siguiente';

  @override
  String get triageNotDiagnosis =>
      'Salala solo lee lo que usted escribió aquí. Esto no es un diagnóstico veterinario.';

  @override
  String triageNoDoseYoung(String days) {
    return 'Sin vacuna registrada, a los $days';
  }

  @override
  String triageDoseOverdue(String name, String days) {
    return '$name tocaba hace $days';
  }

  @override
  String triageDoseDueSoon(String name, String days) {
    return '$name toca en $days';
  }

  @override
  String triageWeightLossPuppy(String percent) {
    return 'Un animal joven ha perdido el $percent % de su peso desde la última pesada';
  }

  @override
  String triageWeightLoss(String percent) {
    return 'El peso ha bajado un $percent % desde la última pesada';
  }

  @override
  String triageNoGainPuppy(String days) {
    return 'Casi nada de peso ganado en $days';
  }

  @override
  String triageTestFlagged(String name) {
    return '$name no volvió limpio';
  }

  @override
  String triageTestExpired(String name, String days) {
    return 'El certificado $name caducó hace $days';
  }

  @override
  String triageWhelpingOverdue(String name, String days) {
    return '$name: el parto va $days por encima de la fecha prevista';
  }

  @override
  String triageSevereSymptom(String name) {
    return '$name se registró como grave y sigue presente';
  }

  @override
  String triageSymptomUnresolved(String name, String days) {
    return '$name se vio hace $days y sigue presente';
  }

  @override
  String get agendaTitle => 'Vacunas por concertar';

  @override
  String daysSingle(String n) {
    return '$n día';
  }

  @override
  String daysDual(String n) {
    return '$n días';
  }

  @override
  String daysPlural(String n) {
    return '$n días';
  }
}

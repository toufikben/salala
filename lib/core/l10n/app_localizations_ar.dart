// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'سلالة';

  @override
  String get navAnimals => 'الحيوانات';

  @override
  String get navLitters => 'الولادات';

  @override
  String get navBuyers => 'المشترون';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get languageName => 'العربية';

  @override
  String get homeEmptyTitle => 'لا توجد حيوانات بعد';

  @override
  String get homeEmptyBody => 'القطيع يبدأ بواحد. سمّها، وابدأ سجلّها من هنا.';

  @override
  String get homeAddAnimal => 'إضافة حيوان';

  @override
  String get homeBreedingStock => 'حيوانات التربية';

  @override
  String get homeAllAnimals => 'كل الحيوانات';

  @override
  String get homeSearchHint =>
      'ابحث بالاسم أو الرقم أو الشريحة أو الملاحظة أو المشتري';

  @override
  String homeNoMatches(String query) {
    return 'لا نتيجة تطابق « $query »';
  }

  @override
  String homeAnimalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حيوان',
      many: '$count حيوانًا',
      few: '$count حيوانات',
      two: 'حيوانان',
      one: 'حيوان واحد',
      zero: 'لا توجد حيوانات',
    );
    return '$_temp0';
  }

  @override
  String get animalName => 'الاسم';

  @override
  String get animalSpecies => 'الفصيلة';

  @override
  String get animalBreed => 'السلالة';

  @override
  String get animalSex => 'الجنس';

  @override
  String get animalBirthDate => 'تاريخ الميلاد';

  @override
  String animalBornOn(String day) {
    return 'وُلد في $day';
  }

  @override
  String get animalStatus => 'الحالة';

  @override
  String get animalMicrochip => 'رقم الشريحة';

  @override
  String get animalMicrochipDate => 'تاريخ زرع الشريحة';

  @override
  String get animalLitter => 'الولادة';

  @override
  String get animalNone => 'لا شيء';

  @override
  String get animalRegistrationNo => 'رقم التسجيل';

  @override
  String get animalRegistry => 'جهة التسجيل';

  @override
  String get animalColor => 'اللون';

  @override
  String get animalNotes => 'ملاحظات';

  @override
  String get animalIsBreedingStock => 'تُصنَّف كحيوان تربية';

  @override
  String get animalAddTitle => 'إضافة حيوان';

  @override
  String get animalEditTitle => 'تعديل الحيوان';

  @override
  String animalDeleteTitle(String name) {
    return 'حذف $name؟';
  }

  @override
  String animalDeleteLittersNote(int litters, int puppies) {
    return 'سيُحذف أيضاً $litters سجل ولادة هي أمّها، ويبقى $puppies من جرائها في حيواناتك لكن دون سجل أمّهم.';
  }

  @override
  String get animalDeleteBody =>
      'سيُحذف معها أيضاً التطعيمات وفحوصات الصحة والأوزان والزيارات البيطرية والأعراض، وسجل التسليم إن وُجد، وصورها وما على هذا الهاتف من ملفات تلك الصور، والولادات التي هي أمّ لها. لا يمكن التراجع عن هذه الخطوة.';

  @override
  String get animalNameRequired => 'الاسم مطلوب';

  @override
  String get animalSpeciesRequired => 'اختر الفصيلة';

  @override
  String get sexMale => 'ذكر';

  @override
  String get sexFemale => 'أنثى';

  @override
  String get sexUnknown => 'غير محدد';

  @override
  String get statusActive => 'لدي';

  @override
  String get statusSold => 'تم تسليمه';

  @override
  String get statusRetired => 'متقاعد';

  @override
  String get statusDeceased => 'متوفى';

  @override
  String get recordsVaccinations => 'التطعيمات';

  @override
  String get recordsHealthTests => 'فحوصات الصحة';

  @override
  String get recordsWeights => 'الأوزان';

  @override
  String get recordsVisits => 'الزيارات البيطرية';

  @override
  String get recordsSymptoms => 'الأعراض';

  @override
  String get recordsPhotos => 'الصور';

  @override
  String get recordsPlacements => 'التسليم';

  @override
  String get recordsEmpty => 'لا يوجد سجل بعد.';

  @override
  String get detailStoryLine => 'كل سجل هنا جزء من قصتها.';

  @override
  String get detailDiedLine => 'سجلّها يبقى كما كان.';

  @override
  String placedFarewell(String name) {
    return '$name انتقل إلى بيت جديد. السجل بقي معك.';
  }

  @override
  String reminderHeadsUpBody(String what, String dueDay) {
    return 'تنبيه: $what مستحق في $dueDay';
  }

  @override
  String reminderDueBody(String what) {
    return '$what موعدها اليوم. دقيقتان تكفيان';
  }

  @override
  String get actionSave => 'حفظ';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get actionDelete => 'حذف';

  @override
  String get actionEdit => 'تعديل';

  @override
  String get actionAdd => 'إضافة';

  @override
  String get actionClose => 'إغلاق';

  @override
  String get actionRetry => 'إعادة المحاولة';

  @override
  String get actionClear => 'مسح';

  @override
  String get actionReplace => 'استبدال';

  @override
  String get lockTitle => 'سلالة مقفل';

  @override
  String get lockEnterPin => 'أدخل الرمز السري';

  @override
  String get lockUnlock => 'فتح';

  @override
  String get lockWrongPin => 'الرمز غير صحيح';

  @override
  String get lockSetPinTitle => 'أنشئ رمزًا سريًا';

  @override
  String get lockSetPinBody =>
      'أربعة أرقام على الأقل. يبقى الرمز على هذا الجهاز ولا يمكن استرجاعه، لذلك دَوِّنه في مكان آمن.';

  @override
  String get lockConfirmPin => 'أعد إدخال الرمز';

  @override
  String get lockPinTooShort => 'أربعة أرقام على الأقل';

  @override
  String get lockPinMismatch => 'الرمزان غير متطابقين';

  @override
  String get lockEnable => 'قفل التطبيق';

  @override
  String get lockDisable => 'إيقاف القفل';

  @override
  String get lockCurrentPin => 'الرمز الحالي';

  @override
  String get lockChangeFailed => 'رفض الهاتف تغيير قفل التطبيق.';

  @override
  String get lockChangePinDone => 'تم تغيير الرمز.';

  @override
  String lockTooManyAttempts(int seconds) {
    return 'محاولات خاطئة كثيرة. أعد المحاولة بعد $seconds ثانية.';
  }

  @override
  String get settingsAppLock => 'قفل التطبيق';

  @override
  String get settingsChangePin => 'تغيير الرمز';

  @override
  String get settingsChangePinBody => 'أدخل الرمز الحالي ثم اختر رمزًا جديدًا.';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsLanguageSystem => 'لغة النظام';

  @override
  String get languageNotStored => 'رفض الهاتف حفظ هذه اللغة.';

  @override
  String get startupFailedTitle =>
      'لم تتمكن سلالة من فتح السجل على هذا الهاتف.';

  @override
  String get startupFailedBody =>
      'سجلاتك ما زالت في الملف. أغلق التطبيق وأعد فتحه.';

  @override
  String get settingsAbout => 'حول التطبيق';

  @override
  String get settingsTrial => 'التجربة المجانية';

  @override
  String settingsTrialRemaining(String days) {
    return 'بقيت $days يومًا';
  }

  @override
  String get settingsTrialOver => 'انتهت التجربة';

  @override
  String get settingsBuildTag => 'رقم البناء';

  @override
  String get settingsOfflineNote =>
      'كل شيء محفوظ على جهازك. بلا حساب، بلا خادم، بلا تتبع.';

  @override
  String get settingsExport => 'تصدير السجلات';

  @override
  String get settingsExportBody =>
      'ملف ZIP واحد يحمل كل سجل وصورة على هذا الهاتف';

  @override
  String get settingsImport => 'استرجاع من حزمة';

  @override
  String get settingsImportBody => 'قراءة حزمة وإرجاعها إلى هذا الهاتف';

  @override
  String settingsLastBackup(String day) {
    return 'آخر نسخة احتياطية: $day';
  }

  @override
  String get settingsNeverBackedUp => 'لم تخرج نسخة احتياطية من هذا الهاتف بعد';

  @override
  String get settingsCsv => 'جدول (CSV)';

  @override
  String get settingsCsvBody =>
      'لمحاسبك أو لاستمارة السجل أو لشريك في الملكية. يُفتح في Excel أو Numbers أو Google Sheets.';

  @override
  String get settingsCsvHerd => 'الحيوانات';

  @override
  String get settingsCsvLitters => 'الولادات';

  @override
  String get settingsCsvVaccinations => 'التحصينات';

  @override
  String get settingsCsvPlacements => 'التسليمات';

  @override
  String csvShared(String file) {
    return '$file جاهز للإرسال';
  }

  @override
  String get csvShareFailed => 'لم يمكن كتابة الجدول على هذا الهاتف';

  @override
  String get csvEmpty => 'لا يوجد على هذا الهاتف ما يُصدَّر بعد';

  @override
  String get csvColAnimal => 'الحيوان';

  @override
  String get csvColCountry => 'الدولة';

  @override
  String get csvColPuppies => 'الجراء';

  @override
  String get csvColBreedingStock => 'قطيع التربية';

  @override
  String get csvColYes => 'نعم';

  @override
  String get csvColNo => 'لا';

  @override
  String packShared(String file) {
    return '$file جاهز للإرسال';
  }

  @override
  String get packShareFailed => 'لم يمكن كتابة الحزمة على هذا الهاتف';

  @override
  String get packReadFailed => 'لم يمكن فتح هذا الملف';

  @override
  String get packNotAPack => 'هذا الملف ليس حزمة سلالة أو أنه تالف';

  @override
  String get packFromTheFuture => 'هذه الحزمة من نسخة سلالة أحدث من هذه النسخة';

  @override
  String packIncomplete(String table) {
    return 'تنقص هذه الحزمة جزء من السجلات: $table';
  }

  @override
  String packUnknownTable(String table) {
    return 'تحتوي هذه الحزمة على جدول لا تعرفه سلالة: $table';
  }

  @override
  String get packRestoreTitle => 'استبدال كل شيء على هذا الهاتف؟';

  @override
  String packRestoreBody(int animals, int rows, String day) {
    return 'من $day. الحيوانات: $animals. السجلات: $rows. الاسترجاع يستبدل كل ما على هذا الهاتف الآن.';
  }

  @override
  String packRestored(int rows) {
    return 'عدد السجلات المسترجعة: $rows';
  }

  @override
  String get packRestoreFailed =>
      'لم يمكن استرجاع الحزمة. لم يتغير شيء على هذا الهاتف.';

  @override
  String get litterAdd => 'ولادة جديدة';

  @override
  String get litterEditTitle => 'تعديل الولادة';

  @override
  String get litterAddPuppies => 'إضافة جراء';

  @override
  String get litterHowMany => 'كم عددها؟';

  @override
  String get litterAddTitle => 'تسجيل ولادة';

  @override
  String get litterEmptyTitle => 'لا توجد ولادات بعد';

  @override
  String get litterEmptyBody =>
      'سجّل التزاوج لمتابعة الحمل وتسجيل الجراء في خطوة واحدة.';

  @override
  String get litterName => 'اسم الولادة';

  @override
  String get litterNameRequired => 'اسم الولادة مطلوب';

  @override
  String get litterDam => 'الأم';

  @override
  String get litterDamRequired => 'اختر الأم';

  @override
  String get litterDamMissing => 'أُمّ محذوفة';

  @override
  String get litterSire => 'الأب';

  @override
  String get litterSireUnknown => 'أب غير معروف';

  @override
  String get litterNoDams => 'صنّف أنثى كحيوان تربية أولًا';

  @override
  String get litterMatingDate => 'تاريخ التزاوج';

  @override
  String get litterWhelpingDate => 'تاريخ الولادة';

  @override
  String get litterWeaningDate => 'تاريخ الفطام';

  @override
  String get litterWhelpingBeforeMating => 'تاريخ الولادة يسبق تاريخ التزاوج.';

  @override
  String get litterWeaningBeforeWhelping => 'تاريخ الفطام يسبق تاريخ الولادة.';

  @override
  String litterExpected(String date) {
    return 'الولادة المتوقعة: $date';
  }

  @override
  String get statsTitle => 'الكنل بالأرقام';

  @override
  String get settingsStats => 'الكنل بالأرقام';

  @override
  String get statsHerdGroup => 'من هنا';

  @override
  String get statsBreedingGroup => 'البطون والجراء';

  @override
  String get statsMoneyGroup => 'التسليمات';

  @override
  String get statsAtHome => 'حيوانات موجودة';

  @override
  String get statsBreedingStock => 'قطيع التربية';

  @override
  String get statsFemales => 'إناث هنا';

  @override
  String get statsMales => 'ذكور هنا';

  @override
  String get statsEverRecorded => 'كل ما سُجّل';

  @override
  String get statsWhelpings => 'بطون في السجل';

  @override
  String get statsPuppies => 'جراء من بطونك';

  @override
  String statsPuppiesThisYear(String year) {
    return 'جراء وُلدوا في $year';
  }

  @override
  String get statsPlacements => 'تسليمات';

  @override
  String get statsUnnamedCurrency => 'بلا عملة محددة';

  @override
  String statsHandoverCount(String count) {
    return '$count منها مدفوعة';
  }

  @override
  String get statsNoRevenue => 'لا سعر مسجّل';

  @override
  String get statsFooter =>
      'محسوبة من سجلك أنت، على هذا الهاتف. لا شيء منها يخرج عنه.';

  @override
  String get birthdayTitle => 'قريبًا';

  @override
  String get birthdayToday => 'اليوم';

  @override
  String birthdayIn(String days) {
    return 'بعد $days';
  }

  @override
  String birthdayTurning(String name, String years) {
    return '$name يبلغ $years';
  }

  @override
  String get heatCardTitle => 'الشياع القادم';

  @override
  String heatCardWindow(String earliest, String latest) {
    return 'بين $earliest و$latest';
  }

  @override
  String heatCardSteady(String count) {
    return 'محسوب على $count دورات في سجلّها.';
  }

  @override
  String get heatCardThin =>
      'دورة واحدة فقط في السجل، لذلك النافذة واسعة. سجّل تلقيحًا آخر لتضيق.';

  @override
  String heatCardWhelping(String day) {
    return 'التلقيح في هذه النافذة يعني ولادة حول $day.';
  }

  @override
  String get bulkVaccineTitle => 'تحصين جماعي';

  @override
  String bulkVaccineCount(String count) {
    return '$count حيوانًا ستأخذ الجرعة نفسها';
  }

  @override
  String get bulkVaccineAction => 'حصّن البطن كله';

  @override
  String bulkVaccineDone(String count) {
    return 'سُجّلت لـ $count حيوانًا';
  }

  @override
  String get pedigreeTitle => 'شجرة النسب';

  @override
  String litterPuppyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count جرو',
      many: '$count جروًا',
      few: '$count جراء',
      two: 'جروان',
      one: 'جرو واحد',
      zero: 'لا توجد جراء مسجلة',
    );
    return '$_temp0';
  }

  @override
  String get litterPuppiesToRegister => 'عدد الجراء المولودة';

  @override
  String get litterPuppiesHint => 'يُضاف كل جرو إلى حيواناتك باسم الولادة';

  @override
  String get litterNoPuppies => 'لم تُسجَّل جراء لهذه الولادة بعد.';

  @override
  String get litterGone => 'تم حذف هذه الولادة.';

  @override
  String litterDeleteTitle(String name) {
    return 'حذف $name؟';
  }

  @override
  String get litterDeleteBody =>
      'تبقى الجراء ضمن حيواناتك، ويُحذف سجل التزاوج فقط. لا يمكن التراجع عن هذه الخطوة.';

  @override
  String get animalGone => 'تم حذف هذا الحيوان.';

  @override
  String get animalDeathDate => 'تاريخ النفوق';

  @override
  String get animalDam => 'الأم';

  @override
  String get animalSire => 'الأب';

  @override
  String get valueUnknown => 'غير مسجّل';

  @override
  String get recordDeleteTitle => 'حذف هذا السجل؟';

  @override
  String get recordSaveFailed => 'لم يُحفظ هذا السجل. لم يُكتب شيء.';

  @override
  String get recordDeleteFailed => 'لم يُحذف هذا السجل. هو ما زال في مكانه.';

  @override
  String get recordDateBeforeBirth =>
      'هذا التاريخ يسبق تاريخ ميلاد هذا الحيوان.';

  @override
  String get vaccinationAdd => 'تطعيم جديد';

  @override
  String get vaccinationAddTitle => 'تسجيل تطعيم';

  @override
  String get vaccinationEditTitle => 'تعديل التطعيم';

  @override
  String get vaccinationName => 'اللقاح';

  @override
  String get vaccinationNameRequired => 'اسم اللقاح مطلوب';

  @override
  String get vaccinationGiven => 'أُعطي في';

  @override
  String get vaccinationNextDue => 'الجرعة القادمة';

  @override
  String get vaccinationNextDueHint =>
      'أي جرعة تجاوزت موعدها تُعلَّم بأنها متأخرة.';

  @override
  String get doseDueBeforeAdministered =>
      'موعد الجرعة القادمة يسبق تاريخ إعطاء هذه الجرعة.';

  @override
  String get vaccinationOverdue => 'متأخر';

  @override
  String get vaccinationManufacturer => 'الشركة المصنّعة';

  @override
  String get vaccinationBatch => 'رقم الدفعة';

  @override
  String get vaccinationVet => 'الطبيب البيطري';

  @override
  String get vaccinationClinic => 'العيادة';

  @override
  String get vaccinationCertificate => 'رقم الشهادة';

  @override
  String get vaccinationDeleteBody =>
      'يُحذف هذا التطعيم من سجل الحيوان. لا يمكن التراجع عن ذلك.';

  @override
  String get weightAdd => 'وزن جديد';

  @override
  String get weightKg => 'الوزن (كغ)';

  @override
  String get weightColumn => 'الوزن';

  @override
  String get weightRequired => 'أدخل الوزن';

  @override
  String get weightInvalid => 'أدخل وزناً مثل 4.2';

  @override
  String get weightMeasuredOn => 'تاريخ الوزن';

  @override
  String get unitKg => 'كغ';

  @override
  String get unitGrams => 'غ';

  @override
  String get weightNote => 'ملاحظة';

  @override
  String get weightDeleteBody => 'يُحذف هذا الوزن. لا يمكن التراجع عن ذلك.';

  @override
  String get weightAppendOnlyHint =>
      'الأوزان لا تُعدَّل. قياس خاطئ؟ احذفه وسجّل الوزن من جديد.';

  @override
  String get animalSpeciesHelper => 'كلب · قط';

  @override
  String get healthTestAdd => 'فحص جديد';

  @override
  String get healthTestAddTitle => 'تسجيل فحص صحي';

  @override
  String get healthTestEditTitle => 'تعديل الفحص الصحي';

  @override
  String get healthTestType => 'نوع الفحص';

  @override
  String get healthTestTypeRequired => 'اسم الفحص مطلوب';

  @override
  String get healthTestResult => 'النتيجة';

  @override
  String get healthTestResultRequired => 'النتيجة مطلوبة';

  @override
  String get healthTestResultHelper =>
      'كما في الشهادة: Clear · Carrier · Affected';

  @override
  String get healthTestDate => 'تاريخ الفحص';

  @override
  String get healthTestValidUntil => 'صالح حتى';

  @override
  String get certificateExpiresBeforeTest =>
      'تنتهي صلاحية هذه الشهادة قبل يوم الفحص الذي تُصدَر عنه.';

  @override
  String get healthTestBody => 'الجهة المانحة';

  @override
  String get healthTestVerifiedBy => 'التحقق بواسطة';

  @override
  String get healthTestExpired => 'منتهي الصلاحية';

  @override
  String get healthTestDeleteBody =>
      'يُحذف هذا الفحص من سجل الحيوان. لا يمكن التراجع عن ذلك.';

  @override
  String get visitAdd => 'زيارة جديدة';

  @override
  String get visitAddTitle => 'تسجيل زيارة بيطرية';

  @override
  String get visitEditTitle => 'تعديل الزيارة البيطرية';

  @override
  String get visitDate => 'تاريخ الزيارة';

  @override
  String get visitReason => 'السبب';

  @override
  String get visitNoReason => 'استشارة';

  @override
  String get visitOutcome => 'النتيجة';

  @override
  String get visitCost => 'التكلفة';

  @override
  String get visitCostInvalid => 'أدخل مبلغاً مثل 250';

  @override
  String get visitCurrency => 'العملة';

  @override
  String get visitDeleteBody =>
      'تُحذف هذه الزيارة من سجل الحيوان. لا يمكن التراجع عن ذلك.';

  @override
  String get symptomAdd => 'عَرَض جديد';

  @override
  String get symptomAddTitle => 'تسجيل عَرَض';

  @override
  String get symptomEditTitle => 'تعديل العَرَض';

  @override
  String get symptomName => 'العَرَض';

  @override
  String get symptomNameRequired => 'اذكر ما رأيته';

  @override
  String get symptomSeverity => 'الشدّة';

  @override
  String get severityMild => 'خفيف';

  @override
  String get severityModerate => 'متوسط';

  @override
  String get severitySevere => 'شديد';

  @override
  String get symptomObservedOn => 'رُصد في';

  @override
  String get symptomState => 'الحالة';

  @override
  String get symptomOngoing => 'ما زال مستمرًا';

  @override
  String get symptomResolved => 'زائل';

  @override
  String get symptomDeleteBody =>
      'يُحذف هذا العَرَض من سجل الحيوان. لا يمكن التراجع عن ذلك.';

  @override
  String get photoAdd => 'صورة جديدة';

  @override
  String get photoFromGallery => 'اختيار من المعرض';

  @override
  String get photoFromCamera => 'التقاط صورة';

  @override
  String get photoDeleteBody =>
      'تُحذف هذه الصورة من سجل الحيوان ويُحذف ملفها معها. لا يمكن التراجع عن ذلك.';

  @override
  String get photoMissing => 'ليست على هذا الهاتف';

  @override
  String get photoTooLarge => 'هذه الصورة كبيرة جدًا لحفظها';

  @override
  String get photoNotAnImage => 'هذا الملف ليس صورة';

  @override
  String get placementAdd => 'تسليم جديد';

  @override
  String get placementAddTitle => 'تسجيل تسليم';

  @override
  String get placementEditTitle => 'تعديل التسليم';

  @override
  String get placementBuyer => 'المشتري';

  @override
  String get placementNoBuyer => 'المشتري غير مسجَّل';

  @override
  String get placementDate => 'تاريخ التسليم';

  @override
  String get placementPrice => 'الثمن';

  @override
  String get placementPriceInvalid => 'أدخل مبلغًا مثل 2500';

  @override
  String get placementCurrency => 'العملة';

  @override
  String get placementGuarantee => 'شروط الضمان';

  @override
  String get placementDeleteBody =>
      'يُحذف هذا التسليم من سجل الحيوان، ويبقى المشتري في جهات اتصالك. لا يمكن التراجع عن ذلك.';

  @override
  String get buyerAdd => 'مشتَرٍ جديد';

  @override
  String get buyerAddTitle => 'إضافة مشتَرٍ';

  @override
  String get buyerEditTitle => 'تعديل المشتري';

  @override
  String get buyerPhone => 'الهاتف';

  @override
  String get buyerEmail => 'البريد الإلكتروني';

  @override
  String get buyerCountryCode => 'رمز البلد';

  @override
  String get buyersEmptyTitle => 'لا يوجد مشترون بعد';

  @override
  String get buyersEmptyBody =>
      'يُضاف المشتري مع تسليم، أو من هنا قبل التسليم: من اشتريت منه العام الماضي ما زال يطلب شهادة النسب.';

  @override
  String get buyersNoAnimals => 'لا يوجد حيوان مسجَّل لهذا الشخص';

  @override
  String buyerDeleteBody(String name) {
    return 'يُحذف $name من جهات اتصالك. ويبقى سجل التسليم في تاريخ الحيوان دون ذكر المشتري. لا يمكن التراجع عن ذلك.';
  }

  @override
  String get pdfAction => 'ملف PDF';

  @override
  String get pdfFailed => 'تعذّر إنشاء ملف PDF';

  @override
  String get pdfTitle => 'السجل الصحي والنسب';

  @override
  String get pdfLitterTitle => 'سجل ولادة الجراء';

  @override
  String pdfGenerated(String day) {
    return 'أُنشئ في $day';
  }

  @override
  String get pdfPedigree => 'النسب';

  @override
  String get pdfLitters => 'ولادات هذا الحيوان';

  @override
  String get pdfPuppies => 'الجراء';

  @override
  String get pdfPlacement => 'سجل البيع';

  @override
  String get pdfBuyer => 'المشتري';

  @override
  String get pdfPhone => 'الهاتف';

  @override
  String get pdfEmail => 'البريد الإلكتروني';

  @override
  String get pdfPlacedOn => 'تاريخ البيع';

  @override
  String get pdfPrice => 'الثمن';

  @override
  String get pdfGuarantee => 'شروط الضمان';

  @override
  String get pdfChartAxes =>
      'الوزن بالكيلوغرام مقابل العمر بالأشهر. أما الجدول أعلاه فيكتب وزن الجرو الصغير بالغرام.';

  @override
  String get pdfDisclaimer =>
      'أُنشئ هذا الملف على جهاز المربّي دون اتصال بالإنترنت من سجلاته الخاصة، وهو ليس شهادة بيطرية.';

  @override
  String get triageTitle => 'ما الخطوة التالية؟';

  @override
  String get triageActNow => 'تصرّف الآن';

  @override
  String get triageWatch => 'راقب عن قرب';

  @override
  String get triageRoutineVet => 'زيارة بيطرية روتينية';

  @override
  String get triageNothing => 'لا شيء في هذا السجل يستدعي خطوة الآن';

  @override
  String get triageNotDiagnosis =>
      'لا تقرأ سلالة إلا ما كتبته هنا، وهذا ليس تشخيصًا بيطريًا.';

  @override
  String triageNoDoseYoung(String days) {
    return 'لم يُسجَّل أي تلقيح والعمر $days';
  }

  @override
  String triageDoseOverdue(String name, String days) {
    return '$name كان مستحقًا منذ $days';
  }

  @override
  String triageDoseDueSoon(String name, String days) {
    return '$name مستحق خلال $days';
  }

  @override
  String triageDoseToday(String what) {
    return '$what مستحق اليوم';
  }

  @override
  String triageWeightLossPuppy(String percent) {
    return 'فقد الحيوان الصغير $percent% من وزنه منذ آخر وزن';
  }

  @override
  String triageWeightLoss(String percent) {
    return 'انخفض الوزن $percent% منذ آخر وزن';
  }

  @override
  String triageNoGainPuppy(String days) {
    return 'زيادة الوزن شبه معدومة خلال $days';
  }

  @override
  String triageTestFlagged(String name) {
    return 'لم تعد نتيجة $name سالمة';
  }

  @override
  String triageTestExpired(String name, String days) {
    return 'انتهت شهادة $name منذ $days';
  }

  @override
  String triageWhelpingOverdue(String name, String days) {
    return '$name: تجاوزت الولادة التاريخ المتوقع بـ $days';
  }

  @override
  String triageSevereSymptom(String name) {
    return '$name سُجِّل بدرجة شديدة وما زال مستمرًا';
  }

  @override
  String triageSymptomUnresolved(String name, String days) {
    return 'ما زال $name مستمرًا بعد $days من رصده';
  }

  @override
  String get agendaTitle => 'تلقيحات يجب حجزها';

  @override
  String daysSingle(String n) {
    return '$n يومًا';
  }

  @override
  String daysDual(String n) {
    return '$n يومين';
  }

  @override
  String get onboardingSlide1Title => 'سجل واحد لكل حيوان';

  @override
  String get onboardingSlide1Body =>
      'كلب أو قطة، سلالته، تاريخ ميلاده، ومن أين جاء. الأول لا يأخذ دقيقة.';

  @override
  String get onboardingSlide2Title => 'صحته، بالترتيب';

  @override
  String get onboardingSlide2Body =>
      'التطعيمات بموعد جرعتها القادمة، الأوزان، الفحوصات، والزيارات البيطرية. سالالة يحجز التذكير عنك.';

  @override
  String get onboardingSlide3Title => 'قصته تسافر معه';

  @override
  String get onboardingSlide3Body =>
      'ملف PDF أو جدول للمشتري، وحزمة ZIP واحدة تحمل كل سجل وصورة إلى هاتف جديد.';

  @override
  String get onboardingSkip => 'تخطٍّ';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingStart => 'أضف أول حيوان';

  @override
  String get settingsOnboarding => 'أعد عرض المقدمة';

  @override
  String get settingsHelp => 'المساعدة';

  @override
  String get settingsRate => 'قيّم سالالة';

  @override
  String get settingsRateBody => 'يفتح بطاقة التقييم من المتجر.';

  @override
  String get settingsWhatsNew => 'ما الجديد';

  @override
  String get settingsPrivacy => 'الخصوصية';

  @override
  String get settingsTerms => 'شروط الاستخدام';

  @override
  String get settingsLicenses => 'رخص البرمجيات المفتوحة';

  @override
  String get rateUnavailable => 'هذا الهاتف لا يستطيع عرض بطاقة التقييم الآن.';

  @override
  String get aboutTitle => 'حول سالالة';

  @override
  String get aboutBody =>
      'دفتر محلي لمربٍّ صغير. لا حساب، لا خادم، لا تتبع — السجلات تسكن هذا الهاتف ولا تخرج إلا بيدك.';

  @override
  String aboutVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get privacyTitle => 'الخصوصية';

  @override
  String get privacyIntro =>
      'سالالة تحتفظ بنوع واحد من البيانات: ما كتبته عن حيواناتك. هذه الصفحة تقول أين تسكن وماذا يمكن أن يُخرجها من هذا الهاتف.';

  @override
  String get privacyStoredHeading => 'ما يُخزَّن';

  @override
  String get privacyStoredBody =>
      'كل حيوان، جرعة، وزن، فحص، زيارة، عرض، تسليم وجهة اتصال — والصور التي أرفقتها — في قاعدة بيانات ومجلد صور داخل مساحة التطبيق الخاصة. أندرويد يمنع التطبيقات الأخرى من الوصول إلى ذلك المجلد، والملفات غير مشفّرة بعد ذلك.';

  @override
  String get privacyBackupHeading => 'ما يخرج من هذا الهاتف';

  @override
  String get privacyBackupBody =>
      'فقط ما تصدّره: حزمة ZIP فيها كل سجل وصورة، جدول CSV واحد، أو PDF لحيوان واحد. كل ملف يذهب حيث ترسله، وبالتالي الحزمة تحمل أسماء مشتريك وأرقام هواتفهم — عامل الملف كما تعامل الورق الذي يحل مكانه. شغّل قفل التطبيق إن كان الهاتف يسافر.';

  @override
  String get privacyCollectHeading => 'ما يُجمع عنك';

  @override
  String get privacyCollectBody =>
      'لا شيء. لا تحليلات، لا تقارير أعطال، لا معرّف إعلاني، ولا اتصال شبكي في هذا التطبيق.';

  @override
  String get privacyRemoveHeading => 'كيف تمسحه';

  @override
  String get privacyRemoveBody =>
      'إزالة التطبيق تزيل قاعدة البيانات ومجلد الصور معه. لا توجد نسخة في مكان آخر، فصدّر حزمة أولًا إن كانت السجلات تهمك — وتذكّر أن رقم قفل التطبيق لا يُستعاد أيضًا.';

  @override
  String get termsTitle => 'شروط الاستخدام';

  @override
  String get termsUseHeading => 'لماذا هذا التطبيق';

  @override
  String get termsUseBody =>
      'للاحتفاظ بسجلاتك عن الحيوانات التي في رعايتك. رخصة واحدة لكل شخص؛ ثبّته على الهواتف التي تستخدمها.';

  @override
  String get termsDataHeading => 'بياناتك لك';

  @override
  String get termsDataBody =>
      'لا نحتفظ بنسخة منها ولا نستطيع استعادتها. النسخ الاحتياطي مسؤوليتك، وزر التصدير في الإعدادات هو الآلية كلها.';

  @override
  String get termsAdviceHeading => 'ليس استشارة بيطرية';

  @override
  String get termsAdviceBody =>
      'سالالة يعيد ما كتبته ويجري حسابًا على التواريخ والأوزان. لا يشخّص، والتذكير موعد في تقويم لا رأي سريري. اتصل بطبيب بيطري.';

  @override
  String get termsWarrantyHeading => 'بلا ضمان';

  @override
  String get termsWarrantyBody =>
      'يُقدَّم التطبيق كما هو. وفي حدود ما يسمح به القانون، لا تُقبل مسؤولية عن سجل ضائع أو تذكير فائت أو قرار اتُّخذ بناء على ما هو مكتوب هنا.';

  @override
  String get helpTitle => 'المساعدة';

  @override
  String get helpQ1 => 'كيف أنسخ احتياطيًا؟';

  @override
  String get helpA1 =>
      'الإعدادات، ثم تصدير السجلات. ملف ZIP يحمل كل صف وكل صورة؛ أرسله لنفسك واحتفظ به. الاستعادة تقرأ الملف نفسه على أي هاتف.';

  @override
  String get helpQ2 => 'نسيت رقمي السري';

  @override
  String get helpA2 =>
      'لا يُستعاد، لأن المحفوظ بصمة له فقط. إزالة التطبيق تمسح القفل والدفتر معه، فإن كان لديك حزمة حديثة استعدها بعد ذلك.';

  @override
  String get helpQ3 => 'فقدت هاتفي';

  @override
  String get helpA3 =>
      'لا شيء على خادم، فلا شيء يمكن إعادته. حزمة صدّرتها سابقًا تعيد الدفتر على هاتف جديد؛ وحزمة لم تصدّرها ضاعت.';

  @override
  String get helpQ4 => 'من أين تأتي التذكيرات؟';

  @override
  String get helpA4 =>
      'من تواريخ الجرعة القادمة التي كتبتها. سالالة يحجز تنبيهًا قبل شهر وتنبيهًا في الصباح نفسه؛ وإن كانت الإشعارات موقوفة للتطبيق، تبقى التواريخ ظاهرة في أجندة القطيع.';

  @override
  String get helpQ5 => 'لماذا تقول صورة إنها ليست على هذا الهاتف؟';

  @override
  String get helpA5 =>
      'الصف بقي والملف لم يبقَ — غالبًا بعد استعادة من حزمة بلا صور. إضافة الصورة مرة أخرى تكفي.';

  @override
  String get helpQ6 => 'هل أستطيع تسليم سجل الحيوان؟';

  @override
  String get helpA6 =>
      'نعم. افتح الحيوان وصدّر ملف PDF: مستند ثابت يحتفظ به المشتري دون هذا التطبيق. والتسليم نفسه يُسجَّل في الصفحة نفسها.';

  @override
  String get helpQ7 => 'ما اللغات المتوفرة؟';

  @override
  String get helpA7 =>
      'الإنجليزية، العربية، الفرنسية، الألمانية، الإسبانية، الإيطالية، البرتغالية، الهولندية. الإعدادات ثم اللغة — التغيير يُطبَّق فورًا.';

  @override
  String get helpQ8 => 'هناك خطأ في التطبيق';

  @override
  String get helpA8 =>
      'اكتب لنا وقل ماذا كنت تفعل حين حدث. الإصدار في صفحة «حول».';

  @override
  String get helpContactHeading => 'اكتب لنا';

  @override
  String get whatsNewTitle => 'ما الجديد';

  @override
  String get whatsNew1 =>
      'صور على بطاقات القطيع، وتصميم أوسع وأدفأ في كل الشاشات.';

  @override
  String get whatsNew2 => 'نقرة التذكير تفتح الحيوان الذي يخصّه.';

  @override
  String get whatsNew3 => 'تصدير الجدول صار بلغة التطبيق التي تقرأها.';

  @override
  String get whatsNew4 =>
      'خمس لغات إضافية: الألمانية، الإسبانية، الإيطالية، البرتغالية، الهولندية.';

  @override
  String get whatsNew5 =>
      'صفحات الخصوصية والشروط والمساعدة، وزر تقييم في الإعدادات.';

  @override
  String daysPlural(String n) {
    return '$n أيام';
  }
}

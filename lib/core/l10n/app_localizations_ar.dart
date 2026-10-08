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
  String get navSettings => 'الإعدادات';

  @override
  String get homeEmptyTitle => 'لا توجد حيوانات بعد';

  @override
  String get homeEmptyBody =>
      'أضف كلبك أو قطتك الأول لتبدأ سجل الصحة والأنساب.';

  @override
  String get homeAddAnimal => 'إضافة حيوان';

  @override
  String get homeBreedingStock => 'حيوانات التربية';

  @override
  String get homeAllAnimals => 'كل الحيوانات';

  @override
  String get homeSearchHint => 'ابحث بالاسم أو الرقم أو الشريحة';

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
  String get animalStatus => 'الحالة';

  @override
  String get animalMicrochip => 'رقم الشريحة';

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
  String get animalDeleteBody =>
      'سيُحذف معها التطعيمات وفحوصات الصحة والأوزان والزيارات البيطرية والأعراض. لا يمكن التراجع عن هذه الخطوة.';

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
  String get recordsPlacements => 'التسليم';

  @override
  String get recordsEmpty => 'لا يوجد سجل بعد.';

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
  String get settingsAppLock => 'قفل التطبيق';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsLanguageSystem => 'لغة النظام';

  @override
  String get settingsAbout => 'حول التطبيق';

  @override
  String get settingsBuildTag => 'رقم البناء';

  @override
  String get settingsOfflineNote =>
      'كل شيء محفوظ على جهازك. بلا حساب، بلا خادم، بلا تتبع.';

  @override
  String get settingsExport => 'تصدير السجلات';

  @override
  String get settingsExportBody => 'ملف JSON واحد فيه كل سجلات هذا الهاتف';

  @override
  String get settingsImport => 'استرجاع من حزمة';

  @override
  String get settingsImportBody => 'قراءة حزمة وإرجاعها إلى هذا الهاتف';

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
  String litterExpected(String date) {
    return 'الولادة المتوقعة: $date';
  }

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
  String reminderHeadsUpBody(String what, String dueDay) {
    return 'تنبيه: $what مستحق في $dueDay';
  }

  @override
  String reminderDueBody(String what) {
    return '$what مستحق اليوم';
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
  String daysPlural(String n) {
    return '$n أيام';
  }
}

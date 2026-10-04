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
      'سيُحذف معها التطعيمات وفحوصات الصحة والأوزان والزيارات البيطرية. لا يمكن التراجع عن هذه الخطوة.';

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
  String get settingsExportSoon => 'تصدير PDF و JSON يأتي في المرحلة الثانية.';

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
  String get weightNote => 'ملاحظة';

  @override
  String get weightDeleteBody => 'يُحذف هذا الوزن. لا يمكن التراجع عن ذلك.';
}

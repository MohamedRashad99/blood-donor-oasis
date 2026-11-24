import '../constants/app_constants.dart';

/// Thank-you + result message sent by an admin to a donor (by hand, on WhatsApp).
/// Wording follows the campaign lines "نقطة دم منك تكون سبب في إنسان يرجع لأهله".
class ThankYouMessage {
  static String build({required String donorName, String bloodType = ''}) {
    final blood = bloodType.isNotEmpty ? '\nفصيلة دمك: $bloodType' : '';
    return '''الأخ الفاضل / $donorName،
نقطة الدم اللي اتبرعت بيها ممكن تبقى سبب في إنسان يرجع لأهله، وأم تطمن على ابنها.
﴿وَمَنْ أَحْيَاهَا فَكَأَنَّمَا أَحْيَا النَّاسَ جَمِيعًا﴾
بنشكرك من قلبنا، وربنا يجعله في ميزان حسناتك ويديك الصحة والعافية.$blood
نتيجة التحاليل مرفقة مع الرسالة.
${AppConstants.orgName}
${AppConstants.slogan}''';
  }
}

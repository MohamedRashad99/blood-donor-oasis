import '../constants/app_constants.dart';

/// Thank-you message sent by an admin to a donor on WhatsApp (about 10 lines).
/// Wording follows the campaign line "نقطة دم منك تكون سبب في إنسان يرجع لأهله".
class ThankYouMessage {
  static String build({required String donorName, String bloodType = ''}) {
    final blood = bloodType.isNotEmpty ? ' (فصيلة دمك: $bloodType)' : '';
    return '''🩸 *شكراً من القلب* 🩸

الأخ الفاضل / *$donorName*$blood

نقطة الدم اللي اتبرعت بيها ممكن تبقى سبب في إنسان يرجع لأهله، وأم تطمن على ابنها.
﴿وَمَنْ أَحْيَاهَا فَكَأَنَّمَا أَحْيَا النَّاسَ جَمِيعًا﴾
ربنا يجعله في ميزان حسناتك ويديك الصحة والعافية ❤️

📎 نتيجة التحاليل مرفقة مع الرسالة.

_رسالة من ${AppConstants.orgName} عبر المنصة الرقمية_
*${AppConstants.slogan}*''';
  }
}

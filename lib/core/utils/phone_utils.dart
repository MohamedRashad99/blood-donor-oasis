import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';

class PhoneUtils {
  /// Validates Egyptian mobile or landline numbers
  static bool isValidEgyptianPhone(String? input) {
    if (input == null || input.trim().isEmpty) return false;
    final cleaned = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Mobile: 010, 011, 012, 015 followed by 8 digits (total 11 digits)
    final mobileRegex = RegExp(r'^(01[0125][0-9]{8})$');
    if (mobileRegex.hasMatch(cleaned)) return true;

    // International Egyptian mobile: +201... or 00201... or 201...
    final intlMobileRegex = RegExp(r'^(\+?20|0020)?(1[0125][0-9]{8})$');
    if (intlMobileRegex.hasMatch(cleaned)) return true;

    // Landline with code (e.g., 050xxxxxxx or 0050xxxxxxx or 02xxxxxxx)
    final landlineRegex = RegExp(r'^(00|0)?[2-9][0-9]{7,8}$');
    if (landlineRegex.hasMatch(cleaned)) return true;

    return false;
  }

  /// Normalizes phone number into international format for WhatsApp (e.g. 201069146914)
  static String? normalizeForWhatsApp(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    var cleaned = input.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    // Remove leading zeros if more than 2
    if (cleaned.startsWith('0020')) {
      cleaned = cleaned.substring(2); // 201xxxxxxxxx
    } else if (cleaned.startsWith('00')) {
      cleaned = '20${cleaned.substring(2)}';
    } else if (cleaned.startsWith('01') && cleaned.length == 11) {
      cleaned = '20${cleaned.substring(1)}';
    } else if (cleaned.startsWith('1') && cleaned.length == 10) {
      cleaned = '20$cleaned';
    } else if (!cleaned.startsWith('20')) {
      // Landline or other local number starting with 0
      if (cleaned.startsWith('0')) {
        cleaned = '20${cleaned.substring(1)}';
      } else {
        cleaned = '20$cleaned';
      }
    }

    return cleaned;
  }

  /// Launch telephone call directly
  static Future<bool> makeCall(String phoneNumber) async {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }

  /// Prepare and open WhatsApp conversation with donor
  static Future<bool> openWhatsApp({
    required String phoneNumber,
    required String donorName,
    String? bloodType,
  }) async {
    final normalized = normalizeForWhatsApp(phoneNumber);
    if (normalized == null || normalized.isEmpty) return false;

    final bloodInfo = bloodType != null && bloodType.isNotEmpty ? ' (فصيلة: $bloodType)' : '';
    final message = '''السلام عليكم ورحمة الله وبركاته،
الأخ الفاضل / $donorName$bloodInfo
نتواصل معكم من "${AppConstants.orgName}"
بخصوص مبادرة التبرع بالدم: "${AppConstants.slogan}".
نسأل الله أن يبارك في صحتكم وعطائكم.''';

    final uri = Uri.parse('https://wa.me/$normalized?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Opens WhatsApp with [text] already filled in. Goes straight to the
  /// donor's chat when the number is valid, otherwise lets the user pick a chat.
  static Future<bool> openWhatsAppText({
    required String phoneNumber,
    required String text,
  }) async {
    final normalized = normalizeForWhatsApp(phoneNumber);
    final target = (normalized == null || normalized.isEmpty) ? '' : normalized;
    final uri = Uri.parse('https://wa.me/$target?text=${Uri.encodeComponent(text)}');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

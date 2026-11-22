import 'package:flutter_test/flutter_test.dart';
import 'package:blood_donor_oasis/core/constants/app_constants.dart';
import 'package:blood_donor_oasis/core/utils/phone_utils.dart';
import 'package:blood_donor_oasis/models/donor.dart';
import 'package:blood_donor_oasis/models/campaign.dart';
import 'package:blood_donor_oasis/models/donation_record.dart';
import 'package:blood_donor_oasis/repositories/donor_repository.dart';

void main() {
  group('Branding and Constants Tests', () {
    test('Verify official organization branding constants', () {
      expect(AppConstants.orgName, 'جمعية كفالة اليتيم بأبو رفاعي');
      expect(AppConstants.orgLocation, 'مسجد أبو رفاعي – محلة دمنة – محافظة الدقهلية – مصر');
      expect(AppConstants.slogan, 'نقطة دم تساوي حياة');
      expect(AppConstants.supervisor, 'تحت إشراف : المهندس محمد رشاد');
    });

    test('Verify all 8 standard blood types exist', () {
      expect(AppConstants.bloodTypes, containsAll(['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']));
      expect(AppConstants.bloodTypes.length, 8);
    });
  });

  group('Egyptian Phone Number & WhatsApp Validation Tests', () {
    test('Valid Egyptian mobile numbers (010, 011, 012, 015)', () {
      expect(PhoneUtils.isValidEgyptianPhone('01069146914'), isTrue);
      expect(PhoneUtils.isValidEgyptianPhone('01159424482'), isTrue);
      expect(PhoneUtils.isValidEgyptianPhone('01221689967'), isTrue);
      expect(PhoneUtils.isValidEgyptianPhone('01503316340'), isTrue);
    });

    test('Valid Egyptian landlines (Dakahlia 050 / 0050)', () {
      expect(PhoneUtils.isValidEgyptianPhone('00502153321'), isTrue);
      expect(PhoneUtils.isValidEgyptianPhone('0502153321'), isTrue);
    });

    test('Invalid phone numbers rejected', () {
      expect(PhoneUtils.isValidEgyptianPhone('12345'), isFalse);
      expect(PhoneUtils.isValidEgyptianPhone('abcdef'), isFalse);
      expect(PhoneUtils.isValidEgyptianPhone(''), isFalse);
      expect(PhoneUtils.isValidEgyptianPhone(null), isFalse);
    });

    test('Normalize Egyptian numbers for WhatsApp', () {
      expect(PhoneUtils.normalizeForWhatsApp('01069146914'), '201069146914');
      expect(PhoneUtils.normalizeForWhatsApp('+201069146914'), '201069146914');
      expect(PhoneUtils.normalizeForWhatsApp('00201069146914'), '201069146914');
    });
  });

  group('Donor Model and CSV Parsing Tests', () {
    test('CSV parsing preserves Arabic names, IDs and phone numbers', () {
      const sampleCsv = '''id,name,bloodType,phone,governorate,city,address,age,gender,available,lastDonationDate,notes,createdAt,updatedAt
r002,احمد يسري حامد البدوي,O+,01069146914,الدقهلية,أبو رفاعي,,,,true,,,2026-06-18T20:09:06.607Z,2026-06-18T22:29:53.211Z
r004,ابراهيم حسانين الدسوقي الحسانين,O+,01068717118,الدقهلية,أبو رفاعي,,,,true,,رقم التبرع: E403026500766,2026-06-18T20:09:06.607Z,2026-06-18T22:29:53.293Z''';

      final donors = LocalDonorRepository.parseCsvToDonors(sampleCsv);
      expect(donors.length, 2);

      expect(donors[0].id, 'r002');
      expect(donors[0].name, 'احمد يسري حامد البدوي');
      expect(donors[0].bloodType, 'O+');
      expect(donors[0].phone, '01069146914');
      expect(donors[0].city, 'أبو رفاعي');
      expect(donors[0].available, isTrue);

      expect(donors[1].id, 'r004');
      expect(donors[1].name, 'ابراهيم حسانين الدسوقي الحسانين');
      expect(donors[1].notes, 'رقم التبرع: E403026500766');
    });

    test('Donor toCsvRow exports complete row with Arabic values', () {
      final donor = Donor(
        id: 'r002',
        name: 'احمد يسري حامد البدوي',
        bloodType: 'O+',
        phone: '01069146914',
        city: 'أبو رفاعي',
        available: true,
      );

      final row = donor.toCsvRow();
      expect(row[0], 'r002');
      expect(row[1], 'احمد يسري حامد البدوي');
      expect(row[2], 'O+');
      expect(row[3], '01069146914');
      expect(row[9], 'متاح');
    });
  });

  group('Campaign & Donation Record Tests', () {
    test('Campaign model calculations and serialization', () {
      final campaign = Campaign(
        id: 'camp_001',
        title: 'حملة مسجد أبو رفاعي الكبرى',
        date: '2026-05-17',
        participantDonorIds: ['r001', 'r002', 'r003'],
      );

      expect(campaign.participantCount, 3);
      expect(campaign.organizer, AppConstants.orgName);
      expect(campaign.status, AppConstants.campaignStatusUpcoming);

      final json = campaign.toJson();
      final fromJson = Campaign.fromJson(json);
      expect(fromJson.title, campaign.title);
      expect(fromJson.participantCount, 3);
    });

    test('DonationRecord model serialization', () {
      final record = DonationRecord(
        id: 'don_001',
        donorId: 'r046',
        donorName: 'اشرف محمد محمد عوضين',
        bloodType: 'A+',
        donationDate: '2026-05-17',
        notes: 'رقم كيس الدم: E403026500808',
      );

      expect(record.donorName, 'اشرف محمد محمد عوضين');
      expect(record.bloodType, 'A+');
      expect(record.status, AppConstants.donationStatusSuccessful);

      final json = record.toJson();
      final restored = DonationRecord.fromJson(json);
      expect(restored.id, 'don_001');
      expect(restored.notes, 'رقم كيس الدم: E403026500808');
    });
  });
}

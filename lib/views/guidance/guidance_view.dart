import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

/// دليل المشرفين: كيف نرد على من يطلب دماً ومن يستحق الدعم.
class GuidanceView extends StatelessWidget {
  const GuidanceView({super.key});

  static const List<String> _eligible = [
    'ظروف صعبة فعلاً: دخل محدود وظروف معيشية قاسية.',
    'طفل محتاج أكياس لا يغطيها التأمين الصحي المدرسي: نحاول نغطيها من عندنا.',
    'محتاج عدد كبير من الأكياس وظروفه صعبة: نساعده بالتواصل مع المعارف والأقارب والأصدقاء ومساعدة أهل الخير.',
  ];

  static const List<String> _notEligible = [
    'حالة بتتعالج في مستشفى خاص كبير ومكلف وبتدفع مبالغ كبيرة.',
    'حالة مقتدرة وبتروح مستشفى كبير: لا نقول لها إننا محتاجين دم لها.',
  ];

  static const List<String> _checklist = [
    'هل ظروف الأسرة صعبة (دخل محدود / معيشة صعبة)؟',
    'أين يتم العلاج؟ هل هو مستشفى خاص كبير ومكلف؟',
    'هل المريض طفل؟ وهل التأمين الصحي المدرسي يغطي الأكياس؟',
    'كم كيس مطلوب؟ وهل العدد كبير؟',
    'حصة الجمعية 30% فقط من أكياس كل حملة: راجع الرقم قبل الوعد.',
  ];

  static const List<_Reply> _replies = [
    _Reply(
      'حالة مستحقة',
      'أهلاً بحضرتك، ربنا يشفيه ويقومه بالسلامة. ظروفكم وصلت لنا وهنعمل اللي نقدر عليه إن شاء الله. ابعتلنا عدد الأكياس المطلوب ومكان العلاج.',
    ),
    _Reply(
      'حالة مقتدرة / مستشفى خاص كبير',
      'ربنا يشفيه ويعافيه. للأسف أكياس الجمعية محدودة وبنخصصها للحالات اللي ظروفها صعبة، وحضرتك قادر وبتتعالج في مستشفى كبير، فمش هنقدر نوفرها لحضرتك. ربنا يسهل أمركم.',
    ),
    _Reply(
      'عدد كبير من الأكياس',
      'ربنا يشفيه. العدد كبير ومش هيغطيه نصيب الجمعية لوحده، فهنساعدكم بالتواصل مع المعارف والأقارب والأصدقاء وأهل الخير في المنطقة عشان نكمل العدد المطلوب.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          icon: Icons.volunteer_activism_rounded,
          title: 'الهدف',
          child: const Text(
            'نوصّل الدم لمن يحتاجه فعلاً. هذا الدليل يساعدك تعرف من يستحق الدعم وكيف ترد على السائل بأدب ووضوح.',
            style: TextStyle(fontSize: 13, height: 1.7),
          ),
        ),
        _card(
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          title: 'من يستحق الدعم',
          child: _bullets(_eligible, Icons.check_rounded, AppColors.success),
        ),
        _card(
          icon: Icons.cancel_rounded,
          color: AppColors.error,
          title: 'من لا نوفر له الدم',
          child: _bullets(_notEligible, Icons.close_rounded, AppColors.error),
        ),
        _card(
          icon: Icons.bloodtype_rounded,
          title: 'حصة الجمعية من كل حملة',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الجمعية تحصل على 30% فقط من أكياس كل حملة. أمثلة:',
                style: TextStyle(fontSize: 13, height: 1.7),
              ),
              const SizedBox(height: 8),
              Table(
                border: TableBorder.all(color: AppColors.border),
                children: const [
                  TableRow(
                    decoration: BoxDecoration(color: AppColors.redSoftBg),
                    children: [
                      _Cell('أكياس الحملة', bold: true),
                      _Cell('حصة الجمعية (30%)', bold: true),
                    ],
                  ),
                  TableRow(children: [_Cell('40'), _Cell('12')]),
                  TableRow(children: [_Cell('45'), _Cell('حوالي 14 (13.5)')]),
                  TableRow(children: [_Cell('50'), _Cell('15')]),
                ],
              ),
            ],
          ),
        ),
        _card(
          icon: Icons.fact_check_rounded,
          title: 'قائمة فحص سريعة قبل الرد',
          child: _bullets(_checklist, Icons.check_box_outline_blank_rounded, AppColors.primaryRed),
        ),
        _card(
          icon: Icons.chat_rounded,
          title: 'ردود مقترحة (اضغط للنسخ)',
          child: Column(
            children: [for (final r in _replies) _replyTile(context, r)],
          ),
        ),
      ],
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required Widget child,
    Color color = AppColors.primaryRed,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _bullets(List<String> items, IconData icon, Color color) {
    return Column(
      children: [
        for (final t in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(t, style: const TextStyle(fontSize: 13, height: 1.6))),
              ],
            ),
          ),
      ],
    );
  }

  Widget _replyTile(BuildContext context, _Reply r) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: r.text));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم نسخ الرد'), backgroundColor: AppColors.success),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(r.title,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryRedDark)),
                  ),
                  const Icon(Icons.copy_rounded, size: 16, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 6),
              Text(r.text, style: const TextStyle(fontSize: 13, height: 1.7)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Reply {
  final String title;
  final String text;
  const _Reply(this.title, this.text);
}

class _Cell extends StatelessWidget {
  final String text;
  final bool bold;
  const _Cell(this.text, {this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(10),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
      );
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/image_compress.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/utils/share_utils.dart';
import '../../core/utils/thank_you_message.dart';
import '../../models/donor.dart';
import '../../models/donor_file.dart';
import '../../repositories/donor_files_repository.dart';

/// "نتيجة التحاليل": result images of a donor, with thank-you message and share.
class DonorFilesSection extends StatefulWidget {
  final Donor donor;
  const DonorFilesSection({super.key, required this.donor});

  @override
  State<DonorFilesSection> createState() => _DonorFilesSectionState();
}

class _DonorFilesSectionState extends State<DonorFilesSection> {
  late final TextEditingController _message;
  List<DonorFile> _files = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  DonorFilesRepository get _repo => context.read<DonorFilesRepository>();

  @override
  void initState() {
    super.initState();
    _message = TextEditingController(
      text: ThankYouMessage.build(
        donorName: widget.donor.name,
        bloodType: widget.donor.bloodType,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final files = await _repo.listForDonor(widget.donor.id);
      if (!mounted) return;
      setState(() {
        _files = files;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل الملفات. تأكد من الاتصال وأنك مسجل بحساب مشرف.';
      });
    }
  }

  void _snack(String text, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ));
  }

  Future<void> _pick() async {
    setState(() => _busy = true);
    try {
      final picked = await FilePicker.pickFiles(type: FileType.image);
      if (picked.isEmpty) return;
      final bytes = await picked.first.readAsBytes();
      final out = ImageCompress.compress(bytes);
      if (out == null) {
        _snack('الملف ليس صورة صالحة أو كبير جداً', ok: false);
        return;
      }
      final name =
          'result_${widget.donor.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saved = await _repo.add(
        donorId: widget.donor.id,
        fileName: name,
        mimeType: out.mimeType,
        bytes: out.bytes,
      );
      if (!mounted) return;
      setState(() => _files = [saved, ..._files]);
      _snack('تم حفظ الصورة');
    } catch (_) {
      _snack('تعذر حفظ الصورة', ok: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(DonorFile f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الصورة'),
        content: const Text('هل تريد حذف هذه الصورة نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.delete(f.id);
      if (!mounted) return;
      setState(() => _files = _files.where((x) => x.id != f.id).toList());
    } catch (_) {
      _snack('تعذر الحذف', ok: false);
    }
  }

  Future<void> _share(DonorFile f) async {
    final done = await ShareUtils.shareResult(file: f, message: _message.text);
    if (!done) {
      await Clipboard.setData(ClipboardData(text: _message.text));
      _snack('المشاركة غير متاحة على هذا الجهاز. تم نسخ نص الرسالة، أرفق الصورة يدوياً.', ok: false);
    }
  }

  Future<void> _sendWhatsApp() async {
    final ok = await PhoneUtils.openWhatsAppText(
      phoneNumber: widget.donor.phone,
      text: _message.text,
    );
    if (!ok) {
      await Clipboard.setData(ClipboardData(text: _message.text));
      _snack('تعذر فتح واتساب. تم نسخ نص الرسالة.', ok: false);
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _message.text));
    _snack('تم نسخ الرسالة');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('نتيجة التحاليل والرسالة',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pick,
              icon: _busy
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('إضافة صورة'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: _loading
              ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
              : _error != null
                  ? Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.error))
                  : _files.isEmpty
                      ? const Text('لا توجد صور محفوظة لهذا المتبرع بعد.',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted))
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [for (final f in _files) _thumb(f)],
                        ),
        ),
        const SizedBox(height: 12),
        const Text('نص رسالة الشكر (يمكن تعديله قبل المشاركة)',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: _message,
          maxLines: 8,
          minLines: 5,
          style: const TextStyle(fontSize: 13, height: 1.6),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.whatsapp,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _sendWhatsApp,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('إرسال الرسالة على واتساب'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _copy,
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('نسخ'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text('زر واتساب يفتح محادثة المتبرع بالرسالة جاهزة. لو عايز ترسل الصورة معها، اضغط "مشاركة" تحت الصورة، أو أرفقها بعد فتح المحادثة.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        const Text('اضغط "مشاركة" تحت أي صورة، وسيفتح الهاتف قائمة المشاركة بالرسالة والصورة معاً لتختار واتساب والمتبرع.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _thumb(DonorFile f) {
    return SizedBox(
      width: 150,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => Dialog(child: InteractiveViewer(child: Image.memory(f.bytes))),
              ),
              child: Image.memory(f.bytes, width: 150, height: 110, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.whatsapp,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  ),
                  onPressed: () => _share(f),
                  icon: const Icon(Icons.share_rounded, size: 14),
                  label: const Text('مشاركة', style: TextStyle(fontSize: 12)),
                ),
              ),
              IconButton(
                tooltip: 'حذف',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                onPressed: () => _delete(f),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

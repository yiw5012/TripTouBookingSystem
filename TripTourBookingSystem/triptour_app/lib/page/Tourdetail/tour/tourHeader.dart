import 'package:flutter/material.dart';
import 'tourVideoPlayer.dart';
import 'package:file_saver/file_saver.dart';

class TourHeader extends StatelessWidget {
  final Map<String, dynamic> tour;
  final List<dynamic> images;
  final String videoUrl;
  final String pdfUrl;

  final int tourId;
  final double averageRating;
  final int reviewCount;

  const TourHeader({
    super.key,
    required this.tour,
    required this.images,
    required this.videoUrl,
    required this.pdfUrl,
    required this.tourId,
    required this.averageRating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [buildTourImage(context), buildTourSummary(context)],
    );
  }

  // ==========================================================
  // IMAGE + VIDEO
  // ==========================================================

  Widget buildTourImage(BuildContext context) {
    final String currentVideoUrl = videoUrl.trim();
    final bool hasVideo = currentVideoUrl.isNotEmpty;
    final bool hasImages = images.isNotEmpty;

    // หากไม่มีทั้งรูปภาพและวิดีโอ แสดงพื้นที่ว่าง
    if (!hasImages && !hasVideo) {
      return Container(
        width: double.infinity,
        height: 230,
        color: const Color(0xFFE0E0E0),
        child: const Center(
          child: Icon(Icons.image, size: 70, color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 230,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // PageView ใช้เลื่อนดูเฉพาะรูปภาพ ไม่รวมวิดีโอเป็นหน้าสุดท้าย
          if (hasImages)
            PageView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) {
                final String imageUrl =
                    images[index]['image']?.toString() ?? '';

                if (imageUrl.isEmpty) {
                  return Container(
                    color: const Color(0xFFE0E0E0),
                    child: const Center(
                      child: Icon(Icons.image, size: 70, color: Colors.grey),
                    ),
                  );
                }

                return Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 230,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFE0E0E0),
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                );
              },
            )
          else
            Container(
              color: const Color(0xFFE0E0E0),
              child: const Center(
                child: Icon(Icons.movie, size: 70, color: Colors.grey),
              ),
            ),

          // ปุ่มเล่นวิดีโออยู่มุมขวาล่างของรูป
          if (hasVideo)
            Positioned(
              right: 12,
              bottom: 12,
              child: Material(
                color: Colors.black.withOpacity(0.72),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _showVideoDialog(context, currentVideoUrl),
                  child: const SizedBox(
                    width: 54,
                    height: 54,
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // เปิดวิดีโอในหน้าต่าง Popup โดยไม่ต้องเลื่อนไปหน้าสุดท้ายของรูป
  void _showVideoDialog(BuildContext context, String currentVideoUrl) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'ปิดวิดีโอ',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: TourVideoPlayer(videoUrl: currentVideoUrl),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // SUMMARY
  // ==========================================================

  Widget buildTourSummary(BuildContext context) {
    final String tourName = tour['tour_name']?.toString() ?? 'ไม่มีชื่อทัวร์';

    final String tourIdText = tour['tour_id']?.toString() ?? '-';

    final String country = tour['country_name_th']?.toString() ?? '-';

    final String type = tour['type']?.toString() ?? '-';

    final String duration = tour['duration_day']?.toString() ?? '-';

    final String price = formatPrice(tour['price']);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // ชื่อ + รหัส
          // ------------------------------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  tourName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Text(
                'รหัสทัวร์: $tourIdText',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ------------------------------------------------------
          // ประเทศ + ประเภท
          // ------------------------------------------------------
          Row(
            children: [
              const Icon(Icons.public, size: 19, color: Colors.green),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  '$country • $type',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // =====================================================
          // REVIEW SUMMARY
          // =====================================================
          Row(
            children: [
              const Icon(Icons.star, size: 21, color: Colors.amber),

              const SizedBox(width: 5),

              Text(
                reviewCount == 0
                    ? 'ยังไม่มีคะแนน'
                    : averageRating.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(width: 8),

              Text(
                reviewCount == 0
                    ? '(ยังไม่มีข้อมูลรีวิว)'
                    : '($reviewCount รีวิว)',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ------------------------------------------------------
          // ระยะเวลา
          // ------------------------------------------------------
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 20, color: Colors.orange),

              const SizedBox(width: 6),

              Text(
                'ระยะเวลา: $duration วัน',
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ------------------------------------------------------
          // ราคา
          // ------------------------------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'ราคาเริ่มต้น',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(width: 8),

              Text(
                '$price บาท',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          // ------------------------------------------------------
          // DOWNLOAD PDF
          // ------------------------------------------------------
          if (pdfUrl.trim().isNotEmpty) ...[
            const SizedBox(height: 16),

            _TourPdfDownloadButton(pdfUrl: pdfUrl, fileName: tourName),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // FORMAT PRICE
  // ==========================================================

  String formatPrice(dynamic value) {
    if (value == null) {
      return '-';
    }

    final num? number = num.tryParse(value.toString());

    if (number == null) {
      return value.toString();
    }

    return number.toStringAsFixed(number % 1 == 0 ? 0 : 2);
  }
}

class _TourPdfDownloadButton extends StatefulWidget {
  final String pdfUrl;
  final String fileName;

  const _TourPdfDownloadButton({required this.pdfUrl, required this.fileName});

  @override
  State<_TourPdfDownloadButton> createState() => _TourPdfDownloadButtonState();
}

class _TourPdfDownloadButtonState extends State<_TourPdfDownloadButton> {
  bool _isSaving = false;

  Future<void> _downloadPdf() async {
    final url = widget.pdfUrl.trim();
    final uri = Uri.tryParse(url);

    // ตรวจสอบ URL ก่อนเริ่มบันทึก
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      _showMessage('ไม่พบ URL ของเอกสาร PDF ที่ถูกต้อง');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // ทำชื่อไฟล์ให้เหมาะกับการบันทึก
      final safeName = widget.fileName.trim().replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );

      // เปิดหน้าต่างบันทึก PDF จาก URL
      final savedPath = await FileSaver.instance.saveAs(
        name: safeName.isEmpty ? 'tour_document' : safeName,
        link: LinkDetails(link: url),
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );

      if (!mounted) return;

      if (savedPath == null || savedPath.isEmpty) {
        _showMessage('ยกเลิกการบันทึกไฟล์ PDF');
      } else {
        _showMessage('บันทึกไฟล์ PDF สำเร็จ');
      }
    } catch (e) {
      debugPrint('Download PDF error: $e');

      if (mounted) {
        _showMessage('ไม่สามารถดาวน์โหลด PDF ได้ กรุณาลองใหม่');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _downloadPdf,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.download_for_offline_outlined),
        label: Text(
          _isSaving ? 'กำลังเตรียมไฟล์ PDF...' : 'ดาวน์โหลดเอกสาร PDF',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

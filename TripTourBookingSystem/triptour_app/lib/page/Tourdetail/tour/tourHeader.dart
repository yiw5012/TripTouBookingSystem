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
    return Column(children: [buildTourImage(), buildTourSummary(context)]);
  }

  // ==========================================================
  // IMAGE + VIDEO
  // ==========================================================

  Widget buildTourImage() {
    final String currentVideoUrl = videoUrl.trim();
    final bool hasVideo = currentVideoUrl.isNotEmpty;

    // จำนวนรายการสื่อทั้งหมด:
    // จำนวนรูปภาพ + 1 รายการ หากมีวิดีโอ
    final int mediaCount = images.length + (hasVideo ? 1 : 0);

    // ไม่มีทั้งรูปภาพและวิดีโอ
    if (mediaCount == 0) {
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
          PageView.builder(
            itemCount: mediaCount,
            itemBuilder: (context, index) {
              // รายการสุดท้ายคือวิดีโอ
              if (hasVideo && index == images.length) {
                return TourVideoPlayer(videoUrl: currentVideoUrl);
              }

              // รายการอื่น ๆ เป็นรูปภาพเหมือนเดิม
              final String imageUrl = images[index]['image']?.toString() ?? '';

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
          ),

          // แจ้งผู้ใช้ว่ามีวิดีโอให้เลื่อนดู
          if (hasVideo)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      images.isNotEmpty ? 'มีวิดีโอ • ปัดเพื่อดู' : 'วิดีโอ',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // SUMMARY
  // ==========================================================

  Widget buildTourSummary(BuildContext context) {
    final String tourName = tour['tour_name']?.toString() ?? 'ไม่มีชื่อทัวร์';

    final String tourIdText = tour['tour_code']?.toString() ?? '-';

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

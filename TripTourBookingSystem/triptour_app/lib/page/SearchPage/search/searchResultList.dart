import 'package:flutter/material.dart';
import 'package:triptour_app/page/Tourdetail/detailTour.dart';

// ---------- Design tokens ----------
const _kPrimary = Color(0xFF10B981);
const _kPrimaryDark = Color(0xFF047857);
const _kInk = Color(0xFF111827);
const _kMuted = Color(0xFF4B5563);

class SearchResultList extends StatelessWidget {
  final List<dynamic> searchResults;

  const SearchResultList({super.key, required this.searchResults});

  // 28900 -> 28,900 (ถ้าแปลงเป็นตัวเลขไม่ได้ จะแสดงค่าเดิม)
  String _formatPrice(dynamic value) {
    final raw = value?.toString().replaceAll(',', '').trim() ?? '';
    if (raw.isEmpty || raw == '-') return '-';

    final number = double.tryParse(raw);
    if (number == null) return raw;

    final text = number % 1 == 0
        ? number.toInt().toString()
        : number.toStringAsFixed(2);
    final parts = text.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
  }

  String _formatDate(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return '-';
    final d = DateTime.tryParse(raw)?.toLocal();
    if (d == null) return raw;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Widget _metaRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: _kMuted),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'ผลการค้นหา',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _kInk,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${searchResults.length} รายการ',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _kPrimaryDark,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: searchResults.length,
          itemBuilder: (context, index) {
            final tour = searchResults[index];
            final rawImage = tour['image'] ?? tour['images'];
            String? imageUrl;

            if (rawImage is String) {
              imageUrl = rawImage.trim();
            } else if (rawImage is List && rawImage.isNotEmpty) {
              imageUrl = rawImage.first?.toString().trim();
            } else if (rawImage is Map && rawImage['url'] != null) {
              imageUrl = rawImage['url'].toString().trim();
            }

            final imageToLoad =
                imageUrl != null &&
                    imageUrl.isNotEmpty &&
                    Uri.tryParse(imageUrl)?.hasAbsolutePath == true
                ? imageUrl
                : '';

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    final int tourId = int.parse(tour['tour_id'].toString());

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailTour(tourId: tourId),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 104,
                              constraints: const BoxConstraints(minHeight: 132),
                              color: const Color(0xFFE5E7EB),
                              child: imageToLoad.isNotEmpty
                                  ? Image.network(
                                      imageToLoad,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                size: 28,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.image,
                                        size: 28,
                                        color: Colors.grey,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tour['tour_name'] ?? 'ไม่มีชื่อทริป',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.bold,
                                        color: _kInk,
                                        height: 1.3,
                                      ),
                                    ),
                                    _metaRow(
                                      Icons.public,
                                      _kPrimaryDark,
                                      '${tour['country_name_th'] ?? '-'}',
                                    ),
                                    _metaRow(
                                      Icons.flight,
                                      Colors.blue,
                                      '${tour['airline'] ?? '-'}',
                                    ),
                                    _metaRow(
                                      Icons.calendar_month_rounded,
                                      Colors.orange,
                                      '${_formatDate(tour['start_date'])} - ${_formatDate(tour['end_date'])}',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              '฿${_formatPrice(tour['price'])}',
                                          style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold,
                                            color: _kInk,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: ' /คน',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: _kMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

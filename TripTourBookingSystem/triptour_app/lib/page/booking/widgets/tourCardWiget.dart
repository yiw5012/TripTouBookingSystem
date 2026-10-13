import 'package:flutter/material.dart';

class TourBookingCardWidget extends StatelessWidget {
  final String? imageUrl;
  final String tourTitle;
  final String route;
  final String tripDates;
  final String airline;
  final String roomSummary;
  final String travelerSummary;
  final String? bookingStatus;
  final Color? statusColor;
  final VoidCallback? onTap;

  const TourBookingCardWidget({
    super.key,
    this.imageUrl,
    this.tourTitle = 'รายละเอียดการจองทัวร์',
    required this.route,
    required this.tripDates,
    required this.airline,
    required this.roomSummary,
    required this.travelerSummary,
    this.bookingStatus,
    this.statusColor,
    this.onTap,
  });

  String get _formattedRoute {
    return route.replaceAll(RegExp(r'V\d+'), '').replaceAll('->', '→').trim();
  }

  String get _formattedTripDates {
    if (tripDates.contains('T') && tripDates.contains('Z')) {
      try {
        final parts = tripDates.split(' ถึง ');
        if (parts.length == 2) {
          final start = DateTime.parse(parts[0]).toLocal();
          final end = DateTime.parse(parts[1]).toLocal();
          const thaiMonths = [
            '',
            'ม.ค.',
            'ก.พ.',
            'มี.ค.',
            'เม.ย.',
            'พ.ค.',
            'มิ.ย.',
            'ก.ค.',
            'ส.ค.',
            'ก.ย.',
            'ต.ค.',
            'พ.ย.',
            'ธ.ค.',
          ];

          if (start.month == end.month && start.year == end.year) {
            return '${start.day} - ${end.day} ${thaiMonths[start.month]} ${start.year}';
          }
          return '${start.day} ${thaiMonths[start.month]} - ${end.day} ${thaiMonths[end.month]} ${end.year}';
        }
      } catch (_) {
        return tripDates;
      }
    }
    return tripDates;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: const Color(0xFF2563EB).withValues(alpha: 0.05),
          highlightColor: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildThumbnail(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      tourTitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                  if (bookingStatus != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            statusColor ??
                                            const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        bookingStatus!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildInfoRow(
                                icon: Icons.location_on_outlined,
                                iconColor: const Color(0xFF2563EB),
                                label: 'เส้นทาง',
                                value: _formattedRoute,
                              ),
                              const SizedBox(height: 6),
                              _buildInfoRow(
                                icon: Icons.calendar_today_outlined,
                                iconColor: const Color(0xFF64748B),
                                label: 'วันเดินทาง',
                                value: _formattedTripDates,
                              ),
                              const SizedBox(height: 6),
                              _buildInfoRow(
                                icon: Icons.flight_takeoff_rounded,
                                iconColor: const Color(0xFF64748B),
                                label: 'สายการบิน',
                                value: airline,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'สรุปการจอง',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            icon: Icons.king_bed_outlined,
                            iconColor: const Color(0xFF64748B),
                            label: 'ห้องพัก',
                            value: roomSummary,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            icon: Icons.people_outline_rounded,
                            iconColor: const Color(0xFF64748B),
                            label: 'ผู้เดินทาง',
                            value: travelerSummary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(height: 96, width: 96, child: widgetImage),
    );
  }

  Widget get widgetImage {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
      );
    }
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 30, color: Color(0xFF94A3B8)),
            SizedBox(height: 4),
            Text(
              'ไม่มีรูปภาพทัวร์',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class TourBookingCardWidget extends StatefulWidget {
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

  @override
  State<TourBookingCardWidget> createState() => _TourBookingCardWidgetState();
}

class _TourBookingCardWidgetState extends State<TourBookingCardWidget> {
  bool _isExpanded = false;

  /// คลีนตัวอักษรขยะในชื่อเส้นทาง (เช่น ตัด 'V2' หรือเปลี่ยน '->' เป็น '→')
  String get _formattedRoute {
    return widget.route
        .replaceAll(RegExp(r'V\d+'), '')
        .replaceAll('->', '→')
        .trim();
  }

  String get _formattedTripDates {
    if (widget.tripDates.contains('T') && widget.tripDates.contains('Z')) {
      try {
        final parts = widget.tripDates.split(' ถึง ');
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
        return widget.tripDates;
      }
    }
    return widget.tripDates;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // ใช้เงาจางๆ ยื่นลงมาข้างล่าง ช่วยแยกการ์ดออกจากพื้นหลังโดยไม่ต้องใช้ Border
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          splashColor: const Color(0xFF2563EB).withOpacity(0.05),
          highlightColor: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Image Banner
              _buildImageBanner(),

              // 2. Core Details
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tourTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.location_on_outlined,
                      iconColor: const Color(0xFF2563EB),
                      label: 'เส้นทาง',
                      value: _formattedRoute,
                      isHighlight: true,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.calendar_today_outlined,
                      iconColor: const Color(0xFF64748B),
                      label: 'วันเดินทาง',
                      value: _formattedTripDates,
                    ),
                  ],
                ),
              ),

              // 3. Expand Toggle Bar
              _buildExpandToggleBar(),

              // 4. Expandable Details Section
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: _buildExpandedSection(),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SUB WIDGETS ---

  Widget _buildImageBanner() {
    return Stack(
      children: [
        SizedBox(
          height: 150,
          width: double.infinity,
          child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
              ? Image.network(
                  widget.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                )
              : _buildImagePlaceholder(),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.transparent,
                  Colors.black.withOpacity(0.05),
                ],
              ),
            ),
          ),
        ),
        if (widget.bookingStatus != null)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.statusColor ?? const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.bookingStatus!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.flight_takeoff_rounded,
                  color: Colors.white,
                  size: 13,
                ),
                const SizedBox(width: 5),
                Text(
                  widget.airline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandToggleBar() {
    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isExpanded ? 'ซ่อนรายละเอียด' : 'ดูรายละเอียดการจองเพิ่มเติม',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _isExpanded
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF475569),
              ),
            ),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: _isExpanded
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedSection() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 16,
                  color: Color(0xFF2563EB),
                ),
                SizedBox(width: 6),
                Text(
                  'ข้อมูลห้องพักและผู้เดินทาง',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.king_bed_outlined,
              iconColor: const Color(0xFF64748B),
              label: 'ห้องพัก',
              value: widget.roomSummary,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.people_outline_rounded,
              iconColor: const Color(0xFF64748B),
              label: 'ผู้เดินทาง',
              value: widget.travelerSummary,
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
    bool isHighlight = false,
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
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
              color: isHighlight
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 32, color: Color(0xFF94A3B8)),
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
}

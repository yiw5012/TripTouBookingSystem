import 'package:flutter/material.dart';

// ---------- Design tokens ----------
const _kPrimary = Color(0xFF10B981);
const _kPrimaryDark = Color(0xFF047857);
const _kInk = Color(0xFF111827);
const _kMuted = Color(0xFF6B7280);
const _kField = Color(0xFFF3F4F6);

List<BoxShadow> get _kShadow => [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.07),
    blurRadius: 8,
    offset: const Offset(0, 2),
  ),
];

class SearchFilterSection extends StatelessWidget {
  final TextEditingController keywordController;

  final String selectedSort;
  final ValueChanged<String?> onSortChanged;

  // Continent
  final String? selectedContinent;
  final VoidCallback onContinentTap;

  // Country
  final String? selectedCountry;

  // Airline
  final List<String> selectedAirlines;

  // Date
  final DateTime? startDate;
  final DateTime? endDate;

  final VoidCallback onCountryTap;
  final VoidCallback onAirlineTap;
  final VoidCallback onDateTap;
  final VoidCallback onClearDate;
  final VoidCallback onSearch;

  final String? selectedDeparture;
  final String? selectedDestination;

  final VoidCallback onDepartureTap;
  final VoidCallback onDestinationTap;

  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;

  final String Function(DateTime?) formatDate;

  const SearchFilterSection({
    super.key,
    required this.keywordController,
    required this.selectedSort,
    required this.onSortChanged,
    required this.selectedContinent,
    required this.onContinentTap,
    required this.selectedCountry,
    required this.selectedAirlines,
    required this.startDate,
    required this.endDate,
    required this.onCountryTap,
    required this.onAirlineTap,
    required this.onDateTap,
    required this.onClearDate,
    required this.onSearch,
    required this.formatDate,
    required this.selectedDeparture,
    required this.selectedDestination,
    required this.onDepartureTap,
    required this.onDestinationTap,
    required this.minPriceController,
    required this.maxPriceController,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = startDate != null && endDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),

        // ============================================
        // คำค้นหา
        // ============================================
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _kShadow,
          ),
          child: TextField(
            controller: keywordController,
            textInputAction: TextInputAction.none,
            onSubmitted: (_) {},
            style: const TextStyle(fontSize: 15, color: _kInk),
            decoration: const InputDecoration(
              hintText: 'รหัสโปรแกรม / ชื่อทัวร์ / คีย์เวิร์ด',
              hintStyle: TextStyle(fontSize: 14, color: _kMuted),
              prefixIcon: Icon(Icons.search_rounded, color: _kMuted),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ============================================
        // การ์ดตัวกรอง
        // ============================================
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: _kShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.tune_rounded, size: 20, color: _kPrimaryDark),
                  SizedBox(width: 8),
                  Text(
                    'ตัวกรอง',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kInk,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ทวีป
              _labeled(
                'ทวีป',
                _PickerField(
                  icon: Icons.public,
                  iconColor: Colors.teal,
                  text: selectedContinent,
                  placeholder: 'ทุกทวีป',
                  onTap: onContinentTap,
                ),
              ),

              const SizedBox(height: 16),

              // ประเทศและสายการบิน
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _labeled(
                      'ประเทศ',
                      _PickerField(
                        icon: Icons.flag_rounded,
                        iconColor: _kPrimaryDark,
                        text: selectedCountry,
                        placeholder: 'เลือกประเทศ',
                        onTap: onCountryTap,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: _labeled(
                      'สายการบิน',
                      _PickerField(
                        icon: Icons.flight,
                        iconColor: Colors.blue,
                        text: selectedAirlines.isEmpty
                            ? null
                            : selectedAirlines.join(', '),
                        placeholder: 'เลือกสายการบิน',
                        onTap: onAirlineTap,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ต้นทางและปลายทาง
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _labeled(
                      'ต้นทาง',
                      _PickerField(
                        icon: Icons.flight_takeoff,
                        iconColor: Colors.teal,
                        text: selectedDeparture,
                        placeholder: 'เลือกต้นทาง',
                        onTap: onDepartureTap,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _labeled(
                      'ปลายทาง',
                      _PickerField(
                        icon: Icons.flight_land,
                        iconColor: Colors.deepOrange,
                        text: selectedDestination,
                        placeholder: 'เลือกปลายทาง',
                        onTap: onDestinationTap,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ช่วงราคา อ้างอิงจาก tour.price
              _labeled(
                'ช่วงราคาโปรแกรม (บาท)',
                Row(
                  children: [
                    Expanded(
                      child: _priceField(minPriceController, 'ราคาต่ำสุด'),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('ถึง', style: TextStyle(color: _kMuted)),
                    ),
                    Expanded(
                      child: _priceField(maxPriceController, 'ราคาสูงสุด'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ช่วงเวลาเดินทาง
              _labeled(
                'ช่วงเวลาเดินทาง',
                Material(
                  color: hasDate ? _kPrimary.withValues(alpha: 0.10) : _kField,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: onDateTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasDate ? _kPrimary : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.orange,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasDate
                                      ? 'ช่วงเวลาที่เลือก'
                                      : 'เลือกวันเดินทาง',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: _kMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hasDate
                                      ? '${formatDate(startDate)} - '
                                            '${formatDate(endDate)}'
                                      : 'วันเริ่มต้น - วันสิ้นสุด',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: hasDate ? _kInk : _kMuted,
                                    fontWeight: hasDate
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasDate)
                            IconButton(
                              onPressed: onClearDate,
                              tooltip: 'ล้างวันที่',
                              icon: const Icon(
                                Icons.close_rounded,
                                color: _kMuted,
                                size: 18,
                              ),
                              splashRadius: 18,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _kMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // เรียงตามราคา
              buildSortDropdown(
                selectedSort: selectedSort,
                onChanged: onSortChanged,
              ),

              const SizedBox(height: 22),

              // ปุ่มค้นหา
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onSearch,
                  icon: const Icon(Icons.search_rounded),
                  label: const Text(
                    'ค้นหา',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: _kInk,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- helpers ----------
  Widget _labeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _kInk,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _priceField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 14, color: _kInk),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: _kMuted),
        prefixIcon: const Icon(
          Icons.payments_outlined,
          size: 20,
          color: _kMuted,
        ),
        filled: true,
        fillColor: _kField,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
      ),
    );
  }

  Widget buildSortDropdown({
    required String selectedSort,
    required ValueChanged<String?> onChanged,
  }) {
    const options = [
      ['none', 'ไม่เรียงราคา'],
      ['price_asc', 'ราคาต่ำ → สูง'],
      ['price_desc', 'ราคาสูง → ต่ำ'],
    ];

    return _labeled(
      'เรียงตามราคา',
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final o in options)
            ChoiceChip(
              label: Text(o[1]),
              selected: selectedSort == o[0],
              showCheckmark: false,
              onSelected: (_) => onChanged(o[0]),
              selectedColor: _kPrimary,
              backgroundColor: _kField,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              labelStyle: TextStyle(
                fontSize: 13.5,
                color: _kInk,
                fontWeight: selectedSort == o[0]
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            ),
        ],
      ),
    );
  }
}

// ช่องเลือกค่า (ทวีป / ประเทศ / สายการบิน / ต้นทาง / ปลายทาง)
class _PickerField extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String? text;
  final String placeholder;
  final VoidCallback onTap;

  const _PickerField({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final has = text != null && text!.isNotEmpty;

    return Material(
      color: has ? _kPrimary.withValues(alpha: 0.10) : _kField,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: has ? _kPrimary : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  has ? text! : placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: has ? _kInk : _kMuted,
                    fontWeight: has ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: _kMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

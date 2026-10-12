import 'package:flutter/material.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),

        // ============================================
        // คำค้นหา
        // ============================================
        const Text(
          'คำค้นหา',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: keywordController,
          textInputAction: TextInputAction.none,
          onSubmitted: (_) {},
          decoration: InputDecoration(
            hintText: 'รหัสทัวร์ / ชื่อทัวร์ / คีย์เวิร์ด',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ============================================
        // เลือกทวีป
        // ============================================
        const Text(
          'ทวีป',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        InkWell(
          onTap: onContinentTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.public, color: Colors.teal, size: 21),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedContinent ?? 'ทุกทวีป',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: selectedContinent == null
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 20),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ============================================
        // ประเทศและสายการบิน
        // ============================================
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ประเทศ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: onCountryTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: 58,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.public,
                            color: Colors.green,
                            size: 21,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedCountry ?? 'เลือกประเทศ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: selectedCountry == null
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'สายการบิน',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: onAirlineTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: 58,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.flight,
                            color: Colors.blue,
                            size: 21,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedAirlines.isEmpty
                                  ? 'เลือกสายการบิน'
                                  : selectedAirlines.join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: selectedAirlines.isEmpty
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ============================================
        // ต้นทางและปลายทาง
        // ============================================
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ต้นทาง',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: onDepartureTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flight_takeoff, color: Colors.teal),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              selectedDeparture ?? 'เลือกต้นทาง',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: selectedDeparture == null
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ปลายทาง',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: onDestinationTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.flight_land,
                            color: Colors.deepOrange,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              selectedDestination ?? 'เลือกปลายทาง',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: selectedDestination == null
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ============================================
        // ช่วงราคา อ้างอิงจาก tour.price
        // ============================================
        const Text(
          'ช่วงราคาโปรแกรม (บาท)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: minPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: 'ราคาต่ำสุด',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('ถึง'),
            ),
            Expanded(
              child: TextField(
                controller: maxPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: 'ราคาสูงสุด',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),

        // ============================================
        // ช่วงเวลาเดินทาง
        // ============================================
        const Text(
          'ช่วงเวลาเดินทาง',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        InkWell(
          onTap: onDateTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        startDate == null || endDate == null
                            ? 'เลือกวันเดินทาง'
                            : 'ช่วงเวลาที่เลือก',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        startDate == null || endDate == null
                            ? 'วันเริ่มต้น - วันสิ้นสุด'
                            : '${formatDate(startDate)} - '
                                  '${formatDate(endDate)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: startDate != null && endDate != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (startDate != null && endDate != null)
                  IconButton(
                    onPressed: onClearDate,
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ============================================
        // เรียงตามราคา
        // ============================================
        buildSortDropdown(selectedSort: selectedSort, onChanged: onSortChanged),

        const SizedBox(height: 30),

        // ============================================
        // ปุ่มค้นหา
        // ============================================
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onSearch,
            icon: const Icon(Icons.search),
            label: const Text(
              'ค้นหา',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSortDropdown({
    required String selectedSort,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'เรียงตามราคา',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        DropdownButtonFormField<String>(
          value: selectedSort,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.sort, color: Colors.orange),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: const [
            DropdownMenuItem(value: 'none', child: Text('ไม่เรียงราคา')),
            DropdownMenuItem(value: 'price_asc', child: Text('ราคาต่ำ → สูง')),
            DropdownMenuItem(value: 'price_desc', child: Text('ราคาสูง → ต่ำ')),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:triptour_app/serverApi.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // =====================================================
  // Controllers
  // =====================================================

  final TextEditingController keywordController = TextEditingController();

  // =====================================================
  // Search values
  // =====================================================

  String? selectedCountry;
  int? selectedCountryId;

  List<dynamic> countries = [];
  bool isLoadingCountries = true;

  List<dynamic> airlines = [];
  bool isLoadingAirlines = true;

  final List<String> selectedAirlines = [];

  List<dynamic> searchResults = [];
  bool isSearchingTours = false;

  bool hasSearched = false;

  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();

    loadCountries();
    loadAirlines();
  }

  Future<void> loadCountries() async {
    final result = await Serverapi.getSearchCountries();

    if (!mounted) return;

    if (result['statusCode'] == 200 && result['body']['success'] == true) {
      setState(() {
        countries = result['body']['data'] ?? [];
        isLoadingCountries = false;
      });
    } else {
      setState(() {
        countries = [];
        isLoadingCountries = false;
      });
    }
  }

  Future<void> loadAirlines() async {
    final result = await Serverapi.getSearchAirlines();

    if (!mounted) return;

    if (result['statusCode'] == 200 && result['body']['success'] == true) {
      setState(() {
        airlines = result['body']['data'] ?? [];
        isLoadingAirlines = false;
      });
    } else {
      setState(() {
        airlines = [];
        isLoadingAirlines = false;
      });
    }
  }

  // =====================================================
  // Dispose
  // =====================================================

  @override
  void dispose() {
    keywordController.dispose();

    super.dispose();
  }

  // =====================================================
  // Date Range
  // =====================================================

  Future<void> selectDateRange() async {
    final DateTime now = DateTime.now();

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,

      firstDate: DateTime(now.year, now.month, now.day),

      lastDate: DateTime(now.year + 2, 12, 31),

      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,

      helpText: 'เลือกช่วงเวลาเดินทาง',

      cancelText: 'ยกเลิก',

      confirmText: 'ยืนยัน',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      startDate = picked.start;
      endDate = picked.end;
    });
  }

  // =====================================================
  // Format Date
  // =====================================================

  String formatDate(DateTime? date) {
    if (date == null) {
      return '--/--/----';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // =====================================================
  // Country Dropdown
  // =====================================================

  Future<void> selectCountry() async {
    final Map<String, dynamic>?
    result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        String searchText = '';

        List<dynamic> filteredCountries = List.from(countries);

        return StatefulBuilder(
          builder: (context, setModalState) {
            filteredCountries = countries.where((country) {
              final nameTh = (country['country_name_th'] ?? '')
                  .toString()
                  .toLowerCase();

              final nameEn = (country['country_name_en'] ?? '')
                  .toString()
                  .toLowerCase();

              final keyword = searchText.toLowerCase();

              return nameTh.contains(keyword) || nameEn.contains(keyword);
            }).toList();

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'เลือกประเทศ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      decoration: InputDecoration(
                        hintText: 'ค้นหาประเทศ',

                        prefixIcon: const Icon(Icons.search),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),

                      onChanged: (value) {
                        setModalState(() {
                          searchText = value;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    Expanded(
                      child: isLoadingCountries
                          ? const Center(child: CircularProgressIndicator())
                          : filteredCountries.isEmpty
                          ? const Center(child: Text('ไม่พบประเทศที่มีทัวร์'))
                          : ListView.builder(
                              itemCount: filteredCountries.length,

                              itemBuilder: (context, index) {
                                final country = filteredCountries[index];

                                final countryName =
                                    country['country_name_th'] ??
                                    country['country_name_en'] ??
                                    '';

                                final bool isSelected =
                                    selectedCountry == countryName;

                                return ListTile(
                                  title: Text(countryName.toString()),

                                  subtitle: Text(
                                    country['country_name_en']?.toString() ??
                                        '',
                                  ),

                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.green,
                                        )
                                      : null,

                                  onTap: () {
                                    Navigator.pop(context, {
                                      'country_id': country['country_id'],
                                      'country_name_th':
                                          country['country_name_th'],
                                      'country_name_en':
                                          country['country_name_en'],
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedCountry = result['country_name_th']?.toString();

        selectedCountryId = result['country_id'];
      });
    }
  }

  // =====================================================
  // Airline Multi Select
  // =====================================================

  Future<void> selectAirlines() async {
    final List<String> tempSelected = List<String>.from(selectedAirlines);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    // =================================
                    // Header
                    // =================================
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'เลือกสายการบิน',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // =================================
                    // Loading
                    // =================================
                    if (isLoadingAirlines)
                      const Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(),
                      )
                    // =================================
                    // ไม่มีข้อมูล
                    // =================================
                    else if (airlines.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(30),
                        child: Text('ยังไม่มีข้อมูลสายการบิน'),
                      )
                    // =================================
                    // รายการสายการบิน
                    // =================================
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,

                          itemCount: airlines.length,

                          itemBuilder: (context, index) {
                            // API ส่งกลับมาเป็น Map
                            final String airline =
                                airlines[index]['airline']?.toString() ?? '';

                            final bool isSelected = tempSelected.contains(
                              airline,
                            );

                            return CheckboxListTile(
                              value: isSelected,

                              title: Text(airline),

                              onChanged: (value) {
                                setModalState(() {
                                  if (value == true) {
                                    if (!tempSelected.contains(airline)) {
                                      tempSelected.add(airline);
                                    }
                                  } else {
                                    tempSelected.remove(airline);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 10),

                    // =================================
                    // ปุ่มยืนยัน
                    // =================================
                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedAirlines
                              ..clear()
                              ..addAll(tempSelected);
                          });

                          Navigator.pop(context);
                        },

                        child: const Text('ยืนยัน'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =====================================================
  // Search Button
  // =====================================================

  Future<void> submitSearch() async {
    setState(() {
      isSearchingTours = true;
      hasSearched = true;
      searchResults = [];
    });

    final result = await Serverapi.searchTours(
      keyword: keywordController.text.trim(),
      countryId: selectedCountryId,
      airlines: selectedAirlines,
      startDate: startDate,
      endDate: endDate,
    );

    if (!mounted) return;

    if (result['statusCode'] == 200 && result['body']['success'] == true) {
      setState(() {
        searchResults = result['body']['data'] ?? [];
        isSearchingTours = false;
      });
    } else {
      setState(() {
        searchResults = [];
        isSearchingTours = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่สามารถค้นหาทริปได้')));
    }
  }

  Widget buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ผลการค้นหา',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        ListView.builder(
          shrinkWrap: true,

          physics: const NeverScrollableScrollPhysics(),

          itemCount: searchResults.length,

          itemBuilder: (context, index) {
            final tour = searchResults[index];

            return Container(
              width: double.infinity,

              margin: const EdgeInsets.only(bottom: 12),

              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(14),

                border: Border.all(color: Colors.grey.shade300),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // =====================================
                  // ชื่อทริป
                  // =====================================
                  Text(
                    tour['tour_name'] ?? 'ไม่มีชื่อทริป',

                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // =====================================
                  // ประเทศ
                  // =====================================
                  Row(
                    children: [
                      const Icon(Icons.public, size: 18, color: Colors.green),

                      const SizedBox(width: 6),

                      Expanded(
                        child: Text(
                          'ประเทศ: '
                          '${tour['country_name_th'] ?? '-'}',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // =====================================
                  // สายการบิน
                  // =====================================
                  Row(
                    children: [
                      const Icon(Icons.flight, size: 18, color: Colors.blue),

                      const SizedBox(width: 6),

                      Expanded(
                        child: Text(
                          'สายการบิน: '
                          '${tour['airline'] ?? '-'}',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // =====================================
                  // วันเดินทาง
                  // =====================================
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 18,
                        color: Colors.orange,
                      ),

                      const SizedBox(width: 6),

                      Expanded(
                        child: Text(
                          'เดินทาง: '
                          '${tour['start_date'] ?? '-'}'
                          ' - '
                          '${tour['end_date'] ?? '-'}',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // =====================================
                  // ราคา
                  // =====================================
                  Row(
                    children: [
                      const Icon(Icons.payments, size: 18, color: Colors.green),

                      const SizedBox(width: 6),

                      Text(
                        'ราคา: '
                        '${tour['price'] ?? '-'} บาท',

                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // =====================================================
  // Build
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,

      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 10),

              // =================================================
              // Keyword
              // =================================================
              const Text(
                'คำค้นหา',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: keywordController,

                // =============================================
                // ป้องกัน Enter ไม่ให้ Submit
                // =============================================
                textInputAction: TextInputAction.none,

                onSubmitted: (_) {
                  // ไม่ทำอะไร
                },

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

              // =================================================
              // Country + Airline
              // =================================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =============================================
                  // Country
                  // =============================================
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ประเทศ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        InkWell(
                          onTap: selectCountry,

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

                  // =============================================
                  // Airline
                  // =============================================
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Text(
                          'สายการบิน',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        InkWell(
                          onTap: selectAirlines,

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

              // =================================================
              // Date Range
              // =================================================
              // =================================================
              // Date Range
              // =================================================
              const Text(
                'ช่วงเวลาเดินทาง',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              InkWell(
                onTap: selectDateRange,

                borderRadius: BorderRadius.circular(12),

                child: Container(
                  width: double.infinity,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),

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
                          onPressed: () {
                            setState(() {
                              startDate = null;
                              endDate = null;
                            });
                          },

                          icon: const Icon(Icons.close, color: Colors.grey),
                        ),

                      const Icon(Icons.keyboard_arrow_down),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // Search Button
              // =================================================
              SizedBox(
                width: double.infinity,

                height: 52,

                child: ElevatedButton.icon(
                  onPressed: submitSearch,

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

              const SizedBox(height: 25),

              // =================================================
              // ผลการค้นหา
              // =================================================
              if (isSearchingTours)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),

              if (!isSearchingTours && searchResults.isNotEmpty)
                buildSearchResults(),

              if (!isSearchingTours && searchResults.isEmpty && hasSearched)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'ไม่พบข้อมูลทริป',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

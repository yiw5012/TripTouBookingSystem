import 'package:flutter/material.dart';
import 'package:triptour_app/serverApi.dart';

import 'search/searchFilterSection.dart';
import 'search/searchOptionSheets.dart';
import 'search/searchResultList.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // =====================================================
  // Controller
  // =====================================================

  final TextEditingController keywordController = TextEditingController();

  // =====================================================
  // Country
  // =====================================================

  String? selectedCountry;
  int? selectedCountryId;

  List<dynamic> countries = [];
  bool isLoadingCountries = true;

  // =====================================================
  // Airline
  // =====================================================

  List<dynamic> airlines = [];
  bool isLoadingAirlines = true;

  final List<String> selectedAirlines = [];

  // =====================================================
  // Search Result
  // =====================================================

  List<dynamic> searchResults = [];

  bool isSearchingTours = false;
  bool hasSearched = false;

  // =====================================================
  // Date
  // =====================================================

  DateTime? startDate;
  DateTime? endDate;

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();

    loadCountries();
    loadAirlines();
  }

  // =====================================================
  // LOAD COUNTRIES
  // =====================================================

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

  // =====================================================
  // LOAD AIRLINES
  // =====================================================

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
  // DATE RANGE
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
  // FORMAT DATE
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
  // COUNTRY
  // =====================================================

  Future<void> selectCountry() async {
    final Map<String, dynamic>? result =
        await SearchOptionSheets.showCountryPicker(
          context: context,
          countries: countries,
          isLoadingCountries: isLoadingCountries,
          selectedCountry: selectedCountry,
        );

    if (result == null) {
      return;
    }

    setState(() {
      selectedCountry = result['country_name_th']?.toString();

      selectedCountryId = result['country_id'];
    });
  }

  // =====================================================
  // AIRLINE
  // =====================================================

  Future<void> selectAirlines() async {
    final List<String>? result = await SearchOptionSheets.showAirlinePicker(
      context: context,
      airlines: airlines,
      isLoadingAirlines: isLoadingAirlines,
      selectedAirlines: selectedAirlines,
    );

    if (result == null) {
      return;
    }

    setState(() {
      selectedAirlines
        ..clear()
        ..addAll(result);
    });
  }

  // =====================================================
  // SEARCH
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

  // =====================================================
  // CLEAR DATE
  // =====================================================

  void clearDate() {
    setState(() {
      startDate = null;
      endDate = null;
    });
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    keywordController.dispose();

    super.dispose();
  }

  // =====================================================
  // BUILD
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
              SearchFilterSection(
                keywordController: keywordController,

                selectedCountry: selectedCountry,

                selectedAirlines: selectedAirlines,

                startDate: startDate,

                endDate: endDate,

                onCountryTap: selectCountry,

                onAirlineTap: selectAirlines,

                onDateTap: selectDateRange,

                onClearDate: clearDate,

                onSearch: submitSearch,

                formatDate: formatDate,
              ),

              const SizedBox(height: 25),

              // =================================================
              // Loading
              // =================================================
              if (isSearchingTours)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),

              // =================================================
              // Results
              // =================================================
              if (!isSearchingTours && searchResults.isNotEmpty)
                SearchResultList(searchResults: searchResults),

              // =================================================
              // Empty
              // =================================================
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

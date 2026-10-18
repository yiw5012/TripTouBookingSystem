import 'package:flutter/material.dart';

// ---------- Design tokens ----------
const _kPrimary = Color(0xFF10B981);
const _kPrimaryDark = Color(0xFF047857);
const _kInk = Color(0xFF111827);
const _kMuted = Color(0xFF6B7280);
const _kField = Color(0xFFF3F4F6);

class SearchOptionSheets {
  // ---------- shared UI helpers ----------
  static Future<T?> _open<T>(BuildContext context, WidgetBuilder builder) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: builder,
    );
  }

  // โครงหน้าต่าง: handle + หัวข้อ + ปุ่มปิด + เนื้อหา
  static Widget _sheet({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    bool fixedHeight = true,
  }) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Column(
        mainAxisSize: fixedHeight ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _kInk,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                tooltip: 'ปิด',
                icon: const Icon(Icons.close_rounded, color: _kInk),
                style: IconButton.styleFrom(backgroundColor: _kField),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: fixedHeight
            ? SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: content,
              )
            : content,
      ),
    );
  }

  static Widget _searchField({
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15, color: _kInk),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: _kMuted),
        prefixIcon: const Icon(Icons.search_rounded, color: _kMuted),
        filled: true,
        fillColor: _kField,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
      ),
    );
  }

  static Widget _optionTile({
    required String title,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
    bool multi = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? _kPrimary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          color: _kInk,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: _kMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (multi)
                  Icon(
                    selected
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: selected ? _kPrimaryDark : _kMuted,
                  )
                else if (selected)
                  const Icon(Icons.check_circle_rounded, color: _kPrimaryDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _loading() =>
      const Center(child: CircularProgressIndicator(color: _kPrimary));

  static Widget _empty(String text) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: Text(text, style: const TextStyle(color: _kMuted)),
    ),
  );

  // =====================================================
  // CONTINENT
  // =====================================================
  static Future<String?> showContinentPicker({
    required BuildContext context,
    required List<dynamic> continents,
    required bool isLoadingContinents,
    required String? selectedContinent,
  }) async {
    return _open<String>(context, (context) {
      String searchText = '';

      return StatefulBuilder(
        builder: (context, setModalState) {
          final filteredContinents = continents.where((item) {
            final name = item is Map
                ? (item['continent'] ?? '').toString()
                : item.toString();

            return name.toLowerCase().contains(searchText.trim().toLowerCase());
          }).toList();

          final isAllSelected =
              selectedContinent == null || selectedContinent.isEmpty;

          return _sheet(
            context: context,
            title: 'เลือกทวีป',
            children: [
              _searchField(
                hint: 'ค้นหาทวีป',
                onChanged: (value) => setModalState(() => searchText = value),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: isLoadingContinents
                    ? _loading()
                    : ListView(
                        children: [
                          // ไม่จำกัดทวีป
                          _optionTile(
                            title: 'ทุกทวีป',
                            selected: isAllSelected,
                            onTap: () => Navigator.pop(context, ''),
                          ),
                          if (filteredContinents.isEmpty)
                            _empty('ไม่พบข้อมูลทวีป'),
                          ...filteredContinents.map((item) {
                            final continentName = item is Map
                                ? (item['continent'] ?? '').toString()
                                : item.toString();

                            return _optionTile(
                              title: continentName,
                              selected: selectedContinent == continentName,
                              onTap: () =>
                                  Navigator.pop(context, continentName),
                            );
                          }),
                        ],
                      ),
              ),
            ],
          );
        },
      );
    });
  }

  // =====================================================
  // COUNTRY
  // =====================================================
  static Future<Map<String, dynamic>?> showCountryPicker({
    required BuildContext context,
    required List<dynamic> countries,
    required bool isLoadingCountries,
    required String? selectedCountry,
  }) async {
    return _open<Map<String, dynamic>>(context, (context) {
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

          return _sheet(
            context: context,
            title: 'เลือกประเทศ',
            children: [
              _searchField(
                hint: 'ค้นหาประเทศ',
                onChanged: (value) => setModalState(() => searchText = value),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: isLoadingCountries
                    ? _loading()
                    : filteredCountries.isEmpty
                    ? _empty('ไม่พบประเทศที่มีทัวร์')
                    : ListView.builder(
                        itemCount: filteredCountries.length,
                        itemBuilder: (context, index) {
                          final country = filteredCountries[index];

                          final countryName =
                              country['country_name_th'] ??
                              country['country_name_en'] ??
                              '';

                          return _optionTile(
                            title: countryName.toString(),
                            subtitle: country['country_name_en']?.toString(),
                            selected: selectedCountry == countryName,
                            onTap: () {
                              Navigator.pop(context, {
                                'country_id': country['country_id'],
                                'country_name_th': country['country_name_th'],
                                'country_name_en': country['country_name_en'],
                              });
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      );
    });
  }

  // =====================================================
  // AIRLINE (เลือกได้หลายรายการ)
  // =====================================================
  static Future<List<String>?> showAirlinePicker({
    required BuildContext context,
    required List<dynamic> airlines,
    required bool isLoadingAirlines,
    required List<String> selectedAirlines,
  }) async {
    final List<String> tempSelected = List<String>.from(selectedAirlines);

    return _open<List<String>>(context, (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return _sheet(
            context: context,
            title: 'เลือกสายการบิน',
            fixedHeight: false,
            children: [
              if (isLoadingAirlines)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: CircularProgressIndicator(color: _kPrimary),
                  ),
                )
              else if (airlines.isEmpty)
                _empty('ยังไม่มีข้อมูลสายการบิน')
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: airlines.length,
                    itemBuilder: (context, index) {
                      final String airline =
                          airlines[index]['airline']?.toString() ?? '';

                      final bool isSelected = tempSelected.contains(airline);

                      return _optionTile(
                        title: airline,
                        selected: isSelected,
                        multi: true,
                        onTap: () {
                          setModalState(() {
                            if (isSelected) {
                              tempSelected.remove(airline);
                            } else if (!tempSelected.contains(airline)) {
                              tempSelected.add(airline);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, List<String>.from(tempSelected));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: _kInk,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    tempSelected.isEmpty
                        ? 'ยืนยัน'
                        : 'ยืนยัน (${tempSelected.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  // =====================================================
  // LOCATION (ต้นทาง / ปลายทาง)
  // =====================================================
  static Future<String?> showLocationPicker({
    required BuildContext context,
    required String title,
    required List<dynamic> locations,
    required bool isLoading,
    required String? selectedValue,
  }) async {
    return _open<String>(context, (context) {
      String searchText = '';

      return StatefulBuilder(
        builder: (context, setModalState) {
          final allLocations =
              locations
                  .map<String>((item) {
                    if (item is Map) {
                      return (item['departure'] ?? item['destination'] ?? '')
                          .toString();
                    }
                    return item.toString();
                  })
                  .where((value) => value.trim().isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();

          final filteredLocations = allLocations
              .where(
                (value) => value.toLowerCase().contains(
                  searchText.trim().toLowerCase(),
                ),
              )
              .toList();

          return _sheet(
            context: context,
            title: title,
            children: [
              _searchField(
                hint: 'ค้นหา$title',
                onChanged: (value) => setModalState(() => searchText = value),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: isLoading
                    ? _loading()
                    : ListView(
                        children: [
                          _optionTile(
                            title: 'ทั้งหมด',
                            selected:
                                selectedValue == null || selectedValue.isEmpty,
                            onTap: () => Navigator.pop(context, ''),
                          ),
                          if (filteredLocations.isEmpty) _empty('ไม่พบข้อมูล'),
                          ...filteredLocations.map((location) {
                            return _optionTile(
                              title: location,
                              selected: selectedValue == location,
                              onTap: () => Navigator.pop(context, location),
                            );
                          }),
                        ],
                      ),
              ),
            ],
          );
        },
      );
    });
  }
}

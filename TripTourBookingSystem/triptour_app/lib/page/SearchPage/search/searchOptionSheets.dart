import 'package:flutter/material.dart';

class SearchOptionSheets {
  static Future<Map<String, dynamic>?> showCountryPicker({
    required BuildContext context,
    required List<dynamic> countries,
    required bool isLoadingCountries,
    required String? selectedCountry,
  }) async {
    return showModalBottomSheet<Map<String, dynamic>>(
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
  }

  static Future<List<String>?> showAirlinePicker({
    required BuildContext context,
    required List<dynamic> airlines,
    required bool isLoadingAirlines,
    required List<String> selectedAirlines,
  }) async {
    final List<String> tempSelected = List<String>.from(selectedAirlines);

    return showModalBottomSheet<List<String>>(
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

                    if (isLoadingAirlines)
                      const Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(),
                      )
                    else if (airlines.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(30),
                        child: Text('ยังไม่มีข้อมูลสายการบิน'),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: airlines.length,
                          itemBuilder: (context, index) {
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

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            List<String>.from(tempSelected),
                          );
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
}

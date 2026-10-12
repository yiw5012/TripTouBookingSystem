import 'package:flutter/material.dart';

class SearchOptionSheets {
  static Future<String?> showContinentPicker({
    required BuildContext context,
    required List<dynamic> continents,
    required bool isLoadingContinents,
    required String? selectedContinent,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        String searchText = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredContinents = continents.where((item) {
              final name = item is Map
                  ? (item['continent'] ?? '').toString()
                  : item.toString();

              return name.toLowerCase().contains(
                searchText.trim().toLowerCase(),
              );
            }).toList();

            final isAllSelected =
                selectedContinent == null || selectedContinent.isEmpty;

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'เลือกทวีป',
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
                          hintText: 'ค้นหาทวีป',
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
                        child: isLoadingContinents
                            ? const Center(child: CircularProgressIndicator())
                            : ListView(
                                children: [
                                  // ไม่จำกัดทวีป
                                  ListTile(
                                    title: const Text('ทุกทวีป'),
                                    trailing: isAllSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                          )
                                        : null,
                                    onTap: () {
                                      Navigator.pop(context, '');
                                    },
                                  ),

                                  if (filteredContinents.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Center(
                                        child: Text('ไม่พบข้อมูลทวีป'),
                                      ),
                                    ),

                                  ...filteredContinents.map((item) {
                                    final continentName = item is Map
                                        ? (item['continent'] ?? '').toString()
                                        : item.toString();

                                    final isSelected =
                                        selectedContinent == continentName;

                                    return ListTile(
                                      title: Text(continentName),
                                      trailing: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.green,
                                            )
                                          : null,
                                      onTap: () {
                                        Navigator.pop(context, continentName);
                                      },
                                    );
                                  }),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

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

  static Future<String?> showLocationPicker({
    required BuildContext context,
    required String title,
    required List<dynamic> locations,
    required bool isLoading,
    required String? selectedValue,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
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

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'ค้นหา$title',
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
                      const SizedBox(height: 12),
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ListView(
                                children: [
                                  ListTile(
                                    title: const Text('ทั้งหมด'),
                                    trailing:
                                        selectedValue == null ||
                                            selectedValue.isEmpty
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                          )
                                        : null,
                                    onTap: () {
                                      Navigator.pop(context, '');
                                    },
                                  ),
                                  if (filteredLocations.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Center(child: Text('ไม่พบข้อมูล')),
                                    ),
                                  ...filteredLocations.map((location) {
                                    return ListTile(
                                      title: Text(location),
                                      trailing: selectedValue == location
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.green,
                                            )
                                          : null,
                                      onTap: () {
                                        Navigator.pop(context, location);
                                      },
                                    );
                                  }),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

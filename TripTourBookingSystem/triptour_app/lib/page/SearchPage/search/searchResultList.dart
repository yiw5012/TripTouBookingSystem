import 'package:flutter/material.dart';
import 'package:triptour_app/page/Tourdetail/detailTour.dart';

class SearchResultList extends StatelessWidget {
  final List<dynamic> searchResults;

  const SearchResultList({super.key, required this.searchResults});

  @override
  Widget build(BuildContext context) {
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

            return GestureDetector(
              onTap: () {
                final int tourId = int.parse(tour['tour_id'].toString());

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailTour(tourId: tourId),
                  ),
                );
              },
              child: Container(
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
                    Text(
                      tour['tour_name'] ?? 'ไม่มีชื่อทริป',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

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

                    Row(
                      children: [
                        const Icon(
                          Icons.payments,
                          size: 18,
                          color: Colors.green,
                        ),
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
              ),
            );
          },
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:triptour_app/page/booking/bookingPage.dart';
import 'package:triptour_app/page/booking/widgets/passenger_counter.dart';

class Step1TourDetails extends StatelessWidget {
  final Map<String, dynamic> tourData;
  final Map<String, dynamic> selectedRound;
  final List<String> passengerTypes;
  final List<int> passengerCounts;
  final List<int> prices;
  final int totalPrice;
  final Function(int index, int delta) onCountChanged;

  const Step1TourDetails({
    super.key,
    required this.tourData,
    required this.selectedRound,
    required this.passengerTypes,
    required this.passengerCounts,
    required this.prices,
    required this.totalPrice,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tourName = tourData['tour_name'] ?? 'Tour';
    final departure = selectedRound['departure'] ?? 'Unknown';
    final destination = selectedRound['destination'] ?? 'Unknown';
    final startDate = selectedRound['start_date'] ?? 'N/A';
    final endDate = selectedRound['end_date'] ?? 'N/A';
    final airline = selectedRound['airline'] ?? 'N/A';

    final int capacity =
        int.tryParse(selectedRound['count']?.toString() ?? '0') ?? 0;
    final int totalPaid =
        int.tryParse(selectedRound['total_paid']?.toString() ?? '0') ?? 0;
    final int availableSeats = capacity - totalPaid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow('Tour', tourName),
        _infoRow(
          'Price',
          formatCurrency(tourData['price'] ?? selectedRound['price'] ?? 0),
        ),
        _infoRow('Type', tourData['type'] ?? 'N/A'),
        _infoRow('Duration', '${tourData['duration_day'] ?? 'N/A'} day'),
        const SizedBox(height: 20),

        const Text(
          'Selected round',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: availableSeats > 0
                  ? Colors.green.shade200
                  : Colors.red.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Route', '$departure → $destination'),
                _infoRow('Dates', '$startDate ถึง $endDate'),
                _infoRow('Airline', airline),
                _infoRow(
                  'Seats Left',
                  '$availableSeats / $capacity ที่',
                  valueColor: availableSeats > 0
                      ? Colors.green.shade700
                      : Colors.red,
                  isBold: true,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        const Divider(),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: passengerTypes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return PassengerCounterRow(
              title: passengerTypes[index],
              count: passengerCounts[index],
              price: prices[index],
              onIncrement: () => onCountChanged(index, 1),
              onDecrement: () => onCountChanged(index, -1),
            );
          },
        ),

        const Divider(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              formatCurrency(totalPrice),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

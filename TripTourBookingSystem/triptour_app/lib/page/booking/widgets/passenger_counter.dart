import 'package:flutter/material.dart';
import 'package:triptour_app/page/booking/bookingPage.dart';

class PassengerCounterRow extends StatelessWidget {
  final String title;
  final int count;
  final int price;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const PassengerCounterRow({
    super.key,
    required this.title,
    required this.count,
    required this.price,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(title, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildButton(
                icon: Icons.remove,
                bgColor: Colors.grey[300]!,
                iconColor: Colors.black87,
                onPressed: count > 0 ? onDecrement : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _buildButton(
                icon: Icons.add,
                bgColor: Colors.green[300]!,
                iconColor: Colors.white,
                onPressed: onIncrement,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency(price),
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
              Text(
                formatCurrency(count * price),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    VoidCallback? onPressed,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: onPressed == null ? Colors.grey[200] : bgColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 18,
            color: onPressed == null ? Colors.grey[400] : iconColor,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class DriverDieselScreen extends StatelessWidget {
  final AuthService authService;
  const DriverDieselScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser!;
    final records = authService.dieselRecords
        .where((d) => d.driverId == user.id)
        .toList();
    final totalLitres = records.fold(0.0, (s, d) => s + d.litres);
    final totalAmount = records.fold(0.0, (s, d) => s + d.amount);

    return Container(
      color: const Color(0xFFF5F5F5),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _summaryCard(
                  'Total Litres',
                  '${totalLitres.toStringAsFixed(1)} L',
                  const Color(0xFFE65100),
                ),
                const SizedBox(width: 12),
                _summaryCard(
                  'Total Cost',
                  '₹${totalAmount.toStringAsFixed(0)}',
                  const Color(0xFF1A237E),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'My Diesel Log',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 14),
            if (records.isEmpty)
              _emptyState()
            else
              ...records.map(
                (r) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE65100).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.local_gas_station,
                            color: Color(0xFFE65100),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.vehicleNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${r.date.day}/${r.date.month}/${r.date.year} · KM: ${r.kmReading.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${r.litres.toStringAsFixed(1)} L',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100),
                              ),
                            ),
                            Text(
                              '₹${r.amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.local_gas_station, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text('No diesel records', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}

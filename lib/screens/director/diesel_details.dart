import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class DieselDetailsScreen extends StatelessWidget {
  final AuthService authService;
  const DieselDetailsScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    final records = authService.dieselRecords;
    final totalLitres = records.fold(0.0, (s, r) => s + r.litres);
    final totalAmount = records.fold(0.0, (s, r) => s + r.amount);

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
                  'Total Spent',
                  '₹${totalAmount.toStringAsFixed(0)}',
                  const Color(0xFF1A237E),
                ),
                const SizedBox(width: 12),
                _summaryCard('Records', '${records.length}', Colors.green),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Diesel Log',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 14),
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
                          size: 24,
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
                                fontSize: 14.5,
                              ),
                            ),
                            if (r.driverName != null)
                              Text(
                                'Driver: ${r.driverName}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
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
                              fontSize: 15,
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
}

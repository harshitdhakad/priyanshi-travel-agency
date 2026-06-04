import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/app_theme.dart';

class DieselDetailsScreen extends StatelessWidget {
  final SupabaseService supabaseService;
  const DieselDetailsScreen({super.key, required this.supabaseService});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabaseService.dieselPurchasesStream(),
        builder: (context, snap) {
          final records = snap.data ?? [];
          final totalLitres = records.fold(
            0.0,
            (s, r) =>
                s + (double.tryParse(r['liters']?.toString() ?? '0') ?? 0),
          );
          final totalAmount = records.fold(
            0.0,
            (s, r) =>
                s + (double.tryParse(r['amount']?.toString() ?? '0') ?? 0),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _summaryCard(
                      'Total Litres',
                      '${totalLitres.toStringAsFixed(1)} L',
                      AppTheme.warning,
                    ),
                    const SizedBox(width: 12),
                    _summaryCard(
                      'Total Spent',
                      '₹${totalAmount.toStringAsFixed(0)}',
                      AppTheme.primary,
                    ),
                    const SizedBox(width: 12),
                    _summaryCard(
                      'Records',
                      '${records.length}',
                      AppTheme.success,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Diesel Log',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 14),
                if (records.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_gas_station_outlined,
                          size: 40,
                          color: AppTheme.textHint,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No diesel records',
                          style: TextStyle(color: AppTheme.textHint),
                        ),
                      ],
                    ),
                  )
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
                                color: AppTheme.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.local_gas_station,
                                color: AppTheme.warning,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r['vehicle_number']?.toString() ??
                                        'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                  Text(
                                    'Date: ${r['purchase_date'] ?? 'N/A'}',
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
                                  '${(double.tryParse(r['liters']?.toString() ?? '0') ?? 0).toStringAsFixed(1)} L',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppTheme.warning,
                                  ),
                                ),
                                Text(
                                  '₹${(double.tryParse(r['amount']?.toString() ?? '0') ?? 0).toStringAsFixed(0)}',
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
          );
        },
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
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

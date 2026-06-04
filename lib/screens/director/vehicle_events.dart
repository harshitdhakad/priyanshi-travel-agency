import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/app_theme.dart';

class VehicleEventsScreen extends StatelessWidget {
  final SupabaseService supabaseService;
  const VehicleEventsScreen({super.key, required this.supabaseService});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabaseService.eventsStream(),
        builder: (context, snap) {
          final events = snap.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Vehicle Events',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      '${events.length} events',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (events.isEmpty)
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
                          Icons.event_busy,
                          size: 40,
                          color: AppTheme.textHint,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No vehicle events',
                          style: TextStyle(color: AppTheme.textHint),
                        ),
                      ],
                    ),
                  )
                else
                  ...events.map((e) {
                    final eventType = e['event_type']?.toString() ?? 'Other';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _eventColor(
                                  eventType,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _eventIcon(eventType),
                                color: _eventColor(eventType),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    eventType,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    e['description']?.toString() ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Vehicle: ${e['vehicle_number'] ?? 'N/A'}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (e['event_date'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Date: ${e['event_date']}',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                  if (e['next_due_date'] != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.event_busy,
                                          size: 12,
                                          color: Colors.orange[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Next: ${e['next_due_date']}',
                                          style: TextStyle(
                                            color: Colors.orange[700],
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (e['cost'] != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Cost: ₹${(double.tryParse(e['cost'].toString()) ?? 0).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _eventColor(String type) {
    switch (type.toLowerCase()) {
      case 'service':
        return AppTheme.primary;
      case 'insurance':
        return AppTheme.success;
      case 'pucc':
        return AppTheme.warning;
      case 'fitness':
        return AppTheme.accent;
      default:
        return AppTheme.secondary;
    }
  }

  IconData _eventIcon(String type) {
    switch (type.toLowerCase()) {
      case 'service':
        return Icons.build;
      case 'insurance':
        return Icons.shield;
      case 'pucc':
        return Icons.eco;
      case 'fitness':
        return Icons.fitness_center;
      default:
        return Icons.event;
    }
  }
}

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class VehicleEventsScreen extends StatelessWidget {
  final AuthService authService;
  const VehicleEventsScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    final events = authService.vehicleEvents;

    return Container(
      color: const Color(0xFFF5F5F5),
      child: SingleChildScrollView(
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
                    color: Color(0xFF1A237E),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Event'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...events.map(
              (e) => Card(
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
                          color: _eventColor(e.eventType).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _eventIcon(e.eventType),
                          color: _eventColor(e.eventType),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  e.eventType,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _eventColor(
                                      e.eventType,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    e.vehicleNumber,
                                    style: TextStyle(
                                      color: _eventColor(e.eventType),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              e.description,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Done: ${e.eventDate.day}/${e.eventDate.month}/${e.eventDate.year}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                  ),
                                ),
                                if (e.nextDueDate != null) ...[
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.event_busy,
                                    size: 12,
                                    color: Colors.orange[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Next: ${e.nextDueDate!.day}/${e.nextDueDate!.month}/${e.nextDueDate!.year}',
                                    style: TextStyle(
                                      color: Colors.orange[700],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (e.cost != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Cost: ₹${e.cost!.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A237E),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _eventColor(String type) {
    switch (type.toLowerCase()) {
      case 'service':
        return const Color(0xFF1A237E);
      case 'insurance':
        return Colors.green;
      case 'pucc':
        return const Color(0xFFE65100);
      case 'fitness':
        return Colors.purple;
      default:
        return Colors.blue;
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

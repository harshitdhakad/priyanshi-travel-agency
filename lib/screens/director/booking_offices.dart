import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class BookingOfficesScreen extends StatelessWidget {
  final AuthService authService;
  const BookingOfficesScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    final bookings = authService.bookings;
    final totalRevenue = bookings
        .where((b) => b.status == 'completed')
        .fold(0.0, (s, b) => s + b.amount);
    final pending = bookings.where((b) => b.status == 'pending').length;
    final confirmed = bookings.where((b) => b.status == 'confirmed').length;

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
                  'Revenue',
                  '₹${totalRevenue.toStringAsFixed(0)}',
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _summaryCard('Pending', '$pending', Colors.orange),
                const SizedBox(width: 12),
                _summaryCard(
                  'Confirmed',
                  '$confirmed',
                  const Color(0xFF1A237E),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bookings',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Booking'),
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
            const SizedBox(height: 14),
            ...bookings.map(
              (b) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _statusColor(b.status),
                            radius: 18,
                            child: Icon(
                              _statusIcon(b.status),
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b.customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  b.customerPhone,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${b.amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            b.pickupLocation,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Icon(
                            Icons.flag_outlined,
                            size: 16,
                            color: Colors.red[700],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              b.dropLocation,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${b.bookingDate.day}/${b.bookingDate.month}/${b.bookingDate.year}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(b.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              b.status[0].toUpperCase() + b.status.substring(1),
                              style: TextStyle(
                                color: _statusColor(b.status),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Office Locations',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 14),
            ..._officeCards(),
          ],
        ),
      ),
    );
  }

  List<Widget> _officeCards() {
    final offices = [
      {
        'name': 'Head Office - Jaipur',
        'address': 'Plot 45, MI Road, Jaipur, Rajasthan',
        'phone': '+91 141 2345678',
      },
      {
        'name': 'Branch - Delhi',
        'address': 'Sector 18, Noida, Delhi NCR',
        'phone': '+91 120 4567890',
      },
      {
        'name': 'Branch - Udaipur',
        'address': 'Lake Palace Road, Udaipur, Rajasthan',
        'phone': '+91 294 2345678',
      },
    ];
    return offices
        .map(
          (o) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.business,
                  color: Color(0xFF1A237E),
                  size: 22,
                ),
              ),
              title: Text(
                o['name']!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                '${o['address']}\n${o['phone']}',
                style: const TextStyle(fontSize: 11),
              ),
              isThreeLine: true,
            ),
          ),
        )
        .toList();
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

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check;
      case 'pending':
        return Icons.hourglass_empty;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.close;
      default:
        return Icons.help;
    }
  }
}

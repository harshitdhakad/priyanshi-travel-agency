import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class DriverHome extends StatelessWidget {
  final AuthService authService;
  const DriverHome({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser!;
    final myDiesel = authService.dieselRecords
        .where((d) => d.driverId == user.id)
        .toList();
    final myRoutes = authService.carRoutes
        .where((r) => r.driverId == user.id)
        .toList();
    final myBookings = authService.bookings
        .where((b) => b.driverId == user.id)
        .toList();
    final totalLitres = myDiesel.fold(0.0, (s, d) => s + d.litres);

    return Container(
      color: const Color(0xFFF5F5F5),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${user.name.split(' ').first}!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vehicle: ${user.vehicleAssigned ?? 'Not assigned'}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'License: ${user.licenseNumber ?? 'N/A'}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats row
            Row(
              children: [
                _statCard(
                  'My Routes',
                  '${myRoutes.length}',
                  Icons.route,
                  const Color(0xFF1A237E),
                ),
                const SizedBox(width: 12),
                _statCard(
                  'Diesel Used',
                  '${totalLitres.toStringAsFixed(0)}L',
                  Icons.local_gas_station,
                  const Color(0xFFE65100),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard(
                  'Bookings',
                  '${myBookings.length}',
                  Icons.book_online,
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _statCard(
                  'Salary',
                  '₹${(user.salary ?? 0).toStringAsFixed(0)}',
                  Icons.payments,
                  const Color(0xFF0D47A1),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Upcoming bookings
            const Text(
              'Upcoming Trips',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 14),
            if (myBookings.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No upcoming trips',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            else
              ...myBookings.map(
                (b) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.withOpacity(0.1),
                      child: const Icon(
                        Icons.directions_car,
                        color: Colors.green,
                      ),
                    ),
                    title: Text(
                      b.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${b.pickupLocation} → ${b.dropLocation}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      '${b.bookingDate.day}/${b.bookingDate.month}',
                      style: const TextStyle(
                        color: Color(0xFF1A237E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),
            // Assigned routes
            const Text(
              'My Routes',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 14),
            ...myRoutes.map(
              (r) => Card(
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
                    child: const Icon(Icons.route, color: Color(0xFF1A237E)),
                  ),
                  title: Text(
                    r.routeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${r.distanceKm.toStringAsFixed(0)} km · ${r.estimatedTime.toStringAsFixed(1)} hrs',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, color: Colors.white.withOpacity(0.5), size: 28),
          ],
        ),
      ),
    );
  }
}

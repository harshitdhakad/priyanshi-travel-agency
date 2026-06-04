import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class DriverRoutesScreen extends StatelessWidget {
  final AuthService authService;
  const DriverRoutesScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser!;
    final routes = authService.carRoutes
        .where((r) => r.driverId == user.id)
        .toList();
    final allRoutes = authService.carRoutes;

    return Container(
      color: const Color(0xFFF5F5F5),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // My Routes section
            Row(
              children: [
                const Icon(Icons.route, color: Color(0xFF1A237E), size: 22),
                const SizedBox(width: 8),
                Text(
                  'My Routes (${routes.length})',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (routes.isEmpty)
              _emptyState('No routes assigned')
            else
              ...routes.map(
                (r) => _routeCard(
                  r.routeName,
                  r.from,
                  r.to,
                  r.distanceKm,
                  r.estimatedTime,
                  true,
                ),
              ),

            const SizedBox(height: 28),
            // All routes
            Row(
              children: [
                const Icon(Icons.map_outlined, color: Colors.grey, size: 22),
                const SizedBox(width: 8),
                Text(
                  'All Routes (${allRoutes.length})',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...allRoutes
                .where((r) => r.driverId != user.id)
                .map(
                  (r) => _routeCard(
                    r.routeName,
                    r.from,
                    r.to,
                    r.distanceKm,
                    r.estimatedTime,
                    false,
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _routeCard(
    String name,
    String from,
    String to,
    double distance,
    double time,
    bool isMine,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isMine
                    ? const Color(0xFF1A237E).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.route,
                color: isMine ? const Color(0xFF1A237E) : Colors.grey,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isMine
                          ? const Color(0xFF1A237E)
                          : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.green[700],
                      ),
                      Text(' $from', style: const TextStyle(fontSize: 11)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Icon(
                        Icons.flag_outlined,
                        size: 14,
                        color: Colors.red[700],
                      ),
                      Text(' $to', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${distance.toStringAsFixed(0)} km',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${time.toStringAsFixed(1)} hrs',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String msg) {
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
          Icon(Icons.route, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(msg, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}

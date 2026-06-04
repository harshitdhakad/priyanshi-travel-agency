import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/app_theme.dart';

class DriverRoutesScreen extends StatelessWidget {
  final SupabaseService supabaseService;
  final String? driverId;
  const DriverRoutesScreen({
    super.key,
    required this.supabaseService,
    this.driverId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabaseService.tableStream('car_routes'),
        builder: (context, snap) {
          final allRoutes = snap.data ?? [];
          final myRoutes = driverId != null
              ? allRoutes.where((r) => r['driver_id'] == driverId).toList()
              : [];
          final otherRoutes = allRoutes
              .where((r) => r['driver_id'] != driverId)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // My Routes
                Row(
                  children: [
                    const Icon(Icons.route, color: AppTheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'My Routes (${myRoutes.length})',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (myRoutes.isEmpty)
                  _emptyState('No routes assigned')
                else
                  ...myRoutes.map((r) => _routeCard(r, true)),

                const SizedBox(height: 28),
                // All routes
                Row(
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      color: AppTheme.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All Routes (${otherRoutes.length})',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...otherRoutes.map((r) => _routeCard(r, false)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _routeCard(Map<String, dynamic> r, bool isMine) {
    final distance = double.tryParse(r['distance_km']?.toString() ?? '0') ?? 0;
    final time = double.tryParse(r['estimated_time']?.toString() ?? '0') ?? 0;
    final name =
        r['route_name']?.toString() ?? '${r['from'] ?? ''} - ${r['to'] ?? ''}';

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
                    ? AppTheme.primary.withValues(alpha: 0.1)
                    : AppTheme.textHint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.route,
                color: isMine ? AppTheme.primary : AppTheme.textHint,
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
                      color: isMine ? AppTheme.primary : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppTheme.success,
                      ),
                      Text(
                        ' ${r['from'] ?? ''}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: AppTheme.textHint,
                        ),
                      ),
                      Icon(
                        Icons.flag_outlined,
                        size: 14,
                        color: AppTheme.error,
                      ),
                      Text(
                        ' ${r['to'] ?? ''}',
                        style: const TextStyle(fontSize: 11),
                      ),
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
                  style: TextStyle(color: AppTheme.textHint, fontSize: 11),
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Icon(Icons.route, size: 40, color: AppTheme.textHint),
          const SizedBox(height: 8),
          Text(msg, style: TextStyle(color: AppTheme.textHint)),
        ],
      ),
    );
  }
}

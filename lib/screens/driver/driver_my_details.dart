import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/app_theme.dart';

class DriverMyDetailsScreen extends StatelessWidget {
  final AuthService authService;
  const DriverMyDetailsScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser!;

    return Container(
      color: const Color(0xFFF5F5F5),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      user.name[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role.name[0].toUpperCase() +
                          user.role.name.substring(1),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Personal Details
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Personal Details',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    _detailRow(Icons.person_outline, 'Full Name', user.name),
                    _detailRow(
                      Icons.account_circle_outlined,
                      'Username',
                      user.username,
                    ),
                    _detailRow(
                      Icons.phone_outlined,
                      'Phone',
                      user.phone ?? 'Not provided',
                    ),
                    _detailRow(
                      Icons.email_outlined,
                      'Email',
                      user.email ?? 'Not provided',
                    ),
                    _detailRow(
                      Icons.location_on_outlined,
                      'Address',
                      user.address ?? 'Not provided',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Work Details
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Work Details',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    _detailRow(
                      Icons.badge_outlined,
                      'License Number',
                      user.licenseNumber ?? 'N/A',
                    ),
                    _detailRow(
                      Icons.directions_car_outlined,
                      'Vehicle Assigned',
                      user.vehicleAssigned ?? 'Not assigned',
                    ),
                    _detailRow(
                      Icons.payments_outlined,
                      'Monthly Salary',
                      user.salary != null
                          ? '₹${user.salary!.toStringAsFixed(0)}'
                          : 'N/A',
                    ),
                    _detailRow(
                      Icons.calendar_today_outlined,
                      'Joined',
                      '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick stats removed - use Supabase streams
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: AppTheme.textHint, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

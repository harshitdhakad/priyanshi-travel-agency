import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../services/app_theme.dart';
import '../../services/localization_service.dart';
import '../../widgets/credits_footer.dart';
import '../director/salary_management.dart';
import '../director/diesel_details.dart';
import '../director/driver_analysis.dart';
import '../director/vehicle_analysis.dart';
import '../director/vehicle_events.dart';
import '../director/driver_management.dart';
import '../director/vehicle_management.dart';
import '../shared/attendance_screen.dart';
import '../shared/appointed_vehicles_screen.dart';
import '../shared/servicing_screen.dart';
import '../shared/booking_offices_screen.dart' as new_booking;
import '../director/logbook_admin_screen.dart';
import '../shared/events_screen.dart';
import '../shared/google_drive_backup_screen.dart';

class StaffDashboard extends StatefulWidget {
  final AuthService authService;
  final SupabaseService supabaseService;
  const StaffDashboard({
    super.key,
    required this.authService,
    required this.supabaseService,
  });

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _selectedIndex = 0;
  final AppLocalizations _loc = AppLocalizations();

  List<String> get _menuItems => [
    _loc.t('dashboard'),
    _loc.t('salary_management'),
    _loc.t('diesel_details'),
    _loc.t('driver_analysis'),
    _loc.t('vehicle_analysis'),
    _loc.t('vehicle_events'),
    _loc.t('bookings_offices'),
    _loc.t('driver_management'),
    _loc.t('vehicle_management'),
    _loc.t('attendance'),
    _loc.t('appointed_vehicles'),
    _loc.t('servicing'),
    _loc.t('fleet_logbook'),
    _loc.t('events'),
    _loc.t('cloud_backup'),
  ];

  static const List<IconData> _menuIcons = [
    Icons.dashboard_outlined,
    Icons.payments_outlined,
    Icons.local_gas_station_outlined,
    Icons.analytics_outlined,
    Icons.directions_car_outlined,
    Icons.event_outlined,
    Icons.book_online_outlined,
    Icons.people_outline,
    Icons.car_repair_outlined,
    Icons.fact_check_outlined,
    Icons.assignment_outlined,
    Icons.build_outlined,
    Icons.menu_book_outlined,
    Icons.event_note_outlined,
    Icons.cloud_upload_outlined,
  ];

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return _buildStaffHome();
      case 1:
        return SalaryManagementScreen(supabaseService: widget.supabaseService);
      case 2:
        return DieselDetailsScreen(authService: widget.authService);
      case 3:
        return DriverAnalysisScreen(
          authService: widget.authService,
          supabaseService: widget.supabaseService,
        );
      case 4:
        return VehicleAnalysisScreen(supabaseService: widget.supabaseService);
      case 5:
        return VehicleEventsScreen(authService: widget.authService);
      case 6:
        return new_booking.BookingOfficesScreen(
          supabaseService: widget.supabaseService,
        );
      case 7:
        return DriverManagementScreen(supabaseService: widget.supabaseService);
      case 8:
        return VehicleManagementScreen(supabaseService: widget.supabaseService);
      case 9:
        return AttendanceScreen(supabaseService: widget.supabaseService);
      case 10:
        return AppointedVehiclesScreen(supabaseService: widget.supabaseService);
      case 11:
        return ServicingScreen(supabaseService: widget.supabaseService);
      case 12:
        return LogbookAdminScreen(supabaseService: widget.supabaseService);
      case 13:
        return EventsScreen(supabaseService: widget.supabaseService);
      case 14:
        return GoogleDriveBackupScreen(supabaseService: widget.supabaseService);
      default:
        return _buildStaffHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_menuItems[_selectedIndex]),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => widget.authService.logout(),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          Expanded(child: _getScreen(_selectedIndex)),
          const CreditsFooter(),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: AppTheme.background,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.badge,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.authService.currentUser?.name ?? _loc.t('staff'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_loc.t('staff')} \u00b7 ${_loc.t('app_name')}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            ...List.generate(_menuItems.length, (index) {
              final isSelected = _selectedIndex == index;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: Icon(
                    _menuIcons[index],
                    color: isSelected ? AppTheme.primary : Colors.grey[700],
                    size: 22,
                  ),
                  title: Text(
                    _menuItems[index],
                    style: TextStyle(
                      color: isSelected ? AppTheme.primary : Colors.grey[800],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14.5,
                    ),
                  ),
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    Navigator.pop(context);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                ),
              );
            }),
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red[700], size: 22),
                title: Text(
                  _loc.t('logout'),
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.authService.logout();
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffHome() {
    final vehicles = widget.authService.vehicles;
    final drivers = widget.authService.drivers;
    final bookings = widget.authService.bookings;

    return Container(
      color: AppTheme.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _loc.t('dashboard'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _loc.locale == 'hi'
                  ? 'संचालन का प्रबंधन करें'
                  : 'Manage operations efficiently',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _statCard(
                  _loc.t('total_drivers'),
                  '${drivers.length}',
                  Icons.drive_eta,
                  AppTheme.primary,
                ),
                const SizedBox(width: 12),
                _statCard(
                  _loc.t('total_vehicles'),
                  '${vehicles.length}',
                  Icons.directions_car,
                  AppTheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard(
                  _loc.t('bookings'),
                  '${bookings.length}',
                  Icons.book_online,
                  AppTheme.success,
                ),
                const SizedBox(width: 12),
                _statCard(
                  _loc.t('active_vehicles'),
                  '${vehicles.where((v) => v.status == 'active').length}',
                  Icons.check_circle_outline,
                  AppTheme.success,
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              _loc.t('quick_actions'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _quickAction(
                  _loc.t('driver_management'),
                  Icons.people,
                  () => setState(() => _selectedIndex = 7),
                ),
                _quickAction(
                  _loc.t('vehicle_management'),
                  Icons.directions_car,
                  () => setState(() => _selectedIndex = 8),
                ),
                _quickAction(
                  _loc.t('bookings_offices'),
                  Icons.book,
                  () => setState(() => _selectedIndex = 6),
                ),
                _quickAction(
                  _loc.t('diesel_details'),
                  Icons.local_gas_station,
                  () => setState(() => _selectedIndex = 2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Icon(icon, color: Colors.white.withOpacity(0.6), size: 28),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13.5,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

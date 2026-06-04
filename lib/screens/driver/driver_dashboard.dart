import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../services/app_theme.dart';
import '../../services/localization_service.dart';
import '../../widgets/credits_footer.dart';
import 'driver_home_screen.dart';
import 'driver_routes.dart';
import 'driver_about.dart';
import 'driver_my_details.dart';
import 'driver_logbook_screen.dart';
import 'diesel_purchase_screen.dart';
import 'driver_booking_screen.dart';
import '../shared/attendance_screen.dart';
import '../shared/appointed_vehicles_screen.dart';
import '../shared/servicing_screen.dart';
import '../shared/booking_offices_screen.dart';
import '../shared/events_screen.dart';
import '../director/salary_management.dart';

class DriverDashboard extends StatefulWidget {
  final AuthService authService;
  final SupabaseService supabaseService;
  const DriverDashboard({
    super.key,
    required this.authService,
    required this.supabaseService,
  });

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _selectedIndex = 0;
  final AppLocalizations _loc = AppLocalizations();

  List<String> get _menuItems => [
    _loc.t('home'),
    _loc.t('attendance'),
    _loc.t('salary_details'),
    _loc.t('diesel_purchases'),
    _loc.t('my_appointed_vehicle'),
    _loc.t('servicing'),
    _loc.t('offices_bookings'),
    _loc.t('booking_trips'),
    _loc.t('fill_logbook'),
    _loc.t('car_routes'),
    _loc.t('about_us'),
    _loc.t('my_details'),
    _loc.t('events'),
  ];

  static const List<IconData> _menuIcons = [
    Icons.home_outlined,
    Icons.fact_check_outlined,
    Icons.payments_outlined,
    Icons.local_gas_station_outlined,
    Icons.directions_car_outlined,
    Icons.build_outlined,
    Icons.book_online_outlined,
    Icons.bookmark_outline,
    Icons.menu_book_outlined,
    Icons.route_outlined,
    Icons.info_outline,
    Icons.person_outline,
    Icons.event_note_outlined,
  ];

  Widget _getScreen(int index) {
    final driverId = widget.authService.currentUser?.id;
    switch (index) {
      case 0:
        return DriverHomeScreen(
          supabaseService: widget.supabaseService,
          driverId: driverId,
          monthlySalary:
              double.tryParse(
                widget.authService.currentUser?.salary?.toString() ?? '',
              ) ??
              0,
        );
      case 1:
        return AttendanceScreen(
          supabaseService: widget.supabaseService,
          isDriverView: true,
          currentDriverId: driverId,
        );
      case 2:
        return SalaryManagementScreen(
          supabaseService: widget.supabaseService,
          isDriverView: true,
          currentDriverId: driverId,
        );
      case 3:
        return DieselPurchaseScreen(
          supabaseService: widget.supabaseService,
          driverId: driverId,
        );
      case 4:
        return AppointedVehiclesScreen(
          supabaseService: widget.supabaseService,
          isDriverView: true,
          currentDriverId: driverId,
        );
      case 5:
        return ServicingScreen(
          supabaseService: widget.supabaseService,
          isDriverView: true,
          currentDriverId: driverId,
        );
      case 6:
        return BookingOfficesScreen(
          supabaseService: widget.supabaseService,
          isDriverView: true,
          currentDriverId: driverId,
        );
      case 7:
        return DriverBookingScreen(
          supabaseService: widget.supabaseService,
          driverId: driverId,
        );
      case 8:
        return DriverLogbookScreen(
          supabaseService: widget.supabaseService,
          driverId: driverId,
        );
      case 9:
        return DriverRoutesScreen(authService: widget.authService);
      case 10:
        return const DriverAboutScreen();
      case 11:
        return DriverMyDetailsScreen(authService: widget.authService);
      case 12:
        return EventsScreen(
          supabaseService: widget.supabaseService,
          isDriverView: true,
        );
      default:
        return DriverHomeScreen(
          supabaseService: widget.supabaseService,
          driverId: driverId,
          monthlySalary:
              double.tryParse(
                widget.authService.currentUser?.salary?.toString() ?? '',
              ) ??
              0,
        );
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
    final user = widget.authService.currentUser;
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
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      user?.name[0] ?? 'D',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.name ?? _loc.t('driver'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.vehicleAssigned ?? _loc.t('app_name'),
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
}

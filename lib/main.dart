import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'services/app_theme.dart';
import 'services/localization_service.dart';
import 'screens/login_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/language_selector.dart';
import 'screens/director/director_dashboard.dart';
import 'screens/driver/driver_dashboard.dart';
import 'screens/staff/staff_dashboard.dart';
import 'models/user_model.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  await AppLocalizations().loadLocale();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService _authService = AuthService();
  final SupabaseService _supabaseService = SupabaseService();
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  final AppLocalizations _loc = AppLocalizations();

  bool _checkingTables = true;
  bool _tablesExist = false;
  bool _showSplash = true;
  bool _splashFired = false;
  bool _checkingLanguage = true;
  bool _needsLanguageSelection = false;
  Timer? _reminderTimer;

  @override
  void initState() {
    super.initState();
    _loc.addListener(() => setState(() {}));
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      final hasChosen = await _loc.hasChosenLanguage();
      final tablesExist = await _supabaseService.checkTablesExist().timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      );
      if (!mounted) return;
      setState(() {
        _checkingLanguage = false;
        _needsLanguageSelection = !hasChosen;
        _tablesExist = tablesExist;
        _checkingTables = false;
      });
    } catch (_) {
      // If anything fails, still proceed past splash
      if (!mounted) return;
      setState(() {
        _checkingLanguage = false;
        _checkingTables = false;
        _tablesExist = false;
      });
    }
    _startReminderTimer();
  }

  void _onSplashComplete() {
    if (!_splashFired && mounted) {
      setState(() {
        _splashFired = true;
        _showSplash = false;
      });
    }
  }

  void _startReminderTimer() {
    _reminderTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkLogbookReminder();
      _supabaseService.checkExpiredAppointments();
    });
  }

  Future<void> _checkLogbookReminder() async {
    final now = DateTime.now();
    if (now.hour == 21 && now.minute == 0) {
      if (_authService.isLoggedIn &&
          _authService.currentUser?.role == UserRole.driver) {
        final driverId = _authService.currentUser?.id;
        if (driverId == null) return;
        try {
          final today = DateFormat('yyyy-MM-dd').format(now);

          // Check if driver is absent or on holiday today
          final attendance = await _supabaseService.getAttendance(
            driverId: driverId,
          );
          final todayAtt = attendance.where((a) => a['date'] == today).toList();
          if (todayAtt.isNotEmpty) {
            final status = todayAtt.first['status'];
            if (status == 'absent' || status == 'holiday') return;
          }

          // Check if logbook already filled for today
          final logbooks = await _supabaseService.getLogbooks(
            driverId: driverId,
          );
          final todayLog = logbooks
              .where((l) => l['log_date'] == today)
              .toList();
          if (todayLog.isEmpty && _navKey.currentContext != null) {
            showDialog(
              context: _navKey.currentContext!,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    const Icon(Icons.alarm, color: AppTheme.error, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      _loc.t('fill_logbook'),
                      style: const TextStyle(
                        color: AppTheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  "It's 9 PM! You haven't filled today's logbook entry yet. Please fill it before going to sleep.",
                  style: const TextStyle(fontSize: 14),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("OK, I'll fill it now"),
                  ),
                ],
              ),
            );
          }
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    _loc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Priyanshi Travel Agency',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navKey,
      theme: AppTheme.lightTheme,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    // Show splash only once - during initial loading or dedicated splash phase
    if (!_splashFired) {
      return AnimatedSplashScreen(onComplete: _onSplashComplete);
    }
    // Still loading after splash - show simple loading indicator
    if (_checkingLanguage || _checkingTables) {
      return Scaffold(
        body: Container(
          color: AppTheme.background,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.primary),
                SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: TextStyle(color: AppTheme.textHint, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // Language selector
    if (_needsLanguageSelection) {
      return LanguageSelectorScreen(
        onLanguageSelected: () =>
            setState(() => _needsLanguageSelection = false),
      );
    }
    // Setup screen
    if (!_tablesExist) {
      return SetupScreen(
        supabaseService: _supabaseService,
        onSetupDone: () {
          _checkTables();
        },
      );
    }
    return _buildApp();
  }

  Future<void> _checkTables() async {
    final exist = await _supabaseService.checkTablesExist();
    setState(() {
      _tablesExist = exist;
    });
  }

  Widget _buildApp() {
    return AnimatedBuilder(
      animation: _authService,
      builder: (context, _) {
        if (!_authService.isLoggedIn) {
          return LoginScreen(
            authService: _authService,
            supabaseService: _supabaseService,
          );
        }
        final user = _authService.currentUser!;
        switch (user.role) {
          case UserRole.director:
            return DirectorDashboard(
              authService: _authService,
              supabaseService: _supabaseService,
            );
          case UserRole.driver:
            return DriverDashboard(
              authService: _authService,
              supabaseService: _supabaseService,
            );
          case UserRole.staff:
            return StaffDashboard(
              authService: _authService,
              supabaseService: _supabaseService,
            );
        }
      },
    );
  }
}

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Hardcoded director credentials
  static const String directorUsername = 'harshit';
  static const String directorPassword = 'harshit@23122010';

  // All registered users
  final List<AppUser> _users = [
    AppUser(
      id: 'director_001',
      username: 'harshit',
      password: 'harshit@23122010',
      role: UserRole.director,
      name: 'Harshit (Director)',
      phone: '+91 98765 43210',
      email: 'harshit@priyanshi.com',
      address: 'Jaipur, Rajasthan',
    ),
    // Sample driver
    AppUser(
      id: 'driver_001',
      username: 'ramesh',
      password: 'ramesh@123',
      role: UserRole.driver,
      name: 'Ramesh Kumar',
      phone: '+91 99887 76655',
      email: 'ramesh@priyanshi.com',
      licenseNumber: 'RJ14-2021-0001234',
      vehicleAssigned: 'RJ-14 CB 1234',
      salary: 18000,
    ),
    // Sample staff
    AppUser(
      id: 'staff_001',
      username: 'priya',
      password: 'priya@123',
      role: UserRole.staff,
      name: 'Priya Sharma',
      phone: '+91 88776 65544',
      email: 'priya@priyanshi.com',
      salary: 22000,
    ),
  ];

  List<AppUser> get users => List.unmodifiable(_users);
  List<AppUser> get drivers =>
      _users.where((u) => u.role == UserRole.driver).toList();
  List<AppUser> get staffMembers =>
      _users.where((u) => u.role == UserRole.staff).toList();

  // Sample vehicles
  final List<Vehicle> vehicles = [
    Vehicle(
      id: 'v1',
      vehicleNumber: 'RJ-14 CB 1234',
      model: 'Innova Crysta',
      brand: 'Toyota',
      year: 2023,
      assignedDriverId: 'driver_001',
      totalKm: 45200,
      status: 'active',
    ),
    Vehicle(
      id: 'v2',
      vehicleNumber: 'RJ-14 AB 5678',
      model: 'Swift Dzire',
      brand: 'Maruti',
      year: 2022,
      totalKm: 62100,
      status: 'active',
    ),
    Vehicle(
      id: 'v3',
      vehicleNumber: 'RJ-14 XY 9012',
      model: 'Ertiga',
      brand: 'Maruti',
      year: 2024,
      totalKm: 18500,
      status: 'idle',
    ),
    Vehicle(
      id: 'v4',
      vehicleNumber: 'RJ-14 MN 3456',
      model: 'Fortuner',
      brand: 'Toyota',
      year: 2023,
      totalKm: 33000,
      status: 'maintenance',
    ),
  ];

  // Sample diesel records
  final List<DieselRecord> dieselRecords = [
    DieselRecord(
      id: 'd1',
      vehicleId: 'v1',
      vehicleNumber: 'RJ-14 CB 1234',
      driverId: 'driver_001',
      driverName: 'Ramesh Kumar',
      litres: 45,
      amount: 4050,
      kmReading: 45200,
      date: DateTime(2026, 5, 28),
    ),
    DieselRecord(
      id: 'd2',
      vehicleId: 'v2',
      vehicleNumber: 'RJ-14 AB 5678',
      litres: 38,
      amount: 3420,
      kmReading: 62100,
      date: DateTime(2026, 5, 30),
    ),
    DieselRecord(
      id: 'd3',
      vehicleId: 'v1',
      vehicleNumber: 'RJ-14 CB 1234',
      driverId: 'driver_001',
      driverName: 'Ramesh Kumar',
      litres: 50,
      amount: 4500,
      kmReading: 44800,
      date: DateTime(2026, 5, 20),
    ),
    DieselRecord(
      id: 'd4',
      vehicleId: 'v3',
      vehicleNumber: 'RJ-14 XY 9012',
      litres: 42,
      amount: 3780,
      kmReading: 18500,
      date: DateTime(2026, 6, 1),
    ),
  ];

  // Sample salary records
  final List<SalaryRecord> salaryRecords = [
    SalaryRecord(
      id: 's1',
      userId: 'driver_001',
      userName: 'Ramesh Kumar',
      baseSalary: 18000,
      bonus: 2000,
      deduction: 500,
      total: 19500,
      month: 'May 2026',
      isPaid: true,
      date: DateTime(2026, 5, 31),
    ),
    SalaryRecord(
      id: 's2',
      userId: 'staff_001',
      userName: 'Priya Sharma',
      baseSalary: 22000,
      bonus: 1000,
      deduction: 0,
      total: 23000,
      month: 'May 2026',
      isPaid: true,
      date: DateTime(2026, 5, 31),
    ),
    SalaryRecord(
      id: 's3',
      userId: 'driver_001',
      userName: 'Ramesh Kumar',
      baseSalary: 18000,
      bonus: 0,
      deduction: 1000,
      total: 17000,
      month: 'April 2026',
      isPaid: true,
      date: DateTime(2026, 4, 30),
    ),
  ];

  // Sample bookings
  final List<Booking> bookings = [
    Booking(
      id: 'b1',
      customerName: 'Amit Verma',
      customerPhone: '+91 91234 56789',
      pickupLocation: 'Jaipur Airport',
      dropLocation: 'Udaipur',
      bookingDate: DateTime(2026, 6, 5),
      vehicleId: 'v1',
      driverId: 'driver_001',
      amount: 8500,
      status: 'confirmed',
    ),
    Booking(
      id: 'b2',
      customerName: 'Sneha Gupta',
      customerPhone: '+91 87654 32109',
      pickupLocation: 'Jaipur Junction',
      dropLocation: 'Jodhpur',
      bookingDate: DateTime(2026, 6, 8),
      amount: 6000,
      status: 'pending',
    ),
    Booking(
      id: 'b3',
      customerName: 'Rajesh Singh',
      customerPhone: '+91 76543 21098',
      pickupLocation: 'Delhi',
      dropLocation: 'Agra',
      bookingDate: DateTime(2026, 6, 2),
      vehicleId: 'v2',
      amount: 4500,
      status: 'completed',
    ),
  ];

  // Sample vehicle events
  final List<VehicleEvent> vehicleEvents = [
    VehicleEvent(
      id: 've1',
      vehicleId: 'v1',
      vehicleNumber: 'RJ-14 CB 1234',
      eventType: 'Service',
      description: 'Regular 50K service',
      eventDate: DateTime(2026, 5, 15),
      nextDueDate: DateTime(2026, 11, 15),
      cost: 8500,
    ),
    VehicleEvent(
      id: 've2',
      vehicleId: 'v4',
      vehicleNumber: 'RJ-14 MN 3456',
      eventType: 'Insurance',
      description: 'Annual insurance renewal',
      eventDate: DateTime(2026, 4, 1),
      nextDueDate: DateTime(2027, 4, 1),
      cost: 22000,
    ),
    VehicleEvent(
      id: 've3',
      vehicleId: 'v2',
      vehicleNumber: 'RJ-14 AB 5678',
      eventType: 'PUCC',
      description: 'Pollution certificate renewal',
      eventDate: DateTime(2026, 3, 20),
      nextDueDate: DateTime(2026, 9, 20),
    ),
  ];

  // Sample car routes
  final List<CarRoute> carRoutes = [
    CarRoute(
      id: 'r1',
      routeName: 'Jaipur - Udaipur',
      from: 'Jaipur',
      to: 'Udaipur',
      distanceKm: 394,
      estimatedTime: 6.5,
      vehicleId: 'v1',
      driverId: 'driver_001',
    ),
    CarRoute(
      id: 'r2',
      routeName: 'Jaipur - Jodhpur',
      from: 'Jaipur',
      to: 'Jodhpur',
      distanceKm: 335,
      estimatedTime: 5.5,
    ),
    CarRoute(
      id: 'r3',
      routeName: 'Delhi - Agra',
      from: 'Delhi',
      to: 'Agra',
      distanceKm: 230,
      estimatedTime: 3.5,
      vehicleId: 'v2',
    ),
    CarRoute(
      id: 'r4',
      routeName: 'Jaipur - Pushkar',
      from: 'Jaipur',
      to: 'Pushkar',
      distanceKm: 150,
      estimatedTime: 2.5,
    ),
  ];

  // Login
  String? login(String username, String password, UserRole selectedRole) {
    try {
      final user = _users.firstWhere(
        (u) =>
            u.username == username &&
            u.password == password &&
            u.role == selectedRole,
      );
      _currentUser = user;
      notifyListeners();
      return null; // no error
    } catch (_) {
      return 'Invalid credentials or wrong role selected';
    }
  }

  // Login from Supabase profile data
  void loginFromProfile(Map<String, dynamic> profile, UserRole role) {
    _currentUser = AppUser(
      id: profile['id']?.toString() ?? '',
      username: profile['username'] ?? '',
      password: profile['password'] ?? '',
      role: role,
      name: profile['name'] ?? '',
      phone: profile['phone'],
      email: profile['email'],
      address: profile['address'],
      licenseNumber: profile['license_number'],
      vehicleAssigned: profile['vehicle_assigned'],
      salary: profile['salary'] != null
          ? (profile['salary'] as num).toDouble()
          : null,
    );
    notifyListeners();
  }

  // Add driver
  AppUser addDriver({
    required String username,
    required String password,
    required String name,
    String? phone,
    String? email,
    String? licenseNumber,
    double? salary,
  }) {
    final driver = AppUser(
      id: 'driver_${_users.length + 1}',
      username: username,
      password: password,
      role: UserRole.driver,
      name: name,
      phone: phone,
      email: email,
      licenseNumber: licenseNumber,
      salary: salary,
    );
    _users.add(driver);
    notifyListeners();
    return driver;
  }

  // Add staff
  AppUser addStaff({
    required String username,
    required String password,
    required String name,
    String? phone,
    String? email,
    double? salary,
  }) {
    final staff = AppUser(
      id: 'staff_${_users.length + 1}',
      username: username,
      password: password,
      role: UserRole.staff,
      name: name,
      phone: phone,
      email: email,
      salary: salary,
    );
    _users.add(staff);
    notifyListeners();
    return staff;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}

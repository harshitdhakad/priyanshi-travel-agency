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

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService extends ChangeNotifier {
  SupabaseClient get client => Supabase.instance.client;
  bool _tablesExist = false;
  bool get tablesExist => _tablesExist;

  // ── SQL to create all tables ──
  static const String setupSQL = '''
-- Profiles table (drivers, staff, director)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('director','driver','staff')),
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  address TEXT,
  license_number TEXT,
  vehicle_assigned TEXT,
  salary NUMERIC DEFAULT 0,
  joining_date DATE DEFAULT CURRENT_DATE,
  driver_no TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Vehicles table
CREATE TABLE IF NOT EXISTS vehicles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  car_name TEXT NOT NULL,
  model_no TEXT NOT NULL,
  number_plate TEXT UNIQUE NOT NULL,
  year INT DEFAULT 2024,
  assigned_driver_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  total_km NUMERIC DEFAULT 0,
  status TEXT DEFAULT 'active' CHECK (status IN ('active','maintenance','idle')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Diesel records
CREATE TABLE IF NOT EXISTS diesel_records (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  vehicle_id UUID REFERENCES vehicles(id) ON DELETE CASCADE,
  vehicle_number TEXT,
  driver_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  driver_name TEXT,
  litres NUMERIC NOT NULL,
  amount NUMERIC NOT NULL,
  km_reading NUMERIC DEFAULT 0,
  record_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Salary records
CREATE TABLE IF NOT EXISTS salary_records (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  user_name TEXT NOT NULL,
  base_salary NUMERIC DEFAULT 0,
  bonus NUMERIC DEFAULT 0,
  deduction NUMERIC DEFAULT 0,
  total NUMERIC DEFAULT 0,
  month TEXT NOT NULL,
  is_paid BOOLEAN DEFAULT FALSE,
  record_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bookings
CREATE TABLE IF NOT EXISTS bookings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  customer_name TEXT NOT NULL,
  customer_phone TEXT,
  pickup_location TEXT NOT NULL,
  drop_location TEXT NOT NULL,
  booking_date DATE DEFAULT CURRENT_DATE,
  vehicle_id UUID REFERENCES vehicles(id) ON DELETE SET NULL,
  driver_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  amount NUMERIC DEFAULT 0,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','confirmed','completed','cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Vehicle events
CREATE TABLE IF NOT EXISTS vehicle_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  vehicle_id UUID REFERENCES vehicles(id) ON DELETE CASCADE,
  vehicle_number TEXT,
  event_type TEXT NOT NULL,
  description TEXT,
  event_date DATE DEFAULT CURRENT_DATE,
  next_due_date DATE,
  cost NUMERIC DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Car routes
CREATE TABLE IF NOT EXISTS car_routes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  route_name TEXT NOT NULL,
  from_location TEXT NOT NULL,
  to_location TEXT NOT NULL,
  distance_km NUMERIC DEFAULT 0,
  estimated_time NUMERIC DEFAULT 0,
  vehicle_id UUID REFERENCES vehicles(id) ON DELETE SET NULL,
  driver_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Offices
CREATE TABLE IF NOT EXISTS offices (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  address TEXT,
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable real-time for all tables
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE vehicles;
ALTER PUBLICATION supabase_realtime ADD TABLE diesel_records;
ALTER PUBLICATION supabase_realtime ADD TABLE salary_records;
ALTER PUBLICATION supabase_realtime ADD TABLE bookings;
ALTER PUBLICATION supabase_realtime ADD TABLE vehicle_events;
ALTER PUBLICATION supabase_realtime ADD TABLE car_routes;
ALTER PUBLICATION supabase_realtime ADD TABLE offices;

-- Insert default director if not exists
INSERT INTO profiles (username, password, role, name, phone, email)
SELECT 'harshit', 'harshit@23122010', 'director', 'Harshit (Director)', '+91 98765 43210', 'harshit@priyanshi.com'
WHERE NOT EXISTS (SELECT 1 FROM profiles WHERE role = 'director');

-- Attendance table
CREATE TABLE IF NOT EXISTS attendance (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  driver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  status TEXT NOT NULL DEFAULT 'present' CHECK (status IN ('present','absent','holiday')),
  marked_by TEXT DEFAULT 'self',
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(driver_id, date)
);
ALTER PUBLICATION supabase_realtime ADD TABLE attendance;

-- Appointed vehicles (driver-vehicle assignment)
CREATE TABLE IF NOT EXISTS appointed_vehicles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  driver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  appointed_date DATE DEFAULT CURRENT_DATE,
  end_date DATE,
  duration_days INTEGER,
  is_active BOOLEAN DEFAULT TRUE,
  is_temporary BOOLEAN DEFAULT FALSE,
  original_driver_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER PUBLICATION supabase_realtime ADD TABLE appointed_vehicles;

-- Servicing records
CREATE TABLE IF NOT EXISTS servicing_records (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  vehicle_number TEXT,
  servicing_date DATE DEFAULT CURRENT_DATE,
  parts_serviced JSONB DEFAULT '[]'::jsonb,
  cost NUMERIC DEFAULT 0,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER PUBLICATION supabase_realtime ADD TABLE servicing_records;

-- Govt offices
CREATE TABLE IF NOT EXISTS govt_offices (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  office_name TEXT NOT NULL,
  joining_date DATE DEFAULT CURRENT_DATE,
  vehicle_id UUID REFERENCES vehicles(id) ON DELETE SET NULL,
  driver_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  monthly_income NUMERIC DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER PUBLICATION supabase_realtime ADD TABLE govt_offices;

-- Booking trips
CREATE TABLE IF NOT EXISTS booking_trips (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  customer_name TEXT NOT NULL,
  destination TEXT,
  vehicle_id UUID REFERENCES vehicles(id) ON DELETE SET NULL,
  driver_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  amount NUMERIC DEFAULT 0,
  payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending','paid')),
  trip_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER PUBLICATION supabase_realtime ADD TABLE booking_trips;

-- Fleet logbooks
CREATE TABLE IF NOT EXISTS fleet_logbooks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  driver_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  vehicle_number TEXT NOT NULL,
  start_odometer NUMERIC DEFAULT 0,
  end_odometer NUMERIC DEFAULT 0,
  total_km NUMERIC GENERATED ALWAYS AS (end_odometer - start_odometer) STORED,
  source TEXT,
  destination TEXT,
  fuel NUMERIC DEFAULT 0,
  toll NUMERIC DEFAULT 0,
  govt_metadata JSONB DEFAULT '{}'::jsonb,
  bill_status TEXT DEFAULT 'draft' CHECK (bill_status IN ('draft','submitted','cleared')),
  log_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER PUBLICATION supabase_realtime ADD TABLE fleet_logbooks;

-- Salary advances (udhaar)
CREATE TABLE IF NOT EXISTS salary_advances (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  driver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount NUMERIC NOT NULL DEFAULT 0,
  reason TEXT,
  advance_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER PUBLICATION supabase_realtime ADD TABLE salary_advances;

-- Salary payments (monthly paid/not paid)
CREATE TABLE IF NOT EXISTS salary_payments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  driver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  month TEXT NOT NULL,
  amount NUMERIC DEFAULT 0,
  is_paid BOOLEAN DEFAULT FALSE,
  paid_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(driver_id, month)
);
ALTER PUBLICATION supabase_realtime ADD TABLE salary_payments;

-- Diesel purchases by drivers
CREATE TABLE IF NOT EXISTS diesel_purchases (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  driver_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  vehicle_id UUID REFERENCES vehicles(id) ON DELETE SET NULL,
  vehicle_number TEXT,
  amount NUMERIC NOT NULL DEFAULT 0,
  liters NUMERIC DEFAULT 0,
  odometer_reading NUMERIC DEFAULT 0,
  purchase_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER PUBLICATION supabase_realtime ADD TABLE diesel_purchases;

-- Office monthly payments tracking
CREATE TABLE IF NOT EXISTS office_payments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  office_id UUID NOT NULL REFERENCES govt_offices(id) ON DELETE CASCADE,
  month TEXT NOT NULL,
  is_paid BOOLEAN DEFAULT FALSE,
  paid_date DATE,
  amount NUMERIC DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(office_id, month)
);
ALTER PUBLICATION supabase_realtime ADD TABLE office_payments;

-- Add pdf_report_url to fleet_logbooks
ALTER TABLE fleet_logbooks ADD COLUMN IF NOT EXISTS pdf_report_url TEXT;

-- Events table (director/staff create, drivers view)
CREATE TABLE IF NOT EXISTS events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  event_date DATE DEFAULT CURRENT_DATE,
  created_by TEXT,
  vehicles_assigned JSONB DEFAULT '[]'::jsonb,
  payment_received NUMERIC DEFAULT 0,
  payment_pending NUMERIC DEFAULT 0,
  status TEXT DEFAULT 'upcoming' CHECK (status IN ('upcoming','active','completed')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER PUBLICATION supabase_realtime ADD TABLE events;

-- Office-Vehicle assignments (multi-vehicle per office)
CREATE TABLE IF NOT EXISTS office_vehicle_assignments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  office_id UUID NOT NULL REFERENCES govt_offices(id) ON DELETE CASCADE,
  vehicle_id UUID REFERENCES vehicles(id) ON DELETE SET NULL,
  driver_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  assigned_date DATE DEFAULT CURRENT_DATE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER PUBLICATION supabase_realtime ADD TABLE office_vehicle_assignments;

-- NOTE: Create a public storage bucket named 'government_logbooks' in Supabase Dashboard

-- Vehicle holidays (per-vehicle holiday tracking)
CREATE TABLE IF NOT EXISTS vehicle_holidays (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  holiday_date DATE NOT NULL DEFAULT CURRENT_DATE,
  reason TEXT,
  marked_by TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(vehicle_id, holiday_date)
);
ALTER PUBLICATION supabase_realtime ADD TABLE vehicle_holidays;

-- Add route_stops and not_went_anywhere to fleet_logbooks
ALTER TABLE fleet_logbooks ADD COLUMN IF NOT EXISTS route_stops JSONB DEFAULT '[]'::jsonb;
ALTER TABLE fleet_logbooks ADD COLUMN IF NOT EXISTS not_went_anywhere BOOLEAN DEFAULT FALSE;

-- Disable RLS on all tables so the app can access them
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles DISABLE ROW LEVEL SECURITY;
ALTER TABLE fleet_logbooks DISABLE ROW LEVEL SECURITY;
ALTER TABLE diesel_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE diesel_purchases DISABLE ROW LEVEL SECURITY;
ALTER TABLE salary_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE salary_payments DISABLE ROW LEVEL SECURITY;
ALTER TABLE bookings DISABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_events DISABLE ROW LEVEL SECURITY;
ALTER TABLE car_routes DISABLE ROW LEVEL SECURITY;
ALTER TABLE offices DISABLE ROW LEVEL SECURITY;
ALTER TABLE attendance DISABLE ROW LEVEL SECURITY;
ALTER TABLE appointed_vehicles DISABLE ROW LEVEL SECURITY;
ALTER TABLE servicing_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE govt_offices DISABLE ROW LEVEL SECURITY;
ALTER TABLE booking_trips DISABLE ROW LEVEL SECURITY;
ALTER TABLE salary_advances DISABLE ROW LEVEL SECURITY;
ALTER TABLE office_vehicle_assignments DISABLE ROW LEVEL SECURITY;
ALTER TABLE events DISABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_holidays DISABLE ROW LEVEL SECURITY;
''';

  // ── Check if tables exist ──
  Future<bool> checkTablesExist() async {
    try {
      await client
          .from('profiles')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 10));
      _tablesExist = true;
      notifyListeners();
      return true;
    } catch (e) {
      print('checkTablesExist error: $e');
      _lastError = e.toString();
      _tablesExist = false;
      notifyListeners();
      return false;
    }
  }

  /// Runs DISABLE RLS on all tables every time app connects.
  /// This fixes the 42501 error when RLS gets re-enabled by Supabase.
  Future<bool> checkRlsStatus() async {
    try {
      // Try inserting and immediately deleting a test row in diesel_purchases
      // If RLS blocks it, we know RLS is still enabled
      await client.from('diesel_purchases').select().limit(1);
      return true;
    } catch (e) {
      if (e.toString().contains('row-level security') ||
          e.toString().contains('42501')) {
        return false;
      }
      return true; // Other errors are fine
    }
  }

  String _lastError = '';
  String get lastError => _lastError;

  // ══════════════════════════════════════
  //  PROFILES (Drivers / Staff / Director)
  // ══════════════════════════════════════

  // Get all profiles by role
  Future<List<Map<String, dynamic>>> getProfiles(String role) async {
    final data = await client
        .from('profiles')
        .select()
        .eq('role', role)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // Real-time stream for profiles
  Stream<List<Map<String, dynamic>>> profileStream(String role) {
    return client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('role', role)
        .map(
          (events) => events.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
  }

  // Add driver
  Future<Map<String, dynamic>?> addDriver({
    required String name,
    required String driverNo,
    required String mobileNo,
    required double salary,
    required DateTime joiningDate,
    required String username,
    required String password,
  }) async {
    try {
      final data = await client
          .from('profiles')
          .insert({
            'name': name,
            'driver_no': driverNo,
            'phone': mobileNo,
            'salary': salary,
            'joining_date': joiningDate.toIso8601String().split('T')[0],
            'username': username,
            'password': password,
            'role': 'driver',
          })
          .select()
          .single();
      notifyListeners();
      return data;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Username "$username" already exists');
      }
      rethrow;
    }
  }

  // Add staff
  Future<Map<String, dynamic>?> addStaff({
    required String name,
    required String mobileNo,
    required double salary,
    required String username,
    required String password,
  }) async {
    try {
      final data = await client
          .from('profiles')
          .insert({
            'name': name,
            'phone': mobileNo,
            'salary': salary,
            'username': username,
            'password': password,
            'role': 'staff',
          })
          .select()
          .single();
      notifyListeners();
      return data;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Username "$username" already exists');
      }
      rethrow;
    }
  }

  // Delete profile
  Future<void> deleteProfile(String id) async {
    await client.from('profiles').delete().eq('id', id);
    notifyListeners();
  }

  // Login check
  Future<Map<String, dynamic>?> login(
    String username,
    String password,
    String role,
  ) async {
    // Check hardcoded director first
    if (role == 'director' &&
        username == 'harshit' &&
        password == 'harshit@23122010') {
      // Also try to get from Supabase
      try {
        final data = await client
            .from('profiles')
            .select()
            .eq('username', username)
            .eq('password', password)
            .eq('role', role)
            .maybeSingle();
        if (data != null) return data;
      } catch (_) {}
      // Return hardcoded director profile
      return {
        'id': 'director_local',
        'username': 'harshit',
        'password': 'harshit@23122010',
        'role': 'director',
        'name': 'Harshit (Director)',
        'phone': '+91 98765 43210',
        'email': 'harshit@priyanshi.com',
      };
    }

    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('username', username)
          .eq('password', password)
          .eq('role', role)
          .maybeSingle();
      return data;
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════
  //  VEHICLES
  // ══════════════════════════════════════

  Future<List<Map<String, dynamic>>> getVehicles() async {
    final data = await client
        .from('vehicles')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Stream<List<Map<String, dynamic>>> vehicleStream() {
    return client
        .from('vehicles')
        .stream(primaryKey: ['id'])
        .map(
          (events) => events.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
  }

  Future<Map<String, dynamic>?> addVehicle({
    required String carName,
    required String modelNo,
    required String numberPlate,
    int? year,
  }) async {
    try {
      final data = await client
          .from('vehicles')
          .insert({
            'car_name': carName,
            'model_no': modelNo,
            'number_plate': numberPlate,
            'year': year ?? 2024,
          })
          .select()
          .single();
      notifyListeners();
      return data;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Number plate "$numberPlate" already exists');
      }
      rethrow;
    }
  }

  Future<void> deleteVehicle(String id) async {
    await client.from('vehicles').delete().eq('id', id);
    notifyListeners();
  }

  // ══════════════════════════════════════
  //  GENERIC QUERIES (for other screens)
  // ══════════════════════════════════════

  Stream<List<Map<String, dynamic>>> tableStream(String table) {
    return client
        .from(table)
        .stream(primaryKey: ['id'])
        .map(
          (events) => events.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
  }

  Future<List<Map<String, dynamic>>> getTable(String table) async {
    final data = await client
        .from(table)
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // ══════════════════════════════════════
  //  ATTENDANCE
  // ══════════════════════════════════════

  Stream<List<Map<String, dynamic>>> attendanceStream() {
    return client
        .from('attendance')
        .stream(primaryKey: ['id'])
        .map((e) => e.map((x) => Map<String, dynamic>.from(x)).toList());
  }

  Future<List<Map<String, dynamic>>> getAttendance({
    String? driverId,
    String? month,
  }) async {
    final query = client.from('attendance').select();
    final data = driverId != null
        ? await query.eq('driver_id', driverId).order('date', ascending: false)
        : await query.order('date', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> markAttendance({
    required String driverId,
    required String status,
    String? date,
    String markedBy = 'self',
    String? note,
  }) async {
    try {
      await client.from('attendance').upsert({
        'driver_id': driverId,
        'status': status,
        'date': date ?? DateTime.now().toIso8601String().split('T')[0],
        'marked_by': markedBy,
        'note': note,
      }, onConflict: 'driver_id,date');
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAttendanceStats(String driverId) async {
    final data = await client
        .from('attendance')
        .select()
        .eq('driver_id', driverId);
    final records = List<Map<String, dynamic>>.from(data);
    final present = records.where((r) => r['status'] == 'present').length;
    final absent = records.where((r) => r['status'] == 'absent').length;
    final holiday = records.where((r) => r['status'] == 'holiday').length;
    return {
      'present': present,
      'absent': absent,
      'holiday': holiday,
      'total': records.length,
    };
  }

  // ══════════════════════════════════════
  //  APPOINTED VEHICLES
  // ══════════════════════════════════════

  Stream<List<Map<String, dynamic>>> appointedVehiclesStream() {
    return client
        .from('appointed_vehicles')
        .stream(primaryKey: ['id'])
        .map((e) => e.map((x) => Map<String, dynamic>.from(x)).toList());
  }

  Future<List<Map<String, dynamic>>> getAppointedVehicles() async {
    final data = await client
        .from('appointed_vehicles')
        .select()
        .order('appointed_date', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> appointVehicle({
    required String driverId,
    required String vehicleId,
    String? date,
  }) async {
    // Deactivate previous appointments for this driver
    await client
        .from('appointed_vehicles')
        .update({
          'is_active': false,
          'end_date': DateTime.now().toIso8601String().split('T')[0],
        })
        .eq('driver_id', driverId)
        .eq('is_active', true);
    await client.from('appointed_vehicles').insert({
      'driver_id': driverId,
      'vehicle_id': vehicleId,
      'appointed_date': date ?? DateTime.now().toIso8601String().split('T')[0],
      'is_active': true,
    });
    notifyListeners();
  }

  Future<void> removeAppointment(String id) async {
    await client.from('appointed_vehicles').delete().eq('id', id);
    notifyListeners();
  }

  // ══════════════════════════════════════
  //  SERVICING
  // ══════════════════════════════════════

  Stream<List<Map<String, dynamic>>> servicingStream() {
    return client
        .from('servicing_records')
        .stream(primaryKey: ['id'])
        .map((e) => e.map((x) => Map<String, dynamic>.from(x)).toList());
  }

  Future<List<Map<String, dynamic>>> getServicingRecords({
    String? vehicleId,
  }) async {
    final query = client.from('servicing_records').select();
    final data = vehicleId != null
        ? await query
              .eq('vehicle_id', vehicleId)
              .order('servicing_date', ascending: false)
        : await query.order('servicing_date', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addServicing({
    required String vehicleId,
    required String vehicleNumber,
    required String date,
    required List<String> partsServiced,
    double? cost,
    String? description,
  }) async {
    await client.from('servicing_records').insert({
      'vehicle_id': vehicleId,
      'vehicle_number': vehicleNumber,
      'servicing_date': date,
      'parts_serviced': partsServiced,
      'cost': cost ?? 0,
      'description': description,
    });
    notifyListeners();
  }

  Future<void> deleteServicing(String id) async {
    await client.from('servicing_records').delete().eq('id', id);
    notifyListeners();
  }

  // ══════════════════════════════════════
  //  GOVT OFFICES
  // ══════════════════════════════════════

  Stream<List<Map<String, dynamic>>> govtOfficesStream() {
    return client
        .from('govt_offices')
        .stream(primaryKey: ['id'])
        .map((e) => e.map((x) => Map<String, dynamic>.from(x)).toList());
  }

  Future<List<Map<String, dynamic>>> getGovtOffices() async {
    final data = await client
        .from('govt_offices')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addGovtOffice({
    required String officeName,
    String? joiningDate,
    String? vehicleId,
    String? driverId,
    double? monthlyIncome,
  }) async {
    await client.from('govt_offices').insert({
      'office_name': officeName,
      'joining_date':
          joiningDate ?? DateTime.now().toIso8601String().split('T')[0],
      'vehicle_id': vehicleId,
      'driver_id': driverId,
      'monthly_income': monthlyIncome ?? 0,
    });
    notifyListeners();
  }

  Future<void> updateGovtOffice(String id, Map<String, dynamic> updates) async {
    await client.from('govt_offices').update(updates).eq('id', id);
    notifyListeners();
  }

  Future<void> deleteGovtOffice(String id) async {
    await client.from('govt_offices').delete().eq('id', id);
    notifyListeners();
  }

  // ══════════════════════════════════════
  //  BOOKING TRIPS
  // ══════════════════════════════════════

  Stream<List<Map<String, dynamic>>> bookingTripsStream() {
    return client
        .from('booking_trips')
        .stream(primaryKey: ['id'])
        .map((e) => e.map((x) => Map<String, dynamic>.from(x)).toList());
  }

  Future<List<Map<String, dynamic>>> getBookingTrips() async {
    final data = await client
        .from('booking_trips')
        .select()
        .order('trip_date', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addBookingTrip({
    required String customerName,
    String? destination,
    String? vehicleId,
    String? driverId,
    double? amount,
    String? paymentStatus,
    String? tripDate,
  }) async {
    await client.from('booking_trips').insert({
      'customer_name': customerName,
      'destination': destination,
      'vehicle_id': vehicleId,
      'driver_id': driverId,
      'amount': amount ?? 0,
      'payment_status': paymentStatus ?? 'pending',
      'trip_date': tripDate ?? DateTime.now().toIso8601String().split('T')[0],
    });
    notifyListeners();
  }

  Future<void> updateBookingTrip(
    String id,
    Map<String, dynamic> updates,
  ) async {
    await client.from('booking_trips').update(updates).eq('id', id);
    notifyListeners();
  }

  Future<void> deleteBookingTrip(String id) async {
    await client.from('booking_trips').delete().eq('id', id);
    notifyListeners();
  }

  // ══════════════════════════════════════
  //  FLEET LOGBOOKS
  // ══════════════════════════════════════

  Stream<List<Map<String, dynamic>>> logbookStream() {
    return client
        .from('fleet_logbooks')
        .stream(primaryKey: ['id'])
        .order('log_date', ascending: false)
        .map((e) => e.map((x) => Map<String, dynamic>.from(x)).toList());
  }

  Future<List<Map<String, dynamic>>> getLogbooks({
    String? driverId,
    String? month,
  }) async {
    var query = client.from('fleet_logbooks').select();
    if (driverId != null) {
      query = query.eq('driver_id', driverId);
    }
    if (month != null && month.isNotEmpty) {
      query = query.like('log_date', '$month%');
    }
    final data = await query.order('log_date', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Get all logbook entries for a specific vehicle in a specific month
  Future<List<Map<String, dynamic>>> getLogbooksByVehicleAndMonth({
    required String vehicleNumber,
    required String month, // yyyy-MM
  }) async {
    final data = await client
        .from('fleet_logbooks')
        .select()
        .eq('vehicle_number', vehicleNumber)
        .like('log_date', '$month%')
        .order('log_date', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addLogbook({
    String? driverId,
    required String vehicleNumber,
    required double startOdometer,
    required double endOdometer,
    String? source,
    String? destination,
    double? fuel,
    double? toll,
    Map<String, dynamic>? govtMetadata,
    String? logDate,
    String billStatus = 'draft',
    List<Map<String, dynamic>>? routeStops,
    bool notWentAnywhere = false,
  }) async {
    await client.from('fleet_logbooks').insert({
      'driver_id': driverId,
      'vehicle_number': vehicleNumber,
      'start_odometer': startOdometer,
      'end_odometer': endOdometer,
      'source': source,
      'destination': destination,
      'fuel': fuel ?? 0,
      'toll': toll ?? 0,
      'govt_metadata': govtMetadata ?? {},
      'bill_status': billStatus,
      'log_date': logDate ?? DateTime.now().toIso8601String().split('T')[0],
      'route_stops': routeStops ?? [],
      'not_went_anywhere': notWentAnywhere,
    });
    notifyListeners();
  }

  Future<void> updateLogbook(String id, Map<String, dynamic> updates) async {
    await client.from('fleet_logbooks').update(updates).eq('id', id);
    notifyListeners();
  }

  Future<void> deleteLogbook(String id) async {
    await client.from('fleet_logbooks').delete().eq('id', id);
    notifyListeners();
  }

  // ══════════════════════════════════════
  //  SALARY ADVANCES
  // ══════════════════════════════════════

  Stream<List<Map<String, dynamic>>> salaryAdvancesStream() {
    return client
        .from('salary_advances')
        .stream(primaryKey: ['id'])
        .map((e) => e.map((x) => Map<String, dynamic>.from(x)).toList());
  }

  Future<List<Map<String, dynamic>>> getSalaryAdvances({
    String? driverId,
  }) async {
    final query = client.from('salary_advances').select();
    final data = driverId != null
        ? await query
              .eq('driver_id', driverId)
              .order('advance_date', ascending: false)
        : await query.order('advance_date', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addSalaryAdvance({
    required String driverId,
    required double amount,
    String? reason,
    String? date,
  }) async {
    await client.from('salary_advances').insert({
      'driver_id': driverId,
      'amount': amount,
      'reason': reason,
      'advance_date': date ?? DateTime.now().toIso8601String().split('T')[0],
    });
    notifyListeners();
  }

  Future<void> deleteSalaryAdvance(String id) async {
    await client.from('salary_advances').delete().eq('id', id);
    notifyListeners();
  }

  // ══════════════════════════════════════
  //  SALARY PAYMENTS
  // ══════════════════════════════════════

  Stream<List<Map<String, dynamic>>> salaryPaymentsStream() {
    return client
        .from('salary_payments')
        .stream(primaryKey: ['id'])
        .map((e) => e.map((x) => Map<String, dynamic>.from(x)).toList());
  }

  Future<List<Map<String, dynamic>>> getSalaryPayments({
    String? driverId,
  }) async {
    final query = client.from('salary_payments').select();
    final data = driverId != null
        ? await query.eq('driver_id', driverId).order('month', ascending: false)
        : await query.order('month', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> markSalaryPaid({
    required String driverId,
    required String month,
    required double amount,
    bool isPaid = true,
  }) async {
    await client.from('salary_payments').upsert({
      'driver_id': driverId,
      'month': month,
      'amount': amount,
      'is_paid': isPaid,
      'paid_date': isPaid
          ? DateTime.now().toIso8601String().split('T')[0]
          : null,
    }, onConflict: 'driver_id,month');
    notifyListeners();
  }

  // ══════════════════════════════════════
  //  DIESEL PURCHASES
  // ══════════════════════════════════════

  Stream<List<Map<String, dynamic>>> dieselPurchasesStream() {
    return client
        .from('diesel_purchases')
        .stream(primaryKey: ['id'])
        .map((e) => e.map((x) => Map<String, dynamic>.from(x)).toList());
  }

  Future<List<Map<String, dynamic>>> getDieselPurchases({
    String? driverId,
    String? vehicleId,
    String? startDate,
    String? endDate,
  }) async {
    var query = client.from('diesel_purchases').select();
    if (driverId != null) {
      query = query.eq('driver_id', driverId);
    }
    if (vehicleId != null) {
      query = query.eq('vehicle_id', vehicleId);
    }
    if (startDate != null && startDate.isNotEmpty) {
      query = query.gte('purchase_date', startDate);
    }
    if (endDate != null && endDate.isNotEmpty) {
      query = query.lte('purchase_date', endDate);
    }
    final data = await query.order('purchase_date', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addDieselPurchase({
    String? driverId,
    String? vehicleId,
    String? vehicleNumber,
    required double amount,
    double? liters,
    double? odometerReading,
    String? date,
  }) async {
    await client.from('diesel_purchases').insert({
      'driver_id': driverId,
      'vehicle_id': vehicleId,
      'vehicle_number': vehicleNumber,
      'amount': amount,
      'liters': liters ?? 0,
      'odometer_reading': odometerReading ?? 0,
      'purchase_date': date ?? DateTime.now().toIso8601String().split('T')[0],
    });
    notifyListeners();
  }

  Future<void> deleteDieselPurchase(String id) async {
    await client.from('diesel_purchases').delete().eq('id', id);
    notifyListeners();
  }

  // ══════════════════════════════════════
  //  OFFICE PAYMENTS (monthly tracking)
  // ══════════════════════════════════════

  Stream<List<Map<String, dynamic>>> officePaymentsStream() {
    return client
        .from('office_payments')
        .stream(primaryKey: ['id'])
        .map((e) => e.map((x) => Map<String, dynamic>.from(x)).toList());
  }

  Future<List<Map<String, dynamic>>> getOfficePayments({
    String? officeId,
  }) async {
    final query = client.from('office_payments').select();
    final data = officeId != null
        ? await query.eq('office_id', officeId).order('month', ascending: false)
        : await query.order('month', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> markOfficePayment({
    required String officeId,
    required String month,
    bool isPaid = true,
    double? amount,
  }) async {
    await client.from('office_payments').upsert({
      'office_id': officeId,
      'month': month,
      'is_paid': isPaid,
      'amount': amount ?? 0,
      'paid_date': isPaid
          ? DateTime.now().toIso8601String().split('T')[0]
          : null,
    }, onConflict: 'office_id,month');
    notifyListeners();
  }

  // ══════════════════════════════════════
  //  TEMP VEHICLE ASSIGNMENT (with duration)
  // ══════════════════════════════════════

  Future<void> appointVehicleTemp({
    required String driverId,
    required String vehicleId,
    required int durationDays,
    String? originalDriverId,
    String? date,
  }) async {
    final appointDate = date ?? DateTime.now().toIso8601String().split('T')[0];
    final endDate = DateTime.parse(
      appointDate,
    ).add(Duration(days: durationDays)).toIso8601String().split('T')[0];
    // If temporary, keep original driver active but add temp record
    await client.from('appointed_vehicles').insert({
      'driver_id': driverId,
      'vehicle_id': vehicleId,
      'appointed_date': appointDate,
      'end_date': endDate,
      'duration_days': durationDays,
      'is_active': true,
      'is_temporary': true,
      'original_driver_id': originalDriverId,
    });
    notifyListeners();
  }

  Future<void> checkExpiredAppointments() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final expired = await client
        .from('appointed_vehicles')
        .select()
        .eq('is_temporary', true)
        .eq('is_active', true)
        .lte('end_date', today);
    final expiredList = List<Map<String, dynamic>>.from(expired);
    for (var appt in expiredList) {
      // Deactivate temp assignment
      await client
          .from('appointed_vehicles')
          .update({'is_active': false})
          .eq('id', appt['id']);
      // Re-activate original driver
      if (appt['original_driver_id'] != null) {
        await client
            .from('appointed_vehicles')
            .update({'is_active': true})
            .eq('driver_id', appt['original_driver_id'])
            .eq('vehicle_id', appt['vehicle_id'])
            .eq('is_temporary', false);
      }
    }
    notifyListeners();
  }

  // ══════════════════════════════════════
  //  EVENTS
  // ══════════════════════════════════════

  Stream<List<Map<String, dynamic>>> eventsStream() {
    return client
        .from('events')
        .stream(primaryKey: ['id'])
        .map((e) => e.map((x) => Map<String, dynamic>.from(x)).toList());
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    final data = await client
        .from('events')
        .select()
        .order('event_date', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addEvent({
    required String title,
    String? description,
    String? eventDate,
    String? createdBy,
    List<String>? vehiclesAssigned,
    double? paymentReceived,
    double? paymentPending,
    String status = 'upcoming',
  }) async {
    await client.from('events').insert({
      'title': title,
      'description': description,
      'event_date': eventDate ?? DateTime.now().toIso8601String().split('T')[0],
      'created_by': createdBy,
      'vehicles_assigned': vehiclesAssigned ?? [],
      'payment_received': paymentReceived ?? 0,
      'payment_pending': paymentPending ?? 0,
      'status': status,
    });
    notifyListeners();
  }

  Future<void> updateEvent(String id, Map<String, dynamic> updates) async {
    await client.from('events').update(updates).eq('id', id);
    notifyListeners();
  }

  Future<void> deleteEvent(String id) async {
    await client.from('events').delete().eq('id', id);
    notifyListeners();
  }

  // ══════════════════════════════════════
  //  OFFICE VEHICLE ASSIGNMENTS (multi-vehicle)
  // ══════════════════════════════════════

  Stream<List<Map<String, dynamic>>> officeVehicleAssignmentsStream() {
    return client
        .from('office_vehicle_assignments')
        .stream(primaryKey: ['id'])
        .map((e) => e.map((x) => Map<String, dynamic>.from(x)).toList());
  }

  Future<List<Map<String, dynamic>>> getOfficeVehicleAssignments({
    String? officeId,
  }) async {
    final query = client.from('office_vehicle_assignments').select();
    final data = officeId != null
        ? await query
              .eq('office_id', officeId)
              .order('assigned_date', ascending: false)
        : await query.order('assigned_date', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addOfficeVehicleAssignment({
    required String officeId,
    String? vehicleId,
    String? driverId,
    String? assignedDate,
  }) async {
    await client.from('office_vehicle_assignments').insert({
      'office_id': officeId,
      'vehicle_id': vehicleId,
      'driver_id': driverId,
      'assigned_date':
          assignedDate ?? DateTime.now().toIso8601String().split('T')[0],
      'is_active': true,
    });
    notifyListeners();
  }

  Future<void> updateOfficeVehicleAssignment(
    String id,
    Map<String, dynamic> updates,
  ) async {
    await client
        .from('office_vehicle_assignments')
        .update(updates)
        .eq('id', id);
    notifyListeners();
  }

  Future<void> deleteOfficeVehicleAssignment(String id) async {
    await client.from('office_vehicle_assignments').delete().eq('id', id);
    notifyListeners();
  }

  // ══════════════════════════════════════
  //  STORAGE: Upload PDF to Supabase Storage
  // ══════════════════════════════════════

  Future<String?> uploadLogbookPdf({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final storage = client.storage.from('government_logbooks');
      await storage.uploadBinary(
        fileName,
        fileBytes,
        fileOptions: const FileOptions(upsert: true),
      );
      final url = storage.getPublicUrl(fileName);
      return url;
    } catch (e) {
      debugPrint('Storage upload error: $e');
      return null;
    }
  }

  Future<void> updateLogbookPdfUrl(String logbookId, String pdfUrl) async {
    await client
        .from('fleet_logbooks')
        .update({'pdf_report_url': pdfUrl})
        .eq('id', logbookId);
    notifyListeners();
  }

  // ══════════════════════════════════════
  //  VEHICLE HOLIDAYS (per-vehicle)
  // ══════════════════════════════════════

  Stream<List<Map<String, dynamic>>> vehicleHolidaysStream() {
    return client
        .from('vehicle_holidays')
        .stream(primaryKey: ['id'])
        .map((e) => e.map((x) => Map<String, dynamic>.from(x)).toList());
  }

  Future<List<Map<String, dynamic>>> getVehicleHolidays({
    String? vehicleId,
    String? date,
  }) async {
    final query = client.from('vehicle_holidays').select();
    var q = query;
    if (vehicleId != null) q = q.eq('vehicle_id', vehicleId);
    if (date != null) q = q.eq('holiday_date', date);
    final data = await q.order('holiday_date', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> markVehicleHoliday({
    required String vehicleId,
    String? date,
    String? reason,
    String? markedBy,
  }) async {
    await client.from('vehicle_holidays').upsert({
      'vehicle_id': vehicleId,
      'holiday_date': date ?? DateTime.now().toIso8601String().split('T')[0],
      'reason': reason,
      'marked_by': markedBy,
    }, onConflict: 'vehicle_id,holiday_date');
    notifyListeners();
  }

  Future<void> removeVehicleHoliday(String id) async {
    await client.from('vehicle_holidays').delete().eq('id', id);
    notifyListeners();
  }

  // ══════════════════════════════════════
  //  DRIVER-SPECIFIC STREAMS
  // ══════════════════════════════════════

  Stream<List<Map<String, dynamic>>> driverBookingsStream(String driverId) {
    // First get vehicles assigned to this driver
    return client
        .from('vehicles')
        .stream(primaryKey: ['id'])
        .map(
          (vehicles) => vehicles
              .where((v) => v['assigned_driver_id'] == driverId)
              .map((v) => v['id'] as String)
              .toList(),
        )
        .asyncMap((vehicleIds) async {
          // Get all bookings and filter by driver_id OR vehicle_id
          final allBookings = await client
              .from('booking_trips')
              .select()
              .order('trip_date', ascending: false);
          return allBookings.map((e) => Map<String, dynamic>.from(e)).where((
            b,
          ) {
            final directMatch = b['driver_id'] == driverId;
            final vehicleMatch = vehicleIds.contains(b['vehicle_id']);
            return directMatch || vehicleMatch;
          }).toList();
        })
        .asBroadcastStream();
  }

  Stream<List<Map<String, dynamic>>> driverAssignmentsStream(String driverId) {
    return client
        .from('office_vehicle_assignments')
        .stream(primaryKey: ['id'])
        .map(
          (events) => events
              .map((e) => Map<String, dynamic>.from(e))
              .where((a) => a['driver_id'] == driverId)
              .toList(),
        );
  }

  // ══════════════════════════════════════
  //  BACKUP: Export all data as JSON
  // ══════════════════════════════════════

  Future<Map<String, dynamic>> exportAllData() async {
    final backup = <String, dynamic>{};
    final tables = [
      'profiles',
      'vehicles',
      'diesel_records',
      'salary_records',
      'bookings',
      'vehicle_events',
      'car_routes',
      'offices',
      'attendance',
      'appointed_vehicles',
      'servicing_records',
      'govt_offices',
      'booking_trips',
      'fleet_logbooks',
      'salary_advances',
      'salary_payments',
      'diesel_purchases',
      'office_payments',
      'events',
      'office_vehicle_assignments',
      'vehicle_holidays',
    ];
    for (final table in tables) {
      try {
        final data = await client.from(table).select();
        backup[table] = data;
      } catch (e) {
        backup[table] = [];
      }
    }
    backup['_meta'] = {
      'exported_at': DateTime.now().toIso8601String(),
      'app': 'Priyanshi Travel Agency',
      'version': '1.0',
    };
    return backup;
  }
}

enum UserRole { driver, staff, director }

class AppUser {
  final String id;
  final String username;
  final String password;
  final UserRole role;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? licenseNumber;
  final String? vehicleAssigned;
  final double? salary;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.licenseNumber,
    this.vehicleAssigned,
    this.salary,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  AppUser copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? licenseNumber,
    String? vehicleAssigned,
    double? salary,
  }) {
    return AppUser(
      id: id,
      username: username,
      password: password,
      role: role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      vehicleAssigned: vehicleAssigned ?? this.vehicleAssigned,
      salary: salary ?? this.salary,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'password': password,
        'role': role.name,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'licenseNumber': licenseNumber,
        'vehicleAssigned': vehicleAssigned,
        'salary': salary,
        'createdAt': createdAt.toIso8601String(),
      };
}

class Vehicle {
  final String id;
  final String vehicleNumber;
  final String model;
  final String brand;
  final int year;
  final String? assignedDriverId;
  final double totalKm;
  final String status; // active, maintenance, idle

  Vehicle({
    required this.id,
    required this.vehicleNumber,
    required this.model,
    required this.brand,
    required this.year,
    this.assignedDriverId,
    this.totalKm = 0,
    this.status = 'active',
  });
}

class DieselRecord {
  final String id;
  final String vehicleId;
  final String vehicleNumber;
  final String? driverId;
  final String? driverName;
  final double litres;
  final double amount;
  final double kmReading;
  final DateTime date;

  DieselRecord({
    required this.id,
    required this.vehicleId,
    required this.vehicleNumber,
    this.driverId,
    this.driverName,
    required this.litres,
    required this.amount,
    required this.kmReading,
    required this.date,
  });
}

class SalaryRecord {
  final String id;
  final String userId;
  final String userName;
  final double baseSalary;
  final double bonus;
  final double deduction;
  final double total;
  final String month;
  final bool isPaid;
  final DateTime date;

  SalaryRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.baseSalary,
    this.bonus = 0,
    this.deduction = 0,
    required this.total,
    required this.month,
    this.isPaid = false,
    required this.date,
  });
}

class Booking {
  final String id;
  final String customerName;
  final String customerPhone;
  final String pickupLocation;
  final String dropLocation;
  final DateTime bookingDate;
  final String? vehicleId;
  final String? driverId;
  final double amount;
  final String status; // pending, confirmed, completed, cancelled

  Booking({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.pickupLocation,
    required this.dropLocation,
    required this.bookingDate,
    this.vehicleId,
    this.driverId,
    required this.amount,
    this.status = 'pending',
  });
}

class VehicleEvent {
  final String id;
  final String vehicleId;
  final String vehicleNumber;
  final String eventType; // service, insurance, pucc, fitness
  final String description;
  final DateTime eventDate;
  final DateTime? nextDueDate;
  final double? cost;

  VehicleEvent({
    required this.id,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.eventType,
    required this.description,
    required this.eventDate,
    this.nextDueDate,
    this.cost,
  });
}

class CarRoute {
  final String id;
  final String routeName;
  final String from;
  final String to;
  final double distanceKm;
  final double estimatedTime; // hours
  final String? vehicleId;
  final String? driverId;

  CarRoute({
    required this.id,
    required this.routeName,
    required this.from,
    required this.to,
    required this.distanceKm,
    required this.estimatedTime,
    this.vehicleId,
    this.driverId,
  });
}

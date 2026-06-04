import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations extends ChangeNotifier {
  static final AppLocalizations _instance = AppLocalizations._internal();
  factory AppLocalizations() => _instance;
  AppLocalizations._internal();

  String _locale = 'en';
  String get locale => _locale;

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString('app_language') ?? 'en';
    notifyListeners();
  }

  Future<void> setLocale(String lang) async {
    _locale = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);
    notifyListeners();
  }

  Future<bool> hasChosenLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('app_language');
  }

  String t(String key) {
    final map = _translations[_locale] ?? _translations['en']!;
    return map[key] ?? _translations['en']![key] ?? key;
  }

  static AppLocalizations of() => _instance;

  static final Map<String, Map<String, String>> _translations = {
    'en': {
      // General
      'app_name': 'Priyanshi Travel Agency',
      'staff_portal': 'Staff Management Portal',
      'welcome': 'Welcome',
      'logout': 'Logout',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'update': 'Update',
      'add': 'Add',
      'done': 'Done',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'error': 'Error',
      'loading': 'Loading...',
      'no_data': 'No data available',
      'contact_director': 'Contact director for credentials',

      // Login
      'login': 'LOGIN',
      'username': 'Username',
      'password': 'Password',
      'invalid_credentials': 'Invalid credentials or wrong role selected',
      'director': 'Director',
      'driver': 'Driver',
      'staff': 'Staff',

      // Dashboard
      'dashboard': 'Dashboard',
      'home': 'Home',
      'quick_actions': 'Quick Actions',
      'total_drivers': 'Total Drivers',
      'total_vehicles': 'Total Vehicles',
      'active_vehicles': 'Active Vehicles',
      'bookings': 'Bookings',

      // Menu items
      'salary_management': 'Salary Management',
      'diesel_details': 'Diesel Details',
      'driver_analysis': 'Driver Analysis',
      'vehicle_analysis': 'Vehicle Analysis',
      'vehicle_events': 'Vehicle Events',
      'bookings_offices': 'Bookings & Offices',
      'driver_management': 'Driver Management',
      'staff_management': 'Staff Management',
      'vehicle_management': 'Vehicle Management',
      'attendance': 'Attendance',
      'appointed_vehicles': 'Appointed Vehicles',
      'servicing': 'Servicing',
      'fleet_logbook': 'Fleet Logbook',
      'events': 'Events',
      'cloud_backup': 'Cloud Backup',
      'salary_details': 'Salary Details',
      'diesel_purchases': 'Diesel Purchases',
      'my_appointed_vehicle': 'My Appointed Vehicle',
      'offices_bookings': 'Offices & Bookings',
      'booking_trips': 'Booking Trips',
      'fill_logbook': 'Fill Logbook',
      'car_routes': 'Car Routes',
      'about_us': 'About Us',
      'my_details': 'My Details',

      // Attendance
      'mark_attendance': 'Mark Attendance',
      'mark_my_attendance': 'Mark My Attendance',
      'present': 'Present',
      'absent': 'Absent',
      'holiday': 'Holiday',
      'attendance_overview': 'Attendance Overview',
      'date': 'Date',

      // Logbook
      'daily_logbook_entry': 'Daily Logbook Entry',
      'vehicle_number': 'Vehicle Number',
      'start_km': 'Start KM',
      'end_km': 'End KM',
      'source': 'Source',
      'destination': 'Destination',
      'fuel': 'Fuel',
      'toll': 'Toll',
      'save_as_draft': 'Save as Draft',
      'submit': 'Submit',
      'my_logbook_entries': 'My Logbook Entries',
      'no_entries': 'No entries yet',
      'add_stop': 'Add Stop',
      'route_stops': 'Route Stops',
      'didnt_go_anywhere': "Didn't go anywhere today",
      'no_trip_today': 'No trip today - Station duty',
      'draft': 'Draft',
      'submitted': 'Submitted',
      'cleared': 'Cleared',

      // About
      'premium_travel': 'Premium Travel Services Since 2015',
      'our_services': 'Our Services',
      'contact': 'Contact',
      'version': 'Version 1.0.0',

      // Credits
      'credits_director': 'Director: Rajesh Kumar Dhakad',
      'credits_dev': 'Dev: Harshit Dhakad',

      // Splash
      'splash_subtitle': 'Trusted Travel Partner',
      'splash_director': 'Director: Mr. Rajesh Kumar Dhakad',
      'splash_developer': 'Developed by Harshit Dhakad',

      // Language
      'choose_language': 'Choose Language',
      'select_language': 'Select your preferred language',
      'english': 'English',
      'hindi': 'Hindi',
      'continue_btn': 'Continue',

      // Misc
      'payment_status': 'Payment Status',
      'pending': 'Pending',
      'paid': 'Paid',
      'amount': 'Amount',
      'customer_name': 'Customer Name',
      'monthly_income': 'Monthly Income',
      'office_name': 'Office Name',
      'joining_date': 'Joining Date',
    },
    'hi': {
      // General
      'app_name': 'प्रियांशी ट्रैवल एजेंसी',
      'staff_portal': 'स्टाफ प्रबंधन पोर्टल',
      'welcome': 'स्वागत',
      'logout': 'लॉग आउट',
      'cancel': 'रद्द करें',
      'save': 'सहेजें',
      'delete': 'हटाएं',
      'edit': 'संपादित करें',
      'update': 'अपडेट करें',
      'add': 'जोड़ें',
      'done': 'हो गया',
      'yes': 'हाँ',
      'no': 'नहीं',
      'ok': 'ठीक है',
      'error': 'त्रुटि',
      'loading': 'लोड हो रहा है...',
      'no_data': 'कोई डेटा उपलब्ध नहीं',
      'contact_director': 'क्रेडेंशियल के लिए डायरेक्टर से संपर्क करें',

      // Login
      'login': 'लॉगिन',
      'username': 'यूज़रनेम',
      'password': 'पासवर्ड',
      'invalid_credentials': 'गलत क्रेडेंशियल या गलत भूमिका',
      'director': 'डायरेक्टर',
      'driver': 'ड्राइवर',
      'staff': 'स्टाफ',

      // Dashboard
      'dashboard': 'डैशबोर्ड',
      'home': 'होम',
      'quick_actions': 'त्वरित कार्य',
      'total_drivers': 'कुल ड्राइवर',
      'total_vehicles': 'कुल वाहन',
      'active_vehicles': 'सक्रिय वाहन',
      'bookings': 'बुकिंग',

      // Menu items
      'salary_management': 'वेतन प्रबंधन',
      'diesel_details': 'डीज़ल विवरण',
      'driver_analysis': 'ड्राइवर विश्लेषण',
      'vehicle_analysis': 'वाहन विश्लेषण',
      'vehicle_events': 'वाहन इवेंट',
      'bookings_offices': 'बुकिंग और कार्यालय',
      'driver_management': 'ड्राइवर प्रबंधन',
      'staff_management': 'स्टाफ प्रबंधन',
      'vehicle_management': 'वाहन प्रबंधन',
      'attendance': 'उपस्थिति',
      'appointed_vehicles': 'नियुक्त वाहन',
      'servicing': 'सर्विसिंग',
      'fleet_logbook': 'फ्लीट लॉगबुक',
      'events': 'इवेंट',
      'cloud_backup': 'क्लाउड बैकअप',
      'salary_details': 'वेतन विवरण',
      'diesel_purchases': 'डीज़ल खरीद',
      'my_appointed_vehicle': 'मेरा नियुक्त वाहन',
      'offices_bookings': 'कार्यालय और बुकिंग',
      'booking_trips': 'बुकिंग ट्रिप',
      'fill_logbook': 'लॉगबुक भरें',
      'car_routes': 'कार रूट',
      'about_us': 'हमारे बारे में',
      'my_details': 'मेरी जानकारी',

      // Attendance
      'mark_attendance': 'उपस्थिति दर्ज करें',
      'mark_my_attendance': 'मेरी उपस्थिति दर्ज करें',
      'present': 'उपस्थित',
      'absent': 'अनुपस्थित',
      'holiday': 'छुट्टी',
      'attendance_overview': 'उपस्थिति अवलोकन',
      'date': 'तारीख',

      // Logbook
      'daily_logbook_entry': 'दैनिक लॉगबुक प्रविष्टि',
      'vehicle_number': 'वाहन नंबर',
      'start_km': 'शुरुआती KM',
      'end_km': 'अंतिम KM',
      'source': 'स्रोत',
      'destination': 'गंतव्य',
      'fuel': 'ईंधन',
      'toll': 'टोल',
      'save_as_draft': 'ड्राफ्ट सहेजें',
      'submit': 'जमा करें',
      'my_logbook_entries': 'मेरी लॉगबुक प्रविष्टियां',
      'no_entries': 'अभी तक कोई प्रविष्टि नहीं',
      'add_stop': 'स्टॉप जोड़ें',
      'route_stops': 'रूट स्टॉप',
      'didnt_go_anywhere': 'आज कहीं नहीं गया',
      'no_trip_today': 'आज कोई यात्रा नहीं - स्टेशन ड्यूटी',
      'draft': 'ड्राफ्ट',
      'submitted': 'जमा',
      'cleared': 'क्लियर',

      // About
      'premium_travel': '2015 से प्रीमियम ट्रैवल सेवाएं',
      'our_services': 'हमारी सेवाएं',
      'contact': 'संपर्क',
      'version': 'संस्करण 1.0.0',

      // Credits
      'credits_director': 'डायरेक्टर: राजेश कुमार ढाकड़',
      'credits_dev': 'डेव: हर्षित ढाकड़',

      // Splash
      'splash_subtitle': 'विश्वसनीय यात्रा साथी',
      'splash_director': 'डायरेक्टर: श्री राजेश कुमार ढाकड़',
      'splash_developer': 'डेवलपर: हर्षित ढाकड़',

      // Language
      'choose_language': 'भाषा चुनें',
      'select_language': 'अपनी पसंदीदा भाषा चुनें',
      'english': 'English',
      'hindi': 'हिंदी',
      'continue_btn': 'जारी रखें',

      // Misc
      'payment_status': 'भुगतान स्थिति',
      'pending': 'लंबित',
      'paid': 'भुगतान हो गया',
      'amount': 'राशि',
      'customer_name': 'ग्राहक का नाम',
      'monthly_income': 'मासिक आय',
      'office_name': 'कार्यालय का नाम',
      'joining_date': 'जॉइनिंग तारीख',
    },
  };
}

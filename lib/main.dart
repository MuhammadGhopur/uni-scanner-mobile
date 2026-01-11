import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'utils/import_csv_to_sqlite.dart';
import 'screens/scanner_page.dart';
import 'screens/dashboard_page.dart';
import 'services/sqlite_service.dart';
import 'screens/expired_page.dart'; // Import ExpiredPage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request camera and storage permissions
  await Permission.camera.request();
  await Permission.storage.request();

  // Initialize shared preferences
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now();
  // You can change this date as needed.
  final expirationDate = DateTime(2026, 1, 18);
  
  // Check if the app is expired
  bool isExpired = now.isAfter(expirationDate);


  final sqliteService = SQLiteService();
  final poCount = await sqliteService.getPoCount();
  if (poCount == 0) {
    await CsvToSqliteImporter.importCsv();
  }
  runApp(MyApp(isExpired: isExpired)); // Pass expiration status to MyApp
}

class MyApp extends StatelessWidget {
  final bool isExpired;
  const MyApp({super.key, required this.isExpired});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isExpired ? const ExpiredPage() : const DashboardPage(), // Conditional home screen
    );
  }
}

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'utils/import_csv_to_sqlite.dart';
import 'screens/scanner_page.dart';
import 'screens/dashboard_page.dart';
import 'services/sqlite_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request camera and storage permissions
  await Permission.camera.request();
  await Permission.storage.request();

  final sqliteService = SQLiteService();
  final poCount = await sqliteService.getPoCount();
  if (poCount == 0) {
    await CsvToSqliteImporter.importCsv();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardPage(),
    );
  }
}

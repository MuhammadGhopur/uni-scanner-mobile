import 'package:flutter/material.dart';
import 'screens/scanner_page.dart';

// TAMBAHKAN BARIS INI
import 'utils/import_csv_to_sqlite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CsvToSqliteImporter.importCsv(); // sekarang TIDAK ERROR

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScannerPage(),
    );
  }
}

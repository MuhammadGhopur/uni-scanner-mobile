import 'package:flutter/services.dart' show rootBundle; // Import rootBundle
import 'package:csv/csv.dart'; // Import csv
import '../services/sqlite_service.dart';

class CsvToSqliteImporter {
  static Future<void> importCsv() async {
    try {
      // Read CSV content from assets
      final csvString = await rootBundle.loadString('assets/po_data.csv');
      List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);

      int importedRowCount = 0; // New counter

      // Assuming the first row is header and actual data starts from the third row (index 2)
      for (int i = 2; i < csvTable.length; i++) {
        final cols = csvTable[i];

        if (cols.length < 3) continue;

        await SQLiteService().insertProduct(
          poNumber: cols[0].toString().trim(),
          custId: cols[1].toString().trim(),
          sku: cols[2].toString().trim(),
        );
        importedRowCount++; // Increment counter
      }

      print('import csv sukses. $importedRowCount baris diimpor dari assets/po_data.csv');
    } catch (e) {
      print('import csv dilewati: $e');
    }
  }
}

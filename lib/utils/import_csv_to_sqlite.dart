import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/sqlite_service.dart';

class CsvToSqliteImporter {
  static Future<void> importCsv() async {
    try {
      // lokasi download android
      final downloadDir = Directory('/storage/emulated/0/Download');
      final sourceFile = File('${downloadDir.path}/po_data.csv');

      if (!await sourceFile.exists()) {
        throw Exception('csv tidak ada di folder Download');
      }

      // lokasi aman app
      final appDir = await getApplicationDocumentsDirectory();
      final targetFile = File('${appDir.path}/po_data.csv');

      // copy sekali
      if (!await targetFile.exists()) {
        await sourceFile.copy(targetFile.path);
      }

      final lines = await targetFile.readAsLines();
      int importedRowCount = 0; // New counter

      for (int i = 2; i < lines.length; i++) {
        final cols = lines[i].split(',');

        if (cols.length < 3) continue;

        await SQLiteService().insertProduct(
          poNumber: cols[0].trim(),
          custId: cols[1].trim(),
          sku: cols[2].trim(),
        );
        importedRowCount++; // Increment counter
      }

      print('import csv sukses');
    } catch (e) {
      print('import csv dilewati: $e');
    }
  }
}

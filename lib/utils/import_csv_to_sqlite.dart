import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class CsvToSqliteImporter {
  static Future<void> importCsv() async {
    final file = File('/storage/emulated/0/Download/po_data.csv');

    if (!await file.exists()) {
      throw Exception('file csv tidak ditemukan');
    }

    final dbPath = join(await getDatabasesPath(), 'uni_scanner.db');
    final db = await openDatabase(dbPath);

    final lines = await file.readAsLines();

    // asumsi header:
    // po_number,cust_id,sku,width
    for (int i = 1; i < lines.length; i++) {
      final cols = lines[i].split(',');

      if (cols.length < 4) continue;

      await db.insert(
        'po_data',
        {
          'po_number': cols[0].trim(),
          'cust_id': cols[1].trim(),
          'sku': cols[2].trim(),
          'width': cols[3].trim(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}

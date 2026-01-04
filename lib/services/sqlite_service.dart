import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLiteService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'po_data.db');

    return await openDatabase(
      path,
      version: 2, // Increased version to 2
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE po_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            po_number TEXT,
            cust_id TEXT,
            sku TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE scanned_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            po_number TEXT,
            sku TEXT,
            width TEXT,
            size TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS po_data'); // Drop and recreate if needed for version 1 structure
          await db.execute('''
            CREATE TABLE po_data (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              po_number TEXT,
              cust_id TEXT,
              sku TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS scanned_data (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              po_number TEXT,
              sku TEXT,
              width TEXT,
              size TEXT,
              timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
          ''');
        }
      },
    );
  }

  Future<Map<String, dynamic>?> getProductByPo(String poNumber) async {
    final db = await database;
    final result = await db.query(
      'po_data',
      where: 'po_number = ?',
      whereArgs: [poNumber],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<List<String>> getAllPoNumbers() async {
    final db = await database;
    final result = await db.query(
      'po_data',
      columns: ['po_number'],
    );

    final poNumbers = result
        .map((e) => e['po_number'] as String)
        .where((e) => e.trim().isNotEmpty)
        .toList();
    return poNumbers;
  }

  Future<int> getPoCount() async {
    final db = await database;
    final count = await db.rawQuery('SELECT COUNT(*) FROM po_data');
    return Sqflite.firstIntValue(count) ?? 0;
  }

  Future<void> insertProduct({
    required String poNumber,
    required String custId,
    required String sku,
  }) async {
    final db = await database;
    await db.insert(
      'po_data',
      {
        'po_number': poNumber,
        'cust_id': custId,
        'sku': sku,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await database;
    return await db.query('po_data');
  }

  Future<List<Map<String, dynamic>>> getFilteredProducts({
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause = 'po_number LIKE ? OR cust_id LIKE ? OR sku LIKE ?';
      whereArgs = ['%$searchQuery%', '%$searchQuery%', '%$searchQuery%'];
    }

    return await db.query(
      'po_data',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      limit: limit,
      offset: offset,
      orderBy: 'po_number ASC', // Order by PO number for consistent pagination
    );
  }

  Future<void> updateProduct({
    required int id,
    required String poNumber,
    required String custId,
    required String sku,
  }) async {
    final db = await database;
    await db.update(
      'po_data',
      {
        'po_number': poNumber,
        'cust_id': custId,
        'sku': sku,
      },
      where: 'id = ?',
      whereArgs: [id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete(
      'po_data',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertScannedData({
    required String poNumber,
    required String sku,
    required String width,
    required String size,
  }) async {
    final db = await database;
    await db.insert(
      'scanned_data',
      {
        'po_number': poNumber,
        'sku': sku,
        'width': width,
        'size': size,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

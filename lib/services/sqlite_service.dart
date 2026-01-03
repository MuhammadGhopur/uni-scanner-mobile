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
    String path = join(await getDatabasesPath(), 'uni_scanner.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE po_data(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            po_number TEXT,
            cust_id TEXT,
            sku TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS po_data');
          await db.execute('''
            CREATE TABLE po_data(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              po_number TEXT,
              cust_id TEXT,
              sku TEXT
            )
          ''');
        }
      },
    );
  }

  Future<void> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    await db.insert(
      'po_data',
      product,
      conflictAlgorithm: ConflictAlgorithm.replace,
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

    return result.isNotEmpty ? result.first : null;
  }
}

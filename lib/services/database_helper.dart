import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/purchase.dart';
import '../models/purchase_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('organiza_compras.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    // Enable foreign keys constraint
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        access_key TEXT UNIQUE NOT NULL,
        store_name TEXT NOT NULL,
        date TEXT NOT NULL,
        total_value REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        category TEXT NOT NULL,
        FOREIGN KEY (purchase_id) REFERENCES purchases (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        color INTEGER NOT NULL,
        icon_code INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    final batch = db.batch();
    batch.insert('categories', {'name': 'Alimentação', 'color': 0xFF2ECC71, 'icon_code': 58729}, conflictAlgorithm: ConflictAlgorithm.ignore);
    batch.insert('categories', {'name': 'Bebidas', 'color': 0xFF3498DB, 'icon_code': 58286}, conflictAlgorithm: ConflictAlgorithm.ignore);
    batch.insert('categories', {'name': 'Limpeza', 'color': 0xFFE67E22, 'icon_code': 984370}, conflictAlgorithm: ConflictAlgorithm.ignore);
    batch.insert('categories', {'name': 'Higiene', 'color': 0xFFE91E63, 'icon_code': 58980}, conflictAlgorithm: ConflictAlgorithm.ignore);
    batch.insert('categories', {'name': 'Outros', 'color': 0xFF95A5A6, 'icon_code': 60233}, conflictAlgorithm: ConflictAlgorithm.ignore);
    batch.insert('settings', {'key': 'default_state', 'value': 'SC'}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await batch.commit();
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE NOT NULL,
          color INTEGER NOT NULL,
          icon_code INTEGER NOT NULL
        )
      ''');

      final batch = db.batch();
      batch.insert('categories', {'name': 'Alimentação', 'color': 0xFF2ECC71, 'icon_code': 58729}, conflictAlgorithm: ConflictAlgorithm.ignore);
      batch.insert('categories', {'name': 'Bebidas', 'color': 0xFF3498DB, 'icon_code': 58286}, conflictAlgorithm: ConflictAlgorithm.ignore);
      batch.insert('categories', {'name': 'Limpeza', 'color': 0xFFE67E22, 'icon_code': 984370}, conflictAlgorithm: ConflictAlgorithm.ignore);
      batch.insert('categories', {'name': 'Higiene', 'color': 0xFFE91E63, 'icon_code': 58980}, conflictAlgorithm: ConflictAlgorithm.ignore);
      batch.insert('categories', {'name': 'Outros', 'color': 0xFF95A5A6, 'icon_code': 60233}, conflictAlgorithm: ConflictAlgorithm.ignore);
      await batch.commit();
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      await db.insert(
        'settings',
        {'key': 'default_state', 'value': 'SC'},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<int> insertPurchase(Purchase purchase) async {
    final db = await instance.database;
    
    return await db.transaction((txn) async {
      // Check if purchase with this access key already exists
      final existing = await txn.query(
        'purchases',
        where: 'access_key = ?',
        whereArgs: [purchase.accessKey],
      );

      int purchaseId;
      if (existing.isNotEmpty) {
        purchaseId = existing.first['id'] as int;
        // Delete existing items to re-import
        await txn.delete(
          'purchase_items',
          where: 'purchase_id = ?',
          whereArgs: [purchaseId],
        );
        // Update purchase info
        await txn.update(
          'purchases',
          purchase.toMap(),
          where: 'id = ?',
          whereArgs: [purchaseId],
        );
      } else {
        purchaseId = await txn.insert('purchases', purchase.toMap());
      }

      // Insert all purchase items
      for (var item in purchase.items) {
        final itemMap = item.copyWith(purchaseId: purchaseId).toMap();
        await txn.insert('purchase_items', itemMap);
      }

      return purchaseId;
    });
  }

  Future<List<Purchase>> getPurchases() async {
    final db = await instance.database;

    final result = await db.query('purchases', orderBy: 'date DESC');

    List<Purchase> purchases = [];
    for (var row in result) {
      final purchaseId = row['id'] as int;
      final itemsResult = await db.query(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [purchaseId],
      );

      final items = itemsResult.map((itemRow) => PurchaseItem.fromMap(itemRow)).toList();
      purchases.add(Purchase.fromMap(row, items: items));
    }

    return purchases;
  }

  Future<Purchase?> getPurchaseById(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      'purchases',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final itemsResult = await db.query(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [id],
      );

      final items = itemsResult.map((itemRow) => PurchaseItem.fromMap(itemRow)).toList();
      return Purchase.fromMap(maps.first, items: items);
    }
    return null;
  }

  Future<int> deletePurchase(int id) async {
    final db = await instance.database;
    return await db.delete(
      'purchases',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateItemCategory(int itemId, String newCategory) async {
    final db = await instance.database;
    return await db.update(
      'purchase_items',
      {'category': newCategory},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<List<Map<String, dynamic>>> getUniqueProducts() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT DISTINCT name, category 
      FROM purchase_items 
      ORDER BY name ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> getProductPriceHistory(String productName) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT pi.unit_price, p.date, p.store_name 
      FROM purchase_items pi 
      JOIN purchases p ON pi.purchase_id = p.id 
      WHERE pi.name = ? 
      ORDER BY p.date ASC
    ''', [productName]);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await instance.database;
    return await db.query('categories', orderBy: 'id ASC');
  }

  Future<int> insertCategory(String name, int colorValue, int iconCodePoint) async {
    final db = await instance.database;
    return await db.insert('categories', {
      'name': name,
      'color': colorValue,
      'icon_code': iconCodePoint,
    });
  }

  Future<void> updateCategory(int id, String oldName, String newName, int colorValue, int iconCodePoint) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'categories',
        {
          'name': newName,
          'color': colorValue,
          'icon_code': iconCodePoint,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      // Cascade to all items using the oldName to the newName
      await txn.update(
        'purchase_items',
        {'category': newName},
        where: 'category = ?',
        whereArgs: [oldName],
      );
    });
  }

  Future<void> deleteCategory(int id, String categoryName) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // Delete the category from categories table
      await txn.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );
      // Reset matching purchase items to "Outros"
      await txn.update(
        'purchase_items',
        {'category': 'Outros'},
        where: 'category = ?',
        whereArgs: [categoryName],
      );
    });
  }

  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final maps = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  Future<void> saveSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

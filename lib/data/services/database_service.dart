import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/emoji.dart';
import '../models/category.dart';

class DatabaseService {
  static const String _databaseName = 'emoji_hub.db';
  static const int _databaseVersion = 1;

  static Database? _database;

  // 获取数据库实例
  Future<Database> get database async {
    return await openDatabase(
      join(await getDatabasesPath(), 'emoji_hub.db'),
      onCreate: (db, version) => _onCreate(db, version),
      onUpgrade: _onUpgrade,
      version: 2,
    );
  }

  // 初始化数据库
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    if (Platform.isWindows || Platform.isLinux) {
      return databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      return openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  // 创建数据表
  Future<void> _onCreate(Database db, int version) async {
    // 创建分类表
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon INTEGER NOT NULL,
        color INTEGER NOT NULL DEFAULT 4278255615,
        sort_order INTEGER NOT NULL,
        create_time TEXT NOT NULL,
        update_time TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 创建表情表
    await db.execute('''
      CREATE TABLE emojis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        path TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        create_time TEXT NOT NULL,
        update_time TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 添加 color 列
      await db.execute(
          'ALTER TABLE categories ADD COLUMN color INTEGER NOT NULL DEFAULT 4278255615');
    }
  }

  Future<void> cleanupDatabase() async {
    final db = await database;
    final List<Map<String, dynamic>> emojis = await db.query('emojis');

    for (var emoji in emojis) {
      final String path = emoji['path'];
      if (path.startsWith('/')) {
        // 提取文件名
        final fileName = path.split('/').last;
        // 更新为相对路径
        await db.update(
          'emojis',
          {'path': 'emojis/$fileName'},
          where: 'id = ?',
          whereArgs: [emoji['id']],
        );
      }
    }
  }

  // Category CRUD 操作
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return db.insert('categories', category.toJson());
  }

  Future<List<Category>> getCategories({bool includeDeleted = false}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: includeDeleted ? null : 'is_deleted = 0',
      orderBy: 'sort_order ASC',
    );
    return List.generate(maps.length, (i) => Category.fromJson(maps[i]));
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return db.update(
      'categories',
      category.toJson(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.update(
      'categories',
      {'is_deleted': 1, 'update_time': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Emoji CRUD 操作
  Future<int> insertEmoji(Emoji emoji) async {
    final db = await database;
    return db.insert('emojis', emoji.toJson());
  }

  Future<List<Emoji>> getEmojis({
    int? categoryId,
    bool includeDeleted = false,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'emojis',
      where: [
        if (!includeDeleted) 'is_deleted = 0',
        if (categoryId != null) 'category_id = $categoryId',
      ].join(' AND '),
    );
    return List.generate(maps.length, (i) => Emoji.fromJson(maps[i]));
  }

  Future<int> updateEmoji(Emoji emoji) async {
    final db = await database;
    return db.update(
      'emojis',
      emoji.toJson(),
      where: 'id = ?',
      whereArgs: [emoji.id],
    );
  }

  Future<int> deleteEmoji(int id) async {
    final db = await database;
    return db.update(
      'emojis',
      {'is_deleted': 1, 'update_time': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'emoji_hub.db');
    await databaseFactory.deleteDatabase(path);
  }

  // 添加一个调试方法
  Future<void> debugPrintCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    print('所有分类: $maps');
  }
}
